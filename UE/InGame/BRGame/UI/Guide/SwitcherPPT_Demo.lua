require "UnLua"

local SwitcherPPT_Demo = Class("Client.Mvc.UserWidgetBase")

function SwitcherPPT_Demo:OnInit()
    print("SwitcherPPT_Demo:OnInit")
    -- 初始化总页数
    local SwitcherChildrenCount = self:GetSwitcherChildrenCount()
    local ProgressPointCount = self:GetProgressPointCount()

    if ProgressPointCount == SwitcherChildrenCount then
        if SwitcherChildrenCount > 0 then
            -- 绑定按钮
            self:BindButtonClicked_PgUp()
            self:BindButtonClicked_PgDown()
            -- 刷新翻页按钮显示状态
            self:UpdateVisibility_PgUp_PgDown()
            -- 刷新页码圆点显示状态
            self:UpdateProgressPointIndexState()
            -- 开始倒计时时间
            self:StartAutoFlipCountdownTimer(self.AutoFlipCountdownTimePerPage)
            -- 绑定Exit按钮单击回调
            self:BindButtonClicked_Exit()
            -- 刷新Exit的Enable状态
            self:UpdateExitBtnEnabledState()
        end
    end

    UserWidgetBase.OnInit(self)
end

function SwitcherPPT_Demo:OnDestroy()
    self:ClearAutoFlipCountdownTimer()

    UserWidgetBase.OnDestroy(self)
end

function SwitcherPPT_Demo:OnKeyDown(_,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey.KeyName ==  "Gamepad_LeftShoulder" then
        self:OnClicked_GUIButton_PgUp()
    elseif  PressKey.KeyName == "Gamepad_RightShoulder"  then
        self:OnClicked_GUIButton_PgDown()
    elseif PressKey.KeyName == "Gamepad_FaceButton_Right" then
        self:OnExitBtnClicked()
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

-- 获得当前 Switcher 内的个数
function SwitcherPPT_Demo:GetSwitcherChildrenCount()
    if self.WidgetSwitcher_Node then
        return self.WidgetSwitcher_Node:GetChildrenCount()
    end

    return 0
end

-- 获得当前激活页 Index
function SwitcherPPT_Demo:GetSwitcherActiveWidgetIndex()
    if self.WidgetSwitcher_Node then
        return self.WidgetSwitcher_Node:GetActiveWidgetIndex()
    end

    return -1
end

-- 设置页 Index
function SwitcherPPT_Demo:SetSwitcherIndex(InIndex)
    if self.WidgetSwitcher_Node then
        self.WidgetSwitcher_Node:SetActiveWidgetIndex(InIndex)
        if InIndex == 1 then
            self:ForceLayoutPrepass()
        end
        self:UpdateVisibility_PgUp_PgDown()
        self:UpdateProgressPointIndexState()
        self:StartAutoFlipCountdownTimer(self.AutoFlipCountdownTimePerPage)
        self:UpdateExitBtnEnabledState()
        self:UpdateCountDownTextState()
    end
end

-- 获得当前 进度圆点 内的个数
function SwitcherPPT_Demo:GetProgressPointCount()
    if self.HB_ProgressPoint then
        return self.HB_ProgressPoint:GetChildrenCount()
    end

    return 0
end

-- 更新 页码圆点 显示状态
function SwitcherPPT_Demo:UpdateProgressPointIndexState()
    if self.HB_ProgressPoint then
        local TempProgressPointIndexMax = self:GetProgressPointCount() - 1
        if TempProgressPointIndexMax > 0 then
            for i = 0, TempProgressPointIndexMax, 1 do
                local TempProgressImageWidget = self.HB_ProgressPoint:GetChildAt(i)
                if TempProgressImageWidget then
                    if i == self:GetSwitcherActiveWidgetIndex() then
                        TempProgressImageWidget:SetBrushFromTexture(self.PrograssPointImageSolid, false)
                    else
                        TempProgressImageWidget:SetBrushFromTexture(self.PrograssPointImageHollow, false)
                    end
                end
            end
        end
    end
end

-- 更新按钮显示状态（上一页按钮 + 下一页按钮）
function SwitcherPPT_Demo:UpdateVisibility_PgUp_PgDown()
    local CurrentActivePageIndex = self:GetSwitcherActiveWidgetIndex()
    if CurrentActivePageIndex == 0 then
        self.GUIButton_PgUp:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.GUIButton_PgDown:SetVisibility(UE.ESlateVisibility.Visible)
    elseif (CurrentActivePageIndex + 1) == self:GetSwitcherChildrenCount() then
        self.GUIButton_PgUp:SetVisibility(UE.ESlateVisibility.Visible)
        self.GUIButton_PgDown:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        -- 都显示
        self.GUIButton_PgUp:SetVisibility(UE.ESlateVisibility.Visible)
        self.GUIButton_PgDown:SetVisibility(UE.ESlateVisibility.Visible)
    end
end

-- 绑定 上一页 按钮 clicked
function SwitcherPPT_Demo:BindButtonClicked_PgUp()
    if self.GUIButton_PgUp then
        self.GUIButton_PgUp.GUIButton_Main.OnClicked:Add(self, self.OnClicked_GUIButton_PgUp)
    end
end

-- 绑定 下一页 按钮 clicked
function SwitcherPPT_Demo:BindButtonClicked_PgDown()
    if self.GUIButton_PgDown then
        self.GUIButton_PgDown.GUIButton_Main.OnClicked:Add(self, self.OnClicked_GUIButton_PgDown)
    end
end

-- 按 上一页 按钮
function SwitcherPPT_Demo:OnClicked_GUIButton_PgUp()
    local NewPageIndex = self:GetSwitcherActiveWidgetIndex() - 1
    if NewPageIndex >= 0 then
        self:SetSwitcherIndex(NewPageIndex)
    end
end

-- 按 下一页 按钮
function SwitcherPPT_Demo:OnClicked_GUIButton_PgDown()
    local NewPageIndex = self:GetSwitcherActiveWidgetIndex() + 1
    if NewPageIndex < self:GetSwitcherChildrenCount() then
        self:SetSwitcherIndex(NewPageIndex)
    end
end

-- 更新倒计时数字
function SwitcherPPT_Demo:UpdateCountdownNumber(InNumber)
    if InNumber >= 0 then
        self.CurrentAutoFlipCountdownSecond = InNumber
        if self.Text_CountdownNumber then
            self.Text_CountdownNumber:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromIngameStaticST("SD_HUDOther", "2371"), InNumber))
        end
    end
