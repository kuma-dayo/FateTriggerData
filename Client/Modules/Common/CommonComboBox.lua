local class_name = "CommonComboBox"
---@class CommonComboBox
CommonComboBox = CommonComboBox or BaseClass(nil, class_name)
require("Client.Modules.Common.CommonComboBoxItem")
---@class CommonComboBoxData
---@field OptionList ComboBoxItemData[] 选项列表
---@field SelectCallBack Function 
---@field Direction boolean 设置方向
---@field DefaultSelect number 默认选中
---@field MaxContentHeight number 最大高度
CommonComboBox.CommonComboBoxData = nil

CommonComboBox.IsOpen = false
CommonComboBox.State = 0

CommonComboBox.ComboboxDirection = {
    Up = 0,
    Down = 1
}

CommonComboBox.ComboboxState = {
    None = 0,
    Normal = 1,
    Hover = 2,
    Open = 3
}

function CommonComboBox:OnInit(Param)
    self.BindNodes = {
        {UDelegate = self.View.ComboboxContent.OnUpdateItem,    Func = Bind(self, self.OnUpdateItem)},
        {UDelegate = self.View.ButtonCombobox.OnClicked,        Func = Bind(self, self.OnToggleClicked)},
        {UDelegate = self.View.ButtonCombobox.OnHovered,        Func = Bind(self, self.OnHovered)},
        {UDelegate = self.View.ButtonCombobox.OnUnHovered,      Func = Bind(self, self.OnUnHovered)},
        {UDelegate = self.View.ComboBoxMask.OnFocusLosted,      Func = Bind(self, self.OnFocusLosted)}
    }
    self.SelectIndex = -1
    self.IsOpen = false
    self.IsHovered = false
    self.State = CommonComboBox.ComboboxState.Normal
    self.ComboBoxItemWidgetList = {}
end

--[[
    CommonComboBoxData = {
        DefaultSelect = 1,              --默认选中索引
        DefaultTip = ""                 --默认提示,DefaultSelect=-1时有效,代表没有默认设置,提示玩家需玩家主动做出选择
        OptionList = {                  --下拉列表信息
            {ItemDataString = "displayStr",}
             {ItemDataString = "displayStr",}
        },
        MaxContentHeight = 100,         --最大下拉框内容高度，不设置的话有多少内容下拉框高度就有多高
        SelectCallBack = function() end,--选中时候的回调
        ListItemClass = "luaPath",      --列表中的lua类路径，默认 ComboBoxItem
    }
--]]
function CommonComboBox:OnShow(CommonComboBoxData)
    self:UpdateUI(CommonComboBoxData)
end

function CommonComboBox:OnManualShow(CommonComboBoxData)
    self:UpdateUI(CommonComboBoxData)
end

function CommonComboBox:UpdateUI(CommonComboBoxData)
    if not CommonComboBoxData then
        CError("[CommonComboBox]OnShow param is nil")
        return
    end
    self.CommonComboBoxData = CommonComboBoxData

    if not self.CommonComboBoxData.DefaultSelect then
        self.CommonComboBoxData.DefaultSelect = 1
    end
    self.SelectIndex = self.CommonComboBoxData.DefaultSelect
    local ListNum = #self.CommonComboBoxData.OptionList
    -- self.View.ComboboxContent:Reload(ListNum)

    local CurHeight = self.CommonComboBoxData.MaxContentHeight
    if not CurHeight or CurHeight == 0 then
        CurHeight = ListNum * self.View.ComboboxContent.ItemHeight
    end
    self.View.ContentHolder:SetHeightOverride(CurHeight)
    self:UpdateState(true)
    self:UpdateContent()

    local DefaultData = self.CommonComboBoxData.OptionList[self.SelectIndex]
    if self.CommonComboBoxData.SelectCallBack then
        self.CommonComboBoxData.SelectCallBack(self.SelectIndex, true, DefaultData)
    end
end

function CommonComboBox:OnHide()
    self.SelectIndex = -1
    self.IsOpen = false
    self.IsHovered = false
    self.State = CommonComboBox.ComboboxState.None
    self.ComboBoxItemWidgetList = nil
end

