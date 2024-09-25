---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 大厅匹配入口
--- Created At: 2023/05/09 15:36
--- Created By: 朝文
---

require("Client.Modules.Match.MatchEntrance.HallMatchEntranceModel")

local class_name = "HallMatchEntranceLogic"
---@class HallMatchEntranceLogic
local HallMatchEntranceLogic = BaseClass(UIHandlerViewBase, class_name)
HallMatchEntranceLogic.Enum_AnimEvent = {
    --入场
    VXE_Hall_BTNStart_In    = "VXE_Hall_BTNStart_In",           --入场动画
    
    --匹配按钮
    VXE_Hall_MatchButton_Pressed    = "VXE_Hall_MatchButton_Pressed",   --匹配按钮按下
    VXE_Hall_MatchButton_Click      = "VXE_Hall_MatchButton_Click",     --匹配按钮点击，动一下而已
    VXE_Hall_Match_Hover            = "VXE_Hall_Match_Hover",           --开始匹配Hover
    VXE_Hall_Match_Unhover          = "VXE_Hall_Match_Unhover",         --开始匹配Unhover

    VXE_Hall_Matching_Pressed       = "VXE_Hall_Matching_Pressed",      --匹配中Pressed
    VXE_Hall_Matching_Hover         = "VXE_Hall_Matching_Hover",        --匹配中Hover
    VXE_Hall_Matching_Unhover       = "VXE_Hall_Matching_Unhover",      --匹配中Unhover

    VXE_Hall_Ready_Pressed          = "VXE_Hall_Unready_Pressed",       --未准备Pressed
    VXE_Hall_Ready_Hover            = "VXE_Hall_Unready_Hover",         --未准备Hover
    VXE_Hall_Ready_Unhover          = "VXE_Hall_Unready_Unhover",       --未准备unhover

    VXE_Hall_Already_Pressed        = "VXE_Hall_Already_Pressed",       --已准备Pressed
    VXE_Hall_Already_Hover          = "VXE_Hall_Already_Hover",         --已准备Hover
    VXE_Hall_Already_Unhover        = "VXE_Hall_Already_Unhover",       --已准备UnHover

    --模式选择
    VXE_Hall_Mode_Pressed           = "VXE_Hall_Mode_Pressed",          --模式选择Pressed
    VXE_Hall_Mode_Hover             = "VXE_Hall_Mode_Hover",            --模式选择Hover
    VXE_Hall_Mode_Unhover           = "VXE_Hall_Mode_Unhover",          --模式选择Unhover
    VXE_Hall_Mode_Scan_Hover        = "VXE_Hall_Mode_Scan_Hover",       --模式选择Hover(匹配中)
    VXE_Hall_Mode_Scan_Unhover      = "VXE_Hall_Mode_Scan_Unhover",     --模式选择Unhover(匹配中)
    VXE_Hall_Mode_Click             = "VXE_Hall_Mode_Click",            --模式选择Click
}

-- 人数描述
HallMatchEntranceLogic.Enum_MatchTeamTypeString = {
    [1]         = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_singlerow")),
    [2]         = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_doublerow")),
    [4]         = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Sipai")),
}

