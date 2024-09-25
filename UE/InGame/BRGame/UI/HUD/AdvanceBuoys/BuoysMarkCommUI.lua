
local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysCommUI"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local BuoysCommUI = require(ParentClassName)
local BuoysMarkCommUI = Class(ParentClassName)



function BuoysMarkCommUI:OnInit()
	print("BuoysMarkCommUI >> OnInit, ", GetObjectName(self))
	
	self.MsgList = {}

	--init也需要listen一下，不确定时序
	table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.PLAYER_PSTeamPos, Func = self.UpdateTeamPos,bCppMsg = true })

    self.GameTagSettings = UE.US1GameTagSettings.Get()

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

	--初始化MarkWideet2的TxtTips文本
	if self.MarkWidget2 and self.TxtTipsValue then self.MarkWidget2.TxtTips:SetText(StringUtil.Format(self.TxtTipsValue)) end
	--移动端隐藏PC提示
	if self.MarkWidget2 and BridgeHelper.IsMobilePlatform() then self.MarkWidget2.TrsOpMark:SetRenderOpacity(0) end
	BuoysCommUI.OnInit(self)

	-- 操作显示文本
	self.TxtOpList = {
		["MarkSystem_CancelMark"] = "", ["MarkSystem_CanBooker"] = "",
	}
	
	self:InitTxtOpList()
	self.bInitRangeAnimation = false
	if not self.bInitRangeAnimation then self:InitRangeAnimation() end
end

function BuoysMarkCommUI:OnDestroy()
	print("BuoysMarkCommUI >> OnDestroy ", GetObjectName(self))
	MsgHelper:UnregisterList(self, self.MsgList)
	if self.MarkWidgetAnimationArray then
		for _, AnimParams in pairs(self.MarkWidgetAnimationArray) do
			AnimParams.InAnimation:Clear()
			AnimParams.OutAnimation:Clear()
		end
	end
end

function BuoysCommUI:InitRangeAnimation()
	self.bInitRangeAnimation = true
	if self.MarkWidget2 then
		--信息动画
		local InfoAnim = UE.FMarkWidgetAnimationParams()
		InfoAnim.Show3DMarkRangeMode:Add("L1")
		InfoAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Common_Info_In)
		InfoAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Common_Info_Out)
		self.MarkWidgetAnimationArray:Add(InfoAnim)
	end
	if self.MarkWidget1 then
		--边缘箭头
		local ArrowAnim = UE.FMarkWidgetAnimationParams()
		ArrowAnim.Show3DMarkRangeMode:Add("Adsorb")
		ArrowAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Common_Arrow_In)
		ArrowAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Common_Arrow_Out)
		self.MarkWidgetAnimationArray:Add(ArrowAnim)
		--边缘文字图标
		local EdgeAnim = UE.FMarkWidgetAnimationParams()
		EdgeAnim.Show3DMarkRangeMode:Add("Default")
		EdgeAnim.Show3DMarkRangeMode:Add("Adsorb")
		EdgeAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Common_Edge_In)
		EdgeAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Common_Edge_Out)
		self.MarkWidgetAnimationArray:Add(EdgeAnim)
	end
end

