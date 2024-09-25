--[[
    赛季通行证协议处理模块
]]
require("Client.Modules.Season.Pass.SeasonBpModel")
local class_name = "SeasonBpCtrl"
---@class SeasonBpCtrl : UserGameController
SeasonBpCtrl = SeasonBpCtrl or BaseClass(UserGameController,class_name)


function SeasonBpCtrl:__init()
    CWaring("==SeasonBpCtrl init")
end

function SeasonBpCtrl:Initialize()
    self.Model = self:GetModel(SeasonBpModel)
end

--[[
    玩家登入
]]
function SeasonBpCtrl:OnLogin(data)
    CWaring("SeasonBpCtrl OnLogin")

    
    self:SendProto_PassStatusReq()
end

--[[
    跨天，重新请求通行证信息
]]
function SeasonBpCtrl:OnDayRefresh(data)
    CWaring("SeasonBpCtrl OnDayRefresh")
    self:SendProto_PassStatusReq()
    self:SendProto_PassDailyTaskReq()
    self:SendProto_PassUnlockWeekTaskReq()
end


function SeasonBpCtrl:AddMsgListenersUser()
    self.ProtoList = {
    	{MsgName = Pb_Message.BuyPassRsp,	Func = self.BuyPassRsp_Func },
		-- {MsgName = Pb_Message.BuyPassLevelRsp,	Func = self.BuyPassLevelRsp_Func },
		{MsgName = Pb_Message.RecvPassRewardRsp,	Func = self.RecvPassRewardRsp_Func },
		{MsgName = Pb_Message.PassStatusRsp,	Func = self.PassStatusRsp_Func },
		{MsgName = Pb_Message.PassExpIncSync,	Func = self.PassExpIncSync_Func },
		{MsgName = Pb_Message.PassDailyTaskRsp,	Func = self.PassDailyTaskRsp_Func },
		-- {MsgName = Pb_Message.PassWeekTaskRsp,	Func = self.PassWeekTaskRsp_Func },
        {MsgName = Pb_Message.PassUnlockWeekTaskRsp,	Func = self.PassUnlockWeekTaskRsp_Func },
    }
end


--[[
    购买高级通行证返回
]]
function SeasonBpCtrl:BuyPassRsp_Func(Msg)
    --[[
        message BuyPassRsp
        {
            int32 SeasonBpId = 1;
            PASS_TYPE PassType = 2;      // 购买成功的通行证类型
        }
    ]]
    -- print_r(Msg,"BuyPassRsp_Func")
    local PassStatus = self.Model:GetPassStatus()
    if PassStatus.SeasonBpId == Msg.SeasonBpId then
        PassStatus.PassType = Msg.PassType
        self.Model:DispatchType(SeasonBpModel.ON_SEASON_BP_PASS_BUY_SUC)
    end
end
-- --[[
--     购买通行证等级返回
-- ]]
-- function SeasonBpCtrl:BuyPassLevelRsp_Func(Msg)
--     --[[
--         message BuyPassLevelRsp
--         {
--             int32 SeasonBpId = 1;
--             int32 Level = 2;        // 成功购买的等级
--         }
--     ]]
--     print_r(Msg,"BuyPassLevelRsp_Func")
--     local PassStatus = self.Model:GetPassStatus()
--     if PassStatus.SeasonBpId == Msg.SeasonBpId then
--         PassStatus.OldLevel = PassStatus.Level
--         PassStatus.Level = Msg.Level

--         self.Model:DispatchType(SeasonBpModel.ON_SEASON_BP_LEVEL_UPDATE)

