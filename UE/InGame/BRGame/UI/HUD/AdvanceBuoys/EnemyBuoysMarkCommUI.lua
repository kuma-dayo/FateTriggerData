

local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysMarkCommUI"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local BuoysMarkCommUI = require(ParentClassName)
local EnemyBuoysMarkCommUI = Class(ParentClassName)


function EnemyBuoysMarkCommUI:OnInit()
	print("EnemyBuoysMarkCommUI >> OnInit, ", GetObjectName(self))
	BuoysMarkCommUI.OnInit(self)
	--self.LastMode = 0
	self.bIfSkipUpdateOridinaryColor = true
	--移动端隐藏PC提示
	if self.TrsOpMark and BridgeHelper.IsMobilePlatform() then self.TrsOpMark:SetRenderOpacity(0) end

	-- 操作显示文本
	self.TxtOpList = {
		["MarkSystem_CancelMark"] = "", ["MarkSystem_CanAccept"] = "",
		["MarkSystem_AlreadyAccept"] = "",
	}
	self:InitTxtOpList()
	self.OpTipsParams = { bCanOpMark = false, OpTxtKey  = "MarkSystem_CancelMark" }
	-- 临时处理编辑器报错，等本地复现了，用正是方案再修改
	AdvanceMarkHelper.InitData(self)
	
	self.bInitRangeAnimation = false
	if not self.bInitRangeAnimation then self:InitRangeAnimation() end
end

function EnemyBuoysMarkCommUI:OnDestroy()
	print("EnemyBuoysMarkCommUI >> OnDestroy ", GetObjectName(self))
    
end

function EnemyBuoysMarkCommUI:InitRangeAnimation()
	self.bInitRangeAnimation = true
	-- 标记信息动画
	local InfoAnim = UE.FMarkWidgetAnimationParams()
	InfoAnim.Show3DMarkRangeMode:Add("L1")
	InfoAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Enemy_Info_In)
	InfoAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Enemy_Info_Out)
	self.MarkWidgetAnimationArray:Add(InfoAnim)
	-- 边缘距离文字动画
	local EdgeAnim = UE.FMarkWidgetAnimationParams()
	EdgeAnim.Show3DMarkRangeMode:Add("Default")
	EdgeAnim.Show3DMarkRangeMode:Add("Adsorb")
	EdgeAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Enemy_Edge_In)
	EdgeAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Enemy_Edge_Out)
	self.MarkWidgetAnimationArray:Add(EdgeAnim)
	-- 边缘箭头动画
	local ArrowAnim = UE.FMarkWidgetAnimationParams()
	ArrowAnim.Show3DMarkRangeMode:Add("Adsorb")
	ArrowAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Enemy_Arrow_In)
	ArrowAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Enemy_Arrow_Out)
	self.MarkWidgetAnimationArray:Add(ArrowAnim)
end

function EnemyBuoysMarkCommUI:SomeOneAccept(InTaskData)
	
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


