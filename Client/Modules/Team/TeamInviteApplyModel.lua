--[[
    别人向我发起的组队请求列表 数据模型
]]
local super = ListModel;
local class_name = "TeamInviteApplyModel";

TeamInviteApplyModel = BaseClass(super, class_name);
TeamInviteApplyModel.ON_OPERATE_TEAM_INVITE = "ON_OPERATE_TEAM_INVITE"
TeamInviteApplyModel.ON_APPEND_TEAM_INVITE_APPLY = "ON_APPEND_TEAM_INVITE_APPLY"
function TeamInviteApplyModel:__init()
    self:DataInit()
end

--[[
    重写父方法，返回唯一Key
    Vo节构 参考 TeamInviteSync
]]
function TeamInviteApplyModel:KeyOf(Vo)
    if self:IsValidOf(Vo) then
        return Vo["InviteInfo"]["TeamId"]
    else
        return nil 
    end
end

function TeamInviteApplyModel:IsValidOf(Vo)
    return Vo["InviteInfo"] ~= nil and Vo["InviteInfo"]["TeamId"] ~= nil
end
--[[
    重写父方法，数据变动更新子类数据
]]
function TeamInviteApplyModel:SetIsChange(value)
    TeamInviteApplyModel.super.SetIsChange(self,value)
    if value then
        self.TeamInviteApplyList = {}
    end
end
--[[
    重写父方法
]]
function TeamInviteApplyModel:SetDataList(list)
    self.TeamInviteApplyList = {}
    TeamInviteApplyModel.super.SetDataList(self,list)
end
--[[
    重写父方法
]]
function TeamInviteApplyModel:Clean()
    TeamInviteApplyModel.super.Clean(self)
    self:DataInit()
end
--[[
    重写父方法
]]
function TeamInviteApplyModel:DeleteData(TeamId)
    TeamInviteApplyModel.super.DeleteData(self,TeamId)
    self:DeleteTeamInviteTips(TeamId)
end

--[[
    玩家登出时调用
]]
function TeamInviteApplyModel:OnLogout(data)
    TeamInviteApplyModel.super.OnLogout(self)
    self:DataInit()
end


function TeamInviteApplyModel:DataInit()
    self.TeamInviteApplyList = {}
    self.InviteTipsList = {}
end

--[[
    获取邀请自己入队的邀请列表
]]
function TeamInviteApplyModel:GetTeamInviteApplyList()
    if #self.TeamInviteApplyList == 0 then
        self.TeamInviteApplyList = {}
        local DataList = self:GetDataList()
        for k,v in ipairs(DataList) do
            local TeamInviteSync = DataList[k]
            local TeamInviteSyncData = self:TransformToFriendShowData(TeamInviteSync)
            table.insert(self.TeamInviteApplyList,TeamInviteSyncData)
        end
        table.sort(self.TeamInviteApplyList,function (a,b)
            return a.Vo.RequestTime < b.Vo.RequestTime
        end)
    end
    return self.TeamInviteApplyList
end

--[[ 
    将协议数据 TeamInviteSync 转化为界面所需的Data格式
]]
function TeamInviteApplyModel:TransformToFriendShowData(TeamInviteSync)
    local ApplyData = {
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST,
        Vo = {
            PlayerId = TeamInviteSync.InviterId,
            Info = TeamInviteSync.InviteInfo,
            RequestTime = TeamInviteSync.RequestTime
        }
    }
    return ApplyData
end
--[[
    获取存储的组队邀请提示信息
]]
function TeamInviteApplyModel:GetTeamInviteTipsData()
    if self.InviteTipsList and #self.InviteTipsList > 0 then
        local Param = {
            TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST,
            Time = self.InviteTipsList[1].AddTime,
            ItemInfoList = self.InviteTipsList,
        }
        self.InviteTipsList = nil
        return Param
    end
end

--[[
    收到被邀请组队通知
]]
function TeamInviteApplyModel:OnReceiveTeamInviteTips(Msg)
    self:PushTeamInviteTips(Msg)
    if  MvcEntry:GetModel(TeamModel):CanPopTeamTips() then
        -- 不在局内 且 好友数据初始化完成 才调用展示
        self:ShowTeamInviteTips()
    end
end

--[[
    存储新增的邀请组队信息 Msg:TeamInviteSync
]]
function TeamInviteApplyModel:PushTeamInviteTips(Msg)
    self.InviteTipsList = self.InviteTipsList or {}
    local Data = {
        PlayerId = Msg.InviterId,
        TeamId = Msg.InviteInfo.TeamId,
        Info = Msg.InviteInfo,
        AddTime = GetTimestamp()
    }
    self.InviteTipsList[#self.InviteTipsList+1] = Data
end

--[[
    删除邀请的信息
]]
function TeamInviteApplyModel:DeleteTeamInviteTips(TeamId)
    if self.InviteTipsList and #self.InviteTipsList> 0 then
        local DeleteIndex = nil
        for Index,Data in ipairs(self.InviteTipsList) do
            local InviteInfo = Data.Info
            if InviteInfo and InviteInfo.TeamId and InviteInfo.TeamId == TeamId then
                DeleteIndex = Index
                break
            end
        end
        if DeleteIndex then
            table.remove(self.InviteTipsList,DeleteIndex)
        end
    end
end

function TeamInviteApplyModel:ShowTeamInviteTips()
    local Param =self:GetTeamInviteTipsData()
    if Param then
        MvcEntry:OpenView(ViewConst.FriendRequestItemList,{Param})
    end
end

return TeamInviteApplyModel;