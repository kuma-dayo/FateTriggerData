
--[[
    端内CG
]]
local super = GameEventDispatcher;
local class_name = "EndinCGModel";
---@class EndinCGModel : GameEventDispatcher
EndinCGModel = BaseClass(super, class_name);


--[[
    游戏初始化完成，用于一些基础常量的定义，例如从字符串表取值
]]
function EndinCGModel:OnGameInit(data) 
end

---【重写】游戏文化初始化完成（初始化/文化发生改变时会调用），用于一些基础常量的定义，例如从字符串表取值(涉及到本地化的)
---@param data any
function EndinCGModel:OnCultureInit(data) 
end

--[[
    用户登入/重连，用于初始化数据,当玩家帐号信息同步完成，会触发
    【注意】重连情景也会触发 并不跟OnLogout成对出现，该接口可能会反复触发
    data 为真表示 为断线重连 值为断线重连类型
]]
function EndinCGModel:OnLogin(data) 
    CLog("EndinCGModel:OnLogin")
    self:InitGCacheFromLocal()
end

--[[
    用户登出，用于清除旧用户的数据相关  data有值表示为断线重连
    @param data data有值表示为断线重连
]]
function EndinCGModel:OnLogout(data)  
    CLog("EndinCGModel:OnLogout")
end

-- --[[
--     用户即将登出，用于在断线后未返回登录界面前，清除旧用户的数据相关
--     @param data 无作用，占位
-- ]]
-- function EndinCGModel:OnPreLogout(data)  
-- end

---【重写】用户重连，登录，用于重连情景需要清除数据的场景
---@param data any data有值表示为断线重连类型
function EndinCGModel:OnLogoutReconnect(data) 
end


-------------------------------------------------------------------------------Cache >>

---初始化:从本地本地缓存读取
function EndinCGModel:InitGCacheFromLocal()
    -- self.CacheEndinCGMap = {}
    self.CacheEndinCGMap = SaveGame.GetItem(EndinCGDefine.CacheEndinCGKey, nil, true) or {}
end

---记录CG是否跳过
function EndinCGModel:RecordCGIsSkip(ModuleId, bSkip)
    local CGCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_CGSettingConfig, Cfg_CGSettingConfig_P.ModuleId, ModuleId)
    if CGCfg == nil then
        return
    end

    if not(CGCfg[Cfg_CGSettingConfig_P.IsCanSkip]) then
        CError(string.format("EndinCGModel:RecordCGIsSkip, Skipping Settings is not supported !!!!, ModuleId = %s", ModuleId))
        return
    end

    local StrKey = tostring(ModuleId)
    local CacheData = self.CacheEndinCGMap[StrKey]
    if CacheData then
        CacheData.SkipCG = bSkip and 1 or 0
        -- CacheData.PlayNum = CacheData.PlayNum or 1
    else
        CacheData = {}
        CacheData.SkipCG = bSkip and 1 or 0
        -- CacheData.PlayNum = CacheData.PlayNum or 1
        self.CacheEndinCGMap[StrKey] = CacheData
    end
    SaveGame.SetItem(EndinCGDefine.CacheEndinCGKey, self.CacheEndinCGMap, nil, true) 
end

---记录CG播放次数
function EndinCGModel:RecordCGPlayCount(ModuleId)
    local StrKey = tostring(ModuleId)
    local CacheData = self.CacheEndinCGMap[StrKey]
    if CacheData then
        CacheData.PlayNum = CacheData.PlayNum + 1
    else
        CacheData = {}
        CacheData.PlayNum = 1
        CacheData.SkipCG = 0
        self.CacheEndinCGMap[StrKey] = CacheData
    end
    SaveGame.SetItem(EndinCGDefine.CacheEndinCGKey, self.CacheEndinCGMap, nil, true) 
end

---获取数据到本地缓存
function EndinCGModel:GetCGCacheFromLocal(ModuleId)
    self:InitGCacheFromLocal()

    if self.CacheEndinCGMap == nil then
        CError("EndinCGModel:GetCGCacheFromLocal, self.CacheEndinCGMap == nil !!!")
        return nil
    end
    local StrKey = tostring(ModuleId)
    return self.CacheEndinCGMap[StrKey]
end

---从本地读取缓存判断是否跳过CG
function EndinCGModel:GetCGIsNeedSkip(ModuleId)
    local CGCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_CGSettingConfig, Cfg_CGSettingConfig_P.ModuleId, ModuleId)
    if CGCfg == nil then
        CError(string.format("EndinCGModel:GetCGIsNeedSkip, CGCfg == nil !!!, bCanSkip = true"))
        return true
    end

    local CacheData = self:GetCGCacheFromLocal(ModuleId) 
    local bCanSkip = false
    if CacheData then
        if CGCfg[Cfg_CGSettingConfig_P.DelaySkip] then
            local Num = CacheData.PlayNum or 0
            if Num > 0  then
                bCanSkip = true
            end
        else
            bCanSkip = CacheData.SkipCG == 1
        end

        CWaring(string.format("EndinCGModel:GetCGIsNeedSkip,ModuleId=[%s],CacheData=[%s],bCanSkip=[%s]", tostring(ModuleId), table.tostring(CacheData), tostring(bCanSkip)))
    end
    -- if UE.UGFUnluaHelper.IsEditor() then
    --     bCanSkip = false
    -- end
    return bCanSkip
end

-------------------------------------------------------------------------------Cache <<


return EndinCGModel