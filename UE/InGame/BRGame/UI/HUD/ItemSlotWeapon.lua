require "UnLua"
require ("InGame.BRGame.ItemSystem.ItemBase.ItemAttachmentHelper")
require ("Common.Utils.StringUtil")
require ("InGame.BRGame.GameDefine")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local ItemSlotWeapon = Class("Common.Framework.UserWidget")
local ShowGuideSlotNum = 0
------------------------------------ Spawn/Destroy ------------------------------------

function ItemSlotWeapon:OnInit()
    -- Item Info
    self.ItemID = 0
    self.PreItemID = 0
    self.ItemInstanceID = 0
    self.InfiniteAmmo = false
    self.MiscSystem = UE.UMiscSystem.GetMiscSystem(self)

    -- Weapon attachment widget
    self.SupportAttachments = {
        ["Weapon.AttachSlot.Barrel"] = self.AttachmentBarrel,
        ["Weapon.AttachSlot.FrontGrip"] = self.AttachmentFrontGrip,
        ["Weapon.AttachSlot.Optics"] = self.AttachmentOptics,
        ["Weapon.AttachSlot.Mag"] = self.AttachmentMag,
        ["Weapon.AttachSlot.Stocks"] = self.AttachmentStocks
    }
    self.AttachmentBarrel:SetParentWeaponSlotID(self.WeaponSlotID)
    self.AttachmentFrontGrip:SetParentWeaponSlotID(self.WeaponSlotID)
    self.AttachmentOptics:SetParentWeaponSlotID(self.WeaponSlotID)
    self.AttachmentMag:SetParentWeaponSlotID(self.WeaponSlotID)
    self.AttachmentStocks:SetParentWeaponSlotID(self.WeaponSlotID)

    -- Bind DragDrop Delegate
    self:BindDragDropFunctions()

    -- area action
    self.HandleSelect = false
    self.IsHoldLeftMouseButton = false
    self.IsHoldDiscardIA = false
    self.HoldingDiscardTime = 0
    self.HoldToPickTipId = "HoldToPick"

    self.MsgList = {
        { MsgName = GameDefine.Msg.WEAPON_UpdateWeaponBulletNum,    Func = self.OnUpdateWeaponBulletNum },
        { MsgName = GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop,     Func = self.OnWeaponSlotDragOnDrop },
        { MsgName = GameDefine.Msg.InventoryItemNumChangeSingle,    Func = self.OnInventoryItemNumChangeSingle, bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.BAG_WhenShowHideBag,          Func = self.CloseBagPanel,                  bCppMsg = true },
        { MsgName = GameDefine.Msg.InventoryItemClientPreDiscard,   Func = self.OnClientPreDiscard,             bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnDestroy,Func = self.OnInventoryDestroy,bCppMsg = true }
    }

    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC then
        table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,           Func = self.OnUpdatePawn,    bCppMsg = true, WatchedObject = TempLocalPC })
        table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickPart,      Func = self.OnDiscardPart,     bCppMsg = true, WatchedObject = TempLocalPC })
        table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickHalf,      Func = self.OnDiscardHalf,   bCppMsg = true, WatchedObject = TempLocalPC })
        table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickAll,       Func = self.OnDiscardAll,    bCppMsg = true, WatchedObject = TempLocalPC })
        table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickHalfStart,      Func = self.OnDiscardHalfStart,   bCppMsg = true, WatchedObject = TempLocalPC })
        table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickHalfCancel,     Func = self.OnDiscardHalfCancel,   bCppMsg = true, WatchedObject = TempLocalPC })
    end

    self:Reset()
    -- self:ResetWeaponAttachmentWidget()

    self.ImageWeaponArea.OnMouseEnterEvent:Bind(self,self.WeaponArea_OnMouseEnter)
    self.ImageWeaponArea.OnMouseLeaveEvent:Bind(self,self.WeaponArea_OnMouseLeave)

    self:UnBindWeaponAvatarAttachSucceed()
    self:BindWeaponAvatarAttachSucceed()

    self.WBP_ChangeBtn.GUIButton_Main.OnClicked:Add(self, self.OnClickedReplaceSkin)
    self.WBP_ChangeBtn.GUIButton_Main.OnHovered:Add(self, self.OnWBP_ChangeBtnHovered)
    self.WBP_ChangeBtn.GUIButton_Main.OnUnHovered:Add(self, self.OnWBP_ChangeBtnUnHovered)
    self.WBP_ChangeBtn.Bg:SetColorAndOpacity(self.BgColor)
    UserWidget.OnInit(self)
end

function ItemSlotWeapon:UpdateIsFocusable(bIsFocus)
    if not self.SupportAttachments then
        return
    end
    for TagName, Widget in pairs(self.SupportAttachments) do
        Widget.bIsFocusable = bIsFocus
    end
end

function ItemSlotWeapon:OnDiscardPart(InInputData)
    if not self.HandleSelect then
        return
    end

    if self.AttachmentBarrel.HandleSelect then
        self.AttachmentBarrel:DiscardPart()
    end
    if self.AttachmentFrontGrip.HandleSelect then
        self.AttachmentFrontGrip:DiscardPart()
    end
    if self.AttachmentOptics.HandleSelect then
        self.AttachmentOptics:DiscardPart()
    end
    if self.AttachmentMag.HandleSelect then
        self.AttachmentMag:DiscardPart()
    end
    if self.AttachmentStocks.HandleSelect then
        self.AttachmentStocks:DiscardPart()
    end
end


function ItemSlotWeapon:OnDiscardAll(InInputData)
    if self.AttachmentBarrel.HandleSelect then
        self.AttachmentBarrel:OnDropAll()
    end
    if self.AttachmentFrontGrip.HandleSelect then
        self.AttachmentFrontGrip:OnDropAll()
    end
    if self.AttachmentOptics.HandleSelect then
        self.AttachmentOptics:OnDropAll()
    end
    if self.AttachmentMag.HandleSelect then
        self.AttachmentMag:OnDropAll()
    end
    if self.AttachmentStocks.HandleSelect then
        self.AttachmentStocks:OnDropAll()
    end
end

--丢弃武器
function ItemSlotWeapon:OnDiscardHalf(InInputData)
    if not self.HandleSelect then
        return
    end
    
    self.IsHoldDiscardIA = false
    UE.UTipsManager.GetTipsManager(self):RemoveTipsUI(self.HoldToPickTipId)

    self:DiscardSelf()
end

function ItemSlotWeapon:OnDiscardHalfStart(InInputData)
    if not self.HandleSelect then
        return
    end
    self.IsHoldDiscardIA = true
    self.HoldingDiscardTime = 0
    UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId(self.HoldToPickTipId, -1, UE.FGenericBlackboardContainer(), self)
end

function ItemSlotWeapon:OnDiscardHalfCancel(InInputData)
    if not self.HandleSelect then
        return
    end
    self.IsHoldDiscardIA = false
    UE.UTipsManager.GetTipsManager(self):RemoveTipsUI(self.HoldToPickTipId)
end


function ItemSlotWeapon:SetBulletIcon(BulletTex2D)
    self.Image_BulletType:SetBrushFromSoftTexture(BulletTex2D, true);
end

function ItemSlotWeapon:SetWeaponName(Name)
    self.TextBlock_Name:SetText(Name);
end

