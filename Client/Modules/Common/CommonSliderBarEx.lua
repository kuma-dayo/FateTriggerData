--[[
    WBP_SliderBarEx 逻辑类
]]

local class_name = "CommonSliderBarEx"
CommonSliderBarEx = CommonSliderBarEx or BaseClass(nil, class_name)

function CommonSliderBarEx:OnInit()
    self.PlatformName = UE.UGameplayStatics.GetPlatformName()
    self.BindNodes = {
        { UDelegate = self.View.Slider.OnValueChanged, Func = Bind(self, self.OnSliderValueChanged) },
        { UDelegate =  self.View.Slider.OnMouseCaptureBegin,Func = Bind(self,self.OnMouseCaptureBeginFunc)},
        { UDelegate =  self.View.Slider.OnMouseCaptureEnd,Func = Bind(self,self.OnMouseCaptureEndFunc)},
        { UDelegate =  self.View.Slider.OnControllerCaptureEnd,Func = Bind(self,self.OnControllerCaptureEndFunc)},
    }
    self:SetValue(0)
end

--[[
    Param = {
        OnValueChangeFunc  -- slider数值变化回调
        IsShowPoint -- 是否展示百分比点（并开启吸附功能） 默认关闭
        PointLimitValue -- 吸附边界值 默认为10 IsShowPoint 开启才有效
    }
    
]]
function CommonSliderBarEx:OnShow(Param)
	self.Param = Param
    if not self.Param then
        CError("CommonSliderBarEx: Param Error. Please Check! ",true)
        return
    end
    -- 开启百分点吸附
    if self.Param.IsShowPoint then
        self.View.Panel_Point:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.Param.PointLimitValue = self.Param.PointLimitValue or 10 
    end
end

function CommonSliderBarEx:SetValue(Value)
    self.View:SetValue(Value)
end

function CommonSliderBarEx:GetValue()
    return self.View:GetValue()
end

function CommonSliderBarEx:OnSliderValueChanged(_,Value)
    if self.Param.OnValueChangeFunc then
        self.Param.OnValueChangeFunc(Value)
    end
end

-- 监听开始点击的鼠标位置
function CommonSliderBarEx:OnMouseCaptureBeginFunc()
    local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
    self.MouseStartPosX = MousePos.X
end

-- 监听完成拖动
function CommonSliderBarEx:OnMouseCaptureEndFunc()
    local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
    if self.MouseStartPosX and math.abs(MousePos.X - self.MouseStartPosX) < 2 then
        -- 点击（非拖动），判断吸附点
        local CurValue = self.View:GetValue()
        local Point = 0
        while Point <= 100 do
            -- 小于边界值则吸附
            if math.abs(CurValue*100 - Point) < self.Param.PointLimitValue then
                self.View:SetValue(Point/100)
                break
            end
            Point = Point + 25
        end
    end
end

function CommonSliderBarEx:OnControllerCaptureEndFunc()
    -- TODO
end

function CommonSliderBarEx:OnHide()
    self.Param = nil
end

return CommonSliderBarEx