function CommonComboBox:OnFocusLosted(ComboBox)
    self:HandleContentVisible(false)
end

function CommonComboBox:OnHovered()
    self.IsHovered = true
    self:UpdateState()
end

function CommonComboBox:OnUnHovered()
    self.IsHovered = false
    self:UpdateState()
end

function CommonComboBox:HandleContentVisible(Open)
    self.IsOpen = Open
    self:UpdateState()
end

function CommonComboBox:OnToggleClicked()
    CLog("[cw] CommonComboBox:OnToggleClicked()")
    self.IsOpen = not self.IsOpen
    self:HandleContentVisible(self.IsOpen)
end

function CommonComboBox:CheckStateChanged()
    local NewState
    if self.IsOpen then
        NewState = CommonComboBox.ComboboxState.Open
    else
        if self.IsHovered then
            NewState = CommonComboBox.ComboboxState.Hover
        else
            NewState = CommonComboBox.ComboboxState.Normal
        end
    end
    if self.State == NewState then
        return false
    end
    self.State = NewState
    return true
end

function CommonComboBox:UpdateState(IsForce)
    if not IsForce and not self:CheckStateChanged() then
        return
    end
    if CommonUtil.IsValid(self.View.ListRoot) then
        self.View.ListRoot:SetVisibility(self.IsOpen and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
        if self.IsOpen then
            self.View.ComboboxContent:Reload(#self.CommonComboBoxData.OptionList)
        end
    end
    if CommonUtil.IsValid(self.View.WidgetSwitcher) then
        self.View.WidgetSwitcher:SetActiveWidgetIndex(self.State - 1)
        if self.SelectIndex == -1 then
            -- ComboBox 没有选中任何项
            if self.View["TextBlock_"..self.State] then
                local DefaultTip = self.CommonComboBoxData.DefaultTip
                if DefaultTip then
                    self.View["TextBlock_"..self.State]:SetText(DefaultTip)
                end
            end
        else
            if self.View["TextBlock_"..self.State] then
                self.View["TextBlock_"..self.State]:SetText(StringUtil.FormatText(self.CommonComboBoxData.OptionList[self.SelectIndex].ItemDataString))
            end
        end
    end
    if CommonUtil.IsValid(self.View.TextBlock) then
        if self.SelectIndex == -1 then
            -- ComboBox 没有选中任何项
            local DefaultTip = self.CommonComboBoxData.DefaultTip
            if DefaultTip then
                self.View.TextBlock:SetText(DefaultTip)
            end
        else
            self.View.TextBlock:SetText(StringUtil.FormatText(self.CommonComboBoxData.OptionList[self.SelectIndex].ItemDataString))
        end
    end
end

function CommonComboBox:OnUpdateItem(EventHandle, Widget, Index)
    local Data = self.CommonComboBoxData.OptionList[Index + 1]
    if Data == nil then
        return
    end
    local ListItem = self:CreateItem(Widget)
    if ListItem == nil then
        return
    end
    ListItem:SetItemData(Data, Index + 1, self.SelectIndex, Bind(self, self.OnItemClickCallBack))
end

function CommonComboBox:OnItemClickCallBack(Index, Data)
    self.SelectIndex = Index
    self:HandleContentVisible(false)
    if self.CommonComboBoxData.SelectCallBack then
        self.CommonComboBoxData.SelectCallBack(self.SelectIndex, false, Data)
    end
end

function CommonComboBox:ForceChangeSelect(Index)
    self.SelectIndex = Index
    self.IsOpen = false
    self:UpdateState(true)
end

function CommonComboBox:CreateItem(Widget)
    if not Widget or not CommonUtil.IsValid(Widget) then
        CError("[CommonComboBox]CreateItem CreateItem Failed")
        return
    end
    local Item = self.ComboBoxItemWidgetList[Widget]
    if not Item then
        local luaPath = self.CommonComboBoxData.ListItemClass or ComboBoxItem
        Item = UIHandler.New(self, Widget, luaPath)
        self.ComboBoxItemWidgetList[Widget] = Item
    end
    return Item.ViewInstance
end

--- 更新一些不需要变化的界面
function CommonComboBox:UpdateContent()
    if self.CommonComboBoxData == nil then
        return
    end

end