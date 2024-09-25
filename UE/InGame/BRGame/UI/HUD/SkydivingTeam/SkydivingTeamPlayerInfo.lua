require "UnLua"

local SkydivingTeamPlayerInfo = Class("Common.Framework.UserWidget")

function SkydivingTeamPlayerInfo:OnInit()
    self.CacheUIManager = UE.UGUIManager.GetUIManager(self)
    if self.CacheUIManager then
        self.SkydivingTeamVM = self.CacheUIManager:GetViewModelByName("SkydivingTeam")
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("SkydivingTeamVMState",{self, self.SkydivingTeamVMStateChange})
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("IsShowSkydivingTeamUI",{self, self.OnIsShowSkydivingTeamUIChange})
    end
    self.CacheSelfVisibility = false
    self:UpdateSelfVisibility(self.SkydivingTeamVM)
    UserWidget.OnInit(self)
end

function SkydivingTeamPlayerInfo:OnDestroy()
    if self.SkydivingTeamVM then
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("SkydivingTeamVMState",{self, self.SkydivingTeamVMStateChange})
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("IsShowSkydivingTeamUI",{self, self.OnIsShowSkydivingTeamUIChange})
    end

    UserWidget.OnDestroy(self)
end

function SkydivingTeamPlayerInfo:OnShow(InContext, InGenericBlackboard)
    self.CurrentPS = InContext

    self:UpdateSkydivingTeamPlayerInfo(self.CurrentPS, self.SkydivingTeamVM, self.SkydivingTeamVM.SkydivingTeamVMState)
end

function SkydivingTeamPlayerInfo:SkydivingTeamVMStateChange(VM, Field)
    self:UpdateSkydivingTeamPlayerInfo(self.CurrentPS, VM, VM.SkydivingTeamVMState)
end

function SkydivingTeamPlayerInfo:UpdateSkydivingTeamPlayerInfo(InPS, VM, State)
    if not InPS then
        return
    end

    local CurrentPlayerId = InPS:GetPlayerId()
    if not CurrentPlayerId then
        return
    end

    local CurrentTeamLeaderId = VM:GetCurrentTeamLeader()
    if CurrentPlayerId == CurrentTeamLeaderId then
        self:SkydivingTeamPlayerInfo_LocalPlayerIsTeamLeader()
    else
        local IsFollower = VM:IsFollower(CurrentPlayerId)
        if IsFollower then
            self:SkydivingTeamPlayerInfo_LocalPlayerIsTeammate(CurrentTeamLeaderId)
        else
            self:SkydivingTeamPlayerInfo_NoTeamLeader()
        end
    end

end

function SkydivingTeamPlayerInfo:OnIsShowSkydivingTeamUIChange(VM, Field)
    if VM then
        self:UpdateSelfVisibility(VM)
    end
end

function SkydivingTeamPlayerInfo:UpdateSelfVisibility(VM)
    if VM.IsShowSkydivingTeamUI then
        if self.CacheSelfVisibility then
            self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function SkydivingTeamPlayerInfo:SkydivingTeamPlayerInfo_NoTeamLeader()
    self.CacheSelfVisibility = false
    self:UpdateSelfVisibility(self.SkydivingTeamVM)
    self.Image_Teammate:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Image_TeamLeader:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function SkydivingTeamPlayerInfo:SkydivingTeamPlayerInfo_LocalPlayerIsTeamLeader()
    self.CacheSelfVisibility = true
    self:UpdateSelfVisibility(self.SkydivingTeamVM)
    self.Image_Teammate:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Image_TeamLeader:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
end

function SkydivingTeamPlayerInfo:SkydivingTeamPlayerInfo_LocalPlayerIsTeammate(TeamLeaderId)
    self.CacheSelfVisibility = true
    self:UpdateSelfVisibility(self.SkydivingTeamVM)
    self.Image_Teammate:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.Image_TeamLeader:SetVisibility(UE.ESlateVisibility.Collapsed)

    local CurrentPS = UE.AGeGameState.GetPlayerStateBy(self, TeamLeaderId)
    if CurrentPS then
        local CurTeamPos = BattleUIHelper.GetTeamPos(CurrentPS)
        local ImgColor = MinimapHelper.GetTeamMemberColor(CurTeamPos)
        self.Image_Teammate:SetColorAndOpacity(ImgColor)
    end
end


return SkydivingTeamPlayerInfo