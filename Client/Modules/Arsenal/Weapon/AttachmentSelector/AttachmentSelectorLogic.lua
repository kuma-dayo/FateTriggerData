--[[
    配件选择通用逻辑
]]

local class_name = "AttachmentSelectorLogic"
AttachmentSelectorLogic = AttachmentSelectorLogic or BaseClass(nil, class_name)



function AttachmentSelectorLogic:OnInit()
    self.HasKeyFous = false

    self.CurSelectWeaponId = nil

    --插槽列表
    self.AttachmentSlotWidgetList = {}
    self.AttachmentSlotIdx2WidgetList = {}
    --【【战备系统】战备系统配件列表不应该支持拖动】: 设置为垂直
    self.View.WBP_ReuseList_AttachmentSlot.ScrollBoxList:SetOrientation(UE.EOrientation.Orient_Vertical)
    self.View.WBP_ReuseList_AttachmentSlot.OnUpdateItem:Add(self.View,  Bind(self,self.OnUpdateAttachmentSlotItem))
    self.CurAttachmentSlot = Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_INVAILD
    self.IgnoreSwitchShowSlot = false

    --配件列表
    self.AttachmentIdList = {}
    self.AttachmentWidgetList = {}
    self.AttachmentIdx2WidgetList = {}
    self.View.WBP_ReuseList_Attachment.OnUpdateItem:Add(self.View,  Bind(self,self.OnUpdateAttachmentItem))
    self.CurAttachmentId = 0
    self.CurHoverAttachmentIdx = 0
    self.LastHoverAttachmentIdx = 0

    --装备配件效果列表
    self.SelectAttachmentList = {}
    self.SelectAttachmentWidgetList = {}
    self.View.WBP_ReuseList_SelectAttachment.OnUpdateItem:Add(self.View,  Bind(self,self.OnUpdateSelectAttachmentItem))
    self.CurSelectAttachmentId = 0

    self.BindNodes = 
    {
		{ UDelegate = self.View.GUIButtonBgClose.OnClicked,				    Func =  Bind(self,self.OnButtonBgCloseClicked) },
	}

    self.MsgList = 
    {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = Bind(self,self.OnEscClicked) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.W), Func = Bind(self,self.OnHoverSwitchAttachment,-1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.S), Func = Bind(self,self.OnHoverSwitchAttachment,1)},
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.SpaceBar), Func = Bind(self,self.OnSelectAttachment)},
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A), Func = Bind(self,self.OnSwitchAttachmentSlot,-1)},
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self,self.OnSwitchAttachmentSlot,1)},

        {Model = WeaponModel,  MsgName = WeaponModel.ON_SELECT_ATTACHMENT,      Func = Bind(self, self.OnUpdateAttachmentList) },
        {Model = WeaponModel,  MsgName = WeaponModel.ON_SELECT_ATTACHMENT_SKIN,      Func = Bind(self, self.OnUpdateAttachmentSkinList) },
        {Model = WeaponModel,  MsgName = WeaponModel.ON_BUY_ATTACHMENT_SKIN,      Func = Bind(self, self.OnBuyAttachmentSkin) },
	}
end

function AttachmentSelectorLogic:OnShow(Param)
    
end


function AttachmentSelectorLogic:OnHide()
    self.CurSelectWeaponId = nil
end

