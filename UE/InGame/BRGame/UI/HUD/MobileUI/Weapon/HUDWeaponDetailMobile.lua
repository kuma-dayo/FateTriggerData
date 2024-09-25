--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local ParentClassName = "InGame.BRGame.UI.HUD.Weapon.HUDWeaponDetailBase"

local HUDWeaponDetailBase = require(ParentClassName)
local HUDWeaponDetailMobile = Class(ParentClassName)


-------------------------------------------- Init/Destroy ------------------------------------

function HUDWeaponDetailMobile:OnInit()
    print("HUDWeaponDetailMobile >> OnInit")
    HUDWeaponDetailBase.OnInit(self)

    self.HasMasked = true
    self.HasWeapon = false
    self.AttachWidgets = {
        ["Weapon.AttachSlot.Barrel"] = self.PartBarrel,      --5
        ["Weapon.AttachSlot.Optics"] = self.PartOptics ,       -- 1
        ["Weapon.AttachSlot.FrontGrip"] = self.PartFrontGrip , --2
        ["Weapon.AttachSlot.Mag"] = self.PartMag,             --3
        ["Weapon.AttachSlot.Stocks"] =self.PartStocks ,       --4
        ["Weapon.AttachSlot.HopUp"] = self.PartHopUp,         --6
    }

    self.AttachNotifyWidgets = {
        ["Weapon.AttachSlot.Barrel"] = self.BP_PartBarrelNotify,      
        ["Weapon.AttachSlot.Optics"] = self.BP_PartOpticsNotify ,       
        ["Weapon.AttachSlot.FrontGrip"] = self.BP_FrontGripNotify, 
        ["Weapon.AttachSlot.Mag"] = self.BP_PartMagNotify,             
        ["Weapon.AttachSlot.Stocks"] =self.BP_PartStocksNotify ,       
        ["Weapon.AttachSlot.HopUp"] = self.BP_PartHopUpNotify,        
    }


    self.GUIButton_ChangeState.OnClicked:Add(self, self.GUIButton_ChangeStateClick)
    self.MsgList = {}

    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC then
        table.insert(self.MsgList, { MsgName ="UIEvent.Pick.BulletNotify", Func = self.OnPickBullectNotify, bCppMsg = false })
        table.insert(self.MsgList, { MsgName ="UIEvent.Pick.AttachmentNotify", Func = self.OnPickAttachmentNotify, bCppMsg = false })
    end

    UserWidget.OnInit(self)
end


function HUDWeaponDetailMobile:GUIButton_ChangeStateClick()

end

-------------------------------------------- Function ------------------------------------

function HUDWeaponDetailMobile:OnPickBullectNotify(Params)
    print("[Wzp] HUDWeaponDetailMobile >> OnPickBullectNotify")
    local SendWeaponSlotIndex = Params.SendWeaponSlotIndex
    local ItemID = Params.PickObj.ItemInfo.ItemID

    if SendWeaponSlotIndex == self.WeaponSlotData.SlotID then
        self:BP_Event_BulletNotify()
        local ItemID = Params.PickObj.ItemInfo.ItemID
        if ItemID then
            local ItemIcon, bValidItemIcon = UE.UItemSystemManager.GetItemDataFString(
                self, ItemID, "ItemIcon", GameDefine.NItemSubTable.Ingame,
                "HUDWeaponDetailMobile:OnPickBullectNotify")
            if bValidItemIcon then
                local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(ItemIcon)
                self.BP_BulletNotify:SetIcon(ImageSoftObjectPtr)
            end
        end
        
    end

end

