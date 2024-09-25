require "UnLua"

local Buff = Class()

function Buff:Initialize(Initializer)
    self.AccumulatedTime = 0
    self.CacheMaxHealth = 0
    self.CacheHealMax = 0
    --print('Init Heal Pack')
end

function Buff:K2_OnBuffAdded()
    --print('Health pack script loaded')
    local Character = self:GetOwner()
    print(Character)
    if Character ~= nil then
        local CurHealth, MaxHealth, bIsValid = UE.UPlayerStatics.GetHealthData(Character.PlayerState)
        self.CacheMaxHealth = MaxHealth
        if self.MaximumPercent > 0 and self.MaximumAbsolute <= 0 then
            self.CacheHealMax = self.MaximumPercent * 0.01 * self.CacheMaxHealth
        elseif self.MaximumAbsolute > 0 and self.MaximumPercent <= 0 then
            self.CacheHealMax = self.MaximumAbsolute
        elseif self.MaximumAbsolute > 0 and self.MaximumPercent > 0 then
            self.CacheHealMax = math.min(self.MaximumAbsolute, self.MaximumPercent * 0.01 * self.CacheMaxHealth)
        else
            self.CacheHealMax = 99999
        end

        self:DoHealing()
    end
end

function Buff:DoHealing()
    local Character = self:GetOwner()
    if Character == nil then
        return 
    end
    local amountToHeal = 0
    local CurHealth, MaxHealth, bIsValid = UE.UPlayerStatics.GetHealthData(Character.PlayerState)
    amountToHeal = self.CacheMaxHealth * self.HealPercent * 0.01 + self.HealAbsolute
    if amountToHeal + CurHealth > self.CacheHealMax then
        amountToHeal = self.CacheHealMax - CurHealth
    end
    self:HealViaDamageManager(amountToHeal)
    print('Player health healed ', amountToHeal)
end

function Buff:K2_TickBuff(DeltaTime)
    --self.AccumulatedTime = self.AccumulatedTime + DeltaTime
    --if self.AccumulatedTime > self.Interval then
    --    self:DoHealing()
    --    self.AccumulatedTime = 0
    --end
    self.Overridden.K2_TickBuff(self, DeltaTime)
end

return Buff