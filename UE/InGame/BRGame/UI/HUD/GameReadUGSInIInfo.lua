
--读取UGS.ini信息

local GameReadUGSInIInfo = Class()

function GameReadUGSInIInfo:Construct()
    -- self.Super:Construct()
end

function GameReadUGSInIInfo:Destruct()
    
end

local InI_Config = nil
local Client_Path = nil

function GameReadUGSInIInfo:GetUserNameWindows()
    local handle = io.popen("echo %USERNAME%")
    local username = handle:read("*l")
    handle:close()
    return username
end

--格式化ini文件内容(转为table)
function GameReadUGSInIInfo:ParseINIFile(filename)
    local config = {}
    local current_section

    for line in io.lines(filename) do
        line = line:match("^%s*(.-)%s*$")

        if line ~= "" and not line:match("^%s*;") then
            local section = line:match("^%[([^%[%]]+)%]$")
            if section then
                current_section = section
                config[current_section] = {}
            else
                local key, value = line:match("^(.-)%s*=%s*(.*)$")
                if key and value and current_section then
                    -- 如果键已经存在，将值存储为数组
                    if config[current_section][key] then
                        if type(config[current_section][key]) ~= "table" then
                            config[current_section][key] = {config[current_section][key]}
                        end
                        table.insert(config[current_section][key], value)
                    else
                        config[current_section][key] = value
                    end
                end
            end
        end
    end

    return config
end

function GameReadUGSInIInfo:GetINIConfig(ini_path)
    local filename = ini_path
    local config = self:ParseINIFile(filename)
    return config
end

function GameReadUGSInIInfo:GetExecuteCommandResult(command_str)
    if not BridgeHelper.IsPCPlatform() then
        --io.popen接口暂不支持在移动端使用,会另作处理
        return nil
    end
    os.execute(command_str)
    -- 读取命令的返回结果
    local file = io.popen(command_str)
    local result = file:read("*all")
    file:close()
    return result
end

function GameReadUGSInIInfo:GetLineFromStr(str)
    if not str or string.len(str) < 1 then
        return nil
    end

    local lineNumber = 5  --要提取的行号,这里直接写死就行了,只需要获取client_name,顺序固定

    local currentLine = 1
    local extractedLine = nil

    for line in str:gmatch("[^\n]+") do
        if currentLine == lineNumber then
            extractedLine = line
            break
        end
        currentLine = currentLine + 1
    end

    local new_extractedLine = {}
    for word in extractedLine:gmatch("%S+") do
        table.insert(new_extractedLine, word)
    end
    return new_extractedLine[3]
end

function GameReadUGSInIInfo:GetClientPath()
    local p4_info = self:GetExecuteCommandResult("p4 info")
    if not p4_info then
        return nil
    end
    local client_path = self:GetLineFromStr(p4_info)
    print("client_path>>>>>>>>>", client_path)
    return client_path
end

function GameReadUGSInIInfo:GetCurChangeList()
    -- 暂时注释编辑器获取代码 
    -- https://pm.gravitation.bytedance.net/projects/issues/51625
    do 
        return 0
    end

    print("==========GameReadUGSInIInfo:GetCurChangeList==========")
    Client_Path = Client_Path or self:GetClientPath()

    print("Client_Path>>>>>>>>>>>>>>>>>>>", Client_Path)

    if not Client_Path then
        print("未找到ClientPath!!")
        return 0
    end

    local user_name = self:GetUserNameWindows()
    local ini_path = "C:\\Users\\" .. user_name .. "\\AppData\\Local\\UnrealGameSync\\UnrealGameSync.ini" --要获取的ini路径,一般都是这个路径

    InI_Config = InI_Config or self:GetINIConfig(ini_path)

    if not InI_Config then
        print("未能找到ini_path!!")
        return 0
    end

    -- 访问重复的键对应的值
    local values = InI_Config["General"]["+RecentProjects"]
    if not values then
        print("未找到RecentProjects!!")
        return 0
    end
    print(values)

    local cur_root = Client_Path:match("(.-)\\S1Game")
    if not cur_root then
        cur_root = Client_Path:match("(.-)\\UE5EA")
        if not cur_root then
            print("匹配目录出错!!")
            return 0
        end
    end

    cur_root = cur_root:gsub("\\", "\\\\")
    print("cur_root>>>>>>>>>>>>", cur_root)

    local clientPath = ""
    local localPath = ""
    for _, value in ipairs(values) do
        localPath = value:match('LocalPath="(.-)"')
        print(localPath)
        print(string.lower(localPath), string.lower(cur_root))
        if string.lower(localPath):find(string.lower(cur_root)) then
            print("找到工作空间匹配路径!")
            clientPath = value:match('ClientPath="(.-)"')
            break
        end
    end
    if string.len(clientPath) < 1 then
        print("解析changelist失败!!", cur_root)
        return 0
    end
    --print("clientPath>>>>>>>>>>>>", clientPath)
    local root_name = clientPath:match("(.-)/S1Game"):gsub("//", "")
    print("root_name>>>>>>>>>>>>>", root_name)
    --print(config[root_name].CurrentChangeNumber)
    if not InI_Config[root_name] then
        print("解析changelist失败!!找不到"..root_name.."key!!")
        return 0
    end
    return InI_Config[root_name].CurrentChangeNumber
end

return GameReadUGSInIInfo