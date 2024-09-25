--[[
    头像相关数据模型
]]

local super = GameEventDispatcher;
local class_name = "HeadIconSettingModel";

---@class HeadIconSettingModel : GameEventDispatcher
---@field private super GameEventDispatcher
HeadIconSettingModel = BaseClass(super, class_name)
HeadIconSettingModel.ON_SELECT_ITEM  = "ON_SELECT_ITEM" -- （界面使用）记录选中
HeadIconSettingModel.ON_SELECT_ITEM_AND_EDIT  = "ON_SELECT_ITEM_AND_EDIT" -- （界面使用）选中并且进入编辑
HeadIconSettingModel.ON_HEAD_ICON_UNLOCK  = "ON_HEAD_ICON_UNLOCK"   -- 头像解锁
HeadIconSettingModel.ON_USE_HEAD_ICON  = "ON_USE_HEAD_ICON" -- 使用了新头像
HeadIconSettingModel.ON_HEAD_FRAME_UNLOCK  = "ON_HEAD_FRAME_UNLOCK" -- 头像框解锁
HeadIconSettingModel.ON_HEAD_WIDGET_UNLOCK  = "ON_HEAD_WIDGET_UNLOCK"   -- 头像挂件解锁
HeadIconSettingModel.ON_HEAD_FRAME_AND_WIDGET_CHANGED  = "ON_HEAD_FRAME_AND_WIDGET_CHANGED" -- 头像框和挂件更新
HeadIconSettingModel.ON_HEAD_WIDGET_COUNT_CHANGED  = "ON_HEAD_WIDGET_COUNT_CHANGED" -- 头像挂件数量变化 （增删）
HeadIconSettingModel.ON_HEAD_WIDGET_EDITING  = "ON_HEAD_WIDGET_EDITING" -- （界面使用）进入头像挂件编辑模式
HeadIconSettingModel.ON_ADJUST_HEAD_WIDGET_ANGLE  = "ON_ADJUST_HEAD_WIDGET_ANGLE"   -- （界面使用） 调整头像挂件角度
HeadIconSettingModel.CLEAR_SELECT  = "CLEAR_SELECT"   -- （界面使用） 调整头像挂件角度
HeadIconSettingModel.ON_SET_HEAD_WIDGET_CAN_SELECT  = "ON_SET_HEAD_WIDGET_CAN_SELECT"   -- （界面使用） 设置挂件是否可选中进入编辑模式

-- 头像设置类型
HeadIconSettingModel.SettingType = {
    -- 头像
    HeadIcon = 1,
    -- 头像框
    HeadFrame = 2,
    -- 头像挂件
    HeadWidget = 3,
}

-- 头像挂件类型
HeadIconSettingModel.HeadWidgetType = {
    CanRotate = 1,  -- 可旋转
    Static = 2, -- 保持竖直状态
}

-- 自定义头像系列ID
HeadIconSettingModel.CustomHeadSeriesId = 3
-- 自定义头像ID 
HeadIconSettingModel.CustomHeadId = 0

function HeadIconSettingModel:__init()
    ---@type DepotModel
    self.DepotModel = MvcEntry:GetModel(DepotModel)
    ---@type PersonalInfoModel
    self.PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)
    self:_dataInit()
end

function HeadIconSettingModel:_dataInit()
    -- {[SettingType] = {[头像Id] = Cfg}}
    self.HeadIconSettingCfgs = {}
    -- {[SettingType] = {序列Cfg,序列Cfg,序列Cfg}}
    self.HeadIconSettingSeriesCfgs = {}
    -- {[SettingType] = {[头像序列Id] = {头像Id, 头像Id, 头像Id }}}
    self.HeadIconSettingSeries2Id = {}
    -- 头像挂件列表缓存（记录增删缓存）
    self.HeadWidgetTempList = nil
    -- 头像挂件操作角度缓存记录
    self.RotationCacheList = {}
    self.ItemSelectParam = nil

    -- 我的自定义头像地址URL
    self.MySelfCustomHeadUrl = ""
    -- 我的审核中自定义头像地址URL
    self.MySelfToExamineCustomHeadUrl = ""
