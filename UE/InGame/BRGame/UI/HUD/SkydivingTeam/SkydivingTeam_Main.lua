require "UnLua"
require "InGame.BRGame.GameDefine"

local SkydivingTeam_Main = Class("Common.Framework.UserWidget")

function SkydivingTeam_Main:OnInit()
    self.CacheInputHandle = false
    self.ActionGuideTextFontSize = 22
    self.CacheUIManager = UE.UGUIManager.GetUIManager(self)
    if self.CacheUIManager then
        self.SkydivingTeamVM = self.CacheUIManager:GetViewModelByName("SkydivingTeam")
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("SkydivingTeamVMState",{self, self.SkydivingTeamVMStateChange})
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("bVisibilityChooseNextTeamLeaderMenu",{self, self.OnChangeVisiblityChooseNextTeamLeaderMenu})
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("FollowPlayerId",{self, self.OnChangeFollowPlayerList})
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("CacheTeamLeaderIsLeaveShip",{self, self.OnChangeCacheTeamLeaderIsLeaveShip})
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("bIsProgressState",{self, self.OnbIsProgressStateChange})
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("ProgressPercentage",{self, self.OnProgressBarPercentageChange})
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("IsEnterShip",{self, self.OnEnterShipChange})
        self.SkydivingTeamVM:K2_AddFieldValueChangedDelegateSimple("IsShowSkydivingTeamUI",{self, self.OnIsShowSkydivingTeamUIChange})

        self:SkydivingTeamVMStateChange(self.SkydivingTeamVM, nil)
        self:OnChangeVisiblityChooseNextTeamLeaderMenu(self.SkydivingTeamVM, nil)
        self:OnChangeFollowPlayerList(self.SkydivingTeamVM, nil)
        self.CacheSelfVisibility = true
        self:UpdateSelfVisibility(self.SkydivingTeamVM)
    end

    self.PlayerBar_1.ChooseOnePlayerId:Add(self, self.OnChooseNextTeamLeaderConfirm)
    self.PlayerBar_2.ChooseOnePlayerId:Add(self, self.OnChooseNextTeamLeaderConfirm)
    self.PlayerBar_3.ChooseOnePlayerId:Add(self, self.OnChooseNextTeamLeaderConfirm)

    self:SetChooseNextLeaderMenuBtnIconImage()
    self:SetBtnInputImage_Interact()

    self.Button_Cancel.OnClicked:Add(self, self.OnButtonCancelClicked)

    UserWidget.OnInit(self)
end

function SkydivingTeam_Main:OnDestroy()
    if self.SkydivingTeamVM then
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("SkydivingTeamVMState",{self, self.SkydivingTeamVMStateChange})
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("bVisibilityChooseNextTeamLeaderMenu",{self, self.OnChangeVisiblityChooseNextTeamLeaderMenu})
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("FollowPlayerId",{self, self.OnChangeFollowPlayerList})
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("CacheTeamLeaderIsLeaveShip",{self, self.OnChangeCacheTeamLeaderIsLeaveShip})
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("bIsProgressState",{self, self.OnbIsProgressStateChange})
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("ProgressPercentage",{self, self.OnProgressBarPercentageChange})
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("IsEnterShip",{self, self.OnEnterShipChange})
        self.SkydivingTeamVM:K2_RemoveFieldValueChangedDelegateSimple("IsShowSkydivingTeamUI",{self, self.OnIsShowSkydivingTeamUIChange})

        self.SkydivingTeamVM = nil
    end

    UserWidget.OnDestroy(self)
end

function SkydivingTeam_Main:SkydivingTeamVMStateChange(VM, Field)
    -- 没起飞的位置
    if VM.SkydivingTeamVMState == 1 then
        self:PSState_NoTeamLeader()
    elseif VM.SkydivingTeamVMState == 2 then
        if VM.CacheTeamLeaderIsLeaveShip then
            self.CacheSelfVisibility = false
            self:UpdateSelfVisibility(VM)
        else
            local CurrentTeamLeader = VM:GetCurrentTeamLeader()
            self:PSState_TeamLeader(CurrentTeamLeader)
        end
    elseif VM.SkydivingTeamVMState == 3 then
        local CurrentTeamLeader = VM:GetCurrentTeamLeader()
        self:PSState_Follower(CurrentTeamLeader)
    elseif VM.SkydivingTeamVMState == 4 then
        if VM.CacheTeamLeaderIsLeaveShip or (not VM:IsAllowFollowAgain()) then
            self.CacheSelfVisibility = false
            self:UpdateSelfVisibility(VM)
        else
            local CurrentTeamLeader = VM:GetCurrentTeamLeader()
            self:PSState_FreePlayer(CurrentTeamLeader)
        end
    end
