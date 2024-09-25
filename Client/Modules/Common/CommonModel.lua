--[[
    用于一些游戏内杂项的处理（不适合独立成模块管理的）
]]
local super = GameEventDispatcher;
local class_name = "CommonModel";
---@class CommonModel : GameEventDispatcher
CommonModel = BaseClass(super, class_name);


--普通地图加载完成
CommonModel.ON_LEVEL_POSTLOADMAPWITHWORLD = "ON_LEVEL_POSTLOADMAPWITHWORLD"

--战斗地图停止Travel（战斗地图还未开始Load，由于网络原因Trave行为被停止了）
CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP = "ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP"
--战斗地图开始加载
CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD = "ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD"
--战斗地图加载完成
CommonModel.ON_LEVEL_BATTLE_POSTLOADMAPWITHWORLD = "ON_LEVEL_BATTLE_POSTLOADMAPWITHWORLD"


--从大厅进战斗过程中的，客户端关键步骤
CommonModel.ON_CLIENT_HIT_KEY_STEP = "ON_CLIENT_HIT_KEY_STEP"

CommonModel.ON_ASYNC_LOADING_SHOW_STOP = "ON_ASYNC_LOADING_SHOW_STOP"

--开始Travel战斗
CommonModel.ON_LEVEL_BATTLE_START_TRAVEL = "ON_LEVEL_BATTLE_START_TRAVEL"

CommonModel.ON_SHOWMOUSECURSOR = "ON_SHOWMOUSECURSOR"
CommonModel.ON_WIDGET_TO_FOCUS = "ON_WIDGET_TO_FOCUS"

--大厅Tab按钮切换通知  参数为TabKey 参考通用大厅标签定义
CommonModel.HALL_TAB_SWITCH = "CommonModel.HALL_TAB_SWITCH"
CommonModel.ON_HALL_TAB_SWITCH_COMPLETED = "CommonModel.ON_HALL_TAB_SWITCH_COMPLETED"
CommonModel.HALL_TAB_SWITCH_AFTER_CLOSE_POPS = "CommonModel.HALL_TAB_SWITCH_AFTER_CLOSE_POPS"


--大厅模型自动旋转开始
CommonModel.HALL_AVATAR_AUTO_ROTATE = "HALL_AVATAR_AUTO_ROTATE"

--CommonButtonExtend 组件 按钮OnHover时候的事件
CommonModel.CommonButtonExtend_OnHover = "CommonButtonExtend_OnHover"


--通知局外需要预加载资产发生变化
CommonModel.ON_PRELOAD_OUTSIDE_ASSTE_LIST_NEED_UPDATE = "ON_PRELOAD_OUTSIDE_ASSTE_LIST_NEED_UPDATE"

-- 异步Loading加载开启 - 从大厅准备进战斗
CommonModel.ON_ASYNC_LOADING_START_TO_BATTLE = "ON_ASYNC_LOADING_START_TO_BATTLE"

-- 异步Loading加载完成 - 不区分战斗大厅
CommonModel.ON_ASYNC_LOADING_FINISHED = "ON_ASYNC_LOADING_FINISHED"
-- 异步Loading加载完成 - 战斗中
CommonModel.ON_ASYNC_LOADING_FINISHED_BATTLE = "ON_ASYNC_LOADING_FINISHED_BATTLE"
-- 异步Loading加载完成 - 大厅
CommonModel.ON_ASYNC_LOADING_FINISHED_HALL = "ON_ASYNC_LOADING_FINISHED_HALL"

-- CommonItemIcon 检测跟数量相关的角标变动
CommonModel.CHECK_ITEM_COUNT_CORNER_TAG = "CommonModel.CHECK_ITEM_COUNT_CORNER_TAG"
CommonModel.CHECK_ACHIEVEMENT_CORNER_TAG = "CommonModel.CHECK_ACHIEVEMENT_CORNER_TAG"

-- Avatar准备通知
CommonModel.ON_AVATAR_PREPARE_STATE_NOTIFY = "ON_AVATAR_PREPARE_STATE_NOTIFY"

--着色器预编译相关
--[[
    着色器编译进度更新
    local Param = {
        RemainTasks = 1,
        TotalTasks = 100,
    }
]]
CommonModel.ON_SHADER_PRECOMPILE_UPDATE = "ON_SHADER_PRECOMPILE_UPDATE"
--[[
    着色器编译完成通知
    local Param = {
        TotalTasks = 100,
    }
]]
CommonModel.ON_SHADER_PRECOMPILE_COMPLETE = "ON_SHADER_PRECOMPILE_COMPLETE"

function CommonModel:__init()
    self:_dataInit()
end

function CommonModel:_dataInit()
    
end

--[[
    玩家登出时调用
]]
function CommonModel:OnLogout(data)
    self:_dataInit()
end

return CommonModel;