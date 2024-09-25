--
-- 物品系统-配件-助手
--
-- @COMPANY	ByteDance
-- @AUTHOR	杨洋
-- @DATE	2022.05.29
--

require("Common.Framework.CommFuncs")

local ItemAttachmentHelper = _G.ItemAttachmentHelper or {}

-------------------------------------------- Config/Enum ------------------------------------

-- 物品属性名定义
ItemAttachmentHelper.NUsefulReason = {
    AttachWeapon1 = "AttachWeapon1",
    AttachWeapon2 = "AttachWeapon2",
    AttachAnyWeapon = "AttachAnyWeapon",
    UnEquipFromWeapon = "UnEquipFromWeapon",
    UnEquipDueToWeaponDetach = "UnEquipDueToWeaponDetach",
    SwapDetachStep_1 = "SwapDetachStep_1",
    SwapDetachStep_2 = "SwapDetachStep_2",
    EquippedSwapWeapon_1 = "EquippedSwapWeapon_1",
    EquippedSwapWeapon_2 = "EquippedSwapWeapon_2",
}
SetErrorIndex(ItemAttachmentHelper.NUsefulReason)

-------------------------------------------- Common ------------------------------------

function ItemAttachmentHelper.BB()
end

function ItemAttachmentHelper.AA()

end

-------------------------------------------- Debug ------------------------------------

-- 
_G.ItemAttachmentHelper = ItemAttachmentHelper
return ItemAttachmentHelper
