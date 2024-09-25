--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local OBSecondaryReason = Class("Common.Framework.UserWidget")

function OBSecondaryReason:OnInit()
    print("OBSecondaryReason >> OnInit ObjectName=", GetObjectName(self))
    UserWidget.OnInit(self)
end

function OBSecondaryReason:InitData(DamageData, EventFlowCfg)

    -- 设置伤害值
    local Damage = DamageData.FinalDamage + DamageData.TotalDamage
    local FinalDamage = string.format("%.f", Damage)
    self.Text_TotalHurt:SetText(FinalDamage) -- 总伤害

    -- 设置武器图标
    if DamageData.DamageType.TagName == "Damage.Physical.Bullet" then
        -- 先读武器表拿到Icon，然后显示玩家名字
        if DamageData.CauserItemId and DamageData.CauserItemId > 0 then
            local ItemSubTable = BattleUIHelper.SetImageTexture_ItemId(self.DamageIcon, DamageData.CauserItemId,
                "FlowImage", self.DefaultTextureNone)
            self.DamageWeapon:SetVisibility(ItemSubTable and UE.ESlateVisibility.SelfHitTestInvisible or
                                                UE.ESlateVisibility.Collapsed)
        end
    else
        local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(EventFlowCfg, DamageData.DamageType.TagName)
        if cfg then
            self.DamageWeapon:SetBrushFromSoftTexture(cfg.IconTexture, false)
            self.DamageWeapon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end

    end

    -- 距离
    if DamageData.LastDamageDistance <= 0 then
        self.HB_Distance:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.HB_Distance:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local Distance = string.format("%.f", DamageData.LastDamageDistance / 100)
        self.Text_Distance:SetText(Distance)
    end

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPC.OriginalPlayerState)
    print("OBSecondaryReason:InitData HudDataCenter", HudDataCenter, GetObjectName(HudDataCenter))
    local OBRules = HudDataCenter:GetOBHudDataRules()
    local IsShowPersonKill = OBRules.HurtedReason:Contains(DamageData.DamageType)
    if IsShowPersonKill == true then
        local PlayerName = UE.UPlayerExSubsystem.Get(self):GetPlayerNameById(DamageData.CauserPlayerId)
        self.PlayerDamageName:SetText(PlayerName)
    else
        local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(EventFlowCfg, DamageData.DamageType.TagName)
        if cfg then
            self.PlayerDamageName:SetText(cfg.DetailDesc)
        end
    end

    -- 初始化伤害部位的数组

    -- 设置伤害部位数组
    local DamageBodyPartTagsNum = DamageData.DamageBodyPartTags:Num()
    if DamageBodyPartTagsNum > self.TagNum then
        self:BP_CheckTagItem(self.TagNum)
    else
        self:BP_CheckTagItem(DamageBodyPartTagsNum)
    end
    local BodyPartArrayBoxNum = self.BodyPartArrayBox:GetChildrenCount()
    print("OBSecondaryReason:InitData DamageBodyPartTagsNum BodyPartArrayBoxNum", DamageBodyPartTagsNum,
        BodyPartArrayBoxNum)
    for i = 0, BodyPartArrayBoxNum - 1 do
        local tmpImage = self.BodyPartArrayBox:GetChildAt(i)
        tmpImage:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    for i, v in pairs(DamageData.DamageBodyPartTags) do
        -- 如果来的数组数大于现在box的预生成的Image数量，直接返回，不生成
        if i <= BodyPartArrayBoxNum then
            local tmpImage = self.BodyPartArrayBox:GetChildAt(i - 1)
            tmpImage:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            print("OBSecondaryReason:InitData DamageBodyPartTags", i - 1, v.TagName)
            if v.TagName == "BodyParts.Head" then
                tmpImage:SetBrushTintColor(self.KillHeadColor)
            else
                tmpImage:SetBrushTintColor(self.KillBodyColor)
            end
        end
    end
end

function OBSecondaryReason:OnDestroy()
    print("OBSecondaryReason >> OnDestroy")
    UserWidget.OnDestroy(self)
end
return OBSecondaryReason
