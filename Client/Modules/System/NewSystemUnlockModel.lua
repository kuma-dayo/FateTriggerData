--[[
    功能解锁数据模型
]]

local super = GameEventDispatcher;
local class_name = "NewSystemUnlockModel";

---@class NewSystemUnlockModel : GameEventDispatcher
---@field private super GameEventDispatcher
NewSystemUnlockModel = BaseClass(super, class_name)

NewSystemUnlockModel.ON_PLAYER_UNLOCK_INFO_INITED = "ON_PLAYER_UNLOCK_INFO_INITED" -- 系统解锁信息初始化完成
NewSystemUnlockModel.ON_NEW_SYSTEM_UNLOCK = "ON_NEW_SYSTEM_UNLOCK" -- 通知系统解锁

function NewSystemUnlockModel:__init()
    self:_dataInit()
end

function NewSystemUnlockModel:_dataInit()
    self:InitUnlockData()
    -- 已解锁id列表
    self.UnlockIdList = {}
end

function NewSystemUnlockModel:OnLogin(data)

end

--[[
    玩家登出时调用
]]
function NewSystemUnlockModel:OnLogout(data)
    NewSystemUnlockModel.super.OnLogout(self)
    self:_dataInit()
end

-------- 对外接口 -----------

-- 功能是否解锁
function NewSystemUnlockModel:IsSystemUnlock(UnlockId,IsShowTips)
    if not self.UnlockCfgList[UnlockId] then
        return true
    end
    if self.UnlockIdList[UnlockId] then
        return true
    elseif IsShowTips then
        self:ShowSystemUnlockTips(UnlockId)
    end
    return false
end

-- 弹未解锁提示
function NewSystemUnlockModel:ShowSystemUnlockTips(UnlockId)
    if self.UnlockCfgList[UnlockId] then
        UIAlert.Show(self.UnlockCfgList[UnlockId].TipsStr)
    end
end

-- 获取解锁提示
function NewSystemUnlockModel:GetSystemUnlockTips(UnlockId)
    if self.UnlockCfgList[UnlockId] then
        return StringUtil.Format(self.UnlockCfgList[UnlockId].TipsStr)
    end
    return ""
end

----------------------------------------

-- 更新解锁id
function NewSystemUnlockModel:UpdateUnlockInfo(UnLockIdList, IsInit)
    self.UnlockIdList = self.UnlockIdList or {}
    for _,UnlockId in ipairs(UnLockIdList) do
        self.UnlockIdList[UnlockId] = true
        if not IsInit then
            self:DispatchType(NewSystemUnlockModel.ON_NEW_SYSTEM_UNLOCK,UnlockId)
        end
    end
end

-- 初始化解锁提示
function NewSystemUnlockModel:InitUnlockData()
    self.UnlockCfgList = {}
    local Cfgs = G_ConfigHelper:GetDict(Cfg_UnLockCfg)
    for _,Cfg in ipairs(Cfgs) do
        local UnlockId = Cfg[Cfg_UnLockCfg_P.UnlockId]
        self.UnlockCfgList[UnlockId] = {
            UnlockId = UnlockId,
            TipsStr = StringUtil.Format(Cfg[Cfg_UnLockCfg_P.TipsStr],Cfg[Cfg_UnLockCfg_P.UnlockValue]),
        }
    end
end