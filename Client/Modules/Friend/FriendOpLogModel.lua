--[[好友操作日志数据模型]]
local super = GameEventDispatcher;
local class_name = "FriendOpLogModel";

---@class FriendOpLogModel : GameEventDispatcher
---@field private super GameEventDispatcher
---@type FriendOpLogModel
FriendOpLogModel = BaseClass(super, class_name)
FriendOpLogModel.ON_GET_FRIEND_OPLOG = "ON_GET_FRIEND_OPLOG"
function FriendOpLogModel:__init()
    self:_dataInit()
end

function FriendOpLogModel:_dataInit()
    self.LogList = {}
end
--[[
    玩家登出时调用
]]
function FriendOpLogModel:OnLogout(data)
    FriendOpLogModel.super.OnLogout(self)
    self:_dataInit()
end
--[[
    获取操作日志列表
    按时间升序排序
]]
function FriendOpLogModel:GetOpLogList(PlayerId)
    return self.LogList[PlayerId]
end

--[[
    删除单个好友的日志
]]
function FriendOpLogModel:DeleteLog(PlayerId)
    self.LogList[PlayerId] = nil
end
--[[
    清空缓存日志
]]
function FriendOpLogModel:ClearAllOpLogList()
    self.LogList = {}
end

function FriendOpLogModel:SaveOpLogList(Msg)
    self.LogList = self.LogList or {}
    local List = {}
    if #Msg.OpLogList > 0 then
        for _, FriendOpLogNode in ipairs(Msg.OpLogList) do
            local LogData = self:HandleLogData(Msg.TargetPlayerId, FriendOpLogNode)
            if LogData then
                table.insert(List,LogData)
            end
        end
        -- 按时间升序排序
        -- table.sort(List,function (a,b)
        --     return a.OpTime < b.OpTime
        -- end)
    end
    self.LogList[Msg.TargetPlayerId] = List
    self:DispatchType(FriendOpLogModel.ON_GET_FRIEND_OPLOG,Msg.TargetPlayerId)
end

-- 根据不同的日志类型，对日志内容进行拼接
function FriendOpLogModel:HandleLogData(TargetPlayerId,FriendOpLogNode)
    -- 提前进行参数解析
    local Params = string.split(FriendOpLogNode.OpParam,";")
    local CfgParam = FriendOpLogNode.OpParam
    local OpType = FriendOpLogNode.OpType
    if OpType == Pb_Enum_FRIEND_OP_TYPE.FRIEND_OP_TEAM_PLAY_RANK and #Params>=2 then
        -- 好友组队游戏排名 日志的参数需要剔除后面的玩家id部分
        CfgParam = Params[1]..";"..Params[2]
    end
    local Cfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_FriendOpLogCfg,{Cfg_FriendOpLogCfg_P.OpType,Cfg_FriendOpLogCfg_P.OpParam},{FriendOpLogNode.OpType,CfgParam})
    if not Cfg then
        CError(StringUtil.Format("FriendOpLogModel:HandleLogData GetCfg Error for OpType = {0} and OpParam = {1}",FriendOpLogNode.OpType,FriendOpLogNode.OpParam),true)
        return nil
    end 
    
    local LogData = {}
    LogData.OpTime = FriendOpLogNode.OpTime
    local LogTimeStr = TimeUtils.GetDateFromTimeStamp(FriendOpLogNode.OpTime)
    local PlayerName = MvcEntry:GetModel(FriendModel):GetPlayerNameByPlayerId(TargetPlayerId)
    local LogTempStr = Cfg[Cfg_FriendOpLogCfg_P.LogTemp]
    LogData.ShortLogStr = Cfg[Cfg_FriendOpLogCfg_P.ShortLogTemp]
    local LogStr = ""
    if OpType == Pb_Enum_FRIEND_OP_TYPE.FRIEND_OP_ADD_FRIEND then
        -- 添加好友日志 - 需要读取添加途径
        local GameModuleId = tonumber(FriendOpLogNode.OpParam)
        local GameModuleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_GameModuleCfg,Cfg_GameModuleCfg_P.ID,GameModuleId)
        local GameModuleName = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendOpLogModel_Unknownway")
        if GameModuleCfg then
            GameModuleName = GameModuleCfg[Cfg_GameModuleCfg_P.Name]
        else
            CWaring("Cfg_GameModuleCfg Error for id = "..GameModuleId)
        end
        LogStr = StringUtil.Format(LogTempStr,LogTimeStr,PlayerName,GameModuleName)
        LogData.ShortLogStr = StringUtil.Format(LogData.ShortLogStr,GameModuleName)

    elseif OpType == Pb_Enum_FRIEND_OP_TYPE.FRIEND_OP_TEAM_PLAY_RANK then
        -- 好友组队游戏排名日志 - 需要添加模式名称
        local GameModeName = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendOpLogModel_Unknownpattern")
        if Params and #Params > 1 then
            -- 参数为 玩法Id;名词
            local GameModeId = tonumber(Params[1])
            local GameModeCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_ModeSelect_PlayModeEntryCfg,Cfg_ModeSelect_PlayModeEntryCfg_P.PlayModeId,GameModeId)
            if GameModeCfg then
                GameModeName = GameModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.PlayModeName]
            else
                CWaring("Cfg_ModeSelect_PlayModeEntryCfg Error for id = "..GameModeId)
            end
        end
        LogStr = StringUtil.Format(LogTempStr,LogTimeStr,PlayerName,GameModeName) 
    else
        LogStr = StringUtil.Format(LogTempStr,LogTimeStr,PlayerName) 
    end
    LogData.LogStr = LogStr
    return LogData
end

return FriendOpLogModel;
