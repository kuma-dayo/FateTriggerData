--[[好友黑名单数据模型]]
local super = ListModel;
local class_name = "FriendBlackListModel";
---@class FriendBlackListModel : GameEventDispatcher
---@type FriendBlackListModel
FriendBlackListModel = BaseClass(super, class_name);
FriendBlackListModel.ON_BLACKLIST_CHANGED = "ON_BLACKLIST_CHANGED"

--[[
    重写父方法，返回唯一Key
]]
function FriendBlackListModel:KeyOf(Vo)
    return Vo["PlayerId"]
end

function FriendBlackListModel:IsValidOf(Vo)
    return Vo["PlayerId"] ~= nil
end

--[[
    重写父方法，数据变动更新子类数据
]]
function FriendBlackListModel:SetIsChange(value)
    FriendBlackListModel.super.SetIsChange(self,value)
    self.IsListChanged = value
end


function FriendBlackListModel:__init()
    self:_dataInit()
end

function FriendBlackListModel:_dataInit()
    self.BlackList = {}
    self.BlackList2PlayerIds = {}
    self.IsListChanged = true
end
--[[
    玩家登出时调用
]]
function FriendBlackListModel:OnLogout(data)
    FriendBlackListModel.super.OnLogout(self)
    self:_dataInit()
end
--[[
    获取黑名单列表
    按时间降序排序
]]
function FriendBlackListModel:GetBlackList()
    if #self.BlackList == 0 or self.IsListChanged then
        self.BlackList = {}
        self.BlackList2PlayerIds = {}
        local DataList = self:GetDataList()
        for _,Data in ipairs(DataList) do
            local FriendBlackNode = {
                PlayerId = Data.PlayerId,
                OpTime = Data.OpTime,
            }
            table.insert(self.BlackList,FriendBlackNode)
            table.insert(self.BlackList2PlayerIds,Data.PlayerId)
        end
        -- 按时间降序排序
        table.sort(self.BlackList,function (a,b)
            return a.OpTime > b.OpTime
        end)
        self.IsListChanged = false
    end
    return self.BlackList,self.BlackList2PlayerIds
end

return FriendBlackListModel;
