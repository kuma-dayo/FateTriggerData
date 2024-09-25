--[[
    大厅侧边菜单栏界面
]]
require("Client.Modules.Team.Common.TeamSideBarLogic")
require("Client.Modules.Chat.ChatInputBarLogic")


local class_name = "TeamAndChatMdt";
TeamAndChatMdt = TeamAndChatMdt or BaseClass(GameMediator, class_name);

function TeamAndChatMdt:__init()
end

function TeamAndChatMdt:OnShow(data)
    
end

function TeamAndChatMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")
-- 需要展示此界面的配置
--[[
    配置参数例子
    [ViewConst.Example] = {
        ShowSelfHead = true, -- 是否将自己的头像展示为大头像，默认为true
        TeamSideBarParam = {
            Scale = 0.5,    -- 侧边栏缩放，默认为 0.54 （大厅显示样式）
            Padding = -60   -- 侧边栏头像间距， 默认为-80   （大厅显示样式）
        }
        IsHideChat = false -- 是否隐藏聊天框 默认为 false
    }
]]
local TeamAndChatConfigs = {}
local BigHeadIconConfigs = {}

function M:OnInit()
    TeamAndChatConfigs = {
        -- 大厅不同切页，是否需要展示的配置由 CommonHallTab 的 tabList 中的 IsShowSideBar 字段控制
        [ViewConst.Hall] = {},
        [ViewConst.Chat] = {},
        [ViewConst.HeroDetail] = {},
        [ViewConst.HeroPreView] = {},
        [ViewConst.WeaponDetail] = {},
        [ViewConst.WeaponSkin] = {},
        [ViewConst.FriendMain] = {},
        [ViewConst.DepotMain] = {},
        [ViewConst.MatchModeSelect] = {},
        [ViewConst.FriendManagerMain] = {},
        [ViewConst.FriendManagerLog] = {},
        [ViewConst.ShopDetail] = {},
        [ViewConst.HallSettlement] = {},
        [ViewConst.PlayerInfo] = {},
        [ViewConst.MatchHistoryDetail] = {},
        [ViewConst.VehicleDetail] = {},
        [ViewConst.VehicleDetailVideo] = {},
        [ViewConst.SeanLotteryPrizePreview] = {},
        [ViewConst.RankSystemMain] = {},
        [ViewConst.VehicleSkin] = {},
        [ViewConst.VehicleSkinSticker] = {},
        [ViewConst.VehicleSkinStickerFull] = {},
        [ViewConst.HeroSkillPreView] = {},
        [ViewConst.FavorablityMainMdt] = {},
    }

    BigHeadIconConfigs = {
        -- 是否需要展示大头像
        [ViewConst.Hall] = {},
        [ViewConst.Chat] = {},
        [ViewConst.FriendMain] = {},
        [ViewConst.MailMain] = {},
        [ViewConst.ItemGet] = {},
        [ViewConst.SpecialItemGet] = {},
    }
    self.BindNodes = 
    {
        { UDelegate = self.Btn_Friend.OnClicked,					            Func = self.BtnFriend_Click_Func },
        { UDelegate = self.OnAnimationFinished_vx_hall_in_teamchat,	            Func = self.On_vx_hall_in_teamchat_Finished },
        { UDelegate = self.OnAnimationFinished_vx_hall_match_success_teamchat,	Func = self.On_vx_hall_match_success_teamchat_Finished },

        { UDelegate = self.OnAnimationFinished_vx_hall_tab_play,	            Func = self.On_OnAnimationFinished_vx_hall_tab_play_Finished },
        { UDelegate = self.OnAnimationFinished_vx_hall_tab_team,	            Func = self.On_OnAnimationFinished_vx_hall_tab_team_Finished },

        { UDelegate = self.Btn_Level.OnClicked,					                Func = self.OnButtonClicked_Level },
        { UDelegate = self.Btn_Level.OnHovered,                                 Func = self.OnButtonOnHovered_Level },
        { UDelegate = self.Btn_Level.OnUnhovered,                               Func = self.OnButtonUnhovered_Level },

        { UDelegate = self.BtnExit.OnClicked,					                Func = self.OnButtonClicked_QuitTeam },
    }
    self.MsgList = {
        -- 这里监听界面打开关闭要比其他地方监听优先级高，避免有其他地方监听关闭的同时执行打开另一个界面，打开完这边再触发，就无法准确计算好层级
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED,    Func = self.OnOtherViewShowed , Priority = 1},
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,  Func = self.OnOtherViewClosed , Priority = 1},

		{Model = HallModel,  MsgName = HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE, Func = self.On_TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_Func},
		{Model = HallModel,  MsgName = HallModel.SET_TEAMANDCHAT_VISIBLE, Func = self.SET_TEAMANDCHAT_VISIBLE_Func},
		{Model = MatchModel, MsgName = MatchModel.ON_MATCH_IDLE,                          Func = self.ON_MATCH_IDLE_Func},
		{Model = MatchModel, MsgName = MatchModel.ON_DS_ERROR,                          Func = self.ON_DS_ERROR_Func},
		{Model = MatchModel, MsgName = MatchModel.ON_MATCH_SUCCESS,                     Func = self.ON_GAMEMATCH_SUCCECS_Func},
		{Model = TeamModel,  MsgName = TeamModel.ON_TEAM_LEADER_CHANGED,				Func = self.OnTeamLeaderChanged },
        {Model = TeamModel,  MsgName = TeamModel.ON_ADD_TEAM_MEMBER,					Func = self.OnTeamLeaderChanged },
		{Model = TeamModel,  MsgName = TeamModel.ON_DEL_TEAM_MEMBER,					Func = self.OnTeamLeaderChanged },
        {Model = TeamModel,  MsgName = TeamModel.ON_CLOSE_TEAM_AND_CHAT_VIEW_BY_ACTION,					Func = self.OnCloseViewByAction },
        {Model = TeamModel,  MsgName = TeamModel.ON_NOTIFY_TEAM_AND_CHAT_IN_OR_OUT_BY_ACTION,					Func = self.PlayDynamicEffectOnShow },

        {Model = UserModel,  MsgName = UserModel.ON_PLAYER_LV_CHANGE,					Func = self.OnPlayerLvChanged },
        {Model = TeamModel,  MsgName = TeamModel.ON_TEAM_INFO_CHANGED,					Func = self.UpdateQuitTeamBtnShow },
        {Model = CommonModel,  MsgName = CommonModel.ON_HALL_TAB_SWITCH_COMPLETED,	    Func = self.ON_HALL_TAB_SWITCH_COMPLETED_func },  --大厅场景切换完成
        {Model = UserModel, MsgName = UserModel.ON_MODIFY_NAME_SUCCESS,                 Func = self.ON_MODIFY_NAME_SUCCESS_func},

        {Model = ChatModel, MsgName = ChatModel.ON_SELECT_CHANNEL_CHANGED, Func = self.ON_SELECT_CHANNEL_CHANGED_func},
    }
    
    -- 因为此界面不参与GetOpenView接口获取的特殊性，所以InputModel无法通过LastViewId来判断此界面是否处于最顶层。
    -- 将输入路由关闭，由自身设置可见性时，动态的注册和移除按键监听
    self.InputFocus = false
    self.InputMsgList = {
		{Model = InputModel, 	MsgName = ActionPressed_Event(ActionMappings.Tab), 		Func = self.OnTabClick },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Enter),       Func = self.OnEnterClick},
    }
    self.DefaultTeamSideBarParam = {Scale = 0.54,Padding = -84}
    -- 当前等级
    self.CurLevel = 1
    -- 是否满级
    self.IsMaxLevel = false
    -- 当前退出队伍按钮的状态
    self.QuitTeamBtnState = false
    self:RegisterRedDot()
