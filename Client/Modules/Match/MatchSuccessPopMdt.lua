--[[
    匹配成功弹窗
]]

local class_name = "MatchSuccessPopMdt";
MatchSuccessPopMdt = MatchSuccessPopMdt or BaseClass(GameMediator, class_name);

function MatchSuccessPopMdt:__init()
end

function MatchSuccessPopMdt:OnShow(data)
end

function MatchSuccessPopMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()

    self.MsgList = 
    {
        {Model = MatchModel,  MsgName = MatchModel.ON_DS_ERROR,         			Func = self.ON_DS_ERROR_Func},
        {Model = MatchModel,  MsgName = MatchModel.ON_MATCH_FAIL,         			Func = self.ON_GAMESTART_MATHCANCEL_Func},	--被动取消
        {Model = MatchModel,  MsgName = MatchModel.ON_CONNECT_DS_SERVER,         			Func = self.ON_CONNECT_DS_SERVER_Func},	--链接到DS服务器

        --匹配状态数据
        { Model = MatchModel, MsgName = MatchModel.ON_MATCHING_STATE_CHANGE,Func = self.ON_MATCHING_STATE_CHANGE_func },--匹配状态变动      
	}
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    self:OnPlayerInAnimation()
end

-- 播放入场动画
function M:OnPlayerInAnimation()
    if self.VXE_Hall_Match_Success_In then
        self:VXE_Hall_Match_Success_In()
    end
end

-- 播放离场动画
function M:OnPlayerOutAnimation()
    if self.VXE_Hall_Match_Success_Out then
        self:VXE_Hall_Match_Success_Out()
    end
end

function M:OnRepeatShow(Param)
    
end

function M:OnHide()
   
end

-- 匹配被动取消
function M:ON_GAMESTART_MATHCANCEL_Func()
    self:OnCloseSuccessPop()
end

-- 开始链接到DS服务器
function M:ON_CONNECT_DS_SERVER_Func()
    self:OnCloseSuccessPop()
end

-- 进入DS失败 关闭匹配成功界面
function M:ON_DS_ERROR_Func()
    self:OnCloseSuccessPop()
end

-- 匹配状态变动处理  不等于匹配成功的状态 说明都要关闭界面
function M:ON_MATCHING_STATE_CHANGE_func(Msg)
    if Msg then
        local NewMatchState = Msg.NewMatchState
        -- 非匹配成功的状态 说明显示异常 需要移除界面
        local MatchState = MatchModel.Enum_MatchState
        if Msg.NewMatchState ~= MatchState.MatchSuccess then
            CLog("MatchSuccessPopMdt OnCloseSuccessPop MatchState = " .. Msg.NewMatchState)
            self:OnCloseSuccessPop()
        end 
    end
end

-- 关闭弹窗
function M:OnCloseSuccessPop()
    local Animation = self["vx_hall_match_success_out"]
    if Animation then
        Animation:UnbindAllFromAnimationFinished(self)
        Animation:BindToAnimationFinished(self, function()
            self:OnClick_CloseBtn()
        end)
        self:OnPlayerOutAnimation()
    else
        self:OnClick_CloseBtn()
    end
end

-- 关闭界面
function M:OnClick_CloseBtn()
    MvcEntry:CloseView(self.viewId)
end

return M
