--[[
    世界观界面内容
]]

local class_name = "NarrativeContentPanel"
NarrativeContentPanel = BaseClass(nil, class_name)

function NarrativeContentPanel:OnInit()

end

function NarrativeContentPanel:OnShow()

end

function NarrativeContentPanel:OnHide()

end

function NarrativeContentPanel:UpdateUI(Param)
    if not (Param and Param.TabId and Param.ContentId)  then
        CError("NarrativeContentPanel Param Error",true)
        return
    end
    local ContentCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_NarrativeCfg,{Cfg_NarrativeCfg_P.TabId,Cfg_NarrativeCfg_P.Id},{Param.TabId,Param.ContentId})
    if not ContentCfg then
        CWaring("NarrativeContentPanel ContentCfg Error, TabId = "..tostring(Param.TabId).." Id = "..tostring(Param.ContentId))
        return
    end
    if ContentCfg.Img1 ~= "" then
        self.View.ImgPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_1,ContentCfg.Img1)
    else
       self.View.ImgPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    self.View.RichTextBlock_1:SetText(StringUtil.Format(ContentCfg.Content1 or ""))
end

return NarrativeContentPanel