end

function SkydivingTeam_Main:OnChangeVisiblityChooseNextTeamLeaderMenu(VM, Field)
    if not self.CacheUIManager then
        self.CacheUIManager = UE.UGUIManager.GetUIManager(self)
    end

    self:OnChangeFollowPlayerList(VM, Field)
    local PlayerIdNum = VM.FollowPlayerId:Num()
    if VM.bVisibilityChooseNextTeamLeaderMenu == true and (not VM.CacheTeamLeaderIsLeaveShip) and (PlayerIdNum > 0) then
        self:TryChangeInputMode(false)

        self:SetSwitcherIndex(1)
        self:SetFocus()
    else
        self:TryChangeInputMode(true)

        self:SetSwitcherIndex(0)
        self:RecoveryLastButtonActionDisplay()
    end


end

function SkydivingTeam_Main:OnChangeFollowPlayerList(VM, Field)
    if VM.CacheTeamLeaderIsLeaveShip then
        return
    end

    local PlayerIdNum = VM.FollowPlayerId:Num()
    if PlayerIdNum == 1 then
        self.PlayerBar_1:SetVisibility(UE.ESlateVisibility.Visible)
        self.PlayerBar_2:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.PlayerBar_3:SetVisibility(UE.ESlateVisibility.Collapsed)
        local PlayerId_1 = VM.FollowPlayerId:Get(1)
        self.PlayerBar_1:SetPlayerBarDisplayInfo(PlayerId_1)
    elseif PlayerIdNum == 2 then
        self.PlayerBar_1:SetVisibility(UE.ESlateVisibility.Visible)
        self.PlayerBar_2:SetVisibility(UE.ESlateVisibility.Visible)
        self.PlayerBar_3:SetVisibility(UE.ESlateVisibility.Collapsed)
        local PlayerId_1 = VM.FollowPlayerId:Get(1)
        self.PlayerBar_1:SetPlayerBarDisplayInfo(PlayerId_1)
        local PlayerId_2 = VM.FollowPlayerId:Get(2)
        self.PlayerBar_2:SetPlayerBarDisplayInfo(PlayerId_2)
    elseif PlayerIdNum == 3 then
        self.PlayerBar_1:SetVisibility(UE.ESlateVisibility.Visible)
        self.PlayerBar_2:SetVisibility(UE.ESlateVisibility.Visible)
        self.PlayerBar_3:SetVisibility(UE.ESlateVisibility.Visible)
        local PlayerId_1 = VM.FollowPlayerId:Get(1)
        self.PlayerBar_1:SetPlayerBarDisplayInfo(PlayerId_1)
        local PlayerId_2 = VM.FollowPlayerId:Get(2)
        self.PlayerBar_2:SetPlayerBarDisplayInfo(PlayerId_2)
        local PlayerId_3 = VM.FollowPlayerId:Get(3)
        self.PlayerBar_3:SetPlayerBarDisplayInfo(PlayerId_3)
    else
        self.PlayerBar_1:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.PlayerBar_2:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.PlayerBar_3:SetVisibility(UE.ESlateVisibility.Collapsed)
        if self.SkydivingTeamVM then
            self.SkydivingTeamVM:CloseChooseNextTeamLeaderMenu()
        end
        self:TryChangeInputMode(true)
        self:SetSwitcherIndex(0)
    end

    self:RecoveryLastButtonActionDisplay()
end

function SkydivingTeam_Main:OnChangeCacheTeamLeaderIsLeaveShip(VM, Field)
    if VM.SkydivingTeamVMState == 1 then
        self:PSState_NoTeamLeader()
    elseif VM.SkydivingTeamVMState == 2 then
        if VM.CacheTeamLeaderIsLeaveShip then
            self.CacheSelfVisibility = false
            self:UpdateSelfVisibility(VM)
        else
            self:PSState_TeamLeader()
        end
    elseif VM.SkydivingTeamVMState == 3 then
        local CurrentTeamLeader = VM:GetCurrentTeamLeader()
        self:PSState_Follower(CurrentTeamLeader)
    elseif VM.SkydivingTeamVMState == 4 then
        if VM.CacheTeamLeaderIsLeaveShip or (not VM:IsAllowFollowAgain()) then
            self.CacheSelfVisibility = false
            self:UpdateSelfVisibility(VM)
        else
            local CurrentTeamLeader = VM:GetCurrentTeamLeader()
            self:PSState_FreePlayer(CurrentTeamLeader)
        end
    end
