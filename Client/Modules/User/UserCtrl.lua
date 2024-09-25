require("Client.Modules.User.UserModel")

--[[
    玩家相关协议处理模块
]]
local class_name = "UserCtrl"
---@class UserCtrl : UserGameController
---@field private model UserModel
UserCtrl = UserCtrl or BaseClass(UserGameController,class_name)


function UserCtrl:__init()
    CWaring("==UserCtrl init")
    self.Model = nil
end

function UserCtrl:Initialize()
    ---@type UserModel
    self.Model = self:GetModel(UserModel)
end


function UserCtrl:AddMsgListenersUser()
    self.ProtoList = {
        { MsgName = Pb_Message.RandomNameRsp,               Func = self.RandomNameRsp_Func },
        { MsgName = Pb_Message.CheckNameRsp,                Func = self.CheckNameRsp_Func },
        { MsgName = Pb_Message.ModifyNameRsp,               Func = self.ModifyNameRsp_Func },
        { MsgName = Pb_Message.QueryMultiPlayerStatusRsp,	Func = self.On_QueryMultiPlayerStatusRsp },
        { MsgName = Pb_Message.HeroInfoSync,	            Func = self.HeroInfoSync_Func },
        { MsgName = Pb_Message.PlayerExitDSRsp,	            Func = self.PlayerExitDSRsp_Func },
        { MsgName = Pb_Message.GetHeadIdListRsp,	        Func = self.GetHeadIdListRsp },
        {MsgName =  Pb_Message.PlayerLevelUpSyc,            Func = self.OnPlayerLevelUpSyc},
        {MsgName =  Pb_Message.PlayerInfoSync,              Func = self.OnPlayerInfoSync},
        {MsgName =  Pb_Message.PlayerSysCofSync,              Func = self.OnPlayerSysCofSync},
    }
    
    self.MsgList = {
        { Model = ViewModel, MsgName = ViewModel.ON_SATE_ACTIVE_CHANGED,    Func = self.ON_SATE_ACTIVE_CHANGED_Fun },
    }
end

function UserCtrl:OnPlayerLevelUpSyc(Msg)
    local UModel = self:GetModel(UserModel)
    UModel:SetPlayerLvAndExp(Msg.Level, Msg.Experience)
    -- 数据派发出去
    self.Model:DispatchType(UserModel.ON_PLAYER_LEVEL_UP_SYC_DATA, Msg)
end


function UserCtrl:RandomNameRsp_Func(Msg)
    local Name = Msg.Name
    if self.NotUpdatePlayerName then
        -- 可能只要一个随机的名称，但并未实际更新到玩家名称上
        self.Model:DispatchType(UserModel.ON_GET_RANDOM_NAME, Name)
    else
        self.Model:SetPlayerName(Name)
    end
end

function UserCtrl:CheckNameRsp_Func(Msg)
    self.Model:DispatchType(UserModel.ON_CHECK_NAME_VALID_RESULT,Msg)
end

function UserCtrl:ModifyNameRsp_Func(Msg)
    local Name = Msg.Name
    if Msg.ErrCode == 0 then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_UserCtrl_Theobservernamehasbe"))
        self.Model:SetPlayerName(Name)
        self.Model:DispatchType(UserModel.ON_MODIFY_NAME_SUCCESS)
    else
        self.Model:DispatchType(UserModel.ON_CHECK_NAME_VALID_RESULT,Msg)
    end
end

-- 查询多个玩家状态接口回包
function UserCtrl:On_QueryMultiPlayerStatusRsp(Msg)
    self.Model:UpdatePlayerStatusCache(Msg.StatusInfoList)
    self.Model:DispatchType(UserModel.ON_QUERY_MULTI_PLAYER_STATE_RSP,Msg.StatusInfoList)
end

--[[
    message HeroInfoSync
    {
        int32               FavoriteId              = 1;    // 偏好
        int64               SelectWeaponId          = 2;    // 选择武器的物品Id
        int64               SelectVehicleId         = 3;    // 选择的载具物品Id
        repeated WeaponSkinNode WeaponSkinList      = 4;    // 每个武器选择的皮肤列表
        repeated HeroSkinNode HeroSkinList          = 5;    // 每个英雄选择的皮肤列表
        repeated VehicleSkinNode VehicleSkinList    = 6;    // 每个载具选择的皮肤列表
    }
]]
function UserCtrl:HeroInfoSync_Func(Msg)
    -- print_r(Msg,"HeroInfoSync_Func",true)
    self:GetModel(HeroModel):SetFavoriteId(Msg.SelectHeroId)
    self:GetModel(HeroModel):SetFavoriteHeroSkinList(Msg.HeroSkinList)
    self:GetModel(WeaponModel):SetSelectWeaponId(Msg.SelectWeaponId)
    self:GetModel(WeaponModel):SetWeaponSkinList(Msg.WeaponSkinList)
    self:GetModel(VehicleModel):SetSelectVehicleId(Msg.SelectVehicleId)
    self:GetModel(VehicleModel):SetVehicleSkinList(Msg.VehicleSkinList)
    self:GetModel(VehicleModel):SetVehicleSkinStickerList(Msg.VehiclSkinStickMap)
    self:GetModel(UserModel):SetLikeTotal(Msg.MiscData.LikeTotal)
    self:GetModel(HeroModel):SetSkinSuitData(Msg.SkinSuitMap)
    
    local PersonalInfoModel = self:GetModel(PersonalInfoModel)
    PersonalInfoModel:SetMyMiscData(Msg.MiscData)
