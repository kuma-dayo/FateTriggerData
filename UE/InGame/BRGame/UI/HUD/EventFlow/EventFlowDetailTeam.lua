--
-- 战斗界面 - 事件流水(击杀/治疗/复活)
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.12
--

local EventFlowDetailTeam = Class("Common.Framework.UserWidget")
local testProfile = require("Common.Utils.InsightProfile")

local Collapsed = UE.ESlateVisibility.Collapsed
local SelfHitTestInvisible = UE.ESlateVisibility.SelfHitTestInvisible

-------------------------------------------- Init/Destroy ------------------------------------
function EventFlowDetailTeam:OnInit()

	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.IfPlayAnimation = false
	UserWidget.OnInit(self)
end

function EventFlowDetailTeam:OnDestroy()
	UserWidget.OnDestroy(self)
end
-------------------------------------------- Get/Set ------------------------------------

-------------------------------------------- Function ------------------------------------
function EventFlowDetailTeam:InitDetailData(InFlowData)
    print("EventFlowDetailTeam:InitDetailData")
    testProfile.Begin("EventFlowDetailTeam:InitDetailData")
    self:SetRenderOpacity(1)
    self:SetVisibility(SelfHitTestInvisible)

    -- 名字信息
    local TargetName = InFlowData.CauseName
    if not InFlowData.CauseName or InFlowData.CauseName == "" then -- 无攻击者昵称时需要用配置表里的 描述信息
        local GameplayTags = UE.UBlueprintGameplayTagLibrary.BreakGameplayTagContainer(InFlowData.Tags)
        for i = 0, GameplayTags:Length() do
            local TagName = ""
            if GameplayTags:IsValidIndex(i) then TagName = UE.UBlueprintGameplayTagLibrary.GetDebugStringFromGameplayTag(GameplayTags:GetRef(i)) end
            local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.EventFlowCfg, TagName)
            if cfg and cfg.DetailDesc then
                TargetName = cfg.DetailDesc
            end
        end
    end
    testProfile.End("EventFlowDetailTeam:InitDetailData")
    self.bIfSelfDamage = InFlowData.PlayerId == InFlowData.ReceiverPlayerId or -1 == InFlowData.PlayerId
    self.Type = InFlowData.Type
    self.Cause_Bg_Color = self:GetTargetColor(InFlowData.CauserTeamId,InFlowData.CauserTeamIndex)
    self.Receive_Bg_Color = self:GetTargetColor(InFlowData.ReceiverTeamId,InFlowData.ReceiverTeamIndex)
    self.CauseIsTeam = self.Cause_Bg_Color ~= UIHelper.LinearColor.White
    self.ReceiveIsTeam = self.Cause_Bg_Color ~= UIHelper.LinearColor.White
    self.CauserKillNum = InFlowData.CauserKillNum
    self.CauserId = InFlowData.PlayerId
    self.OffTeam = InFlowData.ReceiverTeamPlayerNum == 0
    self.bDying = InFlowData.bDying
    self.bKilled = InFlowData.bKilled
    self.ReceiverPlayerId = InFlowData.ReceiverPlayerId

    if self.Overlay_KillAll then
        self.Overlay_KillAll:SetVisibility(self.OffTeam and SelfHitTestInvisible or Collapsed)
    end

    if self.Text_Down then
        self.Text_Down:SetVisibility(self.bDying and SelfHitTestInvisible or Collapsed)
    end

    if self.Text_Kill then
        self.Text_Kill:SetVisibility(self.bKilled and SelfHitTestInvisible or Collapsed)
    end

    self:UpdateEliminateInfo()


    self:UpdateText(self.TxtCaster,TargetName, self.Cause_Bg_Color, true)
    self:UpdateText(self.TxtInjurers,InFlowData.ReceiverName, self.Receive_Bg_Color)




    --print("EventFlowDetailTeam >> InitDetailData OffSetPos:", OffSetPos, "InFlowData.Type:", InFlowData.Type, GetObjectName(self))
end

function EventFlowDetailTeam:UpdateEliminateInfo()

    if not self.LocalPS then
        if not self.LocalPC then
            self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        end
        
        if self.LocalPC then
            self.LocalPS = self.LocalPC.PlayerState
        end
    end
    local IfSelfCauser = false
    if self.LocalPS then
        IfSelfCauser = self.CauserId == self.LocalPS.PlayerId
    end

    if IfSelfCauser then
        -- 淘汰人数
        if self.Text_EliminateNum then
            self.Text_EliminateNum:SetText(tostring(self.CauserKillNum))
        end


        -- 击杀队友不显示title和淘汰数目
        local TeamExSubsystem = UE.UTeamExSubsystem.Get(self)
        local IsTeammate = TeamExSubsystem:IsTeammateByPSandId(self.LocalPS, self.ReceiverPlayerId)
        if self.Overlay_Eliminate then
            local ShowOverlayEliminate = self.bKilled and (not IsTeammate)
            self.Overlay_Eliminate:SetVisibility(ShowOverlayEliminate and SelfHitTestInvisible or Collapsed)
        end
    else
        if self.Overlay_Eliminate then
            self.Overlay_Eliminate:SetVisibility(Collapsed)
        end
    end
end


function EventFlowDetailTeam:UpdateText(TargetText,Str,Color)
    TargetText:SetText(Str)
    TargetText:SetColorAndOpacity(UIHelper.ToSlateColor_LC(Color))
end

function EventFlowDetailTeam:OnAnimationFinished(Animation)
    if Animation then
        self.IfPlayAnimation = false
    end
end

function EventFlowDetailTeam:OnAnimationStarted(Animation)

    if Animation then
        self.IfPlayAnimation = true
    end
end
-- 出场动画
function EventFlowDetailTeam:HideDetailData()

    if self.Root then
        local DistTextDir = UE.FVector2D(0)
        self.Root:SetRenderTranslation(DistTextDir)
    end
    self:SetVisibility(Collapsed)

end

function EventFlowDetailTeam:GetTargetColor(TargetTeamId,TargetTeamIndex)
    local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PC or not PC.PlayerState then
        return UIHelper.LinearColor.White
    end
    local SelfTeamId = PC.PlayerState:GetTeamInfo_Id()
    return SelfTeamId == TargetTeamId and MinimapHelper.GetTeamMemberColor(TargetTeamIndex) or UIHelper.LinearColor.White
end
-------------------------------------------- Callable ------------------------------------

return EventFlowDetailTeam