function ItemSlotWeapon:WeaponArea_OnMouseEnter()
    if BridgeHelper.IsMobilePlatform() then
        return
    end
    

    -- 强化词条
    local TempEnhanceId = nil
    local TempWeaponInventoryIdentity = UE.FInventoryIdentity()
    TempWeaponInventoryIdentity.ItemID = self.ItemID
    TempWeaponInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempPC then
        local TempBagComp = UE.UBagComponent.Get(TempPC)
        if TempBagComp then
            local TempWeaponInventoryInstance = TempBagComp:GetInventoryInstance(TempWeaponInventoryIdentity)
            if TempWeaponInventoryInstance then
                if TempWeaponInventoryInstance:HasItemAttribute("EnhanceAttributeId") then
                    TempEnhanceId = TempWeaponInventoryInstance:GetItemAttributeFString("EnhanceAttributeId")
                end
            end
        end
    end

    print("(Wzp)ItemSlotWeapon:WeaponArea_OnMouseEnter itemid=",self.ItemID,",ItemInstanceID=",self.ItemInstanceID)
    self:WeaponTitleHoverColor()
    self.HandleSelect = true
    if self:IsHaveWeapon() then
        self.Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local TempInteractionKeyName = "Bag.Default.2Action"

        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = nil,
            IsShowAtLeftSide = true,
            ItemID = self.ItemID,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = 1,
            IsShowDiscardNum = true,
            InteractionKeyName = TempInteractionKeyName,
            WeaponInstance = self.GAWeaponInstance,
            EnhanceId = TempEnhanceId,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })

        -- 武器存在时才会设置反色
        self.TextBlock_Name:SetColorAndOpacity(self.CurBulletTextColorMap:FindRef("Hover"))
        self.Text_SkinName:SetColorAndOpacity(self.CurBulletTextColorMap:FindRef("Hover"))
        self.TextBlock_SlotIndex:SetColorAndOpacity(self.CurBulletTextColorMap:FindRef("Hover"))
        self.Image_Key:SetColorAndOpacity(self.CurBulletTextColorMap:FindRef("Hover").SpecifiedColor)

        UE.UGamepadUMGFunctionLibrary.ChangeCursorMoveRate(self, true)
    end
end

function ItemSlotWeapon:WeaponArea_OnMouseLeave()
    if BridgeHelper.IsMobilePlatform() then
        return
    end
    self.Hover:SetVisibility(UE.ESlateVisibility.collapsed)
    self:WeaponTitleStandColor()

    self.HandleSelect = false
    self.IsHoldLeftMouseButton = false


    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
    --self.WBP_ChangeBtn.GUIButton_Main.OnUnHovered:Broadcast()
    self.TextBlock_Name:SetColorAndOpacity(self.CurBulletTextColorMap:FindRef("Stand"))
    self.Text_SkinName:SetColorAndOpacity(self.CurBulletTextColorMap:FindRef("Stand"))
    self.TextBlock_SlotIndex:SetColorAndOpacity(self.CurBulletTextColorMap:FindRef("Stand"))
    self.Image_Key:SetColorAndOpacity(self.CurBulletTextColorMap:FindRef("Stand").SpecifiedColor)

    UE.UGamepadUMGFunctionLibrary.ChangeCursorMoveRate(self, false)
end

function ItemSlotWeapon:OnDestroy()
    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("ItemSlotWeapon:OnDestroy")

    -- Unbind Attachment Function
    self:UnBindWAttachmentGMP()

    -- Weapon attachment widget
    self.SupportAttachments = nil

    -- Item Info
    self.ItemID = nil
    self.ItemInstanceID = nil

    -- area action
    self.HandleSelect = nil
    self.IsHoldLeftMouseButton = nil
    self.InfiniteAmmo = nil
    self.IsHoldDiscardIA = false
    self.HoldingDiscardTime = 0

    self:UnBindGMP()
    self:UnBindDestroyWeaponEnhanceMessage()

    self:UnBindWeaponAvatarAttachSucceed()

    UserWidget.OnDestroy(self)
    TmpProfile.End("ItemSlotWeapon:OnDestroy")
end

function ItemSlotWeapon:OnClose()
    self:HideSopportedAttachmentStyle()
end


function ItemSlotWeapon:Tick(InMyGeometry, InDeltaTime)
    if self.IsHoldDiscardIA then
        self.HoldingDiscardTime = self.HoldingDiscardTime + InDeltaTime
        UE.UTipsManager.GetTipsManager(self):UpdateTipsUIDataByTipsId(self.HoldToPickTipId, self.HoldingDiscardTime, UE.FGenericBlackboardContainer(), self)
    end
end
------------------------------------ Spawn/Destroy ------------------------------------

------------------------------------ Update/Reset -------------------------------------

function ItemSlotWeapon:OnClientPreDiscard(InInventoryInstance)
    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("ItemSlotWeapon:OnClientPreDiscard")

    if not InInventoryInstance then
        return
    end

    if InInventoryInstance:GetInventoryIdentity().ItemID == self.ItemID and InInventoryInstance:GetInventoryIdentity().ItemInstanceID == self.ItemInstanceID then
        self:TryReset()
    end
    TmpProfile.End("ItemSlotWeapon:OnClientPreDiscard")
end

------------------------------------ Update/Reset -------------------------------------

function ItemSlotWeapon:IsExistSlotItem()
    return self.ItemID ~= 0 and self.ItemInstanceID ~= 0
end

--move to C++
-- function ItemSlotWeapon:BindWAttachmentGMP(GAWInstance)
--     if not self.Key_GAW_OnAttachmentStateChange then
--         self.Key_GAW_OnAttachmentStateChange = ListenObjectMessage(nil,
--         GameDefine.MsgCpp.WEAPON_GAW_AttachmentStateChange, self, self.OnAttachmentStateChange)
--     end
-- end
--move to C++
-- function ItemSlotWeapon:UnBindWAttachmentGMP()
--     if self.Key_GAW_OnAttachmentStateChange then
--         UnListenObjectMessage(GameDefine.MsgCpp.WEAPON_GAW_AttachmentStateChange, self,
--         self.Key_GAW_OnAttachmentStateChange)    
--         self.Key_GAW_OnAttachmentStateChange = nil
--     end
-- end

-- move to C++
-- function ItemSlotWeapon:UpdateWeaponBullets(GAWInstance)
--     if GAWInstance then
--         local CurBulletNum = self:GetWeaponCurrentBullet(GAWInstance)
--         self:SetCurBulletNumTxt(CurBulletNum)

--         local InfiniteAmmoFlag = self:GetInfiniteBulletFlag()
--         self:SetInfiniteBulletFlag(InfiniteAmmoFlag)
--         if not InfiniteAmmoFlag then
--             local MaxBulletNum = self:GetWeaponMaxMagBullet(self.CurrentWeaponBulletItemID)
--             self:SetMaxBulletNumTxt(MaxBulletNum)
--         end
--     else
--         self:SetCurBulletNumTxt(0)
--         self:SetInfiniteBulletFlag(false)
--         self:SetMaxBulletNumTxt(0)
--     end
-- end

-- move to C++
-- 获得武器当前弹夹中的子弹数
-- return int32
-- function ItemSlotWeapon:GetWeaponCurrentBullet(GAWeaponInstance)
--     if GAWeaponInstance then
--         local TempMagBoltSetup = GAWeaponInstance:GetMagBoltData()
--         if TempMagBoltSetup then
--             return TempMagBoltSetup.CurrentCartridges
--         end
--     end
--     return 0
-- end

-- move to C++
-- 获得武器当前弹夹最大子弹上限
-- return int32
-- function ItemSlotWeapon:GetWeaponMaxMagBullet(WeaponBulletItemID)
--     if WeaponBulletItemID then
--         local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
--         local TempBagComponent = UE.UBagComponent.Get(PlayerController)
--         if TempBagComponent then
--             local TempItemNum = TempBagComponent:GetItemNumByItemID(WeaponBulletItemID);
--             return TempItemNum
--         end
--     end
--     return 0
-- end

function ItemSlotWeapon:RefreshWeaponDetail()
    local testProfile = require("Common.Utils.InsightProfile")
    testProfile.Begin("ItemSlotWeapon:RefreshWeaponDetail_0")
    -- 强化词条
    local TempEnhanceId = nil
    local TempWeaponInventoryIdentity = UE.FInventoryIdentity()
    TempWeaponInventoryIdentity.ItemID = self.ItemID
    TempWeaponInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempPC then
        local TempBagComp = UE.UBagComponent.Get(TempPC)
        local TempWeaponInventoryInstance = TempBagComp:GetInventoryInstance(TempWeaponInventoryIdentity)
        if TempWeaponInventoryInstance then
            if TempWeaponInventoryInstance:HasItemAttribute("EnhanceAttributeId") then
                TempEnhanceId = TempWeaponInventoryInstance:GetItemAttributeFString("EnhanceAttributeId")
            end
        end
    end


    if self.HandleSelect then
        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = nil,
            IsShowAtLeftSide = true,
            ItemID = self.ItemID,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = 1,
            IsShowDiscardNum = true,
            InteractionKeyName = TempInteractionKeyName,
            WeaponInstance = self.GAWeaponInstance,
            EnhanceId = TempEnhanceId,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })
    end

    testProfile.End("ItemSlotWeapon:RefreshWeaponDetail_0")



        --这里将鼠标悬浮在武器上时候，如果更换武器，武器的详情面板也会更新，这个是之前配件出现问题加的，但是这个很消耗性能暂时注释
    -- testProfile.Begin("ItemSlotWeapon:RefreshWeaponDetail_1")
    local TempInteractionKeyName = "Bag.Default.2Action"

    testProfile.End("ItemSlotWeapon:RefreshWeaponDetail")
