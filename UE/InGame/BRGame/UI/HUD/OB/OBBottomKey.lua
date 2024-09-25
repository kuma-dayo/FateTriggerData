-- 观战按键提示
--
-- @COMPANY	ByteDance
-- @AUTHOR	王泽平
-- @DATE	2023.05.17

require ("InGame.BRGame.ItemSystem.PickSystemHelper")
require ("InGame.BRGame.ItemSystem.RespawnSystemHelper")

local OBBottomKey = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function OBBottomKey:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.GameState = UE.UGameplayStatics.GetGameState(self)

    self.LocalPS = self.LocalPC.OriginalPlayerState --观战玩家（死亡的）
    self.ViewPS = self.LocalPC.PlayerState  --被观战玩家（存活的）

    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PC_Input_OB_Accusation,    Func = self.OnAccusation,  bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.PC_Input_OB_ShowPlayerFlag,    Func = self.OnShowPlayerFlag,  bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.PC_Input_OB_RemindFlagLocation,    Func = self.OnRemindFlagLocation,  bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,	  Func = self.OnUpdateLocalPCPS,   bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.PLAYER_PSUpdateRespawnGeneState,  Func = self.OnChangeRespawnGeneState, bCppMsg = true, WatchedObject = self.LocalPS },
        { MsgName = GameDefine.MsgCpp.PC_Input_OB_ReturnLobby,    Func = self.OnReturnLobby,  bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.Msg.OB_Refresh_PlayerCard,     Func = self.SetPlayerCardShow,   bCppMsg = false },
        { MsgName = GameDefine.Msg.OB_Refresh_PlayerDeath,     Func = self.SetPlayerDeathInfoShow,   bCppMsg = false },
        { MsgName = GameDefine.MsgCpp.UISync_UpdateOnDead,Func = self.UpdateDeadInfo,   bCppMsg = true,  WatchedObject = self.LocalPS  },
	}

    self:OnChangeRespawnGeneState()
    self:InitData()
	UserWidget.OnInit(self)
    print("OBBottomKey >> OnInit")

    self.bShowSettlement = true
end

-- 结算和OB界面交互有干涉
-- function OBBottomKey:OnShow()
--     print("OBBottomKey >> OnShow")

       -- 不能在OnShow的时候调用TryCloseDynamicWidget
--     local UIManager = UE.UGUIManager.GetUIManager(self)
--     UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")
-- end

function OBBottomKey:OnDestroy()
    print("OBBottomKey >> OnDestroy")
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function OBBottomKey:InitData()
    print("OBBottomKey >> InitData")


    local SettleMode = SettlementProxy:GetSettleMode()
    print("OBBottomKey >> InitData > SettleMode=",SettleMode)
    -- if SettleMode == 0 then
    --     --个人
    --     self.Btn_RemindFlagLocation:SetDescription(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SkillDescPanel_Thereseemstobenoconf"))
    -- else
    --     --队伍

    --     self.Btn_RemindFlagLocation:SetDescription(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SkillDescPanel_Thereseemstobenoconf"))
    -- end
end



--刷新眼睛图标背景色
function OBBottomKey:RefreshButtons()
    --观战玩家队伍ID（死亡的）
    local SlefTeamId = self.LocalPS:GetTeamInfo_Id()
    --被观战玩家队伍ID（存活的）
    local ViewTeamId = self.ViewPS:GetTeamInfo_Id()
    print("OBWatchGame >> SlefTeamId=",SlefTeamId,",ViewTeamId=",ViewTeamId)


    -- if  SlefTeamId == ViewTeamId then
    --     --是队友
    --     self.Btn_RemindFlagLocation:SetVisibility(UE.ESlateVisibility.Visible)
    -- else
    --     --是敌人
    --     self.Btn_RemindFlagLocation:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- end
end


function OBBottomKey:IsViewTeamMate()
    
    local TeamExSubsystem = UE.UTeamExSubsystem.Get(self)
	if TeamExSubsystem then
		return TeamExSubsystem:IsTeammateByPSandPS(self.LocalPS,self.ViewPS)
	end
    return false
end


function OBBottomKey:SetPlayerCardShow(isShow)
    self.WS_Tab:SetActiveWidgetIndex(isShow and 1 or 0)
end

function OBBottomKey:SetPlayerDeathInfoShow(isShow)
    self.WS_Shift:SetActiveWidgetIndex(isShow and 1 or 0)
end
-------------------------------------------- Callable ------------------------------------

--举报
function OBBottomKey:OnAccusation()
    print("OBBottomKey >> OnAccusation")
    local SelfPS =  self.LocalPC.OriginalPlayerState
    local gameTeamMode = UE.UTeamExSubsystem.Get(self):GetTeamPlayerNumber()
    local TheGameId =  self.GameState.GameId
    local TheViewPlayerName = self.ViewPS:GetPlayerName()
    local TheViewPlayerId =self.ViewPS:GetPlayerId()

    local UIManager = UE.UGUIManager.GetUIManager(self)
    local bIsShow = UIManager:IsDynamicWidgetShowByHandle(self.ReportHandle) 
    if bIsShow then
        UIManager:TryCloseDynamicWidgetByHandle(self.ReportHandle)
        return
    end


    local GenericBlackboardContainer = UE.FGenericBlackboardContainer()
    local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackboardKeySelector.SelectedKeyName = "ReportPlayerId"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboardContainer, BlackboardKeySelector, tostring(TheViewPlayerId))
    BlackboardKeySelector.SelectedKeyName = "ReportPlayerName"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboardContainer, BlackboardKeySelector, TheViewPlayerName)
    BlackboardKeySelector.SelectedKeyName = "GameId"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboardContainer, BlackboardKeySelector, TheGameId)
    BlackboardKeySelector.SelectedKeyName = "ReportLocation"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsVector(GenericBlackboardContainer,BlackboardKeySelector,UE.FVector(0,0,0))
    BlackboardKeySelector.SelectedKeyName = "PlayerState"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsObject(GenericBlackboardContainer, BlackboardKeySelector, SelfPS)
    BlackboardKeySelector.SelectedKeyName = "ReportPlayerState"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsObject(GenericBlackboardContainer, BlackboardKeySelector, self.ViewPS)
    BlackboardKeySelector.SelectedKeyName = "PreInputMode" --记录当前输入模式，退出举报根据这个值还原当前输入模式
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector, 3)

    self.ReportHandle = UIManager:TryLoadDynamicWidget("UMG_Report",GenericBlackboardContainer,true)
