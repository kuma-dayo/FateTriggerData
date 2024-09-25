local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")

local class_name = "BannerData"
---@class BannerData
local BannerData = BaseClass(nil, class_name)

BannerData.BannerShowTypeNew = "BannerShow_{0}_{1}"

BannerData.BannerId = 0
BannerData.EntryId = 0
BannerData.ShowType = ActivityDefine.BannerShowType.None
BannerData.DismissType = ActivityDefine.BannerDismissType.None
BannerData.StartTime = 0
BannerData.EndTime = 0
BannerData.State = ActivityDefine.BannerShowState.None

---关联的活动id
BannerData.AttachAcId = 0

BannerData.Cfg = nil
BannerData.IsChanged = true

function BannerData:InitFromCfg(Cfg)
    if not Cfg then
        return false
    end
    self.Cfg = Cfg
    self.BannerId = Cfg[Cfg_BannerConfig_P.BannerId]
    self.EntryId = Cfg[Cfg_BannerConfig_P.EntryId]
    self.ShowType = Cfg[Cfg_BannerConfig_P.ShowType]
    self.DismissType = Cfg[Cfg_BannerConfig_P.DismissType]
    self.StartTime = Cfg[Cfg_BannerConfig_P.StartTimeTimestamp]
    self.EndTime = Cfg[Cfg_BannerConfig_P.EndTimeTimestamp]

    if self.EntryId > 0 then
        ---@type EntryData
        local EntryData = MvcEntry:GetModel(ActivityModel):GetEntryData(self.EntryId)
        if EntryData then
            EntryData:AppendBanner(self.BannerId)
        end
    end

    self:CheckFreshState()

    self.IsChanged = false

    return true
end

function BannerData:Recycle()
    CWaring("BannerData:Recycle ID"..self.BannerId)
    self:Reset()
    self.BannerId = 0
    self.EntryId = 0
    self.ShowType = ActivityDefine.BannerShowType.None
    self.DismissType = ActivityDefine.BannerDismissType.None
    self.StartTime = 0
    self.EndTime = 0
    self.AttachAcId = 0
    self.Cfg = nil
    self.IsChanged = true
end

function BannerData:Reset()
    CWaring("BannerData:Reset ID"..self.BannerId)
    self.State = ActivityDefine.BannerShowState.None
end


function BannerData:GetBannerText()
    if not self.Cfg then
        return
    end
    return self.Cfg[Cfg_BannerConfig_P.BannerText]
end

function BannerData:GetBannerImg()
    if not self.Cfg then
        return
    end
    return self.Cfg[Cfg_BannerConfig_P.BannerImg]
end

--- 检测是否可用
function BannerData:IsAvailble()
    self:CheckFreshState()
    return self.State == ActivityDefine.BannerShowState.Showing
end

--- 主动触发banner的展示
---@param AcId number
function BannerData:HandleFreshState()
    if not self:IsAvailble() then
        return
    end
    if self.State == ActivityDefine.BannerShowState.Dismiss then
        return
    end
    if self.DismissType == ActivityDefine.BannerDismissType.Open and self.AttachAcId > 0 then
        SaveGame.SetItem(StringUtil.FormatSimple(BannerData.BannerShowTypeNew,self.AttachAcId, self.BannerId), true)
        self:SetState(ActivityDefine.BannerShowState.Dismiss)
    end
end

function BannerData:SetState(NewState)
    if self.State == NewState then
        self.IsChanged = false
        return
    end
    -- local OldState = self.State
    self.State = NewState
    self.IsChanged = true
    MvcEntry:GetModel(ActivityModel):DispatchType(ActivityModel.ACTIVITY_BANNER_STATE_CHANGE)
end

--- 检测轮播图状态
function BannerData:CheckFreshState()
    local TState = ActivityDefine.BannerShowState.None
    local Timestamp = GetTimestamp()
    if (self.StartTime > 0 and Timestamp < self.StartTime) or (self.EndTime > 0 and Timestamp > self.EndTime) then
        TState = ActivityDefine.BannerShowState.Dismiss
    else
        if self.DismissType == ActivityDefine.BannerDismissType.Permanent then
            TState = ActivityDefine.BannerShowState.Showing
        else
            if self.ShowType == ActivityDefine.BannerShowType.New and self.AttachAcId > 0  then
                local IsBannerShowTypeNew = SaveGame.GetItem(StringUtil.FormatSimple(BannerData.BannerShowTypeNew,self.AttachAcId, self.BannerId))
                if not IsBannerShowTypeNew then
                    ---@type ActivityData
                    local AcData = MvcEntry:GetModel(ActivityModel):GetData(self.AttachAcId)
                    if AcData and AcData:IsAvailble() then
                        TState = ActivityDefine.BannerShowState.Showing
                    end
                else
                    TState = ActivityDefine.BannerShowState.Dismiss
                end
            end
            if self.ShowType == ActivityDefine.BannerShowType.Daily and self.AttachAcId > 0   then
                local SaveGameKey = StringUtil.FormatSimple("BannerNextTriggerOnDay_{0}",self.AttachAcId)
                local LastTimeStamp = SaveGame.GetItem(SaveGameKey)
    
                if LastTimeStamp and Timestamp - LastTimeStamp < 0 then
                    TState = ActivityDefine.BannerShowState.Dismiss
                else
                    SaveGame.SetItem(SaveGameKey, TimeUtils.GetOffsetDayZeroTime(Timestamp, 1))
                    TState = ActivityDefine.BannerShowState.Showing
                end
            end
        end
    end
    self:SetState(TState)
end

function BannerData:BannerSort()
    return self.Sort
end

function BannerData:AttachActivity(AttachAcId)
    self.AttachAcId = AttachAcId
end

return BannerData
