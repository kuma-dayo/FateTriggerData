---
--- Ctrl 模块，主要用于处理协议
--- Description: 大厅匹配
--- Created At: 2023/05/10 10:00
--- Created By: 朝文
---

require("Client.Modules.Match.MatchModel")
require("Client.Modules.Team.TeamModel")
require("Client.Modules.Hall.HallModel")

local class_name = "MatchCtrl"
---@class MatchCtrl : UserGameController
MatchCtrl = MatchCtrl or BaseClass(UserGameController, class_name)

function MatchCtrl:__init()
    CWaring("==MatchCtrl init")
    self.MatchModel = nil 
    
    self.AutoMatch = false  --自动匹配需要的字段
end

function MatchCtrl:Initialize()
    ---@type MatchModel
    self.MatchModel = self:GetModel(MatchModel)
end

function MatchCtrl:AddMsgListenersUser()
    --添加协议回包监听事件
    self.ProtoList = {
        { MsgName = Pb_Message.MatchResultSync,	        Func = self.OnMatchResultSync },        --请求结果回复
        { MsgName = Pb_Message.MatchCancelRsp,	        Func = self.OnMatchCancelRsp },         --请求取消匹配回复
        { MsgName = Pb_Message.MatchRsp,	            Func = self.OnMatchRsp },               --请求回复
        { MsgName = Pb_Message.DsMetaSync,	            Func = self.OnDsMetaSync },             --ds服务器参数下发（包括匹配及自建房）
        { MsgName = Pb_Message.SceneLdCpltdQuerySync,	Func = self.OnSceneLdCpltdQuerySync },  --缓存加载ds资源完成发给服务器的数据及结构信息
        { MsgName = Pb_Message.MatchDsBaseInfoSync,	    Func = self.OnMatchDsBaseInfoSync },    --战斗前同步GameId
        { MsgName = Pb_Message.MatchAndDsStateSync,	    Func = self.MatchAndDsStateSync },      --登录后匹配或对局信息同步
        { MsgName = Pb_Message.PlayerLogoutDs,	        Func = self.PlayerLogoutDs },           --玩家退出ds通知，主要防止卡流程
        { MsgName = Pb_Message.GiveupReconnectDsRsp,	Func = self.GiveupReconnectDsRsp },     --玩家放弃重连进上一局未结束的游戏
        { MsgName = Pb_Message.GameExceptionSync,	        Func = self.GameExceptionSync },    --对局异常通知，主要包括启动ds后的异常通知下发，如Ds加载超时，崩溃等（包括匹配及自建房）
    }

    self.MsgList = {
        { Model = TeamModel,    MsgName = TeamModel.ON_TEAM_MEMBER_PREPARE,	Func = self.ON_TEAM_MEMBER_PREPARE_func },  --队员准备状态同步
        { Model = TeamModel,    MsgName = TeamModel.ON_ADD_TEAM_MEMBER,	    Func = self.BreakAutoMatch },               --队员成员增加
        { Model = TeamModel,    MsgName = TeamModel.ON_DEL_TEAM_MEMBER,	    Func = self.BreakAutoMatch },               --队员成员减少
        { Model = TeamModel,    MsgName = TeamModel.ON_SELF_JOIN_TEAM,	    Func = self.BreakAutoMatch },               --自己加入队伍
        { Model = TeamModel,    MsgName = TeamModel.ON_SELF_SINGLE_IN_TEAM,	Func = self.BreakAutoMatch },               --自己退出队伍 （变回单人，可能存在单人队）
        { Model = MatchModel,   MsgName = MatchModel.ON_BATTLE_MAP_LOAED,	Func = self.ON_BATTLE_MAP_LOAED_func },     --战斗地图加载完成
        { Model = CommonModel,  MsgName = CommonModel.ON_HALL_TAB_SWITCH_COMPLETED,	Func = self.ON_HALL_TAB_SWITCH_COMPLETED_func },  --大厅场景切换完成
        
        { Model = HallModel,    MsgName = HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,	Func = self.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_func },
    }
end

---玩家登入的时候
function MatchCtrl:OnLogin(data)    
end

---玩家登出
function MatchCtrl:OnLogout(data)
    CommonUtil.TimerRegisterOrUnRegister(self.TimerList, false)
end

---用户从大厅进入战斗处理的逻辑
---进入战斗时，需要调整玩家的匹配状态为未匹配
function MatchCtrl:OnPreEnterBattle()
    self.MatchModel:SetMatchState(self.MatchModel.Enum_MatchState.MatchIdle)
end
--从战斗返回大厅成功
function MatchCtrl:OnAfterBackToHall()
    self:SendProto_MatchAndDsStateReq()
end