function HallMatchEntranceLogic:OnInit()
    self._MatchBtnClickable = true
    self.CountDownTimer = nil
    self.MatchSuccessAnimationTimer = nil
    
    self.MsgList = {
        --队伍数据        
        { Model = TeamModel, MsgName = TeamModel.ON_TEAM_INFO_CHANGED,	    Func = self.ON_TEAM_INFO_CHANGED_func },    --队伍变动，刷一下界面就好
        
        --匹配状态数据
        { Model = MatchModel, MsgName = MatchModel.ON_MATCHING_STATE_CHANGE,Func = self.ON_MATCHING_STATE_CHANGE_func },--匹配状态变动
        { Model = MatchModel, MsgName = MatchModel.ON_PLAY_MODE_ID_CHANGED, Func = self.ON_PLAY_MODE_ID_CHANGED_func }, --玩法模式ID(PlayModeId)发生了变化
        { Model = MatchModel, MsgName = MatchModel.ON_TEAM_TYPE_CHANGED,    Func = self.ON_TEAM_TYPE_CHANGED_func },    --队伍类型(TeamType)发生了变化
        { Model = MatchModel, MsgName = MatchModel.ON_PERSPECTIVE_CHANGED,  Func = self.ON_PERSPECTIVE_CHANGED_func },  --视角(Perspective)发生了变化
        { Model = MatchModel, MsgName = MatchModel.ON_SCENE_ID_CHANGED,     Func = self.ON_SCENE_ID_CHANGED_func },     --场景ID(SceneId)发生了变化
        { Model = MatchModel, MsgName = MatchModel.ON_MODE_ID_CHANGED,      Func = self.ON_MODE_ID_CHANGED_func },      --模式ID(ModeId)发生了变化
        { Model = MatchModel, MsgName = MatchModel.ON_CROSS_PLATFORM_MATCH_CHANGED,     Func = self.ON_CROSS_PLATFORM_MATCH_CHANGED_func },                       

        { Model = UserModel, MsgName = UserModel.ON_PLAYER_VALUE_ADD_CHANGED,     Func = self.UpdatePlayerAddInfo },         
        
        --ping值变动
        { Model = MatchSeverModel,       MsgName = MatchSeverModel.ON_MATCH_SERVER_INFO_UPDATED,                     Func = self.ON_MATCH_SERVER_INFO_UPDATED_func},
        --大厅选择的战斗服务器发生了变化
        { Model = MatchModel,            MsgName = MatchModel.ON_BATTLE_SEVER_CHANGED,                               Func = self.ON_BATTLE_SEVER_CHANGED_func},

        { Model = nil, MsgName = CommonEvent.ON_AFTER_BACK_TO_HALL, Func = self.OnAfterBackToHall },
    }

    self.BindNodes =
    {
        --上侧 模式选择 相关
        { UDelegate = self.View.BtnMode.OnClicked,	    Func = Bind(self, self.OnClicked_MapChoose) },
        { UDelegate = self.View.BtnMode.OnPressed,	    Func = Bind(self, self.OnPressed_MapChoose) },
        { UDelegate = self.View.BtnMode.OnReleased,	    Func = Bind(self, self.OnReleased_MapChoose) },
        { UDelegate = self.View.BtnMode.OnHovered,	    Func = Bind(self, self.OnHovered_MapChoose) },
        { UDelegate = self.View.BtnMode.OnUnhovered,	    Func = Bind(self, self.OnUnhovered_MapChoose) },

        --下侧 准备/匹配 相关
        { UDelegate = self.View.BtnStart.OnClicked,			Func = Bind(self, self.OnClicked_Start) },
        { UDelegate = self.View.BtnStart.OnPressed,			Func = Bind(self, self.OnPressed_Start) },
        { UDelegate = self.View.BtnStart.OnReleased,			Func = Bind(self, self.OnReleased_Start) },
        { UDelegate = self.View.BtnStart.OnHovered,			Func = Bind(self, self.OnHovered_Start) },
        { UDelegate = self.View.BtnStart.OnUnhovered,			Func = Bind(self, self.OnUnhovered_Start) },

        { UDelegate = self.View.OnMatchButtonClicked,			Func = Bind(self, self.OnMatchButtonClicked) },
        
        -- 加成卡相关
        { UDelegate = self.View.WBP_CommonBtn_AddInfo.GUIButton_Main.OnHovered,			Func = Bind(self, self.OnBtnAddInfoHovered) },
        { UDelegate = self.View.WBP_CommonBtn_AddInfo.GUIButton_Main.OnUnhovered,			Func = Bind(self, self.OnBtnAddInfoUnhovered) },
    }

    -- 排位相关信息入口
    self.SeasonRankEntranceItem = UIHandler.New(self, self.View.WBP_Season_Rank_Entrance, require("Client.Modules.Season.Rank.SeasonRankEntranceLogic")).ViewInstance

    ---@type MatchModel
    self.MatchModel = MvcEntry:GetModel(MatchModel)

    ---@type MatchModeSelectModel
    self.MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)

    ---@type HallMatchEntranceModel
    self.HallMatchEntranceModel = MvcEntry:GetModel(HallMatchEntranceModel)
end

function HallMatchEntranceLogic:OnShow(Param) 
    self:UpdatePlayerAddInfo()
end

---一个普通的刷新界面显示函数
function HallMatchEntranceLogic:UpdateView()
    local MatchState = self.MatchModel:GetMatchState()

    --更新左侧
    self:UpdateLeftPartDisplay(MatchState, MatchState)

    self:UpdateEntranceAnim("UpdateView")
end

