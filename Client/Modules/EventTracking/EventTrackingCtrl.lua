require("Client.Modules.EventTracking.EventTrackingModel")

local class_name = "EventTrackingCtrl";
---@class EventTrackingCtrl : UserGameController
---@field private super UserGameController
---@field private model EventTrackingModel
EventTrackingCtrl = EventTrackingCtrl or BaseClass(UserGameController, class_name);

EventTrackingCtrl.IsOpen = true --总开关

--转化率枚举,涉及登录前每个环节
EventTrackingCtrl.LoginBeforEnum = {
    StartClient = 1, --启动客户端
    StartUpdate = 2, --开始更新
    UpdateFinished = 3, --更新完成
    StartSDKRegister = 4, --拉起SDK注册界面
    RegisterCodeSend = 5, --注册验证码触发
    StartCertification = 6, --触发实名认证
    LoginRegisterSuc = 7,  --注册成功
    LoginCodeSend = 8, --发送登陆验证码
    LoginSeccecedByCode = 9, --验证码登陆成功
    StartGame = 10, --开始游戏
    StartPreventAddiction = 11, --触发防沉迷验证
}

function EventTrackingCtrl:__init()
    CWaring("==EventTrackingCtrl init")
end

function EventTrackingCtrl:Initialize()
    self.Model = MvcEntry:GetModel(EventTrackingModel)
    self.IsOpen = self.Model.IsOpen
    self.View2AlreadOpened = {}
    --TODO 还需要让逻辑层额外接一个Tab页打开的事件到你这里处理


    self.LastReprotStepData = nil
end

function EventTrackingCtrl:OnLogout()
    --self:ReqIconClicked() --不需要了
end


function EventTrackingCtrl:AddMsgListenersUser()
    if not self.IsOpen then return end
    -- self.MsgList = {{
    --     Model = ViewModel, MsgName = ViewConst.VirtualLogin,  Func = self.OnVirtualLoginState
    -- }}
    print("========EventTrackingCtrl:AddMsgListenersUser========")
    self.MsgList = {
        --{ Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_START,    Func = self.ReqBurialPointReportOnStepFlow},--登录前步骤收集
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED,    Func = self.ON_SATE_ACTIVE_CHANGED_Func},
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,    Func = self.ON_SATE_DEACTIVE_CHANGED_Func},
        { Model = EventTrackingModel, MsgName = EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID,    Func = self.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID_Func},
        { Model = EventTrackingModel, MsgName = EventTrackingModel.ON_SHOP_EVENTTRACKING_CLICK,    Func = self.ReqOnShopInteract},
        { Model = EventTrackingModel, MsgName = EventTrackingModel.ON_ICON_EVENTTRACKING_CLICK,    Func = self.ReqIconClicked},
        { Model = EventTrackingModel, MsgName = EventTrackingModel.ON_LOADING_FLOW_EVENTTRACKING,    Func = self.ReqLoadingFlow},
        --{ Model = EventTrackingModel, MsgName = EventTrackingModel.ON_VOICE_EVENTTRACKING,    Func = self.ReqVoiceFlow},
        { Model = GVoiceModel, MsgName = GVoiceModel.ON_RECEIVE_LOCAL_AUDIO,    Func = self.SetVoiceStart},
        { Model = GVoiceModel, MsgName = GVoiceModel.ON_RECEIVE_LOCAL_AUDIO_END,    Func = self.ReqVoiceFlow},
        { Model = EventTrackingModel, MsgName = EventTrackingModel.ON_HERO_INFO_EVENTTRACKING,    Func = self.ReqOnHeroInfo},
        { Model = EventTrackingModel, MsgName = EventTrackingModel.ON_FRIEND_FLOW_EVENTTRACKING,    Func = self.ReqFriendFlow},
        { Model = GlobalInputModel, MsgName = GlobalInputModel.ON_ANY_INPUT_TRIGGERED,    Func = self.ReqAfkFlow},
        { Model = GlobalInputModel, MsgName = GlobalInputModel.ON_GUIBUTTON_PRESSED,    Func = self.ReqAfkFlow},
    }
end

function EventTrackingCtrl:ON_SATE_ACTIVE_CHANGED_Func(ViewId)
    self:ReportViewIdWithOpen(ViewId)
end
function EventTrackingCtrl:ON_SATE_DEACTIVE_CHANGED_Func(ViewId)
    self:ReportViewIdWithClose(ViewId)
end
function EventTrackingCtrl:ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID_Func(InViewParam)
    self:ReportViewIdWithOpen(InViewParam.ViewId, InViewParam)
