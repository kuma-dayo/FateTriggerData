require("Client.Modules.Hero.HeroDefine")

--[[用户数据模型]]
local super = ListModel;
local class_name = "HeroModel";
---@class HeroModel : GameEventDispatcher
HeroModel = BaseClass(super, class_name);

--玩家当前展示英雄变更
HeroModel.ON_PLAYER_LIKE_HERO_CHANGE = "ON_PLAYER_LIKE_HERO_CHANGE"
--玩家购买了一个新英雄
HeroModel.ON_BUY_NEW_HERO = "ON_BUY_NEW_HERO"
--玩家解锁了一个新英雄
HeroModel.ON_NEW_HERO_UNLOCKED = "ON_NEW_HERO_UNLOCKED"
--英雄当前展示皮肤变更
HeroModel.ON_HERO_LIKE_SKIN_CHANGE = "ON_HERO_LIKE_SKIN_CHANGE"

-- --在皮肤详情界面，切换了当前选中英雄皮肤展示,来触发切换展示
-- HeroModel.TRIGGER_HERO_SKIN_SHOW_CHANGE = "TRIGGER_HERO_SKIN_SHOW_CHANGE"
--在英难预览界面，切换了当前选中英雄展示
HeroModel.TRIGGER_PLAYER_PREVIEW_HERO_CHANGE = "TRIGGER_PLAYER_PREVIEW_HERO_CHANGE"

--展示板界面中，发生购买底板、角色、特效、贴纸行为
HeroModel.ON_HERO_DISPLAYBOARD_BUY = "ON_HERO_DISPLAYBOARD_BUY"

--展示板界面中，预览设置底板，角色、特效、贴纸、成就等
HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_SHOW = "ON_HERO_DISPLAYBOARD_FLOOR_SHOW"
HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_CHANGE = "ON_HERO_DISPLAYBOARD_FLOOR_CHANGE"

HeroModel.ON_HERO_DISPLAYBOARD_ROLE_SHOW = "ON_HERO_DISPLAYBOARD_ROLE_SHOW"
HeroModel.ON_HERO_DISPLAYBOARD_ROLE_CHANGE = "ON_HERO_DISPLAYBOARD_ROLE_CHANGE"

HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_SHOW = "ON_HERO_DISPLAYBOARD_EFFECT_SHOW"
HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_CHANGE = "ON_HERO_DISPLAYBOARD_EFFECT_CHANGE"

HeroModel.ON_HERO_DISPLAYBOARD_STICKER_SHOW = "ON_HERO_DISPLAYBOARD_STICKER_SHOW"
HeroModel.ON_HERO_DISPLAYBOARD_STICKER_CHANGE = "ON_HERO_DISPLAYBOARD_STICKER_CHANGE"

HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_SHOW = "ON_HERO_DISPLAYBOARD_ACHIEVE_SHOW"
HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_CHANGE = "ON_HERO_DISPLAYBOARD_ACHIEVE_CHANGE"


--展示板界面中，装备底板，角色、特效、贴纸、成就等
HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_SELECT = "ON_HERO_DISPLAYBOARD_FLOOR_SELECT"
HeroModel.ON_HERO_DISPLAYBOARD_ROLE_SELECT = "ON_HERO_DISPLAYBOARD_ROLE_SELECT"
HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_SELECT = "ON_HERO_DISPLAYBOARD_EFFECT_SELECT"
HeroModel.ON_HERO_DISPLAYBOARD_STICKER_SELECT = "ON_HERO_DISPLAYBOARD_STICKER_SELECT"
HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_SELECT = "ON_HERO_DISPLAYBOARD_ACHIEVE_SELECT"

HeroModel.ON_PLAYER_EQUIP_STICKER_RSP = "ON_PLAYER_EQUIP_STICKER_RSP"
HeroModel.ON_PLAYER_UNEQUIP_STICKER_RSP = "ON_PLAYER_UNEQUIP_STICKER_RSP"

--通过此事件设置 展示板界面中，装备底板，角色、特效、贴纸、成就等
--HeroModel.NTF_SET_HERO_DISPLAYBOARD_SHOW = "NTF_SET_HERO_DISPLAYBOARD_SHOW"

--角色皮肤界面消息
HeroModel.ON_HERO_SKIN_SUIT_SELECT = "ON_HERO_SKIN_SUIT_SELECT"
HeroModel.ON_HERO_SKIN_SUIT_SUBITEM_SELECT = "ON_HERO_SKIN_SUIT_SUBITEM_SELECT"
HeroModel.ON_HERO_SKIN_PART_SELECT = "ON_HERO_SKIN_PART_SELECT"
HeroModel.ON_HERO_SHOW_ITEM_SELECT = "ON_HERO_SHOW_ITEM_SELECT"
HeroModel.ON_HERO_SHOW_ITEM_CLICK = "ON_HERO_SHOW_ITEM_CLICK"
HeroModel.ON_HERO_SHOW_ITEM_RIGHTCLICK = "ON_HERO_SHOW_ITEM_RIGHTCLICK"
HeroModel.ON_HERO_SKIN_PART_EQUIP = "ON_HERO_SKIN_PART_EQUIP"
HeroModel.HERO_SKIN_DEFAULT_PART_CHANGE = "HERO_SKIN_DEFAULT_PART_CHANGE"
HeroModel.HERO_QUICK_TAB_HOVER = "HERO_QUICK_TAB_HOVER"
HeroModel.HERO_QUICK_TAB_UNHOVER = "HERO_QUICK_TAB_UNHOVER"
HeroModel.HERO_QUICK_TAB_HERO_SELECT = "HERO_QUICK_TAB_HERO_SELECT"

--英雄数据
HeroModel.HERO_RECORD_DATA_CHANGE = "HERO_RECORD_DATA_CHANGE"
HeroModel.HERO_RECORD_HISTORY_DATA_CHANGE = "HERO_RECORD_HISTORY_DATA_CHANGE"

--贴纸扩大10000倍，存储
HeroModel.DISPLAYBOARD_FLOAT2INTSCALE = 10000

--[[
    大厅中
    跟角色/角色皮肤相关的LS或者动画片段的
    事件枚举
]]
HeroModel.LSEventTypeEnum = {
    --IdleLS 事件
    HallIdle = "HallIdle",
    --ClickLS 事件
    HallClick = "HallClick",
    LSPathEnterHall = "LSPathEnterHall",
    LSPathHeroMainLS = "LSPathHeroMainLS",
    LSPathHeroMain2TabDetail = "LSPathHeroMain2TabDetail",
    LSPathHeroMain2TabSkin = "LSPathHeroMain2TabSkin",
    LSPathHeroMain2TabRune = "LSPathHeroMain2TabRune",
    LSPathTabDetail2Skin = "LSPathTabDetail2Skin",
    LSPathTabDetail2Rune = "LSPathTabDetail2Rune",
    LSPathTabSkin2Detail = "LSPathTabSkin2Detail",
    LSPathTabSkin2Rune = "LSPathTabSkin2Rune",
    LSPathTabRune2Detail = "LSPathTabRune2Detail",
    LSPathTabRune2Skin = "LSPathTabRune2Skin",
    LSPathTabDetail2Main = "LSPathTabDetail2Main",
    LSPathTabSkin2Main = "LSPathTabSkin2Main",
    LSPathTabRune2Main = "LSPathTabRune2Main",
    IdleDefault = "IdleDefault",
    IdleHeroTabDetail = "IdleHeroTabDetail",
    IdleHeroTabSkin = "IdleHeroTabSkin",
    IdleHeroTabRune = "IdleHeroTabRune",
    IdleHeroTabDisplayBoard = "IdleHeroTabDisplayBoard",

    --预览界面切换
    LSPathHeroSkin2Preview = "LSPathHeroSkin2Preview",
    LSPathHeroPreview2Skin = "LSPathHeroPreview2Skin",
    LSPathHeroMain2Preview = "LSPathHeroMain2Preview",
    LSPathHeroPreview2Main = "LSPathHeroPreview2Main",
    LSPathHeroDetail2Preview = "LSPathHeroDetail2Preview",
    LSPathHeroPreview2Detail = "LSPathHeroPreview2Detail",

    -- 好感度切换LS
    LSPathFavListOpened = "LSPathFavListOpened",
    LSPathFavListClosed = "LSPathFavListClosed",
    LSPathFavLevelUp = "LSPathFavLevelUp",
    LSPathFavLevelMax = "LSPathFavLevelMax",
    -- IdleFavorMain = "IdleFavorMain", -- 使用 IdleDefault 代替
    IdleFavorGift = "IdleFavorGift",
}

