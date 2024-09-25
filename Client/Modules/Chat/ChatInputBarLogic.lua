--[[
    大厅底部 - 聊天输入栏
]]

local class_name = "ChatInputBarLogic"
ChatInputBarLogic = ChatInputBarLogic or BaseClass(nil, class_name)
ChatInputBarLogic.ShowState = {
    Msg = 1,
    Input = 2
}

function ChatInputBarLogic:OnInit()
    self.InputFocus = true
    self.BindNodes= {
		{ UDelegate = self.View.Btn_Input_Chat.OnClicked,				    Func = Bind(self,self.Btn_Input_Chat_OnClicked) },
		-- { UDelegate = self.View.Btn_Input_Chat.OnPressed,				    Func = Bind(self,self.Btn_Input_Chat_OnPressed) },
		-- { UDelegate = self.View.Btn_Input_Chat.OnReleased,				    Func = Bind(self,self.Btn_Input_Chat_OnReleased) },
		-- { UDelegate = self.View.Btn_Input_Chat.OnHovered,				    Func = Bind(self,self.Btn_Input_Chat_OnHovered) },
		-- { UDelegate = self.View.Btn_Input_Chat.OnUnhovered,				    Func = Bind(self,self.Btn_Input_Chat_OnUnhovered) },
		-- { UDelegate = self.View.Btn_Key_Enter.OnClicked,				    Func = Bind(self,self.OnEnterFunc) },
		{ UDelegate = self.View.WBP_ChatEmojiEntranceBtn.EmojiBtn.OnClicked,				    Func = Bind(self,self.Btn_OnOpenEmojiPanel) },

    }

    self.MsgList = {
        {Model = ChatModel, MsgName = ChatModel.ON_SEND_SUCCESS, Func = Bind(self,self.OnSendSuccess)},
        {Model = ChatModel, MsgName = ChatModel.ON_SEND_FAILED, Func = Bind(self,self.CheckInputState)},
        {Model = ChatModel, MsgName = ChatModel.ON_SELECT_CHANNEL_CHANGED, Func = Bind(self,self.OnSelectChannelChanged)},
        {Model = ChatModel, MsgName = ChatModel.ON_SELECT_FRIEND_CHANGED, Func = Bind(self,self.OnSelectFriendChanged)},
        {Model = ChatModel, MsgName = ChatModel.SAVE_CHAT_SEND_CONTENT, Func = Bind(self,self.DoSaveChatSendContent)},
        {Model = ChatModel, MsgName = ChatModel.ON_RECEIVE_HIGH_PRIORITY_MSG, Func = Bind(self,self.OnReceiveHighPriorityMsg)},
        {Model = ChatModel, MsgName = ChatModel.ON_RECEIVE_NEW_MSG, Func = Bind(self,self.OnReceiveNewMsg)},
        {Model = ChatModel, MsgName = ChatModel.ON_RECEIVE_NEW_MSG_LIST, Func = Bind(self,self.OnReceiveNewMsg)},
        {Model = ChatModel, MsgName = ChatModel.ON_DELETE_MSG, Func = Bind(self,self.OnDeleteMsg)},
        {Model = ChatEmojiModel, MsgName = ChatEmojiModel.ON_CLOSE_EMOJI_PANEL, Func = Bind(self,self.OnCloseEmojiPanel)},
        {Model = ChatEmojiModel, MsgName = ChatEmojiModel.DO_SEND_EMOJI, Func = Bind(self,self.DoSendEmoji)},
        {Model = FriendModel, MsgName = FriendModel.ON_ADD_FRIEND, Func = Bind(self,self.OnFriendListUpdated)},
        {Model = FriendModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnFriendListUpdated)},
    }

     -- 注册输入控件处理
    self.InputBox = UIHandler.New(self,self.View,CommonTextBoxInput,{
        InputWigetName = "ChatInputBox",
        FoucsViewId = ViewConst.Chat,
        OnTextChangedFunc = Bind(self,self.OnTextChangedFunc),
        OnTextCommittedEnterFunc = Bind(self,self.OnEnterFunc),
        OnClearedFunc = Bind(self,self.OnClearedFunc),
    }).ViewInstance

    self.ChatModel = MvcEntry:GetModel(ChatModel)
    self.CDTipsStr = self.ChatModel:GetSendCDErrorCodeTips()
    self.ForbiddenTipsStr = self.ChatModel:GetForbiddenErrorCodeTips()
    self.IsMsgContentEmpty = true
    self.UnlockIds = {
        [Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT] = 10300,
        [Pb_Enum_CHAT_TYPE.TEAM_CHAT] = 10301,
        [Pb_Enum_CHAT_TYPE.PRIVATE_CHAT] = 10302,
    }

    -- 绑定红点
    self:RegisterRedDot()