end


-- 获取默认的武器
function ItemSlotWeapon:GetCurWeaponSkinImageSlotSoftObjectPtr(InCurWeaponSkinId)
    if not InCurWeaponSkinId then
        return nil
    end

    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, InCurWeaponSkinId)
    if not WeaponSkinCfg then
        return nil
    end

    local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(WeaponSkinCfg.WeaponSlotImage)
    return ImageSoftObjectPtr
end

--move to c++
---- 设置武器图片
function ItemSlotWeapon:UpdateWeaponImageContent(InImageSoftObjectPtr)
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if (self.PreItemID == 0 or self.PreItemID ~= self.ItemID) and UIManager:IsAnyDynamicWidgetShowByKey("UMG_Bag") then
        self:VXE_HUD_StopAnimation() 
        self:VXE_HUD_Bag_Weapon_Equip()
    end
    self.PreItemID = self.ItemID
    if self.Image_Content then
        self.Image_Content:SetBrushFromSoftTexture(InImageSoftObjectPtr, false)
    end
    local TheQualityCfg = MvcEntry:GetModel(DepotModel):GetQualityCfgByItemId(self.ItemID)
    if not TheQualityCfg then 
        return 
    end
    local Quality = TheQualityCfg[Cfg_ItemQualityColorCfg_P.Quality]
    self.GUIImage_SpecialBg:SetVisibility(Quality == 5 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.GUIImage_NameSpecialBg:SetVisibility(Quality == 5 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-- move to C++
-- 设置武器图片是否显示
function ItemSlotWeapon:UpdateWeaponImageVisibility(InState)
    if self.Image_Content then
        if InState then
            self.GUIImage_UnequipGray:SetVisibility(UE.ESlateVisibility.Hidden)
            self.Image_Content:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.GUIImage_UnequipGray:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Image_Content:SetVisibility(UE.ESlateVisibility.Hidden)
            self.PreItemID = 0
        end
    end
end

--move to C++
-- function ItemSlotWeapon:UpdateActiveFlagUI(InActiveState)
--     if InActiveState == true then
--         self:SetSlotActive(true)
--     else
--         self:SetSlotActive(false)
--     end
-- end


function ItemSlotWeapon:SetSlotActive(NewState)
    if NewState then
        self.Image_WeaponSelectionCorner:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.Image_WeaponSelectionCorner:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end


function ItemSlotWeapon:OnMouseButtonDown(MyGeometry, MouseEvent)
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()
    
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return DefaultReturnValue
    end

    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
        self.IsHoldLeftMouseButton = true
        DefaultReturnValue = UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent, self, MouseKey)
    elseif MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
        self:DiscardSelf()
    elseif GameDefine.NInputKey.MiddleMouseButton == MouseKey.KeyName then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        if PlayerController then
            local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
            if BattleChatComp then
                if self.ItemID ~= 0 and nil ~= self.ItemID then
                    AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(BattleChatComp, self.ItemID)
                    print("ItemSlotWeapon:OnMouseButtonDown SendMsg Own Bag !")
                else
                    AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemType(BattleChatComp, "Weapon")
                    print("ItemSlotWeapon:OnMouseButtonDown SendMsg Need Bag !")
                end
            end
        end
    end

    return DefaultReturnValue
end

--丢弃
function ItemSlotWeapon:DiscardSelf()
    if self.ItemID ~= 0 and self.ItemInstanceID ~= 0 then
        local TempInventoryIdentity = UE.FInventoryIdentity()
        TempInventoryIdentity.ItemID = self.ItemID
        TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local TempDiscardTag = UE.FGameplayTag()
        UE.UItemStatics.DiscardItem(PlayerController, TempInventoryIdentity, 1, TempDiscardTag)
        UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
    end
end

-- 鼠标按键抬起
function ItemSlotWeapon:OnMouseButtonUp(MyGeometry, MouseEvent)
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)

    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton and self.IsHoldLeftMouseButton then
        self.IsHoldLeftMouseButton = false
    end
    
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function ItemSlotWeapon:IsSameContent(InInventoryIdentity)
    return (self.ItemID == InInventoryIdentity.ItemID) and (self.ItemInstanceID == InInventoryIdentity.ItemInstanceID)
end
-- move to c++
-- display
function ItemSlotWeapon:SetWeaponWidgetVisibility(InVisibility)
    if InVisibility then
        self:UpdateWeaponImageVisibility(true)
        self.Border_BulletType:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Image_BulletType:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.GUIText_CurBulletNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        local InfiniteAmmoFlag = self:GetInfiniteBulletFlag()
        if not InfiniteAmmoFlag then
            self.GUIText_MaxBulletNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end

        self.GUIText_Delimiter:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self:UpdateWeaponImageVisibility(false)
        self.Image_WeaponSelectionCorner:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.GUIImage_NameSpecialBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Border_BulletType:SetVisibility(UE.ESlateVisibility.Hidden)
        self.Image_BulletType:SetVisibility(UE.ESlateVisibility.Hidden)
        self.GUIText_CurBulletNum:SetVisibility(UE.ESlateVisibility.Hidden)
        self.GUIText_Delimiter:SetVisibility(UE.ESlateVisibility.Hidden)
        self.GUIText_MaxBulletNum:SetVisibility(UE.ESlateVisibility.Hidden)
        self.GUIImage_InfiniteAmmo:SetVisibility(UE.ESlateVisibility.Hidden)
        self.GUIImage_SpecialBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.GUIImage_NameSpecialBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TextBlock_Name:SetText(self.NullStateWeaponName)
    end
end

-- move to C++
-- function ItemSlotWeapon:SetNameAndImage()
--     local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(self)
--     local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(self.ItemID, "Ingame")
--     local StrItemID = tostring(self.ItemID)

--     local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, self.ItemID)
--     if not IngameDT then
--         return
--     end

--     local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, StrItemID)
--     if not StructInfo_Item then
--         return
--     end
    
--     -- 设置武器名称
--     local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
--     self.TextBlock_Name:SetText(TranslatedItemName)

--     -- 设置武器的装备栏图片
--     local TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId = self:GetImportantSkinIds(self.GAWeaponInstance)
--     local TempImageSoftObjectPtr = self:GetCurWeaponSkinImageSlotSoftObjectPtr(TempCurWeaponSkinId)
--     if TempImageSoftObjectPtr then
--         self:UpdateWeaponImageContent(TempImageSoftObjectPtr)
--     end

--     -- 设置皮肤Override控件的显示（按I切换）
--     local TempIsShowCanOverrideWidget = self:IsShowWeaponSkinCanOverrideWidget(TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId)
--     if TempIsShowCanOverrideWidget then
--         self:SetWeaponOverrideWidgetVisibility(true)
--     else
--         self:SetWeaponOverrideWidgetVisibility(false)
--     end

--     -- 设置皮肤的名称和颜色
--     if (TempCurWeaponSkinId ~= TempDefaultWeaponSkinId) and (TempCurWeaponSkinId ~= -1) then
--         self:SetWeaponSkinNameWidgetVisibility(true)
--         self:SetWeaponSkinNameBySkinId(TempCurWeaponSkinId)
--         self:SetWeaponSkinBgColorBySkinId(TempCurWeaponSkinId)
--     else
--         self:SetWeaponSkinNameWidgetVisibility(false)
--     end

