--Widget
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
require ("Common.Utils.StringUtil")

local ParentClassName = "InGame.BRGame.UI.HUD.Weapon.HUDWeaponSwitcherBase"
local HUDWeaponSwitcherBase = require(ParentClassName)
local HUDWeaponSwitcherPC = Class(ParentClassName)

-------------------------------------------- Init/Destroy ------------------------------------

function HUDWeaponSwitcherPC:OnInit()
    print("HUDWeaponSwitcherPC", ">> OnInit, ", GetObjectName(self))
    HUDWeaponSwitcherBase.OnInit(self)
end

function HUDWeaponSwitcherPC:OnDestroy()
    print("HUDWeaponSwitcherPC", ">> OnDestroy, ", GetObjectName(self))
	HUDWeaponSwitcherBase.OnDestroy(self)
end


function HUDWeaponSwitcherPC:InitSubWidgetData() --Override Function
    self.WeaponWidgetInfos = {}
    self.WeaponWidgetNum = 2
    for i = 1, self.WeaponWidgetNum do
        local WidgetIndex = i - 1
        local ImgTabOnKey = "ImgTabOn".. WidgetIndex
        local TxtTabNameKey = "TxtTabName".. WidgetIndex
        local ImgTabNumBgKey = "ImgTabNumBg".. WidgetIndex
        local TxtTabNumKey = "TxtTabNum".. WidgetIndex
        local WeaponDetailKey = "BP_WeaponDetail".. WidgetIndex
        local ImgTabBgKey = "ImgTabBg".. WidgetIndex

        local WeaponWidgetInfo = {
            ImgTabOn = self[ImgTabOnKey],
            TxtTabName = self[TxtTabNameKey],
            ImgTabNumBg = self[ImgTabNumBgKey],
            TxtTabNum = self[TxtTabNumKey],
            ImgTabBg = self[ImgTabBgKey],
            WeaponDetail = self[WeaponDetailKey],
        }
        WeaponWidgetInfo.ImgTabOn:SetVisibility(UE.ESlateVisibility.Collapsed)
        WeaponWidgetInfo.ImgTabBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        WeaponWidgetInfo.ImgTabNumBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        WeaponWidgetInfo.ImgTabNumBg:SetColorAndOpacity(BattleUIHelper.GetMiscSystemValue(self, "WeaponImageColor", "TabNotActiveColor"))
        WeaponWidgetInfo.ImgTabOn:GetDynamicMaterial():SetScalarParameterValue("WeaponIndex", 1 - WidgetIndex)
        WeaponWidgetInfo.TxtTabName:SetText('')
        WeaponWidgetInfo.WeaponDetail:InitData(self, i, WeaponWidgetInfo)
        self.WeaponWidgetInfos[i] = WeaponWidgetInfo
    end
    self.ImgIconBg:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function HUDWeaponSwitcherPC:HasWeaponState(bHasWeapon) --Override Funciton
    self.Root:SetRenderOpacity(bHasWeapon and 1 or self.NotWeaponOpacity)

    self.ImgBgNullWeapon:SetVisibility(bHasWeapon and UE.ESlateVisibility.Collapsed or  UE.ESlateVisibility.SelfHitTestInvisible)
    self.ImgUnhandWeapon:SetVisibility(bHasWeapon and UE.ESlateVisibility.Collapsed or  UE.ESlateVisibility.SelfHitTestInvisible)
end

function HUDWeaponSwitcherPC:SwitchFirstWeapon(bSwicth) --Override Funciton
    local FirstWeaponWidgetSlot = self.WeaponWidgetInfos[1]
    if bSwicth then
        self.TrsSwitcher:SetActiveWidgetIndex(0)
        FirstWeaponWidgetSlot.ImgTabOn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        FirstWeaponWidgetSlot.ImgTabBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        FirstWeaponWidgetSlot.WeaponDetail:ShowInitWeaponsUI(true)
        self.ImgIconNullWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        -- self.ImgIconBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- self.ImgIconBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        FirstWeaponWidgetSlot.WeaponDetail:ShowInitWeaponsUI(false)
    end
end

function HUDWeaponSwitcherPC:SendMicrochipTips() --Override Funciton
    MsgHelper:Send(self, GameDefine.Msg.WEAPON_WearMicroChip, {ItemID=nil})
end

-- true 一把枪都没有，false 至少有一把枪
function HUDWeaponSwitcherBase:ControlEmptyImageBgVisibility(bShow)
    print("HUDWeaponSwitcherBase >> ControlEmptyImageBgVisibility > bShow=",bShow,",ObjectName=",GetObjectName(self),",self.ImgIconBg=",self.ImgIconBg)
    self.ImgIconBg:SetVisibility(bShow and  UE.ESlateVisibility.Collapsed or  UE.ESlateVisibility.SelfHitTestInvisible)
    self.ImgIconNullWeapon:SetVisibility(bShow and  UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.ImgBgNullWeapon:SetVisibility(bShow and  UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.NullWeaponBulletStyle:SetVisibility(bShow and  UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    if bShow == true then
        self.CurrentShowingChipId = nil
        for i = 0, #self.BPWeaponDetail do
            self.BPWeaponDetail[i]:StopAllAnimations()
        end
    end
end


--bHaveWeapon 该玩家是否至少有一把枪
--bHandWeapon 该玩家是否处于持枪状态
function HUDWeaponSwitcherPC:UpdateWeaponHUDState(bHaveWeapon,bHandWeapon)
    print("HUDWeaponSwitcherPC >> UpdateWeaponHUDState > bHaveWeapon=",bHaveWeapon,"bHandWeapon=",bHandWeapon)

    local bLocalHandWeapon = bHaveWeapon and bHandWeapon or false
    self.Root:SetRenderOpacity(bHandWeapon and 1 or self.NotWeaponOpacity)

    if bHaveWeapon then
        --有枪
        if bLocalHandWeapon then
            --持枪

            self.ImgUnhandWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.ImgBgNullWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.ImgIconNullWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.ImgIconBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.NullWeaponBulletStyle:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            --空手
            self.ImgUnhandWeapon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible )
            self.ImgBgNullWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.ImgIconNullWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.ImgIconBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.NullWeaponBulletStyle:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        --无枪
        self.ImgUnhandWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ImgBgNullWeapon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.ImgIconNullWeapon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.ImgIconBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.NullWeaponBulletStyle:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

return HUDWeaponSwitcherPC