end

function HeadIconSettingModel:OnLogin(data)
    self:InitSettingCfgs()
end

--[[
    玩家登出时调用
]]
function HeadIconSettingModel:OnLogout(data)
    HeadIconSettingModel.super.OnLogout(self)
    self:_dataInit()
end

-------- 对外接口 -----------

-- 获取系列配置
function HeadIconSettingModel:GetHeadSettingSeriesCfgs(SetttingType)
    if self.HeadIconSettingSeriesCfgs and self.HeadIconSettingSeriesCfgs[SetttingType] then
        return self.HeadIconSettingSeriesCfgs[SetttingType]
    end
    return nil
end

-- 获取系列中的Id
function HeadIconSettingModel:GetShowListForSeries(SettingType,SeriesId)
    local ShowList = {}
    local DepotModel = MvcEntry:GetModel(DepotModel)
    if self.HeadIconSettingSeries2Id and self.HeadIconSettingSeries2Id[SettingType] and self.HeadIconSettingSeries2Id[SettingType][SeriesId] then
        if SettingType == HeadIconSettingModel.SettingType.HeadWidget then
            -- 头像组件需要根据数量展开
            local Ids = self.HeadIconSettingSeries2Id[SettingType][SeriesId]
            for _,Id in ipairs(Ids) do
                local Cfg = self:GetHeadIconSettintCfg(SettingType,Id)
                if Cfg then
                    local ItemId = Cfg[Cfg_HeadWidgetCfg_P.ItemId]
                    local HaveCount = DepotModel:GetItemCountByItemId(ItemId)
                    if HaveCount > 1 then
                        -- 拥有数量超过1个时，Id更改为{Id,Id_1,Id_2,...}
                        ShowList[#ShowList + 1] = Id 
                        for I = 2,HaveCount do
                            local UniqueId = self:TransId2UniqueId(Id,I-1)
                            ShowList[#ShowList + 1] = UniqueId     
                        end
                    else
                        ShowList[#ShowList + 1] = Id 
                    end
                end
            end
        else
            ShowList = self.HeadIconSettingSeries2Id[SettingType][SeriesId]
        end
    end
    return ShowList
end

-- 头像/是否解锁
function HeadIconSettingModel:IsHeadUnlock(HeadId)
    return self:IsSettingUnlock(HeadIconSettingModel.SettingType.HeadIcon, HeadId)
    
end

-- 头像框是否解锁
function HeadIconSettingModel:IsHeadFrameUnlock(HeadFrameId)
    return self:IsSettingUnlock(HeadIconSettingModel.SettingType.HeadFrame, HeadFrameId)
end

-- 判断是否解锁
function HeadIconSettingModel:IsSettingUnlock(SettingType, Id)
    Id = self:TransUniqueId2Id(Id)
    local Cfgs = self.HeadIconSettingCfgs[SettingType]
    if not Cfgs then
        return false
    end
    local Cfg = self.HeadIconSettingCfgs[SettingType][Id]
    if not Cfg then
        CWaring("IsHeadUnlock Can't Get Setting Cfg For Type = "..SettingType.." ,Id = "..Id)
        return false
    end
    local _,CfgKey = self:GetSettintCfgNameAndKey(SettingType)
    if CfgKey then
        local ItemId = Cfg[CfgKey.ItemId] 
        local HaveNum = self.DepotModel:GetItemCountByItemId(ItemId)
        return HaveNum > 0 
    else
        CWaring("IsHeadUnlock Can't Get Setting CfgNameAndKey For Type = "..SettingType.." ,Id = "..Id)
        return false
    end
end

-- 获取使用中的Id
function HeadIconSettingModel:GetUsingId(SettingType)
    local TypeEnum = HeadIconSettingModel.SettingType
    if SettingType == TypeEnum.HeadIcon then
        local SelectPortraitUrl = self.PersonalInfoModel:GetMyPlayerProperty("SelectPortraitUrl")
        local UsingId = SelectPortraitUrl and HeadIconSettingModel.CustomHeadId or self.PersonalInfoModel:GetMyPlayerProperty("HeadId")
        return UsingId
    elseif SettingType == TypeEnum.HeadFrame then
        return self.PersonalInfoModel:GetMyPlayerProperty("HeadFrameId")
    elseif SettingType == TypeEnum.HeadWidget then
        -- 头像挂件是一个列表
        return self:GetUsingHeadWidgetList()
    end
end

-- 头像是否使用中
function HeadIconSettingModel:IsHeadIconUsing(HeadId)
    local SelectPortraitUrl = self.PersonalInfoModel:GetMyPlayerProperty("SelectPortraitUrl")
    local MyHeadId = SelectPortraitUrl and HeadIconSettingModel.CustomHeadId or self.PersonalInfoModel:GetMyPlayerProperty("HeadId")
    return MyHeadId == HeadId
end

-- 头像框是否使用中
function HeadIconSettingModel:IsHeadFrameUsing(HeadFrameId)
    local MyHeadFrameId = self.PersonalInfoModel:GetMyPlayerProperty("HeadFrameId")
    if not MyHeadFrameId then
        return false
    end
    return MyHeadFrameId == HeadFrameId
end

-- 头像组件是否使用中
function HeadIconSettingModel:IsHeadWidgetUsing(HeadWidgetId)
    local HeadWidgetList = self:GetUsingHeadWidgetList()
    if not HeadWidgetList or #HeadWidgetList == 0 then
        return false
    end
    local IsUsing = false
    for _,HeadWidgetNode in ipairs(HeadWidgetList) do
        if HeadWidgetNode.HeadWidgetId == HeadWidgetId then
            IsUsing = true
            break
        end
    end
    return IsUsing
end

-- 判断是否使用中
function HeadIconSettingModel:IsSettingUsing(SettingType, Id)
    local TypeEnum = HeadIconSettingModel.SettingType
    if SettingType == TypeEnum.HeadIcon then
        return self:IsHeadIconUsing(Id)
    elseif SettingType == TypeEnum.HeadFrame then
        return self:IsHeadFrameUsing(Id)
    elseif SettingType == TypeEnum.HeadWidget then
        return self:IsHeadWidgetUsing(Id)
    end
end

-- 获取配置
function HeadIconSettingModel:GetHeadIconSettintCfg(SettingType,Id)
    if not Id then
        return nil
    end
    Id = self:TransUniqueId2Id(Id)
    if self.HeadIconSettingCfgs and self.HeadIconSettingCfgs[SettingType] and self.HeadIconSettingCfgs[SettingType][Id] then
        return self.HeadIconSettingCfgs[SettingType][Id]
    end
    return nil
end

-- 获取配置表名和Key
function HeadIconSettingModel:GetSettintCfgNameAndKey(SettingType)
    local CfgName,CfgKey = nil,nil
    local TypeEnum = HeadIconSettingModel.SettingType
    if SettingType == TypeEnum.HeadIcon then
        CfgName =  Cfg_HeroHeadConfig
        CfgKey =  Cfg_HeroHeadConfig_P
    elseif SettingType == TypeEnum.HeadFrame then
        CfgName =  Cfg_HeadFrameCfg
        CfgKey =  Cfg_HeadFrameCfg_P
    elseif SettingType == TypeEnum.HeadWidget then
        CfgName = Cfg_HeadWidgetCfg
        CfgKey =  Cfg_HeadWidgetCfg_P
    end
    return CfgName,CfgKey
end

-- 获取系列配置表名和Key
function HeadIconSettingModel:GetSettintSeriesCfgNameAndKey(SettingType)
    local CfgName,CfgKey = nil,nil
    local TypeEnum = HeadIconSettingModel.SettingType
    if SettingType == TypeEnum.HeadIcon then
        CfgName =  Cfg_HeadIconSeriesCfg
        CfgKey =  Cfg_HeadIconSeriesCfg_P
    elseif SettingType == TypeEnum.HeadFrame then
        CfgName =  Cfg_HeadFrameSeriesCfg
        CfgKey =  Cfg_HeadFrameSeriesCfg_P
    elseif SettingType == TypeEnum.HeadWidget then
        CfgName = Cfg_HeadWidgetSeriesCfg
        CfgKey =  Cfg_HeadWidgetSeriesCfg_P
    end
    return CfgName,CfgKey
end

-- 获取当前总容量
function HeadIconSettingModel:GetCurMaxWeight()
    local SettingType = HeadIconSettingModel.SettingType.HeadFrame
    local CurFrameId = self:GetUsingId(SettingType)
    if not CurFrameId then
        return 0
    end
    return self:GetHeadFrameTotalWeight(CurFrameId)
end

-- 获取当前已用容量
function HeadIconSettingModel:GetCurUseWeight()
    local SettingType = HeadIconSettingModel.SettingType.HeadWidget
    local HeadWidgetList = self:GetUsingHeadWidgetList()
    if not HeadWidgetList or #HeadWidgetList == 0 then
        return 0
    end
    local UseWeight = 0
    for _,HeadWidgetNode in ipairs(HeadWidgetList) do
        local Cfg = self:GetHeadIconSettintCfg(SettingType,HeadWidgetNode.HeadWidgetId)
        if Cfg then
            UseWeight = UseWeight + Cfg[Cfg_HeadWidgetCfg_P.Weight]
        end
    end
    return UseWeight
end

-- 获取单个头像框的总容量
function HeadIconSettingModel:GetHeadFrameTotalWeight(HeadFrameId)
    local Cfg = self:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadFrame,HeadFrameId)
    if not Cfg then
        return 0
    end
    return Cfg[Cfg_HeadFrameCfg_P.MaxWeight]
end

-- 获取单个挂件的容量
function HeadIconSettingModel:GetHeadWidgetWeight(WidgetId)
    local ToUseWeight = 0
    if WidgetId then
        local Cfg = self:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadWidget,WidgetId)
        if Cfg then
            ToUseWeight = Cfg[Cfg_HeadWidgetCfg_P.Weight]
        end
    end
    return ToUseWeight
end

-- 获取容量信息
function HeadIconSettingModel:GetWeightInfo(ToSelectWidgetId)
    -- 总容量
    local TotalWeight = self:GetCurMaxWeight()
    -- 将使用的容量
    local ToUseWeight = self:GetHeadWidgetWeight(ToSelectWidgetId)
    
    local WeightInfo = {
        Total = TotalWeight,
        ToUse = ToUseWeight
    }

    if ToUseWeight > TotalWeight then
        -- 将使用的容量 已经超过 总容量
        WeightInfo.Full = ToUseWeight
    else
        WeightInfo.Use = 0
        -- local HeadWidgetList = self:GetUsingHeadWidgetList()
        local HeadWidgetList = self:GetSortedUsingHeadWidgetList()
        if HeadWidgetList and #HeadWidgetList > 0 then
            -- for _,HeadWidgetNode in ipairs(HeadWidgetList) do
            -- 从后往前遍历，优先放入后添加的挂件
            for Index = #HeadWidgetList , 1, -1 do
                local HeadWidgetNode = HeadWidgetList[Index]
                if HeadWidgetNode.HeadWidgetId == ToSelectWidgetId then
                    WeightInfo.Use = WeightInfo.Use + ToUseWeight
                    ToUseWeight = 0
                    WeightInfo.ToUse = 0
                else
                    local Cfg = self:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadWidget,HeadWidgetNode.HeadWidgetId)
                    if Cfg then
                        local Weight = Cfg[Cfg_HeadWidgetCfg_P.Weight]
                        if WeightInfo.Use + Weight + ToUseWeight <= TotalWeight then
                            -- 从前往后看能放几个，放不下的将会被卸下
                            WeightInfo.Use = WeightInfo.Use + Weight
                        else
                            break
                        end
                    end
                end
            end 
        end
    end
    return WeightInfo
