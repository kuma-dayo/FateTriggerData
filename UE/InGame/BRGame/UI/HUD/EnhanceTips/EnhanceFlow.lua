

local EnhanceFlow = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function EnhanceFlow:OnInit()
    
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    
    UserWidget.OnInit(self)

    MsgHelper:UnregisterList(self, self.MsgList_PS or {})
    self.MsgList_PS = {
  
    {MsgName = GameDefine.MsgCpp.UISync_Update_FreshEnhanceId,     Func = self.OnFreshEnhanceId,  bCppMsg = true,  WatchedObject = self.LocalPS}, 
    
    }
    MsgHelper:RegisterList(self, self.MsgList_PS)
    MsgHelper:UnregisterList(self, self.MsgListGMP or {})
    self.MsgListGMP = {
        { MsgName = "UIEvent.RemoveEnhanceId", Func = self.RemoveEnhanceId,      bCppMsg = false},
    }
    MsgHelper:RegisterList(self, self.MsgListGMP)
    
end

function EnhanceFlow:OnDestroy()
  
	UserWidget.OnDestroy(self)
end


function EnhanceFlow:OnUpdateEnhanceId(InEnhanceId)
   
    print("EnhanceFlow:OnUpdateEnhanceId",InEnhanceId)
    --大概思路：获取到新的触发id后，先去查一下当前busy的里有没有这个id，如果有的话就不管他
    --如果没有这个id的话，去检查一下当前有没有空余的item可用，没有的话直接进队列排队，
    --如果有空余的item，初始化之后add进EnhanceBox，同时设置timer
    --时间到了之后，将busy的id删除，并去问是否有空余的tips待show

    if self.BusyEnhanceId:Find(InEnhanceId) ~= nil or  InEnhanceId==0 then
        --print("EnhanceFlow:OnUpdateEnhanceId1",InEnhanceId)
        return 
    end
    if self.BusyEnhanceId:Length()>= self.MaxBusyNum then
        --print("EnhanceFlow:OnUpdateEnhanceId2",InEnhanceId)
        self.InPoolEnhanceId:Add(InEnhanceId)
        
        return
    end
    --获取表里的数据
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPS)
    if HudDataCenter == nil then
        return 
    end
    local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(HudDataCenter.HudNetDataCenterAsset.EnhanceAttribute, InEnhanceId)
    if cfg then
        --print("EnhanceFlow:OnUpdateEnhanceId4",InEnhanceId)
        --local ChildWidget = self.EnhanceBoxPool:GetChildAt(1)
        local ChildWidget = self.DynamicEnhanceBoxPool:BP_CreateEntryOfClass(self.TargetClass)
        ChildWidget:BP_InitData(cfg.EnhanceName,cfg.EnhanceIconSoft,cfg.EnhanceBgSoft,InEnhanceId,false)
        -- if HudDataCenter.HudNetDataCenterAsset.EnhanceSystemRules.SpecEnhanceIdArray:Contains(InEnhanceId) then
        --     ChildWidget:BP_InitData(cfg.EnhanceName,cfg.EnhanceIconSoft,cfg.EnhanceBgSoft,InEnhanceId,false)
        -- else
        --     ChildWidget:BP_InitData(cfg.EnhanceName,cfg.EnhanceIconSoft,cfg.EnhanceBgSoft,InEnhanceId,true)
        -- end
       
        --self.EnhanceBox:AddChild(ChildWidget)
        self.BusyEnhanceId:Add(InEnhanceId,ChildWidget)
        print("EnhanceFlow:OnUpdateEnhanceId self.BusyEnhanceId:Length ",self.BusyEnhanceId:Length(),ChildWidget)
    end
end

function EnhanceFlow:RemoveEnhanceId(InEnhanceId)
    
    local ChildWidget = self.BusyEnhanceId:Find(InEnhanceId)
    print("EnhanceFlow:RemoveEnhanceId",InEnhanceId,ChildWidget)
    --self.EnhanceBoxPool:AddChild(ChildWidget)
    self.DynamicEnhanceBoxPool:RemoveEntry(ChildWidget)
    self.BusyEnhanceId:Remove(InEnhanceId)
    if self.InPoolEnhanceId:Length()>0 then
        local Id = self.InPoolEnhanceId:GetRef(1)
        --print("EnhanceFlow:RemoveEnhanceId Id",Id,self.InPoolEnhanceId:Length())
        -- for i = 1, self.InPoolEnhanceId:Length() do

        --     print("EnhanceFlow:RemoveEnhanceId InPoolEnhanceId",i,self.InPoolEnhanceId:GetRef(i))
        -- end
        self:OnUpdateEnhanceId(Id)
        self.InPoolEnhanceId:Remove(Id)
        
    end
   
end



function EnhanceFlow:OnFreshEnhanceId()
    print("EnhanceFlow:OnFreshEnhanceId")
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPS)
    if HudDataCenter == nil then
        return 
    end
    --HudDataCenter.SpecEnhanceIdArray
    --先删除不在的
    --直接清空排队的
    self.InPoolEnhanceId:Clear()
    --先判断当前在show的
    for k,v in pairs(self.BusyEnhanceId) do
        print("EnhanceFlow:OnFreshEnhanceId BusyEnhanceId",k,v)
        if not HudDataCenter.SpecEnhanceIdArray:Contains(k) then
            self:RemoveEnhanceId(k)
        end
    end
    
    --再更新现在有的
    for k,v in pairs(HudDataCenter.SpecEnhanceIdArray) do
        print("EnhanceFlow:OnFreshEnhanceId HudDataCenter.SpecEnhanceIdArray",k,v)
        self:OnUpdateEnhanceId(v)
    end
    
    
end


function EnhanceFlow:OnCleanEnhanceId(InEnhanceId)
    print("EnhanceFlow:OnCleanEnhanceId",InEnhanceId)
    if InEnhanceId == 0 then
        return
    end
    self:RemoveEnhanceId(InEnhanceId)
    
end



return EnhanceFlow