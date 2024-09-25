--[[
    系统菜单数据
]] 

local super = GameEventDispatcher;
local class_name = "SystemMenuModel";

---@class SystemMenuModel : GameEventDispatcher
---@field private super GameEventDispatcher
SystemMenuModel = BaseClass(super, class_name)
-- SystemMenuModel.ON_PLAYER_BASE_INFO_CHANGED = "ON_PLAYER_BASE_INFO_CHANGED" -- 基础信息变化
SystemMenuModel.ON_VOICE_OPEN_STATE_CHANGED = "ON_VOICE_OPEN_STATE_CHANGED"

local SaveKey_VoiceApplyTips = "VoiceApplyTips"
local SaveKey_VoiceSetting = "VoiceSetting"

function SystemMenuModel:__init()
    self:_dataInit()
end

function SystemMenuModel:_dataInit()
    -- 默认设置
    self.VoiceSetting = {
        [SystemMenuConst.VoiceSettingType.VoiceIsOpen] = false,
        [SystemMenuConst.VoiceSettingType.VoiceMode] = true,
        [SystemMenuConst.VoiceSettingType.VoiceChannel] = true,
    }
    
    self.SavedVolume = {}
end

function SystemMenuModel:OnLogin(data)
    local SaveTab = SaveGame.GetItem(SaveKey_VoiceSetting)
    if SaveTab then
        for Key, Val in pairs(SaveTab) do
            local SettingType = SystemMenuConst.VoiceSettingType[Key]
            self.VoiceSetting[SettingType] = (Val == 1) and true or false
            self:SetVoiceSetting(SettingType,self.VoiceSetting[SettingType],true)
        end
    end
end

--[[
    玩家登出时调用
]]
function SystemMenuModel:OnLogout(data)
    SystemMenuModel.super.OnLogout(self)
    self:_dataInit()
end

-- 可否改变设置开关
function SystemMenuModel:CanChangeVoiceSetting(SettingType,SettingState)
    if SettingType and SettingType == SystemMenuConst.VoiceSettingType.VoiceIsOpen then
        -- 打开语音开关要检测是否禁言中
        local BanTips = MvcEntry:GetModel(BanModel):GetBanTipsForType(Pb_Enum_BAN_TYPE.BAN_VOICE)
        if BanTips then
            UIAlert.Show(BanTips)
            return false
        end
    end
    return true
end

-- 获取设置开关
function SystemMenuModel:GetVoiceSetting(SettingType)
    if SettingType == SystemMenuConst.VoiceSettingType.VoiceIsOpen then
        -- 检查是否禁言中
        if MvcEntry:GetModel(BanModel):IsBanningForType(Pb_Enum_BAN_TYPE.BAN_VOICE) then
            return false
        end
    end
    return self.VoiceSetting[SettingType]
end

-- 改变设置开关
function SystemMenuModel:SetVoiceSetting(SettingType, SettingState, NotToSave)
    if not NotToSave then
        self:UpdateLocalSetting(SettingType,SettingState)
    end

    local RoomName = MvcEntry:GetModel(TeamModel):GetTeamVoiceRoomName()
    if not RoomName then
        CLog("SetVoiceSetting Without Room")
        return
    end
    ---@type SystemMenuCtrl
    local SystemMenuCtrl = MvcEntry:GetCtrl(SystemMenuCtrl)
    if SettingType == SystemMenuConst.VoiceSettingType.VoiceIsOpen then
        -- 开/关 语音聊天
        if SettingState then 
            SystemMenuCtrl:EnableTeamSpeaker(true)
            if not self.VoiceSetting[SystemMenuConst.VoiceSettingType.VoiceMode] then
                SystemMenuCtrl:EnableTeamMic(true)
            end
        else
            SystemMenuCtrl:EnableTeamSpeaker(false)
            SystemMenuCtrl:EnableTeamMic(false)
        end
        self:DispatchType(SystemMenuModel.ON_VOICE_OPEN_STATE_CHANGED)
    elseif SettingType == SystemMenuConst.VoiceSettingType.VoiceMode then
        if not self.VoiceSetting[SystemMenuConst.VoiceSettingType.VoiceIsOpen] then
            return
        end
        -- 按键说话/自由麦
        if SettingState then
            SystemMenuCtrl:EnableTeamMic(false)
        else
            SystemMenuCtrl:EnableTeamMic(true)
        end
    end