function MatchCtrl:TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_func(InNotCanReqStatus)
    if not InNotCanReqStatus then return end
    
    self:InsertTimer(0.3, function()
        
        -- --重连回局内战斗弹窗
        -- ---@type MatchModel
        -- local MatchModel = MvcEntry:GetModel(MatchModel)
        -- if MatchModel:GetMatchDsReconnectInfo() then
            -- local DsCache = MatchModel:GetMatchDsReconnectInfo()
            -- UIMessageBox.Show({
            --     describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_Itisdetectedthatthel")),
            --     leftBtnInfo = {
            --         name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_giveup")),           
            --         callback = function()
            --             self:SendProto(Pb_Message.GiveupReconnectDsReq, {GameId = DsCache.GameId})
            --         end,
            --     },
            --     rightBtnInfo = {          
            --         name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_Reconnect")),
            --         callback = function()
            --             self:ReqConnectDServer({DsMeta = DsCache})
            --         end,
            --     },
            -- })            
        --     MatchModel:CleanMatchDsReconnectInfo()
        --     return
        -- end
        
        --局外匹配状态调整
        CLog("[cw] MatchModel:TriggerSyncMatchStateChange()")
        MatchModel:TriggerSyncMatchStateChange()
    end)    
    
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    if not UserModel.IsLoginByCMD or not UserModel.IsAutoMatch then return end
    
    --自动匹配
    UserModel.IsLoginByCMD = false
    UserModel.IsAutoMatch = false
    self:InsertTimer(Timer.NEXT_FRAME, function()
        self:SendMatchReq({
            DsGroupId       = UserModel.CMDAutoMatchCfg.DsGroupId and tonumber(UserModel.CMDAutoMatchCfg.DsGroupId),
            PlayerId        = UserModel.CMDAutoMatchCfg.PlayerId and tonumber(UserModel.CMDAutoMatchCfg.PlayerId),
            GameplayId      = UserModel.CMDAutoMatchCfg.GameplayId and tonumber(UserModel.CMDAutoMatchCfg.GameplayId),
            LevelId         = UserModel.CMDAutoMatchCfg.LevelId and tonumber(UserModel.CMDAutoMatchCfg.LevelId),
            View            = UserModel.CMDAutoMatchCfg.View and tonumber(UserModel.CMDAutoMatchCfg.View),
            TeamType        = UserModel.CMDAutoMatchCfg.TeamType and tonumber(UserModel.CMDAutoMatchCfg.TeamType),
            IsCrossPlatform = UserModel.CMDAutoMatchCfg.IsCrossPlatformMatch == "1",
            NeedFill        = UserModel.CMDAutoMatchCfg.FillTeam == "1",
        })
    end)
end

--[[
    MatchSelectInfo = {
        PlayModeId         = 1,                 --玩法模式id
        Perspective        = 1,                 --视角类型
        TeamType           = 1,                 --队伍类型
        LevelId            = 2,                 --关卡id
        SceneId            = 3,                 --场景id
        ModeId             = 101                --模式id
        CrossPlatformMatch = true,              --是否跨平台匹配
        FillTeam           = true,              --是否补满队伍
        SeverId            = 4,                 --服务器id
    }
--]]
---封装一个接口，外部调用来改变匹配参数
---单人情况下不需要告诉服务器，只需要本地存储就可以了
---多人情况下需要告诉服务器，等服务器回包再进行存储
function MatchCtrl:ChangeMatchModeInfo(MatchSelectInfo)
    CLog("[cw] MatchCtrl:ChangeMatchModeInfo(" .. string.format("%s", tostring(MatchSelectInfo)) .. ")")
    print_r(MatchSelectInfo, "[cw] ====MatchSelectInfo")
    
    if not MatchSelectInfo then MatchSelectInfo = {} end    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)    
    
    --优先级 实参-> 当前已选择 -> 默认
    local function _GetPriorityData(param, cache, default)
        if MatchSelectInfo[param] ~= nil then return MatchSelectInfo[param] end
        if cache ~= nil then return cache end
        return default
    end
    --                                             实参中的字段                        存储的数据                                                        默认值
    local PlayModeId            = _GetPriorityData("PlayModeId",            MatchModel:GetPlayModeId(),                                     MatchModeSelectModel.Const.DefaultSelectPlayModeId)
    local TeamType              = _GetPriorityData("TeamType",              MatchModel:GetTeamType(),                                       MatchModeSelectModel.Const.DefaultSelectTeamType)
    local Perspective           = _GetPriorityData("Perspective",           MatchModel:GetPerspective(),                                    MatchModeSelectModel.Const.DefaultSelectPerspective)
    local LevelId               = _GetPriorityData("LevelId",               MatchModel:GetLevelId(),                                        MatchModeSelectModel.Const.DefaultSelectLevelId) 
    local SceneId               = _GetPriorityData("SceneId",               MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(LevelId),    MatchModeSelectModel.Const.DefaultSelectSceneId) 
    local ModeId                = _GetPriorityData("ModeId",                MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId),     MatchModeSelectModel.Const.DefaultSelectModeId) 
    local CrossPlatformMatch    = _GetPriorityData("CrossPlatformMatch",    MatchModel:GetIsCrossPlatformMatch(),                           MatchModeSelectModel.Const.DefaultSelectCrossPlatformMatch) 
    local FillTeam              = _GetPriorityData("FillTeam",              MatchModel:GetIsFillTeam(),                                     MatchModeSelectModel.Const.DefaultSelectFillTeam) 
    local SeverId               = _GetPriorityData("SeverId",               MatchModel:GetSeverId(),                                        nil) 

    --1.单人模式(且无队伍，例如非邀请状态下)下本地直接设置就可以，不需要同步服务器
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if not(TeamModel.TeamInfoSync and TeamModel.TeamInfoSync.TeamId and TeamModel.TeamInfoSync.TeamId > 0 and
            TeamModel.TeamInfoSync.PlayerCnt and TeamModel.TeamInfoSync.PlayerCnt >= 1 and
            TeamModel.TeamInfoSync.Members and TeamModel.TeamInfoSync.Members[UserModel:GetPlayerId()] ~= nil) then
        CLog("[cw] Not in team, only update local mode select data")
        CLog("[cw] ModeId: " .. tostring(ModeId))
        CLog("[cw] TeamType: " .. tostring(TeamType))
        CLog("[cw] Perspective: " .. tostring(Perspective))
        CLog("[cw] SceneId: " .. tostring(SceneId))
        CLog("[cw] LevelId: " .. tostring(LevelId))
        CLog("[cw] PlayModeId: " .. tostring(PlayModeId))
        CLog("[cw] CrossPlatformMatch: " .. tostring(CrossPlatformMatch))
        CLog("[cw] FillTeam: " .. tostring(FillTeam))
        CLog("[cw] SeverId: " .. tostring(SeverId))
        MatchModel:SetModeId(ModeId)
        MatchModel:SetTeamType(TeamType)
        MatchModel:SetPerspective(Perspective)
        MatchModel:SetSceneId(SceneId)
        MatchModel:SetLevelId(LevelId)
        MatchModel:SetPlayModeId(PlayModeId)
        MatchModel:SetIsCrossPlatformMatch(CrossPlatformMatch)
        MatchModel:SetIsFillTeam(FillTeam)
        if SeverId ~= nil then MatchModel:SetSeverId(SeverId) end
        return
    end

    --2.组队情况下，需要同步服务器
    --与当前的缓存一致的话就不需要做额外处理了
    MatchModel:SetIsFillTeam(FillTeam)
    local CachePlayModeId = MatchModel:GetPlayModeId()
    local CacheTeamType = MatchModel:GetTeamType()
    local CachePerspective = MatchModel:GetPerspective()
    local CacheLevelId = MatchModel:GetLevelId()
    local CacheIsCrossPlayformMatch = MatchModel:GetIsCrossPlatformMatch()
    local CacheSeverId = MatchModel:GetSeverId()
    if PlayModeId == CachePlayModeId and TeamType == CacheTeamType and Perspective == CachePerspective and LevelId == CacheLevelId and CacheIsCrossPlayformMatch == CrossPlatformMatch and CacheSeverId == SeverId then
        CLog("[cw] PlayModeId == CachePlayModeId and TeamType == CacheTeamType and Perspective == CachePerspective and LevelId == CacheLevelId and CacheIsCrossPlayformMatch == CrossPlatformMatch and CacheSeverId == SeverId, no need to Change")
        return
    end
    
    CLog("[cw] GameplayId: " .. tostring(PlayModeId))
    CLog("[cw] LevelId: " .. tostring(LevelId))
    CLog("[cw] View: " .. tostring(Perspective))
    CLog("[cw] TeamType: " .. tostring(TeamType))
    CLog("[cw] IsCrossPlatform: " .. tostring(CrossPlatformMatch))
    CLog("[cw] SeverId: " .. tostring(SeverId))
    if SeverId ~= nil then MatchModel:SetSeverId(SeverId) end           --服务器不上传，但是得本地存储
    ---@type TeamCtrl
    local TeamCtrl = MvcEntry:GetCtrl(TeamCtrl)
    TeamCtrl:SendTeamChangeModeReq({
        GameplayId = PlayModeId, 
        LevelId = LevelId,
        View = Perspective,
        TeamType = TeamType,
        IsCrossPlatform = CrossPlatformMatch,
    })