function HeroModel:KeyOf(vo)
    if vo["CfgId"] then
        return vo["CfgId"]
    end
    return HeroModel.super.KeyOf(self,vo);
end

function HeroModel:__init()
    self:DataInit()
end


function HeroModel:DataInit()
    self.FavoriteId = 0
    self.HeroId2FavoriteSkinId = {}

    self.SuitId2SkinId = {}
    self.SuitId2SkinPartId = {}

    --套装的组件id
    self.SuitId2SubPartId = {}

    --英雄Id配置的底板列表
    self.HeroId2DisplayBoardInfo = {}
    --底板被哪些英雄使用
    self.DisplayBoardFloorId2HeroIdList =  {}
    --特效被哪些英雄使用
    self.DisplayBoardEffectId2HeroIdList = {}
    --特效被哪些英雄使用
    self.DisplayBoardRoleId2HeroIdList = {}
    --贴纸被哪个英雄使用
    self.DisplayBoardStickerId2HeroIdList = {}
    --成就被哪个英雄使用
    self.DisplayBoardAchieveId2HeroIdList = {}

    --赛季英雄数据
    self.DataRecordMap = nil

    --上次选择英雄Index
    self.LastClickedIndex = 0
    --当前选择英雄Index缓存
    self.NowClickedIndex = 0
    --记录操作的item数,避免记录LastClickedIndex时因时机不对造成显示bug
    self.DoCheckItems = {}

    -- self.DisplayDataToHeroIDMap = nil
end

--[[
    玩家登出时调用
]]
function HeroModel:OnLogout(data)
    self:DataInit()
end

---检查用户是否已经拥有了/解锁了该英雄，根据英雄Id
---@param nHeroId number 需要检查的英雄ID
---@return boolean 参数 true:已拥有; false:未拥有
function HeroModel:CheckGotHeroById(nHeroId)
    --数据判空保护
    if not nHeroId or not math.tointeger(nHeroId) then
        CWaring("[cw] trying to check an illegal value(" .. tostring(nHeroId) .. ")'s information")    
        return false
    end
    nHeroId = tonumber(nHeroId)
    
    ---@type DepotModel
    local DepotModel = MvcEntry:GetModel(DepotModel)
    local Count = DepotModel:GetItemCountByItemId(nHeroId)
    return Count > 0
end

---获取传入英雄解锁所需要的材料和数量
---@param nHeroId number 需要检查的英雄ID
---@return number&number 解锁需要的物品id&解锁需要的物品数量
function HeroModel:GetHeroUnlockRequirementsItems(nHeroId)
    local config = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.Id, nHeroId)
    return config[Cfg_HeroConfig_P.UnlockItemId], config[Cfg_HeroConfig_P.UnlockItemNum]
end

---@param nHeroId number 解锁的新英雄id
function HeroModel:OnBuyHeroRsp(nHeroId)
    -- 这里只派发BuyHero。Unlock放到仓库中入包逻辑检测。
    -- self:DispatchType(HeroModel.ON_NEW_HERO_UNLOCKED, nHeroId)
    self:DispatchType(HeroModel.ON_BUY_NEW_HERO, nHeroId)
end


function HeroModel:GetDefaultHeroId()
    return CommonUtil.GetParameterConfig(ParameterConfig.BornSelectHeroId, 0)
end

function HeroModel:GetFavoriteId()
    if not self.FavoriteId or self.FavoriteId == 0 then
        local HeroId = self:GetDefaultHeroId()
        self:SetFavoriteId(HeroId)
    end
    return self.FavoriteId or 0
end

function HeroModel:SetFavoriteId(HeroId)
    if self.FavoriteId == HeroId then
        return
    end
    local OldFavoriteId = self.FavoriteId
    self.FavoriteId = HeroId
    SaveGame.SetItem("CacheSelectHeroId",self.FavoriteId,true)
    if not self.TheCommonModel then
        self.TheCommonModel = MvcEntry:GetModel(CommonModel)
    end
    self.TheCommonModel:DispatchType(CommonModel.ON_PRELOAD_OUTSIDE_ASSTE_LIST_NEED_UPDATE)
    self:DispatchType(HeroModel.ON_PLAYER_LIKE_HERO_CHANGE, {OldId = OldFavoriteId, NewId = HeroId})
end

---获取玩家喜欢的角色的喜欢的皮肤id
---喜欢的 == 展示的
---@return number
function HeroModel:GetFavoriteHeroFavoriteSkinId()
    local CurrentPlayerHeroId = self:GetFavoriteId()
    local CurrentPlayerHeroSkinId = self:GetFavoriteSkinIdByHeroId(CurrentPlayerHeroId)
    return CurrentPlayerHeroSkinId
end

--[[
    根据英雄ID，获取当前展示皮肤ID
]]
function HeroModel:GetFavoriteSkinIdByHeroId(HeroId)
    if not HeroId then
        return 0
    end
    if not self.HeroId2FavoriteSkinId[HeroId] or self.HeroId2FavoriteSkinId[HeroId] == 0 then
        self.HeroId2FavoriteSkinId[HeroId] = self:GetDefaultSkinIdByHeroId(HeroId)
    end
    return self.HeroId2FavoriteSkinId[HeroId] or 0
end

--[[
    根据英雄ID，设置当前装备的皮肤ID
]]
function HeroModel:SetFavoriteSkinIdByHeroId(HeroId,SkinId)
    self.HeroId2FavoriteSkinId[HeroId] = SkinId
    local Param = {
        HeroId = HeroId,
        SkinId = SkinId,
    }
    self:DispatchType(HeroModel.ON_HERO_LIKE_SKIN_CHANGE,Param)
end


--[[
    根据服务器协议返回，设置每个英雄的已装备皮肤
]]
function HeroModel:SetFavoriteHeroSkinList(HeroSkinList)
    for i,v in ipairs(HeroSkinList) do
        self.HeroId2FavoriteSkinId[v.HeroId] = v.HeroSkinId

        for SuitId, SkinId in pairs(v.ColorSuitSelectMap) do
            self.SuitId2SkinId[SuitId] = SkinId
        end
    end
end

--[[
    根据英雄ID 获取这个英雄的默认皮肤ID
]]
function HeroModel:GetDefaultSkinIdByHeroId(HeroId)
    local CfgHeroSkin = self:GetDefaultSkinCfgByHeroId(HeroId)
    if CfgHeroSkin then
        return CfgHeroSkin[Cfg_HeroSkin_P.SkinId]
    end
    return 0
end

