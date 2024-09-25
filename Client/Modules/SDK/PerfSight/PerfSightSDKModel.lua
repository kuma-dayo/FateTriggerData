local super = GameEventDispatcher;
local class_name = "PerfSightSDKModel";

--[[ 
]]
PerfSightSDKModel = BaseClass(super, class_name);

function PerfSightSDKModel:__init()
    self.AppId = ""
end



return PerfSightSDKModel