--
-- 战斗界面Helper
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.16
--

require("Common.Framework.CommFuncs")

local BattleUIHelper = _G.BattleUIHelper or {}


------------------------------------------- Config/Enum ------------------------------------

-- 倒计时类类型
BattleUIHelper.ECountdownType = {
	NumberAdd_ProgressAdd	= 1,
	NumberAdd_ProgressLess	= 2,
	NumberLess_ProgressAdd	= 3,
	NumberLess_ProgressLess	= 4,
}
SetErrorIndex(BattleUIHelper.ECountdownType)

-- 获取配置数据SkillBuff
function BattleUIHelper.GetBuffConfig(InKey)
	local DataTablePath = "/Game/DataTable/DT_SkillBuff"
	local DataTableObject = UE.UObject.Load(DataTablePath)
	local DataTableRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(DataTableObject, InKey)
    return DataTableRow
end

------------------------------------------- Function ----------------------------------------

-- 队伍索引相关(位置)
function BattleUIHelper.GetTeamPos(InPlayerState)
	local TeamExSubsystem = UE.UTeamExSubsystem.Get(InPlayerState)
	if TeamExSubsystem then
		return TeamExSubsystem:GetPlayerNumberInTeamByPS(InPlayerState)
	end
	return -1
end

-- 创建子对象控件
function BattleUIHelper.CreateSubWidget(InMainWidget, InKey, InParent)
    --local LayoutDT = UE.UObject.Load(UIHelper.LayoutDTPath.BattlePanelSubData)
	return UIHelper.CreateSubWidget(InMainWidget, LayoutDT, InKey, InParent)
end

-- 获取护甲
function BattleUIHelper.GetItemSlotFeatureSet(InActor)
    local FeatureSetTag = UE.FGameplayTag()
    FeatureSetTag.TagName = ItemSystemHelper.NFeatureSetName.ItemSlot
    local ItemSlotFeatureSet = UE.UFeatureSetSubsystem.GetFeatureSetFromActor(InActor, FeatureSetTag)
	return ItemSlotFeatureSet
end

function BattleUIHelper.GetArmorShieldValue(InItemSlotFeatureSet)
	if (not InItemSlotFeatureSet) then return end

    local RetArmorShield, RetMaxArmorShield = nil, nil
    local AttributeNum = InItemSlotFeatureSet.BagItemAttribute:Length()
    for i = 1, AttributeNum do
        local BagElem = InItemSlotFeatureSet.BagItemAttribute:Get(i)
        local ArrayLength = BagElem.RuntimeAttribute:Length()
        local IsTargetElem = false
        for k = 1, ArrayLength do
            local ItemAttribute = BagElem.RuntimeAttribute:Get(k)
            if ItemAttribute.AttributeName == ItemSystemHelper.NItemAttrName.ArmorShield then
                RetArmorShield = ItemAttribute.FloatValue
            end
            if ItemAttribute.AttributeName == ItemSystemHelper.NItemAttrName.MaxArmorShield then
                RetMaxArmorShield = ItemAttribute.FloatValue
            end
            if RetArmorShield and RetMaxArmorShield then
                return BagElem, RetArmorShield, RetMaxArmorShield
            end
        end
    end
end

-- 设置护甲进度等级(只能用于材质的护甲条)
function BattleUIHelper.SetArmorShieldLvInfo(InArmorId, InProgressBar, InArmorLvAttributes,InSizeBox_BarArmor)
	if (not InProgressBar) or (not InArmorLvAttributes) then return end
    --local ArmorFiilBrush = UE.UGUIHelper.GetProgressBarBrush(InProgressBar, 1)
    --ArmorFiilBrush.TintColor = UIHelper.ToSlateColor_LC(UIHelper.LinearColor.White)
    if InArmorId then
        local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(InProgressBar)
        local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(InArmorId, "Ingame")
        if SubTable then
            local ItemLevel, bValidItemLevel = SubTable:BP_FindDataUInt8(tostring(InArmorId), "ItemLevel")

            if bValidItemLevel and ItemLevel and InArmorLvAttributes then
				InProgressBar:GetDynamicMaterial():SetScalarParameterValue("SegmentNumber", ItemLevel)
				
				local NewSizeBox_BarArmorSize = (InSizeBox_BarArmor.WidthOverride / 4)*ItemLevel
                InSizeBox_BarArmor:SetWidthOverride(NewSizeBox_BarArmorSize)
                local ArmorLvColor = InArmorLvAttributes:FindRef(ItemLevel).ArmorColor
                if ArmorLvColor then
                    --ArmorFiilBrush.TintColor = UIHelper.ToSlateColor_LC(ArmorLvColor)
					InProgressBar:GetDynamicMaterial():SetVectorParameterValue("InnerFrontColor",ArmorLvColor)
                end
				return ItemLevel
            end
        end
    end
    --UE.UGUIHelper.SetProgressBarBrush(InProgressBar, 1, ArmorFiilBrush)
