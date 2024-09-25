--[[
    剧情系统对接模块
    接入处理 AbilitySystemComponent 发出的GMP
]]

require("Client.Modules.Dialog.DialogSystemModel")
local class_name = "DialogSystemCtrl"
---@class DialogSystemCtrl : UserGameController
DialogSystemCtrl = DialogSystemCtrl or BaseClass(UserGameController,class_name)


function DialogSystemCtrl:__init()
    CWaring("==DialogSystemCtrl init")
    ---@type DialogSystemModel
    self.DialogSystemModel = MvcEntry:GetModel(DialogSystemModel)
    self.IsDialogAutoPlaying = false
end

function DialogSystemCtrl:Initialize()
   
end

--[[
    玩家登入
]]
function DialogSystemCtrl:OnLogin(data)
    CWaring("DialogSystemCtrl OnLogin")
end

function DialogSystemCtrl:AddMsgListenersUser()
    self.MsgListGMP = {
        {   InBindObject = _G.MainSubSystem,    MsgName = "DialogSystem.DialogAction.RecieveActionStart",   Func = Bind(self, self.On_RecieveActionStart),   bCppMsg = true,  WatchedObject = nil},
        {   InBindObject = _G.MainSubSystem,    MsgName = "DialogSystem.DialogAction.RecieveActionEnd",   Func = Bind(self, self.On_RecieveActionEnd),   bCppMsg = true,  WatchedObject = nil},
    }
    self.StoryCfg = nil

    ------ for test
    self.IsTestMode = false
    self.TestHeroId = nil
end

---@param StoryCfg FavorStoryConfig
function DialogSystemCtrl:PlayStory(StoryCfg)
    if not StoryCfg then
        return
    end
    local DialogBPPath = StoryCfg[Cfg_FavorStoryConfig_P.DialogBPPath]
    if not DialogBPPath or DialogBPPath == "" then
        return
    end
    self.StoryCfg = StoryCfg
    self:ActiveDialog(DialogBPPath)
	self.DialogSystemModel:DispatchType(DialogSystemModel.ON_PLAY_STORY)
end

-- 加载激活剧情
---@param DialogClsPath String 剧情Skill的路径
function DialogSystemCtrl:ActiveDialog(DialogClsPath,IsTest)
    local LocalPC = CommonUtil.GetLocalPlayerC()
    if not LocalPC then
        CWaring("DialogSystemCtrl GetLocalPlayerC Error!!")
        return
    end
    local LocalPS = LocalPC.PlayerState
    if not LocalPS then
        CWaring("DialogSystemCtrl PlayerState Error!!")
        return
    end
    local PlayerState_ASC  = LocalPS.PlayerState_ASC
    if not PlayerState_ASC then
        CWaring("DialogSystemCtrl PlayerState_ASC Error!!")
        return
    end
    local AbilityCls = UE.UClass.Load(DialogClsPath)
    if not AbilityCls then
        CWaring("DialogSystemCtrl LoadCls: "..DialogClsPath.." Error!!")
        return
    end
    self.DialogSystemModel:ClearCacheDialogList()
    self.CurDialogClsPath = DialogClsPath
    local AbilityHandle = PlayerState_ASC:K2_GiveAbility(AbilityCls)
    PlayerState_ASC:TryActivateAbility(AbilityHandle)
    self.CurAbilityHandle = AbilityHandle
    self.PlayerState_ASC = PlayerState_ASC
    self.IsTestMode = IsTest
end

function DialogSystemCtrl:On_RecieveActionStart(DoActionType,TheAbilityOwner,TheAbility,ParamJsonStr)
    if DoActionType == UE.EDialogActionType.Start then
        self.TheAbilityOwner = TheAbilityOwner
        self.TheAbility = TheAbility

        local Param = CommonUtil.JsonSafeDecode(ParamJsonStr)
        if not Param then
            return
        end
        --  区分测试和正式
        if self.IsTestMode then
            self.TestHeroId = Param.TestHeroId
            if Param.IsTestTaskReceived then
                self.TheAbility.IsReceiveTask = true
                self.TheAbility.ActionIndex = 0
            elseif Param.IsTestTaskFinished then
                self.TheAbility.IsTaskFinish = true
                self.TheAbility.ActionIndex = 0
            elseif Param.IsTestStoryFinish then
                self.TheAbility.IsStoryFinish = true
                self.TheAbility.ActionIndex = 1
            else
                self.TheAbility.ActionIndex = Param.TestActionIndex or 1
            end
        else
            -- 正式走任务数据
            if not self.StoryCfg then
                CError("EDialogActionType.Start Can't Found StoryCfg!!")
                return
            end

	        local Status = MvcEntry:GetModel(FavorabilityModel):GetPartStatus(self.StoryCfg[Cfg_FavorStoryConfig_P.HeroId],self.StoryCfg[Cfg_FavorStoryConfig_P.PartId])
            if Status == FavorabilityConst.STORY_STATUS.COMPLETED then
			    -- 故事已完成，走回看流程
                self.TheAbility.IsStoryFinish = true
                self.TheAbility.ActionIndex = 1
            else
                local TaskId = self.StoryCfg[Cfg_FavorStoryConfig_P.TaskId]
                if TaskId and TaskId > 0 then
                    -- 判断任务状态
                    local TaskData = MvcEntry:GetModel(TaskModel):GetData(TaskId)
                    if TaskData then
                        self.TheAbility.ActionIndex = 0
                        if TaskData.State >= Pb_Enum_TASK_TYPE_STATE.TASK_TYPE_FINISH then
                            -- 已完成
                            self.TheAbility.IsTaskFinish = true
                        else
                            self.TheAbility.IsReceiveTask = true
                        end
                    else
                        -- 任务未接取，从头播放
                        self.TheAbility.ActionIndex = 1
                    end
                else
                    self.TheAbility.ActionIndex = 1
                end
            end
        end
    elseif DoActionType == UE.EDialogActionType.End then
        self:DoFinishStory()
    else
        self.DialogSystemModel:DoAction(DoActionType,ParamJsonStr)
    end
