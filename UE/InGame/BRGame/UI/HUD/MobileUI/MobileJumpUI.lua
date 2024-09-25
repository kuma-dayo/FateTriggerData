local MobileJumpUI = Class("Common.Framework.UserWidget")

function MobileJumpUI:OnInit()
    print("MobileJumpUI",">> OnInit")
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,  Func = self.OnLocalPCUpdatePawn,    bCppMsg = true, WatchedObject = self.LocalPC },
    }

    UserWidget.OnInit(self)
end

function MobileJumpUI:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
    print("MobileJumpUI", ">> OnLocalPCUpdatePawn, ",
        GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InPCPwn))
    if self.LocalPC == InLocalPC then
        local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
        if not LocalPCPawn then
            return
        end
        MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
        self.MsgList_Pawn = {
            { MsgName = GameDefine.MsgCpp.Character_BRState_Parachute_Glide_OnTagEvent,  Func = self.OnGlideTagCountChange,    bCppMsg = true, WatchedObject = self.LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.Character_BRState_Parachute_Skydive_OnTagEvent,  Func = self.OnSkydiveTagCountChange,    bCppMsg = true, WatchedObject = self.LocalPCPawn },
        }
        MsgHelper:RegisterList(self, self.MsgList_Pawn)
        print("MobileJumpUI", ">> OnLocalPCUpdatePawn, Listen succeed")
    end
end

function MobileJumpUI:OnDestroy()
    UserWidget.OnDestroy(self)
end

function MobileJumpUI:OnGlideTagCountChange(InObj,InTag,InTagCount)
    self:AddTargetInputActions(InTag,InTagCount,true)
end

function MobileJumpUI:OnSkydiveTagCountChange(InObj,InTag,InTagCount)
    self:AddTargetInputActions(InTag,InTagCount,false)
end

function MobileJumpUI:AddTargetInputActions(InTag,InTagCount,InIsGlideTag)
    print("MobileJumpUI", ">> AddTargetInputActions,EnhancedInput.Fly.TriggerGlide ", InTag.TagName, InTagCount,InIsGlideTag)
    if InTagCount < 1 then
        return
    end
    self.BtnJump:ClearInputActions()
    local TargetIAList = InIsGlideTag and self.JumpIAList_Glide or self.JumpIAList_Skydive
    for _, TempIA in pairs(TargetIAList) do
        self.BtnJump:AddInputActionExtend(TempIA)
    end
end

return MobileJumpUI