function HallMatchEntranceLogic:OnHide()
    --兜底逻辑，避免音频泄露
    SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_SEARCHING_STOP)
    self:CleanCountDownTimer()
end

function HallMatchEntranceLogic:CleanCountDownTimer()
    if self.CountDownTimer then
        Timer.RemoveTimer(self.CountDownTimer)
        self.CountDownTimer = nil
    end
end

function HallMatchEntranceLogic:OnManualShow()
    self:UpdatePlayerAddInfo()
    self:UpdateView()
end

function HallMatchEntranceLogic:OnManualHide()
    self:OnUnhovered_Start()
end

---队伍变动
function HallMatchEntranceLogic:ON_TEAM_INFO_CHANGED_func()
    self:UpdateEntranceAnim("UpdateView")
end

---模式配置变动
function HallMatchEntranceLogic:ON_MODE_ID_CHANGED_func()
    --do nothing
end

---队伍类型(TeamType)发生了变化
function HallMatchEntranceLogic:ON_TEAM_TYPE_CHANGED_func()
    self:UpdateLeftModePlayerIconDisplay()      --更新队伍人数上限提示
end

---视角(Perspective)发生了变化
function HallMatchEntranceLogic:ON_PERSPECTIVE_CHANGED_func()
    --do nothing
end

---场景配置变动
function HallMatchEntranceLogic:ON_SCENE_ID_CHANGED_func()
    self:UpdateSceneNameDisplay()               --更新场景名字
    self:UpdateSceneBgImgDisplay()              --更新场景背景图    
end

---玩法模式变动
function HallMatchEntranceLogic:ON_PLAY_MODE_ID_CHANGED_func()
    self:UpdatePlayModeLeftTiPlaymeDisplay()    --更新玩法模式剩余时间
    self:UpdatePlayModeNameDisplay()            --更新玩法模式名字显示
end

---跨平台匹配变动
function HallMatchEntranceLogic:ON_CROSS_PLATFORM_MATCH_CHANGED_func()
    self:UpdateCrossPlatformMatchDisplay()      --更新跨平台匹配显示
end

---服务器列表中的信息更新了，这里需要更新一下各个服务器的延迟
function HallMatchEntranceLogic:ON_MATCH_SERVER_INFO_UPDATED_func()
    self:UpdateSelectSeverDisplay()
end

---大厅选择的战斗服务器发生了变化
function HallMatchEntranceLogic:ON_BATTLE_SEVER_CHANGED_func()
    self:UpdateSelectSeverDisplay()
end

function HallMatchEntranceLogic:OnAfterBackToHall(Param)
    print_r(Param, "allMatchEntranceLogic:OnAfterBackToHall Param")
	CWaring("HallMatchEntranceLogic OnAfterBackToHall")
	if Param and Param.TravelFailedResult then
		CWaring("HallMdt OnAfterBackToHall Because Travel Failed, Result = "..Param.TravelFailedResult)
		if Param.TravelFailedResult == GameStageCtrl.TRAVEL_FAILED_ENUM.BEFORE_PRELOADMAP then
			-- 进战斗Travel失败了直接返回，要更新一下UI
            self:InitEntranceAnim()
            self:UpdateLeftPartDisplay()
		end
	end
end

---匹配状态变动处理
function HallMatchEntranceLogic:ON_MATCHING_STATE_CHANGE_func(Msg)
    local OldMatchState = Msg.OldMatchState
    local NewMatchState = Msg.NewMatchState

    local IsNeedBtnCD = false
    --1.无匹配状态
    local MatchState = MatchModel.Enum_MatchState
    if NewMatchState == MatchState.MatchIdle then
        self:UpdateEntranceAnim("StateChange MatchIdle")

    --2.请求匹配中
    elseif NewMatchState == MatchState.MatchRequesting then
        --do nothing special

    --3.匹配中
    elseif NewMatchState == MatchState.Matching then       
        self:UpdateEntranceAnim("StateChange Matching")
        IsNeedBtnCD = true
    --4.匹配成功
    elseif NewMatchState == MatchState.MatchSuccess then
        self:UpdateEntranceAnim("StateChange Matching Success")
        SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_COMPLETE)

    --5.匹配失败
    elseif NewMatchState == MatchState.MatchFail then        
        self:UpdateEntranceAnim("StateChange Matching Fail")
        IsNeedBtnCD = true
    --6.匹配取消了
    elseif NewMatchState == MatchState.MatchCanceled then        
        self:UpdateEntranceAnim("StateChange Matching MatchCanceled")        
        IsNeedBtnCD = true
    end

    --更新左侧
    self:UpdateLeftPartDisplay(OldMatchState, NewMatchState)
    if IsNeedBtnCD then
        self:DisableMatchBtn()
    end
    
