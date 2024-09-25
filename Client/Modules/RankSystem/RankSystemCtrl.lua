require("Client.Modules.RankSystem.RankDefine");
require("Client.Modules.RankSystem.RankSystemModel");

local class_name = "RankSystemCtrl";
---@class RankSystemCtrl : UserGameController
---@field private super UserGameController
---@field private model RankSystemModel
RankSystemCtrl = RankSystemCtrl or BaseClass(UserGameController, class_name);

function RankSystemCtrl:__init()
    CWaring("==RankSystemCtrl init")
    self.Model = nil
end

function RankSystemCtrl:Initialize()
    self.Model = self:GetModel(RankSystemModel)
end

--- 玩家登出
---@param data any
function RankSystemCtrl:OnLogout(data)
    CWaring("RankSystemCtrl OnLogout")
end

function RankSystemCtrl:OnLogin(data)
    CWaring("RankSystemCtrl OnLogin")
    -- self:ReqSelfRankInfo()
    -- self:ReqPlayerGetAllSkinNum()
end

function RankSystemCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.RankRsp, Func = self.OnRankRsp},
        {MsgName = Pb_Message.StatisticsRsp, Func = self.OnStatisticsRsp},
        {MsgName = Pb_Message.PlayerGetAllSkinNumRsp, Func = self.OnPlayerGetAllSkinNumRsp},
    }
end

function RankSystemCtrl:OnPlayerGetAllSkinNumRsp(Rsp)
    local AllSkinRankTypeId = self.Model:ConvertType2TypeId(RankDefine.Type.Skin, 0)
    self.Model:SetSelfRankInfo(AllSkinRankTypeId, nil, Rsp.SkinNum)
    self:HandleSelfRankCallBack()
end

function RankSystemCtrl:OnRankRsp(Rsp)
    print_r(Rsp)
    local TRankList = {}
    local SelfPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    -- local PlayerIds = {}
    for _, v in pairs(Rsp.RankList) do
        ---@class RankInfo
        ---@field Key number
        ---@field Rank number
        ---@field Score number
        table.insert(TRankList, v)
        if SelfPlayerId == v.Key then
            self.Model:SetSelfRankInfo(Rsp.RankId, v.Rank, v.Score)
        end
        -- table.insert(PlayerIds, v.Key)
    end
    self.Model:AddRankList(Rsp.RankId, Rsp.Location, TRankList)
    -- MvcEntry:GetCtrl(PersonalInfoCtrl):SendGetPlayerListBaseInfoReq(PlayerIds)

    if self.GetRankListCallBack then
        local List = self.Model:GetRankList(Rsp.RankId)
        self.GetRankListCallBack(List)
    end
    self.GetRankListCallBack = nil
end

function RankSystemCtrl:OnStatisticsRsp(Rsp)
    local AllWin,AllKill = 0,0
    for k, v in pairs(Rsp.Statistics) do
        local VRankTypeId = self.Model:ConvertType2TypeId(RankDefine.Type.Victory, tonumber(k))
        self.Model:SetSelfRankInfo(VRankTypeId, nil, v.WinNum)
        AllWin = AllWin + v.WinNum
        local KRankTypeId = self.Model:ConvertType2TypeId(RankDefine.Type.Kill, tonumber(k))
        self.Model:SetSelfRankInfo(KRankTypeId, nil, v.TotKill)
        AllKill = AllKill + v.TotKill
    end

    local VAllRankTypeId = self.Model:ConvertType2TypeId(RankDefine.Type.Victory, 0)
    self.Model:SetSelfRankInfo(VAllRankTypeId, nil, AllWin)
    local KAllRankTypeId = self.Model:ConvertType2TypeId(RankDefine.Type.Kill, 0)
    self.Model:SetSelfRankInfo(KAllRankTypeId, nil, AllKill)

    self:HandleSelfRankCallBack()
end

function RankSystemCtrl:HandleSelfRankCallBack()
    if self.GetSelfRankInfoCallBack then
        local RankInfo = self.Model:GetSelfRankInfo(self.RankTypeId)
        self.GetSelfRankInfoCallBack(RankInfo)
    end
    self.GetSelfRankInfoCallBack = nil
end

--- 请求榜单数据
---@param RankTypeId any
---@param Location any
---@param RankStart any
---@param RankStop any
function RankSystemCtrl:ReqRankList(RankTypeId, Location, RankStart, RankStop)
    if not RankTypeId then
        CError("RankTypeId is nil!", true)
        return
    end
    RankStart = RankStart or 1
    RankStop = RankStop or 100
    local Msg = {
        RankId      = RankTypeId,
        -- Location    = Location,
        RankStart   = RankStart,
        RankStop    = RankStop,
    }
    self:SendProto(Pb_Message.RankReq, Msg, Pb_Message.RankRsp)
end

function RankSystemCtrl:ReqPlayerGetAllSkinNum()
    self:SendProto(Pb_Message.PlayerGetAllSkinNumReq, {}, Pb_Message.PlayerGetAllSkinNumRsp)
end

--- 请求自己的排行榜数据
---@param RankTypeId any
function RankSystemCtrl:ReqSelfRankInfo()
    self:SendProto(Pb_Message.StatisticsReq, {}, Pb_Message.StatisticsRsp)
end

--- 获取自己榜单的数据
---@param RankType any
function RankSystemCtrl:GetSelfRankInfo(RankTypeId, CallBack, IsForce)
    self.GetSelfRankInfoCallBack = CallBack
    self.RankTypeId = RankTypeId
    local RankInfo = self.Model:GetSelfRankInfo(RankTypeId)
    if IsForce or not RankInfo then
        -- self:SendProto(Pb_Message.StatisticsReq, {}, Pb_Message.StatisticsRsp)
        local RankType = self.Model:ConvertTypeId2Type(RankTypeId)
        if RankType == RankDefine.Type.Skin then
            self:ReqPlayerGetAllSkinNum()
            return
        elseif RankType == RankDefine.Type.Victory or RankType == RankDefine.Type.Kill then
            self:ReqSelfRankInfo()
            return
        end
    end
    self:HandleSelfRankCallBack()
    return RankInfo
end

--- 获取榜单数据
---@param RankTypeId any
---@param Location any
function RankSystemCtrl:GetRankList(RankTypeId, Location, CallBack)
    self.GetRankListCallBack = CallBack
    local List = self.Model:GetRankList(RankTypeId, Location)
    local IsTimeOut = self.Model:CheckRankInfoCacheTimeOut(RankTypeId)
    if not List or IsTimeOut then
        self:ReqRankList(RankTypeId, Location)
        return nil
    end
    self.GetRankListCallBack(List)
    return List
end