--     -- 设置武器使用子弹的图标
--     local BulletID, IsFindBulletID = SubTable:BP_FindDataInt32(StrItemID, "BulletItemID")
--     if IsFindBulletID then
--         local SubTableForBullet = TableManagerSubsystem:GetItemCategorySubTableByItemID(BulletID, "Ingame")
--         local BulletItemIcon, IsFindBulletIcon = SubTableForBullet:BP_FindDataFString(tostring(BulletID), "ItemIcon")
--         if IsFindBulletIcon then
--             local ImageSoftObjectBulletPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(BulletItemIcon)
--             self.Image_BulletType:SetBrushFromSoftTexture(ImageSoftObjectBulletPtr, true)
--         end
--     end
-- end

-- move to C++
-- 更新当前武器所使用的子弹物品ID
-- function ItemSlotWeapon:UpdateWeaponBulletItemID(WeaponItemID)
--     if WeaponItemID then
--         local BulletItemID, bValidBulletItemID = UE.UItemSystemManager.GetItemDataInt32(self, WeaponItemID,
--         "BulletItemID", GameDefine.NItemSubTable.Ingame, "InteractiveWeaponDetail:UpdateWeaponBulletItemID")
--         if bValidBulletItemID then
--             self.CurrentWeaponBulletItemID = BulletItemID
--         end
--     else
--         self.CurrentWeaponBulletItemID = nil
--     end
-- end


function ItemSlotWeapon:GetFormat(InStr)
    return StringUtil.ConvertString2FText(StringUtil.Format(InStr))
end

function ItemSlotWeapon:GetWeaponSingleItemById(InCurWeaponSkinId)
    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, InCurWeaponSkinId)
    if not WeaponSkinCfg then
        return nil
    end
    return WeaponSkinCfg
end

-- move to C++
function ItemSlotWeapon:WeaponTitleStandColor()
    local CurBulletTextColor = self.CurBulletTextColorMap:Find("Stand")
    self.GUIText_CurBulletNum:SetColorAndOpacity(CurBulletTextColor)

    local MaxBulletTextColor = self.MaxBulletTextColorMap:Find("Stand")
    self.GUIText_Delimiter:SetColorAndOpacity(MaxBulletTextColor)
    self.GUIText_MaxBulletNum:SetColorAndOpacity(MaxBulletTextColor)
end
-- move to C++
function ItemSlotWeapon:WeaponTitleHoverColor()
    local CurBulletTextColor = self.CurBulletTextColorMap:Find("Hover")
    self.GUIText_CurBulletNum:SetColorAndOpacity(CurBulletTextColor)

    local MaxBulletTextColor = self.MaxBulletTextColorMap:Find("Hover")
    self.GUIText_Delimiter:SetColorAndOpacity(MaxBulletTextColor)
    self.GUIText_MaxBulletNum:SetColorAndOpacity(MaxBulletTextColor)
end

function ItemSlotWeapon:IsHaveWeapon()
    return self.ItemID ~= 0
end


function ItemSlotWeapon:ResetWeaponAttachmentWidget()
    if not self.SupportAttachments or not #self.SupportAttachments == 0 then
        return
    end
    for _, value in pairs(self.SupportAttachments) do
        if value then
            --value:SetVisibility(UE.ESlateVisibility.Collapsed)
            value:Reset()
            local Visibility = value:GetVisibility()
            if Visibility ~= UE.ESlateVisibility.Collapsed then
                value:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
    end
end

function ItemSlotWeapon:SetAttachmentVisible(SupportTagArray)
    if (not self.SupportAttachments) or (not #self.SupportAttachments == 0) then
        return
    end

    -- 校验 SupportTagArray 元素个数
    local ArrNum = SupportTagArray:Num()
    if not SupportTagArray or ArrNum <= 0 then
        return
    end

    -- 拿到枪的Tag，作为类型设置配件槽背景图标，因为每种类型枪的部分配件槽图标不一样
    local WeaponTag = self.GAWeaponInstance:GetMainWeaponTag()

    -- 记录可支持的配件 tag，方便下面 for 循环查询
    local OwneTable = {}
    for index = 1, ArrNum do
        local VisibleWidgetTag = SupportTagArray:Get(index)
        local TagStr = VisibleWidgetTag.TagName
        OwneTable[TagStr] = true
    end

    for Key, Widget in pairs(self.SupportAttachments) do
        --查到有返回true，没有则返回false
        --如果有则设置可见，没有则不可见
        --对比可见性，如果不是想要的可见性则主动设置可见性

        local bContains = OwneTable[Key] and true or false

        local WidgetVisibility = Widget:GetVisibility()

        local TargetVisibility = bContains and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed
        if WidgetVisibility ~= TargetVisibility then
            Widget:SetVisibility(TargetVisibility)
        end

        --如果有这把枪所支持的配件槽，再根据这把枪的类型（Tag）设置这把枪配件槽的图标
        if bContains then
            Widget:UpdateTypeBackground(WeaponTag)
        end
    end

end

function ItemSlotWeapon:GetAllAttachmentWidget()
    local AttachmentList = {self.AttachmentBarrel,self.AttachmentOptics,self.AttachmentFrontGrip,self.AttachmentMag,self.AttachmentStocks}
    return AttachmentList
end


function ItemSlotWeapon:UpdateAttachmentNavigation()
    local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    local WidgetNavgationArr = {}
    local ChildrenCount = self.AttachSlots:GetChildrenCount()
    local index = 0
    for i = 1, ChildrenCount do
        local Widget = self.AttachSlots:GetChildAt(i-1)
        local Visbility = Widget:GetVisibility()
        -- local bIsEmptySlot = Widget:IsEmptySlot()
        if  Visbility == UE.ESlateVisibility.Collapsed then
            Widget.bIsFocusable = false
        else
            if not IsInCursorMode then
                Widget.bIsFocusable = true
            end
            index = index + 1
            table.insert(WidgetNavgationArr,index,Widget)
        end
    end

    self.FirstEquipedAttachment = nil

    for i = 1, #WidgetNavgationArr do

        if self.FirstEquipedAttachment == nil then
            self.FirstEquipedAttachment = WidgetNavgationArr[i]
        end

        local PerSlotIndex = i-1;
        local NextSlotIndex = i+1;
        local PerAttachSlot = PerSlotIndex < 1 and nil or WidgetNavgationArr[PerSlotIndex]
        local NextAttachSlot = NextSlotIndex > #WidgetNavgationArr and nil or WidgetNavgationArr[NextSlotIndex]

        if PerAttachSlot then
            WidgetNavgationArr[i]:SetNavigationRule(UE.EUINavigation.Left,UE.EUINavigationRule.Explicit,0)
            WidgetNavgationArr[i]:SetNavigationRuleExplicit(UE.EUINavigation.Left,PerAttachSlot)
        end

        if NextAttachSlot then
            WidgetNavgationArr[i]:SetNavigationRule(UE.EUINavigation.Right,UE.EUINavigationRule.Explicit,0)
            WidgetNavgationArr[i]:SetNavigationRuleExplicit(UE.EUINavigation.Right,NextAttachSlot)
        end
    end
end

-- move to C++
function ItemSlotWeapon:SetCurBulletNumTxt(InBulletNum)
    if InBulletNum and InBulletNum > 0 and self.GUIText_CurBulletNum then
        self.GUIText_CurBulletNum:SetText(tostring(InBulletNum))
    else
        self.GUIText_CurBulletNum:SetText("0")
    end
end

--move to C++
function ItemSlotWeapon:SetMaxBulletNumTxt(InBulletNum)
    if InBulletNum and InBulletNum > 0 and self.GUIText_MaxBulletNum then

        local NumStr = tostring(InBulletNum)
        local FinnalNum = string.format("%03d",NumStr)
        self.GUIText_MaxBulletNum:SetText(FinnalNum)
    else
        self.GUIText_MaxBulletNum:SetText("000")
    end
end

-- move to C++
-- function ItemSlotWeapon:GetInfiniteBulletFlag()
--     if self.GAWeaponInstance then
--         local IsInfiniteAmmo = self.GAWeaponInstance:IsInfiniteAmmo()
--         return IsInfiniteAmmo
--     end
--     return false
-- end

-- move to C++
function ItemSlotWeapon:SetInfiniteBulletFlag(InNewState)
    if self.InfiniteAmmo == InNewState then
        return
    end

    if InNewState then
        self.InfiniteAmmo = true
        self.GUIImage_InfiniteAmmo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.GUIText_MaxBulletNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.InfiniteAmmo = false
        self.GUIImage_InfiniteAmmo:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.GUIText_MaxBulletNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end


function ItemSlotWeapon:GetAttachmentWidget(AttachmentTag)
    local bContains = false
    for key, _ in pairs(self.SupportAttachments) do
        if key == AttachmentTag.TagName then
            bContains = true
        end
    end

    if not bContains then
     return nil
    end

    if self.SupportAttachments[AttachmentTag.TagName] == nil then
       return nil
    end
    
    local Widget = self.SupportAttachments[AttachmentTag.TagName]
    return Widget
end

--move to C++
-- function ItemSlotWeapon:OnAttachmentStateChange(InGAWAttachmentStateChangeGMPData)
--     if not InGAWAttachmentStateChangeGMPData then return end
--     if not self.GAWeaponInstance then return end
--     if self.GAWeaponInstance == InGAWAttachmentStateChangeGMPData.WeaponInstance then
--         self:UpdateWeaponAttachmentWidget()
--     end
-- end

-- 当拖拽UI悬停在本控件之上时，触发此回调
function ItemSlotWeapon:OnDragEnter(MyGeometry, PointerEvent, Operation)
    -- 显示武器槽边框高亮
    --self.GUIImage_EquipBorder:SetVisibility(UE.ESlateVisibility.Visible)
    --self.OverlayDragOn:SetVisibility(UE.ESlateVisibility.Visible) --self.GUIImage_Light:SetVisibility(UE.ESlateVisibility.Visible)
    if not Operation then return end
    local DragSourceFlag = Operation.DefaultDragVisual:GetDragSource()
    if not DragSourceFlag then return end
    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragInfo()
    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType", GameDefine.NItemSubTable.Ingame, "DropZoomUI:OnDropToPickZoom")
    if IsFindItemType and CurrentItemType == "Weapon" then
        if self:IsHaveWeapon() and TempItemID ~= self.ItemID then
            self:VXE_HUD_Bag_Weapon_Focus_In()
            self:VXE_HUD_Bag_Gun_DragOn_In()
        elseif not self:IsHaveWeapon() then
            self:VXE_HUD_Bag_Gun_DragOn_In()
        end
    end
    if IsFindItemType and CurrentItemType == "Attachment" then
        local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, TempItemID)
        if not IngameDT then return end
        local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(TempItemID))
        if not StructInfo_Item then return end
        if self.SupportAttachments and self.SupportAttachments[StructInfo_Item.SlotName.TagName] then
            self.SupportAttachments[StructInfo_Item.SlotName.TagName]:SetGuideVXEStyle(true)
        end
        local AnotherSlotID = self.WeaponSlotID == 1 and 2 or 1
        MsgHelper:Send(self, GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop, { WeaponSlotID = AnotherSlotID, AttachmentTag = StructInfo_Item.SlotName.TagName, bShowHightLight = false })
    end
    self:Transport_OnDragEnter(MyGeometry, PointerEvent, Operation)