end

-- 开始自动翻页倒计时
function SwitcherPPT_Demo:StartAutoFlipCountdownTimer(InNumber)
    if UE.UKismetSystemLibrary.K2_IsTimerActiveHandle(self, self.AutoFlipTimerHandle) then
        self:ClearAutoFlipCountdownTimer()
    end

    self.AutoFlipTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnAutoFlipCountdownTimerCheck }, 1, true, 0.1, 0)
    self:UpdateCountdownNumber(InNumber)
end

function SwitcherPPT_Demo:ClearAutoFlipCountdownTimer()
    if UE.UKismetSystemLibrary.K2_IsTimerActiveHandle(self, self.AutoFlipTimerHandle) then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.AutoFlipTimerHandle)
    end
end

-- 自动翻页倒计时每秒检查
function SwitcherPPT_Demo:OnAutoFlipCountdownTimerCheck()
    -- body
    local NewCountdownSecond = self.CurrentAutoFlipCountdownSecond - 1
    if NewCountdownSecond >= 0 then
        self.CurrentAutoFlipCountdownSecond = NewCountdownSecond
        self:UpdateCountdownNumber(self.CurrentAutoFlipCountdownSecond)
    else
        self.CurrentAutoFlipCountdownSecond = -1
        local PageIndexActive = self:GetSwitcherActiveWidgetIndex()
        local PageIndexMax = self:GetSwitcherChildrenCount()
        if PageIndexActive == (PageIndexMax - 1) then
            -- 最后一页
            self:ClearAutoFlipCountdownTimer()
        else
            -- 下一页
            self:SetSwitcherIndex(PageIndexActive + 1)
        end
    end
end

function SwitcherPPT_Demo:OnExitBtnClicked()
    local PageIndexActive = self:GetSwitcherActiveWidgetIndex()
    local PageIndexMax = self:GetSwitcherChildrenCount()
    if PageIndexActive == (PageIndexMax - 1) then
        local UIManager = UE.UGUIManager.GetUIManager(self)
        if UIManager then
            UIManager:TryCloseDynamicWidget("UMG_OperationGuide")
        end
        self:ClearAutoFlipCountdownTimer()
    else
        -- 不是最后一页
        local TipsManager =  UE.UTipsManager.GetTipsManager(self)
        --TipsID在Tips表查
        if TipsManager then
            TipsManager:ShowTipsUIByTipsId("Guide.IKnowCantPress")
        end
    end
end

function SwitcherPPT_Demo:BindButtonClicked_Exit()
    --绑定通用按钮接口
    --if self.WBP_CommonBtn_Weak_M then
    --    self.GUIButton_Exit.OnClicked:Add(self, self.OnExitBtnClicked)
    --end

    UIHandler.New(self, self.WBP_CommonBtn_Weak_M, WCommonBtnTips,
            {
                OnItemClick = Bind(self,self.OnExitBtnClicked),
                TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Achievement', "1244"),
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            })
end

function SwitcherPPT_Demo:UpdateExitBtnEnabledState()
    if self.WBP_CommonBtn_Weak_M then
        if (self:GetSwitcherActiveWidgetIndex() + 1) == self:GetSwitcherChildrenCount() then
            self.WBP_CommonBtn_Weak_M:SetIsEnabled(true)
            self.WBP_CommonBtn_Weak_M.GUIButton_Tips:SetColorAndOpacity(self.ExitBtnNormalColor)
        else
            self.WBP_CommonBtn_Weak_M:SetIsEnabled(false)
            self.WBP_CommonBtn_Weak_M.GUIButton_Tips:SetColorAndOpacity(self.ExitBtnGrayColor)
        end
    end
end
function SwitcherPPT_Demo:UpdateCountDownTextState()
    if self.HorizontalBox_0 then
        if (self:GetSwitcherActiveWidgetIndex() + 1) == self:GetSwitcherChildrenCount() then
            self.HorizontalBox_0:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end
return SwitcherPPT_Demo