
require "UnLua"
local class_name = "CustomMainUI"
CustomMainUI = CustomMainUI or BaseClass(GameMediator, class_name);



function CustomMainUI:__init()
    print("CustomMainUI:__init")
    self:ConfigViewId(ViewConst.CustomMainUI)
  
end




local CustomMainUI =Class("Client.Mvc.UserWidgetBase")
function CustomMainUI:OnInit()
    --if UE.UGFUnluaHelper.IsEditor() then
        -- self.BindNodes ={
        --     { UDelegate = self.SettingLayoutControl.Button_Select.OnReleased, Func = self.OnChangeShowAdjustorList},
        --     { UDelegate = self.SettingLayoutControl.Button_ShowDetail.OnReleased, Func = self.OnChangeContentControlShow },
        --     { UDelegate = self.SettingLayoutControl.Button_Close.OnReleased, Func = self.OnClicked_CloseCustomLayout },
        --     }
    --else
        self.SettingLayoutControl.Button_Close.OnClicked:Add(self, self.OnClicked_CloseCustomLayout)
        self.SettingLayoutControl.Button_ShowDetail.OnClicked:Add(self, self.OnChangeContentControlShow)
        self.SettingLayoutControl.Button_Select.OnClicked:Add(self, self.OnChangeShowAdjustorList)
        self.SettingLayoutControl.Button_Hide.OnClicked:Add(self, self.OnChangeItemBan)
        self.SettingLayoutControl.Button_Save.OnClicked:Add(self, self.OnSaveLayoutData)
        self.SettingLayoutControl.Slider_Size.OnValueChanged:Add(self, self.OnSlideSizeValueChanged)
        self.SettingLayoutControl.Slider_Opacity.OnValueChanged:Add(self, self.OnSlideOpacityValueChanged)
        self.SettingLayoutControl.Button_Right.BtnClick.OnClicked:Add(self, self.SetActiveItemMoveRightClicked)
        self.SettingLayoutControl.Button_Left.BtnClick.OnClicked:Add(self, self.SetActiveItemMoveLeftClicked)
        self.SettingLayoutControl.Button_Up.BtnClick.OnClicked:Add(self, self.SetActiveItemMoveUpClicked)
        self.SettingLayoutControl.Button_Down.BtnClick.OnClicked:Add(self, self.SetActiveItemMoveDownClicked)
        self.SettingLayoutControl.Button_ReCall.OnClicked:Add(self, self.OnClickedReCall)
        self.SettingLayoutControl.Button_Reset.OnClicked:Add(self, self.OnClickedReset)
        self.SettingLayoutControl.Button_ChangeLayout.OnClicked:Add(self, self.OnSelectLayout)
        
    -- end
    self.BindNodes ={
        {UDelegate = self.SettingLayoutControl.Slider_Size.OnControllerCaptureEnd,Func = self.OnSlideSizeCaptureEnd},
        {UDelegate = self.SettingLayoutControl.Slider_Size.OnMouseCaptureEnd,Func = self.OnSlideSizeCaptureEnd},
        {UDelegate = self.SettingLayoutControl.Slider_Opacity.OnControllerCaptureEnd,Func = self.OnSlideOpacityCaptureEnd},
        {UDelegate = self.SettingLayoutControl.Slider_Opacity.OnMouseCaptureEnd,Func = self.OnSlideOpacityCaptureEnd},
        {UDelegate = self.SettingLayoutControl.Slider_Size.OnControllerCaptureBegin,Func = self.OnSlideSizeCaptureBegin},
        {UDelegate = self.SettingLayoutControl.Slider_Size.OnMouseCaptureBegin,Func = self.OnSlideSizeCaptureBegin},
        {UDelegate = self.SettingLayoutControl.Slider_Opacity.OnControllerCaptureBegin,Func = self.OnSlideOpacityCaptureBegin},
        {UDelegate = self.SettingLayoutControl.Slider_Opacity.OnMouseCaptureBegin,Func = self.OnSlideOpacityCaptureBegin},
    }
    
    
    self.MsgListGMP = {
        { MsgName = "UIEvent.ChangeActiveItem", Func = self.ChangeActiveItem,      bCppMsg = false},
        { MsgName = "UIEvent.ChangeActiveTabSelectItem", Func = self.ChangeActiveTabSelectItem,      bCppMsg = false},
        { MsgName = "EnhancedInput.MobileLayoutMoveRight",	Func = self.SetActiveItemMoveRightPressed,   bCppMsg = true},
        { MsgName = "EnhancedInput.MobileLayoutMoveLeft",	Func = self.SetActiveItemMoveLeftPressed,   bCppMsg = true},
        { MsgName = "EnhancedInput.MobileLayoutMoveUp",	Func = self.SetActiveItemMoveUpPressed,   bCppMsg = true},
        { MsgName = "EnhancedInput.MobileLayoutMoveBottom",	Func = self.SetActiveItemMoveBottomPressed,   bCppMsg = true},
        { MsgName = "UIEvent.GenerateScreenshot",	Func = self.SuccessGenerateScreenshot,   bCppMsg = true},
        { MsgName = "UIEvent.NotifyItemDrop", Func = self.NotifyItemDrop,      bCppMsg = false},
        { MsgName = "UIEvent.NotifyCallSaveLayout", Func = self.OnSaveLayoutData,      bCppMsg = false},
        { MsgName = "UIEvent.NotifyChangeLayout", Func = self.OnChangeLayout,      bCppMsg = false},
        
    }
    MsgHelper:OpDelegateList(self, self.BindNodes, true)
    --self.Button_Custom.OnClicked:Add(self, self.OnClicked_OpenCustomLayout)
    UserWidgetBase.OnInit(self)
    self.ActiveItemIndex =nil
    
    self:InitData()
    