--[[
    根据英雄ID 获取这个英雄的默认皮肤配置
]]
function HeroModel:GetDefaultSkinCfgByHeroId(HeroId)
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,HeroId)
    if CfgHero then
        local CfgHeroSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,CfgHero[Cfg_HeroConfig_P.SkinId])
        return CfgHeroSkin
    end
    return nil
end

--[[
    根据皮肤ID和字段ID，  获取皮肤在某个阶段需要应用的LS路径
]]
function HeroModel:GetSkinLSPathBySkinIdAndKey(SkinId,EventName)
    CWaring(StringUtil.Format("GetSkinLSPathBySkinIdAndKey:{0},{1}",SkinId,EventName))
    local LSPath = nil
    local IsEnablePostProcess = false
    local Cfg = self:GetHeroEventLSCfg(EventName,SkinId)
    if Cfg then
        LSPath = Cfg[Cfg_HeroEventLSCfg_P.LSPath]
        IsEnablePostProcess = Cfg[Cfg_HeroEventLSCfg_P.IsEnablePostProcess]
        if LSPath and string.len(LSPath) <= 0 then
            LSPath = nil
        end
    end
    return LSPath,IsEnablePostProcess
end

--[[
    根据皮肤ID和字段ID，  获取皮肤在某个阶段需要播放的AnimClip片段
]]
function HeroModel:GetAnimClipPathBySkinIdAndKey(SkinId,EventName)
    CWaring(StringUtil.Format("GetSkinLSPathBySkinIdAndKey:{0},{1}",SkinId,EventName))
    local AnimClipPath = nil
    local Cfg = self:GetHeroEventLSCfg(EventName,SkinId)
    if Cfg then
        AnimClipPath = Cfg[Cfg_HeroEventLSCfg_P.AnimClip]
        if AnimClipPath and string.len(AnimClipPath) <= 0 then
            AnimClipPath = nil
        end
    end
    return AnimClipPath
end

--[[
    根据 事件名、皮肤ID，取到对应的LS可播放列表，然后根据权重值进行随机 
    返回随机的LSPath
]]
function HeroModel:GetHeroEventLS(EventName,SkinId)
    local LSPath = nil
    local Cfg = self:GetHeroEventLSCfg(EventName,SkinId)
    if Cfg then
        LSPath = Cfg[Cfg_HeroEventLSCfg_P.LSPath]
    end
    return LSPath
end

--[[
    根据 事件名、皮肤ID，取到对应的LS可播放列表，然后根据权重值进行随机 

    返回随机后的配置
]]
function HeroModel:GetHeroEventLSCfg(EventName,SkinId, FilterId)
    local Cfg = nil
    local WeightMax = 0
	local LSItems = G_ConfigHelper:GetMultiItemsByKeys(Cfg_HeroEventLSCfg, {Cfg_HeroEventLSCfg_P.EventName,Cfg_HeroEventLSCfg_P.SkinId}, {EventName,SkinId})
	if not LSItems or not next(LSItems) then
        LSItems = nil
		local SkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,SkinId)
        if SkinCfg then
            CWaring("HeroModel:GetHeroEventLS LSItems from SkinId nil,try from HeroId:" .. SkinCfg[Cfg_HeroSkin_P.HeroId])
            LSItems = G_ConfigHelper:GetMultiItemsByKeys(Cfg_HeroEventLSCfg, {Cfg_HeroEventLSCfg_P.EventName,Cfg_HeroEventLSCfg_P.HeroId,Cfg_HeroEventLSCfg_P.SkinId}, {EventName,SkinCfg[Cfg_HeroSkin_P.HeroId],0})
        end
        if not LSItems or not next(LSItems) then 
            CWaring("HeroModel:GetHeroEventLS LSItems from HeroId nil,please check")
            return
        end
	end
	if #LSItems <= 1 then
        Cfg = LSItems[1]
    else
        for k, v in ipairs(LSItems) do
            WeightMax = WeightMax + v[Cfg_HeroEventLSCfg_P.RandomWeight]
        end
        local RandomValue =	math.random(0, WeightMax)
        local TempMax = 0
        local FinalLS
        for k, v in ipairs(LSItems) do
            if not FilterId or FilterId ~= v[Cfg_HeroEventLSCfg_P.Id] then
                TempMax = TempMax + v[Cfg_HeroEventLSCfg_P.RandomWeight]
                if not FinalLS then
                    FinalLS = v
                end
                if TempMax >= RandomValue then
                    Cfg = v
                    break
                end
            end
        end

        if not Cfg then
            CWaring("HeroModel:GetHeroEventLSCfg can not find cfg, use default")
            Cfg = FinalLS
        end
    end
    return Cfg
end

--[[
    获取可展示的英雄配置列表
    按照ID升序排列
]]
function HeroModel:GetShowHeroCfgs()
    local HeroCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.IsShow, 1)         --可以展示的英雄数据列表 
    table.sort(HeroCfgs, function(a, b) return a[Cfg_HeroConfig_P.Id] < b[Cfg_HeroConfig_P.Id] end)  --需要把列表按照ID升序排列
    return HeroCfgs
end

--- 获取已拥有的英雄数量(待缓存)
function HeroModel:GetHaveHeroCount()
    local Count = 0
    local Cfgs = self:GetShowHeroCfgs()
    for index = 1, #Cfgs do
        local ConfigData = Cfgs[index]
        if self:CheckGotHeroById(ConfigData[Cfg_HeroConfig_P.Id]) then
            Count = Count + 1
        end
    end
    return Count
end

--- 获取除默认皮肤之外的已拥有的皮肤(待缓存)
function HeroModel:GetHaveHeroSkinCount()
    local Cfgs = self:GetShowHeroCfgs()
    local DefaultSkins = {}
    for index = 1, #Cfgs do
        local ConfigData = Cfgs[index]
        local HeroId = self:GetDefaultSkinIdByHeroId(ConfigData[Cfg_HeroConfig_P.Id])
        DefaultSkins[HeroId] = 1
    end
    local Count = 0
    local HeroSkinList = G_ConfigHelper:GetDict(Cfg_HeroSkin)
    for index = 1, #HeroSkinList do
        local ConfigData = HeroSkinList[index]
        local IsUnLock = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ConfigData[Cfg_HeroSkin_P.ItemId]) > 0
        if not DefaultSkins[ConfigData[Cfg_HeroSkin_P.SkinId]] and IsUnLock then
            Count = Count + 1
        end
    end
    return Count
end


--角色展示板
function HeroModel:SetDisplayBoardInfo(BoardInfo)
    if BoardInfo == nil then
        return
    end
    -- print_r(BoardInfo,"HeroModel:SetDisplayBoardInfo")
 
    if BoardInfo and next(BoardInfo) then
        ---@type LbStickerNode
        for k, BoardNode in pairs(BoardInfo) do
            if BoardNode.StickerMap then
                for k, StickerNode in pairs(BoardNode.StickerMap) do
                    --客户端安全限定贴纸尺寸
                    local SafeScale = self:SafeLimitStickerScale(StickerNode.ScaleX, StickerNode.ScaleY)
                    StickerNode.ScaleX = SafeScale.ScaleX
                    StickerNode.ScaleY = SafeScale.ScaleY
                end
            end
        end
    end

    self.HeroId2DisplayBoardInfo = BoardInfo
    -- print_r(BoardInfo,"HeroModel:SetDisplayBoardInfo 2")

    -- message LbDisplayBoardInfo
    -- {
    --     int64 FloorId = 1;                          // 底板Id
    --     int64 RoleId = 2;                           // 角色Id
    --     int64 EffectId = 3;                         // 特效Id
    --     map<int64, LbStickerNode> StickerMap = 4;     // 贴纸数据
    --     map<int64, int64> AchieveMap = 5;           // 成就数据
    -- }

    -- self:UpdateDisplayBoardToEquippedHeroId()

    self:UpdateFloorIdUsedByHeroIdList()
    self:UpdateEffectIdUsedByHeroIdList()
    self:UpdateRoleIdUsedByHeroIdList()
    self:UpdateStickerIdUsedByHeroIdList()
    self:UpdateAchieveIdUsedByHeroIdList()