end


function ChatInputBarLogic:OnShow(Param)
    self.View.MsgContent:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:UpdateUI(Param)
end

function ChatInputBarLogic:OnHide()
    self:CleanShowTickTimer()
    self:CleanInputTickTimer()
    self:CleanFocusTickTimer()
    self.ChatModel = nil
    self.IsShowMsg = nil
end

function ChatInputBarLogic:UpdateUI(Param)
    self.View.WBP_ChatEmojiEntranceBtn:RemoveActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.SELECT)
    if self.IsShowMsg == nil then
        self:SwitchToState()
    end
end

-- 检测是否有新消息展示
function ChatInputBarLogic:CheckNewMsg()
    if self.ShowTickTimer ~= nil then
        -- 当前已有信息在展示，不处理，若有更高优先级插入,走事件 ON_RECEIVE_HIGH_PRIORITY_MSG 监听处理
        return
    end
    local NewMsg = self.ChatModel:GetNewMsg()
    -- 最后一条展示的信息，如果没有新消息，就展示这条
    local LastShowMsg = self.ChatModel:GetLastShowMsg()
    
    if not NewMsg and not LastShowMsg then
        -- 需求没新消息，不隐藏
        -- self.View.MsgContent:SetVisibility(UE.ESlateVisibility.Collapsed)
        if self.IsMsgContentEmpty then
            self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.EmptyTips)
        end
        return
    end

    if self.IsMsgContentEmpty then
        self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.Panel_Msg)
        self.IsMsgContentEmpty = false
    end
    local ShowMsg = NewMsg or LastShowMsg
    -- 记录当前展示消息所属的聊天类型，打开聊天界面时，切换到这个类型
    self.CurShowMsgType = ShowMsg.ChatType
    if self.CurShowMsgType == Pb_Enum_CHAT_TYPE.TEAM_CHAT and ShowMsg.IsSystem and not MvcEntry:GetModel(TeamModel):IsSelfInTeam() then
        -- 如果最后一条 为队伍状态变动且变动后玩家处于单人状态 则不会打开组队界面，而是打开世界频道
        self.CurShowMsgType = Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT
    end
    self.ChatModel:SetCurChatType(self.CurShowMsgType)
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    if self.CurShowMsgType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT and ShowMsg.PlayerId ~= MyPlayerId then
        self.CurShowMsgSenderId = ShowMsg.PlayerId
    else
        self.CurShowMsgSenderId = nil
    end
    local ChatType = ShowMsg.ChatType
    local ChatConfig = self.ChatModel:GetChannelConfig(ChatType)
    if not ChatConfig then
        CError("CheckNewMsg GetChannelConfig error for type = "..tostring(ChatType))
        print_trackback()
        return
    end
    local IsSystemMsg = ShowMsg.IsSystem
    -- 频道内（即同优先级下）消息检测时间 (配置时间为毫秒)
    self.MinCheckTime = (ChatConfig[Cfg_ChatParamCfg_P.MinCheckTime] or 0) / 1000
    -- 频道展示时间（即超过此时间，检测低优先级的新消息） (配置时间为毫秒)
    self.ChannelShowTime = (ChatConfig[Cfg_ChatParamCfg_P.ChannelShowTime] or 1) / 1000
    self.View.MsgContent:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- 频道名称
    local ChannelName = self.ChatModel:GetChatParam(ChatType,Cfg_ChatParamCfg_P.Name) or ""
    self.View.ChatChannel:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_4"),ChannelName))
    -- 频道文本背景颜色
    local Color = ChatConfig[Cfg_ChatParamCfg_P.ChannelHexColor]
    -- CommonUtil.SetBrushTintColorFromHex(self.View.ChannelBg,Color)
    CommonUtil.SetTextColorFromeHex(self.View.ChatChannel,Color)
    -- 玩家昵称
    if not IsSystemMsg then
        self.View.Nickname:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local ShowName = StringUtil.SplitPlayerName(ShowMsg.PlayerName)
        self.View.Nickname:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_11"),ShowName))
    else
        self.View.Nickname:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Nickname:SetText("")
    end
    -- self.View.Panel_Msg:ForceLayoutPrepass()
    
    -- TotalWidth为MsgContent的设计宽度，找不到合适取尺寸的接口，先写死了
    local TotalWidth = 471
    local ChannelWidth = self.View.Panel_Channel:GetDesiredSize().X
    local TextNameWidth = self.View.Nickname:GetDesiredSize().X
    local LeftWidth = TotalWidth - ChannelWidth - TextNameWidth
    -- 字体大小为20也先写死用于计算最多能显示几个字了，超出则显示为...
    local MaxShowLength = math.ceil(LeftWidth/20)
    -- 消息内容
    local ShowText = (ShowMsg.EmojiId and ShowMsg.EmojiId > 0) and G_ConfigHelper:GetStrFromOutgameStaticST("SD_Chat", "1256") or ShowMsg.Text
    -- 这里的文本不需要超链接。替换成普通颜色设置
    local Pattern = '<hyperlink color="#([^"]+)" action="[^"]+">'
    local Replacement = '<span color="#%1">'
    ShowText = string.gsub(ShowText,Pattern,Replacement)
    self.View.ChatContent:SetText(ShowText)
    -- 开启计时展示
    if NewMsg then
        self:ScheduleShowMsg()
    end
