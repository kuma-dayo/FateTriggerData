local PlayerLine = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------




--
function PlayerLine:OnInit()
	print("PlayerLine >> OnInit, ", GetObjectName(self))
	self.CurTeamPos = 1
	UserWidget.OnInit(self)
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
end
--
function PlayerLine:OnDestroy()
	print("PlayerLine >> OnDestroy, ", GetObjectName(self))
	
	UserWidget.OnDestroy(self)
end


function PlayerLine:BPNativeFunc_OnItemCustomUpdate(WhichMap, InTaskData)
	local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
	BlackBoardKeySelector.SelectedKeyName = "TeamPos"
	local TeamPos, TeamPosType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(InTaskData.OtherData, BlackBoardKeySelector)

	if TeamPosType then
		self.CurTeamPos = TeamPos
	end

	self.CurRefPS = InTaskData.Owner
	--print("PlayerLine >> BPNativeFunc_OnItemCustomUpdate self.CurRefPS:", GetObjectName(self.CurRefPS), self.CurRefPS, GetObjectName(self))

	if not self.LocalPC then
		self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	end

	-- 是不是队友
	self.bIsTemmate = self.LocalPC and InTaskData.Owner ~= self.LocalPC.PlayerState

	local IfForceUpdate = InTaskData.TaskType == UE.EGMapItemTaskAction.ForceUpdate
	
	-- 确保不是强制刷新地图导致的图标更新
	if WhichMap == UE.EGMapItemShowOnWhichMap.MiniMap and not IfForceUpdate then
		local BuoysSystem = UE.UBuoysMarkManagerSystem.GetBuoysMarkManagerSystem(self)
		if BuoysSystem and InTaskData.RoutePositionArray:Length() > 0 then
			BuoysSystem:BPImpEvent_UpdateWorldEffects(InTaskData.Owner, InTaskData.RoutePositionArray:GetRef(1), true)
		end
		if self.CurRefPS then
			MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Mark_PlayLine, InTaskData.ItemKey, self.CurRefPS, self.bIsTemmate)
		end
	end
	

	local TeamPosColor
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
	if MiscSystem then
		TeamPosColor = MiscSystem.TeamColors:FindRef(self.CurTeamPos)
	end
	self.ImgNumber:SetColorAndOpacity(TeamPosColor)
	self.ImgNumberBg:SetColorAndOpacity(TeamPosColor)
	self.ImgDistImage:SetColorAndOpacity(TeamPosColor)
end

function PlayerLine:BPImpFunc_OnItemRemoveFromMap(WhichMap, InTaskData)
	if WhichMap == UE.EGMapItemShowOnWhichMap.MiniMap then
		local BuoysSystem = UE.UBuoysMarkManagerSystem.GetBuoysMarkManagerSystem(self)
		if BuoysSystem then
			BuoysSystem:BPImpEvent_UpdateWorldEffects(InTaskData.Owner, UE.FVector(), false)
		end
		if self.CurRefPS then
			MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Mark_PlayLineRemove, InTaskData.ItemKey, self.CurRefPS, self.bIsTemmate)
		end
	end
end


return PlayerLine