end

-- function HeroModel:UpdateDisplayBoardToEquippedHeroId()
--     self.DisplayDataToHeroIDMap = {FloorIdToHeroIDMap = {}, RoleIdToHeroIDMap = {}, EffectIdToHeroIDMap = {}, StickerIdToHeroIDMap = {}, AchieveIdToHeroIDMap = {}}

--     for heroID, LbBoardInfo in pairs(self.HeroId2DisplayBoardInfo) do
--         -- 底板数据
--         local IDToHeroIDMap_1 = self.DisplayDataToHeroIDMap.FloorIdToHeroIDMap[LbBoardInfo.FloorId] or {}
--         table.insert(IDToHeroIDMap_1, heroID)
--         self.DisplayDataToHeroIDMap.FloorIdToHeroIDMap[LbBoardInfo.FloorId] = IDToHeroIDMap_1

--         -- 角色数据
--         local IDToHeroIDMap_2 = self.DisplayDataToHeroIDMap.RoleIdToHeroIDMap[LbBoardInfo.RoleId] or {}
--         table.insert(IDToHeroIDMap_2, heroID)
--         self.DisplayDataToHeroIDMap.RoleIdToHeroIDMap[LbBoardInfo.RoleId] = IDToHeroIDMap_2

--         -- 特效数据
--         local IDToHeroIDMap_3 = self.DisplayDataToHeroIDMap.EffectIdToHeroIDMap[LbBoardInfo.EffectId] or {}
--         table.insert(IDToHeroIDMap_3, heroID)
--         self.DisplayDataToHeroIDMap.EffectIdToHeroIDMap[LbBoardInfo.EffectId] = IDToHeroIDMap_3

--         -- 贴纸数据
--         for _, LbStickerNode in pairs(LbBoardInfo.StickerMap) do
--             local IDToHeroIDMap_4 = self.DisplayDataToHeroIDMap.StickerIdToHeroIDMap[LbStickerNode.StickerId] or {}
--             table.insert(IDToHeroIDMap_4, heroID)
--             self.DisplayDataToHeroIDMap.StickerIdToHeroIDMap[LbStickerNode.StickerId] = IDToHeroIDMap_4
--         end

--         -- 成就数据
--         for _, AchieveId in pairs(LbBoardInfo.AchieveMap) do
--             local IDToHeroIDMap_5 = self.DisplayDataToHeroIDMap.AchieveIdToHeroIDMap[AchieveId] or {}
--             table.insert(IDToHeroIDMap_5, heroID)
--             self.DisplayDataToHeroIDMap.AchieveIdToHeroIDMap[AchieveId] = IDToHeroIDMap_5
--         end
--     end
-- end

-- --- 获取显示板数据被哪些英雄装备的英雄ID
-- function HeroModel:GetDisplayBoardEquippedHeroId(BoardTypeEnum, BoardID)
--     if self.DisplayDataToHeroIDMap == nil then
--         return {}
--     end
--     if BoardTypeEnum == EHeroDisplayBoardTabID.Floor.TabId then
--         return self.DisplayDataToHeroIDMap.FloorIdToHeroIDMap[BoardID]
--     elseif BoardTypeEnum == EHeroDisplayBoardTabID.Role.TabId then
--         return self.DisplayDataToHeroIDMap.RoleIdToHeroIDMap[BoardID]
--     elseif BoardTypeEnum == EHeroDisplayBoardTabID.Effect.TabId then
--         return self.DisplayDataToHeroIDMap.EffectIdToHeroIDMap[BoardID]
--     elseif BoardTypeEnum == EHeroDisplayBoardTabID.Sticker.TabId then
--         return self.DisplayDataToHeroIDMap.StickerIdToHeroIDMap[BoardID]
--     elseif BoardTypeEnum == EHeroDisplayBoardTabID.Achieve.TabId then
--         return self.DisplayDataToHeroIDMap.AchieveIdToHeroIDMap[BoardID]
--     end
--     return {}
-- end

---更新背景信息
function HeroModel:UpdateDisplayBoardFloorInfo(HeroId, FloorId)
    self.HeroId2DisplayBoardInfo[HeroId] = self.HeroId2DisplayBoardInfo[HeroId] or {}
    self.HeroId2DisplayBoardInfo[HeroId].FloorId = FloorId
    self:UpdateFloorIdUsedByHeroIdList()
    self:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_SELECT,FloorId)
end

---更新英雄信息
function HeroModel:UpdateDisplayBoardRoleInfo(HeroId, RoleId)
    self.HeroId2DisplayBoardInfo[HeroId] = self.HeroId2DisplayBoardInfo[HeroId] or {}
    self.HeroId2DisplayBoardInfo[HeroId].RoleId = RoleId
    self:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_ROLE_SELECT,RoleId)
end

---更新Effect信息
function HeroModel:UpdateDisplayBoardEffectInfo(HeroId, EffectId)
    self.HeroId2DisplayBoardInfo[HeroId] = self.HeroId2DisplayBoardInfo[HeroId] or {}
    self.HeroId2DisplayBoardInfo[HeroId].EffectId = EffectId
    self:UpdateEffectIdUsedByHeroIdList()
    self:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_SELECT,EffectId)
end

---更新贴纸信息
function HeroModel:UpdateDisplayBoardStickerInfo(HeroId, Slot, StickerInfo, bEquip)
    self.HeroId2DisplayBoardInfo[HeroId] = self.HeroId2DisplayBoardInfo[HeroId] or {}
    self.HeroId2DisplayBoardInfo[HeroId].StickerMap = self.HeroId2DisplayBoardInfo[HeroId].StickerMap or {}
    if StickerInfo then
        --客户端安全限定贴纸尺寸
        local SafeScale = self:SafeLimitStickerScale(StickerInfo.ScaleX, StickerInfo.ScaleY)
        StickerInfo.ScaleX = SafeScale.ScaleX
        StickerInfo.ScaleY = SafeScale.ScaleY
    end
    self.HeroId2DisplayBoardInfo[HeroId].StickerMap[Slot] = StickerInfo 
    self:UpdateStickerIdUsedByHeroIdList()
    self:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_STICKER_SELECT, {HeroId = HeroId, Slot = Slot, StickerId = StickerInfo and StickerInfo.StickerId or 0, bEquip = bEquip})
end

---更新成就信息
function HeroModel:UpdateDisplayBoardAchieveInfo(HeroId, Slot, AchieveId)
    self.HeroId2DisplayBoardInfo[HeroId] = self.HeroId2DisplayBoardInfo[HeroId] or {}
    self.HeroId2DisplayBoardInfo[HeroId].AchieveMap = self.HeroId2DisplayBoardInfo[HeroId].AchieveMap or {}
    self.HeroId2DisplayBoardInfo[HeroId].AchieveMap[Slot] = AchieveId or 0
    self:UpdateAchieveIdUsedByHeroIdList()
    self:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_SELECT, {HeroId = HeroId, Slot = Slot, AchieveId = AchieveId or 0})
end

