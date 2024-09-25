local SettingOperationPanel = Class("Common.Framework.UserWidget")

function SettingOperationPanel:OnInit()
   
    self.ActivateIndex = -1
    self:InitItem()
    UserWidget.OnInit(self)
end

function SettingOperationPanel:InitItem()
    local ChildWidget = nil
    local FuncNameBase = "OnClicked"
    local FuncName = ""
    local Num = self.WrapBox_Cotaint:GetChildrenCount()-1 
    for i = 0,Num,1 do 
        ChildWidget =  self.WrapBox_Cotaint:GetChildAt(i)
        --ChildWidget:AddActiveWidgetStyleFlags(0)
        ChildWidget:AddActiveWidgetStyleFlags(i+2)
        FuncName = FuncNameBase..tostring(i)
        ChildWidget.Button_Select.OnClicked:Add(self, self[FuncName])  
    end
end

function SettingOperationPanel:ChangeActivateIndex(InIndex,IsFromInit)

    print(" SettingOperationPanel:ChangeActivateIndex",InIndex)
    local ChildWidget = nil
    --恢复之前的
    if self.ActivateIndex >=0  then
        ChildWidget = self.WrapBox_Cotaint:GetChildAt(self.ActivateIndex)
        ChildWidget:RemoveActiveWidgetStyleFlags(1)
        --ChildWidget:AddActiveWidgetStyleFlags(0)
    end
    
    self.ActivateIndex = InIndex
    ChildWidget = self.WrapBox_Cotaint:GetChildAt(self.ActivateIndex)
    ChildWidget:AddActiveWidgetStyleFlags(1)
    if IsFromInit then
        return
    end
    local NewSettingValue = UE.FSettingValue()
    NewSettingValue.Value_Int = self.ActivateIndex
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    SettingSubsystem:ApplySetting(self.ParentTag.TagName,NewSettingValue)
end

function SettingOperationPanel:OnClicked0()
    self:ChangeActivateIndex(0,false)
end

function SettingOperationPanel:OnClicked1()
    self:ChangeActivateIndex(1,false)
end

function SettingOperationPanel:OnClicked2()
    self:ChangeActivateIndex(2,false)
end

return SettingOperationPanel  