end

function SkydivingTeam_Main:OnbIsProgressStateChange(VM, Field)
    if VM.bIsProgressState then
        self.GUIProgressBar_Hold:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
        self.GUIProgressBar_Hold:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function SkydivingTeam_Main:OnEnterShipChange(VM, Field)
    if VM then
        if VM.IsEnterShip then
            self:AddActiveWidgetStyle("state2")
        end
    end
end

function SkydivingTeam_Main:OnIsShowSkydivingTeamUIChange(VM, Field)
    if VM then
        self:UpdateSelfVisibility(VM)
    end
end

function SkydivingTeam_Main:UpdateSelfVisibility(VM)
    if VM.IsShowSkydivingTeamUI then
        if self.CacheSelfVisibility then
            self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


-- 设置显示的面板index。入参只接受 0 或者 1，因为只有 2 个子控件。0 是主界面，1 是选择下一个队长的菜单。
function SkydivingTeam_Main:SetSwitcherIndex(InIndex)
    if InIndex == 0 or InIndex == 1 then
        if self.WidgetSwitcher_Main then
            self.WidgetSwitcher_Main:SetActiveWidgetIndex(InIndex)
        end
        self.CacheInputHandle = InIndex == 1
    end
end

function SkydivingTeam_Main:OnKeyDown(MyGeometry, InKeyEvent)
    print("SkydivingTeam_Main " .. "OnKeyDown")
    if not self.CacheInputHandle then
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
    local MouseKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if not MouseKey then 
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
    
    print("SkydivingTeam_Main " .. "OnKeyDown", MouseKey.KeyName)
    if MouseKey.KeyName == "Gamepad_FaceButton_Bottom" then
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif MouseKey.KeyName == "Gamepad_FaceButton_Right" then
        --这里需要帮忙调一下取消转让的函数
        self:OnButtonCancelClicked()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif MouseKey.KeyName == "SpaceBar" then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function SkydivingTeam_Main:OnProgressBarPercentageChange(VM, Field)
    self.GUIProgressBar_Hold:SetPercent(VM.ProgressPercentage)
end


function SkydivingTeam_Main:OnChooseNextTeamLeaderConfirm(PlayerId)
    if self.SkydivingTeamVM then
        self.SkydivingTeamVM:ConfirmNextTeamLeader(PlayerId)
    end
end

function SkydivingTeam_Main:RecoveryLastButtonActionDisplay()
    -- 使用缓存的
    if self.SkydivingTeamVM then
        if self.SkydivingTeamVM.SkydivingTeamVMState == 1 then
            self:SetActionBtnText_RequestTeamLeader()
        elseif self.SkydivingTeamVM.SkydivingTeamVMState == 2 then
            self:SetActionBtnText_TransferLeader()
        elseif self.SkydivingTeamVM.SkydivingTeamVMState == 3 then
            self:SetActionBtnText_CancelFollow()
        elseif self.SkydivingTeamVM.SkydivingTeamVMState == 4 then
            local CurrentTeamLeaderId = self.SkydivingTeamVM:GetCurrentTeamLeader()
            local CurrentPS = UE.AGeGameState.GetPlayerStateBy(self, CurrentTeamLeaderId)
            if CurrentPS then
                self:SetActionBtnText_FollowAgain(CurrentPS)
            end
        end
    end
end

function SkydivingTeam_Main:PSState_NoTeamLeader()
    self:SetActionGuideText_NeedLeader()
    self:SetActionBtnText_RequestTeamLeader()
    self:SetTeamLeaderBgVisibility(false)
end

function SkydivingTeam_Main:PSState_TeamLeader(TeamLeaderId)
    local CurrentPS = UE.AGeGameState.GetPlayerStateBy(self, TeamLeaderId)
    if CurrentPS then
        self:SetActionGuideText_PlayerNameIsLeader(CurrentPS)
    end

    self:SetActionBtnText_TransferLeader()
    self:SetTeamLeaderBgVisibility(true)
end


function SkydivingTeam_Main:PSState_Follower(TeamLeaderId)
    local CurrentPS = UE.AGeGameState.GetPlayerStateBy(self, TeamLeaderId)
    if CurrentPS then
        self:SetActionGuideText_PlayerNameIsLeader(CurrentPS)
    end
    self:SetActionBtnText_CancelFollow()
    self:SetTeamLeaderBgVisibility(true)
end