function HeroModel:UpdateFloorIdUsedByHeroIdList()
    self.DisplayBoardFloorId2HeroIdList = {}
    for HeroId, DisplayBoardInfo in pairs(self.HeroId2DisplayBoardInfo) do
        if DisplayBoardInfo.FloorId and DisplayBoardInfo.FloorId ~= 0 then
            self.DisplayBoardFloorId2HeroIdList[DisplayBoardInfo.FloorId] = self.DisplayBoardFloorId2HeroIdList[DisplayBoardInfo.FloorId] or {}
            table.insert(self.DisplayBoardFloorId2HeroIdList[DisplayBoardInfo.FloorId], HeroId)
        end
    end
end

function HeroModel:UpdateEffectIdUsedByHeroIdList()
    self.DisplayBoardEffectId2HeroIdList = {}
    for HeroId, DisplayBoardInfo in pairs(self.HeroId2DisplayBoardInfo) do
        if DisplayBoardInfo.EffectId and DisplayBoardInfo.EffectId ~= 0 then
            self.DisplayBoardEffectId2HeroIdList[DisplayBoardInfo.EffectId] = self.DisplayBoardEffectId2HeroIdList[DisplayBoardInfo.EffectId] or {}
            table.insert(self.DisplayBoardEffectId2HeroIdList[DisplayBoardInfo.EffectId], HeroId)
        end
    end
end

function HeroModel:UpdateRoleIdUsedByHeroIdList()
    self.DisplayBoardRoleId2HeroIdList = {}
    for HeroId, DisplayBoardInfo in pairs(self.HeroId2DisplayBoardInfo) do
        if DisplayBoardInfo.RoleId and DisplayBoardInfo.RoleId ~= 0 then
            self.DisplayBoardRoleId2HeroIdList[DisplayBoardInfo.RoleId] = self.DisplayBoardRoleId2HeroIdList[DisplayBoardInfo.RoleId] or {}
            table.insert(self.DisplayBoardRoleId2HeroIdList[DisplayBoardInfo.RoleId], HeroId)
        end
    end
end

function HeroModel:UpdateStickerIdUsedByHeroIdList()
    self.DisplayBoardStickerId2HeroIdList = {}
    for HeroId, DisplayBoardInfo in pairs(self.HeroId2DisplayBoardInfo) do
        local StickerMap = DisplayBoardInfo.StickerMap or {}
        for _, v in pairs(StickerMap) do
            if v.StickerId ~= 0 then
                self.DisplayBoardStickerId2HeroIdList[v.StickerId] = self.DisplayBoardStickerId2HeroIdList[v.StickerId] or {}
                table.insert(self.DisplayBoardStickerId2HeroIdList[v.StickerId], HeroId)
            end
        end
    end
end

function HeroModel:UpdateAchieveIdUsedByHeroIdList()
    self.DisplayBoardAchieveId2HeroIdList = {}
    for HeroId, DisplayBoardInfo in pairs(self.HeroId2DisplayBoardInfo) do
        local AchieveMap = DisplayBoardInfo.AchieveMap or {}
        for _, AchieveId in pairs(AchieveMap) do
            if AchieveId ~= 0 then
                self.DisplayBoardAchieveId2HeroIdList[AchieveId] = self.DisplayBoardAchieveId2HeroIdList[AchieveId] or {}
                table.insert(self.DisplayBoardAchieveId2HeroIdList[AchieveId], HeroId)
            end
        end
    end
end

function HeroModel:OnBuyDisplayBoardFloorRsp(FloorId)
    self:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_BUY, FloorId)
end

function HeroModel:OnBuyDisplayBoardRoleRsp(RoleId)
    self:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_BUY, RoleId)
end

function HeroModel:OnBuyDisplayBoardEffectRsp(EffectId)
    self:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_BUY, EffectId)
end

function HeroModel:OnBuyDisplayBoardStickerRsp(StickerId)
    self:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_BUY, StickerId)
end

--[[
   获取当前展示的FloorId
]]
function HeroModel:GetSelectedDisplayBoardFloorId(HeroId)
    return self.HeroId2DisplayBoardInfo[HeroId] and self.HeroId2DisplayBoardInfo[HeroId].FloorId or 0
end

function HeroModel:HasDisplayBoardFloorIdSelected(HeroId, FloorId)
    local SelectedId = self:GetSelectedDisplayBoardFloorId(HeroId)
    return SelectedId == FloorId
end


function HeroModel:GetDefaultFloorIdByHeroId(HeroId)
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,HeroId)
    return CfgHero and CfgHero[Cfg_HeroConfig_P.FloorId] or 0
end


--[[
   获取FloorId被哪个角色使用
]]
function HeroModel:GetFloorUsedByHeroId(FloorId, ExceptHeroId)
    local UsedHeroIdList = self.DisplayBoardFloorId2HeroIdList[FloorId] or {}
    if ExceptHeroId then
        local UseList = {}
        for _, v in ipairs(UsedHeroIdList) do
            if v ~= ExceptHeroId then
                table.insert(UseList, v)
            end
        end
        return UseList
    else
        return UsedHeroIdList
    end
end

--[[
    是否拥有底板
]]
function HeroModel:HasDisplayBoardFloor(FloorId)
    local CfgHeroDisplay = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayFloor, FloorId)
    local ItemId =  CfgHeroDisplay and CfgHeroDisplay[Cfg_HeroDisplayFloor_P.ItemId] or 0
    return ItemId > 0 and MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) > 0 or false
end

--[[
   获取当前展示的角色
]]
function HeroModel:GetSelectedDisplayBoardRoleId(HeroId)
    return self.HeroId2DisplayBoardInfo[HeroId] and self.HeroId2DisplayBoardInfo[HeroId].RoleId or 0
end

function HeroModel:HasDisplayBoardRoleIdSelected(HeroId, RoleId)
    local SelectedId = self:GetSelectedDisplayBoardRoleId(HeroId)
    return RoleId == SelectedId
end

--[[
   获取Role被哪个角色使用
]]
function HeroModel:GetRoleUsedByHeroId(RoleId, ExceptHeroId)
    local UsedHeroIdList = self.DisplayBoardRoleId2HeroIdList[RoleId] or {}
    if ExceptHeroId then
        local UseList = {}
        for _, v in ipairs(UsedHeroIdList) do
            if v ~= ExceptHeroId then
                table.insert(UseList, v)
            end
        end
        return UseList
    else
        return UsedHeroIdList
    end
end

--[[
    是否拥有角色
]]
function HeroModel:HasDisplayBoardRole(RoleId)
    local CfgHeroDisplay = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayRole, RoleId)
    local ItemId =  CfgHeroDisplay and CfgHeroDisplay[Cfg_HeroDisplayRole_P.ItemId] or 0
    return ItemId > 0 and MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) > 0 or false
end

--[[
   获取当前展示的特效
]]
function HeroModel:GetSelectedDisplayBoardEffectId(HeroId)
    return self.HeroId2DisplayBoardInfo[HeroId] and self.HeroId2DisplayBoardInfo[HeroId].EffectId or 0
end

function HeroModel:HasDisplayBoardEffectIdSelected(HeroId, EffectId)
    local SelectedId = self:GetSelectedDisplayBoardEffectId(HeroId)
    return EffectId == SelectedId
end

--[[
   获取Effect被哪个角色使用
]]
function HeroModel:GetEffectUsedByHeroId(EffectId, ExceptHeroId)
    local UsedHeroIdList = self.DisplayBoardEffectId2HeroIdList[EffectId] or {}
    if ExceptHeroId then
        local UseList = {}
        for _, v in ipairs(UsedHeroIdList) do
            if v ~= ExceptHeroId then
                table.insert(UseList, v)
            end
        end
        return UseList
    else
        return UsedHeroIdList
    end
end