function BuoysMarkCommUI:BPImpFunc_On3DMarkIconStartShowFrom3DMark(InTaskData)
	self.CurRefPS = InTaskData.Owner

	--并不能确定这里和rep的时序，需要listen一下
	table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.PLAYER_PSTeamPos, Func = self.UpdateTeamPos,bCppMsg = true})
	
	if self.CurRefPS then
		print("BuoysMarkCommUI >> BPImpFunc_On3DMarkIconStartShowFrom3DMark self.CurRefPS:", GetObjectName(self.CurRefPS), self.CurRefPS,  GetObjectName(self))
	end

	local PlayerName = "ErrorName"
	if CommonUtil.IsValid(self.CurRefPS) then
		--print("BuoysMarkCommUI >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark", GetObjectName(self), "self.CurRefPS is:", GetObjectName(self.CurRefPS))
		PlayerName = self.CurRefPS:GetPlayerName()
	end

	local MarkLogKey = InTaskData.ItemKey
	local LogPlayerName = self.bIfLocalMark and G_ConfigHelper:GetStrFromIngameStaticST("SD_Mark", "MarkLog_MySelf") or PlayerName

    self:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    if not self.LocalPC then
        self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    end

    if not self.LocalPC  then
        print("BuoysMarkCommUI >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark self.LocalPC is nil!", GetObjectName(self))
        return
    end



	local OpTipsParams = { bCanOpMark = false, OpTxtKey  = "MarkSystem_CancelMark" }
	if self.bIfLocalMark then
		OpTipsParams = { bCanOpMark = true, OpTxtKey  = "MarkSystem_CancelMark" }
    end

	--并不能确定这里和rep的时序
    self.CurTeamPos = BattleUIHelper.GetTeamPos(self.CurRefPS)
	if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor then
		self.TeamLinearColor  = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)
	end

	-- ToDo 观战的时候，切换观战对象的浮标时，也会创建这个光柱吗？
	if nil == self.bIfNotUpdateMapEffect or not self.bIfNotUpdateMapEffect then
		local BuoysSystem = UE.UBuoysMarkManagerSystem.GetBuoysMarkManagerSystem(self)
		if BuoysSystem and InTaskData.ItemKey == "MapMarkPoint" then
			BuoysSystem:BPImpEvent_UpdateQuickMarkEffects(self.CurRefPS, InTaskData.Position, self.TeamLinearColor, true)
		end
	end
	

    if self.Slot then
        self.Slot:SetZOrder(self.Zorder - self.CurTeamPos)
    end

	-- 预定玩家的名字
    --if self.TxtName then self.TxtName:SetVisibility(OpTipsParams.bCanOpMark and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible) end
	if self.MarkWidget2 then 
		if self.MarkWidget2.TxtName then
			self.MarkWidget2.TxtName:SetText(LogPlayerName)
			self.MarkWidget2.TxtName:SetVisibility(OpTipsParams.bCanOpMark and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible)
		end

		--self.MarkWidget2.TxtName:SetVisibility(OpTipsParams.bCanOpMark and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible) 
	end
	
    if self.TrsOpMark then self.TrsOpMark:SetVisibility(OpTipsParams.bCanOpMark and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed) end
	if self.MarkWidget2 then self.MarkWidget2.TrsOpMark:SetVisibility(OpTipsParams.bCanOpMark and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed) end
    
	if OpTipsParams.bCanOpMark and OpTipsParams.OpTxtKey then
		self:CheckTxtOpListKey(OpTipsParams.OpTxtKey)
		if self.TxtOpTips then self.TxtOpTips:SetText(StringUtil.Format(self.TxtOpList[OpTipsParams.OpTxtKey])) end
		if self.MarkWidget2 then self.MarkWidget2.TxtOpTips:SetText(StringUtil.Format(self.TxtOpList[OpTipsParams.OpTxtKey])) end
	end

	
    self:UpdateWidgetColor()

    local IfForceUpdate = InTaskData.TaskType == UE.EG3DMarkItemTaskAction.ForceUpdate

	-- 确保不是初始化浮标panel强制刷新导致的发消息
	if not IfForceUpdate then
		self:UpdateMarkLine(true)
		if self.MarkWidget1 then 
			self.MarkWidget1.VXV_Mark_YPos = self.CurLineLength
			print("buo>>self.CurLineLength: ", self.CurLineLength)
			self:VXE_HUD_Mark_Common_In() 
		end
		AdvanceMarkHelper.SendMarkLogHelper(self, MarkLogKey, LogPlayerName)
		if self.CurRefPS then
			MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Mark_Point, MarkLogKey, self.CurRefPS, false)
		end
	end

end

