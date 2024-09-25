---
--- Ctrl 模块，主要用于处理协议
--- Description: 匹配服务器
--- Created At: 2023/08/01 17:10
--- Created By: 朝文
---

require("Client.Modules.Match.MatchSever.MatchSeverModel")


local class_name = "MatchSeverCtrl"
---@class MatchSeverCtrl : UserGameController
---@field private model MatchSeverModel
MatchSeverCtrl = MatchSeverCtrl or BaseClass(UserGameController, class_name)

function MatchSeverCtrl:__init()
    CWaring("[cw] MatchSeverCtrl init")
    self.Model = nil
end

function MatchSeverCtrl:Initialize()
    self.Model = self:GetModel(MatchSeverModel)
end

function MatchSeverCtrl:AddMsgListenersUser()
    self.MsgList = {
        {Model = ViewModel, MsgName = ViewConst.VirtualHall,	Func = self.ON_HALL_STATE_CHANGE_func },
        {Model = MatchModel, MsgName = MatchModel.ON_BATTLE_SEVER_CHANGED,	Func = self.ON_BATTLE_SEVER_CHANGED_func }
    }
    
    --添加协议回包监听事件
    self.ProtoList = {
        { MsgName = Pb_Message.PullDsGroupsRsp,             Func = self.OnPullDsGroupsRsp },
        { MsgName = Pb_Message.ReportDsGroupPingRsp,        Func = self.OnReportDsGroupPingRsp },
        { MsgName = Pb_Message.ReportDsGroupIdRsp,          Func = self.OnReportDsGroupIdRsp },
    }
end

function MatchSeverCtrl:OnLogout(data)
    self:StopAutoMatchSeverPing()
end

function MatchSeverCtrl:OnAfterBackToHall()
    CLog("[cw] MatchSeverCtrl:OnAfterBackToHall()")
    self:StartAutoMatchSeverPing()
end

function MatchSeverCtrl:OnPreEnterBattle()
    CLog("[cw] MatchSeverCtrl:OnPreEnterBattle()")
    --停止自动上报
    self:StopAutoMatchSeverPing()
end

---更新ping值
local function _UpdateLocalPing(Callback)
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    local Data = MatchSeverModel:GetDataList()
    
    local i = 0
    local len = MatchSeverModel:GetLength()
    local function _callback()
        i = i + 1
        if i == len then
            MatchSeverModel:DispatchType(MatchSeverModel.ON_MATCH_SERVER_INFO_UPDATED)
            if Callback then Callback() end
        end
    end
    
    for _, v in pairs(Data) do
        MatchSeverModel:GetPingOf_DsGroupId(v.DsGroupId,
            function(ping)
                v.Ping = ping
                _callback()
            end)
    end
end

local function _CheckPingDataAvailiable()
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    local Data = MatchSeverModel:GetDataList()
    if not Data or not next(Data) then CLog("[cw] _CheckPingDataAvailiable not Data or not next(Data)") return false end

    for _, v in pairs(Data) do
        if v.Ping == 0 then return false end
    end
    
    return true
end

---上报ping值
---@param self MatchSeverCtrl
---@return boolean 是否上报了（如果所有服务器的ping都是0，则说明还没有取得，不能上报）
local function _ReportPing(self)
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    local Data = MatchSeverModel:GetDataList()
    if not Data or not next(Data) then CLog("[cw] not Data or not next(Data)") return false end
    
    local Pings = {}
    for _, v in pairs(Data) do
        Pings[v.DsGroupId] = v.Ping
    end
    
    --print_r(Pings, "[cw] ====Pings")
    self:SendReportDsGroupPingReq(Pings)
end

---暂停自动上报ping值
function MatchSeverCtrl:StopAutoMatchSeverPing()
    if self.ReportPingTimer then
        CLog("[cw] MatchSeverCtrl:StopAutoMatchSeverPing()")
        PingClient.StopPing()
        self:RemoveTimer(self.ReportPingTimer)
        self.ReportPingTimer = nil
    end
end

