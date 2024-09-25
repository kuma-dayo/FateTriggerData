
require "UnLua"
local class_name = "SettingApplyPopUp"
SettingApplyPopUp = SettingApplyPopUp or BaseClass(GameMediator, class_name);


function SettingApplyPopUp:__init()
    
  
    self:ConfigViewId(ViewConst.SettingApplyPopUp)
    --self:ConfigViewId(ViewConst.Setting)
end


function SettingApplyPopUp:OnHide()
end


local SettingApplyPopUp = Class("Client.Mvc.UserWidgetBase")

function SettingApplyPopUp:OnInit()
    
    self.BindNodes ={
    { UDelegate = self.CommonBtn_Cancel.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_Close },
    { UDelegate = self.CommonBtn_Confirm.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_Confirm},
    }
    
    if BridgeHelper.IsMobilePlatform() then
        self.CommonBtn_Confirm.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CommonBtn_Cancel.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
    UserWidgetBase.OnInit(self)
    
end
function SettingApplyPopUp:OnShow(data)
    self.TimerHandle= nil
    if self.MvcCtrl and self.viewId then
        local Data ={
            TabName = data.TagName
        }
        self:DistributContent(Data)
        local UIManager = UE.UGUIManager.GetUIManager(self)
        if UIManager then
            UIManager:TryToChangeInputModeByType(self,UE.EInputModeType.UIOnly,true)
        end
    end
    self.NowTime = self.ResetTime
end

function SettingApplyPopUp:OnHide()
    local UIManager = UE.UGUIManager.GetUIManager(GameInstance)
    if UIManager then
        UIManager:TryToChangeInputModeByType(self,UE.EInputModeType.UIOnly,false)
    end
end

function SettingApplyPopUp:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    
    local TabName,IsFindTitle =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsStringSimple(TipGenricBlackboard,"Tab")
    print("SettingApplyPopUp:OnTipsInitialize TabName",TabName)
    local Data ={
        TabName = TabName
    }
    self:DistributContent(Data)
end
--想尽量做得通用一点点，不同的tab页按apply可能出现的弹窗
function SettingApplyPopUp:DistributContent(data)
    local PopupKey = self.TabNameKeyMap:Find(data.TabName)
    if PopupKey then
        self.CommonBtn_Confirm.Key = PopupKey.ConfirmKey
        self.CommonBtn_Confirm.GamepadKey = PopupKey.GamepadConfirmKey
        self.CommonBtn_Cancel.Key = PopupKey.CancelKey
        self.CommonBtn_Cancel.GamepadKey = PopupKey.GamepadCancelKey
    end
    local GenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(GameInstance)
    if GenericGamepadUMGSubsystem  then 
        local status = GenericGamepadUMGSubsystem:IsInGamepadInput()
        self.CommonBtn_Confirm:SetKeyIcon(status)
        self.CommonBtn_Cancel:SetKeyIcon(status)
    end
    local Data = {}
    if data.TabName == "Setting.Render" then
        Data.describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "ScreenChangeConfirm"))
        Data.CancelTxt = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Save"))
        local TimeSecond = string.format("%d", self.ResetTime)
        Data.ConfirmTxt = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "CancelTime"),TimeSecond)
        self.CommonBtn_Confirm.TextContent= Data.ConfirmTxt
        self.CommonBtn_Cancel.TextContent= Data.CancelTxt
        self.CommonBtn_Confirm.ControlTipsTxt:SetText(Data.ConfirmTxt)
        self.CommonBtn_Cancel.ControlTipsTxt:SetText(Data.CancelTxt)
        self:SetTimer()
    end
    self:SetContent(Data)
end

function SettingApplyPopUp:SetContent(Data)
    self.ContentText:SetText(Data.describe)
end

function SettingApplyPopUp:OnClicked_GUIButton_Confirm()
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    SettingSubsystem:RevertLastApplyData()
    self:OnClicked_GUIButton_Close()
end

function SettingApplyPopUp:OnClicked_GUIButton_Close()
    if self.TimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
        self.TimerHandle = nil
    end
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    SettingSubsystem:ResetCachedLastApplyData()
    if self.MvcCtrl and self.viewId then
        --通过Mvc框架管理的
        MvcEntry:CloseView(self.viewId)  
    else
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        TipsManager:RemoveTipsUI("Setting.SettingApplyPopUp")
        MsgHelper:Send(self, "UIEvent.ESCSetting")
    end
    
    
end

function SettingApplyPopUp:OnKeyDown(MyGeometry,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == self.CommonBtn_Cancel.Key or  PressKey ==  self.CommonBtn_Cancel.GamepadKey then
        self:OnClicked_GUIButton_Close()
    elseif  PressKey == self.CommonBtn_Confirm.Key or  PressKey == self.CommonBtn_Confirm.GamepadKey  then
        self:OnClicked_GUIButton_Confirm()
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end
function SettingApplyPopUp:OnChangeInputType(InStatus)
    self.CommonBtn_Confirm:SetKeyIcon(InStatus)
    self.CommonBtn_Cancel:SetKeyIcon(InStatus)
end

function SettingApplyPopUp:SetTimer()
    if not self.TimerHandle then
        self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateTime}, 1, true, 0, 0)
    end
   
end

function SettingApplyPopUp:UpdateTime()
    self.NowTime = self.NowTime-1
    self.CommonBtn_Confirm.ControlTipsTxt:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "CancelTime"),string.format("%d", self.NowTime)))
    if self.NowTime<=0 then
        self:ClearTimerHandle()
    end
end

function SettingApplyPopUp:ClearTimerHandle()
    if self.TimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
        self.TimerHandle = nil
        self:OnClicked_GUIButton_Confirm()
   end
end


return SettingApplyPopUp