--[[
    好感度数据模型
]]

local super = GameEventDispatcher;
local class_name = "FavorabilityModel";

---@class FavorabilityModel : GameEventDispatcher
---@field private super GameEventDispatcher
FavorabilityModel = BaseClass(super, class_name)

FavorabilityModel.FAVOR_VALUE_CHANGED = "FAVOR_VALUE_CHANGED" -- 好感度数值变化
-- FavorabilityModel.FAVOR_LEVEL_CHANGED = "FAVOR_LEVEL_CHANGED" -- 好感度等级变化
-- FavorabilityModel.SPAWN_GIFT_BOX = "SPAWN_GIFT_BOX" -- 生成礼物盒子
-- FavorabilityModel.DESTROY_GIFT_BOX = "DESTROY_GIFT_BOX" -- 销毁礼物盒子
FavorabilityModel.ON_SEND_GIFT_SUCCESSED = "ON_SEND_GIFT_SUCCESSED" -- 送礼成功
FavorabilityModel.ON_RECEIVE_REWARD_SUCCESSED = "ON_RECEIVE_REWARD_SUCCESSED" -- 领取奖励成功
FavorabilityModel.LEVEL_LS_IS_PLAYING = "LEVEL_LS_IS_PLAYING" -- 升级LS是否播放中
FavorabilityModel.FAVOR_STORY_UPDATED = "FAVOR_STORY_UPDATED" -- 好感度故事状态变化

function FavorabilityModel:__init()
    self:_dataInit()
end

function FavorabilityModel:_dataInit()
    --[[
        [HeroId] = HeroFavorInfo
            {
                int32 FavorLevel = 1;               // 好感度等级
                int64 CurValue = 2;                 // 当前等级的好感度值
                map<int32, int64> PrizeList = 3;    // 已经领取的等级标识，key是等级，value是领取奖励的时间戳,未领取就没有这个key/value
                bool NotFirstEnterFlag = 4;         // true非首次进入，false首次进入
                map<int64, int32> TaskList = 5;     // TaskId：0/1任务状态
                map<int64, StoryPassageData> StoryDataMap = 6; // key是章节Id，value是段落列表信息
            }
    ]]
    self.FavorList = {}
    self.HeroStoryList = {}
    self.HeroPartId2Index = {}
    self.StoryComletedMap = {}
    self.StoryUnlockConditionList = {}

    self.AvatarTransform = {
        Mid = {Location = UE.FVector(20000, 0, 0), Rotation = UE.FRotator(0, 0, 0)},
        -- Left = { Location = UE.FVector(19970, 0, 0), Rotation = UE.FRotator(0, 0, 0)},
    }
end

function FavorabilityModel:OnLogin(data)
    -- self:_dataInit()
    if not self.RegistViewCheck then
        MvcEntry:GetCtrl(ViewController):AddExtraShowCheckFunc("FavorablityMainMdt",Bind(self,self.CheckIsFavorablityOpen))
        self.RegistViewCheck = true
    end
end

--[[
    玩家登出时调用
]]
function FavorabilityModel:OnLogout(data)
    FavorabilityModel.super.OnLogout(self)
    self:_dataInit()
    if self.RegistViewCheck then
        MvcEntry:GetCtrl(ViewController):RemoveExtraShowCheckFunc("FavorablityMainMdt")
        self.RegistViewCheck = false
    end
end

function FavorabilityModel:OnLogoutReconnect()
    FavorabilityModel.super.OnLogoutReconnect(self)
    if self.RegistViewCheck then
        MvcEntry:GetCtrl(ViewController):RemoveExtraShowCheckFunc("FavorablityMainMdt")
        self.RegistViewCheck = false
    end
end

--[[
    检测是否开放好感度系统
]]
function FavorabilityModel:CheckIsFavorablityOpen(Event)
    local ViewId = Event.viewId
    if ViewId ~= ViewConst.FavorablityMainMdt then
        return true
    end
    local Param  = Event.param
    if Param.JumpParam then
        Param.HeroId,Param.TabId = self:ParseFavorabilityJumpParams(Param.JumpParam)
    end
    local HeroId = Param.HeroId
    if not HeroId then
        return false
    end
    return self:IsFavorablityOpen(HeroId,true)
end

