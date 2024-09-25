--[[
    局外武器数据模型
]]
local super = GameEventDispatcher;
local class_name = "WeaponModel";
WeaponModel = BaseClass(super, class_name);


--武器展示
WeaponModel.ON_SELECT_WEAPON = "ON_SELECT_WEAPON"
--武器皮肤装备
WeaponModel.ON_SELECT_WEAPON_SKIN = "ON_SELECT_WEAPON_SKIN"
--武器皮肤解锁
WeaponModel.ON_UNLOCK_WEAPON_SKIN = "ON_UNLOCK_WEAPON_SKIN"
--武器皮肤展示
WeaponModel.ON_UPDATE_WEAPON_SKIN_SHOW = "ON_UPDATE_WEAPON_SKIN_SHOW"
WeaponModel.ON_UPDATE_WEAPON_SKIN_HIDE = "ON_UPDATE_WEAPON_SKIN_HIDE"

--配件保留ID 
WeaponModel.RESERVED_ATTACHMENT_ID = 0
--配件皮肤保留ID
WeaponModel.RESERVED_ATTACHMENT_SKIN_ID = 0
--配件装配更新
WeaponModel.ON_SELECT_ATTACHMENT = "ON_SELECT_ATTACHMENT"
--配件皮肤装配更新
WeaponModel.ON_SELECT_ATTACHMENT_SKIN = "ON_SELECT_ATTACHMENT_SKIN"
--配件皮肤购买
WeaponModel.ON_BUY_ATTACHMENT_SKIN = "ON_BUY_ATTACHMENT_SKIN"

WeaponModel.ON_WEAPON_AVATAR_PREVIEW_UPDATE = "ON_WEAPON_AVATAR_PREVIEW_UPDATE"

--选中配件插槽
WeaponModel.ON_CLICK_SELECT_ATTACHMENT_SLOT = "ON_CLICK_SELECT_ATTACHMENT_SLOT"
WeaponModel.ON_CLICK_CLOSE_ATTACHMENT_SLOT = "ON_CLICK_CLOSE_ATTACHMENT_SLOT"
WeaponModel.ON_HOVER_SELECT_ATTACHMENT_SLOT = "ON_HOVER_SELECT_ATTACHMENT_SLOT"


function WeaponModel:__init()
    self:_dataInit()
end

function WeaponModel:_dataInit()
    --[[
        当前选中的武器ID
    ]]
    self.SelectWeaponId = 0
    --[[
        每把武器当前使用的皮肤ID
    ]]
    self.WeaponId2SelectSkinId = {}

    --配置缓存
    --[[
        每把武器对应的插槽列表
    ]]
    self.WeaponId2SlotTypeList = {}
    --[[
        每把武器的每个插槽下可装配的配件ID列表
    ]]
    self.WeaponId2Slot2PartIdList = {}
    self.WeaponId2Slot2SubType2PartId = {}
    --[[
        每个武器皮肤的每个插槽下可装备的配件皮肤ID列表
    ]]
    self.WeaponSkinId2Slot2PartSkinIdList = {}
    self.WeaponSkinId2Slot2SubType2SkinIdList = {}
    self.DefaultAttachmentSkinList = {}
    --每个皮肤ID，对应槽位，对应的默认皮的avatarId
    self.WeaponSkinId2Slot2BaseAvatarId = {}
    self.PartSkinId2PartId = {}
    --每个皮肤ID，对应槽位，对应的虚拟展示avatarId
    self.WeaponSkinId2Slot2VirtualAvatarId = {}
   

    --持久化数据
    --[[
        每把武器 对应 插槽 选中的  配件ID
        {
            [WeaponId] = {
                [Slot] = PartId
            }
        }
    ]]
    self.WeaponId2Slot2SelectPartId = {}
    self.WeaponId2SelectPartIdList = {}
    self.WeaponId2SelectPartIdListDirty = {};

    self:InitWeaponConfig()
    self:InitWeaponTypeConfig()
    self:InitWeaponPartSlotDefaultIconConfig()
end

--[[
    玩家登出
]]
function WeaponModel:OnLogout(data)
    CWaring("WeaponModel OnLogout")
    self:_dataInit()
end