end

-- 计时展示
function ChatInputBarLogic:ScheduleShowMsg()
    self:CleanShowTickTimer()
    self.ShowTickTimer = Timer.InsertTimer(0,
        function (dt)
            self.DeltaTime = self.DeltaTime + dt
            -- 在 ChannelShowTime 内，按 MinCheckTime 间隔取同优先级下的新消息；
            -- 超过 ChannelShowTime ，取低一级优先级的新消息
            if (self.DeltaTime >= self.MinCheckTime and self.ChatModel:HaveCurPriorityNewMsg())
             or self.DeltaTime >= self.ChannelShowTime then
                self:CleanShowTickTimer()
                self:CheckNewMsg()
            end
        end
    ,true)   
end

function ChatInputBarLogic:CleanShowTickTimer()
    self.DeltaTime = 0
    if self.ShowTickTimer then
        Timer.RemoveTimer(self.ShowTickTimer)
    end
    self.ShowTickTimer = nil
end

-- 发送成功
function ChatInputBarLogic:OnSendSuccess()
    UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatInputBarLogic_Sendsuccess"))
    if not self.IsShowMsg then
        self:CheckInputState()
    end
end

-- 收到更高优先级的消息
function ChatInputBarLogic:OnReceiveHighPriorityMsg()
    if not self.IsShowMsg then
        return
    end
    -- 先打断当前展示中的消息 -> 再展示新消息
    self:CleanShowTickTimer()
    self:CheckNewMsg() 
end

-- 收到新消息
function ChatInputBarLogic:OnReceiveNewMsg()
    if not self.IsShowMsg then
        return
    end
    self:CheckNewMsg()
end

-- 收到消息删除 检测当前显示的是否需要刷新
function ChatInputBarLogic:OnDeleteMsg()
    if not self.IsShowMsg then
        return
    end
    local LastShowMsg = self.ChatModel:GetLastShowMsg()
    if LastShowMsg == nil then
        -- 被删除了
        self.IsMsgContentEmpty = true
        self.CurShowMsgSenderId = nil
        self.CurShowMsgType = Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT
        self.ChatModel:SetCurChatType(self.CurShowMsgType)
        self:CheckNewMsg()
    end
end

-- 聊天频道改变了
function ChatInputBarLogic:OnSelectChannelChanged()
    self:SetInputChannel()
end

-- 聊天好友改变了
function ChatInputBarLogic:OnSelectFriendChanged()
    self.View.ChatInputBox:SetText(self.ChatModel:GetSavedSendContent(self.InputChatType))
    self:DoKeyboardFocus()
end

-- 存储当前聊天输入缓存
function ChatInputBarLogic:DoSaveChatSendContent()
    self.ChatModel:SaveSendContent(self.InputChatType, self.View.ChatInputBox:GetText())
end

-- 点击聊天框 
function ChatInputBarLogic:Btn_Input_Chat_OnClicked()
    if self.IsShowMsg then
        self:CleanShowTickTimer()
        if not MvcEntry:GetModel(NewSystemUnlockModel):IsSystemUnlock(ViewConst.Chat,true) then
            return
        end
        --self:SwitchToState(ChatInputBarLogic.ShowState.Input)
        --self:PlayDynamicEffectOnShow(true)
        -- 打开聊天界面
        local Param = {
            ChatType = self.CurShowMsgType or Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT,
            TargetPlayerId = self.CurShowMsgSenderId
        }
        MvcEntry:OpenView(ViewConst.Chat,Param)
    else
        self:OnEnterFunc()
    end
    self:InteractRedDot(self.ChatRedDot)