end


function BattleUIHelper.GetRomanNumText(InNum)
	if InNum then
		local TempCfgKey = "RomanNum_" .. tostring(InNum)
		local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, TempCfgKey)
		if TextStr then
			return TextStr
		end
	end

	return "Error"
end

-- 设置图片纹理(BagItem)
function BattleUIHelper.SetImageTexture_BagItem(InEquipComp, InImageWidget, InTxtLvWidget, InItemType, InSlotId, InDefaultTexture)
	--print("BattleUIHelper", ">> SetImageTexture_BagItem[0], ", GetObjectName(InEquipComp), GetObjectName(InImageWidget), GetObjectName(InTxtLvWidget), InItemType, InSlotId)

	local InventoryItemSlot, bValidItemSlot = nil, nil
	if InEquipComp then
		local EquipCompOwner = InEquipComp:GetOwner()
		local BagComp = UE.UBagComponent.Get(EquipCompOwner)
		if (not BagComp) then
			Warning("BattleUIHelper", ">> SetImageTexture_BagItem[!], BagComp is invalid!", GetObjectName(EquipCompOwner))
		else
			InventoryItemSlot, bValidItemSlot = BagComp:GetItemSlotByTypeAndSlotID(InItemType, InSlotId)
		end
	end
	
	if (not bValidItemSlot) or (InventoryItemSlot.InventoryIdentity.ItemID == 0) then
		if InTxtLvWidget then InTxtLvWidget:SetText('') end
		--InImageWidget:SetBrushFromTexture(InDefaultTexture, false)

		--Warning("BattleUIHelper", ">> SetImageTexture_BagItem[1], ItemID is invalid!!!", bValidItemSlot)
		return InventoryItemSlot, bValidItemSlot
	end

    --下面一行为获取ItemID（获取对应等级的物品）
	local ItemId = InventoryItemSlot.InventoryIdentity.ItemID
	local ItemIdString = tostring(ItemId)
	local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(InEquipComp)
	local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(ItemId, "Ingame")
	if SubTable then
		-- 物品配置等级
		if InTxtLvWidget then
			local ItemLevel, bValidLv = SubTable:BP_FindDataUInt8(ItemIdString, "ItemLevel")
			if bValidLv and ItemLevel then
				local CfgKey = "RomanNum_".. ItemLevel
				local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, CfgKey)
				print("BattleUIHelper >> SetImageTexture_BagItem > ItemLevel:",ItemLevel)
				print("BattleUIHelper >> SetImageTexture_BagItem > TextStr:",TextStr)
				InTxtLvWidget:SetText(TextStr or ItemLevel)
			else
				InTxtLvWidget:SetText('')
			end
		end
		-- 物品图片图标
		local ImageAsset, bValidImage = SubTable:BP_FindDataFString(ItemIdString, "SlotImage")
		if (not bValidImage) then
			ImageAsset, bValidImage = SubTable:BP_FindDataFString(ItemIdString, "ItemIcon")
		end
		if bValidImage then
			local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(ImageAsset)
			--InImageWidget:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
			print("BattleUIHelper", ">> SetImageTexture_BagItem[3], ", GetObjectName(InImageWidget), ImageAsset, ImageSoftObjectPtr)
			return InventoryItemSlot, bValidItemSlot
		end
	end
	
	if InTxtLvWidget then InTxtLvWidget:SetText('') end
	InImageWidget:SetBrushFromTexture(nil, false)
	return InventoryItemSlot, bValidItemSlot
end

