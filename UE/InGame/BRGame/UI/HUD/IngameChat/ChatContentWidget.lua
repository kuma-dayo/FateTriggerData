local ChatContentWidget = Class("Common.Framework.UserWidget")
function ChatContentWidget:OnInit()

    self.ReplayTip:SetVisibility(UE.ESlateVisibility.Collapsed)

    self.BindNodes ={
        { UDelegate = self.GUIButton.OnHovered, Func = self.OnSelfHovered },
        { UDelegate = self.GUIButton.OnUnhovered, Func = self.OnSelfUnhovered },
        { UDelegate = self.GUIButton.OnClicked, Func = self.OnSelfClicked },
    }
    
    UserWidget.OnInit(self)
end


function ChatContentWidget:InitChatContentWidgetByData(InWidget, InType, bIsMyMessage,InTeamPos,InMessageOwner, InMessage, InCurrentIndex)
    self.WidgetOwner = InWidget
    self.ThisType = InType
    self.MessageOwner = InMessageOwner
    self.InMessage = InMessage
    self.CurrentIndex = InCurrentIndex
    self.bIsMyMessage = bIsMyMessage --是自己？

    self.CanReplay = false --此消息能回复？

    if self.ThisType == UE.EIngameMessageChatChannel.Private then
        self.CanReplay = true
    end


    local FinalText =""
    if  self.ThisType == UE.EIngameMessageChatChannel.MarkSystem then
        FinalText = self.InMessage
    else
        local ChannelName = self.EChatChannelNameArr:Get(InType+1)
        --队伍名字颜色
        local TeamPosColor = self.TeamPosColorMap:Find(InTeamPos)
        local TeamPosStr = StringUtil.Format('<span color="{0}">', TeamPosColor)

        --聊天类型图标
        local IconResult = self.ChannelIconMap:Find(self.ThisType) 
        local ChannalIconStr = StringUtil.Format('<img src="{0}" verticaloffset="0" size="28"></>', IconResult)
    
        --玩家名字
        local NameStr = self.bIsMyMessage and self.PlayerSelfName or self.MessageOwner

        FinalText = ChannalIconStr..TeamPosStr..NameStr..":</>"..self.InMessage
    end

    self.MsgTextBlock:SetText(FinalText)
end
function ChatContentWidget:OnSelfHovered()
    self.GUIImage_Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if not self.ThisType then return end
    if self.CanReplay~= nil and self.CanReplay then
        self.ReplayTip:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.ReplayTip:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end
function ChatContentWidget:OnSelfUnhovered()
    self.GUIImage_Select:SetVisibility(UE.ESlateVisibility.Hidden)
    self.ReplayTip:SetVisibility(UE.ESlateVisibility.Hidden)
end

function ChatContentWidget:OnSelfClicked()
    if self.CanReplay~= nil and self.CanReplay then
        self.WidgetOwner:OnTryReplayMessage(self.CurrentIndex, self.WidgetOwner,self.MessageOwner)
    end
end

function ChatContentWidget:OnDestroy()
    UserWidget.OnDestroy(self)
end

return ChatContentWidget