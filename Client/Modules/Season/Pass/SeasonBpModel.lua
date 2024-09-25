--[[赛季通行证]]
local super = GameEventDispatcher;
local class_name = "SeasonBpModel";
---@class SeasonBpModel : GameEventDispatcher
SeasonBpModel = BaseClass(super, class_name);

--赛季通行证基础信息初始化
SeasonBpModel.ON_SEASON_BP_INFO_INIT = "ON_SEASON_BP_INFO_INIT"
SeasonBpModel.ON_SEASON_BP_PASS_BUY_SUC = "ON_SEASON_BP_PASS_BUY_SUC"
SeasonBpModel.ON_SEASON_BP_LEVEL_UPDATE = "ON_SEASON_BP_LEVEL_UPDATE"
SeasonBpModel.ON_SEASON_BP_AWARD_LEVEL_UPDATE = "ON_SEASON_BP_AWARD_LEVEL_UPDATE"
SeasonBpModel.ON_SEASON_BP_EXP_UPDATE = "ON_SEASON_BP_EXP_UPDATE"
SeasonBpModel.ON_SEASON_BP_DAILY_TASK_UPDATE = "ON_SEASON_BP_DAILY_TASK_UPDATE"
SeasonBpModel.ON_SEASON_BP_WEEK_TASK_UPDATE = "ON_SEASON_BP_WEEK_TASK_UPDATE"

--[[通行证界面，当前正常道具选中展示，参数为ItemId]]
SeasonBpModel.ON_SEASON_BP_MAIN_SELECT_ITEM_SHOW = "ON_SEASON_BP_MAIN_SELECT_ITEM_SHOW"
--通行证界面，当前特殊道具选中展示
SeasonBpModel.ON_SEASON_BP_MAIN_SELECT_SPECIAL_ITEM_SHOW = "ON_SEASON_BP_MAIN_SELECT_SPECIAL_ITEM_SHOW"

function SeasonBpModel:OnGameInit()
    self:DataInit()
end
function SeasonBpModel:OnLogout()
    self:DataInit()
end
function SeasonBpModel:DataInit()
    --[[
        message PassStatusRsp
        {
            int32 SeasonBpId = 1;       // 当前通行证Id
            PASS_TYPE PassType = 2;     // 当前解锁的通行证类型
            int32 BasicAwardedLevel = 3;                // 基础通行证已领取奖励等级
            int32 PremiumAwardedLevel = 4;              // 高级
            int32 DeluxeAwardeLevel = 5;                // 豪华
            int32 Level = 6;            // 通行证等级
            int32 Exp = 7;              // 当前等级的经验数
            int32 Week = 8;             // 赛季开始后的第几周
            int64 StartTime = 9;        // 开始时间
            int64 EndTime = 10;          // 结束时间
            int32 TotWeek = 11;          // 当前赛季总共有多少周
        }
    ]]
    self.PassStatus = nil

    self.DailyTaskList = nil
    self.DailyEndTime = nil
    self.Week2TaskInfo = nil

    self.BpId2SpecailRewardItemList = nil

    self.BpRewardLv2DropItemList = {}

    self.RegistTryFaceAction = {}
end

function SeasonBpModel:CheckPreCacheInfo()
    local TheDepotModel = MvcEntry:GetModel(DepotModel)
    if not self.BpId2SpecailRewardItemList then
        self.BpId2SpecailRewardItemList = {}

        local Dict = G_ConfigHelper:GetDict(Cfg_SeasonBpListCfg)
        for _,BpCfg in pairs(Dict) do
            self.BpId2SpecailRewardItemList[BpCfg[Cfg_SeasonBpListCfg_P.Id]] = {}

            if BpCfg[Cfg_SeasonBpListCfg_P.BonusDropId] and string.len(BpCfg[Cfg_SeasonBpListCfg_P.BonusDropId]) > 0 then
                local ItemList = TheDepotModel:GetItemListForDropId(BpCfg[Cfg_SeasonBpListCfg_P.BonusDropId])

                ListMerge(self.BpId2SpecailRewardItemList[BpCfg[Cfg_SeasonBpListCfg_P.Id]],ItemList)
            end
        end
        local DictReward = G_ConfigHelper:GetDict(Cfg_SeasonBpRewardCfg)
        for _,RewardCfg in ipairs(DictReward) do
            if RewardCfg[Cfg_SeasonBpRewardCfg_P.SpecialItemId] and string.len(RewardCfg[Cfg_SeasonBpRewardCfg_P.SpecialItemId]) > 0 then
                local ItemList = self:GetDropItemListByBpReward(RewardCfg)--TheDepotModel:GetItemListForDropId(RewardCfg[Cfg_SeasonBpRewardCfg_P.DropId])

                for k,v in pairs(self.BpId2SpecailRewardItemList) do
                    ListMerge(v,ItemList)
                end
            end
        end
    end