--[[
    是否拥有特效
]]
function HeroModel:HasDisplayBoardEffect(EffectId)
    local CfgHeroDisplay = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayEffect, EffectId)
    local ItemId =  CfgHeroDisplay and CfgHeroDisplay[Cfg_HeroDisplayEffect_P.ItemId] or 0
    return ItemId > 0 and MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) > 0 or false
end


--[[
   获取槽位上装备的贴纸
]]
function HeroModel:GetSelectedDisplayBoardStickerId(HeroId, Slot)
    local StickerInfo = self:GetSelectedDisplayBoardSticker(HeroId, Slot)
    return StickerInfo and StickerInfo.StickerId or 0
end

--[[
   获取槽位上装备的贴纸
]]
function HeroModel:GetSelectedDisplayBoardSticker(HeroId, Slot)
    return self.HeroId2DisplayBoardInfo[HeroId] 
        and self.HeroId2DisplayBoardInfo[HeroId].StickerMap 
        and self.HeroId2DisplayBoardInfo[HeroId].StickerMap[Slot] 
end

--[[
    获取贴纸是否被装备
]]
function HeroModel:HasDisplayBoardStickerIdSelected(HeroId, StickerId)
    local StickerMap = self.HeroId2DisplayBoardInfo[HeroId] and self.HeroId2DisplayBoardInfo[HeroId].StickerMap or {}
    for _, v in pairs(StickerMap) do
        if v.StickerId == StickerId then
            return true
        end
    end
    return false
end

--[[
    是否拥有贴纸
]]
function HeroModel:HasDisplayBoardSticker(StickerId)
    local CfgStickerDisplay = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplaySticker, StickerId)
    local ItemId =  CfgStickerDisplay and CfgStickerDisplay[Cfg_HeroDisplaySticker_P.ItemId] or 0
    return ItemId > 0 and MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) > 0 or false
end

--[[
   获取贴纸被哪个角色使用
]]
function HeroModel:GetStickerUsedByHeroId(StickerId, ExceptHeroId)
    local UsedHeroIdList = self.DisplayBoardStickerId2HeroIdList[StickerId] or {}
    if ExceptHeroId then
        local UseList = {}
        for _, v in ipairs(UsedHeroIdList) do
            if v ~= ExceptHeroId then
                table.insert(UseList, v)
            end
        end
        return UseList
    else
        return UsedHeroIdList
    end
end

--[[
    获取成就是否已经装配
]]
function HeroModel:GetSelectedDisplayBoardAchieveId(HeroId, Slot)
    return self.HeroId2DisplayBoardInfo[HeroId] 
        and self.HeroId2DisplayBoardInfo[HeroId].AchieveMap 
        and self.HeroId2DisplayBoardInfo[HeroId].AchieveMap[Slot] or 0
end

--[[
    获取成就是否被装备
]]
function HeroModel:HasDisplayBoardAchieveIdSelected(HeroId, AchieveId)
    local AchieveMap = self.HeroId2DisplayBoardInfo[HeroId] and self.HeroId2DisplayBoardInfo[HeroId].AchieveMap or {}
    for _, v in pairs(AchieveMap) do
        if v == AchieveId then
            return true
        end
    end
    return false
end

--[[
   获取成就被哪个角色使用
]]
function HeroModel:GetAchieveUsedByHeroId(AchieveId, ExceptHeroId)
    local UsedHeroIdList = self.DisplayBoardAchieveId2HeroIdList[AchieveId] or {}
    if ExceptHeroId then
        local UseList = {}
        for _, v in ipairs(UsedHeroIdList) do
            if v ~= ExceptHeroId then
                table.insert(UseList, v)
            end
        end
        return UseList
    else
        return UsedHeroIdList
    end
end

--获取成就是被装备的个数
function HeroModel:GetSelectedDisplayBoardAchieveNum(HeroId)
    local Num = 0
    local AchieveMap = self.HeroId2DisplayBoardInfo[HeroId] and self.HeroId2DisplayBoardInfo[HeroId].AchieveMap or {}
    if AchieveMap and next(AchieveMap) then
        for Slot, AchieveId in pairs(AchieveMap) do
            if AchieveId > 0 then
                Num = Num + 1
            end
        end
    end
    return Num
end

function HeroModel:GetHeroSkinList(inHeroId)
    if not self.HeroSkinIdMap then
        self.HeroSkinIdMap = {}
        local HeroSkinList = G_ConfigHelper:GetDict(Cfg_HeroSkin)
        for index = 1, #HeroSkinList do
            local ConfigData = HeroSkinList[index]
            local HeroId = ConfigData[Cfg_HeroSkin_P.HeroId]
            self.HeroSkinIdMap[HeroId] = self.HeroSkinIdMap[HeroId] or {}
            if ConfigData[Cfg_HeroSkin_P.SuitType] == 0 then
                table.insert(self.HeroSkinIdMap[HeroId], ConfigData[Cfg_HeroSkin_P.SkinId])
            else
                local SuitID = ConfigData[Cfg_HeroSkin_P.SuitID]
                self.HeroSkinIdMap[HeroId][SuitID] = self.HeroSkinIdMap[HeroId][SuitID] or {}
                table.insert(self.HeroSkinIdMap[HeroId][SuitID], ConfigData[Cfg_HeroSkin_P.SkinId])
            end
        end
        for k, v in pairs(self.HeroSkinIdMap) do
            local list = {}
            for _, v1 in pairs(v) do
                if type(v1) == "table" then
                    table.insert(list, v1)
                else
                    table.insert(list, {v1})
                end
            end
            self.HeroSkinIdMap[k]["List"] = list
        end
    end
    return self.HeroSkinIdMap[inHeroId]["List"]
end

function HeroModel:GetSuitPartList(inSuitId)
    return self.SuitId2SubPartId[inSuitId]
end

function HeroModel:HandleSuitPart(inSuitId,inPartId,IsRemove)
    self.SuitId2SubPartId[inSuitId] = self.SuitId2SubPartId[inSuitId] or {}
    if IsRemove then
        local tempTable = {}
        for _, v in ipairs(self.SuitId2SubPartId[inSuitId]) do
            if v ~= inPartId then
                table.insert(tempTable,v)
            end
        end
        self.SuitId2SubPartId[inSuitId] = tempTable
    else
        table.insert(self.SuitId2SubPartId[inSuitId], inPartId)
    end
end

function HeroModel:IsEquipSuitPart(inSuitId,inPartId)
    if not self.SuitId2SubPartId[inSuitId] then
        return false
    end
    return table.contains(self.SuitId2SubPartId[inSuitId], inPartId)
end

function HeroModel:GetLastSelectColorfulSkinId(SuitId)
    return self.SuitId2SkinId[SuitId] or 0
end

function HeroModel:SetSkinSuitData(SkinSuitMap)
    for SuitId, SkinData in pairs(SkinSuitMap) do
        self:UpdateSkinSuitPartData(SkinData.SelectSkinId, SuitId, SkinData.SkinSuit)
    end
end

function HeroModel:GetSkinSuitData(SuitId)
    return self.SuitId2SkinPartId[SuitId]
end

function HeroModel:UpdateSkinSuitPartData(SelectSkinId, SuitId, SkinData)
    self.SuitId2SkinPartId[SuitId] = self.SuitId2SkinPartId[SuitId] or {}
    self.SuitId2SkinPartId[SuitId].SelectSkinId = SelectSkinId

    local PartList = {}
    if SelectSkinId == 0 then
        if SkinData then
            for PartType, PartId in pairs(SkinData) do
                PartList[PartType] = PartId
            end
        end
    else
        local CfgHeroSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,SelectSkinId)
        for _, PartId in pairs(CfgHeroSkin[Cfg_HeroSkin_P.SuitPartList]) do
            local CfgPart = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkinPart,PartId)
            PartList[CfgPart[Cfg_HeroSkinPart_P.PartType]] = PartId
        end
    end
    self.SuitId2SkinPartId[SuitId].PartList = PartList
