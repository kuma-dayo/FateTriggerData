
local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysCommUI"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local BuoysCommUI = require(ParentClassName)
local BuoysMarkClientUI = Class(ParentClassName)

BuoysMarkClientUI.SwicherMode = {ScreenCenter=0,Screen=1,ScreenEdge=2}
BuoysMarkClientUI.BuoysWidgets = { "ScreenCenter", "Screen", "ScreenEdge" }

function BuoysMarkClientUI:OnInit()
	print("BuoysMarkClientUI >> OnInit, ", GetObjectName(self))
	
    self.GameTagSettings = UE.US1GameTagSettings.Get()

	self.BgWidgetArr = { ScreenCenter = nil, Screen = nil, ScreenEdge = nil }
	self.IconWidgetArr = { ScreenCenter = nil, Screen = nil, ScreenEdge = nil }
	
	self.NewSlateColor = UE.FSlateColor()

	for index = 1, #BuoysMarkClientUI.BuoysWidgets do
		local WidgetStr = BuoysMarkClientUI.BuoysWidgets[index]
		if self[WidgetStr] then
			local BgWidget = self[WidgetStr]:GetChildAt(0)
			local IconWidget = self[WidgetStr]:GetChildAt(1)
			self.BgWidgetArr[WidgetStr] = BgWidget
			self.IconWidgetArr[WidgetStr] = IconWidget
        end
    end

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

	BuoysCommUI.OnInit(self)

	-- 操作显示文本
	self.TxtOpList = {
		["MarkSystem_CancelMark"] = "", ["MarkSystem_CanBooker"] = "",
	}
	
	self:InitTxtOpList()
end

function BuoysMarkClientUI:OnDestroy()
	print("BuoysMarkClientUI >> OnDestroy ", GetObjectName(self))
    
end

function BuoysMarkClientUI:BPImpFunc_On3DMarkIconStartShowFrom3DMark(InTaskData)
	self.CurRefPS = InTaskData.Owner

	local MarkLogKey = InTaskData.ItemKey

    self:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    if not self.LocalPC then
        self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    end

    if not self.LocalPC  then
        print("BuoysMarkClientUI >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark self.LocalPC is nil!", GetObjectName(self))
        return
    end

	local OpTipsParams = { bCanOpMark = false, OpTxtKey  = "MarkSystem_CancelMark" }
	if self.bIfLocalMark then
		OpTipsParams = { bCanOpMark = true, OpTxtKey  = "MarkSystem_CancelMark" }
    end

    self.CurTeamPos = BattleUIHelper.GetTeamPos(self.CurRefPS)
	if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor then
		self.TeamLinearColor  = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)
	end


    if self.Slot then
        self.Slot:SetZOrder(self.Zorder - self.CurTeamPos)
    end

	-- 预定玩家的名字
    self.TxtName:SetVisibility(OpTipsParams.bCanOpMark and
		UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible)
	
    self.TrsOpMark:SetVisibility(OpTipsParams.bCanOpMark and
		UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
    
	if OpTipsParams.bCanOpMark and OpTipsParams.OpTxtKey then
		self:CheckTxtOpListKey(OpTipsParams.OpTxtKey)
		self.TxtOpTips:SetText(self.TxtOpList[OpTipsParams.OpTxtKey])
	end

	
    self:UpdateWidgetColor()
end

function BuoysMarkClientUI:BPImpFunc_On3DMarkIconRemoveFrom3DMark(InTaskData)

end

-- 更新控件颜色
function BuoysMarkClientUI:UpdateWidgetColor(InNewLinearColor)
	
	if not self.NewSlateColor then
		self.NewSlateColor = UE.FSlateColor()
	end

	self.NewLinearColor = InNewLinearColor or self.TeamLinearColor

	self.ConnLineColor = self.NewLinearColor

	if not self.bIfSkipUpdateOridinaryColor then
		-- body
		self.ImgConnPoint:SetColorAndOpacity(self.ConnLineColor)
		self.ImgDir:SetColorAndOpacity(self.ConnLineColor)
	end

	self.NewSlateColor.SpecifiedColor = self.NewLinearColor

	if not self.bIfSkipUpdateOridinaryColor then
		self.TxtTips:SetColorAndOpacity(self.NewSlateColor)
	end

	self.TxtName:SetColorAndOpacity(self.NewSlateColor)

	if not self.NotNeedUpdateIconAndBgColor or false == self.NotNeedUpdateIconAndBgColor then
		if self.BgWidgetArr then
			for _, value in pairs(self.BgWidgetArr) do
				value:SetColorAndOpacity(self.NewLinearColor)
			end
		end
	
		if self.IconWidgetArr then
			for _, value in pairs(self.IconWidgetArr) do
				value:SetColorAndOpacity(self.NewLinearColor)
			end
		end
	end

	--print("BuoysMarkSysPointItem", ">> UpdateWidgetColor, ...", GetObjectName(self))
end

return BuoysMarkClientUI