function EnemyBuoysMarkCommUI:BPImpFunc_On3DMarkIconStartShowFrom3DMark(InTaskData)
	self.CurRefPS = InTaskData.Owner

	--print("EnemyBuoysMarkCommUI >> BPImpFunc_On3DMarkIconStartShowFrom3DMark self.CurRefPS:", GetObjectName(self.CurRefPS), self.CurRefPS, GetObjectName(self))

	local PlayerName = "ErrorName"
	if CommonUtil.IsValid(self.CurRefPS) then
		PlayerName = self.CurRefPS:GetPlayerName()
	end

	self.MarkLogKey = InTaskData.ItemKey
	self.LogPlayerName = self.bIfLocalMark and G_ConfigHelper:GetStrFromIngameStaticST("SD_Mark", "MarkLog_MySelf") or PlayerName

	self.CurRefPS = InTaskData.Owner

    self:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    if not self.LocalPC then
        self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    end

    if not self.LocalPC  then
        print("EnemyBuoysMarkCommUI >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark self.LocalPC is nil!", GetObjectName(self))
        return
    end
	


    self.CurTeamPos = BattleUIHelper.GetTeamPos(self.CurRefPS)
	if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor then
		self.TeamLinearColor  = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)
	end

	-- ToDo 观战的时候，切换观战对象的浮标时，也会创建这个光柱吗？
	if nil == self.bIfNotUpdateMapEffect or not self.bIfNotUpdateMapEffect then
		local BuoysSystem = UE.UBuoysMarkManagerSystem.GetBuoysMarkManagerSystem(self)
		if BuoysSystem then
			--BuoysSystem:BPImpEvent_UpdateQuickMarkEffects(self.CurRefPS, InTaskData.Position, self.TeamLinearColor, true)
		end
	end
	

    if self.Slot then
        self.Slot:SetZOrder(self.Zorder - self.CurTeamPos)
    end
    
    self:UpdateWidgetColor()

    self.IfForceUpdate = InTaskData.TaskType == UE.EG3DMarkItemTaskAction.ForceUpdate

	if self.bIfLocalMark then
		self.OpTipsParams = { bCanOpMark = true, OpTxtKey  = "MarkSystem_CancelMark" }
    end

	self:SomeOneAccept(InTaskData)

	-- 预定玩家的名字
    --self.TxtName:SetVisibility(self.OpTipsParams.bCanOpMark and
		--UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible)
	
    self.TrsOpMark:SetVisibility(self.OpTipsParams.bCanOpMark and
		UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
    
	if self.OpTipsParams.bCanOpMark and self.OpTipsParams.OpTxtKey then
		self:CheckTxtOpListKey(self.OpTipsParams.OpTxtKey)
		self.TxtOpTips:SetText(self.TxtOpList[self.OpTipsParams.OpTxtKey])
	end

	
	-- 确保不是初始化浮标panel强制刷新导致的发消息
	if not self.IfForceUpdate then
		self:UpdateMarkLine(true)
		self.VXV_Mark_YPos = self.CurLineLength

		-- 不是赞同敌人才播放动效
		if not self.AcceptPS then
			-- body
			self:VXE_HUD_Mark_Enemy_In()
		end
		if AdvanceMarkHelper then
			if self.AcceptPS and not self.IfAccepted then -- 取消赞同不发日志
			else
				local ColorStr = UE.UKismetMathLibrary.ToHex_LinearColor(self.TeamLinearColor)
				AdvanceMarkHelper.SendMarkLogHelper(self, self.MarkLogKey, self.LogPlayerName, ("#" .. ColorStr))
			end
			
		end	
		if self.CurRefPS then
			MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Mark_Point, self.MarkLogKey, self.CurRefPS, false)
		end
	end
end

function EnemyBuoysMarkCommUI:BPImpFunc_On3DMarkIconRemoveFrom3DMark(InTaskData)
	if nil == self.bIfNotUpdateMapEffect or not self.bIfNotUpdateMapEffect then
		local BuoysSystem = UE.UBuoysMarkManagerSystem.GetBuoysMarkManagerSystem(self)
		if BuoysSystem then
			--BuoysSystem:BPImpEvent_UpdateQuickMarkEffects(self.CurRefPS, InTaskData.Position, self.TeamLinearColor, false)
		end
	end
	self:VXE_HUD_Mark_Enemy_Out()

	if self.CurRefPS == self.LocalPS then
		local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()

		BlackBoardKeySelector.SelectedKeyName = "SelfCanelMark"
		local SelfCanelMark, SelfCanelMarkType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(InTaskData.OtherData, BlackBoardKeySelector)
		if SelfCanelMark and SelfCanelMarkType then
			MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Buoys_Remove, InTaskData.ItemKey, self.CurRefPS)
		end
	end
end

return EnemyBuoysMarkCommUI