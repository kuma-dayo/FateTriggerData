require("Client.Modules.Hero.HeroModel")

--[[
    英雄相关协议处理模块
]]
local class_name = "HeroCtrl"
---@class HeroCtrl : UserGameController
---@field private model HeroModel
HeroCtrl = HeroCtrl or BaseClass(UserGameController,class_name)

local DEBUG_HERO = false
local DEBUG_HERO_DATA = false

function HeroCtrl:__init()
    CWaring("==HeroCtrl init")
    self.Model = nil
end

function HeroCtrl:Initialize()
    ---@type HeroModel
    self.Model = self:GetModel(HeroModel)
end

function HeroCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.SelectHeroRsp,	Func = self.SelectHeroRsp_Func },
        {MsgName = Pb_Message.SelectHeroSkinRsp,	Func = self.SelectHeroSkinRsp_Func },
        {MsgName = Pb_Message.BuyHeroSkinRsp,	Func = self.BuyHeroSkinRsp_Func },
        {MsgName = Pb_Message.BuyHeroRsp,	Func = self.BuyHeroRsp_Func },
        {MsgName = Pb_Message.PlayerDisplayBoardDataRsp,	Func = self.PlayerDisplayBoardDataRsp_Func },

        {MsgName = Pb_Message.PlayerBuyFloorRsp,	Func = self.PlayerBuyFloorRsp_Func },
        {MsgName = Pb_Message.PlayerSelectFloorRsp,	Func = self.PlayerSelectFloorRsp_Func },
        {MsgName = Pb_Message.PlayerBuyRoleRsp,	Func = self.PlayerBuyRoleRsp_Func },
        {MsgName = Pb_Message.PlayerSelectRoleRsp,	Func = self.PlayerSelectRoleRsp_Func },
        {MsgName = Pb_Message.PlayerBuyEffectRsp,	Func = self.PlayerBuyEffectRsp_Func },
        {MsgName = Pb_Message.PlayerSelectEffectRsp,	Func = self.PlayerSelectEffectRsp_Func },
        {MsgName = Pb_Message.PlayerBuyStickerRsp,	Func = self.PlayerBuyStickerRsp_Func },
        {MsgName = Pb_Message.PlayerEquipStickerRsp,	Func = self.PlayerEquipStickerRsp_Func },
        {MsgName = Pb_Message.PlayerUnEquipStickerRsp,	Func = self.PlayerUnEquipStickerRsp_Func },
        {MsgName = Pb_Message.PlayerEquipAchieveRsp,	Func = self.PlayerEquipAchieveRsp_Func },
        {MsgName = Pb_Message.PlayerUnEquipAchieveRsp,	Func = self.PlayerUnEquipAchieveRsp_Func },
        {MsgName = Pb_Message.BuyHeroSkinPartRsp,	Func = self.BuySuitPartRsp },
        {MsgName = Pb_Message.SelectHeroSkinCustomPartRsp,	Func = self.EquipSuitPartRsp },
        {MsgName = Pb_Message.SelectHeroSkinDefaultPartRsp,	Func = self.SelectHeroSkinDefaultPartRsp },
        {MsgName = Pb_Message.HeroBattleDataRsp,	Func = self.HeroSeasonHeroRecordDataRes },
        {MsgName = Pb_Message.HeroPerfRecordsRsp,	Func = self.HeroSeasonHeroHistoryDataRes },
	}
end

function HeroCtrl:OnLogin(data)
    self:SendProto_PlayerDisplayBoardDataReq()
end

function HeroCtrl:SelectHeroRsp_Func(Msg)
    self.Model:SetFavoriteId(Msg.HeroId)
end

function HeroCtrl:SelectHeroSkinRsp_Func(Msg)
    self.Model:SetFavoriteSkinIdByHeroId(Msg.HeroId,Msg.HeroSkinId)
end

---购买英雄成功后协议回包
function HeroCtrl:BuyHeroRsp_Func(Msg)
    self.Model:OnBuyHeroRsp(Msg.HeroId)
end

