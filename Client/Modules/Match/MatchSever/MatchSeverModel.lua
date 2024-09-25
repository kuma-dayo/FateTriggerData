---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 匹配服务器信息，获取服务器名字、地区及延迟
--- Created At: 2023/07/26 15:40
--- Created By: 朝文
---
local super = ListModel
local class_name = "MatchSeverModel"
---@class MatchSeverModel : ListModel
MatchSeverModel = BaseClass(super, class_name)
MatchSeverModel.Const = {
    MaxGreenDelay = 49,
    MaxYellowDelay = 200,

    MaxDisplayDelay = 999,
    DefaultUpdatePingDelay = 3, -- 本地展示的ping值更新间隔，
    DefaultReportPingDelay = 60 -- ping值上报间隔(需要为DefaultUpdatePingDelay的n倍)
}

MatchSeverModel.ON_MATCH_SERVER_INFO_UPDATED = "ON_MATCH_SERVER_INFO_UPDATED"

function MatchSeverModel:KeyOf(vo)
    if vo["DsGroupId"] then
        return vo["DsGroupId"]
    end
    return MatchSeverModel.super.KeyOf(self, vo)
end

function MatchSeverModel:__init()
    self:DataInit()
end

---初始化数据，用于第一次调用及登出的时候调用
function MatchSeverModel:DataInit()
    MatchSeverModel.super.Clean(self)

    PingClient.DelAllNode()
    --读取表格缓存一下默认数据
    self.Const.MaxYellowDelay = self:GetParameterConfig_PingUpperLimit()
    self._SeverPingUrlMap = {}
    self:CleanLastReportSeverPingTime()
end

function MatchSeverModel:OnLogin(data)
    ---@type MatchSeverCtrl
    local MatchSeverCtrl = MvcEntry:GetCtrl(MatchSeverCtrl)
    MatchSeverCtrl:SendPullDsGroupsReq()
end

---玩家登出时调用
function MatchSeverModel:OnLogout(data)
    self:DataInit()
end

--region LastReportSeverPingTime

---封装一个设置 LastReportSeverPingTime 的方法, 用于设置 上一次上报ping值的时间
function MatchSeverModel:UpdateLastReportSeverPingTime()
    self.LastReportSeverPingTime = GetLocalTimestamp()
end

---封装一个获取 LastReportSeverPingTime 的方法，用于获取 上一次上报ping值的时间
---@return number
function MatchSeverModel:GetLastReportSeverPingTime()
    return self.LastReportSeverPingTime or 0
end

---封装一个清空 LastReportSeverPingTime 的方法，用于去除 上一次上报ping值的时间
function MatchSeverModel:CleanLastReportSeverPingTime()
    self.LastReportSeverPingTime = nil
end

--endregion LastReportSeverPingTime

---通过 DsGroupId 获取对应服务器的ping
---@param DsGroupId number 服务器id
---@param Callback function 异步获取ping值之后的回调
function MatchSeverModel:GetPingOf_DsGroupId(DsGroupId, Callback)
    local sever = self:GetData(DsGroupId).PingSvrUrl
    self:GetPingOf(sever, Callback)
end

---通过ip地址或者网址获取对应服务器的ping
---@param Callback function 异步获取ping值之后的回调
function MatchSeverModel:GetPingOf(Sever, Callback)
    local SeverUrl = self._SeverPingUrlMap[Sever]
    if not SeverUrl then
        self._SeverPingUrlMap[Sever] = Sever
        PingClient.AddNode(Sever)

        SeverUrl = self._SeverPingUrlMap[Sever]
    end

    if not SeverUrl or SeverUrl == "" then return end
    local delay = PingClient.GetLastDelay(SeverUrl)
    if delay < 0 then
        CWaring("SeverUrl Ping < 0:" .. SeverUrl .. "|PingValue:" .. delay)
    end
    Callback(delay)
end


--[[
复制下方代码，粘贴在UE ~ 调出的cmd中，进行调用debug
lua.do local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel); MatchSeverModel:Debug_PrintSeverList();
--]]
function MatchSeverModel:Debug_PrintSeverList()
    local Data = self:GetDataList()
    print_r(Data, "[cw] ====Data")