end

function HeroModel:EquipSuitPart(HeroSkinPartIdList)
    for _, v in pairs(HeroSkinPartIdList) do
        self:SetSkinSuitPartData(v)
    end
    self:DispatchType(HeroModel.ON_HERO_SKIN_PART_EQUIP)
end

function HeroModel:SetSkinSuitPartData(PartId)
    local CfgPart = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkinPart,PartId)
    if not CfgPart then
        return
    end
    local SuitId = CfgPart[Cfg_HeroSkinPart_P.SuitID]
    local PartType = CfgPart[Cfg_HeroSkinPart_P.PartType]

    self.SuitId2SkinPartId[SuitId] = self.SuitId2SkinPartId[SuitId] or {}
    self.SuitId2SkinPartId[SuitId].PartList = self.SuitId2SkinPartId[SuitId].PartList or {}
    self.SuitId2SkinPartId[SuitId].PartList[PartType] = PartId
end

function HeroModel:GetSkinSuitEquipPartIdList(SuitId, IsPreview)
    if not self.SuitId2SkinPartId[SuitId] then
        local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SuitID,SuitId)
        if not Cfgs or #Cfgs < 1 then
            return
        end
        local Cfg
        for _, v in pairs(Cfgs) do
            if not Cfg and self:IsUnLockSkinId(v[Cfg_HeroSkin_P.SkinId]) then
                Cfg = v
                break
            end
        end
        if not Cfg and IsPreview then
            Cfg = Cfgs[1]
        else
            return
        end
        for _, PartID in pairs(Cfg[Cfg_HeroSkin_P.SuitPartList]) do
            self:SetSkinSuitPartData(PartID)
        end
    end
    return self.SuitId2SkinPartId[SuitId].PartList
end

function HeroModel:IsPartIdEquiped(PartId)
    local CfgPart = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkinPart,PartId)
    if not CfgPart then
        return false
    end
    local SuitId = CfgPart[Cfg_HeroSkinPart_P.SuitID]
    local PartList = self:GetSkinSuitEquipPartIdList(SuitId)
    if not PartList then
        return false
    end
    return table.contains(table.values(PartList), PartId)
end

function HeroModel:IsSkinEquiped(SkinId)
    local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SkinId, SkinId)
    if not Cfg then
        return false
    end
    if Cfg[Cfg_HeroSkin_P.SuitType] ~= Pb_Enum_HERO_SKIN_TYPE.HERO_SKIN_TYPE_PART then
        local FavoriteSkinId = self:GetFavoriteSkinIdByHeroId(Cfg[Cfg_HeroSkin_P.HeroId])
        return FavoriteSkinId == SkinId
    else
        local SuitId = Cfg[Cfg_HeroSkin_P.SuitType]
        if not self.SuitId2SkinPartId[SuitId] then
            return false
       end
       return self.SuitId2SkinPartId[SuitId].SelectSkinId == SkinId
    end
end

function HeroModel:GetCurSkinSelect(SkinId)
    local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SkinId, SkinId)
    if not Cfg then
        return -1, nil
    end

    if Cfg[Cfg_HeroSkin_P.SuitID] == 0 then
        return SkinId, nil
    end

    return self:GetCurSkinSelectBySuitId(Cfg[Cfg_HeroSkin_P.SuitID])
end

function HeroModel:GetCurSkinSelectBySuitId(SuitId)
    if SuitId == 0 then
        return -1, nil
    end

    local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SuitID, SuitId)
    if not Cfgs then
        return -1, nil
    end

    if #Cfgs < 1 then
        return -1, nil
    end

    local DefaultCfg = Cfgs[1]
    local DefaultSelect = DefaultCfg[Cfg_HeroSkin_P.SkinId]

    local FavoriteSkinId = self:GetFavoriteSkinIdByHeroId(DefaultCfg[Cfg_HeroSkin_P.HeroId])
    local Found = false
    for _, v in pairs(Cfgs) do
        if v[Cfg_HeroSkin_P.SkinId] == FavoriteSkinId then
            Found = true
            break
        end
    end

    if not Found then
        return DefaultSelect,DefaultCfg[Cfg_HeroSkin_P.SuitPartList]
    end

    local FavoriterCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SkinId, FavoriteSkinId)

    if FavoriterCfg[Cfg_HeroSkin_P.SuitType] == Pb_Enum_HERO_SKIN_TYPE.HERO_SKIN_TYPE_COLORFUL then
        return FavoriteSkinId, nil
    elseif  FavoriterCfg[Cfg_HeroSkin_P.SuitType] == Pb_Enum_HERO_SKIN_TYPE.HERO_SKIN_TYPE_PART  then
        local SuitPartInfo = self.SuitId2SkinPartId[SuitId]
        if not SuitPartInfo then
            return FavoriteSkinId, nil
        end
        return SuitPartInfo.SelectSkinId, SuitPartInfo.PartList
    else
        return -1, nil
    end
end

--- 获取套装的装备皮肤
---@param HeroId any
function HeroModel:GetSuitFavoriteSkinIdByHeroId(HeroId)
    local FavoriteSkinId = self:GetFavoriteSkinIdByHeroId(HeroId)
    if FavoriteSkinId ~= 0 then
        local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SkinId, FavoriteSkinId)
        if not Cfg then
            return FavoriteSkinId
        end
        local SuitId = Cfg[Cfg_HeroSkin_P.SuitID]
        if Cfg[Cfg_HeroSkin_P.SuitType] == Pb_Enum_HERO_SKIN_TYPE.HERO_SKIN_TYPE_PART then
            if not self.SuitId2SkinPartId[SuitId] then
                return FavoriteSkinId
           end
           return self.SuitId2SkinPartId[SuitId].SelectSkinId or FavoriteSkinId
        end
    end
    return FavoriteSkinId or 0
end
function HeroModel:GetAvatarIDsBySkinId(SkinId,InstID)
    InstID = InstID or 0
	local PartArr = {}
    local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SkinId, SkinId)

    if Cfg[Cfg_HeroSkin_P.SuitType] == Pb_Enum_HERO_SKIN_TYPE.HERO_SKIN_TYPE_PART then
        local SuitId = Cfg[Cfg_HeroSkin_P.SuitID]
        if CustomPartList and #CustomPartList > 0 then
            PartArr = CustomPartList
        elseif (InstID <= 0 or MvcEntry:GetModel(UserModel):IsSelf(InstID)) and self.SuitId2SkinPartId[SuitId] and self.SuitId2SkinPartId[SuitId].PartList then
            PartArr = self.SuitId2SkinPartId[SuitId].PartList
        else
            for _, v in pairs(Cfg[Cfg_HeroSkin_P.SuitPartList]) do
                table.insert(PartArr, v)
            end
        end
    else
        table.insert(PartArr, SkinId)
    end
    print_r(PartArr,"GetAvatarIDsBySkinId")
    return PartArr
end

function HeroModel:CreateDefaultAvatarsBySkinId(AvatarComponent, InstID, SkinId, CustomPartList)
    if not AvatarComponent then
        return
    end
	local PartArr = self:GetAvatarIDsBySkinId(SkinId,InstID)
    AvatarComponent:AddAvatarByIDs(PartArr)
end

