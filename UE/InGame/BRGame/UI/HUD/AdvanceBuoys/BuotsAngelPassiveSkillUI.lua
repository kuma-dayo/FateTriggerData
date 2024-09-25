
local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysCommUI"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local BuoysCommUI = require(ParentClassName)
local BuotsAngelPassiveSkillUI = Class(ParentClassName)

function BuotsAngelPassiveSkillUI:BPImpFunc_On3DMarkIconStartShowFrom3DMark(InTaskData)
	if InTaskData.WatchedObj then
		self.CurRefPS = InTaskData.WatchedObj.PlayerState
		if self.CurRefPS then
            MsgHelper:UnregisterList(self, self.MsgList or {})
            self.MsgList = { { MsgName = GameDefine.MsgCpp.UISync_UpdateOnDead,       Func = self.UpdateDeadInfo,     bCppMsg = true, WatchedObject = self.CurRefPS }, }
            MsgHelper:RegisterList(self, self.MsgList)
		end
	end
end

function BuotsAngelPassiveSkillUI:UpdateDeadInfo(InDeadInfo)
    if InDeadInfo.bIsDead then
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    end
end

return BuotsAngelPassiveSkillUI