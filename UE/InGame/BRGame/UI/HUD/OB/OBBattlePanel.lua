--
-- 观战界面
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.11.22
--

local OBBattlePanel = Class("Common.Framework.UserWidget")
-------------------------------------------- Init/Destroy ------------------------------------

function OBBattlePanel:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.BindNodes = {
        { UDelegate = self.Button_Quit.OnClicked, Func = self.OnClick_Button_Quit },
        
    }

    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.PC_Input_OB_TogglePlayerCard, Func = self.HandleTabDown, bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.PC_Input_OB_ToggleDeathInfo, Func = self.HandleShiftDown, bCppMsg = true, WatchedObject = self.LocalPC },
	}

    self:InitData()

	UserWidget.OnInit(self)

    print("OBBattlePanel@OnInit")
end

function OBBattlePanel:OnShow(data)
    print("OBBattlePanel@OnShow")
end

function OBBattlePanel:OnLayoutLoadCompelete()
    print("OBBattlePanel@OnLayoutLoadCompelete")
    self:SetPlayerCardShow(true)
    self.bLayoutLoadCompelete = true
end

function OBBattlePanel:OnClose()
    self.bShowPlayerCard = false
    self.bShowPlayerDeathInfo = false
end

function OBBattlePanel:OnDestroy()
	UserWidget.OnDestroy(self)
    self.bLayoutLoadCompelete = false
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function OBBattlePanel:InitData()
   self.bShowPlayerCard = false
   self.bShowPlayerDeathInfo = false
   self.bLayoutLoadCompelete = false
end


-------------------------------------------- Callable ------------------------------------
function OBBattlePanel:OnClick_Button_Quit()
    local OBSubsystem = UE.UObserveSubsystem.Get(self)
    OBSubsystem:ObserveExit()
    MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.Normal)
end

function OBBattlePanel:HandleShiftDown()
    self:SetPlayerCardShow(false)
    self:SetPlayerDeathInfoShow(not self.bShowPlayerDeathInfo)
end

function OBBattlePanel:HandleTabDown()
    self:SetPlayerDeathInfoShow(false)
    self:SetPlayerCardShow(not self.bShowPlayerCard)
end

function OBBattlePanel:SetPlayerCardShow(isShow)
    if self.bShowPlayerCard == isShow then
        return
    end
    
    print("OBBattlePanel@SetPlayerCardShow", isShow)
    local UIManager = UE.UGUIManager.GetUIManager(self)
    self.bShowPlayerCard = isShow
    if isShow then
        UIManager:TryLoadDynamicWidget("UMG_OBPlayerDisplayCard")
    else
        UIManager:TryCloseDynamicWidget("UMG_OBPlayerDisplayCard")
    end
    MsgHelper:Send(self, GameDefine.Msg.OB_Refresh_PlayerCard, isShow)
end

function OBBattlePanel:SetPlayerDeathInfoShow(isShow)
    if self.bShowPlayerDeathInfo == isShow then
        return
    end

    print("OBBattlePanel@SetPlayerDeathInfoShow", isShow)
    local UIManager = UE.UGUIManager.GetUIManager(self)
    self.bShowPlayerDeathInfo = isShow
    if isShow then
        UIManager:TryLoadDynamicWidget("UMG_OBPlayerDeathInfo")
    else
        UIManager:TryCloseDynamicWidget("UMG_OBPlayerDeathInfo")
    end
    MsgHelper:Send(self, GameDefine.Msg.OB_Refresh_PlayerDeath, isShow)
end

return OBBattlePanel
