--[[
	已装备配件皮肤Item
]]
local class_name = "AttachmentSelectItem";
local AttachmentSelectItem = BaseClass(nil, class_name)

function AttachmentSelectItem:OnShow(Param)
    self.Param = Param
end

function AttachmentSelectItem:OnHide()

end

function AttachmentSelectItem:SetItemData(SelectAttchment, Index)
	self.SelectAttachmentId = SelectAttchment
	self.Index = Index

	if SelectAttchment ~= nil then
		self.View.GUIEffectDesc:SetText(StringUtil.Format(SelectAttchment.EffectDesc))
	end
end


function AttachmentSelectItem:Select()
end

function AttachmentSelectItem:UnSelect()

end

return AttachmentSelectItem