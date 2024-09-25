--[[
    合并队伍 收到的合并请求 数据模型
]]
local super = ListModel;
local class_name = "TeamMergeApplyModel";

TeamMergeApplyModel = BaseClass(super, class_name);
TeamMergeApplyModel.ON_APPEND_TEAM_MERGE = "ON_APPEND_TEAM_MERGE"
TeamMergeApplyModel.ON_APPEND_TEAM_MERGE_FOR_CAPTAIN = "ON_APPEND_TEAM_MERGE_FOR_CAPTAIN"
TeamMergeApplyModel.ON_OPERATE_TEAM_MERGE = "ON_OPERATE_TEAM_MERGE"
function TeamMergeApplyModel:__init()
    self:DataInit()
end

--[[
    玩家登出时调用
]]
function TeamMergeApplyModel:OnLogout(data)
    TeamMergeApplyModel.super.OnLogout(self)
    self:DataInit()
end

--[[
    重写父方法，返回唯一Key
    Vo节构 参考 MergeListInfo
]]
function TeamMergeApplyModel:KeyOf(Vo)
    if self:IsValidOf(Vo) then
        -- return Vo["MergeSend"]["PlayerId"]
        return Vo["TeamId"]
    else
        return 0 
    end
end

function TeamMergeApplyModel:IsValidOf(Vo)
    -- return Vo["MergeSend"] ~= nil and Vo["MergeSend"]["PlayerId"] ~= nil
    return Vo["TeamId"] ~= nil and Vo["TeamId"] ~= 0
end

--[[
    重写父方法，数据变动更新子类数据
]]
function TeamMergeApplyModel:SetIsChange(value)
    TeamMergeApplyModel.super.SetIsChange(self,value)
    if value then
        self.TeamMergeList = {}
    end
end
--[[
    重写父方法
]]
function TeamMergeApplyModel:SetDataListFromMap(Map)
    self.TeamMergeList = {}
    TeamMergeApplyModel.super.SetDataListFromMap(self,Map)
end
--[[
    重写父方法
]]
function TeamMergeApplyModel:Clean()
    TeamMergeApplyModel.super.Clean(self)
    self:DataInit()
end
--[[
    重写父方法
]]
function TeamMergeApplyModel:DeleteData(TeamId)
    TeamMergeApplyModel.super.DeleteData(self,TeamId)
    self:DeleteTeamMergeTips(TeamId)
end

function TeamMergeApplyModel:DataInit()
    self.TeamMergeList = {}
    self.MergeTipsList = {}
end

--[[
    获取申请入队请求列表数据
]]
function TeamMergeApplyModel:GetTeamMergeDataList()
    local IsCaptian = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain(true)
    if not IsCaptian then
        -- 不是队长无法处理入队请求
        return {}
    end
    if #self.TeamMergeList == 0 then
        self.TeamMergeList = {}
        local DataList = self:GetDataList()
        for k,MergeListInfo in ipairs(DataList) do
            local ShowData = self:TransformToFriendShowData(MergeListInfo)
            table.insert(self.TeamMergeList,ShowData)
        end
        table.sort(self.TeamMergeList,function (a,b)
            return a.Vo.RequestTime < b.Vo.RequestTime
        end)
    end
    return self.TeamMergeList
end

--[[ 
    将协议数据 MergeListInfo 转化为界面所需的Data格式
]]
function TeamMergeApplyModel:TransformToFriendShowData(MergeListInfo)
    local MergeData = {
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST,
        Vo = {
            PlayerId = MergeListInfo.MergeSend.PlayerId,
            Info = MergeListInfo,
            RequestTime = MergeListInfo.RequestTime
        }
    }
    return MergeData
end

-- 合并列表发生变化
function TeamMergeApplyModel:OnMergeApplyListChange(TeamIncreInfo)
    if TeamIncreInfo.MergeRecvList and TeamIncreInfo.MergeRecvList.TeamId > 0 then
        -- 合并发起方的TeamId
        -- 新增
        local MergeListInfo = TeamIncreInfo.MergeRecvList
        local CanAppend = self:AppendData(MergeListInfo)
        if CanAppend then
            self:OnAppendTeamMerge(MergeListInfo)
            return MergeListInfo
        end
    elseif TeamIncreInfo.TargetId > 0 then
        -- 删除 (这里TargetId 为合并发起方的TeamId)
        self:DeleteData(TeamIncreInfo.TargetId)
        self:DispatchType(TeamMergeApplyModel.ON_OPERATE_TEAM_MERGE,TeamIncreInfo.TargetId)
    end
end

--[[
    合并队伍待定列表 增加数据
]]
function TeamMergeApplyModel:OnAppendTeamMerge(MergeListInfo)
    -- 队长和队员都要同步申请者到侧边栏以及待定列表
    self:DispatchType(TeamMergeApplyModel.ON_APPEND_TEAM_MERGE,MergeListInfo)
end


--[[
    只有队长收到的申请弹窗
]]
function TeamMergeApplyModel:OnReceiveTeamMergeTips(TeamMergeSync)
    local IsCaptian = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain()
    if IsCaptian then
        -- 队长才弹出申请弹窗
        self:PushTeamMergeTips(TeamMergeSync)
        if  MvcEntry:GetModel(TeamModel):CanPopTeamTips() then
            -- 不在局内 且 好友数据初始化完成 才调用展示
            self:ShowTeamMergeTips()
        end
        self:DispatchType(TeamMergeApplyModel.ON_APPEND_TEAM_MERGE_FOR_CAPTAIN)
    end
end

--[[
    存储新增的申请合并信息 
]]
function TeamMergeApplyModel:PushTeamMergeTips(TeamMergeSync)
    self.MergeTipsList = self.MergeTipsList or {}
    local Data = {
        PlayerId = TeamMergeSync.MergeSendId,
        TeamId = TeamMergeSync.MergeInfo.SourceTeamId, -- 合并发起方的TeamId
        Info = TeamMergeSync.MergeInfo,
        AddTime = GetTimestamp()
    }
    self.MergeTipsList[#self.MergeTipsList+1] = Data
end

--[[
    删除邀请的信息
]]
function TeamMergeApplyModel:DeleteTeamMergeTips(TeamId)
    if self.MergeTipsList and #self.MergeTipsList> 0 then
        local DeleteIndex = nil
        for Index,Data in ipairs(self.MergeTipsList) do
            if Data.TeamId and Data.TeamId == TeamId then
                DeleteIndex = Index
                break
            end
        end
        if DeleteIndex then
            table.remove(self.MergeTipsList,DeleteIndex)
        end
    end
end

--[[
    获取存储的组队邀请提示信息
]]
function TeamMergeApplyModel:GetTeamMergeTipsData()
    if self.MergeTipsList and #self.MergeTipsList > 0 then
        local Param = {
            TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST,
            Time = self.MergeTipsList[1].AddTime,
            ItemInfoList = self.MergeTipsList,
        }
        self.MergeTipsList = nil
        return Param
    end
end

function TeamMergeApplyModel:ShowTeamMergeTips()
    local Param =self:GetTeamMergeTipsData()
    if Param then
        MvcEntry:OpenView(ViewConst.FriendRequestItemList,{Param})
    end
end

-- 收到更新后的队伍信息，需要更新缓存中的数据
function TeamMergeApplyModel:OnGetOtherTeamInfo(TeamInfo)
    if not TeamInfo or TeamInfo.TeamId == 0 then
        return
    end
    local Data = self:GetData(TeamInfo.TeamId)
    if Data then
        Data.Members = TeamInfo.Members
        self:SetIsChange(true)
    end
end

return TeamMergeApplyModel;