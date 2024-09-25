--
-- 被观战玩家 - 对局信息(击杀数/击倒数/救援数)
--
-- @COMPANY	ByteDance
-- @AUTHOR	王泽平
-- @DATE	2023.05.17

--当前被观战玩家的击杀数 击倒数 救援数 
--切换被观战角色重新刷新信息

require "UnLua"
local ParentClassName = "InGame.BRGame.UI.HUD.OB.Mobile.OBWatchGameBase"

local OBWatchGameBase = require(ParentClassName)
local OBWatchGameMobile = Class(ParentClassName)

-------------------------------------------- Init/Destroy ------------------------------------

local EDropUpState={
    Close = 0,
    Open = 1,
}

function OBWatchGameMobile:OnInit()
    print("OBWatchGameMobile >> OnInit ObjectName=",GetObjectName(self))
    self.UIManager = UE.UGUIManager.GetUIManager(self)

    self.WatchGameViewModel = self.UIManager:GetViewModelByName("TagLayout.GamePlay.OB.WatchGame")
    self.WatchGameViewModel:K2_AddFieldValueChangedDelegateSimple("ViewTargetBattleRecord",{ self, self.OnUpdateViewTargetBattleRecord })
    self.WatchGameViewModel:K2_AddFieldValueChangedDelegateSimple("ViewTargetType",{ self, self.OnViewTargetType })
    self.WatchGameViewModel:K2_AddFieldValueChangedDelegateSimple("ViewTargetName",{ self, self.OnViewTargetName })
    self.WatchGameViewModel:K2_AddFieldValueChangedDelegateSimple("ViewTargetPlayerID",{ self, self.OnViewTargetPlayerID })
    -- self.WatchGameViewModel:K2_AddFieldValueChangedDelegateSimple("OBTeammateArr",{ self, self.OnOBTeammateArr })



    self.GameState = UE.UGameplayStatics.GetGameState(self)
    self:RefreshDropUpBox(EDropUpState.Close)
    self.Button_Change.OnClicked:Add(self,self.OnClickDropUpEntry) 
    self.Button_Change.OnFocusLosted:Add(self,self.OnImageEventMouseButtonDown)
    self.Button_Report.OnClicked:Add(self,self.OnClickReport)
    self.ImageEvent.OnMouseButtonDownEvent:Bind(self,self.OnImageEventMouseButtonDown)

	UserWidget.OnInit(self)
end

function OBWatchGameMobile:OnDestroy()
    print("OBWatchGameMobile >> OnDestroy")

    self.WatchGameViewModel:K2_RemoveFieldValueChangedDelegateSimple("ViewTargetBattleRecord",{ self, self.OnUpdateViewTargetBattleRecord })
    self.WatchGameViewModel:K2_RemoveFieldValueChangedDelegateSimple("ViewTargetType",{ self, self.OnViewTargetType })
    self.WatchGameViewModel:K2_RemoveFieldValueChangedDelegateSimple("ViewTargetName",{ self, self.OnViewTargetName })
    self.WatchGameViewModel:K2_RemoveFieldValueChangedDelegateSimple("ViewTargetPlayerID",{ self, self.OnViewTargetPlayerID })

    self.ImageEvent.OnMouseButtonDownEvent:Clear()
    self.Button_Change.OnClicked:Clear()
	UserWidget.OnDestroy(self)
end


function OBWatchGameMobile:OnShow()
    print("OBWatchGameMobile >> OnShow")
    self:OnUpdateViewTargetBattleRecord(self.WatchGameViewModel,nil)
    self:OnViewTargetName(self.WatchGameViewModel,nil)
    self:OnViewTargetPlayerID(self.WatchGameViewModel,nil)
    self:OnViewTargetType(self.WatchGameViewModel,nil)
end


function OBWatchGameMobile:OnOBTeammateArr(vm, fieldID)
    local OBTeammateArr = vm.OBTeammateArr
    local TeammateNum = OBTeammateArr:Num()
    print("OBWatchGameMobile >> OnOBTeammateArr TeammateNum=",TeammateNum)
end

function OBWatchGameMobile:OnClickDropUpEntry()
    if self.DropUpState == EDropUpState.Close then
        self:OpenDropUpBox()
    else
        self:CloseDropUpBox()
    end
end

function OBWatchGameMobile:OpenDropUpBox()
    self:RefreshDropUpBox(EDropUpState.Open)
end

function OBWatchGameMobile:CloseDropUpBox()
    self:RefreshDropUpBox(EDropUpState.Close)
end

