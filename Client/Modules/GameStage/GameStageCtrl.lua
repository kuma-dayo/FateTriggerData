--[[
    用于处理游戏阶段
]]

local class_name = "GameStageCtrl";
---@class GameStageCtrl : UserGameController
GameStageCtrl = GameStageCtrl or BaseClass(UserGameController,class_name);

-- 进战斗Travel失败情况枚举
GameStageCtrl.TRAVEL_FAILED_ENUM = {
    BEFORE_PRELOADMAP = 1,	-- 战斗地图还未开始Load
}

function GameStageCtrl:__init()
end

function GameStageCtrl:Initialize()

end


function GameStageCtrl:AddMsgListenersUser()
    self.MsgList = {
        { Model = ViewModel, MsgName = ViewConst.LevelStartup,    Func = self.OnLevelStartupState },
        { Model = ViewModel, MsgName = ViewConst.VirtualLogin,    Func = self.OnVirtualLoginState },
        { Model = ViewModel, MsgName = ViewConst.VirtualHall,    Func = self.OnVirtualHallState },
        { Model = ViewModel, MsgName = ViewConst.LevelHall,    Func = self.OnLevelHallState },
        { Model = ViewModel, MsgName = ViewConst.LevelBattle,    Func = self.OnLevelBattleState },
        { Model = CommonModel, MsgName = CommonModel.ON_LEVEL_BATTLE_START_TRAVEL,    Func = self.ON_LEVEL_BATTLE_START_TRAVEL_Func },
        { Model = ViewModel, MsgName = ViewModel.ON_VIEW_ON_SHOW .. ViewConst.LevelBattle,    Func = self.OnLevelBattleOnShow },

        { Model = CommonModel, MsgName = CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP,    Func = self.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP_Func,Priority = 2 },
    }
end

function GameStageCtrl:OnLevelStartupState(State)
    if State then
        CWaring("SetGameStageType:" .. UE.EGameStageType.Startup)
        _G.GameInstance:SetGameStageType(UE.EGameStageType.Startup)
    end
end

--[[
    需要注意，虚拟关卡，依赖真实关卡加载后，State才会变化
    所以当你Open虚拟关卡时，state变化并不是单帧生效
]]
function GameStageCtrl:OnVirtualLoginState(State)
    CommonUtil.g_in_play = not State

    if not State then
        --欢迎界面不可见时，表示进入游戏了
        CommonUtil.g_in_playing = true
    else
        local ViewModel = self:GetModel(ViewModel)
        if ViewModel.last_LEVEL_Fix == ViewConst.VirtualHall or ViewModel.last_LEVEL_Fix == ViewConst.LevelBattle then
            CWaring("SetGameStageType:" .. UE.EGameStageType.Login)
            _G.GameInstance:SetGameStageType(UE.EGameStageType.Login)
        end
    end
end

function GameStageCtrl:OnLevelHallState(State)
    if not State then
        return
    end
    local ViewModel = self:GetModel(ViewModel)
    if ViewModel.last_LEVEL_Fix == ViewConst.LevelStartup then
        --即将从startup进入到登录
        CWaring("SetGameStageType:" .. UE.EGameStageType.Login)
        _G.GameInstance:SetGameStageType(UE.EGameStageType.Login)
    elseif ViewModel.last_LEVEL_Fix == ViewConst.LevelBattle then
        --即将从战斗返回大厅
        CWaring("SetGameStageType:" .. UE.EGameStageType.Lobby)
        _G.GameInstance:SetGameStageType(UE.EGameStageType.Lobby)
        CWaring("CommonEvent.ON_PRE_BACK_TO_HALL")
        self:SendMessage(CommonEvent.ON_PRE_BACK_TO_HALL)
    end
end
--[[
    需要注意，虚拟关卡，依赖真实关卡加载后，State才会变化
    所以当你Open虚拟关卡时，state变化并不是单帧生效
    加载之后触发
]]
function GameStageCtrl:OnVirtualHallState(State)
    if State then
        local ViewModel = self:GetModel(ViewModel)
        if ViewModel.last_LEVEL_Fix == ViewConst.LevelBattle then
            CWaring("CommonEvent.ON_AFTER_BACK_TO_HALL")
            self:SendMessage(CommonEvent.ON_AFTER_BACK_TO_HALL)
        elseif ViewModel.last_LEVEL_Fix == ViewConst.VirtualLogin then
            --从登录到大厅
            CWaring("SetGameStageType:" .. UE.EGameStageType.Lobby)
            _G.GameInstance:SetGameStageType(UE.EGameStageType.Lobby)
        end
    end
end

function GameStageCtrl:OnLevelBattleState(State)
    if not State then
        return
    end
    ---@type ViewModel
    local ViewModel = self:GetModel(ViewModel)
    if ViewModel.last_LEVEL_Fix == ViewConst.VirtualHall then
        CWaring("CommonEvent.ON_PRE_ENTER_BATTLE")
        self:SendMessage(CommonEvent.ON_PRE_ENTER_BATTLE)
    end
end
function GameStageCtrl:ON_LEVEL_BATTLE_START_TRAVEL_Func()
    CWaring("SetGameStageType:" .. UE.EGameStageType.Travel2Battle)
    _G.GameInstance:SetGameStageType(UE.EGameStageType.Travel2Battle)
end

function GameStageCtrl:OnLevelBattleOnShow()
    CWaring("SetGameStageType:" .. UE.EGameStageType.Battle)
    _G.GameInstance:SetGameStageType(UE.EGameStageType.Battle)
    CWaring("CommonEvent.ON_AFTER_ENTER_BATTLE")
    self:SendMessage(CommonEvent.ON_AFTER_ENTER_BATTLE)
end

--[[
    战斗地图停止Travel（战斗地图还未开始Load，由于网络原因Trave行为被停止了）
]]
function GameStageCtrl:ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP_Func()
    _G.GameInstance:SetGameStageType(UE.EGameStageType.Lobby)
    CWaring("GameStageCtrl.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP_Func")
    local Param = {
        TravelFailedResult = GameStageCtrl.TRAVEL_FAILED_ENUM.BEFORE_PRELOADMAP,
    }
    self:SendMessage(CommonEvent.ON_PRE_BACK_TO_HALL,Param)
    self:SendMessage(CommonEvent.ON_AFTER_BACK_TO_HALL,Param)

    UE.UAsyncLoadingScreenLibrary.StopLoadingScreen();

    --TODO 需要检查并跳转到大厅界面
    InputShieldLayer.Close()
    MvcEntry:GetCtrl(ViewJumpCtrl):HallTabSwitch(CommonConst.HL_PLAY)
end