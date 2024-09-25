require("Client.Modules.Guide.GuideModel");

local class_name = "GuideCtrl";
---@class GuideCtrl : UserGameController
---@field private super UserGameController
---@field private model GuideModel
GuideCtrl = GuideCtrl or BaseClass(UserGameController, class_name);

function GuideCtrl:__init()
    CWaring("==GuideCtrl init")
    self.Model = nil
end

function GuideCtrl:Initialize()
    ---@type GuideModel
    self.Model = self:GetModel(GuideModel)
end

--- 玩家登出
---@param data any
function GuideCtrl:OnLogout(data)
    CWaring("GuideCtrl OnLogout")
end

---@param data any
function GuideCtrl:OnLogin(data)
    CWaring("GuideCtrl OnLogin")

    self:SendQueryNewbieGuideConditionReq(Pb_Enum_GUIDE_COND_TYPE.OUTSIDE_GAME_GUIDE)
end

function GuideCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {   MsgName = Pb_Message.GetGameModeDataRsp,    Func = self.OnGetGameModeDataRsp},
        {   MsgName = Pb_Message.QueryNewbieGuideConditionRsp,    Func = self.OnQueryNewbieGuideConditionRsp},
        {   MsgName = Pb_Message.SetNewbieGuideConditionRsp,    Func = self.OnSetNewbieGuideConditionRsp},
        {   MsgName = Pb_Message.PlayerChooseGenderRsp,    Func = self.OnPlayerChooseGenderRsp},
    }
    self.MsgList = {
        {   Model = MatchModel, MsgName = MatchModel.ON_MATCH_CANCELED,  Func = self.OnCheckStartGameGuide },
        {   Model = GuideModel, MsgName = GuideModel.GUIDE_SET_NEXT_STEP,    Func = self.OnGuideSetNextStep },
        {   Model = GuideModel, MsgName = GuideModel.CHECK_GUIDE_SHOW_EVENT,    Func = self.CheckGuideShow },
    }
    self.MsgListGMP ={ 
        {   InBindObject = _G.MainSubSystem,    MsgName = "Request.GetPlayGameModeCount",   Func = Bind(self, self.On_GetPlayGameModeCount),   bCppMsg = true,  WatchedObject = nil}
    }
end

function GuideCtrl:OnGetGameModeDataRsp(Msg)
    print("OnGetGameModeDataRsp", Msg.ModeId, Msg.GameModeCnt)
    MsgHelper:SendCpp(GameInstance, "Response.PlayGameModeCountResponse", Msg.ModeId, Msg.GameModeCnt)

end

-- 新手指引数据请求回包
function GuideCtrl:OnQueryNewbieGuideConditionRsp(Msg)
    print_r(Msg, "GuideCtrl:OnQueryNewbieGuideConditionRsp Msg = ")
    self.Model:SetDataList({
        {
            GuideType = Msg.GuideType, GuideStep = Msg.GuideStep
        }
    })

    self:CheckGuideShow()
end

-- 设置引导步骤返回
function GuideCtrl:OnSetNewbieGuideConditionRsp(Msg)
    print_r(Msg, "GuideCtrl:OnSetNewbieGuideConditionRsp Msg = ")
    self.Model:AppendData({GuideType = Msg.GuideType, GuideStep = Msg.GuideStep})

    self:CheckGuideShow()
end

-- 玩家选择性别返回
function GuideCtrl:OnPlayerChooseGenderRsp(Msg)
    print_r(Msg, "GuideCtrl:OnPlayerChooseGenderRsp Msg = ")
end

-- 匹配主动取消的时候 检测新手引导弹窗
function GuideCtrl:OnCheckStartGameGuide()
    local IsOpenGuide = self.Model:CheckIsOpenGuide()
    if IsOpenGuide then
        local GuideStep = self.Model:GetCurrentShowGuideStep(Pb_Enum_GUIDE_COND_TYPE.OUTSIDE_GAME_GUIDE)
        if GuideStep == GuideModel.Enum_GuideStep.StartGame then
            self:CheckGuideShow()
        end
    end
end

-- 当前引导完成，设置到下一个阶段
function GuideCtrl:OnGuideSetNextStep(TriggerGuideStep)
    local IsOpenGuide = self.Model:CheckIsOpenGuide()
    if IsOpenGuide then
        local GuideStep = self.Model:GetCurrentShowGuideStep(Pb_Enum_GUIDE_COND_TYPE.OUTSIDE_GAME_GUIDE)
        if GuideStep and GuideStep == TriggerGuideStep then
            local NextGuideStep = GuideStep + 1
            self:SendSetNewbieGuideConditionReq(Pb_Enum_GUIDE_COND_TYPE.OUTSIDE_GAME_GUIDE, NextGuideStep)
        end
    end
end

