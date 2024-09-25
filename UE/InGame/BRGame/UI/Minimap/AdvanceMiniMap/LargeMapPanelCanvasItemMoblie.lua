--
-- 大地图地图控件
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.02.24
--

local ParentClassName = "InGame.BRGame.UI.Minimap.AdvanceMiniMap.LargeMapPanelCanvasItem"
local LargeMapPanelCanvasItem = require(ParentClassName)
local LargeMapPanelCanvasItemMoblie = Class(ParentClassName)


-------------------------------------------- Init/Destroy ------------------------------------

--
function LargeMapPanelCanvasItemMoblie:OnInit()
	print("LargeMapPanelCanvasItemMoblie", ">> OnInit[Start], ...", GetObjectName(self))
	self.IsPlayerRouteMarkMod_Moblie = false		--当前标记模式是否是路径标记模式（仅用于手机平台）
	self.NewMarkDataCache = UE.TArray(UE.FVector)	-- 缓存玩家单点标记
	self.bHasMovedMap = false		-- 这个flag值用于记录当前玩家是否有拖拽地图的操作

	self.RoutePointCache = nil		-- 缓存玩家路径标记
	-- 双指按下位置数据
	self.DownPoses = {
		--[1] = { OldPos = UE.FVector2D(928, 393), CurPos = UE.FVector2D(928, 393) }
	}

	if not self.MsgList then
		self.MsgList = {
			{ MsgName = GameDefine.Msg.LARGEMAP_UpdateMapZoomLevel,		Func = self.ChangeMapZoomLevel },
			{ MsgName = GameDefine.Msg.LARGEMAP_UpdateMapMarkMod_Moblie,		Func = self.UpdateMapMarkMod_Moblie },
			{ MsgName = GameDefine.Msg.LARGEMAP_DeleteMarkPoint_Moblie,		Func = self.DeleteMarkPoint_Moblie },
			{ MsgName = GameDefine.Msg.LARGEMAP_MarkMyself,		Func = self.MarkMyself },
			{ MsgName = GameDefine.Msg.LARGEMAP_MoveToMyself,		Func = self.MoveToMyself },
		}
	end
	

	LargeMapPanelCanvasItem.OnInit(self)
	--self.Overridden.Construct(self)

	-- 覆写数据
	self.ZoomLevelDeltaFactor = self.MinimapManager and self.MinimapManager.ZoomLevelDeltaFactor or 0.5
	self.ZoomMobileDeltaFactor = self.MinimapManager and self.MinimapManager.ZoomMobileDeltaFactor or 0.05

	-- 加载

	-- local CacheViewOffsetX = CacheData.LargemapViewOffsetX
	-- if CacheViewOffsetX then
	-- 	self.ViewOffset.X = CacheViewOffsetX
	-- 	self.ViewOffset.Y = CacheData.LargemapViewOffsetY
	-- 	self.ViewOffset = self:ApplyInRangeOffsetPos(self.ViewOffset)
	-- 	self.ViewOffsetStart = self.ViewOffset
	-- end

	self.TouchEventPanel.OnMouseButtonDownEvent:Bind(self,self.OnMouseButtonDown_ImgMap)
end

--
function LargeMapPanelCanvasItemMoblie:OnDestroy()
	print("LargeMapPanelCanvasItemMoblie", ">> OnDestroy, ...", GetObjectName(self))


	LargeMapPanelCanvasItem.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------

-- 是否是小地图
function LargeMapPanelCanvasItemMoblie:IsMinimapPanel()
	return false
end


function LargeMapPanelCanvasItemMoblie:IsInRouteMarkMod()
	-- 手机平台下根据UI按钮确定他是路径标记还是单点标记。
    print("LargeMapPanelCanvasItemMoblie:IsInRouteMarkMod	IsPlayerRouteMarkMod_Moblie:", self.IsPlayerRouteMarkMod_Moblie)
    local RetResult = self.IsPlayerRouteMarkMod_Moblie
	return RetResult
end