--         --TODO 需要展示通行证升级界面
--     end
-- end
--[[
    领取通行证奖励返回
    message RecvPassRewardRsp
    {
        repeated int64 DropIdList = 1;              // 领取的奖励物品列表
        int32 BasicAwardedLevel = 2;                // 基础通行证已领取奖励等级
        int32 PremiumAwardedLevel = 3;              // 高级
        int32 DeluxeAwardeLevel = 4;                // 豪华
        PASS_TYPE PassType = 5;                     // 玩家当前通行证类型
    }
]]
function SeasonBpCtrl:RecvPassRewardRsp_Func(Msg)
    -- repeated int64 ItemIdList = 1;  // 领取的奖励物品列表
    -- UIAlert.Show("功能未做")
    -- print_r(Msg,"RecvPassRewardRsp_Func")
    local PassStatus = self.Model:GetPassStatus()
    PassStatus.BasicAwardedLevel = Msg.BasicAwardedLevel
    PassStatus.PremiumAwardedLevel = Msg.PremiumAwardedLevel
    PassStatus.DeluxeAwardeLevel = Msg.DeluxeAwardeLevel
    PassStatus.PassType = Msg.PassType
    PassStatus.AdvanceAwardeLevel = 0
    if PassStatus.PassType ~= Pb_Enum_PASS_TYPE.BASIC then
        PassStatus.AdvanceAwardeLevel = PassStatus.PassType == Pb_Enum_PASS_TYPE.PREMIUM and PassStatus.PremiumAwardedLevel or PassStatus.DeluxeAwardeLevel
    end

    self.Model:DispatchType(SeasonBpModel.ON_SEASON_BP_AWARD_LEVEL_UPDATE)
    --TODO 需要展示奖励列表
end
--[[
    通行证基础信息返回
]]
function SeasonBpCtrl:PassStatusRsp_Func(Msg)
    --[[
        message PassStatusRsp
        {
            int32 SeasonBpId = 1;       // 当前通行证Id
            PASS_TYPE PassType = 2;     // 当前解锁的通行证类型
            int32 BasicAwardedLevel = 3;                // 基础通行证已领取奖励等级
            int32 PremiumAwardedLevel = 4;              // 高级
            int32 DeluxeAwardeLevel = 5;                // 豪华
            int32 Level = 6;            // 通行证等级
            int32 Exp = 7;              // 当前等级的经验数
            int32 Week = 8;             // 赛季开始后的第几周
            int64 StartTime = 9;        // 开始时间
            int64 EndTime = 10;          // 结束时间
            int32 TotWeek = 11;          // 当前赛季总共有多少周
        }
    ]]
    -- print_r(Msg,"=========asdfasdf",true)
    self.Model:SetPassStatus(Msg)
end

function SeasonBpCtrl:PassExpIncSync_Func(Msg)
    --[[
        // 通行证经验提升同步
        message PassExpIncSync
        {
            int32 Level = 1;        // 通行证等级
            int32 Exp = 2;          // 当前等级的经验数
        }
    ]]
    -- print_r(Msg,"PassExpIncSync_Func")
    local PassStatus = self.Model:GetPassStatus()
    if not PassStatus then
        return
    end
    local OldLevel = PassStatus.Level
    local LevelUpdate = false
    if Msg.Level > OldLevel then
        PassStatus.OldLevel = PassStatus.Level
        LevelUpdate = true
    end
    PassStatus.Level = Msg.Level
    PassStatus.Exp = Msg.Exp
    PassStatus.PassType = Msg.PassType
    
    if LevelUpdate then
        if not self.Model:IsTryToPopUpgrade(PassStatus.PassType) then
            -- 多少次升级都只弹一次
            if PassStatus.PassType == Pb_Enum_PASS_TYPE.BASIC then
                CWaring("LevelUpdate===============1")
                self:GetSingleton(CommonCtrl):TryFaceActionOrInCache(function ()
                    MvcEntry:OpenView(ViewConst.SeasonBpLvUpgradeNormal)
                end)
            else
                CWaring("LevelUpdate===============2")
                self:GetSingleton(CommonCtrl):TryFaceActionOrInCache(function ()
                    MvcEntry:OpenView(ViewConst.SeasonBpLvUpgradeAdvance)
                end)
            end
            self.Model:SetIsTryToPopUpgrade(PassStatus.PassType,true)
        end
        self.Model:DispatchType(SeasonBpModel.ON_SEASON_BP_LEVEL_UPDATE)
    else
        self.Model:DispatchType(SeasonBpModel.ON_SEASON_BP_EXP_UPDATE)
    end
end

function SeasonBpCtrl:PassDailyTaskRsp_Func(Msg)
    -- message PassDailyTaskRsp
    -- {
    --     repeated BpTaskBase TaskList = 1;
    -- }
    -- print_r(Msg,"PassDailyTaskRsp_Func")
    self.Model.DailyEndTime = Msg.TimeToRefresh
    self.Model:SetDailyTaskList(Msg.TaskList)
    self.Model:DispatchType(SeasonBpModel.ON_SEASON_BP_DAILY_TASK_UPDATE)
