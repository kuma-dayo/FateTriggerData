require "UnLua"

local BagUI = Class("Common.Framework.UserWidget")
local AdvanceMarkHelper = require("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")
function BagUI:OnInit()
    print("(Wzp)BagUI:OnInit  [ObjectName]=",GetObjectName(self))
    self.ItemSlotSupportTypes = {
        ["Weapon"] = true
    }
    self.bMobilePlatform = BridgeHelper.IsMobilePlatform()
    self.UIItemSlot = {
        ["Weapon"] = {self.ItemSlotWeapon_1, self.ItemSlotWeapon_2}
    }

    self.AttachmentGuideTable = {
        [1] = {TagName = nil},
        [2] = {TagName = nil}
    } 


    -- 拾取区
    self.BP_DropZoom_Pick:AddItemSlot(self.ReadyPickListInBag)

    -- 背包区
    self.BP_DropZoom_Bag:AddItemSlot(self.BP_BagListUI)

    if BridgeHelper.IsPCPlatform() then
        local ArmorHeadWidget, ArmorBodyWidget, BagWidgetWidget, CurrencyInBagWidget = self.BagEquipmentArea:GetAllWidget()
        self.BP_DropZoom_Bag:AddItemSlot(BagWidgetWidget)
        self.BP_DropZoom_Bag:AddItemSlot(ArmorHeadWidget)
        self.BP_DropZoom_Bag:AddItemSlot(ArmorBodyWidget)
        self.BP_DropZoom_Bag:AddItemSlot(CurrencyInBagWidget)
    
        local BulletWidgets = self.BagBulletArea:GetAllWidget()
        for _, BulletWidget in pairs(BulletWidgets) do
            self.BP_DropZoom_Bag:AddItemSlot(BulletWidget)
        end
    
        local ContainerInBagSlotWidgets = self.ContainerInBag:GetAllSlotWidget()
        for _, SlotWidget in pairs(ContainerInBagSlotWidgets) do
            self.BP_DropZoom_Bag:AddItemSlot(SlotWidget)

            local ItemSlotNormalWidget = SlotWidget:GetItemNormal()
            if ItemSlotNormalWidget then
                ItemSlotNormalWidget.StartAttachmentGuideEvent:Add(self,self.ShowAttachmentGuide)
                ItemSlotNormalWidget.EndAttachmentGuideEvent:Add(self,self.HideAttachmentGuide)
            end
        end
    
        for _, Widget in pairs(self.UIItemSlot["Weapon"]) do
            local AllAttachWidgets = Widget:GetAllAttachmentWidget()
            for _, AttachWidget in pairs(AllAttachWidgets) do
                AttachWidget.StartAttachmentGuideEvent:Add(self,self.ShowAttachmentGuide)
                AttachWidget.EndAttachmentGuideEvent:Add(self,self.HideAttachmentGuide)
            end
        end
        
    
        -- 装备区
        self.BP_DropZoom_Equipment:AddItemSlot(self.UIItemSlot["Weapon"][1])
        self.BP_DropZoom_Equipment:AddItemSlot(self.UIItemSlot["Weapon"][2])
        print("(Wzp)EquipmentItemInBag:UpdateItemInfo  [ArmorHeadWidget]=",ArmorHeadWidget,",[ArmorBodyWidget]=",ArmorBodyWidget,",[BagWidgetWidget]=",BagWidgetWidget,",[CurrencyInBagWidget]=",CurrencyInBagWidget)
    end


    self.NormalSlot = {}

    -- 注册消息监听
    self.MsgList = {{
        MsgName = GameDefine.MsgCpp.BAG_FeatureSetUpdate,
        Func = self.OnUpdateItemFeatureSet,
        bCppMsg = true
    }, {
        MsgName = GameDefine.MsgCpp.BAG_WeightOrSlotNum,
        Func = self.OnUpdateBagData,
        bCppMsg = true
    }, {
        MsgName = GameDefine.Msg.EquippedInstance_Spawn,
        Func = self.OnEquippedInstanceSpawn,
        bCppMsg = true
    }, {
        MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Weapon,
        Func = self.UpdateWeaponSlotSingle,
        bCppMsg = true
    }, {
        MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Reset,
        Func = self.ResetWeaponSlotSingle,
        bCppMsg = true
    }, {
        MsgName = GameDefine.Msg.PLAYER_RespawnXEndRespawn,
        Func = self.OnRespawnXEndRespawn,
        bCppMsg = true
    }, {
        MsgName = GameDefine.MsgCpp.BAG_OnEscTriggerBagUI,
        Func = self.OnEscTriggerBagUI,
        bCppMsg = true
    }, {
        MsgName = GameDefine.Msg.Attachment_Guide_Start,
        Func = self.OnAttachmentGuideStart,
        bCppMsg = false
    }
    ,
    {
        MsgName = GameDefine.Msg.Attachment_Guide_End,
        Func = self.OnAttachmentGuideEnd,
        bCppMsg = false
    },
    {   
        MsgName = GameDefine.MsgCpp.INVENTORY_EQUIPPABLE_ONREP_WEAPON,
        Func = self.OnInventoryEquippableOnRepWeapon,
        bCppMsg = true
    }
    }

    local GamepadInputSubsystem = UE.UGamepadInputSubsystem.Get(self)
    GamepadInputSubsystem.GamepadConnectionNotify:Add(self,self.GamepadConnectionNotify)

    -- 两个技能图标的案件绑定事件
    if self.NormalSkillInfoImage then
        self.NormalSkillInfoImage.OnMouseButtonDownEvent:Bind(self, self.OnMouseButtonDown_NormalSkill)
    end

    if self.UltiSkillInfoImage then
        self.UltiSkillInfoImage.OnMouseButtonDownEvent:Bind(self, self.OnMouseButtonDown_UltiSkill)
    end

    self.GMPKeyBeginDying = ListenObjectMessage(nil, GameDefine.MsgCpp.PLAYER_OnBeginDying, self,
        self.CharacterBeginDying)
    self.GMPKeyBeginDead = ListenObjectMessage(nil, GameDefine.MsgCpp.PLAYER_OnBeginDead, self, self.CharacterBeginDead)

    self:UpdateBagWeightOrSlotNum()
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    self:UpdateWeaponSlotWidget(self.LocalPC)

    -- self:InitBulletWidgetArray()

    self:InitSkillInfo()

    if BridgeHelper.IsPCPlatform() then
        self.ReadyPickListInBag.Delegate_ReadyPickListRetrunFocus:Add(self, self.OnReadyPickListRetrunFocus)
        self:UpdateNavigation()
    end

    self:InitFocusable()
    UserWidget.OnInit(self)
