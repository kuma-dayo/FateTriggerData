

local ParentClassName = "InGame.BRGame.UI.HUD.PlayerInfoBase"
local PlayerInfoBase = require(ParentClassName)
local MobilePlayerInfo = Class(ParentClassName)

function MobilePlayerInfo:OnInit()
    print("MobilePlayerInfo:OnInit", GetObjectName(self))
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    print("MobilePlayerInfo", ">> OnInit, ", GetObjectName(self), GetObjectName(self.LocalPC), self.LocalPC)
    PlayerInfoBase.OnInit(self)
    
end



function MobilePlayerInfo:OnDestroy()
    print("MobilePlayerInfo:OnDestroy")
    PlayerInfoBase.OnDestroy(self)
end

function MobilePlayerInfo:InitSelfBaseData()
    print("MobilePlayerInfo:InitSelfBaseData")
    self.BarHealthPreview:SetPercent(0)
   
end

function MobilePlayerInfo:InitPlayerStateInfo()
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "White")
    self.BarHealth:SetFillColorAndOpacity(NewColor)
    --暂时没有玩家编号和玩家标记功能

end

--设置健康值
function MobilePlayerInfo:SetHealthInfo(InCurHp,InMaxHp)
    print("MobilePlayerInfo:SetHealthInfo", GetObjectName(self),InCurHp,InMaxHp,self.bPreviewTreat,self.PreviewPercent)
     -- 预览伤害
     if (not self.bPreviewTreat) and self.PreviewPercent then
        local CurPercent = self.BarHealth.Percent
        self.PreviewPercent = (self.PreviewPercent > CurPercent) and self.PreviewPercent or CurPercent
        self.BarHealthPreview:SetPercent(self.PreviewPercent)
        local TmpHealthColors = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "Red")
        self.BarHealthPreview:SetFillColorAndOpacity(TmpHealthColors)
        print("MobilePlayerInfo:SetHealthInfo1",CurPercent,self.PreviewPercent)
    end

    -- 设置当前生命
    local NewPercent = (InMaxHp > 0) and (InCurHp / InMaxHp) or 0
    self.BarHealth:SetPercent(NewPercent)
    local NewTxt = math.floor(InCurHp) .. "/" .. math.floor(InMaxHp)
    self.BarHealth:SetToolTipText(NewTxt)
    print("MobilePlayerInfo", ">> SetHealthInfo, self.PreviewPercent", GetObjectName(self), self.bPreviewTreat,self.PreviewPercent)
    -- 预览治疗生命
    if (self.bPreviewTreat) then
        self:PreviewTreat(true, self.PreviewTreatValue)
    end
end

--[[
    预览血量治疗
    bPreviewTreat:  启用或关闭预显示
    InExtraValue:   预览额外值
]]
function MobilePlayerInfo:PreviewTreat(bPreviewTreat, InExtraValue)
    print("MobilePlayerInfo", ">> PreviewTreat, ", bPreviewTreat, InExtraValue)

    self.bPreviewTreat = bPreviewTreat
    self.PreviewTreatValue = InExtraValue
    if bPreviewTreat then
        --local CurPercent = self.BarHealth:GetDynamicMaterial():K2_GetScalarParameterValue("Progress")
        --self.PreviewPercent = CurPercent + (InExtraValue * 0.01)
        self.PreviewPercent = self.BarHealth.Percent + (InExtraValue * 0.01)
    else
        self.PreviewPercent = 0
    end
    --local NewColor = bPreviewTreat and UIHelper.LinearColor.Green or UIHelper.LinearColor.Red
    local NewColorKey = bPreviewTreat and "Green" or "Red"
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", NewColorKey)
    self.BarHealthPreview:SetFillColorAndOpacity(NewColor)
    self.BarHealthPreview:SetPercent(self.PreviewPercent)
   
end

function MobilePlayerInfo:Tick(MyGeometry, InDeltaTime)
    

     --print("MobilePlayerInfo >> Tick > self.bPreviewTreat:",self.bPreviewTreat)
    if (not self.bPreviewTreat) and (self.PreviewPercent > 0) then
        self.PreviewPercent = self.PreviewPercent - (InDeltaTime * self.PreviewRate)
       
        self.BarHealthPreview:SetPercent(self.PreviewPercent)
        print("MobilePlayerInfo >> Tick > self.PreviewPercent",self.PreviewPercent)
    end
    --self:TickRespawnTime(InDeltaTime)
end

function MobilePlayerInfo:SetBarHealthColor(NewColor)
     
     self.BarHealth:SetFillColorAndOpacity(NewColor)
end

return MobilePlayerInfo