-- 设置图片纹理(ItemId)
function BattleUIHelper.SetImageTexture_ItemId(InImageWidget, InItemId, InImageKey, InDefaultTexture)
	local ItemId = InItemId
	local ItemIdString = tostring(ItemId)
	local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(InImageWidget)
	local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(ItemId, "Ingame")
	if SubTable then
		local ImageAsset, bValidImage = nil, nil
		if InImageKey then
			ImageAsset, bValidImage = SubTable:BP_FindDataFString(ItemIdString, InImageKey)
		else
			ImageAsset, bValidImage = SubTable:BP_FindDataFString(ItemIdString, "SlotImage")
			if (not bValidImage) then
				ImageAsset, bValidImage = SubTable:BP_FindDataFString(ItemIdString, "ItemIcon")
			end
		end
		if bValidImage then
			local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(ImageAsset)
			InImageWidget:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
			return SubTable
		end
	end
	
	InImageWidget:SetBrushFromTexture(InDefaultTexture, false)
end

--设置护甲和头盔的品级对应的背景颜色
function BattleUIHelper.SetEquipIconBGColor(InEquipComp, ImageBg, InAttributes, InItemType, InSlotId)
	print("BattleUIHelper.SetImageBGColor1")
	local InventoryItemSlot, bValidItemSlot = nil, nil
	if InEquipComp then
		print("BattleUIHelper.SetImageBGColor3")
		local EquipCompOwner = InEquipComp:GetOwner()
		local BagComp = UE.UBagComponent.Get(EquipCompOwner)
		if (not BagComp) then
			Warning("BattleUIHelper", ">> SetEquipIconBGColor[!], BagComp is invalid!", GetObjectName(EquipCompOwner))
		else
			InventoryItemSlot, bValidItemSlot = BagComp:GetItemSlotByTypeAndSlotID(InItemType, InSlotId)
		end
	end

	if (not bValidItemSlot) or (InventoryItemSlot.InventoryIdentity.ItemID == 0) then
		return InventoryItemSlot, bValidItemSlot
	end

	local ItemId = InventoryItemSlot.InventoryIdentity.ItemID
	local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(InEquipComp)
	if (not TableManagerSubsystem) then
		print("BattleUIHelper.SetEquipIconBGColor TableManagerSubsystem is nil")
		return false
	end
	local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(ItemId, "Ingame")
	if (not SubTable)then
		print("BattleUIHelper.SetEquipIconBGColor SubTable is nil")
		return false
	end
	local ItemLevel, bValidLv = SubTable:BP_FindDataUInt8(tostring(ItemId), "ItemLevel")
	--local LvColor = UIHelper.ToSlateColor_LC(InColor:FindRef(tostring(ItemLevel)))
	local LvColor = InAttributes:FindRef(tostring(ItemLevel)).ArmorColor
    ImageBg:SetColorAndOpacity(LvColor)
	print("BattleUIHelper.SetImageBGColor2")
end

--获取MiscSystem某些属性的某些值（只限制Map属性的）
function BattleUIHelper.GetMiscSystemValue(Obj,TargetMap,Targetkey)
	--这里开始使用MiscSystem的颜色
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(Obj)
	--print("BattleUIHelper:GetMiscSystemValue		>>", GetObjectName(MiscSystem))
	local TmpValue = MiscSystem[TargetMap]:FindRef(Targetkey) 
	return TmpValue
end

function BattleUIHelper.GetMiscSystemMap(Obj,TargetMap)
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(Obj)
	local TmpValue = MiscSystem[TargetMap]
    return TmpValue
end

function BattleUIHelper.GetMiscSystem(Obj)
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(Obj)
	return MiscSystem
end

------------------------------------------- Debug ----------------------------------------
--[[
	测试打印子系统(Cmd: ExecLua BattleUIHelper DebugSubSystem)
]]
function BattleUIHelper.DebugSubSystem(InActor)
	UE.USubsystemBlueprintLibrary.GetEngineSubsystem(InActor)
	UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(InActor)
	UE.USubsystemBlueprintLibrary.GetWorldSubsystem(InActor)
	UE.USubsystemBlueprintLibrary.GetAudioEngineSubsystem(InActor)
	UE.USubsystemBlueprintLibrary.GetLocalPlayerSubSystemFromPlayerController(InActor)
end

--[[
	测试LarkMsgPy(Cmd: ExecLua BattleUIHelper DebugSendLarkMsgByPy)
]]
function BattleUIHelper.DebugSendLarkMsgByPy(InActor, InMode, InBotUrl, InHeader, InMsg, InColorName)
	InMode = InMode or "Comm"
	InBotUrl = InBotUrl or "https://open.feishu.cn/open-apis/bot/v2/hook/2de962bc-572c-429b-828c-fdc3b67725bc"
	InHeader = InHeader or "feiyu.mark"
	InMsg = InMsg or "Cmd: ExecLua BattleUIHelper DebugSendLarkMsgByPy"
	InColorName = InColorName or "turquoise"
	UE.ULarkSenderHelper.SendLarkMsgByPy(InMode, InBotUrl, InHeader, InMsg, InColorName)
