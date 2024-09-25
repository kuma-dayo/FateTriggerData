--[[
    别人发起的申请入队请求列表 数据模型
]]
local super = ListModel;
local class_name = "TeamRequestApplyModel";

TeamRequestApplyModel = BaseClass(super, class_name);
TeamRequestApplyModel.ON_APPEND_TEAM_REQUEST_FOR_CAPTAIN = "ON_APPEND_TEAM_REQUEST_FOR_CAPTAIN"
TeamRequestApplyModel.ON_OPERATE_TEAM_REQUEST = "ON_OPERATE_TEAM_REQUEST"
TeamRequestApplyModel.ON_APPEND_TEAM_REQUEST = "ON_APPEND_TEAM_REQUEST"

function TeamRequestApplyModel:__init()
    self:DataInit()
end

--[[
    重写父方法，返回唯一Key
    Vo结构 ApplyListInfo
]]
function TeamRequestApplyModel:KeyOf(Vo)
    if self:IsValidOf(Vo) then
        return Vo["Applicant"]["PlayerId"]
    else
        return nil 
    end
end

function TeamRequestApplyModel:IsValidOf(Vo)
    return Vo["Applicant"] ~= nil and Vo["Applicant"]["PlayerId"] ~= nil
end

--[[
    重写父方法
]]
function TeamRequestApplyModel:SetDataListFromMap(Map)
    self.TeamInviteRequestList = {}
    TeamRequestApplyModel.super.SetDataListFromMap(self,Map)
end

--[[
    重写父方法
]]
function TeamRequestApplyModel:Clean()
    TeamRequestApplyModel.super.Clean(self)
    self:DataInit()
end
--[[

--[[
    重写父方法，数据变动更新子类数据
]]
function TeamRequestApplyModel:SetIsChange(value)
    TeamRequestApplyModel.super.SetIsChange(self,value)
    if value then
        self.TeamInviteRequestList = {}
    end
end

--[[
    重写父方法
]]
function TeamRequestApplyModel:DeleteData(PlayerId)
    TeamRequestApplyModel.super.DeleteData(self,PlayerId)
    self:DeleteTeamRequestTips(PlayerId)
end

--[[
    玩家登出时调用
]]
function TeamRequestApplyModel:OnLogout(data)
    TeamRequestApplyModel.super.OnLogout(self)
    self:DataInit()
end

function TeamRequestApplyModel:DataInit()
    self.TeamInviteRequestList = {}
    self.RequestTipsList = {}
end

--[[
    获取申请入队请求列表数据
]]
function TeamRequestApplyModel:GetTeamRequestDataList()
    local IsCaptian = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain(true)
    if not IsCaptian then
        -- 不是队长无法处理入队请求
        return {}
    end
    if #self.TeamInviteRequestList == 0 then
        self.TeamInviteRequestList = {}
        local DataList = self:GetDataList()
        for k,ApplyListInfo in ipairs(DataList) do
            local ShowData = self:TransformToFriendShowData(ApplyListInfo)
            table.insert(self.TeamInviteRequestList,ShowData)
        end
        table.sort(self.TeamInviteRequestList,function (a,b)
            return a.Vo.RequestTime < b.Vo.RequestTime
        end)
    end
    return self.TeamInviteRequestList
end

--[[ 
    将协议数据 ApplyListInfo 转化为界面所需的Data格式
]]
function TeamRequestApplyModel:TransformToFriendShowData(ApplyListInfo)
    local ApplyData = {
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST,
        Vo = {
            PlayerId = ApplyListInfo.Applicant.PlayerId,
            Info = ApplyListInfo,
            RequestTime = ApplyListInfo.RequestTime
        }
    }
    return ApplyData
end

-- 申请列表发生变化
function TeamRequestApplyModel:OnRequestListChange(TeamIncreInfo)
    if TeamIncreInfo.ApplyList and TeamIncreInfo.ApplyList.TeamId > 0 then
        -- 新增
        local ApplyListInfo = TeamIncreInfo.ApplyList
        local CanAppend = self:AppendData(ApplyListInfo)
        if CanAppend then
            self:OnAppendTeamRequest(ApplyListInfo)
        end
    elseif TeamIncreInfo.TargetId > 0 then
        -- 删除
        self:DeleteData(TeamIncreInfo.TargetId)
        self:DispatchType(TeamRequestApplyModel.ON_OPERATE_TEAM_REQUEST,TeamIncreInfo.TargetId)
    end
end

--[[
    申请入队待定列表 增加数据
]]
function TeamRequestApplyModel:OnAppendTeamRequest(ApplyListInfo)
    -- 队长和队员都要同步申请者到侧边栏以及待定列表
    self:DispatchType(TeamRequestApplyModel.ON_APPEND_TEAM_REQUEST,ApplyListInfo)
end

--[[
    只有队长收到的申请弹窗
]]
function TeamRequestApplyModel:OnReceiveTeamRequestTips(TeamApplySync)
    local IsCaptian = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain()
    if IsCaptian then
        -- 队长才弹出申请弹窗
        self:PushTeamRequestTips(TeamApplySync)
        if  MvcEntry:GetModel(TeamModel):CanPopTeamTips() then
            -- 不在局内 且 好友数据初始化完成 才调用展示
            self:ShowTeamRequestTips()
        end
        self:DispatchType(TeamRequestApplyModel.ON_APPEND_TEAM_REQUEST_FOR_CAPTAIN)
    end
end

--[[
    存储新增的申请入队信息 
]]
function TeamRequestApplyModel:PushTeamRequestTips(TeamApplySync)
    self.RequestTipsList = self.RequestTipsList or {}
    local Data = {
        PlayerId = TeamApplySync.ApplicantId,
        Info = TeamApplySync.ApplyInfo,
        TeamId = 0,
        AddTime = GetTimestamp()
    }
    self.RequestTipsList[#self.RequestTipsList+1] = Data
end

--[[
    删除申请入队的信息
]]
function TeamRequestApplyModel:DeleteTeamRequestTips(PlayerId)
    if self.RequestTipsList and #self.RequestTipsList> 0 then
        local DeleteIndex = nil
        for Index,Data in ipairs(self.RequestTipsList) do
            if Data.PlayerId and Data.PlayerId == PlayerId then
                DeleteIndex = Index
                break
            end
        end
        if DeleteIndex then
            table.remove(self.RequestTipsList,DeleteIndex)
        end
    end
end

--[[
    获取存储的组队邀请提示信息
]]
function TeamRequestApplyModel:GetTeamRequestTipsData()
    if self.RequestTipsList and #self.RequestTipsList > 0 then
        local Param = {
            TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST,
            Time = self.RequestTipsList[1].AddTime,
            ItemInfoList = self.RequestTipsList,
        }
        self.RequestTipsList = nil
        return Param
    end
end

function TeamRequestApplyModel:ShowTeamRequestTips()
    local Param =self:GetTeamRequestTipsData()
    if Param then
        MvcEntry:OpenView(ViewConst.FriendRequestItemList,{Param})
    end
end

return TeamRequestApplyModel;