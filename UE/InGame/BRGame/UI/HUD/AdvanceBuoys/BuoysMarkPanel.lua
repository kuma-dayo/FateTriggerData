local BuoysMarkPanel = Class("Common.Framework.UserWidget")

function BuoysMarkPanel:OnInit()
    print("BuoysMarkPanel >> OnInit", GetObjectName(self))
    UserWidget.OnInit(self)
end


function BuoysMarkPanel:OnShow()
   -- 绑定队伍消息数据
   if (not self.MsgList_Team) then
    self.MsgList_Team = {
        { MsgName = GameDefine.MsgCpp.MarkSystem_HitTraceFail,		Func = self.OnMarkSystemHitTraceFail,	bCppMsg = true, WatchedObject = nil },
    }
    MsgHelper:RegisterList(self, self.MsgList_Team)
end

end

function BuoysMarkPanel:OnMarkSystemHitTraceFail(InLocalPS, InTraceDistance)
    local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "MarkSystem_TraceFail")
	local TxtFormat = TextStr or ">>>>>> Trace Fail %d m <<<<<<<"
	local NewTxt = string.format(TxtFormat, math.floor(InTraceDistance * 0.01))
	local InParamerters = {
		bEnable = true, Text = NewTxt, --Time = xxx
	}
	--MsgHelper:Send(InLocalPS, GameDefine.Msg.PLAYER_GenericFeedback, InParamerters)
	UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("Generic.FeedbackTips",-1,UE.FGenericBlackboardContainer(),self.Owner,StringUtil.ConvertString2FText(NewTxt))
end

function BuoysMarkPanel:OnClose()
    MsgHelper:UnregisterList(self, self.MsgList_Team or {})
end

return BuoysMarkPanel
