require "UnLua"

require("InGame.BRGame.GameDefine")

local S1BRPlayerController = Class()

function S1BRPlayerController:Initialize(Initializer)
    self.LeftAltKeyDown = false

    --self.bShowSetting = false

    self.SettlementHandle = nil
    self.bShowSettlementInOB = false
end

function S1BRPlayerController:ReceiveBeginPlay()
    print("S1BRPlayerController", ">> ReceiveBeginPlay, ")

    local UIManager = UE.UGUIManager.GetUIManager(self)
    --assert(UIManager, ">> S1BRPlayerController, UIManager is nil!!!")

    -- 非专有服务器才设置
    if not UE.UGFUnluaHelper.IsRunningDedicatedServer(self) then
        self:SetupKeyBindings()
    end

    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if PickupSetting then
        self.HoldTime = PickupSetting.PickHoldTime
    end

    if self:IsLocalController() then
        if UIManager then
            UIManager:CreateDefaultCursorWidget(self)
            UIManager:SetDefaultCursorVisibility(true)
            if UE.UGFStatics.IsMobilePlatform() then
                UIManager:SetDefaultCursorVisibility(false)
            end
        end

        if not CommonUtil.g_in_playing then
            --属于直接启动战斗地图，不是走正常流程的，需要兼容
            --这里额外进行Mvc View赋值，兼容编辑器直接启动战斗地图
            CWaring("S1BRPlayerController:ReceiveBeginPlay fix mvc view logic")
            MvcEntry:GetModel(ViewModel):SetState(ViewConst.LevelBattle, true,nil,UIRoot.UILayerType.Scene);
            MvcEntry:GetModel(ViewModel).show_LEVEL = ViewConst.LevelBattle
            MvcEntry:GetModel(ViewModel).show_LEVEL_Fix = ViewConst.LevelBattle
            --这种也属于游戏场景内，改标记为true @chenyishui
            CommonUtil.g_in_play = true  
            CommonUtil.g_in_playing = true
        end
    end    
    self.CanSetOBTarget = true
end

--function S1BRPlayerController:ReceiveEndPlay(InEndPlayReason)
function S1BRPlayerController:ReceiveDestroyed()
    print("S1BRPlayerController", ">> ReceiveDestroyed, ")

    if not UE.UGFUnluaHelper.IsRunningDedicatedServer(self) then
        if self.MsgList then
            MsgHelper:UnregisterList(self, self.MsgList)
            self.MsgList = nil
        end
    end
    if self.OBTargetTimerHandle then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.OBTargetTimerHandle)
		self.OBTargetTimerHandle = nil
	end
end

function S1BRPlayerController:ReceiveTick(DeltaSeconds)

end

function S1BRPlayerController:SetupKeyBindings()
    self.MsgList = {
        -- { MsgName = "EnhancedInput.SwitchBagShow",	    Func = self.SwitchBagShow,      bCppMsg = true, WatchedObject = self},
        { MsgName = "EnhancedInput.SwitchGMShow",	    Func = self.SwitchGMShow,       bCppMsg = true, WatchedObject = self},
        --{ MsgName = "EnhancedInput.SwitchSettingShow",	Func = self.SwitchSettingShow,  bCppMsg = true, WatchedObject = self},
        { MsgName = "EnhancedInput.OpenSettlementDetailPanel",	Func = self.OpenSettlementDetailPanel,  bCppMsg = true, WatchedObject = self},
        -- { MsgName = "EnhancedInput.SwitchWeapon",	    Func = self.Pressed_Weapon,     bCppMsg = true, WatchedObject = self},
        -- { MsgName = "EnhancedInput.SwitchWeapon2",	    Func = self.Pressed_Weapon2,    bCppMsg = true, WatchedObject = self},
        -- { MsgName = "EnhancedInput.UseThrowable",       Func = self.UseThrowable,       bCppMsg = true, WatchedObject = self},
        -- { MsgName = "EnhancedInput.UsePotion",	        Func = self.UsePotion,          bCppMsg = true, WatchedObject = self},
        -- { MsgName = "EnhancedInput.DoorInteraction",	Func = self.OnDoorInteraction,  bCppMsg = true, WatchedObject = self},
        { MsgName = "EnhancedInput.OBGotoPrevTarget",	Func = self.SetOBPrevTarget,   bCppMsg = true, WatchedObject = self},
        { MsgName = "EnhancedInput.OBGotoNextTarget",	Func = self.SetOBNextTarget,   bCppMsg = true, WatchedObject = self},
        { MsgName = "EnhancedInput.SwitchRespawnGene",  Func = self.SwitchRespawnGene,   bCppMsg = true, WatchedObject = self},
        -- 监听观战协议
        --{ MsgName = "ObserveX.System.EndObserver",      Func = self.OnEndObserve,       bCppMsg = true, WatchedObject = nil},
    }
    MsgHelper:RegisterList(self, self.MsgList)
    --Dump(self.MsgList, self.MsgList, 9)
