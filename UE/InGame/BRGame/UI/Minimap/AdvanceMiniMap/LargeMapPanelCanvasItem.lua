local MapPanelCanvasItemClassName = "InGame.BRGame.UI.Minimap.AdvanceMiniMap.MapPanelCanvasItem"
local MapPanelCanvasItem = require(MapPanelCanvasItemClassName)
local LargeMapPanelCanvasItem = Class(MapPanelCanvasItemClassName)
local testProfile = require("Common.Utils.InsightProfile")


-------------------------------------------- Init/Destroy ------------------------------------

function LargeMapPanelCanvasItem:OnInit()
	print("LargeMapPanelCanvasItem >> OnInit[Start], ...", GetObjectName(self))
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.MsgList = {}
	table.insert(self.MsgList, { MsgName = GameDefine.Msg.LARGEMAP_MoveToAssignPos,			Func = self.UpdateMapOffsetPos })
	table.insert(self.MsgList, { MsgName = GameDefine.Msg.LARGEMAP_UpdateMapZoomLevel,		Func = self.UpdateMapZoomLevel })
	table.insert(self.MsgList, { MsgName = GameDefine.Msg.LARGEMAP_MoveToAssignPos,		Func = self.UpdateMapOffsetPos })

	-- if self.MsgList then
	-- 	table.insert(self.MsgList, { MsgName = GameDefine.Msg.LARGEMAP_MoveToAssignPos,			Func = self.UpdateMapOffsetPos })
	-- 	table.insert(self.MsgList, { MsgName = GameDefine.Msg.LARGEMAP_UpdateMapZoomLevel,		Func = self.UpdateMapZoomLevel })
	-- 	table.insert(self.MsgList, { MsgName = GameDefine.Msg.LARGEMAP_MoveToAssignPos,		Func = self.UpdateMapOffsetPos })
	-- else
	-- 	self.MsgList = {
	-- 		{ MsgName = GameDefine.Msg.LARGEMAP_UpdateMapZoomLevel,		Func = self.UpdateMapZoomLevel },
	-- 		{ MsgName = GameDefine.Msg.LARGEMAP_MoveToAssignPos,		Func = self.UpdateMapOffsetPos },
	-- 	}
	-- end
	--MsgHelper:RegisterList(self, self.MsgList)

	self.MinimapManager = UE.UMinimapManagerSystem.GetMinimapManagerSystem(self)
	
	self.MaxMarkRouteNum = 4

	MapPanelCanvasItem.OnInit(self)

	self.ShowNotifyTimer = nil
end

-- 是否有效初始化
function LargeMapPanelCanvasItem:IsValidInitData()
	return true
end

-- 获取地图控件大小
function LargeMapPanelCanvasItem:GetImgMapSize()
	return self.ImgMap.Slot:GetSize()
end

-- 获取实际缩放比例(V2/V3)
function LargeMapPanelCanvasItem:GetRealZoomV2()
	return UE.UMinimapManagerSystem.GetMinimapManagerSystem(self):GetCurMapZoom(self.MapType)
end

-- 转换成小地图坐标(V3)
function LargeMapPanelCanvasItem:ToMinimapPoint(InWorldLoc)
	return UE.UMinimapManagerSystem.GetMinimapManagerSystem(self):ToMinimapPoint(self.MapType, InWorldLoc)
end

-- 获取父节点裁剪大小
function LargeMapPanelCanvasItem:GetParentClipSize()
	return self.Slot.Parent.Slot:GetSize()
end


-- 是否是小地图
function LargeMapPanelCanvasItem:IsMinimapPanel()
	return false
end


function LargeMapPanelCanvasItem:UpdateMapOffsetPos(InMsgBody)
	if InMsgBody.NewOffsetPos then
		self.TrsMap.Slot:SetPosition(-InMsgBody.NewOffsetPos)
		print("LargeMapPanelCanvasItem >> UpdateMapOffsetPos", GetObjectName(self), "NewOffsetPos:",-InMsgBody.NewOffsetPos)
	end
end

function LargeMapPanelCanvasItem:GetZoomAmount()
	return 1
end


