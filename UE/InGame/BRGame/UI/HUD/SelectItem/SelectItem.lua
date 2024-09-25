--
-- 战斗界面 - 选择物品(消耗品/投掷)
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.31
--

local SelectItem = Class("Common.Framework.UserWidget")
local AdvanceMarkName = 
{
	"MapMarkPoint",
    "MapMarkEnemy",
	"DefenseMark",
	"SomeOneCome"
}

-- 未更新前的选中区块索引
local OldSelectIdx = 0

-------------------------------------------- Logic Interface ------------------------------------
-- 新逻辑复写下边Proxy
local SelectMarkItemProxy = require("InGame.BRGame.UI.HUD.SelectItem.SelectMarkItemProxy")
local SelectAvatarActionItemProxy = require("InGame.BRGame.UI.HUD.SelectItem.SelectAvatarActionItemProxy")
local SelectConsumableItemProxy = require("InGame.BRGame.UI.HUD.SelectItem.SelectConsumableItemProxy")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")
-------------------------------------------- Init/Destroy ------------------------------------
function SelectItem:OnInit()
	UserWidget.OnInit(self)
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

	self.MsgList = {
        -- Mobile
        { MsgName = GameDefine.Msg.SelectPanel_Open,                Func = self.OnSelectPanel_Open,     bCppMsg = false, WatchedObject = nil },
        { MsgName = GameDefine.Msg.SelectPanel_Close,               Func = self.OnSelectPanel_Close,    bCppMsg = false, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.SelectAvatarAction_GamepadLeftShoulder, Func = self.OnAvatarActionGamepadLeftShoulder, bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.SelectAvatarAction_GamepadRightShoulder, Func = self.OnAvatarActionGamepadRightShoulder, bCppMsg = true, WatchedObject = self.LocalPC },

		

		--物品圆盘的中键标记IA触发
		{ MsgName = GameDefine.MsgCpp.PC_Input_SelectItemMark, Func = self.SelectItemMark, bCppMsg = true, WatchedObject = self.LocalPC },
		--使用
		{ MsgName = GameDefine.MsgCpp.PC_Input_SelectItemConfirm, Func = self.SelectItemConfirm, bCppMsg = true, WatchedObject = self.LocalPC },
		--取消
		{ MsgName = GameDefine.MsgCpp.PC_Input_SelectItemCancel, Func = self.OnCloseSelectItemPanel, bCppMsg = true, WatchedObject = self.LocalPC },
    }
	MsgHelper:RegisterList(self, self.MsgList)

	--右键或B键的关闭
	self.PressCancel = false
	--创建轮盘子控件数量
	self.ChildWidgetNum = 0
	self.WidgetInfos = {}

end

function SelectItem:OnDestroy()
	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end
	for i = #self.WidgetInfos, 1 , -1 do
		local WidgetInfo = self.WidgetInfos[i]
		if WidgetInfo.ItemInfo then
			WidgetInfo.ItemInfo:RemoveFromParent()
		end
		if WidgetInfo.WidgetLine then
			WidgetInfo.WidgetLine:RemoveFromParent()
		end
		self.WidgetInfos[i] = nil
	end
	self.WidgetInfos = nil
	self.ChildWidgetNum = 0
	self.CurType = UE.ESelectItemType.None
    UserWidget.OnDestroy(self)
end
-------------------------------------------- Get/Set ------------------------------------

-------------------------------------------- Function ------------------------------------
function SelectItem:InitPresentSelectItemData(InType, ShouldUseItemSlot)
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)

	self.ChildLineClass = UE.UKismetSystemLibrary.LoadClassAsset_Blocking(MiscSystem.SelectItemLineClass)
	self.ChildInfoClass = UE.UKismetSystemLibrary.LoadClassAsset_Blocking(MiscSystem.SelectItemInfoClass)

	self.bMobilePlatform = BridgeHelper.IsMobilePlatform()
	if self.bMobilePlatform == true then
		self.WSwitcher_Tips:SetActiveWidgetIndex(1)
		self.SelectItemTipsWidgetClass = self.BP_SelectItem_Tips_Moblie
	else
		self.WSwitcher_Tips:SetActiveWidgetIndex(0)
		self.SelectItemTipsWidgetClass = self.BP_SelectItem_Tips
	end

	self.WidgetInfos = self.WidgetInfos and self.WidgetInfos or {}
	if InType == UE.ESelectItemType.MarkSystem then
		self.LogicProxy = SelectMarkItemProxy
	elseif InType == UE.ESelectItemType.AvatarAction then
		self.LogicProxy = SelectAvatarActionItemProxy
	else
		self.LogicProxy = SelectConsumableItemProxy--SelectMarkItemProxy--SelectConsumableItemProxy
	end
	
	self.LogicProxy:Init(self)
	
	self:RefreshSelectDatasAndWidgets(InType, true, ShouldUseItemSlot)
	self:RefreshSelectDisplayStyle(InType)

	-- local InMsgBody = {
	-- 	bEnable = true, Type = self.CurType,
	-- }
	-- MsgHelper:Send(self, GameDefine.Msg.PLAYER_OpenSelectItem, InMsgBody)

	-- 设置输入模式/旋转控制
	if BridgeHelper.IsPCPlatform() then
		self.LocalPC:SetIgnoreLookInput(true)
		-- 设置鼠标位置
		if BridgeHelper.IsPCPlatform() then
			UIHelper.SetMouseToCenterLoc(self.LocalPC)
		end
	end
	self:UpdateInfoDetail()
	self:SetSelectItemTips(InType)
