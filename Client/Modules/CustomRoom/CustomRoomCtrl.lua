require("Client.Modules.CustomRoom.CustomRoomModel")
--[[
    自建房协议处理模块
]]
local class_name = "CustomRoomCtrl"
---@class CustomRoomCtrl : UserGameController
CustomRoomCtrl = CustomRoomCtrl or BaseClass(UserGameController,class_name)


function CustomRoomCtrl:__init()
    CWaring("==CustomRoomCtrl init")
end

function CustomRoomCtrl:Initialize()
    self.Model = self:GetModel(CustomRoomModel)
end

--[[
    玩家登入
]]
function CustomRoomCtrl:OnLogin(data)
    CWaring("CustomRoomCtrl OnLogin")
    if data then
        --重连需要请求最新的房间信息
        CWaring("CustomRoomCtrl OnLogin Reconnect")
        local RoomId = self.Model:GetCurEnteredRoomId()
        if RoomId and RoomId > 0 then
            self:SendProto_CustomRoomInfoReq(RoomId)
        end
    end
end


function CustomRoomCtrl:AddMsgListenersUser()
    self.ProtoList = {
    	{MsgName = Pb_Message.StartClientDsSync,	Func = self.StartClientDsSync_Func },
		{MsgName = Pb_Message.RoomListRsp,	Func = self.RoomListRsp_Func },
		{MsgName = Pb_Message.SearchRoomRsp,	Func = self.SearchRoomRsp_Func },
		{MsgName = Pb_Message.CreateRoomRsp,	Func = self.CreateRoomRsp_Func },
		{MsgName = Pb_Message.JoinRoomRsp,	Func = self.JoinRoomRsp_Func },
		{MsgName = Pb_Message.ExitRoomRsp,	Func = self.ExitRoomRsp_Func },
		-- {MsgName = Pb_Message.ChangePosRsp,	Func = self.ChangePosRsp_Func },
		{MsgName = Pb_Message.ChangeTeamRsp,	Func = self.ChangeTeamRsp_Func },
		{MsgName = Pb_Message.KickPlayerRsp,	Func = self.KickPlayerRsp_Func },
        {MsgName = Pb_Message.KickPlayerSync,	Func = self.KickPlayerSync_Func },
		{MsgName = Pb_Message.TransMasterRsp,	Func = self.TransMasterRsp_Func },
		{MsgName = Pb_Message.InviteRsp,	Func = self.InviteRsp_Func },
		{MsgName = Pb_Message.InviteSync,	Func = self.InviteSync_Func },
		{MsgName = Pb_Message.TransMasterSync,	Func = self.TransMasterSync_Func },
        {MsgName = Pb_Message.MasterExitRoomSync,	Func = self.MasterExitRoomSync_Func },
		{MsgName = Pb_Message.PlayerExitRoomSync,	Func = self.PlayerExitRoomSync_Func },
		{MsgName = Pb_Message.JoinRoomSync,	Func = self.JoinRoomSync_Func },
		{MsgName = Pb_Message.ChangePosSync,	Func = self.ChangePosSync_Func },
		{MsgName = Pb_Message.ChangeTeamSync,	Func = self.ChangeTeamSync_Func },
		{MsgName = Pb_Message.DissolveRoomRsp,	Func = self.DissolveRoomRsp_Func },
		{MsgName = Pb_Message.DissolveRoomSync,	Func = self.DissolveRoomSync_Func },
        {MsgName = Pb_Message.StartGameRsp,	Func = self.StartGameRsp_Func },
        {MsgName = Pb_Message.StartGameSync,	Func = self.StartGameSync_Func },
		{MsgName = Pb_Message.CustomRoomNameChangeSync,	Func = self.CustomRoomNameChangeSync_Func },
        {MsgName = Pb_Message.CustomRoomInfoRsp,	Func = self.CustomRoomInfoRsp_Func },
    }

    self.MsgList = {
        { Model = HallModel,    MsgName = HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,	Func = self.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_func },
    }
end


--[[
    通知需要启动客户端的DS 用于战斗
]]
function CustomRoomCtrl:StartClientDsSync_Func(InDsInfo)
    print_r(InDsInfo, "[cw] CustomRoomCtrl:StartClientDsSync_Func")
    -- local CurrentPath = UEConnect.get_projectpath()
    -- local RootPath = string.match(CurrentPath, "@(.+)[\\/]S1Game")

    -- if not RootPath or #RootPath == 0 then
    --     CError(CurrentPath .. " find RootPath fail")
    --     return
    -- end

    -- local url = string.format( "%s/%s", RootPath, InDsInfo.EditorBsPath)
    local RootPath = UEConnect.get_projectpath()
    if #RootPath > 7 and RootPath:sub(-7) == "S1Game/" then
        RootPath = RootPath:sub(1, -8)
    end
    local url = string.format("%s%s", RootPath, InDsInfo.EditorBsPath)
    local params = string.format("%s/%s -gameId=%s -multihome=%s -port=%d -log=%s.log -server -lobbyDS -log -listen_ip=%s -listen_port=%d -listen_timeout=%d %s",
            RootPath, InDsInfo.EditorBsProject,
            InDsInfo.Id,
            InDsInfo.LocalGameAddr, InDsInfo.Port, InDsInfo.Id,
            InDsInfo.ListenIp, InDsInfo.ListenPort, InDsInfo.LocalListenTimeout, InDsInfo.UnrealInsights)

    print_r({InDsInfo=InDsInfo, url=url, params=params}, "ClientDs=")

    UEConnect.start_local_ds(url, params)
