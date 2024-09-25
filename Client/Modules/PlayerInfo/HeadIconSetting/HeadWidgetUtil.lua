--[[
    头像挂件创建相关参数和方法
]]
local HeadWidgetUtil = {}

-- 头像挂件基准尺寸 （以WBP_HeadDetailWidget头像尺寸为标准）
-- 默认底框大小
HeadWidgetUtil.DefaultSize = 248
-- 不显示头像时，空底背景大小
HeadWidgetUtil.EmptyBgSize = 230
-- 外限制框大小
HeadWidgetUtil.DefaultLimit = 380
-- -- 默认缩放
-- HeadWidgetUtil.ParentScale = 1

--[[
    创建头像挂件
    WidgetList = {
        [1] = {
            HeadWidgetId,
            Angle,
            Cfg,
        }
    }
    Scale: 以挂件设置界面尺寸为基准，传入的等比缩放值。
]]
function HeadWidgetUtil.CreateHeadWidgets(WidgetContainer,Outter,WidgetList,Scale)
    if not WidgetContainer then
        CError(" HeadWidgetUtil.CreateHeadWidgets Need A Container",true)
        return
    end
    if not WidgetList or #WidgetList == 0 then
        WidgetContainer:ClearChildren()
        return
    end
    local WBP_HeadWidgetTempCls = UE.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/Item/WBP_HeadWidgetTemp.WBP_HeadWidgetTemp")
    if not WBP_HeadWidgetTempCls then
        CError("HeadWidgetUtil.CreateHeadWidgets Load WBP_HeadWidgetTemp Error",true)
        return
    end
    
    Scale = Scale or 1
    local Index = 1
    for I, WidgetInfo in ipairs(WidgetList) do
        local Child = WidgetContainer:GetChildAt(Index - 1)
        if not Child then
            Child = NewObject(WBP_HeadWidgetTempCls, Outter, nil)
            WidgetContainer:AddChild(Child)
            Child.Slot:SetMinimum(UE.FVector2D(0,0))
            Child.Slot:SetMaximum(UE.FVector2D(1,1))
            Child.Slot:SetOffsets(UE.FMargin())
            Child.Slot:SetAlignment(UE.FVector2D(0.5))
            Child.ScaleBox:SetUserSpecifiedScale(Scale)
        end
        local InitRotation = WidgetInfo.Cfg[Cfg_HeadWidgetCfg_P.InitRotation]
        local RotationAngle = InitRotation + WidgetInfo.Angle
        Child.Bg:SetRenderTransformAngle(RotationAngle)
        local IsStatic = WidgetInfo.Cfg[Cfg_HeadWidgetCfg_P.WidgetType] == HeadIconSettingModel.HeadWidgetType.Static
        local WidgetRotationAngle = IsStatic and -RotationAngle or -InitRotation
        Child.Panel_Widget:SetRenderTransformAngle(WidgetRotationAngle)
        CommonUtil.SetBrushFromSoftObjectPath(Child.Icon,WidgetInfo.Cfg[Cfg_HeadWidgetCfg_P.IconPath],true)
        local PaddingCfg = WidgetInfo.Cfg[Cfg_HeadWidgetCfg_P.SelectPadding]
        Child.Panel_Select.Slot.Padding.Left = PaddingCfg[1]*Scale
        Child.Panel_Select.Slot.Padding.Top = PaddingCfg[2]*Scale
        Child.Panel_Select.Slot.Padding.Right = PaddingCfg[3]*Scale
        Child.Panel_Select.Slot.Padding.Bottom = PaddingCfg[4]*Scale
        Child.Panel_Select.Slot:SetPadding(Child.Panel_Select.Slot.Padding)
        HeadWidgetUtil.AdjustHeadWidget(IsStatic, WidgetContainer, Child, Scale, RotationAngle)
        Index = Index + 1
    end
    while WidgetContainer:GetChildAt(Index - 1) do
        WidgetContainer:RemoveChildAt(Index - 1)
    end
end

-- 用于有一个外框，限制挂件的范围，超出范围，要将其位置挪入框内
function HeadWidgetUtil.AdjustHeadWidget(IsStatic, WidgetContainer, Child, Scale, RotationAngle) 
    local Padding = UE.FMargin(0,0,0,0)
    if IsStatic then
        Scale = Scale or 1
        local BgSize = WidgetContainer.Slot:GetSize()
        local X = -math.sin(math.rad(RotationAngle))* BgSize.X /2
        local Y = -math.cos(math.rad(RotationAngle))* BgSize.Y /2
        local Limit = HeadWidgetUtil.DefaultLimit * Scale / 2
        Child.Icon:ForceLayoutPrepass()
        local IconSize = Child.Icon:GetDesiredSize()
        local SelectPadding = Child.Panel_Select.Slot.Padding
        local IconLeft = (IconSize.X / 2 - SelectPadding.Left) 
        local IconRight = (IconSize.X / 2 - SelectPadding.Right) 
        local IconTop = (IconSize.Y / 2 - SelectPadding.Top) 
        local IconBottom = (IconSize.Y / 2 - SelectPadding.Bottom) 

        local Left = X - IconLeft * Scale 
        local Right = X + IconRight * Scale 
        local Top = Y + IconTop * Scale
        local Bottom = Y - IconBottom * Scale
        if Right > Limit then
            Padding.Right = Right - Limit
            Padding.Left = -Padding.Right
        elseif Left < -Limit then
            Padding.Left = -Left - Limit
            Padding.Right = -Padding.Left
        end

        if Top > Limit then
            Padding.Top = Top - Limit
            Padding.Bottom =  -Padding.Top
        elseif Bottom < -Limit then
            Padding.Bottom =  -Bottom - Limit 
            Padding.Top = -Padding.Bottom
        end
    end
    Child:SetPadding(Padding)
end


return HeadWidgetUtil