end

--[[
    Data = {
        NeedDisplay = true,         --当不为nil时，覆盖内部的判断显示隐藏的逻辑，true为显示，false为隐藏
        NeedPlayDisplayAnim = true, --当为true时会在显示延迟TeamAndChat界面时播放动画
        FromView -- 从哪个界面打开的，用于层级判断变动筛选。如果和父级界面同一帧打开，会收到父级界面的OnViewShowed
    }
--]]
function M:OnShow(Data)
    CLog(string.format("TeamAndChatMdt:M:OnShow Data = %s",table.tostring(Data)))
    self.IsVisible = true
    self.IsVisibleFromOutsize = true
    self.IsMatchingSuccess = false
    self.FromViewId = Data.FromView or ViewConst.Hall
    self:UpdateLevelData()
    self:UpdatePlayerName()
    self:ResetToDefault(Data)
end

function M:OnHide()
    CLog(string.format("TeamAndChatMdt:M:OnHide"))

    self.PlayerHeadCls = nil
    CommonUtil.MvcMsgRegisterOrUnRegister(self,self.InputMsgList,false)
end

function M:OnRepeatShow(Data)
    CLog(string.format("TeamAndChatMdt:M:OnRepeatShow Data = %s",table.tostring(Data)))
end

-- 由 自己内部 控制调用，显示时调用，重新注册按键监听事件
function M:OnCustomShow()
    CLog(string.format("TeamAndChatMdt:M:OnCustomShow"))

    if self.IsHide ~= false and self.InputMsgList then
		CommonUtil.MvcMsgRegisterOrUnRegister(self,self.InputMsgList,true)
        self.IsHide = false
    end
