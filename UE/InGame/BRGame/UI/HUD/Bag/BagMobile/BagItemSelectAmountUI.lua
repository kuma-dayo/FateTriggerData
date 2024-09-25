local BagItemSelectAmountUIMobile = Class("Common.Framework.UserWidget")


function BagItemSelectAmountUIMobile:OnInit()
    print("BagItemSelectAmountUIMobile >> OnInit.")

    self.MinSelectNum = 0
    self.MaxSelectNum = 0
    self.CurrentSelectNum = 0
    self.InItemData = nil
    
    self.BindNodes = 
    {
        { UDelegate = self.Button_Min.OnClicked, Func = self.OnMinClick },
        { UDelegate = self.Button_Max.OnClicked, Func = self.OnMaxClick },
        { UDelegate = self.Button_Discard.OnClicked, Func = self.OnDiscardClick },
        { UDelegate = self.Button_Cancel.OnClicked, Func = self.OnCancelClick },
        { UDelegate = self.Slider.OnValueChanged, Func = self.OnSlideValueChanged },
    }

    UserWidget.OnInit(self)
end

function BagItemSelectAmountUIMobile:OnDestroy()
    print("BagItemSelectAmountUIMobile >> OnDestroy.")
    self.InItemData = nil

    UserWidget.OnDestroy(self)
end

function BagItemSelectAmountUIMobile:UpdateSelectAmount(InItemData)
    print("BagItemSelectAmountUIMobile >> UpdateSelectAmount.")
    if InItemData == nil then
        return
    end

    self.InItemData = InItemData
    self.MinSelectNum =  0
    self.MaxSelectNum = InItemData.ItemNum or 0
    self.CurrentSelectNum = self.MaxSelectNum == 0 and 0 or math.floor(self.MaxSelectNum / 2)

    self.Text_Current:SetText(self.CurrentSelectNum)
    self.TextBlock_Min:SetText(self.MinSelectNum)
    self.TextBlock_Max:SetText(self.MaxSelectNum)
    self.Slider:SetValue(self.CurrentSelectNum)
    self.Slider:SetMinValue(self.MinSelectNum)
    self.Slider:SetMaxValue(self.MaxSelectNum)
    self:SetProgressPercent(self.CurrentSelectNum, self.MinSelectNum, self.MaxSelectNum)
end

function BagItemSelectAmountUIMobile:SetProgressPercent(CurrentValue, MinValue, MaxValue)
    local percent = (CurrentValue - MinValue) / (MaxValue - MinValue)
    self.ProgressBar:SetPercent(percent)
end

function BagItemSelectAmountUIMobile:OnMinClick()
    self.CurrentSelectNum = self.MinSelectNum
    self.Text_Current:SetText(self.CurrentSelectNum)
    self.Slider:SetValue(self.CurrentSelectNum)
    self:SetProgressPercent(self.CurrentSelectNum,self.MinSelectNum,self.MaxSelectNum)
end

function BagItemSelectAmountUIMobile:OnMaxClick()
    self.CurrentSelectNum = self.MaxSelectNum
    self.Text_Current:SetText(self.CurrentSelectNum)
    self.Slider:SetValue(self.CurrentSelectNum)
    self:SetProgressPercent(self.CurrentSelectNum,self.MinSelectNum,self.MaxSelectNum)
end

function BagItemSelectAmountUIMobile:OnDiscardClick()
    print("BagItemSelectAmountUIMobile >> OnDiscardClick")
    
    ItemSystemHelper.TryToDiscardItem(self.InItemData.ItemID, self.InItemData.ItemInstanceID, self.CurrentSelectNum)
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideDropAmount)
end

function BagItemSelectAmountUIMobile:OnCancelClick()
    print("BagItemSelectAmountUIMobile >> OnCancelClick")

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideDropAmount)
end

function BagItemSelectAmountUIMobile:OnSlideValueChanged(InValue)
    -- print("BagItemSelectAmountUIMobile >> OnSlideValueChanged > InValue :",InValue)

    local tIntNum = math.ceil(InValue)
    self.CurrentSelectNum = math.clamp(tIntNum, self.MinSelectNum, self.MaxSelectNum)
    self.Text_Current:SetText(self.CurrentSelectNum)
    self.Slider:SetValue(self.CurrentSelectNum)
    self:SetProgressPercent(self.CurrentSelectNum,self.MinSelectNum,self.MaxSelectNum)
end


return BagItemSelectAmountUIMobile