function HUDWeaponDetailMobile:OnPickAttachmentNotify(Params)
    local SendWeaponSlotIndex = Params.SendWeaponSlotIndex
    local ItemID = Params.PickObj.ItemInfo.ItemID
    print("[Wzp]HUDWeaponDetailMobile >> OnPickAttachmentNotify")
    if SendWeaponSlotIndex ~= self.WeaponSlotData.SlotID then
        return
    end

    if ItemID then
        local SlotImage, RetSlotImage = UE.UItemSystemManager.GetItemDataFString(self, ItemID, "SlotImage", GameDefine.NItemSubTable.Ingame, "HUDWeaponDetailMobile:OnPickBullectNotify")
        local CurrentItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, ItemID, "ItemLevel",GameDefine.NItemSubTable.Ingame, "HUDWeaponDetailMobile:OnPickBullectNotify")
        local LvBgColor = BattleUIHelper.GetMiscSystemValue(self, "WeaponAttchIconColor", CurrentItemLevel)


        local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, ItemID)
        if not IngameDT then
            return ""
        end
    
        local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(ItemID))
        if not StructInfo_Item then
            return
        end
        print("[Wzp]HUDWeaponDetailMobile >> OnPickAttachmentNotify StructInfo_Item")
       local SlotNameTag =  StructInfo_Item.SlotName
       local SlotNameStr = SlotNameTag.TagName

       local AttachNotifyWidget = self.AttachNotifyWidgets[SlotNameStr]
        if IsFindItemLevel and LvBgColor then
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(SlotImage)
            AttachNotifyWidget:SetAttachmentIcon(ImageSoftObjectPtr,LvBgColor)
            AttachNotifyWidget:BP_Event_AttachmentNotify()
            print("[Wzp]HUDWeaponDetailMobile >> OnPickAttachmentNotify AttachNotifyWidget")
        end
    end


end



function HUDWeaponDetailMobile:InitData(InMainWidget, InSlotIndex, WeaponInfo)
    HUDWeaponDetailBase.InitData(InMainWidget, InSlotIndex, WeaponInfo)
    print("[Wzp]HUDWeaponDetailMobile >> InitData")
end

function HUDWeaponDetailMobile:UpdateInnerWeaponInfo(InWeaponSlotData)                   -- override
    print("HUDWeaponDetailMobile", ">> UpdateWeaponInfo, ", GetObjectName(self), InWeaponSlotData.SlotID)
    HUDWeaponDetailBase.UpdateInnerWeaponInfo(self, InWeaponSlotData)
    
    if InWeaponSlotData.bActive then
        --self.GUIImage_Bg:SetVisibility(UE.ESlateVisibility.Collapsed)
        --self.GUIImage_Bg_Light:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TrsWeapon:SetRenderOpacity(1)
    else
        --self.GUIImage_Bg_Light:SetVisibility(UE.ESlateVisibility.Collapsed)
        --self.GUIImage_Bg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TrsWeapon:SetRenderOpacity(0.6)
    end
    self.TrsWeapon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    if self.CurrentWeaponBulletItemID then
        self:UpdateBackGroundImage(self.CurrentWeaponBulletItemID)
    end

    self.HasWeapon = true
end

function HUDWeaponDetailMobile:ResetWidget() -- override
    self.WeaponSlotData.InventoryIdentity.ItemID = 0
    self.WeaponSlotData.InventoryIdentity.ItemInstanceID = 0
    self.WeaponSlotData.ItemType = ""
    self.WeaponSlotData.bActive = false
    self:UnBindGMP()

    self:ResetAttachmentInfo()

    self.HasMasked = true
    self.HasWeapon = false
    --self.GUIImage_Bg_Light:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self.GUIImage_Bg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.TrsWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.TrsWeapon:SetRenderOpacity(0.6)
end

-- 
function HUDWeaponDetailMobile:OnWeaponStateEnter(InWeaponHandle, InParams)
    print("HUDWeaponDetailMobile", ">> OnWeaponStateEnter, ", InParams.StateName.TagName, self.ReloadFully.TagName)
    
    -- Weapon.Reload.Fully / 加载弹药扫光
    if(InParams.StateName.TagName == self.ReloadFully.TagName )then
        print("HUDWeaponDetailMobile", ">> WeaponStateEnter, ", self.ReloadFully.TagName)
        self:StartAnimation()
    end
end

function HUDWeaponDetailMobile:StartAnimation()
    print("HUDWeaponDetailMobile:StartAnimation",self.DurationTime,GetObjectName(self))
   
    if self.DurationTime then
        self.CanvasPanel_Anim:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation(self.Animation_RefreshBullet,0.0, 1,0, 1.0 / self.DurationTime)
        self.HoldTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.EndAnimation}, self.DurationTime, false, 0, 0)
    end
end

function HUDWeaponDetailMobile:EndAnimation()
    print("HUDWeaponDetailMobile:EndAnimation", GetObjectName(self))
    self.CanvasPanel_Anim:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.HoldTimer then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.HoldTimer)
		self.HoldTimer = nil
    end
end


