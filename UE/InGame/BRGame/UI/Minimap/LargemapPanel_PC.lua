--
-- 大地图
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.02.11
--

local ParentClassName = "InGame.BRGame.UI.Minimap.LargemapPanel"
local LargemapPanel = require(ParentClassName)
local LargemapPanel_PC = Class(ParentClassName)
local testProfile = require("Common.Utils.InsightProfile")
-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Override ------------------------------------
function LargemapPanel_PC:IsInParachuteState(InPC)
    if InPC == nil then
        return false
    else
        local GameTagSettings = UE.US1GameTagSettings.Get()
        local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(InPC)
        if LocalPCPawn ~= nil then
            local bParachute = GameTagSettings.HasTagBy(LocalPCPawn, GameTagSettings.ParachuteTag)
            if bParachute == true then
                print("LargemapPanel_PC:IsInParachuteState	跳伞状态")
                return true
            else
                print("LargemapPanel_PC:IsInParachuteState	不属于跳伞状态")
                return false
            end
        end
    end
end

--暂时不SetFocus,不会走OnKeyDown和OnKeyUp

-- function LargemapPanel_PC:OnKeyDown(MyGeometry, InKeyEvent)
--     local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
--     print("LargemapPanel_PC >> OnKeyDown KeyName:", PressKey.KeyName)
--     --print("LargemapPanel_PC >> OnKeyDown PressKey:", PressKey)
--     if not self.BP_AdvanceLargemapPanelUI then
--         -- body
--         return
--     end
--     --获取当前帧鼠标位置
--     if self.MinimapManager then
--         if PressKey == self.MinimapManager.LargeMapCursorModeKeySet.LargeMapEnLarge then
--             self.BP_AdvanceLargemapPanelUI:SetMapZoomByZoomLevelDelta(self.MinimapManager.LargeMapCursorModeZoomFlator)
--             return UE.UWidgetBlueprintLibrary.Unhandled()
--         elseif PressKey == self.MinimapManager.LargeMapCursorModeKeySet.LargeMapReduce then
--             self.BP_AdvanceLargemapPanelUI:SetMapZoomByZoomLevelDelta(-self.MinimapManager.LargeMapCursorModeZoomFlator)
--             return UE.UWidgetBlueprintLibrary.Unhandled()
--         elseif PressKey == self.MinimapManager.LargeMapCursorModeKeySet.LargeMapAltKey then
--             self.BP_AdvanceLargemapPanelUI.bIfCursorModeAltDown = true
--             return UE.UWidgetBlueprintLibrary.Unhandled()
--         elseif PressKey == self.MinimapManager.LargeMapCursorModeKeySet.LargeMapCursorMoveToPlayer then
--             self.BP_AdvanceLargemapPanelUI:MoveMapToMyself()
--             return UE.UWidgetBlueprintLibrary.Unhandled()
--         end
--     end

--     if
--         PressKey.KeyName == "Gamepad_FaceButton_Bottom " or PressKey.KeyName == "Gamepad_RightStick_Up" or
--             PressKey.KeyName == "Gamepad_RightStick_Right" or
--             PressKey.KeyName == "Gamepad_RightStick_Down" or
--             PressKey.KeyName == "Gamepad_RightStick_Left"
--      then
--         return UE.UWidgetBlueprintLibrary.Unhandled()
--     end
--     return UE.UWidgetBlueprintLibrary.Unhandled()
-- end

-- function LargemapPanel_PC:OnKeyUp(MyGeometry, InKeyEvent)
--     local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
--     -- print("LargemapPanel_PC >> OnKeyUp KeyName:", PressKey.KeyName)
--     -- print("LargemapPanel_PC >> OnKeyUp PressKey:", PressKey)

--     if not self.BP_AdvanceLargemapPanelUI then
--         -- body
--         return UE.UWidgetBlueprintLibrary.Unhandled()
--     end

--     if self.MinimapManager then
--         if PressKey == self.MinimapManager.LargeMapCursorModeKeySet.LargeMapAltKey then
--             self.BP_AdvanceLargemapPanelUI.bIfCursorModeAltDown = false
--             return UE.UWidgetBlueprintLibrary.Unhandled()
--         end
--     end

--     return UE.UWidgetBlueprintLibrary.Unhandled()
-- end

function LargemapPanel_PC:OnClose()
    print("LargeMapPanelCanvasItem >> OnClose ", GetObjectName(self))
    UE.UGamepadUMGFunctionLibrary.SetSimulateWheelButton(true)

    if self.RebornStateMapTipsWidget then
        UnLua.Unref(self.RebornStateMapTipsWidget)
        self.RebornStateMapTipsWidget = nil
    end
    self.RebornStateMapTipsWidgetRef = nil
end

function LargemapPanel_PC:OnUpdate(InContext, InGenericBlackboard)
   
end


