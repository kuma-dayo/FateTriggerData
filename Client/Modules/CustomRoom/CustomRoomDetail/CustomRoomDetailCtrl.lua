---
--- Ctrl 模块，主要用于处理协议
--- Description: 自建房 房间详情
--- Created At: 2023/07/04 14:31
--- Created By: 朝文
---

local class_name = "CustomRoomDetailCtrl"
---@class CustomRoomDetailCtrl : UserGameController
CustomRoomDetailCtrl = CustomRoomDetailCtrl or BaseClass(UserGameController, class_name)

--仅适用于 OnRoomPlayerSync
local _Enum_OpType = {
    None = 0,
    Add = 1,
    Remove = 2,
    Update = 3,
}

function CustomRoomDetailCtrl:__init() end
function CustomRoomDetailCtrl:Initialize() end

function CustomRoomDetailCtrl:AddMsgListenersUser()
    -- self.ProtoList = {
    --     { MsgName = Pb_Message.HeroListRsp,	            Func = self.OnHeroListRsp },
    --     { MsgName = Pb_Message.UpdateRoomMasterSync,	Func = self.OnRoomMasterInfoSync },
    --     { MsgName = Pb_Message.RoomPlayerInfoRsp,	    Func = self.OnRoomPlayerInfoRsp },
    --     { MsgName = Pb_Message.TeamListRsp,	            Func = self.OnTeamListRsp },
    --     { MsgName = Pb_Message.SelectTeamRsp,	        Func = self.OnSelectTeamRsp },
    --     { MsgName = Pb_Message.RoomSelectHeroRsp,	    Func = self.OnSelectHeroRsp },
    --     { MsgName = Pb_Message.UpdateRoomPlayerSync,	Func = self.OnRoomPlayerSync },
    -- }
end

-----------------------------------------请求相关------------------------------

------------------
--- 可选英雄列表 ---
------------------
--region
---【发包】获取可选英雄列表
---@param RoomId number 房间id
function CustomRoomDetailCtrl:SendHeroListReq(RoomId)
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    RoomId = RoomId or CustomRoomDetailModel:GetRoomInfo_RoomId()
    local Data = {
        RoomId = RoomId,
    }
    self:SendProto(Pb_Message.HeroListReq, Data)
end

--[[
Msg = {
    --服务器读表下发，HeroConfig中的所有英雄 
    HeroList = { 
        [1] = 200010000, 
        [2] = 200020000, 
        [3] = 200030000, 
        [4] = 200060000, 
    } 
}
--]]
---【回包】获取可选英雄列表
---@param Msg table 
function CustomRoomDetailCtrl:OnHeroListRsp(Msg)
    CLog("[cw][CustomRoomDetailCtrl] OnHeroListRsp(" .. string.format("%s", Msg) .. ")")
    
    local HeroList = Msg.HeroList
    print_r(HeroList, "[cw] ====HeroList")
    
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    CustomRoomDetailModel:SetCustomRoomHeroList(HeroList)
    CustomRoomDetailModel:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_ROOM_HERO_LIST_RSP)
end
--endregion

-------------------
----- 房主信息 -----
-------------------
--region
--[[
    MasterInfoBase = {
        RoomMasterName = bailixi,
        PlayerId = 10569646082
    }
--]]
---【同步】后台同步的房主信息
---@param MasterInfoBase table 房主信息
function CustomRoomDetailCtrl:OnRoomMasterInfoSync(MasterInfoBase)
    CLog("[cw][CustomRoomDetailCtrl] OnRoomMasterInfoSync(" .. string.format("%s", MasterInfoBase) .. ")")
    local Name = MasterInfoBase.RoomMasterName
    local PlayerId = MasterInfoBase.PlayerId
    CLog("[cw] Name: " .. tostring(Name))
    CLog("[cw] PlayerId: " .. tostring(PlayerId))
    
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    CustomRoomDetailModel:UpdateMasterInfo({ Name = Name, PlayerId = PlayerId})
    CustomRoomDetailModel:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_ROOM_MASTER_INFO_SYNC)