function SkydivingTeam_Main:PSState_FreePlayer(TeamLeaderId)
    self:SetActionGuideText_JumpAlone()
    local CurrentPS = UE.AGeGameState.GetPlayerStateBy(self, TeamLeaderId)
    if CurrentPS then
        self:SetActionBtnText_FollowAgain(CurrentPS)
    end
    self:SetTeamLeaderBgVisibility(false)
end

-- 操作指引文本：缺少跳伞指挥
function SkydivingTeam_Main:SetActionGuideText_NeedLeader()
    local Key2Values = {
        Size = self.ActionGuideTextFontSize
    }
    --local aa = "<span color=\"#F5EFDFFF\" size=\"24\">缺少跳伞指挥</>"
    local NewStr = StringUtil.FormatByKey(G_ConfigHelper:GetStrFromIngameStaticST("SD_HUDOther","2365"), Key2Values)
    self.RichTextBlock_SomeThing:SetText(NewStr)
end

-- 操作指引文本：单独脱离
function SkydivingTeam_Main:SetActionGuideText_JumpAlone()
    local Key2Values = {
        Size = self.ActionGuideTextFontSize
    }
    local NewStr = StringUtil.FormatByKey(G_ConfigHelper:GetStrFromIngameStaticST("SD_HUDOther","2366"), Key2Values)
    self.RichTextBlock_SomeThing:SetText(NewStr)
end

-- 操作指引文本：XXX 是跳伞指挥官
function SkydivingTeam_Main:SetActionGuideText_PlayerNameIsLeader(InPS, InStr)
    if not InPS then
        return
    end

    local HexColorStr = self:GetHexPlayerColorString(InPS)
    local CurrentPlayerNameFText = InPS:GetPlayerName()
    local Key2Values = {
        Color = HexColorStr,
        Size = self.ActionGuideTextFontSize,
        PlayerName = CurrentPlayerNameFText
    }

    local NewStr = StringUtil.FormatByKey(G_ConfigHelper:GetStrFromIngameStaticST("SD_HUDOther","2364"), Key2Values)
    self.RichTextBlock_SomeThing:SetText(NewStr)
end

-- 按钮文本：转让指挥
function SkydivingTeam_Main:SetActionBtnText_TransferLeader()
    if self.SkydivingTeamVM then
        local PlayerIdNum = self.SkydivingTeamVM.FollowPlayerId:Num()
        if (PlayerIdNum > 0) then
            self.GUIHorizontalBox_DoSomeThing:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

            local Key2Values = {
                Size = self.ActionGuideTextFontSize
            }
            local NewStr = StringUtil.FormatByKey(G_ConfigHelper:GetStrFromIngameStaticST("SD_HUDOther","2367"), Key2Values)
            self.RichTextBlock_SomeThing_Operation:SetText(NewStr)
        else
            self.GUIHorizontalBox_DoSomeThing:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

-- 按钮文本：取消跟随
function SkydivingTeam_Main:SetActionBtnText_CancelFollow()
    self.GUIHorizontalBox_DoSomeThing:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

    local Key2Values = {
        Size = self.ActionGuideTextFontSize
    }

    local NewStr = StringUtil.FormatByKey(G_ConfigHelper:GetStrFromIngameStaticST("SD_HUDOther","2368"), Key2Values)
    self.RichTextBlock_SomeThing_Operation:SetText(NewStr)
end

-- 按钮文本：继续跟随玩家
function SkydivingTeam_Main:SetActionBtnText_FollowAgain(InPS)
    if not InPS then
        return
    end

    self.GUIHorizontalBox_DoSomeThing:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

    local HexColorStr = self:GetHexPlayerColorString(InPS)
    local CurrentPlayerNameFText = InPS:GetPlayerName()
    local Key2Values = {
        Color = HexColorStr,
        Size = self.ActionGuideTextFontSize,
        PlayerName = CurrentPlayerNameFText
    }
    local NewStr = StringUtil.FormatByKey(G_ConfigHelper:GetStrFromIngameStaticST("SD_HUDOther","2369"), Key2Values)
    self.RichTextBlock_SomeThing_Operation:SetText(NewStr)
end

-- 按钮文本：申请跳伞指挥
function SkydivingTeam_Main:SetActionBtnText_RequestTeamLeader()
    self.GUIHorizontalBox_DoSomeThing:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

    local Key2Values = {
        Size = self.ActionGuideTextFontSize
    }

    local NewStr = StringUtil.FormatByKey(G_ConfigHelper:GetStrFromIngameStaticST("SD_HUDOther","2370"), Key2Values)
    self.RichTextBlock_SomeThing_Operation:SetText(NewStr)