function LargemapPanel_PC:OnShow(InContext, InGenericBlackboard)

    local GenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(GameInstance)
    if GenericGamepadUMGSubsystem and GenericGamepadUMGSubsystem:IsInGamepadInput() then 
        MsgHelper:SendCpp(GameInstance,GameDefine.MsgCpp.Minimap_OpenLargeMapByGamepad)
        print("LargemapPanel_PC:OpenLargeMapByGamepad")
    end

    print("LargemapPanel_PC >> OnShow, ", GetObjectName(self))
    UE.UGamepadUMGFunctionLibrary.SetSimulateWheelButton(false)

    -- self.bIsFocusable = true
    -- self:SetFocus()
    --self:AddActiveWidgetStyleFlagsByName(self.WidgetSyle["Normal"])

    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
	BlackBoardKeySelector.SelectedKeyName = "LargeMapPanelType"
	local LargeTypeName, LargeType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InGenericBlackboard, BlackBoardKeySelector)
    
    print("LargemapPanel_PC:OnShow LargeTypeName:", LargeTypeName)
    
    if LargeType then
        if "ParachuteRespawn" == LargeTypeName then
            self.ParachuteRespawn = true
        else
            self.ParachuteRespawn = false
        end        
    end
    -- 地图居中
    if self.ParachuteRespawn then
        if self.MapPanel and self.MapPanel.Slot then
            local MapPanelPos =  self.MapPanel.Slot:GetSize()
            print("LargemapPanel_PC:OnUpdate MapPanelPos:", MapPanelPos)
            --self.MapPanel.Slot:SetPosition(UE.FVector2D(-MapPanelPos.X / self.RebornXOffsetRate, self.OriginalMapPanelPos.Y))
            self.MapPanel.Slot:SetPosition(UE.FVector2D(-MapPanelPos.X / self.RebornXOffsetRate, -MapPanelPos.Y / self.RebornYOffsetRate))
            self.BP_AdvanceLargemapPanelUI:SetMapPosition(UE.FVector2D(0,0))
            self.MinimapManager:SetCurMapZoomAndUpdateMapIcon(UE.EGMapItemShowOnWhichMap.LargeMap,1.0,true)
        end

        self:AddActiveWidgetStyleFlagsByName(self.WidgetSyle[LargeTypeName])
        if self.MinimapManager then
        end
    else
        if self.MapPanel and self.MapPanel.Slot then
            self.MapPanel.Slot:SetPosition(self.OriginalMapPanelPos)
        end

        self:AddActiveWidgetStyleFlagsByName(self.WidgetSyle["Normal"])
    end

    if LargeTypeName == "ParachuteRespawn" and self.MinimapManager then
        self.MinimapManager:InitLargeMapParachuteTower()

        BlackBoardKeySelector.SelectedKeyName = "GMPParam_1"
        local ParachuteRemainTime, bParachuteRemainTimeType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsFloat(InGenericBlackboard, BlackBoardKeySelector)
        BlackBoardKeySelector.SelectedKeyName = "GMPParam_2"
        local ParachuteRespawnNum, bIfParachuteType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(InGenericBlackboard, BlackBoardKeySelector)
        BlackBoardKeySelector.SelectedKeyName = "GMPParam_3"
        local ParachuteStartTime, ParachuteStartTimeType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsFloat(InGenericBlackboard, BlackBoardKeySelector)
        print("LargemapPanel_PC >> OnUpdate ParachuteRespawn", GetObjectName(self), "ParachuteRemainTime:", ParachuteRemainTime, "ParachuteRespawnNum:",ParachuteRespawnNum, "ParachuteStartTime:", ParachuteStartTime)
        if not self.RebornStateMapTipsWidget then
            self.RebornStateMapTipsWidget = self.DEB_RebornStateMapTips:BP_CreateEntry()
            self.RebornStateMapTipsWidgetRef = UnLua.Ref(self.RebornStateMapTipsWidget)
        end
        if self.RebornStateMapTipsWidget then
            self.RebornStateMapTipsWidget:StartCountDown(ParachuteRemainTime, ParachuteRespawnNum, ParachuteStartTime)
        end
    end

    if BridgeHelper.IsPCPlatform() then
        local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        if LocalPC == nil then
            return
        end

        local bIsParachute = self:IsInParachuteState(LocalPC)
        if bIsParachute == false then
                
            -- 这个偏移是实际测量的结构，大致上位于大地图的中心
            --UIHelper.SetMouseToCenterLoc(LocalPC, 0, 0) -- 不是跳伞状态就设置到默认位置
            if self.BP_AdvanceLargemapPanelUI then
                self.BP_AdvanceLargemapPanelUI:MoveMapToMyself()
                --重置十字光标
                --self.BP_AdvanceLargemapPanelUI:SetMoveVirtualCursor()
                self.BP_AdvanceLargemapPanelUI:ResetCursorToPlayer()
            end
        else
            -- 只有跳伞状态中，大地图才会记录并恢复到上一次的位置
            -- if MinimapSystem.LargeMapCursorPosCache ~= nil then
            --     if (MinimapSystem.LargeMapCursorPosCache.X == 0) and (MinimapSystem.LargeMapCursorPosCache.Y == 0) then
            --         --LocalPC:SetMouseLocation(math.floor(MinimapSystem.LargeMapCursorPosCache.X), math.floor(MinimapSystem.LargeMapCursorPosCache.Y))
            --         UIHelper.SetMouseToCenterLoc(LocalPC, 600, 0) -- 如果是第一次打开大地图，那就设置到默认位置
            --     else
            --         --print("LargemapMainItem:OnShow-->SetScalarParameterValue:", MinimapSystem.LargeMapCursorPosCache)
            --         LocalPC:SetMouseLocation(
            --             math.floor(MinimapSystem.LargeMapCursorPosCache.X),
            --             math.floor(MinimapSystem.LargeMapCursorPosCache.Y)
            --         )
            --     end
            -- else
            --     print("LargemapPanel_PC:OnShow-->MinimapSystem.LargeMapCursorPosCache is nil")
            -- end
        end
    end

    self.BP_AdvanceLargemapPanelUI.StickMoveType = self.StickMoveType
    print("LargemapPanel_PC:OnShow StickMoveType Set" )

    self.BP_AdvanceLargemapPanelUI:ResetMouseLocation()