end
--endregion

-------------------
----- 玩家信息 -----
-------------------
--region
---【发包】请求房间内的玩家信息
---@param RoomId number 房间id
function CustomRoomDetailCtrl:SendRoomPlayerInfoReq(RoomId)
    CLog("[cw][CustomRoomDetailCtrl] SendRoomPlayerInfoReq(" .. string.format("%s", tostring(RoomId)) .. ")")    
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    RoomId = RoomId or CustomRoomDetailModel:GetRoomInfo_RoomId()
    local Data = {
        InRoomId = RoomId or 0,
    }
    self:SendProto(Pb_Message.RoomPlayerInfoReq, Data)
end

--[[
    --这条消息更新的房间信息
    InRoomId = 2,
    --房主信息
    InMasterInfo = { 
        Name = "bailixi" 
        PlayerId = 10569646082 
    },
    -- 玩家信息
    InPlayerInfos = { 
        [1] = { 
            HeroId = 200010000, 
            Name = "bailixi", 
            TeamPosition = 1, 
            PlayerId = 10569646082, 
            TeamId = 1, 
        } 
    }
--]]
---【回包】获取房间内的玩家信息
---@param Msg table 房间星信息
function CustomRoomDetailCtrl:OnRoomPlayerInfoRsp(Msg)
    CLog("[cw][CustomRoomDetailCtrl] OnRoomPlayerInfoRsp()")
    print_r(Msg, "[cw] ====Msg")
    local InRoomId = Msg.RoomId
    local InMasterInfo = Msg.MasterInfo 
    local InPlayerInfo = Msg.PlayerInfos
    
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    if InRoomId ~= CustomRoomDetailModel:GetRoomInfo_RoomId() then
        CError("[cw] Cannot handle Other RoomInfo")
        return
    end

    CustomRoomDetailModel:UpdateMasterInfo(InMasterInfo)
    CustomRoomDetailModel:UpdateCustomRoomInfo_PlayersInfo(InPlayerInfo)
end
--endregion


-------------------
----- 队伍信息 -----
-------------------
--region
---【发包】发送请求获取房间里面的队伍信息
function CustomRoomDetailCtrl:SendTeamListReq()
    CLog("[cw][CustomRoomDetailCtrl] SendTeamListReq()")
    self:SendProto(Pb_Message.TeamListReq, {})
end