function OBWatchGameMobile:RefreshDropUpBox(DropUpState)
    self.DropUpState = DropUpState
    if self.DropUpState == EDropUpState.Open then
        self:OnViewTargetPlayerID(self.WatchGameViewModel,nil)
        self.VB_Teammate:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.VB_Teammate:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function OBWatchGameMobile:GetAllTeammateWidget()
    return {[1] = self.BP_OBSelectPlayer_0,[2] = self.BP_OBSelectPlayer_1,[3] = self.BP_OBSelectPlayer_2}
end

function OBWatchGameMobile:OnUpdateOBInfo()
    self.GUIKill:SetText("?")
    self.GUIAssist:SetText("?")
    self.GUIKnockdown:SetText("?")
end

function OBWatchGameMobile:OnUpdateViewTargetBattleRecord(vm, fieldID)
    local ViewTargetBattleRecord = vm.ViewTargetBattleRecord
    self:RefreshKillKnockDownAssist(ViewTargetBattleRecord)
end

function OBWatchGameMobile:OnViewTargetType(vm, fieldID)
    local ViewTargetType = vm.ViewTargetType
    self:RefreshtViewTargetCamp(ViewTargetType)
end

function OBWatchGameMobile:OnViewTargetName(vm, fieldID)
    local ViewTargetName = vm.ViewTargetName
    self:RefreshPlayerName(ViewTargetName)
end

function OBWatchGameMobile:OnViewTargetPlayerID(vm, fieldID)
    local ViewTargetPlayerID = vm.ViewTargetPlayerID
    print("[WZP]OBWatchGameMobile >> OnViewTargetPlayerID > ViewTargetPlayerID=",ViewTargetPlayerID)
    local PlayerExSubsystemIns = UE.UPlayerExSubsystem.Get(self)
    local ViewTargetPS = PlayerExSubsystemIns:GetPlayerStateById(ViewTargetPlayerID)
    self.ViewTargetPS = ViewTargetPS
    print("[WZP]OBWatchGameMobile >> OnViewTargetPlayerID > ViewTargetPS=",ViewTargetPS)

    self:RefreshViewTargetUI(ViewTargetPS)

    local TeammateTable = {}
    local UObserveSubsystem =  UE.UObserveSubsystem.Get(self)
    local ClientOB_GA = UObserveSubsystem:GetClientOwningAbility()
    if ClientOB_GA then
         local OBTeammateArr = ClientOB_GA.TeammatesValidForOB
         local TeammateArrNum = OBTeammateArr:Num()
         print("[WZP]OBWatchGameMobile >> OnViewTargetPlayerID > TeammateArrNum=",TeammateArrNum)
         local Index = 1
         for i = 1, TeammateArrNum do
            local PlayerID = OBTeammateArr[i]
            if PlayerID ~= ViewTargetPlayerID then
                table.insert(TeammateTable,Index,PlayerID)
                Index = Index+1
            end
         end 
    end

    local TeammateWidget = self:GetAllTeammateWidget()
    -- 这里要判断玩家是不是死亡，如果死亡则不显示
    for i, Widget in pairs(TeammateWidget) do
        local TeammatePlayerID = TeammateTable[i]
        if TeammatePlayerID then
            Widget:InitData(self,TeammatePlayerID)
            Widget:SetVisibility(UE.ESlateVisibility.Visible)
        else
            Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end


function OBWatchGameMobile:RefreshViewTargetUI(InViewTargetPS)
    local PlayerID =InViewTargetPS:GetPlayerId()
    local PlayerName =InViewTargetPS:GetPlayerName()
    local TeamPos = BattleUIHelper.GetTeamPos(InViewTargetPS)
    local ImgColor = MinimapHelper.GetTeamMemberColor(TeamPos)

    self.ImgBgNum:SetColorAndOpacity(ImgColor)
    self.TxtNumber:SetText(TeamPos)

    local RefPawn = UE.UPlayerStatics.GetPSPlayerPawn(InViewTargetPS)
    local PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnData(RefPawn)
    if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
        self.ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon)
    end

end


function OBWatchGameMobile:RefreshPlayerName(InViewTargetName)
    if InViewTargetName then
        self.Text_PlayerName:SetText(InViewTargetName)
    end
    print("[WZP]OBWatchGameMobile >> RefreshPlayerName InViewTargetName=",InViewTargetName)
end


