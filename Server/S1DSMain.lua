
print("DSMain", ">> Setup[Start], ... ")

require("UnLua")
require("BaseRequire")
CommonUtil.IsDS = true
--Old
require("Common.Framework.Class")
require("Common.Framework.CommFuncs")
require("Common.Framework.Json")
require("Common.Framework.Functions")
require ("Common.Framework.SaveGame")
require("Common.Framework.TimeUtils")
ConfigDefine    = require("Common.Framework.ConfigDefine")
IOHelper        = require("Common.Framework.IOHelper")
MsgDefine		= require("Common.Framework.MsgDefine")
-- MsgHelper		= require("Common.Framework.MsgHelper")
-- HttpHelper		= require("Common.Framework.HttpHelper")
BridgeHelper	= require("Common.Framework.BridgeHelper")
ObjectBase		= require("Common.Framework.ObjectBase")

---@type ConfigHelper
G_ConfigHelper   = require("Common.Framework.ConfigHelper").New()
MsgHelper		= require("Common.Framework.MsgHelper").New()
HttpHelper		= require("Common.Framework.HttpHelper").New()
require("Client.Net.HttpRequestJobLogic")
BridgeHelper		= require("Common.Framework.BridgeHelper")
_G.UIHelper		    = require("Common.Framework.UIHelper")
_G.UserWidget		= require("Common.Framework.UserWidget")
--MVC
require("Server.DSMainCtrl")
require("Server.DSProtocol")

--MVC框架初始化
_G.MvcEntry = DSMainCtrl.New()
_G.MvcEntry:Initialize()
CommonUtil.CheckMvcEntyActionCache()

--针对DS环境，将LuaGC停了
collectgarbage("step",  -1024*1024*30)
collectgarbage("stop")

print("DSMain", ">> Setup[End], ... ")