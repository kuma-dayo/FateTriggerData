--
-- 战斗界面 - 结算详情界面
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.011.9
--

local SettlementResultItem = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function SettlementResultItem:OnInit()

    -- self.MsgList = {
    --     { MsgName = GameDefine.MsgCpp.Statistic_RepDatasPS,	Func = self.OnUpdateStatistic,	bCppMsg = true,	WatchedObject = nil },
	-- }

	print("SettlementResultItem >> OnInit")
	if self.Animation_Temprory then
		self:PlayAnimation(self.Animation_Temprory)
		-- self:PlayAnimation(self.FadeAnim)
		print("SettlementResultItem >> Animation_Temprory")
	elseif self.FadeAnim then
		self:PlayAnimation(self.FadeAnim)
		print("SettlementResultItem >> FadeAnim")
	end
	self:VXE_Settlement_In()
	UserWidget.OnInit(self)
	self.SoundEventWhenShow=""
end

function SettlementResultItem:OnDestroy()

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------



return SettlementResultItem