function HUDWeaponDetailMobile:SetCurBulletNumTxt(InBulletNum)
    local TheCurBulletNum = InBulletNum or 0
    local NumStr = string.format("%02d", TheCurBulletNum)

    local BulletWarningNum, bValidBulletItemID = UE.UItemSystemManager.GetItemDataInt32(
        self, WeaponItemID, "AmmoRed", GameDefine.NItemSubTable.Ingame,
        "HUDWeaponDetailBase:UpdateWeaponBulletWarningNum")
        
    local TheWarningTextColor = self.WarningTextColor
    local TheWarningOutlineColor = self.WarningOutlineColor
    self.TxtCurBullet:SetText(NumStr)
    if  BulletWarningNum == nil then
        return
    end

    if TheCurBulletNum <= BulletWarningNum then
        --少于等于警戒值
        self:SetTextColorAndOutline(self.TxtCurBullet,TheWarningTextColor,TheWarningOutlineColor)
    else
        self:SetTextColorAndOutline(self.TxtCurBullet,self.InitTextColor,self.InitTextOutlineColor)
    end
end

function HUDWeaponDetailMobile:UpdateCurrentBulletTextAndColor(CurrentBulletCount)

    -- local TextColor = BulletTextColor
    -- local OutlineColor = OutlineTextColor

    local TheCurBulletNum = CurrentBulletCount or 0
    local FinalColor,TheWarningNum =  UIHelper.LinearColor.LightGrey, 0
    local TheWarningTextColor = self.WarningTextColor
    local TheWarningOutlineColor = self.WarningOutlineColor
    local NumStr = string.format("%03d", TheCurBulletNum)
    self.TxtMaxBullet:SetText(NumStr)

    if TheCurBulletNum <= TheWarningNum then
        --少于等于警戒值
        print("HUDWeaponDetailMobile >> UpdateCurrentBulletTextAndColor")
        self:SetTextColorAndOutline(self.TxtMaxBullet,TheWarningTextColor,TheWarningOutlineColor)
        self:SetTextColorAndOutline(self.TxtCurSymbol,TheWarningTextColor,TheWarningOutlineColor)
    else
        self:SetTextColorAndOutline(self.TxtMaxBullet,self.InitTextColor,self.InitTextOutlineColor)
        self:SetTextColorAndOutline(self.TxtCurSymbol,self.InitTextColor,self.InitTextOutlineColor)
    end
end

function HUDWeaponDetailMobile:SetTextColorAndOutline(TextBlock,Color,OutlineColor)
    local FontInfo = TextBlock.Font
    FontInfo.OutlineSettings.OutlineColor = OutlineColor
    TextBlock:SetFont(FontInfo)
    TextBlock:SetColorAndOpacity(Color)
end

function HUDWeaponDetailMobile:UpdateBackGroundImage(WeaponBulletItemID)
    print("HUDWeaponDetailMobile >> UpdateBackGroundImage > WeaponBulletItemID:", WeaponBulletItemID)
    if WeaponBulletItemID then
        local TheBackgroundColor = self.BackgroundColorMap:Find(WeaponBulletItemID)
        local TheBackgroundSrc = self.BackgroundSrcMap:Find(WeaponBulletItemID)
        print("HUDWeaponDetailMobile >> UpdateBackGroundImage > TheBackgroundSrc:", TheBackgroundColor)
        
        if TheBackgroundColor  then
            self.FireModeImg:SetColorAndOpacity(TheBackgroundColor)
        end

        if TheBackgroundSrc then
            self.ImgBulletBg:SetBrushFromSoftTexture(TheBackgroundSrc,false)
        end

    end
end

function HUDWeaponDetailMobile:MicrochipNotify(TheItemID)  --Override Funciton
    --发送芯片装备GMP

    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin(" HUDWeaponDetailPC:MicrochipNotify")
    MsgHelper:Send(self, GameDefine.Msg.WEAPON_WearMicroChip, {ItemID=TheItemID})
    TmpProfile.End("HUDWeaponDetailPC:MicrochipNotify")
end

