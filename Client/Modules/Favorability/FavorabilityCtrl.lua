--[[
    好感度协议处理模块
]]

require("Client.Modules.Favorability.FavorabilityModel");
require("Client.Modules.Favorability.FavorabilityConst");

local class_name = "FavorabilityCtrl"
---@class FavorabilityCtrl : UserGameController
FavorabilityCtrl = FavorabilityCtrl or BaseClass(UserGameController,class_name)


function FavorabilityCtrl:__init()
    CWaring("==FavorabilityCtrl init")
    ---@type FavorabilityModel
    self.Model = MvcEntry:GetModel(FavorabilityModel)
end

function FavorabilityCtrl:Initialize()
end

--[[
    玩家登入
]]
function FavorabilityCtrl:OnLogin(data)
    CWaring("FavorabilityCtrl OnLogin")
end

function FavorabilityCtrl:AddMsgListenersUser()
    self.ProtoList = {
    	{MsgName = Pb_Message.PlayerGetFavorDataRsp,	Func = self.PlayerGetFavorDataRsp_Func },
		{MsgName = Pb_Message.PlayerSetHeroFirstEnterFlagRsp,	Func = self.PlayerSetHeroFirstEnterFlagRsp_Func },
		{MsgName = Pb_Message.PlayerSendHeroGiftRsp,	Func = self.PlayerSendHeroGiftRsp_Func },
		{MsgName = Pb_Message.PlayerGetFavorLevelPrizeRsp,	Func = self.PlayerGetFavorLevelPrizeRsp_Func },
		{MsgName = Pb_Message.PlayerStorePassageRsp,	Func = self.PlayerStorePassageRsp_Func },
		{MsgName = Pb_Message.PlayerAcceptPassageTaskRsp,	Func = self.PlayerAcceptPassageTaskRsp_Func },
		{MsgName = Pb_Message.PlayerAddFavorSyn,	Func = self.PlayerAddFavorSyn_Func },
    }
    self.MsgList = {
		{Model = DepotModel,  	MsgName = DepotModel.ON_DEPOT_DATA_INITED,      Func = self.ReqUnlockHeroFavor},
		{Model = HeroModel,  	MsgName = HeroModel.ON_NEW_HERO_UNLOCKED,      Func = self.ReqUnlockHeroFavor},

    }
end

-- 接收好感度信息列表
function FavorabilityCtrl:PlayerGetFavorDataRsp_Func(Msg)
    self.Model:OnReceiveHeroFavorData(Msg.HeroFavorMap)
end

function FavorabilityCtrl:PlayerSetHeroFirstEnterFlagRsp_Func(Msg)
    self.Model:SetHeroFirstEnterFlag(Msg.HeroId)
end

function FavorabilityCtrl:PlayerSendHeroGiftRsp_Func(Msg)
    self.Model:DispatchType(FavorabilityModel.ON_SEND_GIFT_SUCCESSED,Msg)
end

function FavorabilityCtrl:PlayerGetFavorLevelPrizeRsp_Func(Msg)
    self.Model:UpdateRewardStatus(Msg.HeroId, Msg.FavorLevelList)
    self.Model:SaveRewardData(Msg)
    self.Model:ShowReward() -- 之前需要播放LS后才展示奖励，现在修改为直接展示了
    self.Model:DispatchType(FavorabilityModel.ON_RECEIVE_REWARD_SUCCESSED,Msg)
end

function FavorabilityCtrl:PlayerStorePassageRsp_Func(Msg)
    self.Model:SetStoryCompleted(Msg)
end

function FavorabilityCtrl:PlayerAcceptPassageTaskRsp_Func(Msg)
    
end

-- 同步好感度信息变动
function FavorabilityCtrl:PlayerAddFavorSyn_Func(Msg)
    self.Model:UpdateFavorInfo(Msg)
end

------------------------------------请求相关----------------------------
-- 请求获取已解锁英雄的好感度
function FavorabilityCtrl:ReqUnlockHeroFavor(NewHeroIdList)
    local HeroIdList = {}
    if NewHeroIdList and #NewHeroIdList > 0 then
        -- 请求新解锁的
        for _,Id in ipairs(NewHeroIdList) do
            local HeroCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,Id)
            if HeroCfg and HeroCfg[Cfg_HeroConfig_P.IsOpenFavor] then
                HeroIdList[#HeroIdList + 1] = Id
            end
        end
    else
        local HeroCfgs = MvcEntry:GetModel(HeroModel):GetShowHeroCfgs() 
        local HeroModel = MvcEntry:GetModel(HeroModel)
        for _,HeroCfg in ipairs(HeroCfgs) do
            local Id = HeroCfg[Cfg_HeroConfig_P.Id]
            if HeroModel:CheckGotHeroById(Id) and HeroCfg[Cfg_HeroConfig_P.IsOpenFavor] then
                HeroIdList[#HeroIdList + 1] = Id
            end
        end
    end
    if #HeroIdList > 0 then
        self:SendProto_PlayerGetFavorDataReq(HeroIdList)
    end
end

-- 获取好感度数据
function FavorabilityCtrl:SendProto_PlayerGetFavorDataReq(HeroIdList)
    local Msg = {
        HeroIdList = HeroIdList
    }
    self:SendProto(Pb_Message.PlayerGetFavorDataReq,Msg)
end

-- 设置某个英雄Id已经进入场景系统
function FavorabilityCtrl:SendProto_PlayerSetHeroFirstEnterFlagReq(HeroId)
    local Msg = {
        HeroId = HeroId
    }
    self:SendProto(Pb_Message.PlayerSetHeroFirstEnterFlagReq,Msg)
end

-- 赠送礼物
function FavorabilityCtrl:SendProto_PlayerSendHeroGiftReq(Param)
    local Msg = {
        HeroId = Param.HeroId,
        ItemId = Param.ItemId,
        ItemNum = Param.ItemNum,
    }
    print_r(Msg)
    self:SendProto(Pb_Message.PlayerSendHeroGiftReq,Msg,Pb_Message.PlayerSendHeroGiftRsp)
end

-- 领取好感度奖励
function FavorabilityCtrl:SendProto_PlayerGetFavorLevelPrizeReq(HeroId)
    local Msg = {
        HeroId = HeroId,
        FavorLevelList = self.Model:GetCanReceiveRewardLevelList(HeroId)
    }
    self:SendProto(Pb_Message.PlayerGetFavorLevelPrizeReq,Msg,Pb_Message.PlayerGetFavorLevelPrizeRsp)
end

function FavorabilityCtrl:SendProto_PlayerStorePassageReq(Param)
    local Msg = {
        HeroId = Param.HeroId,
        PassageId = Param.PartId
    }
    self:SendProto(Pb_Message.PlayerStorePassageReq,Msg,Pb_Message.PlayerStorePassageRsp)
end

function FavorabilityCtrl:SendProto_PlayerAcceptPassageTaskReq(Param)
    local Msg = {
        HeroId = Param.HeroId,
        PassageId = Param.PartId,
        TaskId = Param.TaskId
    }
    self:SendProto(Pb_Message.PlayerAcceptPassageTaskReq,Msg,Pb_Message.PlayerAcceptPassageTaskRsp)
end