--[[
Msg = { 
    --队伍信息
    TeamList = { 
        [1] = { 
            [1] = { 
                "bAIPlayer" = false 
                "TeamId" = 1 
                "Name" = "百里奚2" 
                "HeroId" = 200010000 
                "PlayerId" = 251658244 
                "LobbyAddr" = "172.17.0.3" 
                "TeamPosition" = 1 
            }，
            [2] = {...}
        }
        [2] = { }
}
--]]
---【回包】获取房间里面的队伍信息
---@param Msg table 
function CustomRoomDetailCtrl:OnTeamListRsp(Msg)
    CLog("[cw][CustomRoomDetailCtrl] OnTeamListRsp(" .. string.format("%s", Msg) .. ")")
    
    local TeamList = Msg.TeamList
    print_r(TeamList, "[cw] ====TeamList")
    
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    CustomRoomDetailModel:UpdateCustomRoomInfo_Team(TeamList)
end
--endregion

-------------------
----- 更换队伍 -----
-------------------
--region
---【发包】发送请求变更自建房内的队伍
---@param TeamId number 目标队伍id
function CustomRoomDetailCtrl:SendSelectTeamReq(TeamId)
    CLog("[cw][CustomRoomDetailCtrl] SendSelectTeamReq(" .. string.format("%s", TeamId) .. ")")
    local Data = {
        TeamId = TeamId
    }
    self:SendProto(Pb_Message.SelectTeamReq, Data)
end

--[[
    Msg = {
        --队伍id
        TeamId = 1,
        --错误码
        Error = "ok"|"invalid-heroid"|"forbid-heroid"
    }
--]]
---【回包】变更自建房内的队伍结果
---@param Msg table 变更队伍结果
function CustomRoomDetailCtrl:OnSelectTeamRsp(Msg)
    CLog("[cw][CustomRoomDetailCtrl] OnSelectTeamRsp(" .. string.format("%s", Msg) .. ")")
    local Error = Msg.Msg
    local TeamId = Msg.TeamId
    CLog("[cw] Error: " .. tostring(Error))
    CLog("[cw] TeamId: " .. tostring(TeamId))
    if Error ~= "ok" then return end
    
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    CustomRoomDetailModel:SetCustomRoomInfo_PlayerTeamId(TeamId)
end
--endregion

-------------------
----- 更换英雄 -----
-------------------
--region
---【发包】发送请求变更自建房内使用的英雄
---@param HeroId number 目标英雄id
function CustomRoomDetailCtrl:SendSelectHeroReq(HeroId)
    CLog("[cw][CustomRoomDetailCtrl] SendSelectHeroReq(" .. string.format("%s", HeroId) .. ")")
    local Data = {
        HeroId = HeroId
    }
    self:SendProto(Pb_Message.RoomSelectHeroReq, Data)
end

--[[
    Msg = {
        Error string "ok"|"invalid-heroid"|"forbid-heroid"
        HeroId number 英雄id 
    }
--]]
---【回包】发送请求变更自建房内使用的英雄结果
---@param 
---@param 
function CustomRoomDetailCtrl:OnSelectHeroRsp(Msg)
    local Error = Msg.Msg
    local HeroId = Msg.HeroId
    CLog("[cw][CustomRoomDetailCtrl] OnSelectHeroRsq(" .. string.format("%s, %s", Error, HeroId) .. ")")
    if Error ~= "ok" then return end

    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    CustomRoomDetailModel:SetCustomRoomInfo_PlayerHeroId(HeroId)
end 
--endregion

-------------------
----- 房间更新 -----
-------------------
--region
--[[
    --自建房id
    InRoomId = 1
    --同步的数据及原因
    InOpInfo = { 
        OpType = 1,
        TeamId = 1,
        PlayerId = 4278190083,
        Name = "bailixi2",
        MasterInfo = {
            Name = "bailixi",
            PlayerId = 1325400068
        },
        HeroId = 200020000,
        TeamPosition = 2,
    } 
--]]
---【同步】后台同步的自建房消息
---@param Msg table 同步信息
function CustomRoomDetailCtrl:OnRoomPlayerSync(Msg)
    CLog("[cw] CustomRoomDetailCtrl:OnRoomPlayerSync(" .. string.format("%s", Msg) .. ")")
    print_r(Msg, "[cw] ====Msg")
    local InRoomId      = Msg.RoomId 
    local InOpInfo      = Msg.OpInfo
    local InMasterInfo  = Msg.MasterInfo
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    if InRoomId ~= CustomRoomDetailModel:GetRoomInfo_RoomId() then
        CError("[cw] Cannot handle Other RoomInfo")
        return
    end
    
    CustomRoomDetailModel:UpdateMasterInfo(InMasterInfo)
    for _,OpTb in pairs(InOpInfo) do
        local opType = OpTb.OpType    
        if opType == _Enum_OpType.None then
            --do nothing
        elseif opType == _Enum_OpType.Add then
            CustomRoomDetailModel:Team_AddNewPlayer(OpTb)
        elseif opType == _Enum_OpType.Remove then
            CustomRoomDetailModel:Team_RemovePlayer(OpTb)
        elseif opType == _Enum_OpType.Update then
            CustomRoomDetailModel:Team_UpdatePlayer(OpTb)
        end
    end
        
end 
--endregion