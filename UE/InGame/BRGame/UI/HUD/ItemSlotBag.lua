require "UnLua"

local ItemSlotBag = Class("Common.Framework.UserWidget")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

function ItemSlotBag:OnInit()
    self:ResetItemInfo()

    UserWidget.OnInit(self)
end


function ItemSlotBag:OnDestroy()
    self.ItemID = nil
    self.ItemInstanceID = nil
    self.CurrentWeightOrNum = nil
    self.MaxWeightOrNum = nil

    UserWidget.OnDestroy(self)
end


function ItemSlotBag:ResetItemInfo()
    self.ItemID = 0
    self.ItemInstanceID = 0
    self.CurrentWeightOrNum = -1
    self.MaxWeightOrNum = -1

end


function ItemSlotBag:GetInventoryIdentity()
    return self.ItemID, self.ItemInstanceID
end


function ItemSlotBag:SetSlotInfo(ItemSlotData, ParentWidget)
    if ItemSlotData.InventoryIdentity.ItemID == 0 then
        self:ResetItemInfo()
        self:ShowDontHasBag()
    else
        self.ItemID = ItemSlotData.InventoryIdentity.ItemID
        self.ItemInstanceID = ItemSlotData.InventoryIdentity.ItemInstanceID
        self.ParentWidget = ParentWidget
        self:ShowHasBag()
        self:SetLvImageValue()
    end
end

function ItemSlotBag:UpdateSlotInfo(ItemSlotData)
    -- 背包暂时没有
end

function ItemSlotBag:IsSlotInfoValid()
    if self.ItemID ~= 0 and self.ItemInstanceID ~= 0 then
        return true
    end
    return false
end

function ItemSlotBag:UpdateWeightInfo(BagComponent)
    if not BagComponent then return end
    local IsWeightMode = BagComponent:IsWeightMode()
    if IsWeightMode then
        -- 重量模式
        if self.CurrentWeightOrNum ~= BagComponent:GetCurWeight() then
            self.CurrentWeightOrNum = BagComponent:GetCurWeight()
            self.TextBlock_CurrentWeight:SetText(tostring(self.CurrentWeightOrNum))
        end
        if self.MaxWeightOrNum ~= BagComponent:GetMaxWeight() then
            self.MaxWeightOrNum = BagComponent:GetMaxWeight()
            self.TextBlock_MaxWeight:SetText(tostring(self.MaxWeightOrNum))
        end
        -- 更新进度条
        print("ItemSlotBag >> UpdateWeightInfo SetScalarParameterValue   Progress:", self.CurrentWeightOrNum / self.MaxWeightOrNum)
        self.Image_Backpack_Progressbar:GetDynamicMaterial():SetScalarParameterValue("Progress", (self.CurrentWeightOrNum / self.MaxWeightOrNum) )

        if self.ItemID == 0 then
            self:ResetItemInfo()
            self:ShowDontHasBag()
        end
    else
        -- 格子模式
        if self.CurrentWeightOrNum ~= BagComponent:GetCurSlotNum() then
            self.CurrentWeightOrNum = BagComponent:GetCurSlotNum()
            self.TextBlock_CurrentWeight:SetText(tostring(self.CurrentWeightOrNum))
        end
        if self.MaxWeightOrNum ~= BagComponent:GetMaxSlotNum() then
            self.MaxWeightOrNum = BagComponent:GetMaxSlotNum()
            self.TextBlock_MaxWeight:SetText(tostring(self.MaxWeightOrNum))
        end
    end
end


function ItemSlotBag:Construct()
    self:ShowDontHasBag()
end


function ItemSlotBag:OnMouseButtonDown(MyGeometry, MouseEvent)
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return DefaultReturnValue
    end

    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
        if self:IsSlotInfoValid() then
            DefaultReturnValue = UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent, self, MouseKey)
        end
    elseif MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
        if self:IsSlotInfoValid() then
            local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
            local TempInventoryIdentity = UE.FInventoryIdentity()
            TempInventoryIdentity.ItemID = self.ItemID
            TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID

            local TempDiscardTag = UE.FGameplayTag()
            UE.UItemStatics.DiscardItem(PlayerController, TempInventoryIdentity, 1, TempDiscardTag)
            UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
        end
    elseif MouseKey.KeyName == GameDefine.NInputKey.MiddleMouseButton then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

        if PlayerController then
            local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
            if BattleChatComp then
                local PlayerName = ""
                local PS = PlayerController.PlayerState
                if PS then
                    PlayerName = PS:GetPlayerName()
                end

                if self.ItemID ~= 0 and nil ~= self.ItemID then
                    local ItemName = AdvanceMarkHelper.GetMarkLogItemName(self, self.ItemID)
                    local Color = AdvanceMarkHelper.GetMarkLogItemLevelQualityColor(self, self.ItemID)
                    AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "OwnBag", PlayerName, Color, ItemName)
                    print("ItemSlotArmor:OnMouseButtonDown SendMsg Own Bag !")
                else
                    AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "NeedBag", PlayerName)
                    print("ItemSlotArmor:OnMouseButtonDown SendMsg Need Bag !")
                end
            end
        end
    end

    return DefaultReturnValue