end

--[[
	测试LarkMsgCpp(Cmd: ExecLua BattleUIHelper DebugSendLarkMsgByCpp)
]]
function BattleUIHelper.DebugSendLarkMsgByCpp(InActor, InMode, InBotUrl, InHeader, InMsg, InColorName)
	InMode = InMode or "Comm"
	InBotUrl = InBotUrl or "https://open.feishu.cn/open-apis/bot/v2/hook/2de962bc-572c-429b-828c-fdc3b67725bc"
	InHeader = InHeader or "feiyu.mark"
	InMsg = InMsg or "Cmd: ExecLua BattleUIHelper DebugSendLarkMsgByCpp"
	InColorName = InColorName or "turquoise"
	UE.ULarkSenderHelper.SendLarkMsgByCpp(InMode, InBotUrl, InHeader, InMsg, InColorName)
end

--[[
	测试玩家信息(Cmd: ExecLua BattleUIHelper DebugPlayerInfo 258)
]]
function BattleUIHelper.DebugPlayerInfo(InActor, InP1)
	local PlayerId = InP1 and tonumber(InP1) or nil
	local PlayerState = InActor.PlayerState
	local GameState = UE.UGameplayStatics.GetGameState(InActor)
	print("BattleUIHelper", ">> DebugPlayerInfo, ",
		GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), GameState.PlayerArray:Length(), InP1)
	
	-- 背包数据
    local LocalPCBag = UE.UBagComponent.Get(InActor)
	if LocalPCBag then LocalPCBag:PrintToString() end

	-- 队伍数据
	if PlayerId then PlayerState = GameState:GetPlayerState(PlayerId) end
	if PlayerState then
		--local TeamData = UE.UTeamExSubsystem:GetTeamSharedInfoByPS(PlayerState)
		--print("BattleUIHelper", ">> DebugPlayerInfo, Team: ", GetObjectName(PlayerState), TeamData and TeamData:ToString() or "Nil")
		local OutActors = UE.UGameplayStatics.GetAllActorsOfClass(PlayerState, PlayerState:GetClass())
		local OutActorsNum = OutActors:Length()
		for i = 1, OutActorsNum do
			local TmpActor = OutActors:Get(i)
			print("BattleUIHelper", ">> DebugPlayerInfo, AllPS: ", GetObjectName(TmpActor))
		end
	else
		Error("BattleUIHelper", ">> DebugPlayerInfo, Team: None.")
	end

	-- 角色数据
	local LocalPCPawn = UE.UPlayerStatics.GetPSPlayerPawn(PlayerState)
	if LocalPCPawn then
		print("BattleUIHelper", ">> DebugPlayerInfo, LocalPCPawn: ", GetObjectName(LocalPCPawn), LocalPCPawn:GetTransform())
		-- 技能数据
		if LocalPCPawn.S1Skill then
			LocalPCPawn.S1Skill:FindSkill(nil)
		end
	end

	-- 统计/上报数据
	if UE.UGenericStatics then
		local PlayerGSComp = UE.UGenericStatics.GetGenericStatisticComp(PlayerState)
		if PlayerGSComp then
			print("BattleUIHelper", ">> DebugPlayerInfo[PlayerGS], ", PlayerGSComp:ToString())
		end

		local GameGSComp = UE.UGenericStatics.GetGenericStatisticComp(GameState)
		if GameGSComp then
			print("BattleUIHelper", ">> DebugPlayerInfo[GameGS], ", GameGSComp:ToString())
		end
	end

	UE.UGenericReportComp.StatisticReport(InActor)

	-- StringTable
	--[[local StringTableKey = "Minimap_MarkRouteNumLimit"
	local StringTablePath = "/Game/DataTable/UI/SD_InGameUI.SD_InGameUI"
	local StringTableObject = UE.UObject.Load(StringTablePath)
	local StringTableValue = UE.UKismetStringTableLibrary.TextFromStringTable(StringTablePath, StringTableKey)
	print("BattleUIHelper", ">> DebugPlayerInfo[StringTableValue], ", StringTableObject, StringTableKey, StringTableValue)
	]]

	-- do while
    print("BattleUIHelper", ">> DebugPlayerInfo[do-while], Start.")
	local DoWhileCounter = 0
	local SomeThing = function()
		DoWhileCounter = DoWhileCounter + 1
        print("BattleUIHelper", ">> DebugPlayerInfo[do-while], SomeThing.", DoWhileCounter)
	end
	local SomeOtherThing = function()
		DoWhileCounter = DoWhileCounter + 1
        print("BattleUIHelper", ">> DebugPlayerInfo[do-while], SomeOtherThing.", DoWhileCounter)
	end
	repeat
		if (DoWhileCounter == 10) then
			print("BattleUIHelper", ">> DebugPlayerInfo[do-while], break.")
			break
		end
		SomeThing()
		SomeOtherThing()
	until (DoWhileCounter > 10)
	print("BattleUIHelper", ">> DebugPlayerInfo[do-while], End.")
	-- while do
	while(DoWhileCounter >= 0)
	do
		if (DoWhileCounter == 5) then
			print("BattleUIHelper", ">> DebugPlayerInfo[while], break.")
			break
		end
        print("BattleUIHelper", ">> DebugPlayerInfo[while],", DoWhileCounter)
		DoWhileCounter = DoWhileCounter - 1
	end
	print("BattleUIHelper", ">> DebugPlayerInfo[while], End.")

	-- Message
	MsgHelper:SendCpp(InActor, GameDefine.MsgCpp.PC_UpdatePlayerState, InActor, nil, PlayerState)
