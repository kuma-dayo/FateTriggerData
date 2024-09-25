local AchievementData = require("Client.Modules.Achievement.AchievementData")
local  AchievementConst = require("Client.Modules.Achievement.AchievementConst")

local super = ListModel;
local class_name = "AchievementModel";

---@class AchievementModel : ListModel
---@field private super ListModel
AchievementModel = BaseClass(super, class_name);

AchievementModel.MAX_SLOT_COUNT = 3

AchievementModel.ACHIEVE_STATE_CHANGE_ON_SLOT = "ACHIEVE_STATE_CHANGE_ON_SLOT"
AchievementModel.ACHIEVE_DATA_UPDATE = "ACHIEVE_DATA_UPDATE"
AchievementModel.ACHIEVE_PLAYER_DATA_UPDATE = "ACHIEVE_PLAYER_DATA_UPDATE"

---@class DirtyFlagDefine
AchievementModel.DirtyFlagDefine = {
    NoChanged = 0,
    DirtyDefineInit = 1,
    DirtyDefinePrefixType = 2,
    DirtyDefinePrefixGroup = 12,
}

AchievementModel.DirtyFlagDefineValue = {
}

AchievementModel.PersonInfoPlayerId = 0 --缓存个人中心中对应的用户Id

AchievementModel.TabCfgList = {} --因为表格结构变更, 目前先缓存个人中心中对应的成就一级Tab数据

--- 设置所有状态为脏状态
function AchievementModel:SetAllFlagDirty()
    self.DirtyFlag = 0
    self.AllDirtyFlag = 0
    self:RefreshAllDirtyFlag()
    self.DirtyFlag = self.AllDirtyFlag
end

--- 初始化所有的DirtyFlag
function AchievementModel:InitAllDirtyFlag()
    self.AllDirtyFlag = 0
    for _, Flag in pairs(AchievementModel.DirtyFlagDefine) do
        local FlagValue = 1 << Flag
        AchievementModel.DirtyFlagDefineValue[Flag] = FlagValue
        self.AllDirtyFlag = self.AllDirtyFlag | FlagValue
    end
end

--- 刷新所有的DirtyFlag
function AchievementModel:RefreshAllDirtyFlag()
    self.AllDirtyFlag = 0
    for _, FlagValue in pairs(AchievementModel.DirtyFlagDefineValue) do
        self.AllDirtyFlag = self.AllDirtyFlag | FlagValue
    end
end

--- 动态插入DirtyFlag
---@param DirtyFlag DirtyFlagDefine
---@param IsDirty boolean
function AchievementModel:InsertDirtyByType(DirtyFlag, Offset)
    Offset = Offset or 0
    local NewDirtyFlag = Offset + DirtyFlag
    if AchievementModel.DirtyFlagDefineValue[NewDirtyFlag] then
        CWaring("[AchievementModel]InsertDirtyByType can not insert new value when exist define flag")
        return AchievementModel.DirtyFlagDefineValue[NewDirtyFlag]
    end
    local FlagValue = 1 << NewDirtyFlag
    AchievementModel.DirtyFlagDefineValue[NewDirtyFlag] = FlagValue
    self:RefreshAllDirtyFlag()
    return FlagValue
end

--- 设置脏数据状态
---@param DirtyFlag DirtyFlagDefine
---@param IsDirty boolean
function AchievementModel:SetDirtyByType(DirtyFlag, IsDirty, Offset)
    Offset = Offset or 0
    local NewDirtyFlag = Offset + DirtyFlag
    local FlagValue =  AchievementModel.DirtyFlagDefineValue[NewDirtyFlag]
    if FlagValue == nil then
        FlagValue = self:InsertDirtyByType(DirtyFlag, Offset)
    end
    if IsDirty then
        self.DirtyFlag = self.DirtyFlag | FlagValue
    else
        self.DirtyFlag = self.DirtyFlag & ~FlagValue
    end

    if Offset ~= 0 then
        self:SetDirtyByType(DirtyFlag, true)
    end
end