function AttachmentSelectorLogic:UpdateShowData(SelectWeaponId, SelectWeaponSkinId)
    local TheWeaponModel = MvcEntry:GetModel(WeaponModel)
    local IsWeaponIdChange = false
    if self.CurSelectWeaponId and self.CurSelectWeaponId ~= SelectWeaponId then
        IsWeaponIdChange = true
    end
    self.CurSelectWeaponId = SelectWeaponId
    self.CurWeaponSkinId = SelectWeaponSkinId or TheWeaponModel:GetWeaponSkinId(SelectWeaponId)
    self.CanShowSelectAttachmentList = SelectWeaponSkinId == nil and true or false
    self.CurAttachmentSlot = Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_INVAILD
    self.LastAttachmentSlotType = Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_INVAILD

     local WeaponCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponConfig, SelectWeaponId)
     self.AvailableSlotTypeList = WeaponCfg and WeaponCfg[Cfg_WeaponConfig_P.ShowSlotList] and WeaponCfg[Cfg_WeaponConfig_P.ShowSlotList]:ToTable() or {}
     table.sort(self.AvailableSlotTypeList, function(Slot1, Slot2) 
        local Slot1Cfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSlotConfig, Slot1)
        local Slot2Cfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSlotConfig, Slot2)
        return Slot1Cfg[Cfg_WeaponPartSlotConfig_P.SortId] < Slot2Cfg[Cfg_WeaponPartSlotConfig_P.SortId]
    end )

    if IsWeaponIdChange then
        --武器变动（注意不是皮肤）  需要重置装配件的装配Cache信息
        TheWeaponModel:ClearSlotEquipAttachmentId(self.CurSelectWeaponId)

        --将武器Avatar展示置回默认
        for i, SlotType in ipairs(self.AvailableSlotTypeList) do
            local Param = {
                SlotType = SlotType,
                AvatarId = 0,
                IsAdd = false
            }
            local AvatarId = TheWeaponModel:GetSelectPartSkinIdBySelectPartId(SelectWeaponSkinId,SlotType)
            if not AvatarId or AvatarId <= 0 then
                AvatarId = TheWeaponModel:GetAvatartIdShowByWeaponSkinIdAndSlotType(self.CurWeaponSkinId,SlotType)
            end
            if AvatarId and AvatarId > 0 then
                Param.AvatarId = AvatarId
                Param.IsAdd = true
            else
                Param.AvatarId = 0
                Param.IsAdd = false
            end
            TheWeaponModel:DispatchType(WeaponModel.ON_WEAPON_AVATAR_PREVIEW_UPDATE, Param)
        end
    end
end

function AttachmentSelectorLogic:CanShowAttachmentSlotList()
    local AvailableSlot = #self.AvailableSlotTypeList
    return AvailableSlot > 0
end

function AttachmentSelectorLogic:ShowAttachmentSlotList(IsShow)
    if not self:CanShowAttachmentSlotList() or not IsShow then
        self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:ShowAttachmentList(false)
        self:ShowSelectAttachmentList(false)
    else
        self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:UpdateAttachmentSlot()
        self:ShowAttachmentList(false)
    end
end

function AttachmentSelectorLogic:ShowAttachmentList(IsShow)
    self.IsShowAttachmentList = IsShow
    if not IsShow then
        self.View.WidgetSwitcherList:SetVisibility(UE.ESlateVisibility.Collapsed)
        --取消选中插槽
        self.CurAttachmentSlot = Pb_Enum_WEAPON_SLOT_TYPE.WEAPON_SLOT_INVAILD
        if self.CurAttachmentSlotItem then
            self.CurAttachmentSlotItem:UnSelect()
        end
    else
        self.View.WidgetSwitcherList:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.WidgetSwitcherList:SetActiveWidgetIndex(0)
        self:UpdateAttchmentList()
    end

    self:ShowSelectAttachmentList(not IsShow)

    self:UpdateBgCloseVisibility(IsShow)

    if not IsShow then
        self:SetKeyEventFocus(false)
    end
end

function AttachmentSelectorLogic:UpdateBgCloseVisibility(bVisible)
	self.View.GUIButtonBgClose:SetVisibility(bVisible and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed) 
end


function AttachmentSelectorLogic:SetKeyEventFocus(Focus)
    self.HasKeyFous = Focus
end


function AttachmentSelectorLogic:ShowSelectAttachmentList(IsShow)
    if not self.CanShowSelectAttachmentList or not IsShow then
        --self.View.WidgetSwitcherList:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.View.WidgetSwitcherList:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.WidgetSwitcherList:SetActiveWidgetIndex(1)
        self:UpdateSelectAttachmentList()
    end
end