end


--玩家主动退出游戏对局响应
function UserCtrl:PlayerExitDSRsp_Func(Msg)
    CLog("UserCtrl:PlayerExitDSRsp_Func")
end

--- 返回玩家可选头像列表
---@param Msg GetHeadIdListRsp
function UserCtrl:GetHeadIdListRsp(Msg)
    self.Model.PlayerHeadList = Msg.HeadIdList
    self.Model:DispatchType(UserModel.ON_GET_PALYER_HEAD_LISR_RESULT)
end


-----------------------------------------------发送协议--------------------------------------------------

--[[
    请求创建角色
]]
function UserCtrl:SendProto_CreatePlayerReq(Msg)
    MvcEntry:SendProto(Pb_Message.CreatePlayerReq, Msg,Pb_Message.CreatePlayerRsp)
end

function UserCtrl:SendProto_RandomNameReq(NotUpdatePlayerName)
    self.NotUpdatePlayerName = NotUpdatePlayerName
    local LangType = self:GetModel(LocalizationModel):GetCurSelectLanguageServer()
    CWaring("UserCtrl:SendProto_RandomNameReq LangType:" .. LangType)
    local Msg = {
        LangType = LangType,
    }
    self:SendProto(Pb_Message.RandomNameReq,Msg,Pb_Message.RandomNameRsp)
end

function UserCtrl:SendProto_CheckNameReq(Name)
    local Msg = {
        Name = Name
    }
    self:SendProto(Pb_Message.CheckNameReq,Msg,Pb_Message.CheckNameRsp)
end

function UserCtrl:ModifyNameReq(Name)
    local Msg = {
        Name = Name
    }
    self:SendProto(Pb_Message.ModifyNameReq,Msg,Pb_Message.ModifyNameRsp)
end

function UserCtrl:ON_SATE_ACTIVE_CHANGED_Fun(viewID)
    local ConstPlayerState = require("Client.Modules.User.ConstPlayerState")
    local PLAYER_CLIENT_HALL_STATE = ConstPlayerState.VIEW_ID_2_PLAYER_CLIENT_HALL_STATE_MAP[viewID]
    if not PLAYER_CLIENT_HALL_STATE then return end

    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    UserModel:UpdatePlayerClientHallState(PLAYER_CLIENT_HALL_STATE)
end

-- 查询多个玩家状态接口请求
---@param ReqIdList table<number>
function UserCtrl:SendQueryMultiPlayerStatusReq(ReqIdList)
    local Msg = {
        PlayerList = ReqIdList
    }
    self:SendProto(Pb_Message.QueryMultiPlayerStatusReq,Msg)
end

---更新客户端状态
---@param NewClientState string 客户端状态
---@see ConstPlayerState#Enum_PLAYER_CLIENT_HALL_STATE
function UserCtrl:SendSetPlayerDisplayStatusReq(NewClientState)
    local Msg = {
        DisplayStatus = NewClientState
    }
    self:SendProto(Pb_Message.SetPlayerDisplayStatusReq, Msg)
end

--玩家主动退出游戏对局请求
function UserCtrl:SendProto_PlayerExitDSReq(Reason)
    CLog("UserCtrl:SendProto_PlayerExitDSReq")
    local Msg = {
        Reason = Reason
    }
    self:SendProto(Pb_Message.PlayerExitDSReq,Msg,nil,true)
end

--- 获取玩家头像列表
function UserCtrl:SendProtoGetHeadListReq()
    self:SendProto(Pb_Message.GetHeadIdListReq, {}, Pb_Message.GetHeadIdListRsp)
end


--- 主动请求玩家等级与经验
function UserCtrl:ReqPlayerPlayerLevel()
    self:SendProto(Pb_Message.PlayerLevelReq,{}, Pb_Message.PlayerLevelUpSyc)
end

-- 玩家额外信息同步
function UserCtrl:OnPlayerInfoSync(Msg)
    MvcEntry:GetCtrl(AchievementCtrl):OnGetAchievementInfoRsp(Msg)
end

-- 全量同步各个系统的加成数据
function UserCtrl:OnPlayerSysCofSync(Msg)
    self.Model:SavePlayerCofData(Msg)
end