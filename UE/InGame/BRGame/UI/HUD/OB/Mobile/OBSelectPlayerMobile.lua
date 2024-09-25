
local OBSelectPlayerMobile =Class("Common.Framework.UserWidget")

function OBSelectPlayerMobile:OnInit()
    print("OBSelectPlayerMobile >> OnInit ObjectName=",GetObjectName(self))
	UserWidget.OnInit(self)
end

function OBSelectPlayerMobile:InitData(InParentWidget,InPlayerID)
    -- TeammatePS = InPlayerState
    self.ParentWidget = InParentWidget;
    self.PlayerID = InPlayerID
    self.Button_SwitchViewTarget.OnClicked:Clear()
    self.Button_SwitchViewTarget.OnClicked:Add(self,self.OnClickEntryItem)
    self:RefreshUI()
end

function OBSelectPlayerMobile:RefreshUI()
    local PlayerExSubsystemIns = UE.UPlayerExSubsystem.Get(self)
    local TeammatePS = PlayerExSubsystemIns:GetPlayerStateById(self.PlayerID)

    print("[WZP]OBSelectPlayerMobile >> RefreshUI > self.PlayerID=",self.PlayerID)
    print("[WZP]OBSelectPlayerMobile >> RefreshUI > TeammatePS=",TeammatePS)

    local PlayerName =TeammatePS:GetPlayerName()
    local TeamPos = BattleUIHelper.GetTeamPos(TeammatePS)
    local ImgColor = MinimapHelper.GetTeamMemberColor(TeamPos)

    self.ImgBgNum:SetColorAndOpacity(ImgColor)
    self.TxtNumber:SetText(TeamPos)
    self.Text_PlayerName:SetText(PlayerName)

    local RefPawn = UE.UPlayerStatics.GetPSPlayerPawn(TeammatePS)
    local PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnData(RefPawn)
    if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
        self.ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon)
    end

end

function OBSelectPlayerMobile:OnClickEntryItem()
    local ObserveSubsystem = UE.UObserveSubsystem.Get(self)
    if ObserveSubsystem then
        local OwningGA = ObserveSubsystem:GetClientOwningAbility()
        if OwningGA then
            OwningGA:ServerRPC_TryObservePlayer(self.PlayerID )
        end
    end
    self.ParentWidget:CloseDropUpBox()
end

function OBSelectPlayerMobile:OnDestroy()
    print("OBSelectPlayerMobile >> OnDestroy")
	UserWidget.OnDestroy(self)
end
return OBSelectPlayerMobile