--[[
    英雄是否开放好感度
]]
function FavorabilityModel:IsFavorablityOpen(HeroId,IsTips)
    local FavorLevel = self:GetCurFavorLevel(HeroId)
    local HeroCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, HeroId)
    if not HeroCfg then
        return false
    end
    local IsUnlock = FavorLevel > 0 and HeroCfg[Cfg_HeroConfig_P.IsOpenFavor]
    if not IsUnlock then
        if IsTips then
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityEntranceLogic_LockTips"))
        end
        return false
    end
    return true
end

--[[
    获取场景下Avatar的站位和角度
]]
function FavorabilityModel:GetAvatarTransform()
    return self.AvatarTransform
end

-- 是否首次进入好感度系统
function FavorabilityModel:IsFirstEnterFavor(HeroId)
    if self.FavorList and self.FavorList[HeroId] then
        return not self.FavorList[HeroId].NotFirstEnterFlag
    end
    return true
end

-- 获取当前好感度等级
function FavorabilityModel:GetCurFavorLevel(HeroId)
    if self.FavorList and self.FavorList[HeroId] then
        return self.FavorList[HeroId].FavorLevel
    end
    return 0
end

-- 获取当前好感度数值
function FavorabilityModel:GetCurFavorValue(HeroId)
    if self.FavorList and self.FavorList[HeroId] then
        return self.FavorList[HeroId].CurValue
    end
    return 0
end

-- 获取当前等级需要的最大好感度数值
function FavorabilityModel:GetMaxFavorValueForLevel(Level)
    local CurLevelCfg = G_ConfigHelper:GetSingleItemById(Cfg_FavorLevelCfg,Level)
    if not CurLevelCfg then
        return 0
    end
    return CurLevelCfg[Cfg_FavorLevelCfg_P.Exp]
end

-- 获取配置最大的好感度等级
function FavorabilityModel:GetMaxFavorLevel()
    if not self.FavorMaxLevel then
        local Cfgs = G_ConfigHelper:GetDict(Cfg_FavorLevelCfg)
        self.FavorMaxLevel = Cfgs[#Cfgs][Cfg_FavorLevelCfg_P.Level]
    end
    return self.FavorMaxLevel
end

-- 是否已满级
function FavorabilityModel:IsFavorFullLevel(HeroId)
    return self:GetCurFavorLevel(HeroId) >= self:GetMaxFavorLevel(HeroId)
end

-- 获取可领取奖励的等级列表
function FavorabilityModel:GetCanReceiveRewardLevelList(HeroId)
    local List = {}
    if self.FavorList and self.FavorList[HeroId] then
        local CurLevel = self.FavorList[HeroId].FavorLevel
        if CurLevel > 0 then
            local PrizeList = self.FavorList[HeroId].PrizeList
            for Level = 1,CurLevel do
                if not PrizeList[Level] then
                    List[#List + 1] = Level
                end
            end    
        end
    end
    return List
end

-- 是否有可领取奖励
function FavorabilityModel:HaveRewardCanReceive(HeroId)
    -- return true
    local HaveReward = false
    if self.FavorList and self.FavorList[HeroId] then
        local CurLevel = self.FavorList[HeroId].FavorLevel
        if CurLevel > 1 then
            local PrizeList = self.FavorList[HeroId].PrizeList
            for Level = 2,CurLevel do
                if not PrizeList[Level] then
                    HaveReward = true
                    break
                end
            end    
        end
    end
    return HaveReward
end

-- 奖励是否已领取
function FavorabilityModel:IsRewardGot(HeroId,Level)
    if self.FavorList and self.FavorList[HeroId] then
        local PrizeList = self.FavorList[HeroId].PrizeList
        return PrizeList[Level] ~= nil
    end
    return false
end

-- 获取当前等级赠礼的前置限制段落ID，若无限制或已完成，返回0
function FavorabilityModel:GetSendGiftUnlockPartId(HeroId,CurLevel)
    local FavorLevelCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_FavorDropCfg,{Cfg_FavorDropCfg_P.HeroId,Cfg_FavorDropCfg_P.Level},{HeroId,CurLevel})
    if not FavorLevelCfg then
        return 0
    end
    local UnlockPartId = FavorLevelCfg[Cfg_FavorDropCfg_P.UnlockPartId]
    if UnlockPartId == 0 or self:GetPartStatus(HeroId,UnlockPartId) == FavorabilityConst.STORY_STATUS.COMPLETED then
        return 0
    end
    return UnlockPartId
end

-- 修正可使用的道具数量，看是否达到满级或者达到有限制条件的级别
function FavorabilityModel:FixMaxExpItemCount(HeroId,ItemId,ItemCount)
    local FavorItemExpCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_FavorItemExpCfg,{Cfg_FavorItemExpCfg_P.HeroId,Cfg_FavorItemExpCfg_P.ItemId},{HeroId,ItemId})
    if not FavorItemExpCfg then
        return 0
    end
    local AddExp = FavorItemExpCfg[Cfg_FavorItemExpCfg_P.FavorValue]
    local Level = self:GetCurFavorLevel(HeroId)
    local MaxLevel = self:GetMaxFavorLevel()
    if Level == MaxLevel then
        -- 已满级，不可再使用
        return 0
    end
    local CurExpValue = self:GetCurFavorValue()
    local CurLevelCfg = G_ConfigHelper:GetSingleItemById(Cfg_FavorLevelCfg,Level)
    if not CurLevelCfg then
        return 0
    end

    local MaxCount = 0
    local STATE_COMPLETED = FavorabilityConst.STORY_STATUS.COMPLETED
    for Count = 1,ItemCount do
        local CurDropCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_FavorDropCfg,{Cfg_FavorDropCfg_P.HeroId,Cfg_FavorDropCfg_P.Level},{HeroId,Level})
        if CurDropCfg then
            local UnlockPartId = CurDropCfg[Cfg_FavorDropCfg_P.UnlockPartId]
            if UnlockPartId > 0 and self:GetPartStatus(HeroId,UnlockPartId) ~= STATE_COMPLETED then
                -- 解锁限制未完成，不可以使用了
                break
            end
        end
        -- 无限制或完成了限制条件，可使用
        MaxCount = Count
        local NeedExp = CurLevelCfg[Cfg_FavorLevelCfg_P.Exp]
        if CurExpValue + AddExp >= NeedExp then
            -- 用完升级，改变等级
            Level = Level + 1
            CurExpValue = CurExpValue + AddExp - NeedExp
            CurLevelCfg = G_ConfigHelper:GetSingleItemById(Cfg_FavorLevelCfg,Level)
            if not CurLevelCfg then
                break
            end
        else
            CurExpValue = CurExpValue + AddExp
        end
        
    end
    return MaxCount