end

-- 由 自己内部 控制调用，隐藏时调用，销毁按键监听事件
function M:OnCustomHide()
    CLog(string.format("TeamAndChatMdt:M:OnCustomHide"))

    if self.InputMsgList then
	    CommonUtil.MvcMsgRegisterOrUnRegister(self,self.InputMsgList,false)
    end
    self.IsHide = true
end

-- 更新等级信息
function M:UpdateLevelData()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    self.CurLevel = UserModel:GetPlayerLvAndExp()
    self.IsMaxLevel = UserModel:CheckIsMaxLevel()
end

--[[
    Param = {
        NeedDisplay = true,         --当不为nil时，覆盖内部的判断显示隐藏的逻辑，true为显示，false为隐藏
        NeedPlayDisplayAnim = true, --当为true时会在显示延迟TeamAndChat界面时播放动画
    }
--]]
---@param Param table 包含重置回初始化状态时的一些基础参数
function M:ResetToDefault(Param)
    -- 默认状态为大厅
    local DefaultViewId = ViewConst.Hall
    local IsShow, bNeedPlayAnim = false, false
    local Mdt = MvcEntry:GetCtrl(ViewRegister):GetView(DefaultViewId)
    if Mdt and Mdt.view then
        IsShow = Mdt.view:GetIsShowSidebar()
    end

    if Param then
        if Param.NeedDisplay ~= nil then IsShow = Param.NeedDisplay end
        if Param.NeedPlayDisplayAnim then bNeedPlayAnim = Param.NeedPlayDisplayAnim end
    end
    
    --除非特殊要求播放动画，一般直接显示就好
    self:SetSelfVisibility(IsShow, bNeedPlayAnim)
    
    if IsShow then
        local DefaultConfig = TeamAndChatConfigs[ViewConst.Hall]
        self:UpdateShowStatus(DefaultConfig)
        self:SetSelfVisibility(true)
        self:AdjustZOrder(2)    -- 默认在HallMdt之上
        self:UpdateLightImage()
        self:UpdateLevelShow()
        self:UpdateQuitTeamBtnShow()
    end
end

