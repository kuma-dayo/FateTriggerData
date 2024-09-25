--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ES_EnhanceTitle = Class("Common.Framework.UserWidget")

function ES_EnhanceTitle:OnInit()
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.BAG_WhenShowHideBag,          Func = self.CloseBagPanel,                  bCppMsg = true },
    }
    UserWidget.OnInit(self)
end

function ES_EnhanceTitle:OnShow()
    local UIManager = UE.UGUIManager.GetUIManager(self)
    local IsBagOpen = UIManager:IsAnyDynamicWidgetShowByKey("UMG_Bag")
    if self.WS_InputHint then
        self.WS_InputHint:SetActiveWidgetIndex(IsBagOpen and 1 or 0)
    end
end

function ES_EnhanceTitle:OnDestroy()
	UserWidget.OnDestroy(self)
end

function ES_EnhanceTitle:CloseBagPanel(IsVisible)
    self.WS_InputHint:SetActiveWidgetIndex(IsVisible and 1 or 0)
end

return ES_EnhanceTitle
