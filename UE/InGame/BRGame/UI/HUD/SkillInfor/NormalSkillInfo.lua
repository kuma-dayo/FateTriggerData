--
-- 战斗界面 - 人物技能UI
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.18
--
-- @重构    胡帅
-- @日期    2023.06.16

--@魔改     许欣桐

local NormalSkillInfo = Class("Common.Framework.UserWidget")


function NormalSkillInfo:OnInit()
    
    if not self.NormalSkillInfoViewModel then return end
    print("NormalSkillInfo:OnInit")

    self:InitView()

    self.fieid_IsLocalPawnUpdate = UE.FFieldNotificationId()
    self.fieid_IsUseSkillCount = UE.FFieldNotificationId()
    self.fieid_CurrentSkillCount = UE.FFieldNotificationId()
    self.fieid_NormalSkillStatus = UE.FFieldNotificationId()
    self.fieid_IsUseCD = UE.FFieldNotificationId()
    self.fieid_CurrentCDTime = UE.FFieldNotificationId()
    
    self.func_GetCDPercent = UE.FFieldNotificationId()
    self.fieid_IsUseEnergy = UE.FFieldNotificationId()
    self.fieid_EnergyPercent = UE.FFieldNotificationId()
    self.fieid_IsUseSkillCD = UE.FFieldNotificationId()
    self.fieid_SkillCDPercent = UE.FFieldNotificationId()
    self.fieid_IncreasedSkillCDTime = UE.FFieldNotificationId()

    self.fieid_IsUseCharge = UE.FFieldNotificationId()
    self.fieid_SkillChargePercent = UE.FFieldNotificationId()

    self.fieid_IsLocalPawnUpdate.FieldName = "IsLocalPawnUpdate"
    self.fieid_IsUseSkillCount.FieldName = "IsUseSkillCount"
    self.fieid_CurrentSkillCount.FieldName = "CurrentSkillCount"
    self.fieid_NormalSkillStatus.FieldName = "NormalSkillStatus"
    self.fieid_IsUseCD.FieldName = "IsUseCD"
    self.fieid_CurrentCDTime.FieldName = "CurrentCDTime"
    self.func_GetCDPercent.FieldName = "GetCDPercent"
    self.fieid_IsUseEnergy.FieldName = "IsUseEnergy"
    self.fieid_EnergyPercent.FieldName = "EnergyPercent"
    self.fieid_IsUseSkillCD.FieldName = "IsUseSkillCD"
    self.fieid_SkillCDPercent.FieldName = "SkillCDPercent"
    self.fieid_IncreasedSkillCDTime.FieldName = "IncreasedSkillCDTime"
    self.IncreaseCDPercent = 0

    self.fieid_IsUseCharge.FieldName = "IsUseCharge"
    self.fieid_SkillChargePercent.FieldName = "SkillChargePercent"


    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsLocalPawnUpdate, { self, self.OnIsLocalPawnUpdateChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseSkillCount, { self, self.OnIsUseSkillCountChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_CurrentSkillCount, { self, self.OnCurrentSkillCountChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_NormalSkillStatus, { self, self.OnNormalSkillStatusChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseCD, { self, self.OnIsUseCDChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_CurrentCDTime, { self, self.OnCurrentCDTimeChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.func_GetCDPercent, { self, self.OnGetCDPercentChange })
    
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseEnergy, { self, self.OnIsUseEnergyChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_EnergyPercent, { self, self.OnEnergyPercentChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseSkillCD, { self, self.OnIsUseSkillCDChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_SkillCDPercent, { self, self.OnSkillCDPercentChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IncreasedSkillCDTime, { self, self.OnIncreasedSkillCDTimeChange })

    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsUseCharge, { self, self.OnIsUseChargeChange })
    self.NormalSkillInfoViewModel:K2_AddFieldValueChangedDelegate(self.fieid_SkillChargePercent, { self, self.OnSkillChargePercentChange })


    UserWidget.OnInit(self)

    self.LocalPS = UE.UPlayerStatics.GetCPS(UE.UGameplayStatics.GetPlayerController(self, 0))
    MsgHelper:UnregisterList(self, self.MsgList_PS or {})
    self.MsgList_PS = {{MsgName = GameDefine.MsgCpp.UISync_Update_FreshEnhanceId,  Func = self.OnFreshEnhanceId,  bCppMsg = true,  WatchedObject = self.LocalPS}}
    MsgHelper:RegisterList(self, self.MsgList_PS)
end

function NormalSkillInfo:OnDestroy()
    print("NormalSkillInfo:OnDestroy")
    if not self.NormalSkillInfoViewModel then return end
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsLocalPawnUpdate, { self, self.OnIsLocalPawnUpdateChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseSkillCount, { self, self.OnIsUseSkillCountChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_CurrentSkillCount, { self, self.OnCurrentSkillCountChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_NormalSkillStatus, { self, self.OnNormalSkillStatusChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseCD, { self, self.OnIsUseCDChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_CurrentCDTime, { self, self.OnCurrentCDTimeChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.func_GetCDPercent, { self, self.OnGetCDPercentChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseEnergy, { self, self.OnIsUseEnergyChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_EnergyPercent, { self, self.OnEnergyPercentChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseSkillCD, { self, self.OnIsUseSkillCDChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_SkillCDPercent, { self, self.OnSkillCDPercentChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IncreasedSkillCDTime, { self, self.OnIncreasedSkillCDTimeChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_IsUseCharge, { self, self.OnIsUseChargeChange })
    self.NormalSkillInfoViewModel:K2_RemoveFieldValueChangedDelegate(self.fieid_SkillChargePercent, { self, self.OnSkillChargePercentChange })

    UserWidget.OnDestroy(self)
end

function NormalSkillInfo:InitView()
    self.TxtNumSkillNormal:SetText('')
    self.TxtCDSkillNormal:SetText('')
    self.ImgIconNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TxtTipsSkillNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TxtEnergyProgressNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Skill_Count_CD_Ring:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Skill_Count_Bg:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Skill_Charge_Ring:SetVisibility(UE.ESlateVisibility.Collapsed)

    self:OnIsLocalPawnUpdateChange(self.NormalSkillInfoViewModel,0)
    self:OnNormalSkillStatusChange(self.NormalSkillInfoViewModel,0)
    self:OnIsUseSkillCountChange(self.NormalSkillInfoViewModel,0)
    self:OnCurrentSkillCountChange(self.NormalSkillInfoViewModel,0)
    self:OnSkillChargePercentChange(self.NormalSkillInfoViewModel,0)
    self:OnIsUseCDChange(self.NormalSkillInfoViewModel, 0)
    self:OnIsUseSkillCDChange(self.NormalSkillInfoViewModel, 0)
end

----------------------------------------------- MVVM Start -----------------------------------------------

--    ____ ___  __  __ __  __  ___  _   _ 
--   / ___/ _ \|  \/  |  \/  |/ _ \| \ | |
--  | |  | | | | |\/| | |\/| | | | |  \| |
--  | |__| |_| | |  | | |  | | |_| | |\  |
--   \____\___/|_|  |_|_|  |_|\___/|_| \_|
                                       

function NormalSkillInfo:OnIsLocalPawnUpdateChange(vm, fieldID)
    if not vm then return end

    if vm.CurPawnSkillConfig and vm.CurPawnSkillConfig.SkillIcon then
        -- self.ImgIconSkillNormal:SetBrushFromSoftTexture(vm.CurPawnSkillConfig.SkillIcon, false)

        local SkillTexSoftPtr = vm.CurPawnSkillConfig.SkillIcon
        self:VX_HUD_Skill_SetTex(SkillTexSoftPtr)
    end
end

function NormalSkillInfo:OnNormalSkillStatusChange(vm, fieldID)
    if not vm then return end
    -- print("NormalSkillInfo:OnNormalSkillStatusChange. curStatus = ", vm.NormalSkillStatus)

    --获取技能前类型和状态
    --Normal代表可用，但未激活
    --Activating正在激活
    --Cooling代表冷却中
    --CantUse不可用（被禁用之类的）
    --Invalid不可用（和解锁有关）

    print("NormalSkillInfo@OnNormalSkillStatusChange >> vm.CurrentSkillCount > SkillState =",vm.NormalSkillStatus)
    -- 默认初始化
    self.VXV_isLastRelease = vm.CurrentSkillCount < 1
    self.SkillCount = vm.CurrentSkillCount

    print("NormalSkillInfo@OnNormalSkillStatusChange >> vm.CurrentSkillCount > vm.CurrentSkillCount =",vm.CurrentSkillCount)

    self.ImgIconNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TxtTipsSkillNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Skill_CD_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
    if vm.NormalSkillStatus == UE.EGeSkillStatus.Normal then
        self:EventNormal()
    elseif vm.NormalSkillStatus == UE.EGeSkillStatus.Activating then
        self:EventActivating()
    elseif vm.NormalSkillStatus == UE.EGeSkillStatus.Cooling then
        self:EventCooling()
    elseif vm.NormalSkillStatus == UE.EGeSkillStatus.CantUse then
        self:EventCantUse()
    elseif vm.NormalSkillStatus == UE.EGeSkillStatus.Invalid then
        self.ImgIconNormal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.ImgIconNormal:SetBrushTintColor(self.NormalColor)
        self.TxtTipsSkillNormal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:EventInvalid()
    end   
end

function NormalSkillInfo:OnIncreasedSkillCDTimeChange(vm, fieldID)
    if not vm then return end
    --计算得到技能加速冷却后的时间，然后算出冷却前后时间的差值
    if vm.IsUseCD and not vm.IsUseSkillCD then
        local IncreasedTime = vm.TotalCDTime - vm.IncreasedSkillCDTime
        local DiffCDTime = vm.CurrentCDTime - IncreasedTime
        self.IncreaseCDPercent = (DiffCDTime) / vm.TotalCDTime
        self.Img_Skill_CD_Mask:GetDynamicMaterial():SetScalarParameterValue("Progress", vm:GetCDPercent() + self.IncreaseCDPercent)
    elseif (vm.IsUseSkillCD and not vm.IsUseCD) or (vm.IsUseSkillCD and vm.IsUseCD and vm.TotalSkillCDTime ~= 0) then
        local IncreasedTime = vm.TotalSkillCDTime - vm.IncreasedSkillCDTime
        local DiffCDTime = vm.CurrentSkillCDTime - IncreasedTime
        self.IncreaseCDPercent = (DiffCDTime) / vm.TotalSkillCDTime
        self.Img_Skill_Count_CD_Ring:GetDynamicMaterial():SetScalarParameterValue("Progress", 1- vm.SkillCDPercent - self.IncreaseCDPercent)
    end
end

--   ____  _  _____ _     _        ____ ____  
--  / ___|| |/ /_ _| |   | |      / ___|  _ \ 
--  \___ \| ' / | || |   | |     | |   | | | |
--   ___) | . \ | || |___| |___  | |___| |_| |
--  |____/|_|\_\___|_____|_____|  \____|____/ 
                                           
function NormalSkillInfo:OnIsUseCDChange(vm, fieldID)
    if not vm then return end
    -- print("NormalSkillInfo debug",vm.IsUseCD)
    print("NormalSkillInfo@check visible OnIsUseCDChange isUseSkillCount", vm.IsUseSkillCount,"IsUseCD", vm.IsUseCD)
    self.TxtCDSkillNormal:SetVisibility(((vm.IsUseSkillCD and vm.CurrentSkillCount == 0) or vm.IsUseCD) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.Img_Skill_CD_Mask:SetVisibility((not vm.IsUseSkillCount and vm.IsUseCD) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function NormalSkillInfo:OnCurrentCDTimeChange(vm, fieldID)
    if not vm then return end
    --self.TxtCDSkillNormal:SetVisibility(vm.IsUseCD and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function NormalSkillInfo:OnGetCDPercentChange(vm, fieldID)
    if not vm then return end
    print("NormalSkillInfo@OnGetCDPercentChange",vm:GetCDPercent())
    local CDPercent = 0
    if vm.IsUseCD and not vm.IsUseSkillCD then CDPercent = self.IncreaseCDPercent end
    self.Img_Skill_CD_Mask:GetDynamicMaterial():SetScalarParameterValue("Progress", vm:GetCDPercent() + CDPercent)
    self:SetCDTime(vm)
end

function NormalSkillInfo:SetCDTime(vm)
    if not vm then return end
    if (vm.TotalCDTime-vm.CurrentCDTime+0.0001) > (vm.TotalSkillCDTime - vm.CurrentSkillCDTime) then
        --  print(" NormalSkillInfo:OnCurrentCDTimeChange0",vm.IsUseCD,vm.IsUseSkillCD,vm.CurrentCDTime,vm.CurrentSkillCDTime)
        self.TxtCDSkillNormal:SetText((vm.IsUseCD) and string.format("%.1f", math.max(0, vm.CurrentCDTime)) .. "s" or "")
    else
        --  print(" NormalSkillInfo:OnCurrentCDTimeChange1",vm.IsUseCD,vm.IsUseSkillCD,vm.CurrentCDTime,vm.CurrentSkillCDTime)
        self.TxtCDSkillNormal:SetText((vm.IsUseSkillCD and vm.CurrentSkillCount == 0 )and string.format("%.1f", math.max(0, vm.CurrentSkillCDTime)) .. "s" or "")
    end
end

--   ____  _  _____ _     _        ____ ___  _   _ _   _ _____    ____ ____  
--  / ___|| |/ /_ _| |   | |      / ___/ _ \| | | | \ | |_   _|  / ___|  _ \ 
--  \___ \| ' / | || |   | |     | |  | | | | | | |  \| | | |   | |   | | | |
--   ___) | . \ | || |___| |___  | |__| |_| | |_| | |\  | | |   | |___| |_| |
--  |____/|_|\_\___|_____|_____|  \____\___/ \___/|_| \_| |_|    \____|____/ 
                                                                          

function NormalSkillInfo:OnIsUseSkillCountChange(vm, fieldID)
    if not vm then return end
    print("NormalSkillInfo@OnIsUseSkillCountChange",vm.IsUseSkillCount)
    self.TxtNumSkillNormal:SetVisibility(vm.IsUseSkillCount and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function NormalSkillInfo:OnCurrentSkillCountChange(vm, fieldID)
    if not vm then return end
    self.IncreaseCDPercent = 0
    self.TxtCDSkillNormal:SetColorAndOpacity(self.NormalColor)
    self.Img_Skill_Count_CD_Ring:GetDynamicMaterial():SetScalarParameterValue("Progress", 1 - vm.SkillCDPercent - self.IncreaseCDPercent)
    self.TxtNumSkillNormal:SetText(vm.CurrentSkillCount >= 0 and vm.CurrentSkillCount or " ")
    self.TxtCDSkillNormal:SetVisibility(((vm.IsUseSkillCD and vm.CurrentSkillCount==0) or vm.IsUseCD) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    print("NormalSkillInfo@OnCurrentSkillCountChange", ((vm.IsUseSkillCD and vm.CurrentSkillCount==0) or vm.IsUseCD))
end

function NormalSkillInfo:OnIsUseSkillCDChange(vm, fieldID)
    if not vm then return end
    print("NormalSkillInfo@OnIsUseSkillCDChange isUseCD:",vm.IsUseCD, "isUseSkillCD:",vm.IsUseSkillCD)
    local bEnterCooling = (vm.IsUseSkillCD and vm.CurrentSkillCount ==0 ) or vm.IsUseCD
    if bEnterCooling then
        self:EventEnterCooling()
    end
    self.Img_Skill_Count_CD_Ring:SetVisibility(vm.IsUseSkillCD and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.Img_Skill_Count_Bg:SetVisibility(vm.IsUseSkillCD and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function NormalSkillInfo:OnSkillCDPercentChange(vm, fieldID)
    if not vm then return end
    local CDPercent = 0
    if not vm.IsUseCD and vm.IsUseSkillCD then CDPercent = self.IncreaseCDPercent end
    if vm.IsUseSkillCD and vm.IsUseCD and vm.TotalSkillCDTime ~= 0 then CDPercent = self.IncreaseCDPercent end
    self.Img_Skill_Count_CD_Ring:GetDynamicMaterial():SetScalarParameterValue("Progress", (1 - vm.SkillCDPercent - CDPercent))
    self:SetCDTime(vm)
    -- print("NormalSkillInfo@OnSkillCountPercentChange", (1 - vm.SkillCDPercent))
end

--   ____  _  _____ _     _       _____ _   _ _____ ____   ______   __
--  / ___|| |/ /_ _| |   | |     | ____| \ | | ____|  _ \ / ___\ \ / /
--  \___ \| ' / | || |   | |     |  _| |  \| |  _| | |_) | |  _ \ V / 
--   ___) | . \ | || |___| |___  | |___| |\  | |___|  _ <| |_| | | |  
--  |____/|_|\_\___|_____|_____| |_____|_| \_|_____|_| \_\\____| |_|  
                                                                   

function NormalSkillInfo:OnIsUseEnergyChange(vm, fieldID)
    if not vm then return end
    self.TxtEnergyProgressNormal:SetVisibility(vm.IsUseEnergy and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    self.ImgEnergyProgressNormal:SetVisibility(vm.IsUseEngery and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    -- self.TrsEnergyProgressNormal:SetVisibility(vm.IsUseEngery and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function NormalSkillInfo:OnEnergyPercentChange(vm, fieldID)
    if not vm then return end
    -- print("NormalSkillInfo debug vm.EnergyPercent ",vm.EnergyPercent)
    self.TxtEnergyProgressNormal:SetText(string.format("%.f", math.max(0, vm.EnergyPercent * 100)))

    self.ImgEnergyProgressNormal:GetDynamicMaterial():SetScalarParameterValue("Progress", vm.EnergyPercent)
    -- self.TrsEnergyProgressNormal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if vm.EnergyPercent == 1 then
        self:EventCoolingComplete()
    end
end

--   ____  _  _____ _     _        ____ _   _    _    ____   ____ _____ 
--  / ___|| |/ /_ _| |   | |      / ___| | | |  / \  |  _ \ / ___| ____|
--  \___ \| ' / | || |   | |     | |   | |_| | / _ \ | |_) | |  _|  _|  
--   ___) | . \ | || |___| |___  | |___|  _  |/ ___ \|  _ <| |_| | |___ 
--  |____/|_|\_\___|_____|_____|  \____|_| |_/_/   \_\_| \_\\____|_____|
                                                                     
function NormalSkillInfo:OnIsUseChargeChange(vm, fieldID)
    if not vm then return end
    print("NormalSkillInfo@check visible OnIsUseChargeChange", vm.IsUseCharge)
    self.Trs_SkillCharge:SetVisibility(vm.IsUseCharge and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.Img_Skill_Charge_Ring:SetVisibility(vm.IsUseCharge and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.TrsGuideSkillNormal:SetVisibility(vm.IsUseCharge and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
end

function NormalSkillInfo:OnSkillChargePercentChange(vm, fieldID)
    if not vm then return end
    self.Text_SkillCharge:SetText(string.format("%.f", math.max(0, vm.SkillChargePercent * 100)))
    self.Img_Skill_Charge_Ring:GetDynamicMaterial():SetScalarParameterValue("Line1_Length", vm.SkillChargePercent)
end

----------------------------------------------- MVVM End -----------------------------------------------
function NormalSkillInfo:OnFreshEnhanceId()
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPS)
    --击杀冷却芯片对应表RowName
    local CDReduceRowName = 1001
    if HudDataCenter == nil then return end
    if not HudDataCenter.SpecEnhanceIdArray:Contains(CDReduceRowName) then
        self.IncreaseCDPercent = 0
        self.Img_Skill_CD_Mask:GetDynamicMaterial():SetScalarParameterValue("Progress", self.NormalSkillInfoViewModel:GetCDPercent() + self.IncreaseCDPercent)
        self.Img_Skill_Count_CD_Ring:GetDynamicMaterial():SetScalarParameterValue("Progress", (1 - self.NormalSkillInfoViewModel.SkillCDPercent - self.IncreaseCDPercent))
        self.TxtCDSkillNormal:SetColorAndOpacity(self.NormalColor)
    else
        self.TxtCDSkillNormal:SetColorAndOpacity(self.CDReduceColor)
    end
end

return NormalSkillInfo
