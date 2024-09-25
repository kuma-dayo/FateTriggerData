local ParentName = "InGame.BRGame.UI.Minimap.AdvanceMiniMap.LargeMapPanelCanvasItem"
local LargeMapPanelCanvasItem = require(ParentName)
local LargeMapPanelCanvasItemPC = Class(ParentName)
local testProfile = require("Common.Utils.InsightProfile")


-------------------------------------------- Init/Destroy ------------------------------------

function LargeMapPanelCanvasItemPC:OnInit()
	print("LargeMapPanelCanvasItemPC >> OnInit[Start], ...", GetObjectName(self))
	LargeMapPanelCanvasItem.OnInit(self)

	table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.PC_Input_DelMapMark, Func = self.OnDelMapMark, bCppMsg = true, WatchedObject = self.LocalPC})
	MsgHelper:RegisterList(self, self.MsgList)
end

-- 是否有效初始化
function LargeMapPanelCanvasItemPC:IsValidInitData()
	return true
end

-- 获取地图控件大小
function LargeMapPanelCanvasItemPC:GetImgMapSize()
	return self.ImgMap.Slot:GetSize()
end

-- 获取实际缩放比例(V2/V3)
function LargeMapPanelCanvasItemPC:GetRealZoomV2()
	return UE.UMinimapManagerSystem.GetMinimapManagerSystem(self):GetCurMapZoom(self.MapType)
end

-- 转换成小地图坐标(V3)
function LargeMapPanelCanvasItemPC:ToMinimapPoint(InWorldLoc)
	return UE.UMinimapManagerSystem.GetMinimapManagerSystem(self):ToMinimapPoint(self.MapType, InWorldLoc)
end

-- 获取父节点裁剪大小
function LargeMapPanelCanvasItemPC:GetParentClipSize()
	return self.Slot.Parent.Slot:GetSize()
end


-- 是否是小地图
function LargeMapPanelCanvasItemPC:IsMinimapPanel()
	return false
end


function LargeMapPanelCanvasItemPC:UpdateMapOffsetPos(InMsgBody)
	if InMsgBody.NewOffsetPos then
		self.TrsMap.Slot:SetPosition(-InMsgBody.NewOffsetPos)
		print("LargeMapPanelCanvasItemPC >> UpdateMapOffsetPos", GetObjectName(self), "NewOffsetPos:",-InMsgBody.NewOffsetPos)
	end
end


function LargeMapPanelCanvasItemPC:BPImpFunc_AfterOnMouseMove_ImgEventPanel(InMyGeometry, InMouseEvent)
	--self.bCanNotMark = true

	--print("LargeMapPanelCanvasItemPC >> BPImpFunc_AfterOnMouseMove_ImgEventPanel", GetObjectName(self))
	if (not self.LocalMarkRouteArray) or (self.LocalMarkRouteArray:Length() <= 0) then
		return
	end
	local Length = self.LocalMarkRouteArray:Length()
	local bNeedShowPreview = (Length < self.MaxMarkRouteNum)
	if bNeedShowPreview then
		local CurMarkRouteLoc = self:GetMarkPointFromCursorLinePos()
		if CurMarkRouteLoc == self.CurMarkRouteLoc then
			return
		end
		local bIsAltDown = self:IsInputKeyDown_Alt()
		if bIsAltDown then
			self.CurMarkRouteLoc = CurMarkRouteLoc
			local PreviewRoute = UE.TArray(UE.FVector)
			PreviewRoute:AddUnique(self.LocalMarkRouteArray:GetRef(Length))
			PreviewRoute:AddUnique(CurMarkRouteLoc)
			self:AdvanceMarkPreviewRouteLine(PreviewRoute)
		else
			local DeletePreviewRoute = UE.TArray(UE.FVector)
			self:AdvanceMarkPreviewRouteLine(DeletePreviewRoute)
		end
	else
		local DeletePreviewRoute = UE.TArray(UE.FVector)
		self:AdvanceMarkPreviewRouteLine(DeletePreviewRoute)
	end
end