-- 检测新手引导界面弹窗
function GuideCtrl:CheckGuideShow()
    local IsOpenGuide = self.Model:CheckIsOpenGuide()
    if IsOpenGuide then
        local GuideConfigData = self.Model:GetCurrentGuideConfigData(Pb_Enum_GUIDE_COND_TYPE.OUTSIDE_GAME_GUIDE)
        if GuideConfigData then
            local IsCanOpenGuide = self:CheckIsCanOpenGuideView()
            if IsCanOpenGuide then
                if GuideConfigData.CheckGuideViewId then
                    if self:GetModel(ViewModel):GetState(GuideConfigData.CheckGuideViewId) then
                        MvcEntry:OpenView(GuideConfigData.OpenViewId) 
                    end
                else
                    -- 判断大厅界面的新手引导
                    self:GetSingleton(CommonCtrl):TryFaceActionOrInCache(function ()
                        MvcEntry:OpenView(GuideConfigData.OpenViewId)
                    end)  
                end
            else
                CWaring("GuideCtrl:CheckGuideShow OpenViewId = " .. tostring(GuideConfigData.OpenViewId))
            end
        end
    end
end

-- 检测是否可以打开新手引导弹窗 
function GuideCtrl:CheckIsCanOpenGuideView()
    local IsCanOpen = true
    local GuideStep = self.Model:GetCurrentShowGuideStep(Pb_Enum_GUIDE_COND_TYPE.OUTSIDE_GAME_GUIDE)
    if GuideStep == GuideModel.Enum_GuideStep.StartGame then
        -- 弹窗前要判断是否匹配中
        if MvcEntry:GetModel(MatchModel):IsMatching() then
            IsCanOpen = false
        end
    end
    return IsCanOpen
end

-- GM设置新手引导开启状态
function GuideCtrl:SetGMGuideOpenState(State)
    self.Model:SetGMGuideOpenState(State)
    self:CheckGuideShow()
end

-- GM设置完成新手引导
function GuideCtrl:SetGMCompleteGuide()
    local GuideConfigData = self.Model:GetCurrentGuideConfigData(Pb_Enum_GUIDE_COND_TYPE.OUTSIDE_GAME_GUIDE)
    if GuideConfigData then
        self:SendSetNewbieGuideConditionReq(Pb_Enum_GUIDE_COND_TYPE.OUTSIDE_GAME_GUIDE, GuideModel.Enum_GuideStep.GuideComplete)
        self.Model:SetDataList({
            {
                GuideType = Pb_Enum_GUIDE_COND_TYPE.OUTSIDE_GAME_GUIDE, GuideStep = GuideModel.Enum_GuideStep.GuideComplete
            }
        })

        if self:GetModel(ViewModel):GetState(GuideConfigData.OpenViewId) then
            MvcEntry:CloseView(GuideConfigData.OpenViewId) 
        end
    end
end

-----------------------------------------------发送协议--------------------------------------------------
--[[
    请求对应数据类型的 相关数据

    获取通过  MvcEntry:GetModel(GuideModel):GetData(GuideModel.DataTypeDefine.GUIDE_BR_BATTLE_COUNT)
]]
function GuideCtrl:SendProto_GetGameModeDataReq(ModeId)
    local Msg = {
        ModeId = ModeId
    }
    ----bug=1026256 --user=韩胜辉 【新手引导】loading结束后进局内，新手引导界面会有转菊花 https://www.tapd.cn/68880148/s/1433762 临时解决转菊花问题
    self:SendProto(Pb_Message.GetGameModeDataReq, Msg--[[, Pb_Message.GetGameModeDataReq]])
end

function GuideCtrl:On_GetPlayGameModeCount(GameModeId)
    print("On_GetPlayGameModeCount", GameModeId)
    self:SendProto_GetGameModeDataReq(GameModeId)
end

-- 设置引导步骤请求
function GuideCtrl:SendSetNewbieGuideConditionReq(GuideType, GuideStep)
    local Msg = {
        GuideType = GuideType,
        GuideStep = GuideStep,
    }
    print_r(Msg, "GuideCtrl:SendSetNewbieGuideConditionReq Msg = ")
    self:SendProto(Pb_Message.SetNewbieGuideConditionReq, Msg, Pb_Message.SetNewbieGuideConditionRsp)
end

-- 新手指引数据请求
function GuideCtrl:SendQueryNewbieGuideConditionReq(GuideType)
    local Msg = {
        GuideType = GuideType
    }
    print_r(Msg, "GuideCtrl:SendQueryNewbieGuideConditionReq Msg = ")
    self:SendProto(Pb_Message.QueryNewbieGuideConditionReq, Msg, Pb_Message.QueryNewbieGuideConditionRsp)
end

-- 玩家选择性别请求
function GuideCtrl:SendPlayerChooseGenderReq(ItemId)
    local Msg = {
        ItemId = ItemId
    }
    print_r(Msg, "GuideCtrl:SendPlayerChooseGenderReq Msg = ")
    self:SendProto(Pb_Message.PlayerChooseGenderReq, Msg, Pb_Message.PlayerChooseGenderRsp)
end
