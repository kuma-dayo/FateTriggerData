--[[
    预加载-数据管理
]]

local super = GameEventDispatcher;
local class_name = "PreLoadModel";
---@class PreLoadModel : GameEventDispatcher
---@type PreLoadModel
PreLoadModel = BaseClass(super, class_name);

-- 预加载阶段
PreLoadModel.PRELOADING_STEP = {
    QUIT = -1, -- 提前结束
    NONE = 0,
    ASSET = 1, -- 资产加载
    LEVEL_STREAM = 2, -- 流关卡加载
    FINISH = 99, -- 加载完成
}

-- 开始预加载
PreLoadModel.START_PRELOAD = "START_PRELOAD"
-- 加载中
PreLoadModel.DO_PRELOADING = "DO_PRELOADING"
-- PreloadViewLogic加载表现完成
PreLoadModel.PRELOAD_VIEW_PLAY_FINISH = "PRELOAD_VIEW_PLAY_FINISH"
-- PreloadViewLogic加载提前结束
PreLoadModel.PRELOAD_VIEW_PLAY_QUIT = "PRELOAD_VIEW_PLAY_QUIT"

function PreLoadModel:OnLogout(Param)

end

function PreLoadModel:__init()
    self.PreloadingStep = PreLoadModel.PRELOADING_STEP.NONE
end

function PreLoadModel:SetPreloadStep(Step)
    self.PreloadingStep = Step
	self:DispatchType(PreLoadModel.DO_PRELOADING,Step)
end
function PreLoadModel:GetPreloadStep()
    return self.PreloadingStep
end

function PreLoadModel:IsQuitPreload()
    return self.PreloadingStep == PreLoadModel.PRELOADING_STEP.QUIT
end

--[[
    判断当前预加载行为是否正在工作
]]
function PreLoadModel:IsPreloadWorking()
    if self.PreloadingStep ~= PreLoadModel.PRELOADING_STEP.NONE and self.PreloadingStep ~= PreLoadModel.PRELOADING_STEP.QUIT and self.PreloadingStep ~= PreLoadModel.PRELOADING_STEP.FINISH then
        return true
    end
    return false
end


return PreLoadModel

