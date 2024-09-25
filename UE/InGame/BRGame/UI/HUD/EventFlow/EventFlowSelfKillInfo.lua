--
-- 战斗界面 - 事件流水(击杀/治疗/复活)
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.12
--

local EventFlowSelfKillInfo = Class("Common.Framework.UserWidget")
local testProfile = require("Common.Utils.InsightProfile")

local Collapsed = UE.ESlateVisibility.Collapsed
local SelfHitTestInvisible = UE.ESlateVisibility.SelfHitTestInvisible

-------------------------------------------- Init/Destroy ------------------------------------
function EventFlowSelfKillInfo:OnInit()

	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.IfPlayAnimation = false
	UserWidget.OnInit(self)
end

function EventFlowSelfKillInfo:OnDestroy()
	UserWidget.OnDestroy(self)
end
-------------------------------------------- Get/Set ------------------------------------

-------------------------------------------- Function ------------------------------------
function EventFlowSelfKillInfo:BPImp_UpdateInfo(InFlowData)
    print("EventFlowSelfKillInfo:BPImp_UpdateInfo")
    -- 击杀队友不显示title和淘汰数目
    self:SetVisibility(SelfHitTestInvisible)
    local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    local TeamExSubsystem = UE.UTeamExSubsystem.Get(self)
    if not TeamExSubsystem:IsTeammateByPSandId(LocalPS, InFlowData.ReceiverPlayerId) then
        -- 默认隐藏
        self.Panel_KillTitle:SetVisibility(SelfHitTestInvisible)
        self:VXE_Killtitle_Icon_In()
        print("EventFlowSelfKillInfo:BPImp_UpdateInfo Icon_In")
    end
    self.KillNum = InFlowData.CauserKillNum
    self:UpdateKillInfoText()
end

function EventFlowSelfKillInfo:OnAnimationFinished(Animation)
    if Animation == self.vx_killtitle_out then
        self.IfPlayAnimation = false
        self.Panel_KillTitle:SetVisibility(Collapsed)
        self:SetVisibility(Collapsed)
    elseif Animation == self.vx_killtitle_In then
        self:VXE_Killtitle_Icon_Out()
    end
end

function EventFlowSelfKillInfo:UpdateKillInfoText()
    local CurNum = self.KillNum or 1
    if CurNum > self.MaxKillNum then
        CurNum = self.MaxKillNum
    end
    if CurNum < 1 then
        CurNum = 1
    end
    local StrValue = "EventFlowKillSelfInfo"..tostring(CurNum)
    local Str = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, StrValue)
    self.Text_KillTitle:SetText(Str)
end

return EventFlowSelfKillInfo