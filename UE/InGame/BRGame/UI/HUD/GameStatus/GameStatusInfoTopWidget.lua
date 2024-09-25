
local ParentClassName = "Common.Framework.UserWidget"
local UserWidget = require(ParentClassName)
local GameStatusInfoTopWidget = Class(ParentClassName)


function GameStatusInfoTopWidget:OnInit()
    print("GameStatusInfoTopWidget:OnInit xyzpring")
    self:InitView()


    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bNetworkStatusDisplay",{ self, self.UpdatebNetworkStatusDisplay})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("Ping",{ self, self.UpdatePing })
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bPing",{ self, self.UpdatebPing})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("FPS",{ self,self.UpdateFPS})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bFPS",{ self, self.UpdatebFPS})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("DsFPS",{self, self.UpdateDsFPS})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bDsFPS",{self,self.UpdatebDsFPS})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("ClientTime",{self,self.UpdateClientTime})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bClientTime",{self,self.UpdatebClientTime})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("OutBytesPerSecond",{self,self.UpdateOutBytesPerSecond})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bOutBytesPerSecond",{self,self.UpdatebOutBytesPerSecond})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("OutPacketsPerSecond",{self,self.UpdateOutPacketsPerSecond})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bOutPacketsPerSecond",{self,self.UpdatebOutPacketsPerSecond})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("OutLossPercentage",{self,self.UpdateOutLossPercentage})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bOutLossPercentage",{self,self.UpdatebOutLossPercentage})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("InBytesPerSecond",{self,self.UpdateInBytesPerSecond})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bInBytesPerSecond",{self,self.UpdatebInBytesPerSecond})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("InPacketsPerSecond",{self,self.UpdateInPacketsPerSecond})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bInPacketsPerSecond",{self,self.UpdatebInPacketsPerSecond})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("InLossPercentage",{self,self.UpdateInLossPercentage})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bInLossPercentage",{self,self.UpdatebInLossPercentage})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("NetworkBlockingQueue",{self,self.UpdateNetworkBlockingQueue})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bNetworkBlockingQueue",{self,self.UpdatebNetworkBlockingQueue})

    UserWidget.OnInit(self)
end

function GameStatusInfoTopWidget:OnDestroy()
    print("GameStatusInfoTopWidget:OnDestroy")

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bNetworkStatusDisplay",{ self, self.UpdatebNetworkStatusDisplay})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("Ping",{ self, self.UpdatePing })
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bPing",{self,self.UpdatebPing})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("FPS",{self,self.UpdateFPS})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bFPS",{self,self.UpdatebFPS})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("DsFPS",{self,self.UpdateDsFPS})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bDsFPS",{self,self.UpdatebDsFPS})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("ClientTime",{self,self.UpdateClientTime})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bClientTime",{self,self.UpdatebClientTime})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("OutBytesPerSecond",{self,self.UpdateOutBytesPerSecond})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bOutBytesPerSecond",{self,self.UpdatebOutBytesPerSecond})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("OutPacketsPerSecond",{self,self.UpdateOutPacketsPerSecond})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bOutPacketsPerSecond",{self,self.UpdatebOutPacketsPerSecond})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("OutLossPercentage",{self,self.UpdateOutLossPercentage})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bOutLossPercentage",{self,self.UpdatebOutLossPercentage})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("InBytesPerSecond",{self,self.UpdateInBytesPerSecond})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bInBytesPerSecond",{self,self.UpdatebInBytesPerSecond})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("InPacketsPerSecond",{self,self.UpdateInPacketsPerSecond})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bInPacketsPerSecond",{self,self.UpdatebInPacketsPerSecond})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("InLossPercentage",{self,self.UpdateInLossPercentage})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bInLossPercentage",{self,self.UpdatebInLossPercentage})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("NetworkBlockingQueue",{self,self.UpdateNetworkBlockingQueue})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bNetworkBlockingQueue",{self,self.UpdatebNetworkBlockingQueue})

    UserWidget.OnDestroy(self)
end

function GameStatusInfoTopWidget:InitView()

    -- --根据云策和阳哥要求，设置项隐藏这几个选项，shipping包强制隐藏这几项的网络状态

    self:UpdatebNetworkStatusDisplay(self.GameStatusInfoViewModel,nil)

    self:UpdatebPing(self.GameStatusInfoViewModel,nil)
    self:UpdatePing(self.GameStatusInfoViewModel,nil)

    self:UpdatebFPS(self.GameStatusInfoViewModel,nil)
    self:UpdateFPS(self.GameStatusInfoViewModel,nil)

    self:UpdatebDsFPS(self.GameStatusInfoViewModel,nil)
    self:UpdateDsFPS(self.GameStatusInfoViewModel,nil)

    self:UpdatebClientTime(self.GameStatusInfoViewModel,nil)
    self:UpdateClientTime(self.GameStatusInfoViewModel,nil)

    self:UpdatebOutBytesPerSecond(self.GameStatusInfoViewModel,nil)
    self:UpdateOutBytesPerSecond(self.GameStatusInfoViewModel,nil)

    self:UpdatebOutPacketsPerSecond(self.GameStatusInfoViewModel,nil)
    self:UpdateOutPacketsPerSecond(self.GameStatusInfoViewModel,nil)

    self:UpdatebOutLossPercentage(self.GameStatusInfoViewModel,nil)
    self:UpdateOutLossPercentage(self.GameStatusInfoViewModel,nil)

    self:UpdatebInBytesPerSecond(self.GameStatusInfoViewModel,nil)
    self:UpdateInBytesPerSecond(self.GameStatusInfoViewModel,nil)

    self:UpdatebInPacketsPerSecond(self.GameStatusInfoViewModel,nil)
    self:UpdateInPacketsPerSecond(self.GameStatusInfoViewModel,nil)

    self:UpdatebInLossPercentage(self.GameStatusInfoViewModel,nil)
    self:UpdateInLossPercentage(self.GameStatusInfoViewModel,nil)

    self:UpdatebNetworkBlockingQueue(self.GameStatusInfoViewModel,nil)
    self:UpdateNetworkBlockingQueue(self.GameStatusInfoViewModel,nil)



    print("GameStatusInfoTopWidget:InitView")
