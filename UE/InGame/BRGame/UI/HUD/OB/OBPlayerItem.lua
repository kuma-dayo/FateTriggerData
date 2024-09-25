

local OBPlayerItem = Class("Common.Framework.UserWidget")



function OBPlayerItem:OnInit()
    print("OBPlayerItem:OnInit")
    UserWidget.OnInit(self)
end

function OBPlayerItem:OnDestroy()
	UserWidget.OnDestroy(self)
end

function OBPlayerItem:InitData(InDamage,IsKiller,InDT)
   
    --设置伤害值
    local Damage = InDamage.FinalDamage + InDamage.TotalDamage
    local FinalDamage = string.format("%.f", Damage)
    self.GUITotalDamage:SetText(FinalDamage)
    --设置武器图标
    if InDamage.DamageType.TagName  =="Damage.Physical.Bullet" then
        --先读武器表拿到Icon，然后显示玩家名字
        if InDamage.CauserItemId and InDamage.CauserItemId > 0 then
            local ItemSubTable = BattleUIHelper.SetImageTexture_ItemId(self.DamageIcon, InDamage.CauserItemId, "FlowImage", self.DefaultTextureNone)
            self.DamageIcon:SetVisibility(ItemSubTable and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
    else
        local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(InDT, InDamage.DamageType.TagName)
        if cfg then
            self.DamageIcon:SetBrushFromSoftTexture(cfg.IconTexture, false)
            self.DamageIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    end
    local Texture = UE.UWidgetBlueprintLibrary.GetBrushResourceAsTexture2D(self.DamageIcon.Brush)
    if Texture then
        self.DamageIcon.Brush.ImageSize.X = Texture:Blueprint_GetSizeX()
        self.DamageIcon.Brush.ImageSize.Y = Texture:Blueprint_GetSizeY()
    end
    
    --距离
    if InDamage.LastDamageDistance <=0 then
        self.DamagerDistance:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.DamagerDistance:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local Distance = string.format("%.f", InDamage.LastDamageDistance/100)
        self.DamagerDistance:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromIngameStaticST("SD_OB", "DistanceText"), Distance))
    end
    --如果是击杀者，这的名字不显示，直接显示最上层的
    if IsKiller == true then
        self.PlayerDamageName:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.PlayerDamageName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPC.OriginalPlayerState)
        print("OBPlayerItem:InitData HudDataCenter",HudDataCenter,GetObjectName(HudDataCenter))
        local OBRules = HudDataCenter:GetOBHudDataRules()
        local IsShowPersonKill = OBRules.HurtedReason:Contains(InDamage.DamageType)
        if IsShowPersonKill == true then
            local PlayerName = UE.UPlayerExSubsystem.Get(self):GetPlayerNameById(InDamage.CauserPlayerId)
            self.PlayerDamageName:SetText(PlayerName)
        else
            local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(InDT, InDamage.DamageType.TagName)
            if cfg then
                self.PlayerDamageName:SetText(cfg.DetailDesc)
            end
        end
       
        
    end

    --初始化伤害部位的数组
    
    --设置伤害部位数组
    local DamageBodyPartTagsNum = InDamage.DamageBodyPartTags:Num()
    if DamageBodyPartTagsNum > self.TagNum then
        self:BP_CheckTagItem(self.TagNum)
    else
        self:BP_CheckTagItem(DamageBodyPartTagsNum)
    end
    local BodyPartArrayBoxNum = self.BodyPartArrayBox:GetChildrenCount()
    print("OBPlayerItem:InitData DamageBodyPartTagsNum BodyPartArrayBoxNum",DamageBodyPartTagsNum,BodyPartArrayBoxNum)
    for i =0, BodyPartArrayBoxNum-1 do 
        local tmpImage = self.BodyPartArrayBox:GetChildAt(i)
        tmpImage:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    --[[
    --todo:先不支持动态生成，只支持在precontruct创建好对应的对象，后续再研究
    if BodyPartArrayBoxNum < DamageBodyPartTagsNum then
        for i =1 ,DamageBodyPartTagsNum -BodyPartArrayBoxNum do
        local Object = UE.UWidgetBlueprintLibrary.Create(self,self.ImageClass)
        print("OBPlayerItem:InitData ",Object,GetObjectName(Object))
        Object:SetBrush(self.ImageBursh)
        self.BodyPartArrayBox:AddChild(Object)
        end
    end*/]]--
    for i ,v in pairs(InDamage.DamageBodyPartTags) do 
        --如果来的数组数大于现在box的预生成的Image数量，直接返回，不生成
        if i<=BodyPartArrayBoxNum then
            local tmpImage = self.BodyPartArrayBox:GetChildAt(i-1)
            tmpImage:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            print("OBPlayerItem:InitData DamageBodyPartTags",i-1,v.TagName)
            if v.TagName == "BodyParts.Head" then
                tmpImage:SetBrushTintColor(self.KillHeadColor)
            else
                tmpImage:SetBrushTintColor(self.KillBodyColor)
            end
        end
    end

end





return OBPlayerItem