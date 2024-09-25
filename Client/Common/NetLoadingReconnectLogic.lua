local M = Class()

function M:Construct()
end

function M:Destruct()
    self:Hide()
    NetLoading.ReconnectInstance = nil
    self:Release()
end

function M:Show()
    self:SetVisibility(UE.ESlateVisibility.Visible)
    if self.VXE_HUD_Reconnection then
        self:VXE_HUD_Reconnection()
    end
end

function M:Hide()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return M