function HeroModel:IsUnLockSkinId(SkinId)
    local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SkinId, SkinId)
    if not Cfg then
        return false
    end
    if Cfg[Cfg_HeroSkin_P.ItemId] < 1 then
        return true
    end
    return MvcEntry:GetModel(DepotModel):GetItemCountByItemId(Cfg[Cfg_HeroSkin_P.ItemId]) > 0
end


function HeroModel:SetHeroDataRecord(SeasonId, HeroId, RecordDataKey, RecordDataValue)
    self.DataRecordMap = self.DataRecordMap or {}
    self.DataRecordMap[SeasonId] = self.DataRecordMap[SeasonId] or {}
    self.DataRecordMap[SeasonId][HeroId] = self.DataRecordMap[SeasonId][HeroId] or {}
    self.DataRecordMap[SeasonId][HeroId][RecordDataKey] = RecordDataValue
end

function HeroModel:GetHeroDataRecord(SeasonId, HeroId, RecordDataKey)
    if not self.DataRecordMap or not self.DataRecordMap[SeasonId] 
    or not self.DataRecordMap[SeasonId][HeroId] or not self.DataRecordMap[SeasonId][HeroId][RecordDataKey] then
        return 0
    end
    return self.DataRecordMap[SeasonId][HeroId][RecordDataKey]
end

function HeroModel:SetHeroDataHistoryRecord(SeasonId, HeroId, HistoryRecord)
    self.DataRecordMap = self.DataRecordMap or {}
    self.DataRecordMap[SeasonId] = self.DataRecordMap[SeasonId] or {}
    self.DataRecordMap[SeasonId][HeroId] = self.DataRecordMap[SeasonId][HeroId] or {}
    self.DataRecordMap[SeasonId][HeroId]["History"] = HistoryRecord
    self:DispatchType(HeroModel.HERO_RECORD_HISTORY_DATA_CHANGE)
end

function HeroModel:AddHeroDataHistoryRecord(SeasonId, HeroId, HistoryRecord, StartIdx)
    self.DataRecordMap = self.DataRecordMap or {}
    self.DataRecordMap[SeasonId] = self.DataRecordMap[SeasonId] or {}
    self.DataRecordMap[SeasonId][HeroId] = self.DataRecordMap[SeasonId][HeroId] or {}
    self.DataRecordMap[SeasonId][HeroId]["History"] = self.DataRecordMap[SeasonId][HeroId]["History"] or {}
    if StartIdx ~= #self.DataRecordMap[SeasonId][HeroId]["History"] then
        CError("HeroModel:AddHeroDataHistoryRecord")
    end
    local Count = #HistoryRecord
    for i = Count, 1, -1 do
        table.insert(self.DataRecordMap[SeasonId][HeroId]["History"], HistoryRecord[i])
    end
    self:DispatchType(HeroModel.HERO_RECORD_HISTORY_DATA_CHANGE)
end

function HeroModel:ResetHeroDataRecord()
    self.DataRecordMap = nil
end

function HeroModel:GetHeroDataHistoryRecord(SeasonId, HeroId)
    if not self.DataRecordMap or not self.DataRecordMap[SeasonId]
    or not self.DataRecordMap[SeasonId][HeroId] or not self.DataRecordMap[SeasonId][HeroId]["History"] then
        return nil
    end
    return self.DataRecordMap[SeasonId][HeroId]["History"]
end

function HeroModel:ClearDoCheckItems()
    self.DoCheckItems = {}
end

function HeroModel:SetSelecthHeroId()
    self.LastClickedIndex = self.NowClickedIndex
    self.NowClickedIndex = 0
    self.DoCheckItems = {}
end


---获取英雄面板的默认数据配置
---@return DisplayBoardNode
function HeroModel:GetDefaultDisplayBoardData(InHeroId)
    local DefaultCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayBoardDefaultCfg, InHeroId)
    if DefaultCfg then
        local FloorId = DefaultCfg[Cfg_HeroDisplayBoardDefaultCfg_P.FloorId]
        local RoleId = DefaultCfg[Cfg_HeroDisplayBoardDefaultCfg_P.RoleId]
        local EffectId = DefaultCfg[Cfg_HeroDisplayBoardDefaultCfg_P.EffectId]
    
        local SlotToStickerInfo = {}
        local SlotToAchieveId = {}

        for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
            local StickerId = DefaultCfg["StickerId_"..Slot]
            if StickerId and StickerId > 0 then
                ---@type LbStickerNode
                local StickerInfo = {
                    StickerId = StickerId,
                    XPos = DefaultCfg["PosX_"..Slot],
                    YPos = DefaultCfg["PosY_"..Slot],
                    Angle = DefaultCfg["Angle_"..Slot],
                    ScaleX = DefaultCfg["ScaleX_"..Slot],
                    ScaleY = DefaultCfg["ScaleY_"..Slot],
                }
                SlotToStickerInfo[Slot] = StickerInfo
            end
        end
    
        ---@type DisplayBoardNode
        local DisplayData = {
            HeroId = InHeroId,
            FloorId = FloorId,
            RoleId = RoleId,
            EffectId =EffectId,
            SlotToAchieveId = SlotToAchieveId,
            SlotToStickerInfo = SlotToStickerInfo,
        }
        return DisplayData
    end
    return nil
end

---获取英雄组队标识位置
function HeroModel:GetHeroTeamMarkLocation(SkinId)
    local TeamMarkLocation = UE.FVector(0, 0, 190)
    local HeroSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin, Cfg_HeroSkin_P.SkinId, SkinId)
    if HeroSkinConfig and HeroSkinConfig[Cfg_HeroSkin_P.HeroId] then
        local HeroConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.Id, HeroSkinConfig[Cfg_HeroSkin_P.HeroId])
        if HeroConfig and HeroConfig[Cfg_HeroConfig_P.TeamMarkLocation] then
            local NewLoc = StringUtil.Split(HeroConfig[Cfg_HeroConfig_P.TeamMarkLocation], ",")
            TeamMarkLocation.x = NewLoc[1] and tonumber(NewLoc[1]) or 0
            TeamMarkLocation.y = NewLoc[2] and tonumber(NewLoc[2]) or 0
            TeamMarkLocation.z = NewLoc[3] and tonumber(NewLoc[3]) or 0
        end 
    end
    return TeamMarkLocation
end


local MaxScale = HeroDefine.STICKER_SIZE_MAX * HeroModel.DISPLAYBOARD_FLOAT2INTSCALE
local MinScale = HeroDefine.STICKER_SIZE_MIN * HeroModel.DISPLAYBOARD_FLOAT2INTSCALE
local NormScale = 1.0 * HeroModel.DISPLAYBOARD_FLOAT2INTSCALE
---客户端检查贴纸大小的安全性,并强行设定到安全值
function HeroModel:SafeLimitStickerScale(InScaleX, InScaleY)
    InScaleX = InScaleX or NormScale
    InScaleY = InScaleY or NormScale
    
    if math.abs(InScaleX) > MaxScale then
        --大于最大值
        local dir = 1
        if InScaleX < 0 then
            dir = -1
        end
        InScaleX = MaxScale * dir
    elseif math.abs(InScaleX) < MinScale then
        --小于最小值
        local dir = 1
        if InScaleX < 0 then
            dir = -1
        end
        InScaleX = MinScale * dir
    end

    if math.abs(InScaleX) ~= math.abs(InScaleY) then
        local dir = 1
        if InScaleY < 0 then
            dir = -1
        end
        InScaleY = math.abs(InScaleX) * dir
    end
    
    local Ret = {
        ScaleX = InScaleX, 
        ScaleY = InScaleY
    }

    return Ret
   
end

return HeroModel;