end

function SelectItem:SetSelectItemTips(InType)
	local bPCPlatform = BridgeHelper.IsPCPlatform()
	if not bPCPlatform then return end
	if InType == UE.ESelectItemType.MarkSystem then
		self.BP_SelectItem_Tips:AddActiveWidgetStyleFlags(1)
	else
		self.BP_SelectItem_Tips:RemoveActiveWidgetStyleFlags(1)
	end
end


function SelectItem:SetWidgetSlot(TargetWidget,NewAnchors,NewAlignment,NewSize,InPos, InZOrder)
	TargetWidget.Slot:SetAutoSize(false)
	TargetWidget.Slot:SetAnchors(NewAnchors)
	TargetWidget.Slot:SetAlignment(NewAlignment)
	TargetWidget.Slot:SetSize(NewSize)
	TargetWidget.Slot:SetPosition(InPos)
	TargetWidget.Slot:SetZOrder(InZOrder)
end

function SelectItem:RefreshSelectDatasAndWidgets(InType, bNeedItemSlotData, ShouldUseItemSlot)
	if InType == UE.ESelectItemType.AvatarAction then
		self.SelectDatas = self.LogicProxy.GetSelectItemIdMap(self)
	else
		self.SelectDatas = SelectItemHelper.GetSelectItemIdMap(self,"1",InType)--TODO 后续有获取 modeId 的接口后再对接
	end

	-- Create child widget
	local NewAnchors = UE.FAnchors()
	NewAnchors.Minimum = UE.FVector2D(0.5)
	NewAnchors.Maximum = UE.FVector2D(0.5)
	local NewAlignment = UE.FVector2D(0.5)
	local NewSize = UE.FVector2D(1, 1)

	local function CreateChildWidget(InChildClass, InPos, InZOrder)
		local NewChildWidget= UE.UGUIUserWidget.Create(self.LocalPC, InChildClass, self.LocalPC)
		if NewChildWidget then
			print("SelectItem>>RefreshSelectDatasAndWidgets>>CreateChildWidget>> InChildClass: ", UE.UKismetSystemLibrary.GetClassDisplayName(InChildClass), " InType: ", InType)
			self.Root:AddChild(NewChildWidget)
			self:SetWidgetSlot(NewChildWidget,NewAnchors,NewAlignment,NewSize,InPos,InZOrder)
		end
		return NewChildWidget
	end

	local SelectDatasNum = self.SelectDatas:Length()
	self.OffsetAngle = 360 / SelectDatasNum

	self.CurrentSelectArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
	for _, WidgetInfo in pairs(self.WidgetInfos) do
		if WidgetInfo and WidgetInfo.ItemInfo and WidgetInfo.WidgetLine then
			WidgetInfo.ItemInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
			WidgetInfo.WidgetLine:SetVisibility(UE.ESlateVisibility.Collapsed)
		end
	end

	-- 强引用的图不用异步加载
	if self.CurType ~= UE.ESelectItemType.MarkSystem and self.CurType ~= UE.ESelectItemType.AvatarAction then
		self.TextureList = {}
		for i = 1, SelectDatasNum do
			local Texture = self.LogicProxy.GetTexture2D(self,self.SelectDatas:Get(i))
			table.insert(self.TextureList,Texture)
		end
		self.Path2RefDes = {}
		UE.UGFUnluaHelper.AsyncLoadList(self.TextureList,function (ObjectPathList,ObjectList)
			for k,Path in pairs(ObjectPathList) do
				local Object = ObjectList[k]
				local RefProxy = UnLua.Ref(Object)
				if not self.Path2RefDes then self.Path2RefDes = {} end
				if self.Path2RefDes then
					self.Path2RefDes[Path] = {
						RefProxy = RefProxy,
						Object = Object,
					}
				end
			end
			-- 加载完显示图标
			for i = 1, self.SelectDatas:Length() do
				local WidgetInfo = self.WidgetInfos[i] or {}
				if WidgetInfo and WidgetInfo.ItemInfo then
					if WidgetInfo.ItemInfo.ImgIcon then
						local ImgIconMat = WidgetInfo.ItemInfo.ImgIcon:GetDynamicMaterial()
						local Texture = self.TextureList[i]
						if self.Path2RefDes then
							if self.Path2RefDes[Texture] then 
								if self.Path2RefDes[Texture].Object then
									local bCanSetTexture = (self.CurType ~= UE.ESelectItemType.MarkSystem) and (self.CurType ~= UE.ESelectItemType.AvatarAction)
									if bCanSetTexture then ImgIconMat:SetTextureParameterValue("BackgroundTexture", self.Path2RefDes[Texture].Object) end
								end
							end
						end
					end
					WidgetInfo.ItemInfo:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
				end
			end
		end)
	end
	
	for i = 1, SelectDatasNum do
		local WidgetInfo = self.WidgetInfos[i] or {}
		local SelectData = {}
		SelectData.Texture = self.LogicProxy.GetTexture2D(self,self.SelectDatas:Get(i))

		local TempLinePos = UE.FVector2D(0)
		local TempLineZorder = 4
		local TempInfoPos = UE.FVector2D(0, self.ItemDistance)
		local TempInfoZorder = 10
		if (not WidgetInfo.ItemInfo) and self.ChildWidgetNum < 4 then
			self.ChildWidgetNum = self.ChildWidgetNum + 1
			print("SelectItem>>Create Item Widget>> InType: ", InType, " ChildWidgetNum: ", self.ChildWidgetNum)
			WidgetInfo.WidgetLine = CreateChildWidget(self.ChildLineClass, TempLinePos, TempLineZorder)
			WidgetInfo.ItemInfo = CreateChildWidget(self.ChildInfoClass, TempInfoPos, TempInfoZorder)
		else
			self:SetWidgetSlot(WidgetInfo.WidgetLine,NewAnchors,NewAlignment,NewSize,TempLinePos, TempLineZorder)
			self:SetWidgetSlot(WidgetInfo.ItemInfo,NewAnchors,NewAlignment,NewSize,TempInfoPos, TempInfoZorder)
		end
		self.WidgetInfos[i] = WidgetInfo
		
		local NewAngle = self.OffsetAngle * (i - 1)
		print("SelectItem:InitData-->NewAngle:", NewAngle, "index:", i, "SetRenderTransformAngle param:", NewAngle + self.OffsetAngle * 0.5, "OffsetAngle:", self.OffsetAngle,"WidgetLine",WidgetInfo.WidgetLine)
		WidgetInfo.WidgetLine:SetRenderTransformAngle(NewAngle + self.OffsetAngle * 0.5)
		
		--if bNeedItemSlotData and self.SelectDatas:Get(i) == ShouldUseItemSlot.InventoryIdentity.ItemID then
			--self.CurrentSelectArrow:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
			--self.CurrentSelectArrow:SetRenderTransformAngle(NewAngle)
		--end

		local NewLoc = WidgetInfo.ItemInfo.Slot:GetPosition()
		NewLoc = UE.UKismetMathLibrary.GetRotated2D(NewLoc, NewAngle)
		WidgetInfo.ItemInfo.Slot:SetPosition(NewLoc)
		local ScaleSize = UE.FVector2D(0.85, 0.85)
		WidgetInfo.ItemInfo:SetRenderScale(ScaleSize)
		WidgetInfo.ItemInfo:InitData(SelectData, i, InType)
	end