end

function ChatInputBarLogic:DoKeyboardFocus()
    if not self.IsShowMsg and self.View.ChatInputBox:GetIsEnabled() then
        self:InsertTimer(Timer.NEXT_FRAME,function ()
            self.View.ChatInputBox:SetKeyboardFocus()
        end)
    end
end

-- function ChatInputBarLogic:Btn_Input_Chat_OnPressed()
--     self.View.ChatInput:SetRenderOpacity(0.6)
-- end

-- function ChatInputBarLogic:Btn_Input_Chat_OnReleased()
--     self.View.ChatInput:SetRenderOpacity(1.0)
-- end

-- function ChatInputBarLogic:Btn_Input_Chat_OnHovered()
--     CommonUtil.SetTextColorFromeHex(self.View.EmptyTips,"1B2024",0.8)
-- end

-- function ChatInputBarLogic:Btn_Input_Chat_OnUnhovered()
--     CommonUtil.SetTextColorFromeHex(self.View.EmptyTips,"F5EFDF",0.8)
-- end

-- 切换 消息展示/输入状态
function ChatInputBarLogic:SwitchToState(State)
    State = State or ChatInputBarLogic.ShowState.Msg
    self.IsShowMsg = State == ChatInputBarLogic.ShowState.Msg

    if  State == ChatInputBarLogic.ShowState.Input then
        self.IsPlayInputCloseAnim = true
    end
    -- change show content
    self.View.WidgetSwitcher:SetActiveWidget(self.IsShowMsg and self.View.WidgetSwitcher_Content or self.View.Panel_Input)
    -- 更新表情入口显隐
    local HaveEmojiToShow = MvcEntry:GetModel(ChatEmojiModel):HaveEmojiToShow()
    self.View.WBP_ChatEmojiEntranceBtn:SetVisibility((self.IsShowMsg or not HaveEmojiToShow) and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    if self.IsShowMsg then
        --self.View:RemoveActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.SELECT)
        if self.IsPlayInputCloseAnim then
            self:PlayDynamicEffectOnShow(false)
            self.IsPlayInputCloseAnim = false
        end
        self:CleanInputTickTimer()
        self:CheckNewMsg()
    else
        --self.View:AddActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.SELECT)
        self:PlayDynamicEffectOnShow(true)
        -- 切换到输入框显示，即要进入输入状态
        self:SetInputChannel()
        -- 延迟一帧设置进入输入状态，避免被InputModel的处理覆盖了聚焦
        self:CleanFocusTickTimer()
        self.FocusTimer = Timer.InsertTimer(-1,function ()
            if CommonUtil.IsValid(self.View) then
                self:DoKeyboardFocus()
            end
            self:CleanFocusTickTimer()
        end)
    end
    self:UpdateChatRedDotOpactiy()
end

function ChatInputBarLogic:SetInputChannel()
    self.ChatModel:SaveSendContent(self.InputChatType, self.View.ChatInputBox:GetText())
    self.InputChatType = self.ChatModel:GetCurChatType()
    self.View.ChatInputBox:SetText(self.ChatModel:GetSavedSendContent(self.InputChatType))
    local Name = self.ChatModel:GetChatParam(self.InputChatType,Cfg_ChatParamCfg_P.Name) or ""
    self.MaxSizeLimit = self.ChatModel:GetChatParam(self.InputChatType,Cfg_ChatParamCfg_P.MaxWords) or 100
    self.View.PublishedChannel:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"),Name))
    local Color = self.ChatModel:GetChatParam(self.InputChatType,Cfg_ChatParamCfg_P.ChannelHexColor)
    -- CommonUtil.SetBrushTintColorFromHex(self.View.PublishedChannelBg,Color)
    CommonUtil.SetTextColorFromeHex(self.View.PublishedChannel,Color)
    self.InputBox:SetMaxSizeLimit(self.MaxSizeLimit)
    self:CheckInputState()
end

function ChatInputBarLogic:CheckInputState()
    local ExpireTime = self.ChatModel:GetExpireTime(self.InputChatType)
    local IsForbidden = ExpireTime > 0 and ExpireTime > GetTimestamp()
    self:RefreshCDTick(IsForbidden)
    self:DoKeyboardFocus()
end

