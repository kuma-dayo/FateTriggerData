
local super = ListModel;
local class_name = "GuideModel";

---@class GuideModel : ListModel
---@field private super ListModel
GuideModel = BaseClass(super, class_name);

-- 引导步骤完成
GuideModel.GUIDE_STEP_COMPLETE = "GUIDE_STEP_COMPLETE"
-- 引导步骤关闭弹窗
GuideModel.GUIDE_CLOSE_POPUP = "GUIDE_CLOSE_POPUP"
-- 当前引导完成，设置到下一个阶段  携带引导类型ID
GuideModel.GUIDE_SET_NEXT_STEP = "GUIDE_SET_NEXT_STEP"
-- 当前引导完成，设置到下一个阶段  携带引导类型ID
GuideModel.GUIDE_SET_NEXT_STEP = "GUIDE_SET_NEXT_STEP"
-- 检测新手引导触发事件
GuideModel.CHECK_GUIDE_SHOW_EVENT = "CHECK_GUIDE_SHOW_EVENT"

GuideModel.Enum_GuideStep = {
    -- 选择按键方案
    ChooseKeyScheme = 0,
    -- 开始游戏
    StartGame = 1,
    -- 结算指引
    Settlement = 2,
    -- 选择性别
    ChooseGender = 3,
    -- 引导完成
    GuideComplete = 4,
}
-- 新手引导相关数据
local Const_GuideData = {
    [GuideModel.Enum_GuideStep.ChooseKeyScheme] = {
        OpenViewId = ViewConst.GuideKeySelectionMainPanel,
    },
    [GuideModel.Enum_GuideStep.StartGame] = {
        OpenViewId = ViewConst.GuideStartGame,
    },
    [GuideModel.Enum_GuideStep.Settlement] = {
        OpenViewId = ViewConst.GuideSettlement,
        CheckGuideViewId = ViewConst.HallSettlement
    },
    [GuideModel.Enum_GuideStep.ChooseGender] = {
        OpenViewId = ViewConst.GuideChooseGender,
    },
}

function GuideModel:__init()
    self:_dataInit()
end

function GuideModel:_dataInit()
    -- GM新手引导开启状态 不为nil时优先取值
    self.GMGuideOpenState = nil
    self:InitCheckGuideViewList()
end

-- 初始化检测新手引导界面ID列表
function GuideModel:InitCheckGuideViewList()
    self.CheckGuideViewIdList = {}
    for _, GuideData in pairs(Const_GuideData) do
        if GuideData.CheckGuideViewId then
            self.CheckGuideViewIdList[GuideData.CheckGuideViewId] = true
        end
    end
end

--- 玩家登出时调用
---@param data any
function GuideModel:OnLogout(data)
    GuideModel.super.OnLogout(self)
    self:_dataInit()
end

--- 重写父方法,返回唯一Key
---@param vo any
function GuideModel:KeyOf(vo)
    return vo["GuideType"]
end

--- 重写父类方法,如果数据发生改变
--- 进行通知到这边的逻辑
---@param vo any
function GuideModel:SetIsChange(value)
    GuideModel.super.SetIsChange(self, value)
end

-- 设置GM引导开启状态
function GuideModel:SetGMGuideOpenState(GMGuideOpenState)
    self.GMGuideOpenState = GMGuideOpenState
end

--- 检测是否开启新手引导
---@return boolean 
function GuideModel:CheckIsOpenGuide()
    local IsOpenGuide = false
    if self.GMGuideOpenState ~= nil then
        IsOpenGuide = self.GMGuideOpenState
    else
        if CommonUtil.IsShipping() and (MvcEntry:GetModel(LoginModel):IsSDKLogin() or MvcEntry:GetCtrl(OnlineSubCtrl):IsOnlineEnabled()) then
            IsOpenGuide = true
        end
    end
    return IsOpenGuide
end

-- 获取当前可显示的新手引导步骤
function GuideModel:GetCurrentShowGuideStep(GuideType)
    local GuideStep = nil
    local GuideData = self:GetData(GuideType)
    if GuideData and GuideData.GuideStep then
        GuideStep =  GuideData.GuideStep
    end
    return GuideStep
end

-- 检测是否新手引导界面ID
function GuideModel:CheckIsGuideViewId(ViewId)
    local IsGuideViewId = false
    if self.CheckGuideViewIdList[ViewId] then
        IsGuideViewId = true
    end
    return IsGuideViewId
end

-- 获取当前需要展示的新手引导数据
function GuideModel:GetCurrentGuideConfigData(GuideType)
    local GuideConfigData = nil
    local GuideStep = self:GetCurrentShowGuideStep(GuideType)
    if GuideStep and Const_GuideData[GuideStep] then
        GuideConfigData = Const_GuideData[GuideStep]
    end
    return GuideConfigData
end

return GuideModel;
