local ItemAttachmentHelper = require ("InGame.BRGame.ItemSystem.ItemBase.ItemAttachmentHelper")
local StringUtil = require ("Common.Utils.StringUtil")
local GameDefine = require ("InGame.BRGame.GameDefine")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local ItemSlotWeaponMobile = Class("Common.Framework.UserWidget")

function ItemSlotWeaponMobile:OnInit()
    print("BagM@WeaponSlot Init")

    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()
end

function ItemSlotWeaponMobile:OnDestroy()

end

--   ____  _   _ ____  _     ___ ____    ____    _    _     _     
--  |  _ \| | | | __ )| |   |_ _/ ___|  / ___|  / \  | |   | |    
--  | |_) | | | |  _ \| |    | | |     | |     / _ \ | |   | |    
--  |  __/| |_| | |_) | |___ | | |___  | |___ / ___ \| |___| |___ 
--  |_|    \___/|____/|_____|___\____|  \____/_/   \_\_____|_____|
                                                               
function ItemSlotWeaponMobile:SetSlotIndex(index)
    self.SlotIndex = index
    self.TextBlock_SlotIndex:SetText(self.SlotIndex)
    print("BagM@SetSlotIndex", index)
end

function ItemSlotWeaponMobile:SetWeaponData(WeaponItemData)
    self.WeaponItemData = WeaponItemData
end

function ItemSlotWeaponMobile:IsHaveWeapon()
    return self.WeaponItemData ~= nil
end
--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  
function ItemSlotWeaponMobile:InitUI() 
    -- 配件槽位
    self.SupportAttachmentWidgetMap = {
        ["Weapon.AttachSlot.Barrel"] = self.BP_AttachmentBarrel,
        ["Weapon.AttachSlot.Optics"] = self.BP_AttachmentOptics,
        ["Weapon.AttachSlot.FrontGrip"] = self.BP_AttachmentFrontGrip,
        ["Weapon.AttachSlot.Mag"] = self.BP_AttachmentMag,
        ["Weapon.AttachSlot.Stocks"] = self.BP_AttachmentStocks
    }

    self:ResetWidget()
    self:SetSelectState(false)
end

function ItemSlotWeaponMobile:InitData()
    self.ViewModel = UE.UGUIManager.GetUIManager(self):GetViewModelByName("ViewModel_PlayerBag")
    self.WeaponItemData = nil

    -- area action
    self.HandleSelect = false
    self.CurrentTouchState = GameDefine.TouchType.None
    self.DragDistance = 0
    self.DragOperationActiveMinDistance = 10.0;
    self.DragStartPosition = UE.FVector2D()
    self.DragStartPosition.X = 0
    self.DragStartPosition.Y = 0
    self.bDraging = true
end

function ItemSlotWeaponMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
        { MsgName = GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop,     Func = self.OnWeaponSlotDragOnDrop },

    }
end

function ItemSlotWeaponMobile:InitUIEvent()
    self:BindDragDropFunctions()
end

--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|
function ItemSlotWeaponMobile:ShowWidget()
    if not self.WeaponItemData then
        self:ResetWidget()
        return
    end

    self:RefreshWeaponName(self.WeaponItemData.WeaponName)
    self:RefreshWeaponSkinAndName(self.WeaponItemData.WeaponCurrentSkinId, self.WeaponItemData.WeaponDefaultSkinId, self.WeaponItemData.WeaponReplaceSkinId)
    self:RefreshWeaponBulletIcon(self.WeaponItemData.WeaponBulletIcon)
    self:RefreshWeaponBulletNumTotal(self.WeaponItemData.BulletNum, self.WeaponItemData.BulletMaxNum)
    self:RefreshWeaponInfiniteBullet(self.WeaponItemData.InfiniteAmmo)

    -- 附件槽位显示
    self:RefreshWeaponAttachmentWidget(
        self.WeaponItemData.WeaponSupportAttachmentTypeList, 
        self.WeaponItemData.WeaponAttachments, 
        self.WeaponItemData.GAWeaponInstance)
    
    -- 强化词条
    self:RefreshWeaponEnhanceWidget(self.WeaponItemData.WeaponEnhanceAttrID)

    -- 设置显示状态
    self:SetWeaponExistVisibility(true)
