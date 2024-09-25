require "UnLua"
require ("Common.Utils.StringUtil")

local HUDWeaponSwitcherBase = Class("Common.Framework.UserWidget")


function HUDWeaponSwitcherBase:OnInit()
    print("HUDWeaponSwitcherBase", ">> OnInit, ", GetObjectName(self))
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

	self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,              Func = self.OnLocalPCUpdatePawn,            bCppMsg = true,	    WatchedObject = self.LocalPC },
		{ MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Weapon,    Func = self.OnInventoryItemSlotsChangeWeapon,              bCppMsg = true },
		{ MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Reset,    Func = self.OnInventoryItemSlotsReset,              bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.INVENTORY_EQUIPPABLE_ONREP_WEAPON,              Func = self.OnInventoryEquippableOnRepWeapon,        bCppMsg = true },
        { MsgName = GameDefine.Msg.WEAPON_UpdateWeaponPanelBGPic,       Func = self.OnUpdateWeaponPanelBGPic,       bCppMsg = false },
        { MsgName = GameDefine.Msg.WEAPON_FireModeChange_Clinet,        Func = self.OnFireModeChange,               bCppMsg = true }
	}
    
    self.WeaponInfoCacheTable={
        [1]={
            ID = nil
        },
        [2]={
            ID = nil
        }
    }

    self:InitSubWidgetData()

    UserWidget.OnInit(self)

    self.BPWeaponDetail = {
        [0] = self.BP_WeaponDetail0,
        [1] = self.BP_WeaponDetail1,
    }
    for i = 0, #self.BPWeaponDetail do
        self.BPWeaponDetail[i].HUDWeaponSwitcherBase = self
    end
    --当前显示的芯片Id
    self.CurrentShowingChipId = nil
    

end

function HUDWeaponSwitcherBase:OnDestroy()
    print("HUDWeaponSwitcherBase", ">> OnDestroy, ", GetObjectName(self))

	UserWidget.OnDestroy(self)
end


function HUDWeaponSwitcherBase:InitSubWidgetData() --Virtual Funciton
end


--当前角色持枪状态，如果当前是空手状态那么 bHasWeapon = false
function HUDWeaponSwitcherBase:HasWeaponState(bHasWeapon) --Virtual Funciton
end


function HUDWeaponSwitcherBase:SendMicrochipTips(bHasWeapon) --Virtual Funciton
end


function HUDWeaponSwitcherBase:SwitchFirstWeapon(bSwicth)
end


function HUDWeaponSwitcherBase:InitPlayerPawnInfo()

end

function HUDWeaponSwitcherBase:ControlEmptyImageBgVisibility(bShow)

end


function HUDWeaponSwitcherBase:ResetWeaponInfoSingle(InBagComponentOwner, InInventoryItemSlot)
    local WeaponInfoCache = self.WeaponInfoCacheTable[InInventoryItemSlot.SlotID]
    WeaponInfoCache.ID = -1
    
    local WeaponWidgetInfo = self.WeaponWidgetInfos[InInventoryItemSlot.SlotID]
    if WeaponWidgetInfo and WeaponWidgetInfo.WeaponDetail then
        WeaponWidgetInfo.WeaponDetail:ResetWidget()
    end

    if WeaponWidgetInfo and WeaponWidgetInfo.ImgTabOn then
        WeaponWidgetInfo.ImgTabOn:SetVisibility(UE.ESlateVisibility.Collapsed)
        WeaponWidgetInfo.ImgTabBg:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    if WeaponWidgetInfo and WeaponWidgetInfo.TxtTabName then
        WeaponWidgetInfo.TxtTabName:SetColorAndOpacity(BattleUIHelper.GetMiscSystemValue(self, "WeaponTextColor", "TabNameNotActive"))
        WeaponWidgetInfo.TxtTabName:SetRenderOpacity(self.EnableTexTabOpacity)
        WeaponWidgetInfo.TxtTabName:SetText('')
    end

    if WeaponWidgetInfo and WeaponWidgetInfo.ImgTabNumBg then
        WeaponWidgetInfo.ImgTabNumBg:SetColorAndOpacity(BattleUIHelper.GetMiscSystemValue(self, "WeaponImageColor", "TabNotActiveColor"))
        if BridgeHelper.IsPCPlatform() then WeaponWidgetInfo.ImgTabNumBg:SetVisibility(UE.ESlateVisibility.Collapsed) end
    end

    self:UpdateEmptyWeaponImgBgState()
