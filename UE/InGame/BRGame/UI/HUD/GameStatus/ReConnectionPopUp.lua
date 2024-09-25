require "UnLua"

local ReConnectionPopUp = Class("Common.Framework.UserWidget")


function ReConnectionPopUp:OnInit()
    if BridgeHelper.IsPCPlatform() then
        self.BindNodes ={
            { UDelegate = self.CommonBtn_Cancel.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_Close },
            { UDelegate = self.CommonBtn_Confirm.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_ResetDefault},
        }
    end
    if BridgeHelper.IsMobilePlatform() then
        self.BindNodes ={
            { UDelegate = self.BP_Button_Cancel.Button.OnClicked, Func = self.OnClicked_GUIButton_Close },
            { UDelegate = self.BP_Button_Exit.Button.OnClicked, Func = self.OnClicked_GUIButton_ResetDefault},
        }
        self.BP_Button_Cancel.Text:SetText(self.BP_Button_Cancel.TextContent)
        self.BP_Button_Exit.Text:SetText(self.BP_Button_Exit.TextContent)
    end
    UserWidget.OnInit(self)
end

function ReConnectionPopUp:OnClose()
   
   
end



function ReConnectionPopUp:OnDestroy()


    UserWidget.OnDestroy(self)
end


function ReConnectionPopUp:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self.IsShowConnect = false
    local TipsKey = UE.FGenericBlackboardKeySelector()
    TipsKey.SelectedKeyName ="TipsId"
    local TipsId,IsFind =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,TipsKey)
    if IsFind == true then
        self.IsShowRun = true
    else
        self.IsShowRun = false
    end
    local GenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(GameInstance)
    if GenericGamepadUMGSubsystem  then 
        local status = GenericGamepadUMGSubsystem:IsInGamepadInput()
        self.CommonBtn_Confirm:SetKeyIcon(status)
        self.CommonBtn_Cancel:SetKeyIcon(status)
    end
end

function ReConnectionPopUp:OnClicked_GUIButton_Close()
    MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.Normal)
end


function ReConnectionPopUp:OnClicked_GUIButton_ResetDefault()
    if self.IsShowRun == false then
        self.IsShowConnect = true
        UE.UTipsManager.GetTipsManager(self):RemoveTipsUI("NetWork.ReConnection.PopUp")
        UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("NetWork.ReConnection")
    else
        
    end
    
    
end

function ReConnectionPopUp:OnKeyDown(MyGeometry,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    --=print("ReConnectionPopUp:OnKeyDown",PressKey)
    if PressKey == self.CommonBtn_Cancel.Key or  PressKey ==  self.CommonBtn_Cancel.GamepadKey then
        self:OnClicked_GUIButton_Close()
    elseif  PressKey == self.CommonBtn_Confirm.Key or  PressKey == self.CommonBtn_Confirm.GamepadKey  then
        self:OnClicked_GUIButton_ResetDefault()
    end
    return UE.UWidgetBlueprintLibrary.Handled()
    
end
function ReConnectionPopUp:OnChangeInputType(InStatus)
    self.CommonBtn_Confirm:SetKeyIcon(InStatus)
    self.CommonBtn_Cancel:SetKeyIcon(InStatus)
end
return ReConnectionPopUp