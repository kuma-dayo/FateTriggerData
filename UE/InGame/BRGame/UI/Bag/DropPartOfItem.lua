require "UnLua"
require ("Common.Utils.StringUtil")

local DropPartOfItem = Class()

function DropPartOfItem:Initialize(Initializer)
    self.ItemID = 0
    self.ItemInstanceID = 0
    self.CurrentNum = 0
    self.MinNum = 0
    self.MaxNum = 0

end

function DropPartOfItem:Construct()
	self.MsgList = {
		{ MsgName = GameDefine.Msg.PLAYER_ToggleDropPartOfItem,     Func = self.ToggleDropPartOfItem,   bCppMsg = false }
    }
	MsgHelper:RegisterList(self, self.MsgList)
    
    self.PlayerBagViewModel = UE.UGUIManager.GetUIManager(self):GetViewModelByName("ViewModel_PlayerBag")
    self.Button_Drop.OnClicked:Add(self, self.OnDropClick)
    self.Button_Cancle.OnClicked:Add(self, self.OnCancleClick)
    self.Button_Min.OnClicked:Add(self, self.OnMinClick)
    self.Button_Max.OnClicked:Add(self, self.OnMaxClick)
    self.Text_Current.OnTextCommitted:Add(self, self.OnCurrentTextCommitted)
    self.Text_Current.OnTextChanged:Add(self, self.OnCurrentTextChanged)
    self.Slider_Nums.OnValueChanged:Add(self, self.OnSlideValueChanged)
    self.Button_Drop.OnHovered:Add(self,self.OnButton_DropHoverd)
    self.Button_Drop.OnUnhovered:Add(self,self.OnButton_DropUnhoverd)
    self.Button_Cancle.OnHovered:Add(self,self.OnButton_CancleHoverd)
    self.Button_Cancle.OnUnhovered:Add(self,self.OnButton_CancleUnhoverd)
    self.WhiteColor = self.ButtonContentColorMap:Find("White")
    self.BlackColor = self.ButtonContentColorMap:Find("Black")

end

function DropPartOfItem:Destruct()
	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end

    --self:Release()
end




function DropPartOfItem:OnDropClick()
    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = self.ItemID
    TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local tPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if tPC then
        local TempDiscardReasonTag = UE.FGameplayTag()
        TempDiscardReasonTag.TagName = "InventoryItem.Reason.DiscardActively"
        UE.UItemStatics.DiscardItem(tPC, TempInventoryIdentity, self.CurrentNum, TempDiscardReasonTag)
        local UIManager = UE.UGUIManager.GetUIManager(self)
        local bClose = UIManager:TryCloseDynamicWidget("UMG_DropItem")
        -- self:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.bIsFocusable = false
        -- self:UpdateEnabled(false)
    end
end

function DropPartOfItem:OnCancleClick()
    local UIManager = UE.UGUIManager.GetUIManager(self)
    local bClose = UIManager:TryCloseDynamicWidget("UMG_DropItem")
    -- self:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.bIsFocusable = false
    -- self:UpdateEnabled(false)
end

function DropPartOfItem:OnMinClick()
    self.CurrentNum = self.MinNum
    self.CurrentNum = UE.UKismetMathLibrary.Clamp(math.floor(self.CurrentNum),1,math.floor(self.MaxNum))
    self.Text_Current:SetText(self.CurrentNum)
    self.Slider_Nums:SetValue(self.CurrentNum)
    self:SetProgPercent(self.CurrentNum,self.MinNum,self.MaxNum)
end

function DropPartOfItem:OnMaxClick()
    self.CurrentNum = self.MaxNum
    self.CurrentNum = UE.UKismetMathLibrary.Clamp(math.floor(self.CurrentNum),1,math.floor(self.MaxNum))
    self.Text_Current:SetText(self.CurrentNum)
    self.Slider_Nums:SetValue(self.CurrentNum)
    self:SetProgPercent(self.CurrentNum,self.MinNum,self.MaxNum)
end

function DropPartOfItem:OnCurrentTextCommitted(InText, CommitMethod)
    local text = UE.UKismetTextLibrary.Conv_TextToString(InText)
    self.CurrentNum = UE.UKismetStringLibrary.Conv_StringToInt(text)
    self.CurrentNum = UE.UKismetMathLibrary.Clamp(math.floor(self.CurrentNum),1,math.floor(self.MaxNum))
    self:SetProgPercent(self.CurrentNum,self.MinNum,self.MaxNum)
    self.Text_Current:SetText(self.CurrentNum)
    self.Slider_Nums:SetValue(self.CurrentNum)
end

