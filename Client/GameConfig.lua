--[[
    游戏基础配置相关
]]

local init = false
GameConfig = {}

local configData = {}
local localServerListData = {}

-- 鼠标样式枚举,id对应 Cfg_MouseCursorIconCfg
GameConfig.CursorType = {
    Default = 1000,
    Drag = 1001,
    Rotate = 1002,
    Scale = 1003,
}
GameConfig.UseCursorType = GameConfig.CursorType.Default
GameConfig.UseCursorTransform = nil
function GameConfig.Init()
    if init then
        return
    end
    
    --TODO 初始化
    -- configData = CommonUtil.JSONDecodeFileInContent("StreamingAssets/config.json")
    -- localServerListData = CommonUtil.JSONDecodeFileInContent("StreamingAssets/serverList.json")
    -- CommonUtil.testMode = configData.testMode
    CommonUtil.testMode = true
    init = true
end

--[[
    获取本地服务器列表
]]
function GameConfig.GetLocalSeverList()
    return localServerListData
end

--[[
    获取本地服务器信息   根据索引值
]]
function GameConfig.GetLocalServerInfoByIndex(index)
    local info = localServerListData and localServerListData[index]
    if not info then
        info = {
            ["ip"]= "192.168.2.188",
            ["port"]= 1085,
            ["name"]= G_ConfigHelper:GetStrFromOutgameStaticST("SD_ServerList","1001"),
        }
    end
    return info
end

--[[
    是否测试模式
]]
function GameConfig.IsTestMode()
    GameConfig.Init()
    return CommonUtil.testMode
end

--[[
    是否测试重连
]]
function GameConfig.TestReconnect()
    return CommonUtil.test_reconnect
    -- return true
end
