
local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysCommUI"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local BuoysCommUI = require(ParentClassName)
local BuoysTeammateChipsUI = Class(ParentClassName)

function BuoysTeammateChipsUI:BPImpFunc_On3DMarkIconStartShowFrom3DMark(InTaskData)
	print("BuoysTeamPlayerInfo:BPImpFunc_On3DMarkIconStartShowFrom3DMark")
	if InTaskData.WatchedObj then
		self.CurRefPS = InTaskData.WatchedObj.PlayerState
		if self.CurRefPS then
			self.ScreenArmorBar:InitRefPS(self.CurRefPS)
			self.ScreenHealthBar:InitRefPS(self.CurRefPS)
		end
	end
end

return BuoysTeammateChipsUI