end

-- 当拖拽UI离开本控件之上时，触发此回调
function ItemSlotWeapon:OnDragLeave(PointerEvent, Operation)
    -- 隐藏灰色蒙版、高亮蒙版和高亮边框
    --MsgHelper:Send(nil, GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop, { WeaponItemID = self.ItemID })
    print("ItemSlotWeapon >> ItemSlotWeapon self.WeaponWidgetNumber:",self.WeaponWidgetNumber)
    self.OverlayDragOn:SetVisibility(UE.ESlateVisibility.Hidden) --self.GUIImage_Light:SetVisibility(UE.ESlateVisibility.Hidden)
    if self:IsPlayingAnimation(self.vx_hud_bag_weapon_dragon_anim) then self:VXE_HUD_Bag_Gun_DragOn_Out() end
    if self.VX_Focus:GetRenderOpacity() == 1 then self:VXE_HUD_Bag_Weapon_Focus_Out() end

    if not Operation then return end
    local DragSourceFlag = Operation.DefaultDragVisual:GetDragSource()
    if not DragSourceFlag then return end
    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragInfo()
    print("ItemSlotWeapon >> Transport_OnDragEnter > ItemInstanceID:", TempInstanceID)
    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
    GameDefine.NItemSubTable.Ingame, "DropZoomUI:OnDropToPickZoom")
    if not IsFindItemType then return end
    if CurrentItemType == "Attachment" then
        local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, TempItemID)
        if not IngameDT then return end
        local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(TempItemID))
        if not StructInfo_Item then return end
        if not self.SupportAttachments then return end
        if not self.SupportAttachments[StructInfo_Item.SlotName.TagName] then return end
        self.SupportAttachments[StructInfo_Item.SlotName.TagName]:SetGuideVXEStyle(false)
        local AnotherSlotID = self.WeaponSlotID == 1 and 2 or 1
        MsgHelper:Send(self, GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop, { WeaponSlotID = AnotherSlotID, AttachmentTag = StructInfo_Item.SlotName.TagName, bShowHightLight = true })
    end
    self:Transport_OnDragLeave(PointerEvent, Operation)
end

-- 当拖拽到本控件并释放鼠标按键的时候会触发此回调（拖拽完成）
function ItemSlotWeapon:OnDrop(MyGeometry, PointerEvent, Operation)
    --MsgHelper:Send(nil, GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop, { WeaponItemID = self.ItemID })
    print("ItemSlotWeapon >> ItemSlotWeapon self.WeaponWidgetNumber:",self.WeaponWidgetNumber)
    self:DragEnterSetHighLight(Operation.DefaultDragVisual, false)
    return self:Transport_OnDrop(MyGeometry, PointerEvent, Operation)
end

function ItemSlotWeapon:Transport_OnDragEnter(MyGeometry, PointerEvent, Operation)
    if not Operation then return end
    local DragSourceFlag = Operation.DefaultDragVisual:GetDragSource()
    if not DragSourceFlag then return end
    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragInfo()
    print("ItemSlotWeapon >> Transport_OnDragEnter > ItemInstanceID:", TempInstanceID)
    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
    GameDefine.NItemSubTable.Ingame, "DropZoomUI:OnDropToPickZoom")
    if CurrentItemType == "Attachment" and self:IsExistSlotItem() then
        local CanAttach =  UE.UGAWAttachmentFunctionLibrary.CanAttachToWeapon(self.GAWeaponInstance, TempItemID) 
        if  CanAttach  then
            self:DragEnterSetHighLight(Operation.DefaultDragVisual, true)
            Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Equip)
        end
    elseif CurrentItemType == "Weapon" then
        self:DragEnterSetHighLight(Operation.DefaultDragVisual, true)
        Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Equip)
    -- else
        --self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
    end


end

function ItemSlotWeapon:Transport_OnDragLeave(PointerEvent, Operation)
    -- 直接转发
    self:DragEnterSetHighLight(Operation.DefaultDragVisual, false)
    --self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end

