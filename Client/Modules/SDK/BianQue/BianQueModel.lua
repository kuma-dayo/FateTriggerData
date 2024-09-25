local super = GameEventDispatcher;
local class_name = "BianQueModel";

--[[ 
    扁鹊Model
]]
---@class BianQueModel
BianQueModel = BaseClass(super, class_name);

--[[
    扁鹊的内置画像变量
]]
BianQueModel.SYSTEMPORTAINT =
{
    --渠道
    CHANNEL = "_Channel",
    --游戏App版本号
    APPVERSION = "_GameAppVersion",
    --游戏资源版本号
    RESVERSION = "_GameResVersion",
    --网络类型
    NETTYPE = "_NetType",
    --账户平台
    ACCOUNTPLATFORM = "_AccountPlatform",
    --操作系统
    OS = "_OS",
    --操作系统版本号
    OSVERSION = "_OSVersion",
    --设备机型
    DEVICENAME = "_DeviceName",
    --设备型号
    DEVICEMODEL = "_DeviceModel",
    --设备CPU
    DEVICECPU = "_DeviceCPU",
    --设备GPU
    DEVICEGPU = "_DeviceGPU",
    --设备ID
    DEVICEID = "_DeviceID",
    --设备内存
    DEVICEMEMORY = "_DeviceMemory",
    --用户账号
    ACCOUNT = "_Account",
    --扁鹊ID
    BQID = "_BQID",
    --扁鹊CCS版本号
    CCSVERSION = "_CCSVersion",
    --32/64位系统
    SYSTEMBIT = "_SystemBit",
    --用户系统语言
    SYSTEMLANGUAGE = "_SysLanguage",
    --区域
    REGION = "Region"
}


--[[
    扁鹊的自定义画像变量
]]
BianQueModel.USERPORTAINT =
{
    ACCOUNTNAME = "AccountName",
    NEWBEEPROGRESS = "NewBeeProgress",
}


function BianQueModel:__init()
end

function BianQueModel:OnLogout()
end


return BianQueModel