function M:UpdateShowStatus(ShowConfig)
    -- HeadIcon and TeamSideBar
    local IsShowSelfHead = ShowConfig.ShowSelfHead ~= false
    self.MineInfo:SetVisibility(IsShowSelfHead and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if IsShowSelfHead then
        self:UpdatePlayerHeadClsShow()
    end
    local TeamSideBarParam = ShowConfig.TeamSideBarParam or self.DefaultTeamSideBarParam
    TeamSideBarParam.IsHideSelf = IsShowSelfHead
    if not self.TeamSideBarLogic then
        self.TeamSideBarLogic = UIHandler.New(self,self.WBP_TeamSideBar, TeamSideBarLogic, TeamSideBarParam).ViewInstance
    else
        self.TeamSideBarLogic:UpdateUI(TeamSideBarParam)
    end
    
    -- ChatInputBar
    if ShowConfig.IsHideChat then
        self.WBP_ChatInput:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.WBP_ChatInput:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local ChatInputBarParam = {
        -- TODO
    }
    if not self.ChatInputBarLogic then
        self.ChatInputBarLogic = UIHandler.New(self,self.WBP_ChatInput, ChatInputBarLogic, ChatInputBarParam).ViewInstance
    else
        self.ChatInputBarLogic:UpdateUI(ChatInputBarParam)
    end
end

-- 初始化头像组件
function M:InitPlayerHeadCls()
    if not self.PlayerHeadCls then
        local Param = self:GetPlayerHeadParam()
        self.PlayerHeadCls = UIHandler.New(self,self.WBP_CommonHeadIcon, CommonHeadIcon, Param).ViewInstance
    end
    if not self.SmallPlayerHeadCls then
        local Param = self:GetPlayerHeadParam()
        self.SmallPlayerHeadCls = UIHandler.New(self,self.MyselfSmallHeadIcon, CommonHeadIcon, Param).ViewInstance
    end
end

-- 获取头像参数
function M:GetPlayerHeadParam()
    local Param = {
        PlayerId = MvcEntry:GetModel(UserModel).PlayerId,
        -- OnItemClick = Bind(self,self.OnSelfHeadClick),
        IsCaptain = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain(),
        ShowLevel = false,
        ShowUpAni = false,
        ClickOpenPersonal = true,
    }
    return Param
end

-- 更新玩家头像组件展示
function M:UpdatePlayerHeadClsShow()
    self:InitPlayerHeadCls()
    -- 主场景&页签为开始游戏&没有其他弹窗
    local IsBigHead = true
    local HallTabType = MvcEntry:GetModel(HallModel):GetCurHallTabType()
    local IsHallTabPlay = HallTabType == CommonConst.HL_PLAY
    if IsHallTabPlay then
        local ViewModel = MvcEntry:GetModel(ViewModel) 
        local PopOpenList = ViewModel:GetOpenList(UIRoot.UILayerType.Pop)
        if PopOpenList and #PopOpenList > 0 then
            for Index, TopPopView in ipairs(PopOpenList) do
                local Config = BigHeadIconConfigs[TopPopView.viewId]
                if not Config then
                    IsBigHead = false
                    break
                end
            end
        end
    else 
        IsBigHead = false
    end
    if self.CurrentIsBigHead ~= IsBigHead then
        self.CurrentIsBigHead = IsBigHead
        -- 状态有变化 需要刷新一下头像组件
        local NeedUpdateHeadCls = self.CurrentIsBigHead and self.PlayerHeadCls or self.SmallPlayerHeadCls
        if NeedUpdateHeadCls then
            local Param = self:GetPlayerHeadParam()
            NeedUpdateHeadCls:UpdateUI(Param, false)
        end

        if self.CurrentIsBigHead then
            if self.VXE_Hall_TeamBar_TabPlay_In then
                self:VXE_Hall_TeamBar_TabPlay_In()
            end
        else
            if self.VXE_Hall_TeamBar_TabPlay_Out then
                self:VXE_Hall_TeamBar_TabPlay_Out()
            end
        end
    end
end

function M:GetCurChatInputAbsolutePos()
    if CommonUtil.IsValid(self.WBP_ChatInput) then
        local AbsolutePos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.WBP_ChatInput:GetCachedGeometry(), UE.FVector2D(0,0))
        return AbsolutePos
        -- MvcEntry:GetModel(ChatModel):SetCurChatInputPos(ViewportPos) 
    end
    return nil
end