end

function SelectItem:RefreshSelectDisplayStyle(InType)
	local ItemTexture, ItemSlateBrush, ItemMargin = SelectItemHelper.GetSelectItemDisplayStyle(self,"1",InType)
	if ItemTexture then self.ImgSelect:SetBrushFromSoftTexture(ItemTexture) end
	if ItemSlateBrush then self.VX_Select_Glow:SetBrush(ItemSlateBrush) end
	local GlowSlot = UE.UWidgetLayoutLibrary.SlotAsOverlaySlot(self.VX_Select_Glow)
	if ItemMargin then GlowSlot:SetPadding(ItemMargin) end
end

function SelectItem:UpdateSelectItemVXE(SelectIdx, bIsSelect)
	if self.CurType == UE.ESelectItemType.None then return end
	if not self.WidgetInfos then return end
	if not self.WidgetInfos[SelectIdx] then return end
	if bIsSelect then
		self.WidgetInfos[SelectIdx].ItemInfo:PlayItemSelectVXE(self.CurType, bIsSelect)
	else
		self.WidgetInfos[SelectIdx].ItemInfo:PlayItemSelectVXE(self.CurType, bIsSelect)
	end
end

-- 更新选择方向索引 已完成
function SelectItem:UpdatePresentSelectDir(InImgSpaceRotYaw,SelectIdx,SelectYaw)
	if SelectYaw ~= nil then 
		self.ImgSelect:SetRenderTransformAngle(SelectYaw) 
		self.VX_HigLight:SetRenderTransformAngle(SelectYaw) 
	end
	if InImgSpaceRotYaw ~= nil then self.TrsDir:SetRenderTransformAngle(InImgSpaceRotYaw+90) end	-- 光标位置, InImgSpaceRotYaw + 90 就是偏转角
	local NewVisible = SelectIdx and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
	self.TrsDir:SetVisibility(NewVisible)
	if self.bHidePointerArrow then 
		self.TrsDir:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.CurrentSelectArrow:SetVisibility(UE.ESlateVisibility.Collapsed) 
	end
	self.ImgSelect:SetVisibility(NewVisible)
	self.VX_HigLight:SetVisibility(NewVisible)
	self:UpdateSelectTips()
	self:UpdateSelectItemPicScale()

	if OldSelectIdx ~= SelectIdx then
		self:UpdateSelectItemVXE(OldSelectIdx, false)
		OldSelectIdx = SelectIdx
		self:VXE_Hud_Select_In()
		self:UpdateSelectItemVXE(SelectIdx, true)
	end