end

function ItemSlotWeaponMobile:ResetWidget()
    self:InitData()
    self:SetWeaponExistVisibility(false)

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

function ItemSlotWeaponMobile:RefreshWeaponName(weaponName)
    self.TextBlock_WeaponName:SetText(StringUtil.Format(weaponName))
end

function ItemSlotWeaponMobile:RefreshWeaponSkinAndName(weaponCurrentSkinId, weaponDefaultSkinId, weaponReplaceSkinId)
    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, weaponCurrentSkinId)
    if not WeaponSkinCfg then
        return nil
    end

    -- 设置武器图片
    local TempImageSoftObjectPtr = UE.UPlayerBagFunctionLibrary.GetWeaponBagSkinIcon_BySkinID(self, weaponCurrentSkinId)
    if TempImageSoftObjectPtr then
        print("BagM@refresh weapon skin", self.SlotIndex, weaponCurrentSkinId)
        self.Image_Weapon:SetBrushFromSoftTexture(TempImageSoftObjectPtr, false)
    end

    -- 设置皮肤切换panel显示
    local TempIsShowCanOverrideWidget = self:IsShowWeaponSkinCanOverrideWidget(weaponCurrentSkinId, weaponDefaultSkinId, weaponReplaceSkinId)
    if TempIsShowCanOverrideWidget then
        self:SetWeaponOverrideWidgetVisibility(true)
    else
        self:SetWeaponOverrideWidgetVisibility(false)
    end

    -- 设置皮肤名称和颜色
    if (weaponCurrentSkinId ~= weaponDefaultSkinId) and (weaponCurrentSkinId ~= 0) then
        self:SetWeaponSkinNameWidgetVisibility(true)
        self.TextBlock_WeaponName:SetText(StringUtil.Format(WeaponSkinCfg.SkinName))
        self:SetWeaponSkinBgColorBySkinId(weaponCurrentSkinId)
    else
        self:SetWeaponSkinNameWidgetVisibility(false)
    end
end

function ItemSlotWeaponMobile:RefreshWeaponBulletIcon(weaponBullteIconPtr)
    self.Image_BulletType:SetBrushFromSoftTexture(weaponBullteIconPtr, false)
end

function ItemSlotWeaponMobile:RefreshWeaponBulletNumTotal(currentBulletNum, maxBulletNum)
    self:RefreshWeaponBulletNumCurrent(currentBulletNum)
    self:RefreshWeaponBulletNumMax(maxBulletNum)
end

function ItemSlotWeaponMobile:RefreshWeaponBulletNumCurrent(value)
    self.GUIText_CurBulletNum:SetText(value)
end

function ItemSlotWeaponMobile:RefreshWeaponBulletNumMax(value)
    self.GUIText_MaxBulletNum:SetText(value)
end

