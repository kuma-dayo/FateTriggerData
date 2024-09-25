--[[
    新手引导结算指引界面
]]

local class_name = "GuideSettlementMdt";
GuideSettlementMdt = GuideSettlementMdt or BaseClass(GameMediator, class_name);

function GuideSettlementMdt:__init()
end

function GuideSettlementMdt:OnShow(data)
end

function GuideSettlementMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = {
        { Model = GuideModel, MsgName = GuideModel.GUIDE_STEP_COMPLETE,    Func = self.OnGuideStepComplete },
    }
    self.InputFocus = false
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    self:InitMaskSize()
    MvcEntry:GetModel(GuideModel):DispatchType(GuideModel.GUIDE_SET_NEXT_STEP, GuideModel.Enum_GuideStep.Settlement)
    self:OnPlayerInAnimation()
end

-- 根据结算界面按钮宽度设置一下图片大小
function M:InitMaskSize()
    local DefaultViewId = ViewConst.HallSettlement
    local Mdt = MvcEntry:GetCtrl(ViewRegister):GetView(DefaultViewId)
    if Mdt and Mdt.view then
        local BtnContinueSize = Mdt.view:OnGetBtnContinueSize()
        if BtnContinueSize then
            -- 计算长度偏移值
            local InitSizeX = 147.8
            local OffsetX = BtnContinueSize.x - InitSizeX
            OffsetX = OffsetX > 0 and OffsetX or 0
            local Size = self.Overlay_Mask.Slot:GetSize()
            Size.x = Size.x + OffsetX
            self.Overlay_Mask.Slot:SetSize(Size)
        end
    end
end

function M:OnRepeatShow(Param)
    
end

-- 播放入场动画
function M:OnPlayerInAnimation()
    local GuideInEventNameList = {
        [LocalizationModel.IllnLanguageSupportEnum.zhHans] = "VXE_Guide_In",
        [LocalizationModel.IllnLanguageSupportEnum.enUS] = "VXE_Guide_In_EN",
        [LocalizationModel.IllnLanguageSupportEnum.jaJP] = "VXE_Guide_In_JA",
        [LocalizationModel.IllnLanguageSupportEnum.zhHant] = "VXE_Guide_In",
    }
    local LocalLanuage = MvcEntry:GetModel(LocalizationModel):GetCurSelectLanguage()
    local GuideInEventName = LocalLanuage and GuideInEventNameList[LocalLanuage] or "VXE_Guide_In"
    if self[GuideInEventName] then
        self[GuideInEventName](self)
    end
end

-- 播放离场动画
function M:OnPlayerOutAnimation()
    if self.VXE_Guide_Out then
        self:VXE_Guide_Out()
    end
end

-- 新手引导完成关闭弹窗
function M:OnGuideStepComplete()
    self:OnClosePop()
end

-- 关闭弹窗
function M:OnClosePop()
    local Animation = self["vx_guide_out"]
    if Animation then
        Animation:UnbindAllFromAnimationFinished(self)
        Animation:BindToAnimationFinished(self, function()
            self:OnClose()
        end)
        self:OnPlayerOutAnimation()
    else
        self:OnClose()
    end
end

function M:OnHide()
   
end

-- 关闭界面
function M:OnClose()
    MvcEntry:CloseView(self.viewId)
end



return M