end

---------------------------------------------------- 自动匹配 ------------------------------------------------------------
--region
---封装一个取消自动匹配的接口，外部不要直接操控字段
function MatchCtrl:BreakAutoMatch()
    if not self.AutoMatch then return end
    
    self.AutoMatch = false
end

---自动匹配需要的请求
---当玩家从大厅的局外结算点击继续时，队长需要判断其他玩家的状态，当其他玩家都处于准备中（在局外结算中时不属于结算中）时，就继续进行匹配
---如果当时其他玩家还在结算中，则需要等待队员都退出局外结算界面回到大厅后，再发送匹配请求，来实现自动匹配
function MatchCtrl:AutoMatchReq()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)

    --1.在队伍中，但不是队长，则不能进行匹配，需要调整状态为准备中
    if TeamModel:IsSelfTeamNotCaptain() then
        return 
    end

    --2.更新自动匹配设置    
    local IsInTeam = TeamModel:IsInTeam(UserModel:GetPlayerId())
    local ReqData = {
        PlayerId        = UserModel:GetPlayerId(),
        ModeGroupId     = 1,
        GameplayId      = MatchModel:GetPlayModeId(),
        LevelId         = MatchModel:GetLevelId(),
        ModeId         = MatchModel:GetModeId(),
        IsCrossPlatform = MatchModel:GetIsCrossPlatformMatch(),
        NeedFill        = MatchModel:GetIsFillTeam(),
        IsTeamMatch     = IsInTeam,
    }

    --3.发送匹配请求的逻辑
    --3.1.队伍中需要检查是否所有队友已经准备
    if IsInTeam then
        self.AutoMatch = true
        local AutoMatchCheckPass = self:AutoMatchCheck()
        if AutoMatchCheckPass then
            self:AutoMatchStart(ReqData)
        end

    --3.2.单人情况下不需要检查，直接发送请求
    else
        self:SendMatchReq(ReqData)
    end
end

