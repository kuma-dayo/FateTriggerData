--[[
   UIHandler解耦逻辑类  基类
]] 
local class_name = "UIHandlerViewBase"
UIHandlerViewBase = BaseClass(nil, class_name)

function UIHandlerViewBase:OnInit()
end
function UIHandlerViewBase:OnShow(Param)
end
function UIHandlerViewBase:OnManualShow(Param)
end
function UIHandlerViewBase:OnManualHide(Param)
end
function UIHandlerViewBase:OnHide(Param)
end
--[[
	@param Data 自定义参数，首次创建时可能存在值
	@param IsNotVirtualTrigger 是否  不是因为虚拟场景切换触发的
		true  表示为初始化创建
		false 表示为虚拟场景切换触发
]]
function UIHandlerViewBase:OnShowAvator(Data,IsNotVirtualTrigger) end
function UIHandlerViewBase:OnHideAvator(Data,IsNotVirtualTrigger) end

function UIHandlerViewBase:OnDestroy(Data,IsNotVirtualTrigger)
end


return UIHandlerViewBase