end

--region -------------- 左侧 --------------

---更新左侧小人Icon的图标，根据单排/双排和四排来显示不同个数的小人
function HallMatchEntranceLogic:UpdateLeftModePlayerIconDisplay()
    -- todo delete
    -- ---封装一个函数处理小人显示
    -- ---@param num number 需要显示的小人个数
    -- local function _UpdateTeamIcon(num)
    --     if not num then return end
    --     for i = 1, 4 do
    --         local widget = self.View["GUIImage_Player_" .. tostring(i)]
    --         if widget then
    --             if i <= num then
    --                 widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --             else
    --                 widget:SetVisibility(UE.ESlateVisibility.Hidden)
    --             end
    --         else
    --             CError("[cw][HallMatchEntranceLogic] Trying to toggle GUIImage_Player_" .. tostring(i) .. "'s display which is a illegal widget.")
    --         end
    --     end
    -- end
    -- local TeamType = self.MatchModel:GetTeamType() or 1
    -- _UpdateTeamIcon(TeamType)

    local TeamType = self.MatchModel:GetTeamType() or 1
    local PeopleText = HallMatchEntranceLogic.Enum_MatchTeamTypeString[TeamType] or ""
    self.View.TextBlock_People:SetText(StringUtil.Format(PeopleText))
end

---更新地图名显示
function HallMatchEntranceLogic:UpdateSceneNameDisplay()
    local SceneId = self.MatchModel:GetSceneId()
    if not SceneId then
        self.View.GUITextBlock_SceneName:SetText("")
        return
    end

    local SceneName = self.MatchModeSelectModel:GetSceneEntryCfg_SceneName(SceneId) or ""
    self.View.GUITextBlock_SceneName:SetText(StringUtil.Format(SceneName))
end

---更新背景地图显示
function HallMatchEntranceLogic:UpdateSceneBgImgDisplay()
    local SceneId = self.MatchModel:GetSceneId()
    if not SceneId then
        return
    end
    local HallMatchEntranceBgImgPath = self.MatchModeSelectModel:GetSceneEntryCfg_HallMatchEntranceBgImgPath(SceneId)
    CommonUtil.SetMaterialTextureParamSoftObjectPath(self.View.VX_MI_Img_Mode, "Tex", HallMatchEntranceBgImgPath)
end

---更新地图剩余时间显示
function HallMatchEntranceLogic:UpdatePlayModeLeftTiPlaymeDisplay()
    self:CleanCountDownTimer()

    local PlayModeId = self.MatchModel:GetPlayModeId()

    self.View.GUIImage_Line:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.ImgTimer:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.TxtTimer:SetVisibility(UE.ESlateVisibility.Collapsed)

    --配置错误不显示
    if not PlayModeId then return end

    --永久开放不显示
    local StartTime = self.MatchModeSelectModel:GetPlayModeCfg_StartTime(PlayModeId)
    local EndTime = self.MatchModeSelectModel:GetPlayModeCfg_EndTime(PlayModeId)
    if StartTime == 0 and EndTime == 0 then return end

    --显示开放显示
    local NowTimeStamp = GetTimestamp()
    if StartTime <= NowTimeStamp and NowTimeStamp < EndTime then
        self.View.GUIImage_Line:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.ImgTimer:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.TxtTimer:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        local function _UpdateTIme()
            local _timeStamp = GetTimestamp()
            local dif = EndTime - _timeStamp
            local timeStr = TimeUtils.GetTimeString_CountDownStyle(dif)
            if CommonUtil.IsValid(self.View) then
                self.View.TxtTimer:SetText(timeStr) 
            end
            return dif
        end

        --显示倒计时相关控件，并初始化显示文字
        _UpdateTIme()
        self.CountDownTimer = Timer.InsertTimer(1, function()
            local dif = _UpdateTIme()
            if dif == 0 then
                --这里应该触发一个刷新事件
            end
        end, true)
    end
    
end