end


function HUDWeaponSwitcherBase:UpdateWeaponInfoSingle(InBagComponentOwner, InInventoryItemSlot)
    local testProfile = require("Common.Utils.InsightProfile")
    testProfile.Begin("HUDWeaponSwitcherBase:UpdateWeaponInfoSingle")
    print("HUDWeaponSwitcherBase >> UpdateWeaponInfoSingle")
    if not InBagComponentOwner then return end

    local TempBagComp = UE.UBagComponent.Get(InBagComponentOwner)
    if not TempBagComp then return end

    local CurActiveIndex = 0

    local WeaponWidgetInfo = self.WeaponWidgetInfos[InInventoryItemSlot.SlotID]
    if WeaponWidgetInfo then
        if InInventoryItemSlot.bActive then
            CurActiveIndex = InInventoryItemSlot.SlotID
        end

        WeaponWidgetInfo.WeaponDetail:UpdateInnerWeaponInfo(InInventoryItemSlot)

        local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(InBagComponentOwner, InInventoryItemSlot.InventoryIdentity.ItemID)
        if not IngameDT then
            return
        end

        local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(InInventoryItemSlot.InventoryIdentity.ItemID))
        if not StructInfo_Item then
            return
        end

        -- if itemid equal?
        
        local WeaponInfoCache = self.WeaponInfoCacheTable[InInventoryItemSlot.SlotID]
        if WeaponInfoCache.ID ~= InInventoryItemSlot.InventoryIdentity.ItemID then
            if WeaponWidgetInfo.TxtTabName then
                print("HUDWeaponSwitcherBase:UpdateWeaponInfoSingle >> TxtTabName1=",StructInfo_Item.ItemName)
                local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
                WeaponWidgetInfo.TxtTabName:SetText(TranslatedItemName)
                print("HUDWeaponSwitcherBase:UpdateWeaponInfoSingle >> TxtTabName=",TranslatedItemName)
            end

            WeaponInfoCache.ID = InInventoryItemSlot.InventoryIdentity.ItemID
        end

        if InInventoryItemSlot.bActive then
            if WeaponWidgetInfo.ImgTabOn then
                WeaponWidgetInfo.ImgTabOn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                WeaponWidgetInfo.ImgTabBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end

            if WeaponWidgetInfo.TxtTabName then
                WeaponWidgetInfo.TxtTabName:SetColorAndOpacity(self.EnableTxtTabColor)
                WeaponWidgetInfo.TxtTabName:SetRenderOpacity(self.EnableTexTabOpacity)
            end

            if WeaponWidgetInfo.ImgTabNumBg then
                WeaponWidgetInfo.ImgTabNumBg:SetColorAndOpacity(BattleUIHelper.GetMiscSystemValue(self, "WeaponImageColor", "TabActiveColor"))
                if BridgeHelper.IsPCPlatform() then WeaponWidgetInfo.ImgTabNumBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
            end
        else
            if WeaponWidgetInfo.ImgTabOn then
                WeaponWidgetInfo.ImgTabOn:SetVisibility(UE.ESlateVisibility.Collapsed)
                WeaponWidgetInfo.ImgTabBg:SetVisibility(UE.ESlateVisibility.Collapsed)
            end

            if WeaponWidgetInfo.TxtTabName then
                WeaponWidgetInfo.TxtTabName:SetColorAndOpacity(self.DisableTxtTabColor)
                WeaponWidgetInfo.TxtTabName:SetRenderOpacity(self.DisableTexTabOpacity)
            end

            if WeaponWidgetInfo.ImgTabNumBg then
                WeaponWidgetInfo.ImgTabNumBg:SetColorAndOpacity(BattleUIHelper.GetMiscSystemValue(self, "WeaponImageColor", "TabNotActiveColor"))
                if BridgeHelper.IsPCPlatform() then WeaponWidgetInfo.ImgTabNumBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
            end
        end

        WeaponWidgetInfo.WeaponDetail:SetActiveState(InInventoryItemSlot.bActive)
    end

    if self.TrsSwitcher then
        if CurActiveIndex ~= 0 then
            self.TrsSwitcher:SetActiveWidgetIndex(CurActiveIndex - 1)
        end
    end

    local ItemSlots = TempBagComp:GetItemSlots()
    local ActiveWeaponIndex = 0
    for i = 1, ItemSlots:Num() do
        local TmpSlot = ItemSlots:Get(i)
        if TmpSlot.ItemType == "Weapon" then
            local WeaponSlotData = TmpSlot
            if WeaponSlotData.bActive then
                ActiveWeaponIndex = WeaponSlotData.SlotID
            end

        end
    end

    self:HandleWeaponState(ActiveWeaponIndex)
    --self:PlayChipAnim(InInventoryItemSlot,CurActiveIndex)