end

-- 手机平台更新选择方向索引
function SelectItem:UpdatePresentSelectDir_Mobile(InImgSpaceRotYaw, InPositionOffset2D,SelectIdx,SelectYaw)
	print("SelectItem:UpdateSelectDir_Moblie-->InPositionOffset2D:", InPositionOffset2D)
	if InImgSpaceRotYaw then self.TrsDir:SetRenderTransformAngle(InImgSpaceRotYaw + 90) end	-- 光标位置, InImgSpaceRotYaw + 90 就是偏转角
	-- 无效范围 -90 < X < 90 and 10 < Y < 190
	if ( (InPositionOffset2D.X < 90) and (InPositionOffset2D.X > -90) ) and ( (InPositionOffset2D.Y < 190) and (InPositionOffset2D.Y > 10) ) then
		-- 在这个范围内轮盘不算选中，要清空选择数据
		self.SelectIdx = -1
		self.ImgSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.VX_HigLight:SetVisibility(UE.ESlateVisibility.Collapsed)
		return nil
	end
	if SelectYaw then 
		self.ImgSelect:SetRenderTransformAngle(SelectYaw) 
		self.VX_HigLight:SetRenderTransformAngle(SelectYaw)
	end

	local NewVisible = (SelectIdx) and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
	self.ImgSelect:SetVisibility(NewVisible)
	self.VX_HigLight:SetVisibility(NewVisible)
	self:UpdateSelectTips()
	self:UpdateSelectItemPicScale()

	if OldSelectIdx ~= SelectIdx then
		self:UpdateSelectItemVXE(OldSelectIdx, false)
		OldSelectIdx = SelectIdx
		self:VXE_Hud_Select_In()
		self:UpdateSelectItemVXE(OldSelectIdx, true)
	end
end

-- 更新选择索引提示 有耦合 Lua
function SelectItem:UpdateSelectTips()
	if not self.LogicProxy then
		return
	end
	if not self.SelectItemTipsWidgetClass then
		return
	end

	local NameVis,DescribeVis,LVis,MVis,RVis
	if self.SelectDatas and self.SelectIdx > 0 and self.SelectIdx <= self.SelectDatas:Num() then
		local SelectInfos = self.SelectDatas:Get(self.SelectIdx)
		local NewText = self.LogicProxy.UpdateSelectName(self,SelectInfos) or ""
		local NewTip = self.LogicProxy.UpdateSelectDescribe(self,SelectInfos) or ""
		self.SelectItemTipsWidgetClass:SetItemTxtName(NewText)
		self.SelectItemTipsWidgetClass:SetTips(NewTip)
		NameVis,DescribeVis,LVis,MVis,RVis = self.LogicProxy.GetLayoutVisibility(self,SelectInfos)
	else
		NameVis,DescribeVis,LVis,MVis,RVis = self.LogicProxy.GetLayoutVisibility(self,nil)
	end
	self.SelectItemTipsWidgetClass:UpdateVisibility(NameVis, DescribeVis, LVis, MVis, RVis)
end

