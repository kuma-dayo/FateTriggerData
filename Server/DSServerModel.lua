local super = GameEventDispatcher;
local class_name = "DSServerModel";
DSServerModel = BaseClass(super, class_name);

--DS即将被关闭事件通知
DSServerModel.ON_DEDICATED_SERVER_END = "ON_DEDICATED_SERVER_END"
--DS游戏玩法结束通知
DSServerModel.ON_DEDICATED_GAMEOVER = "ON_DEDICATED_GAMEOVER"

function DSServerModel:__init()
    self:DataInit()
end

function DSServerModel:DataInit()
end

return DSServerModel;