function LargeMapPanelCanvasItemPC:BPImpFunc_AfterOnMouseButtonUp_ImgEventPanel(InMyGeometry, InMouseEvent)
	local bIsAltDown = self:IsInputKeyDown_Alt()

	print("LargeMapPanelCanvasItemPC >> AfterOnMouseButtonUp_ImgEventPanel, bIsAltDown", bIsAltDown)

	if (not bIsAltDown) then
		-- 玩家标记地图
		local WorldPoint = self:GetMarkPointFromCursorLinePos()
		print("LargeMapPanelCanvasItemPC:AfterOnMouseButtonUp_ImgEventPanel	WorldPoint:", WorldPoint)
		local PlayLineArray = UE.TArray(UE.FVector)
		PlayLineArray:AddUnique(WorldPoint)
		self:AdvanceMarkPlayLine(PlayLineArray)
	else
		-- 玩家标记路线
		if not self.LocalMarkRouteArray then
			self.LocalMarkRouteArray = UE.TArray(UE.FVector)
		end
		local NotifyKey = nil
		local LocalMarkRouteNum = self.LocalMarkRouteArray:Length()
		if LocalMarkRouteNum < self.MaxMarkRouteNum then
			--获取光标位置 转换成 光标控件本地位置
			--光标控件本地位置 转 绝对位置
			-- 绝对位置 转 地图控件本地位置
			local ToWorldPoint =  self:GetMarkPointFromCursorLinePos()
			local LastPoint = (LocalMarkRouteNum >= 1) and self.LocalMarkRouteArray:GetRef(LocalMarkRouteNum) or nil
			local ToLastPoint = LastPoint and UE.UKismetMathLibrary.Vector_Distance2D(LastPoint, ToWorldPoint) or 999999
			if ToLastPoint > 10 then
				self.LocalMarkRouteArray:AddUnique(ToWorldPoint)
				self:AdvanceMarkRouteLine(self.LocalMarkRouteArray)
			else
				NotifyKey = "Minimap_MarkRouteDistLimit"
			end
			--MarkSystemDataSet:ServerAddMarkRoutePoint(ToWorldPoint)
		else
			NotifyKey = "Minimap_MarkRouteNumLimit"
		end

		if NotifyKey then
			local MinimapTextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, NotifyKey)
			local NewNotifyText = MinimapTextStr and string.format(MinimapTextStr, self.MaxMarkRouteNum) or ""

			self:ShowNotify()
			self:SimplePlayAnimationByName("Anim_Notify", false)
		end
	end
end

function LargeMapPanelCanvasItemPC:ShowNotify()
	--self.TxtNotify:SetText(NewNotifyText)

	if (self.Overlay_Notify) then
		self.Overlay_Notify:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	end

	if(self.ShowNotifyTimer) then
		Timer.RemoveTimer(self.ShowNotifyTimer)
	end
	self.ShowNotifyTimer = Timer.InsertTimer(self.NotifyShowTime,function ()
		self:HideNotify()
	end,false

	)
end

function LargeMapPanelCanvasItemPC:HideNotify()

	if (self.Overlay_Notify) then
		self.Overlay_Notify:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
end


function LargeMapPanelCanvasItemPC:IsInputKeyDown_Alt()
	if not self.LocalPC then return false end
	local IfCursorLargeMapAltKey = self.LocalPC:IsInputKeyDown(self.MinimapManager.LargeMapCursorModeKeySet.LargeMapAltKey)
	local IfPCLargeMapAltKey = self.LocalPC:IsInputKeyDown(UE.EKeys.LeftAlt) or self.LocalPC:IsInputKeyDown(UE.EKeys.RightAlt)
	return IfCursorLargeMapAltKey or IfPCLargeMapAltKey or self.bIfCursorModeAltDown
	--return self.LocalPC:IsInputKeyDown(UE.EKeys.LeftAlt) or self.LocalPC:IsInputKeyDown(UE.EKeys.RightAlt) or self.LocalPC:IsInputKeyDown(self.MinimapManager.LargeMapCursorModeKeySet.LargeMapAltKey) 
end

---comment 这个方法在ParentWidget中传入 ImgPanel 绑定事件
---@param ImgEventPanel UImage对象
function LargeMapPanelCanvasItemPC:SetImgEventPanel(ImgEventPanel, ImgMouseDownPanel)
	self.ImgEventPanelImage = ImgEventPanel
	self.ImgMouseDownPanel = ImgMouseDownPanel
	if nil == self.ImgEventPanelImage or nil == self.ImgMouseDownPanel then
		print("LargeMapPanelCanvasItemPC >> SetImgEventPanel > self.ImgEventPanel:", self.ImgEventPanel, "self.ImgMouseDownPanel:", self.ImgMouseDownPanel)
		print("LargeMapPanelCanvasItemPC Error : 大地图蓝图 LargeMapPanelCanvasItemPC 的 ImgEventPanel 为空值，未绑定事件")
	end
	--注册回调
	if self.ImgEventPanelImage then
		self:RegistImgEvent()
		self.ImgEventPanelImage.OnMouseButtonDoubleClickEvent:Bind(self, self.OnMouseButtonDoubleClickImgEventPanelImage)
	end

end