function ItemSlotWeaponMobile:RefreshWeaponInfiniteBullet(isInfiniteBullet)
    if isInfiniteBullet then
        self.GUIText_CurBulletNum:SetVisibility(UE.ESlateVisibility.Hidden)
        self.GUIText_Delimiter:SetVisibility(UE.ESlateVisibility.Hidden)
        self.GUIText_CurBulletNum:SetVisibility(UE.ESlateVisibility.Hidden)

        self.GUIImage_InfiniteAmmo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.GUIText_CurBulletNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.GUIText_Delimiter:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.GUIText_CurBulletNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        self.GUIImage_InfiniteAmmo:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function ItemSlotWeaponMobile:RefreshWeaponAttachmentWidget(WeaponSupprotAttchmentTypeList, WeaponAttachments,  GAWeaponInstance)
    if not self.SupportAttachmentWidgetMap or not #self.SupportAttachmentWidgetMap == 0 then
        return
    end
    local ArrNum = WeaponSupprotAttchmentTypeList:Num()
    if ArrNum <= 0 then
        return
    end 
    print("BagM@WeaponSupprotAttchmentTypeList num",  ArrNum)

    --拿到枪的Tag，作为类型设置配件槽背景图标，因为每种类型枪的部分配件槽图标不一样
    local WeaponTag = GAWeaponInstance:GetMainWeaponTag()

    -- 1.控制需要显示附件槽位
    for key, Widget in pairs(self.SupportAttachmentWidgetMap) do
        local bContains = WeaponSupprotAttchmentTypeList:Contains(key) and true or false
        local WidgetVisibility = Widget:GetVisibility()

        local TargetVisibility = bContains and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed
        if WidgetVisibility ~=  TargetVisibility then
            Widget:SetVisibility(TargetVisibility)
        end

        --如果有这把枪所支持的配件槽，再根据这把枪的类型（Tag）设置这把枪配件槽的图标
        if bContains then
            Widget:RefreshAttachmentTypeBG(WeaponTag)
        end
    end

    -- 2.刷新需要显示附件
    print("BagM@WeaponAttachments num",  tostring(WeaponAttachments:Length()))
    for key, Widget in pairs(self.SupportAttachmentWidgetMap) do
        local AttachmentData = WeaponAttachments:FindRef(key)
        if AttachmentData then
            print("BagM@WeaponAttachments tag key",  key, "attachmentID", AttachmentData.ItemID)
            Widget:SetAttachmentData(AttachmentData)
            Widget:ShowWidget()
        else
            Widget:ResetWidget()
        end
    end
end

function ItemSlotWeaponMobile:ResetWeaponAttachmentWidget()
    if not self.SupportAttachmentWidgetMap or not #self.SupportAttachmentWidgetMap == 0 then
        return
    end
    for _, value in pairs(self.SupportAttachmentWidgetMap) do
        if value then
            value:ResetWidget()
            local Visibility = value:GetVisibility()
            if Visibility ~= UE.ESlateVisibility.Collapsed then
                value:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
    end
end

function ItemSlotWeaponMobile:RefreshWeaponEnhanceWidget(InEnhanceId)
    self.BP_EnhanceAttribute:ShowWidget(InEnhanceId)
end

--   _   _ ___    ____ ___  _   _ _____ ____   ___  _      
--  | | | |_ _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |     
--  | | | || |  | |  | | | |  \| | | | | |_) | | | | |     
--  | |_| || |  | |__| |_| | |\  | | | |  _ <| |_| | |___  
--   \___/|___|  \____\___/|_| \_| |_| |_| \_\\___/|_____| 
                                                        
function ItemSlotWeaponMobile:SetWeaponSkinNameWidgetVisibility(IsVisible)
    if IsVisible then
        self.Panel_SkinName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Panel_SkinName:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ItemSlotWeaponMobile:SetWeaponOverrideWidgetVisibility(IsVisible)
    if IsVisible then
        self.Panel_SkinChange:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Panel_SkinChange:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ItemSlotWeaponMobile:SetWeaponSkinBgColorBySkinId(inWeaponSkinId)
    local TheQualityCfg = MvcEntry:GetModel(DepotModel):GetQualityCfgByItemId(inWeaponSkinId)
    local Color = TheQualityCfg[Cfg_ItemQualityColorCfg_P.HexColor]
    CommonUtil.SetTextColorFromeHex(self.TextBlock_WeaponName,Color)
end

