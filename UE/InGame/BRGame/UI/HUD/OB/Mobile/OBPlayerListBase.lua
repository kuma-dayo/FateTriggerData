

local OBPlayerListBase = Class("Common.Framework.UserWidget")

function OBPlayerListBase:OnInit()
    print("OBPlayerListBase:OnInit")
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.LocalPS = self.LocalPC.OriginalPlayerState
    self.IsShowList = false
    self.IsManKill = false
    MsgHelper:UnregisterList(self, self.MsgUIList or {})
    self.MsgUIList = {
       
        { MsgName = "EnhancedInput.OB.RefreshOBPlayerList",	Func = self.RefreshOBPlayerListShow,   bCppMsg = true, WatchedObject = self.LocalPC},
    }
    MsgHelper:RegisterList(self, self.MsgUIList)
    self.GUIItemBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:InitPlayerStateInfo()
    self:InitData()
    self.Open_Input:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.OBKillerItem:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.NameSwitcher:SetActiveWidgetIndex(0)
    
end

function OBPlayerListBase:OnDestroy()
    MsgHelper:UnregisterList(self, self.MsgUIList)
    self:ResetData()
	UserWidget.OnDestroy(self)

end

function OBPlayerListBase:ResetData()
    self.IsShowList = false
    self.IsManKill = false
end

function OBPlayerListBase:InitPlayerStateInfo()
    print("OBPlayerListBase:InitPlayerStateInfo")
    MsgHelper:UnregisterList(self, self.MsgList or {})
    self.MsgList = {
       
        { MsgName = GameDefine.MsgCpp.UISync_UpdatePlayerDamageList,	Func = self.RefreshOBPlayerList,   bCppMsg = true, WatchedObject = self.LocalPS},
    }
    MsgHelper:RegisterList(self, self.MsgList)
end


function OBPlayerListBase:InitData()
    self.LocalPS = self.LocalPC.OriginalPlayerState
    print("OBPlayerListBase:InitData LocalPS",self.LocalPC.OriginalPlayerState,GetObjectName(self.LocalPC.OriginalPlayerState))
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPS)
    print("OBPlayerListBase:InitData HudDataCenter",HudDataCenter,GetObjectName(HudDataCenter))
    local OBRules = HudDataCenter:GetOBHudDataRules()
    self.ListItemNum = OBRules.OBPlayerListNum
    local PlayerDamageList = HudDataCenter.PlayerDamageList
    local PlayerDamageListNum = PlayerDamageList.DamageDataList:Num()
    local ListItemBoxChildNum = self.ListItemBox:GetChildrenCount()
    local BeginInitItem = (PlayerDamageListNum>self.ListItemNum) and PlayerDamageListNum-self.ListItemNum or 0
    print("OBPlayerListBase:InitData HudDataCenter DamageDataList",PlayerDamageList.DamageDataList:Num(),ListItemBoxChildNum,BeginInitItem)
    self:HideAllListItem()
    --伤害信息默认读蓝图里的ListItemNum,检查当前box的item数量够不够，不够就生成
    if PlayerDamageListNum> ListItemBoxChildNum  then
        if PlayerDamageListNum >self.ListItemNum then
            self:CreateOBPlayerItem(self.ListItemNum-ListItemBoxChildNum)
        else
            self:CreateOBPlayerItem(PlayerDamageListNum-ListItemBoxChildNum)
        end
        
    end
   
    --self.ListItemBox:ClearChildren()
    local Begin =0
    for i,v in pairs(PlayerDamageList.DamageDataList) do 
        print("OBPlayerListBase:InitData HudDataCenter detail",i,v.CauserPlayerId,v.CauserHeroId,v.CauserItemId,v.DamageType.TagName)
        if i>=BeginInitItem then
            
        if i == 1  then
            local ChildWidget = self.OBKillerItem
            --设置最上面的Item的数据
            --设置名字
            local IsShowPersonKill = OBRules.HurtedReason:Contains(v.DamageType)
            if IsShowPersonKill == true  then
            --if v.DamageType.TagName  == "Damage.Physical.Bullet" then
                self.IsManKill = true
                --self.KilledReason:SetText(StringUtil.Format("击杀者"))
                self.KilledReason:SetText(self.KillReasonForMan)
                local PlayerName = UE.UPlayerExSubsystem.Get(self):GetPlayerNameById(v.CauserPlayerId)
                self.KillerName:SetText(PlayerName)
                --self.KillerName:SetText(v.CauserPlayerId)
                print("OBPlayerListBase:InitData HudDataCenter detail PlayerName",PlayerName)
                --
                local PawnConfig = UE.FGePawnConfig()
                local  bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(v.CauserHeroId,PawnConfig,self)
                print("OBPlayerListBase:InitData HudDataCenter detail PawnConfig",PawnConfig.Name)
                if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.SmallIcon) then
                    print("OBPlayerListBase:InitData HudDataCenter detail PawnConfig",PawnConfig.SmallIcon)
                    self.DamageIcon:SetBrushFromSoftTexture(PawnConfig.SmallIcon, false)
                end
                --ChildWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            else
                --self.KilledReason:SetText(StringUtil.Format("淘汰原因"))
                self.KilledReason:SetText(self.KillReasonForOthers)
                local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.EventFlowCfg, v.DamageType.TagName)
                if cfg then
                    self.KillerName:SetText(cfg.DetailDesc)
                    self.DamageIcon:SetBrushFromSoftTexture(cfg.IconTexture, false)
                    print("OBPlayerListBase:InitData HudDataCenter detail KilledReason ",cfg.DetailDesc)
                end

            end

            ChildWidget:InitData(v,true,self.EventFlowCfg)
        else
            local ChildWidget = self.ListItemBox:GetChildAt(Begin)
            ChildWidget:InitData(v,false,self.EventFlowCfg)
            ChildWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            Begin = Begin+1
        end
        
    end
    end
end


function OBPlayerListBase:RefreshOBPlayerListShow()
    
    self.IsShowList = not self.IsShowList
    print("OBPlayerListBase:RefreshOBPlayerListShow",self.IsShowList)
    if self.IsShowList == true then
        self.GUIItemBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.NameSwitcher:SetActiveWidgetIndex(1)
        self.Open_Input:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if self.IsManKill == true then
            self.OBKillerItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    else
        self.GUIItemBox:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.NameSwitcher:SetActiveWidgetIndex(0)
        self.Open_Input:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.OBKillerItem:SetVisibility(UE.ESlateVisibility.Collapsed)
        
    end
end

function OBPlayerListBase:RefreshOBPlayerList()
    print("OBPlayerListBase:RefreshOBPlayerList")
    self:InitData()
end

function OBPlayerListBase:CreateOBPlayerItem(InNum)
    print("OBPlayerListBase:CreateOBPlayerItem InNum",InNum)
    for i=1,InNum do 
        local ChildWidget = UE.UGUIUserWidget.Create(self.LocalPC, self.ListWidgetType, self.LocalPC)
        self.ListItemBox:AddChild(ChildWidget)
        ChildWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    print("OBPlayerListBase:CreateOBPlayerItem NowListNum",self.ListItemBox:GetChildrenCount())
end

function OBPlayerListBase:HideAllListItem()
   
    local ListItemBoxChildNum = self.ListItemBox:GetChildrenCount()
    for i=0 ,ListItemBoxChildNum-1 do 
        local Item = self.ListItemBox:GetChildAt(i)
        Item:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    print("OBPlayerListBase:HideAllListItem ListItemBoxChildNum",ListItemBoxChildNum)
end

return OBPlayerListBase