-- 自身标记功能实现
function LargeMapPanelCanvasItemMoblie:MarkMyselfLocation()
    local MyLocation = self:GetPlayerLoction()
    if MyLocation ~= nil then
        -- 自己当前的坐标位置作为一个标记点
        local PlayLineArray = UE.TArray(UE.FVector)
		PlayLineArray:AddUnique(MyLocation)
		self:AdvanceMarkPlayLine(PlayLineArray)
		print("LargeMapPanelCanvasItemMoblie >> MarkMyselfLocation[Debug], ", MyLocation)
    else
        print("LargeMapPanelCanvasItemMoblie:MarkMyselfLocation-->self:GetPlayerLoction failed, MyLocation is nil")
    end
end

function LargeMapPanelCanvasItemMoblie:FixAndUpdateMapZoom(InZoomLevel)
	--  以玩家当前坐标位置为基准点，修正地图缩放


	--print("LargeMapPanelCanvasItemMoblie >> FixAndUpdateMapZoom	InZoomLevel:", InZoomLevel)
	self:SetZoomLevelAndFixPos(InZoomLevel, UE.FVector2D(0))

end

-------------------------------------------- Function ------------------------------------


function LargeMapPanelCanvasItemMoblie:ChangeMapZoomLevel(InMsgBody)
	local NewZoomLevel = InMsgBody.NewZoomLevel
	local OldZoomLevel = self.ZoomLevel
	local IsZoomInOpt = InMsgBody.IsZoomIn
	if IsZoomInOpt ~= nil then
		-- 放大
		if IsZoomInOpt == true then
			--self:SetZoomLevel(NewZoomLevel)
			self:FixAndUpdateMapZoom(NewZoomLevel)
			--print("LargeMapPanelCanvasItemMoblie >> UpdateMapZoomLevel	IsZoomInOpt:", IsZoomInOpt, "OldZoomLevel:", OldZoomLevel, "NewZoomLevel:", NewZoomLevel)
		else
			--self:SetZoomLevel(NewZoomLevel)
			self:FixAndUpdateMapZoom(NewZoomLevel)
			--print("LargeMapPanelCanvasItemMoblie >> UpdateMapZoomLevel	IsZoomInOpt:", IsZoomInOpt, "OldZoomLevel:", OldZoomLevel, "NewZoomLevel:", NewZoomLevel)
		end
	else
		-- InMsgBody.IsZoomIn等于nil说明是直接设置zoom level
		if NewZoomLevel == nil then
			--print("LargeMapPanelCanvasItemMoblie >> UpdateMapZoomLevel InMsgBody.NewZoomLevel is nil")
			return
		end
		self:FixAndUpdateMapZoom(NewZoomLevel)
		--print("LargeMapPanelCanvasItemMoblie >> UpdateMapZoomLevel	ZoomLevel to set:", OldZoomLevel)
	end
	
end

function LargeMapPanelCanvasItemMoblie:UpdateMapMarkMod_Moblie(InMsgBody)
	if not BridgeHelper.IsMobilePlatform() then	
		print("LargeMapPanelCanvasItemMoblie:UpdateMapMarkMod_Moblie 当前不是手机平台, UpdateMapMarkMod_Moblie函数无效，直接返回")
		return
	end
	self.IsPlayerRouteMarkMod_Moblie = InMsgBody.IsPlayerRouteMarkMod
	print("LargeMapPanelCanvasItemMoblie:UpdateMapMarkMod_Moblie		IsPlayerRouteMarkMod:", InMsgBody.IsPlayerRouteMarkMod)
end

function LargeMapPanelCanvasItemMoblie:DeleteMarkPoint_Moblie(InMsgBody)
    if not BridgeHelper.IsMobilePlatform() then	
		print("LargeMapPanelCanvasItemMoblie:DeleteMarkPoint_Moblie 当前不是手机平台, UpdateMapMarkMod_Moblie函数无效, 直接返回")
		return
	end
    if LargeMapPanelCanvasItem ~= nil then
        print("LargeMapPanelCanvasItemMoblie:DeleteMarkPoint_Moblie-->LargeMapPanelCanvasItem.OnDelMapMark")
        self:OnDelMapMark()
    end
	