end

--[[
    获取段落状态
]]
function FavorabilityModel:GetPartStatus(HeroId,PartId)
    local STORY_STATUS = FavorabilityConst.STORY_STATUS
    local Status = STORY_STATUS.LOCK
    if not HeroId then
        return Status
    end
    if self.StoryComletedMap[HeroId] and self.StoryComletedMap[HeroId][PartId] and self.StoryComletedMap[HeroId][PartId] > 0 then
        -- 已完成
        Status = STORY_STATUS.COMPLETED
    else
        self:InitHeroStoryCfg(HeroId)
        local UnlockCondition = nil
        if self.StoryUnlockConditionList[HeroId] then
            UnlockCondition = self.StoryUnlockConditionList[HeroId][PartId]
        end
        if UnlockCondition then
            -- 判断是否解锁
            local UnlockType = UnlockCondition.UnlockType
            if UnlockType == FavorabilityConst.STORY_UNLOCK_TYPE.LEVEL then
                local CurLevel = self:GetCurFavorLevel(HeroId)
                if CurLevel >= UnlockCondition.UnlockParam then
                    Status = STORY_STATUS.NORMAL
                end
            elseif UnlockType == FavorabilityConst.STORY_UNLOCK_TYPE.PART then
                if self:GetPartStatus(HeroId,UnlockCondition.UnlockParam) == STORY_STATUS.COMPLETED then
                    Status = STORY_STATUS.NORMAL
                end
            elseif UnlockType == FavorabilityConst.STORY_UNLOCK_TYPE.TASK then
                if MvcEntry:GetModel(TaskModel):HasTaskFinished(UnlockCondition.UnlockParam) then
                    Status = STORY_STATUS.NORMAL
                end
            else
                Status = STORY_STATUS.NORMAL
            end
        else
            CWaring(StringUtil.Format("FavorabilityModel:GetPartStatus Can't Found UnlockCondition For HeroId = {0} PartId = {1}, Please Check",HeroId,PartId))
        end
    end
    return Status
end

