local MapPanelCanvasItem = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function MapPanelCanvasItem:OnInit()
	print("MapPanelCanvasItem >> OnInit[Start], ...", GetObjectName(self))
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

	UserWidget.OnInit(self)
end

-- 获取地图控件大小
function MapPanelCanvasItem:GetImgMapSize()
	return self.ImgMap.Slot:GetSize()
end

-- 获取实际缩放比例(V2/V3)
function MapPanelCanvasItem:GetRealZoomV2()
	return UE.UMinimapManagerSystem.GetMinimapManagerSystem(self):GetCurMapZoom(self.MapType)
end

-- 获取缩放等级(额外缩放)
function MapPanelCanvasItem:GetZoomLevel()
	return UE.UMinimapManagerSystem.GetMinimapManagerSystem(self):GetCurMapZoomInfoParams(self.MapType).ZoomLevel
end

function MapPanelCanvasItem:GetMaxZoomLevel()
	return UE.UMinimapManagerSystem.GetMinimapManagerSystem(self):GetCurMapZoomInfoParams(self.MapType).MaxZoomLevel
end

function MapPanelCanvasItem:GetMinZoomLevel()
	return UE.UMinimapManagerSystem.GetMinimapManagerSystem(self):GetCurMapZoomInfoParams(self.MapType).MinZoomLevel
end

-- 转换成小地图坐标(V3)
function MapPanelCanvasItem:ToMinimapPoint(InWorldLoc)
	return UE.UMinimapManagerSystem.GetMinimapManagerSystem(self):ToMinimapPoint(self.MapType, InWorldLoc)
end

-- 获取父节点裁剪大小
function MapPanelCanvasItem:GetParentClipSize()
	return self.Slot.Parent.Slot:GetSize()
end

return MapPanelCanvasItem