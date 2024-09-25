--[[
    我向别人发起的组队请求列表 数据模型
]]
local super = ListModel;
local class_name = "TeamInviteModel";

---@class TeamInviteModel
TeamInviteModel = BaseClass(super, class_name);
TeamInviteModel.ON_APPEND_TEAM_INVITE = "ON_APPEND_TEAM_INVITE"
function TeamInviteModel:__init()
    self:DataInit()
end

--[[
    玩家登出时调用
]]
function TeamInviteModel:OnLogout(data)
    TeamInviteModel.super.OnLogout(self)
    self:DataInit()
end

--[[
    重写父方法，返回唯一Key
    Vo结构 参考 InviteListInfo
]]
function TeamInviteModel:KeyOf(Vo)
    if self:IsValidOf(Vo) then
        return Vo["Invitee"]["PlayerId"]
    else
        return nil 
    end
end

function TeamInviteModel:IsValidOf(Vo)
    return Vo["Invitee"] ~= nil and Vo["Invitee"]["PlayerId"] ~= nil
end

function TeamInviteModel:DataInit()
    
end

-- 邀请列表发生变化
function TeamInviteModel:OnInviteListChange(TeamIncreInfo)
    local InviteListInfo = TeamIncreInfo.InviteList
    if InviteListInfo and InviteListInfo.Inviter and InviteListInfo.Inviter.PlayerId > 0 then
        -- 新增
        local CanAppend = self:AppendData(InviteListInfo)
        if CanAppend then
            self:DispatchType(TeamInviteModel.ON_APPEND_TEAM_INVITE,InviteListInfo)
        end
    elseif TeamIncreInfo.TargetId > 0 then
        -- 删除
        self:DeleteData(TeamIncreInfo.TargetId)
    end
end

return TeamInviteModel;