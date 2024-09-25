
--- 处理 WBP_Login_SelectCountryWidget 类似于UMG的 CheckBox 控件

local class_name = "CommonCheckBox"
---@class CommonCheckBox
CommonCheckBox = CommonCheckBox or BaseClass(CommonCheckBox, class_name)

function CommonCheckBox:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.GUIButton_Tips.OnClicked,				Func = Bind(self,self.OnItemButtonClick) },
		-- Hover效果均放入动效实现
		-- { UDelegate = self.View.GUIButton_Tips.OnHovered,				Func = Bind(self,self.OnBtnHovered) },
		-- { UDelegate = self.View.GUIButton_Tips.OnUnhovered,				Func = Bind(self,self.OnBtnUnovered) },
	}
end

--[[
	Param = {
		OnCheckStateChanged = function(boolen) end,				    --【可选】点击回调
        bIsChecked          = false                                 --【可选】默认false,代表未选中
		TipStr				= "提示文本" 						     --【可选】提示文本（如果有值 会优先使用此文本进行展示）
        bIsDisable          = false                                 --【可选】是否禁用
        DisableTip          = "提示文本"                             --【可选】禁用时的禁用提示
	}
]]
function CommonCheckBox:OnShow(Param)
    self:UpdateUI(Param)
end

function CommonCheckBox:OnManualShow(Param)
    self:UpdateUI(Param)
end

function CommonCheckBox:UpdateUI(Param)
    self.Param = Param
    self.bIsChecked = self.Param.bIsChecked or false
    self.OnCheckStateChanged = self.Param.OnCheckStateChanged
    self.bIsDisable = self.Param.bIsDisable or false
    self.DisableTip = self.Param.DisableTip

    self:SetIsChecked(self.bIsChecked)
end

function CommonCheckBox:OnManualHide(Param)
end

function CommonCheckBox:OnHide(Param)
end

function CommonCheckBox:OnDestroy(Data,IsNotVirtualTrigger)
end

---设置是否禁用互动
function CommonCheckBox:SetCheckBoxDisable(IsDisable, TipStr)
    self.bIsDisable = IsDisable
    if self.bIsDisable then
        self.DisableTipStr = TipStr    
    end
end

function CommonCheckBox:OnItemButtonClick()
    if self.bIsDisable then
        --被禁用了
        if self.DisableTipStr then
            UIAlert.Show(self.DisableTipStr)
        end
    else
        self:SetIsChecked(not(self.bIsChecked))

        if self.OnCheckStateChanged then
            self.OnCheckStateChanged(self.bIsChecked)
        end
    end
end

---设置是否被Checked
function CommonCheckBox:SetIsChecked(bIsChecked)
    self.bIsChecked = bIsChecked

    if CommonUtil.IsValid(self.View.WidgetSwitcher_Icon) then
        if self.bIsChecked then
            if CommonUtil.IsValid(self.View.Icon_Select) then
                self.View.WidgetSwitcher_Icon:SetActiveWidget(self.View.Icon_Select)
            end
        else
            if CommonUtil.IsValid(self.View.Icon_Empty) then
                self.View.WidgetSwitcher_Icon:SetActiveWidget(self.View.Icon_Empty)
            end
        end
    end
end