end

-- 是否超过当前最大容量
function HeadIconSettingModel:IsFullWeight(ToSelectWidgetId)
    local TotalWeight = self:GetCurMaxWeight()
    local CurUseWeight = self:GetCurUseWeight()
    local ToUseWeight = self:GetHeadWidgetWeight(ToSelectWidgetId)
    return ToUseWeight > (TotalWeight - CurUseWeight)
end

-- 获取当前挂件的角度
function HeadIconSettingModel:GetHeadWidgetAngle(HeadWidgetId)
    if not HeadWidgetId then
        return 0
    end
    local HeadWidgetList = self:GetUsingHeadWidgetList()
    for _,HeadWidgetNode in ipairs(HeadWidgetList) do
        if HeadWidgetNode.HeadWidgetId == HeadWidgetId then
            return HeadWidgetNode.Angle or 0
        end
    end
    return 0
end
----------------------------------------
-- 头像挂件操作记录缓存
-- 所有操作取最后一步缓存作为基准，缓存会在 保存到服务器后/关闭界面 清空

-- 清空缓存
function HeadIconSettingModel:ClearHeadWidgetTemp()
    self.HeadWidgetTempList = nil
    self.RotationCacheList = {}
end

-- 获取当前生效中的头像挂件列表
function HeadIconSettingModel:GetUsingHeadWidgetList()
    if self.HeadWidgetTempList == nil then
        self.HeadWidgetTempList = {}
        local UseIdCount = {}
        local List = MvcEntry:GetModel(PersonalInfoModel):GetMyPlayerProperty("HeadWidgetList")
        for Index,HeadWidgetNode in ipairs(List) do
            local NewNode = {}
            local WidgetId = HeadWidgetNode.HeadWidgetId
            UseIdCount[WidgetId] = UseIdCount[WidgetId] or 0
            local CurCount = UseIdCount[WidgetId]
            if CurCount > 0 then
                local UniqueId = self:TransId2UniqueId(WidgetId,CurCount)
                NewNode.HeadWidgetId = UniqueId
            else
                NewNode.HeadWidgetId = WidgetId
            end
            UseIdCount[WidgetId] = UseIdCount[WidgetId] + 1
            NewNode.Angle = HeadWidgetNode.Angle
            self.HeadWidgetTempList[#self.HeadWidgetTempList + 1] = NewNode
        end
    end
    return self.HeadWidgetTempList
end

--[[
    用于需要进行替换判断的 生效中头像挂件列表
    替换顺序：优先判断重量，再考虑装备时间
    重量优先放小的
    时间优先放后添加的
]]
function HeadIconSettingModel:GetSortedUsingHeadWidgetList()
    local List = self:GetUsingHeadWidgetList()
    -- local TempList = DeepCopy(List)
    -- sort 不稳定，这里必须严格保证weight相等情况下原先的顺序
    -- local Indices = {}
    -- for I = 1, #List do
    --     Indices[I] = I
    -- end
    -- table.sort(Indices,function(A,B)
    --     local WeightA = self:GetHeadWidgetWeight(List[A].HeadWidgetId)
    --     local WeightB = self:GetHeadWidgetWeight(List[B].HeadWidgetId)
    --     if WeightA ~= WeightB then
    --         return WeightA > WeightB
    --     else
    --         return A < B
    --     end
    -- end)
    -- local TempList = {}
    -- for I = 1, #List do
    --     TempList[I] = DeepCopy(List[Indices[I]])
    --   end
    -- return TempList
    return CommonUtil.StableSort(List,function(A,B)
        local WeightA = self:GetHeadWidgetWeight(List[A].HeadWidgetId)
        local WeightB = self:GetHeadWidgetWeight(List[B].HeadWidgetId)
        if WeightA ~= WeightB then
            return WeightA > WeightB
        else
            return A < B
        end
    end)
end

-- 添加一个挂件
function HeadIconSettingModel:AddHeadWidgetTemp(TargetHeadWidgetId)
    -- local LastList = self:GetUsingHeadWidgetList()
    local LastList = self:GetSortedUsingHeadWidgetList()
    local NewList = {}
    local TotalWeight = self:GetCurMaxWeight()
    local ToUseWeight = self:GetHeadWidgetWeight(TargetHeadWidgetId)
    local HaveUseWeight = 0
    if LastList and #LastList > 0 then
        -- for _,HeadWidgetNode in ipairs(LastList) do
        -- 从后往前遍历，优先放入后添加的挂件
        for Index = #LastList , 1, -1 do
            local HeadWidgetNode = LastList[Index]
            local Cfg = self:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadWidget,HeadWidgetNode.HeadWidgetId)
            if Cfg then
                local Weight = Cfg[Cfg_HeadWidgetCfg_P.Weight]
                if HaveUseWeight + Weight + ToUseWeight <= TotalWeight then
                    HaveUseWeight = HaveUseWeight + Weight
                    table.insert(NewList,1,{HeadWidgetId = HeadWidgetNode.HeadWidgetId , Angle = HeadWidgetNode.Angle})
                else
                    break
                end
            end
        end
    end
    table.insert(NewList,{HeadWidgetId = TargetHeadWidgetId , Angle = 0})
    self.HeadWidgetTempList = NewList
    self:DispatchType(HeadIconSettingModel.ON_HEAD_WIDGET_COUNT_CHANGED)
