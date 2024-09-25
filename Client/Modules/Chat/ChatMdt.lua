--[[
    聊天主界面
]]

local class_name = "ChatMdt";
ChatMdt = ChatMdt or BaseClass(GameMediator, class_name);

function ChatMdt:__init()
end

function ChatMdt:OnShow(data)
end

function ChatMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = 
    {
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.GUIButton_Close_ClickFunc},
        {Model = ChatModel, MsgName = ChatModel.ON_RECEIVE_NEW_MSG, Func = self.OnReceiveNewMsg},
        {Model = ChatModel, MsgName = ChatModel.ON_RECEIVE_NEW_MSG_LIST, Func = self.OnReceiveNewMsgList},
        {Model = ChatModel, MsgName = ChatModel.ON_SEND_SUCCESS, Func = self.OnSendSuccess},
        {Model = ChatModel, MsgName = ChatModel.ON_SEND_FAILED, Func = self.OnSendFailed},
        {Model = ChatModel, MsgName = ChatModel.ON_DELETE_MSG, Func = self.OnDeleteMsg},
        {Model = FriendModel, MsgName = FriendModel.ON_ADD_FRIEND, Func =self.OnFriendListUpdated},
        {Model = FriendModel, MsgName = ListModel.ON_DELETED, Func =self.OnFriendListUpdated},
        {Model = FriendModel, MsgName = FriendModel.ON_PLAYERSTATE_CHANGED, Func =self.OnFriendStateChanged},
        -- {Model = TeamModel, MsgName = TeamModel.ON_SELF_QUIT_TEAM, Func = self.CheckIsInTeamType},
        {Model = TeamModel, MsgName = TeamModel.ON_GET_OTHER_TEAM_INFO, Func = self.OnGetOtherTeamInfo},
        {Model = UserModel, MsgName = UserModel.ON_QUERY_PLAYER_STATE_RSP, Func = Bind(self,self.OnQueryTeamState)},

        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED,    Func = self.OnOtherViewShowed },

        {Model = ChatEmojiModel, MsgName = ChatEmojiModel.ON_OPEN_EMOJI_PANEL, Func = self.OnOpenEmojiPanel},
        -- {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_INFO_HOVER_TIPS_CLOSED_EVENT, Func = self.OnHoverTipsClosed},
        {Model = ChatModel, MsgName = ChatModel.ON_UPDATE_CHAT_POSITION, Func = self.UpdatePosition},
    }

    self.BindNodes = 
    {
		{ UDelegate = self.GUIButton_Close.OnClicked,				    Func = self.GUIButton_Close_ClickFunc },
		{ UDelegate = self.Btn_NewMassage.OnClicked,				    Func = self.RefreshMsgContent },
		{ UDelegate = self.GUIButton_CloseEmoji.OnClicked,				    Func = self.OnHideEmojiPanel },
        { UDelegate = self.OnAnimationFinished_vx_hud_chat_message_out,	Func = Bind(self,self.On_vx_hud_chat_message_out_Finished) },
        { UDelegate = self.OnAnimationFinished_vx_hud_chat_friend_out,	Func = Bind(self,self.On_vx_hud_chat_friend_out_Finished) },
        { UDelegate = self.OnAnimationFinished_vx_hud_chat_emoji_out,	Func = Bind(self,self.On_vx_hud_chat_emoji_out_Finished) },
     
	}
    -- 聊天频道红点信息
    self.CONST_CHANNEL_REDDOT_INFO = {
        [Pb_Enum_CHAT_TYPE.PRIVATE_CHAT] = {
            RedDotKey = "ChatFriendTab",
            RedDotSuffix = "",
        },
        [Pb_Enum_CHAT_TYPE.TEAM_CHAT] = {
            RedDotKey = "ChatTeamTab",
            RedDotSuffix = "",
        },
    }

    self.ChatModel = MvcEntry:GetModel(ChatModel)
    self.ChatList:SetIsUpdateOffsetWhenMaxSizeChanged(true)
    self:InitChannelTab()
    self:InitFriendContent()
    self.CDTipsStr = self.ChatModel:GetSendCDErrorCodeTips()
    self.FriendListItem = {}
    self.CommonHeadIconCls = {}

    self.StateTextColor = {
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE] = {Hex = "C0BCB0",Opacity = 0.6},
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_SINGLE] = {Hex = "FF8E3E"},
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM] = {Hex = "FFC74F"},
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_MATCHING] = {Hex = "4DD033"},
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_GAMING] = {Hex = "C0BCB0"},
    }
    self.PlayerId2Index = {}
    self.QueryTeamPlayerIdList = {}
    self.QueryStatePlayerIdList = {}
    self.AutoTeamCheckTime = 1  -- 定时请求好友队伍状态的间隔时间
    self.RedDotWidgetList = {}
    self.IsClickTips = false
end

