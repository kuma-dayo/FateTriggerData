require "UnLua"

local SettingMultipleChoiceItem = Class("Common.Framework.UserWidget")

function SettingMultipleChoiceItem:OnInit()
    self.MsgListGMP = 
    {
       
    }
    MsgHelper:RegisterList(self, self.MsgListGMP)

    self.Button_Left.OnClicked:Add(self, Bind(self,self.OnChangeIndex_Sub))
    self.Button_Right.OnClicked:Add(self, Bind(self,self.OnChangeIndex_Add))
    UserWidget.OnInit(self)
    
end

function SettingMultipleChoiceItem:OnDestroy()
   
	
    UserWidget.OnDestroy(self)
end


function SettingMultipleChoiceItem:SetHoverStyle()
   
    UE.UGTSoundStatics.PostAkEvent(self, self.HoverSound)
    
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.TextBlock_Title:SetColorAndOpacity(self.TextHoverColor)
    self.TextBlockContent:SetColorAndOpacity(self.TextHoverColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.Collapsed)
    local ChildWidget = self.ItemHorizontalBox:GetChildAt(self.ActivateIndex)
    if ChildWidget then
        ChildWidget.WidgetSwitcher:SetActiveWidgetIndex(2)
    end
    

    --通知detail更新
     local data =
    {
        InTag = self.ParentTag,
        IsShowTableDetailWidget = false,
        InBlackboard = UE.FGenericBlackboardContainer()
    }
    MsgHelper:Send(self, "UIEvent.ChangeDetailContent",data)
end


function SettingMultipleChoiceItem:SetNormalStyle()
    
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TextBlock_Title:SetColorAndOpacity(self.TextOriginalColor)
    self.TextBlockContent:SetColorAndOpacity(self.TextOriginalColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local ChildWidget = self.ItemHorizontalBox:GetChildAt(self.ActivateIndex)
    if ChildWidget then
        ChildWidget.WidgetSwitcher:SetActiveWidgetIndex(1)
    end
    

    
    
end


-- 鼠标按键移入
function SettingMultipleChoiceItem:OnMouseEnter(InMyGeometry, InMouseEvent)
    
    self:SetHoverStyle()
    --通知detail更新
   
end


-- 鼠标按键移出
function SettingMultipleChoiceItem:OnMouseLeave(InMouseEvent)
    
	self:SetNormalStyle()
end





function SettingMultipleChoiceItem:OnChangeIndex_Sub()
    self:ChangeChoiceStatus(self.ActivateIndex-1)
end


function SettingMultipleChoiceItem:OnChangeIndex_Add()
    self:ChangeChoiceStatus(self.ActivateIndex+1)
end

function SettingMultipleChoiceItem:ChangeChoiceStatus(InNum)
    if InNum<0 then
        return

    elseif InNum >=self.IsUsingNum then
        return
    end
    local ChildWidget =self.ItemHorizontalBox:GetChildAt(self.ActivateIndex)
    if ChildWidget then
        ChildWidget.WidgetSwitcher:SetActiveWidgetIndex(0)
        self.ActivateIndex = InNum
        ChildWidget =self.ItemHorizontalBox:GetChildAt(InNum)
        ChildWidget.WidgetSwitcher:SetActiveWidgetIndex(1)
        self.TextBlockContent:SetText(ChildWidget.ShowText)

        local NewSettingValue = UE.FSettingValue()
        NewSettingValue.Value_Int = self.ActivateIndex
        local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
        SettingSubsystem:ApplySetting(self.ParentTag.TagName,NewSettingValue)
    end
end


function SettingMultipleChoiceItem:RefreshItemContent(ItemContent)
    if ItemContent ==nil then
        local ErrorTypeStr = StringUtil.FormatSimple("SettingMultipleChoiceItem:RefreshItemContent ItemContent is nil")
        EnsureCall(ErrorTypeStr)
        return
    end
    print("SettingMultipleChoiceItem:RefreshItemContent DefaultValue",ItemContent.DefaultValue,self.ParentTag.TagName,ItemContent.TextArray:Num(),ItemContent.KeyArray:Num())
    if ItemContent.DefaultValue <0 then
        return
    end
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    
    --先复原原来的item
    local ChildWidget =self.ItemHorizontalBox:GetChildAt(self.ActivateIndex)
    if ChildWidget then
        ChildWidget.WidgetSwitcher:SetActiveWidgetIndex(0)
    end
   
    for i = 0,self.ItemHorizontalBox:GetChildrenCount()-1 do 
        ChildWidget=self.ItemHorizontalBox:GetChildAt(i)
        ChildWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end 
    --需要刷新的话，数组的数量一定不能小于0
    --如果数组的值等于0，代表只需要刷新默认值
    --如果数组的个数比现有的item多，先创建足够的数量
   
    if ItemContent.TextArray:Num()>self.ItemHorizontalBox:GetChildrenCount() then
        local Num= ItemContent.TextArray:Num() -self.ItemHorizontalBox:GetChildrenCount()
        for i=1, Num do
            ChildWidget =  UE.UGUIUserWidget.Create(self.LocalPC, self.ChocieClass, self.LocalPC)
            if ChildWidget then
                ChildWidget.ShowText = ItemContent.TextArray:GetRef(ItemContent.TextArray:Num()-Num+i)
                self.ItemHorizontalBox:AddChild(ChildWidget)
                ChildWidget.Slot:SetSize(UE.FSlateChildSize())
            end
            
        end

    elseif ItemContent.TextArray:Num()<= 0 then
        if ItemContent == UE.FSettingItemReturnValue() then
            return 
        end
       

    else
        --如果有多余的item，将他隐藏
        for i = ItemContent.TextArray:Num(),self.ItemHorizontalBox:GetChildrenCount()-1 do 
            ChildWidget=self.ItemHorizontalBox:GetChildAt(i)
            ChildWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end 
    end
    --将已有的Item的文本换回来
    self.ActivateIndex = ItemContent.DefaultValue
    if ItemContent.TextArray:Num() >0 then
        for i =1 ,ItemContent.TextArray:Num() do
            ChildWidget = self.ItemHorizontalBox:GetChildAt(i-1)
            if ChildWidget then
                ChildWidget.ShowText = ItemContent.TextArray:GetRef(i)
            end
        end
        self.IsUsingNum = ItemContent.TextArray:Num()
    end
    
    ChildWidget = self.ItemHorizontalBox:GetChildAt(self.ActivateIndex)
    if ChildWidget then
        ChildWidget.WidgetSwitcher:SetActiveWidgetIndex(2)
        self.TextBlockContent:SetText(ChildWidget.ShowText)
    end
    if ItemContent.KeyArray:Num() >0 then
        self.IsUsingNum = self.ItemHorizontalBox:GetChildrenCount()- ItemContent.KeyArray:Num()   
        for i,v in pairs(ItemContent.KeyArray) do 
            
            ChildWidget = self.ItemHorizontalBox:GetChildAt(v)
            if ChildWidget then
                ChildWidget.WidgetSwitcher:SetActiveWidgetIndex(3)
            end
        end
        print("SettingMultipleChoiceItem:RefreshItemContent self.IsUsingNum",self.IsUsingNum)
    end
    self:ChangeChoiceStatus(self.ActivateIndex)
end


function SettingMultipleChoiceItem:OnFocusReceived(MyGeometry,InFocusEvent)
    self:SetHoverStyle()
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingMultipleChoiceItem:OnFocusLost(InFocusEvent)
    self:SetNormalStyle()
end

return SettingMultipleChoiceItem
