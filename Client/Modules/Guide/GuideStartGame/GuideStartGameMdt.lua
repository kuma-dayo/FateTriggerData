--[[
    新手引导开始游戏界面
]]

local class_name = "GuideStartGameMdt";
GuideStartGameMdt = GuideStartGameMdt or BaseClass(GameMediator, class_name);

function GuideStartGameMdt:__init()
end

function GuideStartGameMdt:OnShow(data)
end

function GuideStartGameMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = {
        { Model = GuideModel, MsgName = GuideModel.GUIDE_SET_NEXT_STEP,    Func = self.OnGuideStepComplete },
        { Model = GuideModel, MsgName = GuideModel.GUIDE_CLOSE_POPUP,    Func = self.OnGuideStepComplete },
    }
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
   self:OnPlayerInAnimation()
end

function M:OnRepeatShow(Param)
    
end

-- 播放入场动画
function M:OnPlayerInAnimation()
    if self.VXE_Guide_Start_In then
        self:VXE_Guide_Start_In()
    end
end

-- 播放离场动画
function M:OnPlayerOutAnimation()
    if self.VXE_Guide_Start_Out then
        self:VXE_Guide_Start_Out()
    end
end

-- 关闭弹窗
function M:OnClosePop()
    local Animation = self["vx_guide_start_out"]
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

-- 关闭弹窗 
function M:OnGuideStepComplete()
    self:OnClosePop()
end


-- 关闭界面
function M:OnClose()
    MvcEntry:CloseView(self.viewId)
end

return M
