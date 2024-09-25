local MobileReloadUI = Class("Common.Framework.UserWidget")

function MobileReloadUI:OnInit()
    print("MobileReloadUI",">> OnInit")
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,  Func = self.OnLocalPCUpdatePawn,    bCppMsg = true, WatchedObject = self.LocalPC },
    }
    if not self.LocalPC then
        return
    end
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    if not LocalPCPawn then
        return
    end
    MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
    self.MsgList_Pawn = {
        { MsgName = GameDefine.MsgCpp.Character_Gun_Reload_Tac_OnTagEvent,  Func = self.OnTacTagCountChange,    bCppMsg = true, WatchedObject = self.LocalPCPawn },
        { MsgName = GameDefine.MsgCpp.Character_Gun_Reload_Full_OnTagEvent,  Func = self.OnFullTagCountChange,    bCppMsg = true, WatchedObject = self.LocalPCPawn },
    }
    MsgHelper:RegisterList(self, self.MsgList_Pawn)
    print("MobileReloadUI", ">> OnInit, Listen succeed")
    UserWidget.OnInit(self)
end

function MobileReloadUI:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
    print("MobileReloadUI", ">> OnLocalPCUpdatePawn, ",
        GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InPCPwn))
    if self.LocalPC == InLocalPC then
        local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
        if not LocalPCPawn then
            return
        end
        MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
        self.MsgList_Pawn = {
            { MsgName = GameDefine.MsgCpp.Character_Gun_Reload_Tac_OnTagEvent,  Func = self.OnTacTagCountChange,    bCppMsg = true, WatchedObject = self.LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.Character_Gun_Reload_Full_OnTagEvent,  Func = self.OnFullTagCountChange,    bCppMsg = true, WatchedObject = self.LocalPCPawn },
        }
        MsgHelper:RegisterList(self, self.MsgList_Pawn)
        print("MobileReloadUI", ">> OnLocalPCUpdatePawn, Listen succeed")
    end
end

function MobileReloadUI:OnDestroy()
    if self.MsgList_Pawn then
		MsgHelper:UnregisterList(self, self.MsgList_Pawn)
		self.MsgList_Pawn = nil
	end
    UserWidget.OnDestroy(self)
end

function MobileReloadUI:OnTacTagCountChange(InASC,InTag,InTagCount)
    if not self:IsLocalContgroller(InASC) then
        return
    end
    print("MobileReloadUI", ">> OnTacTagCountChange, ", InTag.TagName, InTagCount,InIsTacTag,PlayerController,PlayerController and PlayerController:IsLocalController() or false)
    self:UpdateData(InTag,InTagCount,true)
end

function MobileReloadUI:OnFullTagCountChange(InASC,InTag,InTagCount)
    if not self:IsLocalContgroller(InASC) then
        return
    end
    print("MobileReloadUI", ">> OnFullTagCountChange, ", InTag.TagName, InTagCount,InIsTacTag,PlayerController,PlayerController and PlayerController:IsLocalController() or false)
    self:UpdateData(InTag,InTagCount,false)
end

function MobileReloadUI:UpdateData(InTag,InTagCount,InIsTacTag)
    print("MobileReloadUI", ">> UpdateData, ", InTag.TagName, InTagCount,InIsTacTag)
    self.bInRelading = InTagCount > 0
    self.Reloading:SetVisibility(self.bInRelading and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if self.bInRelading then
        local WeaponInstance = UE.UGAWAttachmentFunctionLibrary.GetFirstEquippingWeaponInstance(self);
        if not WeaponInstance then
            print("MobileReloadUI", ">> UpdateData, error :not get WeaponInstance")
            self.RemainTime = 0
        else
            self.RemainTime = WeaponInstance:GetMagnitudeByTag(InIsTacTag and self.TacTag or self.FullTag, 1)
        end
    else
        self.RemainTime = 0
    end

    self.AllTime = self.RemainTime > 0 and self.RemainTime or 0
end

function MobileReloadUI:IsLocalContgroller(InASC)
    local Pawn = InASC:GetOwner():Cast(UE.APawn)
    if Pawn == nil then
        return false
    end
    local PlayerController = Pawn:GetController()
    if PlayerController == nil then
        return false
    end

    return self.LocalPC == PlayerController
end

return MobileReloadUI