--[[
    初始化武器模块相关配置
]]
function WeaponModel:InitWeaponConfig()
    self.WeaponId2SlotTypeList = {}
    self.WeaponId2Slot2PartIdList = {}
    self.WeaponId2Slot2SubType2PartId = {}
    self.WeaponSkinId2Slot2PartSkinIdList = {}
    self.WeaponSkinId2Slot2SubType2SkinIdList = {}
    self.WeaponSkinId2Slot2BaseAvatarId = {}
    self.PartSkinId2PartId = {}
    self.WeaponSkinId2Slot2VirtualAvatarId = {}

    local WeaponId2SlotTypeMap = {}
    local SuitWeaponIdList = {}
    local WeaponPartCfgs = G_ConfigHelper:GetDict(Cfg_WeaponPartConfig)
    for _, Cfg in ipairs(WeaponPartCfgs) do
        local SuitWeaponIdList = Cfg[Cfg_WeaponPartConfig_P.SuitWeaponList]--CommonUtil.SplitStringIdListToNumList(Cfg[Cfg_WeaponPartConfig_P.SuitWeaponList])
        local PartId =  Cfg[Cfg_WeaponPartConfig_P.PartId]
        local SlotType =  Cfg[Cfg_WeaponPartConfig_P.SlotType]
        local SubType =  Cfg[Cfg_WeaponPartConfig_P.SubType]
        for Index, WeaponId in pairs(SuitWeaponIdList) do
            WeaponId2SlotTypeMap[WeaponId] = WeaponId2SlotTypeMap[WeaponId] or {}
            WeaponId2SlotTypeMap[WeaponId][SlotType] = 1

            self.WeaponId2Slot2PartIdList[WeaponId] = self.WeaponId2Slot2PartIdList[WeaponId] or {}
            self.WeaponId2Slot2PartIdList[WeaponId][SlotType] = self.WeaponId2Slot2PartIdList[WeaponId][SlotType] or {}
            table.insert(self.WeaponId2Slot2PartIdList[WeaponId][SlotType],PartId)

            self.WeaponId2Slot2SubType2PartId[WeaponId] = self.WeaponId2Slot2SubType2PartId[WeaponId] or {}
            self.WeaponId2Slot2SubType2PartId[WeaponId][SlotType] = self.WeaponId2Slot2SubType2PartId[WeaponId][SlotType] or {}
            self.WeaponId2Slot2SubType2PartId[WeaponId][SlotType][SubType] = PartId
        end
    end
    for WeaponId,Slot2Value in pairs(WeaponId2SlotTypeMap) do
        for SlotType,Value in pairs(Slot2Value) do
            self.WeaponId2SlotTypeList[WeaponId] = self.WeaponId2SlotTypeList[WeaponId]  or {}
            table.insert(self.WeaponId2SlotTypeList[WeaponId],SlotType)
        end
    end

    local WeaponSkinConfigs = G_ConfigHelper:GetDict(Cfg_WeaponSkinConfig)
    for _, Cfg in ipairs(WeaponSkinConfigs) do
        local WeaponSkinId = Cfg[Cfg_WeaponSkinConfig_P.SkinId]
        local WeaponId = Cfg[Cfg_WeaponSkinConfig_P.WeaponId]
        local SuitPartSkinIdList = Cfg[Cfg_WeaponSkinConfig_P.ExtendPartSkinIdList]--CommonUtil.SplitStringIdListToNumList(Cfg[Cfg_WeaponSkinConfig_P.ExtendPartSkinIdList])
        for Index, PartSkinId in pairs(SuitPartSkinIdList) do
            local CfgPartSkin = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSkinConfig,PartSkinId)
            local SlotType = CfgPartSkin[Cfg_WeaponPartSkinConfig_P.SlotType]
            local SubType = CfgPartSkin[Cfg_WeaponPartSkinConfig_P.SubType]

            self.WeaponSkinId2Slot2PartSkinIdList[WeaponSkinId] = self.WeaponSkinId2Slot2PartSkinIdList[WeaponSkinId] or {}
            self.WeaponSkinId2Slot2PartSkinIdList[WeaponSkinId][SlotType] = self.WeaponSkinId2Slot2PartSkinIdList[WeaponSkinId][SlotType] or {}

            table.insert(self.WeaponSkinId2Slot2PartSkinIdList[WeaponSkinId][SlotType],PartSkinId)

            self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId] = self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId] or {}
            self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId][SlotType] = self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId][SlotType] or {}
            self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId][SlotType][SubType] = self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId][SlotType][SubType] or {}

            table.insert(self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId][SlotType][SubType],PartSkinId)

            local PartId = self.WeaponId2Slot2SubType2PartId[WeaponId][SlotType][SubType]
            self.PartSkinId2PartId[PartSkinId] = PartId
        end

        local BasePartSkinIdLis = Cfg[Cfg_WeaponSkinConfig_P.BasePartSkinIdList]
        for Index, PartSkinId in pairs(BasePartSkinIdLis) do
            local CfgPartSkin = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSkinConfig,PartSkinId)
            local SlotType = CfgPartSkin[Cfg_WeaponPartSkinConfig_P.SlotType]

            self.WeaponSkinId2Slot2BaseAvatarId[WeaponSkinId] = self.WeaponSkinId2Slot2BaseAvatarId[WeaponSkinId] or {}
            self.WeaponSkinId2Slot2BaseAvatarId[WeaponSkinId][SlotType] = PartSkinId
        end

        local VirtualPartSkinIdLis = Cfg[Cfg_WeaponSkinConfig_P.VirtualPartSkinIdList]
        if not VirtualPartSkinIdLis then
            -- 先屏蔽报错
            return
        end
        for Index, PartSkinId in pairs(VirtualPartSkinIdLis) do
            local CfgPartSkin = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSkinConfig,PartSkinId)
            local SlotType = CfgPartSkin[Cfg_WeaponPartSkinConfig_P.SlotType]

            self.WeaponSkinId2Slot2VirtualAvatarId[WeaponSkinId] = self.WeaponSkinId2Slot2VirtualAvatarId[WeaponSkinId] or {}
            self.WeaponSkinId2Slot2VirtualAvatarId[WeaponSkinId][SlotType] = PartSkinId
        end
        
    end
