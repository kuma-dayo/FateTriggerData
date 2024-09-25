require "UnLua"

local ChooseWeaponAimSingleUI = Class("Common.Framework.UserWidget")

function ChooseWeaponAimSingleUI:InitSingleAim(MagnificationId, ParentUI)
    self.MagnificationId = MagnificationId
    self.ParentUI = ParentUI
    self.GUIButtonItem.OnClicked:Add(self, self.OnChooseMag)
    self.GUIButtonItem.OnHovered:Add(self, self.OnHovered)
    self.GUIButtonItem.OnUnhovered:Add(self, self.OnUnhovered)
end

function ChooseWeaponAimSingleUI:OnChooseMag()
    self.ParentUI:OnChooseMag(self.MagnificationId)
end

function ChooseWeaponAimSingleUI:ChangeSelectState(NewState)
    if NewState then
        self.GUIImageSelect:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.GUIImageSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ChooseWeaponAimSingleUI:OnHovered()
    print("dyptest OnHovered")
    self.ScaleBox:SetRenderScale(UE.FVector2D(self.ScaleNum, self.ScaleNum))
end

function ChooseWeaponAimSingleUI:OnUnhovered()
    print("dyptest OnUnhovered")
    self.ScaleBox:SetRenderScale(UE.FVector2D(1, 1))
end
--
return ChooseWeaponAimSingleUI