-- 更新选择物品的图标大小 lua
function SelectItem:UpdateSelectItemPicScale()
	if self.WidgetInfos == nil then
		print("SelectItem::UpdateSelectItemPicSize-->self.WidgetInfos == nil")
		return
	end
	self.WSwitcher_Tips:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
	local SelectDatasNum = #self.WidgetInfos
	for index = 1, SelectDatasNum do
		local TargetItemWidgetClass = self.WidgetInfos[index]
		-- 被选中的物品放大，没被选中的缩小
		if index == self.SelectIdx then			
			if TargetItemWidgetClass ~= nil then
				local OrgSize = UE.FVector2D(1.0, 1.0)
				print("SelectItem::UpdateSelectItemPicSize-->SetItemRenderScale at 100%	#fffaee")
				--TargetItemWidgetClass.ItemInfo:SetRenderScale(OrgSize)
				--TargetItemWidgetClass.ItemInfo:SetItemPicColorAndOpacity(1.0, 0.955974, 0.854993, 1.0)	-- 颜色：#fffaee
				TargetItemWidgetClass.ItemInfo:SetSelectColor()	-- 颜色：#fffaee
				--TargetItemWidgetClass.ItemInfo:SetItemPicColorAndOpacity(0.0, 0.0, 0.0, 1.0)	-- 颜色：#fffaee
			else
				print("SelectItem::UpdateSelectItemPicSize-->TargetItemWidgetClass is nil")
			end
		else
			if TargetItemWidgetClass ~= nil then				
				local ScaleSize = UE.FVector2D(0.85, 0.85)
				print("SelectItem::UpdateSelectItemPicSize-->SetItemRenderScale at 85%	#d0854d")
				--TargetItemWidgetClass.ItemInfo:SetRenderScale(ScaleSize)
				--TargetItemWidgetClass.ItemInfo:SetItemPicColorAndOpacity(0.630757, 0.234551, 0.074214, 1.0)			-- 颜色：#d0854d
				TargetItemWidgetClass.ItemInfo:SetUnselectColor()			-- 颜色：#d0854d
			else
				print("SelectItem::UpdateSelectItemPicSize-->TargetItemWidgetClass is nil")
			end
		end
		
	end	
	
end

function SelectItem:UpdateInfoDetail()
	self:RefreshSelectDatasAndWidgets(self.CurType, true)
	self:RefreshSelectDisplayStyle(self.CurType)

	local TotalNum = 0
	for i, WidgetInfo in pairs(self.WidgetInfos) do
		if WidgetInfo and WidgetInfo.ItemInfo and i<=self.SelectDatas:Length() then
			local ItemNum,NumColor = self.LogicProxy.GetNumDetail(self,self.SelectDatas:Get(i))
			local ItemName,NameColor = self.LogicProxy.GetNameDetail(self,self.SelectDatas:Get(i))
			local ItemInfiniteOnOff = self.LogicProxy.GetInfiniteDetail(self,self.SelectDatas:Get(i))
			WidgetInfo.ItemInfo:SetNumText(ItemNum,NumColor)
			WidgetInfo.ItemInfo:SetNameText(ItemName,NameColor)
			WidgetInfo.ItemInfo:SetInfiniteState(ItemInfiniteOnOff)
			WidgetInfo.ItemInfo.WidgetSwitcherNum:SetActiveWidgetIndex(1)
			if ItemNum then
				TotalNum = TotalNum + ItemNum
			end
		end
	end
	self:UpdateSelectTips()

	
	self:SetActiveItemVisble(UE.ESlateVisibility.HitTestInvisible)
	if self.CurType == UE.ESelectItemType.Medicines or  self.CurType == UE.ESelectItemType.Throw then
	--如果数量都是0，那就默认隐藏指针和选择的扇面
		if TotalNum == 0 then
			self:SetActiveItemVisble(UE.ESlateVisibility.Collapsed)
		else
			local Newidx = self:GetNewSelectIdx()
			local BaseAngle = 360/ self.SelectDatas:Num()
			local NewAngle = Newidx*BaseAngle
			--self:SetActiveItemNewAngle(NewAngle)
			print("SelectItem:UpdateInfoDetail SelectIdx",Newidx,"NewAngle",NewAngle)
			
		end 
	end
end

--[[
	触发选择(使用)物品(投掷)
	bUseItem:	True:使用物品 False:选择物品
]]
function SelectItem:TriggerPresentOperation(InItemId)
	print("SelectItem:TriggerOperation ItemId:", InItemId)
	self.LogicProxy.TriggerOperation(self,InItemId)
end

