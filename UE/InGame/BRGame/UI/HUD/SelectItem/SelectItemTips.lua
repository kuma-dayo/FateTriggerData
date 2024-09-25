local SelectItemTips = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Init/Destroy ------------------------------------

function SelectItemTips:OnInit()
	UserWidget.OnInit(self)
end

function SelectItemTips:OnDestroy()
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function SelectItemTips:InitData()
	--
	
end

function SelectItemTips:SetItemTxtName(InNameStr)
    self.TxtName:SetText(InNameStr)
end

function SelectItemTips:SetTips(InTipsStr)
    self.TxtTips:SetText(InTipsStr)
end

function SelectItemTips:UpdateVisibility(InTxtNameVis, InTipsTxtVis, InMouseLVis, InMouseMVis, InMouseRVis)
    self.TxtName:SetVisibility(InTxtNameVis)
	self.TxtTips:SetVisibility(InTipsTxtVis)
	self.TrsMouseL:SetVisibility(InMouseLVis)
	self.TrsMouseM:SetVisibility(InMouseMVis)
	self.TrsMouseR:SetVisibility(InMouseRVis)
end

-------------------------------------------- Callable ------------------------------------

return SelectItemTips