-- 激活态背景条 （仅在好友界面ViewConst.FriendMain 打开时，显示）
function M:UpdateLightImage(ViewId,IsActive)
    local IsShow = false
    if IsActive and ViewId and ViewId == ViewConst.FriendMain then
        IsShow = true
    end
    -- 新版ui不需要这个。先屏蔽。到时接入在处理
    -- self.Light:SetVisibility(IsShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-- 更新等级按钮展示
function M:UpdateLevelShow()
    self:RemoveAllActiveWidgetStyleFlags()
    local UseFlags = self.IsMaxLevel and 7 or 5
    self:AddActiveWidgetStyleFlags(UseFlags)
    self.Text_Level:SetText(StringUtil.FormatSimple(self.CurLevel))
end

-- 更新退出队伍按钮展示
function M:UpdateQuitTeamBtnShow()
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsShowBtn = TeamModel:IsSelfInTeam()
    if self.QuitTeamBtnState ~= IsShowBtn then
        self.QuitTeamBtnState = IsShowBtn
        if self.QuitTeamBtnState then
            if self.VXE_Hall_TeamBar_Team_In then
                self:VXE_Hall_TeamBar_Team_In()
            end
        else
            if self.VXE_Hall_TeamBar_Team_Out then
                self:VXE_Hall_TeamBar_Team_Out()
            end
        end
    end
end

-- 更新玩家自己的名字显示
function M:UpdatePlayerName(ViewId)
    if not ViewId or ViewId == ViewConst.FriendMain or ViewId == ViewConst.Chat then
        local IsShow = true
        if MvcEntry:GetModel(ViewModel):GetState(ViewConst.FriendMain) then
            IsShow = false
        elseif MvcEntry:GetModel(ViewModel):GetState(ViewConst.Chat) then
            IsShow = MvcEntry:GetModel(ChatModel):GetCurChatType() ~= Pb_Enum_CHAT_TYPE.PRIVATE_CHAT
        end
        self.LbName:SetVisibility(IsShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        local PlayerName = MvcEntry:GetModel(UserModel):GetPlayerName()
        local ShowName = StringUtil.SplitPlayerName(PlayerName)
        self.LbName:SetText(StringUtil.Format(ShowName))
    end
end

function M:ON_HALL_TAB_SWITCH_COMPLETED_func()
    self:UpdatePlayerHeadClsShow()
end

function M:ON_MODIFY_NAME_SUCCESS_func()
    self:UpdatePlayerName()
end

function M:ON_SELECT_CHANNEL_CHANGED_func()
    self:UpdatePlayerName()
end

-- 玩家等级更新回调
function M:OnPlayerLvChanged()
    self:UpdateLevelData()
    self:UpdateLevelShow()
end

--队长变动，检测头像是否展示队长标识
function M:OnTeamLeaderChanged()
	if self.PlayerHeadCls then
		self.PlayerHeadCls:UpdateCaptainFlag(MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain())
	end
end
--恢复等待匹配状态
function M:ON_MATCH_IDLE_Func()
    if self.IsMatchingSuccess then
        self:ON_DS_ERROR_Func()
    end
end
---进入DS失败
function M:ON_DS_ERROR_Func()
    self.IsMatchingSuccess = false
    self:SetSelfVisibility(true, true)
end
-- 匹配成功
function M:ON_GAMEMATCH_SUCCECS_Func()
    self.IsMatchingSuccess = true
    self:SetSelfVisibility(false, true)
end

---VirtualHallMdt 播放LS控制UI显隐
-- IsVisible
---@param IsVisible boolean 需要控件显示与否
function M:On_TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_Func(IsVisible)
    self.IsVisibleFromOutsize = IsVisible   -- 从外部设置的显隐
    -- 这里IsVisible为false时，直接隐藏不播动效
    self:SetSelfVisibility(IsVisible, IsVisible) 
end

function M:SET_TEAMANDCHAT_VISIBLE_Func(IsVisible)
    self:SetSelfVisibility(IsVisible, false) 
end

---封装一个接口，处理显示隐藏控件逻辑，及是否需要播放动画
---@param IsVisible boolean 是否需要显示控件
---@param IsPlayAnim boolean 是否需要播放动画
function M:SetSelfVisibility(IsVisible, IsPlayAnim)    
    self.IsVisible = IsVisible
    if IsPlayAnim then
        self:StopAnimation(self.vx_hall_in_teamchat)
        self:StopAnimation(self.vx_hall_match_success_teamchat)
        local AnimName = IsVisible and "vx_hall_in_teamchat" or "vx_hall_match_success_teamchat"
        -- local Speed = IsPlayAnim and 1 or 999
        self:PlayAnimation(self[AnimName], 0, 1, 0, 1)
        if IsVisible then self.PanelContent:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
    else
        if IsVisible then
            self.PanelContent:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self:OnCustomShow()
        else
            self:StopAnimation(self.vx_hall_in_teamchat)
            self:StopAnimation(self.vx_hall_match_success_teamchat)
            self:OnCustomHide()
            self.PanelContent:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function M:On_vx_hall_in_teamchat_Finished()
    if not self.IsVisible then
        CLog("== TeamAndChatMdt On_vx_hall_in_teamchat_Finished But Self Is Need Invisible!")
        self.PanelContent:SetVisibility(UE.ESlateVisibility.Collapsed)
        return 
    end
    self:OnCustomShow()
end

function M:On_vx_hall_match_success_teamchat_Finished()
    self:OnCustomHide()
    self.PanelContent:SetVisibility(UE.ESlateVisibility.Collapsed)
end

-- 切换头像相关动画播放完成 
function M:On_OnAnimationFinished_vx_hall_tab_play_Finished()
    -- 动画播放完成 派发更新位置事件
    MvcEntry:GetModel(ChatModel):DispatchType(ChatModel.ON_UPDATE_CHAT_POSITION)
end

-- 组队按钮相关动画播放完成 
function M:On_OnAnimationFinished_vx_hall_tab_team_Finished()
    -- 动画播放完成 派发更新位置事件
    MvcEntry:GetModel(ChatModel):DispatchType(ChatModel.ON_UPDATE_CHAT_POSITION)
end

-- 等级按钮点击
function M:OnButtonClicked_Level()
    MvcEntry:OpenView(ViewConst.PlayerLevelGrowthMdt)
end

-- 退出队伍按钮点击
function M:OnButtonClicked_QuitTeam()
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsSelfInTeam = TeamModel:IsSelfInTeam()
    if IsSelfInTeam then
        local IsMatching = MvcEntry:GetModel(MatchModel):IsMatching()
        if IsMatching then
            local msgParam = {
                describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "QuitTeamTip")),
                leftBtnInfo = {},
                rightBtnInfo = {
                    callback = function()
                        MvcEntry:GetCtrl(TeamCtrl):SendTeamQuitReq()
                    end
                }
            }
            UIMessageBox.Show(msgParam)
        else
            MvcEntry:GetCtrl(TeamCtrl):SendTeamQuitReq()
        end
    end
