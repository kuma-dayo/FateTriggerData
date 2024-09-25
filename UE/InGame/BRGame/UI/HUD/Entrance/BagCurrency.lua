require "UnLua"

local BagCurrency = Class("Common.Framework.UserWidget")

function BagCurrency:OnInit()
    print("BagCurrency:OnInit")
    self.ItemNum = 0

    self.InitListenList = { 
        { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnDestroy_Currency, Func = self.OnDestroyItem, bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnStackNum_Change_Currency, Func = self.OnCurrencyStackNumChange, bCppMsg = true },
    }
    MsgHelper:RegisterList(self, self.InitListenList)
    self:UpdateCurrencyNumber()
    UserWidget.OnInit(self)
end

function BagCurrency:OnDestroy()
    print("BagCurrency:OnDestroy")
    if self.InitListenList then
        MsgHelper:UnregisterList(self, self.InitListenList)
    end
    UserWidget.OnDestroy(self)
end

function BagCurrency:UpdateCurrencyNumber()
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempLocalPC then return end
    local TempBagComp = UE.UBagComponent.Get(TempLocalPC)
    if TempBagComp then
        local PreItemNum = self.ItemNum
        self.ItemNum = TempBagComp:GetItemNumByItemID(self.DefaultItem)
        if self.ItemNum > PreItemNum then 
            print("BagCurrency:UpdateCurrencyNumber:Add Currency")
            self.VXV_Before_Number = PreItemNum
            self.VXV_After_Number = self.ItemNum
            self:VXE_Number_Start()
        else
            self:UpdateCurrencyNumberText(self.ItemNum)
        end
    end
end

function BagCurrency:UpdateCurrencyNumberText(InNumber)
    if self.Txt_MoneyNum then
        self.Txt_MoneyNum:SetText(InNumber)
    end
end

function BagCurrency:OnCurrencyStackNumChange(InInventoryInstance)
    if not InInventoryInstance then return end
    self:UpdateCurrencyNumber()
end

function BagCurrency:OnDestroyItem(InInventoryInstance)
    if not InInventoryInstance then return end
    self:UpdateCurrencyNumber()
end

return BagCurrency