end

function EventTrackingCtrl:ReportViewIdWithOpen(ViewId, InViewParam)
    self:ReqOnViewFlow(true, ViewId, InViewParam)
end

function EventTrackingCtrl:ReportViewIdWithClose(ViewId)
    self:ReqOnViewFlow(false, ViewId)
end

function EventTrackingCtrl:ReportViewIdWithClose(ViewId)
    self:ReqOnViewFlow(false, ViewId)
end

function EventTrackingCtrl:ReqOnViewFlow(InIsOpen, ViewId, InViewParam)
    if not self.IsOpen then return end

    if not ViewId then
        CError("EventTrackingCtrl:ReqOnViewFlow>>>>>>>>>>> ViewId is nil")
        return
    end

    local ViewTabId = InViewParam and InViewParam.TabId or 0

    local IsIdInBlackList = self.Model:IsViewIdInBlackList(ViewId)
    if IsIdInBlackList then
        return
    end
    print("EventTrackingCtrl:ReqOnViewFlow====================", InIsOpen, ViewId, ViewTabId)

    self.Model:UpdateViewFlowData(InIsOpen, ViewId, InViewParam)

    self.fct_tab = self.Model:GetFctTab()
    self.upper_layer = self.Model:GetUpperLayer()
    local duration = self.Model:GetDuration()
    local is_daily_frist = self.Model:IsDailyFrist()

    self:ReqFunctionViewFlow(ViewId, InIsOpen, InIsOpen and 0 or duration, is_daily_frist)
end

function EventTrackingCtrl:ReqFunctionViewFlow(ViewId, InIsOpen, duration, is_daily_frist)
    local PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId() 
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local MatchState = MatchModel:GetMatchState()--MatchModel.Enum_MatchState.Matching
    local GetDisPlayState = MvcEntry:GetModel(UserModel):GetPlayerCacheState(PlayerId)
    local DisPlayState = (not GetDisPlayState or type(GetDisPlayState.DisplayStatus) == "number") and self.Model.Enum_PLAYER_CLIENT_HALL_STATE.Hall or GetDisPlayState.DisplayStatus
    if MatchState == MatchModel.Enum_MatchState.Matching then --匹配中状态高于大厅
        DisPlayState = "Matching"
    end
    local UpperLayer = InIsOpen and self.Model:GetUpperLayer() or self.Model:GetUpperLayer(false)
    if UpperLayer == ViewId then
        UpperLayer = ""
    end
    local JsonValue = {
            ["game_status"] = DisPlayState,--Pb_Enum_PLAYER_STATE.PLAYER_LOBBY, --gaming-对局中,matching-匹配中,lobby-大厅,checkout-结算界面。
            ["fct_type"] = ViewId, --viewId
            ["fct_tab"] = self.Model:GetNowTab(), --fcttab-fcttab-...
            ["action"] = InIsOpen and 1 or 0, --view open or close (1 or 0)
            ["refrence_fct_type"] = UpperLayer, --上级界面(fct_type + fct_tab) 已存在,询问接口
            ["refrence_fct_tab"] = self.Model:GetUpperLayerTab(), --上级界面(fct_type + fct_tab) 已存在,询问接口
            ["duration"] = duration, --访问停留时间(询问接口,应当在Close时记录)
            ["is_daily_first"] = is_daily_frist, --是否当天第一次打开(1:是， 0:否)
    }
    UE.UBuryReportSubsystem.SendBuryByContext(GameInstance, nil, "function_view_flow", CommonUtil.JsonSafeEncode(JsonValue))
end