end

-- 剧情完成
function DialogSystemCtrl:DoFinishStory()
    -- 上报服务器段落完成
    self:DoReportFinish()
    self:ClearCurAbility()
	self.DialogSystemModel:DispatchType(DialogSystemModel.ON_FINISH_STORY)
end

-- 剧情因设置中断，停止播放，并未完整结束
function DialogSystemCtrl:DoStopStory(ViewId)
    MvcEntry:CloseView(ViewId)
	self.DialogSystemModel:DispatchType(DialogSystemModel.ON_STOP_STORY)
end

function DialogSystemCtrl:On_RecieveActionEnd(DoActionType)
    self.DialogSystemModel:EndAction(DoActionType)
end

-- 通过选项，结束当前动作
-- function DialogSystemCtrl:SelectOption(OptionIndex)
--     if self.TheAbility then
--         self.TheAbility.OptionIndex = OptionIndex
--         self:FinishCurAction()
--     end
-- end

-- 结束当前动作
function DialogSystemCtrl:FinishCurAction()
    if self.TheAbility and self.TheAbility.ActionIndex ~= nil then
        self.TheAbility.ActionIndex = self.TheAbility.ActionIndex + 1
    end
end

function DialogSystemCtrl:DoSkipToEnd(SkipDes,SkipToIndex)
    if self.TheAbility.IsStoryFinish or SkipToIndex == 0 then
        --[[
            以下情况下点跳过，则出现弹窗，确认直接结束
            1. 剧情回看
            2. 不配置跳转索引
        ]]
        local TitleStr = self:GetPlayingStoryPartName()
        local Param = {
            TitleStr = TitleStr,
            DesStr = SkipDes,
        }
        MvcEntry:OpenView(ViewConst.DialogSkipTips,Param)
    else
        self.TheAbility.ActionIndex = SkipToIndex
    end
end

function DialogSystemCtrl:SetIsDialogAutoPlaying(IsDialogAutoPlaying)
    self.IsDialogAutoPlaying = IsDialogAutoPlaying
end

function DialogSystemCtrl:GetIsDialogAutoPlaying()
    return self.IsDialogAutoPlaying
end

function DialogSystemCtrl:DoRestart()
    if self.CurDialogClsPath then
        self:ClearCurAbility()
        self:ActiveDialog(self.CurDialogClsPath)
    end
end

function DialogSystemCtrl:ClearCurAbility()
    self.PlayerState_ASC:ClearAbility(self.CurAbilityHandle)
    self.DialogSystemModel:ResetData()
    self.CurAbilityHandle = nil
    self.StoryCfg = nil
    self.IsDialogAutoPlaying = false
end

function DialogSystemCtrl:DoReportFinish()
    if not self.StoryCfg then
        return
    end
    local HeroId = self.StoryCfg[Cfg_FavorStoryConfig_P.HeroId]
    local PartId = self.StoryCfg[Cfg_FavorStoryConfig_P.PartId]
    if MvcEntry:GetModel(FavorabilityModel):GetPartStatus(HeroId,PartId) == FavorabilityConst.STORY_STATUS.COMPLETED then
        return
    end
    local Param = {
        HeroId = HeroId,
        PartId = PartId,
    }
    MvcEntry:GetCtrl(FavorabilityCtrl):SendProto_PlayerStorePassageReq(Param)
end

function DialogSystemCtrl:DoReceiveTask()
    if not self.StoryCfg then
        return
    end
    local Param = {
        HeroId = self.StoryCfg[Cfg_FavorStoryConfig_P.HeroId],
        PartId = self.StoryCfg[Cfg_FavorStoryConfig_P.PartId],
        TaskId = self.StoryCfg[Cfg_FavorStoryConfig_P.TaskId],
    }
    MvcEntry:GetCtrl(FavorabilityCtrl):SendProto_PlayerAcceptPassageTaskReq(Param) 
end

function DialogSystemCtrl:GetPlayingStoryHeroId()
    if self.IsTestMode then
        return self.TestHeroId
    end
    if not self.StoryCfg then
        return nil
    end
    return self.StoryCfg[Cfg_FavorStoryConfig_P.HeroId]
end

function DialogSystemCtrl:GetPlayingStoryHeroName()
    local HeroId = self:GetPlayingStoryHeroId()
    if not HeroId then
        return ""
    end
    local HeroCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,HeroId)
    if not HeroCfg then
        return ""
    end
    return HeroCfg[Cfg_HeroConfig_P.Name]
end

function DialogSystemCtrl:GetPlayingStoryChapterName()
    if not self.StoryCfg then
        return ""
    end
    return self.StoryCfg[Cfg_FavorStoryConfig_P.ChapterName]
end

function DialogSystemCtrl:GetPlayingStoryPartName()
    if not self.StoryCfg then
        return ""
    end
    return self.StoryCfg[Cfg_FavorStoryConfig_P.PartName]
end