--- 判断是否是脏数据
---@param DirtyFlag DirtyFlagDefine
function AchievementModel:IsDirtyByType(DirtyFlag, Offset, IsReset)
    Offset = Offset or 0
    local NewDirtyFlag = Offset + DirtyFlag
    local FlagValue =  AchievementModel.DirtyFlagDefineValue[NewDirtyFlag]
    if FlagValue == nil then
        return true
    end
    local Res = self.DirtyFlag & FlagValue > 0
    self:SetDirtyByType(DirtyFlag, false, Offset)
    return Res
end

function AchievementModel:__init()
    self:_dataInit()
end

function AchievementModel:_dataInit()
    self:Clean()
    self.DataByType = {}
    self.DataByGroup = {}
    self.DataCompleteByType = {}
    self.PlayerDataComplete = {}
    self.GameAchiData = {}
    self.SlotList = {}
    self.LoadingType = LoadingCtrl.TypeEnum.OTHER --缓存Loading类型（连同判断是否处于结算界面用于表现弹小弹窗还是大弹窗）
    self:SetAllFlagDirty()
    self:SetDirtyByType(AchievementModel.DirtyFlagDefine.DirtyDefineInit, true)
end

---@param data any
function AchievementModel:OnLogin(data)
    CWaring("NoticeModel OnLogin")
    -- self:InitData()
end

--- 玩家登出时调用
---@param data any
function AchievementModel:OnLogout(data)
    for _, v1 in pairs(self.PlayerDataComplete) do
        if v1["Map"] then
            for _, v2 in pairs(v1["Map"]) do
                PoolManager.Reclaim(v2)
            end
        end
    end
    local List = self:GetDataList()
    for _, v1 in pairs(List) do
        PoolManager.Reclaim(v1)
    end
    AchievementModel.super.OnLogout(self)
    self:_dataInit()
end

--- 重写父方法,返回唯一Key
---@param vo any
function AchievementModel:KeyOf(vo)
    return vo["ID"]
end

--- 重写父类方法,如果数据发生改变
--- 进行通知到这边的逻辑
---@param vo any
function AchievementModel:SetIsChange(value)
    AchievementModel.super.SetIsChange(self, value)
end

function AchievementModel:InitData()
    if not self:IsDirtyByType(AchievementModel.DirtyFlagDefine.DirtyDefineInit, 0, true) then
        return
    end
    local AchievementConfigs = G_ConfigHelper:GetDict(Cfg_AchievementCfg)
    if not AchievementConfigs then
        CError("AchievementConfigs is nil, need check!")
        return
    end
    local List = {}
    local TempList = {}
    for _, Cfg in pairs(AchievementConfigs) do
        repeat
            local GroupId = Cfg[Cfg_AchievementCfg_P.MissionID]
            if not Cfg[Cfg_AchievementCfg_P.IsEnable] then
                break
            end

            if TempList[GroupId] then
                break
            end
            
            TempList[GroupId] = true

            ---@type AchievementData
            local Data = PoolManager.GetInstance(AchievementData)
            Data:InitDataFromCfgId(Cfg[Cfg_AchievementCfg_P.ID])

            table.insert(List, Data)
            self.DataByType[0] = self.DataByType[0] or {}
            self.DataByType[Data.Type] = self.DataByType[Data.Type] or {}
            table.insert(self.DataByType[0],Data.ID)
            table.insert(self.DataByType[Data.Type],Data.ID)

            local GroupId = Data:GetGroupByType()
            self.DataByGroup[0] = self.DataByGroup[0] or {}
            self.DataByGroup[GroupId] = self.DataByGroup[GroupId] or {}
            table.insert(self.DataByGroup[0],Data.ID)
            table.insert(self.DataByGroup[GroupId],Data.ID)
        until true
    end
    self:SetDataList(List)
    self:InitTabDataList(AchievementConfigs)
end

