require "UnLua"

local SinglePickupWeapon = Class()

function SinglePickupWeapon:OnInit2(Test)
    -- local Num = self.PickDropItemData.ItemAttribute:Length()
    -- local TargetIndex = nil
    -- for i = 1, Num do
    --     local ItemAttribute = self.PickDropItemData.ItemAttribute:GetRef(Num)
    --     if ItemAttribute.AttributeName == GameDefine.NItemAttribute.WeaponHandleID then
    --         TargetIndex = i
    --         break
    --     end
    -- end
    -- if TargetIndex then
    --     -- 这里移除是因为，武器在丢弃时，则立刻销毁物品
    --     self.PickDropItemData.ItemAttribute:Remove(TargetIndex)
    -- end
end

return SinglePickupWeapon