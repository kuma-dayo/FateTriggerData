local OBEasterMobile = Class("Common.Framework.UserWidget")

local SelfVMTagName = "TagLayout.GamePlay.OB.Easter"

function OBEasterMobile:GetSelfVM()
    local SelfVM
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager then
        SelfVM = UIManager:GetViewModelByName(SelfVMTagName)
    end
    return SelfVM
end

function OBEasterMobile:OnInit()
    print("OBEasterMobile >> OnInit")

    local vm = self:GetSelfVM()
    if vm then
        self:InitView(vm)

        vm:K2_AddFieldValueChangedDelegateSimple("CurOBEasterState",{ self, self.UpdateCurOBEasterState })
        vm:K2_AddFieldValueChangedDelegateSimple("RespawnGeneRemainTime",{ self, self.UpdateRespawnGeneRemainTime })
    end

    self.BP_OBRemindTips.Button_Remind.OnClicked:Add(self, self.OnClickRemindTipsBtn)
    self.BP_OBDeathTips.Button_Detail.OnClicked:Add(self, self.OnClickDeathTipsBtn)
    
	UserWidget.OnInit(self)
end

function OBEasterMobile:OnDestroy()
    print("OBEasterMobile >> OnDestroy")

    local vm = self:GetSelfVM()
    if vm then
        vm:K2_RemoveFieldValueChangedDelegateSimple("CurOBEasterState",{ self, self.UpdateCurOBEasterState })
        vm:K2_RemoveFieldValueChangedDelegateSimple("RespawnGeneRemainTime",{ self, self.UpdateRespawnGeneRemainTime })
    end

    self.BP_OBRemindTips.Button_Remind.OnClicked:Clear()
    self.BP_OBDeathTips.Button_Detail.OnClicked:Clear()

	UserWidget.OnDestroy(self)
end

function OBEasterMobile:InitView(vm)
    vm:UpdateWithCurOBEasterState()

    self:UpdateCurOBEasterState(vm, nil)
    self:UpdateRespawnGeneRemainTime(vm, nil)
end

function OBEasterMobile:UpdateCurOBEasterState(vm, fieldID)
    print("OBEasterMobile >> UpdateCurOBEasterState. CurOBEasterState = ", vm.CurOBEasterState)

    local EasterStateIndex = 1

    if vm.CurOBEasterState == UE.EOBEasterState.Respawnable then
        EasterStateIndex = 0
    elseif vm.CurOBEasterState == UE.EOBEasterState.SelfOver then
        EasterStateIndex = 1
    elseif vm.CurOBEasterState == UE.EOBEasterState.TeamOver then
        EasterStateIndex = 1
    end

    self.WidgetSwitcher_EasterState:SetActiveWidgetIndex(EasterStateIndex)
end

function OBEasterMobile:UpdateRespawnGeneRemainTime(vm, fieldID)
    -- print("OBEasterMobile >> UpdateRespawnGeneRemainTime. CurRespawnGeneRemainTime = ", vm.RespawnGeneRemainTime)

    self.BP_OBRemindTips.Text_Time:SetText(string.format("%.f", vm.RespawnGeneRemainTime))
end

function OBEasterMobile:OnClickRemindTipsBtn()
    local vm = self:GetSelfVM()
    if vm then
        if vm.CurOBEasterState == UE.EOBEasterState.Respawnable then
            local AWBMark = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
            local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
            if AWBMark and LocalPC then
                AWBMark:ShowPlayerTeamBuoys(LocalPC)
            end
        end
    end
end

function OBEasterMobile:OnClickDeathTipsBtn()
    local vm = self:GetSelfVM()
    if vm then
        if vm.CurOBEasterState == UE.EOBEasterState.SelfOver or vm.CurOBEasterState == UE.EOBEasterState.TeamOver then
            if SettlementProxy:GetCurrentResultMode() ~= Settlement.EResultMode.None then
                local UIManager = UE.UGUIManager.GetUIManager(self)
                if UIManager and not UIManager:IsAnyDynamicWidgetShowByKey("UMG_SettlementDetail") then
                    Settlement.bForceReviewStart = false
                    UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
                end
            end
        end
    end
end


return OBEasterMobile