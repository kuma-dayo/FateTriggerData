require ("InGame.BRGame.ItemSystem.RespawnSystemHelper")

local RebornPointMapWidget = Class("Common.Framework.UserWidget")


RebornPointMapWidget.LastStartWidget = -1


-------------------------------------------- Init/Destroy ------------------------------------


--
function RebornPointMapWidget:OnInit()
	print("RebornPointMapWidget >> OnInit, ", GetObjectName(self))

	-- 是否选中
	self.IfIsOnFouced = false
	
	self.MiniMapManager = UE.UMinimapManagerSystem.GetMinimapManagerSystem(self)

	self.RebornCDTime = 10

	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
   	self.RefPS = UE.UPlayerStatics.GetCPS(self.LocalPC)

	self.CurPressedSpaceTime = 0
	self.PressedLongHoldTime = self.PressedLongHoldTime or 1.5
	self.PressedSpaceInter = self.PressedSpaceInter or 0.05

	print("RebornPointMapWidget >> OnInit self.Button_RebornSimulate:", GetObjectName(self.Button_RebornSimulate), GetObjectName(self))

	self.BindNodes ={
		{ UDelegate = self.Button_RebornSimulate.OnClicked, Func = self.OnSelfClicked },
    }

	local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	if LocalPC then self.LocalPS = UE.UPlayerStatics.GetCPS(LocalPC) end

	self.bSelectedPoint = false
	self.TimerHandle = Timer.InsertTimer(Timer.NEXT_TICK, function()
		self.TimerHandle = nil
		self:SetFirstSelectPoint()
	end, false)
	self.CachedRebornNum = 0
	UserWidget.OnInit(self)
end

function RebornPointMapWidget:OnDestroy()
	if self.TimerHandle then Timer.RemoveTimer(self.TimerHandle) end
    self.TimerHandle = nil
end

function RebornPointMapWidget:BPNativeFunc_UpdateRespawnCharacterNum()

	if self.SelectPlayerNumAppearance then
		local LocalMarkRouteNum = self.SelectPlayerNumAppearance:Length()
		if LocalMarkRouteNum > 0 then
			local StyleFlags = 1
			for index = 1, LocalMarkRouteNum do
				local CurNum = self.SelectPlayerNumAppearance:GetRef(index)
				if CurNum <= self.RespawnCharacterNum then
					StyleFlags = StyleFlags + 1
				else
					break
				end
			end

			self:RemoveAllActiveWidgetStyleFlags()
			self:AddActiveWidgetStyleFlags(StyleFlags)
		else
			self:RemoveAllActiveWidgetStyleFlags()
			self:AddActiveWidgetStyleFlags(0)
		end
	end
end

function RebornPointMapWidget:SetFirstSelectPoint()
	print("RebornPointMapWidget>>SetFirstSelectPoint")
	self.bSelectedPoint = true
end

function RebornPointMapWidget:OnSelfClicked()
	self.bSelectedPoint = true
	self:VXE_HUD_Reborn_Selected()
end

function RebornPointMapWidget:BPNativeFunc_UpdateTeamCharacterChooseTower()
	--print("RebornPointMapWidget >> BPNativeFunc_UpdateTeamCharacterChooseTower, ", GetObjectName(self))

	if self.WBP_RebornTeamStateWidget then	
		if self.SelectPlayerTeamPos then
			local LocalMarkRouteNum = self.SelectPlayerTeamPos:Length()
			if LocalMarkRouteNum > 0 then
				local bPlayerSelect = false
				if self.LocalPS then
					local CurTeamPos = BattleUIHelper.GetTeamPos(self.LocalPS)
					for _, v in pairs(self.SelectPlayerTeamPos) do
						if v ~= nil and v == CurTeamPos then 
							self:VXE_HUD_Reborn_Selected()
							bPlayerSelect = true
						end
					end
					if not bPlayerSelect then self:VXE_HUD_Reborn_Unselect() end
				end
		
				if self.Image_Default then
					self.Image_Default:SetVisibility(UE.ESlateVisibility.Collapsed)
				end
				
				--根据队伍编号播放选点动画
				if LocalMarkRouteNum > self.CachedRebornNum and self.bSelectedPoint == true then
					if LocalMarkRouteNum == 1 then self:VXE_HUD_Reborn_Choose_01() end
					if LocalMarkRouteNum == 2 then self:VXE_HUD_Reborn_Choose_12() end
					if LocalMarkRouteNum == 3 then self:VXE_HUD_Reborn_Choose_23() end
					if LocalMarkRouteNum == 4 then self:VXE_HUD_Reborn_Choose_34() end
				end
				self.WBP_RebornTeamStateWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				self.WBP_RebornTeamStateWidget:RemoveAllActiveWidgetStyleFlags()
				self.WBP_RebornTeamStateWidget:AddActiveWidgetStyleFlags(LocalMarkRouteNum - 1)
				self.CachedRebornNum = LocalMarkRouteNum

				for index = 1, LocalMarkRouteNum do
					local TeamPos = self.SelectPlayerTeamPos:GetRef(index)
					local CurName = self.WBP_RebornTeamStateWidget.RebornTeamWidgetName..tostring(index)

					print("RebornPointMapWidget >> BPNativeFunc_UpdateTeamCharacterChooseTower TeamPos is", TeamPos, GetObjectName(self))

					local CurRebornWidget = self.WBP_RebornTeamStateWidget:GetWidgetByName(CurName)
					
					if CurRebornWidget then
						CurRebornWidget.TeamText = StringUtil.ConvertString2FText(TeamPos)--tostring(TeamPos)
						--print("RebornPointMapWidget >> BPNativeFunc_UpdateTeamCharacterChooseTower CurRebornWidget is", GetObjectName(CurRebornWidget), GetObjectName(self))
						CurRebornWidget:SetTeamText(TeamPos)
					end
				end
			else
				self:VXE_HUD_Reborn_Unselect()
				self.CachedRebornNum = 0		
				if self.Image_Default then
					self.Image_Default:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				end
				self.WBP_RebornTeamStateWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
			end
		end
		self.bSelectedPoint = false
	end
end

return RebornPointMapWidget
