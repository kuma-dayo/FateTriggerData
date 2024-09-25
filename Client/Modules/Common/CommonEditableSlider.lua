--[[
    通用的CommonEditableSlider控件
]]
require "UnLua"

local class_name = "CommonEditableSlider"
CommonEditableSlider = CommonEditableSlider or BaseClass(nil, class_name)

---@class CommonEditableSliderParam
---@field ValueChangeCallBack function 回调
---@field Gap number 步进值
---@field MinValue number 最小值
---@field MaxValue number 最大值
---@field DefaultValue number 默认值
---@field AllowMaxIsZero boolean 是否允许最大值为0
---@field TipTxt string 提示文字
CommonEditableSlider.Param = nil

function CommonEditableSlider:OnInit(Param)
    self.BindNodes = {
        {UDelegate = self.View.Button_Min.OnClicked, Func = Bind(self, self.OnBtnMin)},
        {UDelegate = self.View.Button_Max.OnClicked, Func = Bind(self, self.OnBtnMax)},
        {UDelegate = self.View.EditableText.OnTextCommitted, Func = Bind(self, self.OnTextCommitted)},
        {UDelegate = self.View.EditableText.OnTextChanged, Func = Bind(self, self.OnTextChanged)},
        {UDelegate = self.View.Slider.OnValueChanged, Func = Bind(self, self.OnValueChanged)}
    }

    self.MsgList = {
        {
            Model = InputModel,
            MsgName = ActionPressed_Event(ActionMappings.Right),
            Func = Bind(self, self.OnBtnAdd)
        },{
            Model = InputModel,
            MsgName = ActionPressed_Event(ActionMappings.Left),
            Func = Bind(self, self.OnBtnSub)
        },
    }

    self.Gap = 1
    self.CurValue = -1
    self.MinValue = 1
    self.MaxValue = 999
    self.DefaultValue = 0
end

--- OnShow
---@param Param CommonEditableSliderParam
function CommonEditableSlider:OnShow(Param)
    self:UpdateItemInfo(Param)
end

function CommonEditableSlider:OnHide()
end

--- UpdateItemInfo
---@param Param CommonEditableSliderParam
function CommonEditableSlider:UpdateItemInfo(Param)
    self.Param = Param
    if self.Param == nil then
        return
    end
    if self.View == nil then
        CError("CommonEditableSlider:UpdateItemInfo View nil",true)
        return
    end

    self.MinValue = self.Param.MinValue or 1
    self.MaxValue = self.Param.MaxValue or 999
    self.DefaultValue = self.Param.DefaultValue or 0
    self.Gap = self.Param.Gap or 1

    local AllowMaxIsZero = self.Param.AllowMaxIsZero
    if self.MaxValue == 0 then
        if AllowMaxIsZero then
            self.MinValue = 0
        else
            CWaring("[CommonEditableSlider]UpdateItemInfo MaxValue is zero!")
            self.MaxValue = 999
        end
    end

    if self.Param.TipTxt then
        self.View.RichTextBlock_Intimacy:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.RichTextBlock_Intimacy:SetText(self.Param.TipTxt)
    else
        self.View.RichTextBlock_Intimacy:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    self.View.Text_Min:SetText(self.MinValue)
    self.View.Text_Max:SetText(self.MaxValue)
    self.View.Slider:SetMaxValue(self.MaxValue)
    self.View.Slider:SetMinValue(self.MinValue)
    self.View.Slider:SetStepSize(self.Gap)
    self:UpdateValue(self.DefaultValue)
end

function CommonEditableSlider:UpdateValue(Value, bForceCall)
    bForceCall = bForceCall or false
    if not(bForceCall) and self.CurValue == Value then
        return
    end

    if Value < self.MinValue then
        Value = self.MinValue
    end
    if Value > self.MaxValue then
        Value = self.MaxValue
    end

    self:SetCurValue(Value)

    -- print("CommonEditableSlider UpdateValue",self.CurValue)

    if self.Param.ValueChangeCallBack then
        self.Param.ValueChangeCallBack(self.CurValue)
    end
end

function CommonEditableSlider:SetCurValue(Value)
    self.CurValue = Value

    self.View.EditableText:SetText(self.CurValue)
    self.View.Slider:SetValue(self.CurValue)
end

function CommonEditableSlider:OnBtnSub()
    -- print("CommonEditableSlider OnBtnSub")
    local Value = self.CurValue - self.Gap
	if Value < self.MinValue then
        return
    end
    self:UpdateValue(Value)
end

function CommonEditableSlider:OnBtnAdd()
    -- print("CommonEditableSlider OnBtnAdd")
    local Value = self.CurValue + self.Gap
	if Value > self.MaxValue then
        return
    end
    self:UpdateValue(Value)
end

function CommonEditableSlider:OnBtnMin()
    self:UpdateValue(self.MinValue)
end

function CommonEditableSlider:OnBtnMax()
    self:UpdateValue(self.MaxValue)
end

function CommonEditableSlider:OnTextChanged(InValue)
    -- local TempValue = StringUtil.Trim(self.View.EditableText:GetText())
    local TempValue = self.View.EditableText:GetText()
    if not TempValue or string.len(TempValue) <= 0 then
        return
    end
    -- local NumValue = tonumber(TempValue)

    -- 必须输入大于{0}并小于{1}的整数,数字为非0开头!
    local str = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "CommonEditableSlider_Tip1"), self.MinValue, self.MaxValue)
    -- ^:从头开始匹配,[1-9]第1位必须是1-9,%d+:其它位置必须是数字,$:匹配匹配到字符串结尾
    -- if string.match(TempValue,"^[1-9]%d+$") then
    local NumValue = tonumber(TempValue)
    if NumValue then
        -- 转换为数字成功
        if self.MaxValue > 0 and (NumValue < self.MinValue or NumValue > self.MaxValue) then
            -- 数字超出区间-提示匹配失败
            UIAlert.Show(str)
        end

        self:UpdateValue(NumValue, true)
    else
        -- 输入了除数字之外的值-提示匹配失败
        UIAlert.Show(str)
        NumValue = tonumber(string.match(TempValue,"[1-9]%d*") or "0") 
        self:UpdateValue(NumValue, true)
    end 
end

function CommonEditableSlider:OnTextCommitted(_, InValue)
    -- CWaring("CommonEditableSlider OnTextCommitted",InValue)
    local TempValue = StringUtil.Trim(self.View.EditableText:GetText())
    local Value = tonumber(TempValue)
    if not Value or Value ~= self.CurValue then
        Value = self.CurValue
        self.View.EditableText:SetText(Value)
    end
	-- if Value < self.MinValue then
    --     Value = self.MinValue
	-- 	self.View.EditableText:SetText(Value)
    -- end
    -- if Value > self.MaxValue then
    --     Value = self.MaxValue
	-- 	self.View.EditableText:SetText(Value)
    -- end
    -- self:UpdateValue(Value)
end

function CommonEditableSlider:OnValueChanged(_, InValue)
    -- print("CommonEditableSlider OnValueChanged",InValue)
    local Value = math.floor(self.View.Slider:GetValue())
    self:UpdateValue(Value)
end

return CommonEditableSlider