end

-- 等级按钮hover
function M:OnButtonOnHovered_Level()
    self:RemoveAllActiveWidgetStyleFlags()
    local UseFlags = self.IsMaxLevel and 8 or 6
    self:AddActiveWidgetStyleFlags(UseFlags)
end

-- 等级按钮unhover
function M:OnButtonUnhovered_Level()
    self:RemoveAllActiveWidgetStyleFlags()
    local UseFlags = self.IsMaxLevel and 7 or 5
    self:AddActiveWidgetStyleFlags(UseFlags)
end

--好友按钮点击，呼出好友主界面
function M:BtnFriend_Click_Func()
    self:OnTabClick()
end

--自己头像被点击
-- function M:OnSelfHeadClick()
--     -- TODO 暂时设为打开好友列表，后续根据需求修改
--     MvcEntry:OpenView(ViewConst.FriendMain)
-- end

--[[
	按下Tab,打开好友主界面
]]
function M:OnTabClick()
	-- if MvcEntry:GetModel(MatchModel):IsMatching() then --正在匹配中不弹出由按键响应的大厅模块界面
	-- 	return
	-- end
    if not self:CheckZOrderForInput() then
        return
    end

    if self.IsMatchingSuccess then
        -- 匹配成功情况下不需响应
        return
    end
    -- 特殊处理 监听聊天界面关闭，需要切换聊天框显示状态
    if ViewId == ViewConst.Chat and self.ChatInputBarLogic then
        self.ChatInputBarLogic:SwitchToState()
        return
    end

    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.FriendMain) then
        --MvcEntry:CloseView(ViewConst.FriendMain)
        MvcEntry:GetModel(FriendModel):DispatchType(FriendModel.ON_CLOSE_FRIENDVIEW_BY_ACTION)
        
    else
        MvcEntry:OpenView(ViewConst.FriendMain)
        self:InteractRedDot()
    end