function DropPartOfItem:OnSlideValueChanged(InValue)
    print("DropPartOfItem >> OnSlideValueChanged > InValue :",InValue)
    local tCurrentNum = InValue
    local tIntNum = UE.UKismetMathLibrary.FCeil(tCurrentNum)
    self.Slider_Nums:SetValue(tIntNum)
    self.CurrentNum = UE.UKismetMathLibrary.Clamp(math.floor(tIntNum),1,math.floor(self.MaxNum))
    self:SetProgPercent(self.CurrentNum,self.MinNum,self.MaxNum)
    self.Text_Current:SetText(self.CurrentNum)
end

function DropPartOfItem:ToggleDropPartOfItem(InMsgBody)
    self:UpdateEnabled(InMsgBody.isShow)
    self.bIsFocusable = InMsgBody.isShow
    if InMsgBody.isShow then
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:Init(InMsgBody.ItemID,InMsgBody.InstanceID,InMsgBody.MinNum,InMsgBody.MaxNum,InMsgBody.CurrentNum)
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    print("DropPartOfItem >> ToggleDropPartOfItem")
end

function DropPartOfItem:OnShow(InContext,InGeneicBlackboard)
    print("[Wzp]DropPartOfItem >> OnShow")

    local ItemIDValue,ItemIDResult = self:GetBlackboardIntValue(InGeneicBlackboard,"ItemID")
    local InstanceIDValue,InstanceIDResult = self:GetBlackboardIntValue(InGeneicBlackboard,"InstanceID")
    local MinNumValue,MinNumResult = self:GetBlackboardIntValue(InGeneicBlackboard,"MinNum")
    local MaxNumValue,MaxNumResult = self:GetBlackboardIntValue(InGeneicBlackboard,"MaxNum")
    local CurrentNumValue,CurrentNumResult = self:GetBlackboardIntValue(InGeneicBlackboard,"CurrentNum")
    if ItemIDResult and InstanceIDResult and MinNumResult and MaxNumResult and CurrentNumResult then
        self.PlayerBagViewModel:SetDropPartOfItemCache(ItemIDValue,InstanceIDValue,MinNumValue,MaxNumValue,CurrentNumValue)
        self:Init(ItemIDValue,InstanceIDValue,MinNumValue,MaxNumValue,CurrentNumValue)
    else
        ItemIDValue,InstanceIDValue,MinNumValue,MaxNumValue,CurrentNumValue = self.PlayerBagViewModel:GetDropPartOfItemCache()
        self:Init(ItemIDValue,InstanceIDValue,MinNumValue,MaxNumValue,CurrentNumValue)
    end
    local S1InputSystem = UE.US1InputSubsystem.Get(self)
    if S1InputSystem then
        S1InputSystem:SetHasOpenDropPartOfItem(true)
    end
end

function DropPartOfItem:GetBlackboardIntValue(InGeneicBlackboard,KeyName)
    local KeySelector = UE.FGenericBlackboardKeySelector()
    KeySelector.SelectedKeyName = KeyName
    local Value, Result  = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(InGeneicBlackboard,KeySelector)
    return  Value, Result
end


function DropPartOfItem:Init(InItemID, InInstanceID, InMinNum, InMaxNum, InCurrentNum)
    self.ItemID = InItemID
    self.ItemInstanceID = InInstanceID
    self.CurrentNum = InCurrentNum
    self.MinNum = InMinNum
    self.MaxNum = InMaxNum

    local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(self)
    local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(InItemID, "Ingame")
    if not SubTable then return end
    local StrItemID = tostring(InItemID)

    -- 显示物品名称
    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, InItemID)
    if not IngameDT then
        return
    end

    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, StrItemID)
    if not StructInfo_Item then
        return
    end

    local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
    self.TextBlock_ItemName:SetText(TranslatedItemName)
    
    -- 显示图片
    local ItemIcon, RetItemIcon = SubTable:BP_FindDataFString(StrItemID,"ItemIcon")
    if RetItemIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(ItemIcon)
        self.Image_Item:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
    end
    --显示最小值最大值
    self.TextBlock_Min:SetText(InMinNum)
    self.TextBlock_Max:SetText(InMaxNum)


    --调整slider
    self.CurrentNum = UE.UKismetMathLibrary.Clamp(math.floor(self.CurrentNum),math.floor(self.MinNum),math.floor(self.MaxNum))  
    self.Slider_Nums:SetValue(self.CurrentNum)
    self.Slider_Nums:SetMinValue(self.MinNum)
    self.Slider_Nums:SetMaxValue(self.MaxNum)
    self:SetProgPercent(self.CurrentNum,self.MinNum,self.MaxNum)
    self.Text_Current:SetText(self.CurrentNum)
    
end

