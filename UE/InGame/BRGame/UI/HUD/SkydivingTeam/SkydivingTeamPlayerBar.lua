require "UnLua"
require "InGame.BRGame.GameDefine"

local SkydivingTeamPlayerBar = Class("Common.Framework.UserWidget")

function SkydivingTeamPlayerBar:OnInit()
    self.BarBtn.OnClicked:Add(self, self.OnClickedBarBtn)


    UserWidget.OnInit(self)
end

function SkydivingTeamPlayerBar:OnDestroy()
    self.BarBtn.OnClicked:Clear()


    UserWidget.OnDestroy(self)
end


function SkydivingTeamPlayerBar:OnClickedBarBtn()
    self.ChooseOnePlayerId:Broadcast(self.CurrentPlayerId)
end

function SkydivingTeamPlayerBar:SetPlayerBarDisplayInfo(PlayerId)
    self.CurrentPlayerId = PlayerId

    local CurrentPS = UE.AGeGameState.GetPlayerStateBy(self, PlayerId)
    if not CurrentPS then
        return
    end

    -- 设置颜色
    self:SetColorAndNumText(CurrentPS)

    -- 名字
    self:SetPlayerName(CurrentPS)

    -- 设置头像
    local IsSetIconSucceed = false;
    local RefPawn = UE.UPlayerStatics.GetPSPlayerPawn(CurrentPS)
    if RefPawn then
        -- Icon
        local PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnData(RefPawn)
        if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
            self:SetPlayerIcon(PawnConfig.Icon)
            IsSetIconSucceed = true
        end
    end

    if not IsSetIconSucceed then
        -- 设置默认头像
        self:SetPlayerIcon(nil)
    end
end

function SkydivingTeamPlayerBar:SetPlayerIcon(InIcon)
    if InIcon then
        self.PlayerIcon:SetBrushFromSoftTexture(InIcon)
        self.WidgetSwitcherIcon:SetActiveWidgetIndex(0)
    else
        -- 默认头像（无英雄头像）
        self.WidgetSwitcherIcon:SetActiveWidgetIndex(1)
    end
end

function SkydivingTeamPlayerBar:SetColorAndNumText(InPlayerState)
    if InPlayerState then
        -- 设置颜色
        local CurTeamPos = BattleUIHelper.GetTeamPos(InPlayerState)
        local ImgColor = MinimapHelper.GetTeamMemberColor(CurTeamPos)
        self.ImgBgNum:SetColorAndOpacity(ImgColor)

        local TextColor = UE.FSlateColor()
        TextColor.SpecifiedColor = ImgColor
        self.Text_TeamPos:SetColorAndOpacity(TextColor)
        
        self.Text_TeamPos:SetText(tostring(CurTeamPos))
    end
end

function SkydivingTeamPlayerBar:SetPlayerName(InPS)
    local CurrentName = InPS:GetPlayerName()
    self.PlayerName_Normal:SetText(CurrentName)
    self.PlayerName_Hover:SetText(CurrentName)
    self.PlayerName_Click:SetText(CurrentName)
end

return SkydivingTeamPlayerBar