end

function BagUI:UpdateNavigation()
    print("(Wzp)BagUI:UpdateNavigation  [ObjectName]=",GetObjectName(self))
    if not self.ReadyPickListInBag then return end
    self.ReadyPickListInBag.bIsFocusable = false
end

function BagUI:OnShow(InContext, InGenericBlackboard)
    print("(Wzp)BagUI:OnShow  [ObjectName]=",GetObjectName(self))
    self:InitSkillInfo()
    self:InitFocusable()
    self:InitHanldSelectNavigation()
    self.Overridden.OnShow(self, InContext, InGenericBlackboard)
    if BridgeHelper.IsPCPlatform() then
        self.ReadyPickListInBag:ReadyPickupUpdate()
    end

    UE.UGamepadUMGFunctionLibrary.SetSimulateMiddleButton(true)
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if not UIManager then return end
    local LobbyPlayerInfoViewModel = UIManager:GetViewModelByName("TagLayout.Gameplay.LobbyPlayerInfo")
    if not LobbyPlayerInfoViewModel then return end
    if LobbyPlayerInfoViewModel.PlayerPlayCount < 3 then self:ShowGuideAmmoTips() end

    --
    local GenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(GameInstance)
    if GenericGamepadUMGSubsystem and GenericGamepadUMGSubsystem:IsInGamepadInput() then 
        MsgHelper:SendCpp(GameInstance,GameDefine.MsgCpp.Minimap_OpenLargeMapByGamepad)
        print("BagUI:OpenBagByGamepad")
    end

end

function BagUI:OnClose(InContext, InGenericBlackboard)
    print("(Wzp)BagUI:OnClose  [ObjectName]=",GetObjectName(self))

    UE.UGamepadUMGFunctionLibrary.SetSimulateMiddleButton(false)
    local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    if IsInCursorMode then
        UE.UGamepadUMGFunctionLibrary.InitCurControlWidget(nil)
    end

    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    TipsManager:RemoveTipsUI("Guide.AmmoInBag")
    self:SendBury()
end

function BagUI:OnClicked_Close()
    print("(Wzp)BagUI:OnClicked_Close  [ObjectName]=",GetObjectName(self))
    NotifyObjectMessage(self.LocalPC, "EnhancedInput.ToggleBagUI")
end