end

function SkydivingTeam_Main:GetHexPlayerColorString(InPS)
    if InPS then
        local CurTeamPos = BattleUIHelper.GetTeamPos(InPS)
        if CurTeamPos == 1 then
            return '#4DD032FF'
        elseif CurTeamPos == 2 then
            return '#2EE3E5FF'
        elseif CurTeamPos == 3 then
            return '#FF7165FF'
        elseif CurTeamPos == 4 then
            return '#FFC74FFF'
        end
    end

    -- 255 或者其他
    return '#00FF00FF'
end

-- 设置按键输入图片的通用函数
function SkydivingTeam_Main:SetBtnInputImage(InInputAction)
    self.BtnInputImage.InputAction = InInputAction
    self.BtnInputImage:RefreshKeyIcon(InInputAction)
end

-- 设置输入按键的图片：交互键
function SkydivingTeam_Main:SetBtnInputImage_Interact()
    self:SetBtnInputImage(self.InputAction_InteractSoftRef)
end

-- 设置背景板
function SkydivingTeam_Main:SetTeamLeaderBgVisibility(ShowState)
    if self.Overlay_TeamLeaderBg then
        if ShowState then
            self.Overlay_TeamLeaderBg:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
            self.Overlay_TeamLeaderBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function SkydivingTeam_Main:OnButtonCancelClicked()
    if self.SkydivingTeamVM then
        self.SkydivingTeamVM:CloseChooseNextTeamLeaderMenu()
    end
end

function SkydivingTeam_Main:OnGUIButton_BackgroundClicked()
    if self.SkydivingTeamVM then
        self.SkydivingTeamVM:CloseChooseNextTeamLeaderMenu()
    end
end



function SkydivingTeam_Main:SetChooseNextLeaderMenuBtnIconImage()
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end

    -- 获取当前的按键图片
    local KeyboardKey = UE.FKey()
    local HasKey = false

    local KeyArray = UE.TArray(UE.FKey)
    self.InputAction_Interact:GetTargetKey(self, KeyArray)
    local ArrayNum = KeyArray:Num()
    for i = 1 , ArrayNum do
        local LoopKey = KeyArray:Get(i)
        if LoopKey then
            local IsKeyboardKey = UE.UKismetInputLibrary.Key_IsKeyboardKey(LoopKey)
            if IsKeyboardKey then
                KeyboardKey = LoopKey
                HasKey = true
                break
            end
        end
    end

    if HasKey then
        local TargetDefaultIcon = SettingSubsystem.KeyIconMap:TryGetIconByKeyWithState(self, KeyboardKey, UE.EkeyStateType.Default)
        local TargetHoverIcon = SettingSubsystem.KeyIconMap:TryGetIconByKeyWithState(self, KeyboardKey, UE.EkeyStateType.Hover)

        if TargetDefaultIcon and self.BtnInputImage_Menu_Normal then
            -- Icon 正常颜色
            self.BtnInputImage_Menu_Normal:SetBrushFromTexture(TargetDefaultIcon)

            -- 设置文字颜色
            local TextColor = UE.FSlateColor()
            TextColor.SpecifiedColor = self.TextColorNormal
            self.BtnCancelSwitchLeader_Normal:SetColorAndOpacity(TextColor)
        end

        if TargetHoverIcon and self.BtnInputImage_Menu_Hover and self.BtnInputImage_Menu_Click then
            -- Icon 反色
            self.BtnInputImage_Menu_Hover:SetBrushFromTexture(TargetHoverIcon)
            self.BtnInputImage_Menu_Click:SetBrushFromTexture(TargetHoverIcon)

            -- 设置文字颜色
            local TextColor = UE.FSlateColor()
            TextColor.SpecifiedColor = self.TextColorHover
            self.BtnCancelSwitchLeader_Hover:SetColorAndOpacity(TextColor)
            self.BtnCancelSwitchLeader_Click:SetColorAndOpacity(TextColor)
        end
    end

end

function SkydivingTeam_Main:OnMouseButtonDown(MyGeometry, MouseEvent)
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)

    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
        self.SkydivingTeamVM:CloseChooseNextTeamLeaderMenu()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function SkydivingTeam_Main:OnFocusLost(InFocusEvent)
    self:TryChangeInputMode(true)
    self:SetSwitcherIndex(0)
    self:RecoveryLastButtonActionDisplay()
end


return SkydivingTeam_Main