local class_name = "ComboBoxItem"
ComboBoxItem = ComboBoxItem or BaseClass(nil, class_name)

---@class ComboBoxItemData
---@field ItemDataString string 选项数据
---@field ItemIndex number 选项序列
---@field ItemID number 选项指定ID
ComboBoxItem.ComboBoxItemData = nil
---当前item的序号
ComboBoxItem.ComboBoxItemIndex = 0

function ComboBoxItem:OnShow()
end

function ComboBoxItem:OnInit(Param)
    self.BindNodes = {
        {UDelegate = self.View.ButtonClickItem.OnClicked, Func = Bind(self, self.OnItemClick)},
    }

    self.ComboBoxItemIndex = 0
    self.IsSelect = false
end

function ComboBoxItem:OnHide()
    self.ComboBoxItemIndex = 0
    self.IsSelect = false
end

function ComboBoxItem:UpdateState()
    if self.IsSelect then
        self.View:VXE_Btn_Selected()
    else
        self.View:VXE_Btn_UnSelect()
    end
end

function ComboBoxItem:SetSelect(Select)
    -- if self.IsSelect == Select then
    --     return
    -- end
    self.IsSelect = Select
    self:UpdateState()
end

function ComboBoxItem:OnItemSelect(_, Index)
    if not self.ComboBoxItemData then
        return
    end
    if not CommonUtil.IsValid(self.View) then
        return
    end
    self:SetSelect(self.ComboBoxItemIndex == Index)
end

function ComboBoxItem:OnItemClick()
    if not self.ComboBoxItemData then
        return
    end
    if self.ItemClickCallBack then
        self.ItemClickCallBack(self.ComboBoxItemIndex, self.ComboBoxItemData)
    end
end

function ComboBoxItem:SetItemData(ItemData, Index, CurSelectIndex, ItemClickCallBack)
    if ItemData == nil then
        CError("[ComboBoxItem] SetItemData ItemData is nil")
        return
    end

    self.ComboBoxItemData = ItemData
    self.ItemClickCallBack = ItemClickCallBack
    self.ComboBoxItemIndex = Index
    self.CurSelectIndex = CurSelectIndex
    self:UpdateContent()
end

--- 更新一些不需要变化的界面
function ComboBoxItem:UpdateContent()
    if self.ComboBoxItemData == nil then
        return
    end
    if CommonUtil.IsValid(self.View.TextBlock) then
        self.View.TextBlock:SetText(StringUtil.FormatText(self.ComboBoxItemData.ItemDataString))
    end
    self:OnItemSelect(_ , self.CurSelectIndex)
end

function ComboBoxItem:UpdateSelect(CurSelectIndex)
    if self.ComboBoxItemData == nil then
        return
    end
    self.CurSelectIndex = CurSelectIndex
    self:OnItemSelect(_ , self.CurSelectIndex)
end
