--[[
    我向别人发起的申请入队请求列表 数据模型
]]
local super = ListModel;
local class_name = "TeamRequestModel";

TeamRequestModel = BaseClass(super, class_name);
TeamRequestModel.ON_APPEND_TEAM_REQUEST = "ON_APPEND_TEAM_REQUEST"

function TeamRequestModel:__init()
    self:DataInit()
end

--[[
    玩家登出时调用
]]
function TeamRequestModel:OnLogout(data)
    TeamRequestModel.super.OnLogout(self)
    self:DataInit()
end

--[[
    重写父方法，返回唯一Key
    Vo结构 参考 TeamApplyRsp
]]
function TeamRequestModel:KeyOf(Vo)
    if self:IsValidOf(Vo) then
        return Vo["ApplyInfo"]["TeamId"]
    else
        return nil 
    end
end

function TeamRequestModel:IsValidOf(Vo)
    return Vo["ApplyInfo"] ~= nil and Vo["ApplyInfo"]["TeamId"] ~= nil
end

function TeamRequestModel:DataInit()
    
end


return TeamRequestModel;