--[[
    载具皮肤贴纸插槽已满界面
]]

local class_name = "VehicleSkinStickerFullMdt";
VehicleSkinStickerFullMdt = VehicleSkinStickerFullMdt or BaseClass(GameMediator, class_name);


function VehicleSkinStickerFullMdt:__init()
end

function VehicleSkinStickerFullMdt:OnShow(data)
end

function VehicleSkinStickerFullMdt:OnHide()

end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
	self.BindNodes = 
    {
		 { UDelegate = self.ReuseList_StickerSlot.OnUpdateItem,	Func = self.OnUpdateSlotItem },
	}
	
	self.MsgList = 
	{
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked},
		{Model = VehicleModel, MsgName = VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER_LIST, Func = self.ON_UPDATE_VEHICLE_SKIN_STICKER_LIST},
	}
	self.SlotItemWidgetList = {}
	self.TheVehicleModel = MvcEntry:GetModel(VehicleModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
end


--由mdt触发调用
function M:OnShow(data)
	self.CurSelectVehicleId = data.VehicleId or 0
	self.CurSelectVehicleSkinId = data.VehicleSkinId or 0
	self.CurEditStickerInfo = data.StickerInfo
	self.CurSelectSlot = 0
	self:InitCommonUI()
end

function M:OnShowAvator()
	self.TheVehicleModel:DispatchType(VehicleModel.ON_OPEN_VEHICLE_SKIN_STICKER_SHOW, 
	{

	})
end


function M:InitCommonUI()
	--通用Touch输入
	UIHandler.New(self, self.WBP_Common_TouchInput, CommonTouchInput, 
	{

	})

	local StickerEditParam = 
	{
		VehicleId = self.CurSelectVehicleId,
		VehicleSkinId = self.CurSelectVehicleSkinId,
	}
	self.StickerEditInst = UIHandler.New(self, self.WBP_VehicleSkinSticker_Edit, 
			require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerEdit"), StickerEditParam).ViewInstance

	self.ReplaceSlotInst = UIHandler.New(self,self.WBP_CommonBtn_Strong_S, WCommonBtnTips, 
	{
		OnItemClick = Bind(self,self.OnSlotReplaceClicked),
		CommonTipsID = CommonConst.CT_SPACE,
		TipStr = self.TheArsenalModel:GetArsenalText(10040),
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
		ActionMappingKey = ActionMappings.SpaceBar,
	}).ViewInstance
	
	UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
    })

	 UIHandler.New(self,self.CommonBtnTips_Rotate, WCommonBtnTips, 
	 {
		 CommonTipsID = CommonConst.CT_ROTATE,
		 HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
		 TipStr = self.TheArsenalModel:GetArsenalText("10045_Btn"),
		 ActionMappingKey = ActionMappings.LeftMouseButton,
	 })

	self.WidgetSwitcherBuy:SetActiveWidgetIndex(0)

	local MaxStickerSlotNum = self.TheVehicleModel:GetVehilceSkinStickerMaxSlot(self.CurSelectVehicleSkinId)
	if MaxStickerSlotNum == 1 then
		self.SlotOne:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.SlotList:SetVisibility(UE.ESlateVisibility.Collapsed)

		self:UpdateOneSlot()
	else
		self.SlotOne:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.SlotList:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

		self:UpdateSlotList()
	end

	local IsEnough = self.TheVehicleModel:IsStickerEnough(self.CurSelectStickerId)
	if not IsEnough then
		local StickerShortageParam = 
		{
			CallReplaceFunc = Bind(self, self.OnStickerReplaceClicked),
			CallCloseFunc = Bind(self, self.OnStickerShortageCloseClicked)
		}
		self.StickerShortageInst = UIHandler.New(self, self.WBP_VehicleSkinSticker_Shortage, 
				require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerShortageLogic"), StickerShortageParam).ViewInstance
	end

	self:UpdateSlotButtonState()
end

function M:UpdateSlotButtonState()
	if self.ReplaceSlotInst == nil then
		return
	end

	self.ReplaceSlotInst:SetBtnEnabled(self.CurSelectSlot ~= 0)
end


function M:UpdateOneSlot()
	local Param = {
		VehicleSkinId = self.CurSelectVehicleSkinId,
		OnItemClick = Bind(self,self.OnSlotItemClick)
	}
	self.OneSlotInst = UIHandler.New(self, self.WBP_VehicleSkinSticker_Item, 
		require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerSlotItem"), Param).ViewInstance
	if self.OneSlotInst ~= nil then
		self.OneSlotInst:SetItemData(1)
	end
end

function M:UpdateSlotList()
	self.SlotIdList = {}
	local MaxStickerSlotNum = self.TheVehicleModel:GetVehilceSkinStickerMaxSlot(self.CurSelectVehicleSkinId)
	for Slot=1, MaxStickerSlotNum do
		table.insert(self.SlotIdList, Slot)
	end
	self.ReuseList_StickerSlot:Reload(#self.SlotIdList)
end

function M:CreateSlotItem(Widget)
	local Item = self.SlotItemWidgetList[Widget]
	if not Item then
		local Param = {
			VehicleSkinId = self.CurSelectVehicleSkinId,
			OnItemClick = Bind(self,self.OnSlotItemClick)
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerSlotItem"), Param)
		self.SlotItemWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end

function M:OnSlotItemClick(Item, VehicleSkinId, Slot)
	if Item == nil or Slot == nil then 
		return
	end
	if self.CurSelectSlot ~= 0 then
		self:UpdateEditStickerStateShow(self.CurSelectSlot, false)
	end
	self.CurSelectSlot = Slot or 0
	if self.CurSelectSlot ~= 0 then
		self:UpdateEditStickerStateShow(self.CurSelectSlot, true)
	end
	self:OnSelectSlotItem(Item)
	
end

function M:OnSelectSlotItem(Item)
	if self.CurSelectSlotItem then
		self.CurSelectSlotItem:UnSelect()
	end
	self.CurSelectSlotItem = Item
	if self.CurSelectSlotItem then
		self.CurSelectSlotItem:Select()
	end

	self:UpdateSlotButtonState()
end

function M:OnUpdateSlotItem(Widget, Index)
	local i = Index + 1
	local SlotId = self.SlotIdList[i]
	if SlotId == nil then
		return
	end

	local ListItem = self:CreateSlotItem(Widget)
	if ListItem == nil then
		return
	end

    if SlotId == self.CurSelectSlot then
		self:OnSelectSlotItem(ListItem)
	else 
		ListItem:UnSelect()
	end
	ListItem:SetItemData(SlotId)
end


function M:OnSlotReplaceClicked()
	if self.CurEditStickerInfo == nil then
		return 
	end
	local IsEnough = self.TheVehicleModel:IsStickerEnough(self.CurEditStickerInfo.StickerId)
	if not IsEnough then
		self.WidgetSwitcherBuy:SetActiveWidgetIndex(1)
		if self.StickerShortageInst ~= nil then
			self.StickerShortageInst:UpdateVisibility(true)
			self.StickerShortageInst:UpdateInfo(self.CurSelectVehicleSkinId, self.CurEditStickerInfo.StickerId)
		end
	else
		if self.CurSelectSlot == self.CurEditStickerInfo.Slot then
			UIAlert.Show(self.TheArsenalModel:GetArsenalText(10050))
			return
		end

		local StickerInfo = self.TheVehicleModel:GetVehicleSkinStickerBySlot(self.CurSelectVehicleSkinId, self.CurSelectSlot)
		if StickerInfo == nil then
			--没有现存的贴纸，无法替换
			local msgParam = {
				describe = self.TheArsenalModel:GetArsenalText(10041),
			}
			UIMessageBox.Show(msgParam)
			return
		end
		MvcEntry:GetCtrl(ArsenalCtrl):SendProto_RemoveVehicleSkinSticker(self.CurSelectVehicleSkinId, StickerInfo.StickerId, 
			StickerInfo.Slot, VehicleSkinStickerMdt.StickerUpdateType.REPLACED)

		MvcEntry:GetCtrl(ArsenalCtrl):SendProto_AddVehicleSkinSticker(self.CurSelectVehicleSkinId, self.CurEditStickerInfo, 
			VehicleSkinStickerMdt.StickerUpdateType.REPLACE)
	end
end

function M:OnStickerReplaceClicked(TargetVehicleSkinId, TargetSlot, TargetStickerId)
	--目标的槽位信息
	local TargetStickerInfo = self.TheVehicleModel:GetVehicleSkinStickerBySlot(self.CurSelectVehicleSkinId, self.CurSelectSlot)
	if TargetStickerInfo == nil then
		CLog("Select Slot Not Found Sticker!")
		return
	end

	--来源槽位信息
	local SrcStickerInfo = self.TheVehicleModel:GetVehicleSkinStickerBySlot(TargetVehicleSkinId, TargetSlot)
	if SrcStickerInfo == nil then
		--没有现存的贴纸，无法替换
		local msgParam = {
			describe = self.TheArsenalModel:GetArsenalText(10041),
		}
		UIMessageBox.Show(msgParam)
		return
	end

	--目标Slot不变，使用的来源的贴纸Id
	TargetStickerInfo.StickerId = SrcStickerInfo.StickerId
	TargetStickerInfo.Position = self.CurEditStickerInfo.Position
	TargetStickerInfo.Rotator = self.CurEditStickerInfo.Rotator
	TargetStickerInfo.Scale = self.CurEditStickerInfo.Scale
	TargetStickerInfo.RotateAngle = self.CurEditStickerInfo.RotateAngle
	TargetStickerInfo.ScaleLength = self.CurEditStickerInfo.ScaleLength

	--删除来源贴纸
	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_RemoveVehicleSkinSticker(TargetVehicleSkinId, SrcStickerInfo.StickerId, 
		SrcStickerInfo.Slot, VehicleSkinStickerMdt.StickerUpdateType.REPLACED)

	--替换目标槽位贴纸
	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_UpdateVehicleSkinSticker(self.CurSelectVehicleSkinId, TargetStickerInfo, 
		VehicleSkinStickerMdt.StickerUpdateType.REPLACE)
end


function M:OnStickerShortageCloseClicked()
	self:OnEscClicked()
end


--[[
	更新编辑
]]
function M:UpdateEditStickerStateShow(Slot, State)
	if self.StickerEditInst == nil then
		return
	end
	self.StickerEditInst:UpdateStickerHoverState(Slot, State)
end
--------------------------按钮以及网络事件---------------------------

function M:OnEscClicked()
	MvcEntry:CloseView(self.viewId)
end


function M:ON_UPDATE_VEHICLE_SKIN_STICKER_LIST(UpdateReason)
	local TipsId = UpdateReason == 1 and 10042 or UpdateReason == 2 and 10043 or 0
	if TipsId ~= 0 then
		UIAlert.Show(self.TheArsenalModel:GetArsenalText(TipsId))
	end
	MvcEntry:CloseView(self.viewId)
end



return M