end

function LargeMapPanelCanvasItemMoblie:MarkMyself(InMsgBody)
    print("LargeMapPanelCanvasItemMoblie:MarkMyself")
    self:MarkMyselfLocation()
end

function LargeMapPanelCanvasItemMoblie:MoveToMyself(InMsgBody)
	print("LargeMapPanelCanvasItemMoblie:MoveToMyself")
	self:MoveMapToMyself()
end

-------------------------------------------- Override ------------------------------------

-- 鼠标按键按下(ImgMap)
function LargeMapPanelCanvasItemMoblie:OnMouseButtonDown_ImgMap(InMyGeometry, InMouseEvent)
	print("LargeMapPanelCanvasItemMoblie >> OnMouseButtonDown_ImgMap", UE.UGUIHelper.SPointerEvent(InMouseEvent, false))

	local bMobilePlatform = BridgeHelper.IsMobilePlatform()
	local bRightMouseButtonDown = bMobilePlatform or UE.UKismetInputLibrary.PointerEvent_IsMouseButtonDown(InMouseEvent, UE.EKeys.RightMouseButton)
	if not bRightMouseButtonDown then
		return UE.UWidgetBlueprintLibrary.Unhandled()
	end

	local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)

	
	local bIsRouteMarkMod = self:IsInRouteMarkMod()
	print("LargeMapPanelCanvasItemMoblie >> OnMouseButtonDown_ImgMap, ", bRightMouseButtonDown, bIsRouteMarkMod)
	if (not bIsRouteMarkMod) then
		-- 玩家标记地图
		local NewMarkData = self:GetToWorldPoint(InMouseEvent)
		self.NewMarkDataCache = UE.TArray(UE.FVector)-- 缓存标记位置
		self.NewMarkDataCache:AddUnique(NewMarkData)

		---手机端再按下按键的时候只是记录坐标，抬起按键的时候才标记
		print("LargeMapPanelCanvasItemMoblie >> OnMouseButtonDown_ImgMap NewMarkData:", NewMarkData)
	else		
		self.RoutePointCache = self:GetToWorldPoint(InMouseEvent)
	end
	
	-- 在安卓平台中，标记点按键是鼠标左键（PC端是鼠标右键），这就和和OnMouseButtonDown回调冲突，所有这里把事件设置成Unhandled，以便继续处理OnMouseButtonDown回调
	-- return UE.UWidgetBlueprintLibrary.Handled()
	return UE.UWidgetBlueprintLibrary.Unhandled()
end



-- 鼠标按键按下
function LargeMapPanelCanvasItemMoblie:OnMouseButtonDown(InMyGeometry, InMouseEvent)				-- override
	-- 多点按下操作
	local PointIndex = UE.UKismetInputLibrary.PointerEvent_GetPointerIndex(InMouseEvent)
	if PointIndex <= 5 then
		local PointScreenPos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent)
		self.DownPoses[PointIndex] = { OldPos = PointScreenPos, CurPos = PointScreenPos }
	end

	self.ViewOffsetStart = self.ViewOffset
	self.MouseDownPositionAbsolute = UE.UKismetInputLibrary.PointerEvent_GetLastScreenSpacePosition(InMouseEvent)
	return UE.UWidgetBlueprintLibrary.Handled()
	--return LargeMapPanelCanvasItem.OnMouseButtonDown(self, InMyGeometry, InMouseEvent)
end


-- 鼠标按键移入
function LargeMapPanelCanvasItemMoblie:OnMouseEnter(InMyGeometry, InMouseEvent)
	self.bLeftMouseButtonDown = UE.UKismetInputLibrary.PointerEvent_IsMouseButtonDown(InMouseEvent, UE.EKeys.LeftMouseButton)
	
	if not self:IsInRouteMarkMod() then
		self:OnKeyUp_Alt()
	end

	--print("LargeMapPanelCanvasItemMoblie", ">> OnMouseEnter, ", InMyGeometry, InMouseEvent)
end