end



function CustomMainUI:InitData()
    --初始化控制面板的button
   self:InitTabSelectItem()
   local widget = nil
   --初始化每个widget的信息，1、在Itembox的index；2、在当层是否可被编辑
   for i = 2, self.ItemBox:GetChildrenCount()-1 do
    widget = self.ItemBox:GetChildAt(i)
    self.CustomWidgetArray:Add(widget)
    widget.ItemInBoxInedx = i
    widget.MyParent = self
    end
    
    
end

function CustomMainUI:OnShow(data,InGenericBlackboard)
   
    --设置背景，大厅用默认背景图，局内背景直接透明
    --读取布局数据
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        if InGenericBlackboard then
            local LayoutIndex,IsFindLayoutIndex =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsIntSimple(InGenericBlackboard,"LayoutIndex")
            if IsFindLayoutIndex == true then
                self.LayoutIndex = LayoutIndex
            end
            local NewText,IsFindNewText =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsStringSimple(InGenericBlackboard,"NewText")
            if IsFindNewText == true then
                self.SettingLayoutControl.Text_Default:SetText(NewText)
            end
            self.Image_Bg:SetColorandOpacity(self.InBattleColor)
        end
       
    else
        if data then
            self.LayoutIndex = data.LayoutIndex
            self.Image_Bg:SetColorandOpacity(self.InHallBgColor)
            self.SettingLayoutControl.Text_Default:SetText(data.NewText)
        end
        
    end
    print("CustomMainUI:OnShow",data,InGenericBlackboard, self.LayoutIndex )
    
   self:InitItemData(false)
    --初始化给默认的item进行初始化
   self.ItemBox:GetChildAt(self.DefaultActiveItemIndex):OnDragDetected(nil,nil,nil)
  
end


function CustomMainUI:InitItemData(IsFromReset)
      --设置控制面板基本参数
    self.SettingLayoutControl:RemoveAllActiveWidgetStyleFlags()
    self.SettingLayoutControl:AddActiveWidgetStyleFlags(2)
    self.SettingLayoutControl.WidgetSwitcher_ReCall:SetActiveWidgetIndex(1)
    self:ClearRecordLayoutDataArray()
    local MobileCustomLayoutData = UE.UGenericSettingSubsystem.Get(self):GetMobileCustomLayoutDataByLayoutIndex(self.LayoutIndex,IsFromReset)
    local widget = nil
    --初始化每个widget的信息，1、在Itembox的index；2、在当层是否可被编辑
  
    local data = UE.FSettingLayoutItemSaveData()
    for i = 2, self.ItemBox:GetChildrenCount()-1 do
        widget = self.ItemBox:GetChildAt(i)
       
        data = MobileCustomLayoutData:FindRef(widget.MyLayoutData.ItemLayoutTagName)
        widget:RevertAllStyle()
        if data and data.ItemLayoutTagName ~= "None" then
            widget:InitBaseData(data)
            widget:RefreshItemShowBan()
            print("CustomMainUI:InitItemData",data.ItemLayoutTagName)
        end
     end
     
       
