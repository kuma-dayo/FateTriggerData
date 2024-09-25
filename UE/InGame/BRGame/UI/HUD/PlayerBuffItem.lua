--
-- 战斗界面Buff - 控件
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.28
--

local PlayerBuffItem = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function PlayerBuffItem:OnInit()
    --print("PlayerBuffItem", ">> OnInit, ...", GetObjectName(self))
    
	UserWidget.OnInit(self)
end

function PlayerBuffItem:OnDestroy()
    --print("PlayerBuffItem", ">> OnDestroy, ...", GetObjectName(self))

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function PlayerBuffItem:InitData(InBuffObject)
	local bShowBuff = InBuffObject and InBuffObject.bShowHUD
	local NewVisible = bShowBuff and
		UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
	self:SetVisibility(NewVisible)

	if bShowBuff then
		local BuffTags = InBuffObject.BuffTag.CombinedTags.GameplayTags
		local BuffTag = (BuffTags:Length() > 0) and BuffTags:Get(1) or nil
		local BuffTagName = BuffTag and BuffTag.TagName or nil
		local BuffData = BattleUIHelper.GetBuffConfig(BuffTagName)
		if BuffData then
			--local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(BuffData.Image)
			self.ImgIcon:SetBrushFromSoftTexture(BuffData.Image, false)
		else
			--self.ImgIcon:SetBrushFromTexture(self.TextureNone, false)
		end

		local TimeSeconds = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
		self.TotalTime = InBuffObject.Duration
		self.CurTime = math.max(0, self.TotalTime - (TimeSeconds - InBuffObject.BeginPlayTime))
		self:UpdateProgress(0)

		print("PlayerBuffItem", ">> InitData[ok], ", BuffTagName, self.CurTime, self.TotalTime)
	end
end

function PlayerBuffItem:UpdateProgress(InDeltaTime)
	if (not self.CurTime) or (not self.TotalTime) or (self.CurTime < 0) then
		return
	end
	self.CurTime = self.CurTime - InDeltaTime

	local CurProgress = math.max(0, self.CurTime / self.TotalTime)
	self.ImgProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", CurProgress)
end

-------------------------------------------- Callable ------------------------------------

-- 
function PlayerBuffItem:TickImpl(MyGeometry, InDeltaTime, bForceUpdate)
	self:UpdateProgress(InDeltaTime)
end

return PlayerBuffItem