function ItemSlotWeaponMobile:IsShowWeaponSkinCanOverrideWidget(InCurWeaponSkinId, InDefaultWeaponSkinId, InReplacedWeaponSkinId)
    local ReturnVal = false

    if InCurWeaponSkinId == -1 or InDefaultWeaponSkinId == -1 or InReplacedWeaponSkinId == -1 then
        return ReturnVal
    end

    --设置皮肤Override状态
    if InCurWeaponSkinId ~= -1 then
        if InReplacedWeaponSkinId == InDefaultWeaponSkinId then
            return ReturnVal
        end
        if InCurWeaponSkinId ~= InDefaultWeaponSkinId then
            -- 当前的皮 是 特殊皮
            if InCurWeaponSkinId ~= InReplacedWeaponSkinId then
                -- 当前皮 和 玩家的皮 不一致
                ReturnVal = true
            end
        end
    end

    return ReturnVal
end


function ItemSlotWeaponMobile:SetWeaponExistVisibility(IsVisible)
    self.WidgetSwitcher_Weapon:SetActiveWidgetIndex(IsVisible and 1 or 0)
    self:SetVisibility(IsVisible and UE.ESlateVisibility.Visible or UE.ESlateVisibility.SelfHitTestInvisible)
    self.bIsFocusable = IsVisible and true or false
end

function ItemSlotWeaponMobile:SetSelectState(IsSelect)
    self.WidgetSwitcher_Select:SetActiveWidgetIndex(IsSelect and 1 or 0)
end

function ItemSlotWeaponMobile:SetTouchState(InState)
    local PreState = self.CurrentTouchState
    self.CurrentTouchState = InState

    return PreState
end

function ItemSlotWeaponMobile:DragEnterSetHighLight(DragWidget, HighLightBool)
    if not DragWidget then return end

    local DragItemID, DragWeaponInstanceID, DragItemNum, DragIDType = DragWidget:GetDragItemData()
    if self.WeaponItemData.ItemInstanceID ~= DragWeaponInstanceID and HighLightBool then
        -- self.OverlayDragOn:SetVisibility(UE.ESlateVisibility.Visible)
        -- UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Hover_01")
    else
        -- self.OverlayDragOn:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  
function ItemSlotWeaponMobile:BindDragDropFunctions()
    for key, Widget in pairs(self.SupportAttachmentWidgetMap) do
        if Widget then
            if Widget.Delegate_TransportOnDragEnter then
                Widget.Delegate_TransportOnDragEnter:Add(self, self.Transport_OnDragEnter)
            end
    
            if Widget.Delegate_TransportOnDrop then
                Widget.Delegate_TransportOnDrop:Add(self, self.Transport_OnDrop)
            end

            -- if value.Delegate_TransportOnDragLeave then
            --     value.Delegate_TransportOnDragLeave:Add(self, self.Transport_OnDragLeave)
            -- end
        end
    end
end

function ItemSlotWeaponMobile:OnMouseButtonDown(MyGeometry, MouseEvent)
    if (self.WeaponItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    print("BagM@ItemSlotWeaponMobile OnMouseButtonDown", self.SlotIndex)
    -- UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Click_01")

    -- 默认Mobile平台
    self:SetTouchState(GameDefine.TouchType.Selected)
    self.DragDistance = 0

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then return UE.UWidgetBlueprintLibrary.Handled() end

    local CurrentDragPositionInViewport = UE.UGFUnluaHelper.FPointerEvent_GetScreenSpacePosition(MouseEvent)
    self.DragStartPosition = CurrentDragPositionInViewport

    return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent, self, MouseKey)
end