--- func desc
---@param Data AchievementData
function AchievementModel:UpdateCompleteList(Data)
    if Data.State == AchievementConst.OWN_STATE.Have then
        self.DataCompleteByType[0] = self.DataCompleteByType[0] or {}
        self.DataCompleteByType[0]["Map"] = self.DataCompleteByType[0]["Map"] or {}
        if not self.DataCompleteByType[0]["Map"][Data.ID] then
            self.DataCompleteByType[0]["List"] = self.DataCompleteByType[0]["List"] or {}
            self.DataCompleteByType[Data.Type] = self.DataCompleteByType[Data.Type] or {}
            self.DataCompleteByType[Data.Type]["Map"] = self.DataCompleteByType[Data.Type]["Map"] or {}
            self.DataCompleteByType[Data.Type]["List"] = self.DataCompleteByType[Data.Type]["List"] or {}
            self.DataCompleteByType[0]["Map"][Data.ID] = true
            self.DataCompleteByType[0].IsDirty = true
            self.DataCompleteByType[Data.Type]["Map"][Data.ID] = true
            self.DataCompleteByType[Data.Type].IsDirty = true
            table.insert(self.DataCompleteByType[0]["List"],Data.ID)
            table.insert(self.DataCompleteByType[Data.Type]["List"],Data.ID) 
        end
    end
end

function AchievementModel:SetCompleteListDirty(Id, Dirty)
    local Data = self:GetData(Id)
    if not Data then
        return
    end
    if self.DataCompleteByType[0] then
        self.DataCompleteByType[0].IsDirty = Dirty
    end
    if self.DataCompleteByType[Data.Type] then
        self.DataCompleteByType[Data.Type].IsDirty = Dirty
    end
end

function AchievementModel:GetListByType(Type, PlayerId)
    if self:IsDirtyByType(AchievementModel.DirtyFlagDefine.DirtyDefinePrefixType, 0, true) then
        for k, v in pairs(self.DataByType) do
            self.DataByType[k] = self:SortList(self.DataByType[k])
        end
    end
    return self.DataByType[Type]
end

function AchievementModel:GetListByGroup(Group)
    if self:IsDirtyByType(AchievementModel.DirtyFlagDefine.DirtyDefinePrefixGroup, 0, true) then
        for k, v in pairs(self.DataByGroup) do
            self.DataByGroup[k] = self:SortList(self.DataByGroup[k])
        end
    end
    return self.DataByGroup[Group]
end

function AchievementModel:GetCompleteListByType(Type)
    if not self.DataCompleteByType[Type] then
        return
    end
    if self.DataCompleteByType[Type] and self.DataCompleteByType[Type].IsDirty then
        self.DataCompleteByType[Type]["List"] = self:SortList(self.DataCompleteByType[Type]["List"])
        self.DataCompleteByType[Type].IsDirty = false
    end
    return self.DataCompleteByType[Type]["List"]
end

function AchievementModel:GetAvalibleSlot()
    for i = 1, 3 do
        if not self.SlotList[i] then
            return i
        end
    end
    return -1
end

function AchievementModel:GetSlotAchieveId(Slot)
    return self.SlotList[Slot]
end

function AchievementModel:AddSlot(Slot, GroupId)
    if GroupId < 1 then
        return
    end
    if Slot > AchievementModel.MAX_SLOT_COUNT then
        CWaring("AchievementModel:AddSlot Slot is Over Count!")
        return
    end
    local OldId = self.SlotList[Slot]

    if OldId == GroupId then
        return
    end

    ---@type AchievementData
    local Data = self:GetData(GroupId)
    if not Data or Data.SlotId > 0 then
        return
    end

    self:SetCompleteListDirty(GroupId, true)
    self:ResetSlotByAchieveId(OldId, 0)
    self:ResetSlotByAchieveId(GroupId, Slot)
    self.SlotList[Slot] = GroupId
    self:DispatchType(AchievementModel.ACHIEVE_STATE_CHANGE_ON_SLOT, {Id = GroupId, OldId = OldId, Slot = Slot}) 
    MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.CHECK_ACHIEVEMENT_CORNER_TAG,{Id = GroupId, OldId = OldId, Slot = Slot})
end

function AchievementModel:AddSlotByUniId(Slot, UniId)
    local TempCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_AchievementCfg, Cfg_AchievementCfg_P.ID, UniId)
    if not TempCfg then
        return
    end
    local AchvGroupId = TempCfg[Cfg_AchievementCfg_P.MissionID]
    self:AddSlot(Slot, AchvGroupId)
end

function AchievementModel:ResetSlotByAchieveId(GroupId, Slot)
    if not GroupId then
        return
    end
    local Data = self:GetData(GroupId)
    if Data then
        Data.SlotId = Slot
    end
