local ChatContentWidgetMobile = Class("Common.Framework.UserWidget")
function ChatContentWidgetMobile:OnInit()
    print("ChatContentWidgetMobile >> OnInit self=",GetObjectName(self))
    self.Button_ChatReplay.OnClicked:Add(self, self.OnChatReplayButtonClicked)
    UserWidget.OnInit(self)
end
function ChatContentWidgetMobile:InitChatContentWidgetByData(InWidget, InType, InMessageOwner, InMessage, InCurrentIndex, VoiceData)
    print("ChatContentWidgetMobile >> InitChatContentWidgetByData self=",GetObjectName(self))
    self.WidgetOwner = InWidget
    self.ThisType = InType
    self.MessageOwner = InMessageOwner
    self.InMessage = InMessage
    self.CurrentIndex = InCurrentIndex
    local ChannelName = self.EChatChannelNameArr:Get(InType+1)

    local FinalText = ""
    local ColorTextTag = "<span color=\"#000000\">"
    if InType == 0 then
        ColorTextTag = "<span color=\"#000000\">"
        FinalText = ColorTextTag.."["..ChannelName.."]"..self.MessageOwner..":</>"..self.InMessage
    elseif InType == 1 then
        ColorTextTag = "<span color=\"#bb00ff\">"
        FinalText = ColorTextTag.."["..ChannelName.."]"..self.MessageOwner..":</>"..self.InMessage
    elseif InType == 2 then
        ColorTextTag = "<span color=\"#bb0123\">"
        FinalText = ColorTextTag.."["..ChannelName.."]"..self.MessageOwner..":</>"..self.InMessage
    elseif InType == 3 then
        ColorTextTag = "<span color=\"#cc0000\">"
        FinalText = ColorTextTag.."["..ChannelName.."]"..self.MessageOwner..":</>"..self.InMessage
    elseif InType == 4 then
        ColorTextTag = "<span color=\"#ff0000\">"
        FinalText = ColorTextTag.."["..ChannelName.."]"..self.MessageOwner..":</>"..self.InMessage
    elseif 5 == InType then -- 标记日志直接传一个富文本格式的消息参数进来
        FinalText = InMessage
    end
    --"<span color="#bb00ff">[1]话痨玩家:</>21342134"

    FinalText = StringUtil.Format(FinalText)
    -- "我标记了<span color="#cc0000"> 燃烧手雷 </>"

    self.MsgTextBlock:SetText(FinalText)
    if VoiceData == nil then
        self.VoicePanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ChatContentWidgetMobile:OnChatReplayButtonClicked()
    if self.WidgetOwner then
        self.WidgetOwner:OnTryReplayMessage(self.CurrentIndex, self.WidgetOwner,self.MessageOwner)
    end
end


return ChatContentWidgetMobile