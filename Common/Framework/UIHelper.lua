--
-- UIHelper
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.02.14
--

local UIHelper = _G.UIHelper or {}

-------------------------------------------- Config/Enum ------------------------------------

--[[
const FColor FColor::White(255,255,255);
const FColor FColor::Black(0,0,0);
const FColor FColor::Transparent(0, 0, 0, 0);
const FColor FColor::Red(255,0,0);
const FColor FColor::Green(0,255,0);
const FColor FColor::Blue(0,0,255);
const FColor FColor::Yellow(255,255,0);
const FColor FColor::Cyan(0,255,255);
const FColor FColor::Magenta(255,0,255);
const FColor FColor::Orange(243, 156, 18);
const FColor FColor::Purple(169, 7, 228);
const FColor FColor::Turquoise(26, 188, 156);
const FColor FColor::Silver(189, 195, 199);
const FColor FColor::Emerald(46, 204, 113);
]]
UIHelper.LinearColor = {
    White                   = UE.FLinearColor(1, 1, 1, 1),
    Black                   = UE.FLinearColor(0, 0, 0, 1),
    Transparent             = UE.FLinearColor(0, 0, 0, 0),
    Red                     = UE.FLinearColor(1, 0, 0, 1),
    Green                   = UE.FLinearColor(0, 1, 0, 1),
    Blue                    = UE.FLinearColor(0, 0, 1, 1),
    Yellow                  = UE.FLinearColor(1, 1, 0, 1),
    Cyan                    = UE.FLinearColor(0, 1, 1, 1),
    Magenta                 = UE.FLinearColor(1, 0, 1, 1),
    Orange                  = UE.FLinearColor(0.95, 0.61, 0.07, 1),
    Purple                  = UE.FLinearColor(0.66, 0.02, 0.89, 1),
    Turquoise               = UE.FLinearColor(0.10, 0.73, 0.61, 1),
    Silver                  = UE.FLinearColor(0.74, 0.76, 0.78, 1),
    Emerald                 = UE.FLinearColor(0.18, 0.80, 0.44, 1),

    Grey                    = UE.FLinearColor(0.50, 0.50, 0.50, 1),
    LightGrey               = UE.FLinearColor(0.25, 0.25, 0.25, 1),
    DarkGrey                = UE.FLinearColor(0.10, 0.10, 0.10, 1),
    LightBlack              = UE.FLinearColor(0.05, 0.05, 0.05, 1),
}
UIHelper.HexColor = {
    White = "#FFFFFF",
    Red = "#FF0000",
}


-- 布局数据表
local BaseDTPath = "/Game/DataTable/UI/"
UIHelper.LayoutDTPath = {
	PanelLayoutData				    = BaseDTPath.. "CDT_PanelLayoutData",
    TMPMainLayoutData               = BaseDTPath.. "Layout/MainLayoutData",

	BattleModeData				    = BaseDTPath.. "DT_BattleModeData",
	--BattlePanelSubData				= BaseDTPath.. "DT_BattlePanelSubData",
    
	MinimapPanelSubData				= BaseDTPath.. "DT_MinimapPanelSubData",
	TipsPanelSubData				= BaseDTPath.. "DT_TipsPanelSubData",
    BuoysLayoutData                 = BaseDTPath.. "DT_BuoysLayoutData",
}
SetErrorIndex(UIHelper.LayoutDTPath)

-- 获取配置表数据(DataTable)
function UIHelper.GetDataTableRow(InDTPath, InKey)
	local DataTableObject = UE.UObject.Load(InDTPath)
	local DataTableRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(DataTableObject, InKey)
    return DataTableRow
end


-------------------------------------------- Function ------------------------------------

-- 设置鼠标位置
function UIHelper.SetMouseToCenterLoc(InLocalPC, InOffsetX, InOffsetY)
    UE.UGUIHelper.SetMouseToCenterLoc(InLocalPC, InOffsetX or 0, InOffsetY or 0)
end

-- 获取界面配置数据
function UIHelper.GetWidgetCfgData(InKey)
	local WidgetCfgObject = UE.UObject.Load(UIHelper.LayoutDTPath.PanelLayoutData)
	local WidgetData = UE.UDataTableFunctionLibrary.GetRowDataStructure(WidgetCfgObject, InKey)
	if WidgetData and WidgetData.ClassPtr then
		return WidgetData
	end
end

-- 创建战斗布局
function UIHelper.CreateBattleLayouts(InMainWidget)
    if (not InMainWidget) then
        Error("UIHelper", ">> CreateLayouts, Invalid Params!!!", InMainWidget)
        return
    end

    local ModeKeys = { "Base", "BRMode" }
    local LayoutDT = UE.UObject.Load(UIHelper.LayoutDTPath.BattlePanelSubData)
    local LayoutModeDT = UE.UObject.Load(UIHelper.LayoutDTPath.BattleModeData)

    for _, ModeKey in ipairs(ModeKeys) do
        local ModeData = UE.UDataTableFunctionLibrary.GetRowDataStructure(LayoutModeDT, ModeKey)
        if ModeData then
            local LayoutArray = ModeData.Layouts:ToArray()
            for i = 1, LayoutArray:Length() do
                local WidgetKey = LayoutArray:GetRef(i)

                UIHelper.CreateSubWidget(InMainWidget, LayoutDT, WidgetKey, nil, true)
            end
        else
            Warning("UIHelper", ">> CreateLayouts, ModeData invalid! ", LayoutModeDT, ModeKey)
        end
    end
