--
-- 战斗界面 - 大招信息
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.18

--@重构 许欣桐
--

local UltiSkillInfo = Class("Common.Framework.UserWidget")
--初始化MVVM绑定变量
function UltiSkillInfo:OnInit()
    print("UltiSkillInfo:OnInit")
    if not self.UltiSkillInfoViewModel then return end
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

    self.LocalPS = UE.UPlayerStatics.GetCPS(UE.UGameplayStatics.GetPlayerController(self, 0))
    MsgHelper:UnregisterList(self, self.MsgList_PS or {})
    self.MsgList_PS = {{MsgName = GameDefine.MsgCpp.UISync_Update_FreshEnhanceId,  Func = self.OnFreshEnhanceId,  bCppMsg = true,  WatchedObject = self.LocalPS}}
    MsgHelper:RegisterList(self, self.MsgList_PS)
end

function UltiSkillInfo:OnDestroy()
    if not self.UltiSkillInfoViewModel then return end
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


function UltiSkillInfo:InitInfo()
    print("UltiSkillInfo:InitInfo")
    self.TxtNumSkill:SetText('')
    self.TxtCDSkill:SetText('')
    self.TxtTipsSkill:SetText('')
    self.TxtTipsSkill:SetVisibility(UE.ESlateVisibility.Collapsed)  
    self.ImgLockSkill:SetVisibility(UE.ESlateVisibility.Collapsed) 
    self.TrsConditionSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
    --初始化设置图标
    self.LastSkillStatus =  UE.EGeSkillStatus.Cooling
    self.LastInCantUse = false
    self.DisplayType =  UE.EGeSkillEnergyDisplayType.Percentage

    self:OnIsLocalPawnUpdateChange(self.UltiSkillInfoViewModel,0)
    self:OnUltiSkillStatusChange(self.UltiSkillInfoViewModel,0)
    self:OnCurrentEnergyChange(self.UltiSkillInfoViewModel,0)
end



--------------------------------------MVVM Start------------------------------------------------------------
function UltiSkillInfo:OnIsLocalPawnUpdateChange(vm, fieldID)
    if vm.CurPawnSkillConfig and vm.CurPawnSkillConfig.SkillIcon then
         print("UltiSkillInfo >> OnIsLocalPawnUpdateChange > CurPawnSkillConfig.SkillIcon=",vm.CurPawnSkillConfig.SkillIcon)
        -- self.ImgIconSkill:SetBrushFromSoftTexture(vm.CurPawnSkillConfig.SkillIcon, false)
        local SkillTexSoftPtr = vm.CurPawnSkillConfig.SkillIcon
        -- local Skill_Texture = SkillTexSoftPtr:Get() 
        -- local Skill_Texture = SkillTexSoftPtr:LoadSynchronous()--使用Get函数读取为nil 尝试使用同时方式获取资产实例
        self:VX_HUD_Skill_SetTex(SkillTexSoftPtr)
    end
end