-- 删除按键按下
function LargeMapPanelCanvasItemMoblie:OnDelMapMark(InInputData)
	--print("LargeMapPanelCanvasItemMoblie", ">> OnDelMapMark, ...", InInputData)

	local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)

	local bIsRouteMarkMod = self:IsInRouteMarkMod()
	if not bIsRouteMarkMod then
		-- 玩家删除标记地图
		self:AdvanceMarkPlayLine(UE.TArray(UE.FVector))
	else
		-- 玩家删除标记路线
		self.LocalMarkRouteArray = UE.TArray(UE.FVector)
		self:OnKeyUp_Alt()
	end
end

-- Alt按键释放
-- Alt按键释放
function LargeMapPanelCanvasItemMoblie:OnKeyUp_Alt(InInputData)
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

-- 鼠标按键释放
function LargeMapPanelCanvasItemMoblie:OnMouseButtonUp(InMyGeometry, InMouseEvent)
	print("LargeMapPanelCanvasItemMoblie >> OnMouseButtonUp")
	-- 在安卓平台下，下面这个接口永远返回true，可能是UE平台的bug。不知道原因。（虽然实际上鼠标按键已经释放，但依然返回true）。所以这里强制设置成false
	local RetCode = UE.UKismetInputLibrary.PointerEvent_IsMouseButtonDown(InMouseEvent, UE.EKeys.LeftMouseButton)
	if RetCode == true then
		self.bLeftMouseButtonDown = false
	end
	-- 画出标记
	if	self.bHasMovedMap == false then
		local bIsRouteMarkMod = self:IsInRouteMarkMod()

		if bIsRouteMarkMod == false then
			--print("LargeMapPanelCanvasItemMoblie:OnMouseButtonUp	ServerUpdateMarkData")
			self:AdvanceMarkPlayLine(self.NewMarkDataCache)
		else
			--print("LargeMapPanelCanvasItemMoblie:OnMouseButtonUp	ServerSetMarkRoutePoints")
			if not self.LocalMarkRouteArray then
				self.LocalMarkRouteArray = UE.TArray(UE.FVector)
			end
			local NotifyKey = nil
			local LocalMarkRouteNum = self.LocalMarkRouteArray:Length()
			if LocalMarkRouteNum < self.MaxMarkRouteNum then
				local ToWorldPoint = self.RoutePointCache
				local LastPoint = (LocalMarkRouteNum >= 1) and self.LocalMarkRouteArray:GetRef(LocalMarkRouteNum) or nil
				local ToLastPoint = LastPoint and UE.UKismetMathLibrary.Vector_Distance2D(LastPoint, ToWorldPoint) or 999999
				if ToLastPoint > 10 then
					self.LocalMarkRouteArray:AddUnique(ToWorldPoint)
					self:AdvanceMarkRouteLine(self.LocalMarkRouteArray)
				else
					--NotifyKey = "Minimap_MarkRouteDistLimit"
				end
			else
				NotifyKey = "Minimap_MarkRouteNumLimit"
			end

			if NotifyKey then
				local MinimapTextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, NotifyKey)
				local NewNotifyText = MinimapTextStr and string.format(MinimapTextStr, self.MaxMarkRouteNum) or ""
				self.TxtNotify:SetText(NewNotifyText)
				self:SimplePlayAnimationByName("Anim_Notify", false)
			end
		end
	end
	
	print("LargeMapPanelCanvasItemMoblie >> OnMouseButtonUp, ", self.bLeftMouseButtonDown, UE.UGUIHelper.SPointerEvent(InMouseEvent, false))
	self.bHasMovedMap = false
	
	-- 多点按下操作
	local PointIndex = UE.UKismetInputLibrary.PointerEvent_GetPointerIndex(InMouseEvent)
	if PointIndex <= 5 then
		self.DownPoses[PointIndex] = nil
	end

	return UE.UWidgetBlueprintLibrary.Handled()
end

function LargeMapPanelCanvasItemMoblie:GetTouchDownNum()
	local DownPosesLen = 0
	if self.DownPoses then
		for TmpPointIndex, TmpPointInfo in pairs(self.DownPoses) do
			if TmpPointInfo ~= nil then
				DownPosesLen = DownPosesLen + 1
			end
		end
	end
	
	return DownPosesLen