function BagUI:OnInventoryEquippableOnRepWeapon(InInventoryInstance, InEquippableInstance)
    if InInventoryInstance then
        local CurrentInventoryIdentity = InInventoryInstance:GetInventoryIdentity()

        local TempBagComp = UE.UBagComponent.Get(self.LocalPC)
        if not TempBagComp then
            return
        end

        local WeaponSlot,bIsFind = TempBagComp:GetItemSlot(CurrentInventoryIdentity)
        if bIsFind then
            self:UpdateWeaponSlotWidgetSingle(TempBagComp, WeaponSlot)
        end
    end
end


-- 初始化技能信息
function BagUI:InitSkillInfo()
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)

    if (not LocalPCPawn) then
        print("BagUI:InitSkillInfo not LocalPCPawn")
        return
    end

    if self.SkillTacticalWidgetInfos and self.SkillUltimateWidgetInfos then
        --return
    end

    self.SkillTacticalWidgetInfos = {}
    self.SkillUltimateWidgetInfos = {}

    local PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnData(LocalPCPawn)
    local SkillConfigLength = PawnConfig.SkillConfigs:Length()
    print("BagUI:InitSkillInfo SkillConfigLength", SkillConfigLength)
    for i = 1, SkillConfigLength do
        local SkillConfig = PawnConfig.SkillConfigs:GetRef(i)
        -- 因为确定了SkillTypeTag和TriggerInputTag是一一对应，且后期会加接口规范，目前用最蠢的办法写ifelse
        local InputTagName = SkillConfig.TriggerInputTag.TagName

        if InputTagName == "EnhancedInput.Skill.Tactical" then
            self.SkillTacticalWidgetInfos["Skill.SkillTag.Tactical"] = {
                SkillId = SkillConfig.SkillId
            }
        elseif InputTagName == "EnhancedInput.Skill.Ultimate" then
            self.SkillUltimateWidgetInfos["Skill.SkillTag.Ultimate"] = {
                SkillId = SkillConfig.SkillId
            }
        end
    end
end

-- function BagUI:InitBulletWidgetArray()
--     self.BulletItemWidgetArray = {self.WBP_BulletSlotInContainer_0, self.WBP_BulletSlotInContainer_1,
--                                   self.WBP_BulletSlotInContainer_2, self.WBP_BulletSlotInContainer_3,
--                                   self.WBP_BulletSlotInContainer_4}

--     if self.BulletItemWidgetArray then
--         for i = 1, #self.BulletItemWidgetArray, 1 do
--             self.BulletItemWidgetArray[i]:SetLockState(false)
--         end
--     end

-- end

function BagUI:GetBulletWidgetByOnlySupportItemId(InItemId)
    print("(Wzp)BagUI:GetBulletWidgetByOnlySupportItemId  [ObjectName]=",GetObjectName(self),",[InItemId]=",InItemId,",[self.BulletItemWidgetArray]=",self.BulletItemWidgetArray)

    if self.BulletItemWidgetArray then
        for i = 1, #self.BulletItemWidgetArray, 1 do
            local SlotWidget = self.BulletItemWidgetArray[i]
            local TempItemId = SlotWidget:GetOnlySupportItemId()
            if TempItemId == InItemId then
                return SlotWidget
            end
        end
    end

    return nil
end