end

function CustomRoomCtrl:RoomListRsp_Func(Msg)
    self.Model:SetDataList(Msg.RoomList,true)

    self.Model:DispatchType(CustomRoomModel.ON_ROOM_LIST_UDPATE)
end

--[[
    message SearchRoomRsp
    {
        int32 ErrorCode = 1;            // 0 成功，1不存在
        BaseRoomInfoMsg RoomInfo = 2;   // 自建房基础信息 
    }
]]
function CustomRoomCtrl:SearchRoomRsp_Func(Msg)
    print_r(Msg)
    if Msg.ErrorCode == 0 then
        self.Model:SetCurSearchRoomInfo(Msg.RoomInfo)
        self.Model:DispatchType(CustomRoomModel.ON_ROOM_SEARCH_RESULT_UDPATE,Msg.RoomInfo)
    else
        self:GetSingleton(ErrorCtrl):PopErrorSync(Msg.ErrorCode)
        self.Model:DispatchType(CustomRoomModel.ON_ROOM_SEARCH_RESULT_UDPATE,nil)
    end
end

function CustomRoomCtrl:CreateRoomRsp_Func(Msg)
    print_r(Msg)
    self.Model:SetCurEnteredRoomInfo(Msg.RoomInfo)
    self.Model:DispatchType(CustomRoomModel.ON_ROOM_ENTER_NOTIFY)

    self:CheckAutoEnterCustomRoom()
end

function CustomRoomCtrl:JoinRoomRsp_Func(Msg)
    print_r(Msg)
    self.Model:SetCurEnteredRoomInfo(Msg.RoomInfo)
    self.Model:DispatchType(CustomRoomModel.ON_ROOM_ENTER_NOTIFY)

    self:CheckAutoEnterCustomRoom()
end

function CustomRoomCtrl:ExitRoomRsp_Func(Msg)
    self.Model:SetCurEnteredRoomInfo(nil)
    self.Model:DispatchType(CustomRoomModel.ON_ROOM_EXIT_NOTIFY)
end

-- function CustomRoomCtrl:ChangePosRsp_Func(Msg)
-- end
function CustomRoomCtrl:ChangeTeamRsp_Func(Msg)
end
function CustomRoomCtrl:KickPlayerRsp_Func(Msg)
end
function CustomRoomCtrl:TransMasterRsp_Func(Msg)
end
function CustomRoomCtrl:DissolveRoomRsp_Func(Msg)
end

function CustomRoomCtrl:InviteRsp_Func(Msg)
    
end

function CustomRoomCtrl:InviteSync_Func(Msg)
    --TODO 处理邀请，需要弹窗 未做
end

function CustomRoomCtrl:TransMasterSync_Func(Msg)
    self.Model:TransMasterSync_Func(Msg)
end

function CustomRoomCtrl:MasterExitRoomSync_Func(Msg)
    self.Model:MasterExitRoomSync_Func(Msg)
end


function CustomRoomCtrl:PlayerExitRoomSync_Func(Msg)
    self.Model:PlayerExitRoomSync_Func(Msg)
end

function CustomRoomCtrl:KickPlayerSync_Func(Msg)
    UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCtrl_Youwereaskedtoleavet"))
    self.Model:SetCurEnteredRoomInfo(nil)
    self.Model:DispatchType(CustomRoomModel.ON_ROOM_EXIT_NOTIFY)
end

function CustomRoomCtrl:JoinRoomSync_Func(Msg)
    self.Model:JoinRoomSync_Func(Msg)
end

function CustomRoomCtrl:ChangePosSync_Func(Msg)
    self.Model:ChangePosSync_Func(Msg)
end

function CustomRoomCtrl:ChangeTeamSync_Func(Msg)
    self.Model:ChangeTeamSync_Func(Msg)
end


function CustomRoomCtrl:DissolveRoomSync_Func(Msg)
    self.Model:SetCurEnteredRoomInfo(nil)
    self.Model:DispatchType(CustomRoomModel.ON_ROOM_EXIT_NOTIFY)
end

