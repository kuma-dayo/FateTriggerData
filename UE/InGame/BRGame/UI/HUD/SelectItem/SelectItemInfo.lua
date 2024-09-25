--
-- 战斗界面 - 选择物品信息
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.31
--
local SelectItemInfo = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Init/Destroy ------------------------------------

function SelectItemInfo:OnInit()
    self.ItemCfgData = {}
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.LocalPCBag = UE.UBagComponent.Get(self.LocalPC)

	UserWidget.OnInit(self)
end

function SelectItemInfo:OnDestroy()
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------

--[[
    return: { ItemName, ItemDesc, ItemNum }
]]
function SelectItemInfo:GetItemCfgData()
    return self.ItemCfgData
end

-- 控制Item图标图片缩放大小的
function SelectItemInfo:SetItemRenderScale(InScale)
    print("SelectItemInfo::SetItemRenderScale-->InScale.X:", InScale.X, "InScale.Y:", InScale.Y)
    local FVector2DData = UE.FVector2D(InScale.X, InScale.Y)
    self.ImgIcon:SetRenderScale(FVector2DData)
    self.Image_Line:SetRenderScale(FVector2DData)
    --self.TxtNum:SetRenderScale(InScale)
end

function SelectItemInfo:SetItemPicColorAndOpacity(InR, InG, InB, InA)
    print("SelectItemInfo::SetItemPicColorAndOpacity-->R:", InR, "G:", InG, "B:", InB, "A:", InA)
    local ValueToSet = UE.FLinearColor(InR, InG, InB, InA)
    self:SetItemPicLinearColor(ValueToSet)
end


function SelectItemInfo:SetItemPicLinearColor(LinerColor)
    self.ImgIcon:SetColorAndOpacity(LinerColor)
    self.Image_Line:SetColorAndOpacity(LinerColor)

    local SlateColorToSet = UE.FSlateColor()
    SlateColorToSet.SpecifiedColor = LinerColor
    self.TxtNum:SetColorAndOpacity(SlateColorToSet)
    self.NameTxt:SetColorAndOpacity(SlateColorToSet)
end

-------------------------------------------- Function ------------------------------------

function SelectItemInfo:InitData(InParameters, InIndex, InItemType)
    self.ItemCfgData = {
        Index = InIndex,
    }
	self.Parameters = InParameters
    if InParameters.Texture then
        --self.ImgIcon:SetBrushFromSoftTexture(InParameters.Texture, false)
        if InItemType == UE.ESelectItemType.MarkSystem or InItemType == UE.ESelectItemType.AvatarAction then
            -- 不属于消耗品的 没有数字和斜杠
            --self.ImgIcon:GetDynamicMaterial():SetScalarParameterValue("CutB", 0.0)
            --self.ImgIcon:GetDynamicMaterial():SetScalarParameterValue("CutK", 999)
            self.Image_Line:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.TxtNum:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.ImgIcon:GetDynamicMaterial():SetTextureParameterValue("BackgroundTexture", InParameters.Texture)
        end
        
        -- local ItemId = InParameters and InParameters.ItemId or nil
        -- local NewVisible = (ItemId and ItemId > 0) and
        -- 	UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
        self:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

        -- 未选中的图标都是原尺寸的80%       
        local ScaleSize = {
                X = 0.85, Y = 0.85
        }
        print("SelectItemInfo::InitData-->SetItemRenderScale at 80%     #d0854d")
        --self:SetItemRenderScale(ScaleSize)
       -- self:SetItemPicColorAndOpacity(0.630757, 0.234551, 0.074214, 1.0)	-- 颜色：#d0854d
        self:SetItemPicLinearColor(self.InitColor)	-- 颜色：#d0854d
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function SelectItemInfo:SetSelectColor()
    self:SetItemPicLinearColor(self.SelectColor) -- 颜色：#fffaee
end

function SelectItemInfo:SetUnselectColor()
    self:SetItemPicLinearColor(self.UnSelectColor) -- 颜色：#d0854d
end

function SelectItemInfo:PlayItemSelectVXE(InType, bIsSelect)
    if bIsSelect then
        self:VXE_IconSelect_Img_In()
    else
        self:VXE_IconSelect_Img_Out()
    end
end

-------------------------------------------- Callable ------------------------------------

function SelectItemInfo:SetNumText(InText,InColor)
    if InText == 0 then
        -- self.TxtNum:SetRenderOpacity(0.4)
        -- self.ImgIcon:SetRenderOpacity(0.4)
        -- self.Image_Line:SetRenderOpacity(0.4)
        self.TxtNum:SetRenderOpacity(self.NotOwnedOpacity)
        self.ImgIcon:SetRenderOpacity(self.NotOwnedOpacity)
        self.Image_Line:SetRenderOpacity(self.NotOwnedOpacity)
    else
        -- self.TxtNum:SetRenderOpacity(1.0)
        -- self.ImgIcon:SetRenderOpacity(1.0)
        -- self.Image_Line:SetRenderOpacity(1.0)
        self.TxtNum:SetRenderOpacity(self.OwnedOpacity)
        self.ImgIcon:SetRenderOpacity(self.OwnedOpacity)
        self.Image_Line:SetRenderOpacity(self.OwnedOpacity)
    end
    
    if InText then
        self.TxtNum:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.TxtNum:SetText(InText)
        -- 不要在这里设置字体颜色，否则会覆盖策划的颜色叠加
        --self.TxtNum:SetColorAndOpacity(InColor)
    else
        self.TxtNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function SelectItemInfo:SetInfiniteState(InState)
    if InState then
        -- 设置数字
        self.WidgetSwitcherNum:SetActiveWidgetIndex(1)
    else
        -- 设置无限
        self.WidgetSwitcherNum:SetActiveWidgetIndex(0)
    end
end

function SelectItemInfo:SetNameText(InText,InColor)
    print("SelectItemInfo:SetNameText-->xuyanzu",InText)
    if InText then
        self.NameTxt:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.NameTxt:SetText(InText)
        self.NameTxt:SetColorAndOpacity(InColor)
    else
        self.NameTxt:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

return SelectItemInfo