-----------------------------------------请求相关------------------------------
--[[
    选择自己的偏好英雄
]]
function HeroCtrl:SendProto_SelectHeroReq(HeroID)
    if not HeroID or HeroID == 0 then
        CWaring("HeroCtrl:SendProto_SelectHeroReq HeroID not vaild")
        return
    end

    local ConfigData = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.Id, HeroID)
    if not ConfigData then
        return
    end
    --1.当前喜欢的英雄ID和数据记录的一致，则不处理
    ---@type HeroModel
    local HeroModel = MvcEntry:GetModel(HeroModel)    
    if HeroID == HeroModel:GetFavoriteId() then CWaring("[cw] same like hero, return") return end

    --2.如果还没有获得，则不能喜欢
    local bGog = HeroModel:CheckGotHeroById(HeroID)
    if not bGog then
        --TODO: 这里后续应该会改文字或者表现，目前第一版先弹alert by bailixi
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_Youcantmarkheroesyou"))         
        return 
    end

    local Msg = {
        HeroId = HeroID,
    }
    self:SendProto(Pb_Message.SelectHeroReq,Msg, Pb_Message.SelectHeroRsp)
end

---发送协议解锁英雄
---@param ToBuyHeroId number 需要购买的英雄ID
function HeroCtrl:SendProto_BuyHeroReq(ToBuyHeroId)
    CLog("[cw] HeroCtrl:SendProto_BuyHeroReq(" .. string.format("%s", ToBuyHeroId) .. ")")
    local Msg = {
        HeroId = ToBuyHeroId,
    }
    self:SendProto(Pb_Message.BuyHeroReq, Msg)
end

--[[
    购买英雄皮肤
]]
function HeroCtrl:SendProto_BuyHeroSkinReq(HeroId,HeroSkinId)
    local Msg = {
        HeroId = HeroId,
        HeroSkinId = HeroSkinId,
    }
    self:SendProto(Pb_Message.BuyHeroSkinReq,Msg,Pb_Message.BuyHeroSkinRsp)
end

--[[
    为英雄装备自己想要的皮肤
]]
function HeroCtrl:SendProto_SelectHeroSkinReq(HeroId,HeroSkinId)
    local Msg = {
        HeroId = HeroId,
        HeroSkinId = HeroSkinId,
    }

    self:SendProto(Pb_Message.SelectHeroSkinReq,Msg,Pb_Message.SelectHeroSkinRsp)
end

function HeroCtrl:BuyHeroSkinRsp_Func(Msg)
    
end

--[[
    角色展示板
]]
--获取展示版的数据
function HeroCtrl:SendProto_PlayerDisplayBoardDataReq()
    local Msg = {
    }
    self:SendProto(Pb_Message.PlayerDisplayBoardDataReq,Msg)
end

function HeroCtrl:PlayerDisplayBoardDataRsp_Func(Msg)
    if Msg == nil then
        return 
    end

    -- local TableAux = require("Common.Utils.TableAux")
    -- CError(string.format("获取展示版的数据 Msg = %s",TableAux.TableToString(Msg)))

    self.Model:SetDisplayBoardInfo(Msg.DisplayBoardMap)
end

--解锁底板
function HeroCtrl:SendProto_PlayerBuyFloorReq(FloorId)
    local Msg = {
        FloorId = FloorId,
    }
    self:SendProto(Pb_Message.PlayerBuyFloorReq,Msg,Pb_Message.PlayerBuyFloorRsp)
end

function HeroCtrl:PlayerBuyFloorRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:OnBuyDisplayBoardFloorRsp(Msg.FloorId)
end

--选择使用底板
function HeroCtrl:SendProto_PlayerSelectFloorReq(HeroId, FloorId)
    local Msg = {
        HeroId = HeroId,
        FloorId = FloorId
    }
    self:SendProto(Pb_Message.PlayerSelectFloorReq,Msg,Pb_Message.PlayerSelectFloorRsp)
end

function HeroCtrl:PlayerSelectFloorRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:UpdateDisplayBoardFloorInfo(Msg.HeroId, Msg.FloorId)
end

--解锁角色
function HeroCtrl:SendProto_PlayerBuyRoleReq(RoleId)
    local Msg = {
        RoleId = RoleId
    }
    self:SendProto(Pb_Message.PlayerBuyRoleReq,Msg,Pb_Message.PlayerBuyRoleRsp)
end

function HeroCtrl:PlayerBuyRoleRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:OnBuyDisplayBoardRoleRsp(Msg.RoleId)
end

--选择使用角色
function HeroCtrl:SendProto_PlayerSelectRoleReq(HeroId, RoleId)
    local Msg = {
        HeroId = HeroId,
        RoleId = RoleId
    }
    self:SendProto(Pb_Message.PlayerSelectRoleReq,Msg,Pb_Message.PlayerSelectRoleRsp)
end

function HeroCtrl:PlayerSelectRoleRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:UpdateDisplayBoardRoleInfo(Msg.HeroId, Msg.RoleId)
end

