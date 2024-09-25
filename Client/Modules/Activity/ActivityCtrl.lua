--[[
    活动协议处理模块
]]
require("Client.Modules.Activity.ActivityModel")
require("Client.Modules.Activity.ActivitySubModel")
local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
local class_name = "ActivityCtrl"
---@class ActivityCtrl : UserGameController
ActivityCtrl = ActivityCtrl or BaseClass(UserGameController,class_name)

ActivityCtrl.DEBUG = false


ActivityCtrl.CHECK_BANNER_STATE_TIME = 10

function ActivityCtrl:__init()
    CWaring("==ActivityCtrl init")
    ---@type ActivityModel
	self.ActivityModel = MvcEntry:GetModel(ActivityModel)
	---@type ActivitySubModel
	self.ActivitySubModel = MvcEntry:GetModel(ActivitySubModel)
	self:CleanAutoCheckTimer()
end

function ActivityCtrl:Initialize()
end

--[[
    玩家登入
]]
function ActivityCtrl:OnLogin(data)
    CWaring("ActivityCtrl OnLogin")
	self:TestOpenActivity()
	self.CheckTimer = Timer.InsertTimer(ActivityCtrl.CHECK_BANNER_STATE_TIME,function()
		self.ActivityModel:CheckAvailbleActivityBannerState()
	end, true)
end

--- 玩家登出
---@param data any
function ActivityCtrl:OnLogout(data)
    CWaring("ActivityCtrl OnLogout")
	self:CleanAutoCheckTimer()
end

--- 跨天刷新
function ActivityCtrl:OnDayRefresh()
    CWaring("ActivityCtrl ========================= OnDayRefresh")
	self.ActivityModel.DitryFlag:SetAllFlagDirty()
    self.ActivityModel:DispatchType(ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE)
end

function ActivityCtrl:AddMsgListenersUser()
    self.ProtoList = {
		{MsgName = Pb_Message.OpenActivityListSync,	Func = self.OpenActivityListSyn_Func },
		{MsgName = Pb_Message.CloseActivityListSync,	Func = self.CloseActivityListSyn_Func },
		{MsgName = Pb_Message.ActivityGetPrizeRsp,	Func = self.ActivityGetPrizeRsp_Func },
		{MsgName = Pb_Message.PlayerGetActivityDataRsp,	Func = self.PlayerGetActivityDataRsp_Func },
		{MsgName = Pb_Message.PlayerSetActivitySubItemPrizeStateRsp,	Func = self.PlayerSetActivitySubItemPrizeStateRsp_Func },
		{MsgName = Pb_Message.NoticeListSync, Func = self.NoticeListSyn_Func}
    }
end


function ActivityCtrl:CleanAutoCheckTimer()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

--Activity.proto
function ActivityCtrl:PlayerSetActivitySubItemPrizeStateRsp_Func(Msg)
	print_r(Msg, "ActivityCtrl:PlayerSetActivitySubItemPrizeStateRsp_Func")
	self.ActivityModel:On_PlayerSetActivitySubItemPrizeStateRsp_Func(Msg)
end

--[[
	Msg = {
	    repeated int64 NoticeList = 1;    // 公告Id列表
	}
]]
function ActivityCtrl:NoticeListSyn_Func(Msg)
	print_r(Msg, "ActivityCtrl:NoticeListSyn_Func")
	self.ActivityModel:On_NoticeListSyn(Msg)
end

--[[
	Msg = {
	    repeated int64 ActivityIdList = 1;  // 开启的活动列表Id
	}
]]
function ActivityCtrl:OpenActivityListSyn_Func(Msg)
	print_r(Msg, "ActivityCtrl:OpenActivityListSyn_Func")
	self.ActivityModel:On_OpenActivityListSyn(Msg)
	for _, AcId in pairs(Msg.ActivityIdList) do
        self:SendProtoPlayerGetActivityDataReq(AcId)
    end
end

--[[
	Msg = {
	    repeated int64 ActivityIdList = 1;  // 关闭的活动Id列表
	}
]]
function ActivityCtrl:CloseActivityListSyn_Func(Msg)
	print_r(Msg, "ActivityCtrl:CloseActivityListSyn_Func")
	self.ActivityModel:On_CloseActivityListSyn(Msg)
end

--[[
	Msg = {
	    int64 ActivityId = 1;                   // 活动Id
	    int64 ActivitySubItemId = 2;            // 子项Id
	}
]]
function ActivityCtrl:ActivityGetPrizeRsp_Func(Msg)
	print_r(Msg, "ActivityCtrl:ActivityGetPrizeRsp_Func")
	self.ActivityModel:On_ActivityGetPrizeRsp(Msg)
end

--[[
	Msg = {
	    int64 ActivityId = 1;                   // 活动Id
	    map<int64, int64> SubItemMap = 2;       // 已经领取的奖励子项数据，Key子项Id,Value子项奖励领取时间
	}
]]
function ActivityCtrl:PlayerGetActivityDataRsp_Func(Msg)
	print_r(Msg, "ActivityCtrl:PlayerGetActivityDataRsp_Func")
	self.ActivityModel:On_PlayerGetActivityDataRsp(Msg)
end

