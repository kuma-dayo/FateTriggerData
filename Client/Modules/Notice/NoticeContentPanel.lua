--[[
    公告界面内容
]]

local class_name = "NoticeContentPanel"
NoticeContentPanel = BaseClass(nil, class_name)

function NoticeContentPanel:OnInit()

end

function NoticeContentPanel:OnShow()

end

function NoticeContentPanel:OnHide()

end

---
---@param Data NoticeItem
function NoticeContentPanel:UpdateUI(Data)
    if not (Data and Data.Id)  then
        CError("NoticeContentPanel Param Error",true)
        return
    end
    if Data.Pic ~= "" then
        self.View.ImgPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_1,Data.Pic)
    else
       self.View.ImgPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    self.View.RichTextBlock_1:SetText(StringUtil.Format(Data.Content))
end

return NoticeContentPanel