function CustomRoomCtrl:StartGameRsp_Func(Msg)
    --TODO 需要进行提示，正在准备进入游戏，请稍候
end


function CustomRoomCtrl:StartGameSync_Func(Msg)
    self.Model:StartGameSync_Func(Msg)
end

--[[
	Msg = {
	    int64 CustomRoomId = 1;     // 自建房Id
	    string CustomRoomName = 2;  // 变化后的自建房名字
	}
]]
function CustomRoomCtrl:CustomRoomNameChangeSync_Func(Msg)
	self.Model:On_CustomRoomNameChangeSync(Msg)
    self.Model:DispatchType(CustomRoomModel.ON_ROOM_NAME_CHANGE)
end

--[[
    message CustomRoomInfoRsp
    {
        CUSTOMROOM_PLAYER_STATE CustomRoomPlayerState = 1;  // 玩家在房间中的状态
        FullRoomInfo RoomInfo = 2;
    }
]]
function CustomRoomCtrl:CustomRoomInfoRsp_Func(Msg)
    if Msg.CustomRoomPlayerState == 0 then
        self.Model:SetCurEnteredRoomInfo(Msg.RoomInfo)

        self.Model:DispatchType(CustomRoomModel.ON_ROOM_REFRESH)
    end
end


---自动创建自建房相关
function CustomRoomCtrl:TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_func(InNotCanReqStatus)
    if not InNotCanReqStatus then return end
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    if not UserModel.IsAutoEnterCustomRoom then return end
    local CurEnteredRoomId = self.Model:GetCurEnteredRoomId()
    if CurEnteredRoomId then
        --进入房间流程
        self:CheckAutoEnterCustomRoom()
    else
        --加入房间流程
        self:CheckAutoJoinCustomRoom()
    end
end

--检测自动进入房间
function CustomRoomCtrl:CheckAutoEnterCustomRoom()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    if not UserModel.IsAutoEnterCustomRoom then return end
    UserModel.IsAutoEnterCustomRoom = false
    MvcEntry:OpenView(ViewConst.CustomRoomPanel)

    self:CheckAutoStartCustomRoom()
end

--检测自动加入房间
function CustomRoomCtrl:CheckAutoJoinCustomRoom()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local RoomCfg = UserModel.CMDAutoEnterCustomRoomCfg
    if RoomCfg then
        self:SendProto_AutoTestJoinRoomReq(RoomCfg.CustomRoomModeId, RoomCfg.CustomRoomView, RoomCfg.CustomRoomTeamType, RoomCfg.CustomRoomDsGroupId, RoomCfg.CustomRoomConfigId, RoomCfg.CustomRoomSceneId, 
            RoomCfg.CustomRoomMaxPlayerNum, RoomCfg.CustomRoomTimeToStart, RoomCfg.CustomRoomId, RoomCfg.CustomRoomTeamNumLimit, RoomCfg.ParentDSExtParams, RoomCfg.DSExtParams)
    end
end

--检测进入房间后开始游戏
function CustomRoomCtrl:CheckAutoStartCustomRoom()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    if not UserModel.IsAutoStartCustomRoom then return end
    UserModel.IsAutoStartCustomRoom = false
    local CurEnteredRoomId = self.Model:GetCurEnteredRoomId()
    if CurEnteredRoomId then
        local IsMaster = self.Model:IsMaster(UserModel:GetPlayerId())
        if IsMaster then
            self:InsertTimer(Timer.NEXT_FRAME, function()
                self:SendProto_StartGameReq(CurEnteredRoomId)
            end)
        end
    end
end

------------------------------------请求相关----------------------------


function CustomRoomCtrl:SendProto_RoomListReq(ModeId,IsNoPasswd)
    self.Model:SetCurSearchRoomInfo(nil)
    local Msg = {
        ModeId = ModeId,
        IsNoPasswd = IsNoPasswd,
    }
    self:SendProto(Pb_Message.RoomListReq,Msg,Pb_Message.RoomListRsp)
end

function CustomRoomCtrl:SendProto_SearchRoomReq(RoomId)
    local Msg = {
        CustomRoomId = RoomId,
    }
    print_r(Msg)
    self:SendProto(Pb_Message.SearchRoomReq,Msg,Pb_Message.SearchRoomRsp)
end

function CustomRoomCtrl:SendProto_CreateRoomReq(Msg)
    print_r(Msg)
    self:SendProto(Pb_Message.CreateRoomReq,Msg,Pb_Message.CreateRoomRsp)
end

function CustomRoomCtrl:SendProto_JoinRoomReq(RoomId,Passwd,Source)
    local Msg = {
        CustomRoomId = RoomId,
        Passwd = Passwd,
        Source = Source,
    }
    self:SendProto(Pb_Message.JoinRoomReq,Msg,Pb_Message.JoinRoomRsp)
end