end

-- 创建子控件
function UIHelper.CreateSubWidget(InMainWidget, InLayoutDT, InWidgetKey, InNewParent, bWidgetKeyAsName, InNewWidgetName)
    local WidgetData = UE.UDataTableFunctionLibrary.GetRowDataStructure(InLayoutDT, InWidgetKey)
    if (not InMainWidget) or (not WidgetData) then
        Warning("UIHelper", ">> CreateSubWidget, Invalid! ", InMainWidget, InLayoutDT, InWidgetKey, WidgetData)
        return nil
    end

    local ParentName = InNewParent and InNewParent or WidgetData.Parent
    local ParentWidget = InMainWidget[ParentName]
    local LocalPC = UE.UGameplayStatics.GetPlayerController(InMainWidget, 0)
    --local WidgetClass = UE.UKismetSystemLibrary.Conv_SoftClassReferenceToClass(WidgetData.ClassPtr)
    local WidgetClass = UE.UKismetSystemLibrary.LoadClassAsset_Blocking(WidgetData.ClassPtr)
    local WidgetName = bWidgetKeyAsName and InWidgetKey or (InNewWidgetName or "")
    local WidgetObject = UE.UGUIUserWidget.Create(LocalPC, WidgetClass, LocalPC, WidgetName)
    --local WidgetObject = UE.UWidgetBlueprintLibrary.Create(LocalPC, WidgetClass, LocalPC)
    if ParentWidget and WidgetClass and WidgetObject then
        ParentWidget:AddChild(WidgetObject)
        WidgetObject:SetVisibility(WidgetData.Visibility)

        WidgetObject.Slot:SetLayout(WidgetData.LayoutData)
        WidgetObject.Slot:SetAutoSize(WidgetData.bAutoSize)
        WidgetObject.Slot:SetZOrder(WidgetData.ZOrder)

        Log("UIHelper", ">> CreateSubWidget, AddChild[Ok]: ", 
            InWidgetKey, GetObjectName(InMainWidget), ParentName, GetObjectName(ParentWidget), WidgetClass, GetObjectName(WidgetObject))
        return WidgetObject
    else
        Warning("UIHelper", ">> CreateSubWidget, AddChild[Fail]: ", 
            InWidgetKey, GetObjectName(InMainWidget), ParentName, GetObjectName(ParentWidget), WidgetClass, GetObjectName(WidgetObject), WidgetData.ClassPtr)
    end
    return nil
end

-- UIManager
-- 是否显示界面
function UIHelper.IsShowByHandle(InContent, InWidgetHandle)
    local UIManager = UE.UGUIManager.GetUIManager(InContent)
    if UIManager and InWidgetHandle then
        return UIManager:IsShowByHandle(InWidgetHandle)
    end
end

function UIHelper.IsShowByKey(InContent, InKey)
    local UIManager = UE.UGUIManager.GetUIManager(InContent)
    if UIManager then
        return UIManager:IsShowByKey(InKey)
    end
    return false
end

function UIHelper.GetHandleByKey(InContent, InKey)
    local UIManager = UE.UGUIManager.GetUIManager(InContent)
    if UIManager then
        return UIManager:GetHandleByKey(InKey)
    end
    return 0 --invalidhandle
end

-- Widget
function UIHelper.SetWidgetSize(InWidget, InAddExtraSize)
	if InWidget then
		local NewSize = InWidget.Slot:GetSize() + InAddExtraSize
		InWidget.Slot:SetSize(NewSize)
	end
end
function UIHelper.SetWidgetPosY(InWidget, InAddExtraPosY)
	if InWidget then
		local NewPos = InWidget.Slot:GetPosition()
		NewPos.Y = NewPos.Y + InAddExtraPosY
		InWidget.Slot:SetPosition(NewPos)
	end
end

-- 设置控件置灰颜色
function UIHelper.SetToGrey(InWidget, bIsGrey, InGreyColor, bSlateColor)
    if InWidget and InWidget.SetColorAndOpacity then
        local NewColor = bIsGrey and
            (InGreyColor or UIHelper.LinearColor.DarkGrey) or UIHelper.LinearColor.White
        InWidget:SetColorAndOpacity(bSlateColor and UIHelper.ToSlateColor_LC(NewColor) or NewColor)
    end
end

-- 颜色值转换 (FLinearColor -> FSlateColor)
function UIHelper.ToSlateColor_LC(InLinearColor)
    local SlateColor = UE.FSlateColor()
    --SlateColor.ColorUseRule = UE.ESlateColorStylingMode.UseColor_Specified
    SlateColor.SpecifiedColor = InLinearColor
    return SlateColor
end

-------------------------------------------- Global ------------------------------------

_G.UIHelper = UIHelper

return UIHelper