--解锁特效
function HeroCtrl:SendProto_PlayerBuyEffectReq(EffectId)
    local Msg = {
        EffectId = EffectId
    }
    self:SendProto(Pb_Message.PlayerBuyEffectReq,Msg,Pb_Message.PlayerBuyEffectRsp)
end

function HeroCtrl:PlayerBuyEffectRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:OnBuyDisplayBoardEffectRsp(Msg.EffectId)
end

--选择使用特效
function HeroCtrl:SendProto_PlayerSelectEffectReq(HeroId, EffectId)
    local Msg = {
        HeroId = HeroId,
        EffectId = EffectId
    }
    self:SendProto(Pb_Message.PlayerSelectEffectReq,Msg,Pb_Message.PlayerSelectEffectRsp)
end

function HeroCtrl:PlayerSelectEffectRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:UpdateDisplayBoardEffectInfo(Msg.HeroId, Msg.EffectId)
end

-- 解锁贴纸
function HeroCtrl:SendProto_PlayerBuyStickerReq(StickerId)
    local Msg = {
        StickerId = StickerId
    }
    self:SendProto(Pb_Message.PlayerBuyStickerReq,Msg,Pb_Message.PlayerBuyStickerRsp)
end

function HeroCtrl:PlayerBuyStickerRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:OnBuyDisplayBoardStickerRsp(Msg.StickerId)
end

--装备贴纸
function HeroCtrl:SendProto_PlayerEquipStickerReq(HeroId, Slot, StickerParam)
    if StickerParam == nil then
        CError("HeroCtrl:SendProto_PlayerEquipStickerReq, StickerParam == nil", true)
        return
    end
    local Msg = {
        HeroId = HeroId,
        Slot = Slot, 
        StickerInfo = StickerParam
    }
    self:SendProto(Pb_Message.PlayerEquipStickerReq,Msg,Pb_Message.PlayerEquipStickerRsp)
end

function HeroCtrl:PlayerEquipStickerRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:UpdateDisplayBoardStickerInfo(Msg.HeroId, Msg.Slot, Msg.StickerInfo, true)

    self.Model:DispatchType(HeroModel.ON_PLAYER_EQUIP_STICKER_RSP)
end

--卸载贴纸
function HeroCtrl:SendProto_PlayerUnEquipStickerReq(HeroId, Slot)
    local Msg = {
        HeroId = HeroId,
        Slot = Slot
    }
    self:SendProto(Pb_Message.PlayerUnEquipStickerReq,Msg,Pb_Message.PlayerUnEquipStickerRsp)
end

function HeroCtrl:PlayerUnEquipStickerRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:UpdateDisplayBoardStickerInfo(Msg.HeroId, Msg.Slot, nil, false)

    self.Model:DispatchType(HeroModel.ON_PLAYER_UNEQUIP_STICKER_RSP)
end

--装备成就
function HeroCtrl:SendProto_PlayerEquipAchieveReq(HeroId, Slot, AchieveId)
    local Msg = {
        HeroId = HeroId,
        Slot = Slot,
        AchieveGroupId = AchieveId
    }
    self:SendProto(Pb_Message.PlayerEquipAchieveReq, Msg, Pb_Message.PlayerEquipAchieveRsp)
end

function HeroCtrl:PlayerEquipAchieveRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:UpdateDisplayBoardAchieveInfo(Msg.HeroId, Msg.Slot, Msg.AchieveGroupId)
end

--卸载成就
function HeroCtrl:SendProto_PlayerUnEquipAchieveReq(HeroId, Slot)
    local Msg = {
        HeroId = HeroId,
        Slot = Slot
    }
    self:SendProto(Pb_Message.PlayerUnEquipAchieveReq, Msg, Pb_Message.PlayerUnEquipAchieveRsp)
end

function HeroCtrl:PlayerUnEquipAchieveRsp_Func(Msg)
    if Msg == nil then 
        return
    end
    self.Model:UpdateDisplayBoardAchieveInfo(Msg.HeroId, Msg.Slot)
end


function HeroCtrl:EquipSuitPartReq(HeroId, HeroSkinPartIdList)
    local Msg = {
        HeroId = HeroId,
        HeroSkinPartIdList = HeroSkinPartIdList,
    }

    if DEBUG_HERO then
        self:EquipSuitPartRsp(Msg)
    else
        self:SendProto(Pb_Message.SelectHeroSkinCustomPartReq,Msg,Pb_Message.SelectHeroSkinCustomPartRsp)
    end