end


function HUDWeaponSwitcherBase:HandleWeaponState(InCurrentActiveIndex)
    print("HUDWeaponSwitcherPC >> HandleWeaponState > InCurrentActiveIndex=",InCurrentActiveIndex)
    local ValidWeaponNum = 0
    for i = 1, #self.WeaponWidgetInfos do
        local WeaponWidgetInfo = self.WeaponWidgetInfos[i]
        if WeaponWidgetInfo then
            local IsValid = WeaponWidgetInfo.WeaponDetail:IsExistValidWeaponInSlot()
            if IsValid then
                ValidWeaponNum = ValidWeaponNum + 1
            end
        end
    end

    local bHandWeapon = (InCurrentActiveIndex ~= 0)
    local bHaveWeapon = (ValidWeaponNum > 0)
    self:UpdateWeaponHUDState(bHaveWeapon,bHandWeapon)
    -- self:UpdateWeaponHUDState(true,bHandWeapon)
    -- if  then
    --     -- self:ControlEmptyImageBgVisibility(false)

    -- else

    -- end
end


--bHaveWeapon 该玩家是否至少有一把枪
--bHandWeapon 该玩家是否处于持枪状态
function HUDWeaponSwitcherBase:UpdateWeaponHUDState(bHaveWeapon,bHandWeapon)

end


function HUDWeaponSwitcherBase:UpdateEmptyWeaponImgBgState()
    local ValidWeaponNum = 0
    for i = 1, #self.WeaponWidgetInfos do
        local WeaponWidgetInfo = self.WeaponWidgetInfos[i]
        if WeaponWidgetInfo then
            local IsValid = WeaponWidgetInfo.WeaponDetail:IsExistValidWeaponInSlot()
            if IsValid then
                ValidWeaponNum = ValidWeaponNum + 1
            end
        end
    end

    if ValidWeaponNum > 0 then
        self:ControlEmptyImageBgVisibility(false)
    else
        self:ControlEmptyImageBgVisibility(true)
    end
end


function HUDWeaponSwitcherBase:OnInventoryEquippableOnRepWeapon(InInventoryInstance, InEquippableInstance)
    if InInventoryInstance then
        
        if not InInventoryInstance.GetInventoryIdentity then
            print("HUDWeaponSwitcherBase:OnInventoryEquippableOnRepWeapon [InEquippedInstance.GetInventoryIdentity]=",InInventoryInstance.GetInventoryIdentity,",[getClassName]=",getClassName(InInventoryInstance),",[ObjectName]=",GetObjectName(InInventoryInstance))
            return
        end

        local CurrentInventoryIdentity = InInventoryInstance:GetInventoryIdentity()

        local TempBagComp = UE.UBagComponent.Get(self.LocalPC)
        if not TempBagComp then
            return nil
        end

        local WeaponSlot,bIsFind = TempBagComp:GetItemSlot(CurrentInventoryIdentity)
        if bIsFind then
            if self.InvalidationBox then
                self.InvalidationBox:SetCanCache(false)
            end
            self:UpdateWeaponInfoSingle(self.LocalPC, WeaponSlot)
            if self.InvalidationBox then
                self.InvalidationBox:SetCanCache(true)
            end
        end
    end

end


-------------------------------------------- Callable ------------------------------------

function HUDWeaponSwitcherBase:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
	--print("HUDWeaponSwitcherBase", ">> OnLocalPCUpdatePawn, ", GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InPCPwn))
    if InLocalPC == self.LocalPC then
		self:InitPlayerPawnInfo()
	end
