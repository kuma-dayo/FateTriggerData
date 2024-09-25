--[[
    静态绑定到WBP_Common_BtnTipsIcon的代码
    用于统一控制按钮键位图标显隐
]]

require "UnLua"
-- 特殊获得弹窗 场景背景板
local CommonBtnTipsIcon = Class()

function CommonBtnTipsIcon:Construct()
    CLog("CommonBtnTipsIcon: Construct")
	self.Overridden.Construct(self)
    CommonUtil.DoMvcEntyAction(function ()
        MvcEntry:GetModel(InputModel):AddListener(InputModel.SET_KEYBOARD_ICON_VISIBLE,self.OnSetKeyboardIconVisible,self)
    end)
    self:OnSetKeyboardIconVisible(MvcEntry:GetModel(InputModel):IsPCInput())
end

function CommonBtnTipsIcon:Destruct()
    MvcEntry:GetModel(InputModel):RemoveListener(InputModel.SET_KEYBOARD_ICON_VISIBLE,self.OnSetKeyboardIconVisible,self)
    self.Overridden.Destruct(self)	
end

-- 设置键位图标显隐
function CommonBtnTipsIcon:OnSetKeyboardIconVisible(IsVisible)
    if self.ControlTipsIcon then
        self.ControlTipsIcon:SetVisibility(IsVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
end

function CommonBtnTipsIcon:ReceiveDestroyed()
end

return CommonBtnTipsIcon
