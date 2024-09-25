--[[自建房数据模型]]
local super = ListModel;
local class_name = "CustomRoomModel";
---@class CustomRoomModel : GameEventDispatcher
CustomRoomModel = BaseClass(super, class_name);

CustomRoomModel.ON_ROOM_LIST_UDPATE = "ON_ROOM_LIST_UDPATE"
CustomRoomModel.ON_ROOM_SEARCH_RESULT_UDPATE = "ON_ROOM_SEARCH_RESULT_UDPATE"
CustomRoomModel.ON_ROOM_ENTER_NOTIFY = "ON_ROOM_ENTER_NOTIFY"
CustomRoomModel.ON_ROOM_EXIT_NOTIFY = "ON_ROOM_EXIT_NOTIFY"
CustomRoomModel.ON_ROOM_MASTER_UPDATE = "ON_ROOM_MASTER_UPDATE"
CustomRoomModel.ON_ROOM_TEAM_MEMBER_UDPATE = "ON_ROOM_TEAM_MEMBER_UDPATE"
CustomRoomModel.ON_ROOM_REFRESH = "ON_ROOM_REFRESH"

CustomRoomModel.ON_ROOM_WATI_ENTING_BATTLE = "ON_ROOM_WATI_ENTING_BATTLE"
CustomRoomModel.ON_ROOM_WATI_ENTING_BATTLE_BREAK = "ON_ROOM_WATI_ENTING_BATTLE_BREAK"
CustomRoomModel.ON_ROOM_NAME_CHANGE = "ON_ROOM_NAME_CHANGE"
CustomRoomModel.ON_ROOM_SPECTATOR_UPDATE = "ON_ROOM_SPECTATOR_UPDATE"


function CustomRoomModel:__init()
    self:DataInit()
end

function CustomRoomModel:OnCultureInit()
    self.ViewType2Describe = {
        [1] = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomModel_firstperson")),
        [3] = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomModel_thirdperson")),
    }
end

function CustomRoomModel:DataInit()
    self.CurSearchRoomInfo = nil
    self.CurEnteredRoomInfo = nil


    self.RoomPlayerId2TeamId = {}
    self.RoomPlayerId2Pos = {}
    self.RoomPlayerId2PlayerInfo = {}

    self.CanCreateModeIdList = nil

    self.RoomListDirty = true
    self.RoomPlayerId2PlayerInfoDirty = true
    self.CurEnterRoomPlayerNum = 0
end

function CustomRoomModel:OnLogin()
    self:CheckConfigPreCalculate()
end
function CustomRoomModel:OnLogout()
    self:DataInit()
end

--[[
    格式不同需要重写此方法

    返回数据格式的唯一Key
]]
function CustomRoomModel:KeyOf(vo)
    if vo["CustomRoomId"] then
        return vo["CustomRoomId"]
    end
end

--[[
    可重写此方法，用于获取数据变化情况
]]
function CustomRoomModel:SetIsChange(value)
    CustomRoomModel.super.SetIsChange(self,value)
    if value then
        self.RoomListDirty = true
    end
end