function ItemSlotWeaponMobile:OnMouseButtonUp(MyGeometry, MouseEvent)
    if (self.WeaponItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    print("BagM@ItemSlotWeaponMobile OnMouseButtonUp", self.SlotIndex)

    -- 默认Mobile平台
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()
    self.CurrentTouchState = GameDefine.TouchType.None
    
   
    return DefaultReturnValue
end

function ItemSlotWeaponMobile:OnMouseEnter(MyGeometry, MouseEvent)
    if (self.WeaponItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotWeaponMobile:OnMouseEnter", self.SlotIndex)
end

function ItemSlotWeaponMobile:OnMouseLeave(MouseEvent)
    if (self.WeaponItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotWeaponMobile:OnMouseLeave", self.SlotIndex)
end

function ItemSlotWeaponMobile:OnDragDetected(MyGeometry, PointerEvent)
    if self.WeaponItemData == nil then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotWeaponMobile:OnDragDetected", self.SlotIndex)
    self.bDraging = true

    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)    
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)

    self.CurrentDragVisualWidget = DefaultDragVisualWidget
    self.CurrentDragVisualWidget:SetDragVisibility(false)
    
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget

    DefaultDragVisualWidget:SetDragItemData(self.WeaponItemData.ItemID, self.WeaponItemData.ItemInstanceID, 1, GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.EquipZoom, self)
    DefaultDragVisualWidget:ShowWidget()

    return DragDropObject
end

function ItemSlotWeaponMobile:OnDragOver(MyGeometry, MouseEvent, Operation)
    if (self.WeaponItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    if not self.CurrentDragVisualWidget then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    if self.CurrentTouchState == GameDefine.TouchType.Selected then
        local CurrentDragPositionInViewport = UE.UGFUnluaHelper.FPointerEvent_GetScreenSpacePosition(MouseEvent)
        local TempX = math.abs(CurrentDragPositionInViewport.X - self.DragStartPosition.X)
        local TempY = math.abs(CurrentDragPositionInViewport.Y - self.DragStartPosition.Y)

        if (TempX > self.DragOperationActiveMinDistance) or (TempY > self.DragOperationActiveMinDistance) then
            local PreState = self:SetTouchState(GameDefine.TouchType.Drag)
            if (PreState == GameDefine.TouchType.Selected) and (self.CurrentTouchState == GameDefine.TouchType.Drag) then
                self.CurrentDragVisualWidget:SetDragVisibility(true)
            end
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotWeaponMobile:OnDragComplete()
    if (self.WeaponItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
    print("BagM@ItemSlotCommonItemMobile:OnDragComplete", self.SlotIndex)
    self.bDraging = false
end

-- 丢弃区域相关
-- 当拖拽UI悬停在本控件之上时，触发此回调
function ItemSlotWeaponMobile:OnDragEnter(MyGeometry, PointerEvent, Operation)
    if not Operation then return end
    local DragSourceFlag = Operation.DefaultDragVisual:GetDragSource()
    if not DragSourceFlag then return end
    
    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragItemData()
    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType", GameDefine.NItemSubTable.Ingame, "DropZoomUI:OnDropToPickZoom")
    if IsFindItemType and CurrentItemType == "Weapon" then
        if self:IsHaveWeapon() and TempItemID ~= self.WeaponItemData.ItemID then
            -- TODO ui组件亮起
        elseif not self:IsHaveWeapon() then
            -- TODO ui组件亮起
        end
    end
    self:Transport_OnDragEnter(MyGeometry, PointerEvent, Operation)
end

-- 当拖拽UI离开本控件之上时，触发此回调
function ItemSlotWeaponMobile:OnDragLeave(PointerEvent, Operation)
    MsgHelper:Send(nil, GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop, { WeaponItemID = self.WeaponItemData.ItemID })
    print("BagM@ItemSlotWeaponMobile:OnDragLeave:",self.SlotIndex)
    
    self:Transport_OnDragLeave(PointerEvent, Operation)
end

-- 当拖拽到本控件并释放鼠标按键的时候会触发此回调（拖拽完成）
function ItemSlotWeaponMobile:OnDrop(MyGeometry, PointerEvent, Operation)
    MsgHelper:Send(nil, GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop, { WeaponItemID = self.WeaponItemData.ItemID })
    print("BagM@ItemSlotWeaponMobile:OnDrop:",self.SlotIndex)
    
    self:DragEnterSetHighLight(Operation.DefaultDragVisual, false)

    return self:Transport_OnDrop(MyGeometry, PointerEvent, Operation)
end

function ItemSlotWeaponMobile:Transport_OnDragEnter(MyGeometry, PointerEvent, Operation)
    if not Operation then return end
    local DragSourceFlag = Operation.DefaultDragVisual:GetDragSource()
    if not DragSourceFlag then return end
    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragItemData()
    
    print("BagM@ItemSlotWeaponMobile Transport_OnDragEnter> ItemInstanceID:", TempInstanceID)
    
    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
    GameDefine.NItemSubTable.Ingame, "ItemSlotWeaponMobile:Transport_OnDragEnter")
    
    if CurrentItemType == "Attachment" and self:IsHaveWeapon() then
        local CanAttach =  UE.UGAWAttachmentFunctionLibrary.CanAttachToWeapon(self.WeaponItemData.GAWeaponInstance, TempItemID) 
        if  CanAttach  then
            self:DragEnterSetHighLight(Operation.DefaultDragVisual, true)
            Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Equip)
        end
    elseif CurrentItemType == "Weapon" then
        self:DragEnterSetHighLight(Operation.DefaultDragVisual, true)
        Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Equip)
    else

    end