function ItemSlotWeapon:Transport_OnDrop(MyGeometry, PointerEvent, Operation)
    print("ItemSlotWeapon >> Transport_OnDrop self.WeaponWidgetNumber:",self.WeaponWidgetNumber)
    print("ItemSlotWeapon >> Transport_OnDrop")
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    self:HideAllHighLight()
    -- 完成拖拽就隐藏灰色蒙版、高亮蒙版和高亮边框
    print("ItemSlotWeapon:Transport_OnDrop")

    --self.GUIImage_EquipBorder:SetVisibility(UE.ESlateVisibility.Hidden)
    self.OverlayDragOn:SetVisibility(UE.ESlateVisibility.Hidden) --self.GUIImage_Light:SetVisibility(UE.ESlateVisibility.Hidden)
    UE.UWidgetBlueprintLibrary.CancelDragDrop()
    if not Operation or not Operation.DefaultDragVisual then
        return true
    end

    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragInfo()
    Operation.DefaultDragVisual:OnDropCallBack()
    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
    GameDefine.NItemSubTable.Ingame, "ItemSlotWeapon:OnDrop")
    if not IsFindItemType then
        self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
        return true
    end

    local StructInfo_Item = nil
    if (CurrentItemType == "Weapon") then self:VXE_HUD_StopAnimation() end
    if (CurrentItemType == "Attachment") then 
        local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, TempItemID)
        if IngameDT then
            StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(TempItemID))
        end
    end

    if TempInstanceIDType == GameDefine.InstanceIDType.PickInstance then
        -- 配件和武器，从拾取列表可以拖拽到槽位，指定最后能装备的最终槽位，或者替换到指定槽位的武器
        if (CurrentItemType == "Attachment") or (CurrentItemType == "Weapon") then
            local TempGameplayTag = UE.FGameplayTag()
            if self.WeaponSlotID == 1 then
                TempGameplayTag.TagName = "InventoryItem.TryAddToSlot.1"
            elseif self.WeaponSlotID == 2 then
                TempGameplayTag.TagName = "InventoryItem.TryAddToSlot.2"
            end

            local TempTagContainer = UE.FGameplayTagContainer()
            TempTagContainer.GameplayTags:Add(TempGameplayTag)

            local TempGameplayTagDragDrop = UE.FGameplayTag()
            TempGameplayTagDragDrop.TagName = "PickSystem.PickMode.Drag"
            TempTagContainer.GameplayTags:Add(TempGameplayTagDragDrop)

            local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(PlayerController)
            if LocalPCPawn then
                local PickupObjArray = Operation.DefaultDragVisual:GetPickupObjInfo()
                if not PickupObjArray then return end
                for index = 1, PickupObjArray:Length() do
                    local CurrentPickupObj = PickupObjArray:Get(index)
                    if CurrentPickupObj then
                        UE.UPickupStatics.TryPickupItem(LocalPCPawn, CurrentPickupObj,0, UE.EPickReason.PR_Player,TempTagContainer)
                    end
                end
            end

            return true
        else
            self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
            return true
        end
    end

    local TempBagComponent = UE.UBagComponent.Get(PlayerController)
    if not TempBagComponent then return end

    if CurrentItemType == "Weapon" then
        -- 武器
        local DragSourceFlag,DragSourceWidget = Operation.DefaultDragVisual:GetDragSource()
        DragSourceWidget:OnWeaponSlotDragOnDrop()
        if not DragSourceFlag then return end
        if TempInstanceIDType == GameDefine.InstanceIDType.ItemInstance and Operation.DefaultDragVisual:GetDropPurpose() == GameDefine.DropAction.PURPOSE_Equip and DragSourceFlag == GameDefine.DragActionSource.EquipZoom then
            -- 武器装备槽位->某个武器槽位（可能是自己）
            if TempItemID == self.ItemID and TempInstanceID == self.ItemInstanceID then return end
            local Reason = nil
            if self.WeaponSlotID == 1 then
                Reason = ItemSystemHelper.NUsefulReason.SwapToWeapon1
            else
                Reason = ItemSystemHelper.NUsefulReason.SwapToWeapon2
            end

            local PrepareUseInventoryIdentity = UE.FInventoryIdentity()
            PrepareUseInventoryIdentity.ItemID = TempItemID
            PrepareUseInventoryIdentity.ItemInstanceID = TempInstanceID
            local CurrentWAttachmentInventoryInstance = TempBagComponent:GetInventoryInstance(PrepareUseInventoryIdentity)
            if not CurrentWAttachmentInventoryInstance then return end
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

            -- 获取当前拖拽到的武器
            local WeaponInventoryIdentity = UE.FInventoryIdentity()
            WeaponInventoryIdentity.ItemID = self.ItemID
            WeaponInventoryIdentity.ItemInstanceID = self.ItemInstanceID
            local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
            local TempPawn = PlayerController:GetPawn()
            local TempEquipmentComp = UE.UEquipmentStatics.GetEquipmentComponent(TempPawn)
            if not TempEquipmentComp then return end
            local CurrentDropToWeaponInstance = TempEquipmentComp:GetEquipmentInstanceByInventoryIdentity(WeaponInventoryIdentity)
            if not CurrentDropToWeaponInstance then return end

            -- 查询当前拖拽到的武器的目标槽位是否已存在配件
            local DropToWeaponAttachmentEffectArray = UE.UGAWAttachmentFunctionLibrary.GetAllAttachmentEffectHandleInSlot(CurrentDropToWeaponInstance, StructInfo_Item.SlotName)
            local DropToWeaponAttachmentCountInSlot = DropToWeaponAttachmentEffectArray:Length()
            local IsExistAttachment = DropToWeaponAttachmentCountInSlot > 0

            local InReason = nil
            if (self.WeaponSlotID == 1) then
                if IsExistAttachment then
                    InReason = ItemAttachmentHelper.NUsefulReason.EquippedSwapWeapon_1
                else
                    InReason = ItemAttachmentHelper.NUsefulReason.AttachWeapon1
                end
            elseif (self.WeaponSlotID == 2) then
                if IsExistAttachment then
                    InReason = ItemAttachmentHelper.NUsefulReason.EquippedSwapWeapon_2
                else
                    InReason = ItemAttachmentHelper.NUsefulReason.AttachWeapon2
                end
            end

            if InReason then
                CurrentWAttachmentInventoryInstance:RequestUseItem(InReason)
            end
        end
    else
        -- 其他
        self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    end

    return true
end

function ItemSlotWeapon:DragEnterSetHighLight(DragWidget, HighLightBool)
    if not DragWidget then return end

    local DragItemID, DragWeaponInstanceID, DragItemNum, DragIDType = DragWidget:GetDragInfo()
    if self.ItemInstanceID ~= DragWeaponInstanceID and HighLightBool then
        self.OverlayDragOn:SetVisibility(UE.ESlateVisibility.Visible)
        UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Hover_01")
    else
        self.OverlayDragOn:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function ItemSlotWeapon:HideAllHighLight()
    self.OverlayDragOn:SetVisibility(UE.ESlateVisibility.Hidden)
    -- local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    -- local OutTags = UE.UGWSWeaponWorldSubsystem.GetWeaponOwnedAttachSlotTags(PlayerController,self.WeaponHandle)
    -- local OutTagsNum = OutTags:Length()
    -- if OutTagsNum == 0 then return end
    -- for i = 1, OutTagsNum do
    --     local AllowAttachSlotTag = OutTags:Get(i)
    --     local TargetAttachmentWidget = self:GetAttachmentWidget(AllowAttachSlotTag)
    --     if not TargetAttachmentWidget then break end
    --     TargetAttachmentWidget:SetHighLightVisibility(false)
    -- end
end

function ItemSlotWeapon:BindDragDropFunctions()
    for key, value in pairs(self.SupportAttachments) do
        if not value then goto continue end
        if value.Delegate_TransportOnDragEnter then
            value.Delegate_TransportOnDragEnter:Add(self, self.Transport_OnDragEnter)
        end

        if value.Delegate_TransportOnDrop then
            value.Delegate_TransportOnDrop:Add(self, self.Transport_OnDrop)
        end

        -- if value.Delegate_TransportOnDragLeave then
        --     value.Delegate_TransportOnDragLeave:Add(self, self.Transport_OnDragLeave)
        -- end

        ::continue::
    end
end

function ItemSlotWeapon:OnDragDetected(MyGeometry, PointerEvent)
    if self.ItemID == 0 then
        return nil
    end

    if self.Overlay_Active then self:VXE_HUD_Bag_Weapon_Floating_In() end
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)

    -- 在这里显示卸载的灰色蒙版
    -- self.GUIImage_UnequipGray:SetVisibility(UE.ESlateVisibility.Visible)
    local CurWeaponSlotIndex = self.TextBlock_SlotIndex:GetText()
    local CurWeaponName = self.TextBlock_Name:GetText()

    DefaultDragVisualWidget:SetDragInfo(self.ItemID, self.ItemInstanceID, 1, GameDefine.InstanceIDType.ItemInstance,
    tonumber(CurWeaponSlotIndex), CurWeaponName, self.GAWeaponInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.EquipZoom, self)
    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget
    return DragDropObject
end