--通过TeamExInfo_Specific同步TeamPos
function BuoysMarkCommUI:UpdateTeamPos(OwnerPS,TeamExInfo)

	if self.CurRefPS ~= OwnerPS then
		return
	end

	print("BuoysMarkCommUI >> UpdateTeamPos", self.CurTeamPos)

	if not TeamExInfo then
		print("BuoysMarkCommUI >> TeamExInfo is null")
	end

	

	if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor then

		if TeamExInfo then
			self.CurTeamPos = TeamExInfo:GetPlayerSerialNumber()
			self.TeamLinearColor  = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)
		elseif OwnerPS then
			self.CurTeamPos = BattleUIHelper.GetTeamPos(OwnerPS)
			self.TeamLinearColor  = AdvanceMarkHelper.TeamPosColor:FindRef(OwnerPS)
		end
	end

	self:UpdateWidgetColor()
end

function BuoysMarkCommUI:BPImpFunc_On3DMarkIconRemoveFrom3DMark(InTaskData)
	if nil == self.bIfNotUpdateMapEffect or not self.bIfNotUpdateMapEffect then
		local BuoysSystem = UE.UBuoysMarkManagerSystem.GetBuoysMarkManagerSystem(self)
		if BuoysSystem and InTaskData.ItemKey == "MapMarkPoint" then
			BuoysSystem:BPImpEvent_UpdateQuickMarkEffects(self.CurRefPS, InTaskData.Position, self.TeamLinearColor, false)
		end
	end
	if self.MarkWidget1 then self:VXE_HUD_Mark_Common_Out() end


	if self.CurRefPS == self.LocalPS then
		local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()

		BlackBoardKeySelector.SelectedKeyName = "SelfCanelMark"
		local SelfCanelMark, SelfCanelMarkType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(InTaskData.OtherData, BlackBoardKeySelector)
		if SelfCanelMark and SelfCanelMarkType then
			MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Buoys_Remove, InTaskData.ItemKey, self.CurRefPS)
		end
	end

	MsgHelper:UnregisterList(self, self.MsgList)
end

-- 更新控件颜色
function BuoysMarkCommUI:UpdateWidgetColor(InNewLinearColor)
	
	if not self.NewSlateColor then
		self.NewSlateColor = UE.FSlateColor()
	end

	self.NewLinearColor = InNewLinearColor or self.TeamLinearColor

	self.ConnLineColor = self.NewLinearColor

	if not self.bIfSkipUpdateOridinaryColor then
		-- body
		if self.ImgConnPoint and self.ImgDir then
			self.ImgConnPoint:SetColorAndOpacity(self.ConnLineColor)
			self.ImgDir:SetColorAndOpacity(self.ConnLineColor)
		end
		if self.MarkWidget1 then
			self.MarkWidget1.ImgConnPoint:SetColorAndOpacity(self.ConnLineColor)
			self.MarkWidget1.ImgDir:SetColorAndOpacity(self.ConnLineColor)
			self.MarkWidget1.VX_Cirlce_Wave:SetColorAndOpacity(self.NewLinearColor)
		end
	end

	self.NewSlateColor.SpecifiedColor = self.NewLinearColor

	if not self.bIfSkipUpdateOridinaryColor then
		if self.MarkWidget2 then self.MarkWidget2.TxtTips:SetColorAndOpacity(self.NewSlateColor) end
		if self.TxtTips then self.TxtTips:SetColorAndOpacity(self.NewSlateColor) end
	end

	if self.MarkWidget2 then self.MarkWidget2.TxtName:SetColorAndOpacity(self.NewSlateColor) end
	if self.TxtName then self.TxtName:SetColorAndOpacity(self.NewSlateColor) end

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

	if self.VXV_PlayerColor then self.VXV_PlayerColor = self.NewLinearColor end
	

	--print("BuoysMarkSysPointItem", ">> UpdateWidgetColor, ...", GetObjectName(self))
end

return BuoysMarkCommUI