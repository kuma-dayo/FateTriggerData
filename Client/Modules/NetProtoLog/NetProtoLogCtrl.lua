require("Client.Modules.NetProtoLog.NetProtoLogModel")
--[[
    协议log处理模块
]]
local class_name = "NetProtoLogCtrl"
---@class NetProtoLogCtrl : UserGameController
NetProtoLogCtrl = NetProtoLogCtrl or BaseClass(UserGameController,class_name)


function NetProtoLogCtrl:__init()
    CWaring("==NetProtoLogCtrl init")
    self.Model = nil
    self:InitRepeatRecvNetMsg()
end

function NetProtoLogCtrl:Initialize()
    ---@type NetProtoLogModel
    self.Model = self:GetModel(NetProtoLogModel)
end

--[[
    玩家登入
]]
function NetProtoLogCtrl:OnLogin(data)
    CWaring("NetProtoLogCtrl OnLogin")
end

--[[
    玩家登出
]]
function NetProtoLogCtrl:OnLogout(data)

end

-- 需要重复打印的协议直接初始化的时候赋值一次就行
function NetProtoLogCtrl:InitRepeatRecvNetMsg()
    self.RecvNetMsgIdList = {}
    -- 匹配相关
    self.RecvNetMsgIdList[Pb_Message.MatchRsp] = {IsRepeatPrint = true, IsPrintRecvData = false}
    self.RecvNetMsgIdList[Pb_Message.MatchCancelRsp] = {IsRepeatPrint = true, IsPrintRecvData = false}

    -- 聊天相关
    self.RecvNetMsgIdList[Pb_Message.ChatSync] = {IsRepeatPrint = true, IsPrintRecvData = false}
    self.RecvNetMsgIdList[Pb_Message.ChatTipsSync] = {IsRepeatPrint = true, IsPrintRecvData = false}

    --组队相关
    self.RecvNetMsgIdList[Pb_Message.TeamInviteSync] = {IsRepeatPrint = true, IsPrintRecvData = false}
    self.RecvNetMsgIdList[Pb_Message.TeamApplySync] = {IsRepeatPrint = true, IsPrintRecvData = false}
    self.RecvNetMsgIdList[Pb_Message.TeamMergeSync] = {IsRepeatPrint = true, IsPrintRecvData = false}

    -- 检测协议回包耗时列表 key为RecvNetMsgId 
    self.CheckRecvNetMsgCostTimeList = {}

end

function NetProtoLogCtrl:AddMsgListenersUser()

end

-- GM设置协议打印状态
function NetProtoLogCtrl:SetGMOpenNetProtoLogState(GMOpenNetProtoLogState)
    self.Model:SetGMOpenNetProtoLogState(GMOpenNetProtoLogState)
end


-- 添加协议请求打印
---@param SendNetMsgId string 发送的协议号
---@param SendExtraTipMsg any 请求需要展示的提示数据
---@param RecvNetMsgId string 期待返回的协议号
---@param IsRepeatPrint boolean 协议回包是否重复打印  false的情况打印一次后会移除
---@param IsPrintRecvData boolean 是否打印返回的协议数据
function NetProtoLogCtrl:AddSendNetProtoLog(SendNetMsgId, SendExtraTipMsg, RecvNetMsgId, IsRepeatPrint, IsPrintRecvData)
    local IsOpenNetProtoLog = self.Model:CheckIsOpenNetProtoLog()
    if not IsOpenNetProtoLog then return end
    if SendNetMsgId then
        -- 打印协议请求相关log
        self:PrintNetProtoLog(SendNetMsgId, SendExtraTipMsg)
        self:AddRecvNetProtoLog(RecvNetMsgId, IsRepeatPrint, IsPrintRecvData)
        self:AddCheckRecvNetMsgCostTime(SendNetMsgId, RecvNetMsgId)
    else
        CError("NetProtoLogCtrl:AddSendNetProtoLog SendNetMsgId Is Nil")
    end 
end

-- 增加单条协议回包耗时检测
---@param SendNetMsgId string 发送的协议号
---@param RecvNetMsgId string 期待返回的协议号
function NetProtoLogCtrl:AddCheckRecvNetMsgCostTime(SendNetMsgId, RecvNetMsgId)
    if SendNetMsgId and RecvNetMsgId then
        self.CheckRecvNetMsgCostTimeList[RecvNetMsgId] = {
            SendNetMsgId = SendNetMsgId,
            SendMilliseconds = GetLocalTimestampMillisecondsUtc()
        }
    end
end

