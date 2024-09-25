--[[
    用于WBP_Common_InputBox的逻辑类
]]
local class_name = "CommonInputBoxLogic"
local CommonInputBoxLogic = BaseClass(nil, class_name)


function CommonInputBoxLogic:OnInit()
    self.BindNodes = {
    	{ UDelegate = self.View.GUIButton_Input.OnClicked,	Func = Bind(self,self.GUIButton_Input_OnClicked) },
    	{ UDelegate = self.View.Btn_Cancel.GUIButton_Main.OnClicked,	Func = Bind(self,self.Btn_Canel_OnClicked) },
	}
end

--[[
    Param 
    与 CommonTextBoxInput 参数一致，用于CommonTextBoxInput
    Param.DefaultName = "默认文本"      --【可选】默认文本
]]
function CommonInputBoxLogic:OnShow(Param)
    self.Param = Param
    self.SizeLimit = self.Param.SizeLimit or CommonTextBoxInput.DEFAULT_SIZE_LIMIT
    self.ParentOnTextChangedFunc = Param.OnTextChangedFunc
    if not self.CommonTextBoxInputCls then
        Param.OnTextChangedFunc = Bind(self,self.OnTextChangedFunc)
        self.CommonTextBoxInputCls = UIHandler.New(self,self.View,CommonTextBoxInput,Param).ViewInstance
    end
    self.View.WidgetSwitcher_State:SetActiveWidget(self.View.Panel_Normal)
    -- self.View.Text_WordNum:SetText(StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"),0,self.SizeLimit))
    if Param.DefaultName then
        self.View.GUIText_Hint:SetText(StringUtil.Format(Param.DefaultName))
    end
end

function CommonInputBoxLogic:OnHide()

end

function CommonInputBoxLogic:OnTextChangedFunc(_,InName, bNotUpdateText)
    -- self.View.Text_WordNum:SetText(StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"),#self:GetText(),self.SizeLimit))
    if self.ParentOnTextChangedFunc then
        self.ParentOnTextChangedFunc(InName,bNotUpdateText)
    end
end

function CommonInputBoxLogic:GUIButton_Input_OnClicked()
    self.View.WidgetSwitcher_State:SetActiveWidget(self.View.Panel_Select)
    -- 延迟一帧设置进入输入状态，避免被InputModel的处理覆盖了聚焦
    self:InsertTimer(-1,function ()
        if CommonUtil.IsValid(self.View) then
            self.View.NameInput:SetKeyboardFocus()
        end
    end)
end
function CommonInputBoxLogic:Btn_Canel_OnClicked()
    self.View.WidgetSwitcher_State:SetActiveWidget(self.View.Panel_Normal)
end

----------- 兼容对NameInput调用的方法

function CommonInputBoxLogic:SetKeyboardFocus()
    self.View.NameInput:SetKeyboardFocus()
end
function CommonInputBoxLogic:SetText(Text)
    self.View.NameInput:SetText(Text)
end
function CommonInputBoxLogic:GetText()
    return self.View.NameInput:GetText()
end

return CommonInputBoxLogic