end

function AchievementModel:RemoveSlotByUniId(UniId)
    local TempCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_AchievementCfg, Cfg_AchievementCfg_P.ID, UniId)
    if not TempCfg then
        return
    end
    local AchvGroupId = TempCfg[Cfg_AchievementCfg_P.MissionID]
    self:RemoveSlotById(AchvGroupId)
end

function AchievementModel:RemoveSlotById(GroupId)
    self:SetCompleteListDirty(GroupId, true)
    self:ResetSlotByAchieveId(GroupId, 0)
    local CommonModel = MvcEntry:GetModel(CommonModel)
    for k, v in pairs(self.SlotList) do
        if v == GroupId then
            self.SlotList[k] = nil
            self:DispatchType(AchievementModel.ACHIEVE_STATE_CHANGE_ON_SLOT, {Id = 0, OldId = GroupId, Slot = k}) 
            CommonModel:DispatchType(CommonModel.CHECK_ACHIEVEMENT_CORNER_TAG,{Id = 0, OldId = GroupId, Slot = k})
            return
        end
    end
end

function AchievementModel:RemoveSlot(Slot)
    self:SetCompleteListDirty(Id, true)
    local OldId = self.SlotList[Slot]
    self.SlotList[Slot] = nil
    if OldId then
        self:ResetSlotByAchieveId(OldId, 0)
        self:DispatchType(AchievementModel.ACHIEVE_STATE_CHANGE_ON_SLOT, {Id = 0, OldId = OldId, Slot = Slot}) 
        MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.CHECK_ACHIEVEMENT_CORNER_TAG,{Id = 0, OldId = OldId, Slot = Slot})
    end
end

--- func desc
---@param List AchievementData
function AchievementModel:SortList(List, PlayerId)
    if not List or #List < 2 then
        return List
    end

    table.sort(List, function(a, b)
        local AData = self:GetPlayerData(a, PlayerId)
        local BData = self:GetPlayerData(b, PlayerId)
        if not AData or not BData then
            return false
        end
        if AData:IsUnlock() ~= BData:IsUnlock() then
            return (AData:IsUnlock() and 1 or 0) > (BData:IsUnlock() and 1 or 0) --已解锁大于未解锁
        else
            if AData:IsEquiped() ~= BData:IsEquiped() then
                return (AData:IsEquiped() and 1 or 0) > (BData:IsEquiped() and 1 or 0) --已装备大于未装备
            end
            if AData.LV ~= BData.LV then
                return AData.LV > BData.LV --高等级大于低等级
            end
            if AData.GetTimeStamp ~= BData.GetTimeStamp then
                return AData.GetTimeStamp > BData.GetTimeStamp --按获取时间
            end
            return AData.ID > BData.ID --按ID大小
        end
    end)

    return List
end

--- func desc
---@param PlayerId any
---@param Id any
---@return AchievementData
function AchievementModel:GetPlayerAchieveData(PlayerId, UniId, GroupId)
    local TempData = self.PlayerDataComplete[PlayerId]
    TempData = TempData or {}
    TempData["Map"] = TempData["Map"] or {}
    TempData["List"] = TempData["List"] or {}
    TempData["Slot"] = TempData["Slot"] or {}
    if not TempData["Map"][GroupId] then
        ---@type AchievementData
        local Data = PoolManager.GetInstance(AchievementData)
        Data:InitDataFromCfgId(UniId)
        table.insert(TempData["List"], Data.ID)
        TempData["Map"][GroupId] = Data
    end
    self.PlayerDataComplete[PlayerId] = TempData
    return TempData["Map"][GroupId]
end

--- func desc
---@param PlayerId any
---@return AchievementData
function AchievementModel:GetPlayerCompleteList(PlayerId)
    if not self.PlayerDataComplete[PlayerId] or not self.PlayerDataComplete[PlayerId]["List"] then
        return
    end
    if not self.PlayerDataComplete[PlayerId].IsDirty then
        self.PlayerDataComplete[PlayerId]["List"] = self:SortList(self.PlayerDataComplete[PlayerId]["List"], PlayerId)
        self.PlayerDataComplete[PlayerId].IsDirty = true
    end
    return self.PlayerDataComplete[PlayerId]["List"]