-- 初始化频道列表
function M:InitChannelTab()
    local ChannelList = self.ChatModel:GetShowChannelList()
    self.ChannelTabWidgetList = {}
    if ChannelList and #ChannelList > 0 then
        local ChannelTabParam = {
            ClickCallBack = Bind(self,self.OnChannelBtnClick),
            ValidCheck = Bind(self,self.OnChannelValidCheck),
            HideInitTrigger = true,
            -- IsOpenKeyboardSwitch = true,
        }
        ChannelTabParam.ItemInfoList = {}
        local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(ChatChannelTabUMGPath))
        for Index, ChannelInfo in ipairs(ChannelList) do
            local Widget = NewObject(WidgetClass, self)
            self.ChannelList:AddChild(Widget)
            if Index > 1 then
                Widget.Padding.Left = 6
                Widget:SetPadding(Widget.Padding)
            end
            -- 设置频道Icon
            local IconPath = ChannelInfo.IconPath
            CommonUtil.SetBrushFromSoftObjectPath(Widget.Image_Icon,IconPath)
            -- 设置HoverTips频道名称
            -- Widget.TextChannelName:SetText(StringUtil.Format(ChannelInfo.Name))
            -- 设置Hover事件
            Widget.GUIButton_TabBg.OnHovered:Add(self,Bind(self,self.OnChannelBtnHovered,Widget,ChannelInfo.Name))
            Widget.GUIButton_TabBg.OnUnhovered:Add(self,Bind(self,self.OnChannelBtnUnhovered))

            local RedDotInfo = self.CONST_CHANNEL_REDDOT_INFO[ChannelInfo.ChatType]
            local RedDotKey = RedDotInfo and RedDotInfo.RedDotKey or nil
            local RedDotSuffix = RedDotInfo and RedDotInfo.RedDotSuffix or nil
            local TabItemInfo = {
                Index = Index,
                Id = ChannelInfo.ChatType,
                Widget = Widget,
                LabelStr = ChannelInfo.Name,
                RedDotKey = RedDotKey,
                RedDotSuffix = RedDotSuffix,
            }
            ChannelTabParam.ItemInfoList[#ChannelTabParam.ItemInfoList + 1] = TabItemInfo
            self.ChannelTabWidgetList[ChannelInfo.ChatType] = Widget
        end
        self.TabListCls = UIHandler.New(self,self.ChannelList, CommonMenuTab,ChannelTabParam).ViewInstance
    end
end

-- 初始化好友列表相关内容
function M:InitFriendContent()
    -- 默认选中的好友Index
    self.SelectFriendIndex = 1
    -- 添加好友按钮
    UIHandler.New(self, self.CommonBtnTips_AddFriend, WCommonBtnTips, 
    {
        OnItemClick = Bind(self, self.GUIButton_AddFriend_ClickFunc),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatMdt_Addfriends_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.SpaceBar
    })
end

function M:OnShow(Param)
    self.Param  = Param or {}
    self:UpdatePosition()
    self:AddListeners()
    self.LastSelectChatType = 0
    self.LastSelectChannelItem = nil
    self.SelectChatType = self.ChatModel:GetCurChatType()
    if self.Param.TargetPlayerId then
        -- 指定跳转到私聊好友，强制切到私聊频道
        self.SelectChatType = Pb_Enum_CHAT_TYPE.PRIVATE_CHAT
    elseif self.Param.ChatType then
        self.SelectChatType = self.Param.ChatType
    end
    -- self:CheckIsInTeamType()
    self.CommonHeadIconCls = {}
    self.UnreadMsgCount = 0
    self.TabListCls:OnTabItemClick(self.SelectChatType,true,true)
    self.ChatModel:DispatchType(ChatModel.ON_OPEN_CHAT_MDT)
    MvcEntry:GetModel(FriendModel):SetAddFriendModule(GameModuleCfg.Chat.ID)
    self:PlayMessageDynamicEffectOnShow(true)
end

function M:OnRepeatShow(Param)
    self.Param  = Param or {}
    if self.Param.TargetPlayerId then
        if self.FriendList then
            local SelectFriendData = self.FriendList[self.SelectFriendIndex]
            if self.SelectChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT and SelectFriendData and SelectFriendData.Vo.PlayerId == self.Param.TargetPlayerId then
                -- 当前已经选中这个了，无需变动
                return
            end
        end
        -- 指定跳转到私聊好友，强制切到私聊频道
        self.SelectChatType = Pb_Enum_CHAT_TYPE.PRIVATE_CHAT
        self.TabListCls:OnTabItemClick(self.SelectChatType,true,true)
        self:UpdatePosition()
    end
end

-- 更新位置
function M:UpdatePosition()
    local DefaultViewId = ViewConst.TeamAndChat
    local Mdt = MvcEntry:GetCtrl(ViewRegister):GetView(DefaultViewId)
    if Mdt and Mdt.view then
        local CurChatInputPos = Mdt.view:GetCurChatInputAbsolutePos()
        if CurChatInputPos then
            -- 转换成局部位置 (0,0)描点位置
            local _,CurViewPortPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(self, CurChatInputPos)
            local Panel_MessagePosition = self.Panel_Message.Slot:GetPosition()
            local WBP_Chat_Emoji_PanelPosition = self.WBP_Chat_Emoji_Panel.Slot:GetPosition()
            self.Panel_Message.Slot:SetPosition(UE.FVector2D(CurViewPortPos.X, Panel_MessagePosition.Y))
            self.WBP_Chat_Emoji_Panel.Slot:SetPosition(UE.FVector2D(CurViewPortPos.X, WBP_Chat_Emoji_PanelPosition.Y)) 
        end
    end
end

function M:OnHide()
    self.ChatMsgList = {}
    self.CommonHeadIconCls = {}
    self.UnreadMsgCount = 0
    self:RemoveListeners()
    self:StopQueryPlayerState()
    -- self:CleanInputTickTimer()
    MvcEntry:GetModel(FriendModel):ClearAddFriendModule(GameModuleCfg.Chat.ID)
    for _,Widget in pairs(self.FriendListItem) do
        Widget.GUIButton_Normal.OnClicked:Clear()
    end

end

function M:AddListeners()
    self.ChatList.OnScrollItem:Add(self, self.OnScrollItem)
    self.ChatList.OnPreUpdateItem:Add(self, self.OnPreUpdateItem)
    self.ChatList.OnUpdateItem:Add(self,self.OnUpdateItem)
    self.WBP_ReuseList_Friend.OnUpdateItem:Add(self,self.OnUpdateFriendItem)
end

function M:RemoveListeners()
    self.ChatList.OnScrollItem:Clear()
    self.ChatList.OnPreUpdateItem:Clear()
    self.ChatList.OnUpdateItem:Clear()
    self.WBP_ReuseList_Friend.OnUpdateItem:Clear()
    for _,Widget in pairs(self.ChannelTabWidgetList) do
        Widget.GUIButton_TabBg.OnHovered:Clear()
        Widget.GUIButton_TabBg.OnUnhovered:Clear()
    end
end

-- 刷新消息展示列表
function M:RefreshMsgContent(IsAppend)
    self:HideNewMsgTips()
    local SelectPlayerId = nil
    if self.SelectChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        if not IsAppend then
            self:RefreshFriendList()
            self:StartTeamQueryTimer()
        end
        local SelectFriendData = self.FriendList[self.SelectFriendIndex]
        if SelectFriendData then
            SelectPlayerId = SelectFriendData.Vo.PlayerId
        end
    else
        self:StopQueryPlayerState()
        self:ClearTeamQueryTimer()
        self:PlayFriendDynamicEffectOnShow(false)
        self.FriendPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    --[[
        因为ReuseListEx中，对于Item的布局依赖于ScrollBoxList的大小，
        而当ScrollBoxList大小改变时候，调用的接口GetCachedGeometry().GetLocalSize()取的是上一帧的大小
        所以需要在改变大小的下一帧，再调用Reload，才能得到正确的item布局
    ]]
    if self.LastSelectChatType ~= self.SelectChatType and (self.LastSelectChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT or self.SelectChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT) then
        self:InsertTimer(-1,function ()
            if CommonUtil.IsValid(self) then
                self:ReloadChatList(SelectPlayerId,IsAppend)
            end
        end)
        self.LastSelectChatType = self.SelectChatType
        return
    end
    self:ReloadChatList(SelectPlayerId,IsAppend)
end

function M:ReloadChatList(SelectPlayerId,IsAppend)
    self.ChatMsgList = self.ChatModel:GetMsgList(self.SelectChatType,SelectPlayerId)
    local ListLength = #self.ChatMsgList
    if self.SelectChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT and self.FriendList and #self.FriendList > 0 then
        -- 顶部需要一个聊天对象提示文本
        ListLength = ListLength + 1
    end
    if IsAppend then
        self.ChatList:Append(ListLength) 
        self.ChatList:ScrollToEnd()
    else
        -- self.ChatList:Reload(ListLength)
        self.ChatList:ReloadToIndex(ListLength,ListLength-1)
    end

    self:RefreshCDTick()
end

-- 刷新好友列表显示
function M:RefreshFriendList()
    self:StopQueryPlayerState()
    self.FriendPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.FriendList = MvcEntry:GetModel(FriendModel):GetFriendDataList()
    local Number = #self.FriendList
    self.WidgetSwitcher_Friend:SetActiveWidget(Number > 0 and self.WBP_ReuseList_Friend or self.EmptyTips)
    if Number > 0 then
        self.SelectFriendIndex = 1
        for Index,FriendData in ipairs(self.FriendList) do
            local PlayerId = FriendData.Vo.PlayerId
            -- if (self.Param.TargetPlayerId and self.Param.TargetPlayerId == PlayerId) or (not self.Param.TargetPlayerId and self.ChatModel:HaveUnreadMsgForPlayerId(PlayerId)) then
            if (self.Param.TargetPlayerId and self.Param.TargetPlayerId == PlayerId) then
                self.SelectFriendIndex = Index
            end
            self.QueryStatePlayerIdList[#self.QueryStatePlayerIdList + 1] = PlayerId
        end
        self:DoReloadFriendList(Number)
    end
    self:StartQueryPlayerState()
    self:PlayFriendDynamicEffectOnShow(true)
end

function M:DoReloadFriendList(Number)
    self.PlayerId2Index = {}
    self.QueryTeamPlayerIdList = {}
    self.WBP_ReuseList_Friend:Reload(Number)
end

-- 好友列表Item内容
function M:OnUpdateFriendItem(Widget,I)
    local Index = I + 1
    local FriendData = self.FriendList[Index]
    if not (FriendData and FriendData.Vo) then
        CError("OnUpdateFriendItem Error For Index = "..Index,true)
        return
    end
    FriendData = FriendData.Vo
    -- Btn
    Widget.GUIButton_Normal.OnClicked:Clear()
    local IsSelect = self.SelectFriendIndex == Index
    if IsSelect then
        self.ChatModel:SetTargetFriendId(FriendData.PlayerId)
        -- self.:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        Widget.GUIButton_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
        Widget:AddActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.SELECT)
        Widget:RemoveActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.HOVER)
    else
        Widget.GUIButton_Normal:SetVisibility(UE.ESlateVisibility.Visible)
        Widget.GUIButton_Normal.OnClicked:Add(self, Bind(self,self.OnClickFriendItem,Index))
        Widget:RemoveActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.SELECT)
    end
    -- 赋值给蓝图变量，用于vx动效
    -- Widget.isSelected = IsSelect
    -- Widget.WidgetSwitcher:SetActiveWidget(IsSelect and Widget.Select or Widget.Normal)
    
    -- local FriendName = StringUtil.StringTruncationByChar(FriendData.PlayerName, "#")[1] --story=1004214 --user=郭洪 【社交】账号系统迭代 https://www.tapd.cn/68880148/s/1211315

    -- PlayerName
    local PlayerNameParam = {
        WidgetBaseOrHandler = self,
        TextBlockName = Widget.Text_PlayerName,
        TextBlockId = Widget.Text_PlayerNameId,
        PlayerId = FriendData.PlayerId,
        DefaultStr = FriendData.FriendName,
    }
    MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
    -- Widget.Text_PlayerName:SetText(FriendName)
    CommonUtil.SetTextColorFromeHex(Widget.Text_PlayerName, IsSelect and "#1B2024" or "F5EFDF", IsSelect and 1 or 0.5)
    CommonUtil.SetTextColorFromeHex(Widget.Text_PlayerNameId, IsSelect and "#1B2024" or "F5EFDF", IsSelect and 1 or 0.5)

    -- CommonHeadIcon
    local Param = {
        PlayerId = FriendData.PlayerId,
        PlayerName = FriendData.PlayerName,
        FilterOperateList = {CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Chat}
    }
    if not self.CommonHeadIconCls[Widget] then
        self.CommonHeadIconCls[Widget] = UIHandler.New(self,Widget.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.CommonHeadIconCls[Widget]:UpdateUI(Param)
    end
    -- State
    self:UpdateFriendItemState(Index, Widget, FriendData, true)
   
    self.PlayerId2Index[FriendData.PlayerId] = Index
    self.FriendListItem[Index] = Widget

    self:RegisterRedDot(Widget, FriendData.PlayerId, IsSelect)
end

function M:UpdateFriendItemState(Index, Widget, FriendData, IsReload)
    Widget:SetRenderOpacity(FriendData.PlayerState == Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE and 0.5 or 1)
    local StateText  = MvcEntry:GetModel(UserModel):GetPlayerDisplayStateFromPlayerState(FriendData.PlayerState,FriendData.PlayerId)
    local IsRealInTeam = false
    if FriendData.State == FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM then
        local TeamModel = MvcEntry:GetModel(TeamModel)
        if TeamModel:IsInTeam(FriendData.PlayerId)  then
            -- 组队中 需要显示队伍人物
            StateText = StringUtil.Format("{0} {1}/{2}",StateText,TeamModel:GetTeamMemberCount(FriendData.PlayerId),FriendConst.MAX_TEAM_MEMBER_COUNT)
            IsRealInTeam = true
        end
        if IsReload then
            self.QueryTeamPlayerIdList[#self.QueryTeamPlayerIdList + 1] = FriendData.PlayerId
        end
    end
    Widget.Text_State:SetText(StringUtil.Format(StateText))
    local ShowState = FriendData.State
    if ShowState == FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM and not IsRealInTeam then
        ShowState = FriendConst.PLAYER_STATE_ENUM.PLAYER_SINGLE
    end
    local TextColorInfo = self.StateTextColor[ShowState]
    local IsSelect = self.SelectFriendIndex == Index
    if not IsSelect and TextColorInfo then
        CommonUtil.SetTextColorFromeHex(Widget.Text_State,TextColorInfo.Hex,TextColorInfo.Opacity or 1)
        -- local TheLinearColor = UE.UGFUnluaHelper.FLinearColorFromHex(TextColorInfo.Hex)
        -- TheLinearColor.A = TextColorInfo.Opacity or 1
        -- -- 赋值给蓝图变量，用于vx动效
        -- Widget.Text_StateColor = TheLinearColor
    else
        CommonUtil.SetTextColorFromeHex(Widget.Text_State, "#1B2024", 1)
    end
end

function M:OnScrollItem(StartIdx,EndIdx)
    if self.UnreadMsgCount > 0 and EndIdx >= #self.ChatMsgList - self.UnreadMsgCount then
        self:RefreshMsgContent(false)
    end
end

-- 聊天列表Item预处理
function M:OnPreUpdateItem(Index)
    local FixIndex = Index + 1
    if self.SelectChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        if FixIndex == 1 then
            -- 顶部需要一个聊天对象提示文本
            self.ChatList:ChangeItemClassForIndex(Index,"System")
            return
        else
            FixIndex = FixIndex - 1 
        end
    end
    local Msg = self.ChatMsgList[FixIndex]
    if not Msg then
        return
    end
    if Msg.IsSystem then
        self.ChatList:ChangeItemClassForIndex(Index,"System")
    elseif Msg.IsSelf then
        self.ChatList:ChangeItemClassForIndex(Index,"Send")
    else
        self.ChatList:ChangeItemClassForIndex(Index,"")
    end
end

-- 聊天列表Item内容
function M:OnUpdateItem(Widget, Index)
    local FixIndex = Index + 1
    MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):UnregistPlayerNameUpdate(self, Widget.Text_PlayerName)
    MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):UnregistPlayerNameUpdate(self, Widget.RichText_TargetFriend)
    if self.SelectChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        if  FixIndex == 1 then
            -- 顶部需要一个聊天对象提示文本
            local SelectFriendData = self.FriendList[self.SelectFriendIndex]
            if SelectFriendData and SelectFriendData.Vo.PlayerId and SelectFriendData.Vo.PlayerName then
                 -- 昵称
                local PlayerNameParam = {
                    WidgetBaseOrHandler = self,
                    TextBlockName = Widget.RichText_TargetFriend,
                    PlayerId = SelectFriendData.Vo.PlayerId,
                    DefaultStr = SelectFriendData.Vo.PlayerName,
                    NameTextPattern = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatMdt_Chattingwith"),
                }  
                MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
                -- Widget.RichText_TargetFriend:SetText((SelectFriendData and SelectFriendData.Vo.PlayerName) and StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatMdt_Chattingwith"),SelectFriendData.Vo.PlayerName) or "")
            else
                Widget.RichText_TargetFriend:SetText("")
            end
            return
        else
            FixIndex = FixIndex - 1
        end
    else
        
    end
    local Msg = self.ChatMsgList[FixIndex]
    if Msg then
        if Msg.IsSystem then
            -- 系统消息
            -- Widget.RichText_TargetFriend.OnHyperlinkHovered:Clear()
            -- Widget.RichText_TargetFriend.OnHyperlinkUnhovered:Clear()
            Widget.RichText_TargetFriend.OnHyperlinkClicked:Clear()
            -- local function ShowHoverTips(_,ActionKey)
            --      -- 弹窗操作界面
            --     local Param =  {
            --         PlayerId = tonumber(ActionKey),
            --         IsShowOperateBtn = false,
            --         FocusWidget = Widget,
            --         IsNeedReqUpdateData = true,
            --     }
            --     MvcEntry:OpenView(ViewConst.CommonPlayerInfoHoverTip,Param)
            -- end
            -- Widget.RichText_TargetFriend.OnHyperlinkHovered:Add(self, ShowHoverTips)
            -- local function CloseHoverTips()
            --     if not self.IsClickTips then
            --         MvcEntry:CloseView(ViewConst.CommonPlayerInfoHoverTip)
            --     end
            -- end
            -- Widget.RichText_TargetFriend.OnHyperlinkUnhovered:Add(self, CloseHoverTips)
            local function ShowHoverTipsOperateMenu(_,ActionKey)
                -- self.IsClickTips = true
                -- -- 点击显示个人信息Tips的按钮菜单
                -- local Param = {
                --     PlayerId = tonumber(ActionKey),
                --     BtnState = true, 
                -- }
                -- MvcEntry:GetModel(PersonalInfoModel):DispatchType(PersonalInfoModel.ON_COMMON_HEAD_CHANGE_OPERATE_BTN_STATE_EVENT, Param)
                local Param =  {
                    PlayerId = tonumber(ActionKey),
                    IsShowOperateBtn = true,
                    FocusWidget = Widget,
                    IsNeedReqUpdateData = true,
                }
                MvcEntry:OpenView(ViewConst.CommonPlayerInfoHoverTip,Param)
            end
            Widget.RichText_TargetFriend.OnHyperlinkClicked:Add(self,ShowHoverTipsOperateMenu)
            Widget.RichText_TargetFriend:SetText(Msg.Text)
        else
            -- 普通消息
            local IsPrivateChat = self.SelectChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT
            -- 更新头像展示
            local Param = {
                PlayerId = Msg.PlayerId,
                FocusType = Msg.IsSelf and CommonHeadIconOperateMdt.FocusTypeEnum.LEFT or CommonHeadIconOperateMdt.FocusTypeEnum.RIGHT,
                CloseAutoCheckFriendShow = true,
                IsCaptain = false,
                FilterOperateList = IsPrivateChat and {CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Chat} or nil
            }
            if not self.CommonHeadIconCls[Widget.WBP_CommonHeadIcon] then
                self.CommonHeadIconCls[Widget.WBP_CommonHeadIcon] = UIHandler.New(self,Widget.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
            else 
                self.CommonHeadIconCls[Widget.WBP_CommonHeadIcon]:UpdateUI(Param)
            end
            -- 昵称
            local PlayerNameParam = {
                WidgetBaseOrHandler = self,
                TextBlockName = Widget.Text_PlayerName,
                TextBlockId = Widget.Text_PlayerNameId,
                PlayerId = Msg.PlayerId,
                DefaultStr = Msg.PlayerName,
            }
            MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
            -- Widget.Text_PlayerName:SetText(StringUtil.Format(Msg.PlayerName))
            -- TODO 各种Icon设置
            -- 信息内容
            if Msg.EmojiId ~= 0 then
                -- 表情消息
                Widget.Content:SetActiveWidget(Widget.Img_Emoji)
                MvcEntry:GetCtrl(ChatCtrl):SetEmojiImg(Msg.EmojiId,Widget.Img_Emoji)
            else
                -- 文字消息
                Widget.Content:SetActiveWidget(Widget.Chat_Text)
                Widget.Chat_Content:SetText(StringUtil.Format(Msg.Text))
            end
            if IsPrivateChat then
                -- 好友私聊，展示的时候标记消息为已读状态
                self.ChatModel:SetMsgRead(Msg)
            end

            if Widget.WBP_ChatViolation_Tips then
                -- 仅自己可见
                if Msg.MsgStatus == Pb_Enum_MSG_STATUS.CHAT_SELF then 
                    Widget.WBP_ChatViolation_Tips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    local TipsCfg = G_ConfigHelper:GetSingleItemById(Cfg_TipsCode,TipsCode.ChatBanTips.ID)
                    if TipsCfg then
                        Widget.WBP_ChatViolation_Tips.TxtTips:SetText(TipsCfg[Cfg_TipsCode_P.Des])
                    end
                else
                    Widget.WBP_ChatViolation_Tips:SetVisibility(UE.ESlateVisibility.Collapsed)
                end
            end
        end
    end
end

-- 个人详情Tips关闭
-- function M:OnHoverTipsClosed()
--     self.IsClickTips = false
-- end

-- 收到新消息
function M:OnReceiveNewMsg(ChatMsg)
    if ChatMsg.ChatType ~= self.SelectChatType then
        -- 非当前选中频道，就不管了
        return
    elseif ChatMsg.ChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        local CurSelectPlayer = self.FriendList[self.SelectFriendIndex]
        if not CurSelectPlayer or (not ChatMsg.IsSelf and CurSelectPlayer.Vo.PlayerId ~= ChatMsg.PlayerId) then
            -- 收到私聊消息但不是当前私聊对象，忽略
            return
        end
    end
    self:HandleReceiveNewMsg(ChatMsg.IsSelf)
end

-- 收到多条新消息
function M:OnReceiveNewMsgList(ChatType)
    if ChatType ~= self.SelectChatType then
        -- 非当前选中频道，就不管了
        return
    end
    self:HandleReceiveNewMsg()
end

function M:HandleReceiveNewMsg(IsFromSelf)
    local CurOffset = self.ChatList:GetScrollOffset()
    local MaxOffset = self.ChatList:GetScrollOffsetOfEnd()
    if (not IsFromSelf) and MaxOffset - CurOffset > 200 then
        -- 如果新增的是自己发送的消息，必须刷新
        -- 向上滑动了部分，展示新消息数量，不刷新列表
        self:ShowNewMsgTips()
    else
        self:RefreshMsgContent(true)
    end
end

-- 展示新消息提示
function M:ShowNewMsgTips()
    self.NewMsgTips:SetVisibility(UE.ESlateVisibility.Visible)
    self.UnreadMsgCount = self.UnreadMsgCount + 1
    self.Text_UnreadMsgCount:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatMdt_items"), self.UnreadMsgCount))
end

-- 隐藏新消息提示
function M:HideNewMsgTips()
    self.NewMsgTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.UnreadMsgCount = 0
end

-- 刷新CD展示
function M:RefreshCDTick()
    self:CleanInputTickTimer()
    local ExpireTime = self.ChatModel:GetExpireTime(self.SelectChatType)
    if ExpireTime > 0 and ExpireTime > GetTimestamp() then
        self.CdTickTips:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    local NextSendTime = self.ChatModel:GetNextTimeForSend(self.SelectChatType)
    local LeftSeconds = math.ceil(NextSendTime - GetTimestamp())
    if LeftSeconds > 0 then
        self:SetCDTimeTips(LeftSeconds)
        self.InputCDTimer = self:InsertTimer(1,function ()
            LeftSeconds = LeftSeconds - 1
            self:SetCDTimeTips(LeftSeconds)
            if LeftSeconds <= 0 then
                self:CleanInputTickTimer()
            end
        end,true)
    else
        self:SetCDTimeTips(-1)
    end
end

-- 发送失败提示
function M:OnSendFailed(Status)
    self:CleanInputTickTimer()
    self.CdTickTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local ExpireTime = self.ChatModel:GetExpireTime(self.SelectChatType)
    if ExpireTime > 0 and ExpireTime > GetTimestamp() then
        self.LableTime:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatMdt_Thischannelhasbeensi")))
        self.InputCDTimer = self:InsertTimer(2,function ()
            self.CdTickTips:SetVisibility(UE.ESlateVisibility.Collapsed)
        end)    
    else
        if Status == Pb_Enum_MSG_STATUS.CHAT_INVALID then
            self:RefreshCDTick()
        else
            self.LableTime:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatMdt_Themessagecontainsil")))
            self.InputCDTimer = self:InsertTimer(2,function ()
                self:RefreshCDTick()
            end)    
        end
    end
    
end

function M:CleanInputTickTimer()
    if self.InputCDTimer then
        self:RemoveTimer(self.InputCDTimer)
    end
    self.InputCDTimer = nil
end

function M:SetCDTimeTips(LeftSeconds)
    if LeftSeconds > 0 then
        self.CdTickTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.LableTime:SetText(StringUtil.Format(self.CDTipsStr,LeftSeconds))
    else
        self.CdTickTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 好友状态改变
function M:OnFriendStateChanged()
    if self.SelectChatType ~= Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        return
    end
    self:ReloadFriendList()
end

-- 好友列表改变
function M:OnFriendListUpdated()
    if self.SelectChatType ~= Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        return
    end
    -- self:ReloadFriendList()
    self:RefreshMsgContent(false)
end

function M:ReloadFriendList()
    local CurPlayerId = nil
    local CurSelectPlayer = self.FriendList[self.SelectFriendIndex]
    if CurSelectPlayer then
        CurPlayerId = CurSelectPlayer.Vo.PlayerId
    end
    self.FriendList = MvcEntry:GetModel(FriendModel):GetFriendDataList()
    if CurPlayerId then
        for Index,FriendData in ipairs(self.FriendList) do
            if FriendData.Vo.PlayerId == CurPlayerId then
                self.SelectFriendIndex = Index
                break
            end     
        end
    end
    self.WidgetSwitcher_Friend:SetActiveWidget(#self.FriendList > 0 and self.WBP_ReuseList_Friend or self.EmptyTips)
    self:DoReloadFriendList(#self.FriendList)
end

function M:OnChannelBtnHovered(Widget,TipsStr)
    local Param = {
        ParentWidgetCls = self,
        TipsStr = TipsStr,
        FocusWidget = Widget,
    }
    MvcEntry:OpenView(ViewConst.CommonHoverTips,Param)
    -- Widget.HoverTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function M:OnChannelBtnUnhovered()
    -- Widget.HoverTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    MvcEntry:CloseView(ViewConst.CommonHoverTips)
end

-- 点击频道
function M:OnChannelBtnClick(ChatType,ItemInfo,IsInit)
    if self.LastSelectChannelItem then
        local LastWidget = self.LastSelectChannelItem.Widget
        -- LastWidget.Padding.Right = 0
        -- LastWidget.Padding.Left = self.LastSelectChannelItem.Index > 1 and -30 or 0
        -- LastWidget:SetPadding(LastWidget.Padding)
    end
    self.LastSelectChatType = self.SelectChatType
    self.SelectChatType = ChatType
    if ChatType ~= Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        self.ChatModel:DispatchType(ChatModel.SAVE_CHAT_SEND_CONTENT)
        self.ChatModel:SetTargetFriendId(0)
    end
    self.ChatModel:SetCurChatType(ChatType)
    -- ItemInfo.Widget.HoverTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- ItemInfo.Widget.Padding.Right = 15
    -- ItemInfo.Widget.Padding.Left = ItemInfo.Index > 1 and -14 or 18
    -- ItemInfo.Widget:SetPadding(ItemInfo.Widget.Padding)
    self.LastSelectChannelItem = ItemInfo
    self:RefreshMsgContent()
end

-- 检测频道是否可选
function M:OnChannelValidCheck(ChatType)
    return true
end

-- 点击好友列表
function M:OnClickFriendItem(Index)
    self.ChatModel:DispatchType(ChatModel.SAVE_CHAT_SEND_CONTENT)
    local LastIndex = self.SelectFriendIndex
    self.SelectFriendIndex = Index
    if LastIndex and self.FriendListItem and self.FriendListItem[LastIndex] then
        local LastItem = self.FriendListItem[LastIndex]
        self:OnUpdateFriendItem(LastItem,LastIndex - 1)        
    end
    if self.SelectFriendIndex and self.FriendListItem and self.FriendListItem[self.SelectFriendIndex] then
        local CurSelectItem = self.FriendListItem[self.SelectFriendIndex]
        self:OnUpdateFriendItem(CurSelectItem,self.SelectFriendIndex - 1)
        local FriendData = self.FriendList[self.SelectFriendIndex]
        self:ReloadChatList(FriendData.Vo.PlayerId)
        self:InteractRedDot(FriendData.Vo.PlayerId)
    end
end

--弹出手动添加好友界面
function M:GUIButton_AddFriend_ClickFunc()
    if self.SelectChatType ~= Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        return
    end
    if self.FriendList and #self.FriendList > 0 then
        return
    end
    MvcEntry:OpenView(ViewConst.FriendAdd)  
end


function M:GUIButton_Close_ClickFunc()
    MvcEntry:CloseView(ViewConst.Chat)
    self:PlayMessageDynamicEffectOnShow(false)
end

function M:OnSendSuccess()
    self:RefreshCDTick()
    if self.IsOpenEmojiPanel then
        self:OnHideEmojiPanel()
    end
end

function M:OnDeleteMsg()
    self:RefreshMsgContent(false)
end
---------- 轮询队伍
function M:OnGetOtherTeamInfo(TeamInfo)
    if not TeamInfo then
        return
    end
    local TargetPlayerId = TeamInfo.TargetId
    if self.PlayerId2Index and self.PlayerId2Index[TargetPlayerId] then
        local TargetIndex = self.PlayerId2Index[TargetPlayerId]
        if TargetIndex and self.FriendListItem[TargetIndex] and self.FriendList[TargetIndex] then
            local Widget = self.FriendListItem[TargetIndex]
            local FriendData = self.FriendList[TargetIndex].Vo
            self:UpdateFriendItemState(TargetIndex, Widget, FriendData)
        end
    end
end

function M:StartTeamQueryTimer()
    if self.TeamQueryTimer then
        return
    end
    self.TeamQueryTimer = self:InsertTimer(self.AutoTeamCheckTime,function()
        if self.QueryTeamPlayerIdList and #self.QueryTeamPlayerIdList > 0 then
            MvcEntry:GetCtrl(TeamCtrl):SendPlayerListTeamInfoReq(self.QueryTeamPlayerIdList)
        end
    end,true)
end

function M:ClearTeamQueryTimer()
    if self.TeamQueryTimer then
        self:RemoveTimer(self.TeamQueryTimer)
        self.TeamQueryTimer = nil
    end
end

--------- 轮询状态，仅取二级状态，一级状态走服务器推送
function M:StartQueryPlayerState()
    if not self.StartQuery and #self.QueryStatePlayerIdList > 0 then
        MvcEntry:GetCtrl(PlayerStateQueryCtrl):PushQueryPlayerIdList(self.QueryStatePlayerIdList)
        self.StartQuery = true
    end
end

function M:StopQueryPlayerState()
    if #self.QueryStatePlayerIdList > 0 then
        MvcEntry:GetCtrl(PlayerStateQueryCtrl):DeleteQueryPlayerIdList(self.QueryStatePlayerIdList)
    end
    self.StartQuery = false
end

-- 收到玩家状态
function M:OnQueryTeamState(_,Msg)
    local FriendModel = MvcEntry:GetModel(FriendModel)
    local TargetPlayerId = Msg.PlayerId
    if self.PlayerId2Index and self.PlayerId2Index[TargetPlayerId] then
        local TargetIndex = self.PlayerId2Index[TargetPlayerId]
        if TargetIndex and self.FriendListItem[TargetIndex] and self.FriendList[TargetIndex] then
            local Widget = self.FriendListItem[TargetIndex]
            local FriendData = self.FriendList[TargetIndex].Vo
            FriendData.PlayerState = Msg.PlayerStateInfo
            FriendData.State = FriendModel:ConvertLobbyState2FriendState(Msg.PlayerStateInfo.Status)
            self:UpdateFriendItemState(TargetIndex, Widget, FriendData)
        end
    end
end

-- 监听其他界面打开，如果为Pop界面，要关闭自身
function M:OnOtherViewShowed(ViewId)
    if ViewId == self.viewId or not ViewConstConfig or not ViewConstConfig[ViewId] then
        return
    end
    if ViewConstConfig[ViewId].UILayerType and ViewConstConfig[ViewId].UILayerType > UIRoot.UILayerType.Pop then
        -- Pop层往上的界面关闭，不影响界面展示
        return
    end
    if ViewId == ViewConst.CommonHoverTips then
        return
    end
    self:GUIButton_Close_ClickFunc()
end


-- 打开选择表情面板
function M:OnOpenEmojiPanel()
    if self.IsOpenEmojiPanel then
        self:OnHideEmojiPanel()
        return
    end
    self.IsOpenEmojiPanel = true
    self.GUIButton_CloseEmoji:SetVisibility(UE.ESlateVisibility.Visible)    
    self.WBP_Chat_Emoji_Panel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)    
    if not self.ChatEmojiCls then
        self.ChatEmojiCls = UIHandler.New(self,self.WBP_Chat_Emoji_Panel,require("Client.Modules.Chat.ChatEmojiLogic")).ViewInstance
    end
    self.ChatEmojiCls:UpdateUI()
    self:PlayEmojiDynamicEffectOnShow(true)
end

function M:OnHideEmojiPanel()
    self.IsOpenEmojiPanel = false
    self.GUIButton_CloseEmoji:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self.WBP_Chat_Emoji_Panel:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:PlayEmojiDynamicEffectOnShow(false)
    MvcEntry:GetModel(ChatEmojiModel):DispatchType(ChatEmojiModel.ON_CLOSE_EMOJI_PANEL)
end

-- 绑定红点
function M:RegisterRedDot(Widget, PlayerId, IsSelect)
    local RedDotKey = "ChatFriendItem_"
    local RedDotSuffix = PlayerId
    if not self.RedDotWidgetList[PlayerId] then
        Widget.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.RedDotWidgetList[PlayerId] = UIHandler.New(self, Widget.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
    else 
        self.RedDotWidgetList[PlayerId]:ChangeKey(RedDotKey, RedDotSuffix)
    end  

    -- 选中的情况下 需要直接触发红点消失逻辑
    if IsSelect then
        self:InteractRedDot(PlayerId)
    end
end

-- 红点触发逻辑
function M:InteractRedDot(PlayerId)
    if self.RedDotWidgetList[PlayerId] then
        self.RedDotWidgetList[PlayerId]:Interact()
    end
end

--[[
    播放信息页显示退出动效
]]
function M:PlayMessageDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Hall_Chat_Message_In then
            self:VXE_Hall_Chat_Message_In()
        end
    else
        if self.VXE_Hall_Chat_Message_Out then
            self:VXE_Hall_Chat_Message_Out()
        end
    end
end

--[[
    播放好友页显示退出动效
]]
function M:PlayFriendDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Hall_Chat_Friend_In then
            self:VXE_Hall_Chat_Friend_In()
        end
    else
        if self.VXE_Hall_Chat_Friend_Out then
            self:VXE_Hall_Chat_Friend_Out()
        end
    end
end

--[[
    播放好友页显示退出动效
]]
function M:PlayEmojiDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Hall_Chat_Emoji_In then
            self:VXE_Hall_Chat_Emoji_In()
        end
    else
        if self.VXE_Hall_Chat_Emoji_Out then
            self:VXE_Hall_Chat_Emoji_Out()
        end
    end
end

function M:On_vx_hud_chat_message_out_Finished()
    --MvcEntry:CloseView(ViewConst.Chat)
end

function M:On_vx_hud_chat_friend_out_Finished()
    self.FriendPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function M:On_vx_hud_chat_emoji_out_Finished()
    self.WBP_Chat_Emoji_Panel:SetVisibility(UE.ESlateVisibility.Collapsed)
end


return M