-- 添加协议回包打印
---@param RecvNetMsgId string 期待返回的协议号
---@param IsRepeatPrint boolean 协议回包是否重复打印  false的情况打印一次后会移除
---@param IsPrintRecvData boolean 是否打印返回的协议数据
function NetProtoLogCtrl:AddRecvNetProtoLog(RecvNetMsgId, IsRepeatPrint, IsPrintRecvData)
    local IsOpenNetProtoLog = self.Model:CheckIsOpenNetProtoLog()
    if not IsOpenNetProtoLog then return end
    if RecvNetMsgId then
        self.RecvNetMsgIdList[RecvNetMsgId] = {
            IsRepeatPrint = IsRepeatPrint,
            IsPrintRecvData = IsPrintRecvData,
        }
    end
end

--[[
    协议返回 会主动调用这个接口 
]]
function NetProtoLogCtrl:CheckRecvMsgId(MsgId, MsgData)
    local IsOpenNetProtoLog = self.Model:CheckIsOpenNetProtoLog()
    if not IsOpenNetProtoLog then return end

    if self.RecvNetMsgIdList[MsgId] then
        local RecvNetMsgValue = self.RecvNetMsgIdList[MsgId]
        local ExtraTipMsg = RecvNetMsgValue.IsPrintRecvData and MsgData or nil
        self:PrintNetProtoLog(MsgId, ExtraTipMsg)
        -- 只打印一次的直接就删除
        if not RecvNetMsgValue.IsRepeatPrint then
            self.RecvNetMsgIdList[MsgId] = nil 
        end
    end
    
    -- 打印单条协议回包耗时
    if self.CheckRecvNetMsgCostTimeList[MsgId] then
        local RecvMilliseconds = GetLocalTimestampMillisecondsUtc()
        local SendNetMsgId = self.CheckRecvNetMsgCostTimeList[MsgId].SendNetMsgId
        local CostTime = RecvMilliseconds - self.CheckRecvNetMsgCostTimeList[MsgId].SendMilliseconds
        self:PrintLog("NetProtoLogCtrl:PrintNetProtoLog Print Send And Recv CostTime SendNetMsgId = " .. SendNetMsgId .. " RecvNetMsgId = " .. MsgId .. " CostTime = ".. CostTime .. "ms")
        self.CheckRecvNetMsgCostTimeList[MsgId] = nil
    end
end

-- 打印协议相关log 用于大厅延迟测试
---@param NetMsgId string 协议号
---@param ExtraTipMsg any 额外需要展示的提示数据
function NetProtoLogCtrl:PrintNetProtoLog(NetMsgId,ExtraTipMsg)
    local IsOpenNetProtoLog = self.Model:CheckIsOpenNetProtoLog()
    if not IsOpenNetProtoLog then return end
    if NetMsgId then
        -- 本地毫秒数据
        local TimestampMilliseconds = GetLocalTimestampMillisecondsUtc()
        -- 获取毫秒部分的数据
        local Milliseconds = string.sub(tostring(TimestampMilliseconds), -3)
        local CurTime = TimeUtils.GetDateTimeStrFromTimeStamp(math.floor(TimestampMilliseconds/1000), "%04d.%02d.%02d %02d.%02d.%02d")
        self:PrintLog("NetProtoLogCtrl:PrintNetProtoLog NetMsgId = " .. NetMsgId .. " CurTime = " .. CurTime .. ":" .. Milliseconds .. " TimestampMilliseconds = " .. TimestampMilliseconds)
        local ExtraTipMsgText = "NetProtoLogCtrl:PrintNetProtoLog ExtraTipMsg = "
        if ExtraTipMsg then
            if type(ExtraTipMsg) == "table" then
                print_r(ExtraTipMsg, ExtraTipMsgText, true)
            elseif type(ExtraTipMsg) == "number" then
                self:PrintLog(ExtraTipMsgText .. tostring(ExtraTipMsg))
            elseif type(ExtraTipMsg) == "string" then
                self:PrintLog(ExtraTipMsgText .. ExtraTipMsg)
            end  
        end
    else
        CError("NetProtoLogCtrl:PrintNetProtoLog NetMsgId Is Nil")
    end
end

-- 打印协议相关log shipping包的情况使用CWaring打印
---@param NetMsgId string 协议号
---@param ExtraTipMsg any 额外需要展示的提示数据
function NetProtoLogCtrl:PrintLog(Log)
    if CommonUtil.IsShipping() then
        if CWaring then
            CWaring(Log)
        else
            print(Log)
        end
    else
        print(Log)
    end
end


