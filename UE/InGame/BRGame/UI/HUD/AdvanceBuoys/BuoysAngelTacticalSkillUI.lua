
local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysCommUI"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local BuoysCommUI = require(ParentClassName)
local BuoysAngelTacticalSkillUI = Class(ParentClassName)

function BuoysAngelTacticalSkillUI:BPImpFunc_On3DMarkIconStartShowFrom3DMark(InTaskData)
	print("BuoysTeammateChipsUI:BPImpFunc_On3DMarkIconStartShowFrom3DMark")
	if InTaskData.WatchedObj then
		self.CurRefPS = InTaskData.WatchedObj.PlayerState
		if self.CurRefPS then
			self.PlayerArmorBar:InitRefPS(self.CurRefPS)
			self.PlayerHealthBar:InitRefPS(self.CurRefPS)
		end
	end
end

return BuoysAngelTacticalSkillUI

