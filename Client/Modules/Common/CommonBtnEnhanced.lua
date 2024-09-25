--[[
    增强输入按钮
    WBP_CommonBtn_Enhanced 
]]

require "UnLua"
local class_name = "CommonBtnEnhanced"
---@class CommonBtnEnhanced
CommonBtnEnhanced = CommonBtnEnhanced or BaseClass(UIHandlerViewBase, class_name)

function CommonBtnEnhanced:OnInit()
    self.BindNodes = {
        
		{ UDelegate = self.View.OnTap,				    Func = Bind(self, self.OnTapFunc) },
        { UDelegate = self.View.OnHold,				    Func = Bind(self, self.OnHoldFunc) },
        { UDelegate = self.View.OnDoubleClicked,		Func = Bind(self, self.OnDoubleClickedFunc) },
        { UDelegate = self.View.OnPressed,		        Func = Bind(self, self.OnPressedFunc) },
        { UDelegate = self.View.OnReleased,		        Func = Bind(self, self.OnReleasedFunc) },

        --下面这些事件也是可以触发的,
        -- { UDelegate = self.View.GUIButtonItem.OnClicked,		Func = Bind(self, self.OnClickedFunc) },
        -- { UDelegate = self.View.GUIButtonItem.OnPressed,		Func = Bind(self, self.OnPressedBtnFunc) },
        -- { UDelegate = self.View.GUIButtonItem.OnReleased,	Func = Bind(self, self.OnReleasedBtnFunc) },
        -- { UDelegate = self.View.GUIButtonItem.OnHovered,		Func = Bind(self, self.OnHoveredBtnFunc) },
        -- { UDelegate = self.View.GUIButtonItem.OnUnHovered,	Func = Bind(self, self.OnUnHoveredBtnFunc) },
	}

    self.MsgList = {
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.LeftMouseButtonTap), Func = Bind(self, self.LeftMouseButtonTap_Func)},
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.LeftMouseButtonDouble), Func = Bind(self, self.LeftMouseButtonDouble_Func)},
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.LeftMouseButtonHold), Func = Bind(self, self.LeftMouseButtonHold_Func)},
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.RightMouseButton),	    Func = Bind(self, self.RightMouseButtonPress_Func) },
        {Model = InputModel, MsgName = ActionReleased_Event(ActionMappings.RightMouseButton),	    Func = Bind(self, self.RightMouseButtonReleased_Func) },
        {Model = InputModel, MsgName = ActionReleased_Event(ActionMappings.RightMouseButtonTap),    Func = Bind(self, self.RightMouseButtonTap_Func)},
    }
end


--[[
	Param = {
		OnBtnClicked 		    = function() end,					--【可选】鼠标左键点击回调:鼠标左键Pressed后在规定的时间内Released才会触发一次
        OnBtnHold 		        = function() end,					--【可选】鼠标左键Hold(长按)回调::鼠标左键长按规定时间后触发一次
        OnBtnDoubleClicked 	    = function() end,					--【可选】鼠标左键双击回调
        OnBtnPressed 	        = function() end,					--【可选】鼠标左键Pressed回调
        OnBtnReleased 	        = function() end,					--【可选】鼠标左键Released回调
        OnRightBtnPressed      = function() end,					--【可选】鼠标右键Pressed 
        OnRightBtnReleased     = function() end,					--【可选】鼠标右键Released
        OnRightBtnClicked      = function() end,					--【可选】鼠标右键Clicked:鼠标右键Pressed后在规定的时间内Released才会触发一次
	}
]]

function CommonBtnEnhanced:OnShow(Param)
    self:UpdateBtnInfo(Param)
end

function CommonBtnEnhanced:OnManualShow(Param)
    self:UpdateBtnInfo(Param)
end

function CommonBtnEnhanced:UpdateBtnInfo(Param)
    Param = Param or {}
    self.OnBtnClicked = Param.OnBtnClicked
    self.OnBtnHold = Param.OnBtnHold
    self.OnBtnDoubleClicked = Param.OnBtnDoubleClicked
    self.OnBtnPressed = Param.OnBtnPressed
    self.OnBtnReleased = Param.OnBtnReleased

    self.OnRightBtnPressed = Param.OnRightBtnPressed
    self.OnRightBtnReleased = Param.OnRightBtnReleased
    self.OnRightBtnClicked = Param.OnRightBtnClicked