end

--[[
    按下enter，响应聊天
]]
function M:OnEnterClick()
    if not self:CheckZOrderForInput() then
        CLog("TeamAndChatMdt OnEnterClick CheckZOrderForInput ")
        return
    end
    if self.ChatInputBarLogic then
        self.ChatInputBarLogic:OnEnterFunc()
    end
end

--[[
    检查层级，决定是否响应按键
]]
function M:CheckZOrderForInput()
    if not self.IsVisibleFromOutsize then
        -- 外部设置隐藏期间不响应
        CLog("TeamAndChatMdt CheckZOrderForInput NotVisible Outside ")
        return false
    end
    -- 有dialog层存在时不响应按键
    local DialogCount = UIRoot.GetLayerChildCount(UIRoot.UILayerType.Dialog)
    if DialogCount > 0 then
        CLog("TeamAndChatMdt CheckZOrderForInput DialogCount ")
        return false
    end
    local CurZOrder = self.Slot:GetZOrder()
    local CurChildCount = UIRoot.GetLayerChildCount(UIRoot.UILayerType.Pop)
    if CurZOrder > CurChildCount then
        return true
    else
        CWaring("TeamAndChatMdt Receive Input, But CurZOrder is Lower! So Return")
        return false
    end
end

-- 调整自身的层级
function M:AdjustZOrder(TargetZOrder)
    if not TargetZOrder then
        local CurChildCount = UIRoot.GetLayerChildCount(UIRoot.UILayerType.Pop)
        TargetZOrder = CurChildCount + 1 
    end
    if self.Slot then
        self.Slot:SetZOrder(TargetZOrder)
    else
        CError("TeamAndChatMdt.AdjustZOrder slot nil",true)
        print_r(self)
        return
    end
end

-- 新界面打开后触发
function M:OnOtherViewShowed(ViewId)
    if not self.IsVisibleFromOutsize then
        -- 外部设置隐藏期间不响应
        CLog("== TeamAndChatMdt OnOtherViewShowed NotVisible Outside")
        return false
    end
    if ViewConstConfig[ViewId].UILayerType and ViewConstConfig[ViewId].UILayerType > UIRoot.UILayerType.Pop then
        -- Pop层往上的界面关闭，不影响界面展示
        return
    end
    if ViewId == self.FromViewId then
        CLog("== TeamAndChatMdt OnOtherViewShowed ParentView Show")
        return
    end

    if TeamAndChatConfigs[ViewId] then
        local Config = TeamAndChatConfigs[ViewId]
        self:SetSelfVisibility(true)
        self:UpdateShowStatus(Config)
        -- 调层级
        self:AdjustZOrder()
        -- self:UpdateLightImage(ViewId,true)
        self:UpdatePlayerName(ViewId)
        -- 特殊处理 监听聊天界面打开，需要切换聊天框为输入状态
        if ViewId == ViewConst.Chat and self.ChatInputBarLogic then
        CLog("TeamAndChatMdt OnOtherViewShowed SwitchToState ")
            self.ChatInputBarLogic:SwitchToState(ChatInputBarLogic.ShowState.Input)
        end
    --else
        -- 顶层界面不需要展示，保留当前显示状态和层级，无需改变
    end
end

