require "UnLua"

local PotionRecommendManager = Class()


function PotionRecommendManager:DoRecommend()
    print("[PotionRecommend] lua=[PotionRecommendManager:DoRecommend] Called.")
    local TempIsRecommend = self:IsRecommend(self.CurrentMessagePlayerState, self.CurrentMessageInItemId)
    if not TempIsRecommend then
        print("[PotionRecommend] lua=[PotionRecommendManager:DoRecommend] TempIsRecommend is false, return.")
    end

    self:SituationRecommend()
end

function PotionRecommendManager:DefaultRecommend()
    --local SwitchItemIdList = UE.TArray(0)
    --SwitchItemIdList:Add(130000003) -- 小双25,2s
    --SwitchItemIdList:Add(130000004) -- 中双100,5s
    --SwitchItemIdList:Add(130000005) -- 凤凰双全,8s
    --self:ChangeSlotByItemIdArray(self.CurrentMessagePlayerState, SwitchItemIdList)
end

function PotionRecommendManager:SituationRecommend()
    print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] Called.")

    -- 生命值，生命最大值
    local CurrentHealth, CurrentMaxHealth = self:GetHealthInfo(self.CurrentMessagePlayerState)
    -- 护甲值，护甲最大值
    local IsExistArmor,CurrentArmor,CurrentMaxArmor = self:GetArmorInfo(self.CurrentMessagePlayerState)
    -- 生命已满状态
    local CurrentHpIsMax = CurrentHealth == CurrentMaxHealth
    -- 护甲已满状态
    local CurrentApIsMax = false
    if IsExistArmor then
        CurrentApIsMax = CurrentArmor == CurrentMaxArmor
    else
        CurrentApIsMax = true
    end
    -- 生命损失值
    local HealthDiff = CurrentMaxHealth - CurrentHealth
    -- 护甲损失值
    local ArmorDiff = 0
    if IsExistArmor then
        ArmorDiff = CurrentMaxArmor - CurrentArmor
    else
        ArmorDiff = 0
    end

    print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] CurrentHealth and CurrentMaxHealth:", tostring(CurrentHealth),tostring(CurrentMaxHealth))
    print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] CurrentArmor and CurrentMaxArmor:", tostring(CurrentArmor),tostring(CurrentMaxArmor))
    print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] CurrentHpIsMax:", tostring(CurrentHpIsMax))
    print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] CurrentApIsMax:", tostring(CurrentHpIsMax))
    print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] HealthDiff:", tostring(HealthDiff))
    print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] ArmorDiff:", tostring(ArmorDiff))

    -- 状态判断1
    if CurrentHpIsMax and CurrentApIsMax then
        print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] ChangeSlotSituation_1")
        self:ChangeSlotSituation_1()
        return
    end

    -- 状态判断2
    if (HealthDiff + ArmorDiff <= 50) then
        print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] ChangeSlotSituation_2")
        self:ChangeSlotSituation_2()
        return
    end

    -- 状态判断3
    if (HealthDiff + ArmorDiff > 50) and (HealthDiff + ArmorDiff <= 125) then
        print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] ChangeSlotSituation_3")
        self:ChangeSlotSituation_3()
        return
    end

    -- 状态判断4
    if (HealthDiff + ArmorDiff > 125) then
        print("[PotionRecommend] lua=[PotionRecommendManager:SituationRecommend] ChangeSlotSituation_4")
        self:ChangeSlotSituation_4()
        return
    end

end

function PotionRecommendManager:ChangeSlotSituation_1()
    local SwitchItemIdList = UE.TArray(0)
    SwitchItemIdList:Add(130000003) -- 小双25
    SwitchItemIdList:Add(130000004) -- 中双100
    SwitchItemIdList:Add(130000005) -- 凤凰双全
    self:ChangeSlotByItemIdArray(self.CurrentMessagePlayerState, SwitchItemIdList)
end

function PotionRecommendManager:ChangeSlotSituation_2()
    local SwitchItemIdList = UE.TArray(0)
    SwitchItemIdList:Add(130000003) -- 小双25
    SwitchItemIdList:Add(130000004) -- 中双100
    SwitchItemIdList:Add(130000005) -- 凤凰双全
    self:ChangeSlotByItemIdArray(self.CurrentMessagePlayerState, SwitchItemIdList)
end

function PotionRecommendManager:ChangeSlotSituation_3()
    local SwitchItemIdList = UE.TArray(0)
    SwitchItemIdList:Add(130000004) -- 中双100
    SwitchItemIdList:Add(130000003) -- 小双25
    SwitchItemIdList:Add(130000005) -- 凤凰双全
    self:ChangeSlotByItemIdArray(self.CurrentMessagePlayerState, SwitchItemIdList)
end


function PotionRecommendManager:ChangeSlotSituation_4()
    local SwitchItemIdList = UE.TArray(0)
    SwitchItemIdList:Add(130000005) -- 凤凰双全
    SwitchItemIdList:Add(130000003) -- 小双25
    SwitchItemIdList:Add(130000004) -- 中双100
    self:ChangeSlotByItemIdArray(self.CurrentMessagePlayerState, SwitchItemIdList)
end

return PotionRecommendManager
