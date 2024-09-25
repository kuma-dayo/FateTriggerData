
local ParentClassName = "Common.Framework.UserWidget"
local UserWidget = require(ParentClassName)
local GameStatusInfoWidget = Class(ParentClassName)

function GameStatusInfoWidget:OnInit()
    if not self.GameStatusInfoViewModel then return end
    print("GameStatusInfoWidget:OnInit xyzpring")
    UserWidget.OnInit(self)
    self:InitView()
    self:AddFieldValueChangedDelegate()
end

function GameStatusInfoWidget:InitView()

    self:UpdatebNetworkStatusDisplay(self.GameStatusInfoViewModel, nil)
    self:UpdatePing(self.GameStatusInfoViewModel, nil)
    self:UpdatebPing(self.GameStatusInfoViewModel, nil)
    self:UpdateFPS(self.GameStatusInfoViewModel, nil)
    self:UpdatebFPS(self.GameStatusInfoViewModel, nil)
    self:UpdateOutBytesPerSecond(self.GameStatusInfoViewModel, nil)
    self:UpdatebOutBytesPerSecond(self.GameStatusInfoViewModel, nil)
    self:UpdateOutPacketsPerSecond(self.GameStatusInfoViewModel, nil)
    self:UpdatebOutPacketsPerSecond(self.GameStatusInfoViewModel, nil)
    self:UpdateOutLossPercentage(self.GameStatusInfoViewModel, nil)
    self:UpdatebOutLossPercentage(self.GameStatusInfoViewModel, nil)
    self:UpdateInBytesPerSecond(self.GameStatusInfoViewModel, nil)
    self:UpdatebInBytesPerSecond(self.GameStatusInfoViewModel, nil)
    self:UpdateInPacketsPerSecond(self.GameStatusInfoViewModel, nil)
    self:UpdatebInPacketsPerSecond(self.GameStatusInfoViewModel, nil)
    self:UpdateInLossPercentage(self.GameStatusInfoViewModel, nil)
    self:UpdatebInLossPercentage(self.GameStatusInfoViewModel, nil)

    print("GameStatusInfoWidget:InitView")
end

function GameStatusInfoWidget:OnDestroy()
    print("GameStatusInfoWidget:OnDestroy")
    
    self:RemoveFieldValueChangedDelegate()


    UserWidget.OnDestroy(self)
end

function GameStatusInfoWidget:AddFieldValueChangedDelegate()
    if not self.GameStatusInfoViewModel then return end
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bNetworkStatusDisplay",{ self, self.UpdatebNetworkStatusDisplay })

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("Ping",{ self, self.UpdatePing })
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bPing",{ self, self.UpdatebPing})

    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("FPS",{ self,self.UpdateFPS})
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("bFPS",{ self, self.UpdatebFPS})

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
end

function GameStatusInfoWidget:RemoveFieldValueChangedDelegate()
    if not self.GameStatusInfoViewModel then return end
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bNetworkStatusDisplay",{ self, self.UpdatebNetworkStatusDisplay })

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("Ping",{ self, self.UpdatePing })
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bPing",{ self, self.UpdatebPing})

    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("FPS",{ self,self.UpdateFPS})
    self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("bFPS",{ self, self.UpdatebFPS})

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
end

function GameStatusInfoWidget:UpdatebNetworkStatusDisplay(vm, fieldID)
    self.InvalidationBox_0:SetCanCache(false)
    local bNetworkStatusDisplay = vm.bNetworkStatusDisplay
    self.MainPanel:SetVisibility(bNetworkStatusDisplay and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.InvalidationBox_0:SetCanCache(true)
end


function GameStatusInfoWidget:UpdatePing(vm, fieldID)
    if not vm then return end
    self.Text_Ping:SetText(math.floor(vm.Ping))
end

function GameStatusInfoWidget:UpdatebPing(vm, fieldID)
    -- self.HB_Ping:SetVisibility(vm.bPing and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function GameStatusInfoWidget:UpdateFPS(vm, fieldID)
    if not vm then return end
    self.Text_FPS:SetText(vm.FPS)
end

function GameStatusInfoWidget:UpdatebFPS(vm, fieldID)
    -- self.HB_FPS:SetVisibility(vm.bFPS and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function GameStatusInfoWidget:UpdateOutBytesPerSecond(vm, fieldID)
    if not vm then return end
    self.Text_Send:SetText(vm.OutBytesPerSecond .. "KB/s")
end

function GameStatusInfoWidget:UpdatebOutBytesPerSecond(vm, fieldID)
    -- self.HB_Send:SetVisibility(vm.bOutBytesPerSecond and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end


function GameStatusInfoWidget:UpdateOutPacketsPerSecond(vm, fieldID)
    if not vm then return end
    self.Text_Speed1:SetText(vm.OutPacketsPerSecond .. "pkt/s")
end

function GameStatusInfoWidget:UpdatebOutPacketsPerSecond(vm, fieldID)
    -- self.Text_Speed1:SetVisibility(vm.bOutPacketsPerSecond and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function GameStatusInfoWidget:UpdateOutLossPercentage(vm, fieldID)
    if not vm then return end
    self.Text_Pkt1:SetText(vm.OutLossPercentage .. "%")
end

function GameStatusInfoWidget:UpdatebOutLossPercentage(vm, fieldID)
    -- self.HB_Kpt1:SetVisibility(vm.bOutLossPercentage and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function GameStatusInfoWidget:UpdateInBytesPerSecond(vm, fieldID)
    if not vm then return end
    self.Text_Download:SetText(vm.InBytesPerSecond .. "KB/s")
end

function GameStatusInfoWidget:UpdatebInBytesPerSecond(vm, fieldID)
    -- self.HB_Download:SetVisibility(vm.bInBytesPerSecond  and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function GameStatusInfoWidget:UpdateInPacketsPerSecond(vm, fieldID)
    if not vm then return end
    self.Text_Speed2:SetText(vm.InPacketsPerSecond .. "pkt/s")
end

function GameStatusInfoWidget:UpdatebInPacketsPerSecond(vm, fieldID)
    -- self.Text_Speed2:SetVisibility(vm.bInPacketsPerSecond and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function GameStatusInfoWidget:UpdateInLossPercentage(vm, fieldID)
    if not vm then return end
    self.Text_Pkt2:SetText(vm.InLossPercentage .. "%")
end

function GameStatusInfoWidget:UpdatebInLossPercentage(vm, fieldID)
    -- self.HB_Kpt2:SetVisibility(vm.bInLossPercentage  and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

return GameStatusInfoWidget