end


-- 鼠标移动
function LargeMapPanelCanvasItemMoblie:OnMouseMove(InMyGeometry, InMouseEvent)				-- override
	--print("LargeMapPanelCanvasItemMoblie >> OnMouseMove")
	local ScreenSpacePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent)

	if not self.bLeftMouseButtonDown then
		return UE.UWidgetBlueprintLibrary.Unhandled()
	end

	local AbsoluteScale = UE.UGUIHelper.GetGeometryAbsoluteScale(InMyGeometry)
	
	--print("LargeMapPanelCanvasItemMoblie>> OnMouseMove > self.MouseDownPositionAbsolute:",self.MouseDownPositionAbsolute)
	--self.ViewOffset = self.ViewOffsetStart + ((self.MouseDownPositionAbsolute - ScreenSpacePos) / AbsoluteScale) / self:GetZoomAmount()
	-- 多点按下操作
	
	local PointIndex = UE.UKismetInputLibrary.PointerEvent_GetPointerIndex(InMouseEvent)
	if PointIndex <= 5 then
		--local PointCursorDelta = UE.UKismetInputLibrary.PointerEvent_GetCursorDelta(InMouseEvent)
		local PointScreenPos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent)
		local PointLastScreenPos = UE.UKismetInputLibrary.PointerEvent_GetLastScreenSpacePosition(InMouseEvent)
		local PointMoveDelta = PointLastScreenPos - PointScreenPos
		self.DownPoses[PointIndex] = self.DownPoses[PointIndex] or { OldPos = PointLastScreenPos, CurPos = PointScreenPos }
		self.DownPoses[PointIndex].OldPos = self.DownPoses[PointIndex].CurPos
		self.DownPoses[PointIndex].CurPos = PointScreenPos
		if not UE.UKismetMathLibrary.IsNearlyZero2D(PointMoveDelta, 0) then
			--print("LargeMapPanelCanvasItemMoblie", ">> OnMouseMove, TouchPoint[0]: ", PointIndex, PointMoveDelta)
			local IterIndex, ValidPoses, IndexPoses = 0, {}, {}
			for TmpPointIndex, TmpPointInfo in pairs(self.DownPoses) do
				if IterIndex >= 2 then
					break
				end
				IterIndex = IterIndex + 1
				ValidPoses[TmpPointIndex] = {
					IterIndex = IterIndex, PointInfo = TmpPointInfo
				}
				IndexPoses[IterIndex] = ValidPoses[TmpPointIndex]
				--print("LargeMapPanelCanvasItemMoblie", ">> OnMouseMove, TouchPoint[It]: ", IterIndex, TmpPointIndex, IndexPoses[IterIndex])
			end

			local PointData1 = ValidPoses[PointIndex]
			local IterIndex1 = PointData1 and PointData1.IterIndex or nil
			--print("LargeMapPanelCanvasItemMoblie", ">> OnMouseMove, TouchPoint[1]: ", PointIndex, IterIndex1)
			if IterIndex1 and PointData1.PointInfo then
				local IterIndex2 = (IterIndex1 > 1) and 1 or 2
				local PointData2 = IndexPoses[IterIndex2]
				if PointData2 and PointData2.PointInfo then
					print("LargeMapPanelCanvasItemMoblie >> OnMouseMove if PointData2 and PointData2.PointInfo then")
					local ConnDir = PointData1.PointInfo.OldPos - PointData2.PointInfo.CurPos
					local DeltaV3, ConnDirV3 = UE.FVector(PointMoveDelta.X, PointMoveDelta.Y, 0), UE.FVector(ConnDir.X, ConnDir.Y, 0)
					--local ProjectV3 = UE.UKismetMathLibrary.ProjectVectorOnToVector(DeltaV3, ConnDirV3)
					local DeltaNV3, ConnDirNV3 = UE.UKismetMathLibrary.Normal(DeltaV3), UE.UKismetMathLibrary.Normal(ConnDirV3)
					local CosineAngle = UE.UKismetMathLibrary.Vector_CosineAngle2D(ConnDirNV3, DeltaNV3)
					--print("LargeMapPanelCanvasItemMoblie", ">> OnMouseMove, TouchPoint[2]: ", PointData1.PointInfo.OldPos, PointData2.PointInfo.CurPos)
					--print("LargeMapPanelCanvasItemMoblie", ">> OnMouseMove, TouchPoint[3]: ", DeltaV3, ConnDirV3, ProjectV3)
					--print("LargeMapPanelCanvasItemMoblie", ">> OnMouseMove, TouchPoint[4]: ", ConnDirNV3, DeltaNV3, CosineAngle)
					
					if not (math.abs(CosineAngle) <= 0.001) then
						local InZoomLevelDelta = -CosineAngle * self.ZoomMobileDeltaFactor
						--local InZoomLevelDelta = -((CosineAngle > 0) and 1 or -1) * self.ZoomMobileDeltaFactor
						--print("LargeMapPanelCanvasItemMoblie >> OnMouseMove MulitiTouch ChangeZoom InZoomLevelDelta:", InZoomLevelDelta)
						self:ChangeZoomLevelAndFixPos(InZoomLevelDelta , UE.FVector2D())
					end
				end
			end
		end
	end

	self.MouseDownPositionAbsolute = self.MouseDownPositionAbsolute or UE.FVector2D(0)
	local NewViewOffset = self.ViewOffsetStart + ((self.MouseDownPositionAbsolute - ScreenSpacePos) / AbsoluteScale) / self:GetZoomAmount()

	-- 判断玩家是否有拖拽地图
	if NewViewOffset ~= self.ViewOffset then
		if self:GetTouchDownNum() < 2 then
			--print("LargeMapPanelCanvasItemMoblie>> OnMouseMove > NewViewOffset, self.DownPoses length: ",NewViewOffset, self:GetTouchDownNum())
			self.ViewOffset = NewViewOffset
			-- 如果玩家拖拽了地图，则设置标记
			self.bHasMovedMap = true
			self.ViewOffset = self:ApplyInRangeOffsetPos(self.ViewOffset)
		end
	end

	if self.CacheMousePos ~= UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent) then
		self.CacheMousePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent)
		--print("LargeMapPanelCanvasItemMoblie >> OnMouseMove, ", self.ViewOffset, UE.UGUIHelper.SPointerEvent(InMouseEvent, false))
	end
	return UE.UWidgetBlueprintLibrary.Handled()