---封装一个检查自动匹配的
---@return boolean 当前状态下是否满足自动匹配要求
function MatchCtrl:AutoMatchCheck()
    --1.没有开启自动匹配，不适用
    if not self.AutoMatch then return false end
    
    --2.单人模式下，不适用
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if not TeamModel:IsSelfInTeam() then return false end
    
    --3.队员未准备，不做处理
    if not TeamModel:IsMyTeamAllMembersTeamPlayerInfoStatusREADY() then return false end

    -- --4.已检查通过，正在延迟处理中，不做处理
    -- if self.AutoMatchDelayTimerHandler then return false end    
    
    --5.Pass
    return true    
end

---延迟1秒开始匹配
---@param ReqData table
function MatchCtrl:AutoMatchStart(ReqData)
    -- self.AutoMatchDelayTimerHandler = self:InsertTimer(1, function()
        self:BreakAutoMatch()

        self:SendMatchReq(ReqData)

        -- self:RemoveTimer(self.AutoMatchDelayTimerHandler)
        -- self.AutoMatchDelayTimerHandler = nil
    -- end)
end
--endregion
--------------------------------------------------- 事件相关 -------------------------------------------------------------

---加载完成ds资源后需要同步ds状态信息
function MatchCtrl:ON_BATTLE_MAP_LOAED_func()
    local ReqDSInfoData = self.MatchModel:GetReqDSInfoData()
    if not ReqDSInfoData then
        return
    end
    ReqDSInfoData.Msg = "ok"
    
    self:SendProto(Pb_Message.SceneLdCpltdResReq, self.Model.ReqDSInfoData)
end

---队员准备状态同步
---这里需要处理
---    当所有队友准备好之后，自己也要准备
---    自动匹配检查
---@param InMemberInfo table
function MatchCtrl:ON_TEAM_MEMBER_PREPARE_func(InMemberInfo)
    --0.判空保护
    if not InMemberInfo then return end

    --1.如果自身缓存的准备状态为空，则初始化一下状态
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    
    --2.玩家自身不是队长，则不处理   
    local IsCaptain = TeamModel:IsSelfTeamCaptain()
    if not IsCaptain then return end
    
    --3.自动匹配检测
    local AutoMatchCheckPass = self:AutoMatchCheck()
    if AutoMatchCheckPass then
        self:AutoMatchStart()
    end
end

------------------------------------------------- 请求/协议相关 ----------------------------------------------------------
---=========== 同步状态（登陆后下发匹配状态） ===========---
--region
--[[
Msg = {
    DsMeta = {
        bAsanDs
        IsPrepare
        PlayerId
        GameId
        GameBranch
        Port
    }
    MatchState = 0|1|2
}
--]]
---登录后匹配或对局信息同步
function MatchCtrl:MatchAndDsStateSync(Msg)
    CWaring("[cw] MatchCtrl:MatchAndDsStateSync(" .. string.format("%s", Msg) .. ")")
    print_r(Msg, "[cw] ====Msg",true)

    ---test---
    --Msg.DsMeta = {
    --    bAsanDs = false,
    --    Ip = "10.85.50.156",
    --    PlayerId    = 15183380483,
    --    GameId  = "17217042310121145231",
    --    GameBranch  = "trunk6",
    --    Port    = 9242
    --}
    ---test end---
    
    --断线重连回局内

    --如果还在travel或者战斗阶段，不处理此协议
    if _G.GameInstance:GetGameStageType() == UE.EGameStageType.Travel2Battle or _G.GameInstance:GetGameStageType() == UE.EGameStageType.Battle then
        CWaring("[cw] MatchCtrl:MatchAndDsStateSync GetGameStageType is not avaliable, Break")
        return
    end
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    if Msg.DsMeta and Msg.DsMeta.GameId ~= "" then
        CWaring("[cw] MatchCtrl:MatchAndDsStateSync DsMeta is avaliable, tring to show reconnect panel")
        -- MatchModel:SetMatchDsReconnectInfo(Msg.DsMeta)
        MatchModel:SaveCurDsGroupId(Msg.DsMeta.DsGroupId)
        --发现有对局重连，注册一个贴脸弹窗
        self:GetSingleton(CommonCtrl):TryFaceActionOrInCache(function ()
            local DsCache = Msg.DsMeta
            UIMessageBox.Show({
                describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_Itisdetectedthatthel")),
                leftBtnInfo = {
                    name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_giveup_Btn")),           
                    callback = function()
                        self:SendProto(Pb_Message.GiveupReconnectDsReq, {GameId = DsCache.GameId})
                    end,
                },
                rightBtnInfo = {          
                    name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_Reconnect_Btn")),
                    callback = function()
                        self:ReqConnectDServer({DsMeta = DsCache})
                        CWaring("[KeyStep-->Client][1] MatchCtrl:MatchAndDsStateSync")
                        UE.UGFUnluaHelper.OnClientHitKeyStep("[KeyStep-->Client][1] Reconnect")
                    end,
                },
                HideCloseBtn = true,
                HideCloseTip = true,
            })    
        end)
    end
        
    --匹配状态改变
    local MatchConst = require("Client.Modules.Match.MatchConst")
    if Msg.MatchState == MatchConst.Enum_MatchAndDsStateSync_MatchState.NOT_IN_MATCHING then
        MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchIdle)
    elseif Msg.MatchState == MatchConst.Enum_MatchAndDsStateSync_MatchState.MATCHING then
        MatchModel:SetMatchState(MatchModel.Enum_MatchState.Matching)
    elseif Msg.MatchState == MatchConst.Enum_MatchAndDsStateSync_MatchState.MATCH_SUCCESS then
        MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchSuccess)
    end