end

function CustomMainUI:InitTabSelectItem()
    local ChildWidget = self.SettingLayoutControl.Panel_SeletDetail:GetChildAt(self.ActiveTabIndex)
    ChildWidget.WidgetSwitcher:SetActiveWidgetIndex(1)
    local data = {
        ButtonTxt = ChildWidget.Text,
        Index = ChildWidget.LayerId,
        Brush = ChildWidget.Image_Select,
        IsFromInit = true
    }
    self:ChangeActiveTabSelectItem(data)
end

function CustomMainUI:OnClicked_CloseCustomLayout()
    
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        if self:IsHasRecordLayoutData() == true then
            UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("Setting.CustomLayoutConfirm")
            return
        end
        UE.UGUIManager.GetUIManager(self):TryCloseDynamicWidget("UMG_MobileCustomLayout")
    else
        if self:IsHasRecordLayoutData() == true then
            MvcEntry:OpenView(ViewConst.CustomLayoutConfirm)
            return
        end
        MvcEntry:CloseView(self.viewId)
    end
    local data ={
        IsShow = true
    }
    MsgHelper:Send(self, "UIEvent.SettingIsShow",data)
end

function CustomMainUI:OnChangeShowAdjustorList()
    if self.SettingLayoutControl:HasActiveWidgetStyleFlags(2) then
        self.SettingLayoutControl.WidgetSwitcher_Select:SetActiveWidgetIndex(1)
        self.SettingLayoutControl:RemoveActiveWidgetStyleFlags(2)
        self.SettingLayoutControl:AddActiveWidgetStyleFlags(4)
    else
        self.SettingLayoutControl.WidgetSwitcher_Select:SetActiveWidgetIndex(0)
        self.SettingLayoutControl:RemoveActiveWidgetStyleFlags(4)
        self.SettingLayoutControl:AddActiveWidgetStyleFlags(2)
    end
end

function CustomMainUI:OnChangeContentControlShow()
    if self.SettingLayoutControl:HasActiveWidgetStyleFlags(2) or self.SettingLayoutControl:HasActiveWidgetStyleFlags(4)then
        self.SettingLayoutControl.WidgetSwitcher_ShowDetail:SetActiveWidgetIndex(0)
        self.SettingLayoutControl:RemoveActiveWidgetStyleFlags(2)
        self.SettingLayoutControl:RemoveActiveWidgetStyleFlags(4)
        self.SettingLayoutControl:AddActiveWidgetStyleFlags(5)
        
    else
        self.SettingLayoutControl.WidgetSwitcher_ShowDetail:SetActiveWidgetIndex(1)
        self.SettingLayoutControl:RemoveActiveWidgetStyleFlags(5)
        self.SettingLayoutControl.IsCanMove = false
        self.SettingLayoutControl:AddActiveWidgetStyleFlags(2)
        self.SettingLayoutControl.WidgetSwitcher_Select:SetActiveWidgetIndex(0)
    end
end

function CustomMainUI:RevertLastActiveItem()
    local widget = nil
    widget =self.ItemBox:GetChildAt(self.ActiveItemIndex)
    --print("CustomMainUI:RevertLastActiveItem",self.ActiveItemIndex,GetObjectName(widget),widget.IsCanBan,widget.MyLayoutData.ItemSaveData.IsBan)
    widget.IsActive = false
    if widget.IsCanBan == true and widget.MyLayoutData.ItemSaveData.IsBan == true then
        widget:RefreshItemShowBan()
        return
    end
    if widget.IsOverlap == true then
        if widget.BP_CustomMoveWidgetOther then
            widget.BP_CustomMoveWidgetOther:AddActiveWidgetStyleFlags(1)
        end
        if widget.BP_CustomMoveWidget then
            widget.BP_CustomMoveWidget:AddActiveWidgetStyleFlags(1)
        end
        return
    end

    if widget.BP_CustomMoveWidgetOther then
        widget.BP_CustomMoveWidgetOther:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if widget.BP_CustomMoveWidget then
        widget.BP_CustomMoveWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function CustomMainUI:RefreshActiveItem(Indata)
    self.ActiveItemIndex = Indata.InIndex
    self.ItemBox:GetChildAt(self.ActiveItemIndex).IsActive = true
    self:IsShowBanButton(Indata.IsCanBan,Indata.IsBan)
    self.SettingLayoutControl.Slider_Size:SetMinValue(Indata.MinScale)
    self.SettingLayoutControl.Slider_Size:SetMaxValue(Indata.MaxScale)
    local Scale =  UE.UKismetMathLibrary.MapRangeClamped(Indata.DefaultScale,Indata.MinScale,Indata.MaxScale,0,1)
    print("CustomMainUI:RefreshActiveItem",Scale,Indata.MinScale,Indata.MaxScale,Indata.DefaultScale)
    self:SetSizeValueToProgressPanel( self.SettingLayoutControl.ProgressBar_Size,self.SettingLayoutControl.Slider_Size,self.SettingLayoutControl.Text_Size,Scale,Indata.DefaultScale)
    self:SetOpacityValueToProgressPanel( self.SettingLayoutControl.ProgressBar_Opacity,self.SettingLayoutControl.Slider_Opacity,self.SettingLayoutControl.Text_Opacity,Indata.RenderOpacity)
 
