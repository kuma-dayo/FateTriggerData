local ConquestZoneFloatTipMinimapUI = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

--
function ConquestZoneFloatTipMinimapUI:OnInit()
	print("ConquestZoneFloatTipMinimapUI >> OnInit, ", GetObjectName(self))

	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.OccupyingPercentChanged,	        Func = self.OnOccupyingPercentChanged,     bCppMsg = true,	WatchedObject = nil },
		{ MsgName = GameDefine.MsgCpp.ZoneOwnerCampIdChanged,	        Func = self.OnZoneOwnerCampIdChanged,      bCppMsg = true,	WatchedObject = nil },
		{ MsgName = GameDefine.MsgCpp.ZoneStateChanged,	                Func = self.OnZoneStateChangedTag,         bCppMsg = true,	WatchedObject = nil },
		{ MsgName = GameDefine.MsgCpp.ZonePlayerChanged,	            Func = self.OnZonePlayerChangedTag,        bCppMsg = true,	WatchedObject = nil },
		{ MsgName = GameDefine.MsgCpp.OccupyingCampIdChanged,	        Func = self.OnOccupyingCampIdChanged,      bCppMsg = true,	WatchedObject = nil },
	}
	--小地图模式
	self.BP_ConquestStateWidget:ChangeShowMode(2)
	UserWidget.OnInit(self)


end

--
function ConquestZoneFloatTipMinimapUI:OnDestroy()
	print("ConquestZoneFloatTipMinimapUI >> OnDestroy, ", GetObjectName(self))
	
	UserWidget.OnDestroy(self)
end

function ConquestZoneFloatTipMinimapUI:BPNativeFunc_OnItemCustomUpdate(WhichMap, InTaskData)
    
    self.Zone = InTaskData.WatchedObj
	self.LocalPC = InTaskData.Owner

	self:InnerRefreshStateWidget(self.Zone)
end

function ConquestZoneFloatTipMinimapUI:BPNativeFunc_OnItemStartShow(WhichMap, InTaskData)
	self:BPNativeFunc_OnItemCustomUpdate(WhichMap, InTaskData)
	
end

function ConquestZoneFloatTipMinimapUI:InnerRefreshStateWidget(Zone)
	if self.Zone == Zone then
		self.BP_ConquestStateWidget:SetConquestData(self.Zone.ConquestZoneData)
	end
end
-----------------callback -----------------------------

function ConquestZoneFloatTipMinimapUI:OnOccupyingPercentChanged(Zone, NewPercent)
	--print("ConquestZoneFloatTipMinimapUI", ">> OnOccupyingPercentChanged Zone:", Zone:GetName(), "  percent:",NewPercent)
	
    self:InnerRefreshStateWidget(Zone)
end
function ConquestZoneFloatTipMinimapUI:OnZoneOwnerCampIdChanged(Zone, CampId)
	--print("ConquestZoneFloatTipMinimapUI", ">> OnZoneOwnerCampIdChanged Zone:", Zone:GetName(), "  campid:",CampId)
    self:InnerRefreshStateWidget(Zone)
end

function ConquestZoneFloatTipMinimapUI:OnZoneStateChangedTag(Zone,NewState)
	--print("ConquestZoneFloatTipMinimapUI", ">> OnZoneStateChangedTag Zone:", Zone:GetName(), "  State:",NewState)
    self:InnerRefreshStateWidget(Zone)

end
function ConquestZoneFloatTipMinimapUI:OnZonePlayerChangedTag(Zone)
	--print("ConquestZoneFloatTipMinimapUI", ">> OnZonePlayerChangedTag Zone:", Zone:GetName())
    self:InnerRefreshStateWidget(Zone)

end

function ConquestZoneFloatTipMinimapUI:OnOccupyingCampIdChanged(Zone,CampId)
	--print("ConquestZoneFloatTipMinimapUI", ">> OnZonePlayerChangedTag Zone:", Zone:GetName())
    self:InnerRefreshStateWidget(Zone)

end

return ConquestZoneFloatTipMinimapUI