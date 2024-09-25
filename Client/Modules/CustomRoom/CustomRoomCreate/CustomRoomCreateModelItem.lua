local class_name = "CustomRoomCreateModelItem"
local CustomRoomCreateModelItem = CustomRoomCreateModelItem or BaseClass(nil, class_name)

---@class CustomRoomCreateModelItem
---@field ItemDataString string 选项数据
---@field ItemIndex number 选项序列
---@field ItemID number 选项指定ID
CustomRoomCreateModelItem.CustomRoomCreateModelItemData = nil

function CustomRoomCreateModelItem:OnShow()
end

function CustomRoomCreateModelItem:OnInit()
    self.BindNodes = {
        -- {UDelegate = self.View.ButtonClickItem.OnClicked, Func = Bind(self, self.OnItemClick)},
    }

    self.CustomRoomCreateModelItemIndex = 0
    self.IsSelect = false
end

function CustomRoomCreateModelItem:OnHide()
    self.CustomRoomCreateModelItemIndex = 0
    self.IsSelect = false
end

function CustomRoomCreateModelItem:UpdateState()
    self.View.WidgetSwitcher_43:SetActiveWidgetIndex(self.IsSelect and 1 or 0)
end

function CustomRoomCreateModelItem:SetSelect(Select)
    self.IsSelect = Select
    self:UpdateState()
end

function CustomRoomCreateModelItem:OnItemSelect(_, Index)
    if not self.CustomRoomCreateModelItemData then
        return
    end
    if not CommonUtil.IsValid(self.View) then
        return
    end
    self:SetSelect(self.CustomRoomCreateModelItemIndex == Index)
end

function CustomRoomCreateModelItem:SetItemData(ItemData, Index, CurSelectIndex, ModeId,ItemClickCallBack)
    if ItemData == nil then
        CError("[CustomRoomCreateModelItem] SetItemData ItemData is nil")
        return
    end

    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.CustomRoomCreateModelItemData = ItemData
    self.CustomRoomCreateModelItemIndex = Index
    self.ItemClickCallBack = ItemClickCallBack
    if not self.ItemInst then
        self.ItemInst = UIHandler.New(self,self.View.WBP_ComboBoxItem,ComboBoxItem).ViewInstance
    end
    self.ItemInst:SetItemData(ItemData, Index, CurSelectIndex, Bind(self,self.OnModelItemClick))
    --背景图以及文字描述
    local TheRoomCfg = G_ConfigHelper:GetSingleItemById(Cfg_CustomRoomConfig,ModeId)

    if TheRoomCfg then
        CommonUtil.SetBrushFromSoftObjectPath(self.View.ImgMode,TheRoomCfg[Cfg_CustomRoomConfig_P.SceneTexture])
        self.View.LbDesMode:SetText(TheRoomCfg[Cfg_CustomRoomConfig_P.ModeDes])
    end

    local TheModeCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_ModeEntryCfg,ModeId)
    if TheModeCfg then
        self.View.LbModeName:SetText(TheModeCfg[Cfg_ModeSelect_ModeEntryCfg_P.ModeName])
    end
    self:SetSelect(self.CustomRoomCreateModelItemIndex == CurSelectIndex)
end

function CustomRoomCreateModelItem:OnModelItemClick(ItemIndex,ItemData)
    if not self.CustomRoomCreateModelItemData then
        return
    end
    if self.ItemClickCallBack then
        self.ItemClickCallBack(self.CustomRoomCreateModelItemIndex, self.CustomRoomCreateModelItemData)
    end
end

function CustomRoomCreateModelItem:UpdateSelect(CurSelectIndex)
    if self.CustomRoomCreateModelItemData == nil then
        return
    end
    self:OnItemSelect(_ , CurSelectIndex)
    self.ItemInst:UpdateSelect(CurSelectIndex)
end

return CustomRoomCreateModelItem