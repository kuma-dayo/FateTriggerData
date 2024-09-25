local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysCommUI"
local BuoysCommUI = require(ParentClassName)
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")
local BuoysWeaponItem = Class(ParentClassName)


function BuoysWeaponItem:OnInit()
	print("BuoysWeaponItem >> OnInit, ", GetObjectName(self))

    self.GameTagSettings = UE.US1GameTagSettings.Get()

    local BuoysWidgets = { "ScreenCenter", "Screen", "ScreenEdge" }

	self.BgWidgetArr = { ScreenCenter = nil, Screen = nil, ScreenEdge = nil }
	self.IconWidgetArr = { ScreenCenter = nil, Screen = nil, ScreenEdge = nil }
	self.NewSlateColor = UE.FSlateColor()
	self.CurTeamSlateColor = UE.FSlateColor()


    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	if self.LocalPC and self.TeamColor then
		local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
		if LocalPS then
			local CurTeamPos = BattleUIHelper.GetTeamPos(LocalPS)
			self.TeamColor = MinimapHelper.GetTeamMemberColor(CurTeamPos)
		end
	end

	--移动端隐藏PC提示
	if self.MarkWidget2 and BridgeHelper.IsMobilePlatform() then 
		self.MarkWidget2.TrsOpMark:SetRenderOpacity(0) 
	end
	BuoysCommUI.OnInit(self)

	for index = 1, #BuoysWidgets do
		local WidgetStr = BuoysWidgets[index]
		if self[WidgetStr] then
			local BgWidget = self[WidgetStr]:GetChildAt(0)
			local IconWidget = self[WidgetStr]:GetChildAt(2)
			self.BgWidgetArr[WidgetStr] = BgWidget
			self.IconWidgetArr[WidgetStr] = IconWidget
        end
    end
	-- 操作显示文本
	self.TxtOpList = {
		["MarkSystem_CancelMark"] = "", ["MarkSystem_CanBooker"] = "",
		["MarkSystem_CancelBooker"] = "", ["MarkSystem_AlreadyBooker"] = "",
	}
	
	self:InitTxtOpList()
	self.bInitRangeAnimation = false
	if not self.bInitRangeAnimation then self:InitRangeAnimation() end
end

function BuoysWeaponItem:OnDestroy()
	print("BuoysWeaponItem >> OnDestroy ", GetObjectName(self))
	if self.MarkWidgetAnimationArray then
		for _, AnimParams in pairs(self.MarkWidgetAnimationArray) do
			AnimParams.InAnimation:Clear()
			AnimParams.OutAnimation:Clear()
		end
	end
end

function BuoysWeaponItem:InitRangeAnimation()
	self.bInitRangeAnimation = true
	-- 边缘距离文字动画
	local SideAnim = UE.FMarkWidgetAnimationParams()
	SideAnim.Show3DMarkRangeMode:Add("Default")
	SideAnim.Show3DMarkRangeMode:Add("Adsorb")
	SideAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Weapon_Edge_In)
	SideAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Weapon_Edge_Out)
	-- 边缘箭头动画
	SideAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Weapon_Arrow_In)
	SideAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Weapon_Arrow_Out)
	--边缘中心图标变大动画
	SideAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Weapon_Trans_IconIn)
	SideAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Weapon_Trans_IconOut)
	self.MarkWidgetAnimationArray:Add(SideAnim)
	--信息显示动画
	if self.MarkWidget2 then
		local InfoAnim = UE.FMarkWidgetAnimationParams()
		InfoAnim.Show3DMarkRangeMode:Add("L1")
		InfoAnim.InAnimation:Add(self, self.VXE_HUD_Mark_Weapon_Trans_In)
		InfoAnim.OutAnimation:Add(self, self.VXE_HUD_Mark_Weapon_Trans_Out)
		self.MarkWidgetAnimationArray:Add(InfoAnim)
	end
end