end


-- function SeasonBpCtrl:PassWeekTaskRsp_Func(Msg)
--     -- message PassWeekTaskRsp
--     -- {
--     --     int32 Week = 1;                     // 第几周的任务
--     --     repeated BpTaskBase TaskList = 2;   // 返回请求周的任务
--     --     bool Unlock = 3;                    // 该周任务是否解锁
--     -- }
--     print_r(Msg,"PassWeekTaskRsp_Func")
--     self.Model:SetWeekTaskInfo(Msg.Week,Msg)
--     self.Model:DispatchType(SeasonBpModel.ON_SEASON_BP_WEEK_TASK_UPDATE)
-- end

function SeasonBpCtrl:PassUnlockWeekTaskRsp_Func(Msg)
    --[[
        message PassUnlockWeekTaskRsp
        {
            map<int32, WeeklyTasksBase> WeeklyTasksList = 1;    // 已解锁周所有任务
            int32 CurWeek = 2;                                  // 当前周
        }
    ]]
    -- print_r(Msg,"PassUnlockWeekTaskRsp_Func")
    for Week,v in pairs(Msg.WeeklyTasksList) do
        local TaskInfo = {
            Week = Week,
            TaskList = v.TaskList,
            Unlock = true,
        }
        self.Model:SetWeekTaskInfo(Week,TaskInfo)
    end
    self.Model:DispatchType(SeasonBpModel.ON_SEASON_BP_WEEK_TASK_UPDATE)
end





------------------------------------请求相关----------------------------

--[[
    请求购买通行证
]]
function SeasonBpCtrl:SendProto_BuyPassReq(SeasonBpId,PassType)
    local Msg = {
        SeasonBpId= SeasonBpId,
        PassType= PassType,
    }
    -- print_r(Msg)
    self:SendProto(Pb_Message.BuyPassReq,Msg,Pb_Message.BuyPassRsp)
end

-- --[[
--     购买通行证等级
-- ]]
-- function SeasonBpCtrl:SendProto_BuyPassLevelReq(SeasonBpId,Level)
--     local Msg = {
--         SeasonBpId= SeasonBpId,
--         Level= Level,
--     }
--     self:SendProto(Pb_Message.BuyPassLevelReq,Msg,Pb_Message.BuyPassLevelRsp)
-- end
--[[
    请求领取通行证奖励
]]
function SeasonBpCtrl:SendProto_RecvPassRewardReq()
    local Msg = {
    }
    self:SendProto(Pb_Message.RecvPassRewardReq,Msg)
end

--[[
    请求通行证相关基础信息
]]
function SeasonBpCtrl:SendProto_PassStatusReq(NeedNetLoading)
    local Msg = {

    }
    if not NeedNetLoading then
        self:SendProto(Pb_Message.PassStatusReq,Msg)
    else
        self:SendProto(Pb_Message.PassStatusReq,Msg,Pb_Message.PassStatusRsp)
    end
end

-- --[[
--     请求
-- ]]
-- function SeasonBpCtrl:SendProto_PassExpReq()
--     local Msg = {

--     }
--     self:SendProto(Pb_Message.PassExpReq,Msg)
-- end
--[[
    请求赛季日任务
]]
function SeasonBpCtrl:SendProto_PassDailyTaskReq()
    local Msg = {

    }
    self:SendProto(Pb_Message.PassDailyTaskReq,Msg,Pb_Message.PassDailyTaskRsp)
end

-- function SeasonBpCtrl:SendProto_SeasonWeekReq(Week)
--     local Msg = {
--         Week = Week,
--     }
--     print_r(Msg,"SendProto_SeasonWeekReq",true)
--     self:SendProto(Pb_Message.PassWeekTaskReq,Msg,Pb_Message.SeasonWeekRsp)
-- end

function SeasonBpCtrl:SendProto_PassUnlockWeekTaskReq(Week)
    local Msg = {
    }
    -- print_r(Msg,"SendProto_PassUnlockWeekTaskReq",true)
    self:SendProto(Pb_Message.PassUnlockWeekTaskReq,Msg,Pb_Message.PassUnlockWeekTaskRsp)
end