function BagUI:OnMouseButtonDown_NormalSkill(MyGeometry, MouseEvent)
    local bIsPC = BridgeHelper.IsPCPlatform()

    local MiddleMouseButton = bIsPC and
                                  UE.UKismetInputLibrary
                                      .PointerEvent_IsMouseButtonDown(MouseEvent, UE.EKeys.MiddleMouseButton)

    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return DefaultReturnValue
    end

    print("BagUI", ">> OnMouseButtonDown_NormalSkill", GetObjectName(self))

    if GameDefine.NInputKey.MiddleMouseButton == MouseKey.KeyName then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)

        if PlayerController and LocalPCPawn then
            local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
            if BattleChatComp then
                local PlayerName = ""
                if PlayerController.PlayerState then
                    PlayerName = PlayerController.PlayerState:GetPlayerName()
                end
                for TagName, SkillWidgetInfo in pairs(self.SkillTacticalWidgetInfos) do
                    local SkillTag = UE.FGameplayTag()
                    SkillTag.TagName = TagName      
                    local State = UE.UGeSkillBlueprintLibrary.GetSkillState(LocalPCPawn, SkillTag)
                    local IsUseCountCD, CurrentCountCDTime, TotalCountCDTime =
                        UE.UGeSkillBlueprintLibrary.GetUseCountCDParameter(LocalPCPawn, SkillTag)

                    local IsUseCD, CurrentCDTime, TotalCDTime =
                        UE.UGeSkillBlueprintLibrary.GetSkillCDParameter(LocalPCPawn, SkillTag)
                    local IsUseEnergy, CurrentEnergy, TotalEnergy, eDisplayType = UE.UGeSkillBlueprintLibrary.GetSkillEnergy(LocalPCPawn, SkillTag)
                    local CoolTime = (TotalCDTime - CurrentCDTime) > (TotalCountCDTime - CurrentCountCDTime) and math.floor(CurrentCDTime) or math.floor(CurrentCountCDTime)
                    local Percentage = (TotalCDTime - CurrentCDTime) > (TotalCountCDTime - CurrentCountCDTime) and CurrentCDTime / TotalCDTime or CurrentCountCDTime / TotalCountCDTime
                    local NeedPercentage = math.floor((1.0 - Percentage) * 100) -- 还需要多少百分比
                    local SkillName = ""

                    local TmpSkillId = SkillWidgetInfo.SkillId

                    local DisplayText
                    local heroId = LocalPCPawn.PawnData.PawnTypeID

                    local ADCMark = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
                    local cfg
                    if ADCMark and ADCMark.HeroSkillCfg then
                        cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(ADCMark.HeroSkillCfg,
                            tostring(TmpSkillId))
                        if cfg then
                            SkillName = cfg.SkillName
                        end

                    end

                    if UE.EGeSkillStatus.Activating == State then
                        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "TacticalSkillActivating",
                            PlayerName, SkillName)
                    elseif UE.EGeSkillStatus.Cooling == State then
                        if Percentage > 0.85 and Percentage < 0.99 then
                            if IsUseCD then
                                AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "TacticalSkillCoolTime85-99",
                                PlayerName, SkillName, CoolTime)
                            elseif IsUseEnergy then
                                AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "TacticalSkillEnergy85-99",
                                PlayerName, SkillName, NeedPercentage)
                            end
                        else
                            if IsUseCD then
                                AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "TacticalSkillCoolTime", PlayerName,
                                SkillName, CoolTime)
                            elseif IsUseEnergy then
                                AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "TacticalSkillEnergy", PlayerName,
                                SkillName, NeedPercentage)
                            end
                        end
                        
                    elseif State == UE.EGeSkillStatus.Invalid then

                    elseif State == UE.EGeSkillStatus.Normal then
                        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "TacticalSkillNormal", PlayerName,
                            SkillName)
                    elseif UE.EGeSkillStatus.CantUse == State then
                        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "TacticalSkillCannot", PlayerName,
                            SkillName)
                    end
                end
            end
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function BagUI:OnMouseButtonDown_UltiSkill(MyGeometry, MouseEvent)
    local bIsPC = BridgeHelper.IsPCPlatform()
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Unhandled()

    local MiddleMouseButton = bIsPC and
                                  UE.UKismetInputLibrary
                                      .PointerEvent_IsMouseButtonDown(MouseEvent, UE.EKeys.MiddleMouseButton)

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return DefaultReturnValue
    end

    print("BagUI", ">> OnMouseButtonDown_UltiSkill", GetObjectName(self))

    if GameDefine.NInputKey.MiddleMouseButton == MouseKey.KeyName then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)

        if PlayerController and LocalPCPawn then
            local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
            if BattleChatComp then
                local PlayerName = ""
                if PlayerController.PlayerState then
                    PlayerName = PlayerController.PlayerState:GetPlayerName()
                end
                for TagName, SkillWidgetInfo in pairs(self.SkillUltimateWidgetInfos) do
                    local SkillTag = UE.FGameplayTag()
                    SkillTag.TagName = TagName
                    local State = UE.UGeSkillBlueprintLibrary.GetSkillState(LocalPCPawn, SkillTag)
                    local IsUseCD, CurrentCDTime, TotalCDTime =
                        UE.UGeSkillBlueprintLibrary.GetSkillCDParameter(LocalPCPawn, SkillTag)
                    local IsUseEnergy, CurrentEnergy, TotalEnergy, eDisplayType = UE.UGeSkillBlueprintLibrary.GetSkillEnergy(LocalPCPawn, SkillTag)
                    local CoolTime = IsUseCD and math.floor(CurrentCDTime) or math.floor(TotalEnergy - CurrentEnergy)
                    local Percentage = IsUseCD and CurrentCDTime / TotalCDTime or CurrentEnergy / TotalEnergy
                    local NeedPercentage = math.floor((1.0 - Percentage) * 100) -- 还需要多少百分比
                    local TmpSkillId = SkillWidgetInfo.SkillId
                    local SkillName = ""
                    local ADCMark = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
                    local cfg
                    if ADCMark and ADCMark.HeroSkillCfg then
                        cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(ADCMark.HeroSkillCfg,
                            tostring(TmpSkillId))

                        if cfg then
                            SkillName = cfg.SkillName
                        end
                    end


                    local heroId = LocalPCPawn.PawnData.PawnTypeID
                    if UE.EGeSkillStatus.Activating == State then
                        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "UltimateSkillActivating",
                            PlayerName, SkillName)
                        print("BagUI:OnMouseButtonDown_UltiSkill SendMsg UE.EGeSkillStatus.Activating")
                    elseif UE.EGeSkillStatus.Normal == State then
                        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "UltimateSkillNormal", PlayerName,
                            SkillName)
                        print("BagUI:OnMouseButtonDown_UltiSkill SendMsg UE.EGeSkillStatus.Normal")
                    elseif UE.EGeSkillStatus.Cooling == State then
                        if Percentage > 0.85 and Percentage < 0.99 then
                            if IsUseCD then
                                AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "UltimateSkillCoolTime85-99",
                                PlayerName, SkillName, CoolTime)
                            elseif IsUseEnergy then
                                AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "UltimateSkillEnergy85-99",
                                PlayerName, SkillName, NeedPercentage)
                            end
                        else
                            if IsUseCD then
                                AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "UltimateSkillCoolTime", PlayerName,
                                SkillName, CoolTime)
                            elseif IsUseEnergy then
                                AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "UltimateSkillEnergy", PlayerName,
                                SkillName, NeedPercentage)
                            end
                        end
                        print("BagUI:OnMouseButtonDown_UltiSkill SendMsg UE.EGeSkillStatus.Cooling")
                    elseif UE.EGeSkillStatus.Invalid == State then
                    elseif UE.EGeSkillStatus.CantUse == State then
                        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, "UltimateSkillCannot", PlayerName,
                            SkillName)
                        print("BagUI:OnMouseButtonDown_UltiSkill SendMsg UE.EGeSkillStatus.CantUse")
                    end
                end
            end
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function BagUI:OnDestroy()
    print("(Wzp)BagUI:OnDestroy  [ObjectName]=",GetObjectName(self))
    if self.GMPKeyBeginDying then
        UnListenObjectMessage(GameDefine.MsgCpp.PLAYER_OnBeginDying, self, self.GMPKeyBeginDying)
        self.GMPKeyBeginDying = nil
    end

    if self.GMPKeyBeginDead then
        UnListenObjectMessage(GameDefine.MsgCpp.PLAYER_OnBeginDead, self, self.GMPKeyBeginDead)
        self.GMPKeyBeginDead = nil
    end

    UserWidget.OnDestroy(self)

    self.ItemSlotSupportTypes = nil
    self.UIItemSlot = nil
    self.NormalSlot = nil
