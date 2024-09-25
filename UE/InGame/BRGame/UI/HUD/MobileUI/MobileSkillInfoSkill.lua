--
-- 战斗界面 - 大招信息
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.18

--@重构 许欣桐
--

local MobileUltiSkillInfo = Class("Common.Framework.UserWidget")
--初始化MVVM绑定变量
function MobileUltiSkillInfo:OnInit()
    print("MobileUltiSkillInfo:OnInit")
    self:InitInfo()

    self.fieid_IsLocalPawnUpdate = UE.FFieldNotificationId()
    self.fieid_IsLocalPawnUpdate.FieldName = "IsLocalPawnUpdate"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsLocalPawnUpdate, { self, self.OnIsLocalPawnUpdateChange })

    self.fieid_UltiSkillStatus = UE.FFieldNotificationId()
    self.fieid_UltiSkillStatus.FieldName = "UltiSkillStatus"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_UltiSkillStatus, { self, self.OnUltiSkillStatusChange })

    self.fieid_IsUseSkillCount = UE.FFieldNotificationId()
    self.fieid_IsUseSkillCount.FieldName = "IsUseSkillCount"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseSkillCount, { self, self.OnIsUseSkillCountChange })

    self.fieid_CurrentSkillCount = UE.FFieldNotificationId()
    self.fieid_CurrentSkillCount.FieldName = "CurrentSkillCount"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_CurrentSkillCount, { self, self.OnCurrentSkillCountChange })

    self.fieid_IsUseCD = UE.FFieldNotificationId()
    self.fieid_IsUseCD.FieldName = "IsUseCD"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseCD, { self, self.OnIsUseCDChange })

    self.fieid_CurrentCDTime = UE.FFieldNotificationId()
    self.fieid_CurrentCDTime.FieldName = "CurrentCDTime"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_CurrentCDTime, { self, self.OnCurrentCDTimeChange })

    self.fieid_IsUseEnergy = UE.FFieldNotificationId()
    self.fieid_IsUseEnergy.FieldName = "IsUseEnergy"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseEnergy, { self, self.OnIsUseEnergyChange })

    self.fieid_CurrentEnergy = UE.FFieldNotificationId()
    self.fieid_CurrentEnergy.FieldName = "CurrentEnergy"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_CurrentEnergy, { self, self.OnCurrentEnergyChange })
--[[
    self.fieid_EnergyPercent = UE.FFieldNotificationId()
    self.fieid_EnergyPercent.FieldName = "EnergyPercent"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_EnergyPercent, { self, self.OnEnergyPercentChange })
]]--

    self.fieid_IsUseSkillCD = UE.FFieldNotificationId()
    self.fieid_IsUseSkillCD.FieldName = "IsUseSkillCD"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseSkillCD, { self, self.OnIsUseSkillCDChange })

    self.fieid_SkillCDPercent = UE.FFieldNotificationId()
    self.fieid_SkillCDPercent.FieldName = "SkillCDPercent"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_SkillCDPercent, { self, self.OnSkillCDPercentChange })

    self.fieid_DisplayType = UE.FFieldNotificationId()
    self.fieid_DisplayType.FieldName = "DisplayType"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_DisplayType, { self, self.OnDisplayTypeChange })

    self.func_GetCDPercent = UE.FFieldNotificationId()
    self.func_GetCDPercent.FieldName = "GetCDPercent"
    self.UltiSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.func_GetCDPercent, { self, self.OnGetCDPercentChange })

    UserWidget.OnInit(self)
end

function MobileUltiSkillInfo:OnDestroy()
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsLocalPawnUpdate, { self, self.OnIsLocalPawnUpdateChange })
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_UltiSkillStatus, { self, self.OnUltiSkillStatusChange })

    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseSkillCount, { self, self.OnIsUseSkillCountChange })
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsLocalPawnUpdate, { self, self.OnCurrentSkillCountChange })
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseCD, { self, self.OnIsUseCDChange })
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_CurrentCDTime, { self, self.OnCurrentCDTimeChange })
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseEnergy, { self, self.OnIsUseEnergyChange })
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_CurrentEnergy, { self, self.OnCurrentEnergyChange })
    --self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_EnergyPercent, { self, self.OnEnergyPercentChange })
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseSkillCD, { self, self.OnIsUseSkillCDChange })
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_SkillCDPercent, { self, self.OnSkillCDPercentChange })
    self.UltiSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_DisplayType, { self, self.OnDisplayTypeChange })

    UserWidget.OnDestroy(self)
end


