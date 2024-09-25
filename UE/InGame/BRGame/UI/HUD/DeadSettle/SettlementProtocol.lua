--
-- 结算协议
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.11.9
--

-------------------------------------------- Login ------------------------------------

--其他的协议放置在 Client/Modules/InGameSettlement/InGameSettlementCtrl.lua 中

s2c.OnCampSettlement    = function(CampSettlement)

    GameLog.Dump(CampSettlement, CampSettlement)
    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_CampSettlement, CampSettlement)
end