end

function BagUI:OnUpdateBagData(InBagComponent)
    print("(Wzp)BagUI:OnDestroy  [ObjectName]=",GetObjectName(self))
    -- 更新背包的重量或者格子
    self:UpdateBagWeightOrSlotNum()
end

function BagUI:OnRespawnXEndRespawn(RespawnPlayerID, BeingRespawnPlayerID)
    print("(Wzp)BagUI:OnRespawnXEndRespawn  [ObjectName]=",GetObjectName(self))
    if BeingRespawnPlayerID == 0 then
        return
    end
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if PlayerController and PlayerController:GetPlayerId() == RespawnPlayerID then
        self:UpdateWeaponSlotWidget(PlayerController)
    end
end

function BagUI:CharacterBeginDying(InDyingMessageInfo)
    print("(Wzp)BagUI:CharacterBeginDying  [ObjectName]=",GetObjectName(self))
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not InDyingMessageInfo then
        return
    end
    local Character = InDyingMessageInfo.DyingActor
    if not Character then
        return
    end
    if PlayerController == Character:GetController() then
        local UIManager = UE.UGUIManager.GetUIManager(self)
        -- local BagHandle = UIManager:ShowByKey("UMG_Bag")
        -- UIManager:CloseByHandle(self.Handle, false)
    end
end

function BagUI:CharacterBeginDead(InDeadMessageInfo)
    print("(Wzp)BagUI:CharacterBeginDead  [ObjectName]=",GetObjectName(self))
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not InDeadMessageInfo then
        return
    end
    local Character = InDeadMessageInfo.DeadActor
    if not Character then
        return
    end
    if PlayerController == Character:GetController() then
        local UIManager = UE.UGUIManager.GetUIManager(self)
        -- local BagHandle = UIManager:ShowByKey("UMG_Bag")
        -- UIManager:CloseByHandle(self.Handle, false)
    end
