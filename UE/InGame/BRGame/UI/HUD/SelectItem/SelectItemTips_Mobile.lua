local SelectItemTips_Mobile = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Init/Destroy ------------------------------------

function SelectItemTips_Mobile:OnInit()
	UserWidget.OnInit(self)
end

function SelectItemTips_Mobile:OnDestroy()
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function SelectItemTips_Mobile:InitData()
	--self.Parameters = InParameters
	
end

function SelectItemTips_Mobile:SetItemTxtName(InNameStr)
    self.TxtName:SetText(InNameStr)
end

function SelectItemTips_Mobile:SetTips(InTipsStr)
    -- 手机版没有这个，直接返回，但是这个函数必须保留
    return
end

function SelectItemTips_Mobile:UpdateVisibility(InTxtNameVis, InTipsTxtVis, InMouseLVis, InMouseMVis, InMouseRVis)
    self.TxtName:SetVisibility(InTxtNameVis)
end


-------------------------------------------- Callable ------------------------------------

return SelectItemTips_Mobile