end

function HUDWeaponSwitcherBase:OnInventoryItemSlotsChangeWeapon(InBagComponentOwner, InInventoryItemSlot)
    if self.InvalidationBox then
        self.InvalidationBox:SetCanCache(false)
    end
    local testProfile = require("Common.Utils.InsightProfile")
    testProfile.Begin("HUDWeaponSwitcherBase:OnInventoryItemSlotsChangeWeapon")
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if InBagComponentOwner == TempLocalPC then
        --self:UpdateWeaponInfo(TempLocalPC)
        --这里需要在更新武器信息之前，记录一下目前显示的武器的芯片id

        self:UpdateWeaponInfoSingle(TempLocalPC, InInventoryItemSlot)
    end
    if self.InvalidationBox then
        self.InvalidationBox:SetCanCache(true)
    end
    testProfile.End("HUDWeaponSwitcherBase:OnInventoryItemSlotsChangeWeapon")
end

function HUDWeaponSwitcherBase:OnInventoryItemSlotsReset(InBagComponentOwner, InInventoryItemSlot)
    if self.InvalidationBox then
        self.InvalidationBox:SetCanCache(false)
    end
    if InInventoryItemSlot.ItemType == ItemSystemHelper.NItemType.Weapon then
        self:ResetWeaponInfoSingle(InBagComponentOwner, InInventoryItemSlot)
    end
    if self.InvalidationBox then
        self.InvalidationBox:SetCanCache(true)
    end
end

function HUDWeaponSwitcherBase:OnUpdateWeaponPanelBGPic(InMsgBody)
    if self.InvalidationBox then
        self.InvalidationBox:SetCanCache(false)
    end
    -- print("HUDWeaponSwitcherBase::OnUpdateWeaponPanelBGPic--> Start CurBulletNum:",
    --     InMsgBody.CurBulletNum, "MaxBulletNum:", InMsgBody.MaxBulletNum, "MinAmmoWarningNum:", InMsgBody.MinAmmoWarningNum)
    if (InMsgBody.CurBulletNum + InMsgBody.MaxBulletNum) < InMsgBody.MinAmmoWarningNum then       
        --print("HUDWeaponSwitcherBase::OnUpdateWeaponPanelBGPic--> Start     SetActiveWidgetIndex(1)")
        self.ImgBg_Red:SetVisibility(UE.ESlateVisibility.Visible)
    else
        --print("HUDWeaponSwitcherBase::OnUpdateWeaponPanelBGPic--> Start     SetActiveWidgetIndex(0)")
        self.ImgBg_Red:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.InvalidationBox then
        self.InvalidationBox:SetCanCache(true)
    end
end


function HUDWeaponSwitcherBase:OnFireModeChange(InGAWeaponInstance)
    if not InGAWeaponInstance then
        return
    end
    if self.InvalidationBox then
        self.InvalidationBox:SetCanCache(false)
    end
    for i = 1, self.WeaponWidgetNum do
        local WeaponWidgetInfo = self.WeaponWidgetInfos[i]
        if WeaponWidgetInfo.WeaponDetail then
            local CurrentInventoryIdentity = WeaponWidgetInfo.WeaponDetail:GetCurrentInventoryIdentity()
            if CurrentInventoryIdentity then
                local CurrentWeaponInstanceInventoryIdentity = InGAWeaponInstance:GetInventoryIdentity()
                if (CurrentWeaponInstanceInventoryIdentity.ItemID == CurrentInventoryIdentity.ItemID) and (CurrentWeaponInstanceInventoryIdentity.ItemInstanceID == CurrentInventoryIdentity.ItemInstanceID) then
                    local TempFireModeTag, TempFireModeTags, bResult = WeaponWidgetInfo.WeaponDetail:GetFireModeInfo(InGAWeaponInstance)
                    if bResult then
                        WeaponWidgetInfo.WeaponDetail:UpdateFireMode(TempFireModeTag, TempFireModeTags)
                        break
                    end
                end
            end
        end
    end
    if self.InvalidationBox then
        self.InvalidationBox:SetCanCache(true)
    end
end


return HUDWeaponSwitcherBase