---请求领取任务奖励
---@param ActiveityID number
---@param SubItemIds number[]
function ActivityCtrl:TrySendProtoActivityGetPrizeReq(ActiveityID, SubItemIds)
	SubItemIds = SubItemIds or {}
	---@type ActivityData
	local AcData = self.ActivityModel:GetData(ActiveityID)
	if AcData == nil then
		return
	end

	if AcData.Type == Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_DAY_TASK then
		-- local AcData = self:GetData(AcId)
		if next(SubItemIds) == nil then
			-- 没有可领取的奖励！
			UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Activity', "Lua_Activity_NoAwardToGetAll"))
			return
		end

		for _, SubItemId in pairs(SubItemIds) do
			---@type ActivitySubData
			local SubAcData = AcData:GetSubItemById(SubItemId)
			local SubAcState = SubAcData:GetState()
			if SubAcData.Type == Pb_Enum_ACTIVITY_SUB_ITEM_TYPE.ACTIVITY_SUB_ITEM_TYPE_ACTIVITY and SubAcState == ActivityDefine.ActivitySubState.Not then
				-- 活跃度不足，无法领取。
				UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Activity', "Lua_Activity_NotEnoughAP"))
				return
			end
			if SubAcData.Type == Pb_Enum_ACTIVITY_SUB_ITEM_TYPE.ACTIVITY_SUB_ITEM_TYPE_TASK and SubAcState == ActivityDefine.ActivitySubState.Not then
				-- 任务未完成，无法领取。
				UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Activity', "Lua_Activity_TaskNoFinished"))
				return
			end
			if SubAcState == ActivityDefine.ActivitySubState.Got then
				-- 已经领取，不能重复领取。
				UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Activity', "Lua_Activity_TaskHasGot"))
				return
			end
		end

		--TODO:请求领取奖励
		self:SendProtoActivityGetPrizeReq(ActiveityID, SubItemIds)
	end
end

------------------------------------请求相关----------------------------
function ActivityCtrl:SendProtoPlayerSetActivitySubItemPrizeStateReq(ActivityId,SubItemId)
	local Msg = {
		ActivityId = ActivityId,
		SubItemId = SubItemId,
	}
	self:SendProto(Pb_Message.PlayerSetActivitySubItemPrizeStateReq, Msg, Pb_Message.PlayerSetActivitySubItemPrizeStateRsp)
end

--[[
	// 请求子项Id列表的信息
    repeated int64 SubItemIdList = 1;       // 子项Id列表
]]
function ActivityCtrl:SendProtoActivityGetSubItemCfgReq(SubItemIdList)
	local Msg = {
		SubItemIdList = SubItemIdList,
	}
	self:SendProto(Pb_Message.ActivityGetSubItemCfgReq, Msg, Pb_Message.ActivityGetSubItemCfgRsp)
end

--[[
	// 领取奖励，关联的任务或者活跃度达成条件，才能领取奖励成功
    int64 ActivityId = 1;                   // 活动Id
    int64 SubItemIdList = 2;            // 子项Id
]]
function ActivityCtrl:SendProtoActivityGetPrizeReq(ActivityId,SubItemIdList)
	local Msg = {
		ActivityId = ActivityId,
		SubItemIdList = SubItemIdList,
	}
	self:SendProto(Pb_Message.ActivityGetPrizeReq, Msg, Pb_Message.ActivityGetPrizeRsp)
end

--[[
	// 获取某个活动的玩家领奖数据
    int64 ActivityId = 1;                   // 活动Id
]]
function ActivityCtrl:SendProtoPlayerGetActivityDataReq(ActivityId)
	local Msg = {
		ActivityId = ActivityId,
	}
	self:SendProto(Pb_Message.PlayerGetActivityDataReq, Msg, Pb_Message.PlayerGetActivityDataRsp)
end

--- 通过入口打开活动界面
---@param EntryId any
---@param ActivityId any
function ActivityCtrl:OpenActivityByEntry(EntryId, ActivityId)
	MvcEntry:OpenView(ViewConst.ActivityMain,{EntryId = EntryId, ActivityId = ActivityId})
end


--- 打开活动界面
---@param ActivityId number
---@param EntryId number
function ActivityCtrl:OpenActivity(ActivityId, EntryId)
	---@type ActivityData
	local ACData = self.ActivityModel:GetData(ActivityId)
	if not ACData then
		return
	end

	if not ACData:IsAvailble() then
		return
	end

	---@type ActivityUMGBinds
    local HandleBinds = ActivityDefine.ActivityUMGBinds[ACData.Type]
    if HandleBinds and HandleBinds.ViewID and HandleBinds.ViewID > 0 then
		MvcEntry:OpenView(HandleBinds.ViewID,{ActivityId = ActivityId})
	else
		if not EntryId and ACData.Entries and ACData.Entries:Length() > 0 then
			EntryId = ACData.Entries[1]
		end
		self:OpenActivityByEntry(EntryId, ActivityId)
    end
end

--- 测试
function ActivityCtrl:DumpActivity()
    if not ActivityCtrl.DEBUG then
        return
    end

	print_r(MvcEntry:GetModel(ActivityModel):GetDataList(), "ActivityModel:GetDataList")
	print_r(MvcEntry:GetModel(ActivityModel).BannerDataMap, "ActivityModel:BannerDataMap")
	print_r(MvcEntry:GetModel(ActivityModel).EntryDataMap, "ActivityModel:EntryDataMap")
end

function ActivityCtrl:TestOpenActivity()
    if not ActivityCtrl.DEBUG then
        return
    end
	local ActivityIdList = {
		24041100101,
		24041100201,
		24041200201,
		24041200501,
		24041600301,
		24041600401,
	}

	local Index = math.floor(math.random(1,6))
    MvcEntry:GetModel(ActivityModel):On_OpenActivityListSyn({
        ActivityIdList = {
            ActivityIdList[Index],
        }
    })
end

function ActivityCtrl:TestCloseActivity()
    if not ActivityCtrl.DEBUG then
        return
    end

	local ActivityIdList = {
		24041100101,
		24041100201,
		24041200201,
		24041200501,
		24041600301,
		24041600401,
	}
	local Index = math.floor(math.random(1,6))
    MvcEntry:GetModel(ActivityModel):On_CloseActivityListSyn({
        ActivityIdList = {
            ActivityIdList[Index],
        }
    })
end

