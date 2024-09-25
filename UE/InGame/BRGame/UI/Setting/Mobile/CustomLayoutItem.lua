



local CustomLayoutItem = Class("Common.Framework.UserWidget")

function CustomLayoutItem:OnInit()

        
    self.Button.OnClicked:Add(self, self.OnClicked_OpenEdit) 
    --self.Button.OnUnhovered:Add(self, self.OnUnhoveredReset) 
    self.Button_Use.OnClicked:Add(self, self.OnClicked_ApplyLayout)
    self.Button_Custom.OnClicked:Add(self, self.OnClicked_OpenCustomLayout)  
    --self.Button.OnFocusLosted:Add(self, self.OnFocusLosted)  
    

    UserWidget.OnInit(self)
end

function CustomLayoutItem:OnClicked_OpenEdit()
     print("CustomLayoutItem:OnClicked_OpenEdit",GetObjectName(self))
    self.CallEditLayoutIndex:Broadcast(self.Index)
    self.WidgetSwitcher:SetActiveWidgetIndex(1)
    self.Panel_Custom:SetVisibility(UE.ESlateVisibility.Visible)
    self.Button_Use:SetVisibility(UE.ESlateVisibility.Visible)
end


function CustomLayoutItem:OnUnhoveredReset()
    print("CustomLayoutItem:OnUnhoveredReset",GetObjectName(self),self.IsActive)
    if  self.IsActive == true then
        self.WidgetSwitcher:SetActiveWidgetIndex(2)
    else
        self.WidgetSwitcher:SetActiveWidgetIndex(0)
    end 
    self.Panel_Custom:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Button_Use:SetVisibility(UE.ESlateVisibility.Collapsed)
end


function CustomLayoutItem:OnClicked_OpenCustomLayout()
    print("CustomLayoutItem:OnClicked_OpenCustomLayout",GetObjectName(self),self.Index)
   
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        local GenericBlackboardContainer = UE.FGenericBlackboardContainer()
        local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
        BlackboardKeySelector.SelectedKeyName = "LayoutIndex"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector,self.Index)
        BlackboardKeySelector.SelectedKeyName = "NewText"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboardContainer, BlackboardKeySelector,self.NewText)
        UE.UGUIManager.GetUIManager(self):TryLoadDynamicWidget("UMG_MobileCustomLayout",GenericBlackboardContainer)
       
    else
        local Param = 
	{
		LayoutIndex = self.Index,
		NewText = self.NewText
	}
        MvcEntry:OpenView(ViewConst.CustomMainUI,Param)
        
    end
    
    local data ={
        IsShow = false
    }
    MsgHelper:Send(self, "UIEvent.SettingIsShow",data)
end


function CustomLayoutItem:OnClicked_ApplyLayout()
    print("CustomLayoutItem:OnClicked_ApplyLayout",GetObjectName(self))
    self.WidgetSwitcher:SetActiveWidgetIndex(2)
    self.IsActive = true
    self.CallActiveLayoutIndex:Broadcast(self.Index)
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("Setting.CustomLayoutApply")
    else
        MvcEntry:OpenView(ViewConst.CustomLayoutApplyTips)
    end
   
end

function CustomLayoutItem:OnFocusLosted()
    print("CustomLayoutItem:OnFocusLosted",GetObjectName(self))
    self:OnUnhoveredReset()
end

return CustomLayoutItem