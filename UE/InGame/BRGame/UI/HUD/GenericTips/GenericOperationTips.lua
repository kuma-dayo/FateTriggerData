--
-- 战斗界面控件 - 通用操作提示
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.30
--

require ("InGame.BRGame.UI.HUD.BattleUIHelper")

local ECountdownType = BattleUIHelper.ECountdownType

local GenericOperationTips = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function GenericOperationTips:OnInit()
	-- 
	self.WidgetInfos = {}
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    self:InitPlayerPawnInfo()
    
    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,			Func = self.OnLocalPCUpdatePawn, 	bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.PLAYER_GenericUseTips,		Func = self.OnGenericUseTips,		bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.PLAYER_GenericItemUseTips,	Func = self.OnGenericUseTips,		bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.PLAYER_GenericSkillUseTips,	Func = self.OnGenericSkillUseTips,	bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.PLAYER_GenericGuideTips,		Func = self.OnGenericGuideTips,		bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.PLAYER_GenericSkillTips,		Func = self.OnGenericIconTips,		bCppMsg = true,	WatchedObject = nil },
	}

	UserWidget.OnInit(self)
end

function GenericOperationTips:OnDestroy()
    MsgHelper:UnregisterList(self, self.MsgList_DyingRescue or {})

	-- 销毁删除数据(WidgetPools)
	for WidgetKey, WidgetInfo in pairs(self.WidgetInfos or {}) do
		if WidgetInfo and WidgetInfo.Widget then
			WidgetInfo.Widget:RemoveFromParent()
			WidgetInfo.Widget = nil
		end
	end
	self.WidgetInfos = nil

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function GenericOperationTips:InitData(InParamerters)
	
end

function GenericOperationTips:InitPlayerPawnInfo()
	local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
	if LocalPCPawn then
        MsgHelper:UnregisterList(self, self.MsgList_DyingRescue or {})
        self.MsgList_DyingRescue = {
            -- 濒死/救援
			--{ MsgName = GameDefine.MsgCpp.PLAYER_OnBeginRescue,         Func = self.OnBeginRescue,          bCppMsg = true, WatchedObject = LocalPCPawn },
			--{ MsgName = GameDefine.MsgCpp.PLAYER_OnEndRescue,           Func = self.OnEndRescue,            bCppMsg = true, WatchedObject = LocalPCPawn },
			--{ MsgName = GameDefine.MsgCpp.PLAYER_OnRescueActorChanged,  Func = self.OnRescueActorChanged,   bCppMsg = true, WatchedObject = LocalPCPawn },
        }
        MsgHelper:RegisterList(self, self.MsgList_DyingRescue)
    end
end

-- 更新提示
function GenericOperationTips:UpdateGenericTips(InWidgetKey, bEnable, InParamerters)
	print("GenericOperationTips", ">> UpdateGenericTips", InWidgetKey, bEnable, InParamerters)
	if (not InWidgetKey) or ('' == InWidgetKey) then return end

	local WidgetInfo = self.WidgetInfos[InWidgetKey]
	if (not bEnable) then	-- Force Destroy
		if WidgetInfo and WidgetInfo.Widget then
			WidgetInfo.Widget:RemoveFromParent()
			WidgetInfo.Widget = nil
		end
		return
	end

	if (not WidgetInfo) or (not WidgetInfo.Widget) then
		local NewWidget = GenericTipsHelper.CreateSubWidget(self, InWidgetKey)
		if NewWidget then
			WidgetInfo = { Widget = NewWidget, }
			self.WidgetInfos[InWidgetKey] = WidgetInfo
		end
	end
	if WidgetInfo and WidgetInfo.Widget then
		-- GenericIconTipsItem:InitData
		WidgetInfo.Widget:InitData(InParamerters)
		return WidgetInfo
	end
end

-------------------------------------------- Callable ------------------------------------

-- 
function GenericOperationTips:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
	--print("GenericOperationTips", ">> OnLocalPCUpdatePawn, ", GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InPCPwn))

	if self.LocalPC == InLocalPC then
		self:InitPlayerPawnInfo()
	end
end

-- 通用提示(使用)
function GenericOperationTips:OnGenericUseTips(InInstigator, bEnable, bIncremental, InMaxValue, InText)
	print("GenericOperationTips", ">> OnGenericUseTips[Start], ", 
		GetObjectName(InInstigator), bEnable, bIncremental, InMaxValue, InText)

	local CountdownType = bIncremental and
		ECountdownType.NumberAdd_ProgressAdd or ECountdownType.NumberLess_ProgressLess
	local InParamerters = {
		bEnable = bEnable, CountdownType = CountdownType, MaxValue = InMaxValue, Text = InText,
	}
	-- GenericUseTipsItem:InitData
	self:UpdateGenericTips("Generic.UseTips", bEnable, InParamerters)
