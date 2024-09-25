--[[
    处理多行输入框控件的通用逻辑
]]

local class_name = "CommonMultiLineTextBoxInput"
CommonMultiLineTextBoxInput = CommonMultiLineTextBoxInput or BaseClass(nil, class_name)

function CommonMultiLineTextBoxInput:OnInit()
    self.BindNodes = {}
    self.SizeLimit = 60
end

--[[
    Param格式指引
	{
		InputWigetName: TextBox控件名称 
        --注： UIHandler需要传入TextBox的父级Panel管理生命周期，所以传入View和控件名字，以获取控件使用。而且此TextBox不能主动Remove，必须跟随父级Panel的生命周期
        
        FoucsViewId[Optional]: 父级界面ID，用于输入完成后恢复按键Focus。如输入完成后无需其他按键操作，可不传
        SizeLimit [Optional]: 输入最大长度限制， 默认为60
        OnTextChangedFunc [Optional]: OnTextChanged 时执行的回调
        OnTextCommittedFunc [Optional]: OnTextCommitted 时执行的回调， 会将 InCommitMethod 参数传出可供自行判断
        OnTextCommittedEnterFunc [Optional]: OnTextCommitted 且 InCommitMethod为 UE.ETextCommit.OnEnter 时执行的回调
        OnClearedFunc[Optional]: OnTextCommitted 且 InCommitMethod 为 不经过UE.ETextCommit.OnEnter的UE.ETextCommit.OnCleared 时执行的回调 一般为Esc触发
	}
]]
function CommonMultiLineTextBoxInput:OnShow(Param)
	self.Param = Param
    if not (self.Param.InputWigetName and self.View[self.Param.InputWigetName]) then
        CError("CommonMultiLineTextBoxInput: Can't Get InputWidget. Please Check! ")
        print_trackback()
        return
    end
    self.InputWidget =  self.View[self.Param.InputWigetName]
    self.SizeLimit = self.Param.SizeLimit or self.SizeLimit
    self.CurInputText = ""
    if self.Param.OnTextChangedFunc then
        local BindNode = {UDelegate = self.InputWidget.OnTextChanged,Func = Bind(self,self.OnTextChanged)}
        self.BindNodes[#self.BindNodes + 1] = BindNode
    end
    --这边无论是否有OnTextCommittedFunc 都需要进行监听委托，需要额外处理ViewFocus问题，所以将判断注释
    -- if self.Param.OnTextCommittedFunc or self.Param.OnTextCommittedEnterFunc then
        self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.InputWidget.OnTextCommitted,Func = Bind(self,self.OnTextCommitted)}
    -- end
    self:ReRegister()
end

-- 供外部调用 设置最大输入长度限制
function CommonMultiLineTextBoxInput:SetMaxSizeLimit(SizeLimit)
    self.SizeLimit = SizeLimit
end

function CommonMultiLineTextBoxInput:OnTextChanged(_,InText)
    -- local InputTxt,IsSplit =StringUtil.CutByLength( tostring(InText),self.SizeLimit)
    local InputTxt = InText
    local TexNum = StringUtil.utf8StringLen(InputTxt)
    -- print("CommonMultiLineTextBoxInput_OnTextChanged:" .. TexNum)
    
    -- TODO 暂时屏蔽
    -- EditTextBlock优化，需要区分当前是否存储输入状态（拼音或者五笔属于）
    -- 当前无法区分，导致去限制输入框的字节数时，容易失去焦点，导致后续输入框的输入行为都无法捕捉到

    if TexNum > tonumber(self.SizeLimit) then
        -- 超长了重置回原文本显示
        self.CurInputText = StringUtil.CutByLength( tostring(InputTxt),self.SizeLimit)
        self.InputWidget:SetText(self.CurInputText)
        self.Param.OnTextChangedFunc(self.View,self.CurInputText)
    else
        self.CurInputText = InputTxt
		self.Param.OnTextChangedFunc(self.View, InputTxt, true)
    end
    -- TODO 暂时先把截断逻辑写上。后续修改完再处理
    -- self.CurInputText = InputTxt
    -- if IsSplit then
        -- self.InputWidget:SetText(self.CurInputText)
    -- end
    self.Param.OnTextChangedFunc(self.View, InputTxt, true)
end

function CommonMultiLineTextBoxInput:OnTextCommitted(_,InText,InCommitMethod)
	print("CommonMultiLineTextBoxInput", ">> InCommitMethod = "..tostring(InCommitMethod),">> OnTextCommitted...".. InText)
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

function CommonMultiLineTextBoxInput:OnHide()
    self.Param = nil
end

return CommonMultiLineTextBoxInput