end

--[[
    初始化武器类型配置
]]--
function WeaponModel:InitWeaponTypeConfig()
    self.WeaponTypeList = {}
    self.WeaponType2IdList = {}
    
    local CfgList = G_ConfigHelper:GetDict(Cfg_WeaponDetailType)    
    for _, Cfg in pairs(CfgList) do
        table.insert(self.WeaponTypeList, Cfg[Cfg_WeaponDetailType_P.TypeID])
    end

    for _, WeaponType in pairs(self.WeaponTypeList) do
        local CfgWC = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponConfig, Cfg_WeaponConfig_P.IsShow, true)
        for _, Cfg in pairs(CfgWC) do
            if WeaponType == 0 or Cfg[Cfg_WeaponConfig_P.WeaponType] == WeaponType then 
                self.WeaponType2IdList[WeaponType] = self.WeaponType2IdList[WeaponType] or {} 
                table.insert(self.WeaponType2IdList[WeaponType], Cfg[Cfg_WeaponConfig_P.WeaponId])
            end
        end 
    end
end

--[[
    初始化武器槽位默认的图标
]]
function WeaponModel:InitWeaponPartSlotDefaultIconConfig()
    self.WeaponId2Slot2DefaultIconId = {}

    local CfgList = G_ConfigHelper:GetDict(Cfg_WeaponPartSlotDefaultIconConfig)    
    for _, Cfg in pairs(CfgList) do
        local SuitWeaponIdList = Cfg[Cfg_WeaponPartSlotDefaultIconConfig_P.SuitWeaponList]
        local SlotType =  Cfg[Cfg_WeaponPartSlotDefaultIconConfig_P.Slot]

        for Index, WeaponId in pairs(SuitWeaponIdList) do
            self.WeaponId2Slot2DefaultIconId[WeaponId] = self.WeaponId2Slot2DefaultIconId[WeaponId] or {}
            self.WeaponId2Slot2DefaultIconId[WeaponId][SlotType] = Cfg[Cfg_WeaponPartSlotDefaultIconConfig_P.IconId]
        end
    end
end

--获取配件插槽默认图标
function WeaponModel:GetWeaponPartSlotDefaultIcon(WeaponId, Slot)
    local DefaultIconId = self.WeaponId2Slot2DefaultIconId[WeaponId] and  self.WeaponId2Slot2DefaultIconId[WeaponId][Slot] or 0
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSlotDefaultIconConfig, DefaultIconId)
    return Cfg and Cfg[Cfg_WeaponPartSlotDefaultIconConfig_P.SlotDefaultIcon] or ""
end

function WeaponModel:GetPartSkinIdListByWeaponAndSlot(WeaponId,SlotType)
    local PartSkinIdList = self.WeaponSkinId2Slot2PartSkinIdList[WeaponId] and self.WeaponSkinId2Slot2PartSkinIdList[WeaponId][SlotType] or {}
    table.sort(PartSkinIdList, function(a ,b)
        local QualityA = self:GetWeaponPartSkinQuality(a)
        local QualityB = self:GetWeaponPartSkinQuality(b)
        if QualityA ~= QualityB then 
            return QualityA < QualityB
        end
        return a < b
    end)
    return PartSkinIdList