end


-- 将鼠标位置转换成小地图本地坐标位置 返回：FVector2D
function LargeMapPanelCanvasItemMoblie:GetImgMapSpacePos(InMouseEvent)
	local ScreenSpacePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent) --获取鼠标位置
	local ImgMap_Geometry = self.ImgMap:GetCachedGeometry()
	local WidgetSpacePos = UE.USlateBlueprintLibrary.AbsoluteToLocal(ImgMap_Geometry, ScreenSpacePos)
	print("LargeMapPanelCanvasItemMoblie:GetImgMapSpacePos>> ", WidgetSpacePos)
	local ImgMapSpacePos = WidgetSpacePos - (self:GetImgMapSize() / 2)

	return ImgMapSpacePos
end

--1.将鼠标的绝对坐标转成小地图本地坐标，将小地图本地坐标转成3D世界坐标 ，返回：FVector
function LargeMapPanelCanvasItemMoblie:GetToWorldPoint(InMouseEvent)
	local ImgMap_LocalSpacePos = self:GetImgMapSpacePos(InMouseEvent)
	local ToWorldPoint = self.MinimapManager:ToWorldPoint(self.MapType, ImgMap_LocalSpacePos) --将地图上的点转成大世界3D坐标
	return ToWorldPoint
end

function LargeMapPanelCanvasItemMoblie:BPImpEvent_AfterSetZoom()
	if self.ParentPanel then
		self.ParentPanel:OnChangeMapZoomLevel(self.ZoomLevel)
	end
end


return LargeMapPanelCanvasItemMoblie