end

function HeroCtrl:EquipSuitPartRsp(Msg)
    self.Model:EquipSuitPart(Msg.HeroSkinPartIdList)
end

function HeroCtrl:BuySuitPartReq(PartId)
    local Msg = {
        HeroSkinPartId = PartId,
    }
    if DEBUG_HERO then
        self:BuySuitPartRsp(Msg)
    else
        self:SendProto(Pb_Message.BuyHeroSkinPartReq,Msg,Pb_Message.BuyHeroSkinPartRsp)
    end
end

function HeroCtrl:BuySuitPartRsp(Msg)
end

function HeroCtrl:SelectHeroSkinDefaultPartReq(HeroSkinId, SuitId)
    local Msg = {
        HeroSkinId = HeroSkinId,
        SuitId = SuitId,
    }
    if DEBUG_HERO then
        self:SelectHeroSkinDefaultPartRsp(Msg)
    else
        self:SendProto(Pb_Message.SelectHeroSkinDefaultPartReq,Msg,Pb_Message.SelectHeroSkinDefaultPartRsp)
    end
end

function HeroCtrl:SelectHeroSkinDefaultPartRsp(Msg)
    local List
    if Msg.HeroSkinId == 0 then
        List = self.Model:GetSkinSuitEquipPartIdList(Msg.SuitId)
    end
    self.Model:UpdateSkinSuitPartData(Msg.HeroSkinId, Msg.SuitId, List)
    self.Model:DispatchType(HeroModel.HERO_SKIN_DEFAULT_PART_CHANGE)

end


function HeroCtrl:ReqHeroSeasonHeroRecordData(Season, HeroId)
    local Msg = {
        SeasonId = Season,
        HeroId = HeroId,
    }
    if DEBUG_HERO_DATA then
        Msg.RecordData = {
            ["1"] = 123
        }
        self:HeroSeasonHeroRecordDataRes(Msg)
    else
        if self.Model:GetHeroDataRecord(Season, HeroId, "SeasonId") == Season
        and self.Model:GetHeroDataRecord(Season, HeroId, "HeroId") == HeroId then
            self.Model:DispatchType(HeroModel.HERO_RECORD_DATA_CHANGE)
        else
            self:SendProto(Pb_Message.HeroBattleDataReq,Msg,Pb_Message.HeroBattleDataRsp)
        end
    end
end

function HeroCtrl:HeroSeasonHeroRecordDataRes(Msg)
    print_r(Msg)
    for k, v in pairs(Msg) do
        self.Model:SetHeroDataRecord(Msg.SeasonId, Msg.HeroId, k, v)
    end
    self.Model:DispatchType(HeroModel.HERO_RECORD_DATA_CHANGE)
end

function HeroCtrl:ReqHeroSeasonHeroHistoryData(Season, HeroId, StartIdx)
    StartIdx = StartIdx or 0
    local Msg = {
        SeasonId = Season,
        HeroId = HeroId,
        StartIdx = StartIdx
    }
    print("StartIdx ====", StartIdx)
    if DEBUG_HERO_DATA then
        Msg.HeroPerfRecords = MvcEntry:GetModel(HeroModel):GetHeroDataHistoryRecord(Season,HeroId) or {}
        for i = 1, 10, 1 do
            local Id = #table.keys(Msg.HeroPerfRecords)
            local Score = math.random(0, 260)
            local PowerScoreInc = math.random(-50, 60)
            local Rank = math.random(0, 60)
            table.insert(Msg.HeroPerfRecords, {
                Id = Id,
                PowerScore = Score,
                PowerScoreInc = PowerScoreInc,
                Rank = Rank
            })
        end
        self:HeroSeasonHeroHistoryDataRes(Msg)
    else
        local HeroPerfRecords = MvcEntry:GetModel(HeroModel):GetHeroDataHistoryRecord(Season,HeroId)
        if HeroPerfRecords and #HeroPerfRecords > StartIdx then
            self.Model:DispatchType(HeroModel.HERO_RECORD_HISTORY_DATA_CHANGE)
        else
            self:SendProto(Pb_Message.HeroPerfRecordsReq,Msg,Pb_Message.HeroPerfRecordsRsp) 
        end
    end
end

function HeroCtrl:HeroSeasonHeroHistoryDataRes(Msg)
    print_r(Msg)
    -- if #Msg.HeroPerfRecords == 0 then
    --     return
    -- end
    self.Model:AddHeroDataHistoryRecord(Msg.SeasonId, Msg.HeroId, Msg.HeroPerfRecords, Msg.StartIdx)
