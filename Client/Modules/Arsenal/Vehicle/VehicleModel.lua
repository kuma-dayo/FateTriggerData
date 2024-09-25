--[[
    局外载具数据模型
]]
local super = GameEventDispatcher;
local class_name = "VehicleModel";
VehicleModel = BaseClass(super, class_name);



--载具展示
VehicleModel.ON_UPDATE_VEHICLE_SKIN_SHOW = "ON_UPDATE_VEHICLE_SKIN_SHOW"
VehicleModel.ON_SELECT_VEHICLE = "ON_SELECT_VEHICLE"
--载具皮肤装备
VehicleModel.ON_SELECT_VEHICLE_SKIN = "ON_SELECT_VEHICLE_SKIN"
VehicleModel.ON_UNLOCK_VEHICLE_SKIN = "ON_UNLOCK_VEHICLE_SKIN"
--载具皮肤贴纸
VehicleModel.ON_OPEN_VEHICLE_SKIN_STICKER_SHOW = "ON_OPEN_VEHICLE_SKIN_STICKER_SHOW"
VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER_SHOW = "ON_UPDATE_VEHICLE_SKIN_STICKER_SHOW"
VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER_LIST = "ON_UPDATE_VEHICLE_SKIN_STICKER_LIST"
VehicleModel.ON_BUY_VEHICLE_SKIN_STICKER_LIST = "ON_BUY_VEHICLE_SKIN_STICKER_LIST"

VehicleModel.ON_ADD_VEHICLE_SKIN_STICKER = "ON_ADD_VEHICLE_SKIN_STICKER"
VehicleModel.ON_REMOVE_VEHICLE_SKIN_STICKER = "ON_REMOVE_VEHICLE_SKIN_STICKER"
VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER = "ON_UPDATE_VEHICLE_SKIN_STICKER"



--车牌摇号结果
VehicleModel.ON_LICENSEPLATE_LOTTERY_RESULT = "ON_LICENSEPLATE_LOTTERY_RESULT"
--选择车牌
VehicleModel.ON_LICENSEPLATE_SELECT = "ON_LICENSEPLATE_SELECT"



function VehicleModel:__init()
    self:_dataInit()
end

function VehicleModel:_dataInit()
    --[[
        当前选中的载具ID
    ]]
    self.SelectVehicleId = 0
    --[[
        每个戴具当前使用的皮肤ID
    ]]
    self.VehicleId2SelectSkinId = {}
    --[[
        每个戴具车牌信息
    ]]
    self.VehicleId2LicensePlate = {}
    --[[
        每个戴具车牌摇号次数
    ]]
    self.VehicleId2PlateLotteryCount = {}
    --[[
        载具皮肤-贴纸列表
    ]]
    self.VehicleSkinId2StickerList = {}
    --[[
        贴纸-载具皮肤列表
    ]]
    self.StickerId2VehicleSkinList = {}
    
    self:InitVehicleSkinTypeConfig()
end

--[[
    玩家登出
]]
function VehicleModel:OnLogout(data)
    CWaring("VehicleModel OnLogout")
    self:_dataInit()
end


--[[
    初始化载具皮肤贴纸类型配置
]]--
function VehicleModel:InitVehicleSkinTypeConfig()
    self.VehicleSkinStickerTypeList = {}
    self.VehicleSkinStickerType2IdList = {}
    
    local CfgList = G_ConfigHelper:GetDict(Cfg_VehicleSkinStickerType)    
    for _, Cfg in pairs(CfgList) do
        table.insert(self.VehicleSkinStickerTypeList, Cfg[Cfg_VehicleSkinStickerType_P.TypeId])
    end

    for _, Type in pairs(self.VehicleSkinStickerTypeList) do
        local CfgWC = G_ConfigHelper:GetDict(Cfg_VehicleSkinSticker)
        for _, Cfg in pairs(CfgWC) do
            if Type == 0 or Cfg[Cfg_VehicleSkinSticker_P.StickerType] == Type then 
                self.VehicleSkinStickerType2IdList[Type] = self.VehicleSkinStickerType2IdList[Type] or {} 
                table.insert(self.VehicleSkinStickerType2IdList[Type], Cfg[Cfg_VehicleSkinSticker_P.StickerId])
            end
        end 
    end
end


--获取载具对应的选中皮肤
function VehicleModel:GetVehicleSelectSkinId(VehicleId)
    if not self.VehicleId2SelectSkinId[VehicleId] then
        self.VehicleId2SelectSkinId[VehicleId] = self:GetVehicleDefaultSkinId(VehicleId)
    end
    return self.VehicleId2SelectSkinId[VehicleId]
end

--载具读表：获取默认的皮肤
function VehicleModel:GetVehicleDefaultSkinId(VehicleId)
    local VehicleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleConfig, Cfg_VehicleConfig_P.VehicleId, VehicleId)
    return VehicleCfg and VehicleCfg[Cfg_VehicleConfig_P.DefaultSkinId] or 0
end

--获取载具的车牌信息
function VehicleModel:GetVehicleLicensePlate(VehicleId)
    return self.VehicleId2LicensePlate[VehicleId] or ""
