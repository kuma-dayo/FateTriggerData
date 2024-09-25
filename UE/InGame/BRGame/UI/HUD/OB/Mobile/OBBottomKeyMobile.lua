-- 观战按钮
--
-- @COMPANY	ByteDance
-- @AUTHOR	王泽平  公亮亮
-- @DATE	2023.05.17 2024.5.11

require ("InGame.BRGame.ItemSystem.PickSystemHelper")

local OBBottomKeyMobile = Class("Common.Framework.UserWidget")

function OBBottomKeyMobile:OnInit()
    print("OBBottomKeyMobile >> OnInit")

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.GameState = UE.UGameplayStatics.GetGameState(self)

    self.LocalPS = self.LocalPC.OriginalPlayerState --观战玩家（死亡的）
    self.ViewPS = self.LocalPC.PlayerState  --被观战玩家（存活的）

    self.UIManager = UE.UGUIManager.GetUIManager(self)

    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,	  Func = self.OnUpdateLocalPCPS,   bCppMsg = true, WatchedObject = self.LocalPC },
	}

    MsgHelper:RegisterList(self, self.MsgList)

    if BridgeHelper.IsMobilePlatform() then

        self.BindNodes ={
            { UDelegate = self.Button_Exit.OnClicked, Func = self.OnClicked_Button_Exit },
            { UDelegate = self.Button_DeathInfo.OnClicked, Func = self.OnClicked_Button_CauseOfDeath},
            { UDelegate = self.Button_ViewTargetCard.OnClicked, Func = self.OnClicked_Button_ShowFlag},
        }
    end

    self.bWipeout = false  -- 全军覆没
    self.bClickedDeathinfo = false  -- 点击伤害统计
    self.bClickedShowFlag = false  -- 点击旗帜展示
    self.RefreshExitButtons();

	UserWidget.OnInit(self)
end

function OBBottomKeyMobile:OnDestroy()
    print("OBBottomKeyMobile >> OnDestroy")
	UserWidget.OnDestroy(self)
end

--[GMP消息]每次切换被观战者（存活的）后触发
function OBBottomKeyMobile:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    --更新存活被观战者
    print("OBBottomKeyMobile:OnUpdateLocalPCPS",GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
	if self.LocalPC == InLocalPC then
        if InNewPS then
            self.ViewPS = InNewPS
            self:RefreshExitButtons()
        end
	end
end

--刷新退出观战图标背景色
function OBBottomKeyMobile:RefreshExitButtons()
    print("OBBottomKeyMobile >> RefreshExitButtons")

    if not self then
        print("OBBottomKeyMobile >> self is nil")
        return
    end

    if not self.LocalPC or not self.ViewPS then
        return
    end

    --观战玩家队伍ID（死亡的）
    local SlefTeamId = self.LocalPS:GetTeamInfo_Id()
    --被观战玩家队伍ID（存活的）
    local ViewTeamId = self.ViewPS:GetTeamInfo_Id()
    print("OBWatchGame >> SlefTeamId=",SlefTeamId,",ViewTeamId=",ViewTeamId)

    if  SlefTeamId == ViewTeamId then
        --是队友
        self.bWipeout = false
        self.WidgetSwitcher_Exit:SetActiveWidgetIndex(0)
    else
        --是敌人
        self.bWipeout = true
        self.WidgetSwitcher_Exit:SetActiveWidgetIndex(1)
    end
end

function OBBottomKeyMobile:OnClicked_Button_Exit()  -- 点击退出观战按钮
    print("OBBottomKeyMobile >> OnClicked_Button_Exit")
    if self.UIManager ~= nil then
        print("OBBottomKeyMobile >> UIManager is not nil")

        if bWipeout then
            print("OBBottomKeyMobile >> bWipeout is true")
            self.UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
        else
            print("OBBottomKeyMobile >> bWipeout is not false")

            local TipsManager = UE.UTipsManager.GetTipsManager(self)
            TipsManager:ShowTipsUIByTipsId("OBPopUp")
        end
    end
end

function OBBottomKeyMobile:OnClicked_Button_CauseOfDeath()  -- 点击死亡原因统计按钮
    print("OBBottomKeyMobile >> OnClicked_Button_CauseOfDeath")

    if self.bClickedShowFlag then
        self.WidgetSwitcher_ViewTargetCard:SetActiveWidgetIndex(0)
        -- self.UIManager:TryCloseDynamicWidget("")
    end

    if self.bClickedDeathinfo then
        self.bClickedDeathinfo = false
        self.WidgetSwitcher_DeathInfo:SetActiveWidgetIndex(0)
        if self.UIManager ~= nil then
            print("OBBottomKeyMobile >> UIManager is not nil")
        end
        self.UIManager:TryCloseDynamicWidget("UMG_OBPlayerList_Mobile")
    else
        self.bClickedDeathinfo = true
        self.WidgetSwitcher_DeathInfo:SetActiveWidgetIndex(1)
        if self.UIManager ~= nil then
            print("OBBottomKeyMobile >> UIManager is not nil")
        end
        self.UIManager:TryLoadDynamicWidget("UMG_OBPlayerList_Mobile")
    end
end

function OBBottomKeyMobile:OnClicked_Button_ShowFlag()  -- 点击旗帜展示按钮
    print("OBBottomKeyMobile >> OnClicked_Button_ShowFlag")

    if self.bClickedDeathinfo then
        self.WidgetSwitcher_DeathInfo:SetActiveWidgetIndex(0)
        self.UIManager:TryCloseDynamicWidget("UMG_OBPlayerList_Mobile")
    end

    if self.bClickedShowFlag then
        self.bClickedShowFlag = false
        self.WidgetSwitcher_ViewTargetCard:SetActiveWidgetIndex(0)
        
    else
        self.bClickedShowFlag = true
        self.WidgetSwitcher_ViewTargetCard:SetActiveWidgetIndex(1)

    end
    
    local TipsManager =  UE.UTipsManager.GetTipsManager(self)
    if not TipsManager:IsTipsIsShowing("OB.ShowPlayerFlag") then
        TipsManager:ShowTipsUIByTipsId("OB.ShowPlayerFlag")
    end
end

return OBBottomKeyMobile