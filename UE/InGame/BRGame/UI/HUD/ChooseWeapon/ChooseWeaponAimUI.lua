require "UnLua"

local ChooseWeaponAimUI = Class("Common.Framework.UserWidget")

function ChooseWeaponAimUI:InitWeaponAim(WeaponId, MagnificationId, IsMain, ParentUI)
    print("dyptest ChooseWeaponAimUI:InitWeaponAim"..WeaponId..MagnificationId)
    self.CurMagId = MagnificationId
    self.CurWeaponId = WeaponId
    self.IsMain = IsMain
    self.ParentUI = ParentUI

    -- 显示当前选择准镜
    local MagRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.ItemDT, self.CurMagId)
    local ItemIconSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(MagRow.ItemIcon)
    self.Image_SelectIcon:SetBrushFromSoftTexture(ItemIconSoftObjectPtr, false)
    local MagLevel = MagRow.ItemLevel
    self.Image_SelectIcon:SetBrushFromSoftTexture(ItemIconSoftObjectPtr, false)

    -- 等级颜色
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if PickupSetting then
        local BackgroundImagePath = PickupSetting.PickupBGImageMap:Find(MagLevel)
        local BackgroundImage = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(BackgroundImagePath)
        if BackgroundImage then
            self.Image_Background:SetBrushFromSoftTexture(BackgroundImage, true)
            self.Image_Background:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
        end
    end

    -- Bind Click
    print("dyptest ChooseWeaponAimUI:Bind Click")
    self.GUIButton.OnClicked:Add(self, self.OnChangeMag)

    -- 准镜UI更新
    self.MagUIList = UE.TArray(UE.UWidget)
    self.WBP_ReuseList.OnUpdateItem:Add(self, self.OnMagUIUpdate)
    --
end

function ChooseWeaponAimUI:OnChangeMag()
    print("dyptest ChooseWeaponAimUI:OnChangeMag")
    self.WidgetSwitcher_State:SetActiveWidgetIndex(1)
    self:InitAvailableUI(self.CurWeaponId, self.CurMagId)
    -- 尝试更改该准镜，意味者选择了该组合，需要通知上层ParentUI
    self.ParentUI:OnChooseSelf()
end

-- 寻找配置的某把枪的所有准镜
function ChooseWeaponAimUI:GetAllMagnificationsOfWeapon(WeaponId)
    local MatchMagArray = self.MagMatchRule.MatchRuleMap:Find(WeaponId)
    if MatchMagArray == nil then
        print("ChooseWeaponAimUI error! Don't fing match magnificaions for weapon", WeaponId)
        return nil
    end
    if MatchMagArray.ItemIdArray:Length() > 0 then
        for i = 1, MatchMagArray.ItemIdArray:Length() do
            print("ChooseWeaponAimUI MatchMagArray.ItemIdArray", MatchMagArray.ItemIdArray:Get(i))
        end
        return MatchMagArray.ItemIdArray
    end
end

function ChooseWeaponAimUI:InitAvailableUI(WeaponId, MagId)
    self.AvailableMagArray = self:GetAllMagnificationsOfWeapon(WeaponId)
    if self.AvailableMagArray == nil then
        return
    end
    local len = self.AvailableMagArray:Length()
    self.WBP_ReuseList:Reload(len)
end

function ChooseWeaponAimUI:OnMagUIUpdate(Widget, Index)
    local i = Index + 1
    local CurMagWidget = Widget
    local MagId = self.AvailableMagArray:Get(i)

    -- 准镜图标显示
    local MagRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.ItemDT, MagId)
    local MagLevel = MagRow.ItemLevel
    local ItemIconSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(MagRow.ItemIcon)
    CurMagWidget.GUIImageIcon:SetBrushFromSoftTexture(ItemIconSoftObjectPtr, false)

    -- 等级颜色
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if PickupSetting then
        local BackgroundImagePath = PickupSetting.PickupBGImageMap:Find(MagLevel)
        local BackgroundImage = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(BackgroundImagePath)
        if BackgroundImage then
            CurMagWidget.GUIImage_QualityBg:SetBrushFromSoftTexture(BackgroundImage, true)
            CurMagWidget.GUIImage_QualityBg:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
        end
    end

    if MagId == self.CurMagId then
        CurMagWidget:ChangeSelectState(true)
    else
        CurMagWidget:ChangeSelectState(false)
    end
    CurMagWidget:InitSingleAim(MagId, self)
    self.MagUIList:Add(CurMagWidget)
end

-- 选择了某个准镜
function ChooseWeaponAimUI:OnChooseMag(ChooseMagId)
    self.CurMagId = ChooseMagId
    self.ParentUI:OnChangeMagId(self.CurMagId, self.IsMain)

    local len = self.MagUIList:Length()
    for i = 1, len do
        if self.CurMagId == self.MagUIList:Get(i).MagnificationId then
            self.MagUIList:Get(i):ChangeSelectState(true)
        else
            self.MagUIList:Get(i):ChangeSelectState(false)
        end
    end

    -- 状态切换并更改显示准镜
    self.WidgetSwitcher_State:SetActiveWidgetIndex(0)
    local MagRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.ItemDT, self.CurMagId)
    local ItemIconSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(MagRow.ItemIcon)
    local MagLevel = MagRow.ItemLevel
    self.Image_SelectIcon:SetBrushFromSoftTexture(ItemIconSoftObjectPtr, false)

    -- 等级颜色
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if PickupSetting then
        local BackgroundImagePath = PickupSetting.PickupBGImageMap:Find(MagLevel)
        local BackgroundImage = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(BackgroundImagePath)
        if BackgroundImage then
            self.Image_Background:SetBrushFromSoftTexture(BackgroundImage, true)
            self.Image_Background:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
        end
    end

end
--
return ChooseWeaponAimUI