end

function WeaponModel:GetWeaponPartSkinQuality(PartSkinId)
    local WeaponPartSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponPartSkinConfig,
        Cfg_WeaponPartSkinConfig_P.PartSkinId, PartSkinId)
    if WeaponPartSkinCfg == nil then
        return 0
    end
    local ItemCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_ItemConfig, 
        Cfg_ItemConfig_P.ItemId, WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.ItemId])

    if ItemCfg == nil then
        return 0
    end
    return ItemCfg[Cfg_ItemConfig_P.Quality]
end

--获取展示武器ID
function WeaponModel:GetSelectWeaponId()
    return self.SelectWeaponId
end

--更新展示武器ID
function WeaponModel:SetSelectWeaponId(SelectWeaponId)
    if SelectWeaponId == self.SelectWeaponId then
        return
    end
    self.SelectWeaponId = SelectWeaponId
    self:DispatchType(WeaponModel.ON_SELECT_WEAPON)
end

--更新武器对应的选中皮肤列表
function WeaponModel:SetWeaponSkinList(WeaponSkinList)
    for _, v in ipairs(WeaponSkinList) do
        self.WeaponId2SelectSkinId[v.WeaponId] = v.WeaponSkinId
    end
end

--更新武器对应的选中皮肤
function WeaponModel:UpdateWeaponId2SkinId(WeaponId, WeaponSkinId)
    if self.WeaponId2SelectSkinId[WeaponId] == WeaponSkinId then
        return
    end
    self.WeaponId2SelectSkinId[WeaponId] = WeaponSkinId
    self:DispatchType(WeaponModel.ON_SELECT_WEAPON_SKIN)
end

--获取武器对应的选中皮肤
function WeaponModel:GetWeaponSelectSkinId(WeaponId)
    if not self.WeaponId2SelectSkinId[WeaponId] then
        self.WeaponId2SelectSkinId[WeaponId] = self:GetWeaponDefaultSkinId(WeaponId)
    end
    return self.WeaponId2SelectSkinId[WeaponId]
end

--武器读表：获取默认的皮肤
function WeaponModel:GetWeaponDefaultSkinId(WeaponId)
    local WCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponConfig, Cfg_WeaponConfig_P.WeaponId, WeaponId)
    if WCfg ~= nil then 
        return WCfg[Cfg_WeaponConfig_P.DefaultSkinId]
    end
    return 0
end

--[[
    展示武器：首选当前已装备皮肤，否则选择默认皮肤
]]
function WeaponModel:GetWeaponSkinId(WeaponId)
    return self:GetWeaponSelectSkinId(WeaponId)
end


--[[
    展示用的：获取当前展示枪的装备皮肤
]]
function WeaponModel:GetWeaponShowSkinId()
    local WeaponId = self:GetSelectWeaponId()
    local SkinId = self:GetWeaponSkinId(WeaponId)
    return SkinId
end