---更新玩法模式名显示
function HallMatchEntranceLogic:UpdatePlayModeNameDisplay()
    local PlayMode = self.MatchModel:GetPlayModeId()
    if not PlayMode then
        self.View.GUITextBlock_PlayMode:SetText("")
        return
    end
    
    local PlayModeName = self.MatchModeSelectModel:GetPlayModeCfg_PlayModeName(PlayMode) or ""
    self.View.GUITextBlock_PlayMode:SetText(StringUtil.Format(PlayModeName))
end

---更新跨平台匹配显示
function HallMatchEntranceLogic:UpdateCrossPlatformMatchDisplay()
    local IsCrossPlatformMatch = self.MatchModel:GetIsCrossPlatformMatch()
    if IsCrossPlatformMatch then
        self.View.HorizontalBox_CrossPlatformMatch:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.View.HorizontalBox_CrossPlatformMatch:SetVisibility(UE.ESlateVisibility.Collapsed)    
    end
end

---更新已选择的服务器延迟信息
function HallMatchEntranceLogic:UpdateSelectSeverDisplay()
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local SelectedSeverId = MatchModel:GetSeverId()
    if not SelectedSeverId then return end
    
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    local delay = MatchSeverModel:GetDsPingByDsGroupId(SelectedSeverId)
    --延迟文字
    delay = delay or 0
    local tip = "{0}ms"
    local Color = self.View.NetworkGreen
    --延迟文字颜色
    if delay <= MatchSeverModel.Const.MaxGreenDelay then
        Color = self.View.NetworkGreen
    elseif delay <= MatchSeverModel.Const.MaxYellowDelay then
        Color = self.View.NetworkYellow
    else
        Color = self.View.NetworkRed
        tip = ">{0}ms"
        delay = MatchSeverModel.Const.MaxYellowDelay
    end
    self.View.GUIImage_Network:SetColorAndOpacity(Color.SpecifiedColor)
    self.View.GUITextBlock_NetworkLatency:SetColorAndOpacity(Color)
    self.View.GUITextBlock_NetworkLatency:SetText(StringUtil.Format(tip, delay))
end

---更新左侧模式文字显示
function HallMatchEntranceLogic:UpdateLeftPartDisplay()
    self:UpdateLeftModePlayerIconDisplay()      --更新队伍人数上限提示
    self:UpdateSceneNameDisplay()               --更新场景名字
    self:UpdateSceneBgImgDisplay()              --更新场景背景图
    self:UpdatePlayModeLeftTiPlaymeDisplay()    --更新玩法模式剩余时间
    self:UpdatePlayModeNameDisplay()            --更新玩法模式名字显示
    self:UpdateCrossPlatformMatchDisplay()      --更新跨平台匹配显示
    self:UpdateSelectSeverDisplay()             --更新已选择的服务器延迟信息
end

---点击模式匹配按钮
---  *队伍中
---      队长 打开模式界面选择
---      队员 无法操作
---  *个人    打开模式界面选择
function HallMatchEntranceLogic:OnClicked_MapChoose()
    if not self.MatchModel:IsMatchIdle() then
        --非闲置情况下不做处理
        return
    end   
    
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)

    --1.在队伍中(人数>1才算队伍) 且 非队长 时，不能进行操作    
    if TeamModel:IsSelfInTeam() and not TeamModel:IsSelfTeamCaptain() then
        local Param = {
            describe = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_HallMatchEntranceMdt_Yourenotthecaptain"),
        }
        UIMessageBox.Show(Param)
        return
    end

    --2.打开模式选择界面
    MvcEntry:OpenView(ViewConst.MatchModeSelect)

    self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Mode_Click)
end

function HallMatchEntranceLogic:OnPressed_MapChoose()
    if self.MatchModel:IsMatchIdle() then
        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Mode_Pressed)
    end
end

function HallMatchEntranceLogic:OnReleased_MapChoose()
end

function HallMatchEntranceLogic:OnHovered_MapChoose()
    if self.MatchModel:IsMatchIdle() then
        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Mode_Hover)
    else
        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Mode_Scan_Hover)
    end   
end

function HallMatchEntranceLogic:OnUnhovered_MapChoose()
    if self.MatchModel:IsMatchIdle() then
        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Mode_Unhover)
    else
        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Mode_Scan_Unhover)
    end   
end

--endregion -------------- 左侧 --------------

--region -------------- 右侧 --------------

---封装一个接口判断匹配按钮是否可以点击
---@return boolean
function HallMatchEntranceLogic:IsMatchBtnClickable()
    return self._MatchBtnClickable
end

