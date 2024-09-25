require ("Common.Utils.StringUtil")

local StartGameWidget_DF = Class("Common.Framework.UserWidget")

function StartGameWidget_DF:OnInit()
    print("StartGameWidget_DF:OnInit")
    self.UIManager = UE.UGUIManager.GetUIManager(self)
    self.bFinishCountDown = false
    if BridgeHelper.IsMobilePlatform() then

        self.GUIHorizontalBox_0:SetVisibility(UE.ESlateVisibility.Visible)

        self.WBP_ChangeHeroBtn.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_ChangeWeaponBtn.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)

        self.HorizontalBox_PCInfo:SetVisibility(UE.ESlateVisibility.Collapsed)

        self.BindNodes ={
            { UDelegate = self.WBP_ChangeHeroBtn.GUIButton_Tips.OnClicked, Func = self.OnClicked_WBP_ChangeHeroBtn },
            { UDelegate = self.WBP_ChangeWeaponBtn.GUIButton_Tips.OnClicked, Func = self.OnClicked_WBP_ChangeWeaponBtn},
        }
        self.WBP_ChangeHeroBtn.ControlTipsTxt:SetText(self.WBP_ChangeHeroBtn.TextContent)
        self.WBP_ChangeWeaponBtn.ControlTipsTxt:SetText(self.WBP_ChangeWeaponBtn.TextContent)
    end
    UserWidget.OnInit(self)
end

function StartGameWidget_DF:OnClicked_WBP_ChangeHeroBtn()
    print("StartGameWidget_DF >> OnClicked_WBP_ChangeHeroBtn")
    if self.UIManager ~= nil then
        print("UIManager is not nil")
        self.UIManager:TryLoadDynamicWidget("UMG_Birthland")
    end
end

function StartGameWidget_DF:OnClicked_WBP_ChangeWeaponBtn()
    print("StartGameWidget_DF >> OnClicked_WBP_ChangeWeaponBtn")
    if self.UIManager ~= nil then
        print("UIManager is not nil")
        self.UIManager:TryLoadDynamicWidget("UMG_ChooseWeaponCombination")
    end
end

function StartGameWidget_DF:OnShow()
    print("StartGameWidget_DF:OnShow")
    self.CountDownTime = 0
    self.DFCountDownText = ""
    self.FinalCountDownTime = 5
    self.bFinishCountDown = false
end

function StartGameWidget_DF:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self.CountDownTime = NewCountDownTime
    self.DFCountDownText = self.TxtTips:GetText()
    self.bFinishCountDown = false
    self.TxtTips:SetText(StringUtil.Format(self.DFCountDownText, math.floor(self.CountDownTime)))
    self:VXE_StartGame_In()
end

function StartGameWidget_DF:Tick(MyGeometry, InDeltaTime)
    if self.CountDownTime <= 0 then return end
    local FormatDeltaTime = string.format("%.1f", InDeltaTime)
    self.CountDownTime = self.CountDownTime - FormatDeltaTime
    self.TxtTips:SetText(StringUtil.Format(self.DFCountDownText, math.floor(self.CountDownTime)))
    --最后倒计时动效
    if self.CountDownTime <= 5.5 and self.FinalCountDownTime > 0 then
        if self.FinalCountDownTime == math.floor(self.FinalCountDownTime) then
            self.FinalCountDownText:SetText(math.floor(self.FinalCountDownTime))
            self:VXE_StartGame_Countdown()
        end
        self.FinalCountDownTime = self.FinalCountDownTime - FormatDeltaTime
    end
    if not self.bFinishCountDown and self.CountDownTime > 0 and self.CountDownTime < 1 then 
        self.bFinishCountDown = true
        self:VXE_StartGame_Out() 
    end
end

function StartGameWidget_DF:OnDestroy()
    UserWidget.OnDestroy(self)
end


return StartGameWidget_DF