--[[
    戳英雄和阅读这块可能得手动调用该接口，目前无事件交互
    local InHeroData : table = {
        HeroId: any,
        TxtIndex: any,
        IsSkip: any,
        IsInterrupt: any
    }
]]
function EventTrackingCtrl:ReqOnHeroInfo(InHeroData)
    if not self.IsOpen then return end
    local FavorabilityModel = MvcEntry:GetModel(FavorabilityModel)
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId() 
    local MatchState = MatchModel:GetMatchState()--MatchModel.Enum_MatchState.Matching
    local GetDisPlayState = MvcEntry:GetModel(UserModel):GetPlayerCacheState(PlayerId)
    local DisPlayState = (not GetDisPlayState or type(GetDisPlayState.DisplayStatus) == "number") and self.Model.Enum_PLAYER_CLIENT_HALL_STATE.Hall or GetDisPlayState.DisplayStatus
    if MatchState == MatchModel.Enum_MatchState.Matching then --匹配中状态高于大厅
        DisPlayState = "Matching"
    end
    local ViewId = self.Model:GetNowViewId()

    local info_index = InHeroData.info_index or 0
    local hero_id = InHeroData.hero_id or 0
    local action = InHeroData.action or self.Model.CLICKHEROACTSCENE.HALL
    local into_type = InHeroData.into_type or "animation"
    if InHeroData.action == self.Model.CLICKHEROACTSCENE.READ then
        local ReadData = self.Model:GetHeroReadData()
        info_index = ReadData.info_index
        hero_id = ReadData.hero_id
        into_type = ReadData.into_type
    end

    local FavorValue = FavorabilityModel:GetCurFavorValue(hero_id)
    local CurFavorLevel = FavorabilityModel:GetCurFavorLevel(hero_id)

    local JsonValue = {
            ["hero_id"] = InHeroData.hero_id, --英雄Id
            ["current_favor_lv"] = CurFavorLevel, --当前好感度等级
            ["current_favor"] = FavorValue, --当前好感度
            ["action"] = action, --203308101-戳英雄,203308111-阅读英雄故事 
            ["refer_source_page_uuid"] = GetLocalTimestamp() .. PlayerId,
            ["refrence"] = self.Model:GetUpperLayer(), --上级界面(fct_type + fct_tab) 已存在,询问接口
            ["game_status"] = DisPlayState, --gaming-对局中,matching-匹配中,lobby-大厅,checkout-结算界面。
            ["game_scene"] = InHeroData.action == self.Model.CLICKHEROACTSCENE.READ and ViewConst.FavorablityMainMdt or ViewConst.Hall, --完成时的界面
            ["into_type"] = into_type, --访问的界面类型(text,animation)
            ["info_index"] = info_index, --文本第几页，或者滚动列表文本获取进度百分比
            ["duration"] = InHeroData.action == self.Model.CLICKHEROACTSCENE.READ and self.Model:GetHeroViewDuration() or 0, --阅读时长
            ["is_skip"] = InHeroData.is_skip or 0, --是否跳过(针对动画,目前暂不处理,传0)
            ["is_interrupt"] = (DisPlayState ~= self.Model.Enum_PLAYER_CLIENT_HALL_STATE.Hall and DisPlayState ~= self.Model.Enum_PLAYER_CLIENT_HALL_STATE.HallFavor) and 1 or 0, --是否被打断(匹配成功被动转场或主动跳转到其它界面0)
            ["interrupt_detail"] = (DisPlayState == self.Model.Enum_PLAYER_CLIENT_HALL_STATE.Hall or DisPlayState == self.Model.Enum_PLAYER_CLIENT_HALL_STATE.HallFavor) and "0" or "" .. DisPlayState, --打断细节,同PlayerState 
            
    }
    UE.UBuryReportSubsystem.SendBuryByContext(GameInstance, nil, "hero_info_interact", CommonUtil.JsonSafeEncode(JsonValue))
end

--[[需要在商店模块点击事件等调用
    local InShopData : table = {
        ProductId: any,
        ProductType: any,
        ShopId: any,
        pageId: any,
    }
]]
function EventTrackingCtrl:ReqOnShopInteract(InShopData)
    if not self.IsOpen then return end
    local IsInDetailView = MvcEntry:GetModel(ViewModel):GetState(ViewConst.ShopDetail)
    local ShopModel = MvcEntry:GetModel(ShopModel)

    local GetTabIndex = 0--MvcEntry:GetModel(ShopModel):GetCurSelectTabIndex() 
    local isShowInDetail = InShopData.isShowInDetail--GetTabIndex and (GetTabIndex .. "-" .. (IsInDetailView and "1" or "0")) or 0
    local CurTabIndex = ShopModel:GetCurTabIndex() or 1

    --[[
        日志中CurTabIndex == 2下product_id存在一个100001得值，但跟踪下来没发现断点有存在这个情况，先针对性屏蔽下，关注一下问题先
    ]]
    if CurTabIndex == 2 and InShopData.product_id == 100001 then
        return
    end

    local JsonValue = {
            ["action"] = InShopData.action,
            ["product_id"] = InShopData.product_id, --商品Id
            ["belong_product_id"] = InShopData.belong_product_id, --是否为捆绑包下商品
            ["shop_id"] = 4, --商店Id
            ["tab_index"] = CurTabIndex .. "-" .. isShowInDetail, --商店页码
            ["product_index"] = InShopData.product_index, --商店页码
            ["buy_type"] = InShopData.buy_type, --商店页码
    }
    UE.UBuryReportSubsystem.SendBuryByContext(GameInstance, nil, "shop_interact_flow", CommonUtil.JsonSafeEncode(JsonValue))
