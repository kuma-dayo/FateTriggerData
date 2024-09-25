--
-- 被观战玩家 - 对局信息(击杀数/击倒数/救援数)
--
-- @COMPANY	ByteDance
-- @AUTHOR	王泽平
-- @DATE	2023.05.17

--当前被观战玩家的击杀数 击倒数 救援数 
--切换被观战角色重新刷新信息
local OBWatchGame = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function OBWatchGame:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.GameState = UE.UGameplayStatics.GetGameState(self)
    self.LocalPS = self.LocalPC.OriginalPlayerState --观战玩家（死亡的）
    self.ViewPS = self.LocalPC.PlayerState  --被观战玩家（存活的）

    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.ViewPlayerBattleRecord, Func = self.OnViewPlayerBattleRecord,      bCppMsg = true, WatchedObject =  self.LocalPS },
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,	  Func = self.OnUpdateLocalPCPS,   bCppMsg = true, WatchedObject = self.LocalPC },
	}
    self:OnUpdateOBInfo()
    self:InitData()
    self.WatchPlayer = nil
    self:RefreshEyeUI()



	UserWidget.OnInit(self)
    print("OBWatchGame >> OnInit")

end

function OBWatchGame:OnDestroy()
    print("OBWatchGame >> OnDestroy")
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function OBWatchGame:InitData()
    print("OBWatchGame >> InitData")
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPC.OriginalPlayerState)
    self:SetKillKnockDownAssist(HudDataCenter.ViewPlayerBattleRecord)

end



function OBWatchGame:OnUpdateOBInfo()
    self.GUIKill:SetText("?")
    self.GUIAssist:SetText("?")
    self.GUIKnockdown:SetText("?")
end



-- 获取/设置击杀 助攻 击倒信息，
-- PlayerBattleRecord 结构体 : PlayerId玩家id、KillDeath击杀、KnockDown击倒、PlayerAssist助攻、PlayerDamage伤害输出
function OBWatchGame:SetKillKnockDownAssist(PlayerBattleRecord)
    if PlayerBattleRecord then
        local PlayerId = PlayerBattleRecord.PlayerId
        local KillDeath =  PlayerBattleRecord.KillDeath
        local KnockDown = PlayerBattleRecord.KnockDown
        local PlayerAssist = PlayerBattleRecord.PlayerAssist

        print("OBWatchGame >> SetKillKnockDownAssist > PlayerId=",PlayerId)
        print("OBWatchGame >> SetKillKnockDownAssist > KillDeath=",KillDeath)
        print("OBWatchGame >> SetKillKnockDownAssist > KnockDown=",KnockDown)
        print("OBWatchGame >> SetKillKnockDownAssist > PlayerAssist=",PlayerAssist)

        if KillDeath then
            self.GUIKill:SetText(tostring(KillDeath))
        end
        if KnockDown then
            self.GUIKnockdown:SetText(tostring(KnockDown))
        end
        if PlayerAssist then
            self.GUIAssist:SetText(tostring(PlayerAssist))
        end
    end
end

--刷新图标背景色
function OBWatchGame:RefreshEyeUI()
    if not self.LocalPS or not self.ViewPS then
        return
    end
    --观战玩家队伍ID（死亡的）
    local SlefTeamId = self.LocalPS:GetTeamInfo_Id()
    --被观战玩家队伍ID（存活的）
    local ViewTeamId = self.ViewPS:GetTeamInfo_Id()
    if SlefTeamId == nil or ViewTeamId == nil then
        return
    end
    print("OBWatchGame >> SlefTeamId=", SlefTeamId, ",ViewTeamId=", ViewTeamId)

    if SlefTeamId == ViewTeamId then
        --是队友
        self.SW_GuanZhanBg:SetActiveWidgetIndex(0)     --显示原谅色小眼睛
        self.GUIImage_RightResurrection:SetColorAndOpacity(self.FriendlyColor)
        self.GUIImage_LeftResurrection:SetColorAndOpacity(self.FriendlyColor)
    else
        --是敌人
        self.SW_GuanZhanBg:SetActiveWidgetIndex(1)     --显示红色小眼睛
        self.GUIImage_RightResurrection:SetColorAndOpacity(self.EmenyColor)
        self.GUIImage_LeftResurrection:SetColorAndOpacity(self.EmenyColor)
    end
end
-------------------------------------------- Callable ------------------------------------


--[GMP消息]被观战玩家（存活的）有击杀、助攻、救援事件会触发
function OBWatchGame:OnViewPlayerBattleRecord(PlayerBattleRecord)
    print("[GMP] OBWatchGame >> OnBattleRecord")
    self:SetKillKnockDownAssist(PlayerBattleRecord)

end

--[GMP消息]每次切换被观战者（存活的）后触发
function OBWatchGame:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    --更新存活被观战者
    print("OBWatchGame:OnUpdateLocalPCPS",GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
    if self.LocalPC == InLocalPC then
        if InNewPS then
            self.ViewPS = InNewPS
            --设置击杀 助攻 击倒
            local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPC.OriginalPlayerState)
            self:SetKillKnockDownAssist(HudDataCenter.ViewPlayerBattleRecord)
            --刷新眼睛图标背景色
            self:RefreshEyeUI()
        end
	end


end


return OBWatchGame

