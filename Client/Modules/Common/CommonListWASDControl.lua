--[[
    通用的CommonListWASDControl控件

    用于对列表的WASD通用控制
]]

local class_name = "CommonListWASDControl"
---@class CommonListWASDControl
CommonListWASDControl = CommonListWASDControl or BaseClass(nil, class_name)

CommonListWASDControl.ControlModeEnum = {
    --[[
        同时响应wasd 及方向按钮
    ]]
    ALL = 1,
    --[[
        只响应wasd
    ]]
    JUST_WASD = 2,
    --[[
        只响应  方向按钮
    ]]
    JUST_DirectionKeys = 3,
}

CommonListWASDControl.ControlRuleEnum = {    
    Default = 1,    --默认，一般使用ReuseList的时候就可以使用
    CustomRule = 2, --用户自定义规则，当页面布局不规则的时候使用，参考 HeroMdt    
}

--[[
   local Param = {        
        CurShowIndex = 1,       --【可选】当前开始Index值，默认为0
        ControlRule = nil,      --【可选】参考 CommonListWASDControl.ControlRuleEnum
        ControlMode = nil,      --【可选】控制类型，可选，默认为 CommonListWASDControl.ControlModeEnum.ALL
        Callback = nil,         --【可选】操作回调，参数为列表的Index值 ，表示操作后需要展示的目标 Index        
        
        ----- Default Rule -----
        * 当前布局是使用ReuseList的时候，需要填写以下参数
        DataListSize = nil,     --【使用Default Rule填写】列表数量（从1开始计数）       
        IsVertical = True,      --【使用Default Rule填写】是否垂直朝向        
        ColNum = nil,           --【使用Default Rule填写】多少列 IsVertical为true生效  ColNum 为nil值或者 <=1, 只会响应 WS 及 上下按键       
        RowNum = nil,           --【使用Default Rule填写】多少行 IsVertical为false生效  RowNum 为nil值或者 <=1, 只会响应 AD 及 左右按键        
        --- Default Rule End ---
        
        ------ Custom Rule -----
        * 当页面布局是自定义布局的时候，这个时候的摆放就是不规则的了，此时需要设置
        CustomRuleMap = {     --【使用Custom Rule填写】这里需要传入自定义的规则
            [1] = {
                Left = 2,
                Right = nil,
                Top = nil,
                Bottom = 5,
            },
            ...
        }
        ---- Custom Rule ENd ---
   }
]]
function CommonListWASDControl:ParamSet(Param)
    if not Param then
        CError("CommonListWASDControl Param nil",true)
        return
    end
    self.Param = self.Param or {}

    self.Param.DataListSize = Param.DataListSize or self.Param.DataListSize or 0
    self.Param.CurShowIndex = Param.CurShowIndex or self.Param.CurShowIndex or 0
    if Param.IsVertical ~= nil then
        self.Param.IsVertical = Param.IsVertical
    end
    self.Param.ColNum = Param.ColNum or self.Param.ColNum or 1
    self.Param.RowNum = Param.RowNum or self.Param.RowNum or 1
    self.Param.Callback = Param.Callback or self.Param.Callback or nil
    self.Param.ControlMode = Param.ControlMode or self.Param.ControlMode or CommonListWASDControl.ControlModeEnum.ALL
    self.Param.ControlRule = Param.ControlRule or self.Param.ControlRule or CommonListWASDControl.ControlRuleEnum.Default
    self.Param.CustomRuleMap = Param.CustomRuleMap or self.Param.CustomRuleMap or {}
    
    self.CurShowIndex = self.Param.CurShowIndex
end

function CommonListWASDControl:OnInit(Param)
    self:ParamSet(Param)

    self.MsgList =
    {
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Left), Func = Bind(self,self.OnDiectionKeyLeftRightControlClick,-1) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Right), Func = Bind(self,self.OnDiectionKeyLeftRightControlClick,1) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Down), Func = Bind(self,self.OnDiectionKeyUpDownControlClick,1) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Up), Func = Bind(self,self.OnDiectionKeyUpDownControlClick,-1) },
        
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A), Func = Bind(self,self.OnADControlClick,-1) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self,self.OnADControlClick,1) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.S), Func = Bind(self,self.OnWSControlClick,1) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.W), Func = Bind(self,self.OnWSControlClick,-1) },
    }
end

function CommonListWASDControl:OnShow(Param)
    --self:UpdateUI(Param)
end
function CommonListWASDControl:OnHide()
end
function CommonListWASDControl:UpdateParam(Param)
    self:ParamSet(Param)
end


function CommonListWASDControl:OnWSControlClick(Value)
    if self.Param.ControlMode == CommonListWASDControl.ControlModeEnum.JUST_DirectionKeys then
        return false
    end
    return self:OnWSControlClickInner(Value)