function LargeMapPanelCanvasItemPC:OnMouseButtonDoubleClickImgEventPanelImage(InMyGeometry, InMouseEvent)
	-- body
	return UE.UWidgetBlueprintLibrary.Handled()
end


function LargeMapPanelCanvasItemPC:OnDestroy()
	print("LargeMapPanelCanvasItemPC >> OnDestroy, ...", GetObjectName(self))
	if self.ImgEventPanelImage then
		-- body
		self.ImgEventPanelImage.OnMouseButtonDoubleClickEvent:Unbind()
	end


	UserWidget.OnDestroy(self)
end

-- 删除按键按下
function LargeMapPanelCanvasItemPC:BPImpFunc_OnDelMapMark()
	--print("LargeMapPanelCanvasItemPC", ">> OnDelMapMark, ...", InInputData)

	local bIsAltDown = self:IsInputKeyDown_Alt()
	if not bIsAltDown then
		-- 玩家删除标记地图
		self:AdvanceMarkPlayLine(UE.TArray(UE.FVector))
	else
		-- 玩家删除标记路线
		self.LocalMarkRouteArray = UE.TArray(UE.FVector)
		self:OnKeyUp_Alt()
	end
end

function LargeMapPanelCanvasItemPC:OnDelMapMark(InstanceValue)
	self:BPImpFunc_OnDelMapMark()
end


-- function LargeMapPanelCanvasItemPC:SetMoveVirtualCursor()
	
-- 	self.bMouseOverstep = true
-- 	--Slot尺寸
-- 	local MapAreaSize = UE.FVector2D(0, 0)

-- 	if self.ImgCursorImage then
-- 		local ImgCursorImageSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ImgCursorImage)
-- 		MapAreaSize = ImgCursorImageSlot:GetSize()
-- 	end


-- 	if self.MiniMapManager then
-- 		--需要在跳伞之后
-- 		if self.MiniMapManager:GetCurrentParachuteState() == 2 then
-- 			--准星回正分成两种情况，地图有放大/没有放大
-- 			local CurZoomLevel = self.MiniMapManager:GetCurMapZoomInfoParamsConst(UE.EGMapItemShowOnWhichMap.LargeMap).ZoomLevel
-- 			--放大时，直接回正到中间即可
-- 			if CurZoomLevel > 1 then
-- 				--即Slot Size的一半位置
-- 				self.VirtualCursorPos = MapAreaSize / 2

-- 			--未放大时，需要回正到玩家图标位置，因为缩放为1时大地图无法移动
-- 			elseif CurZoomLevel == 1 then

-- 				local PlayerLocation = self:GetPlayerLoction()
-- 				local PlayerLocMiniMap = self:ToMinimapPoint(PlayerLocation)
-- 				--在缩放为1的时候，加上0.5倍的Slot长度，就是uv对应的坐标（图标是剧中对齐（见UMapPanelCanvas::AddNewMapWidget, Line 275），但是UV默认是左上角对齐）
-- 				self.VirtualCursorPos =  UE.FVector2D(PlayerLocMiniMap.X + MapAreaSize.X / 2, PlayerLocMiniMap.Y + MapAreaSize.Y / 2)
-- 			end
-- 		end
-- 	end
-- end

-- todo 观战的时候需要取到观战对象的坐标吗？
-- 获取当前玩家自己的世界坐标
function LargeMapPanelCanvasItemPC:GetPlayerLoction()
	local PlayerViewTarget = self:GetOwningPlayerViewTarget()
	local PlayerLoctionPos = nil
	if PlayerViewTarget == nil then
		print("LargeMapPanelCanvasItemPC >> GetPlayerLoction-->self:GetOwningPlayerViewTarget() Failed")
	else            
		PlayerLoctionPos = PlayerViewTarget:K2_GetActorLocation()
		print("LargeMapPanelCanvasItemPC >> GetPlayerLoction-->PlayerLoctionPos:(", PlayerLoctionPos.X, ", ", PlayerLoctionPos.Y,
		", ", PlayerLoctionPos.Z, ")")
	end
	return PlayerLoctionPos
end

-- 把地图移动到玩家自己的位置
function LargeMapPanelCanvasItemPC:MoveMapToMyself()
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
			print("LargeMapPanelCanvasItemPC >> MoveMapToMyself-->MiniMapScreenPos:", MiniMapScreenPos)
		end
	end
end


-- Alt按键释放
function LargeMapPanelCanvasItemPC:OnKeyUp_Alt(InInputData)
	if not self.LocalMarkRouteArray then return end

	local LocalMarkRouteNum = self.LocalMarkRouteArray:Length()
	if LocalMarkRouteNum <= self.MaxMarkRouteNum then

		local MarkRoutes = (LocalMarkRouteNum > 1) and self.LocalMarkRouteArray or {}
		self:AdvanceMarkRouteLine(MarkRoutes)
	end
	self.LocalMarkRouteArray = nil

	local DeletePreviewRoute = UE.TArray(UE.FVector)
	self:AdvanceMarkPreviewRouteLine(DeletePreviewRoute)
