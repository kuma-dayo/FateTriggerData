---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 征服模式历史战绩
--- Created At: 2023/08/14 16:43
--- Created By: 朝文
---

local class_name = "MatchHistoryDetail_Conqure"
local super = require("Client.Modules.PlayerInfo.MatchHistoryDetail.MatchHistoryDetail_SubPageBase")
---@class MatchHistoryDetail_Conqure : MatchHistoryDetail_SubpageBase
local MatchHistoryDetail_Conqure = BaseClass(super, class_name)

---@return string lua路径
function MatchHistoryDetail_Conqure:GetPageItemLuaPath()
    return "Client.Modules.PlayerInfo.MatchHistoryDetail.Conqure.MatchHistoryDetail_ConqureItem"
end

---@param FixedIndex number 从1开始的索引
---@return any 索引对应的数据
function MatchHistoryDetail_Conqure:GetPageItemDataByIndex(FixedIndex)
    return self.Data.DetailData.CampSettlement.PlayerArray[FixedIndex]
end

function MatchHistoryDetail_Conqure:SetData(Param)
    MatchHistoryDetail_Conqure.super.SetData(self, Param)
    
    if self.Data.DetailData.CampSettlement.IsPlayerArraySorted then return end
    
    local PlayerArray = self.Data.DetailData.CampSettlement.PlayerArray
    if not PlayerArray or not next(PlayerArray) then
        CError("[cw] Something is wrong here, PlayerArray is nil")
        print_r(Param, "[cw] MatchHistoryDetail_Conqure ====Param")
        return
    end

    --下发的数据是以playerId为key的，这样就不能很好的拿取，所以到这一步需要以队伍的位置为key来排序一下
    local newPlayerArray = {}
    for playerId, playerInfo in pairs(self.Data.DetailData.CampSettlement.PlayerArray) do
        newPlayerArray[playerInfo.PosInTeam] = playerInfo
        newPlayerArray[playerInfo.PosInTeam].PlayerId = playerId
    end
    self.Data.DetailData.CampSettlement.PlayerArray = newPlayerArray
    self.Data.DetailData.CampSettlement.IsPlayerArraySorted = true
end

function MatchHistoryDetail_Conqure:UpdateView(Param)
    self.View.WBPReuseList:Reload(#self.Data.DetailData.CampSettlement.PlayerArray)
end

return MatchHistoryDetail_Conqure
