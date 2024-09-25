
local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysMarkCommUI"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local BuoysCommUI = require(ParentClassName)
local BuoysMarkPoint = Class(ParentClassName)



function BuoysMarkPoint:OnInit()
	print("BuoysMarkPoint >> OnInit, ", GetObjectName(self))
	
    self.GameTagSettings = UE.US1GameTagSettings.Get()
	BuoysCommUI.OnInit(self)

    -- 操作显示文本
	self.TxtOpList = {
		["MarkSystem_CancelMark"] = "", ["MarkSystem_CanAccept"] = "",
		["MarkSystem_AlreadyAccept"] = "",
	}
	self:InitTxtOpList()

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.DistTxtOffset = self.DistTxtOffset or UE.FVector2D(50, 40)

	--初始化MarkWideet2的TxtTips文本
	if self.MarkWidget2 and self.TxtTipsValue then self.MarkWidget2.TxtTips:SetText(StringUtil.Format(self.TxtTipsValue)) end
	--移动端隐藏PC提示
	if self.MarkWidget2 and BridgeHelper.IsMobilePlatform() then self.MarkWidget2.TrsOpMark:SetRenderOpacity(0) end

	self.bInitRangeAnimation = false
	if not self.bInitRangeAnimation then self:InitRangeAnimation() end
end

function BuoysMarkPoint:OnDestroy()
	print("BuoysMarkPoint >> OnDestroy ", GetObjectName(self))
	if self.MarkWidgetAnimationArray then
		for _, AnimParams in pairs(self.MarkWidgetAnimationArray) do
			AnimParams.InAnimation:Clear()
			AnimParams.OutAnimation:Clear()
		end
	end
end

function BuoysMarkPoint:InitRangeAnimation()
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

function BuoysMarkPoint:SomeOneAccept(InTaskData)
	
	-- 有人赞同，需要更新日志
	if self.AcceptPS and self.IfAccepted then
		self.LogPlayerName = not self.IfSelfAccepted and self.AcceptPS:GetPlayerName() or G_ConfigHelper:GetStrFromIngameStaticST("SD_Mark", "MarkLog_MySelf")

		if not string.find( self.MarkLogKey, "Accept")  then
			-- body
			self.MarkLogKey = self.MarkLogKey.."Accept"
		end
	end

	-- 自己赞同的
	if self.IfSelfAccepted then
		self.OpTipsParams = { bCanOpMark = true, OpTxtKey  = "MarkSystem_AlreadyAccept" }
	else
		-- 只要不是自己标记的，就算被别人赞同了，也可以赞同
		if not self.bIfLocalMark then
			self.OpTipsParams = { bCanOpMark = true, OpTxtKey  = "MarkSystem_CanAccept" }
		end
	end
end