function CustomRoomCtrl:SendProto_ExitRoomReq(RoomId)
    local Msg = {
        CustomRoomId = RoomId,
    }
    self:SendProto(Pb_Message.ExitRoomReq,Msg,Pb_Message.ExitRoomRsp)
end

--暂时废弃
-- function CustomRoomCtrl:SendProto_ChangePosReq(RoomId,TarPos)
--     local Msg = {
--         CustomRoomId = RoomId,
--         TarPos = TarPos,
--     }
--     self:SendProto(Pb_Message.ChangePosReq,Msg,Pb_Message.ChangePosRsp)
-- end

function CustomRoomCtrl:SendProto_ChangeTeamReq(RoomId,TarTeamId)
    local Msg = {
        CustomRoomId = RoomId,
        TarTeamId = TarTeamId,
    }
    self:SendProto(Pb_Message.ChangeTeamReq,Msg,Pb_Message.ChangeTeamRsp)
end

function CustomRoomCtrl:SendProto_KickPlayerReq(RoomId,TarPlayerId)
    local Msg = {
        CustomRoomId = RoomId,
        TarPlayerId = TarPlayerId,
    }
    self:SendProto(Pb_Message.KickPlayerReq,Msg,Pb_Message.KickPlayerRsp)
end

function CustomRoomCtrl:SendProto_TransMasterReq(RoomId,TarPlayerId)
    local Msg = {
        CustomRoomId = RoomId,
        TarPlayerId = TarPlayerId,
    }
    self:SendProto(Pb_Message.TransMasterReq,Msg,Pb_Message.TransMasterRsp)
end

function CustomRoomCtrl:SendProto_InviteReq(RoomId,InviteeId)
    local Msg = {
        CustomRoomId = RoomId,
        InviteeId = InviteeId,
    }
    self:SendProto(Pb_Message.InviteReq,Msg,Pb_Message.InviteRsp)
end

function CustomRoomCtrl:SendProto_DissolveRoomReq(RoomId)
    local Msg = {
        CustomRoomId = RoomId,
    }
    self:SendProto(Pb_Message.DissolveRoomReq,Msg,Pb_Message.DissolveRoomRsp)
end
function CustomRoomCtrl:SendProto_StartGameReq(RoomId)
    local Msg = {
        CustomRoomId = RoomId,
    }
    self:SendProto(Pb_Message.StartGameReq,Msg,Pb_Message.StartGameRsp)

    CWaring("[KeyStep-->Client][0-room] CustomRoomCtrl:SendProto_StartGameReq")
    UE.UGFUnluaHelper.OnClientHitKeyStep("0")
end

function CustomRoomCtrl:SendProto_CustomRoomInfoReq(RoomId)
    if not RoomId then
        CError("CustomRoomCtrl:SendProto_CustomRoomInfoReq RoomId nil",true)
        return
    end
    local Msg = {
        CustomRoomId = RoomId,
    }
    self:SendProto(Pb_Message.CustomRoomInfoReq,Msg,Pb_Message.CustomRoomInfoRsp)
end

-- 自动跑测时的加入房间请求
---@param ModeId number 模式Id
---@param View number 视角1, 2, 3
---@param TeamType number 队伍类型1, 2, 3
---@param DsGroupId number 房主所在的DsGroupId，即选择的Ds服务器环境
---@param ConfigId number 模式配置的ConfigId
---@param SceneId number 地图ID
---@param MaxPlayerNum number 最大人数，开局
---@param TimeToStart number 房间存在当前时间后自动开局
---@param RoomId number 房间Id 必须保证为正数
---@param TeamNumLimit number 自建房队伍数量
---@param ParentDSExtParams string 父DS扩展命令行参数，仅用于DS Fork模式时，父DS扩展命令行参数
---@param DSExtParams string DS扩展命令行参数，非DS Fork模式 和 DS Fork模式下 子DS使用 的扩展命令行参数 string 
function CustomRoomCtrl:SendProto_AutoTestJoinRoomReq(ModeId, View, TeamType, DsGroupId, ConfigId, SceneId, MaxPlayerNum, TimeToStart, RoomId, TeamNumLimit, ParentDSExtParams, DSExtParams)
    local Msg = {
        ModeId = ModeId,
        View = View,
        TeamType = TeamType,
        DsGroupId = DsGroupId,
        ConfigId = ConfigId,
        SceneId = SceneId,
        MaxPlayerNum = MaxPlayerNum,
        TimeToStart = TimeToStart,
        RoomId = RoomId,
        TeamNumLimit = TeamNumLimit,
        ParentDSExtParams = ParentDSExtParams,
        DSExtParams = DSExtParams,
    }
    print_r(Msg, "[hz] CustomRoomCtrl:SendProto_AutoTestJoinRoomReq ==== Msg")
    self:SendProto(Pb_Message.AutoTestJoinRoomReq,Msg)
end



