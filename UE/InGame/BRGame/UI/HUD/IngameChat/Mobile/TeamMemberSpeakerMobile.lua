local TeamMemberSpeakerMobile = Class("Common.Framework.UserWidget")

function TeamMemberSpeakerMobile:OnInit()
    print("TeamMemberSpeakerMobile >> OnInit self=",GetObjectName(self))
    self.TeammatePlayerID = -1
    self:RegistEvent()
    UserWidget.OnInit(self)
end

function TeamMemberSpeakerMobile:OnShow()
    self:RefreshAudioSlider()
    self:RefreshUI()
end

function TeamMemberSpeakerMobile:OnDestroy()
    print("TeamMemberSpeakerMobile >> OnDestroy self=",GetObjectName(self))
    self:UnRegistEvent()
    UserWidget.OnDestroy(self)
end

function TeamMemberSpeakerMobile:RegistEvent()
    self.Slider.OnValueChanged:Add(self,self.OnAudioSliderChange)
end

function TeamMemberSpeakerMobile:UnRegistEvent()
    self.Slider.OnValueChanged:Clear()
end


function TeamMemberSpeakerMobile:OnAudioSliderChange(InValue)
    local Value = math.tointeger(math.floor(InValue*100))
    UE.UGVoiceHelper.SetPlayerVolume(self.ThisPlayerID,Value)
    self.ProgressBar:SetPercent(InValue)
    self.Text_Percent:SetText(Value)
end

function TeamMemberSpeakerMobile:RefreshAudioSlider()
    self.Slider:SetValue(0.3)
    self:OnAudioSliderChange(0.3)
end



function TeamMemberSpeakerMobile:InitInitTeammate(InPlayerState)
    self.ThisPS= InPlayerState
    self.ThisPlayerID = self.ThisPS:GetPlayerId()
end


function TeamMemberSpeakerMobile:RefreshUI()
    if self.ThisPS and self.ThisPlayerID then
        local TeamNum = BattleUIHelper.GetTeamPos(self.ThisPS)
        self.Txt_TeamNum:SetText(TeamNum)
        local ImgColor = MinimapHelper.GetTeamMemberColor(TeamNum)
        self.Img_TeamColor:SetColorAndOpacity(ImgColor)

        local Volume = UE.UGVoiceHelper.GetPlayerVolume(self.ThisPlayerID)
        self.ProgressBar:SetPercent(Volume*0.01)
        self.Text_Percent:SetText(Volume)
        self.Slider:SetValue(Volume*0.01)
    end
end



return TeamMemberSpeakerMobile