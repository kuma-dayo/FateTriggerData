--[[
    用于 WBP_VehicleSkinSticker_Shortage 的逻辑, 
    贴纸不足需要购买
]]

local class_name = "VehicleSkinStickerShortageLogic"
VehicleSkinStickerShortageLogic = VehicleSkinStickerShortageLogic or BaseClass(nil, class_name)

---@class VehicleSkinStickerShortageLogicParam

function VehicleSkinStickerShortageLogic:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.View.WBP_ReuseList_Sticker2VehicleList.OnUpdateItem, Func = Bind(self, self.OnUpdateItem)},
        { UDelegate = self.View.Common_Button_GetBuy.Btn_List.OnClicked,	Func =  Bind(self,self.OnStickerBuyClicked) },
        { UDelegate = self.View.WBP_CommonBtn_Cir_Small.GUIButton_Main.OnClicked,	Func =  Bind(self,self.OnCloseClicked) },
        
       
    }
    self.MsgList = 
	{
        {Model = VehicleModel, MsgName = VehicleModel.ON_BUY_VEHICLE_SKIN_STICKER_LIST, Func = Bind(self, self.ON_BUY_VEHICLE_SKIN_STICKER_LIST)},
	}
    self.Widget2Item = {}
    self.TheVehicleModel = MvcEntry:GetModel(VehicleModel)
    self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
end

function VehicleSkinStickerShortageLogic:OnShow(Param)
    self.Param = Param
    self.ShortageButtonInst = UIHandler.New(self, self.View.WBP_CommonBtn_Weak_M, WCommonBtnTips,
    {
        OnItemClick = Bind(self,self.OnRepalceClicked),
        CommonTipsID = CommonConst.CT_SPACE,
		TipStr = self.TheArsenalModel:GetArsenalText(10040),
		ActionMappingKey = ActionMappings.SpaceBar,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    }).ViewInstance

    self:UpdateInfo()
    self:UpdateShortageButtonState()
end


function VehicleSkinStickerShortageLogic:OnHide()

end

function VehicleSkinStickerShortageLogic:UpdateVisibility(bVisible)
    if self.View == nil then
        return 
    end
    self.View:SetVisibility(bVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function VehicleSkinStickerShortageLogic:UpdateInfo(VehicleSkinId, StickerId)
    self.VehicleSkinId = VehicleSkinId or 0
    self.StickerId = StickerId or 0
    
    local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, self.StickerId)
    if StickerCfg == nil then 
		return
	end
    self.View.Common_Button_GetBuy.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Common_Button_GetBuy.Img_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Common_Button_GetBuy.Text_Count:SetText(self.TheArsenalModel:GetArsenalText(10038))
    
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemId])
    if not CfgItem then
        self.View.MoneyIcon_GetBuy:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.View.MoneyIcon_GetBuy:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.MoneyIcon_GetBuy, CfgItem[Cfg_ItemConfig_P.IconPath])
    end
    self.View.TextNum_GetBuy:SetText(StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemNum])
    
    local Num = self.TheVehicleModel:GetStickerNumUsedByOtherVehicleSkin(VehicleSkinId, StickerId)
    self.View.UsedStickerNum:SetText(Num)
    
    self:UpdateSticker2VehicleSkinList()
    self:UpdateShortageTextInfoVisibility()
end

function VehicleSkinStickerShortageLogic:UpdateShortageButtonState()
    if self.ShortageButtonInst == nil then
        return
    end
    self.ShortageButtonInst:SetBtnEnabled(self.CurVehicleSkinInfo ~= nil)
end


function VehicleSkinStickerShortageLogic:UpdateSticker2VehicleSkinList()
    self.Sticker2VehicleSkinList = {}
    local AllSticker2VehicleSkinList = self.TheVehicleModel:GetStickerId2VehicleSkinList(self.StickerId)
    for _, V in ipairs(AllSticker2VehicleSkinList) do
        if V.VehicleSkinId ~= self.VehicleSkinId then
            table.insert(self.Sticker2VehicleSkinList, V)
        end
    end
    self.View.WBP_ReuseList_Sticker2VehicleList:Reload(#self.Sticker2VehicleSkinList)
end

function VehicleSkinStickerShortageLogic:CreateItem(Widget, Data)
    local Item = self.Widget2Item[Widget]
    if not Item then
        local Param = {
			OnItemClick = Bind(self,self.OnItemClick),
            StickerId = self.StickerId,
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerShortageItem"), Param)
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function VehicleSkinStickerShortageLogic:OnItemClick(Item, VehicleSkinInfo)
    self.CurVehicleSkinInfo = VehicleSkinInfo
    if self.CurSelectItem then
		self.CurSelectItem:UnSelect()
	end
	self.CurSelectItem = Item
	if self.CurSelectItem then
		self.CurSelectItem:Select()
	end

   self:UpdateShortageButtonState()
end

function VehicleSkinStickerShortageLogic:UpdateShortageTextInfoVisibility()
    local IsEnough = self.TheVehicleModel:IsStickerEnough(self.StickerId)
    self.View.ShortageTextInfo:SetVisibility(IsEnough and  UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
end


function VehicleSkinStickerShortageLogic:OnUpdateItem(_, Widget, Index)
    local FixIndex = Index + 1
    local Data = self.Sticker2VehicleSkinList[FixIndex]
    if Data == nil then
        return
    end
    local TargetItem = self:CreateItem(Widget, Data)
    if TargetItem == nil then
        return
    end
    TargetItem:SetItemData(Data)
end


function VehicleSkinStickerShortageLogic:OnRepalceClicked()
    if self.CurVehicleSkinInfo == nil then
        return
    end
    if self.Param ~= nil and self.Param.CallReplaceFunc ~= nil then
        self.Param.CallReplaceFunc(self.CurVehicleSkinInfo.VehicleSkinId, 
            self.CurVehicleSkinInfo.Slot, self.StickerId)
    end
end


function VehicleSkinStickerShortageLogic:OnStickerBuyClicked()
    local Param = {
		StickerBuyFrom = 1,
		StickerId = self.StickerId
	}
    MvcEntry:OpenView(ViewConst.VehicleSkinStickerBuy, Param)
end

function VehicleSkinStickerShortageLogic:OnCloseClicked()
    if self.Param ~= nil and self.Param.CallCloseFunc ~= nil then
        self.Param.CallCloseFunc()
    end
end

function VehicleSkinStickerShortageLogic:ON_BUY_VEHICLE_SKIN_STICKER_LIST()
   self:UpdateShortageTextInfoVisibility()
end

return VehicleSkinStickerShortageLogic