end

function CustomMainUI:SetOpacityValueToProgressPanel(InProgressBar,InSlider,InTextBlock,SizeRate)
    if InProgressBar then
        InProgressBar:SetPercent(SizeRate)
    end
    if InSlider then
        InSlider:SetValue(SizeRate)
    end
    
    local Num = SizeRate*100
    local Txt = string.format("%.f",Num).."%"
    if InTextBlock then
        InTextBlock:SetText(Txt)
    end
    
end

function CustomMainUI:SetSizeValueToProgressPanel(InProgressBar,InSlider,InTextBlock,SizeRate,RealValue)
   
    if InProgressBar then
        InProgressBar:SetPercent(SizeRate)
    end
    if InSlider then
        InSlider:SetValue(RealValue)
    end
    
    local Num = RealValue*100
    local Txt = string.format("%.f",Num).."%"
    if InTextBlock then
        InTextBlock:SetText(Txt)
    end
end


function CustomMainUI:ChangeActiveItem(Indata)
    print("CustomMainUI:ChangeActiveItem",Indata.InItemName,Indata.InIndex,Indata.IsCanBan,Indata.IsBan,Indata.RenderOpacity,Indata.DefaultScale,GetObjectName(self))
   
    if Indata.OutOperation ~= nil   then
        self.SettingLayoutControl:AddActiveWidgetStyleFlags(1)
    end
    
    
    if  self.ActiveItemIndex == Indata.InIndex then
        return
    end
    if self.ActiveItemIndex > 0 then
        self:RevertLastActiveItem()
        
    end
    self:RefreshActiveItem(Indata)
    
end

function CustomMainUI:IsShowBanButton(IsCanShowBan,IsBan)
    if IsCanShowBan == true then
        self.SettingLayoutControl.Panel_Hide:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
       
    else
        self.SettingLayoutControl.Panel_Hide:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self:RefreshBanBuStatus(IsBan)
end

function CustomMainUI:RefreshBanBuStatus(IsBan)
    if IsBan == true then
        self.SettingLayoutControl.WidgetSwitcher_Hide:SetActiveWidgetIndex(1)
        self.SettingLayoutControl.Panel_Size:SetIsEnabled(false)
        self.SettingLayoutControl.Panel_Opacity:SetIsEnabled(false)
        self.SettingLayoutControl.TxtSize:SetIsEnabled(false)
        self.SettingLayoutControl.TxtOpacity:SetIsEnabled(false)
    else
        self.SettingLayoutControl.WidgetSwitcher_Hide:SetActiveWidgetIndex(0)
        self.SettingLayoutControl.Panel_Size:SetIsEnabled(true)
        self.SettingLayoutControl.Panel_Opacity:SetIsEnabled(true)
        self.SettingLayoutControl.TxtSize:SetIsEnabled(true)
        self.SettingLayoutControl.TxtOpacity:SetIsEnabled(true)
    end
    
end





function CustomMainUI:OnChangeItemBan()
    local widget = self.ItemBox:GetChildAt(self.ActiveItemIndex) 
    if widget then
        self:AddRecordLayoutDataArray(widget.MyLayoutData)
    
    
    if widget.MyLayoutData.ItemSaveData.IsBan== true then
        self.SettingLayoutControl.WidgetSwitcher_Hide:SetActiveWidgetIndex(0)
        widget.MyLayoutData.ItemSaveData.IsBan= false
    else
        self.SettingLayoutControl.WidgetSwitcher_Hide:SetActiveWidgetIndex(1)
        widget.MyLayoutData.ItemSaveData.IsBan= true
    end
    widget:RefreshItemShowBan()
    self:RefreshBanBuStatus(widget.MyLayoutData.ItemSaveData.IsBan)