--[[
    获取武器映射规则配置
    用于读取 每把武器情况下的  待机动画/LS 等等

    
    通过读取WeaponAnimMapping表获取英雄与枪械的对应持枪动作关系，
    通过枪的皮肤ID和英雄皮肤ID获取
        未找到  通过枪的皮肤ID和英雄默认皮肤ID获取
        未找到  通过枪的默认皮肤ID和英雄默认皮肤ID获取
    若某枪械皮肤ID或英雄皮肤ID未在表中配置，表明枪械皮肤或英雄皮肤应用所属枪械或英雄默认皮肤的持枪美术资源

    @param WeaponSkinId  武器皮肤ID
    @param HeroSkinId    英雄皮肤ID
]]
function WeaponModel:GetWeaponAnimMappingCfg(WeaponSkinId,HeroSkinId)
    if not WeaponSkinId or not HeroSkinId then
        CWaring("WeaponModel:GetWeaponAnimMappingCfg param error:" .. (not WeaponSkinId and " WeaponSkinId nil " or "") .. (not HeroSkinId and " HeroSkinId nil " or ""))
        return
    end
    local WeaponMappingCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_WeaponAnimMappingCfg,{Cfg_WeaponAnimMappingCfg_P.WeaponSkinId,Cfg_WeaponAnimMappingCfg_P.HeroSkinId},{WeaponSkinId,HeroSkinId})
    if not WeaponMappingCfg then
        CWaring("WeaponModel:GetWeaponAnimMappingCfg Try Fix With HeroSkinIdDefault")
        local CfgHeroSkin = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SkinId,HeroSkinId)
        local HeroId = CfgHeroSkin[Cfg_HeroSkin_P.HeroId]
        local CfgHero = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroConfig,Cfg_HeroConfig_P.Id,HeroId)
        local HeroSkinIdDefault = CfgHero[Cfg_HeroConfig_P.SkinId]

        WeaponMappingCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_WeaponAnimMappingCfg,{Cfg_WeaponAnimMappingCfg_P.WeaponSkinId,Cfg_WeaponAnimMappingCfg_P.HeroSkinId},{WeaponSkinId,HeroSkinIdDefault})
        if not WeaponMappingCfg then
            CWaring("WeaponModel:GetWeaponAnimMappingCfg Try Fix With HeroSkinIdDefault and with WeaponSkinIdDefault")
            local CfgWeaponSkin = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.SkinId,WeaponSkinId)
            local WeaponId = CfgWeaponSkin[Cfg_WeaponSkinConfig_P.WeaponId]
            local CfgWeapon = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponConfig,Cfg_WeaponConfig_P.WeaponId,WeaponId)
            local WeaponSkinIdDefault = CfgWeapon[Cfg_WeaponConfig_P.DefaultSkinId]

            WeaponMappingCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_WeaponAnimMappingCfg,{Cfg_WeaponAnimMappingCfg_P.WeaponSkinId,Cfg_WeaponAnimMappingCfg_P.HeroSkinId},{WeaponSkinIdDefault,HeroSkinIdDefault})

            if not WeaponMappingCfg then
                CError("WeaponModel:GetWeaponAnimMappingCfg not found,please check!",true)
            end
        end
    end
    return WeaponMappingCfg
end


--===============================武器配件=============================
--[[
    获取武器对应槽位的配件列表
]]
function WeaponModel:GetWeaponSlotAttachmentIdList(WeaponId, Slot)
    local AttachmentIdList = self.WeaponId2Slot2PartIdList[WeaponId] and self.WeaponId2Slot2PartIdList[WeaponId][Slot] or {}
    table.sort(AttachmentIdList, function(a, b)
        local QualityA = self:GetWeaponPartQuality(a)
        local QualityB = self:GetWeaponPartQuality(b)
        if QualityA ~= QualityB then 
            return QualityA < QualityB
        end
        return a < b
    end)
    return AttachmentIdList
end


function WeaponModel:GetWeaponPartQuality(PartId)
    local WeaponPartCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponPartConfig,
        Cfg_WeaponPartConfig_P.PartId, PartId)
    if WeaponPartCfg == nil then
        return 0
    end
    local ItemCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_ItemConfig, 
        Cfg_ItemConfig_P.ItemId, WeaponPartCfg[Cfg_WeaponPartSkinConfig_P.ItemId])

    if ItemCfg == nil then
        return 0
    end
    return ItemCfg[Cfg_ItemConfig_P.Quality]
end


--[[
    根据武器Id获取已装配的配件列表
]]
function WeaponModel:GetWeaponAttachmentIdList(WeaponId)
    if self.WeaponId2SelectPartIdListDirty[WeaponId] == nil or self.WeaponId2SelectPartIdListDirty[WeaponId] then
        self.WeaponId2SelectPartIdListDirty[WeaponId] = false

        self.WeaponId2SelectPartIdList[WeaponId] = {}
        if self.WeaponId2Slot2SelectPartId[WeaponId] then
            for Slot,PartId in pairs(self.WeaponId2Slot2SelectPartId[WeaponId]) do
                table.insert(self.WeaponId2SelectPartIdList[WeaponId],PartId)
            end
        end
    end
    return self.WeaponId2SelectPartIdList[WeaponId] and self.WeaponId2SelectPartIdList[WeaponId] or {}
end

function WeaponModel:GetPartIdByPartSkinId(PartSkinId)
    return self.PartSkinId2PartId[PartSkinId] or 0
end

function WeaponModel:GetSlotTypesListByWeaponId(WeaponId)
    return self.WeaponId2SlotTypeList[WeaponId]
end


--[[
    根据配件Id读表获取SlotType，SubType
]]
function WeaponModel:GetSlotTypeByAttachmentId(AttachmentId)
    if not AttachmentId or AttachmentId <= 0 then
        return 0, 0
    end
    local WeaponPartCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartConfig, AttachmentId)
    if WeaponPartCfg == nil then
        return 0, 0
    end
    local Slot = WeaponPartCfg[Cfg_WeaponPartConfig_P.SlotType]
    local SubType = WeaponPartCfg[Cfg_WeaponPartConfig_P.SubType]
    return Slot, SubType