end

--[[
	测试全局时间加速(Cmd: ExecLuaRPC BattleUIHelper DebugGlobalTimeDilation 100)
]]
function BattleUIHelper.DebugGlobalTimeDilation(InActor, InP1)
	print("BattleUIHelper", ">> DebugGlobalTimeDilation, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1)

	if UE.UGFUnluaHelper.IsRunningDedicatedServer(InActor) then
		UE.UGameplayStatics.SetGlobalTimeDilation(InActor, tonumber(InP1))
	end
end
function BattleUIHelper.DebugTriggerTimeDilation(InActor)
	print("BattleUIHelper", ">> DebugTriggerTimeDilation, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role))

	if UE.UGFUnluaHelper.IsRunningDedicatedServer(InActor) then
		local CurTimeDilation = UE.UGameplayStatics.GetGlobalTimeDilation(InActor)
		local NewTimeDilation = (CurTimeDilation > 1 and 1 or 10)
		UE.UGameplayStatics.SetGlobalTimeDilation(InActor, NewTimeDilation)
	elseif (InActor and InActor.ExecLuaRPC) then
		InActor:ExecLuaRPC("BattleUIHelper DebugTriggerTimeDilation")
	end
end

--[[
	测试预览加血(Cmd: ExecLua BattleUIHelper DebugPreviewTreat 0 20)
]]
function BattleUIHelper.DebugPreviewTreat(InActor, InP1, InP2, InP3, InP4)
	print("BattleUIHelper", ">> DebugPreviewTreat, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1, InP2, InP3, InP4)

	local bPreviewTreat = (tonumber(InP1) > 0)
	local InExtraValue = tonumber(InP2)
	MsgHelper:SendCpp(InActor, GameDefine.MsgCpp.PLAYER_HealthShowPreview, bPreviewTreat, InExtraValue)
end

--[[
	测试添加Buff(Cmd: ExecLuaRPC BattleUIHelper DebugAddBuff)
]]
function BattleUIHelper.DebugAddBuff(InActor)
	print("BattleUIHelper", ">> DebugAddBuff, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role))

	local OpPawn = UE.UPlayerStatics.GetLocalPCRealPawn(InActor)
	if UE.UGFUnluaHelper.IsRunningDedicatedServer(OpPawn) then
		local MiscSystem = UE.UMiscSystem.GetMiscSystem(InActor)
		local BuffClass = UE.UKismetSystemLibrary.LoadClassAsset_Blocking(MiscSystem.TestBuffClass)
		local NewBuffObject = UE.USkillBlueprintLibrary.AddBuffByClass(OpPawn, BuffClass, OpPawn)

		function ModifyBuff()
			if NewBuffObject then
				--NewBuffObject:SetBuffTag()
				NewBuffObject:SetCurrentLevel(5)
			end
		end
	end
end

--[[
	测试启用传送至标记点(Cmd: ExecLuaRPC BattleUIHelper DebugEnableToMarkPoint 1)
]]
function BattleUIHelper.DebugEnableToMarkPoint(InActor, InP1)
	local ValueP1 = InP1 and tonumber(InP1) or 0
	print("BattleUIHelper", ">> DebugTeleportToMarkPoint, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1, ValueP1)

end
function BattleUIHelper.DebugTiggerTeleport(InActor)
	print("BattleUIHelper", ">> DebugTiggerTeleport, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role))

	local PlayerState = InActor.PlayerState
	local ADCBussinessCom = UE.UAdvanceMarkBussinessComponent.GetAdvanceMarkBussinessComponentClientOnly(PlayerState)
	if ADCBussinessCom then
		local bIfCanAutoMark = ADCBussinessCom:IfCanAutoToMarkPoint()
		ADCBussinessCom.bAutoToMarkPoint = not bIfCanAutoMark
		ADCBussinessCom:SetAutoToMarkPoint(not bIfCanAutoMark)
	end
end

--[[
	测试通用使用提示(Cmd: ExecLua BattleUIHelper DebugGenericUseTips 1 1 10 Text)
]]
function BattleUIHelper.DebugGenericUseTips(InActor, InP1, InP2, InP3, InP4)
	print("BattleUIHelper", ">> DebugGenericUseTips, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1, InP2, InP3, InP4)

	local bEnable = (tonumber(InP1) > 0)
	local bIncremental = (tonumber(InP2) > 0)
	local InMaxValue = tonumber(InP3)
	local InText = tostring(InP4)
	MsgHelper:SendCpp(InActor, GameDefine.MsgCpp.PLAYER_GenericUseTips, bEnable, bIncremental, InMaxValue, InText)
end

--[[
	测试通用按键指南提示(Cmd: ExecLua BattleUIHelper DebugGenericGuideTips 1 F ShowTextTips  )
]]
function BattleUIHelper.DebugGenericGuideTips(InActor, InP1, InP2, InP3, InP4, InP5)
	print("BattleUIHelper", ">> DebugGenericGuideTips, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1, InP2, InP3, InP4, InP5)

	local InInstigator = UE.UPlayerStatics.GetLocalPCRealPawn(InActor)
	local bEnable = (tonumber(InP1) > 0)
	local InTextKey, InTextTips, InTopTips1, InTopTips2 = tostring(InP2), tostring(InP3), tostring(InP4 or ''), tostring(InP5 or '')
	MsgHelper:SendCpp(InActor, GameDefine.MsgCpp.PLAYER_GenericGuideTips,
		InInstigator, bEnable, InTextKey, InTextTips, InTopTips1, InTopTips2)
end

--[[
	测试通用提示Icon(Cmd: ExecLua BattleUIHelper DebugGenericSkillTips Generic.IconTips 1 TextTips)
]]
function BattleUIHelper.DebugGenericSkillTips(InActor, InP1, InP2, InP3)
	print("BattleUIHelper", ">> DebugGenericSkillTips, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1, InP2, InP3)

	-- InInstigator, InWidgetKey, bEnable, InIconAsset, InTextTips, InLinearColor
	local InInstigator = UE.UPlayerStatics.GetLocalPCRealPawn(InActor)
	local InWidgetKey = InP1 or "Generic.IconTips"
	local bEnable = (tonumber(InP2) > 0)
	local InIconAsset = ""
	local InTextTips, InLinearColor = tostring(InP3), UIHelper.LinearColor.Red
	MsgHelper:SendCpp(InActor, GameDefine.MsgCpp.PLAYER_GenericSkillTips,
		InInstigator, InWidgetKey, bEnable, InIconAsset, InTextTips, InLinearColor)
end

--[[
	测试通用技能使用提示(Cmd: ExecLua BattleUIHelper DebugGenericSkillUseTips Generic.SkillUseTips 1 1 20)
]]
function BattleUIHelper.DebugGenericSkillUseTips(InActor, InP1, InP2, InP3, InP4)
	print("BattleUIHelper", ">> DebugGenericSkillUseTips, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1, InP2, InP3)

	-- InInstigator, InWidgetKey, bEnable, InIconAsset, InTextTips, InLinearColor
	local InInstigator = UE.UPlayerStatics.GetLocalPCRealPawn(InActor)
	local InWidgetKey = InP1 or "Generic.SkillUseTips"
	local bEnable, bIsCasting = (tonumber(InP2) > 0), (tonumber(InP3) > 0)
	local InMaxValue = tonumber(InP4)
	MsgHelper:SendCpp(InActor, GameDefine.MsgCpp.PLAYER_GenericSkillUseTips, 
		InInstigator, InWidgetKey, bEnable, bIsCasting, InIconAsset or "", InMaxValue)
end

--[[
	测试濒死(Cmd: ExecLua BattleUIHelper DebugDying 1 1 110)
]]
function BattleUIHelper.DebugDying(InActor, InP1, InP2, InP3, InP4)
	print("BattleUIHelper", ">> DebugDying, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1, InP2, InP3, InP4)

	--[[local DyingInfo = UE.FS1LifetimeDyingInfo()
	DyingInfo.bIsDying = (tonumber(InP1) > 0)
	DyingInfo.DyingCounter = tonumber(InP2)
	DyingInfo.DeadCountdownTime = tonumber(InP3)
	local OpPawn = UE.UPlayerStatics.GetLocalPCRealPawn(InActor)
	local LifetimeMgr = UE.US1CharacterLifetimeManager.GetLifetimeManager(OpPawn)
	MsgHelper:SendCpp(OpPawn, GameDefine.MsgCpp.PLAYER_OnBeginDying, LifetimeMgr)
	]]
end

--[[
	测试救援(Cmd: ExecLua BattleUIHelper DebugRescue 1 15)
]]
function BattleUIHelper.DebugRescue(InActor, InP1, InP2, InP3, InP4)
	print("BattleUIHelper", ">> DebugDying, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1, InP2, InP3, InP4)
	
	local OpPawn = UE.UPlayerStatics.GetLocalPCRealPawn(InActor)
	if tonumber(InP1) == 1 then
		MsgHelper:SendCpp(OpPawn, GameDefine.MsgCpp.PLAYER_OnRescueActorChanged, InActor)
	elseif tonumber(InP1) == 2 then
		MsgHelper:SendCpp(OpPawn, GameDefine.MsgCpp.PLAYER_OnRescueActorChanged, nil)
	elseif tonumber(InP1) == 3 then
		MsgHelper:SendCpp(OpPawn, GameDefine.MsgCpp.PLAYER_OnBeginRescue, nil, tonumber(InP2))
	elseif tonumber(InP1) == 4 then
		MsgHelper:SendCpp(OpPawn, GameDefine.MsgCpp.PLAYER_OnEndRescue)
	end
end

--[[
	测试事件流水(Cmd: ExecLua BattleUIHelper DebugEventFlow)
]]
function BattleUIHelper.DebugEventFlow(InActor, InP1, InP2, InP3, InP4)
	print("BattleUIHelper", ">> DebugDying, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1, InP2, InP3, InP4)
	
    local GameState = UE.UGameplayStatics.GetGameState(InActor)
	local OpPawn = UE.UPlayerStatics.GetLocalPCRealPawn(InActor)
	if GameState and GameState.GameDataSyncComp then
		GameState.GameDataSyncComp.EventFlowData.CauseActor = OpPawn
		GameState.GameDataSyncComp.EventFlowData.ReceiverActor = OpPawn
		GameState.GameDataSyncComp.EventFlowData.bKilled = true
		GameState.GameDataSyncComp.EventFlowData.bDying = false
		GameState.GameDataSyncComp.EventFlowData.ItemId = 100000001
		local TagNames = {} or { "Bodyparts.Head", "Bodyparts.Body", "UI.EventFlow.ThroughSmoke", "UI.EventFlow.ThroughWall" }
		for i, TagName in ipairs(TagNames) do
			local GameplayTag = UE.FGameplayTag()
			GameplayTag.TagName = TagName
			UE.UBlueprintGameplayTagLibrary.AddGameplayTag(GameState.GameDataSyncComp.EventFlowData.Tags, GameplayTag)
		end
		
		MsgHelper:SendCpp(GameState.GameDataSyncComp, GameDefine.MsgCpp.GAMESYNC_UpdateEventFlow, GameState.GameDataSyncComp)
	end
end

--[[
	测试屏幕模式(Cmd: ExecLua BattleUIHelper DebugScreenMode 1)
]]
function BattleUIHelper.DebugScreenMode(InActor, InP1)
	print("BattleUIHelper", ">> DebugScreenMode, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1)

	--[[
		/** The window is in true fullscreen mode */
		Fullscreen,
		/** The window has no border and takes up the entire area of the screen */
		WindowedFullscreen,
		/** The window has a border and may not take up the entire screen area */
		Windowed,
	]]
	local FullscreenMode = InP1 and tonumber(InP1) or 0
	local GameUserSettings = UE.UGameUserSettings.GetGameUserSettings()
	GameUserSettings:SetFullscreenMode(FullscreenMode)
	--GameUserSettings:SetVSyncEnabled(true)
	GameUserSettings:ApplySettings(true)
end

--[[
	测试锁定鼠标(Cmd: ExecLua BattleUIHelper DebugLimitToCenter 0)
]]
function BattleUIHelper.DebugLimitToCenter(InActor, InP1)
	print("BattleUIHelper", ">> DebugLimitToCenter, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1)

	local LimitMode = InP1 and tonumber(InP1) or 0
	local UIManager = UE.UGUIManager.GetUIManager(InActor)
	UIManager.bEnableLimitToCenter = (LimitMode > 0)
end

--[[
	测试大地图显示(Cmd: ExecLua BattleUIHelper DebugTriggerMap)
]]
function BattleUIHelper.DebugTriggerMap(InActor)
	-- 此代码段废弃 --xuyanzu
	-- print("BattleUIHelper", ">> DebugTriggerMap, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role))

	-- local UIManager = UE.UGUIManager.GetUIManager(InActor)
	-- local HandleUILargemap = BattleUIHelper.HandleUILargemap
	-- if UIHelper.IsShowByHandle(InActor, HandleUILargemap) then
	-- 	UIManager:CloseByHandle(HandleUILargemap)
	-- else
	-- 	if BridgeHelper.IsMobilePlatform() then
	-- 		--HandleUILargemap = UIManager:ShowByKey("UMG_Largemap_Moblie")
	-- 	end
	-- 	if BridgeHelper.IsPCPlatform() then
	-- 		--HandleUILargemap = UIManager:ShowByKey("UMG_Largemap")
	-- 	end
		
	-- end
	-- BattleUIHelper.HandleUILargemap = HandleUILargemap
end

--[[
	测试小地图UpdateMode(Cmd: ExecLua BattleUIHelper DebugMapUpdateMode)
]]
function BattleUIHelper.DebugMapUpdateMode(InActor)
	print("BattleUIHelper", ">> DebugMapUpdateMode, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role))

	local MinimapSystem = UE.UMinimapSystem.GetMinimapSystem(InActor)
	local NewUpdateMode = MinimapSystem.WidgetUpdateMode + 1
	if NewUpdateMode > 2 then NewUpdateMode = 0 end
	MinimapSystem.WidgetUpdateMode = NewUpdateMode
	print("BattleUIHelper", ">> DebugMapUpdateMode, WidgetUpdateMode: ", NewUpdateMode)
end

function BattleUIHelper.DebugGyroInputMotionState(InActor)
	print("[yddhu]BattleUIHelper.DebugGyroInputMotionState")
	
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
		local UIManager = UE.UGUIManager.GetUIManager(InActor)
		if UIManager then
			local HandleUILargemap = UIManager:TryLoadDynamicWidget("UMG_DebugGyroInputMotionState")
		end
	else
		MvcEntry:OpenView(ViewConst.GMDebugGyroInputMotionState)
	end

end

--[[
	测试内存申请(Cmd: ExecLua BattleUIHelper TestMemory_Malloc 1)
]]
function BattleUIHelper.TestMemory_Malloc(InActor, InP1)
	print("BattleUIHelper", ">> TestMemory_Malloc, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1)

	local MallocSize = InP1 and tonumber(InP1) or 1
	if not UE.US1GameCheatExtension.TestMemory_Malloc(MallocSize) then
		Warning("BattleUIHelper", ">> TestMemory_Malloc, Fail.")
	end
end

--[[
	测试内存申请(Cmd: ExecLua BattleUIHelper TestMemory_TryOOM 1)
]]
function BattleUIHelper.TestMemory_TryOOM(InActor, InP1)
	print("BattleUIHelper", ">> TestMemory_TryOOM, ", GetObjectName(InActor), UE.UGUIHelper.SNetRole(InActor.Role), InP1)

	local IncRate = InP1 and tonumber(InP1) or 1
	UE.US1GameCheatExtension.TestMemory_TryOOM(IncRate)
end

------------------------------------------- Require ----------------------------------------

_G.BattleUIHelper = BattleUIHelper
return BattleUIHelper