---每过一定的时间向服务器报告当前的ping值
function MatchSeverCtrl:StartAutoMatchSeverPing()
    --已经有一个了，就不用继续上报了
    if self.ReportPingTimer then
        CLog("[cw] MatchSeverCtrl already got a ReportPingTimer, do not need to run a new one.")
        return 
    end
    
    --还没有服务器数据，不开启自动上报
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    if MatchSeverModel:GetLength() == 0 then
        CWaring("[cw] MatchSeverCtrl not got DsGroups yet, abandon to run StartAutoMatchSeverPing")
        return
    end
    
    CLog("[cw] MatchSeverCtrl:StartAutoMatchSeverPing()")
    PingClient.StartPing(MatchSeverModel.Const.DefaultUpdatePingDelay)
    local timeDiff = math.abs(MatchSeverModel:GetLastReportSeverPingTime() - GetLocalTimestamp())
    self.ReportPingTimer = self:InsertTimer(
            MatchSeverModel.Const.DefaultUpdatePingDelay,
            function()
                --更新本地ping
                _UpdateLocalPing()

                --如果到达了可发送的时间，且数据可用
                timeDiff = timeDiff + MatchSeverModel.Const.DefaultUpdatePingDelay
                if timeDiff >= MatchSeverModel.Const.DefaultReportPingDelay and _CheckPingDataAvailiable() then
                    --上报一下ping
                    _ReportPing(self)
                    --自动选择延迟最低的服务器
                    MatchSeverModel:ChooseLowestPingSeverAsSelectSever() 
                    --更新Timer参数，开始下一轮tick
                    MatchSeverModel:UpdateLastReportSeverPingTime()
                    timeDiff = 0
                end
            end,
            true)
end

-----------------------------------------请求相关------------------------------

function MatchSeverCtrl:SendPullDsGroupsReq()
    CLog("[cw] MatchSeverCtrl:SendPullDsGroupsReq()")
    self:SendProto(Pb_Message.PullDsGroupsReq, {})
end 

-- 客户端选择战斗服同步请求
function MatchSeverCtrl:SendReportDsGroupIdReq(DsGroupId)
    if DsGroupId then
        CLog("[cw] MatchSeverCtrl:SendReportDsGroupIdReq()  " .. tostring(DsGroupId))
        local Msg = {
            DsGroupId = DsGroupId,
        }
        self:SendProto(Pb_Message.ReportDsGroupIdReq, Msg, Pb_Message.ReportDsGroupIdRsp)
    else
        CError("MatchSeverCtrl:SendReportDsGroupIdReq  DsGroupId is nil")
    end
end 

--[[
Msg = { 
    DsGroups = { 
        [1] = { 
            GameplayIds = { 
                  [1] => 10003 
                  [2] => 10004 
            }, 
            Region = "亚洲", 
            PingSvrUrl = "", 
            DsGroupName = "谷歌香港", 
            DsGroupId = 3, 
            Open = true, 
            Area = "香港", 
            ClientMatchConfigTableKey  = "MatchConfigCN"
        }, 
        [2] = { ... }
} 
--]]
function MatchSeverCtrl:OnPullDsGroupsRsp(Msg)
    print_r(Msg, "[cw] OnPullDsGroupsRsp ====Msg")
    
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    MatchSeverModel:DataInit()
    MatchSeverModel:SetDataList(Msg.DsGroups)

    for _, Sever in ipairs(Msg.DsGroups) do
        table.insert(MatchSeverModel._SeverPingUrlMap, Sever.PingSvrUrl)
        PingClient.AddNode(Sever.PingSvrUrl)
    end
    
    --第一次获取列表时需要更新一下ping和上报一下
    self:StartAutoMatchSeverPing()
end 

function MatchSeverCtrl:SendReportDsGroupPingReq(ping)
    CLog("[cw] MatchSeverCtrl:SendReportDsGroupPingReq()")
    self:SendProto(Pb_Message.ReportDsGroupPingReq, {PingValues = ping})
end 

function MatchSeverCtrl:OnReportDsGroupPingRsp()
    CLog("[cw] MatchSeverCtrl:OnReportDsGroupPingRsp()")
end 

function MatchSeverCtrl:OnReportDsGroupIdRsp()
    CLog("[cw] MatchSeverCtrl:OnReportDsGroupIdRsp()")
end

function MatchSeverCtrl:ON_HALL_STATE_CHANGE_func(State)
    if State then
        --开启自动上报
        self:StartAutoMatchSeverPing()
    end
end

-- 大厅选择的战斗服务器发生了变化  上报给服务器
function MatchSeverCtrl:ON_BATTLE_SEVER_CHANGED_func()
    local SeverId = MvcEntry:GetModel(MatchModel):GetSeverId()
    self:SendReportDsGroupIdReq(SeverId)
end