end
--endregion
---=========== 进入DS ===========---
--region
--[[
    InData = {
        DsMeta = {
            Ip = 1,
            Port = 2,
        }
    }
--]]
---链接至DS服务器
---@param InData table 包含IP及端口数据
function MatchCtrl:ReqConnectDServer(InData)
    MvcEntry:GetModel(HallModel):SetIsLevelTravel(true)
    -- 检测下当前socket状态，断线则不弹此提示
    if not MvcEntry:GetModel(SocketMgr):IsConnected() then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_Thecurrentnetworkisd"))
        return
    end
    self.MatchModel:DispatchType(MatchModel.ON_CONNECT_DS_SERVER)
    --Trave之前通知客户端需要连的DS类型 
    UE.UGFUnluaHelper.SetIsConnectingAsanDS(InData.DsMeta.bAsanDs)
    UE.UGFUnluaHelper.SetDSGameId(InData.DsMeta.GameId)
    UE.UGFUnluaHelper.SetAegisSequnce(InData.DsMeta.PlayerId)

    self:CheckandSetEncryptionKeySeed(InData.DsMeta.EncryptKey, InData.DsMeta.ServerPublicKey, InData.DsMeta.ServerKeyMD5)

    -- 连接参数cmd
    local ExecCmd = string.format("Open %s:%d", InData.DsMeta.Ip, InData.DsMeta.Port)

    -- 自定义客户端参数
    local ClientParams = {
        RoomId = 1,
        UUId = InData.DsMeta.PlayerId
    }

    --Travel到战斗关卡
    self:TravelToBattle(ExecCmd, ClientParams)
end

-- 生成并校验加密种子
function MatchCtrl:CheckandSetEncryptionKeySeed(ServerEncryptKey, ServerPublicKey, ServerKeyMD5)
    CWaring("MatchCtrl:CheckandSetEncryptionKeySeed ServerEncryptKey="..tostring(ServerEncryptKey))
    CWaring("MatchCtrl:CheckandSetEncryptionKeySeed ServerPublicKey="..tostring(ServerPublicKey).." ServerKeyMD5="..tostring(ServerKeyMD5))

    if ServerEncryptKey ~= "" and ServerPublicKey ~= "" and ServerKeyMD5 ~= "" then
        local TheLoginModel = self:GetModel(LoginModel)
        local ClientDHKeyInfo = TheLoginModel:GetClientDHKeyInfo()
        print("MatchCtrl:CheckandSetEncryptionKeySeed ClientPrivateKey="..tostring(ClientDHKeyInfo.PrivateKey).." ServerPublicKey="..tostring(ServerPublicKey))
        local ClientDHKeySeed = UE.UGFUnluaHelper.GenerateDHKeySeed(ServerPublicKey, ClientDHKeyInfo.PrivateKey)
        print("MatchCtrl:CheckandSetEncryptionKeySeed ClientDHKeySeed="..ClientDHKeySeed)

        --local DecodeServerEncryptKey = self:dec(ServerEncryptKey)
        ClientEncryptKey = self:DecXorForBattle(ServerEncryptKey, ClientDHKeySeed)
        print("MatchCtrl:CheckandSetEncryptionKeySeed ClientEncryptKey="..ClientEncryptKey)

        -- local temp2 = "1049703680"
        local ClientKeySeedMD5 = md5.sumhexa(ClientEncryptKey)
        CWaring("MatchCtrl:CheckandSetEncryptionKeySeed ClientKeySeedMD5="..tostring(ClientKeySeedMD5).." ServerKeyMD5="..tostring(ServerKeyMD5))
        if ClientKeySeedMD5 == ServerKeyMD5 then
            UE.UGFUnluaHelper.SetEncryptionKeySeed(ClientEncryptKey)
        else
            CWaring("MatchCtrl:CheckandSetEncryptionKeySeed MD5 Check Error!!")
        end
        -- local TestXor = "dywdjbzwm#123*"
        -- local TestResult1 = self:DecXorForBattle(TestXor, ClientDHKeySeed)
        -- local TestResult2 = self:DecXorForBattle(TestResult1, ClientDHKeySeed)
        -- print("MatchCtrl:CheckandSetEncryptionKeySeed TestResult1="..tostring(TestResult1))
        -- print("MatchCtrl:CheckandSetEncryptionKeySeed TestResult2="..tostring(TestResult2))
    else
        CWaring("MatchCtrl:CheckandSetEncryptionKeySeed Some Param is NULL")
    end
end

function MatchCtrl:DecXorForBattle(src, key)
    if src == nil then
        print("MatchCtrl.DecXorForBattle src == nil!")
        return
    end
    if key == nil then
        print("MatchCtrl.DecXorForBattle key == nil!")
        return
    end
    local ssrc = tostring(src)
    local ssrc_len = string.len(ssrc)
    if ssrc_len == 0 then
        print("MatchCtrl.DecXorForBattle src len == 0!")
        return
    end
    local skey = tostring(key)
    local skey_len = string.len(skey)
    if skey_len == 0 then
        print("MatchCtrl.DecXorForBattle key len == 0!")
        return
    end
    local dec_src = {}
    local kidx = 1
    for i=1, ssrc_len do
        local ch_src = string.byte(ssrc, i)
        local ch_key = string.byte(skey, kidx)
        kidx = ( kidx % skey_len ) + 1
        local ch = ch_src ~ ch_key
        table.insert(dec_src, string.char(ch))
    end
    return table.concat(dec_src)