end

function ItemSlotWeaponMobile:Transport_OnDragLeave(PointerEvent, Operation)
    self:DragEnterSetHighLight(Operation.DefaultDragVisual, false)
end

function ItemSlotWeaponMobile:Transport_OnDrop(MyGeometry, PointerEvent, Operation)
    print("BagM@ItemSlotWeaponMobile Transport_OnDrop self.WeaponWidgetNumber:",self.SlotIndex)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    
    UE.UWidgetBlueprintLibrary.CancelDragDrop()

    if not Operation or not Operation.DefaultDragVisual then
        return true
    end

    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragItemData()
    Operation.DefaultDragVisual:OnDropCallBack()
    
    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
    GameDefine.NItemSubTable.Ingame, "ItemSlotWeaponMobile:Transport_OnDrop")
    print("BagM@ItemSlotWeaponMobile Transport_OnDrop IsFindItemType:", TempItemID, CurrentItemType, IsFindItemType)

    if not IsFindItemType then
        self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
        return true
    end

    local TempBagComponent = UE.UBagComponent.Get(PlayerController)
    if not TempBagComponent then return end

    if CurrentItemType == "Weapon" then
        print("BagM@ItemSlotWeaponMobile Transport_OnDrop CurrentItemType", CurrentItemType)

        local DragSourceFlag, DragSourceWidget = Operation.DefaultDragVisual:GetDragSource()
        DragSourceWidget:OnWeaponSlotDragOnDrop()
        if not DragSourceFlag then 
            return 
        end
    
        if TempInstanceIDType == GameDefine.InstanceIDType.ItemInstance and 
        Operation.DefaultDragVisual:GetDropPurpose() == GameDefine.DropAction.PURPOSE_Equip and 
        DragSourceFlag == GameDefine.DragActionSource.EquipZoom then
            -- 武器装备槽位->某个武器槽位（可能是自己）
            if TempItemID == self.WeaponItemData.ItemID and TempInstanceID == self.WeaponItemData.ItemInstanceID then 
                return 
            end
            
            local Reason = nil
            if self.SlotIndex == 1 then
                Reason = ItemSystemHelper.NUsefulReason.SwapToWeapon1
            else
                Reason = ItemSystemHelper.NUsefulReason.SwapToWeapon2
            end

            local PrepareUseInventoryIdentity = UE.FInventoryIdentity()
            PrepareUseInventoryIdentity.ItemID = TempItemID
            PrepareUseInventoryIdentity.ItemInstanceID = TempInstanceID
            local CurrentWAttachmentInventoryInstance = TempBagComponent:GetInventoryInstance(PrepareUseInventoryIdentity)
            if not CurrentWAttachmentInventoryInstance then 
                print("BagM@ItemSlotWeaponMobile Transport_OnDrop not find instance")
                return 
            end
            CurrentWAttachmentInventoryInstance:RequestUseItem(Reason)
        else
            self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
        end
    elseif CurrentItemType == "Attachment" then
        -- 配件
        if TempInstanceIDType == GameDefine.InstanceIDType.ItemInstance and Operation.DefaultDragVisual:GetDropPurpose() == GameDefine.DropAction.PURPOSE_Equip then
            -- 背包区域的物品 -> 装备区域 = 使用物品（装备/替换）

            local AttachmentInventoryIdentity = UE.FInventoryIdentity()
            AttachmentInventoryIdentity.ItemID = TempItemID
            AttachmentInventoryIdentity.ItemInstanceID = TempInstanceID
            local CurrentWAttachmentInventoryInstance = TempBagComponent:GetInventoryInstance(AttachmentInventoryIdentity)
            if not CurrentWAttachmentInventoryInstance then return end

            local OldWeaponInstance = CurrentWAttachmentInventoryInstance:GetCurrentAttachedWInstance()
            if OldWeaponInstance then
                local OldEffectObject = UE.UGAWAttachmentFunctionLibrary.GetAttachmentInstance(OldWeaponInstance,
                CurrentWAttachmentInventoryInstance.AttachmentHandleID)

                local GAWInstance = self.WeaponItemData.GAWeaponInstance
                if not GAWInstance then return end

                local AttachmentEffectArray = UE.UGAWAttachmentFunctionLibrary.GetAllAttachmentEffectHandleInSlot(
                GAWInstance, OldEffectObject.SlotName)
                local CurrentWeaponAttachmentCountInSlot = AttachmentEffectArray:Length()
                local IsExistAttachment = CurrentWeaponAttachmentCountInSlot > 0

                local InReason = nil
                if (self.SlotIndex == 1) then
                    if IsExistAttachment then
                        InReason = ItemAttachmentHelper.NUsefulReason.EquippedSwapWeapon_1
                    else
                        InReason = ItemAttachmentHelper.NUsefulReason.AttachWeapon1
                    end
                elseif (self.SlotIndex == 2) then
                    if IsExistAttachment then
                        InReason = ItemAttachmentHelper.NUsefulReason.EquippedSwapWeapon_2
                    else
                        InReason = ItemAttachmentHelper.NUsefulReason.AttachWeapon2
                    end
                end

                if InReason then
                    CurrentWAttachmentInventoryInstance:RequestUseItem(InReason)
                end
            else
                local InReason = nil
                if self.SlotIndex == 1 then
                    InReason = ItemAttachmentHelper.NUsefulReason.AttachWeapon1
                elseif self.SlotIndex == 2 then
                    InReason = ItemAttachmentHelper.NUsefulReason.AttachWeapon2
                end

                if InReason then
                    CurrentWAttachmentInventoryInstance:RequestUseItem(InReason)
                end
            end
        end
    else
        -- 其他
        self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    end

    return true
end

function ItemSlotWeaponMobile:OnFocusReceived(MyGeometry, InFocusEvent)
    print("BagM@ItemSlotWeaponMobile:OnFocusReceived:",self.SlotIndex)
    self.HandleSelect = true
    self:SetSelectState(true)

    if self.HandleSelect then
        if self.WeaponItemData.ItemID ~= -1 then
            MsgHelper:Send(self, GameDefine.Msg.BagMobile_ShowItemDetail, {
                ItemID= self.WeaponItemData.ItemID,
                ItemSkinId = self.WeaponItemData.WeaponCurrentSkinId,
                EnhanceId = self.WeaponItemData.WeaponEnhanceAttrID,
                InWeaponInstance = self.WeaponItemData.GAWeaponInstance,
            })
        end
    end
    
    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotWeaponMobile:OnFocusLost( InFocusEvent)
    print("BagM@ItemSlotWeaponMobile:OnFocusLost:",self.SlotIndex)
    self.HandleSelect = false
    self:SetSelectState(false)

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_|  
function ItemSlotWeaponMobile:OnWeaponSlotDragOnDrop(InMsgBody)
    -- 设置UI状态动效
end


return ItemSlotWeaponMobile