---给匹配按钮加个点击限制
-- 修改为通过匹配状态发生改变时(匹配中 <-> 停止匹配)开启，不再由点击主动触发 @chenyishui
---@param DisableTime number 限制时长，默认为 0.6s
function HallMatchEntranceLogic:DisableMatchBtn(DisableTime)
    if self._MatchBtnClickableTimer then return end

    DisableTime = DisableTime or 0.6
    self._MatchBtnClickable = false
    self._MatchBtnClickableTimer = Timer.InsertTimer(DisableTime, function()
        self._MatchBtnClickable = true
        self._MatchBtnClickableTimer = nil
    end)
end

---因为蓝图动画需要，在播放动画前先更新一下蓝图中的参数，方便动效同学根据参数进行调整。
function HallMatchEntranceLogic:UpdateBluePrintFiled()
    local CacheData = self.HallMatchEntranceModel:GetStoreData()    
   
    self.View.IsCaptain = CacheData.TeamInfo.isCaptain
    self.View.IsReady = CacheData.TeamInfo.isReady
end

---封装一个触发蓝图中的动画事件的接口
---@param AnimEventName string 动画事件名称
---@param LogKey string debug使用信息
function HallMatchEntranceLogic:ExecuteAnimEvent(AnimEventName, LogKey, bNeedDebugLog)
    if not self.View or not self.View[AnimEventName] then
        CError("[cw][HallMatchEntranceLogic] Cannot find " .. tostring(AnimEventName) .. " in " .. tostring(self.View) .. "")
        CError(debug.traceback())
        return
    end

    local newLogKey
    if LogKey then
        newLogKey = "[" .. tostring(LogKey) .. "]"
    else
        newLogKey = ""
    end
    CLog("[cw][HallMatchEntranceLogic]" .. newLogKey .. " *** " .. tostring(AnimEventName))
    if bNeedDebugLog then self.HallMatchEntranceModel:_Debug_LogNewState(LogKey) end
    self.View[AnimEventName](self.View)
end

---初始化入场动画，界面显示时需要先播放这个动画，来确保数据准确
---1）初始化 HallMatchEntranceModel 中存储的数据
---2）播放入场动画
function HallMatchEntranceLogic:InitEntranceAnim()
    --1.初始化数据
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)

    local InitState = {
        TeamInfo = {
            isCaptain = not TeamModel:IsSelfInTeam() or TeamModel:IsSelfTeamCaptain(),
            isReady = self.MatchModel:GetIsPrepare()
        },
        MatchInfo = {
            isMatching = nil,           --后续赋值
            isMatchingSuccess = nil     --后续赋值
        }
    }
    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.HallMatchEntranceModel:ClearStoreData()
    self.HallMatchEntranceModel:StoreData(InitState)

    --2.播放入场动画
    self:UpdateBluePrintFiled()
    self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_BTNStart_In, nil, true)
    self:OnMatchButtonClicked(nil, false)

    -- 初始化时，要先把缓存的状态更新为当前状态，才不会出现错误的显示
    self.MatchModel:TriggerSyncMatchStateChange()

    --匹配成功特殊逻辑(初始化的逻辑不能控制到匹配及匹配成功，所以需要稍后调用)
    if self.MatchModel:IsMatchSuccessed() then
        CLog("[cw] HallMatchEntranceLogic:InitEntranceAnim() MatchModel:IsMatchSuccessed()")
        self.HallMatchEntranceModel:UpdateNextAnimData(nil, nil, true, false)
        self:UpdateEntranceAnim("InitMatchSuccessed Step1")
        -- self:InsertTimer(Timer.NEXT_TICK, function()
            self.HallMatchEntranceModel:UpdateNextAnimData(nil, nil, nil, true)
            self:UpdateEntranceAnim("InitMatchSuccessed Step2")
            self:UpdateEntranceAnim()
        -- end)
        
    --匹配中特殊逻辑(初始化的逻辑不能控制到匹配及匹配成功，所以需要稍后调用)
    elseif self.MatchModel:IsMatching() then
        CLog("[cw] HallMatchEntranceLogic:InitEntranceAnim() MatchModel:IsMatching()")
        self.HallMatchEntranceModel:UpdateNextAnimData(nil, nil, true, false)
        self:UpdateEntranceAnim("InitMatching")
    end
end