function BuoysWeaponItem:BPImpFunc_On3DMarkIconStartShowFrom3DMark(InTaskData)

	local MarkLogKey = InTaskData.ItemKey
	local LogPlayerName
	local QualityLevel = 0

	local bGameState = InTaskData.Owner.GetPlayerName
	if bGameState then
    	self.CurRefPS = InTaskData.Owner
	else
		self.CurRefPS = nil
	end

	--print("BuoysWeaponItem >> BPImpFunc_On3DMarkIconStartShowFrom3DMark self.CurRefPS:", GetObjectName(self.CurRefPS), self.CurRefPS, GetObjectName(self))

	if CommonUtil.IsValid(self.CurRefPS) then
		if self.bIfLocalMark then 
			LogPlayerName = G_ConfigHelper:GetStrFromIngameStaticST("SD_Mark", "MarkLog_MySelf") 
		else
			if bGameState then LogPlayerName = self.CurRefPS:GetPlayerName() end
		end
	end

    self:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    if not self.LocalPC then
        self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    end

    if not self.LocalPC  then
        print("BuoysWeaponItem >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark self.LocalPC is nil!", GetObjectName(self))
        return
    end

	if bGameState then
    	self.CurTeamPos = BattleUIHelper.GetTeamPos(self.CurRefPS)
	end


    if self.Slot then
        self.Slot:SetZOrder(self.Zorder - self.CurTeamPos)
    end


	local LocalPCId = self.LocalPC:GetPlayerId()
    local LocalPS = self.LocalPC and self.LocalPC.PlayerState
    local bIfLocalMark = self.CurRefPS == LocalPS
    local LocalGetPlayerId = LocalPS and LocalPS:GetPlayerId()
	local LocalPlayerId = LocalPS and LocalPS.PlayerId
	local AdcComp  = UE.UAdvanceMarkBussinessComponent.GetAdvanceMarkBussinessComponentClientOnly(self)
	local AdcPS
	local AdcPC
	local AdcPSPlayerId

	if AdcComp then
		AdcPS = AdcComp:GetLocalPCPS()
		AdcPSPlayerId = AdcPS and AdcPS.PlayerId
		AdcPC = AdcComp:GetLocalPC()
	end
	
	--print("BuoysWeaponItem:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark AdcPSPlayerId:", AdcPSPlayerId, GetObjectName(self), GetObjectName(AdcPS), GetObjectName(AdcPC))

    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()

    BlackBoardKeySelector.SelectedKeyName = "BookerId"
    local BookerId, BookerIdType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt64(InTaskData.OtherData, BlackBoardKeySelector)
	--print("BuoysWeaponItem:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark BookerId!", BookerId, "BookerIdType:", BookerIdType, "LocalPlayerId:", LocalPlayerId, "LocalGetPlayerId:", LocalGetPlayerId, "LocalPCId:", LocalPCId, GetObjectName(self), GetObjectName(LocalPS), GetObjectName(self.LocalPC))
	local IfReserve = false
    local OpTipsParams = { bCanOpMark = false, OpTxtKey  = "MarkSystem_CancelMark" }
    if bIfLocalMark then
        OpTipsParams = { bCanOpMark = true, OpTxtKey = "MarkSystem_CancelMark" }
        if BookerIdType and BookerId ~= 0 then
            if (BookerId ~= LocalPlayerId) then --被人预定了
                local BookerPS = UE.AGeGameState.GetPlayerStateBy(self, BookerId)
                OpTipsParams = { bCanOpMark = false, OpTxtKey = "MarkSystem_AlreadyBooker" }
				if BookerPS then
					self:CheckTxtOpListKey("MarkSystem_AlreadyBooker")
					local TxtAlreadyBooker = self.TxtOpList["MarkSystem_AlreadyBooker"]
					if not string.find( MarkLogKey, "Reserve")  then
						MarkLogKey = MarkLogKey.."Reserve"
					end
					
					LogPlayerName = BookerPS:GetPlayerName()
					if self.TxtName then self.TxtName:SetText(StringUtil.Format(TxtAlreadyBooker, BookerPS:GetPlayerName())) end
					if self.MarkWidget2 then self.MarkWidget2.TxtName:SetText(StringUtil.Format(TxtAlreadyBooker, BookerPS:GetPlayerName())) end
				end
				if self.CurRefPS then
					MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Reserve_Item, self.CurRefPS, false)
				end
				IfReserve = true
            end
        end
    else
        if BookerIdType then
            if (BookerId == LocalPlayerId) then
				--print("BuoysWeaponItem:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark BookerId == LocalPlayerId!", GetObjectName(self))
			    OpTipsParams = { bCanOpMark = true, OpTxtKey = "MarkSystem_CancelBooker" }
                if nil == self.bIfClientOnlyShow or false == self.bIfClientOnlyShow then
					--在预定时，隐藏自己这个handle同步的Mark图标--------------------------------------
                    self:SetVisibility(UE.ESlateVisibility.Collapsed)
					--print("BuoysWeaponItem:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark Rerver UI BookerId == LocalPlayerId! SetCollapsed!", GetObjectName(self))
					LogPlayerName = G_ConfigHelper:GetStrFromIngameStaticST("SD_Mark", "MarkLog_MySelf")
				else
					--print("BuoysWeaponItem:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark Client UI BookerId == LocalPlayerId! SetVisibile!", GetObjectName(self))
					self:VXE_HUD_Mark_Weapon_Reserve()
                end
				if self.CurRefPS then
					MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Reserve_Item, self.CurRefPS, false)
				end
				IfReserve = true
            elseif 0 == BookerId then
                OpTipsParams = { bCanOpMark = true, OpTxtKey = "MarkSystem_CanBooker" }
            else --被人预定了
                local BookerPS = UE.AGeGameState.GetPlayerStateBy(self, BookerId)
                OpTipsParams = { bCanOpMark = false, OpTxtKey = "MarkSystem_AlreadyBooker" }
				if BookerPS then
					self:CheckTxtOpListKey("MarkSystem_AlreadyBooker")
					local TxtAlreadyBooker = self.TxtOpList["MarkSystem_AlreadyBooker"]
					if not string.find( MarkLogKey, "Reserve")  then
						MarkLogKey = MarkLogKey.."Reserve"
					end
					LogPlayerName = BookerPS:GetPlayerName()
					if self.TxtName then self.TxtName:SetText(StringUtil.Format(TxtAlreadyBooker, BookerPS:GetPlayerName())) end
					if self.MarkWidget2 then self.MarkWidget2.TxtName:SetText(StringUtil.Format(TxtAlreadyBooker, BookerPS:GetPlayerName())) end
					if self.CurRefPS then
						MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Reserve_Item, self.CurRefPS, false)
					end
					IfReserve = true
				end
            end
        else --没有预定ID，说明没有人预定
            OpTipsParams = { bCanOpMark = true, OpTxtKey = "MarkSystem_CanBooker" }
        end
    end


    -- 预定玩家的名字
    if self.TxtName then self.TxtName:SetVisibility(OpTipsParams.bCanOpMark and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible) end
	if self.MarkWidget2 then 
		--self.MarkWidget2:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
		self.MarkWidget2.TxtName:SetVisibility(OpTipsParams.bCanOpMark and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible) 
	end
    
	if self.TrsOpMark then self.TrsOpMark:SetVisibility(OpTipsParams.bCanOpMark and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed) end
    if self.MarkWidget2 then self.MarkWidget2.TrsOpMark:SetVisibility(OpTipsParams.bCanOpMark and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed) end

	if OpTipsParams.bCanOpMark and OpTipsParams.OpTxtKey then
		self:CheckTxtOpListKey(OpTipsParams.OpTxtKey)
		if self.TxtOpTips then self.TxtOpTips:SetText(self.TxtOpList[OpTipsParams.OpTxtKey]) end
		if self.MarkWidget2 and self.MarkWidget2.TxtOpTips then self.MarkWidget2.TxtOpTips:SetText(self.TxtOpList[OpTipsParams.OpTxtKey]) end
	end

	BlackBoardKeySelector.SelectedKeyName = "ItemId"
    local ItemId, ItemIdType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(InTaskData.OtherData, BlackBoardKeySelector)

	if ItemIdType then
		self.ItemId = ItemId
    else
        print("BuoysWeaponItem:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark does not have ItemId!")
        return
	end

    -- 处理类型
	local CurItemType, IsFindType = UE.UItemSystemManager.GetItemDataFName(self, self.ItemId, "ItemType",
    GameDefine.NItemSubTable.Ingame, "BuoysWeaponItem.BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark")

    local PickupItemId = self.ItemId
    local PickupItemIdStr = tostring(PickupItemId)

    local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(self)
    local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(PickupItemId, "Ingame")

    if SubTable then
        local ImageSoftObjectPtr = nil

        local FlowImage, bValidIcon = SubTable:BP_FindDataFString(PickupItemIdStr, "FlowImage")
        if bValidIcon then
            ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(FlowImage)
        end

        if ImageSoftObjectPtr then
            -- 设置纹理
            --:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
            if self.IconWidgetArr and self.IconWidgetArr.ScreenCenter then
                self.IconWidgetArr.ScreenCenter:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
            end

            if self.IconWidgetArr and self.IconWidgetArr.ScreenEdge then
                self.IconWidgetArr.ScreenEdge:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
            end
        end

        local bValidName = true
        local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, PickupItemId)
        if not IngameDT then
			bValidName = false
        end

		local StructInfo_Item
		if bValidName then
			StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, PickupItemIdStr)
		end

		if not StructInfo_Item then
			bValidName = false
		end
			
		if bValidName then
			local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
			self.ItemName = TranslatedItemName
			if self.TxtTips then self.TxtTips:SetText(TranslatedItemName) end
			if self.MarkWidget2 then self.MarkWidget2.TxtTips:SetText(TranslatedItemName) end
        end

        local ItemLevel, bValidLevel = SubTable:BP_FindDataUInt8(PickupItemIdStr, "ItemLevel")
		QualityLevel = ItemLevel
        if CurItemType == "Weapon" then
            --获得物品品质信息
            local NewLinearColor = bValidLevel and AdvanceMarkHelper.GetMarkItemQualityColor(self, ItemLevel) or
                UIHelper.LinearColor.White
            -- 设置背景框颜色
            if NewLinearColor then
                for _, value in pairs(self.BgWidgetArr) do
                 	value:SetColorAndOpacity(NewLinearColor)
                end
                -- 控件颜色都设置好
                self:UpdateWidgetColor(NewLinearColor)
            end
        end
    end

    local IfForceUpdate = InTaskData.TaskType == UE.EG3DMarkItemTaskAction.ForceUpdate
	self.QualityColor = AdvanceMarkHelper.GetMarkLogItemQualityColor(self, QualityLevel)
	local IfReserveHavePicked, IfReserveHavePickedType
	if self.bIfReserved then
		BlackBoardKeySelector.SelectedKeyName = "IfReserveHavePicked"
		IfReserveHavePicked, IfReserveHavePickedType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(InTaskData.OtherData, BlackBoardKeySelector)
	end

	-- 确保不是初始化浮标panel强制刷新导致的发消息
	if not IfForceUpdate then
		if IfReserveHavePickedType and IfReserveHavePicked then
			-- 不是别人捡走同步的消息才发送我预定了xxx；我标记了xxx这样子的标记日志
		else
			-- body
			if self.MarkWidget2 then self:VXE_HUD_Mark_Weapon_In() end
			AdvanceMarkHelper.SendMarkLogHelperSafe(self, MarkLogKey, LogPlayerName, self.QualityColor, self.ItemName)
			if not IfReserve then
				if self.CurRefPS then
					MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Mark_Point, MarkLogKey, self.CurRefPS, false)
				end
			end
		end
	end
	
