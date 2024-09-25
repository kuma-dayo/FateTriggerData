
local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysCommUI"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local BuoysCommUI = require(ParentClassName)
local BuoysChipUI = Class(ParentClassName)

local Collapsed = UE.ESlateVisibility.Collapsed
local SelfHitTestInvisible = UE.ESlateVisibility.SelfHitTestInvisible

function BuoysChipUI:OnInit()
	print("BuoysChipUI >> OnInit, ", GetObjectName(self))
	BuoysCommUI.OnInit(self)
end

function BuoysChipUI:OnDestroy()
	print("BuoysChipUI >> OnDestroy ", GetObjectName(self))
end

function BuoysChipUI:OnAnimationFinished(Animation)
    if Animation == self.vx_chipmask_out then
		self:SetVisibility(Collapsed)
	elseif Animation == self.vx_chipmask_in then
		
    end
end

function BuoysChipUI:BPImpFunc_OnCheckSetVisibility()
	-- body
	self:SetVisibility(SelfHitTestInvisible)
	self:VXE_Chip_Mask_In()
end

function BuoysChipUI:BPImpFunc_OnCheckSetCollapsed()
	-- body
	self:VXE_Chip_Mask_Out()
end

-- 挪到cpp中
-- function BuoysChipUI:BPImpFunc_OnTick3DMarkIconCustomUpdateFrom3DMark()
--     self:UpdateBuoysDir(self.OffsetRot.Yaw)
-- end

-- function BuoysChipUI:UpdateBuoysDir(InRotYaw)
-- 	if(self.bIfAdsorb) then
-- 		self.ScreenEdge:SetVisibility(SelfHitTestInvisible)
-- 		self.ScreenCenter:SetVisibility(Collapsed)
-- 	else
-- 		self.ScreenEdge:SetVisibility(Collapsed)
-- 		self.ScreenCenter:SetVisibility(SelfHitTestInvisible)
-- 	end
-- end

function BuoysChipUI:SetChipScreenOffset(InOffset)
	if not self.AbsorbOffSet then return end
	self.AbsorbOffSet.OffsetVec.X = InOffset.X
	self.AbsorbOffSet.OffsetVec.Y = InOffset.Y
	if InOffset.Z ~= 0 then self.AbsorbOffSet.OffsetVec.Z = InOffset.Z end
end

return BuoysChipUI