-- 获取英雄可展示的剧情列表
function FavorabilityModel:GetHeroStoryShowList(HeroId)
    if not HeroId then
        return nil
    end
    self:InitHeroStoryCfg(HeroId)
    local AllList = self.HeroStoryList[HeroId]
    local ShowList = {}
    local STATUS_LOCK = FavorabilityConst.STORY_STATUS.LOCK
    for _,PartId in ipairs(AllList) do
        PartId = tonumber(PartId)
        local StoryCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_FavorStoryConfig,{Cfg_FavorStoryConfig_P.HeroId,Cfg_FavorStoryConfig_P.PartId},{HeroId,PartId})
        if StoryCfg then
            local IsKeyPart = StoryCfg[Cfg_FavorStoryConfig_P.IsKeyPart]
            if IsKeyPart or self:GetPartStatus(HeroId,PartId) ~= STATUS_LOCK then
                ShowList[#ShowList + 1] = StoryCfg
            end
        end
    end
    return ShowList
end

-- 获取该剧情id前，可播放的剧情
function FavorabilityModel:GetCanPlayStory(HeroId,ThePartId)
    local ShowList = self:GetHeroStoryShowList(HeroId)
    if not ShowList or #ShowList == 0 then
        return nil
    end
    local CanPlayStoryCfg = nil
    local STORY_STATUS_NORMAL = FavorabilityConst.STORY_STATUS.NORMAL
    local TaskModel = MvcEntry:GetModel(TaskModel)
    for _,StoryCfg in ipairs(ShowList) do
        local PartId = StoryCfg[Cfg_FavorStoryConfig_P.PartId]
        if PartId >= ThePartId then
            break
        end
        local PartStatus = self:GetPartStatus(HeroId,PartId)
        if PartStatus == STORY_STATUS_NORMAL then
            -- 普通可执行状态下 
            local TaskId = StoryCfg[Cfg_FavorStoryConfig_P.TaskId]
            if not TaskId or TaskId == 0 or not TaskModel:GetData(TaskId) then
                -- 没有任务 或 任务未接取 才允许播放
                CanPlayStoryCfg = StoryCfg
                break
            end
        end
    end
    return CanPlayStoryCfg
end

-- 恢复配置为树状结构
function FavorabilityModel:InitHeroStoryCfg(HeroId)
    if self.HeroStoryList[HeroId] then
        return
    end
    self.HeroStoryList[HeroId] = {}
    self.HeroPartId2Index[HeroId] = {}
    self.StoryUnlockConditionList[HeroId] = {}
    -- 读取解析配置
    local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_FavorStoryConfig, Cfg_FavorStoryConfig_P.HeroId, HeroId)
    if Cfgs then
        for _,Cfg in ipairs(Cfgs) do
            table.insert(self.HeroStoryList[HeroId],Cfg[Cfg_FavorStoryConfig_P.PartId])
            self.StoryUnlockConditionList[HeroId][Cfg[Cfg_FavorStoryConfig_P.PartId]] = 
            {
                UnlockType = Cfg[Cfg_FavorStoryConfig_P.UnlockType],
                UnlockParam = Cfg[Cfg_FavorStoryConfig_P.UnlockParam],
            }
        end
    end
    for HeroId, PartList in pairs(self.HeroStoryList) do
        table.sort(PartList,function(IdA,IdB)
            return IdA < IdB
        end)
        for Index, PartId in ipairs(PartList) do
            self.HeroPartId2Index[HeroId][PartId] = tonumber(Index)
        end
    end
end

--[[
    收到服务器返回的英雄好感度数据
    HeroFavorMap = {
        HeroId = message HeroFavorInfo
    }
]]
function FavorabilityModel:OnReceiveHeroFavorData(HeroFavorMap)
    self.FavorList = {}
    self.StoryComletedMap = {}
    for HeroId, HeroFavorInfo in pairs(HeroFavorMap) do
        self.FavorList[HeroId] = HeroFavorInfo
        self:SetStoryCompleteStatus(HeroId,HeroFavorInfo)
    end
end

-- 记录已经完成的剧情
function FavorabilityModel:SetStoryCompleteStatus(HeroId,HeroFavorInfo)
    self.StoryComletedMap[HeroId] = {}
    local StoryData  = HeroFavorInfo.StoryData
    if not StoryData then
        return
    end
    for PartId, Timestamp in pairs(StoryData) do
        PartId = tonumber(PartId)
        self.StoryComletedMap[HeroId][PartId] = Timestamp
    end
end

-- 标记剧情已完成
function FavorabilityModel:SetStoryCompleted(Msg)
    local HeroId = Msg.HeroId
    local PartId = Msg.PassageId
    self.StoryComletedMap[HeroId] = self.StoryComletedMap[HeroId] or {}
    self.StoryComletedMap[HeroId][PartId] = GetTimestamp()
    self:DispatchType(FavorabilityModel.FAVOR_STORY_UPDATED)
