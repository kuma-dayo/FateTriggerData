local ItemSlotWeaponEnhanceMobile = Class("Common.Framework.UserWidget")

function ItemSlotWeaponEnhanceMobile:OnInit()
    print("NewBagMobile@ItemSlotWeaponEnhanceMobile Init")

    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    UserWidget.OnInit(self)
end

function ItemSlotWeaponEnhanceMobile:OnDestroy()
    UserWidget.OnDestroy(self)
end

function ItemSlotWeaponEnhanceMobile:OnClose()
    -- self:ResetHold()
    UserWidget.OnClose(self)
end

function ItemSlotWeaponEnhanceMobile:Tick(InMyGeometry, InDeltaTime)
    if self.IsHoldRightMouseButton and self.DestroyHoldTime then
        self.HoldingTime = self.HoldingTime + InDeltaTime
        if self.HoldingTime >= self.DestroyHoldTime then
            -- self:ResetHold()
            -- self:HoldToDestroyEnhanceAttribute()
        end
    end
end

--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  

function ItemSlotWeaponEnhanceMobile:InitUI()
    self:ResetWidget()
end

function ItemSlotWeaponEnhanceMobile:InitData()
    self.EnhanceID = ""
end

function ItemSlotWeaponEnhanceMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
       
    }
end

function ItemSlotWeaponEnhanceMobile:InitUIEvent()
end

--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|
function ItemSlotWeaponEnhanceMobile:ShowWidget(InEnhanceId)
    if not InEnhanceId then
        self:ResetWidget()
        return
    end
    if self.EnhanceID == "" and InEnhanceId == "" then
        self:ResetWidget()
        return
    end

    if self.EnhanceID ~= InEnhanceId then
        -- 更新强化词条图片
        self.EnhanceID = InEnhanceId
        local TempGameplayTag = UE.FGameplayTag()
        TempGameplayTag.TagName = GameDefine.NTag.TABLE_EnhanceAttribute
        -- 查找表资源
        local TempEnhanceAttributeDT = UE.UTableManagerSubsystem.GetDataTableByTag(self, TempGameplayTag)
        if TempEnhanceAttributeDT then
            -- 查找表的某行
            local StructInfoEnhanceAttr = UE.UDataTableFunctionLibrary.GetRowDataStructure(TempEnhanceAttributeDT, tostring(InEnhanceId))
            if StructInfoEnhanceAttr then
                -- 查找强化词条图片
                local EnhanceIconSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceIconSoft)
                self:RefreshEnhanceIcon(EnhanceIconSoftPtr)
            end
        end

        self:SetEnhanceVisible(true)
    end
end

function ItemSlotWeaponEnhanceMobile:ResetWidget()
    self:SetEnhanceVisible(false)
    self:SetSelectState(false)
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end


function ItemSlotWeaponEnhanceMobile:RefreshEnhanceIcon(InTexture)
    if self.Image_Icon then
        self.Image_Content:SetBrushFromSoftTexture(InTexture, false)
    end
end

--   _   _ ___    ____ ___  _   _ _____ ____   ___  _      
--  | | | |_ _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |     
--  | | | || |  | |  | | | |  \| | | | | |_) | | | | |     
--  | |_| || |  | |__| |_| | |\  | | | |  _ <| |_| | |___  
--   \___/|___|  \____\___/|_| \_| |_| |_| \_\\___/|_____|
function ItemSlotWeaponEnhanceMobile:SetEnhanceVisible(IsVisible)
    if not IsVisible then
        self.EnhanceID = ""
        self.Image_Bg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.Image_Content:SetVisibility(UE.ESlateVisibility.Collapsed);
		self.Image_Quality:SetVisibility(UE.ESlateVisibility.Collapsed);
        self.bIsFocusable = false
    else
        self.Image_Bg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Image_Content:SetVisibility(UE.ESlateVisibility.Visible);
		self.Image_Quality:SetColorAndOpacity(self.EnhanceNotEmpty);
        self.bIsFocusable = true
    end
end

function ItemSlotWeaponEnhanceMobile:SetSelectState(IsSelectState)
    self.Image_Select:SetVisibility(IsSelectState and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed);
end

--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  
function ItemSlotWeaponEnhanceMobile:OnMouseButtonDown(MyGeometry, MouseEvent)
    if (self.EhanceID == "") then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotWeaponEnhanceMobile:OnMouseButtonUp(MyGeometry, MouseEvent)
    if (self.ItemData == "") then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_ShowItemDetail, {
        EnhanceId = self.EhanceID
    })
    
    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotWeaponEnhanceMobile:OnFocusReceived(MyGeometry, InFocusEvent)
    print("BagM@ItemSlotWeaponEnhanceMobile:OnFocusReceived:",self.SlotIndex)
    self.HandleSelect = true
    self:SetSelectState(true)

    if self.HandleSelect then
        MsgHelper:Send(self, GameDefine.Msg.BagMobile_ShowItemDetail, {
            EnhanceId = self.EhanceID
        })
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotWeaponEnhanceMobile:OnFocusLost( InFocusEvent)
    print("BagM@ItemSlotWeaponEnhanceMobile:OnFocusLost:",self.SlotIndex)
    self.HandleSelect = false
    self:SetSelectState(false)

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 

return ItemSlotWeaponEnhanceMobile