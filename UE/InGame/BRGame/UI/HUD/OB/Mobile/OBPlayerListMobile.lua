

local OBPlayerListMobile = Class("Common.Framework.UserWidget")

function OBPlayerListMobile:OnInit()
    print("OBPlayerListMobile:OnInit")
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.LocalPS = self.LocalPC.OriginalPlayerState
    self.IsShowList = false
    self.IsManKill = false
    MsgHelper:UnregisterList(self, self.MsgUIList or {})
    self.MsgUIList = {
       
        { MsgName = "EnhancedInput.OB.RefreshOBPlayerList",	Func = self.RefreshOBPlayerListShow,   bCppMsg = true, WatchedObject = self.LocalPC},
    }
    MsgHelper:RegisterList(self, self.MsgUIList)
    self:InitPlayerStateInfo()
    -- self:InitData()
    --self.OBKillerItem:SetVisibility(UE.ESlateVisibility.Collapsed)
    
end

function OBPlayerListMobile:OnShow()
    self:InitData()
end

function OBPlayerListMobile:OnDestroy()
    MsgHelper:UnregisterList(self, self.MsgUIList)
    self:ResetData()
	UserWidget.OnDestroy(self)

end

function OBPlayerListMobile:ResetData()
    self.IsShowList = false
    self.IsManKill = false
end

function OBPlayerListMobile:InitPlayerStateInfo()
    print("OBPlayerListMobile:InitPlayerStateInfo")
    MsgHelper:UnregisterList(self, self.MsgList or {})
    self.MsgList = {
       
        { MsgName = GameDefine.MsgCpp.UISync_UpdatePlayerDamageList,	Func = self.RefreshOBPlayerList,   bCppMsg = true, WatchedObject = self.LocalPS},
    }
    MsgHelper:RegisterList(self, self.MsgList)
end


function OBPlayerListMobile:InitData()
    self.LocalPS = self.LocalPC.OriginalPlayerState
    print("OBPlayerListMobile:InitData LocalPS",self.LocalPC.OriginalPlayerState,GetObjectName(self.LocalPC.OriginalPlayerState))
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPS)
    print("OBPlayerListMobile:InitData HudDataCenter",HudDataCenter,GetObjectName(HudDataCenter))
    local OBRules = HudDataCenter:GetOBHudDataRules()
    self.ListItemNum = OBRules.OBPlayerListNum
    local PlayerDamageList = HudDataCenter.PlayerDamageList
    local PlayerDamageListNum = PlayerDamageList.DamageDataList:Num()
    local ListItemBoxChildNum = self.ListItemBox:GetChildrenCount()
    local BeginInitItem = (PlayerDamageListNum>self.ListItemNum) and PlayerDamageListNum-self.ListItemNum or 0
    print("OBPlayerListMobile:InitData HudDataCenter DamageDataList",PlayerDamageList.DamageDataList:Num(),ListItemBoxChildNum,BeginInitItem)

    self:HideAllListItem()
    --伤害信息默认读蓝图里的ListItemNum,检查当前box的item数量够不够，不够就生成
    if PlayerDamageListNum> ListItemBoxChildNum  then
        if PlayerDamageListNum >self.ListItemNum then
            self:CreateOBPlayerItem(self.ListItemNum-ListItemBoxChildNum)
        else
            self:CreateOBPlayerItem(PlayerDamageListNum-ListItemBoxChildNum)
        end
        
    end
   
    local Begin =0
    for i,v in pairs(PlayerDamageList.DamageDataList) do 
        print("OBPlayerListMobile:InitData HudDataCenter detail",i,v.CauserPlayerId,v.CauserHeroId,v.CauserItemId,v.DamageType.TagName)
        if i>=BeginInitItem then
            
        if i == 1  then
            -- 主要原因
            self.BP_OBMainHurtItem:InitData(OBRules,v,self.EventFlowCfg)
        else
            local ChildWidget = self.ListItemBox:GetChildAt(Begin)
            ChildWidget:InitData(v,false,self.EventFlowCfg)
            ChildWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            Begin = Begin+1
        end
        
    end
    end
end


function OBPlayerListMobile:RefreshSecondaryReasonUI(Widget)
    --次要原因

end


function OBPlayerListMobile:RefreshOBPlayerListShow()
    
    self.IsShowList = not self.IsShowList
    print("OBPlayerListMobile:RefreshOBPlayerListShow",self.IsShowList)
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

function OBPlayerListMobile:RefreshOBPlayerList()
    print("OBPlayerListMobile:RefreshOBPlayerList")
    self:InitData()
end

function OBPlayerListMobile:CreateOBPlayerItem(InNum)
    print("OBPlayerListMobile:CreateOBPlayerItem InNum",InNum)
    for i=1,InNum do 
        local ChildWidget = UE.UGUIUserWidget.Create(self.LocalPC, self.ListWidgetType, self.LocalPC)
        self.ListItemBox:AddChild(ChildWidget)
        ChildWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    print("OBPlayerListMobile:CreateOBPlayerItem NowListNum",self.ListItemBox:GetChildrenCount())
end

function OBPlayerListMobile:HideAllListItem()
   
    local ListItemBoxChildNum = self.ListItemBox:GetChildrenCount()
    for i=0 ,ListItemBoxChildNum-1 do 
        local Item = self.ListItemBox:GetChildAt(i)
        Item:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    print("OBPlayerListMobile:HideAllListItem ListItemBoxChildNum",ListItemBoxChildNum)
end

return OBPlayerListMobile