end

-- 触发GM显示/隐藏
function S1BRPlayerController:SwitchGMShow(key)
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
        local UIManager = UE.UGUIManager.GetUIManager(self)
        if UIManager then
            local bIsGMOpen = UIManager:IsDynamicWidgetShowByHandle(self.GMHandle)
            if bIsGMOpen then
                UIManager:TryCloseDynamicWidgetByHandle(self.GMHandle);
            else
                self.GMHandle = UIManager:TryLoadDynamicWidget("UMG_GM");
            end
        end
    else
        if MvcEntry:GetModel(ViewModel):GetState(ViewConst.GMPanel) then
            MvcEntry:CloseView(ViewConst.GMPanel)
        else
            MvcEntry:OpenView(ViewConst.GMPanel)
        end
    end
end
-- -- 触发Setting显示/隐藏
-- function S1BRPlayerController:SwitchSettingShow(key)
--     if self.bShowSetting then
--         MsgHelper:Send(self, GameDefine.Msg.SETTING_Hide)
--     else
--         MsgHelper:Send(self, GameDefine.Msg.SETTING_Show)
--     end
--     self.bShowSetting = not self.bShowSetting
--     print("S1BRPlayerController", ">> SwitchSettingShow, ", GetObjectName(self), self.bShowSetting)
-- end
--触发Settlement显示隐藏
function S1BRPlayerController:OpenSettlementDetailPanel()
    -- #45415 【结算】玩家小队团灭后，弹出的结算数据UI短暂的点空格按钮会闪烁一下
    if self.bShowSettlementInOB then
        self.bShowSettlementInOB = false
        return
    end

    if SettlementProxy:GetCurrentResultMode() == Settlement.EResultMode.None then
        return 
    end

    local UIManager = UE.UGUIManager.GetUIManager(self)
    if not UIManager then
        return
    end

    if not UIManager:IsAnyDynamicWidgetShowByKey("UMG_SettlementDetail") then
        self.SettlementHandle = UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
    else
        --游戏结束后不可以关闭UI，等待结束
        local bOver = SettlementProxy:IsGameOver()
        if not bOver then
            UIManager:TryCloseDynamicWidgetByHandle(self.SettlementHandle)
            self.SettlementHandle = nil

            local UIManager = UE.UGUIManager.GetUIManager(self)
	        UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")
        end
    end

    -- 以下为提审逻辑
    --local bOver = SettlementProxy:IsGameOver()
    --local ResultMode = SettlementProxy:GetCurrentResultMode()
    --local bReviewStart = SettlementProxy:IsReviewStart()
    --local bIsTeamOver = SettlementProxy:IsTeamOver()
    --print("S1BRPlayerController:OpenSettlementDetailPanel > bOver =", bOver)
    --print("S1BRPlayerController:OpenSettlementDetailPanel > ResultMode =", ResultMode)
    --print("S1BRPlayerController:OpenSettlementDetailPanel > bReviewStart =", bReviewStart)
    --print("S1BRPlayerController:OpenSettlementDetailPanel > bIsTeamOver =", bIsTeamOver)
    --
    --if SettlementProxy:GetCurrentResultMode() == Settlement.EResultMode.None then
    --    return
    --end
    --
    --if not UIManager:IsAnyDynamicWidgetShowByKey("UMG_SettlementDetail") then
    --    self.SettlementHandle = UIManager:TryLoadDynamicWidget(self,"UMG_SettlementDetail")
    --end
    --
    --if bReviewStart and ResultMode == Settlement.EResultMode.DieToOut then
    --    print("S1BRPlayerController:OpenSettlementDetailPanel > bReviewStart + DieToOut")
    --elseif ResultMode == Settlement.EResultMode.AllDead or ResultMode == Settlement.EResultMode.Victory or ResultMode == Settlement.EResultMode.Finish then
    --    print("S1BRPlayerController:OpenSettlementDetailPanel > AllDead")
    --else
    --    if  self.SettlementHandle == nil then
    --        self.SettlementHandle = UIManager:ShowByKey("UMG_SettlementDetail")
    --    else
    --        --游戏结束后不可以关闭UI，等待结束
    --        local bOver = SettlementProxy:IsGameOver()
    --        if not bOver then
    --            UIManager:TryCloseDynamicWidgetByHandle(self.SettlementHandle)
    --            self.SettlementHandle = nil
    --        end
    --    end
    --end

    print("S1BRPlayerController", ">> UMG_SettlementDetail, ", GetObjectName(self))