end

function CommonListWASDControl:OnADControlClick(Value)
    if self.Param.ControlMode == CommonListWASDControl.ControlModeEnum.JUST_DirectionKeys then
        return false
    end
    return self:OnADControlClickInner(Value)
end

function CommonListWASDControl:OnDiectionKeyUpDownControlClick(Value)
    if self.Param.ControlMode == CommonListWASDControl.ControlModeEnum.JUST_WASD then
        return false
    end
    return self:OnWSControlClickInner(Value)
end

function CommonListWASDControl:OnDiectionKeyLeftRightControlClick(Value)
    if self.Param.ControlMode == CommonListWASDControl.ControlModeEnum.JUST_WASD then
        return false
    end
    return self:OnADControlClickInner(Value)
end

--[[
    Value 1表示下 -1表示上   (上下)
]]
function CommonListWASDControl:OnWSControlClickInner(Value)
    --1.如果有特殊规则走特殊逻辑
    if self.Param.ControlRule == CommonListWASDControl.ControlRuleEnum.CustomRule then        
        return self:CustomWSControlClickInner(Value)
    end

    --2.否则走默认逻辑
    if self.Param.IsVertical == false and self.Param.RowNum <= 1 then
        --水平，但是不是多行，不响应
        return false
    end
    if self.Param.IsVertical then
        Value = Value * self.Param.ColNum
    end
    self:OnControlValueChange(Value)
    return true
end

--[[
    Value -1 表示左 1表示右   （左右）
]]
function CommonListWASDControl:OnADControlClickInner(Value)
    --1.如果有特殊规则走特殊逻辑
    if self.Param.ControlRule == CommonListWASDControl.ControlRuleEnum.CustomRule then        
        return self:CustomADControlClickInner(Value)
    end
    
    --2.否则走默认逻辑
    if self.Param.IsVertical and self.Param.ColNum <= 1 then
        --垂直，但是不是多列，不响应
        return false
    end
    if not self.Param.IsVertical then
        Value = Value * self.Param.RowNum
    end
    self:OnControlValueChange(Value)
    return true
end

function CommonListWASDControl:OnControlValueChange(Value)
    --CWaring("OnControlValueChange:Value" .. Value)
    self.CurShowIndex = self.CurShowIndex + Value
    if self.CurShowIndex > 0 then
        self.CurShowIndex = self.CurShowIndex % self.Param.DataListSize
        if self.CurShowIndex == 0 then
            self.CurShowIndex = self.Param.DataListSize
        end
    else
        self.CurShowIndex = math.abs(self.CurShowIndex) % self.Param.DataListSize
        self.CurShowIndex = self.Param.DataListSize - self.CurShowIndex
    end
    --CWaring("OnControlValueChange:CurShowIndex" .. self.CurShowIndex)
    if self.Param.Callback then
        self.Param.Callback(self.CurShowIndex)
    end
end

--region Custom Rule

---@param Value number 参数 1表示下 -1表示上
---@return boolean 是否执行成功
function CommonListWASDControl:CustomWSControlClickInner(Value)
    local ControlMap = self.Param.CustomRuleMap
    if not ControlMap or not next(ControlMap) then return false end
    
    local CurrentNodeMap = ControlMap[self.CurShowIndex]
    if not CurrentNodeMap or not next(CurrentNodeMap) then return false end

    local Next
    if Value == -1 then
        Next = CurrentNodeMap.Top
    else
        Next = CurrentNodeMap.Bottom
    end
    if not Next then return false end

    self:CustomOnControlValueChange(Next)
    return true
end

---@param Value number 参数 -1表示左 1表示右
---@return boolean 是否执行成功
function CommonListWASDControl:CustomADControlClickInner(Value)
    local ControlMap = self.Param.CustomRuleMap        
    if not ControlMap or not next(ControlMap) then return false end
    
    local CurrentNodeMap = ControlMap[self.CurShowIndex]
    if not CurrentNodeMap or not next(CurrentNodeMap) then return false end

    local Next
    if Value == 1 then
        Next = CurrentNodeMap.Right
    else
        Next = CurrentNodeMap.Left
    end
    if not Next then return false end

    self:CustomOnControlValueChange(Next)
    return true
end

---@param newShowIndex number 新的索引位置
function CommonListWASDControl:CustomOnControlValueChange(newShowIndex)
    CLog("[cw] CommonListWASDControl:CustomOnControlValueChange(" .. string.format("%s", newShowIndex) .. ")")
    self.CurShowIndex = newShowIndex

    if self.Param.Callback then
        self.Param.Callback(self.CurShowIndex)
    end
end

--endregion CustomRule

return CommonListWASDControl