end


function BuoysWeaponItem:BPImpFunc_On3DMarkIconRemoveFrom3DMark(InTaskData)
	--if self.MarkWidget2 then self:VXE_HUD_Mark_Weapon_Out() end

	local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()

	if self.bIfReserved then
		local IfReserveHavePicked, IfReserveHavePickedType
		BlackBoardKeySelector.SelectedKeyName = "IfReserveHavePicked"
		IfReserveHavePicked, IfReserveHavePickedType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(InTaskData.OtherData, BlackBoardKeySelector)
		if IfReserveHavePickedType and IfReserveHavePicked and not self.bIfOtherReserved then -- 自己预定的东西才会发 被xxx捡走了 的消息
			BlackBoardKeySelector.SelectedKeyName = "PickedTeamPlayer"
			local PickedTeamPlayer, PickedTeamPlayerPickedType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsObject(InTaskData.OtherData, BlackBoardKeySelector)
			if PickedTeamPlayerPickedType then
				local PickedPlayerName = PickedTeamPlayer and PickedTeamPlayer:GetPlayerName() or "Error"
				AdvanceMarkHelper.SendMarkLogHelper(self, "ReservedItemPickedByPerson", PickedPlayerName, self.QualityColor, self.ItemName)
			else
				AdvanceMarkHelper.SendMarkLogHelper(self, "ReservedItemPicked", self.QualityColor, self.ItemName)
			end
		end
	end

	if self.CurRefPS == self.LocalPS then
		BlackBoardKeySelector.SelectedKeyName = "SelfCanelMark"
		local SelfCanelMark, SelfCanelMarkType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(InTaskData.OtherData, BlackBoardKeySelector)
		if SelfCanelMark and SelfCanelMarkType then
			MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Buoys_Remove, InTaskData.ItemKey, self.CurRefPS)
		end
	end
end

-- 更新控件颜色
function BuoysWeaponItem:UpdateWidgetColor(InNewLinearColor)
	if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor and self.CurTeamPos then
		self.TeamLinearColor  = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)
	end
	self.NewLinearColor = InNewLinearColor or self.TeamLinearColor

	self.ImgConnPoint:SetColorAndOpacity(self.NewLinearColor)
	self.ImgDir:SetColorAndOpacity(self.NewLinearColor)
	self.NewSlateColor.SpecifiedColor = self.NewLinearColor
	self.CurTeamSlateColor.SpecifiedColor = self.TeamLinearColor

	if self.TxtTips then self.TxtTips:SetColorAndOpacity(self.NewSlateColor) end
	if self.TxtName then self.TxtName:SetColorAndOpacity(self.CurTeamSlateColor) end
	if self.MarkWidget2 then 
		self.MarkWidget2.TxtTips:SetColorAndOpacity(self.NewSlateColor)
		self.MarkWidget2.TxtName:SetColorAndOpacity(self.CurTeamSlateColor)
	end

	--print("BuoysMarkSysPointItem", ">> UpdateWidgetColor, ...", GetObjectName(self))
end

return BuoysWeaponItem