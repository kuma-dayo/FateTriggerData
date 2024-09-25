--[[好友申请数据模型]]
local super = ListModel;
local class_name = "FriendApplyModel";
---@class FriendApplyModel : GameEventDispatcher
---@type FriendApplyModel
FriendApplyModel = BaseClass(super, class_name);

FriendApplyModel.ON_OPERATE_APPLY = "ON_OPERATE_APPLY" -- 操作申请列表

--[[
    重写父方法，返回唯一Key
]]
function FriendApplyModel:KeyOf(Vo)
    return Vo["PlayerId"]
end

function FriendApplyModel:IsValidOf(Vo)
    return Vo["PlayerId"] ~= nil
end

--[[
    重写父方法，数据变动更新子类数据
]]
function FriendApplyModel:SetIsChange(value)
    FriendApplyModel.super.SetIsChange(self,value)
    self.IsApplyListChanged = value
    if value then
        self.ApplyList = {}
    end
end

function FriendApplyModel:__init()
    self:DataInit()
end

function FriendApplyModel:DataInit()
    self.IsApplyListChanged = true
    self.ApplyList = {}
end

--[[
    重写父方法，数据更新
    需要判断是否缓存新增数据
]]
function FriendApplyModel:UpdateDatas(itemList,fullCheck)
    local StateList,Map = FriendApplyModel.super.UpdateDatas(self,itemList,fullCheck)
    if Map["AddMap"] and #Map["AddMap"] > 0 then
        self:PushFriendApplyTips(Map["AddMap"])
        if  MvcEntry:GetModel(TeamModel):CanPopTeamTips() then
        -- 不在局内 且 好友数据初始化完成 才调用展示
            self:ShowFriendApplyTips()
        end
    end
end

--[[
    重写父方法
]]
function FriendApplyModel:DeleteData(DelPlayerId)
    FriendApplyModel.super.DeleteData(self,DelPlayerId)
    self:DeleteFriendApplyTips(DelPlayerId)
end

--[[
    玩家登出时调用
]]
function FriendApplyModel:OnLogout(data)
    FriendApplyModel.super.OnLogout(self)
    self:DataInit()
end

-- 获取好友申请列表
function FriendApplyModel:GetApplyList()
    if #self.ApplyList == 0 or self.IsApplyListChanged then
        self.ApplyList = {}
        local DataList = self:GetDataList()
        for k,v in ipairs(DataList) do
            local AddFriendApplyNode = DataList[k]
            local ApplyData = self:TransformToFriendShowData(AddFriendApplyNode)
            table.insert(self.ApplyList,ApplyData)
        end

        table.sort(self.ApplyList,function (a,b)
            return a.Vo.AddTime < b.Vo.AddTime
        end)
        self.IsApplyListChanged = false
    end
    return self.ApplyList
end

--[[
    是否在申请列表中
]]
function FriendApplyModel:IsInApplyList(PlayerId)
    PlayerId = tonumber(PlayerId)
    return self:GetData(PlayerId) ~= nil
end


--[[ 
    将协议数据 AddFriendApplyNode 转化为界面所需的Data格式
]]
function FriendApplyModel:TransformToFriendShowData(AddFriendApplyNode)
    local ApplyData = {
        TypeId = FriendConst.LIST_TYPE_ENUM.FRIEND_REQUEST,
        Vo = {
            PlayerName = AddFriendApplyNode.PlayerName,
            PlayerId = AddFriendApplyNode.PlayerId,
            AddTime = AddFriendApplyNode.AddTime,
            HeadId = AddFriendApplyNode.HeadId
        }
    }
    return ApplyData
end

--[[
    存下操作申请的信息，用于飘字提示
]]
function FriendApplyModel:SaveApplyOperateInfo(OperateInfo)
    self.ApplyOperateInfo = OperateInfo
end

--[[
    同意添加/拒绝添加 好友提示
]]
function FriendApplyModel:ShowOperateApplyTips(OpePlayerData)
	if self.ApplyOperateInfo and OpePlayerData and self.ApplyOperateInfo.PlayerId == OpePlayerData.PlayerId then
        local Code = self.ApplyOperateInfo.Choice and TipsCode.FriendRequestAccept or TipsCode.FriendRequestDenied
        local TipsArgs = { OpePlayerData.PlayerName }
        MvcEntry:GetCtrl(ErrorCtrl):PopTipsSync(Code.ID,"",TipsArgs)
        self.ApplyOperateInfo = nil
	end
end

--[[
    获取存储的好友申请提示信息
]]
function FriendApplyModel:GetFriendApplyTipsData()
    if self.ApplyTipsList and #self.ApplyTipsList > 0 then
        local Param = {
            TypeId = FriendConst.LIST_TYPE_ENUM.FRIEND_REQUEST,
            Time = self.ApplyTipsList[1].AddTime,
            ItemInfoList = self.ApplyTipsList,
        }
        self.ApplyTipsList = nil
        return Param
    end
end

--[[
    存储新增的好友申请提示信息
]]
function FriendApplyModel:PushFriendApplyTips(ApplyAddMap)
    table.sort(ApplyAddMap,function (A,B)
        return A.AddTime < B.AddTime
    end)
    self.ApplyTipsList = self.ApplyTipsList or {}
    ListMerge(self.ApplyTipsList,ApplyAddMap)
end

-- 需要检查是否有缓存的弹窗数据，有也要清除
function FriendApplyModel:DeleteFriendApplyTips(DelPlayerId)
    self.ApplyTipsList = self.ApplyTipsList or {}
    local DelIndex = nil
    for Index, AddFriendApplyNode in ipairs(self.ApplyTipsList) do
        if AddFriendApplyNode.PlayerId == DelPlayerId then
            DelIndex = Index
            break
        end
    end
    if DelIndex then
        table.remove(self.ApplyTipsList,DelIndex)
    end
end

function FriendApplyModel:ShowFriendApplyTips()
    local Param =self:GetFriendApplyTipsData()
    if Param then
        MvcEntry:OpenView(ViewConst.FriendRequestItemList,{Param})
    end
end


return FriendApplyModel;