end

---Travel到战斗关卡
function MatchCtrl:TravelToBattle(ExecUrl, ClientParams)
    -- 进局内，加载loading界面前，刷新字体图集缓存
    -- 因此loading界面的字体会被加载进来，可避免到了局内再LoadFont
    UE.UGFUnluaHelper.FlushFontAtlasCache("MatchCtrl:TravelToBattle")

    local EnterFunc = function()
        --Lua侧GC
        LuaGC()

        local Param = {
            resUrl = ExecUrl,
            option = ClientParams or {},
        }
        self:OpenView(ViewConst.LevelBattle,Param)
    end

    local LoadingShowParam = {
        TypeEnum = LoadingCtrl.TypeEnum.HALL_TO_BATTLE,
    }
    MvcEntry:GetCtrl(LoadingCtrl):ReqLoadingScreenShow(LoadingShowParam,EnterFunc)
end

---请求ds服务器参数回复
---@param InData table
function MatchCtrl:OnDsMetaSync(InData)
    if not InData.DsMeta then return end
    

    CWaring("======MatchCtrl:OnMatchDsMetaRsp=========")
    print_r(InData,"MatchCtrl:OnDsMetaSync:",true)
    CWaring("[KeyStep-->Client][1] MatchCtrl:OnDsMetaSync")
    UE.UGFUnluaHelper.OnClientHitKeyStep("1")
    self.MatchModel:SaveCurDsGroupId(InData.DsMeta.DsGroupId)
    if InData.DsMetaSrc == Pb_Enum_DS_META_SRC.MATCH_SVR then
        --[[
            匹配
            依赖LS播放完成，再进行ReqConnectDServer
        ]]
        self.MatchModel:DispatchType(MatchModel.ON_GAMEMATCH_DSMETA_SYNC, InData)
    elseif InData.DsMetaSrc == Pb_Enum_DS_META_SRC.CUSTOM_ROOM_SVR then
        --自建房
        self:ReqConnectDServer(InData)
    else
        CError("MatchCtrl:OnDsMetaSync InData.DsMetaSrc not support:" .. InData.DsMetaSrc,true)
    end
end

---缓存加载ds资源完成发给服务器的数据及结构信息
function MatchCtrl:OnSceneLdCpltdQuerySync(InDSInfoData)
    self.MatchModel:SetReqDSInfoData(InDSInfoData)
end

--[[
    Msg = {
        GameId = 1,     -- GameId
        Reason = 2,     -- 退出原因
    }
--]]
---玩家退出ds通知，主要防止卡流程
function MatchCtrl:PlayerLogoutDs(Msg)
    CWaring("[cw][debug] MatchCtrl:PlayerLogoutDs(" .. string.format("%s, %s", tostring(Msg.GameId), tostring(Msg.Reason)) .. ")")
    --TODO 手动停止Loading界面
    UE.UAsyncLoadingScreenLibrary.StopLoadingScreen();
    if self:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        CWaring("[cw][debug] MatchCtrl:PlayerLogoutDs==========1")
        UIMessageBox.Show({
            describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_Thecurrentgamehasend")),
            rightBtnInfo = {
                callback = function() MvcEntry:GetCtrl(CommonCtrl):ExitBattle(Msg.Reason) end,
            },
            HideCloseBtn = true,
            HideCloseTip = true,
        })
    else
        CWaring("[cw][debug] MatchCtrl:PlayerLogoutDs==========2")
        UIMessageBox.Show({
            describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_Thecurrentgamehasend")),
            rightBtnInfo = {
                callback = function() 
                end,
            },
            HideCloseBtn = true,
            HideCloseTip = true,
        })
    end
end

---玩家放弃重连进上一局游戏
function MatchCtrl:GiveupReconnectDsRsp(Msg)
    CWaring("[cw] MatchCtrl:GiveupReconnectDsRsp(" .. string.format("%s", Msg) .. ")")
    print_r(Msg, "[cw] ====Msg",true)
end

--[[
    // 对局异常通知，主要包括启动ds后的异常通知下发，如Ds加载超时，崩溃等
    message GameExceptionSync
    {
        string GameId = 1;                      // GameId
        DS_META_SRC Source = 2;          // 异常来源
        int32 ErrorCode = 3;                    // 为0 则表示未出现错误, 非0对应的错误码在ErrorCode配置表
    }
]]
function MatchCtrl:GameExceptionSync(Msg)
    print_r(Msg,"MatchCtrl:GameExceptionSync",true)
    if Msg.Source == Pb_Enum_DS_META_SRC.MATCH_SVR then
        self:OnMatchResultFailed()
    elseif Msg.Source == Pb_Enum_DS_META_SRC.CUSTOM_ROOM_SVR then
        self:GetModel(CustomRoomModel):DispatchType(CustomRoomModel.ON_ROOM_WATI_ENTING_BATTLE_BREAK)
    else
        CError("MatchCtrl:GameExceptionSync Source Invalid:" .. Msg.Source )
    end
    if Msg.ErrorCode ~= 0 then
        --TODO 进行提示
        self:GetSingleton(ErrorCtrl):PopErrorSync(Msg.ErrorCode)
    end
end