end

--[[
    根据配件皮肤Id读表获取SlotType，SubType
]]
function WeaponModel:GetSlotTypeByAttachmentSkinId(AttachmentSkinId)
    if not AttachmentSkinId or AttachmentSkinId <= 0 then
        return 0, 0
    end
    local WeaponPartSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSkinConfig, AttachmentSkinId)
    if WeaponPartSkinCfg == nil then
        return 0, 0
    end
    local Slot = WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.SlotType]
    local SubType = WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.SubType]
    return Slot, SubType
end

--[[
   根据组装的AvatarId，找到SlotType
]]
function WeaponModel:GetSlotTypeByAvatarId(AvatarId)
    local Slot, _ = self:GetSlotTypeByAttachmentId(AvatarId)
    if Slot == 0 then
        Slot, _ = self:GetSlotTypeByAttachmentSkinId(AvatarId)
    end
    return Slot
end

--[[
    根据武器id, 配件Slot, SubType, 获取默认的配件皮肤Id
]]
function WeaponModel:GetDefaultAttachmentSkinId(WeaponId, Slot, SubType)
    local WeaponSkinId = self:GetWeaponSkinId(WeaponId)
    if self.DefaultAttachmentSkinList[WeaponSkinId] == nil then
        --缓冲武器默认配件列表
        self.DefaultAttachmentSkinList[WeaponSkinId] = {}
        local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, WeaponSkinId)
        local DefaultAttachmentSkinIdList = WeaponSkinCfg and WeaponSkinCfg[Cfg_WeaponSkinConfig_P.DefaultPartSkinIdList] or {} --CommonUtil.SplitStringIdListToNumList(WeaponSkinCfg[Cfg_WeaponSkinConfig_P.DefaultPartSkinIdList]) or {}
        for _, AttachmentSkinId in pairs(DefaultAttachmentSkinIdList) do
            local Slot, SubType = self:GetSlotTypeByAttachmentSkinId(AttachmentSkinId)
            if Slot ~= 0 then
                self.DefaultAttachmentSkinList[WeaponSkinId][AttachmentSkinId] = {Slot = Slot,SubType = SubType}
            end
        end
    end
    for K, V in pairs(self.DefaultAttachmentSkinList[WeaponSkinId]) do
        if V.Slot == Slot and V.SubType == SubType then
            return K
        end
    end
    return 0
end

--[[
    根据武器皮肤ID及插槽，返回当前需要展示的avatar组件ID

    返回0，表示未装配或者不需要装配
]]
function WeaponModel:GetAvatartIdShowByWeaponSkinIdAndSlotType(WeaponSkinId,SlotType,SubType)
    local AvatartId = 0
    if not AvatartId or AvatartId == 0 then
        if SubType and SubType > 0 then
            AvatartId = self:GetShowPartSkinIdBySlotTypeAndSubType(WeaponSkinId,SlotType,SubType)
        end
        if not AvatartId or AvatartId == 0 then
            AvatartId = self.WeaponSkinId2Slot2BaseAvatarId[WeaponSkinId] and self.WeaponSkinId2Slot2BaseAvatarId[WeaponSkinId][SlotType] or 0
        end
    end
    return AvatartId
end

function WeaponModel:GetShowPartSkinIdBySlotTypeAndSubType(WeaponSkinId,SlotType,SubType)
    if not WeaponSkinId or WeaponSkinId <= 0 then
        return 0
    end
    local AvatartId = 0
    local TaragetSubTypSkinIdList = self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId] and self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId][SlotType] and self.WeaponSkinId2Slot2SubType2SkinIdList[WeaponSkinId][SlotType][SubType] or {}
    local TaragetSubTypSkinId = TaragetSubTypSkinIdList and TaragetSubTypSkinIdList[1] or nil
    if TaragetSubTypSkinId and self:IsAttachmentSkinIdUnLocked(TaragetSubTypSkinId) then
        AvatartId = TaragetSubTypSkinId
    else
        local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, WeaponSkinId)
        AvatartId = self:GetDefaultAttachmentSkinId(WeaponSkinCfg[Cfg_WeaponSkinConfig_P.WeaponId],SlotType,SubType)
    end
    return (AvatartId > 0) and AvatartId or 0
end