end

---遍历所有的服务器，找到延迟最低的那个作为默认的服务器(如果已经有选择了的服务器了，则不为玩家选择)
function MatchSeverModel:ChooseLowestPingSeverAsSelectSever()
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    if MatchModel:GetSeverId() then
        return
    end

    local MinPingDs = self:GetLowestPingSever()
    if MinPingDs == nil then
        CWaring("[cw] not found lowest ping sever")
        return
    end
    MatchModel:SetSeverId(MinPingDs.DsGroupId)
    CLog("[cw] Lowest ping is " .. tostring(MinPingDs.Ping) .. " of " .. tostring(MinPingDs.DsGroupName) .. "(" .. tostring(MinPingDs.DsGroupId) ..
             ")")
end

---遍历所有的服务器，找到延迟最低的
function MatchSeverModel:GetLowestPingSever()
    local Data = self:GetDataList()
    print_r(Data, "MatchSeverModel:ChooseLowestPingSeverAsSelectSever DataList = ")
    local MinPingDs = nil
    for k, v in pairs(Data) do
        if not MinPingDs or MinPingDs.Ping < 0 or (v.Ping >= 0 and  v.Ping < MinPingDs.Ping) then
            MinPingDs = v
        end
    end
    return MinPingDs
end

function MatchSeverModel:GetDsGroupDetailByDsGroupId(DsGroupId)
    return self:GetData(DsGroupId)
end

--[[
    获取指定DS的 Ping值
    如果<0，会优化显示为999
]]
function MatchSeverModel:GetDsPingByDsGroupId(DsGroupId)
    local DsGroupInfo = self:GetData(DsGroupId)
    local PingValueShow = DsGroupInfo and DsGroupInfo.Ping
    if PingValueShow and PingValueShow < 0 then
        CWaring("GetDsPingByDsGroupId Ping < 0 the DsGroupId Is:" .. DsGroupId)
        PingValueShow = 9999
    elseif not PingValueShow then
        CWaring("GetDsPingByDsGroupId Ping not found the DsGroupId Is:" .. DsGroupId)
        PingValueShow = 9999
    end
    return PingValueShow or "-1"
end

---@return number 获取配置的红色ping显示上限值 大于此值即显示红色
function MatchSeverModel:GetParameterConfig_PingUpperLimit()
    local pingUpperLimit = CommonUtil.GetParameterConfig(ParameterConfig.PingUpperLimit, 200)
    return pingUpperLimit
end

--- 获取战斗集群表
---@param DsGroupId any
function MatchSeverModel:GetDsGroupsConfig(DsGroupId)
    if not DsGroupId then CError(debug.traceback()) return end
    local DsGroupsConfig = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_DsGroupsConfig, DsGroupId)
    return DsGroupsConfig
end

-- 获取服务器名称 
function MatchSeverModel:GetDsGroupName(DsGroupId)
    local DsGroupName = ""
    local DsGroupsConfig = self:GetDsGroupsConfig(DsGroupId)
    if DsGroupsConfig then
        DsGroupName = DsGroupsConfig[Cfg_ModeSelect_DsGroupsConfig_P.DsGroupName]
    end
    return DsGroupName
end

-- 获取区域名称 
function MatchSeverModel:GetRegionName(DsGroupId)
    local RegionName = ""
    local DsGroupsConfig = self:GetDsGroupsConfig(DsGroupId)
    if DsGroupsConfig then
        RegionName = DsGroupsConfig[Cfg_ModeSelect_DsGroupsConfig_P.Region]
    end
    return RegionName
end

-- 获取国家地区名称 
function MatchSeverModel:GetAreaName(DsGroupId)
    local AreaName = ""
    local DsGroupsConfig = self:GetDsGroupsConfig(DsGroupId)
    if DsGroupsConfig then
        AreaName = DsGroupsConfig[Cfg_ModeSelect_DsGroupsConfig_P.Area]
    end
    return AreaName
end

return MatchSeverModel