function SelectItem:OnSelectPanel_Open(InAnalogValue)
    if (not InAnalogValue) then return end
    local AnalogValue = InAnalogValue.AnalogValue
    local SelectItemType = InAnalogValue.SelectItemType
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if not BridgeHelper.IsMobilePlatform()  then
        return
    end

    if AnalogValue ~= nil then            
        local OffsetSpacePos3D = UE.FVector(AnalogValue.X, -AnalogValue.Y, 0)
        local SpaceRotYaw = UE.UKismetMathLibrary.Conv_VectorToRotator(OffsetSpacePos3D).Yaw
        local TranslationCentral = UE.FVector2D(0, 100) -- Translation 中心点是（0，100）
        local OffsetSpace2D = UE.FVector2D(OffsetSpacePos3D.X * 100, OffsetSpacePos3D.Y * 100)
        print("SelectItem", ">> OnSelectPanel_Open[3], SpaceRotYaw:", SpaceRotYaw, "OffsetSpace2D:", OffsetSpace2D)
        if self.IsFirstOpenSelectItemPanel then
            local OrigTranslation = self.SelectArrowTransform
            print("MobilePlatform:OnSelectPanel_Open -- >OrigTranslation:", OrigTranslation)
            -- 手机光标初始位置可以配置
            -- todo：SpaceRotYaw的角度影响选中
            self:UpdateSelectDir_Mobile(SpaceRotYaw, OrigTranslation)
        else
            self:UpdateSelectDir_Mobile(SpaceRotYaw, TranslationCentral + OffsetSpace2D)
        end
        self.IsFirstOpenSelectItemPanel = false
        -- 轮盘关闭时会触发，不用再此处TriggerOperation(true)
    else
        -- 实现短按直接装备当前物品的功能
        print("MobilePlatform TriggerOperation TriggerOperation",SelectItemType)
        self:TriggerOperation(true)
        if SelectItemType == UE.ESelectItemType.Throw then
            print("MobilePlatform TriggerOperation UseThrowable")
            self.LocalPC:UseThrowable()
        else
            print("MobilePlatform TriggerOperation UsePotion")
            self.LocalPC:UsePotion()
        end
    end
end

function SelectItem:OnSelectPanel_Close(InSelectItemType)
	print("SelectItem", ">> OnSelectPanel_Close, ", InSelectItemType)
    self.IsFirstOpenSelectItemPanel = true
    self:CloseSelectItemPanel()
end

-------------------------------------------- Callable ------------------------------------

function SelectItem:ChooseTriggerOperation(InMyGeometry, MouseKey, IsMouseDown)
	--return res1：是否Trigger res2：是否Handled
	--Handled是因为在UMG劫持消息，会导致EnhancedInput残留按键状态，从而导致bug --xuyanzu
	local bTrigger,bHandle = self.LogicProxy.ShouldTriggerOperation(self,MouseKey,IsMouseDown) 
	if bTrigger then
		local SelectInfos = self.SelectDatas:Get(self.SelectIdx)
		self:TriggerPresentOperation(SelectInfos)
	end
	if self.LogicProxy.ShouldClose(self,MouseKey,IsMouseDown) then
		self:CloseSelectItemPanel()
	end
	print("SelectItem::ChooseTriggerOperation",bHandle)
	return bHandle
end

function SelectItem:OnShow(InContext,InGeneicBlackboard)
	print("SelectItem:OnShow",InContext,InGeneicBlackboard)

	-- self.bIsFocusable = true
	-- self:SetFocus()



	local TxtKey = UE.FGenericBlackboardKeySelector()
    TxtKey.SelectedKeyName ="Type"
    local Type,IsFindType =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsEnum(InGeneicBlackboard,TxtKey)
	print("SelectItem:OnShow TryGetValueAsEnum",Type,IsFindType)
	self:InitSelectItemData()
	-- VX
	self:VXE_Hud_Roulette_In()
	self.CurType = Type
	if Type == UE.ESelectItemType.AvatarAction then
		self.OnAnalogValueChangeToWidgetEvent:Add(self, self.OnAnalogValueChange)
	end

	local InMsgBody = {
		bEnable = true, Type = self.CurType,
	}
	MsgHelper:Send(self, GameDefine.Msg.PLAYER_OpenSelectItem, InMsgBody)

	OldSelectIdx = self.SelectIdx
	if Type == UE.ESelectItemType.Throw or Type == UE.ESelectItemType.Medicines then
		self.ImgSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.TrsDir:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.VX_HigLight:SetVisibility(UE.ESlateVisibility.Collapsed)
	else
		self.ImgSelect:SetRenderTransformAngle(0)
		self.TrsDir:SetRenderTransformAngle(0)
		self.VX_HigLight:SetRenderTransformAngle(0)
	end
	
	if not self.SelectDatas then return end
	local SelectDatasNum = self.SelectDatas:Length()
	local BagComponent = UE.UBagComponent.Get(self.LocalPC)
	if not BagComponent then return end
	local SlotType = self.CurType == UE.ESelectItemType.Medicines and ItemSystemHelper.NItemType.Potion or ItemSystemHelper.NItemType.Throwable
	local UseItemSlot, bHasSlot = BagComponent:GetItemSlotByTypeAndSlotID(SlotType, 1)
	if not bHasSlot then return end
	if UseItemSlot.InventoryIdentity.ItemID == 0 then return end
	for i = 1, SelectDatasNum do
		local NewAngle = self.OffsetAngle * (i - 1)
		if self.SelectDatas:Get(i) == UseItemSlot.InventoryIdentity.ItemID then
			self.CurrentSelectArrow:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
			self.CurrentSelectArrow:SetRenderTransformAngle(NewAngle)
		end
	end
