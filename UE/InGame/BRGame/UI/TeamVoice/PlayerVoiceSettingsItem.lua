require "UnLua"

local PlayerVoiceSettingsItem = Class("Common.Framework.UserWidget")

function PlayerVoiceSettingsItem:OnInit()
    print("PlayerVoiceSettingsItem:OnInit")

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    self.BindNodes ={
        { UDelegate = self.Slider.OnValueChanged, Func = self.OnSliderValueChanged },
        { UDelegate = self.Button_Voice.OnClicked, Func = self.OnVoiceSwitchButtonClicked },
        { UDelegate = self.Button_Add.OnClicked,Func = self.OnVoiceAddClicked },
        { UDelegate = self.Button_Sub.OnClicked,Func = self.OnVoiceSubClicked },
        { UDelegate = self.Button_Report.OnClicked,Func = self.OnOpenReport },
    }

    self.bVoiceLimit = false
    self.MAX_VOICE = 100
    self.MIN_VOICE = 0
    self.SaveVolume = 100
    -- self.ImgHover.OnMouseEnterEvent:Bind(self,self.OnMouseEnter_Slider)
    UserWidget.OnInit(self)
end

--#region 事件


function PlayerVoiceSettingsItem:OnShow()
    self:UpdateVoiceSpeakerUI()
end

function PlayerVoiceSettingsItem:OnMouseEnter(MyGeometry,MouseEvent)
    self:Hover()
    return UE.UWidgetBlueprintLibrary.Handled()
end

function PlayerVoiceSettingsItem:OnMouseLeave(MyGeometry,MouseEvent)
    self:UnHover()
    return UE.UWidgetBlueprintLibrary.Handled()
end


function PlayerVoiceSettingsItem:Hover()
    self.ImgBG:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.ProgressBar:SetRenderScale(self.ProgressBarHoverSize)
    --滑动条选中态
    self.Slider:SetRenderScale(self.SliderHoverSize)
    self.Slider:SetVisibility(UE.ESlateVisibility.Visible)
    --文字选中态
    self.PlayerNameTextBlock:SetColorAndOpacity(self.TextHoveredColor)
    self.TxtVoice:SetColorAndOpacity(self.TextHoveredColor)
    local TmpFont = self.TxtVoice.Font
    TmpFont.Size = self.TextSizeHovered
    self.TxtVoice:SetFont(TmpFont)

    self.GUIImage_Normol:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.GUIImage_HoverFrame:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

end

function PlayerVoiceSettingsItem:UnHover()
    self.ImgBG:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ProgressBar:SetRenderScale(UE.FVector2D(1,1))
    --滑动条未选中态
    self.Slider:SetRenderScale(UE.FVector2D(1,1))
    self.Slider:SetVisibility(UE.ESlateVisibility.Collapsed)
    --文字未选中态
    self.PlayerNameTextBlock:SetColorAndOpacity(self.TextUnhoveredColor)
    self.TxtVoice:SetColorAndOpacity(self.TextUnhoveredColor)
    local TmpFont = self.TxtVoice.Font
    TmpFont.Size = self.TextSizeUnhovered
    self.TxtVoice:SetFont(TmpFont)

    self.GUIImage_Normol:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.GUIImage_HoverFrame:SetVisibility(UE.ESlateVisibility.Collapsed)

    self.ImgVoiceOn:SetColorAndOpacity(self.ImgUnhoveredColor)
    self.ImgVoiceOff:SetColorAndOpacity(self.ImgUnhoveredColor)
end

--#endregion


function PlayerVoiceSettingsItem:OnSliderValueChanged(InVaule)
    print("(Wzp)PlayerVoiceSettingsItem:OnSliderValueChanged [InVaule]=",InVaule)
    local RoomInfo = self.PlayerChatComponent:GetVoiceRoomInfoByPlayerID(self.CurrentTeammateOwnerPlayerId)
    if not RoomInfo then
        return
    end
    local bEnableSpeaker = RoomInfo.bEnableSpeaker
    print("(Wzp)PlayerVoiceSettingsItem >> OnSliderValueChanged  [ObjectName=",GetObjectName(self),"],[InVaule=",InVaule,"], [RoomInfo=",RoomInfo,"],[bEnableSpeaker=",bEnableSpeaker,"]")
    if not bEnableSpeaker then
        return
    end

    local Value = math.tointeger(math.round(InVaule*100))
    self.SaveVolume = Value
    self.PlayerChatComponent:SetSpeakerVolume(self.CurrentTeammateOwnerPlayerId,self.SaveVolume)
    self:InitVolume()