function DropPartOfItem:AddCurrentNum(InNumOffset)
    self.CurrentNum = self.CurrentNum + InNumOffset
    self.CurrentNum = UE.UKismetMathLibrary.Clamp(self.CurrentNum,1,self.MaxNum)
    self.Text_Current:SetText(self.CurrentNum)
    self.Slider_Nums:SetValue(self.CurrentNum)
end

function DropPartOfItem:OnMouseWheel(MyGeometry, MouseEvent)
    if self:IsVisible() then
        local WheelDelta = UE.UKismetInputLibrary.PointerEvent_GetWheelDelta(MouseEvent)
        if WheelDelta > 0 then
            self:AddCurrentNum(1)
        elseif WheelDelta < 0 then
            self:AddCurrentNum(-1)
        end
        self:SetProgPercent(self.CurrentNum,self.MinNum,self.MaxNum)
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function DropPartOfItem:SetProgPercent(CurrentValue,MinValue,MaxValue)
    local percent = (CurrentValue-MinValue) / (MaxValue-MinValue)
    print("DropPartOfItem >> SetProgPercent > MinValue:",MinValue,"MaxValue:",MaxValue)
    self.SoliderProgFill:SetPercent(percent)
end

function DropPartOfItem:OnButton_CancleHoverd()
    local HVBox = self.Button_Cancle:GetChildAt(0)
    local ButtonText = HVBox:GetChildAt(1)
    local BtnTextColor = self.ButtonColorMap:Find("Hoverd")
    ButtonText:SetColorAndOpacity(BtnTextColor)
    self.GUIImage_CancelBg:SetColorAndOpacity(self.BlackColor)
    self.GUIImage_CancelKey:SetColorAndOpacity(self.WhiteColor)
end

function DropPartOfItem:OnButton_CancleUnhoverd()
    local HVBox = self.Button_Cancle:GetChildAt(0)
    local ButtonText = HVBox:GetChildAt(1)
    local BtnTextColor = self.ButtonColorMap:Find("Unhoverd")
    ButtonText:SetColorAndOpacity(BtnTextColor)
    self.GUIImage_CancelBg:SetColorAndOpacity(self.WhiteColor)
    self.GUIImage_CancelKey:SetColorAndOpacity(self.BlackColor)
end

function DropPartOfItem:OnButton_DropHoverd()
    local HVBox = self.Button_Drop:GetChildAt(0)
    local ButtonText = HVBox:GetChildAt(1)
    local BtnTextColor = self.ButtonColorMap:Find("Hoverd")
    ButtonText:SetColorAndOpacity(BtnTextColor)
    self.GUIImage_ThrowBg:SetColorAndOpacity(self.BlackColor)
    self.GUIImage_ThrowKey:SetColorAndOpacity(self.WhiteColor)
end

function DropPartOfItem:OnButton_DropUnhoverd()
    local HVBox = self.Button_Drop:GetChildAt(0)
    local ButtonText = HVBox:GetChildAt(1)
    local BtnTextColor = self.ButtonColorMap:Find("Unhoverd")
    ButtonText:SetColorAndOpacity(BtnTextColor)
    self.GUIImage_ThrowBg:SetColorAndOpacity(self.WhiteColor)
    self.GUIImage_ThrowKey:SetColorAndOpacity(self.BlackColor)
end



function DropPartOfItem:OnKeyDown(MyGeometry,InKeyEvent)
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    print("DropPartOfItem >> OnKeyDown")
    if PressKey == self.PC_DropKey or PressKey == self.GamePad_PlayStation_DropKey or PressKey == self.GamePad_XBox_DropKey then
        print("DropPartOfItem >> OnDropClick")
        self:OnDropClick()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif PressKey == self.PC_CancelKey or  PressKey == self.PlayStation_CancelKey or PressKey == self.GamePad_XBox_CancelKey then
        print("DropPartOfItem >> OnCancleClick")
        self:OnCancleClick()
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end


function DropPartOfItem:OnDestroy()
    self.Button_Drop.OnClicked:Clear()
    self.Button_Cancle.OnClicked:Clear()
    self.Button_Min.OnClicked:Clear()
    self.Button_Max.OnClicked:Clear()
    self.Text_Current.OnTextCommitted:Clear()
    self.Slider_Nums.OnValueChanged:Clear()
    self.Button_Drop.OnHovered:Clear()
    self.Button_Drop.OnUnhovered:Clear()
    self.Button_Cancle.OnHovered:Clear()
    self.Button_Cancle.OnUnhovered:Clear()
end

function DropPartOfItem:OnCurrentTextChanged(Text)
    print("DropPartOfItem >> OnCurrentTextChanged")

    local number = tonumber(Text)
    if number then
        self.Text_Current:SetText(number)
    else
        self.Text_Current:SetText("")
    end
end

return DropPartOfItem