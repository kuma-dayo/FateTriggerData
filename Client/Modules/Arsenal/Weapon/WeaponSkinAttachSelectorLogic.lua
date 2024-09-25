--[[
    配件皮肤选择逻辑
]]

require("Client.Modules.Arsenal.Weapon.AttachmentSelector.AttachmentSelectorLogic")

local class_name = "WeaponSkinAttachSelectorLogic"
WeaponSkinAttachSelectorLogic = WeaponSkinAttachSelectorLogic or BaseClass(AttachmentSelectorLogic, class_name)

function WeaponSkinAttachSelectorLogic:OnShow(Param)
    WeaponSkinAttachSelectorLogic.super.OnShow(self, Param)

    self.View.GUISelectorTitle:SetText(MvcEntry:GetModel(ArsenalModel):GetArsenalText(10016))
    self.View.SizeBoxAttachmentList:SetMaxDesiredHeight(620.0)
    self.View.SizeBoxSelectAttachmentList:SetMaxDesiredHeight(620.0)

    local newOffset = self.View.SelectorCanvas.Slot:GetOffsets()
    newOffset.Top = newOffset.Top - 230
    self.View.SelectorCanvas.Slot:SetOffsets(newOffset)
end

function WeaponSkinAttachSelectorLogic:GetAttachmentList()
    local AttachmentIdList = {}
    table.insert(AttachmentIdList, WeaponModel.RESERVED_ATTACHMENT_SKIN_ID)
    return ListMerge(AttachmentIdList,MvcEntry:GetModel(WeaponModel):GetPartSkinIdListByWeaponAndSlot(self.CurWeaponSkinId,self.CurAttachmentSlot))  
end

function WeaponSkinAttachSelectorLogic:GetAttachmentItemLuaClass()
    return require("Client.Modules.Arsenal.Weapon.WeaponSkinAttachItem")
end

function WeaponSkinAttachSelectorLogic:GetSelectAttachmentId()
    local SelectSkinId = MvcEntry:GetModel(WeaponModel):GetSelectPartSkinIdBySelectPartId(self.CurWeaponSkinId,self.CurAttachmentSlot)
    return SelectSkinId
end



return WeaponSkinAttachSelectorLogic