end

--显示玩家信标
function OBBottomKey:OnShowPlayerFlag()
    --print("OBBottomKey >> OnShowPlayerFlag")
    -- local TipsManager =  UE.UTipsManager.GetTipsManager(self)
    -- if not TipsManager:IsTipsIsShowing("OB.ShowPlayerFlag") then
    --    TipsManager:ShowTipsUIByTipsId("OB.ShowPlayerFlag")
    -- end
   
end



--提示信标位置
function OBBottomKey:OnRemindFlagLocation()
    self:OnChangeRespawnGeneState()
    print("OBBottomKey >> OnRemindFlagLocation")
    
    -- MsgHelper:Send(self, GameDefine.Msg.BuoysSystem_ShowBootyBox)

    if self.bIsDead then
        -- #45415 【结算】玩家小队团灭后，弹出的结算数据UI短暂的点空格按钮会闪烁一下
        if self.LocalPC then
            self.LocalPC.bShowSettlementInOB = true
        end

        if self.bShowSettlement then
            local  UIManager = UE.UGUIManager.GetUIManager(self)
            UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
        end
        
        return
    else
        
        local AWBMark = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
        if AWBMark and self.LocalPC then
            AWBMark:ShowPlayerTeamBuoys(self.LocalPC)
        end
    end
    
end


function OBBottomKey:OnChangeRespawnGeneState()
    if (not UE.UKismetSystemLibrary.IsValid(self.LocalPS)) then
        return
    end

    local RespawnGeneState = RespawnSystemHelper.GetRespawnGeneState(self.LocalPS) 
    local bPSDead = self.LocalPS.bIsDead
    self.bIsDead = ((RespawnGeneState == UE.ERespawnGeneState.NoMoreRespawn) or (RespawnGeneState == UE.ERespawnGeneState.TimeOut) or (not self:IsViewTeamMate()))
                     and bPSDead
    self.Btn_RemindFlagLocation.GUITextBlock_69:SetText(self.bIsDead and self.LookData or self.TipLocation)
end

--[GMP消息]每次切换被观战者（存活的）后触发
function OBBottomKey:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    --更新存活被观战者
    print("OBEaster:OnUpdateLocalPCPS",GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
	if self.LocalPC == InLocalPC then
        if InNewPS then
            self.ViewPS = InNewPS
            self:RefreshButtons()
        end
	end

end


function OBBottomKey:OnReturnLobby()
    print("OBBottomKey:OnReturnLobby")
    MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.Normal)
end


function OBBottomKey:OnUpdateCharacterState()
    local bAlive = false
    if self.LocalPS:IsAlive() ==true then
        bAlive = not self.IsDead
    else
        bAlive =self.LocalPS:IsAlive()
    end

    local gene = UE.URespawnSubsystem.Get(self):HasGeneRespawnRule()
    if gene == false then
        if bAlive == true then
            self:UpdateToNormalWidget(bAlive)
        else
            self:UpdateToDeadlWidget(true)
        end
        return
    end


    local RespawnGeneState = RespawnSystemHelper.GetRespawnGeneState(self.LocalPS)
    if (RespawnGeneState == UE.ERespawnGeneState.TimeOut) or (RespawnGeneState == UE.ERespawnGeneState.NoMoreRespawn) then

    end
end

function OBBottomKey:UpdateDeadInfo(InDeadInfo)
    self.IsDead = InDeadInfo.bIsDead
    self.bShowSettlement = false
    self:OnRemindFlagLocation()
    self.bShowSettlement = true
end

return OBBottomKey