---更新一下动画播放，通过
---@param LogKey string debug使用信息
function HallMatchEntranceLogic:UpdateEntranceAnim(LogKey)
    -- Timer.InsertTimer(-1, function()
        if not self.HallMatchEntranceModel:HasStoreData() then CLog("[cw][HallMatchEntranceLogic] not has store data") return end
        
        self:UpdateBluePrintFiled()
        
        local Anims = self.HallMatchEntranceModel:Calculate()
        if Anims and next(Anims) then 
            for _, animEvent in ipairs(Anims) do
                self:ExecuteAnimEvent(animEvent, LogKey, true)
            end
        end

        self.HallMatchEntranceModel:ReplaceOldDate()
    -- end)
end

---辅助判定为队伍状态下按钮的点击逻辑
---外部不应该直接使用，为了避免外部使用，调整为local函数
---@param self HallMatchEntranceLogic
local function _TeamMatchCheck(self)
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    ---@type TeamCtrl
    local TeamCtrl = MvcEntry:GetCtrl(TeamCtrl)
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local IsMatching = MatchModel:IsMatching()
    ---@type MatchCtrl
    local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)

    --1.队长
    if TeamModel:IsSelfTeamCaptain() then
        --1.1.匹配中 -> 取消匹配
        if IsMatching then
            MatchCtrl:SendMatchCancelReq()
            -- self:DisableMatchBtn()

        --1.2.未匹配 -> 检查队员是否已经准备好了，准备好后就可以匹配了
        else
            if not TeamModel:IsMyTeamAllMembersTeamPlayerInfoStatusREADY() then
                local Param = {
                    describe = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_HallMatchEntranceMdt_Therearestillteammat")
                }
                UIMessageBox.Show(Param)
            else
                self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_MatchButton_Click)
                -- self:DisableMatchBtn()

                MatchCtrl:SendMatchReq()
                SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_START)
            end
        end

    --2.队员
    else
        --2.1.匹配中 -> 取消匹配
        if IsMatching then
            MatchCtrl:SendMatchCancelReq()
            -- self:DisableMatchBtn()
            SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_CANCEL)

        --2.2.未匹配 -> 切换准备状态
        else
            local isReady = MatchModel:GetIsPrepare()
            if isReady then
                TeamCtrl:ChangeMyTeamMemberStatusToUnReady()
                SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_CANCEL)
            else
                TeamCtrl:ChangeMyTeamMemberStatusToReady()
                SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_READY)
            end
        end
    end
end

---辅助判定为个人状态下按钮的点击逻辑
---外部不应该直接使用，为了避免外部使用，调整为local函数
---@param self HallMatchEntranceLogic
local function _SoloMatchCheck(self)
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local IsMatching = MatchModel:IsMatching()
    ---@type MatchCtrl
    local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)

    --2.1.匹配中 -> 取消匹配
    if IsMatching then
        -- self:DisableMatchBtn()
        MatchCtrl:SendMatchCancelReq()
        SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_CANCEL)
        --2.2.未匹配 -> 直接开始匹配
    else
        -- self:DisableMatchBtn()
        MatchCtrl:SendMatchReq()
        SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_START)
    end
    self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_MatchButton_Click)
end

---点击右侧匹配按钮
---  *队伍中
---      队长 开始匹配/取消匹配        
---      队员 准备/取消准备/取消匹配
---
---  *个人    开始匹配/取消匹配   
function HallMatchEntranceLogic:OnClicked_Start()
    if not self:IsMatchBtnClickable() then return end

    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)

    if TeamModel:IsSelfInTeam() then
        _TeamMatchCheck(self)
    else
        _SoloMatchCheck(self)
    end
end

function HallMatchEntranceLogic:OnPressed_Start() 
    if not self:IsMatchBtnClickable() then return end

    local IsMatching = self.MatchModel:IsMatching()

    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsSelfCaptain = TeamModel:IsSelfTeamCaptain()
    local IsSelfInTeam = TeamModel:IsSelfInTeam()

    --处理动效
    if IsMatching then
        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Matching_Pressed)
    else
        --单人 或 队长 时，需要播放按钮进入匹配的效果
        if not IsSelfInTeam or IsSelfCaptain then
            self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_MatchButton_Pressed)

        --队员，需要播放按钮准备的效果
        else
            -- if TeamModel:IsMyTeamPlayerInfoStatusREADY() then                
            if self.View.IsReady then                
                self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Already_Pressed)
            else
                self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Ready_Pressed)
            end
        end
    end
end
function HallMatchEntranceLogic:OnReleased_Start() end