end
end

function CustomMainUI:OnSaveLayoutData()
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    self.SettingLayoutControl:SetVisibility(UE.ESlateVisibility.Collapsed)
    SettingSubsystem:GenerateScreenshot(self.LayoutIndex)
    self:SaveMyLayoutData(self.ItemBox:GetChildAt(self.ActiveItemIndex).MyLayoutData)
end

function CustomMainUI:ChangeActiveTabSelectItem(Indata)
    self.SettingLayoutControl.TabSelectTxt:SetText(Indata.ButtonTxt)
    self.SettingLayoutControl.TabSelectIcon:SetBrush(Indata.Brush)
    self.SettingLayoutControl.Panel_SeletDetail:GetChildAt(self.ActiveTabIndex).WidgetSwitcher:SetActiveWidgetIndex(0)
    self.ActiveTabIndex = Indata.Index
    self:RefreshWidgetIsEnable()
    if Indata.IsFromInit== true  then
        return 
       
    end
    self.SettingLayoutControl:RemoveActiveWidgetStyleFlags(4)
    self.SettingLayoutControl:AddActiveWidgetStyleFlags(2)
   
    self.SettingLayoutControl.WidgetSwitcher_Select:SetActiveWidgetIndex(0)
    self:RevertLastActiveItem()
     self.ActiveItemIndex = 0
end


function CustomMainUI:RefreshWidgetIsEnable()
    if self.ActiveTabIndex ==3 then
        for i = 2, self.ItemBox:GetChildrenCount()-1 do
            self.ItemBox:GetChildAt(i):SetIsEnabled(true)
        end
        return 
    end
    for i = 2, self.ItemBox:GetChildrenCount()-1 do
        if self.ItemBox:GetChildAt(i).LayerId == self.ActiveTabIndex then
            self.ItemBox:GetChildAt(i):SetIsEnabled(true)
        else
            self.ItemBox:GetChildAt(i):SetIsEnabled(false)
        end
    end
   
end

function CustomMainUI:OnSlideSizeValueChanged(InFloat)
    local Scale =  UE.UKismetMathLibrary.MapRangeClamped(InFloat,self.SettingLayoutControl.Slider_Size.MinValue,self.SettingLayoutControl.Slider_Size.MaxValue,0,1)
    self:SetSizeValueToProgressPanel( self.SettingLayoutControl.ProgressBar_Size,nil,self.SettingLayoutControl.Text_Size,Scale,InFloat)
    if self.ActiveItemIndex ~= 0 then
        local widget = self.ItemBox:GetChildAt(self.ActiveItemIndex)
        widget:SetMyRenderScale(InFloat)
        --widget:UpdatePivotAndTransLation(UE.FVector2D(0.5,0.5))
        self:CheckAllWidgetsHasOverlap()
        
    end
end

function CustomMainUI:OnSlideSizeCaptureEnd()
    print(" CustomMainUI:OnSlideSizeValueChanged OnSlideSizeCaptureEnd")
    if self.IsSlideSizeCaptureBegin == true then
        local widget = self.ItemBox:GetChildAt(self.ActiveItemIndex)
       
        widget:UpdatePivotAndTransLation(UE.FVector2D(0,0))
        self.IsSlideSizeCaptureBegin = false
    end
    
end

function CustomMainUI:OnSlideOpacityValueChanged(InFloat)
   
    self:SetOpacityValueToProgressPanel( self.SettingLayoutControl.ProgressBar_Opacity,nil,self.SettingLayoutControl.Text_Opacity,InFloat)
    if self.ActiveItemIndex ~= 0 then
        local widget = self.ItemBox:GetChildAt(self.ActiveItemIndex)
        widget:SetMyRenderOpacity(InFloat)
        
        
    end
end

function CustomMainUI:OnSlideOpacityCaptureEnd()
    print(" CustomMainUI:OnSlideOpacityCaptureEnd OnSlideSizeCaptureEnd")
    
end