-- CallBack
function ItemSlotWeapon:OnUpdateWeaponBulletNum(InMsgBody)
    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("ItemSlotWeapon:OnUpdateWeaponBulletNum")

    print("ItemSlotWeapon:OnUpdateWeaponBulletNum-->InMsgBody:", InMsgBody.WeaponEntity, "SlotID", InMsgBody.SlotID,
    "self.WeaponSlotID:", self.WeaponSlotID)
    if self.WeaponSlotID ~= InMsgBody.SlotID then
        return
    end
    if InMsgBody.WeaponEntity ~= nil then
        self:UpdateWeaponBullets(InMsgBody.WeaponEntity)
    else
        print("InMsgBody.WeaponEntity is nil")
    end
    TmpProfile.End("ItemSlotWeapon:OnUpdateWeaponBulletNum")
end

function ItemSlotWeapon:OnWeaponSlotDragOnDrop(InMsgBody)
    if self.Overlay_Active and self.Overlay_Active:GetRenderOpacity() ~= 1 then
        self:VXE_HUD_Bag_Weapon_Floating_Out() 
    end

    if InMsgBody == nil then return end

    if InMsgBody.WeaponSlotID ~= nil and InMsgBody.AttachmentTag ~= nil and InMsgBody.bShowHightLight ~= nil then
        if InMsgBody.WeaponSlotID == self.WeaponSlotID then
            self.SupportAttachments[InMsgBody.AttachmentTag]:SetGuideVXEStyle(InMsgBody.bShowHightLight)
        end
    end

    if InMsgBody.AttachmentTag ~= nil and InMsgBody.bEndGuide ~= nil then
        if InMsgBody.bEndGuide then
            self:EndWeaponAttachmentEquipGuide(InMsgBody.AttachmentTag)
        end
    end


    -- self.GUIImage_UnequipGray:SetVisibility(UE.ESlateVisibility.Hidden)
end

function ItemSlotWeapon:OnInventoryItemNumChangeSingle(InFGMPMessage_InventoryItemChange)
    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("ItemSlotWeapon:OnInventoryItemNumChangeSingle")

    if not InFGMPMessage_InventoryItemChange.ItemObject then return end
    local TempLocalPC = InFGMPMessage_InventoryItemChange.ItemObject:GetPlayerController()
    if not TempLocalPC then return end
    if TempLocalPC:GetWorld() ~= self:GetWorld() then return end
    if self.GAWeaponInstance then
        local CurrentInventoryIdentity = InFGMPMessage_InventoryItemChange.ItemObject:GetInventoryIdentity()
        --武器使用的弹药数量有修改时，更新UI
        if CurrentInventoryIdentity.ItemID == self.CurrentWeaponBulletItemID then
            TmpProfile.Begin("ItemSlotWeapon:UpdateWeaponBullets")
            self:UpdateWeaponBullets(self.GAWeaponInstance)
            TmpProfile.End("ItemSlotWeapon:UpdateWeaponBullets")
        end
    end
    TmpProfile.End("ItemSlotWeapon:OnInventoryItemNumChangeSingle")
end

function ItemSlotWeapon:OnInventoryDestroy(InInventoryInstance)
    print("ItemSlotWeapon >> OnInventoryDestroy...")
    local CurrentInventoryIdentity = InInventoryInstance:GetInventoryIdentity()
    if self.GAWeaponInstance then
        if CurrentInventoryIdentity.ItemID == self.CurrentWeaponBulletItemID then
            self:SetMaxBulletNumTxt(0)
        end
    end
end

function ItemSlotWeapon:CloseBagPanel(IsVisible)
    if (not IsVisible) then
        -- self.GUIImage_UnequipGray:SetVisibility(UE.ESlateVisibility.Hidden)
        --self.GUIImage_EquipBorder:SetVisibility(UE.ESlateVisibility.Hidden)
        self.OverlayDragOn:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end


function ItemSlotWeapon:OnUpdatePawn(InLocalPC, InPCPwn)
    self:UnBindWeaponAvatarAttachSucceed()
    self:BindWeaponAvatarAttachSucceed()
end

function ItemSlotWeapon:BindWeaponAvatarAttachSucceed()
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC then
        local CurPawn = TempLocalPC:GetPawn()
        if CurPawn then
            if self.WeaponAttachSucceedHandle then
                self:UnBindWeaponAvatarAttachSucceed()
            end
            self.WeaponAttachSucceedHandle = ListenObjectMessage(CurPawn, GameDefine.MsgCpp.WEAPON_SKIN_ATTACH_SUCCEED, self, self.OnWeaponAvatarAttachSucceed)
        end
    end
end

function ItemSlotWeapon:UnBindWeaponAvatarAttachSucceed()
    if self.WeaponAttachSucceedHandle then
        UnListenObjectMessage(GameDefine.MsgCpp.WEAPON_SKIN_ATTACH_SUCCEED, self, self.WeaponAttachSucceedHandle)
        self.WeaponAttachSucceedHandle = nil
    end
end

function ItemSlotWeapon:OnWeaponAvatarAttachSucceed(InUAvatarItemDefinitionPtr)
    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("ItemSlotWeapon:OnWeaponAvatarAttachSucceed")

    if not InUAvatarItemDefinitionPtr then
       return 
    end

    if self.GAWeaponInstance then
        -- 设置武器的装备栏图片
        local TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId = self:GetImportantSkinIds(self.GAWeaponInstance)
        local TempImageSoftObjectPtr = self:GetCurWeaponSkinImageSlotSoftObjectPtr(TempCurWeaponSkinId)
        if TempImageSoftObjectPtr then
            self:UpdateWeaponImageContent(TempImageSoftObjectPtr)
        end

        -- 设置皮肤Override控件的显示（按I切换）
        local TempIsShowCanOverrideWidget = self:IsShowWeaponSkinCanOverrideWidget(TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId)
        if TempIsShowCanOverrideWidget then
            self:SetWeaponOverrideWidgetVisibility(true)
        else
            self:SetWeaponOverrideWidgetVisibility(false)
        end

        -- 设置皮肤的名称和颜色
        if (TempCurWeaponSkinId ~= TempDefaultWeaponSkinId) and (TempCurWeaponSkinId ~= -1) then
            self:SetWeaponSkinNameWidgetVisibility(true)
            self:SetWeaponSkinNameBySkinId(TempCurWeaponSkinId)
            self:SetWeaponSkinBgColorBySkinId(TempCurWeaponSkinId)
        else
            self:SetWeaponSkinNameWidgetVisibility(false)
        end
    end
    TmpProfile.End("ItemSlotWeapon:OnWeaponAvatarAttachSucceed")
end

-- move to C++
-- function ItemSlotWeapon:GetImportantSkinIds(InGAWeaponInstance)
--     local TempCurWeaponSkinId = -1
--     local TempDefaultWeaponSkinId = -1
--     local TempReplacedWeaponSkinId = -1

--     if not InGAWeaponInstance then
--         return TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId
--     end

--     local TempAvatarManagerSubsystem = UE.UAvatarManagerSubsystem.Get(self)
--     if not TempAvatarManagerSubsystem then
--         return TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId
--     end

--     local TempTargetSlot = UE.FGameplayTag()
--     TempTargetSlot.TagName = GameDefine.NTag.WEAPON_SKIN_ATTACHSLOT_GUNBODY
--     TempCurWeaponSkinId = TempAvatarManagerSubsystem:GetWeaponCurrentAvatarID(InGAWeaponInstance, TempTargetSlot)
--     TempDefaultWeaponSkinId = TempAvatarManagerSubsystem:GetWeaponDefaultAvatarID(InGAWeaponInstance, TempTargetSlot)
--     TempReplacedWeaponSkinId = TempAvatarManagerSubsystem:GetWeaponReplacedAvatarIDByWeaponInst(InGAWeaponInstance)

--     return TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId
-- end

--move to C++
-- function ItemSlotWeapon:IsShowWeaponSkinCanOverrideWidget(InCurWeaponSkinId, InDefaultWeaponSkinId, InReplacedWeaponSkinId)
--     local ReturnVal = false

--     if InCurWeaponSkinId == -1 or InDefaultWeaponSkinId == -1 or InReplacedWeaponSkinId == -1 then
--         return ReturnVal
--     end