function WeaponModel:GetSelectPartSkinIdBySelectPartId(WeaponSkinId,SlotType)
    if not WeaponSkinId or WeaponSkinId <= 0 then
        return 0
    end
    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, WeaponSkinId)
    local WeaponId = WeaponSkinCfg[Cfg_WeaponSkinConfig_P.WeaponId]
    local PartId = self:GetSlotEquipAttachmentId(WeaponId,SlotType)
    if PartId > 0 then
        local SlotTmp, SubType = self:GetSlotTypeByAttachmentId(PartId)

        local PartSkinId  = self:GetShowPartSkinIdBySlotTypeAndSubType(WeaponSkinId,SlotType,SubType)
        return PartSkinId
    else
        CWaring("WeaponModel:GetSelectPartSkinIdBySelectPartId PartId nil")
    end
    return 0
end

--[[
    获取指定武器皮肤槽位的虚拟配件Id
]]
function WeaponModel:GetVirtualAvatarIdIdBySkindAndSlot(WeaponSkinId,SlotType)
    return self.WeaponSkinId2Slot2VirtualAvatarId[WeaponSkinId] and self.WeaponSkinId2Slot2VirtualAvatarId[WeaponSkinId][SlotType] or 0
end
    

--[[
    --获取指定武器槽位的配件Id
]]
function WeaponModel:GetSlotEquipAttachmentId(WeaponId, Slot)
    return self.WeaponId2Slot2SelectPartId[WeaponId] and self.WeaponId2Slot2SelectPartId[WeaponId][Slot] or  0
end


--[[
    设置指定武器槽位的配件Id
]]
function WeaponModel:SetSlotEquipAttachmentId(WeaponId, Slot, AttachmentId)
    self.WeaponId2Slot2SelectPartId[WeaponId] = self.WeaponId2Slot2SelectPartId[WeaponId] or {}
    self.WeaponId2Slot2SelectPartId[WeaponId][Slot] = AttachmentId
    self.WeaponId2SelectPartIdListDirty[WeaponId] = true
end

--[[
   清空指定武器槽位的配件Id
]]
function WeaponModel:ClearSlotEquipAttachmentId(WeaponId)
    if not WeaponId then
        self.WeaponId2Slot2SelectPartId = {}
        self.WeaponId2Slot2SelectPartId = {}
        self.WeaponId2SelectPartIdListDirty = {}
    else
        self.WeaponId2Slot2SelectPartId[WeaponId] = {}
        self.WeaponId2Slot2SelectPartId[WeaponId] = {}
        self.WeaponId2SelectPartIdListDirty[WeaponId] = true
    end
end


--[[
    获取对应插槽对应的GameplayTag
]]
function WeaponModel:GetSlotTagBySlotType(SlotType)
    local WeaponPartSlotConfig = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSlotConfig,SlotType)
    if WeaponPartSlotConfig and WeaponPartSlotConfig[Cfg_WeaponPartSlotConfig_P.SlotTag]  then
        return WeaponPartSlotConfig[Cfg_WeaponPartSlotConfig_P.SlotTag] 
    end
    return nil
end

--[[
    检查枪械皮肤是否解锁
]]
function WeaponModel:HasWeaponSkin(WeaponSkinId)
    local SkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,
        Cfg_WeaponSkinConfig_P.SkinId, WeaponSkinId)
    if SkinCfg == nil then
        return false
    end
    local SkinItemId = SkinCfg[Cfg_WeaponSkinConfig_P.ItemId]
    local ItemCount = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(SkinItemId) or 0
    return ItemCount > 0
end


--[[
    获取枪械皮肤的质量
]]
function WeaponModel:GetWeaponSkinQuality(WeaponSkinId)
    local SkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,
        Cfg_WeaponSkinConfig_P.SkinId, WeaponSkinId)
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
    检查配件皮肤是否已经解锁
]]
function WeaponModel:IsAttachmentSkinIdUnLocked(AttachmentSkinId)
    local WeaponPartSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponPartSkinConfig,
        Cfg_WeaponPartSkinConfig_P.PartSkinId, AttachmentSkinId)
    if WeaponPartSkinCfg == nil then
        return false
    end
    local SkinItemID = WeaponPartSkinCfg[Cfg_WeaponSkinConfig_P.ItemId]
    local ItemCount = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(SkinItemID) or 0
    CWaring(StringUtil.Format("==========ItemId:{0}  {1}",SkinItemID,ItemCount))
    return ItemCount > 0 
end