end

function PlayerVoiceSettingsItem:InitializePlayerVoiceItem()
    -- self:InitializedPlayerInfoByID()
    self.PlayerChatComponent = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
end

--点击 音量加
function PlayerVoiceSettingsItem:OnVoiceAddClicked()
    --开启队友语音
    local bEnableSpeaker = self.PlayerChatComponent:GetSpakerState(self.CurrentTeammateOwnerPlayerId)
    if bEnableSpeaker == false then
        self:OnVoiceSwitchButtonClicked()
    end

    local Volume = self.PlayerChatComponent:GetSpeakerVolume(self.CurrentTeammateOwnerPlayerId)
    self.SaveVolume = math.clamp(Volume + 1,self.MIN_VOICE,self.MAX_VOICE)
    self.PlayerChatComponent:SetSpeakerVolume(self.CurrentTeammateOwnerPlayerId,self.SaveVolume)

    self:InitVolume()

end

--点击 音量减
function PlayerVoiceSettingsItem:OnVoiceSubClicked()
    --开启队友语音
    local bEnableSpeaker = self.PlayerChatComponent:GetSpakerState(self.CurrentTeammateOwnerPlayerId)
    if bEnableSpeaker == false then
        self:OnVoiceSwitchButtonClicked()
    end

    local Volume = self.PlayerChatComponent:GetSpeakerVolume(self.CurrentTeammateOwnerPlayerId)
    self.SaveVolume = math.clamp(Volume - 1,self.MIN_VOICE,self.MAX_VOICE)
    self.PlayerChatComponent:SetSpeakerVolume(self.CurrentTeammateOwnerPlayerId,self.SaveVolume)
    self:InitVolume()
end


--点击 小喇叭按钮
function PlayerVoiceSettingsItem:OnVoiceSwitchButtonClicked()
    local bEnableSpeaker = self.PlayerChatComponent:GetSpakerState(self.CurrentTeammateOwnerPlayerId)
    self.PlayerChatComponent:SetSpakerState(self.CurrentTeammateOwnerPlayerId,not bEnableSpeaker)
    self:UpdateVoiceSpeakerUI()
end


function PlayerVoiceSettingsItem:InitVolume()
    local Volume = self.PlayerChatComponent:GetSpeakerVolume(self.CurrentTeammateOwnerPlayerId)
    --已知Bug，控制Slider会导致 OnSliderValueChanged 触发
    self.Slider:SetValue(Volume / 100)
    self.ProgressBar:SetPercent(Volume / 100)
    self.TxtVoice:SetText(Volume)
end

function PlayerVoiceSettingsItem:UpdateVoiceSpeakerUI()
    local bEnableSpeaker = self.PlayerChatComponent:GetSpakerState(self.CurrentTeammateOwnerPlayerId)
    self.Slider:SetIsEnabled(bEnableSpeaker)
    self.ProgressBar:SetIsEnabled(bEnableSpeaker)
    if bEnableSpeaker then
        self:OnSliderValueChanged(self.SaveVolume/100)
    else
        self:UpdateSlider(0)
    end
    self:UpdateVoiceButton(bEnableSpeaker)
end

function PlayerVoiceSettingsItem:UpdateSlider(Volume)
    print("(Wzp)PlayerVoiceSettingsItem:UpdateSlider [Volume]=",Volume,"[Volume / 100.0] =",Volume / 100.0)
    self.Slider:SetValue(Volume / 100.0)
    self.ProgressBar:SetPercent(Volume / 100.0)
    self.TxtVoice:SetText(Volume)
end

--更新小喇叭图标
function PlayerVoiceSettingsItem:UpdateVoiceButton(bIsActive)
    local ChildrenCount = self.Button_Voice:GetChildrenCount()
    for index = 0, ChildrenCount-1 do
        local OverlayWidget = self.Button_Voice:GetChildAt(index)
        local SizeBoxWidget = OverlayWidget:GetChildAt(1)
        local SwitcherWidget = SizeBoxWidget:GetChildAt(0)
        SwitcherWidget:SetActiveWidgetIndex(bIsActive and 0 or 1)
    end
end