end


--[[
    返回当前赛季通行证ID
]]
function SeasonBpModel:GetSeasonBpId()
    return self.PassStatus and self.PassStatus.SeasonBpId or 0
end
--[[
    获取还剩余的时间展示
]]
function SeasonBpModel:FormatEndTimeShow(TimeStr)
    local ShowStr = StringUtil.Format("<span color=\"#F5EFDF99\" size=\"24\">{0}</><span color=\"#F5EFDFE6\" size=\"24\">{1}</>", G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","SeasonEndTime"), TimeStr)
    return ShowStr
end
function SeasonBpModel:GetEndTime()
    local SeasonEndTime = self.PassStatus and self.PassStatus.EndTime or 0
    -- CWaring(SeasonEndTime)
    return SeasonEndTime
end

function SeasonBpModel:GetAwardedLevel()
    return self.PassStatus and self.PassStatus.BasicAwardedLevel or 0
end
function SeasonBpModel:GetAdvanceAwardedLevel()
    return self.PassStatus and self.PassStatus.AdvanceAwardeLevel or 0
end

--[[
    获取通行证最大等级
]]
function SeasonBpModel:GetBpLevelMax()
    local NeedShowRewardList = G_ConfigHelper:GetMultiItemsByKey(Cfg_SeasonBpRewardCfg,Cfg_SeasonBpRewardCfg_P.SeasonBpId,self:GetSeasonBpId())
    return #NeedShowRewardList
end

function SeasonBpModel:GetPassStatus()
    return self.PassStatus
end
function SeasonBpModel:SetPassStatus(Status)
    self.PassStatus = Status
    self.PassStatus.AdvanceAwardeLevel = 0
    if self.PassStatus.PassType ~= Pb_Enum_PASS_TYPE.BASIC then
        self.PassStatus.AdvanceAwardeLevel = self.PassStatus.PassType == Pb_Enum_PASS_TYPE.PREMIUM and self.PassStatus.PremiumAwardedLevel or self.PassStatus.DeluxeAwardeLevel
    end

    self:DispatchType(SeasonBpModel.ON_SEASON_BP_INFO_INIT)
end

function SeasonBpModel:GetDailyTaskList()
    return self.DailyTaskList or nil
end
function SeasonBpModel:SetDailyTaskList(List)
    self.DailyTaskList = List
end
function SeasonBpModel:GetWeekTaskInfo(Week)
    return self.Week2TaskInfo and self.Week2TaskInfo[Week] or nil
end
function SeasonBpModel:SetWeekTaskInfo(Week,TaskInfo)
    self.Week2TaskInfo = self.Week2TaskInfo or {}
    self.Week2TaskInfo[Week] = TaskInfo
end
function SeasonBpModel:IsWeekTaskInfoInit()
    return (self.Week2TaskInfo ~= nil)
end

function SeasonBpModel:GetSpecialRewardItemListByBpId(BpId)
    self:CheckPreCacheInfo()
    return self.BpId2SpecailRewardItemList[BpId] or {}
end

function SeasonBpModel:GetDropItemListByBpReward(BpReward)
    local Level = BpReward[Cfg_SeasonBpRewardCfg_P.Level]
    if not self.BpRewardLv2DropItemList[Level] then
        self.BpRewardLv2DropItemList[Level] = {}
        local RewardItemIds = BpReward[Cfg_SeasonBpRewardCfg_P.RewardItemIds]
        local RewardItemNums = BpReward[Cfg_SeasonBpRewardCfg_P.RewardItemNums]
        if RewardItemIds and RewardItemIds:Num() > 0 then
            for i=1,RewardItemIds:Num() do
                local Id = RewardItemIds:Get(i)

                local Item = {
                    ItemId = Id,
                    ItemNum = RewardItemNums:Num() >= i and RewardItemNums:Get(i) or 1,
                }
                self.BpRewardLv2DropItemList[Level][#self.BpRewardLv2DropItemList[Level] + 1] = Item
            end  
        end
    end
    return self.BpRewardLv2DropItemList[Level] or {}
end

-- 是否已经塞入升级弹脸界面
function SeasonBpModel:IsTryToPopUpgrade(PassType)
    CLog("== SeasonBpModel:IsTryToPopUpgrade Type = "..PassType.." IsTry = "..tostring(self.RegistTryFaceAction[PassType] or "false"))
    return self.RegistTryFaceAction[PassType]
end

-- 设置是否已经塞入升级弹脸界面
function SeasonBpModel:SetIsTryToPopUpgrade(PassType,IsTry)
    CLog("== SeasonBpModel:SetIsTryToPopUpgrade Type = "..PassType.." IsTry = "..tostring(IsTry))
    self.RegistTryFaceAction[PassType] = IsTry
end

return SeasonBpModel;