end


function ItemSlotBag:OnClicked_Weapon()
    self.OnClickedItem:Broadcast(self)
end

function ItemSlotBag:Reset()
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
    self:ResetItemInfo()
    self:ResetWidget()
    self:ShowDontHasBag()
end

function ItemSlotBag:IsSameContent(InInventoryIdentity)
    return (self.ItemID == InInventoryIdentity.ItemID) and (self.ItemInstanceID == InInventoryIdentity.ItemInstanceID)
end

-- 根据物品等级修改背景颜色
function ItemSlotBag:UpdateBackGroundImage(CurItemLevel)
    local LvBgColorTexture = BattleUIHelper.GetMiscSystemValue(self,"BagLvBgColorTexture", CurItemLevel)
    if LvBgColorTexture then
        local CurrentMaterial = self.Image_Background:GetDynamicMaterial()
        if CurrentMaterial then
            CurrentMaterial:SetTextureParameterValue("FillTexture", LvBgColorTexture)
        end
        self.Image_Background:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.Image_Background:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

-- display
function ItemSlotBag:ShowHasBag()
    self.Image_Content:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.TextBlock_CurrentWeight:SetVisibility(UE.ESlateVisibility.Visible)
    self.TextBlock_Delimiter:SetVisibility(UE.ESlateVisibility.Visible)
    self.TextBlock_MaxWeight:SetVisibility(UE.ESlateVisibility.Visible)
    self.Image_Content:SetBrushFromSoftTexture(self.DefaultBagPicSoft, false)
    self.Image_Content:SetColorAndOpacity(self.DefaultBagPicColor)
end

function ItemSlotBag:ShowDontHasBag()
    self.Image_Content:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)    
    self.Image_Content:SetBrushFromSoftTexture(self.EmptyBagPicSoft, false)                       
    self.Image_Content:SetColorAndOpacity(self.EmptyBagPicColor)

    -- 设置背景颜色为空包颜色
    self:UpdateBackGroundImage(0)
end

-- 设置 level image value
function ItemSlotBag:SetLvImageValue()
    local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(self)
    local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(self.ItemID, "Ingame")
    local StrItemID = tostring(self.ItemID)
    local CurItemLevel, RetItemLevel = SubTable:BP_FindDataUInt8(StrItemID,"ItemLevel")
    if RetItemLevel then
        self:UpdateBackGroundImage(CurItemLevel)       
    end
end

function ItemSlotBag:ResetWidget()
    -- 图片暂时不处理，反正会隐藏
end

function ItemSlotBag:OnMouseEnter(MyGeometry, MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        return
    end

    local TempInteractionKeyName = "Bag.Default.2Action"

    if self:IsSlotInfoValid() then
        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = self.ParentWidget,
            IsShowAtLeftSide = true ,
            ItemID=self.ItemID,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = 1,
            IsShowDiscardNum = true,
            InteractionKeyName = TempInteractionKeyName,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })

        self.Image_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

end

function ItemSlotBag:OnMouseLeave(MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        return
    end

    self.Image_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end

function ItemSlotBag:OnDragEnter(MyGeometry, PointerEvent, Operation)
    -- 暂不处理，转发
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
end

function ItemSlotBag:OnDragLeave(PointerEvent, Operation)
    -- 暂不处理，转发
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end

function ItemSlotBag:OnDrop(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end

function ItemSlotBag:OnDragDetected(MyGeometry, PointerEvent)
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)
    DefaultDragVisualWidget:SetDragInfo(self.ItemID, self.ItemInstanceID, 1, GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.BagZoom, self)
    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget
    return DragDropObject
end

return ItemSlotBag