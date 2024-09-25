--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local OBMainReason =Class("Common.Framework.UserWidget")

function OBMainReason:OnInit()
    print("OBMainReason >> OnInit ObjectName=",GetObjectName(self))
	UserWidget.OnInit(self)
end

function OBMainReason:InitData(OBRules,DamageData,EventFlowCfg)

    local IsShowPersonKill = OBRules.HurtedReason:Contains(DamageData.DamageType)
    if IsShowPersonKill == true  then
        --原因-被击杀 
        self.IsManKill = true
        self.KilledReason:SetText(self.KillReasonForMan) ---死亡原因
        local PlayerName = UE.UPlayerExSubsystem.Get(self):GetPlayerNameById(DamageData.CauserPlayerId)
        self.KillerName:SetText(PlayerName) 
        print("OBPlayerListMobile:InitData HudDataCenter detail PlayerName",PlayerName)
        --
        local PawnConfig = UE.FGePawnConfig()
        local  bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(DamageData.CauserHeroId,PawnConfig,self)
        print("OBPlayerListMobile:InitData HudDataCenter detail PawnConfig",PawnConfig.Name)
        if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.SmallIcon) then
            print("OBPlayerListMobile:InitData HudDataCenter detail PawnConfig",PawnConfig.SmallIcon)
            self.DamageIcon:SetBrushFromSoftTexture(PawnConfig.SmallIcon,false)  --伤害图标样式
        end
    else
        -- 原因-意外死亡
        self.KilledReason:SetText(self.KillReasonForOthers) --死亡原因
        local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(EventFlowCfg, DamageData.DamageType.TagName)
        if cfg then
            self.KillerName:SetText(cfg.DetailDesc) 
            self.DamageIcon:SetBrushFromSoftTexture(cfg.IconTexture,false)  --伤害图标样式
            print("OBPlayerListMobile:InitData HudDataCenter detail KilledReason ",cfg.DetailDesc)
        end
    end

    -- 设置伤害值
    local Damage = DamageData.FinalDamage + DamageData.TotalDamage
    local FinalDamage = string.format("%.f", Damage)
    self.Text_TotalHurt:SetText(FinalDamage)  --总伤害
    -- 设置武器图标
    if DamageData.DamageType.TagName == "Damage.Physical.Bullet" then
        -- 先读武器表拿到Icon，然后显示玩家名字
        if DamageData.CauserItemId and DamageData.CauserItemId > 0 then
            local ItemSubTable = BattleUIHelper.SetImageTexture_ItemId(self.DamageWeapon, DamageData.CauserItemId, "FlowImage",
                self.DefaultTextureNone)
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


    --初始化伤害部位的数组
    
    --设置伤害部位数组
    local DamageBodyPartTagsNum = DamageData.DamageBodyPartTags:Num()
    if DamageBodyPartTagsNum > self.TagNum then
        self:BP_CheckTagItem(self.TagNum)
    else
        self:BP_CheckTagItem(DamageBodyPartTagsNum)
    end
    local BodyPartArrayBoxNum = self.BodyPartArrayBox:GetChildrenCount()
    print("OBMainReason:InitData DamageBodyPartTagsNum BodyPartArrayBoxNum",DamageBodyPartTagsNum,BodyPartArrayBoxNum)
    for i =0, BodyPartArrayBoxNum-1 do 
        local tmpImage = self.BodyPartArrayBox:GetChildAt(i)
        tmpImage:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    for i ,v in pairs(DamageData.DamageBodyPartTags) do 
        --如果来的数组数大于现在box的预生成的Image数量，直接返回，不生成
        if i<=BodyPartArrayBoxNum then
            local tmpImage = self.BodyPartArrayBox:GetChildAt(i-1)
            tmpImage:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            print("OBMainReason:InitData DamageBodyPartTags",i-1,v.TagName)
            if v.TagName == "BodyParts.Head" then
                tmpImage:SetBrushTintColor(self.KillHeadColor)
            else
                tmpImage:SetBrushTintColor(self.KillBodyColor)
            end
        end
    end
end

function OBMainReason:OnDestroy()
    print("OBMainReason >> OnDestroy")
	UserWidget.OnDestroy(self)
end
return OBMainReason