-- 刷新CD展示
function ChatInputBarLogic:RefreshCDTick(IsForbidden)
    self:CleanInputTickTimer()
    local NextSendTime = 0
    if IsForbidden then
        NextSendTime = self.ChatModel:GetExpireTime(self.InputChatType)
    else
        NextSendTime = self.ChatModel:GetNextTimeForSend(self.InputChatType)
    end
    local LeftSeconds = math.ceil(NextSendTime - GetTimestamp())
    if LeftSeconds > 0 then
        self:SetInputHintText(LeftSeconds,IsForbidden)
        self.InputCDTimer = Timer.InsertTimer(1,function ()
            LeftSeconds = LeftSeconds - 1
            self:SetInputHintText(LeftSeconds,IsForbidden)
            if LeftSeconds <= 0 then
                self:CleanInputTickTimer()
            end
        end,true)
    else
        self:SetInputHintText()
    end
end

function ChatInputBarLogic:SetInputHintText(LeftSeconds,IsForbidden)
    if not LeftSeconds or LeftSeconds <= 0 then
        IsForbidden = false
    end
    self.View.WidgetSwitcher_Input:SetActiveWidget(IsForbidden and self.View.Input_Ban or self.View.ChatInputBox)
    if IsForbidden then
        local TipsStr = ""
        -- if LeftSeconds <= 60 then
        --     TipsStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatInputBarLogic_seconds"),LeftSeconds) 
        -- elseif LeftSeconds <= 60*60 then
        --     TipsStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatInputBarLogic_minutes"),math.floor(LeftSeconds/60)) 
        -- else
        --     TipsStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatInputBarLogic_hours"),math.floor(LeftSeconds/3600)) 
        -- end
        --[[
            客户端显示永远为两个时间单位
            - X天X时
            - X时X分
        ]]
        local Days = math.floor(LeftSeconds / (24 * 3600))
        local Hours = math.floor((LeftSeconds % (24 * 3600)) / 3600)
        local Minutes = math.floor((LeftSeconds % 3600) / 60)
        if Days > 0 then
            TipsStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatInputBarLogic_DayAndHour"),Days,Hours) 
        else
            if Hours == 0 and Minutes == 0 then
                -- 要求小于一分钟显示一分钟
                Minutes = 1
            end
            TipsStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatInputBarLogic_HourAndMinute"),Hours,Minutes) 
        end
        self.View.GUITextBlock_BanTime:SetText(StringUtil.Format(self.ForbiddenTipsStr,TipsStr))
    else
        if self.InputChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
            if MvcEntry:GetModel(FriendModel):IsFriendListEmpty() then
                self:SetInputBoxEnabled(false)
                self.View.ChatInputBox:SetHintText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatInputBarLogic_Friendswhohavenoconv")))
                return
            end
        end
        self:SetInputBoxEnabled(true)
        local DefaultStr =  StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatInputBarLogic_Pleaseenterthechatco"))
        local NewSystemUnlockModel = MvcEntry:GetModel(NewSystemUnlockModel)
        local UnlockId = self.UnlockIds[self.InputChatType]
        if not NewSystemUnlockModel:IsSystemUnlock(UnlockId) then
            DefaultStr =  NewSystemUnlockModel:GetSystemUnlockTips(UnlockId)
            self:SetInputBoxEnabled(false)
        end
        local Str = (LeftSeconds and LeftSeconds > 0) and StringUtil.Format(self.CDTipsStr,LeftSeconds) or DefaultStr
        self.View.ChatInputBox:SetHintText(Str)
    end
end