function WeaponModel:CreateDefaultAvatarsBySkinId(AvatarComponent,SkinId,UserWeaponSelectPartCache)
    if not AvatarComponent then
        return
    end
    --主体默认DA组装
    AvatarComponent:AddAvatarByID(SkinId)
    --默认配件DA组装
    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.SkinId, SkinId) 
    local WeaponId = WeaponSkinCfg[Cfg_WeaponSkinConfig_P.WeaponId]
    local WeaponCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponConfig,WeaponId)
    local SlotTypeList = WeaponCfg[Cfg_WeaponConfig_P.AvailableSlotList]

    for k,SlotType in pairs(SlotTypeList) do
        local AvatarId = 0
        if UserWeaponSelectPartCache then
            AvatarId = self:GetSelectPartSkinIdBySelectPartId(SkinId,SlotType)
        end
        if not (AvatarId and AvatarId > 0) then
            AvatarId = self:GetAvatartIdShowByWeaponSkinIdAndSlotType(SkinId,SlotType)
        end
        if AvatarId and AvatarId > 0 then
            CWaring("WeaponModel:CreateDefaultAvatarsBySkinId WeaponId:".. WeaponId .. " SkinId:" .. SkinId .. " SlotType:" .. SlotType .. " AddAvatarByID:" .. AvatarId)
            AvatarComponent:AddAvatarByID(AvatarId)
        else
            local SlotTag = self:GetSlotTagBySlotType(SlotType)
            if SlotTag then
                AvatarComponent:RemoveAvatarBySlotType(SlotTag)
            end
        end
    end
end



--根据槽位获取武器预览目标位置
function WeaponModel:GetWeaponTransForSlot(WeaponId, SlotType)
	local WeaponCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponConfig, Cfg_WeaponConfig_P.ItemId, WeaponId)
    if WeaponCfg == nil then 
		return
	end
    local WeaponTransForSlot = nil
    if SlotType == Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_CHIP then --// 芯片
        WeaponTransForSlot = WeaponCfg[Cfg_WeaponConfig_P.WeaponTransForChip]
    elseif  SlotType == Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_MUZZLE then --// 枪口
        WeaponTransForSlot = WeaponCfg[Cfg_WeaponConfig_P.WeaponTransForMuzzle]
    elseif  SlotType == Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_GRIP then --// 握把
        WeaponTransForSlot = WeaponCfg[Cfg_WeaponConfig_P.WeaponTransForGrip]
    elseif  SlotType == Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_CLIP then --// 弹夹
        WeaponTransForSlot = WeaponCfg[Cfg_WeaponConfig_P.WeaponTransForClip]
    elseif  SlotType == Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_SIGHT then --// 瞄具
        WeaponTransForSlot = WeaponCfg[Cfg_WeaponConfig_P.WeaponTransForSight]
    elseif  SlotType == Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_STOCK then --//  枪托
        WeaponTransForSlot = WeaponCfg[Cfg_WeaponConfig_P.WeaponTransForStock]
	end
    if WeaponTransForSlot == nil then
        CWaring("GetWeaponTransForSlot: Not Found Trans")
        return
    end
    local Pattern = "X=([%d%.%-]+),Y=([%d%.%-]+),Z=([%d%.%-]+),Pitch=([%d%.%-]+),Yaw=([%d%.%-]+),Roll=([%d%.%-]+)"
    local X, Y, Z, Pitch, Yaw, Roll = string.match(WeaponTransForSlot, Pattern)
    if X and Y and Z and Pitch and Yaw and Roll then
        local Location = UE.FVector(X, Y, Z)
        local Rotation = UE.FRotator(Pitch, Yaw, Roll)
        local Scale = UE.FVector(1.0, 1.0, 1.0)
        return UE.UKismetMathLibrary.MakeTransform(Location, Rotation, Scale)
    end
end


--[[
    协议，武器装配配件
]]
function WeaponModel:WeaponEquipPart(WeaponId, Slot, PartId)
    self:SetSlotEquipAttachmentId(WeaponId, Slot, PartId)
    self:DispatchType(WeaponModel.ON_SELECT_ATTACHMENT)
end

--[[
     协议，武器卸载配件
]]
function WeaponModel:WeaponUnEquipPart(WeaponId, Slot)
    self:SetSlotEquipAttachmentId(WeaponId, Slot, nil)
    self:DispatchType(WeaponModel.ON_SELECT_ATTACHMENT)
end

--[[
     协议，购买武器配件皮肤
]]
function WeaponModel:BuyWeaponPartSkin(WeaponSkinId, WeaponPartSkinId)
    self:DispatchType(WeaponModel.ON_BUY_ATTACHMENT_SKIN)
end



return WeaponModel