function LargeMapPanelCanvasItem:UpdateMapZoomLevel(InMsgBody)
	local NewZoomLevel = InMsgBody.NewZoomLevel
	local OldZoomLevel = self.ZoomLevel
	local IsZoomInOpt = InMsgBody.IsZoomIn

	if NewZoomLevel then
		if self.MinimapManager then
			self.MinimapManager:SetCurMapZoomAndUpdateMapIcon(self.MapType, NewZoomLevel, true)
		end
		--print("LargeMapPanelCanvasItem >> UpdateMapZoomLevel", GetObjectName(self), "OldZoomLevel:",OldZoomLevel, "NewZoomLevel:", NewZoomLevel)
	end

end



--
function LargeMapPanelCanvasItem:OnDestroy()
	print("LargeMapPanelCanvasItem >> OnDestroy, ...", GetObjectName(self))
	if self.ImgEventPanelImage then
		-- body
		self.ImgEventPanelImage.OnMouseButtonDoubleClickEvent:Unbind()
	end

	if(self.ShowNotifyTimer) then
		Timer.RemoveTimer(self.ShowNotifyTimer)
	end
	
	UserWidget.OnDestroy(self)
end

-- todo 观战的时候需要取到观战对象的坐标吗？
-- 获取当前玩家自己的世界坐标
function LargeMapPanelCanvasItem:GetPlayerLoction()
	local PlayerViewTarget = self:GetOwningPlayerViewTarget()
	local PlayerLoctionPos = nil
	if PlayerViewTarget == nil then
		print("LargeMapPanelCanvasItem >> GetPlayerLoction-->self:GetOwningPlayerViewTarget() Failed")
	else            
		PlayerLoctionPos = PlayerViewTarget:K2_GetActorLocation()
		print("LargeMapPanelCanvasItem >> GetPlayerLoction-->PlayerLoctionPos:(", PlayerLoctionPos.X, ", ", PlayerLoctionPos.Y,
		", ", PlayerLoctionPos.Z, ")")
	end
	return PlayerLoctionPos
end

-- 把地图移动到玩家自己的位置
function LargeMapPanelCanvasItem:MoveMapToMyself()
	local PlayerLocation = self:GetPlayerLoction()
	local PlayerLocMiniMap = self:ToMinimapPoint(PlayerLocation)
	local PlayerLoc2D = UE.FVector2D(PlayerLocMiniMap.X, PlayerLocMiniMap.Y) -- 此坐标系的原点位于右上角，因此坐标属于第三象限	
	local ImgMapSpacePos = PlayerLoc2D                                    -- ImgMapSpacePos的坐标系原点位于左下角，因此坐标属于第一象限

	self.ViewOffset = self:ApplyInRangeOffsetPos(PlayerLoc2D)
	self.ViewOffsetStart = self.ViewOffset

	local bPCPlatform = BridgeHelper.IsPCPlatform()
	if bPCPlatform == true then
		--local BuoysScreenPos, bSucc = UE.UGameplayStatics.ProjectWorldToScreen(self.LocalPC, TargetBuoysLoc, BuoysScreenPos, false)
		local MiniMapScreenPos, bSucc = UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(self.LocalPC,
		PlayerLocMiniMap, MiniMapScreenPos, true)
		if bSucc == true then
			--self.LocalPC:SetMouseLocation(math.floor(MiniMapScreenPos.X), math.floor(MiniMapScreenPos.Y))
			print("LargeMapPanelCanvasItem >> MoveMapToMyself-->MiniMapScreenPos:", MiniMapScreenPos)
		end
	end
end

function LargeMapPanelCanvasItem:SetParentPanel(CurParentPanel)
	print("LargeMapPanelCanvasItem >> LargeMapPanelCanvasItem CurParentPanel", GetObjectName(CurParentPanel))
	self.ParentPanel = CurParentPanel
end

function LargeMapPanelCanvasItem:AdvanceMarkRouteLine(MarkRoutes)
	local ADCMark = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
	if ADCMark then
		ADCMark:UpdateAdvancrMarkRouteLine(MarkRoutes)
	end
end

function LargeMapPanelCanvasItem:AdvanceMarkPlayLine(MarkRoutes)
	local ADCMark = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
	if ADCMark then
		ADCMark:UpdateAdvancrMarkPlayerLine(MarkRoutes)
	end
end

function LargeMapPanelCanvasItem:AdvanceMarkPreviewRouteLine(MarkRoutes)
	local ADCMark = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
	if ADCMark then
		ADCMark:UpdateAdvancrMarkPreviewRouteLine(MarkRoutes)
	end
end

return LargeMapPanelCanvasItem