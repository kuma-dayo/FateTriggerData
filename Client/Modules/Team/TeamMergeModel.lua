--[[
    合并队伍 发出的合并请求 数据模型
]]
local super = ListModel;
local class_name = "TeamMergeModel";

TeamMergeModel = BaseClass(super, class_name);
TeamMergeModel.ON_APPEND_TEAM_MERGE = "ON_APPEND_TEAM_MERGE"

function TeamMergeModel:__init()
    self:DataInit()
end

--[[
    玩家登出时调用
]]
function TeamMergeModel:OnLogout(data)
    TeamMergeModel.super.OnLogout(self)
    self:DataInit()
end

--[[
    重写父方法，返回唯一Key
    Vo节构 参考 MergeListInfo
]]
function TeamMergeModel:KeyOf(Vo)
    if self:IsValidOf(Vo) then
        -- return Vo["MergeSend"]["PlayerId"]
        return Vo["TeamId"]
    else
        return nil 
    end
end

function TeamMergeModel:IsValidOf(Vo)
    -- return Vo["MergeSend"] ~= nil and Vo["MergeSend"]["PlayerId"] ~= nil
    return Vo["TeamId"] ~= nil and Vo["TeamId"] ~= 0
end

--[[
    重写父方法
]]
function TeamMergeModel:SetDataListFromMap(Map)
    TeamMergeModel.super.SetDataListFromMap(self,Map)
end
--[[
    重写父方法
]]
function TeamMergeModel:Clean()
    TeamMergeModel.super.Clean(self)
    self:DataInit()
end

function TeamMergeModel:DataInit()
end

-- 发出的合并列表发生变化
function TeamMergeModel:OnMergeListChange(TeamIncreInfo)
    if TeamIncreInfo.MergeSendList and TeamIncreInfo.MergeSendList.TeamId > 0 then
        -- 合并接收方的TeamId
        -- 新增
        local MergeListInfo = TeamIncreInfo.MergeSendList
        local CanAppend = self:AppendData(MergeListInfo)
        if CanAppend then
        --     self:OnAppendTeamMerge(MergeListInfo)
            self:DispatchType(TeamMergeModel.ON_APPEND_TEAM_MERGE)
        end
    elseif TeamIncreInfo.TargetId > 0 then
        -- 删除 (这里TargetId 为合并接收方的TeamId)
        self:DeleteData(TeamIncreInfo.TargetId)
        -- self:DispatchType(TeamMergeModel.ON_OPERATE_TEAM_MERGE,TeamIncreInfo.TeamId)
    end
end

--[[
    发出的合并队伍待定列表 增加数据
]]
function TeamMergeModel:OnAppendTeamMerge(MergeListInfo)
    -- 队长和队员都要同步申请者到侧边栏以及待定列表
    self:DispatchType(TeamMergeModel.ON_APPEND_TEAM_MERGE,MergeListInfo)
end

function TeamMergeModel:OnGetOtherTeamInfo(TeamInfo)
    if not TeamInfo or TeamInfo.TeamId == 0 then
        return
    end
    local Data = self:GetData(TeamInfo.TeamId)
    if Data then
        Data.Members = TeamInfo.Members
        self:SetIsChange(true)
    end
end

return TeamMergeModel;