end



function LargemapPanel_PC:UpdateLargeMapPanelStyle()
    local IfRespawnParachute = false

    -- 显示跳伞复活倒计时UI，隐藏Tab切换页签
    if IfRespawnParachute then
		self:AddActiveWidgetStyleFlagsByName(self.WidgetSyle["ParachuteRespawn"])
	else
		self:AddActiveWidgetStyleFlagsByName(self.WidgetSyle["Normal"])
	end

end


function LargemapPanel_PC:AddActiveWidgetStyleFlagsByName(SlyeName)
    print("LargemapPanel_PC:AddActiveWidgetStyleFlagsByName", SlyeName)
    self:RemoveAllActiveWidgetStyleFlags()
    self:AddActiveWidgetStyleFlags(SlyeName)
end

-------------------------------------------- Init/Destroy ------------------------------------

function LargemapPanel_PC:OnInit()
    print("LargemapPanel_PC >> OnInit, ", GetObjectName(self))

    if self.BP_AdvanceLargemapPanelUI then
        self.BP_AdvanceLargemapPanelUI:SetImgEventPanel(self.ImgEventPanel)
    end
    if self.MapPanel.Slot then
        self.OriginalMapPanelPos =  self.MapPanel.Slot:GetPosition()
    end
    
    if not self.WidgetSyle then
		self.WidgetSyle = 
		{
			["Normal"] = 1, -- 默认
			["ParachuteRespawn"] = 2, -- 跳伞复活
		}
	end

    LargemapPanel.OnInit(self)
    table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.PC_Input_ScaleMapEnLarge_Gamepad,		Func = self.OnScaleMapEnLarge_Gamepad, bCppMsg = true, WatchedObject = self.LocalPC})
    table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.PC_Input_ScaleMapReduce_Gamepad,		Func = self.OnScaleMapReduce_Gamepad, bCppMsg = true, WatchedObject = self.LocalPC})
    table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.PC_Input_ResetMapCursor,		Func = self.OnResetMapCursor, bCppMsg = true, WatchedObject = self.LocalPC})
    MsgHelper:RegisterList(self, self.MsgList)
end

--手柄缩放IA
function LargemapPanel_PC:OnScaleMapEnLarge_Gamepad(Input)
    self.BP_AdvanceLargemapPanelUI:SetMapZoomByZoomLevelDelta(self.MinimapManager.LargeMapCursorModeZoomFlator)
end

function LargemapPanel_PC:OnScaleMapReduce_Gamepad(Input)
    self.BP_AdvanceLargemapPanelUI:SetMapZoomByZoomLevelDelta(-self.MinimapManager.LargeMapCursorModeZoomFlator)
end

function LargemapPanel_PC:OnResetMapCursor(Input)
    self.BP_AdvanceLargemapPanelUI:MoveMapToMyself()
    self.BP_AdvanceLargemapPanelUI:ResetCursorToPlayer()
end


function LargemapPanel_PC:OnDestroy()
    print("LargemapPanel_PC >> OnDestroy, ", GetObjectName(self))

    if BridgeHelper.IsPCPlatform() then
        if self.ImgTrigger then
            -- body
            self.ImgTrigger.OnMouseMoveEvent:Unbind()
        end
    end
    LargemapPanel.OnDestroy(self)
end

return LargemapPanel_PC