--endregion
---=========== 请求匹配 ===========---
--region
--[[
    local Msg = {
        DsGroupId       = 1,            -- 服务器id
        PlayerId        = 1,            -- 玩家PlayerId，必填
        GameplayId      = 1000001,      -- 玩法Id
        LevelId         = 101101,       -- 关卡Id
        View            = 1/3,          -- 视角类型
        TeamType        = 1/2/4         -- 队伍类型
        IsCrossPlatform = true,         -- 是否跨平台匹配
        NeedFill        = true,         -- 是否需要补人，即填充队伍（当队伍数量不满时会补充路人）
        IsTeamMatch     = true,         -- 是否为组队匹配，组队匹配会直接发往组队服 
    }
--]]
---发送匹配请求，这里不会判断是否满足条件，如果需要判断队友是否准备好，请使用TeamModel中的函数进行判断
---@param ReqData table 参考上方格式，缺省的话会使用玩家当前的状态作为数据
function MatchCtrl:SendMatchReq(ReqData)
    --非匹配闲置状态，不允许匹配
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    if not MatchModel:IsMatchIdle() then
        CError("[cw] Tring to match while not in MatchIdle state, CurState is " .. tostring(MatchModel:Debug_GetMatchStateString()) .. "", true)
        return
    end
    
    --判空保护
    ReqData = ReqData or {}

    --1.判断当前队伍人数是否等于小于已选择的模式
    local TeamType = ReqData.TeamType or MatchModel:GetTeamType()
    local MaxTeamPlayerNum = TeamType or 0
    
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local CurTeamPlaterNum = TeamModel:GetMyTeamMemberCount()
    if CurTeamPlaterNum > MaxTeamPlayerNum then
        CLog("[cw] Current selected team type is " .. tostring(TeamType) .. " which MaxTeamPlayerNum is " .. tostring(MaxTeamPlayerNum) .. ", but current TeamPlayerNum is " .. tostring(CurTeamPlaterNum) .. "")
        UIMessageBox.Show({describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_gametips"), MaxTeamPlayerNum, CurTeamPlaterNum)})
        return
    end
    
    --2.整理数据发送协议
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = ReqData.PlayerId or UserModel:GetPlayerId()
    local IsInTeam = TeamModel:IsInTeam(PlayerId)    
    local IsNeedFill = ReqData.NeedFill
    if IsNeedFill == nil then IsNeedFill = MatchModel:GetIsFillTeam() end
    local IsCrossPlatform = ReqData.IsCrossPlatform
    if IsCrossPlatform == nil then IsCrossPlatform = MatchModel:GetIsCrossPlatformMatch() end
                             
    local Msg = {
        DsGroupId   = ReqData.DsGroupId or MatchModel:GetSeverId(),                     -- 服务器id
        MatchModeId = -1,                                                               -- 匹配模式id，后续赋值（服务器用于匹配策略）
        PlayerId    = PlayerId,                                                         -- 玩家PlayerId
        GameplayId  = ReqData.GameplayId or MatchModel:GetPlayModeId(),                 -- 玩法Id
        LevelId     = ReqData.LevelId or MatchModel:GetLevelId(),                       -- 关卡Id
        View        = ReqData.Perspective or MatchModel:GetPerspective(),               -- 视角类型 (1, 3)
        TeamType    = TeamType,                                                         -- 队伍类型 (1, 2, 4) 
        NeedFill    = IsNeedFill,                                                       -- 是否需要补人，即填充队伍（当队伍数量不满时会补充路人）
        IsTeamMatch = ReqData.IsTeamMatch ~= nil and ReqData.IsTeamMatch or IsInTeam,   -- 是否为组队匹配，组队匹配会直接发往组队服
        IsCrossPlatform = IsCrossPlatform,                                              -- 是否需要跨平台匹配
        PlayModeId = -1,                                                                -- 玩法模式ID，后续赋值（服务器用于区分匹配模式 存储类型）
    }
    
    --万一到这里还不能取到最低延迟的服务器，则使用第一个服务器id，并设置一下
    if not Msg.DsGroupId then
        ---@type MatchSeverModel
        local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
        local _, severCfg = next(MatchSeverModel:GetDataList())
        if severCfg then
            Msg.DsGroupId = severCfg.DsGroupId
            MatchModel:SetSeverId(Msg.DsGroupId)   
        end
    end
    Msg.MatchModeId = MatchModel:GetStrategyId(Msg.DsGroupId, Msg.GameplayId, Msg.LevelId, Msg.TeamType, Msg.View)
    Msg.PlayModeId = MatchModel:GetGamePlayModeId(Msg.GameplayId, Msg.TeamType, Msg.View)
    --检查通过
    -- print_r(Msg, "[cw] MatchCtrl Trying to Match")
    self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchRequesting)
    MvcEntry:SendProto(Pb_Message.MatchReq, Msg, Pb_Message.MatchRsp)

    CWaring("[KeyStep-->Client][0] MatchCtrl:SendMatchReq")
    UE.UGFUnluaHelper.OnClientHitKeyStep("0")

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.MatchReq, nil, Pb_Message.MatchRsp, true, false)
end

---这里是请求匹配回包，代表玩家进入了匹配队列，并不是说明玩家匹配成功了。
---需要查看玩家是否匹配成功了，请查看 MainCtrl.OnMatchResultSync
function MatchCtrl:OnMatchRsp(InData)
    print_r(InData, "[cw] OnMatchRsp InData")
    --1.匹配失败
    if not InData or not InData.Result then
        --1.1.修改状态为匹配失败
        self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchFail)

        --1.2.下一帧再把状态调整为Idle
        self:InsertTimer(-1, function()
            self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchIdle)
        end)
        if InData and InData.Msg then
            UIAlert.Show(InData.Msg) 
        end
        return
    end    
    
    --2.匹配成功
    --2.1.修改状态为匹配中
    self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.Matching)
   
    --2.2.队员需要切回到大厅
    --提示队员房主已经开始游戏
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsTeamMember = TeamModel:IsSelfTeamNotCaptain()
    if IsTeamMember then
        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_Captainhasstartedthe")))
    end
