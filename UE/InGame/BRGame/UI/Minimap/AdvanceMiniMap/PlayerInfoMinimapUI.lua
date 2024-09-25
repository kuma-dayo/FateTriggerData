local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")
local MiniMapOrdinaryItemClassName = "InGame.BRGame.UI.Minimap.AdvanceMiniMap.MiniMapOrdinaryItem"
local MiniMapOrdinaryItem = require(MiniMapOrdinaryItemClassName)
local PlayerInfoMinimapUI = Class(MiniMapOrdinaryItemClassName)


-------------------------------------------- Init/Destroy ------------------------------------

function PlayerInfoMinimapUI:OnInit()
	print("PlayerInfoMinimapUI >> OnInit, ", GetObjectName(self))

	self.ImgFire:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.ImgRide:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.TrsOffline:SetVisibility(UE.ESlateVisibility.Collapsed)

	self.OffsetRot = 90
	self.CurSlateColor = UE.FSlateColor()

	self:UpdateWidgetColor()

	-- 临时处理编辑器报错，等本地复现了，用正是方案再修改
	AdvanceMarkHelper.InitData(self)
	MiniMapOrdinaryItem.OnInit(self)
end

function PlayerInfoMinimapUI:OnDestroy()
	print("PlayerInfoMinimapUI >> OnDestroy, ", GetObjectName(self))

	MiniMapOrdinaryItem.OnDestroy(self)
end

--[[
function PlayerInfoMinimapUI:IfCanUpdateState(PawnStateName)
	-- 死亡后就不能再接受到其他状态
    if "Normal" == self.CurPawnStateName and "Normal" == PawnStateName then
		return false
	end

	if "Dead" == self.CurPawnStateName and "Dead" == PawnStateName then
		return false
	end

	-- if "Dying" == self.CurPawnStateName and "Dying" == PawnStateName then
	-- 	return false
	-- end
	 
	if "Dead" == self.CurPawnStateName and "Normal" ~= PawnStateName and "GeneRespawnUpdate" ~= PawnStateName and "Dead" ~= PawnStateName then
		print("PlayerInfoMinimapUI >> SetPlayerStateInfo Cannot OldPawnStateName is Dead, PawnStateName is", PawnStateName)
		return false
	end

	return true
end

function PlayerInfoMinimapUI:BPImpFunc_SetPlayerStateInfo(PawnStateName, bIfForce)
	if not bIfForce and false == self:IfCanUpdateState(PawnStateName) then
		return
	end

	
	if "Normal" == PawnStateName then
		self:UpdateWidgetColor()
		self:IsDriveCar(false)
		self:IsOffLine(false)
	elseif "Dead" == PawnStateName then
		self:IsDriveCar(false)
		self:IsDead(true)
	elseif "Dying" == PawnStateName or "RescueStart" == PawnStateName or "RescueStop" == PawnStateName then
		self:IsDriveCar(false)
		self:IsDying(true)
	elseif "Vehicle" == PawnStateName then
		self:IsDriveCar(true)
	elseif "Fire" == PawnStateName then
		-- self:UpdateWidgetFire()
	elseif "OffLine" == PawnStateName then
		self:IsOffLine(true)
	elseif "GeneRespawnUpdate" == PawnStateName then
		-- 进入基因提取状态，那么角色一定已经死亡了，地图图标设置成和死亡状态一样的
		local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
		BlackBoardKeySelector.SelectedKeyName = "RespawnGeneExState"

		local RespawnGeneExState, RespawnGeneExStateType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(self.TaskData.OtherData, BlackBoardKeySelector)

		if RespawnGeneExStateType then
			--if UE.ERespawnGeneState.FinishDeployed == RespawnGeneExState then
			-- 可能先收到基因部署成功的消息，后收到正在基因部署的消息。所以直接判断角色存活
			if self.CurRefPS then
				local IfAlive = self.CurRefPS:IsAlive()
				if IfAlive or UE.ERespawnGeneState.Default == RespawnGeneExState then
					self:BPImpFunc_SetPlayerStateInfo("Normal", self.CurRefPS)
				else
					self:BPImpFunc_SetPlayerStateInfo("Dead", self.CurRefPS)
				end
			end
		end
	else
		self:UpdateWidgetColor()
		self:IsDriveCar(false)
		self:IsOffLine(false)
	end

	self.CurPawnStateName = PawnStateName

end
]]--

function PlayerInfoMinimapUI:UpdateWidgetColor(InLinearColor)
	local TeamPosColor
	if not AdvanceMarkHelper.TeamPosColor then
		AdvanceMarkHelper.InitData(self)
	end
	if nil ==  InLinearColor and AdvanceMarkHelper.TeamPosColor then
		TeamPosColor = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)
	end
	self.NewLinearColor = InLinearColor or TeamPosColor
	self.ImgBg:SetColorAndOpacity(self.NewLinearColor)
	self.ImgDir:SetColorAndOpacity(self.NewLinearColor)
	self.ImgOfflineBg:SetColorAndOpacity(self.NewLinearColor)
	self.ImgRide:SetColorAndOpacity(self.NewLinearColor)
	if self.CurSlateColor then
		self.CurSlateColor.SpecifiedColor = self.NewLinearColor
		self.TxtNumber:SetColorAndOpacity(self.CurSlateColor)
	else
		self.TxtNumber:SetColorAndOpacity(UIHelper.ToSlateColor_LC(self.NewLinearColor))
	end

	self.ImgFire:SetColorAndOpacity(self.NewLinearColor)
end