--     --设置皮肤Override状态
--     if InCurWeaponSkinId ~= -1 then
--         if InReplacedWeaponSkinId == InDefaultWeaponSkinId then
--             return ReturnVal
--         end
--         if InCurWeaponSkinId ~= InDefaultWeaponSkinId then
--             -- 当前的皮 是 特殊皮
--             if InCurWeaponSkinId ~= InReplacedWeaponSkinId then
--                 -- 当前皮 和 玩家的皮 不一致
--                 ReturnVal = true
--             end
--         end
--     end

--     return ReturnVal
-- end

-- move to C++
function ItemSlotWeapon:SetWeaponOverrideWidgetVisibility(InVisibilityState)
    if self.WBP_ChangeBtn then
        if InVisibilityState then
            self.WBP_ChangeBtn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.WBP_ChangeBtn:SetVisibility(UE.ESlateVisibility.Hidden)
        end
    end
end
-- move to C++
function ItemSlotWeapon:SetWeaponSkinNameWidgetVisibility(InVisibilityState)
    if self.Overlay_WeaponSkinName then
        if InVisibilityState then
            self.Panel_SkinName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.Panel_SkinName:SetVisibility(UE.ESlateVisibility.Hidden)
        end
    end
end
--move to C++
function ItemSlotWeapon:SetWeaponSkinNameBySkinId(InWeaponSkinId)
    if not InWeaponSkinId then
        return nil
    end

    if InWeaponSkinId == 0 then
        return nil
    end

    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, InWeaponSkinId)
    if not WeaponSkinCfg then
        return nil
    end

    if self.Text_SkinName then
        local TempTranslatedWeaponSkinName = StringUtil.Format(WeaponSkinCfg.SkinName)
        self.Text_SkinName:SetText(TempTranslatedWeaponSkinName)
    end
end

function ItemSlotWeapon:SetWeaponSkinBgColorBySkinId(InWeaponSkinId)
    local TheQualityCfg = MvcEntry:GetModel(DepotModel):GetQualityCfgByItemId(InWeaponSkinId)
    local Color = TheQualityCfg[Cfg_ItemQualityColorCfg_P.HexColor]
    CommonUtil.SetBrushTintColorFromHex(self.Image_SkinColor,Color)
end


function ItemSlotWeapon:OnClickedReplaceSkin()
    if self.GAWeaponInstance then
        self.GAWeaponInstance:TryOverrideWeaponSkinOnClient()
    end
end


function ItemSlotWeapon:OnWBP_ChangeBtnHovered()
    self:WeaponArea_OnMouseEnter()
end

function ItemSlotWeapon:OnWBP_ChangeBtnUnHovered()
    self:WeaponArea_OnMouseLeave()
end

function ItemSlotWeapon:UpdateEnhanceWeaponInfo(InInventoryInstance)
    if InInventoryInstance and self.WBP_EnhanceAttribute_ForWeapon then
        if InInventoryInstance:HasItemAttribute("EnhanceAttributeId") then
            -- 设置强化词条图标 非空（显示）
            self:SetWPEnhanceEmptyState(false)

            -- 记录强化词条Id，更新武器 InventoryIdentity
            local CurrentWeaponInventoryIdentity = InInventoryInstance:GetInventoryIdentity()
            local TempEnhanceId = InInventoryInstance:GetItemAttributeFString("EnhanceAttributeId")
            self.WBP_EnhanceAttribute_ForWeapon:UpdateEnhanceWeaponInnerInfo(CurrentWeaponInventoryIdentity, TempEnhanceId)
        else
            -- 设置强化词条图标 空（不显示）
            self:SetWPEnhanceEmptyState(true)
        end
    end
end


function ItemSlotWeapon:SetWPEnhanceEmptyState(InState)
    if self.WBP_EnhanceAttribute_ForWeapon then
        if InState ~= nil then
            self.WBP_EnhanceAttribute_ForWeapon:SetEnhanceEmptyState(InState)
        end
    end
end

function ItemSlotWeapon:SetWPEnhanceVisibility(InState)
    if self.WBP_EnhanceAttribute_ForWeapon then
        if InState then
            self.WBP_EnhanceAttribute_ForWeapon:SetVisibility(UE.ESlateVisibility.Visible)
        else
            self.WBP_EnhanceAttribute_ForWeapon:SetVisibility(UE.ESlateVisibility.Collapsed) 
        end
    end
end

--move to C++
-- 绑定销毁武器强化词条消息
-- function ItemSlotWeapon:BindDestroyWeaponEnhanceMessage()
--     if not self.GMPHandle_InventoryItemDestroyWeaponEnhance then
--         -- 因为只有主端有，所以可以监听全局
--         self.GMPHandle_InventoryItemDestroyWeaponEnhance = ListenObjectMessage(nil, GameDefine.Msg.InventoryItemWeaponDestroyEnhance, self, self.OnDestroyWeaponEnhanceCallback)
--     end
-- end
--move to C++
-- 解除绑定销毁武器强化词条消息
-- function ItemSlotWeapon:UnBindDestroyWeaponEnhanceMessage()
--     if self.GMPHandle_InventoryItemDestroyWeaponEnhance then
--         UnListenObjectMessage(GameDefine.MsgCpp.InventoryItemWeaponDestroyEnhance, self, self.GMPHandle_InventoryItemDestroyWeaponEnhance)
--         self.GMPHandle_InventoryItemDestroyWeaponEnhance = nil
--     end
-- end
function ItemSlotWeapon:OnFocusReceived(MyGeometry,InFocusEvent)
    self.HandleSelect = true
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function ItemSlotWeapon:OnFocusLost(InFocusEvent)
    self.HandleSelect = false
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function ItemSlotWeapon:OnSelectArea()

    if not self.HandleSelect then
        return
    end

    local FocusWiget = self.FirstEquipedAttachment
    if FocusWiget then
        FocusWiget:SetFocus()
    end
end

function ItemSlotWeapon:OnKeyDown(MyGeometry,InKeyEvent)  
	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)

    if PressKey == self.Gamepad_Select_One or PressKey == self.Gamepad_Select_Two then      
        print("ItemSlotWeapon >> OnKeyDown")
        self:OnSelectArea()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end


function ItemSlotWeapon:WeaponAttachmentEquipGuide(AttachmentTag, ShowGuideSoltNum, bOtherAttachmentSlotAttach)
    local bStartGuide = false
    if AttachmentTag ~= nil then
        local AttachmentWidget = self.SupportAttachments[AttachmentTag]
        if AttachmentWidget then
            bStartGuide = true
        end
    else
        self:ShowSopportedAttachmentStyle()
    end

    if not bStartGuide then return end
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PlayerController then return end
    local TempPawn = PlayerController:GetPawn()
    if not TempPawn then return end
    local TempEquipmentComp = UE.UEquipmentStatics.GetEquipmentComponent(TempPawn)
    if not TempEquipmentComp then return end
    local GAWInstance = TempEquipmentComp:GetEquippedInstance()
    if not GAWInstance then return end
    if not GAWInstance.GetInventoryIdentity then return end
    local bIsHoldingWeapon = GAWInstance:GetInventoryIdentity().ItemID == self.ItemID and GAWInstance:GetInventoryIdentity().ItemInstanceID == self.ItemInstanceID
    if not AttachmentTag then return end
    local AttachmentWidget = self.SupportAttachments[AttachmentTag]
    if not AttachmentWidget then return end
    local bShowGuideHighLight = AttachmentWidget.ItemID == -1 and (bIsHoldingWeapon or ShowGuideSoltNum == 1) 
    if bShowGuideHighLight == false then bShowGuideHighLight = bOtherAttachmentSlotAttach end
    AttachmentWidget:StartGuideHightLight(bShowGuideHighLight)
end


function ItemSlotWeapon:EndWeaponAttachmentEquipGuide(AttachmentTag)
    self:HideSopportedAttachmentStyle()
    --if ShowGuideSlotNum == 0 then return end
    if AttachmentTag ~= nil then
        local AttachmentWidget = self.SupportAttachments[AttachmentTag]
        if AttachmentWidget then
            AttachmentWidget:EndGuideHightLight()
        end
        ShowGuideSlotNum = 0
    end
end

function ItemSlotWeapon:ShowSopportedAttachmentStyle()
    self.UnsupportedWeapon:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
end

function ItemSlotWeapon:HideSopportedAttachmentStyle()
    self.UnsupportedWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return ItemSlotWeapon