function UltiSkillInfo:OnUltiSkillStatusChange(vm, fieldID)
    print("UltiSkillInfo:OnUltiSkillStatusChange. curStatus = ", vm.UltiSkillStatus, self.LastSkillStatus,
    " vm.IsUseCD", vm.IsUseCD,
    "vm.IsUseSkillCD",vm.IsUseSkillCD,
    "LastInCantUse", self.LastInCantUse)
    --获取技能前类型和状态
        --Normal代表可用，但未激活
        --Activating正在激活
        --Cooling代表冷却中
        --CantUse不可用（被禁用之类的）
        --Invalid不可用（和解锁有关）
        self.TrsConditionSkill:SetVisibility(UE.ESlateVisibility.Collapsed)   
        self.ImgIconSkill:SetBrushTintColor(self.NormalColor)
        self.ImgIconSkill:SetRenderOpacity(self.CoolStateOpacity)
        self.TxtTipsSkill:SetVisibility(UE.ESlateVisibility.Collapsed)  
        self.ImgLockSkill:SetVisibility(UE.ESlateVisibility.Collapsed) 
        -- self.ImgActiveSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtCDSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtNumSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TrsGuideSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TrsEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TrsGuideSkill:SetVisibility(((vm.IsUseSkillCD and vm.CurrentSkillCount==0)  or vm.IsUseCD)  and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
       
        if vm.UltiSkillStatus == UE.EGeSkillStatus.Normal then
            --可用状态，也就是这时候可以释放大招了
            if self.LastInCantUse == false then
                self:BP_EventCoolingFinish()
            end
            self:EventNormal()
            self.ImgIconSkill:SetRenderOpacity(1)
            self.TrsGuideSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.LastInCantUse = false
        elseif  vm.UltiSkillStatus == UE.EGeSkillStatus.Activating then
            --激活中，也就是按了X键之后
            print("UltiSkillInfo:OnUltiSkillStatusChange Activating bIsUseEnergyProgressBar",vm.bIsUseEnergyProgressBar)
            self.isUseProgress = vm.bIsUseEnergyProgressBar
            self:EventActivating()
            self.ImgIconSkill:SetBrushTintColor(self.ActiveColor)
            self.ImgIconSkill:SetRenderOpacity(self.CoolActiveOpacity)
            self.LastInCantUse = false
        elseif  vm.UltiSkillStatus == UE.EGeSkillStatus.Consuming then
            --这里属于进激活能量条后的倒计时状态，一定会显示进度条  这里已经和策划约定好
            print("UltiSkillInfo:OnUltiSkillStatusChange Consuming bIsUseEnergyProgressBar",vm.bIsUseEnergyProgressBar, self.DisplayType)
            if self.LastSkillStatus == UE.EGeSkillStatus.Cooling then
               -- 断线重连回来 需要执行动效的增量内容
                self:EventNormal()
                self:EventActivating()
                self.ImgIconSkill:SetBrushTintColor(self.ActiveColor)
                self.ImgIconSkill:SetRenderOpacity(self.CoolActiveOpacity)
                print("UltiSkillInfo:OnCurrentEnergyChange Consuming CurrentEnergy",vm.CurrentEnergy,"TotalEnergy",vm.TotalEnergy)
            end
            self.isUseProgress = true
            self.DisplayType = vm.DisplayType
            self:ShowDisplayType(self.DisplayType, self.UltiSkillInfoViewModel)
            self:EventConsuming()
            self.LastInCantUse = false
        elseif vm.UltiSkillStatus == UE.EGeSkillStatus.Cooling then
            --冷却状态，大招的表现就是充能中
            self.isUseProgress = vm.IsUseEnergy
            self:EventCooling()
            self.ImgIconSkill:SetRenderOpacity(self.CoolStateOpacity)
            self.DisplayType = UE.EGeSkillEnergyDisplayType.Percentage
            self:ShowDisplayType(self.DisplayType,vm)
            self.LastInCantUse = false
        elseif vm.UltiSkillStatus == UE.EGeSkillStatus.CantUse then
            self:EventCantUse()
            self.LastInCantUse = true
            if self.LastSkillStatus == UE.EGeSkillStatus.Activating then
                self:BP_EventCoolingFinish()
                self.ImgIconSkill:SetRenderOpacity(1)
                self.TrsGuideSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end
        elseif vm.UltiSkillStatus == UE.EGeSkillStatus.Invalid then
            self:EventInvalid()
            self.LastInCantUse= false
        end
        self.LastSkillStatus = vm.UltiSkillStatus
        
end

function UltiSkillInfo:OnIsUseCDChange(vm, fieldID)
    if not vm then return end
    -- print("UltiSkillInfo:OnIsUseCDChange IsUseCD",vm.IsUseCD)
    self.TxtCDSkill:SetVisibility(vm.IsUseCD and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function UltiSkillInfo:OnCurrentCDTimeChange(vm, fieldID)
    if not vm then return end
    -- print("UltiSkillInfo:OnCurrentCDTimeChange CurrentCDTime",vm.CurrentCDTime)
    self.TxtCDSkill:SetText(string.format("%.f", math.max(0, vm.CurrentCDTime)) or "")
    local cool = vm.CurrentCDTime / vm.TotalCDTime
    self.VX_ArrowLight:SetRenderTransformAngle(cool*360)
end

function UltiSkillInfo:OnIsUseSkillCountChange(vm, fieldID)
    if not vm then return end
    -- print("UltiSkillInfo:OnIsUseSkillCountChange IsUseSkillCount",vm.IsUseSkillCount)
    self.TxtNumSkill:SetVisibility(vm.IsUseSkillCount and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function UltiSkillInfo:OnCurrentSkillCountChange(vm, fieldID)
    if not vm then return end
    -- print("UltiSkillInfo:OnCurrentSkillCountChange CurrentSkillCount",vm.CurrentSkillCount)
    self.TxtNumSkill:SetText(vm.CurrentSkillCount >= 0 and vm.CurrentSkillCount or " ")
end



function UltiSkillInfo:OnIsUseEnergyChange(vm, fieldID)
    if not vm then return end
    print("UltiSkillInfo:OnIsUseEnergyChange IsUseEnergy",vm.IsUseEnergy)
    self.TrsEnergyProgressSkill:SetVisibility(vm.IsUseEnergy and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function UltiSkillInfo:OnCurrentEnergyChange(vm, fieldID)
    if not vm then return end
    -- print("UltiSkillInfo:OnCurrentEnergyChange CurrentEnergy",vm.CurrentEnergy,"TotalEnergy",vm.TotalEnergy,"DisplayType",self.DisplayType)
    if vm.CurrentEnergy == -1 or vm.TotalEnergy == 0 then
        -- 海员消耗状态下 当前能量值为-1
        self.Img_Skill_Energy_Ring:GetDynamicMaterial():SetScalarParameterValue("Progress", 0)
        self.TxtEnergySymbol:SetText("")
        self.TxtEnergyProgressSkill:SetText("")
        return
    end

    local EnergyPercent = vm.CurrentEnergy/vm.TotalEnergy
    self.Img_Skill_Energy_Ring:GetDynamicMaterial():SetScalarParameterValue("Progress", EnergyPercent)
    self.VX_ArrowLight:SetRenderTransformAngle(EnergyPercent*360)
    if self.DisplayType ==  UE.EGeSkillEnergyDisplayType.Percentage then
        self.TxtEnergyProgressSkill:SetText(string.format("%.f", math.max(0,EnergyPercent*100)))
    elseif self.DisplayType ==  UE.EGeSkillEnergyDisplayType.Timer then
        self.TxtEnergyProgressSkill:SetText(string.format("%.f",vm.CurrentEnergy ))
    end
    self.TrsEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible )
    if EnergyPercent == 1 and self.LastInCantUse == true then
        self:BP_EventCoolingFinish()
    end
    --未激活且充能结束后弹出提示
    local bCanShowTips = (vm.UltiSkillStatus ~= UE.EGeSkillStatus.Activating) and
    (vm.UltiSkillStatus ~= UE.EGeSkillStatus.Consuming) and
    (vm.UltiSkillStatus ~= UE.EGeSkillStatus.CantUse)
    if EnergyPercent == 1 and bCanShowTips then
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        TipsManager:ShowTipsUIByTipsId("Skill.ReadyTips")
    end
end



function UltiSkillInfo:OnIsUseSkillCDChange(vm, fieldID)
    
    -- print("UltiSkillInfo:OnIsUseSkillCDChange IsUseSkillCD",vm.IsUseSkillCD)
end

function UltiSkillInfo:OnSkillCDPercentChange(vm, fieldID)
    -- print("UltiSkillInfo:OnSkillCDPercentChange IsUseSkillCD",vm.SkillCDPercent)
end

function UltiSkillInfo:OnDisplayTypeChange(vm, fieldID)
    if not vm then return end
    print("UltiSkillInfo:OnDisplayTypeChange DisplayType",vm.DisplayType,"curstatus is ",vm.UltiSkillStatus)
    if vm.UltiSkillStatus == UE.EGeSkillStatus.Consuming then
        self:ShowDisplayType(vm.DisplayType,vm)
        self.DisplayType = vm.DisplayType
        -- 断线重连回来 数值可能不发生变化需要强制刷新一次
        self:OnCurrentEnergyChange(self.UltiSkillInfoViewModel,0)
    end
end


function UltiSkillInfo:ShowDisplayType(InDisplayType,vm)
    if not vm then return end
    print("UltiSkillInfo:ShowDisplayType DisplayType",InDisplayType)
    if InDisplayType ==  UE.EGeSkillEnergyDisplayType.Percentage then
        self.TrsEnergyProgressSkill:SetVisibility(vm.IsUseEnergy and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        self.TxtEnergySymbol:SetText("%")
    elseif InDisplayType ==  UE.EGeSkillEnergyDisplayType.Timer then
        self.TrsEnergyProgressSkill:SetVisibility(vm.IsUseEnergy and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        self.TxtEnergySymbol:SetText("s")
    elseif InDisplayType ==  UE.EGeSkillEnergyDisplayType.Disable then
        self.TxtEnergySymbol:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtEnergyProgressSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function UltiSkillInfo:OnFreshEnhanceId()
    print("UltiSkillInfo:OnFreshEnhanceId")
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPS)
    --极速冷却芯片对应表RowName
    local CDReduceRowName = 1002
    if HudDataCenter == nil then return end
    if not HudDataCenter.SpecEnhanceIdArray:Contains(CDReduceRowName) then
        self.EnhanceTips:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtCDSkill:SetColorAndOpacity(self.NormalColor)
        self.TxtEnergyProgressSkill:SetColorAndOpacity(self.NormalColor)
        self.TxtEnergySymbol:SetColorAndOpacity(self.NormalColor)
    else
        self.EnhanceTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TxtCDSkill:SetColorAndOpacity(self.CDReduceColor)
        self.TxtEnergyProgressSkill:SetColorAndOpacity(self.CDReduceColor)
        self.TxtEnergySymbol:SetColorAndOpacity(self.CDReduceColor)
    end
end

return UltiSkillInfo