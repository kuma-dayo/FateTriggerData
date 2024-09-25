--[[
    剧情表现对话界面 - 对话内容逻辑
]]

local class_name = "DialogContentLogic"
DialogContentLogic = DialogContentLogic or BaseClass(nil, class_name)


function DialogContentLogic:OnInit()
    self.InputFocus = true
end

function DialogContentLogic:OnShow()
end

function DialogContentLogic:OnHide()
end

function DialogContentLogic:UpdateUI(Param,FinishCallback)
    self.Param = Param
    self.FinishCallback = FinishCallback
    self.TextWithArrow = StringUtil.FormatSimple('{0}<widget src="W_TemaranNextIcon"></>',self.Param.DialogText)
    local SpeakerName = MvcEntry:GetCtrl(DialogSystemCtrl):GetPlayingStoryHeroName()
    self.View.Text_SpeakerName:SetText(SpeakerName)
    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:PlayTextShow()
end

function DialogContentLogic:PlayTextShow()
    self:CleanTimer()
    self.View.RichText_Dialog:SetText("")
    local AllText = self.Param.DialogText
    local TextLen = StringUtil.utf8StringLen(AllText)
    local Index = 1
    local SubTextLength = 0
    self.PlayTextTimer = self:InsertTimer(self.Param.PlaySpeed,function()
        local WordByte = string.byte(AllText, Index)
		local CharSize = StringUtil.utf8CharSize(WordByte)
        Index = Index + CharSize
        SubTextLength = SubTextLength + (CharSize>=3 and 2 or 1)
        local SubText =  string.sub(AllText,1,Index-1)
        self.View.RichText_Dialog:SetText(StringUtil.Format(SubText))
        if SubTextLength >= TextLen then
            self:CleanTimer()
            self:FinishPlaying()
        end
    end,true)
end

function DialogContentLogic:CleanTimer()
    if self.PlayTextTimer then
        self:RemoveTimer(self.PlayTextTimer)
        self.PlayTextTimer = nil
    end
end

function DialogContentLogic:ShowAllText()
    if self.PlayTextTimer then
        self:CleanTimer()
    end
    self:FinishPlaying()
end

function DialogContentLogic:FinishPlaying()
    self.View.RichText_Dialog:SetText(StringUtil.Format(self.TextWithArrow))
    if self.FinishCallback then
        self.FinishCallback()
    end
end

return DialogContentLogic