function PlayerVoiceSettingsItem:OnUpdateHerotypeId(HeroTypeId)
    print("PlayerVoiceSettingsItem >> OnUpdateHerotypeId > HeroTypeId=",HeroTypeId)
    local PawnConfig = UE.FGePawnConfig()
    local bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(HeroTypeId,PawnConfig,self)
    if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
        self.Head.GUIImage_Hero:SetBrushFromSoftTexture(PawnConfig.Icon, false)
    end
end



function PlayerVoiceSettingsItem:OnOpenReport()
    print("PlayerVoiceSettingsItem >> OnOpenReport ")

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPS = LocalPC and LocalPC.PlayerState or nil

    local TheGameId =  self.GameState.GameId

    if not self.ThisPS then return end
    local ThePlayerName = self.ThisPS:GetPlayerName()
    local ThePlayerId = self.ThisPS:GetPlayerId()

    local TeamExSubsystem =  UE.UTeamExSubsystem.Get(self)
    local TheTeamId = TeamExSubsystem:GetTeamIdByPS(LocalPS)

    -- local Param = {
    --     ReportScene = ReportConst.Enum_ReportScene.InGame,

    --     GameInfo = {
    --         GameId = TheGameId,
    --         LevelId = 1011001,
    --         View = 1,
    --         TeamType = 1
    --     },
    --     ReportLocation = {1, 2, 3},
    --     DefaultSelectReportPlayerIndex  = 1,
    --     ReportPlayers = {
    --         [1] = {
    --             PlayerId = ThePlayerName,
    --             PlayerName = ThePlayerId
    --         }
    --     },
    -- }

 
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
    BlackboardKeySelector.SelectedKeyName = "SelfPlayerId"
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
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsObject(GenericBlackboardContainer, BlackboardKeySelector, self.SelfPS)
    BlackboardKeySelector.SelectedKeyName = "ReportPlayerState"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsObject(GenericBlackboardContainer, BlackboardKeySelector, self.ThisPS)
    BlackboardKeySelector.SelectedKeyName = "PreInputMode" --记录当前输入模式，退出举报根据这个值还原当前输入模式
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector, 2)

    self.ReportHandle = UIManager:TryLoadDynamicWidget("UMG_Report",GenericBlackboardContainer,true)

    MvcEntry:GetCtrl(ReportCtrl)
    -- local ReportCtrl = MvcEntry:GetCtrl(ReportCtrl)
    -- ReportCtrl:InGameReport(Param)
end


function PlayerVoiceSettingsItem:RefreshUI(TeammatePS,SelfPS)

    self.PlayerChatComponent = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.GameState = UE.UGameplayStatics.GetGameState(self)
    self.ThisPS = TeammatePS
    self.SelfPS = SelfPS
    self.CurrentTeammateOwnerPlayerId = TeammatePS:GetPlayerId()

    print("[Wzp]PlayerVoiceSettingsItem >> RefreshUI <ObjectName=",GetObjectName(self),"><self.ThisPS=",self.ThisPS,"><self.CurrentTeammateOwnerPlayerId=",self.CurrentTeammateOwnerPlayerId,">")
    self.MsgList = {
        { MsgName  = GameDefine.MsgCpp.UISync_Update_RuntimeHeroId ,Func = self.OnUpdateHerotypeId , bCppMsg = true , WatchedObject = TeammatePS},
    }

    MsgHelper:RegisterList(self, self.MsgList)

    local PlayerName = TeammatePS:GetPlayerName()
    local CurTeamPos = BattleUIHelper.GetTeamPos(TeammatePS)
    local ImgColor = MinimapHelper.GetTeamMemberColor(CurTeamPos)
    
    print("[Wzp]PlayerVoiceSettingsItem >> RefreshUI <PlayerName=",PlayerName,",><CurTeamPos=",CurTeamPos,">")

    self:SetVisibility(UE.ESlateVisibility.Visible)
    self.PlayerNameTextBlock:SetText(TeammatePS:GetPlayerName())
    self.Head.Text_Num:SetText(CurTeamPos or 1)
    self.Head.ImgBg:SetColorAndOpacity(ImgColor)

    local HeroId = UE.UPlayerExSubsystem.Get(self):GetPlayerRuntimeHeroId(TeammatePS:GetPlayerId())
    local RefPawn = UE.UPlayerStatics.GetPSPlayerPawn(TeammatePS)
    local PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnData(RefPawn)
    if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
        self.Head.GUIImage_Hero:SetBrushFromSoftTexture(PawnConfig.Icon, false)
    end  
end


return PlayerVoiceSettingsItem