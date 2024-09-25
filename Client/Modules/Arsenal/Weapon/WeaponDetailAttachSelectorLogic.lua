--[[
    配件选择通用逻辑
]]

require("Client.Modules.Arsenal.Weapon.AttachmentSelector.AttachmentSelectorLogic")

local class_name = "WeaponDetailAttachSelectorLogic"
WeaponDetailAttachSelectorLogic = WeaponDetailAttachSelectorLogic or BaseClass(AttachmentSelectorLogic, class_name)


function WeaponDetailAttachSelectorLogic:OnShow(Param)
    WeaponDetailAttachSelectorLogic.super.OnShow(self, Param)
    self.TheWeaponModel = MvcEntry:GetModel(WeaponModel)

    self.View.GUISelectorTitle:SetText(StringUtil.Format(MvcEntry:GetModel(ArsenalModel):GetArsenalText(10011)))
    self.View.SizeBoxAttachmentList:SetMaxDesiredHeight(550.0)
    self.View.SizeBoxSelectAttachmentList:SetMaxDesiredHeight(550.0)
end

function WeaponDetailAttachSelectorLogic:GetAttachmentList()
    local AttachmentIdList = {}
    table.insert(AttachmentIdList, WeaponModel.RESERVED_ATTACHMENT_ID)
    return ListMerge(AttachmentIdList, self.TheWeaponModel:GetWeaponSlotAttachmentIdList(self.CurSelectWeaponId, self.CurAttachmentSlot))
end

function WeaponDetailAttachSelectorLogic:GetAttachmentItemLuaClass()
    return require("Client.Modules.Arsenal.Weapon.WeaponDetailAttachItem")
end

function WeaponDetailAttachSelectorLogic:GetSelectAttachmentId()
    local SelectAttachmentId = self.TheWeaponModel:GetSlotEquipAttachmentId(self.CurSelectWeaponId, self.CurAttachmentSlot)
    if SelectAttachmentId then
        CWaring("SelectAttachmentId:" .. SelectAttachmentId)
    end
    return SelectAttachmentId
end



return WeaponDetailAttachSelectorLogic
