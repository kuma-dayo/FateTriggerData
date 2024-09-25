local BagItemDetailKeyButtonUI = Class("Common.Framework.UserWidget")

local ItemSystemHelper = require ("InGame.BRGame.ItemSystem.ItemSystemHelper")

function BagItemDetailKeyButtonUI:OnInit()
    print("BagItemDetailKeyButtonUI >> OnInit.")

    self.CurState = ItemSystemHelper.NKeyButtonState.None
    self.InItemData = nil

    self.BindNodes = 
    {
        { UDelegate = self.Button_Left.OnClicked, Func = self.OnButtonLeftClick },
        { UDelegate = self.Button_Right.OnClicked, Func = self.OnButtonRightClick },
    }

    UserWidget.OnInit(self)
end

function BagItemDetailKeyButtonUI:OnDestroy()
    print("BagItemDetailKeyButtonUI >> OnDestroy.")
    self.InItemData = nil

    UserWidget.OnDestroy(self)
end

function BagItemDetailKeyButtonUI:UpdateDetailButton(InItemData)
    print("BagItemDetailKeyButtonUI >> UpdateDetailButton.")

    if InItemData == nil then
        return
    end

    self.InItemData = InItemData
    self.CurState = InItemData.KeyButtonState

    if InItemData.KeyButtonState == ItemSystemHelper.NKeyButtonState.None then
        return
    elseif InItemData.KeyButtonState == ItemSystemHelper.NKeyButtonState.AttachmentCanUse then
        -- 可装配配件
        self.Button_Left:SetVisibility(UE.ESlateVisibility.Visible)
        self.Button_Right:SetVisibility(UE.ESlateVisibility.Visible)
        -- 丢弃
        self.TextBlock_Left:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2008"))
        -- 装备
        self.TextBlock_Right:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2028"))
    elseif InItemData.KeyButtonState == ItemSystemHelper.NKeyButtonState.AttachmentCanNotUse then
        -- 不可装配配件
        self.Button_Left:SetVisibility(UE.ESlateVisibility.Visible)
        self.Button_Right:SetVisibility(UE.ESlateVisibility.Hidden)
        -- 丢弃
        self.TextBlock_Left:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2008"))
    elseif InItemData.KeyButtonState == ItemSystemHelper.NKeyButtonState.Potion then
        -- 药品
        self.Button_Left:SetVisibility(UE.ESlateVisibility.Visible)
        self.Button_Right:SetVisibility(UE.ESlateVisibility.Visible)
        -- 丢一个
        self.TextBlock_Left:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2030"))
        -- 使用
        self.TextBlock_Right:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2005"))
    elseif InItemData.KeyButtonState == ItemSystemHelper.NKeyButtonState.Throwable then
        -- 投掷物
        self.Button_Left:SetVisibility(UE.ESlateVisibility.Visible)
        self.Button_Right:SetVisibility(UE.ESlateVisibility.Visible)
        -- 丢一个
        self.TextBlock_Left:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2030"))
        -- 全部丢弃
        self.TextBlock_Right:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2000"))
    elseif InItemData.KeyButtonState == ItemSystemHelper.NKeyButtonState.BulletCanUse then
        -- 可使用弹药
        self.Button_Left:SetVisibility(UE.ESlateVisibility.Visible)
        self.Button_Right:SetVisibility(UE.ESlateVisibility.Visible)
        -- 丢一个
        self.TextBlock_Left:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2030"))
        -- 部分丢
        self.TextBlock_Right:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2001"))
    elseif InItemData.KeyButtonState == ItemSystemHelper.NKeyButtonState.BulletCanNotUse then
        -- 无法使用弹药
        self.Button_Left:SetVisibility(UE.ESlateVisibility.Visible)
        self.Button_Right:SetVisibility(UE.ESlateVisibility.Visible)
        -- 丢一个
        self.TextBlock_Left:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2030"))
        -- 全部丢弃
        self.TextBlock_Right:SetText(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2000"))
    end

end

function BagItemDetailKeyButtonUI:OnButtonLeftClick()
    print("BagItemDetailKeyButtonUI >> OnButtonLeftClick. CurState = ", tostring(self.CurState))

    if self.CurState == ItemSystemHelper.NKeyButtonState.None then
        error("BagItemDetailKeyButtonUI:OnButtonRightClick. Invalid click option. Check 'CurState' data is correct or not.")
        return
    end

   
    if self.CurState == ItemSystemHelper.NKeyButtonState.AttachmentCanUse then
        -- 可装配配件 丢弃
        ItemSystemHelper.TryToDiscardItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID, self.InItemData.ItemNum)
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.AttachmentCanNotUse then
        -- 不可装配配件
        ItemSystemHelper.TryToDiscardItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID, self.InItemData.ItemNum)
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.Potion then
        ItemSystemHelper.TryToDiscardItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID, 1)
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.Throwable then
        -- 投掷物
        ItemSystemHelper.TryToDiscardItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID, 1)
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.BulletCanUse then
        -- 可使用弹药
        ItemSystemHelper.TryToDiscardItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID, math.floor(self.InItemData.ItemNum/2))
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.BulletCanNotUse then
        -- 无法使用弹药
        ItemSystemHelper.TryToDiscardItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID, math.floor(self.InItemData.ItemNum/2))
    end

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemButton)
end

function BagItemDetailKeyButtonUI:OnButtonRightClick()
    print("BagItemDetailKeyButtonUI >> OnButtonRightClick. CurState = ", tostring(self.CurState))

    if self.CurState == ItemSystemHelper.NKeyButtonState.None or self.CurState == ItemSystemHelper.NKeyButtonState.AttachmentCanNotUse then
        error("BagItemDetailKeyButtonUI:OnButtonRightClick. Invalid click option. Check 'CurState' data is correct or not.")
        return
    end

    if self.CurState == ItemSystemHelper.NKeyButtonState.AttachmentCanUse then
        -- 可装配配件
        ItemSystemHelper.TryToEquipAttachmentToAnyWeapon(self.InItemData.ItemID, self.InItemData.ItemInstanceID, 1, GameDefine.InstanceIDType.ItemInstance)
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.AttachmentCanNotUse then
        -- 不可装配配件
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.Potion then
        ItemSystemHelper.TryUseItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID)
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.Throwable then
        -- 投掷物
        ItemSystemHelper.TryToDiscardItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID, self.InItemData.ItemNum)
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.BulletCanUse then
        -- 可使用弹药
        MsgHelper:Send(self, GameDefine.Msg.BagMobile_ShowDropAmount, self.InItemData)
    elseif self.CurState == ItemSystemHelper.NKeyButtonState.BulletCanNotUse then
        -- 无法使用弹药
        ItemSystemHelper.TryToDiscardItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID, self.InItemData.ItemNum)
    end

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemButton)
end


return BagItemDetailKeyButtonUI