function MobileUltiSkillInfo:InitInfo()
    self.TxtNumSkill:SetText('')
    self.TxtCDSkill:SetText('')
    self.TxtTipsSkill:SetText('')
    self.TxtTipsSkill:SetVisibility(UE.ESlateVisibility.Collapsed)  
    self.ImgLockSkill:SetVisibility(UE.ESlateVisibility.Collapsed) 
    self.TrsConditionSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
    --初始化设置图标
    self:OnIsLocalPawnUpdateChange(self.UltiSkillInfoViewModel,0)
    self:OnUltiSkillStatusChange(self.UltiSkillInfoViewModel,0)
    self.LastSkillStatus =  UE.EGeSkillStatus.Cooling
    self.LastInCantUse= false
    self.DisplayType =  UE.EGeSkillEnergyDisplayType.Percentage
end



--------------------------------------MVVM Start------------------------------------------------------------
function MobileUltiSkillInfo:OnIsLocalPawnUpdateChange(vm, fieldID)
    if vm ==nil then
        print("MobileUltiSkillInfo:OnIsLocalPawnUpdateChange",vm)
        return
    end
    print(" MobileUltiSkillInfo:OnIsLocalPawnUpdateChange",vm.CurPawnSkillConfig.SkillIcon)
    if vm.CurPawnSkillConfig and vm.CurPawnSkillConfig.SkillIcon then
        self.ImgIconSkill:SetBrushFromSoftTexture(vm.CurPawnSkillConfig.SkillIcon, false)
        self.GUIImage_icon_full:SetBrushFromSoftTexture(vm.CurPawnSkillConfig.SkillIcon, false)
    end
end


function MobileUltiSkillInfo:OnUltiSkillStatusChange(vm, fieldID)
    print("MobileUltiSkillInfo:OnUltiSkillStatusChange. curStatus = ", vm.UltiSkillStatus)
    --获取技能前类型和状态
        --Normal代表可用，但未激活
        --Activating正在激活
        --Cooling代表冷却中
        --CantUse不可用（被禁用之类的）
        --Invalid不可用（和解锁有关）
        self.TrsConditionSkill:SetVisibility(UE.ESlateVisibility.Collapsed)   
        self.ImgIconSkill:SetBrushTintColor(self.NormalColor)
        self.ImgIconSkill:SetRenderOpacity(0.4)
        self.ImgActiveSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CDBox:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ImgProgressSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtNumSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ImgEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TrsEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.Collapsed)

        if vm.UltiSkillStatus == UE.EGeSkillStatus.Normal then
            self.ImgIconSkill:SetRenderOpacity(1)
            --self.TrsGuideSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        elseif  vm.UltiSkillStatus == UE.EGeSkillStatus.Activating then
            self.ImgIconSkill:SetBrushTintColor(self.ActiveColor)
            self.ImgIconSkill:SetRenderOpacity(self.CoolActiveOpacity)
            self.ImgActiveSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        elseif vm.UltiSkillStatus == UE.EGeSkillStatus.Cooling then
            
            self.ImgIconSkill:SetRenderOpacity(self.CoolStateOpacity)
            self.DisplayType = UE.EGeSkillEnergyDisplayType.Percentage
            self:ShowDisplayType(self.DisplayType,vm)
            --self.TrsGuideSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        elseif vm.UltiSkillStatus == UE.EGeSkillStatus.CantUse then

        elseif vm.UltiSkillStatus == UE.EGeSkillStatus.Invalid then
            self.TrsConditionSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.ImgLockSkill:SetBrushTintColor(self.NormalColor)
        end
        self.LastSkillStatus = vm.UltiSkillStatus
        
end