end

function AchievementModel:GetPlayerData(Id, PlayerId)
    if not PlayerId or PlayerId == 0 or MvcEntry:GetModel(UserModel):IsSelf(PlayerId) then
        return self:GetData(Id)
    end
    
    if not self.PlayerDataComplete[PlayerId] or not self.PlayerDataComplete[PlayerId]["Map"] then
        return nil
    end
    return self.PlayerDataComplete[PlayerId]["Map"][Id]
end

function AchievementModel:GetGameAchiList(GameId)
    if not GameId or tonumber(GameId) < 1 then
        return
    end
    if not self.GameAchiData[GameId] then
        return
    end
    if self.GameAchiData[GameId].IsDirty then
        self.GameAchiData[GameId]["ChangeList"] = self:SortList(self.GameAchiData[GameId]["ChangeList"])
    end
    return self.GameAchiData[GameId]["ChangeList"] , self.GameAchiData[GameId]["CompleteList"]
end

function AchievementModel:SetGameAchiData(GameId, Id)
    if not GameId or tonumber(GameId) < 1 then
        return
    end
    self.GameAchiData[GameId] = self.GameAchiData[GameId] or {}
    self.GameAchiData[GameId]["ChangeList"] = self.GameAchiData[GameId]["ChangeList"] or {}
    self.GameAchiData[GameId]["CompleteList"] = self.GameAchiData[GameId]["CompleteList"] or {}
    self.GameAchiData[GameId].IsDirty = true
    table.insert(self.GameAchiData[GameId]["ChangeList"], Id)
    ---@type AchievementData
    local Data = self:GetData(Id)
    if Data.IsUpLV then
        table.insert(self.GameAchiData[GameId]["CompleteList"], Id)
    end
end


function AchievementModel:AddPlayerSlotByGroupId(Slot, SlotData, PlayerId)
    local GroupId = SlotData and SlotData.AchvGroupId or 0
    if MvcEntry:GetModel(UserModel):IsSelf(PlayerId) then
        self:AddSlot(Slot, GroupId)
    else
        self.PlayerDataComplete[PlayerId] = self.PlayerDataComplete[PlayerId] or {}
        self.PlayerDataComplete[PlayerId]["Slot"] = self.PlayerDataComplete[PlayerId]["Slot"] or {}
        self.PlayerDataComplete[PlayerId]["Slot"][Slot] = GroupId
    end
end

function AchievementModel:GetPlayerSlotAchieveId(Slot, PlayerId)
    PlayerId = PlayerId or 0 
    if MvcEntry:GetModel(UserModel):IsSelf(PlayerId) then
        return self:GetSlotAchieveId(Slot)
    end
    if not self.PlayerDataComplete[PlayerId] then
        return
    end
    if not self.PlayerDataComplete[PlayerId]["Slot"] then
        return
    end
    return self.PlayerDataComplete[PlayerId]["Slot"][Slot] 
end

function AchievementModel:ConvertUniId2GroupId(UniId)
    if not UniId then
        return
    end
    local TempCfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCfg, UniId)
    if not TempCfg then
        return
    end
    return TempCfg[Cfg_AchievementCfg_P.MissionID]
end

--[[
    获取下一级ItemData
]]
function AchievementModel:GetItemShowInfo(InData, InIsShowFrist)
    --判断下是否在组里面，如果是，则展示下一级未获得的成就
    local hasMissionIds = G_ConfigHelper:GetMultiItemsByKey(Cfg_AchievementCfg, Cfg_AchievementCfg_P.MissionID, InData.ID)
    local resultData = InData

    if #hasMissionIds > 1 then
        if InData.Quality == 1 and InData.State == AchievementConst.OWN_STATE.Not then
            return resultData
        end
        if InIsShowFrist then
            return resultData
        end
        if InData.Quality < #hasMissionIds then
            local cfgData = G_ConfigHelper:GetSingleItemByKeys(Cfg_AchievementCfg, {Cfg_AchievementCfg_P.Quality, Cfg_AchievementCfg_P.MissionID} , {InData.Quality + 1, InData.ID})
            resultData = PoolManager.GetInstance(AchievementData)
            resultData:InitDataFromCfgId(cfgData[Cfg_AchievementCfg_P.ID])
            resultData.State = AchievementConst.OWN_STATE.Have
        end
    end

    return resultData
