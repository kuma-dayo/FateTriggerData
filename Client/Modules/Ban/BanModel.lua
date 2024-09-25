--[[
    封禁状态 数据模型
]]

local super = GameEventDispatcher;
local class_name = "BanModel";

---@class BanModel : GameEventDispatcher
---@field private super GameEventDispatcher
BanModel = BaseClass(super, class_name)

-- 封禁状态变化
BanModel.ON_BAN_STATE_CHANGED = "ON_BAN_STATE_CHANGED"

function BanModel:__init()
    self:_dataInit()
end

function BanModel:_dataInit()
    self.BanInfoList = {}
    self.BanTimerList = {}
end

function BanModel:OnLogin(data)

end

function BanModel:OnLogout(data)
    BanModel.super.OnLogout(self)
    self:CleanAllBanTimer()
    self:_dataInit()
end

-------- 对外接口 -----------

-- 获取是否封禁中
function BanModel:IsBanningForType(BanType)
    if not (self.BanInfoList and self.BanInfoList[BanType]) then
        return false
    end
    local BanData = self.BanInfoList[BanType]
    return GetTimestamp() < BanData.BanTime
end

function BanModel:GetBanTimeForType(BanType)
    if not (self.BanInfoList and self.BanInfoList[BanType]) then
        return 0
    end
    return self.BanInfoList[BanType].BanTime
end

-- 获取封禁提示语
function BanModel:GetBanTipsForType(BanType)
    if not (self.BanInfoList and self.BanInfoList[BanType]) then
        return nil
    end
    local BanData = self.BanInfoList[BanType]
    if GetTimestamp() >= BanData.BanTime then
        return nil
    end

    local TipsId = nil
    if BanType == Pb_Enum_BAN_TYPE.BAN_VOICE then
        TipsId = TipsCode.VoiceBanTips.ID
    else
        -- todo 其他封禁提示
    end

    if not TipsId then
        CWaring("BanModel:GetBanTipsForType Without TipsId For Type = "..BanType,true)
        return nil
    end
    local TipsCfg = G_ConfigHelper:GetSingleItemById(Cfg_TipsCode,TipsId)
    if not TipsCfg then
        return nil
    end
    -- 当前账号因{0}被禁止使用语音聊天，将于{1}解除禁止使用语音聊天
    local Tips = TipsCfg[Cfg_TipsCode_P.Des]
    local BanReasonStr = ""
    if BanData.BanReasonTextId and BanData.BanReasonTextId ~= 0 then
        local ReasonCfg = G_ConfigHelper:GetSingleItemById(Cfg_MiscTextConfig,BanData.BanReasonTextId)
        if ReasonCfg then
            BanReasonStr = ReasonCfg[Cfg_MiscTextConfig_P.Des]
        end
    elseif BanData.BanReason then
        BanReasonStr = BanData.BanReason
    end
    local TimeStr = TimeUtils.GetDateTimeStrFromTimeStamp(BanData.BanTime)

    Tips = StringUtil.Format(Tips,BanReasonStr, TimeStr)
    return Tips

end

-------- 协议数据处理接口 -----------

--[[
	Msg = {
	    repeated BanData BanList    = 1;    // 禁止列表
	}
    // 禁止数据同步
    // 玩家登录时主动推送，数据变化时，服务器主动同步
    // 如果玩家没有禁止的话，两个参数为nil，客户端需要注意判断

    message BanData{
        BAN_TYPE    BanType         = 1;    // 禁止类型
        int64       BanTime         = 2;    // 禁止的截止时间戳，UTC0, BnaTima为空或者小于当前时间说明解除禁止了
        string      BanReason       = 3;    // 禁止原因
        int64       BanReasonTextId = 4;    // 禁止原因的文本Id,优先用该字段，没有的时候用2禁止原因字段
    }
]]
function BanModel:On_BanDataSync(Msg)
    self.BanInfoList = self.BanInfoList or {}
    local CurTime = GetTimestamp()
    for _,BanData in ipairs(Msg.BanList) do
        local BanType = BanData.BanType
        self.BanInfoList[BanType] = BanData
        local LeftTime = BanData.BanTime - CurTime
        local Param = {
            BanType = BanType,
            IsBan = LeftTime > 0
        }
        self:DispatchType(BanModel.ON_BAN_STATE_CHANGED,Param)
        self:CleanBanTimer(BanType)
        if LeftTime > 0 then
            self:AddBanTimer(BanType,LeftTime)
        end
    end
end

function BanModel:AddBanTimer(BanType,LeftTime)
    self.BanTimerList = self.BanTimerList or {}
    self:CleanBanTimer(BanType)
    self.BanTimerList[BanType] = Timer.InsertTimer(LeftTime,function ()
        self:CleanBanTimer(BanType)
        local Msg = {
            BanType = BanType,
            IsBan = false
        }
        self:DispatchType(BanModel.ON_BAN_STATE_CHANGED,Msg)
    end)
end

function BanModel:CleanBanTimer(BanType)
    self.BanTimerList = self.BanTimerList or {}
    if self.BanTimerList[BanType] then
        Timer.RemoveTimer(self.BanTimerList[BanType])
        self.BanTimerList[BanType] = nil
    end
end

function BanModel:CleanAllBanTimer()
    self.BanTimerList = self.BanTimerList or {}
    for BanType,BanTimer in pairs(self.BanTimerList) do
        Timer.RemoveTimer(BanTimer)
        self.BanTimerList[BanType] = nil
    end
    self.BanTimerList = {}
end