function HallMatchEntranceLogic:OnHovered_Start()
    local IsMatching = self.MatchModel:IsMatching()

    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsSelfCaptain = TeamModel:IsSelfTeamCaptain()
    local IsSelfInTeam = TeamModel:IsSelfInTeam()

    --处理动效
    if IsMatching then
        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Matching_Hover)
    else
        --单人 或 队长 时，需要播放按钮进入匹配的效果
        if not IsSelfInTeam or IsSelfCaptain then
            self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Match_Hover)

        --队员，需要播放按钮准备的效果
        else
            -- if TeamModel:IsMyTeamPlayerInfoStatusREADY() then                
            if self.View.IsReady then                
                self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Already_Hover)
            else
                self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Ready_Hover)
            end
        end
    end

    --处理音效
    SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_BTN_HOVER)
end

function HallMatchEntranceLogic:OnUnhovered_Start()
    local IsMatching = self.MatchModel:IsMatching()

    if IsMatching then
        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Matching_Unhover)
    else
        ---@type TeamModel
        local TeamModel = MvcEntry:GetModel(TeamModel)
        local IsSelfCaptain = TeamModel:IsSelfTeamCaptain()
        local IsSelfInTeam = TeamModel:IsSelfInTeam()

        --单人 或 队长 时，需要播放按钮进入匹配的效果
        if not IsSelfInTeam or IsSelfCaptain then
            self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Match_Unhover)

        --队员，需要播放按钮准备的效果
        else
            if TeamModel:IsMyTeamPlayerInfoStatusREADY() then
                self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Already_Unhover)
            else
                self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Ready_Unhover)
            end
        end
    end
end

---自定义的蓝图派发事件，用于修正复杂动画
---@param bIsInArea boolean 蓝图侧传入的变量，用于逻辑判断是否需要触发 hover 或 unhover
function HallMatchEntranceLogic:OnMatchButtonClicked(handler, bIsInArea)
    CLog("[cw][HallMatchEntranceLogic]: OnMatchButtonClicked(" .. string.format("%s", bIsInArea) .. ")")
    local IsMatching = self.MatchModel:IsMatching()
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsSelfCaptain = TeamModel:IsSelfTeamCaptain()
    local IsSelfInTeam = TeamModel:IsSelfInTeam()

    --1.匹配中
    if IsMatching then
        if bIsInArea then
            self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Matching_Hover)
        else
            --self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Matching_Unhover)
        end

    --2.未匹配
    else
        --2.1.队伍中
        if IsSelfInTeam then
            --2.1.1.队长
            if IsSelfCaptain then
                if bIsInArea then
                    self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Match_Hover)
                else
                    --self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Match_Unhover)
                end

            --2.1.2.队员
            else
                --2.1.2.1.准备
                if TeamModel:IsMyTeamPlayerInfoStatusREADY() then
                    if bIsInArea then
                        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Already_Hover)
                    else
                        --self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Already_Unhover)
                    end
                --2.1.2.2.未准备
                else
                    if bIsInArea then
                        self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Ready_Hover)
                    else
                        --self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Ready_Unhover)
                    end
                end
            end

        --2.2.单人
        else
            if bIsInArea then
                self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Match_Hover)
            else
                --self:ExecuteAnimEvent(HallMatchEntranceLogic.Enum_AnimEvent.VXE_Hall_Match_Unhover)
            end
        end
    end
end

--endregion -------------- 右侧 --------------

-- 玩家加成卡生效提示按钮
function HallMatchEntranceLogic:UpdatePlayerAddInfo()
    local UserModel = MvcEntry:GetModel(UserModel)
    local IsShowAddInfo = UserModel:IsShowPlayerExpAddInfo()
    self.View.GUIScaleBox_AddInfo:SetVisibility(IsShowAddInfo and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function HallMatchEntranceLogic:OnBtnAddInfoHovered()
    if not self.AddInfoDetailCls then
        self.AddInfoDetailCls = UIHandler.New(self,self.View.WBP_BuffProps_Detail,require("Client.Modules.Hall.HallPlayerAddInfoDetailLogic")).ViewInstance
    end
    self.AddInfoDetailCls:UpdateView()
    self.View.WBP_BuffProps_Detail:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function HallMatchEntranceLogic:OnBtnAddInfoUnhovered()
    self.View.WBP_BuffProps_Detail:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return HallMatchEntranceLogic
