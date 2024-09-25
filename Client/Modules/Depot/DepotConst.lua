--[[
    仓库的常量定义
]]
DepotConst = 
{

}

--特殊的物品ID
DepotConst.ITEM_ID_EXP = 910000000
DepotConst.ITEM_ID_GOLDEN = 900000001
DepotConst.ITEM_ID_DIAMOND = 900000002
DepotConst.ITEM_ID_DIAMOND_GIFT = 999999999
DepotConst.ITEM_ID_FRIEND_INTIMACY = 700000135 -- 好友亲密度道具 - 鲜花

-- 时间文本显示字色
DepotConst.TimeTextColor = {
    Normal = "F5EFDF",
    Warning = "D94445", -- 临期 小于1天(24小时)
}


--物品子类型
DepotConst.ItemSubType = {
    --英雄拥有权
    ["Hero"] = "Hero",
    --皮肤
    ["Skin"] = "Skin",
    --武器拥有权
    ["Weapon"] = "Weapon",
    --载具拥有权
    ["Vehicle"] = "Vehicle",
    --头像
    ["Head"] = "Head",
    --头像边框
    ["HeadFrame"] = "HeadFrame",
    --头像挂件
    ["HeadWidget"] = "HeadWidget",
    --皮肤部件
    ["SkinPart"] = "SkinPart",
    --背景板
    ["Background"] = "Background",
    --特效
    ["Effect"] = "Effect",
    --角色姿势
    ["Pose"] = "Pose",
    --贴纸
    ["Sticker"] = "Sticker",
}