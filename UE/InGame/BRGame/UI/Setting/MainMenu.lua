require "UnLua"

local class_name = "MainMenuUI"
MainMenuUI = MainMenuUI or BaseClass(GameMediator, class_name);
local MainMenu = Class("Client.Mvc.UserWidgetBase")


function MainMenuUI:__init()
    print("SettingMainUI:__init")
    self:ConfigViewId(ViewConst.MainMenu)
end

function MainMenuUI:OnShow(data)
    print("MainMenuUI:OnShow")

    self:SetFocus()
end

function MainMenuUI:OnHide()
end




function MainMenu:OnInit()
    print("MainMenu:OnInit")
    self.IsInGame = true
    -- 注册消息监听
	self.MsgList = {
        --{ MsgName = "UIEvent.OpenMainMenu",	    Func = self.OnMainMenuVisibilityToggle,      bCppMsg = true, WatchedObject = nil},
    }
    MsgHelper:RegisterList(self, self.MsgList)
    self.BtnBack.ControlTipsTxt:SetColorAndOpacity(self.TxtUnhoveredColor)
    self.BtnBack.ControlTipsIcon:SetBrushfromSoftTexture(self.WhiteBackIcon,false)
    self.BindNodes ={
        { UDelegate = self.BtnBack.GUIButton_Tips.OnClicked, Func = self.OnBackClicked },
        { UDelegate = self.BtnBack.GUIButton_Tips.OnHovered, Func = self.OnBackHovered },
        { UDelegate = self.BtnBack.GUIButton_Tips.OnUnhovered, Func = self.OnBackUnhovered },
    }
    self.BP_BtnSetting.ButtonOption.OnClicked:Add(self, MainMenu.OnSettingClick)
    self.BP_BtnSetting.GamepadKeyDownDelegate:Add(self, self.OnSettingClick)
    self.BP_BtnReturn.ButtonOption.OnClicked:Add(self, MainMenu.OnReturnClick)
    self.BP_BtnReturn.GamepadKeyDownDelegate:Add(self, self.OnReturnClick)

    self:SetHoveredStyle(self.BP_BtnReturn.ButtonOption)
    self:SetHoveredStyle(self.BP_BtnSetting.ButtonOption)

    -- self.BtnBack.ControlTipsIcon:SetBrushFromSoftTexture(self.WhiteBackIcon)
    self.BtnBack.ControlTipsTxt:SetText(self.BackText)
    self.BtnBack.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, true)
    end

    if self.BP_BtnQuitEditor.ButtonOption then
        self.BP_BtnQuitEditor.GamepadKeyDownDelegate:Add(self, self.OnQuitEditorClick)
        self.BP_BtnQuitEditor.ButtonOption.OnClicked:Add(self, MainMenu.OnQuitEditorClick)
        self:SetHoveredStyle(self.BP_BtnQuitEditor.ButtonOption)
        self.BP_BtnQuitEditor.ButtonOption:SetVisibility(UE.UGFUnluaHelper.IsEditor() and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    end

    -- local GenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(self)
    -- if GenericGamepadUMGSubsystem then 
    --     local status = GenericGamepadUMGSubsystem:IsInGamepadInput()
    --     --self.BP_BtnReturn:SetBrushfromSoftTexture(self.WhiteBackIcon,false)
    --     -- self.CommonBtn_Confirm:SetKeyIcon(status)
    --     -- self.CommonBtn_Cancel:SetKeyIcon(status)
    -- end

    --因为如果只是简单隐藏返回大厅按钮，会有奇怪的效果，故还是共用一个按钮
    -- if  self.MvcCtrl and self.viewId  then
    --     self.Txt_Return:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MainMenu_Exitthegame")))
    -- else
    --     self.Txt_Return:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MainMenu_Returntothehall")))
    -- end
    UserWidgetBase.OnInit(self)
end

function MainMenu:SetHoveredStyle(Button)
    if BridgeHelper.IsMobilePlatform then
        return;
    end
    local HBox = Button:GetChildAt(0)
    local ImgIcon = HBox:GetChildAt(0)
    local TxtTitle = HBox:GetChildAt(1)
    local Margin = UE.FMargin()
    Button.OnHovered:Add(self, function()
        --Margin.Left = 200
        --HBox.Slot:SetPadding(Margin)
        HBox.Slot:SetHorizontalAlignment(UE.EHorizontalAlignment.HAlign_Center)
        ImgIcon:SetColorAndOpacity(self.ImgHoveredColor)
        TxtTitle:SetColorAndOpacity(self.TxtHoveredColor)
    end)

    Button.OnUnhovered:Add(self, function()
        --Margin.Left = 0
        --HBox.Slot:SetPadding(Margin)
        HBox.Slot:SetHorizontalAlignment(UE.EHorizontalAlignment.HAlign_Left) 
        ImgIcon:SetColorAndOpacity(self.ImgUnhoveredColor)
        TxtTitle:SetColorAndOpacity(self.TxtUnhoveredColor)
    end)
end

function MainMenu:OnBackHovered()
    -- self.BtnBack.ControlTipsIcon:SetBrushFromSoftTexture(self.BlackBackIcon)
    self.BtnBack.ControlTipsTxt:SetColorAndOpacity(self.TxtHoveredColor)
    self.BtnBack.ControlTipsIcon:SetBrushfromSoftTexture(self.BlackBackIcon,false)
    local FontInfo = self.BtnBack.ControlTipsTxt.Font
    FontInfo.OutlineSettings.OutlineSize = 0
    self.BtnBack.ControlTipsTxt:SetFont(FontInfo)
end

function MainMenu:OnBackUnhovered()
    -- self.BtnBack.ControlTipsIcon:SetBrushFromSoftTexture(self.WhiteBackIcon)
    self.BtnBack.ControlTipsTxt:SetColorAndOpacity(self.TxtUnhoveredColor)
    self.BtnBack.ControlTipsIcon:SetBrushfromSoftTexture(self.WhiteBackIcon,false)
    local FontInfo = self.BtnBack.ControlTipsTxt.Font
    FontInfo.OutlineSettings.OutlineSize = 2
    self.BtnBack.ControlTipsTxt:SetFont(FontInfo)
end

function MainMenu:OnQuitEditorClick()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if PlayerController then
        UE.UKismetSystemLibrary.QuitGame(self,PlayerController,0,false)
    end
end

function MainMenu:OnDestroy()
	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end
    UserWidgetBase.OnDestroy(self)
    --self:Release()
end

function MainMenu:OnShow(data)
    -- print("BackToLobbyConfirm:OnShow",data)
    -- local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    -- if PlayerController then
    --     PlayerController.bShowMouseCursor = true;

    -- end
    self:SetFocus()
end
--[[
function MainMenu:OnMainMenuVisibilityToggle()
    print(("MainMenu:OnMainMenuVisibilityToggle"))
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if PlayerController then
        if self:IsVisible() then
            self:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            local UIManager = UE.UGUIManager.GetUIManager(self)
            if UIManager then
                local Key = UE.FGameplayTag()
                Key.TagName = "TagLayout.Settings"
                self.SettingWidget = UIManager:GetFirstTagPanel(Key)
            end
            if self.SettingWidget and self.SettingWidget:IsVisible() then
                MsgHelper:Send(self, GameDefine.Msg.SETTING_Hide)
            else
                self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                if self.IsInGame then
                    self.TextBlock_Back:SetText(self.BackText_InGame)
                else
                    self.TextBlock_Back:SetText(self.BackText_OutGame)
                end
            end
        end
    end
end
]]--
function MainMenu:OnSettingClick()
    -- local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if self.MvcCtrl and self.viewId then
        print("MainMenu:OnSettingClick")
        --通过Mvc框架管理的
        MvcEntry:CloseView(self.viewId)
        -- if UE.UGameplayStatics.GetPlatformName() == "Windows" then
        --     MvcEntry:OpenView(ViewConst.Setting)
        -- else
        --     MvcEntry:OpenView(ViewConst.SettingMobile)
        -- end
        if  BridgeHelper.IsPCPlatform() then
            MvcEntry:OpenView(ViewConst.Setting)
        else
            MvcEntry:OpenView(ViewConst.SettingMobile)
       end
    else
        local UIManager = UE.UGUIManager.GetUIManager(self)
        UIManager:TryLoadDynamicWidget("UMG_Setting")
    end
end


function MainMenu:OnReturnClick()
    if self.MvcCtrl and self.viewId then
        MvcEntry:OpenView(ViewConst.BackToLobbyConfirm)

    else
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        TipsManager:ShowTipsUIByTipsId("MainMenu.BackToLobbyConfirm")
    end

end

function MainMenu:OnBackClicked()
    
    if self.MvcCtrl and self.viewId then
        MvcEntry:CloseView(self.viewId)
    else
        local UIManager = UE.UGUIManager.GetUIManager(self)
        UIManager:TryCloseDynamicWidget("UMG_MainMenu")
    end
end

function MainMenu:OnConfirmClick()
end

function MainMenu:OnKeyDown(MyGeometry,InKeyEvent)
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey.KeyName == "Gamepad_FaceButton_Right"  or PressKey == self.PC_CloseKey then
        self:OnBackClicked()
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    local TotalSwitchKeyList,TotalSwitchResult = self.IAE_VoiceTotalSwitch:GetTargetKey(self)
    local ChatModeKeyList,ChatModeResult = self.IAE_VoiceChatModeSwitch:GetTargetKey(self)
    self.TotalSwitchKeyList = TotalSwitchKeyList
    self.ChatModeKeyList = ChatModeKeyList

    for index = 1, TotalSwitchKeyList:Num() do
        local TmpKey = TotalSwitchKeyList:Get(index)
        if PressKey ==  TmpKey then
            return UE.UWidgetBlueprintLibrary.Unhandled()
        end
    end

    for index = 1, ChatModeKeyList:Num() do
        local TmpKey = ChatModeKeyList:Get(index)
        if PressKey ==  TmpKey then
            return UE.UWidgetBlueprintLibrary.Unhandled()
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end


function MainMenu:OnMouseButtonDown(InMyGeometry, InMouseEvent)

    return UE.UWidgetBlueprintLibrary.Handled()
end

function MainMenu:OnMouseButtonUp(InMyGeometry, InMouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function MainMenu:OnCursorModeChanged(bNewCursorMode)

    local bIsGamepadMode = not bNewCursorMode
    local AllNavigationArr = UE.TArray(UE.FWidgetCustomNavigationData)
    if bIsGamepadMode then
        local Button_SettingNavgation = UE.UGamepadUMGFunctionLibrary.SetSingleWidgetNavgationData(self.BP_BtnSetting,self.BP_BtnQuitEditor,self.BP_BtnReturn,nil,nil)
        local Button_ReturnNavgation = UE.UGamepadUMGFunctionLibrary.SetSingleWidgetNavgationData(self.BP_BtnReturn,self.BP_BtnSetting,self.BP_BtnQuitEditor,nil,nil)
        local Button_QuitEditorNavgation = UE.UGamepadUMGFunctionLibrary.SetSingleWidgetNavgationData(self.BP_BtnQuitEditor,self.BP_BtnReturn,self.BP_BtnSetting,nil,nil)
        AllNavigationArr:Add(Button_SettingNavgation)
        AllNavigationArr:Add(Button_ReturnNavgation)
        AllNavigationArr:Add(Button_QuitEditorNavgation)
        UE.UGamepadUMGFunctionLibrary.InitAllCustomNaviagtionDataWithWidget(AllNavigationArr)
        self.BP_BtnSetting:SetFocus()
    end

    self.BP_BtnSetting.bIsFocusable = bIsGamepadMode
    self.BP_BtnReturn.bIsFocusable = bIsGamepadMode
    self.BP_BtnQuitEditor.bIsFocusable = bIsGamepadMode
end

-- function MainMenu:OnCommonInputNotify(InCurType)
--     self:Super_OnCommonInputNotify(InCurType)
--     print("MainMenu:OnCommonInputNotify [InCurType]=",InCurType)
-- end

return MainMenu