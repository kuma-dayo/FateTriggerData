--[[
    通用的按钮扩展  针对View为GUIButton
    目前扩展
    鼠标右键点击
]]
local class_name = "CommonButtonExtend"
CommonButtonExtend = CommonButtonExtend or BaseClass(nil, class_name)

function CommonButtonExtend:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.OnClicked,				Func = Bind(self,self.OnClicked_Func) },
        { UDelegate = self.View.OnHovered,				Func = Bind(self,self.OnHovered_Func) },
        { UDelegate = self.View.OnUnhovered,				Func = Bind(self,self.OnUnhovered_Func) },
	}
    self.MsgList = {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.RightMouseButton),	Func = self.RightMouseButtonPressFunc },
        {Model = InputModel, MsgName = ActionReleased_Event(ActionMappings.RightMouseButton),	Func = self.RightMouseButtonReleasedFunc },
        {Model = CommonModel, MsgName = CommonModel.CommonButtonExtend_OnHover,	Func = self.CommonButtonExtend_OnHover_Func },
	}
end

--[[
    Param结构指引
	{
		ClickFunc
        RightClickFunc
	}
]]
function CommonButtonExtend:OnShow(Param)
    self.Param = Param
    self.IsHover = false
end

function CommonButtonExtend:OnHide()
    self:CleanHoverFixTimer()
end


function CommonButtonExtend:OnClicked_Func()
    if self.Param and self.Param.ClickFunc then
        self.Param.ClickFunc()
    end
end

function CommonButtonExtend:CommonButtonExtend_OnHover_Func(ButtonUID)
    local UniqueId = UE.UGFUnluaHelper.GetObjectUniqueID(self.View)
    if UniqueId ~= ButtonUID then
        self:CleanHoverFixTimer()
        self.IsHoverFix = false
        self.IsHover = false
    end
end

function CommonButtonExtend:OnHovered_Func()
    -- CWaring("==============OnHovered_Func")
    self.IsHover = true
    self.IsHoverFix = true
    self:CleanHoverFixTimer()

    local UniqueId = UE.UGFUnluaHelper.GetObjectUniqueID(self.View)
    MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.CommonButtonExtend_OnHover,UniqueId)
end
--[[
    OnUnhovered 当玩家鼠标右键按下时，这个时候会认为是鼠标离开，所以会触发这个事情
    所以通过HoverFixTimer行为去Fix
]]
function CommonButtonExtend:OnUnhovered_Func()
    -- CWaring("==============OnUnhovered_Func")
    self.IsHover = false
    self:ScheduleHoverFix(0.2)
end

function CommonButtonExtend:ScheduleHoverFix(duration)
    self:CleanHoverFixTimer()
    self.HoverFixTimer = Timer.InsertTimer(duration,function()
        self.HoverFixTimer = nil
        self.IsHoverFix = false
	end)   
end
function CommonButtonExtend:CleanHoverFixTimer()
    if self.HoverFixTimer then
        Timer.RemoveTimer(self.HoverFixTimer)
    end
    self.HoverFixTimer = nil
end

function CommonButtonExtend:RightMouseButtonPressFunc()
    -- CWaring("==============RightMouseButtonPressFunc")
    self.IsRightMouseButtonPress = true
end

function CommonButtonExtend:RightMouseButtonReleasedFunc()
    if not self.IsRightMouseButtonPress then
        return
    end
    self.IsRightMouseButtonPress = false
    if self.IsHoverFix then
        -- CWaring("==============RightMouseButtonReleasedFunc")
        if self.Param and self.Param.ClickFunc then
            self.Param.RightClickFunc()
        end
    -- else
    --     CWaring("==============RightMouseButtonReleasedFunc2")
    end
end

return CommonButtonExtend