function CustomMainUI:OnSlideSizeCaptureBegin()
    print("CustomMainUI:OnSlideSizeCaptureBegin")
    local widget = self.ItemBox:GetChildAt(self.ActiveItemIndex)
    --widget:SetRenderTransformPivot(UE.FVector2D(0.5,0.5))
    widget:UpdatePivotAndTransLation(UE.FVector2D(0.5,0.5))
    self:AddRecordLayoutDataArray(self.ItemBox:GetChildAt(self.ActiveItemIndex).MyLayoutData)
    self.IsSlideSizeCaptureBegin = true
end

function CustomMainUI:OnSlideOpacityCaptureBegin()
    self:AddRecordLayoutDataArray(self.ItemBox:GetChildAt(self.ActiveItemIndex).MyLayoutData)
end

function CustomMainUI:OnDrop(InGeometry,DragDropEvent,InOperation)
    print("USettingLayoutItemWidget CustomMainUI:OnDrop",GetObjectName(InOperation.Payload))
    self:CheckAllWidgetsHasOverlap()
    local ChildWidget = self.ItemBox:GetChildAt(self.ActiveItemIndex)
    self:AddRecordLayoutDataArray(ChildWidget.MyLayoutData)

    ChildWidget:ChangeMyPosition(DragDropEvent,InOperation)
    self.SettingLayoutControl.WidgetSwitcher_ReCall:SetActiveWidgetIndex(0)
    
   
    self.SettingLayoutControl:RemoveActiveWidgetStyleFlags(1)
    local EventReply = UE.UWidgetBlueprintLibrary.Handled()
    return UE.UWidgetBlueprintLibrary.EndDragDrop(EventReply)
end

function  CustomMainUI:NotifyItemDrop(Indata)
    self:OnDrop(Indata.InGeometry,Indata.DragDropEvent,Indata.InOperation)
end


-- function CustomMainUI:OnTouchMoved(InGeometry,InGestureEvent)
   
--     -- local ps1 = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InGestureEvent)
--     -- print("USettingLayoutItemWidget CustomMainUI:OnTouchMoved position1",GetObjectName(self),ps1)
--     -- local ps2 = UE.USlateBlueprintLibrary.AbsoluteToLocal(InGeometry,(ps1))
--     -- print("USettingLayoutItemWidget CustomMainUI:OnTouchMoved position2",GetObjectName(self),ps2)
   

--     -- local widget = self.ItemBox:GetChildAt(self.ActiveItemIndex)
   
--     -- local CanvasPanel = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(widget)
--     -- CanvasPanel:SetPosition(ps2)
  
--     return UE.UWidgetBlueprintLibrary.Handled()
-- end

function CustomMainUI:SetActiveItemMove(InDis)
   
    local widget =  self.ItemBox:GetChildAt(self.ActiveItemIndex)
    self:AddRecordLayoutDataArray(widget.MyLayoutData)

    local CanvasPanel = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(widget)
    local PS = CanvasPanel:GetPosition()
    PS.X = PS.X +InDis.X
    PS.Y = PS.Y +InDis.Y
   
    widget:SetMyPosition(widget,PS)
    self:CheckAllWidgetsHasOverlap()
    self.SettingLayoutControl.WidgetSwitcher_ReCall:SetActiveWidgetIndex(0)
   
  
    
end



function CustomMainUI:SetActiveItemMoveRightClicked()
    local Vector= UE.FVector2D()
    Vector.X = 1
   self:SetActiveItemMove(Vector) 
end

function CustomMainUI:SetActiveItemMoveRightPressed()
    
    local Vector= UE.FVector2D()
    Vector.X = self.SettingLayoutControl.Button_Right.MoveDis
    print("CustomMainUI:SetActiveItemMoveRightPressed",Vector.X )
    self:SetActiveItemMove(Vector) 
end

function CustomMainUI:SetActiveItemMoveLeftClicked()
    local Vector= UE.FVector2D()
    Vector.X = -1
   self:SetActiveItemMove(Vector) 
end

function CustomMainUI:SetActiveItemMoveLeftPressed()
    local Vector= UE.FVector2D()
    Vector.X = self.SettingLayoutControl.Button_Left.MoveDis
    self:SetActiveItemMove(Vector) 
end

function CustomMainUI:SetActiveItemMoveUpClicked()
    local Vector= UE.FVector2D()
    Vector.Y = -1
   self:SetActiveItemMove(Vector) 
end

function CustomMainUI:SetActiveItemMoveUpPressed()
    local Vector= UE.FVector2D()
    Vector.Y = self.SettingLayoutControl.Button_Up.MoveDis
    self:SetActiveItemMove(Vector) 
