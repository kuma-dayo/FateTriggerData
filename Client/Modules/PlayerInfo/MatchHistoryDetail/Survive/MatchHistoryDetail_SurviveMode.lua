---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 大逃杀模式历史战绩
--- Created At: 2023/08/14 16:43
--- Created By: 朝文
---

local class_name = "MatchHistoryDetail_SurviveMode"
local super = require("Client.Modules.PlayerInfo.MatchHistoryDetail.MatchHistoryDetail_SubPageBase")
---@class MatchHistoryDetail_SurviveMode : MatchHistoryDetail_SubpageBase
local MatchHistoryDetail_SurviveMode = BaseClass(super, class_name)

---@return string lua路径
function MatchHistoryDetail_SurviveMode:GetPageItemLuaPath()
    return "Client.Modules.PlayerInfo.MatchHistoryDetail.Survive.MatchHistoryDetail_SurviveModeItem"
end

---@param FixedIndex number 从1开始的索引
---@return any 索引对应的数据
function MatchHistoryDetail_SurviveMode:GetPageItemDataByIndex(FixedIndex)
    return self.Data.DetailData.BrSettlement.PlayerArray[FixedIndex]
end

function MatchHistoryDetail_SurviveMode:SetData(Param)
    MatchHistoryDetail_SurviveMode.super.SetData(self, Param)
    
    if self.Data.DetailData.BrSettlement.IsPlayerArraySorted then return end
    
    --下发的数据是以playerId为key的，这样就不能很好的拿取，所以到这一步需要以队伍的位置为key来排序一下
    local newPlayerArray = {}
    for playerId, playerInfo in pairs(self.Data.DetailData.BrSettlement.PlayerArray) do
        newPlayerArray[playerInfo.PosInTeam] = playerInfo
        newPlayerArray[playerInfo.PosInTeam].PlayerId = playerId
    end
    self.Data.DetailData.BrSettlement.PlayerArray = newPlayerArray
    self.Data.DetailData.BrSettlement.IsPlayerArraySorted = true
end

function MatchHistoryDetail_SurviveMode:UpdateView(Param)
    self.View.WBPReuseList:Reload(#self.Data.DetailData.BrSettlement.PlayerArray)
end

return MatchHistoryDetail_SurviveMode