end


--[[
    转化率埋点上报
]]
function EventTrackingCtrl:ReqOnStepFlow(StepType)
    self.LastReprotStepData = self.LastReprotStepData or {StepType = 0}
    local LastReportStepId = self.LastReprotStepData.StepType
    if StepType <= LastReportStepId then
        return
    end

    local LastConversionStepData = SaveGame.GetItem("LastConversionStepData",true) or {}
    local LastConversionStepId = LastConversionStepData and LastConversionStepData.StepType or 0
    local IsFirst = true
    if StepType <= LastConversionStepId then
        IsFirst = false
    end
    if LastReportStepId > 0 then
        for i=LastReportStepId+1,(StepType-1) do
            self:_ReqOnStepFlow(i,true,IsFirst)
        end
    end
    self:_ReqOnStepFlow(StepType,false,IsFirst)
end

function EventTrackingCtrl:_ReqOnStepFlow(StepType, IsSkip,IsFirst)
    if not self.IsOpen then return end
    CWaring("EventTrackingCtrl:ReqOnStepFlow:" .. StepType .. "|IsSkip:" .. (IsSkip and "1" or "0") .. "|IsFirst:" .. (IsFirst and "1" or "0"))
    local duration = 0
    local CTime = GetLocalTimestamp()
    if not IsSkip then
        -- local LastReportStepId = self.LastReprotStepData and self.LastReprotStepData.StepType or 0
        local LastReptorTime = self.LastReprotStepData and self.LastReprotStepData.StepTime or 0

        if LastReptorTime > 0 then
            duration = CTime - LastReptorTime
        end

        self.LastReprotStepData = self.LastReprotStepData or {}
        self.LastReprotStepData.StepType = StepType
        self.LastReprotStepData.StepTime = CTime
    end
    if IsFirst and not IsSkip then
        local LastConversionStepData = SaveGame.GetItem("LastConversionStepData") or {}
        LastConversionStepData.StepType = StepType
        LastConversionStepData.StepTime = CTime
        SaveGame.SetItem("LastConversionStepData", LastConversionStepData,true)
    end


    local LoginModel = MvcEntry:GetModel(LoginModel)

    local LoginDeviceInfo = LoginModel:GetLoginDeviceInfo()
    local LoginClientInfo = LoginModel:GetLoginClientInfo()
    local LoginAccountInfo = LoginModel:GetLoginAccountInfo()
    local LoginLocationInfo = LoginModel:GetLoginLocationInfo()

    local JsonValue = {
            ["login_channel"] = LoginAccountInfo.ChannelId,
            ["step_id"] = StepType, --步骤Id （1-14，枚举，对应表格登陆前置步骤拆分）
            ["is_skip"] = IsSkip and 1 or 0, --是否跳过
            ["is_first"] = IsFirst and 1 or 0, --是否首次上报
            ["duration"] = duration, --持续时间
            ["force_sdk"] = 1,   --给内部接口用的，标识强制走SDK上报
            ["gpu"] = LoginDeviceInfo.GLRender, 
            ["cpu"] = LoginDeviceInfo.CpuHardware, 
    }
    UE.UBuryReportSubsystem.SendBuryByContext(GameInstance, nil, "step_flow", CommonUtil.JsonSafeEncode(JsonValue))
end

--[[
    Icon点击流水
]]
function EventTrackingCtrl:ReqIconClicked(InIconData)
    if not self.IsOpen or not InIconData then return end
    local JsonValue = InIconData--self.Model:GetUIClickedList()
    UE.UBuryReportSubsystem.SendBuryByContext(GameInstance, nil, "icon_click_flow", CommonUtil.JsonSafeEncode(JsonValue))
    --self.Model:ClearUIClickedList()
end

function EventTrackingCtrl:SetVoiceStart()
    if not self.IsOpen or MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then --局内不处理
        return
    end
    self.Model:SetVoiceIsStart()
end


