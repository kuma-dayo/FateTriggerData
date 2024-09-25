---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 玩家个人空间数据
--- Created At: 2023/08/04 17:13
--- Created By: 朝文
---

local super = GameEventDispatcher
local class_name = "PlayerInfoModel"
---@class PlayerInfoModel : GameEventDispatcher
PlayerInfoModel = BaseClass(super, class_name)
PlayerInfoModel.Enum_MatchType = {
    Survive = ""
}
PlayerInfoModel.Const = {
    DefaultSelectTabId = 1,
}
PlayerInfoModel.Enum_SubPageCfg = {
    --个人信息
    PersonalInfoPage = {
        Id = 1,
        LuaPath = "Client.Modules.PlayerInfo.PersonalInfo.PlayerInfo_PersonInfo",
        BpPath = "/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/WBP_ImformationMainUI.WBP_ImformationMainUI",
        VitrualSceneId = 900,
    },

    -- 个人数据统计
    PersonalStatisticsPage = {
        Id = 2,
        LuaPath = "Client.Modules.PlayerInfo.PersonalStatistics.PlayerInfo_Statistics",
        BpPath = "/Game/BluePrints/UMG/OutsideGame/Information/PersonalData/WBP_Information_PersonalData_Panel.WBP_Information_PersonalData_Panel",
    },

    --历史战绩
    MatchHistoryPage = {
        Id = 3,
        LuaPath = "Client.Modules.PlayerInfo.MatchHistory.PlayerInfo_MatchHistory",
        BpPath = "/Game/BluePrints/UMG/OutsideGame/Information/MatchHistory/WBP_MatchHistoty_Detail.WBP_MatchHistoty_Detail",
    },

    AchievementPage = {
        Id = 4,
        LuaPath = "Client.Modules.Achievement.TabAchievement",
        BpPath = "/Game/BluePrints/UMG/OutsideGame/Achievement/WBP_Achievement_Main_New.WBP_Achievement_Main_New",
    }
}

PlayerInfoModel.Enum_Tab = {
    PersonalInfoPage = PlayerInfoModel.Enum_SubPageCfg.PersonalInfoPage.Id,
    PersonalStatisticsPage = PlayerInfoModel.Enum_SubPageCfg.PersonalStatisticsPage.Id,
    MatchHistoryPage = PlayerInfoModel.Enum_SubPageCfg.MatchHistoryPage.Id,
    AchievementPage = PlayerInfoModel.Enum_SubPageCfg.AchievementPage.Id
}

function PlayerInfoModel:__init()
    self:DataInit()
end

---初始化数据，用于第一次调用及登出的时候调用
function PlayerInfoModel:DataInit()
    --TODO: 
    self.CurSelectTab = 1
end

---玩家登出时调用
function PlayerInfoModel:OnLogout(data)
    self:DataInit()
end

function PlayerInfoModel:SetCurSelectTab(InTabIndex)
    self.CurSelectTab = InTabIndex
end

function PlayerInfoModel:GetCurSelectTab()
    return self.CurSelectTab
end

return PlayerInfoModel