end

function CommonBtnEnhanced:OnManualHide(Param)
    self:UpdateBtnInfo(nil)
end

function CommonBtnEnhanced:OnHide(Param)
    self:UpdateBtnInfo(nil)
end

function CommonBtnEnhanced:OnTapFunc()
    CWaring("CommonBtnEnhanced:OnTapItemFunc !!")

    if self.OnBtnClicked then
        self.OnBtnClicked()
    end
end

function CommonBtnEnhanced:OnHoldFunc()
    CWaring("CommonBtnEnhanced:OnHoldFunc !!")

    if self.OnBtnHold then
        self.OnBtnHold()
    end
end

function CommonBtnEnhanced:OnDoubleClickedFunc()
    CWaring("CommonBtnEnhanced:OnDoubleClickedFunc !!")

    if self.OnBtnDoubleClicked then
        self.OnBtnDoubleClicked()
    end
end

function CommonBtnEnhanced:OnPressedFunc()
    CWaring("CommonBtnEnhanced:OnPressedFunc !!")

    if self.OnBtnPressed then
        self.OnBtnPressed()
    end
end

function CommonBtnEnhanced:OnReleasedFunc()
    CWaring("CommonBtnEnhanced:OnReleasedFunc !!")

    if self.OnBtnReleased then
        self.OnBtnReleased()
    end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- function CommonBtnEnhanced:OnClickedFunc()
--     -- CWaring("CommonBtnEnhanced:OnClickedFunc !!")
--     if self.OnBtnClicked then
--         self.OnBtnClicked()
--     end
-- end

-- function CommonBtnEnhanced:OnPressedBtnFunc()
--     -- CWaring("CommonBtnEnhanced:OnPressedBtnFunc !!")

--     if self.OnBtnPressed then
--         self.OnBtnPressed()
--     end
-- end

-- function CommonBtnEnhanced:OnReleasedBtnFunc()
--     -- CWaring("CommonBtnEnhanced:OnReleasedBtnFunc !!")

--     if self.OnBtnReleased then
--         self.OnBtnReleased()
--     end
-- end

-- function CommonBtnEnhanced:OnHoveredBtnFunc()
--     -- CWaring("CommonBtnEnhanced:OnHoveredBtnFunc !!")
-- end

-- function CommonBtnEnhanced:OnUnHoveredBtnFunc()
--     -- CWaring("CommonBtnEnhanced:OnUnHoveredBtnFunc !!")
-- end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- function CommonBtnEnhanced:LeftMouseButtonTap_Func()
--     CError("CommonBtnEnhanced:LeftMouseButtonTap_Func !!")
-- end

-- function CommonBtnEnhanced:LeftMouseButtonDouble_Func()
--     CError("CommonBtnEnhanced:LeftMouseButtonDouble_Func !!")
-- end

-- function CommonBtnEnhanced:LeftMouseButtonHold_Func()
--     CError("CommonBtnEnhanced:LeftMouseButtonHold_Func !!")
-- end

function CommonBtnEnhanced:RightMouseButtonPress_Func()
    if self.OnRightBtnPressed then
        local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
        local bIsUnder = UE.USlateBlueprintLibrary.IsUnderLocation(self.View:GetCachedGeometry(), MousePos)
        if bIsUnder then
            CWaring("CommonBtnEnhanced:RightMouseButtonPress_Func !!")
            self:OnRightBtnPressed()    
        end
    end
end

function CommonBtnEnhanced:RightMouseButtonReleased_Func()
    if self.OnRightBtnReleased then
        local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
        local bIsUnder = UE.USlateBlueprintLibrary.IsUnderLocation(self.View:GetCachedGeometry(), MousePos)
        if bIsUnder then
            CWaring("CommonBtnEnhanced:RightMouseButtonReleased_Func !!")
            self:OnRightBtnReleased()    
        end
    end
end

function CommonBtnEnhanced:RightMouseButtonTap_Func()
    if self.OnRightBtnClicked then
        local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
        local bIsUnder = UE.USlateBlueprintLibrary.IsUnderLocation(self.View:GetCachedGeometry(), MousePos)
        if bIsUnder then
            CWaring("CommonBtnEnhanced:RightMouseButtonTap_Func !!")
            self:OnRightBtnClicked()    
        end
    end
end

return CommonBtnEnhanced
