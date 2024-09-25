

local SettingLayoutItem = Class("Common.Framework.UserWidget")

function SettingLayoutItem:OnInit()
    --默认隐藏橙色框
    if self.BP_CustomMoveWidgetOther then
        self.BP_CustomMoveWidgetOther:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.BP_CustomMoveWidgetOther:RemoveAllActiveWidgetStyleFlags()
    end
    if self.BP_CustomMoveWidget then
        self.BP_CustomMoveWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.BP_CustomMoveWidget:RemoveAllActiveWidgetStyleFlags()
    end
    if self.IsUseOtherLine == true and self.BP_CustomMoveWidgetOther then
        self.CustomMoveWidget = self.BP_CustomMoveWidgetOther
    else
        self.CustomMoveWidget = self.BP_CustomMoveWidget
    end 
   
    UserWidget.OnInit(self)
   
end
function SettingLayoutItem:OnShow(data)
   
    self:InitData()
end

function SettingLayoutItem:OnClose()
    self.IsActive = false
end
function SettingLayoutItem:InitData()
    if self.IsActive == true then
        return 
    end
    self.IsOverlap = false
    self.IsActive = false
    --self:RefreshItemShowBan()
end

function SettingLayoutItem:RefreshItemShowBan()
   --print("SettingLayoutItem:RefreshItemShowBan",self.IsCanBan,GetObjectName(self),self.MyLayoutData.ItemSaveData.IsBan,self.IsActive)
     --如果是被禁用的，需要显示红色警示，style:2
     if self.IsCanBan == false then
        return
     end
     if self.MyLayoutData.ItemSaveData.IsBan == true then
        self.BP_CustomMoveWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if self.IsActive == false then
            self.BP_CustomMoveWidget:AddActiveWidgetStyleFlags(2)
        else
            self.BP_CustomMoveWidget:AddActiveWidgetStyleFlags(3)
        end
        
    else
       
        if self.IsActive == false then
            self.BP_CustomMoveWidget:RemoveActiveWidgetStyleFlags(2)
        else
            self.BP_CustomMoveWidget:RemoveActiveWidgetStyleFlags(3)
        end
        
    end
end

function SettingLayoutItem:OnDragDetected(InGeometry,InMouseEvent,OutOperation)
    print("SettingLayoutItem:OnDragDetected",GetObjectName(self))
    
  self:SetDragStatus()
   local data =
   {
       InItemName = self.MyLayoutData.ItemLayoutTagName,
       InIndex = self.ItemInBoxInedx,
       IsCanBan = self.IsCanBan,
       IsBan = self.MyLayoutData.ItemSaveData.IsBan,
       RenderOpacity =self.MyLayoutData.ItemSaveData.RenderOpacity,
       MinScale = self.MinScale,
       MaxScale = self.MaxScale,
       DefaultScale = self.MyLayoutData.ItemSaveData.Scale,
       OutOperation = OutOperation
   }
   MsgHelper:Send(self, "UIEvent.ChangeActiveItem",data)
  
end


function SettingLayoutItem:SetDragStatus()
    if self.IsUseOtherLine == true and self.BP_CustomMoveWidgetOther then
        self.BP_CustomMoveWidgetOther:RemoveAllActiveWidgetStyleFlags()
        self.BP_CustomMoveWidgetOther:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
       
       
    elseif self.BP_CustomMoveWidget then
        self.BP_CustomMoveWidget:RemoveAllActiveWidgetStyleFlags()
        self.BP_CustomMoveWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if self.MyLayoutData.ItemSaveData.IsBan == true then
            
            self.BP_CustomMoveWidget:AddActiveWidgetStyleFlags(3)  
        
        end
       
   end
end

function SettingLayoutItem:OnDragCancelled(InDragDropEvent,InOperation)
    print("SettingLayoutItem:OnDragCancelled",GetObjectName(self))
    
  
    
 end

 function SettingLayoutItem:OnTouchStarted(InMyGeometry, InTouchEvent)
    print("SettingLayoutItem:OnTouchStarted",GetObjectName(self))
    self:OnDragDetected(InMyGeometry,InTouchEvent,nil)
    return UE.FEventReply()
end
function SettingLayoutItem:OnTouchMoved(InGeometry,InGestureEvent)
    --print("SettingLayoutItem:OnTouchMoved",GetObjectName(self))
    return UE.FEventReply()
end


function SettingLayoutItem:OnDragLeave(InDragDropEvent, Operation)
    print("SettingLayoutItem:OnDragLeave",GetObjectName(self))
    
end


function SettingLayoutItem:OnDrop(MyGeometry,DragDropEvent,InOperation)
    print("USettingLayoutItemWidget SettingLayoutItem:OnDrop",GetObjectName(self))
    --还是去通知主界面统一做管理比较好
    local data =
    {
        InGeometry = MyGeometry,
        DragDropEvent = DragDropEvent,
        InOperation = InOperation
    }
    MsgHelper:Send(self, "UIEvent.NotifyItemDrop",data)
    local EventReply = UE.UWidgetBlueprintLibrary.Handled()
    return UE.UWidgetBlueprintLibrary.EndDragDrop(EventReply)
end




function SettingLayoutItem:SetOverlapStatus()
    if self.MyLayoutData.ItemSaveData.IsBan == true then
        return
    end
    print("SettingLayoutItem:SetOverlapStatus",GetObjectName(self))
    self.CustomMoveWidget:RemoveAllActiveWidgetStyleFlags()
    self.CustomMoveWidget:AddActiveWidgetStyleFlags(1)
    self.CustomMoveWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.IsOverlap = true
end

function SettingLayoutItem:RevertStatus()
    if self.MyLayoutData.ItemSaveData.IsBan == true then
        return
    end
    print("SettingLayoutItem:RevertStatus",GetObjectName(self))
    self.CustomMoveWidget:RemoveAllActiveWidgetStyleFlags()
    self.CustomMoveWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.IsOverlap =false
end

function SettingLayoutItem:RevertAllStyle()
    if self.BP_CustomMoveWidgetOther then
        self.BP_CustomMoveWidgetOther:RemoveAllActiveWidgetStyleFlags()
        self.BP_CustomMoveWidgetOther:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
    self.CustomMoveWidget:RemoveAllActiveWidgetStyleFlags()
    self.CustomMoveWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return SettingLayoutItem