end

-- 仅更新开关标记
function SystemMenuModel:UpdateLocalSetting(SettingType,SettingState)
    self.VoiceSetting = self.VoiceSetting or {}
    self.VoiceSetting[SettingType] = SettingState
    --保存到本地
    self:SaveVoiceSetting()
end

function SystemMenuModel:SaveVolume(PlayerId,Volume)
    self.SavedVolume = self.SavedVolume or {}
    self.SavedVolume[PlayerId] = Volume
end

function SystemMenuModel:GetSavedVolume(PlayerId)
    return self.SavedVolume[PlayerId] or 100
end

function SystemMenuModel:ClearSavedVolume()
    self.SavedVolume = {}
end

-- 改变玩家国家与区域
function SystemMenuModel:SetRegionPolicy(RegionPolicyId)
    self.RegionPolicyId = RegionPolicyId
end
-- 获取玩家国家与区域
function SystemMenuModel:GetRegionPolicy()
    if self.RegionPolicyId == nil then
        self.RegionPolicyId = SaveGame.GetItem(SystemMenuConst.RegionPolicyIdKey, nil,true) or 0
        local RegionPolicyCfg = G_ConfigHelper:GetSingleItemById(Cfg_RegionPolicyConfig, self.RegionPolicyId)

        if not RegionPolicyCfg then
            CError(string.format("SystemMenuModel:GetRegionPolicy, RegionPolicyCfg == nil, self.RegionPolicyId = %s",tostring(self.RegionPolicyId)))

            local Cfgs = G_ConfigHelper:GetDict(Cfg_RegionPolicyConfig)
            for RegionID, Cfg in pairs(Cfgs) do
                self.RegionPolicyId = RegionID
                break
            end
        end
    end
    return self.RegionPolicyId
end


---------------------------------VoiceSetting >>

local GetVoiceSettingTypeKey = function(InVal)
    for StrKey, Val in pairs(SystemMenuConst.VoiceSettingType) do
        if Val == InVal then
            return StrKey
        end
    end
    return nil
end

---保存到本地 self.VoiceSetting 值到本地
function SystemMenuModel:SaveVoiceSetting()
    -- local GetVoiceSettingTypeKey = function(InVal)
    --     for StrKey, Val in pairs(SystemMenuConst.VoiceSettingType) do
    --         if Val == InVal then
    --             return StrKey
    --         end
    --     end
    --     return nil
    -- end

    local StrTabVal = {}
    for Key, Val in pairs(self.VoiceSetting) do
        local StrKey = GetVoiceSettingTypeKey(Key)
        StrTabVal[StrKey] = Val and 1 or 0
    end

    SaveGame.SetItem(SaveKey_VoiceSetting, StrTabVal)
end

---获本地缓存的值
function SystemMenuModel:GetVoiceSettingBySettingType(InSettingType)
    local StrKey = GetVoiceSettingTypeKey(InSettingType)
    local VoiceSettingTab = SaveGame.GetItem(SaveKey_VoiceSetting)
    if VoiceSettingTab then
        return VoiceSettingTab[StrKey]  or nil
    end
    return nil
end

-- 获取本地记录: 是否弹出过申请语音权限
function SystemMenuModel:HadShownVoiceApplyTips()
    return SaveGame.GetItem(SaveKey_VoiceApplyTips)
end

-- 记录到本地: 弹出过申请语音权限
function SystemMenuModel:SaveHadShownVoiceApplyTips()
    SaveGame.SetItem(SaveKey_VoiceApplyTips, true)
end
---------------------------------VoiceSetting <<
