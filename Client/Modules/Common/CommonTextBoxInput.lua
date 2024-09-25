--[[
    处理输入框控件的通用逻辑
]]

local class_name = "CommonTextBoxInput"
CommonTextBoxInput = CommonTextBoxInput or BaseClass(nil, class_name)

--[[
    输入模式枚举
]]
CommonTextBoxInput.InputFormatType = {
    --普通
    NORMAL = 1,
    --只允许数字
    NUMBER = 2,
    --显示为密码类型
    PASSWORD = 3,
}

CommonTextBoxInput.DEFAULT_SIZE_LIMIT = 60

function CommonTextBoxInput:OnInit()
    self.BindNodes = {}
    self.SizeLimit = CommonTextBoxInput.DEFAULT_SIZE_LIMIT

    self.InputFormatType2ErrorTip = {
        [CommonTextBoxInput.InputFormatType.NUMBER] = G_ConfigHelper:GetStrFromCommonStaticST("InputFormatErrorNumber"),
    }
end

--[[
    Param格式指引
	{
		InputWigetName: TextBox控件名称 
        --注： UIHandler需要传入TextBox的父级Panel管理生命周期，所以传入View和控件名字，以获取控件使用。而且此TextBox不能主动Remove，必须跟随父级Panel的生命周期
        
        FoucsViewId[Optional]: 父级界面ID，用于输入完成后恢复按键Focus。如输入完成后无需其他按键操作，可不传
        SizeLimit [Optional]: 输入最大长度限制， 默认为60
        InputFormatType 输入模式，默认为  CommonTextBoxInput.InputFormatType.NORMAL
        HideInputFormatErrorTip  输入文本不符合输入模式时，是否需要提示，默认需要
        OnTextChangedFunc [Optional]: OnTextChanged 时执行的回调
            回参：
                1.View本身
                2.文本
                3.是否 没有被截断  true表示 没截断  false表示被截断
                4.当前文本长度
        OnTextCommittedFunc [Optional]: OnTextCommitted 时执行的回调， 会将 InCommitMethod 参数传出可供自行判断
            回参：
                1.View本身
                2.文本
                3.InCommitMethod
        OnTextCommittedEnterFunc [Optional]: OnTextCommitted 且 InCommitMethod为 UE.ETextCommit.OnEnter 时执行的回调
            回参：
                1.View本身
                2.文本
                3.InCommitMethod
        OnClearedFunc[Optional]: OnTextCommitted 且 InCommitMethod 为 不经过UE.ETextCommit.OnEnter的UE.ETextCommit.OnCleared 时执行的回调 一般为Esc触发
            暂时没有回参
	}
]]
function CommonTextBoxInput:OnShow(Param)
	self.Param = Param
    if not (self.Param.InputWigetName and self.View[self.Param.InputWigetName]) then
        CError("CommonTextBoxInput: Can't Get InputWidget. Please Check! ")
        print_trackback()
        return
    end
    self.InputWidget =  self.View[self.Param.InputWigetName]
    self.SizeLimit = self.Param.SizeLimit or self.SizeLimit
    self.InputFormatType = self.Param and self.Param.InputFormatType or CommonTextBoxInput.InputFormatType.NORMAL
    self.HideInputFormatErrorTip = self.Param and self.Param.HideInputFormatErrorTip or false
    self.CurInputText = ""
    self.BindNodes = {
        {UDelegate = self.InputWidget.OnTextChanged,Func = Bind(self,self.OnTextChanged)},
        {UDelegate = self.InputWidget.OnTextCommitted,Func = Bind(self,self.OnTextCommitted)}
    }
    if self.InputWidget.IsA and self.InputWidget:IsA(UE.UEditableTextBox) then
        if self.InputFormatType == CommonTextBoxInput.InputFormatType.PASSWORD then
            self.InputWidget:SetIsPassword(true)
        else
            self.InputWidget:SetIsPassword(false)
        end
    end
    self:ReRegister()
end

-- 供外部调用 设置最大输入长度限制
function CommonTextBoxInput:SetMaxSizeLimit(SizeLimit)
    self.SizeLimit = SizeLimit
end

function CommonTextBoxInput:OnTextChanged(_,InText)
    local InputTxt = InText
    local TexNum = StringUtil.utf8StringLen(InputTxt)
    -- print("CommonTextBoxInput_OnTextChanged:" .. TexNum)

    local NeedResetInputWidgetShow = false
    if TexNum > 0 then
        --处理InputFormatType
        if self.InputFormatType == CommonTextBoxInput.InputFormatType.NUMBER then
            local NumValue = tonumber(InputTxt)
            if not NumValue then
                InputTxt = self.CurInputText
                TexNum = StringUtil.utf8StringLen(InputTxt)
                NeedResetInputWidgetShow = true
                self:AlertInputFormatErrorTip()
            end
        end
    end
    
    local IsNotCutByLimit = true
    if TexNum > tonumber(self.SizeLimit) then
        -- 超长了重置回原文本显示
        InputTxt = StringUtil.CutByLength( tostring(InputTxt),self.SizeLimit)
        IsNotCutByLimit = false
        NeedResetInputWidgetShow = true
        TexNum = self.SizeLimit
    end
    self.CurInputText = InputTxt
    if NeedResetInputWidgetShow then
        self.InputWidget:SetText(InputTxt)
    end
    if self.Param and self.Param.OnTextChangedFunc then
        self.Param.OnTextChangedFunc(self.View, InputTxt, IsNotCutByLimit)
    end
end

function CommonTextBoxInput:OnTextCommitted(_,InText,InCommitMethod)
	print("CommonTextBoxInput", ">> InCommitMethod = "..tostring(InCommitMethod),">> OnTextCommitted...".. InText)
   if InCommitMethod == UE.ETextCommit.OnEnter then
        if self.Param and self.Param.FoucsViewId then
            MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_WIDGET_TO_FOCUS,self.Param.FoucsViewId)
        end
        if self.Param and self.Param.OnTextCommittedEnterFunc then
            self.Param.OnTextCommittedEnterFunc(self.View,InText,InCommitMethod)
        end
	elseif InCommitMethod == UE.ETextCommit.OnCleared and self.Param and self.Param.OnClearedFunc then
        self.Param.OnClearedFunc()
    end
    if self.Param and self.Param.OnTextCommittedFunc then
        -- 如果在OnClearedFunc把父节点界面关闭，则self.Param会清除，不会进入此回调
        self.Param.OnTextCommittedFunc(self.View,InText,InCommitMethod)
    end
end

--[[
    输入文本不符合当前输入模式，进行提示
]]
function CommonTextBoxInput:AlertInputFormatErrorTip()
    if self.HideInputFormatErrorTip then
        return
    end
    local Tip = self.InputFormatType2ErrorTip[self.InputFormatType]
    if Tip then
        UIAlert.Show(Tip)
    end
end

function CommonTextBoxInput:OnHide()
    self.Param = nil
end

return CommonTextBoxInput