end

--function S1BRPlayerController:OnDoorInteraction()
--    if self.pInteractiveActor then
--        if self:GetLocalRole() == UE.ENetRole.ROLE_AutonomousProxy then
--             local pendingState = self.pInteractiveActor:CalcPendingInteractiveState(self)
--             if pendingState ~= UE.EDoorInteractiveState.None then
--                 self:ServerRPC_SetDoorActorInteractive(self.pInteractiveActor, self.pInteractiveActor.CurDoorInteractiveState, pendingState)
--             end
--        end
--     end
--
--     if self.pInteractiveComponent then
--         if self:GetLocalRole() == UE.ENetRole.ROLE_AutonomousProxy then
--              local pendingState = self.pInteractiveComponent:CalcPendingInteractiveState(self)
--              print("xiaoyaolua:" .. "CalcPendingDoorState="..tostring(pendingState))
--              if pendingState ~= UE.EDoorInteractiveState.None then
--                  print("xiaoyaolua:" .. "ServerRPC begin")
--                  self:ServerRPC_SetDoorComponentInteractive(self.pInteractiveComponent, self.pInteractiveComponent:GetCurInteractiveState(), pendingState)
--                  print("xiaoyaolua:" .. "ServerRPC end")
--              end
--         end
--      end
--end

function S1BRPlayerController:SetOBPrevTarget()
    print("OBX -- SetOBPrevTarget--")
    --self:ObservePrevTarget()
    if self.CanSetOBTarget == true then
        local OBSubsystem = UE.UObserveSubsystem.Get(self)
        OBSubsystem:ObservePrevViewTarget()
        self.CanSetOBTarget = false
        self:SetTimerForOB()
    end
end

function S1BRPlayerController:SetOBNextTarget()
    print("OBX -- SetOBNextTarget--")
    --self:ObserveNextTarget()
    if self.CanSetOBTarget == true then
        local OBSubsystem = UE.UObserveSubsystem.Get(self)
        OBSubsystem:ObserveNextViewTarget()
        self.CanSetOBTarget = false
        self:SetTimerForOB()
    end
    
end

function S1BRPlayerController:SetTimerForOB()
    
	if self.OBTargetTimerHandle then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.OBTargetTimerHandle)
		self.OBTargetTimerHandle = nil
	end
    self.OBTargetTimerHandle= UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.ResetCanSetOBTarget}, self.SetOBTargetInterval, false, 0, 0)
end

function S1BRPlayerController:ResetCanSetOBTarget()
    self.CanSetOBTarget = true
end

function S1BRPlayerController:SwitchRespawnGene()
    print("PC -- SwitchRespawnGene--")

    self:ActivateRespawnSkill_PS()
end

function S1BRPlayerController:OnEndObserve(InData)
    print("PC -- OnEndObserve--")
end

function S1BRPlayerController:Pressed_LeftAlt()
    self.LeftAltKeyDown = true
end

function S1BRPlayerController:Released_LeftAlt()
    self.LeftAltKeyDown = false
end

function S1BRPlayerController:IsLeftAltDown()
    return self.LeftAltKeyDown
end

return S1BRPlayerController