end

-- 更新背包重量或者格子个数
function BagUI:UpdateBagWeightOrSlotNum()
    print("(Wzp)BagUI:UpdateBagWeightOrSlotNum  [ObjectName]=",GetObjectName(self))
    if self.WBP_CommonItemContainerInBag then
        self.WBP_CommonItemContainerInBag:UpdateLockSlotState()
    end
end

function BagUI:OnEquippedInstanceSpawn(InPawn, InEquippedInstance)
    print("(Wzp)BagUI:OnEquippedInstanceSpawn  [ObjectName]=",GetObjectName(self),",[InPawn]=",InPawn,",[InEquippedInstance]=",InEquippedInstance)
    if not InPawn then
        return
    end
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC ~= InPawn:GetOwner() then
        return
    end
    -- 刷新武器信息
    self:UpdateWeaponSlotWidget(TempLocalPC)
end

function BagUI:UpdateWeaponSlotSingle(InBagComponentOwner, InInventoryItemSlot)
    print("(Wzp)BagUI:UpdateWeaponSlotSingle  [ObjectName]=",GetObjectName(self))
    self:UpdateWeaponSlotWidgetSingle(InBagComponentOwner, InInventoryItemSlot)
end

function BagUI:ResetWeaponSlotSingle(InBagComponentOwner, InInventoryItemSlot)
    print("(Wzp)BagUI:ResetWeaponSlotSingle  [ObjectName]=",GetObjectName(self))
    if InInventoryItemSlot.ItemType == ItemSystemHelper.NItemType.Weapon then
        self:ResetWeaponSlotWidgetSingle(InBagComponentOwner, InInventoryItemSlot)
    end
end

-- move to C++
-- function BagUI:UpdateWeaponSlotWidget(LocalPC)
--     if not LocalPC then return end

--     local UpdateWeaponSlotIDSet = UE.TSet(0)
--     UpdateWeaponSlotIDSet:Add(1)
--     UpdateWeaponSlotIDSet:Add(2)

--     local CurActiveIndex = 1
--     local BagComp = UE.UBagComponent.Get(LocalPC)
--     local WeaponSlotDatas = BagComp:GetItemSlots()
--     for i = 1, WeaponSlotDatas:Length() do
--         local WeaponSlotData = WeaponSlotDatas:Get(i)
--         if WeaponSlotData then 
--             if WeaponSlotData.ItemType ~= ItemSystemHelper.NItemSlotType.Weapon then
--                 goto continue
--             end
--             if WeaponSlotData.bActive then
--                 CurActiveIndex = WeaponSlotData.SlotID
--             end

--             local WeaponWidgetInfo = nil
--             if WeaponSlotData.SlotID == 1 then
--                 WeaponWidgetInfo = self.ItemSlotWeapon_1
--             else
--                 WeaponWidgetInfo = self.ItemSlotWeapon_2
--             end
--             if not WeaponWidgetInfo then
--                 goto continue
--             end

--             if UpdateWeaponSlotIDSet:Contains(WeaponSlotData.SlotID) then
--                 UpdateWeaponSlotIDSet:Remove(WeaponSlotData.SlotID)
--             end
--             WeaponWidgetInfo:UpdateWeaponInfo(WeaponSlotData)
--             ::continue::
--         end
--     end

--     local ResetWeaponSlotIDs = UpdateWeaponSlotIDSet:ToArray()

--     --全部重置再刷新
--     for i = 1, ResetWeaponSlotIDs:Length() do
--         local TargetID = ResetWeaponSlotIDs:Get(i)
--         if TargetID then
--             local WeaponWidgetInfo = nil
--             if TargetID == 1 then
--                 WeaponWidgetInfo = self.ItemSlotWeapon_1
--             else
--                 WeaponWidgetInfo = self.ItemSlotWeapon_2
--             end
--             if WeaponWidgetInfo then
--                 WeaponWidgetInfo:Reset()
--             end
--         end
--     end
-- end

function BagUI:OnUpdateItemFeatureSet(InItemSlotFeatureSet, InItemSlotFeatureSetOuter)
    print("(Wzp)BagUI:OnUpdateItemFeatureSet  [ObjectName]=",GetObjectName(self))
    local TempPlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPlayerController then
        return
    end
end

