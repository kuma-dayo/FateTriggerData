require "UnLua"

local ChooseWeapon_ItemSingleUI = Class("Common.Framework.UserWidget")

    
function ChooseWeapon_ItemSingleUI:InitItemId(ItemId, IconSoftObjPtr)
    self.GUIImage:SetBrushFromSoftTexture(IconSoftObjPtr, false)
end

--
return ChooseWeapon_ItemSingleUI
 