end

function CustomMainUI:SetActiveItemMoveDownClicked()
    local Vector= UE.FVector2D()
    Vector.Y = 1
   self:SetActiveItemMove(Vector) 
end

function CustomMainUI:SetActiveItemMoveBottomPressed()
    local Vector= UE.FVector2D()
    Vector.Y = self.SettingLayoutControl.Button_Down.MoveDis
    self:SetActiveItemMove(Vector) 
end

function CustomMainUI:SuccessGenerateScreenshot(Index)
    print("CustomMainUI:SuccessGenerateScreenshot",Index)
    self.SettingLayoutControl:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:OnClicked_CloseCustomLayout()
end

function CustomMainUI:OnClickedReCall()
    local ItemData = UE.FSettingLayoutItemSaveData()
    local IsFind = self:GetLastRecordLayoutData(ItemData)
    print("CustomMainUI:OnClickedReCall",IsFind,ItemData.ItemLayoutTagName)
    if IsFind == true then
        --找到目标widget回退
        local widget = nil 
        for i = 2, self.ItemBox:GetChildrenCount()-1 do
            widget = self.ItemBox:GetChildAt(i)
            if widget.MyLayoutData.ItemLayoutTagName == ItemData.ItemLayoutTagName then
                widget:InitBaseData(ItemData)
                self:RefreshBanBuStatus(widget.MyLayoutData.ItemSaveData.IsBan)
                local data =
                {
                    InItemName = widget.MyLayoutData.ItemLayoutTagName,
                    InIndex = i,
                    IsCanBan = widget.IsCanBan,
                    IsBan = widget.MyLayoutData.ItemSaveData.IsBan,
                    RenderOpacity =widget.MyLayoutData.ItemSaveData.RenderOpacity,
                    MinScale = widget.MinScale,
                    MaxScale = widget.MaxScale,
                    DefaultScale = widget.MyLayoutData.ItemSaveData.Scale,
                    OutOperation = nil
                }
                self:ChangeActiveItem(data)
               
                
                self.SettingLayoutControl.Slider_Size:SetValue(widget.MyLayoutData.ItemSaveData.Scale)
                self.SettingLayoutControl.Slider_Opacity:SetValue(widget.MyLayoutData.ItemSaveData.RenderOpacity)
                
                break
            end
        end
        self:CheckAllWidgetsHasOverlap()
    end
    IsFind = self:IsHasRecordLayoutData()
    if IsFind== false then
        self.SettingLayoutControl.WidgetSwitcher_ReCall:SetActiveWidgetIndex(1) 
    end
end

function CustomMainUI:OnClickedReset()
    self:InitItemData(true)
    self.ItemBox:GetChildAt(self.DefaultActiveItemIndex):SetDragStatus()
    --改布局数据被删除
    UE.UGenericSettingSubsystem.Get(self):AddtDelMobileIndex(self.LayoutIndex)
end

function CustomMainUI:RefreshLayoutItemStatus(OverlapWidgets)
    for i = 2, self.ItemBox:GetChildrenCount()-1 do
        self.ItemBox:GetChildAt(i):RevertStatus()
    end
    self.ItemBox:GetChildAt(self.ActiveItemIndex):SetDragStatus()
    self.ItemBox:GetChildAt(self.ActiveItemIndex):RefreshItemShowBan()
    for i=1 ,OverlapWidgets:Num() do
        OverlapWidgets:GetRef(i):SetOverlapStatus()
    end
end

function CustomMainUI:OnSelectLayout()
    
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
         local GenericBlackboard = UE.FGenericBlackboardContainer()
        local  LayoutIndexType= UE.FGenericBlackboardKeySelector()  
        LayoutIndexType.SelectedKeyName = "LayoutIndex"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboard,LayoutIndexType, self.LayoutIndex) 
        UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("Setting.LayoutSelect",-1,GenericBlackboard,self)
    else
        local data =
        {
            LayoutIndex = self.LayoutIndex
        }
        MvcEntry:OpenView(ViewConst.LayoutSelect,data)
    end
end


function CustomMainUI:OnChangeLayout(data)
    self.LayoutIndex = data.ActiveIndex
    self.SettingLayoutControl.Text_Default:SetText(data.NewText)
    self:InitItemData(false)
   
   self.ItemBox:GetChildAt(self.DefaultActiveItemIndex):OnDragDetected(nil,nil,nil)
end
return CustomMainUI