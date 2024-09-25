require "UnLua"

local class_name = "MainMenuUI"
MainMenuUI = MainMenuUI or BaseClass(GameMediator, class_name);

function MainMenuUI:__init()
    print("SettingMainUI:__init")
    self:ConfigViewId(ViewConst.MainMenuMobile)
end

function MainMenuUI:OnShow(data)
    print("MainMenuUI:OnShow")
end

function MainMenuUI:OnHide()
end

local MainMenuMobile = Class("Client.Mvc.UserWidgetBase")

function MainMenuMobile:OnInit()
    print("MainMenuMobile:OnInit")
    self.IsInGame = true
    -- 注册消息监听
	self.MsgList = {
        --{ MsgName = "UIEvent.OpenMainMenu",	    Func = self.OnMainMenuVisibilityToggle,      bCppMsg = true, WatchedObject = nil},
    }
    MsgHelper:RegisterList(self, self.MsgList)
    self.Button_Setting.OnClicked:Add(self, MainMenuMobile.OnSettingClick)
    self.Button_Return.OnClicked:Add(self, MainMenuMobile.OnReturnClick)

    self:SetHoveredStyle(self.Button_Return)
    self:SetHoveredStyle(self.Button_Setting)


    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, true)
    end

    if self.Button_QuitEditor then
        self.Button_QuitEditor.OnClicked:Add(self, MainMenuMobile.OnQuitEditorClick)
        self:SetHoveredStyle(self.Button_QuitEditor)
        self.Button_QuitEditor:SetVisibility(UE.UGFUnluaHelper.IsEditor() and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    end
    --因为如果只是简单隐藏返回大厅按钮，会有奇怪的效果，故还是共用一个按钮
    if  self.MvcCtrl and self.viewId  then
        self.Txt_Return:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MainMenu_Exitthegame")))
    else
        self.Txt_Return:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MainMenu_Returntothehall")))
    end
    UserWidgetBase.OnInit(self)
end

function MainMenuMobile:SetHoveredStyle(Button)
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


function MainMenuMobile:OnQuitEditorClick()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if PlayerController then
        UE.UKismetSystemLibrary.QuitGame(self,PlayerController,0,false)
    end
end

function MainMenuMobile:OnDestroy()
	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end
    UserWidgetBase.OnDestroy(self)
    --self:Release()
end

function MainMenuMobile:OnShow(data)
    -- print("BackToLobbyConfirm:OnShow",data)
    -- local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    -- if PlayerController then
    --     PlayerController.bShowMouseCursor = true;

    -- end
end
--[[
function MainMenuMobile:OnMainMenuVisibilityToggle()
    print(("MainMenuMobile:OnMainMenuVisibilityToggle"))
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
function MainMenuMobile:OnSettingClick()
    -- local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if self.MvcCtrl and self.viewId then
        print("MainMenuMobile:OnSettingClick")
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


function MainMenuMobile:OnReturnClick()
    if self.MvcCtrl and self.viewId then
        MvcEntry:OpenView(ViewConst.BackToLobbyConfirm)

    else
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        TipsManager:ShowTipsUIByTipsId("MainMenuMobile.BackToLobbyConfirm")
    end

end

function MainMenuMobile:OnBackClicked()
    
    if self.MvcCtrl and self.viewId then
        MvcEntry:CloseView(self.viewId)
    else
        local UIManager = UE.UGUIManager.GetUIManager(self)
        UIManager:TryCloseDynamicWidget("UMG_MainMenu")
    end
end

function MainMenuMobile:OnConfirmClick()
end

function MainMenuMobile:OnKeyDown(MyGeometry,InKeyEvent)
    -- local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    -- if PressKey == UE.FName("Escape") then
    --     self:OnBackClicked()
    -- end
    return UE.UWidgetBlueprintLibrary.Handled()
end



function MainMenuMobile:OnKeyUp(MyGeometry,InKeyEvent)
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == UE.FName("Escape") then
        self:OnBackClicked()
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

return MainMenuMobile