function EventTrackingCtrl:ReqVoiceFlow(InVoiceLevel)
    if not self.IsOpen or MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then --局内不处理
        return
    end
    local SystemMenuModel = MvcEntry:GetModel(SystemMenuModel)
    local voice_duration = self.Model:GetVoiceDuration()
    local voice_channel = SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceChannel) == true and 1 or 2
    local voice_input_type = SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceMode) == true and 1 or 2
    local JsonValue = {
        ["voice_scene"] = self.Model.VOICESCENE.OUTSIDEGAME, --语音场景(1-局内，2-局外)
        ["voice_channel"] = voice_channel,--self.Model:GetUpperLayer(), --语音频道，需要提供映射表。
        ["voice_input_type"] = voice_input_type, --语音输入类型(1-按键说话，2-自由说话)
        ["voice_duration"] = voice_duration, --本次语音输入时长
    }
    UE.UBuryReportSubsystem.SendBuryByContext(GameInstance, nil, "voice_flow", CommonUtil.JsonSafeEncode(JsonValue))
end

function EventTrackingCtrl:ReqFriendFlow(InAction)
    if not self.IsOpen then
        return
    end

    local TeamModel = MvcEntry:GetModel(TeamModel)
    local FriendModel = MvcEntry:GetModel(FriendModel)
    local FriendBlackList = MvcEntry:GetModel(FriendBlackListModel)
    local TeamId = TeamModel:GetTeamId()
    local FriendsNum = FriendModel:GetAllFriendNum()
    local BlackListCount, BlackIdList = FriendBlackList:GetBlackList()
    local PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    local friend_refer_source = self.Model:GetFriendAddSource(InAction.playerId, false, InAction.bIsClear)
    if friend_refer_source < 1 then
        return
    end

    local JsonValue = {
        ["action"] = InAction.action, --101506101-申请好友，101506102-通过申请，101506103-拒绝申请，101506111-删除好友，101506112-拉黑，101506113-移除拉黑
        ["target_role_id"] = InAction.playerId, --操作对象的role_id
        ["friend_refer_source"] = friend_refer_source, --来源
        ["team_uuid"] = TeamId, --队伍Id
        ["friend_num"] = FriendsNum,   --当前已有的好友数量（包含通过的这一个）
        ["blacklist_num"] = #BlackListCount,   --当前已经拉黑的人员数量（包含拉黑的这一个）
        ["relation"] = self.Model:GetFriendAddSourceByTeam() --发起人和目标人之间关系
    }
    UE.UBuryReportSubsystem.SendBuryByContext(GameInstance, nil, "friend_flow", CommonUtil.JsonSafeEncode(JsonValue))
end

--[[
    afk_flow挂机流水
]]
function EventTrackingCtrl:ReqAfkFlow(InEventKey)
    if not self.IsOpen then
        return
    end

    local Duration = self.Model:GetAfkDuration()
    if Duration < 180 then --挂机不满3分钟不上报
        return
    end
    
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = UserModel:GetPlayerId() 
    local GetDisPlayState = UserModel:GetPlayerCacheState(PlayerId)
    local DisPlayState = GetDisPlayState and GetDisPlayState.DisplayStatus or nil

    local JsonValue = {
        ["game_status"] = DisPlayState,
        ["afk_duration"] = Duration
    }
    UE.UBuryReportSubsystem.SendBuryByContext(GameInstance, nil, "afk_flow", CommonUtil.JsonSafeEncode(JsonValue))
end

--[[
    loading界面日志埋点
]]
function EventTrackingCtrl:ReqLoadingFlow(InIsOpenLodingView)
    if not self.IsOpen then
        return
    end

    if InIsOpenLodingView == EventTrackingModel.OpenType.OnShow then
        self.Model:UpdateLoadingDurationNowTime()
    end

    local CustomRoomModel = MvcEntry:GetModel(CustomRoomModel)
    --local GameId = MvcEntry:GetModel(HallSettlementModel):GetGameId()
    local TheUserModel = MvcEntry:GetModel(UserModel)

    local JsonValue = {
        ["loading_action"] = InIsOpenLodingView, --1-打开，0-关闭
        ["loading_duration"] = InIsOpenLodingView == EventTrackingModel.OpenType.OnShow and 0 or self.Model:GetLoadingDurationNowTime(),
        ["game_uuid"] = TheUserModel:GetDSGameIdShow(),
        ["loading_type"] = self.Model:GetLoadingType() == LoadingCtrl.TypeEnum.BATTLE_TO_HALL and "settlement_loading" or "begin_loading",
        ["player_cnt"] = CustomRoomModel and CustomRoomModel:GetCurEnterRoomPlayerNum() or 0
    }
    UE.UBuryReportSubsystem.SendBuryByContext(GameInstance, nil, "loading_flow", CommonUtil.JsonSafeEncode(JsonValue))
end

