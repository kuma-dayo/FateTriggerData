--
-- 战斗界面 - 人物技能UI-移动端
--
-- @重构    胡帅
-- @日期    2023.06.20

local MobileSkillInfoNormal = Class("Common.Framework.UserWidget")


function MobileSkillInfoNormal:OnInit()
    print("MobileSkillInfoNormal:OnInit")

    self:InitView()

    self.fieid_IsLocalPawnUpdate = UE.FFieldNotificationId()
    self.fieid_IsUseSkillCount = UE.FFieldNotificationId()
    self.fieid_CurrentSkillCount = UE.FFieldNotificationId()
    self.fieid_NormalSkillStatus = UE.FFieldNotificationId()
    self.fieid_IsUseCD = UE.FFieldNotificationId()
    self.fieid_CurrentCDTime = UE.FFieldNotificationId()
    self.fieid_IsUseSkillCD = UE.FFieldNotificationId()
    self.fieid_SkillCDPercent = UE.FFieldNotificationId()
    self.func_GetCDPercent= UE.FFieldNotificationId()
    self.func_GetCDPercent.FieldName = "GetCDPercent"
    self.fieid_IsLocalPawnUpdate.FieldName = "IsLocalPawnUpdate"
    self.fieid_IsUseSkillCount.FieldName = "IsUseSkillCount"
    self.fieid_CurrentSkillCount.FieldName = "CurrentSkillCount"
    self.fieid_NormalSkillStatus.FieldName = "NormalSkillStatus"
    self.fieid_IsUseCD.FieldName = "IsUseCD"
    self.fieid_CurrentCDTime.FieldName = "CurrentCDTime"
    self.fieid_IsUseSkillCD.FieldName = "IsUseSkillCD"
    self.fieid_SkillCDPercent.FieldName = "SkillCDPercent"

    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsLocalPawnUpdate, { self, self.OnIsLocalPawnUpdateChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseSkillCount, { self, self.OnIsUseSkillCountChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_CurrentSkillCount, { self, self.OnCurrentSkillCountChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_NormalSkillStatus, { self, self.OnNormalSkillStatusChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseCD, { self, self.OnIsUseCDChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_CurrentCDTime, { self, self.OnCurrentCDTimeChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseSkillCD, { self, self.OnIsUseSkillCDChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_SkillCDPercent, { self, self.OnSkillCDPercentChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.func_GetCDPercent, { self, self.OnGetCDPercentChange })
    UserWidget.OnInit(self)
end

function MobileSkillInfoNormal:OnDestroy()
    print("MobileSkillInfoNormal:OnDestroy")

    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsLocalPawnUpdate, { self, self.OnIsLocalPawnUpdateChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseSkillCount, { self, self.OnIsUseSkillCountChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_CurrentSkillCount, { self, self.OnCurrentSkillCountChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_NormalSkillStatus, { self, self.OnNormalSkillStatusChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseCD, { self, self.OnIsUseCDChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_CurrentCDTime, { self, self.OnCurrentCDTimeChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseSkillCD, { self, self.OnIsUseSkillCDChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_SkillCDPercent, { self, self.OnSkillCDPercentChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.func_GetCDPercent, { self, self.OnGetCDPercentChange })
    UserWidget.OnDestroy(self)
end

function MobileSkillInfoNormal:InitView()
    self.TxtNumSkillNormal:SetText('')
    self.TxtCDSkillNormal:SetText('')
    self.TrsLockSkillNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TrsConditionSkillNormal:SetVisibility(UE.ESlateVisibility.Collapsed)

    self.ImgSkillCountNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
    --初始化设置图标
    self:OnIsLocalPawnUpdateChange(self.NormalSkillInfoViewModel,0)
    self:OnCurrentSkillCountChange(self.NormalSkillInfoViewModel,0)
    self:OnIsUseSkillCountChange(self.NormalSkillInfoViewModel,0)
end

----------------------------------------------- MVVM Start -----------------------------------------------

function MobileSkillInfoNormal:OnIsLocalPawnUpdateChange(vm, fieldID)
    if vm ==nil then
        print("MobileSkillInfoNormal:OnIsLocalPawnUpdateChange",vm)
        return
    end
    if vm.CurPawnSkillConfig and vm.CurPawnSkillConfig.SkillIcon then
        print(" MobileSkillInfoNormal:OnIsLocalPawnUpdateChange",vm.CurPawnSkillConfig.SkillIcon)
        self.ImgIconSkillNormal:SetBrushFromSoftTexture(vm.CurPawnSkillConfig.SkillIcon, false)
        self.GUIImage_icon_fullNormal:SetBrushFromSoftTexture(vm.CurPawnSkillConfig.SkillIcon, false)
    end
end

function MobileSkillInfoNormal:OnIsUseSkillCountChange(vm, fieldID)
    print("MobileSkillInfoNormal:OnIsUseSkillCountChange",vm.IsUseSkillCount)
    self.TxtNumSkillNormal:SetVisibility(vm.IsUseSkillCount and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function MobileSkillInfoNormal:OnCurrentSkillCountChange(vm, fieldID)
    print("MobileSkillInfoNormal:OnCurrentSkillCountChange",vm.CurrentSkillCount,vm.IsUseSkillCD)

    self.TxtNumSkillNormal:SetText(vm.CurrentSkillCount >= 0 and vm.CurrentSkillCount or " ")
    self.TxtCDSkillNormal:SetText("")
    self.TxtCDSkillNormal:SetVisibility(((vm.IsUseSkillCD and vm.CurrentSkillCount==0) or vm.IsUseCD) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    
end

function MobileSkillInfoNormal:OnNormalSkillStatusChange(vm, fieldID)
    print("NormalSkillInfo:OnNormalSkillStatusChange. curStatus = ", vm.NormalSkillStatus)

    --self.TxtCDSkillNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ImgActiveSkillNormal:SetVisibility(UE.ESlateVisibility.Collapsed)

    if vm.NormalSkillStatus == UE.EGeSkillStatus.Activating then
        self.ImgActiveSkillNormal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    local bIsGrey = (vm.NormalSkillStatus == UE.EGeSkillStatus.Cooling or
                     vm.NormalSkillStatus == UE.EGeSkillStatus.CantUse or
                     vm.NormalSkillStatus == UE.EGeSkillStatus.Invalid)
    UIHelper.SetToGrey(self.ImgIconSkillNormal, bIsGrey, self.DisableColor)
    UIHelper.SetToGrey(self.TxtNumSkillNormal, bIsGrey, self.DisableColor, true)
end

function MobileSkillInfoNormal:OnIsUseCDChange(vm, fieldID)
    print("MobileSkillInfoNormal:OnIsUseCDChange",vm.IsUseCD)
    self.TxtCDSkillNormal:SetText("")
    self.TxtCDSkillNormal:SetVisibility(vm.IsUseCD and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-- function MobileSkillInfoNormal:OnCurrentCDTimeChange(vm, fieldID)

--     self.TxtCDSkillNormal:SetText(vm.IsUseCD and string.format("%.f", math.max(0, vm.CurrentCDTime)) .. "s" or "")
-- end

function MobileSkillInfoNormal:OnGetCDPercentChange(vm, fieldID)
   --print("MobileSkillInfoNormal:OnGetCDPercentChange",vm.TotalCDTime)
    self:SetCDTime(vm)
end



function MobileSkillInfoNormal:SetCDTime(vm)
    if (vm.TotalCDTime-vm.CurrentCDTime) > (vm.TotalSkillCDTime - vm.CurrentSkillCDTime) then
         print(" MobileSkillInfoNormal:OnCurrentCDTimeChange0",vm.IsUseCD,vm.IsUseSkillCD,vm.CurrentCDTime,vm.CurrentSkillCDTime)
        self.TxtCDSkillNormal:SetText((vm.IsUseCD  )and string.format("%.1f", math.max(0, vm.CurrentCDTime)) .. "s" or "")
    else
         print(" MobileSkillInfoNormal:OnCurrentCDTimeChange1",vm.IsUseCD,vm.IsUseSkillCD,vm.CurrentCDTime,vm.CurrentSkillCDTime)
        self.TxtCDSkillNormal:SetText((vm.IsUseSkillCD and vm.CurrentSkillCount==0 )and string.format("%.1f", math.max(0, vm.CurrentSkillCDTime)) .. "s" or "")
    end
end


function MobileSkillInfoNormal:OnIsUseSkillCDChange(vm, fieldID)
    self.ImgSkillCountNormal:SetVisibility(vm.IsUseSkillCD and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function MobileSkillInfoNormal:OnSkillCDPercentChange(vm, fieldID)
    self.ImgSkillCountNormal:GetDynamicMaterial():SetScalarParameterValue("Progress", (1 - vm.SkillCDPercent))
end

----------------------------------------------- MVVM End -----------------------------------------------


return MobileSkillInfoNormal