end

-- 轮盘隐藏
function SelectItem:OnClose(Destroy)
	if self.SelectIdx > 0 and self.SelectIdx <= self.SelectDatas:Num() then--未取消时
		local SelectInfos = self.SelectDatas:Get(self.SelectIdx)
		print("SelectItem:OnClose",self.LogicProxy, SelectInfos)
		if self.CurType == UE.ESelectItemType.MarkSystem then
			local ItemId = self.SelectDatas:IsValidIndex(self.SelectIdx) and self.SelectDatas:Get(self.SelectIdx) or self.SelectDatas:Get(1)
			local AdvanceMarkBussinessComponent = UE.UAdvanceMarkBussinessComponent.GetAdvanceMarkBussinessComponentClientOnly(self)
			if AdvanceMarkBussinessComponent and AdvanceMarkName[ItemId] and (not self.PressCancel) then
				print("SelectItem:OnMouseButtonUp ItemId",ItemId)
				AdvanceMarkBussinessComponent:HitTraceMarkByType(AdvanceMarkName[ItemId])
			else
				-- print("SelectItem:OnMouseButtonUp ItemId 1 =",ItemId)
				-- if (ItemId ~= nil) then 
				-- 	AdvanceMarkHelper.SendMarkLogMessageHelperWithItemId(self,ItemId)
				-- end
			end
		end
		if self.LogicProxy and SelectInfos and (not self.PressCancel) then
			self.LogicProxy.TriggerClose(self,SelectInfos)
		end
	end
	-- Notify
	local InMsgBody = {
		bEnable = false, Type = self.CurType,
	}
	MsgHelper:Send(self, GameDefine.Msg.PLAYER_OpenSelectItem, InMsgBody)
	self.Path2RefDes = {}

	if self.CurType == UE.ESelectItemType.AvatarAction then
		self.OnAnalogValueChangeToWidgetEvent:Remove(self, self.OnAnalogValueChange)
	end

	self.CurrentSelectArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.PressCancel = false

	if self.SelectItemViewModel then
		self.SelectItemViewModel.CurSelectItemType = UE.ESelectItemType.None;
		--self.SelectItemViewModel:ToggleNormalMarkIMC(true);
	end
end

function SelectItem:TriggerOperation(WidgetOwner,ItemId)
	local AdvanceMarkBussinessComponent = UE.UAdvanceMarkBussinessComponent.GetAdvanceMarkBussinessComponentClientOnly(WidgetOwner)
	if AdvanceMarkBussinessComponent and AdvanceMarkName[ItemId] then
		AdvanceMarkBussinessComponent:HitTraceMarkByType(AdvanceMarkName[ItemId])
	end
end

function SelectItem:OnKeyUp(_, InKeyEvent)
	local KeyName = UE.UKismetInputLibrary.GetKey(InKeyEvent).KeyName
	print("SelectItem:OnKeyUp KeyName = ", KeyName)

	if self.CurType == UE.ESelectItemType.AvatarAction then
		return UE.UWidgetBlueprintLibrary.Handled()
	end
end

-- function SelectItem:OnMouseButtonDown(InMyGeometry, InMouseEvent)
-- 	local KeyName = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(InMouseEvent).KeyName
-- 	if KeyName == "MiddleMouseButton" then--标记

-- 		local ItemId = self.SelectDatas:Get(self.SelectIdx)
-- 			local AdvanceMarkBussinessComponent = UE.UAdvanceMarkBussinessComponent.GetAdvanceMarkBussinessComponentClientOnly(self)
-- 			if AdvanceMarkBussinessComponent and AdvanceMarkName[ItemId] then
-- 				AdvanceMarkBussinessComponent:HitTraceMarkByType(AdvanceMarkName[ItemId])
-- 			else
				
-- 				local ItemNum,NumColor = self.LogicProxy.GetNumDetail(self,self.SelectDatas:Get(self.SelectIdx))