end


---@class CornerTagParam
---@field TagPos number
---@field TagId CornerTagCfg
---@field TagWordId number
---@field TagHeroId number
---@field TagHeroSkinId number
---@field IsLock boolean
---@field IsGot boolean
---@field IsOutOfDate boolean
---@return table {TagParam:CornerTagParam,ItemState:HeroDefine.EDisplayBoardItemState}
function HeroCtrl:GetCornerTagParam(DisplayBoardTabID, HeroId, DisplayBoardId)
    local TagParam = {
        TagPos = CommonConst.CORNER_TAGPOS.Right,
        TagId = 0,
        TagWordId = 0,
        TagHeroId = 0,
        TagHeroSkinId = 0,
        IsLock = false,
        IsGot = false,
        IsOutOfDate = false,
    }
    local RetVal = {
        TagParam = TagParam,
        ItemState = HeroDefine.EDisplayBoardItemState.Owned
    }

    --已经拥有
    local bHas = false
    if DisplayBoardTabID == EHeroDisplayBoardTabID.Floor.TabId then
        bHas = self.Model:HasDisplayBoardFloor(DisplayBoardId)
    elseif DisplayBoardTabID == EHeroDisplayBoardTabID.Role.TabId then
        bHas = self.Model:HasDisplayBoardRole(DisplayBoardId)
    elseif DisplayBoardTabID == EHeroDisplayBoardTabID.Effect.TabId then
        bHas = self.Model:HasDisplayBoardEffect(DisplayBoardId)
    elseif DisplayBoardTabID == EHeroDisplayBoardTabID.Sticker.TabId then
        bHas = self.Model:HasDisplayBoardSticker(DisplayBoardId)
    end
    if not(bHas) then
        -- 没有拥有
        RetVal.ItemState = HeroDefine.EDisplayBoardItemState.Lock
        TagParam.TagId = CornerTagCfg.Lock.TagId
        return RetVal
    end

    --已经装备
    local IsSelected = false
    if DisplayBoardTabID == EHeroDisplayBoardTabID.Floor.TabId then
        IsSelected = self.Model:HasDisplayBoardFloorIdSelected(HeroId, DisplayBoardId)
    elseif DisplayBoardTabID == EHeroDisplayBoardTabID.Role.TabId then
        IsSelected = self.Model:HasDisplayBoardRoleIdSelected(HeroId, DisplayBoardId)
    elseif DisplayBoardTabID == EHeroDisplayBoardTabID.Effect.TabId then
        IsSelected = self.Model:HasDisplayBoardEffectIdSelected(HeroId, DisplayBoardId)
    elseif DisplayBoardTabID == EHeroDisplayBoardTabID.Sticker.TabId then
        IsSelected = self.Model:HasDisplayBoardStickerIdSelected(HeroId, DisplayBoardId)
    end
    if IsSelected then
        RetVal.ItemState = HeroDefine.EDisplayBoardItemState.EquippedByCur
        TagParam.TagId = CornerTagCfg.Equipped.TagId
        return RetVal
    end

    --被哪个英雄使用
    local UsedByHeroIds = nil
    if DisplayBoardTabID == EHeroDisplayBoardTabID.Floor.TabId then
        UsedByHeroIds = self.Model:GetFloorUsedByHeroId(DisplayBoardId, HeroId)
    elseif DisplayBoardTabID == EHeroDisplayBoardTabID.Role.TabId then
        UsedByHeroIds = {}
    elseif DisplayBoardTabID == EHeroDisplayBoardTabID.Effect.TabId then
        UsedByHeroIds = self.Model:GetEffectUsedByHeroId(DisplayBoardId, HeroId)
    elseif DisplayBoardTabID == EHeroDisplayBoardTabID.Sticker.TabId then
        UsedByHeroIds = self.Model:GetStickerUsedByHeroId(DisplayBoardId, HeroId)
    end
    if UsedByHeroIds and next(UsedByHeroIds) then
        TagParam.TagId = CornerTagCfg.HeroBg.TagId
        TagParam.TagHeroId = UsedByHeroIds[1]
        TagParam.TagHeroSkinId = self.Model:GetDefaultSkinIdByHeroId(TagParam.TagHeroId)
        RetVal.ItemState = HeroDefine.EDisplayBoardItemState.EquippedByOther
        return RetVal
    end

    return RetVal
end