function BuoysMarkPoint:BPImpFunc_On3DMarkIconStartShowFrom3DMark(InTaskData)
	self.CurRefPS = InTaskData.Owner

	--print("BuoysMarkPoint >> BPImpFunc_On3DMarkIconStartShowFrom3DMark self.CurRefPS:", GetObjectName(self.CurRefPS), self.CurRefPS,  GetObjectName(self))

	local PlayerName = "ErrorName"
	if CommonUtil.IsValid(self.CurRefPS) then
		--print("BuoysMarkPoint >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark", GetObjectName(self), "self.CurRefPS is:", GetObjectName(self.CurRefPS))
		PlayerName = self.CurRefPS:GetPlayerName()
	end

	self.MarkLogKey = InTaskData.ItemKey
	self.LogPlayerName = self.bIfLocalMark and G_ConfigHelper:GetStrFromIngameStaticST("SD_Mark", "MarkLog_MySelf") or PlayerName

    self:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    if not self.LocalPC then
        self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    end

    if not self.LocalPC  then
        print("BuoysMarkPoint >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark self.LocalPC is nil!", GetObjectName(self))
        return
    end
	

	
	self.OpTipsParams = { bCanOpMark = false, OpTxtKey  = "MarkSystem_CancelMark" }
	if self.bIfLocalMark then
		self.OpTipsParams = { bCanOpMark = true, OpTxtKey  = "MarkSystem_CancelMark" }
    end

    self.CurTeamPos = BattleUIHelper.GetTeamPos(self.CurRefPS)
	if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor then
		self.TeamLinearColor  = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)

	else
		print("BuoysMarkPoint >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark AdvanceMarkHelper is nil!")
	end
	

	-- ToDo 观战的时候，切换观战对象的浮标时，也会创建这个光柱吗？
	if nil == self.bIfNotUpdateMapEffect or not self.bIfNotUpdateMapEffect then
		local BuoysSystem = UE.UBuoysMarkManagerSystem.GetBuoysMarkManagerSystem(self)
		if BuoysSystem then
			BuoysSystem:BPImpEvent_UpdateQuickMarkEffects(self.CurRefPS, InTaskData.Position, self.TeamLinearColor, true)
		end
	end
	

    if self.Slot then
        self.Slot:SetZOrder(self.Zorder - self.CurTeamPos)
    end


	
    self:UpdateWidgetColor()

    self.IfForceUpdate = InTaskData.TaskType == UE.EG3DMarkItemTaskAction.ForceUpdate

	self:SomeOneAccept(InTaskData)

	-- 预定玩家的名字
	if self.TxtName then self.TxtName:SetVisibility(self.OpTipsParams.bCanOpMark and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible) end
	if self.MarkWidget2 then self.MarkWidget2.TxtName:SetVisibility(self.OpTipsParams.bCanOpMark and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible) end
		
	if self.TrsOpMark then self.TrsOpMark:SetVisibility(self.OpTipsParams.bCanOpMark and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed) end
	if self.MarkWidget2 then self.MarkWidget2.TrsOpMark:SetVisibility(self.OpTipsParams.bCanOpMark and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed) end
		
	


	if self.OpTipsParams.bCanOpMark and self.OpTipsParams.OpTxtKey then
		self:CheckTxtOpListKey(self.OpTipsParams.OpTxtKey)
		if self.TxtOpTips then self.TxtOpTips:SetText(StringUtil.Format(self.TxtOpList[self.OpTipsParams.OpTxtKey])) end
		if self.MarkWidget2 then self.MarkWidget2.TxtOpTips:SetText(StringUtil.Format(self.TxtOpList[self.OpTipsParams.OpTxtKey])) end
	end


	-- 确保不是初始化浮标panel强制刷新导致的发消息
	if not self.IfForceUpdate then
		self:UpdateMarkLine(true)
		if self.MarkWidget1 then 
			self.MarkWidget1.VXV_Mark_YPos = self.CurLineLength
			print("buo>>self.CurLineLength: ", self.CurLineLength)
			self:VXE_HUD_Mark_Common_In() 
		end
		if self.AcceptPS and not self.IfAccepted then -- 取消赞同不发日志
		else
			if AdvanceMarkHelper then
				local ColorStr = UE.UKismetMathLibrary.ToHex_LinearColor(self.TeamLinearColor)
				AdvanceMarkHelper.SendMarkLogHelper(self, self.MarkLogKey, self.LogPlayerName, ("#" .. ColorStr))
			else
				print("BuoysMarkPoint >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark AdvanceMarkHelper is nil!")
			end
		end
		
		self.LastAccept = self.IfAccepted
		if self.CurRefPS then
			MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Mark_Point, self.MarkLogKey, self.CurRefPS, false)
		end
	end

end

function BuoysMarkPoint:BPImpFunc_On3DMarkIconRemoveFrom3DMark(InTaskData)
	if nil == self.bIfNotUpdateMapEffect or not self.bIfNotUpdateMapEffect then
		local BuoysSystem = UE.UBuoysMarkManagerSystem.GetBuoysMarkManagerSystem(self)
		if BuoysSystem then
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
end

-- 更新控件颜色
function BuoysMarkPoint:UpdateWidgetColor(InNewLinearColor)
	
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

return BuoysMarkPoint