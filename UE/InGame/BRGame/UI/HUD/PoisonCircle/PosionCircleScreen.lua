local PosionCircleScreen = Class("Common.Framework.UserWidget")

local RingActorMapping = {
    [0] = 0.1,
    [1] = 0.2,
    [2] = 0.3,
    [3] = 0.4,
    [4] = 0.5,
    [5] = 0.6,
    [6] = 0.7,
    [7] = 0.8,
    [8] = 1,
}

function PosionCircleScreen:OnInit()
    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.RING_StateChange,	    Func = self.OnChanged_RingState,        bCppMsg = true, WatchedObject = nil },
	}
    if self.MsgList then MsgHelper:RegisterList(self, self.MsgList) end
    UserWidget.OnInit(self)
end

function PosionCircleScreen:OnDestroy()
    if self.MsgList then MsgHelper:UnregisterList(self, self.MsgList) end
    UserWidget.OnDestroy(self)
end

function PosionCircleScreen:OnShow()
    self:UpdateBGMaterial()
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if not UIManager then return end
    local LobbyPlayerInfoViewModel = UIManager:GetViewModelByName("TagLayout.Gameplay.LobbyPlayerInfo")
    if not LobbyPlayerInfoViewModel then return end
    if LobbyPlayerInfoViewModel.PlayerPlayCount < 3 then
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        local GenericBlackboardContainer = UE.FGenericBlackboardContainer()
        local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
        BlackboardKeySelector.SelectedKeyName = "Anchors"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsVector(GenericBlackboardContainer,BlackboardKeySelector,UE.FVector(0.5,0.5,0))
        BlackboardKeySelector.SelectedKeyName = "Alignment"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsVector(GenericBlackboardContainer,BlackboardKeySelector,UE.FVector(0.5,0.5,0))
        TipsManager:ShowTipsUIByTipsId("Guide.PoisonCircle", -1, GenericBlackboardContainer, self)
    end
end

function PosionCircleScreen:OnClose()
    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    TipsManager:RemoveTipsUI("Guide.PoisonCircle")
end

function PosionCircleScreen:OnChanged_RingState(InRingActor)
    self:UpdateBGMaterial()
end

function PosionCircleScreen:UpdateBGMaterial()
    if not UE.UKismetSystemLibrary.IsValid(self.RingActor) then
		self.RingActor = MinimapHelper.GetRingActor(self)
	end
    if (not UE.UKismetSystemLibrary.IsValid(self.RingActor)) or (self.RingActor:GetWorld() ~= self:GetWorld()) then return end

    if self.RingActor:GetRingIndex() == nil then return end
    local RingIndex = self.RingActor:GetRingIndex()
    if self.ImgBg then
        if not RingActorMapping[RingIndex] then return end
        print("PosionCircleScreen>>UpdateMaterialValue>>RingIndex: ", RingIndex, " RingActorMapping[RingIndex]: ", RingActorMapping[RingIndex])
        self.ImgBg:GetDynamicMaterial():SetScalarParameterValue("Global_Intensity", RingActorMapping[RingIndex])
    end
end

return PosionCircleScreen