end

-- 通用提示(按键指南)
function GenericOperationTips:OnGenericGuideTips(InInstigator, bEnable, InTextKey, InTextTips, InTopTips1, InTopTips2)
	print("GenericOperationTips", ">> OnGenericGuideTips[Start], ", 
		 GetObjectName(InInstigator), bEnable, InTextKey, InTextTips, InTopTips1, InTopTips2)
	
	local InParamerters = {
		bEnable = bEnable,
		TextKey = InTextKey, TextTips = InTextTips, 
		TopTips1 = InTopTips1, TopTips2 = InTopTips2,
	}
	-- GenericGuideTipsItem:InitData
	self:UpdateGenericTips("Generic.GuideTips", bEnable, InParamerters)
end

-- 通用提示Icon
function GenericOperationTips:OnGenericIconTips(InInstigator, InWidgetKey, bEnable, InIconAsset, InTextTips, InLinearColor)
	print("GenericOperationTips", ">> OnGenericIconTips[Start], ", 
		 GetObjectName(InInstigator), InWidgetKey, bEnable, InIconAsset, InTextTips, InLinearColor)

	local InParamerters = {
		bEnable = bEnable, IconAsset = InIconAsset, TextTips = InTextTips, LinearColor = InLinearColor,
	}
	-- GenericIconTipsItem:InitData
	local WidgetKey = (InWidgetKey and ('' ~= InWidgetKey)) and InWidgetKey or "Generic.IconTips"
	self:UpdateGenericTips(WidgetKey, bEnable, InParamerters)
end

-- 通用使用提示(技能)
function GenericOperationTips:OnGenericSkillUseTips(InInstigator, InWidgetKey, bEnable, bIsCasting, InIconAsset, InMaxValue)
	print("GenericOperationTips", ">> OnGenericIconTips[Start], ", 
		 GetObjectName(InInstigator), InWidgetKey, bEnable, bIsCasting, InIconAsset, InMaxValue)

	local InParamerters = {
		bEnable = bEnable, bIsCasting = bIsCasting,
		IconAsset = InIconAsset, MaxValue = InMaxValue,
		CountdownType = ECountdownType.NumberLess_ProgressAdd, 
	}
	local WidgetKey = (InWidgetKey and ('' ~= InWidgetKey)) and InWidgetKey or "Generic.SkillUseTips"
	local WidgetInfo = self:UpdateGenericTips(WidgetKey, bEnable, InParamerters)
end

-- 被救援中
function GenericOperationTips:OnBeginRescue(InRescueMessageInfo)
    print("GenericOperationTips", ">> OnBeginRescue, ", InRescueMessageInfo.RescueInfo.RescueTime)
	local RescueTime = InRescueMessageInfo.RescueInfo.RescueTime
	local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "RescueTips_DoRescue")
	local InParamerters = {
		bEnable = true, bEnableDoing = true,
		CountdownType = ECountdownType.NumberLess_ProgressAdd,
		MaxValue = RescueTime, Text = (TextStr or "DoRescue..."),
	}
	self:UpdateTips_RescueProgress(InParamerters)
end

-- 被救援结束
function GenericOperationTips:OnEndRescue(InRescueMessageInfo)
    print("GenericOperationTips", ">> OnEndRescue, ", InRescueMessageInfo.RescueInfo.EndReason)

	local InParamerters = {
		bEnable = false, bRescueBreak = (InRescueMessageInfo.RescueInfo.EndReason ~= UE.ES1RescueEndReason.RescueCompleted),
	}
	self:UpdateTips_RescueProgress(InParamerters)
end

-- 被救援进度
function GenericOperationTips:UpdateTips_RescueProgress(InParamerters)
	local WidgetInfo = self:UpdateGenericTips("Generic.RescueTips", true, InParamerters)
	if WidgetInfo and WidgetInfo.Widget then
		-- GenericRescueTipsItem:UpdateRescueProgress
		WidgetInfo.Widget:UpdateRescueProgress(InParamerters)
	end
end

-- 主动的救援提示
function GenericOperationTips:OnRescueActorChanged(InRescueActor)
    print("GenericOperationTips", ">> OnRescueActorChanged, ", GetObjectName(InRescueActor))
	
	-- 救援按键提示
	local bEnableTips = (nil ~= InRescueActor)
	local WidgetInfo = self:UpdateGenericTips("Generic.RescueTips", true, nil)
	if WidgetInfo and WidgetInfo.Widget then
		-- GenericRescueTipsItem:UpdateRescueTips
		WidgetInfo.Widget:UpdateRescueTips(bEnableTips)
	end
end

return GenericOperationTips
