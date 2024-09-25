---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 死斗模式历史战绩
--- Created At: 2023/08/14 16:43
--- Created By: 朝文
---

local class_name = "MatchHistoryDetail_DeathMatch"
local super = require("Client.Modules.PlayerInfo.MatchHistoryDetail.MatchHistoryDetail_SubPageBase")
---@class MatchHistoryDetail_DeathMatch : MatchHistoryDetail_SubpageBase
local MatchHistoryDetail_DeathMatch = BaseClass(super, class_name)

---@return string lua路径
function MatchHistoryDetail_DeathMatch:GetPageItemLuaPath()
    return "Client.Modules.PlayerInfo.MatchHistoryDetail.DeathMatch.MatchHistoryDetail_DeathMatchItem"
end

---@param FixedIndex number 从1开始的索引
---@return any 索引对应的数据
function MatchHistoryDetail_DeathMatch:GetPageItemDataByIndex(FixedIndex)
    return self.Data.DetailData.CampSettlement.PlayerArray[FixedIndex]
end

function MatchHistoryDetail_DeathMatch:SetData(Param)
    MatchHistoryDetail_DeathMatch.super.SetData(self, Param)
    
    if self.Data.DetailData.CampSettlement.IsPlayerArraySorted then return end
    
    local PlayerArray = self.Data.DetailData.CampSettlement.PlayerArray
    if not PlayerArray or not next(PlayerArray) then
        CError("[cw] Something is wrong here, PlayerArray is nil")
        print_r(Param, "[cw] MatchHistoryDetail_DeathMatch ====Param")
        return
    end 
    
    --这里不应该存在一个以上的数据，以防万一处理一遍     
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = UserModel:GetPlayerId()
    local newPlayerArray = {}
    for playerId, playerInfo in pairs(self.Data.DetailData.CampSettlement.PlayerArray) do
        if PlayerId == playerId then
            table.insert(newPlayerArray, playerInfo)
            newPlayerArray[#newPlayerArray].PlayerId = playerId
            newPlayerArray[#newPlayerArray].PlayerRank = self.Data.DetailData.CampSettlement.TeamRank
            break
        end
    end
    self.Data.DetailData.CampSettlement.PlayerArray = newPlayerArray
    
    
    --这里说明整理好了
    self.Data.DetailData.CampSettlement.IsPlayerArraySorted = true
    
    print_r(self.Data.DetailData.CampSettlement, "[cw] ====self.Data.DetailData.CampSettlement")
end

function MatchHistoryDetail_DeathMatch:UpdateView(Param)
    --死斗模式只显示自己的数据，所以只有一条
    self.View.WBPReuseList:Reload(1)
end

return MatchHistoryDetail_DeathMatch
