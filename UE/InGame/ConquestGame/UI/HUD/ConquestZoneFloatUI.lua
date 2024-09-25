
local ConquestZoneFloatUI = Class("Common.Framework.UserWidget")

function ConquestZoneFloatUI:OnInit()
	print("ConquestZoneFloatUI >> OnInit, ", GetObjectName(self))

	self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.OccupyingPercentChanged,	        Func = self.OnOccupyingPercentChanged,     bCppMsg = true,	WatchedObject = nil },
		{ MsgName = GameDefine.MsgCpp.ZoneOwnerCampIdChanged,	        Func = self.OnZoneOwnerCampIdChanged,      bCppMsg = true,	WatchedObject = nil },
		{ MsgName = GameDefine.MsgCpp.ZoneStateChanged,	                Func = self.OnZoneStateChangedTag,         bCppMsg = true,	WatchedObject = nil },
		{ MsgName = GameDefine.MsgCpp.ZonePlayerChanged,	            Func = self.OnZonePlayerChangedTag,        bCppMsg = true,	WatchedObject = nil },
		{ MsgName = GameDefine.MsgCpp.OccupyingCampIdChanged,	        Func = self.OnOccupyingCampIdChanged,      bCppMsg = true,	WatchedObject = nil },
	}

	--浮标模式
	self.BP_ConquestStateWidget:ChangeShowMode(3)

	self.FloatTipRefreshTimer = Timer.InsertTimer(0.2, function()
		if self.Zone and self.LocalPC then
			self.BP_ConquestStateWidget:SetDistance(self.LocalPC,self.Zone)
		end
    end, true)

	UserWidget.OnInit(self)
end

function ConquestZoneFloatUI:OnDestroy()
	print("ConquestZoneFloatUI >> OnDestroy, ", GetObjectName(self))
	if self.FloatTipRefreshTimer then
        Timer.RemoveTimer(self.FloatTipRefreshTimer)
        self.FloatTipRefreshTimer = nil
    end
	UserWidget.OnDestroy(self)
end


function ConquestZoneFloatUI:OnShow()
    print("ConquestZoneFloatUI OnShow")
  
end

function ConquestZoneFloatUI:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark(Which3DMark, InTaskData)
    
    self.Zone = InTaskData.WatchedObj
	print("ConquestZoneFloatUI:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark:",GetObjectName(self),"WatchedObj:",GetObjectName(self.Zone))
	if self.LocalPC == nil then
		self.LocalPC = UE.UGameplayStatics.GetPlayerController(self.Zone, 0)
	end
	self.BP_ConquestStateWidget:SetDistance(self.LocalPC,self.Zone)
	self:InnerRefreshStateWidget(self.Zone)
end

function ConquestZoneFloatUI:BPImpFunc_On3DMarkIconStartShowFrom3DMark(Which3DMark, InTaskData)
	self.Zone = InTaskData.WatchedObj
	print("ConquestZoneFloatUI:BPImpFunc_On3DMarkIconStartShowFrom3DMark:",GetObjectName(self),"WatchedObj:",GetObjectName(self.Zone))
	if self.LocalPC == nil then
		self.LocalPC = UE.UGameplayStatics.GetPlayerController(self.Zone, 0)
	end
end


-----------------functions ----------------------


function ConquestZoneFloatUI:InnerRefreshStateWidget(Zone)
	if self.Zone == Zone then
		self.BP_ConquestStateWidget:SetConquestData(self.Zone.ConquestZoneData)
	end
end
-----------------callback -----------------------------

function ConquestZoneFloatUI:OnOccupyingPercentChanged(Zone, NewPercent)
	--print("ConquestZoneFloatUI", ">> OnOccupyingPercentChanged Zone:", Zone:GetName(), "  percent:",NewPercent)
	
    self:InnerRefreshStateWidget(Zone)
end
function ConquestZoneFloatUI:OnZoneOwnerCampIdChanged(Zone, CampId)
	--print("ConquestZoneFloatUI", ">> OnZoneOwnerCampIdChanged Zone:", Zone:GetName(), "  campid:",CampId)
    self:InnerRefreshStateWidget(Zone)
end

function ConquestZoneFloatUI:OnZoneStateChangedTag(Zone,NewState)
	--print("ConquestZoneFloatUI", ">> OnZoneStateChangedTag Zone:", Zone:GetName(), "  State:",NewState)
    self:InnerRefreshStateWidget(Zone)

end
function ConquestZoneFloatUI:OnZonePlayerChangedTag(Zone)
	--print("ConquestZoneFloatUI", ">> OnZonePlayerChangedTag Zone:", Zone:GetName())
    self:InnerRefreshStateWidget(Zone)

end

function ConquestZoneFloatUI:OnOccupyingCampIdChanged(Zone,CampId)
	--print("ConquestZoneFloatUI", ">> OnZonePlayerChangedTag Zone:", Zone:GetName())
    self:InnerRefreshStateWidget(Zone)

end

return ConquestZoneFloatUI