function BagUI:OnMouseButtonDoubleClick(MyGeometry, MouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function BagUI:OnEscTriggerBagUI()
    NotifyObjectMessage(self.LocalPC, "EnhancedInput.ToggleBagUI")
end

function BagUI:InitHanldSelectNavigation()
    print("(Wzp)BagUI:InitHanldSelectNavigation  [ObjectName]=",GetObjectName(self))

    local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    if IsInCursorMode then
        UE.UGamepadUMGFunctionLibrary.InitCurControlWidget(self)
        return
    end

    self.ContainerInBag:SetFocus()

end

function BagUI:OnReadyPickListRetrunFocus(bIsFocus)
    print("(Wzp)BagUI:OnReadyPickListRetrunFocus  [ObjectName]=",GetObjectName(self),",[bIsFocus]=",bIsFocus)
    local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)

    self.ItemSlotWeapon_1.bIsFocusable = not IsInCursorMode
    self.ItemSlotWeapon_2.bIsFocusable = not IsInCursorMode
    
    if IsInCursorMode then
        return
    end


    if not bIsFocus then
        self.ContainerInBag:SetFocus()
    end

    self.ReadyPickListInBag.bIsFocusable = bIsFocus
end


function BagUI:InitFocusable()
    print("(Wzp)BagUI:InitFocusable  [ObjectName]=",GetObjectName(self))
    local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    print("(Wzp)BagUI:InitFocusable  [IsInCursorMode]=",IsInCursorMode)
    self:UpdateIsFocusable(not IsInCursorMode)
end



function BagUI:UpdateIsFocusable(bIsFocus)
    print("(Wzp)BagUI:UpdateIsFocusable  [ObjectName]=",GetObjectName(self),",[bIsFocus]=",bIsFocus)

    self.ItemSlotWeapon_1.bIsFocusable = bIsFocus
    self.ItemSlotWeapon_2.bIsFocusable = bIsFocus
    self.ContainerInBag.bIsFocusable = bIsFocus
    self.BagEquipmentArea.bIsFocusable = bIsFocus
    self.BagBulletArea.bIsFocusable = bIsFocus
    self.ReadyPickListInBag.bIsFocusable = bIsFocus

    self.ItemSlotWeapon_1:UpdateIsFocusable(bIsFocus)
    self.ItemSlotWeapon_2:UpdateIsFocusable(bIsFocus)
    self.ContainerInBag:UpdateIsFocusable(bIsFocus)
    self.BagEquipmentArea:UpdateIsFocusable(bIsFocus)
    self.BagBulletArea:UpdateIsFocusable(bIsFocus)

end

function BagUI:GamepadConnectionNotify(bGamepadAttached)
    print("(Wzp)BagUI:GamepadConnectionNotify  [ObjectName]=",GetObjectName(self),",[bGamepadAttached]=",bGamepadAttached)
    self:InitFocusable()
end

function BagUI:OnCursorModeChanged(bInCursorMode)
    print("(Wzp)BagUI:OnCursorModeChanged  [ObjectName]=",GetObjectName(self),",[bInCursorMode]=",bInCursorMode)
    self:InitFocusable()
    
    if not bInCursorMode then
        self.bIsFocusable = false
        self:InitHanldSelectNavigation()
        UE.UGUIHelper.LimitMouseToCenterLoc(self.LocalPC, 0)
        -- local ViewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
        -- self.LocalPC:SetMouseLocation(ViewportSize.X*0.5,ViewportSize.Y*0.5)
    else
        self:SetFocus()
    end
end