-- 界面关闭后触发
function M:OnOtherViewClosed(ViewId)
    if not self.IsVisibleFromOutsize then
        -- 外部设置隐藏期间不响应
        CLog("== TeamAndChatMdt OnOtherViewClosed NotVisible Outside")
        return false
    end
    if self.IsMatchingSuccess then
        -- 匹配成功情况下不需响应
        CLog("== TeamAndChatMdt OnOtherViewClosed IsMatchingSuccess")
        return
    end
    -- 特殊处理 监听聊天界面关闭，需要切换聊天框显示状态
    if ViewId == ViewConst.Chat  and self.ChatInputBarLogic then
        self.ChatInputBarLogic:SwitchToState()
        -- return
    end
    if not ViewConstConfig or not ViewConstConfig[ViewId] then
        return
    end
    if ViewConstConfig[ViewId].UILayerType and ViewConstConfig[ViewId].UILayerType > UIRoot.UILayerType.Pop then
        -- Pop层往上的界面关闭，不影响界面展示
        return
    end
    if ViewId == self.FromViewId then
        CLog("== TeamAndChatMdt OnOtherViewClosed ParentView Closed")
        return
    end
    -- self:UpdateLightImage(ViewId,false)
    self:UpdatePlayerName(ViewId)
    local ViewModel = MvcEntry:GetModel(ViewModel) 
    local PopOpenList = ViewModel:GetOpenList(UIRoot.UILayerType.Pop)
    if PopOpenList and #PopOpenList > 0 then
        local TopPopView = PopOpenList[1]
        local Config = TeamAndChatConfigs[TopPopView.viewId]
        if Config then
            -- 界面关闭后， 当前最顶层界面，需要展示
            self:UpdateShowStatus(Config)
            self:SetSelfVisibility(true)
            self:AdjustZOrder()
        else
            -- 界面关闭后， 当前最顶层界面，不需要展示
            local SecondPopView = PopOpenList[2]
            if SecondPopView then
                if TeamAndChatConfigs[SecondPopView.viewId] then
                    -- 再下面一层需要展示，调整到和下面一层同个层级
                    self:UpdateShowStatus(TeamAndChatConfigs[SecondPopView.viewId])
                    self:SetSelfVisibility(true)
                    local CurChildCount = UIRoot.GetLayerChildCount(UIRoot.UILayerType.Pop)
                    self:AdjustZOrder(CurChildCount - 1)
                else
                    -- 最顶两层都不需要，隐藏自己
                    self:SetSelfVisibility(false)
                end
            else
                -- 没有下一层了，显示大厅状态
                self:ResetToDefault()
            end
        end
    else
        -- 上层没有界面了,重置回大厅状态
        self:ResetToDefault()
    end
end

-- 绑定红点
function M:RegisterRedDot()
    local RedDotKey = "TeamUp"
    local RedDotSuffix = ""
    if not self.ItemRedDot then
        self.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.ItemRedDot = UIHandler.New(self, self.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
    else 
        self.ItemRedDot:ChangeKey(RedDotKey, RedDotSuffix)
    end  

    RedDotKey = "LevelGrowth"
    RedDotSuffix = ""
    if not self.LevelRedDot then
        self.WBP_LevelRedDot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.LevelRedDot = UIHandler.New(self, self.WBP_LevelRedDot, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
    else 
        self.LevelRedDot:ChangeKey(RedDotKey, RedDotSuffix)
    end  
end

-- 红点触发逻辑
function M:InteractRedDot()
    if self.ItemRedDot then
        if MvcEntry:GetModel(NewSystemUnlockModel):IsSystemUnlock(ViewConst.FriendMain) then
            self.ItemRedDot:Interact() 
        end
    end
end

--[[
    播放显示退出动效
]]
function M:PlayDynamicEffectOnShow(InIsOnShow)
    local IsUnLucked = MvcEntry:GetModel(NewSystemUnlockModel):IsSystemUnlock(ViewConst.FriendMain, false)
    if not IsUnLucked then return end
    if InIsOnShow then
        if self.VXE_Hall_TeamBar_Open then
            self:VXE_Hall_TeamBar_Open()
        end
    else
        if self.VXE_Hall_TeamBar_Close then
            self:VXE_Hall_TeamBar_Close()
        end
    end
end


function M:OnCloseViewByAction()
    self:PlayDynamicEffectOnShow(false)
    MvcEntry:CloseView(ViewConst.TeamAndChat)
end

return M
