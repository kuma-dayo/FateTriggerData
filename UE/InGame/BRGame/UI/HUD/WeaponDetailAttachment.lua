local WeaponDetailAttachment = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function WeaponDetailAttachment:OnInit()
    self.ItemID = 0
    -- self:UpdateLvColor(nil)
    --self.InitPartColor = self.ImgPart.ColorAndOpacity
    --self.InitImgBgColor = self.ImgBg.ColorAndOpacity
    --print("WeaponDetailAttachment >> OnInit")

    self.bIsMobilePlatform = BridgeHelper.IsMobilePlatform()
    local index = self.bIsMobilePlatform and 1 or 0
    self.WS_Platform:SetActiveWidgetIndex(index)
    self.SelfImgBg = self.bIsMobilePlatform and self.ImgBg_Mobile or self.ImgBg
    self.SelfImgPart = self.bIsMobilePlatform and self.ImgPart_Mobile or self.ImgPart


    UserWidget.OnInit(self)
end

function WeaponDetailAttachment:OnDestroy()
    self.ItemID = nil
    UserWidget.OnDestroy(self)
end

-------------------------------------------- Function ------------------------------------

function WeaponDetailAttachment:UpdateAttachmentInfo(ItemID)
    local testProfile = require("Common.Utils.InsightProfile")
    testProfile.Begin("WeaponDetailAttachment:UpdateAttachmentInfo")
    if ItemID then
        self.ItemID = ItemID
        self:UpdateLvColor(ItemID)
        return
    end
    self:UpdateLvColor(nil)
    testProfile.End("WeaponDetailAttachment:UpdateAttachmentInfo")
   -- print("WeaponDetailAttachment >> UpdateAttachmentInfo")
end

function WeaponDetailAttachment:SetIcon(Tex2D)
    self.ImgPart:SetBrushFromSoftTexture(Tex2D,false)
end


function WeaponDetailAttachment:ResetAttachmentUI()
    self.ItemID = 0
    self.ItemInstanceID = 0
    self:UpdateLvColor(nil)
end

function WeaponDetailAttachment:UpdateLvColor(InItemID)
    if self.bIsMobilePlatform then
        self:UpdateLvColor_Mobile(InItemID)
    else
        self:UpdateLvColor_PC(InItemID)
    end
end

function WeaponDetailAttachment:UpdateLvColor_PC(InItemID)
    if InItemID then
        local ItemLevel, bValidItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, InItemID, "ItemLevel",
            GameDefine.NItemSubTable.Ingame, "InteractiveWeaponDetail:UpdateWeaponAttachment")

        local LvBgColor                  = BattleUIHelper.GetMiscSystemValue(self, "WeaponAttchIconColor", ItemLevel)
        --print("WangZepingLog LvBgColor:", LvBgColor)
        if LvBgColor then
            self.SelfImgPart:SetColorAndOpacity(self.AttColor)
            self.SelfImgBg:SetBrushFromTexture(self.AttachBg)
            self.SelfImgBg:SetColorAndOpacity(LvBgColor)
        end
    end

    if not InItemID then
        self.SelfImgPart:SetColorAndOpacity(self.NotEquipColor)
        self.SelfImgBg:SetColorAndOpacity(self.ImgBgResetColor)
        self.SelfImgBg:SetBrushFromTexture(self.BgImg_PC)
    end
end

function WeaponDetailAttachment:UpdateLvColor_Mobile(InItemID)
    if InItemID then
        local ItemLevel, bValidItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, InItemID, "ItemLevel",
            GameDefine.NItemSubTable.Ingame, "InteractiveWeaponDetail:UpdateWeaponAttachment")

        local TheBackgroundSrc = self.Moblie_AttachLvBgTexturesMap:Find(ItemLevel)
        if TheBackgroundSrc then
            self.SelfImgBg:SetBrushFromTexture(TheBackgroundSrc)
        end
    end

    if not InItemID then
        self.SelfImgPart:SetColorAndOpacity(self.NotEquipColor)
        self.SelfImgBg:SetColorAndOpacity(self.ImgBgResetColor)
        self.SelfImgBg:SetBrushFromTexture(self.BgImg_Mobile)
    end
end

return WeaponDetailAttachment