function BagUI:ShowAttachmentGuide(InInventoryIdentity)
    print("(Wzp)BagUI:ShowAttachmentGuide  [ObjectName]=",GetObjectName(self))

    local ItemID = InInventoryIdentity.ItemID

    local BagComp = UE.UBagComponent.Get(self.LocalPC)


    local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(self,ItemID, "ItemType",GameDefine.NItemSubTable.Ingame,"ItemSlotNormal:SetItemInfo")
        if  IsFindTempItemType and TempItemType == "Attachment" then
        --拿到物品所支持的枪械栏槽位Array
        local WeaponSlotArr = UE.UGAWAttachmentFunctionLibrary.FindAttachableWeaponSlots(self.LocalPC,ItemID)
        local WeaponSlotNum = WeaponSlotArr:Num()
        for index = 1, WeaponSlotNum do
                local InventoryItemSlot = WeaponSlotArr:Get(index)
                local BagWeaponInstance = BagComp:GetInventoryInstance(InventoryItemSlot.InventoryIdentity)

                local WeaponInstance = BagWeaponInstance.CurrentEquippableInstance
                local SlotID = InventoryItemSlot.SlotID

                local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self.LocalPC, ItemID)
                if not IngameDT then
                    return
                end

                local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(ItemID))
                if not StructInfo_Item then
                    return
                end

                local Tag = StructInfo_Item.SlotName
                self.AttachmentGuideTable[SlotID].TagName = Tag.TagName

        end


        local ShowGuideSoltNum = 0
        local WeaponHasAttachmentAttach = {true, true}
        for SlotID, Value in pairs(self.AttachmentGuideTable) do
            local TagName = Value.TagName
            --用于判断是否禁用配件槽位，如果只有1个槽位可用则ShowGuideSoltNum为1，显示高亮
            if TagName then 
                ShowGuideSoltNum = ShowGuideSoltNum + 1
                local WeaponSlotWidget = self.UIItemSlot["Weapon"][SlotID]
                --用于判断是否另一个槽位已装上配件，另一个未装上配件的槽位显示高亮
                if WeaponSlotWidget then 
                    local AttachmentWidget = WeaponSlotWidget.SupportAttachments[TagName]
                    if AttachmentWidget then
                        if AttachmentWidget.ItemID == -1 then WeaponHasAttachmentAttach[SlotID] = false end 
                    end
                end
            end
        end
        
        for SlotID, Value in pairs(self.AttachmentGuideTable) do
            local TagName = Value.TagName
            local WeaponSlotWidget = self.UIItemSlot["Weapon"][SlotID]
            if WeaponSlotWidget then
                local OtherWeaponSlot = (SlotID == 1 and 2) or 1
                WeaponSlotWidget:WeaponAttachmentEquipGuide(TagName, ShowGuideSoltNum, WeaponHasAttachmentAttach[OtherWeaponSlot])
            end
        end
    end
end


function BagUI:HideAttachmentGuide()
    print("(Wzp)BagUI:HideAttachmentGuide  [ObjectName]=",GetObjectName(self))
    for SlotID, Value in pairs(self.AttachmentGuideTable) do
        local TagName = Value.TagName
        local WeaponSlotWidget = self.UIItemSlot["Weapon"][SlotID]
        if WeaponSlotWidget then
            WeaponSlotWidget:EndWeaponAttachmentEquipGuide(TagName)
        end
    end

    self.AttachmentGuideTable[1].TagName = nil
    self.AttachmentGuideTable[2].TagName = nil
end

function BagUI:OnAttachmentGuideStart(MsgParams)
    local GuideInvertoryIdentity = MsgParams.GuideInventoryIdentity
    self:ShowAttachmentGuide(GuideInvertoryIdentity)
end 

function BagUI:OnAttachmentGuideEnd()
    print("(Wzp)BagUI:OnAttachmentGuideEnd  [ObjectName]=",GetObjectName(self))
    self:HideAttachmentGuide()
end

function BagUI:ShowGuideAmmoTips()
    print("(Wzp)BagUI:ShowGuideAmmoTips  [ObjectName]=",GetObjectName(self))
    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    local GenericBlackboardContainer = UE.FGenericBlackboardContainer()
    local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackboardKeySelector.SelectedKeyName = "Anchors"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsVector(GenericBlackboardContainer,BlackboardKeySelector,UE.FVector(1,1,0))
    BlackboardKeySelector.SelectedKeyName = "Alignment"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsVector(GenericBlackboardContainer,BlackboardKeySelector,UE.FVector(1,1,0))
    TipsManager:ShowTipsUIByTipsId("Guide.AmmoInBag", -1, GenericBlackboardContainer, self)
end

function BagUI:SendBury()
    print("(Wzp)BagUI:SendBury  [ObjectName]=",GetObjectName(self))
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    if LocalPCPawn then

        local vec = LocalPCPawn:K2_GetActorLocation();
        local JsonValue = {
            ["action"] = 102107102,
            ["position"] = string.format("X: %.2f, Y: %.2f, Z: %.2f", vec.X, vec.Y, vec.Z),
            ["object_source"] = "backpack",
        }
        UE.UBuryReportSubsystem.SendBuryByContext(GameInstance,LocalPCPawn.PlayerState,"game_during_item_flow",CommonUtil.JsonSafeEncode(JsonValue))
    end
   
end

function BagUI:SetSelectWidget(Widget)
    if self.SelectWidget then
        self.SelectWidget:OnUnhover()
    end
    self.SelectWidget = Widget
    self.SelectWidget:Onhover()
end


return BagUI