--[[
function PlayerInfoMinimapUI:IsDying(bIfDying)
	-- 倒地
	if bIfDying then
		if AdvanceMarkHelper.MarkIconColor then
			local NewLinearColor = AdvanceMarkHelper.MarkIconColor:FindRef("Dying")
			if not NewLinearColor then
				print("PlayerInfoMinimapUI >> IsDying AdvanceMarkHelper.MarkIconColor:FindRef(Dying) is nil", GetObjectName(self))
			end
			self:UpdateWidgetColor(NewLinearColor)
		end
	else
		self:UpdateWidgetColor()
	end
end

function PlayerInfoMinimapUI:IsDead(bIfDead)
	-- 死亡
	if bIfDead then
		if AdvanceMarkHelper.MarkIconColor then
			local NewLinearColor = AdvanceMarkHelper.MarkIconColor:FindRef("Dead")
			if not NewLinearColor then
				print("PlayerInfoMinimapUI >> IsDead AdvanceMarkHelper.MarkIconColor:FindRef(IsDead) is nil", GetObjectName(self))
			end
			self:UpdateWidgetColor(NewLinearColor)
		end
	else
		self:UpdateWidgetColor()
	end
end

-- 开火状态
function PlayerInfoMinimapUI:UpdateWidgetFire()
	self:SimplePlayAnimationByName("Anim_Fire", false)
end

function PlayerInfoMinimapUI:IsOffLine(bIsOffline)
	self.TrsState:SetVisibility(bIsOffline and
		UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible)
	self.TrsOffline:SetVisibility(bIsOffline and
		UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function PlayerInfoMinimapUI:IsDriveCar(IsDrive)
	self.TxtNumber:SetVisibility(IsDrive and
		UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible)
	self.ImgRide:SetVisibility(IsDrive and
		UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
end



function PlayerInfoMinimapUI:BPImpFunc_UpdateTeamPos()
	-- 队友低层级
	if self.bTeammate then
		if self.Slot and self.CurTeamPos then
			self.Slot:SetZOrder(self.WidgetUpdateInfo.ZOrder - self.CurTeamPos)
		end

		self.TrsViewDir:SetVisibility(UE.ESlateVisibility.Collapsed)

		-- 移除毒圈提示
		if self.ImgPlayzoneDist then
			self.ImgPlayzoneDist:RemoveFromParent()
			self.ImgPlayzoneDist = nil
		end
	else
		self.TrsViewDir:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
	end

	self.TxtNumber:SetText(self.CurTeamPos)
	-- 更新队友的颜色
	self:UpdateWidgetColor()
end
]]--

-- 更新安全区信息
-- function PlayerInfoMinimapUI:BPImpFunc_UpdatePlayzoneInfo(bImgPlayzoneDistCollapsed, bForceUpdate, ToPlayzoneDist, PlayzoneDist, CurRealZoomV2)
-- 	-- 队友低层级

-- 	if not self.ImgPlayzoneDist then
-- 		return
-- 	end

-- 	if (bImgPlayzoneDistCollapsed and PlayzoneDist > 0) then
-- 		if bForceUpdate or (self.ToPlayzoneDist ~= ToPlayzoneDist) then
-- 			self.ToPlayzoneDist = ToPlayzoneDist
-- 			local CurSize = self.ImgPlayzoneDist.Slot:GetSize()
-- 			CurSize.Y = ToPlayzoneDist * CurRealZoomV2.Y

-- 			self.ImgPlayzoneDist.Slot:SetSize(CurSize)
-- 			if self.Slot then
-- 				self.Slot:SetSize(CurSize)
-- 			end

-- 			-- 设置长宽比，防止材质被拉长
-- 			self.ImgPlayzoneDist:GetDynamicMaterial():SetScalarParameterValue("Density", (CurSize.Y / CurSize.X) / 10 )
-- 			CurSize.X = CurSize.Y
-- 			if self.Slot then
-- 				self.Slot:SetSize(CurSize * 2.25)
-- 			end
-- 		end

-- 		local DirVector = self.SelfPlayerLoc - self.SelfPlayzoneCenter
-- 		if bForceUpdate or (self.DirVector ~= DirVector) then
-- 			self.DirVector = DirVector
-- 			local NewAngle = self.DirVectorRot.Yaw - self.OffsetRot
-- 			self.ImgPlayzoneDist:SetRenderTransformAngle(NewAngle)
-- 		end

-- 		self.ImgPlayzoneDist:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
-- 	else
-- 		self.ImgPlayzoneDist:SetVisibility(UE.ESlateVisibility.Collapsed)
-- 	end
-- end

-- function PlayerInfoMinimapUI:BPImpFunc_IsAdsorbItem(IfAdsorbItem)
-- 	self.ImgBg:SetVisibility(IfAdsorbItem and
-- 		UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible)

-- 	if IfAdsorbItem then
-- 		local CurRot = UE.UKismetMathLibrary.Conv_VectorToRotator(self.WidgetUpdateInfo.ToMapPos)
-- 		local NewAngle = self.CurRot.Yaw + self.OffsetRot

-- 		self.TrsActorDir:SetRenderTransformAngle(NewAngle)
-- 		self.Slot:SetPosition(self.CurDisplayPos)
-- 	elseif UE.UKismetSystemLibrary.IsValid(self.ParentMapWidgetPanel) and self.ParentMapWidgetPanel:IsMinimapPanel() then --假如在小地图上，没吸附到边缘时，需要复原原来的位置
-- 		if self.Slot then
-- 			-- body
-- 			self.Slot:SetPosition(UE.FVector2D(self.WidgetUpdateInfo.ToMapPos.X, self.WidgetUpdateInfo.ToMapPos.Y))
-- 		end
-- 	end
-- end


return PlayerInfoMinimapUI