-- 获取/设置击杀 助攻 击倒信息，
-- PlayerBattleRecord 结构体 : PlayerId玩家id、KillDeath击杀、KnockDown击倒、PlayerAssist助攻、PlayerDamage伤害输出
function OBWatchGameMobile:RefreshKillKnockDownAssist(InPlayerBattleRecord)
    if InPlayerBattleRecord then
        local PlayerId = InPlayerBattleRecord.PlayerId
        local KillDeath =  InPlayerBattleRecord.KillDeath
        local KnockDown = InPlayerBattleRecord.KnockDown
        local PlayerAssist = InPlayerBattleRecord.PlayerAssist

        print("OBWatchGameMobile >> RefreshKillKnockDownAssist > PlayerId=",PlayerId)
        print("OBWatchGameMobile >> RefreshKillKnockDownAssist > KillDeath=",KillDeath)
        print("OBWatchGameMobile >> RefreshKillKnockDownAssist > KnockDown=",KnockDown)
        print("OBWatchGameMobile >> RefreshKillKnockDownAssist > PlayerAssist=",PlayerAssist)

        if KillDeath then
            self.BP_KDA.Text_Kill:SetText(tostring(KillDeath))
        end
        if KnockDown then
            self.BP_KDA.Text_Down:SetText(tostring(KnockDown))
        end
        if PlayerAssist then
            self.BP_KDA.Text_Assist:SetText(tostring(PlayerAssist))
        end
    end
end

function OBWatchGameMobile:RefreshtViewTargetCamp(InViewTargetType)

    local CampLinearColor = self.CampColorMap:Find(InViewTargetType)
    if InViewTargetType == UE.EViewTargetType.Teammate then
        self.BP_KDA.WS_Camp:SetActiveWidgetIndex(0)
    elseif InViewTargetType == UE.EViewTargetType.Enemy then
        self.BP_KDA.WS_Camp:SetActiveWidgetIndex(1)
    end
    self.Image_Right:SetColorAndOpacity(CampLinearColor)
    self.Image_Left:SetColorAndOpacity(CampLinearColor)
end


function OBWatchGameMobile:OnClickReport()

    if not self.ViewTargetPS then
        return
    end



    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local OriginalPlayerState = LocalPC.OriginalPlayerState

    local TheGameId =  self.GameState.GameId

    local ThePlayerName = self.ViewTargetPS:GetPlayerName()
    local ThePlayerId = self.ViewTargetPS:GetPlayerId()

    local TeamExSubsystem = UE.UTeamExSubsystem.Get(self)
    local TheTeamId = TeamExSubsystem:GetTeamIdByPS(self.ViewTargetPS)

    local UIManager = UE.UGUIManager.GetUIManager(self)
    local bIsShow = UIManager:IsDynamicWidgetShowByHandle(self.ReportHandle) 
    if bIsShow then
        UIManager:TryCloseDynamicWidgetByHandle(self.ReportHandle)
        return
    end

    
    local GenericBlackboardContainer = UE.FGenericBlackboardContainer()
    local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackboardKeySelector.SelectedKeyName = "ReportPlayerId"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboardContainer, BlackboardKeySelector, tostring(ThePlayerId))
    -- BlackboardKeySelector.SelectedKeyName = "SelfPlayerId"
    -- UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboardContainer, BlackboardKeySelector, tostring(ThePlayerId))

    BlackboardKeySelector.SelectedKeyName = "ReportPlayerName"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboardContainer, BlackboardKeySelector, ThePlayerName)
    BlackboardKeySelector.SelectedKeyName = "GameId"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboardContainer, BlackboardKeySelector, TheGameId)
    BlackboardKeySelector.SelectedKeyName = "ReportLocation"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsVector(GenericBlackboardContainer,BlackboardKeySelector,UE.FVector(0,0,0))
    BlackboardKeySelector.SelectedKeyName = "ReportTeamId"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboardContainer, BlackboardKeySelector, TheTeamId)
    BlackboardKeySelector.SelectedKeyName = "PlayerState"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsObject(GenericBlackboardContainer, BlackboardKeySelector, self.ViewTargetPS)
    BlackboardKeySelector.SelectedKeyName = "ReportPlayerState"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsObject(GenericBlackboardContainer, BlackboardKeySelector, OriginalPlayerState)
    BlackboardKeySelector.SelectedKeyName = "PreInputMode" --记录当前输入模式，退出举报根据这个值还原当前输入模式
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector, 2)

    self.ReportHandle = UIManager:TryLoadDynamicWidget("UMG_Report",GenericBlackboardContainer,true)
end


function OBWatchGameMobile:OnImageEventMouseButtonDown(InMyGeometry, InMouseEvent)

    print("[wzp]OBWatchGameMobile >> OnImageEventMouseButtonDown")
    self:CloseDropUpBox();
end



return OBWatchGameMobile

