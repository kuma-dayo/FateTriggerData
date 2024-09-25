--[[
    角色展示板，每一层UMG的基类
]]
local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
end

function M:OnShow(msg)

end

function M:OnHide()

end

function M:UpdateUI()

end

function M:SetDisplayId(DisplayId)
    self.DisplayId = DisplayId
end

function M:SetLinkTabId(TabId)
    self.TabId = TabId
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayBoardTabConfig, TabId)
    if Cfg then
        self.bOpen = Cfg[Cfg_HeroDisplayBoardTabConfig_P.IsOpen]
        if self.bOpen then
            self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            -- self:SetVisibility(UE.ESlateVisibility.Hidden)
            self:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        CError(string.format("WBP_HeroDisplayLayerBase:SetLinkTabId, Get Cfg_HeroDisplayBoardTabConfig Failed !! TabId=[%s]", tostring(TabId)))
    end
end

function M:GetLinkTabId()
    return self.TabId
end

function M:GetIsOpen()
    return self.bOpen
end

function M:GetDisplayId()
    return self.DisplayId
end



return M