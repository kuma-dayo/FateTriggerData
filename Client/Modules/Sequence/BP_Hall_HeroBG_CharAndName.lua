--[[
    英雄名称和名字的背景板  代理Lua类
]]
local BP_Hall_HeroBG_CharAndName = Class()

function BP_Hall_HeroBG_CharAndName:ReceiveBeginPlay()
	CLog("BP_Hall_HeroBG_CharAndName: BeginPlay")
	self.Overridden.ReceiveBeginPlay(self)

    CommonUtil.DoMvcEntyAction(function ()
        MvcEntry:GetModel(HallModel):AddListener(HallModel.TRIGGER_BP_Hall_HeroBg_CharAndName_SHOWOROUT,self.ON_TRIGGER_BP_Hall_HeroBG_CharAndName_SHOWOROUT,self)
        MvcEntry:GetModel(ViewModel):AddListener(ViewConst.HeroPreView,self.OnHeroPreViewShowOrHide,self)
    end)
end


function BP_Hall_HeroBG_CharAndName:ReceiveEndPlay(EndPlayReason)
    self.Overridden.ReceiveEndPlay(self,EndPlayReason)	
    MvcEntry:GetModel(HallModel):RemoveListener(HallModel.TRIGGER_BP_Hall_HeroBg_CharAndName_SHOWOROUT,self.ON_TRIGGER_BP_Hall_HeroBG_CharAndName_SHOWOROUT,self)
    MvcEntry:GetModel(ViewModel):RemoveListener(ViewConst.HeroPreView,self.OnHeroPreViewShowOrHide,self)
end


--[[
    接收到事件，来隐藏或者显示背景板
]]
function BP_Hall_HeroBG_CharAndName:ON_TRIGGER_BP_Hall_HeroBG_CharAndName_SHOWOROUT(Value)
    self:TriggerShowOrHideInner(Value)
end

--[[
    角色预览界面打开时，需要隐藏背景板
    角色预监界面关闭时，需要显示背景板
]]
function BP_Hall_HeroBG_CharAndName:OnHeroPreViewShowOrHide(Value)
    self:TriggerShowOrHideInner(not Value)
end

function BP_Hall_HeroBG_CharAndName:TriggerShowOrHideInner(Value)
    --TODO 调用蓝图方法
    if Value then
        self:TriggerShow()
    else
        self:TriggerHide()
    end
end

return BP_Hall_HeroBG_CharAndName