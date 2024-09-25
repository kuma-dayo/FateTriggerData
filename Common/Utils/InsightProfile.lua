-- Author:[hushuai]
-- 适用于Unreal Insight中Track文件的Lua标签

local InsightProfile = {}

InsightProfile.profileTagUDMap = {}
-- 避免业务漏调用End函数，导致userdata无法释放
setmetatable(InsightProfile.profileTagUDMap, {__mode = "v"})

InsightProfile.isEnable = false
if UE and UE.UGFUnluaHelper and UE.UGFUnluaHelper.GetBuildType() ~= "Shipping" and UE.UGFUnluaHelper.GetBuildType() ~= "Test" then
    InsightProfile.isEnable = true
end

function InsightProfile.Begin(tagString)
    if InsightProfile.isEnable ~= true then
        return
    end

    if not tagString or tagString == "" then
        return
    end

    local profileTagUD = UE and UE.FProfileTag()
    if not profileTagUD then
        return
    end

    local callStackInfo = debug.getinfo(2, "Sl")
    if not callStackInfo or not next(callStackInfo) then
        return
    end

    -- 文件名为全路径时，忽略因为字符串加载Lua，而导致路径头出现“@”的问题
    local filePath = callStackInfo.source or callStackInfo.short_src or ""
    local line = callStackInfo.currentline or callStackInfo.linedefined or 0

    if not pcall(profileTagUD.Begin, profileTagUD, tagString, filePath, line) then
        Error("InsightProfile.Begin. Error!!! tagString = ", tagString)
        return
    end

    InsightProfile.profileTagUDMap[tagString] = profileTagUD
end

function InsightProfile.End(tagString)
    if InsightProfile.isEnable ~= true then
        return
    end

    if not tagString or tagString == "" then
        return
    end

    local profileTagUD = InsightProfile.profileTagUDMap[tagString]
    if not profileTagUD then
        return
    end

    if not pcall(profileTagUD.End, profileTagUD) then
        Error("InsightProfile.End. Error!!! tagString = ", tagString)
        return
    end

    InsightProfile.profileTagUDMap[tagString] = nil
end

return InsightProfile