end

--获取载具车牌摇号次数
function VehicleModel:GetVehicleLotteryCount(VehicleId)
    return self.VehicleId2PlateLotteryCount[VehicleId] or 0
end

--[[
    展示武器：首选当前已装备皮肤，否则选择默认皮肤
]]
function VehicleModel:GetWeaponSkinId(WeaponId)
    return self:GetWeaponSelectSkinId(WeaponId)
end

--[[
    展示载具：首选当前已装备皮肤，否则选择默认皮肤
]]
function VehicleModel:GetVehicleSkinId(VehicleId)
    return self:GetVehicleSelectSkinId(VehicleId)
end


--[[
    检查载具皮肤是否解锁
]]
function VehicleModel:HasVehicleSkin(VehicleSkinId)
    local SkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig,
    Cfg_VehicleSkinConfig_P.SkinId, VehicleSkinId)
    if SkinCfg == nil then
        return false
    end
    local SkinItemId = SkinCfg[Cfg_VehicleSkinConfig_P.ItemId]
    local ItemCount = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(SkinItemId) or 0
    return ItemCount > 0
end

--[[
    检查载具皮肤贴纸Id是否解锁
]]
function VehicleModel:HasVehicleSkinSticker(VehicleSkinStickerId)
    local SkinStickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, VehicleSkinStickerId)
    if SkinStickerCfg == nil then
        return false
    end
    local ItemId = SkinStickerCfg[Cfg_VehicleSkinSticker_P.ItemId]
    local ItemCount = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) or 0
    return ItemCount > 0
end

--[[
    检查载具皮肤贴纸Id是否能直接购买
]]
function VehicleModel:CanBuyVehicleSkinSticker(VehicleSkinStickerId)
    local SkinStickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, VehicleSkinStickerId)
    if SkinStickerCfg == nil then
        return false
    end
    return SkinStickerCfg[Cfg_VehicleSkinSticker_P.UnlockFlag] == 1
end


--[[
    获取载具皮肤的质量
]]
function VehicleModel:GetVehicleSkinQuality(VehicleSkinId)
    local SkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig,
    Cfg_VehicleSkinConfig_P.SkinId, VehicleSkinId)
    if SkinCfg == nil then
        return 0
    end
    local ItemCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_ItemConfig, 
        Cfg_ItemConfig_P.ItemId, SkinCfg[Cfg_WeaponSkinConfig_P.ItemId])

    if ItemCfg == nil then
        return 0
    end
    return ItemCfg[Cfg_ItemConfig_P.Quality] or 0
end

--[[
    获取载具皮肤贴纸的质量
]]
function VehicleModel:GetVehicleSkinStickerQuality(VehicleSkinStickerId)
    local SkinStickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, VehicleSkinStickerId)
    if SkinStickerCfg == nil then
        return 0
    end
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, SkinStickerCfg[Cfg_VehicleSkinSticker_P.ItemId])
    if ItemCfg == nil then
        return 0
    end
    return ItemCfg[Cfg_ItemConfig_P.Quality] or 0
end


--获取展示载具ID
function VehicleModel:GetSelectVehicleId()
    return self.SelectVehicleId
end

--更新展示载具
function VehicleModel:SetSelectVehicleId(SelectVehicleId)
    if self.SelectVehicleId == SelectVehicleId then
        return
    end
    self.SelectVehicleId = SelectVehicleId
    self:DispatchType(VehicleModel.ON_SELECT_VEHICLE)
end

--更新载具对应皮肤列表
function VehicleModel:SetVehicleSkinList(VehicleSkinList)
    for _, v in ipairs(VehicleSkinList) do
        self.VehicleId2SelectSkinId[v.VehicleId] = v.VehicleSkinId
        self.VehicleId2LicensePlate[v.VehicleId] = v.LicensePlate
        self.VehicleId2PlateLotteryCount[v.VehicleId] = v.LotteryCount
    end
    self:DispatchType(VehicleModel.ON_SELECT_VEHICLE_SKIN)
end

--更新武器对应的选中皮肤
function VehicleModel:UpdateVehicleId2SkinId(VehicleId, VehicleSkinId)
    if self.VehicleId2SelectSkinId[VehicleId] == VehicleSkinId then
        return
    end
    self.VehicleId2SelectSkinId[VehicleId] = VehicleSkinId
    self:DispatchType(VehicleModel.ON_SELECT_VEHICLE_SKIN)
end

--更新载具车牌
function VehicleModel:UpdateVehicleId2LicensePlate(VehicleId, LicensePlate)
    self.VehicleId2LicensePlate[VehicleId] = LicensePlate
end

--更新载具车牌摇号次数
function VehicleModel:UpdateVehicleId2PlateLotteryCount(VehicleId, PlateLotteryCount)
    self.VehicleId2PlateLotteryCount[VehicleId] = PlateLotteryCount
end