function ChatInputBarLogic:SetInputBoxEnabled(IsEnabled)
    self.View.ChatInputBox:SetIsEnabled(IsEnabled)
    local HaveEmojiToShow = MvcEntry:GetModel(ChatEmojiModel):HaveEmojiToShow()
    self.View.WBP_ChatEmojiEntranceBtn:SetVisibility((IsEnabled and not self.IsShowMsg and HaveEmojiToShow) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function ChatInputBarLogic:CleanInputTickTimer()
    if self.InputCDTimer then
        Timer.RemoveTimer(self.InputCDTimer)
    end
    self.InputCDTimer = nil
end
function ChatInputBarLogic:CleanFocusTickTimer()
    if self.FocusTimer then
        Timer.RemoveTimer(self.FocusTimer)
    end
    self.FocusTimer = nil
end

function ChatInputBarLogic:OnTextChangedFunc(InputBox,InputTxt)
    if not CommonUtil.IsValid(self.View) then
        return
    end
end

function ChatInputBarLogic:OnEnterFunc()
    if not CommonUtil.IsValid(self.View) then
        return
    end

    if self.IsShowMsg then
        self:Btn_Input_Chat_OnClicked()
    else
        local UnlockId = self.UnlockIds[self.InputChatType]
        if not MvcEntry:GetModel(NewSystemUnlockModel):IsSystemUnlock(UnlockId,true) then
            return
        end
        local InputText = self.View.ChatInputBox:GetText()
        -- 检测是否纯空格
        local TrimEmptyText = StringUtil.AllTrim(InputText)
        if InputText ~= "" and TrimEmptyText ~= "" then
            InputText = StringUtil.HandleTextSpacesToValid(InputText)
            self:DoSendMsg(InputText)
            self.ChatModel:ClearSavedSendContent(self.InputChatType)
            self.View.ChatInputBox:SetText("")
        else
            MvcEntry:CloseView(ViewConst.Chat)
        end
    end
end

function ChatInputBarLogic:DoSendMsg(InputText,EmojiId)
    local NextSendTime = self.ChatModel:GetNextTimeForSend(self.InputChatType)
        local LeftSeconds = math.ceil(NextSendTime - GetTimestamp())
        if LeftSeconds > 0 then
            MvcEntry:GetCtrl(ErrorCtrl):PopTipsSync(TipsCode.ChatNeedCD.ID,"",{LeftSeconds})
            self:DoKeyboardFocus()
            return
        end
    local ReceiverId = self.ChatModel:GetTagetFriendId()
    if self.InputChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT and ReceiverId == 0 then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatInputBarLogic_Goandaddfriendsfirst"))
        return
    end
    -- 向服务器发送请求
    local ChatInfo = {
        SendTime = GetTimestamp(),
        Text = InputText,
        ChatType = self.InputChatType,
        EmojiId = EmojiId
    }
    MvcEntry:GetCtrl(ChatCtrl):SendProto_ChatReq(ReceiverId,ChatInfo)
end

function ChatInputBarLogic:OnFriendListUpdated()
    if self.InputChatType ~= Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        return
    end
    self:SetInputHintText()
end

function ChatInputBarLogic:OnClearedFunc()
    MvcEntry:CloseView(ViewConst.Chat)
end

function ChatInputBarLogic:Btn_OnOpenEmojiPanel()
    -- self.View.WBP_ChatEmojiEntranceBtn:RemoveActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.HOVER)
    self.View.WBP_ChatEmojiEntranceBtn:AddActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.SELECT)
    MvcEntry:GetModel(ChatEmojiModel):DispatchType(ChatEmojiModel.ON_OPEN_EMOJI_PANEL)
    self:InteractRedDot(self.EmojiRedDot)
end

function ChatInputBarLogic:OnCloseEmojiPanel()
    self.View.WBP_ChatEmojiEntranceBtn:RemoveActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.SELECT)
end

function ChatInputBarLogic:DoSendEmoji(_,EmojiId)
    self:DoSendMsg("",EmojiId)
end

-- 绑定红点
function ChatInputBarLogic:RegisterRedDot()
    if not self.ChatRedDot then
        self.View.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local RedDotKey = "Chat"
        local RedDotSuffix = ""
        self.ChatRedDot = UIHandler.New(self, self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
    end  
    if not self.EmojiRedDot and self.View.WBP_ChatEmojiEntranceBtn.WBP_RedDotFactory then
        local RedDotKey = "ChatEmojiEntrance"
        local RedDotSuffix = ""
        self.EmojiRedDot = UIHandler.New(self, self.View.WBP_ChatEmojiEntranceBtn.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
    end
end

-- 更新聊天红点透明度 打开聊天框的时候要隐藏
function ChatInputBarLogic:UpdateChatRedDotOpactiy()
    local Opactiy = self.IsShowMsg and 1 or 0
    if self.View.WBP_RedDotFactory then
        self.View.WBP_RedDotFactory:SetRenderOpacity(Opactiy)
    end
end

-- 红点触发逻辑
function ChatInputBarLogic:InteractRedDot(RedDotItem)
    if RedDotItem then
        RedDotItem:Interact()
    end
end

--[[
    播放显示退出动效
]]
function ChatInputBarLogic:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.View.VXE_Hall_ChatInput_Open then
            self.View:VXE_Hall_ChatInput_Open()
        end
    else
        if self.View.VXE_Hall_ChatInput_Close then
            self.View:VXE_Hall_ChatInput_Close()
        end
    end
end

return ChatInputBarLogic
