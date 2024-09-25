--通用Tips 富文本的倒计时类
--作者：许欣桐

local GenericCommonRichTextTips = Class("Common.Framework.UserWidget")

function GenericCommonRichTextTips:OnInit()
    print("GenericGuideTips:OnInit")
   self.FormatText = ""
    UserWidget.OnInit(self)
end


function GenericCommonRichTextTips:OnDestroy()
    print("GenericCommonRichTextTips:OnDestroy")
 
    UserWidget.OnDestroy(self)
end


function GenericCommonRichTextTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self.FormatText = self.TxtTips:GetText()
    self.TxtTips:SetText(StringUtil.Format(self.FormatText, string.format("%.f", NewCountDownTime)))
end

function GenericCommonRichTextTips:UpdateData(Owner,NewCountDownTime,TipGenricBlackboard)
    self.TxtTips:SetText(StringUtil.Format(self.FormatText, string.format("%.f", NewCountDownTime)))
end

return GenericCommonRichTextTips