--登录下发载具贴纸列表
function VehicleModel:SetVehicleSkinStickerList(VehiclSkinStickMap)
    for VehicleSkinId, VehicleStickSkinData in pairs(VehiclSkinStickMap) do
        self.VehicleSkinId2StickerList[VehicleSkinId] = self.VehicleSkinId2StickerList[VehicleSkinId] or {}
        for _, V in ipairs(VehicleStickSkinData.StickDataList) do
            local T = JSON:decode(V.CustomData)
            table.insert(self.VehicleSkinId2StickerList[VehicleSkinId], 
            {
                StickerId = V.StickerId,
                Scale = T.Scale,
                Rotator = T.Rotator,
                Position = T.Position,
                RotateAngle = T.RotateAngle,
                ScaleLength = T.ScaleLength,
                Restore = T.Restore,
                Slot = T.Slot,
            })
        end
    end

    for VehicleSkinId, StickerList in pairs(self.VehicleSkinId2StickerList) do
        for K, V in pairs(StickerList) do
            self.StickerId2VehicleSkinList[V.StickerId] = self.StickerId2VehicleSkinList[V.StickerId] or {}
            table.insert(self.StickerId2VehicleSkinList[V.StickerId], 
            {
                VehicleSkinId = VehicleSkinId,
                Scale = V.Scale,
                Rotator = V.Rotator,
                Position = V.Position,
                RotateAngle = V.RotateAngle,
                ScaleLength = V.ScaleLength,
                Restore = V.Restore,
                Slot = V.Slot,
            })
        end
    end
end


--更新某个载具皮肤的贴纸数据
function VehicleModel:UpdateVehicleSkinId2StickerList(VehicleSkinId, StickerList)
    self.VehicleSkinId2StickerList[VehicleSkinId] =  {}
    self.StickerId2VehicleSkinList = {}

    self.VehicleSkinId2StickerList[VehicleSkinId] = StickerList
    for VehicleSkinId, StickerList in pairs(self.VehicleSkinId2StickerList) do
        for _, V in ipairs(StickerList) do
            self.StickerId2VehicleSkinList[V.StickerId] = self.StickerId2VehicleSkinList[V.StickerId] or {}
            table.insert(self.StickerId2VehicleSkinList[V.StickerId],   
            {
                VehicleSkinId = VehicleSkinId,
                Scale = V.Scale,
                Rotator = V.Rotator,
                Position = V.Position,
                RotateAngle = V.RotateAngle,
                ScaleLength = V.ScaleLength,
                Restore = V.Restore,
                Slot = V.Slot,
            })
        end
    end
end

function VehicleModel:GetVehicleSkinId2StickerList(VehicleSkinId)
    return self.VehicleSkinId2StickerList[VehicleSkinId] or {}
end


--[[
    通过插槽来获取贴纸，只有一个
]]
function VehicleModel:GetVehicleSkinStickerBySlot(VehicleSkinId, Slot)
    local StickerList = self:GetVehicleSkinId2StickerList(VehicleSkinId)
    for _, V in ipairs(StickerList) do
        if V.Slot == Slot then
            return V
        end
    end
end

function VehicleModel:GetStickerId2VehicleSkinList(StickerId)
    return self.StickerId2VehicleSkinList[StickerId] or {}
end

function VehicleModel:IsVehicleSkinStickerSlotFull(VehicleSkinId)
    local StickerIdList = self.VehicleSkinId2StickerList[VehicleSkinId] or {}
    return #StickerIdList >= self:GetVehilceSkinStickerMaxSlot(VehicleSkinId)
end

function VehicleModel:IsStickerEnough(StickerId)
   local UsedStickerListNum = #self:GetStickerId2VehicleSkinList(StickerId)
   local ItemNum = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(StickerId) or 0
   return ItemNum > UsedStickerListNum
end

--[[
    被其他皮肤使用的贴纸数量
]]
function VehicleModel:GetStickerNumUsedByOtherVehicleSkin(VehicleSkinId, StickerId)
    local StickerUsedByOtherVehicleSkin  = {}
    local AllSticker2VehicleSkinList = self:GetStickerId2VehicleSkinList(StickerId)
    for _, V in ipairs(AllSticker2VehicleSkinList) do
        if V.VehicleSkinId ~= VehicleSkinId then
            table.insert(StickerUsedByOtherVehicleSkin, V)
        end
    end
    return #StickerUsedByOtherVehicleSkin
end


function VehicleModel:GetVehilceSkinEmptyStickerSlot(VehicleSkinId)
    local StickerList = self.VehicleSkinId2StickerList[VehicleSkinId] or {}
    local OccupiedSlotList = {}
    for _, v in ipairs(StickerList) do 
        OccupiedSlotList[v.Slot] = v.Slot
    end
    for Slot=1, self:GetVehilceSkinStickerMaxSlot(VehicleSkinId) do
        if not OccupiedSlotList[Slot] then
            return Slot
        end
    end
    return 0
end


function VehicleModel:GetVehilceSkinStickerMaxSlot(VehicleSkinId)
    local VehicleSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinConfig, VehicleSkinId)
    return VehicleSkinCfg and VehicleSkinCfg[Cfg_VehicleSkinConfig_P.StickerSlotNum] or 0
end


return VehicleModel