end



--1.将鼠标的绝对坐标转成小地图本地坐标，将小地图本地坐标转成3D世界坐标 ，返回：FVector
function LargeMapPanelCanvasItemPC:GetToWorldPoint(InMouseEvent)
	local ImgMap_LocalSpacePos = self:GetImgMapSpacePos(InMouseEvent)
	local ToWorldPoint = self.MinimapManager:ToWorldPoint(self.MapType, ImgMap_LocalSpacePos) --将地图上的点转成大世界3D坐标
	return ToWorldPoint
end


-- 得到十字光标对应的3D世界的坐标，返回：FVector
function LargeMapPanelCanvasItemPC:GetCursorLineToWorldPos()
	local ImgMapSpacePos = self:GetMapPositionFromCurrentCursor()

	if self.MinimapManager then
		local WorldPoint = self.MinimapManager:ToWorldPoint(self.MapType, ImgMapSpacePos)
		return WorldPoint
	end
end

-- 获取当前十字光标在小地图控件坐标，返回：FVector2D
function LargeMapPanelCanvasItemPC:GetMapPositionFromCurrentCursor()
	--将十字光标材质位置(0-1)转成十字光标控件(Widget)本地位置
	--十字光标控件(Widget)本地位置转成绝对坐标
	--绝对坐标转成小地图(Widget)控件坐标
	local ImgCursor_Geometry = self.ImgCursor:GetCachedGeometry()
	local ImgMap_Geometry = self.ImgMap:GetCachedGeometry()
	local Cursor_ScreenSpacePos = self:CursorLinePosToScreenPos(ImgCursor_Geometry)
	local ImgMap_LocalSpacePos = UE.USlateBlueprintLibrary.AbsoluteToLocal(ImgMap_Geometry, Cursor_ScreenSpacePos)
	local ImgMap_LocalRelativePos = ImgMap_LocalSpacePos - (self:GetImgMapSize() / 2)
	return ImgMap_LocalRelativePos
end

-- 获取当前十字光标在小地图控件坐标，返回：FVector2D
function LargeMapPanelCanvasItemPC:GetCurrentCursorToScreenSpacePos()
	local ImgCursor_Geometry = self.ImgCursor:GetCachedGeometry()
	local Cursor_ScreenSpacePos = self:CursorLinePosToScreenPos(ImgCursor_Geometry)
	return Cursor_ScreenSpacePos
end

-- 获取光标线位置 ,返回：FVector2D(0~1)
function LargeMapPanelCanvasItemPC:GetCursorLinePos()
	local CurPosX = self.ImgCursor:GetDynamicMaterial():K2_GetScalarParameterValue("CursorX")
	local CurPosY = self.ImgCursor:GetDynamicMaterial():K2_GetScalarParameterValue("CursorY")
	return UE.FVector2D(CurPosX, CurPosY)
end

-- 将光标线坐标转换为大地图控件坐标（WidgetSpacePos），其实就是SetCursorLinePos的逆运算,返回：FVector2D
function LargeMapPanelCanvasItemPC:CursorLinePosToWidgetSpacePos(InCursorLinePos)
	if InCursorLinePos == nil then
		return
	end
	local ImgCursorSize = self.ImgCursor.Slot:GetSize() -- 光标图的原始尺寸
	local WidgetSpacePosX = InCursorLinePos.X * ImgCursorSize.X
	local WidgetSpacePosY = InCursorLinePos.Y * ImgCursorSize.Y
	return UE.FVector2D(WidgetSpacePosX, WidgetSpacePosY)
end

-- 将当前光标坐标转换为屏幕坐标
function LargeMapPanelCanvasItemPC:CursorLinePosToScreenPos(InImgCursorGeometry)
	if InImgCursorGeometry == nil then
		return
	end
	local CurPos = self:GetCursorLinePos()                          -- 获取光标的坐标
	local CursorWidgetPos = self:CursorLinePosToWidgetSpacePos(CurPos) -- 转换为控件坐标
	--print("LargeMapPanelCanvasItemPC CursorWidgetPos is", CursorWidgetPos)
	local ImgCursorScreenPos = UE.USlateBlueprintLibrary.LocalToAbsolute(InImgCursorGeometry, CursorWidgetPos)
	return ImgCursorScreenPos
end


return LargeMapPanelCanvasItemPC