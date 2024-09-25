local MiniMapTips = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------




--
function MiniMapTips:OnInit()
	print("MiniMapTips", ">> OnInit, ", GetObjectName(self))
	
	UserWidget.OnInit(self)
end
--
function MiniMapTips:OnDestroy()
	print("MiniMapTips", ">> OnDestroy, ", GetObjectName(self))
	
	UserWidget.OnDestroy(self)
end

function MiniMapTips:BPNativeFunc_OnItemStartShow(WhichMap, InTaskData)

	self.Actor = InTaskData.WatchedObj
	if self.Actor  then
		self.TxtLevel = self.Actor.TxtLevel
		local OpTxtWidget = (MinimapHelper.EMapNameLevel.L1 == self.TxtLevel) and self.TxtNameL1 or self.TxtNameL2
		if OpTxtWidget then
			OpTxtWidget:SetText(self.Actor.TxtTips)
			OpTxtWidget:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
		end
	end

end

return MiniMapTips