end

--[[
    根据英雄Id获取对应成就信息以及其余通用成就
]]
function AchievementModel:GetAchievementDataByHeroId(InHeroId)
    InHeroId = InHeroId or 0
    local resultTable = {}
    for GroupType, tabCfg in pairs(self.TabCfgList) do
        if GroupType == AchievementConst.GROUP_DEF.HERO then
            for _, tabAchievementData in pairs(tabCfg) do
                local HeroCfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCategoryConfig, tabAchievementData[Cfg_AchievementCfg_P.SecTypeID])
                if HeroCfg and HeroCfg[Cfg_AchievementCategoryConfig_P.AttachHeroID] == InHeroId then
                    local heroAchievementData = self:GetData(tabAchievementData[Cfg_AchievementCfg_P.MissionID])
                    table.insert(resultTable, heroAchievementData)
                end
            end
        else
            local dataList = self:GetListByType(GroupType)
            for _, achievementOtherGroupId in pairs(dataList) do
                local data = self:GetData(achievementOtherGroupId)
                if data then
                    table.insert(resultTable, data)
                end
            end
        end
    end
    return resultTable
end


--[[
    因为表格结构变更, 目前先缓存个人中心中对应的成就一级Tab数据
]]
function AchievementModel:InitTabDataList(Cfg)
    local TempSecTyIdList = {}
    for _, data in pairs(Cfg) do
        if data.TypeID > 0 then
            self.TabCfgList[data.TypeID] = self.TabCfgList[data.TypeID] or {}
            if data.SecTypeID > 0 then
                if not TempSecTyIdList[data.SecTypeID] then
                    TempSecTyIdList[data.SecTypeID] = data.SecTypeID
                    table.insert(self.TabCfgList[data.TypeID], data)
                end
            end
        end
    end
end

function AchievementModel:GetTabDataByTypeID(InTypeID)
    return self.TabCfgList[InTypeID]
end

-- 通过成就唯一ID获取对应的成就名称
function AchievementModel:GetAchievementNameByUniId(UniId)
    local TempCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_AchievementCfg, Cfg_AchievementCfg_P.ID, UniId)
    if not TempCfg then
        return
    end
    local AchievementName = TempCfg[Cfg_AchievementCfg_P.Name]
    return AchievementName
end

-- 通过成就唯一ID获取对应的成就品质
function AchievementModel:GetAchievementQualityByUniId(UniId)
    local TempCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_AchievementCfg, Cfg_AchievementCfg_P.ID, UniId)
    if not TempCfg then
        return
    end
    local Quality = TempCfg[Cfg_AchievementCfg_P.Quality]
    return Quality
end



--[[
    缓存个人中心中对应的用户Id
]]
function AchievementModel:SetPersonInfoPlayerId(InPlayerId)
    self.PersonInfoPlayerId = InPlayerId
end
function AchievementModel:GetPersonInfoPlayerId()
    return self.PersonInfoPlayerId
end

---获取成就对应的图片
function AchievementModel:GetAchievementIcon(InAchieveId)
    local Icon = ""
    ---@type AchievementData
    local AchieveData = self:GetData(InAchieveId)
    if AchieveData then
        Icon = AchieveData:GetIcon() 
    else
        local AchieveCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_AchievementCfg, {Cfg_AchievementCfg_P.MissionID,Cfg_AchievementCfg_P.SubID},{InAchieveId,1})
        if AchieveCfg then
            Icon = AchieveCfg[Cfg_AchievementCfg_P.Image]
        end
    end
    return Icon
end

function AchievementModel:SetLoadingType(InType)
    self.LoadingType = InType
end

function AchievementModel:GetLoadingType()
    if self.LoadingType == LoadingCtrl.TypeEnum.HALL_TO_BATTLE then
        return self.LoadingType
    end
    local type = self.LoadingType
    self.LoadingType = LoadingCtrl.TypeEnum.HALL_TO_BATTLE
    return type
end


return AchievementModel;
