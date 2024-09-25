

require "UnLua"
local class_name = "SettingSetPopUp"
SettingSetPopUp = SettingSetPopUp or BaseClass(GameMediator, class_name);


function SettingSetPopUp:__init()
    
    print("SettingSetPopUp:__init")
    self:ConfigViewId(ViewConst.SettingSetPopUp)
    --self:ConfigViewId(ViewConst.Setting)
end


function SettingSetPopUp:OnHide()
end


local SettingSetPopUp = Class("Client.Mvc.UserWidgetBase")

function SettingSetPopUp:OnInit()
    print("SettingSetPopUp:OnInit")
    
    -- self.MsgList = 
    -- {
	-- 	{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnClicked_GUIButton_Close },
    --     {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Enter), Func = self.OnClicked_GUIButton_ResetDefault },
    -- }
    self.BindNodes ={
    { UDelegate = self.CommonBtn_Cancel.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_Close },
    { UDelegate = self.CommonBtn_Confirm.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_ResetDefault},
    }
    
    if BridgeHelper.IsMobilePlatform() then
        self.CommonBtn_Confirm.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CommonBtn_Cancel.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
    UserWidgetBase.OnInit(self)
    
end
function SettingSetPopUp:OnShow(data)
    print("SettingSetPopUp:OnShow",data)
   
    if self.MvcCtrl and self.viewId then
        self:SetContent(data)
        self.CommonBtn_Confirm:OnShow(data,nil)
        self.CommonBtn_Cancel:OnShow(data,nil)
        local UIManager = UE.UGUIManager.GetUIManager(self)
        if UIManager then
            UIManager:TryToChangeInputModeByType(self,UE.EInputModeType.UIOnly,true)
        end
    end
    local GenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(GameInstance)
    if GenericGamepadUMGSubsystem  then 
        local status = GenericGamepadUMGSubsystem:IsInGamepadInput()
        self.CommonBtn_Confirm:SetKeyIcon(status)
        self.CommonBtn_Cancel:SetKeyIcon(status)
    end
    

end

function SettingSetPopUp:OnHide()
    local UIManager = UE.UGUIManager.GetUIManager(GameInstance)
    if UIManager then
        UIManager:TryToChangeInputModeByType(self,UE.EInputModeType.UIOnly,false)
    end
end

function SettingSetPopUp:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    print("SettingSetPopUp:OnTipsInitialize")
    
    --local Title,IsFindTitle =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,TxtKey)
    local Title,IsFindTitle =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsStringSimple(TipGenricBlackboard,"TabText")
  
    --local Detail,IsFindDetail =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsStringInLua(TipGenricBlackboard,TxtKey)
    local Detail,IsFindDetail =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsStringSimple(TipGenricBlackboard,"DetailText")
    -- TxtKey.SelectedKeyName ="IsSimilar"
    -- local IsSimilar,IsFindSimilar =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(TipGenricBlackboard,TxtKey)

    print("SettingSetPopUp:OnTipsInitialize Title",Title,Detail)
    local Data ={
        TabText = Title,
        DetailText = Detail,
        --IsSimilar = IsSimilar, 
    }
    
    self:SetContent(Data)
end

function SettingSetPopUp:SetContent(data)
   
    print("SettingSetPopUp:SetContent",data)
    self.GUITextBlock_TabText:SetText(data.TabText)
    self.GUITextBlock_Detail:SetText(data.DetailText)
    -- if data.IsSimilar == true then
    --     self.CommonBtn_Confirm:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- else
    --     self.CommonBtn_Confirm:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- end
end

function SettingSetPopUp:SetHoveredStyle(Button,UnhoverIcon,HoverIcon)
    
    Button.GUIButton_Tips.OnHovered:Add(self, function()
        Button.ControlTipsIcon:SetBrushFromSoftTexture(HoverIcon)
        Button.ControlTipsTxt:SetColorAndOpacity(self.TxtHoverColor)
    end)

    Button.GUIButton_Tips.OnUnhovered:Add(self, function()
        Button.ControlTipsIcon:SetBrushFromSoftTexture(UnhoverIcon)
        Button.ControlTipsTxt:SetColorAndOpacity(self.TxtNormalColor)
    end)
end



function SettingSetPopUp:OnClicked_GUIButton_Close()
    print("SettingSetPopUp:OnClicked_GUIButton_Close ESC")
    
    if self.MvcCtrl and self.viewId then
        --通过Mvc框架管理的
        MvcEntry:CloseView(self.viewId)  
    else
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        TipsManager:RemoveTipsUI("Setting.SettingSetPopUp")
        MsgHelper:Send(self, "UIEvent.ESCSetting")
    end
    
    
end

function SettingSetPopUp:OnClicked_GUIButton_ResetDefault()
    print("SettingSetPopUp:OnClicked_GUIButton_ResetDefault")
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
        SettingSubsystem:ResetKeyMapConflict()
   
    MsgHelper:Send(self, "UIEvent.ResetDefaultSetting")
    self:OnClicked_GUIButton_Close()
end


function SettingSetPopUp:OnKeyDown(MyGeometry,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    print("SettingSetPopUp:OnKeyDown",PressKey)
    if PressKey == self.CommonBtn_Cancel.Key or  PressKey ==  self.CommonBtn_Cancel.GamepadKey then
        self:OnClicked_GUIButton_Close()
    elseif  PressKey == self.CommonBtn_Confirm.Key or  PressKey == self.CommonBtn_Confirm.GamepadKey  then
        self:OnClicked_GUIButton_ResetDefault()
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end



function SettingSetPopUp:OnChangeInputType(InStatus)
    self.CommonBtn_Confirm:SetKeyIcon(InStatus)
    self.CommonBtn_Cancel:SetKeyIcon(InStatus)
end
return SettingSetPopUp