end

function MatchCtrl:OnMatchDsBaseInfoSync(InData)
    if InData == nil then
        return
    end
    
    CLog("====MatchCtrl:OnMatchDsBaseInfoSync====")
    CLog("InData.GameId: " .. tostring(InData.GameId))
    print_r(InData.DsIniInfo, "====InData.DsIniInfo")

    self:GetModel(UserModel):SetDSGameId(InData.GameId)
    self:GetModel(UserModel):SetDSVersion(InData.DsIniInfo.Branch or "--",InData.DsIniInfo.Changelist or "--")
    
    UE.UGFUnluaHelper.SetDSGameId(InData.GameId)
end
--endregion
---=========== 匹配队列 ===========---
--region
--[[
    InData = {
        Result = true;                  // 匹配成功与否，true-成功，false-失败
        Msg = "stringMsg";              // 匹配失败信息，成功时不需要查看该参数
        MatchParam = {                  // 匹配关键参数
            TeamSize        = 1,
            TeamId          = 2,
            BucketHeadIndex = 3,
            ModeGroupId     = 4,
            RatingType      = 5,
            GameId          = 6,
            PlayerIds       = {1,2,3}
        }
    }
--]]
---请求结果回复
---@param InData table
function MatchCtrl:OnMatchResultSync(InData)
    if InData then
        print_r(InData, "[cw] OnMatchResultSync ====InData")
        --1.匹配成功
        if InData.Result then
            -- 新手引导相关 匹配成功就触发关闭界面
            MvcEntry:GetModel(GuideModel):DispatchType(GuideModel.GUIDE_SET_NEXT_STEP, GuideModel.Enum_GuideStep.StartGame)
    
            -- 匹配成功，需要让大厅强行切回TabPlay页签。且需等待切换完成，才可派发匹配成功事件。触发后续表现
            self.WaitingSceneSwitch = true
            local Param = {
                TabKey = CommonConst.HL_PLAY,
                IsForceSelect = true
            }
            MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.HALL_TAB_SWITCH_AFTER_CLOSE_POPS,Param)
            -- self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchSuccess)
        --2.匹配失败
        else
            if InData.Msg then
                UIAlert.Show(InData.Msg) 
            end
            self:OnMatchResultFailed()
        end 
    else
        CError("MatchCtrl:OnMatchResultSync InData is nil")
    end
end

function MatchCtrl:OnMatchResultFailed()
    --匹配成功后，还是有可能失败，因为拉不起DS等原因，需要从匹配状态Break出来
    if self.MatchModel:IsMatchSuccessed() then            
        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchCtrl_Matchingfailedreturn")), 1)
        --1.1.修改状态为匹配失败
        self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchFail)
        --1.2.再把状态调整为Idle
        self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchIdle)
        self.MatchModel:DispatchType(MatchModel.ON_DS_ERROR)
    --还没有匹配成功时，直接转换状态即可
    else
        --1.1.修改状态为匹配失败
        self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchFail)

        --1.2.再把状态调整为Idle
        self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchIdle)
    end
end

--[[
    匹配成功后，需要将场景切回大厅，切换完成后，才将匹配成功事件抛出，进行展示效果播放
]]
function MatchCtrl:ON_HALL_TAB_SWITCH_COMPLETED_func(CurTabKey)
    if self.WaitingSceneSwitch and CurTabKey and CurTabKey == CommonConst.HL_PLAY then
        self.MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchSuccess)
        self.WaitingSceneSwitch = false
    end
end

--------------
--- 取消匹配 ---
--------------

---发送协议请求取消匹配
function MatchCtrl:SendMatchCancelReq()
    local ReqData = {}
    self:SendProto(Pb_Message.MatchCancelReq, ReqData, Pb_Message.MatchCancelRsp)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.MatchCancelReq, nil, Pb_Message.MatchCancelRsp, true, false)
end

--[[
    请求获取可能存在的匹配/对局信息请求
]]
function MatchCtrl:SendProto_MatchAndDsStateReq()
    local Msg = {}
    self:SendProto(Pb_Message.MatchAndDsStateReq, Msg,nil,true)
end

--[[
    InData = {
        Result = true,
        Msg = "StringMsg"    
    }
--]]
---请求取消匹配回复
---@param InData table
function MatchCtrl:OnMatchCancelRsp(InData)
    local function _InnerCancel()
        --首先先转变状态为取消了
        self.MatchModel:SetMatchState(self.MatchModel.Enum_MatchState.MatchCanceled, InData)
        
        --下一帧再把状态调整为Idle
        self:InsertTimer(Timer.NEXT_FRAME, function()
            self.MatchModel:SetMatchState(self.MatchModel.Enum_MatchState.MatchIdle)
        end)
    end
        
    if not InData or not InData.Result then
        --不在匹配队列中了，这种情况需要改变回未匹配状态
        if InData and InData.Msg and InData.Msg == "not-found-team" then
            _InnerCancel()
        else
            --do something here
        end
        return 
    end

    _InnerCancel()
end
--endregion