-- 				if(ItemNum > 0) then
-- 					local ItemTypeName = AdvanceMarkHelper.GetMarkLogItemTypeName(self, ItemId)
-- 					AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(self, ItemId, ItemTypeName)
-- 				else
-- 					AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemTypeId(self, ItemId)
-- 				end

-- 				--AdvanceMarkHelper.SendMarkLogMessageHelperWithItemId(self,ItemId)
-- 			end

-- 		if self.CurType == UE.ESelectItemType.MarkSystem then
			
-- 		else
-- 			--return UE.UWidgetBlueprintLibrary.UnHandled()
-- 		end


-- 	elseif KeyName == "RightMouseButton" then--取消
-- 		self.SelectIdx = -1
-- 		print("SelectItem:OnMouseButtonDown SelectIdx = -1")
-- 	end

-- 	print("SelectItem", ">> OnMouseButtonDown, ...", GetObjectName(self), InMyGeometry, KeyName)
-- 	local bShouldHandle = self:ChooseTriggerOperation(InMyGeometry, KeyName, true)
-- 	return UE.UWidgetBlueprintLibrary.UnHandled()
-- end

function SelectItem:SelectItemMark(Input)

	if self.CurType == UE.ESelectItemType.Medicines or self.CurType == UE.ESelectItemType.Throw then
		local ItemId = self.SelectDatas:Get(self.SelectIdx)
		local AdvanceMarkBussinessComponent = UE.UAdvanceMarkBussinessComponent.GetAdvanceMarkBussinessComponentClientOnly(self)
		if AdvanceMarkBussinessComponent and AdvanceMarkName[ItemId] then
			AdvanceMarkBussinessComponent:HitTraceMarkByType(AdvanceMarkName[ItemId])
		else
			
			local ItemNum,NumColor = self.LogicProxy.GetNumDetail(self,self.SelectDatas:Get(self.SelectIdx))

			if(ItemNum > 0) then
				local ItemTypeName = AdvanceMarkHelper.GetMarkLogItemTypeName(self, ItemId, true)
				AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(self, ItemId, ItemTypeName)
			else
				AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemTypeId(self, ItemId)
			end
			
			self:CloseSelectItemPanel()
			--AdvanceMarkHelper.SendMarkLogMessageHelperWithItemId(self,ItemId)
		end

	end
end

function SelectItem:SelectItemConfirm(Input)

	if self.CurType == UE.ESelectItemType.Medicines or self.CurType == UE.ESelectItemType.Throw or self.CurType == UE.ESelectItemType.AvatarAction then
		local SelectInfos = self.SelectDatas:Get(self.SelectIdx)
		self:TriggerPresentOperation(SelectInfos)
		self:CloseSelectItemPanel()
	end

end


function SelectItem:OnAnalogValueChange(InIsLeft, InValue, InIsXValue, InIsAdd)
	-- print("[yddhu]SelectItem:OnAnalogValueChange. InIsAdd = ", InIsAdd)
	if self.CurType == UE.ESelectItemType.AvatarAction and InIsLeft == false and InIsAdd == false then
		-- IA轮盘通过松开手柄右摇杆触发
		self:ChooseTriggerOperation(nil, "Gamepad_RightStick_Release", true)
	end
end

function SelectItem:OnAvatarActionGamepadLeftShoulder(_)
	print("[yddhu]SelectItem:OnAvatarActionGamepadLeftShoulder.")
	
	if self.CurType == UE.ESelectItemType.AvatarAction then
		self.LogicProxy.SwitchCurrentSelectIndex(true)
		self:RefreshSelectDatasAndWidgets(self.CurType, false)
		self:UpdateInfoDetail()
	end
end

function SelectItem:OnAvatarActionGamepadRightShoulder(_)
	print("[yddhu]SelectItem:OnAvatarActionGamepadRightShoulder.")
	
	if self.CurType == UE.ESelectItemType.AvatarAction then
		self.LogicProxy.SwitchCurrentSelectIndex(false)
		self:RefreshSelectDatasAndWidgets(self.CurType, false)
		self:UpdateInfoDetail()
	end
end

function SelectItem:SetActiveItemVisble(type)
	self.WSwitcher_Tips:SetVisibility(type)
	self.TrsDir:SetVisibility(type)
	self.ImgSelect:SetVisibility(type)
	self.VX_HigLight:SetVisibility(type)
end

function SelectItem:SetActiveItemNewAngle(NewAngle)
	self.TrsDir:SetRenderTransformAngle(NewAngle)
	self.ImgSelect:SetRenderTransformAngle(NewAngle)
	self.VX_HigLight:SetRenderTransformAngle(NewAngle)
end

function SelectItem:OnCloseSelectItemPanel()

	self.PressCancel = true
	self:CloseSelectItemPanel()
end

return SelectItem