--更新配件信息
function HUDWeaponDetailMobile:UpdateAttachmentInfo(bIsAttachChange, bIsSwitchWeapon)

        local ThebIsAttachChange = bIsAttachChange or false --配件是否改变
        local ThebIsSwitchWeapon = bIsSwitchWeapon or false --武器是否切换

        local testProfile = require("Common.Utils.InsightProfile")
        testProfile.Begin("HUDWeaponDetailMobile:UpdateAttachmentInfo")
        -- 根据插槽信息，开启/关闭相关插槽显示
        local CurrentWeaponInventoryIdentity = self.WeaponSlotData.InventoryIdentity
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    
        local TempPawn = PlayerController:K2_GetPawn()
        local TempEquipmentComponent = UE.UEquipmentStatics.GetEquipmentComponent(TempPawn)
        if not TempEquipmentComponent then return end
        local GAWInstance = TempEquipmentComponent:GetEquipmentInstanceByInventoryIdentity(CurrentWeaponInventoryIdentity)
        if not GAWInstance then return end
    
        -- 获取这把武器拥有的配件插槽名称数组
        local WAttachmentSlotTagArray = UE.UGAWAttachmentFunctionLibrary.GetWeaponOwnedAttachSlotTags(GAWInstance)
        local AttachmentNum = WAttachmentSlotTagArray:Length()


        local WeaponTag =  self.GAWeaponInstance and self.GAWeaponInstance:GetMainWeaponTag() or nil
        for i = 1, AttachmentNum do
            local AttachmentTag = WAttachmentSlotTagArray:Get(i)
            local GAWAttachmentEffectArray = UE.UGAWAttachmentFunctionLibrary.GetAllAttachmentEffectHandleInSlot(GAWInstance,
                AttachmentTag)
                
            local NewWidget = self.AttachWidgets[AttachmentTag.TagName]


            if not NewWidget then
                print("HUDWeaponDetailMobile >> UpdateAttachmentInfo > self.AttachWidgets 没有这个key：",AttachmentTag.TagName)
            end


            if not NewWidget then
                goto continue
            end
            NewWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            local ParentPanel = NewWidget:GetParent()
            ParentPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

            NewWidget:SetWeaponAttachmentIcon(WeaponTag,AttachmentTag.TagName)

            local WAttachmentInSlot = GAWAttachmentEffectArray:Length()
            local TempGAWAttachmentEffect = nil
            if WAttachmentInSlot == 1 then
                TempGAWAttachmentEffect = GAWAttachmentEffectArray:Get(1)
                if TempGAWAttachmentEffect then
                    NewWidget:UpdateAttachmentInfo(TempGAWAttachmentEffect.ItemID)
                end
            end

            if AttachmentTag.TagName == "Weapon.AttachSlot.HopUp" and self.WeaponSlotData.bActive then
                local MicrochipID = TempGAWAttachmentEffect and tostring(TempGAWAttachmentEffect.ItemID) or nil
                if self.MicrochipID ~= MicrochipID and ThebIsAttachChange then
                    self.MicrochipID = MicrochipID
                    self:MicrochipNotify(MicrochipID)
                elseif ThebIsSwitchWeapon then
                    self:MicrochipNotify(MicrochipID)
                end
            end

            ::continue::
        end



        testProfile.End("HUDWeaponDetailMobile:UpdateAttachmentInfo")
end

function HUDWeaponDetailMobile:ResetAttachmentInfo()
    local testProfile = require("Common.Utils.InsightProfile")
    testProfile.Begin("HUDWeaponDetailMobile:ResetAttachmentInfo")
    local ChildNum = self.AttachSlots:GetChildrenCount()
    for i = 1, ChildNum do
        local AttachWidget = self.AttachSlots:GetChildAt(i-1)
        AttachWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    testProfile.End("HUDWeaponDetailMobile:ResetAttachmentInfo")
    
end


function HUDWeaponDetailMobile:UpdateFireMode(InFireModeTag, InFireModeTags)  -- override Function
    local IconType = self:ConvertFireModeTagToIconID(InFireModeTag)
    if not IconType then
        print("HUDWeaponDetailMobile >> UpdateFireMode > IconType is nil")
        return
    end
    
    print("HUDWeaponDetailMobile >> UpdateFireMode > IconType:",IconType)
    local FireModeKey = string.gsub(IconType, "Weapon.Attribute.FireMode.", "")   -- Weapon.Attribute.FireMode.Auto 返回 Auto
    local FireModeText = self.FireModeMap:Find(FireModeKey)
    self.TextFireType:SetText(FireModeText)
end


function HUDWeaponDetailMobile:SetActiveState(bIsActive)
    self:ClearInputActions()
    if bIsActive then
        self.GUICanvasPanelTile:SetVisibility(UE.ESlateVisibility.Visible)
        self:AddInputActionExtend(self.IA_SwitchEmpty)
    else
        self.GUICanvasPanelTile:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:AddInputActionExtend(self.IA_SwitchWeapon)
    end

end


function HUDWeaponDetailMobile:SendMicrochipTips() --Override Funciton
    MsgHelper:Send(self, GameDefine.Msg.WEAPON_WearMicroChip, {ItemID=nil})
end


return HUDWeaponDetailMobile