end

function FavorabilityModel:UpdateFavorInfo(Msg)
    local HeroId = Msg.HeroId
    if self.FavorList and self.FavorList[HeroId] then
        self.FavorList[HeroId].FavorLevel = Msg.FavorAfterLevel
        self.FavorList[HeroId].CurValue = Msg.CurValue
        self:DispatchType(FavorabilityModel.FAVOR_VALUE_CHANGED,Msg)
    end
end

-- 修改首次进入标记
function FavorabilityModel:SetHeroFirstEnterFlag(HeroId)
    if self.FavorList and self.FavorList[HeroId] then
        self.FavorList[HeroId].NotFirstEnterFlag = true
    end
end

-- 修改领奖标记
function FavorabilityModel:UpdateRewardStatus(HeroId,FavorLevelList)
    if self.FavorList and self.FavorList[HeroId] then
        local CurTime = GetTimestamp()
        local PrizeList = self.FavorList[HeroId].PrizeList
        for _,Level in ipairs(FavorLevelList) do
            PrizeList[Level] = CurTime
        end
    end
end

-- 缓存获得奖励内容，待动画播放完再调用弹窗
function FavorabilityModel:SaveRewardData(Msg)
    if not Msg.PrizeItemList or #Msg.PrizeItemList == 0 then
        self.SavedRewardData = nil
        return
    end
    self.SavedRewardData = {
        PrizeItemList = Msg.PrizeItemList,
        DecomposeItemList = Msg.DecomposeItemList
    }
end

-- 调用通用奖励弹窗展示奖励
function FavorabilityModel:ShowReward()
    if self.SavedRewardData then
        MvcEntry:GetCtrl(ItemGetCtrl):OnDropPrizeItemSyn(self.SavedRewardData)
        self.SavedRewardData = nil
    end
end

-- 是否从好感度界面关闭（用于控制LS）
function FavorabilityModel:SetIsCloseFromFavorMain(IsCloseFromFavorMain)
    self.IsCloseFromFavorMain = IsCloseFromFavorMain
end

-- 是否从好感度界面关闭（用于控制LS）
function FavorabilityModel:GetIsCloseFromFavorMain()
    -- 只获取一次生效
    local IsCloseFromFavorMain = self.IsCloseFromFavorMain
    self.IsCloseFromFavorMain = nil
    return IsCloseFromFavorMain
end

--[[
    剧情物品是否已解锁
]]
function FavorabilityModel:IsStoryItemUnlock(HeroId, StoryItemId)
    if not StoryItemId then
        return false
    end
    local StoryItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_StoryItemConfig, StoryItemId)
    if not StoryItemCfg then
        return false
    end
    local STORY_STATUS = FavorabilityConst.STORY_STATUS
    local UnlockType  = StoryItemCfg[Cfg_StoryItemConfig_P.UnlockType]
    local UnlockParam  = StoryItemCfg[Cfg_StoryItemConfig_P.UnlockParam]
    if UnlockType == FavorabilityConst.STORY_UNLOCK_TYPE.LEVEL then
        local CurLevel = self:GetCurFavorLevel(HeroId)
        if CurLevel >= UnlockParam then
            return true
        end
    elseif UnlockType == FavorabilityConst.STORY_UNLOCK_TYPE.PART then
        if self:GetPartStatus(HeroId,UnlockParam) == STORY_STATUS.COMPLETED then
            return true
        end
    elseif UnlockType == FavorabilityConst.STORY_UNLOCK_TYPE.TASK then
        if MvcEntry:GetModel(TaskModel):HasTaskFinished(UnlockParam) then
            return true
        end
    else
        return true
    end
    
end

--[[
    解析跳转参数
    1 英雄id; 2 页签id; 3 子页签id
]]
function FavorabilityModel:ParseFavorabilityJumpParams(JumpParam)
    local HeroId,TabId,SubTabId
    if not JumpParam or JumpParam:Length() == 0 then
        return HeroId,TabId,SubTabId
    end
    HeroId = tonumber(JumpParam[1])
    if JumpParam:Length() == 2 then
        TabId = tonumber(JumpParam[2])
    elseif JumpParam:Length() == 3 then
        TabId = tonumber(JumpParam[2])
        SubTabId = tonumber(JumpParam[3])
    end
    return HeroId,TabId,SubTabId
end