--[[
    配件槽位列表
]]
function AttachmentSelectorLogic:UpdateAttachmentSlot()
    if #self.AvailableSlotTypeList > 0 then
        self.View.WBP_ReuseList_AttachmentSlot:Reload(#self.AvailableSlotTypeList)
    end
end

function AttachmentSelectorLogic:CreateAttachmentSlotItem(Widget, Index)
	local Item = self.AttachmentSlotWidgetList[Widget]
	if not Item then
		local Param = {
			OnItemClick = Bind(self,self.OnAttachmentSlotItemClicked),
            OnItemHover = Bind(self,self.OnAttachmentSlotItemHover),
            OnItemUnHover = Bind(self,self.OnAttachmentSlotItemUnHover),
            Handler = self
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Arsenal.Weapon.AttachmentSelector.AttachmentSlotItem"), Param)
		self.AttachmentSlotWidgetList[Widget] = Item
	end
    self.AttachmentSlotIdx2WidgetList[Index] = Item
	return Item.ViewInstance
end

function AttachmentSelectorLogic:OnAttachmentSlotItemHover(Slot)
    self:SwitchHoverAttachSlot(Slot, true)
end

function AttachmentSelectorLogic:OnAttachmentSlotItemUnHover(Slot)
    if self.CurAttachmentSlot == Slot then
        return
    end
    self:SwitchHoverAttachSlot(Slot, false)
end

function AttachmentSelectorLogic:OnAttachmentSlotItemClicked(Widget, AttachmentSlotType, Index)
    self.LastAttachmentSlotType = self.CurAttachmentSlot
    self.CurAttachmentSlot = AttachmentSlotType
    self.CurHoverAttachmentIdx = 0

    self:OnSelectAttachmentSlotItem(Widget)
    
    self:SwitchPreviewAttachSlot()
end

function AttachmentSelectorLogic:OnSelectAttachmentSlotItem(Item)
	if self.CurAttachmentSlotItem then
		self.CurAttachmentSlotItem:UnSelect()
	end
	self.CurAttachmentSlotItem = Item
	if self.CurAttachmentSlotItem then
		self.CurAttachmentSlotItem:Select()
	end

    if self.LastAttachmentSlotType == self.CurAttachmentSlot then
        if not self.IgnoreSwitchShowSlot then
            self:ShowAttachmentList(not self.IsShowAttachmentList)
        end
    else 
        self:ShowAttachmentList(self.HasKeyFous)
    end
end

function AttachmentSelectorLogic:OnUpdateAttachmentSlotItem(Handler, Widget, Index)
	local i = Index + 1
	local AttachmentSlotType = self.AvailableSlotTypeList[i]
	local ListItem = self:CreateAttachmentSlotItem(Widget, i)
	if ListItem == nil then
		return
	end

    if AttachmentSlotType == self.CurAttachmentSlot then
		self:OnSelectAttachmentSlotItem(ListItem)
	else 
		ListItem:UnSelect()
	end
	ListItem:SetItemData(AttachmentSlotType, i)
end


--切换预览插槽
function AttachmentSelectorLogic:SwitchPreviewAttachSlot()
    local TheWeaponModel = MvcEntry:GetModel(WeaponModel)
    if self.IsShowAttachmentList then
        local Param = {
            SlotType = self.CurAttachmentSlot,
            LastSlotType =  self.LastAttachmentSlotType
        }
        TheWeaponModel:DispatchType(WeaponModel.ON_CLICK_SELECT_ATTACHMENT_SLOT, Param)
    else
        local Param = { 
            SlotType = self.CurAttachmentSlot,
        }
        TheWeaponModel:DispatchType(WeaponModel.ON_CLICK_CLOSE_ATTACHMENT_SLOT, Param)
    end
end

--切换HOVER槽位
function AttachmentSelectorLogic:SwitchHoverAttachSlot(Slot, Hover)
    local TheWeaponModel = MvcEntry:GetModel(WeaponModel)
    local Param = {
        SlotType = Slot,
        IsHover = Hover,
        IsSelected = (self.CurAttachmentSlot == Slot)
    }
    TheWeaponModel:DispatchType(WeaponModel.ON_HOVER_SELECT_ATTACHMENT_SLOT, Param)
end


--[[
    配件列表
]]

function AttachmentSelectorLogic:GetAttachmentList()
    --需要覆写
end

function AttachmentSelectorLogic:GetAttachmentItemLuaClass()
    --需要覆写
end

function AttachmentSelectorLogic:GetSelectAttachmentId()
    --需要覆写
end

------------------------------------AttchmentList >>

function AttachmentSelectorLogic:UpdateAttchmentList()
    self.CurAttachmentId = self:GetSelectAttachmentId()
    self.AttachmentIdList = self:GetAttachmentList()
    if #self.AttachmentIdList > 0 then
        self.View.WBP_ReuseList_Attachment:Reload(#self.AttachmentIdList)
    end
end


function AttachmentSelectorLogic:CreateAttachmentItem(Widget, Idx)
	local Item = self.AttachmentWidgetList[Widget]
	if not Item then
		local Param = {
			OnItemClick = Bind(self,self.OnAttachmentItemClicked),
            ReqGetCurAttachmentId = Bind(self, self.GetSelectAttachmentId),
            Handler = self,
		}
		Item = UIHandler.New(self, Widget, self:GetAttachmentItemLuaClass(), Param)
		self.AttachmentWidgetList[Widget] = Item
	end
    self.AttachmentIdx2WidgetList[Idx] = Item
	return Item.ViewInstance
end

function AttachmentSelectorLogic:OnAttachmentItemClicked(Widget, AttachmentId, Index)
    self.CurAttachmentId = AttachmentId
	self:OnSelectAttachmentItem(Widget)
end

function AttachmentSelectorLogic:OnSelectAttachmentItem(Item)
	if self.CurAttachmentItem then
		self.CurAttachmentItem:UnSelect()
	end
	self.CurAttachmentItem = Item
	if self.CurAttachmentItem then
		self.CurAttachmentItem:Select()
	end
end

function AttachmentSelectorLogic:OnUpdateAttachmentItem(Handler, Widget, Index)
	local i = Index + 1
	local AttachmentId = self.AttachmentIdList[i]
	local ListItem = self:CreateAttachmentItem(Widget, i)
	if ListItem == nil then
		return
	end

    ListItem:SetItemData(AttachmentId, i, self.CurAttachmentSlot, self.CurHoverAttachmentIdx)

    if AttachmentId == self.CurAttachmentId then
		-- self:OnSelectAttachmentItem(ListItem)
        self.CurAttachmentItem = ListItem
        ListItem:Select()
	else 
		ListItem:UnSelect()
	end
end

function AttachmentSelectorLogic:UpdateHoverItem(Idx)
    local WidgetItem = self.AttachmentIdx2WidgetList[self.CurHoverAttachmentIdx]
    if WidgetItem ~= nil and WidgetItem.ViewInstance ~= nil then
        WidgetItem.ViewInstance:SetUnhover()
    end
    self.CurHoverAttachmentIdx = Idx
    WidgetItem = self.AttachmentIdx2WidgetList[self.CurHoverAttachmentIdx]
    if WidgetItem ~= nil and WidgetItem.ViewInstance ~= nil then
        WidgetItem.ViewInstance:SetHover()
    end
end

------------------------------------AttchmentList <<


--[[
    装备配件效果列表
]]
function AttachmentSelectorLogic:UpdateSelectAttachmentList()
    self.SelectAttachmentList = {}
    local SelectAttachmentList = MvcEntry:GetModel(WeaponModel):GetWeaponAttachmentIdList(self.CurSelectWeaponId)
    for _, v in pairs(SelectAttachmentList) do
        local WeaponPartCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponPartConfig, Cfg_WeaponPartConfig_P.PartId, v)  
        if WeaponPartCfg ~= nil then
            local Slot = WeaponPartCfg[Cfg_WeaponPartConfig_P.SlotType]
            local EffectDesc1 = WeaponPartCfg[Cfg_WeaponPartConfig_P.EffectDesc1]
            local EffectDesc2 = WeaponPartCfg[Cfg_WeaponPartConfig_P.EffectDesc2]
            local EffectDesc3 = WeaponPartCfg[Cfg_WeaponPartConfig_P.EffectDesc3]
            local EffectDesc4 = WeaponPartCfg[Cfg_WeaponPartConfig_P.EffectDesc4]
            if StringUtil.ConvertFText2String(EffectDesc1) ~= "" then
                table.insert(self.SelectAttachmentList, {AttachmentId = v, Slot = Slot, EffectDesc = EffectDesc1, SortId = 1})
            end
            if StringUtil.ConvertFText2String(EffectDesc2) ~= "" then
                table.insert(self.SelectAttachmentList, {AttachmentId = v, Slot = Slot, EffectDesc = EffectDesc2, SortId = 2})
            end
            if StringUtil.ConvertFText2String(EffectDesc3) ~= "" then
                table.insert(self.SelectAttachmentList, {AttachmentId = v, Slot = Slot, EffectDesc = EffectDesc3, SortId = 3})
            end
            if StringUtil.ConvertFText2String(EffectDesc4) ~= "" then
                table.insert(self.SelectAttachmentList, {AttachmentId = v, Slot = Slot, EffectDesc = EffectDesc4, SortId = 4})
            end
        end 
    end
    table.sort(self.SelectAttachmentList, function(A, B)
        if A.Slot ~= B.Slot then
            return A.Slot < B.Slot
        end
        if A.AttachmentId ~= B.AttachmentId then
            return A.AttachmentId < B.AttachmentId
        end
        return A.SortId < B.SortId
    end)
    self.View.WBP_ReuseList_SelectAttachment:Reload(#self.SelectAttachmentList)
end

function AttachmentSelectorLogic:CreateSelectAttachmentItem(Widget, LuaClass)
	local Item = self.SelectAttachmentWidgetList[Widget]
	if not Item then
        local Param = {
            WeaponId = self.CurSelectWeaponId,
            WeaponSkinId = self.CurWeaponSkinId, 
            Slot = self.CurAttachmentSlot,
			OnItemClick = Bind(self,self.OnAttachmentItemClicked),
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Arsenal.Weapon.AttachmentSelector.AttachmentSelectItem"), Param)
		self.SelectAttachmentWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end

function AttachmentSelectorLogic:OnUpdateSelectAttachmentItem(Handler, Widget, Index)
	local i = Index + 1
	local SelectAttchment = self.SelectAttachmentList[i]
	local ListItem = self:CreateSelectAttachmentItem(Widget)
	if ListItem == nil then
		return
	end

    if SelectAttchment.AttchmentId == self.CurSelectAttachmentId then
		ListItem:Select()
	else 
		ListItem:UnSelect()
	end
	ListItem:SetItemData(SelectAttchment, i)
end


function AttachmentSelectorLogic:OnButtonBgCloseClicked()
	self:ShowAttachmentList(false)
    self:SwitchPreviewAttachSlot()
end

--键盘交互逻辑
function AttachmentSelectorLogic:OnEscClicked()
    if not self.HasKeyFous then
        return 
    end
    self:ShowAttachmentList(false)
    self:SwitchPreviewAttachSlot()
    return true
end

function AttachmentSelectorLogic:OnHoverSwitchAttachment(Direction)
    if not self.HasKeyFous then
        return 
    end
    self.LastHoverAttachmentIdx = self.CurHoverAttachmentIdx
    if Direction > 0 then 
        self.CurHoverAttachmentIdx = self.CurHoverAttachmentIdx + 1
        self.CurHoverAttachmentIdx = self.CurHoverAttachmentIdx <= #self.AttachmentIdList and self.CurHoverAttachmentIdx or 1
	else 
		self.CurHoverAttachmentIdx = self.CurHoverAttachmentIdx - 1
        self.CurHoverAttachmentIdx = self.CurHoverAttachmentIdx <= 0 and #self.AttachmentIdList or self.CurHoverAttachmentIdx
	end
    self.View.WBP_ReuseList_Attachment:RefreshOne(self.LastHoverAttachmentIdx-1)
    self.View.WBP_ReuseList_Attachment:RefreshOne(self.CurHoverAttachmentIdx-1)
    self.View.WBP_ReuseList_Attachment:JumpByIdxStyle(self.CurHoverAttachmentIdx-1, UE.EReuseListJumpStyle.Content)
    
    return true
end


function AttachmentSelectorLogic:OnSelectAttachment()
    if not self.HasKeyFous then
        return 
    end
    local WidgetItem = self.AttachmentIdx2WidgetList[self.CurHoverAttachmentIdx]
    if WidgetItem ~= nil and WidgetItem.ViewInstance ~= nil then
        WidgetItem.ViewInstance:OnItemClicked()
    end
    return true
end


function AttachmentSelectorLogic:OnSwitchAttachmentSlot(Direction)
    if not self.HasKeyFous then
        return 
    end
    
    local Idx, Slot = 0,0
	if Direction > 0 then 
		Idx,Slot = CommonUtil.GetListNextIndex4Id(self.AvailableSlotTypeList, self.CurAttachmentSlot)
	else 
		Idx,Slot = CommonUtil.GetListPreIndex4Id(self.AvailableSlotTypeList, self.CurAttachmentSlot)
	end
    local WidgetItem = self.AttachmentSlotIdx2WidgetList[Idx] and self.AttachmentSlotIdx2WidgetList[Idx].ViewInstance or nil
    if WidgetItem then
        self:OnAttachmentSlotItemClicked(WidgetItem, Slot, Idx)
    end

    return true
end

function AttachmentSelectorLogic:OnUpdateAttachmentList(Attachment)
    self.IgnoreSwitchShowSlot = true
    self.View.WBP_ReuseList_AttachmentSlot:Refresh()
    self.IgnoreSwitchShowSlot = false

    self.View.WBP_ReuseList_Attachment:Refresh()
    self.View.WBP_ReuseList_SelectAttachment:Refresh()
end

function AttachmentSelectorLogic:OnUpdateAttachmentSkinList()
    self.IgnoreSwitchShowSlot = true
    self.View.WBP_ReuseList_AttachmentSlot:Refresh()
    self.IgnoreSwitchShowSlot = false

    self.View.WBP_ReuseList_Attachment:Refresh()
end

function AttachmentSelectorLogic:OnBuyAttachmentSkin()
    local WidgetItem = self.AttachmentIdx2WidgetList[self.CurHoverAttachmentIdx]
    if WidgetItem ~= nil and WidgetItem.ViewInstance ~= nil then
        WidgetItem.ViewInstance:OnItemClicked()
    end
end




return AttachmentSelectorLogic
