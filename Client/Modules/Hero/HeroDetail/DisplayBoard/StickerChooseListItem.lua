local class_name = "StickerChooseListItem"
local StickerChooseListItem = BaseClass(nil, class_name)


function StickerChooseListItem:OnInit()
    self.MsgList = 
    {

	}
    self.BindNodes = 
    {
        { UDelegate = self.View.GUIButtonItem.OnClicked,		    Func = Bind(self,self.OnClicked_BtnClick) },
        { UDelegate = self.View.GUIButtonItem.OnHovered,            Func = Bind(self,self.OnBtnHovered) },
        { UDelegate = self.View.GUIButtonItem.OnUnhovered,          Func = Bind(self,self.OnBtnUnhovered) },
	}
end

function StickerChooseListItem:OnShow(Param)

end

function StickerChooseListItem:OnHide()

end

--[[
    {
        StickerId
        HeroId = self.HeroId,
        ClickFunc
        Index
    }
]]
function StickerChooseListItem:SetData(Param)
    self.Param = Param
    self.HeroId = self.Param.HeroId
    self.StickerId = self.Param.StickerId or 0
    self.IsLocked = false
    self.IsSelected = false
    self.UsedByHeroId = 0
    self:SetStickerData()
end

function StickerChooseListItem:SetStickerData()
    if self.StickerId == nil or self.StickerId == 0 then
        return 
    end
    
    local TblSticker = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplaySticker, self.StickerId)
    if TblSticker == nil then
        CWaring("TblSticker None: StickerId .."..self.StickerId)
        return
    end
    
    local TheItemId = TblSticker[Cfg_HeroDisplaySticker_P.ItemId]
    self.IsLocked = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(TheItemId) <= 0
    self.IsSelected = MvcEntry:GetModel(HeroModel):HasDisplayBoardStickerIdSelected(self.HeroId, self.StickerId)
    self.UsedByHeroId = MvcEntry:GetModel(HeroModel):GetStickerUsedByHeroId(self.StickerId, self.HeroId)

    self:SetUiInfo()
    
    self:UpdateStateShow()
end

function StickerChooseListItem:SetUiInfo()
    local TblSticker = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplaySticker, self.StickerId)
    if TblSticker == nil then
        CWaring("TblSticker None: StickerId .."..self.StickerId)
        return
    end
    local TheItemId = TblSticker[Cfg_HeroDisplaySticker_P.ItemId]

    CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageIcon,TblSticker[Cfg_HeroDisplaySticker_P.ResPath])
    local Count = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(TheItemId) 

    if CommonUtil.IsValid(self.View.GUITextBlock_216) then
        if UE.UGFUnluaHelper.IsEditor() then
            self.View.GUITextBlock_216:SetText(TheItemId.."-"..Count)
        else
            self.View.GUITextBlock_216:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

--[[
    状态显示
    已装备
    未解锁
    已解锁未装备
]]
function StickerChooseListItem:UpdateStateShow()
    local CommonSubscriptWidget = self.View.WBP_CommonSubscript_Equiped
    if CommonSubscriptWidget == nil then
        return
    end

    CommonSubscriptWidget.WidgetSwitcherState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.UsedByHeroId > 0 then
        CommonSubscriptWidget.WidgetSwitcherState:SetActiveWidget(CommonSubscriptWidget.Used)
    elseif self.IsSelected then
        CommonSubscriptWidget.WidgetSwitcherState:SetActiveWidget(CommonSubscriptWidget.Equiped)
    elseif self.IsLocked then
        CommonSubscriptWidget.WidgetSwitcherState:SetActiveWidget(CommonSubscriptWidget.Locked)
    else
        CommonSubscriptWidget.WidgetSwitcherState:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    if self.UsedByHeroId  > 0 then
        local DefaultHeroSkinId = MvcEntry:GetModel(HeroModel):GetDefaultSkinIdByHeroId(self.UsedByHeroId)
        local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,DefaultHeroSkinId)
        if TblSkin then
            CommonUtil.SetBrushFromSoftObjectPath(CommonSubscriptWidget.Image_Used,TblSkin[Cfg_HeroSkin_P.PNGPath])
        end
    end

    
    self.View.WidgetSwitcherBg:SetActiveWidgetIndex(self.IsLocked and 1 or 0)
end

function StickerChooseListItem:Select()
    if self.IsLock then
        self.View.GUIImageSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.GUIImageLockSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.View.GUIImageSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.GUIImageLockSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


function StickerChooseListItem:UnSelect()
    self.View.GUIImageSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.GUIImageLockSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
end


function StickerChooseListItem:OnClicked_BtnClick()
    if self.Param and self.Param.ClickFunc then
        self.Param.ClickFunc()
    end
end

function StickerChooseListItem:OnBtnHovered()
    self.View.RootPanel:SetRenderScale(UE.FVector2D(1.1,1.1))
    if self.View.Slot then
        self.View.Slot:SetZOrder(1)
    end
    self.View.HoverImg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function StickerChooseListItem:OnBtnUnhovered()
    self.View.RootPanel:SetRenderScale(UE.FVector2D(1,1))
    if self.View.Slot then
        self.View.Slot:SetZOrder(0)
    end
    self.View.HoverImg:SetVisibility(UE.ESlateVisibility.Collapsed)
end



return StickerChooseListItem