function MobileUltiSkillInfo:OnIsUseCDChange(vm, fieldID)
    print("MobileUltiSkillInfo:OnIsUseCDChange IsUseCD",vm.IsUseCD)
    self.CDBox:SetVisibility(vm.IsUseCD and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.ImgProgressSkill:SetVisibility(vm.IsUseCD and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function MobileUltiSkillInfo:OnCurrentCDTimeChange(vm, fieldID)
    print("MobileUltiSkillInfo:OnCurrentCDTimeChange CurrentCDTime",vm.CurrentCDTime)
    self.TxtCDSkill:SetText(string.format("%.f", math.max(0, vm.CurrentCDTime)) or "")
    local cool = vm.CurrentCDTime / vm.TotalCDTime
    self.ImgProgressSkill:GetDynamicMaterial():SetScalarParameterValue("Progress", cool)
end

function MobileUltiSkillInfo:OnIsUseSkillCountChange(vm, fieldID)
    print("MobileUltiSkillInfo:OnIsUseSkillCountChange IsUseSkillCount",vm.IsUseSkillCount)
    self.TxtNumSkill:SetVisibility(vm.IsUseSkillCount and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function MobileUltiSkillInfo:OnCurrentSkillCountChange(vm, fieldID)
    print("MobileUltiSkillInfo:OnCurrentSkillCountChange CurrentSkillCount",vm.CurrentSkillCount)
    self.TxtNumSkill:SetText(vm.CurrentSkillCount >= 0 and vm.CurrentSkillCount or " ")
end



function MobileUltiSkillInfo:OnIsUseEnergyChange(vm, fieldID)
    print("MobileUltiSkillInfo:OnIsUseEnergyChange IsUseEnergy",vm.IsUseEnergy)
    self.TrsEnergyProgressSkill:SetVisibility(vm.IsUseEnergy and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.ImgEnergyProgressSkill:SetVisibility(vm.IsUseEnergy and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function MobileUltiSkillInfo:OnCurrentEnergyChange(vm, fieldID)
    --print("MobileUltiSkillInfo:OnCurrentEnergyChange CurrentEnergy",vm.CurrentEnergy,"TotalEnergy",vm.TotalEnergy)
    local EnergyPercent = vm.CurrentEnergy/vm.TotalEnergy
    --print("MobileUltiSkillInfo:OnCurrentEnergyChange CurrentEnergy",vm.CurrentEnergy,"TotalEnergy",vm.TotalEnergy,"EnergyPercent",EnergyPercent)
    self.ImgEnergyProgressSkill:GetDynamicMaterial():SetScalarParameterValue("Progress", EnergyPercent)
    self.ImgEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.DisplayType ==  UE.EGeSkillEnergyDisplayType.Percentage then
        self.TxtEnergyProgressSkill:SetText(string.format("%.f", math.max(0,EnergyPercent*100)))
    elseif self.DisplayType ==  UE.EGeSkillEnergyDisplayType.Timer then
        self.TxtEnergyProgressSkill:SetText(string.format("%.f",vm.CurrentEnergy ))
    end
   
    self.TrsEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible )
    if EnergyPercent == 1 then
        self.ImgEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TrsEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.Collapsed )
    end

end



function MobileUltiSkillInfo:OnIsUseSkillCDChange(vm, fieldID)
    print("MobileUltiSkillInfo:OnIsUseSkillCDChange IsUseSkillCD",vm.IsUseSkillCD)
    self.ImgSkillCount:SetVisibility(vm.IsUseSkillCD and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function MobileUltiSkillInfo:OnSkillCDPercentChange(vm, fieldID)
    print("MobileUltiSkillInfo:OnSkillCDPercentChange IsUseSkillCD",vm.SkillCDPercent)
    self.ImgSkillCount:GetDynamicMaterial():SetScalarParameterValue("Progress", (1-vm.SkillCDPercent))
end

function MobileUltiSkillInfo:OnDisplayTypeChange(vm, fieldID)
print("UltiSkillInfo:OnDisplayTypeChange DisplayType",vm.DisplayType,"curstatus is ",vm.UltiSkillStatus)
    if vm.UltiSkillStatus == UE.EGeSkillStatus.Consuming then
        self:ShowDisplayType(vm.DisplayType,vm)
        self.DisplayType = vm.DisplayType
    end
   
end


function MobileUltiSkillInfo:ShowDisplayType(InDisplayType,vm)
    print("MobileUltiSkillInfo:ShowDisplayType DisplayType",InDisplayType)
    if InDisplayType ==  UE.EGeSkillEnergyDisplayType.Percentage then
        self.TrsEnergyProgressSkill:SetVisibility(vm.IsUseEnergy and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        self.TxtEnergySymbol:SetText("%")
        self.TxtEnergyProgressSymbol:SetText("%")
    elseif InDisplayType ==  UE.EGeSkillEnergyDisplayType.Timer then
        self.TrsEnergyProgressSkill:SetVisibility(vm.IsUseEnergy and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        self.TxtEnergySymbol:SetText("s")
        self.TxtEnergyProgressSymbol:SetText("s")
    elseif InDisplayType ==  UE.EGeSkillEnergyDisplayType.Disable then
        self.TxtEnergySymbol:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    print("MobileUltiSkillInfo:ShowDisplayType DisplayType",InDisplayType,self.TxtEnergySymbol:GetText())
end


return MobileUltiSkillInfo