end

function GameStatusInfoTopWidget:UpdatebNetworkStatusDisplay(vm, fieldID)
    
end

--网络延迟Ping
function GameStatusInfoTopWidget:UpdatePing(vm, fieldID)
    if vm then
        self.Text_Ping:SetText(math.floor(vm.Ping))
    end
end

function GameStatusInfoTopWidget:UpdatebPing(vm, fieldID)
    --local IsShipping = CommonUtil.IsShipping()
    self.HV_Ping:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end


--客户端FPS
function GameStatusInfoTopWidget:UpdateFPS(vm, fieldID)
    if vm then
        self.Text_FPS:SetText(tostring(vm.FPS))
    end
end

function GameStatusInfoTopWidget:UpdatebFPS(vm, fieldID)
    self.HV_FPS:SetVisibility(vm.bFPS and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--Ds FPS
function GameStatusInfoTopWidget:UpdateDsFPS(vm, fieldID)
    if vm then
        if self.Text_DsFPS then self.Text_DsFPS:SetText(tostring(vm.DsFPS)) end
    end
end

function GameStatusInfoTopWidget:UpdatebDsFPS(vm, fieldID)
    if self.HV_DsFPS then
        local IsShipping = CommonUtil.IsShipping()
        print("GameStatusInfoTopWidget:UpdatebDsFPS [IsShipping]=",IsShipping)
        if IsShipping then
            self.HV_DsFPS:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.HV_DsFPS:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end

    end
end

--上传速度 kb/s
function GameStatusInfoTopWidget:UpdateOutBytesPerSecond(vm, fieldID)
    if vm then
        self.Text_Send:SetText(StringUtil.Format("{0}KB/s",vm.OutBytesPerSecond))
    end
end

function GameStatusInfoTopWidget:UpdatebOutBytesPerSecond(vm, fieldID)
    self.HV_Send:SetVisibility(vm.bOutBytesPerSecond and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function GameStatusInfoTopWidget:UpdateOutPacketsPerSecond(vm, fieldID)
    if vm then
        self.Text_Speed1:SetText(StringUtil.Format("{0}pkt/s",vm.OutPacketsPerSecond))
    end
end

function GameStatusInfoTopWidget:UpdatebOutPacketsPerSecond(vm, fieldID)
    self.Text_Speed1:SetVisibility(vm.bOutPacketsPerSecond and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end


function GameStatusInfoTopWidget:UpdateOutLossPercentage(vm, fieldID)
    if vm then
        self.Text_Pkt1:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_1"),vm.OutLossPercentage))
    end
end

function GameStatusInfoTopWidget:UpdatebOutLossPercentage(vm, fieldID)
    self.ReceivePacketsLoss:SetVisibility(vm.bOutLossPercentage and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function GameStatusInfoTopWidget:UpdateInBytesPerSecond(vm, fieldID)
    if vm then
        self.Text_Download:SetText(StringUtil.Format("{0}KB/s",vm.InBytesPerSecond))
    end
end

function GameStatusInfoTopWidget:UpdatebInBytesPerSecond(vm, fieldID)
    self.HV_Download:SetVisibility(vm.bInBytesPerSecond  and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--接收包速率
function GameStatusInfoTopWidget:UpdateInPacketsPerSecond(vm, fieldID)
    if vm then
        self.Text_Speed2:SetText(StringUtil.Format("{0}pkt/s",vm.InPacketsPerSecond))
    end
end

function GameStatusInfoTopWidget:UpdatebInPacketsPerSecond(vm, fieldID)
    self.Text_Speed2:SetVisibility(vm.bInPacketsPerSecond and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--接收丢包率
function GameStatusInfoTopWidget:UpdateInLossPercentage(vm, fieldID)
    if vm then
        if self.Text_Pkt2 then self.Text_Pkt2:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_1"),vm.InLossPercentage)) end
    end
end

--接收丢包率
function GameStatusInfoTopWidget:UpdatebInLossPercentage(vm, fieldID)
    self.SendPacketsLoss:SetVisibility(vm.bInLossPercentage  and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function GameStatusInfoTopWidget:UpdateClientTime(vm, fieldID)
    if self.Text_ClientTime then
        self.Text_ClientTime:SetText(tostring(vm.ClientTime))
    end
end


function GameStatusInfoTopWidget:UpdatebClientTime(vm, fieldID)
    if self.HV_ClientTime then
        --local IsShipping = CommonUtil.IsShipping()
        self.HV_ClientTime:SetVisibility(vm.bClientTime and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
end

function GameStatusInfoTopWidget:UpdateNetworkBlockingQueue(vm, fieldID)
    if self.Text_NetQueued then self.Text_NetQueued:SetText(vm.NetworkBlockingQueue) end
end

function GameStatusInfoTopWidget:UpdatebNetworkBlockingQueue(vm, fieldID)
    if self.HV_NetQueued then
        local IsShipping = CommonUtil.IsShipping()
        print("GameStatusInfoTopWidget:UpdatebNetworkBlockingQueue [IsShipping]=",IsShipping)
        if IsShipping then
            self.HV_NetQueued:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.HV_NetQueued:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

return GameStatusInfoTopWidget