end

-- 删除一个挂件
function HeadIconSettingModel:DelHeadWidgetTemp(TargetHeadWidgetId)
    for Index = #self.HeadWidgetTempList , 1, -1 do
        if self.HeadWidgetTempList[Index].HeadWidgetId == TargetHeadWidgetId then
            table.remove(self.HeadWidgetTempList,Index)
            break
        end
    end
    -- 删除则立刻保存
    MvcEntry:GetCtrl(PersonalInfoCtrl):RequestChangeHeadWidget()
    -- self:DispatchType(HeadIconSettingModel.ON_HEAD_WIDGET_COUNT_CHANGED,true)
end

-- 添加一步操作缓存
function HeadIconSettingModel:PushRotationCache(Angle,IsReset)
    if IsReset then
        -- 针对单个挂件操作缓存，选中添加/调整另一个，则先清空之前的缓存
        self.RotationCacheList = {}
    end
    self.RotationCacheList[#self.RotationCacheList + 1] = Angle
end

-- 获取上一步操作缓存
function HeadIconSettingModel:PopRotationCache()
    if #self.RotationCacheList == 0 then
        return nil
    end
    local Rotation = self.RotationCacheList[#self.RotationCacheList - 1]
    self.RotationCacheList[#self.RotationCacheList] = nil
    return Rotation
end

-- 更新挂件的角度
function HeadIconSettingModel:UpdateHeadWidgetAngle(HeadWidgetId,Angle)
    local HeadWidgetList = self:GetUsingHeadWidgetList()
    for _,HeadWidgetNode in ipairs(HeadWidgetList) do
        if HeadWidgetNode.HeadWidgetId == HeadWidgetId then
            HeadWidgetNode.Angle = Angle
            break
        end
    end
end

----------------------------------------
-- 帮界面记录是否触发第一次选中
function HeadIconSettingModel:SetItemSelectParam(ItemSelectParam)
    self.ItemSelectParam = ItemSelectParam
end

function HeadIconSettingModel:GetItemSelectParam()
    return self.ItemSelectParam
end

----------------------------------------

-- 初始化配置
function HeadIconSettingModel:InitSettingCfgs()
    self.HeadIconSettingCfgs = {}
    self.HeadIconSettingSeries2Id = {}
    self.HeadIconSettingSeriesCfgs = {}
    local TypeEnum = HeadIconSettingModel.SettingType
    for _,SettingType in pairs (TypeEnum) do
        -- 基础信息配置
        self.HeadIconSettingCfgs[SettingType] = {}
        self.HeadIconSettingSeries2Id[SettingType] = {}
        local CfgName,CfgKey = self:GetSettintCfgNameAndKey(SettingType)
        if CfgName and CfgKey then
            local Cfgs = G_ConfigHelper:GetDict(CfgName)
            if Cfgs then
                for _,Cfg in ipairs(Cfgs) do
                    local Id = Cfg[CfgKey.HeadId or CfgKey.Id]
                    self.HeadIconSettingCfgs[SettingType][Id] = Cfg
                    local SeriesId = Cfg[CfgKey.SeriesId]
                    self.HeadIconSettingSeries2Id[SettingType][SeriesId] =  self.HeadIconSettingSeries2Id[SettingType][SeriesId] or {}
                    table.insert( self.HeadIconSettingSeries2Id[SettingType][SeriesId], Id)
                end
            end
        end

        -- 系列信息配置
        self.HeadIconSettingSeriesCfgs[SettingType] = {}
        local CfgName,CfgKey = self:GetSettintSeriesCfgNameAndKey(SettingType)
        if CfgName and CfgKey then
            local Cfgs = G_ConfigHelper:GetDict(CfgName)
            if Cfgs then
                for _,Cfg in ipairs(Cfgs) do
                    self.HeadIconSettingSeriesCfgs[SettingType][Cfg[CfgKey.SeriesId]] = Cfg
                end
                table.sort(self.HeadIconSettingSeriesCfgs[SettingType],function (SeriesCfgA,SeriesCfgB)
                    return SeriesCfgA[CfgKey.Sort] < SeriesCfgB[CfgKey.Sort]
                end)
            end
        end
        
    end
end

-- 头像挂件可能有数量叠加，需要前端自己区分，加上Id - 唯一Id 转换
function HeadIconSettingModel:TransId2UniqueId(Id,Index)
    return StringUtil.Format("{0}_{1}",tostring(Id),Index)
end

function HeadIconSettingModel:TransUniqueId2Id(UniqueId)
    local Index = string.find(UniqueId,"_")
    if Index then
        return tonumber(string.sub(UniqueId,1,Index-1))
    else
        return tonumber(UniqueId)
    end
end

-- 检测是否为自定义头像ID
function HeadIconSettingModel:CheckIsCustomHead(Id)
    local IsCustomHead = HeadIconSettingModel.CustomHeadId == Id
    return IsCustomHead
end

-- 检测自己是否拥有自定义头像
function HeadIconSettingModel:CheckMySelfIsHasCustomHead()
    local PortraitUrl = self.PersonalInfoModel:GetMyPlayerProperty("PortraitUrl")
    local IsHasCustomHead = PortraitUrl and PortraitUrl ~= ""
    return IsHasCustomHead
end

-- 检测自己的自定义头像是否审核中
function HeadIconSettingModel:CheckMySelfIsToExamineCustomHead()
    local AuditPortraitUrl = self.PersonalInfoModel:GetMyPlayerProperty("AuditPortraitUrl")
    local IsToExamine = AuditPortraitUrl and AuditPortraitUrl ~= ""
    return IsToExamine
end

-- 获取自己的自定义头像路径 
---@param IsToExamine boolean 是否优先获取审核中的头像
function HeadIconSettingModel:GetMySelfCustomHeadUrl(IsToExamine)
    local AuditPortraitUrl = self.PersonalInfoModel:GetMyPlayerProperty("AuditPortraitUrl")
    local PortraitUrl = self.PersonalInfoModel:GetMyPlayerProperty("PortraitUrl")
    local ShowPortraitUrl = (IsToExamine and AuditPortraitUrl and AuditPortraitUrl ~= "") and AuditPortraitUrl or PortraitUrl
    return ShowPortraitUrl
end

-- 判断是否可以上传自定义头像  一个月只能上传一次 暂时未添加
function HeadIconSettingModel:CheckIsCanUploadCustomHeadUrl()
    local IsCanUpload = true
    return IsCanUpload 
end