function CustomRoomModel:CheckConfigPreCalculate()
    if not self.CanCreateModeIdList then
        local TheDict = G_ConfigHelper:GetDict(Cfg_CustomRoomConfig)
        self.CanCreateModeIdList = {}

        for k,v in ipairs(TheDict) do
            if v[Cfg_CustomRoomConfig_P.IsOpen] then
                local ModeId = v[Cfg_CustomRoomConfig_P.ModeId]
                self.CanCreateModeIdList[#self.CanCreateModeIdList + 1] = ModeId
            end
        end
    end
end


function CustomRoomModel:GetRoomList()
    if self.RoomListDirty then
        self.RoomListDirty = false

        local DataList = self:GetDataList()
        if #DataList > 1 then
            --TODO 进行房间列表排序
            -- print_r(DataList,"Before:")
            table.sort(DataList, function(a ,b)
                local AlreadyStartA = a.Status == Pb_Enum_CUSTOMROOM_STATUS.CUSTOMROOM_ST_GAME and 1 or 0
                local AlreadyStartB = b.Status == Pb_Enum_CUSTOMROOM_STATUS.CUSTOMROOM_ST_GAME and 1 or 0
                if AlreadyStartA ~=  AlreadyStartB then
                    return (AlreadyStartA < AlreadyStartB)
                end
                local NeedPwdA = a.IsLock and 1 or 0
                local NeedPwdB = b.IsLock and 1 or 0 
                if NeedPwdA ~= NeedPwdB then
                    return (NeedPwdA < NeedPwdB)
                end
                local CreateTimeA = a.CreateTime
                local CreateTimeB = b.CreateTime
                return (CreateTimeA < CreateTimeB)
            end)
            -- print_r(DataList,"After:")
        end
    end
    return self:GetDataList()
end


function CustomRoomModel:CheckMsgInvalidWithRoomId(CustomRoomId)
    if not self.CurEnteredRoomInfo then
        CWaring("CustomRoomModel:CheckMsgInvalidWithRoomId CurEnteredRoomInfo nil",true)
        return false
    end
    if CustomRoomId ~= self.CurEnteredRoomInfo.BaseRoomInfo.CustomRoomId then
        CError("CustomRoomModel:CheckMsgInvalidWithRoomId RoomId not equal",true)
        return false
    end
    return true
end

--[[
    房主变动

    // 转移房主通知，给房间其他成员
    message TransMasterSync
    {
        int64 CustomRoomId = 1;
        int64 NewMasterId = 2;  // 新的房主PlayerId
    }
]]
function CustomRoomModel:TransMasterSync_Func(Msg)
    if not self:CheckMsgInvalidWithRoomId(Msg.CustomRoomId) then
        return
    end
    local OldMasterTeamId = self:GetTeamIdByPlayerId(self.CurEnteredRoomInfo.BaseRoomInfo.MasterId)
    self.CurEnteredRoomInfo.BaseRoomInfo.MasterId = Msg.NewMasterId
    local NewMasterTeamId = self:GetTeamIdByPlayerId(self.CurEnteredRoomInfo.BaseRoomInfo.MasterId)
    self:DispatchType(CustomRoomModel.ON_ROOM_MASTER_UPDATE)

    self:DispatchType(CustomRoomModel.ON_ROOM_TEAM_MEMBER_UDPATE,{OldMasterTeamId,NewMasterTeamId})
end


function CustomRoomModel:__PosChangeInfoSync(PosChangeInfo)
    local TheTeamId = PosChangeInfo.TeamId
    -- for k,PlayerPosChange in ipairs(PosChangeInfo.PlayerPosChangeList) do
    --     --[[
    --         message PlayerPosChangeInfo
    --         {
    --             int64 PlayerId = 1;
    --             int32 Pos = 2;
    --         }
    --     ]]
    --     self:__OnTeamAndPosChangeUpdate(PlayerPosChange.PlayerId,TheTeamId,PlayerPosChange.Pos)
    -- end
    for Pos,PlayerId in ipairs(PosChangeInfo.PlayerPosChangeList) do
        self:__OnTeamAndPosChangeUpdate(PlayerId,TheTeamId,Pos)
    end
end

function CustomRoomModel:__OnTeamAndPosChangeUpdate(PlayerId,NewTeamId,NewPos)
    local PlayerInfo = self.RoomPlayerId2PlayerInfo[PlayerId]
    local OldTeamId = self.RoomPlayerId2TeamId[PlayerId] or nil
    local OldPos = self.RoomPlayerId2Pos[PlayerId] or nil
    if OldTeamId and OldPos then
        self.CurEnteredRoomInfo.TeamList[OldTeamId].PlayerInfoList[OldPos] = nil
    end

    self.RoomPlayerId2TeamId[PlayerId] = NewTeamId
    self.RoomPlayerId2Pos[PlayerId] = NewPos
    self.RoomPlayerId2PlayerInfoDirty = true

    self.CurEnteredRoomInfo.TeamList[NewTeamId] = self.CurEnteredRoomInfo.TeamList[NewTeamId] or {PlayerInfoList = {}}
    self.CurEnteredRoomInfo.TeamList[NewTeamId].PlayerInfoList[NewPos] = PlayerInfo
end

--[[
    // 房主退出通知
    message MasterExitRoomSync
    {
        int64 CustomRoomId = 1;
        int64 MasterPlayerId = 2;     // 新房主Id
        PosChangeInfoBase PosChangeInfo = 3;
    }
]]
function CustomRoomModel:MasterExitRoomSync_Func(Msg)
    if not self:CheckMsgInvalidWithRoomId(Msg.CustomRoomId) then
        return
    end
    print_r(Msg)
    local OldMasterId = self.CurEnteredRoomInfo.BaseRoomInfo.MasterId
    local OldMasterTeamId = self:GetTeamIdByPlayerId(OldMasterId)
    local OldPos = self.RoomPlayerId2Pos[OldMasterId]
    self.CurEnteredRoomInfo.TeamList[OldMasterTeamId].PlayerInfoList[OldPos] = nil
    self.RoomPlayerId2TeamId[OldMasterId] = nil
    self.RoomPlayerId2Pos[OldMasterId] = nil
    self.RoomPlayerId2PlayerInfo[OldMasterId] = nil
    self.RoomPlayerId2PlayerInfoDirty = true

    self.CurEnteredRoomInfo.BaseRoomInfo.MasterId = Msg.MasterPlayerId
    local NewMasterTeamId = self:GetTeamIdByPlayerId(self.CurEnteredRoomInfo.BaseRoomInfo.MasterId)

    self:__PosChangeInfoSync(Msg.PosChangeInfo)

    self:DispatchType(CustomRoomModel.ON_ROOM_MASTER_UPDATE)

    self:DispatchType(CustomRoomModel.ON_ROOM_TEAM_MEMBER_UDPATE,{OldMasterTeamId,NewMasterTeamId})
end


--[[
    普通玩家退出通知
    message PlayerExitRoomSync
    {
        int64 CustomRoomId = 1;
        int64 PlayerId = 2;     // 退出玩家Id
        PosChangeInfoBase PosChangeInfo = 3;
    }
]]
function CustomRoomModel:PlayerExitRoomSync_Func(Msg)
    if not self:CheckMsgInvalidWithRoomId(Msg.CustomRoomId) then
        return
    end
    local TeamId = self.RoomPlayerId2TeamId[Msg.PlayerId]
    if not TeamId then
        CWaring("CustomRoomModel:PlayerExitSync_Func TeamId nil")
        return
    end
    print_r(Msg)
    local Pos = self.RoomPlayerId2Pos[Msg.PlayerId]
    self.CurEnteredRoomInfo.TeamList[TeamId].PlayerInfoList[Pos] = nil
    self.RoomPlayerId2TeamId[Msg.PlayerId] = nil
    self.RoomPlayerId2Pos[Msg.PlayerId] = nil
    self.RoomPlayerId2PlayerInfo[Msg.PlayerId] = nil
    self.RoomPlayerId2PlayerInfoDirty = true

    self:__PosChangeInfoSync(Msg.PosChangeInfo)

    self:DispatchType(CustomRoomModel.ON_ROOM_TEAM_MEMBER_UDPATE,{TeamId})
end

--[[
    队员加入
]]
function CustomRoomModel:JoinRoomSync_Func(Msg)
    if not self:CheckMsgInvalidWithRoomId(Msg.CustomRoomId) then
        return
    end
    print_r(Msg)
    local PlayerId = Msg.PlayerInfo.PlayerId
    self.RoomPlayerId2TeamId[PlayerId] = Msg.TeamId
    self.RoomPlayerId2Pos[PlayerId] = Msg.Pos
    self.RoomPlayerId2PlayerInfo[PlayerId] = Msg.PlayerInfo
    self.RoomPlayerId2PlayerInfoDirty = true

    self.CurEnteredRoomInfo.TeamList[Msg.TeamId] = self.CurEnteredRoomInfo.TeamList[Msg.TeamId] or {PlayerInfoList = {}}
    self.CurEnteredRoomInfo.TeamList[Msg.TeamId].PlayerInfoList[Msg.Pos] = Msg.PlayerInfo

    self:DispatchType(CustomRoomModel.ON_ROOM_TEAM_MEMBER_UDPATE,{Msg.TeamId})
end

--[[
    队员调换位置

    message PlayerPosChangeSync
    {
        int64 RoomId = 1;
        int64 PlayerId = 2;
        int32 Pos = 3;          // 在队伍中位置
    }
]]
function CustomRoomModel:ChangePosSync_Func(Msg)
    if not self:CheckMsgInvalidWithRoomId(Msg.CustomRoomId) then
        return
    end
    local TeamId = self.RoomPlayerId2TeamId[Msg.PlayerId]
    if not TeamId then
        CWaring("CustomRoomModel:PlayerPosChangeSync_Func TeamId nil")
        return
    end
    local PlayerInfo = self.RoomPlayerId2PlayerInfo[Msg.PlayerId]

    local OldPos = self.RoomPlayerId2Pos[Msg.PlayerId] or nil
    if OldPos then
        self.CurEnteredRoomInfo.TeamList[Msg.TeamId].PlayerInfoList[OldPos] = nil
    end
    self.CurEnteredRoomInfo.TeamList[Msg.TeamId].PlayerInfoList[Msg.Pos] = PlayerInfo
    self.RoomPlayerId2Pos[Msg.PlayerId] = Msg.Pos

    print_r(self.CurEnteredRoomInfo)

    self:DispatchType(CustomRoomModel.ON_ROOM_TEAM_MEMBER_UDPATE,{Msg.TeamId})
end

--[[
    队员调换队伍（包含位置）

    // 更换队伍后同步消息给房间内其他成员
    message PlayerTeamChangeInfo
    {
        int64 PlayerId = 1;     // Team或位置有变化的玩家Id
        int32 TeamId = 2;       // 变化后的TeamId
        int32 Pos = 3;          // 变化后在队伍中的位置
    }
    message ChangeTeamSync
    {
        int64 CustomRoomId = 1;
        repeated PlayerTeamChangeInfo TeamChangeInfo = 2;    // 队伍或位置有变化的信息列表
    }
]]
function CustomRoomModel:ChangeTeamSync_Func(Msg)
    if not self:CheckMsgInvalidWithRoomId(Msg.CustomRoomId) then
        return
    end

    local ExistChangeTeamIdList = {}
    for k,PlayerTeamChangeInfo in ipairs(Msg.TeamChangeInfo) do
        local OldTeamId = self.RoomPlayerId2TeamId[PlayerTeamChangeInfo.PlayerId] or nil
        self:__OnTeamAndPosChangeUpdate(PlayerTeamChangeInfo.PlayerId,PlayerTeamChangeInfo.TeamId,PlayerTeamChangeInfo.Pos)

        ExistChangeTeamIdList[#ExistChangeTeamIdList + 1] = OldTeamId
        ExistChangeTeamIdList[#ExistChangeTeamIdList + 1] = PlayerTeamChangeInfo.TeamId
    end
    -- print_r(ExistChangeTeamIdList)
    -- print_r(self.CurEnteredRoomInfo)

    self:DispatchType(CustomRoomModel.ON_ROOM_TEAM_MEMBER_UDPATE,ExistChangeTeamIdList)
end

--[[
    // 房主点击开始游戏后，通知房间成员对局准备开始了
    /*
    * 这个协议可能会收到多次
    * 第一次收到表示通知房间成员进入“等待”开局界面
    * 第二次收到表示在开局时失败了，需要返回房间界面或者其他界面
    * 开局成功，则走已有的同步Ds连接信息协议：DsMetaSync
    */

    message StartGameSync
    {
        int64 CustomRoomId = 1;   // 自建房Id
        int32 ErrorCode = 2;      // 为0 则表示未出现错误, 非0对应的错误码在ErrorCode配置表
    }
]]
function CustomRoomModel:StartGameSync_Func(Msg)
    print_r(Msg)
    if not self:CheckMsgInvalidWithRoomId(Msg.CustomRoomId) then
        return
    end
    if Msg.ErrorCode ~= 0 then
        --TODO 进行提示
        MvcEntry:GetCtrl(ErrorCtrl):PopErrorSync(Msg.ErrorCode)
        self:DispatchType(CustomRoomModel.ON_ROOM_WATI_ENTING_BATTLE_BREAK)
    else
        self:DispatchType(CustomRoomModel.ON_ROOM_WATI_ENTING_BATTLE)
    end
end

function CustomRoomModel:SetCurSearchRoomInfo(Vo)
    self.CurSearchRoomInfo = Vo
end

function CustomRoomModel:GetCurSearchRoomInfo()
    return self.CurSearchRoomInfo
end

function CustomRoomModel:SetCurEnteredRoomInfo(Vo)
    self.CurEnteredRoomInfo = Vo
    self.RoomPlayerId2PlayerInfoDirty = true
    if self.CurEnteredRoomInfo then
        self.RoomPlayerId2TeamId = {}
        self.RoomPlayerId2Pos = {}
        self.RoomPlayerId2PlayerInfo = {}

        for TeamId,BaseTeamInfo in pairs(self.CurEnteredRoomInfo.TeamList) do
            for TeamPos,RoomPlayerInfo in pairs(BaseTeamInfo.PlayerInfoList) do
                self.RoomPlayerId2TeamId[RoomPlayerInfo.PlayerId] = TeamId
                self.RoomPlayerId2Pos[RoomPlayerInfo.PlayerId] = TeamPos
                self.RoomPlayerId2PlayerInfo[RoomPlayerInfo.PlayerId] = RoomPlayerInfo
            end
        end
    else
        self.RoomPlayerId2TeamId = {}
        self.RoomPlayerId2Pos = {}
        self.RoomPlayerId2PlayerInfo = {}
    end
end
function CustomRoomModel:GetCurEnteredRoomInfo()
    return self.CurEnteredRoomInfo
end

function CustomRoomModel:GetCurEnteredRoomId()
    return self.CurEnteredRoomInfo and self.CurEnteredRoomInfo.BaseRoomInfo.CustomRoomId or nil
end


function CustomRoomModel:GetRoomPlayerInfoById(PlayerId)
    return self.RoomPlayerId2PlayerInfo[PlayerId] or nil
end
function CustomRoomModel:GetTeamInfoByTeamId(TeamId)
    return self.CurEnteredRoomInfo and self.CurEnteredRoomInfo.TeamList and self.CurEnteredRoomInfo.TeamList[TeamId].PlayerInfoList or nil
end

--[[
    判断玩家ID是否队长
]]
function CustomRoomModel:IsMaster(PlayerId)
    if not self.CurEnteredRoomInfo then
        return false
    end
    if PlayerId == self.CurEnteredRoomInfo.BaseRoomInfo.MasterId then
        return true
    end
    return false
end

--[[
    指定玩家是否在  主客户端的房间内
]]
function CustomRoomModel:IsPlayerInCurEnteredRoomInfo(PlayerId)
    if not self.CurEnteredRoomInfo then
        return false
    end
    local PlayerInfo = self:GetRoomPlayerInfoById(PlayerId)
    return PlayerInfo and true or false
end

--[[
    玩家自身是否在自建房内
]]
function CustomRoomModel:IsSelfInRoom()
    return self:IsPlayerInCurEnteredRoomInfo(MvcEntry:GetModel(UserModel):GetPlayerId())
end

function CustomRoomModel:GetCanCreateModeIdList()
    self:CheckConfigPreCalculate()
    return self.CanCreateModeIdList
end

function CustomRoomModel:GetDesByViewType(ViewType)
    return self.ViewType2Describe[ViewType] or "None"
end

function CustomRoomModel:GetTeamIdByPlayerId(PlayerId)
    return self.RoomPlayerId2TeamId[PlayerId] or nil
end

function CustomRoomModel:GetCurEnterRoomPlayerNum()
    if self.RoomPlayerId2PlayerInfoDirty then
        self.RoomPlayerId2PlayerInfoDirty = false
        self.CurEnterRoomPlayerNum = table_leng(self.RoomPlayerId2PlayerInfo)
    end
    return self.CurEnterRoomPlayerNum
end

--[[
	Msg = {
	    int64 CustomRoomId = 1;     // 自建房Id
	    string CustomRoomName = 2;  // 变化后的自建房名字
	}
]]
function CustomRoomModel:On_CustomRoomNameChangeSync(Msg)
    if not self:CheckMsgInvalidWithRoomId(Msg.CustomRoomId) then
        return
    end
    self.CurEnteredRoomInfo.BaseRoomInfo.CustomRoomName = Msg.CustomRoomName
end

-- 获取位置对应观战玩家id
function CustomRoomModel:GetSpectatorIdByPos(Pos)
    return self.CurEnteredRoomInfo and self.CurEnteredRoomInfo.SpectaterIdList and self.CurEnteredRoomInfo.SpectaterIdList[Pos] or nil
end
