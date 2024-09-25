JSON = require("Common.Lib.JSON")
-- TableAux = require("Common.Utils.TableAux")

local print = UnLua.Log
local warn = UnLua.LogWarn--UEWarning
local error = UnLua.LogError--UEError

CommonUtil = CommonUtil or {}


--[[是否已经成功游戏，第一个Level加载成功，会将此值置为true]]
if CommonUtil.g_in_game == nil then
    CommonUtil.g_in_game = false
end
--[[是否在游戏中，在欢迎界面为false，在非欢迎界面为true]]
if CommonUtil.g_in_play == nil then
    CommonUtil.g_in_play = false
end
--[[是否已在登录过游戏了，默认为false,登录进入大厅后会为true]]
if CommonUtil.g_in_playing == nil then
    CommonUtil.g_in_playing = false
end
--[[是否游戏入口subsystem已经启动完成,默认为false 会在S1ClientMain:OnStart置为true]]
if CommonUtil.g_client_main_start == nil then
    CommonUtil.g_client_main_start = false
end
--[[是否处于开发者模式 ，默认为真]]
if CommonUtil.testMode == nil then
    CommonUtil.testMode = true
end
--[[
    是否DS，默认不是
    会在S1ClienMain/S1DSMain这边进行赋值
]]
if CommonUtil.IsDS == nil then
    CommonUtil.IsDS = false
end

--[[打印日志-普通，发布模式下将不会打印]]
function CLog(str)
    if CommonUtil.testMode then
        print(str)
    end
end

--[[打印日志-警告，发布模式下将不会打印]]
function CWaring(str,strackback)
    if CommonUtil.testMode then
        warn(str)
        if strackback then
            print_trackback()
        end
    end
end

--[[打印日志-错误，发布模式下也会打印]]
function CError(str,strackback)
    error(str)
    if strackback then
        print_trackback()
    end
end

---打印日志-调试，发布模式下将不会打印，会额外添加文件名+行号
---@param str string 要打印的字符串
function CDebug(str)
    if CommonUtil.testMode then
        local info = debug.getinfo(2)
        if info then
	        print(StringUtil.Format2("[%s:%s] %s", info.source, info.currentline, str))
        else
            print(StringUtil.Format2("%s", str))
        end
    end
end

--[[
    判断运行环境是否DS
]]
function CommonUtil.IsDedicatedServer()
    return CommonUtil.IsDS
end

--[[解码JSon格式的文件内容到Table  Content目录
relativePath 相对路径
]]
function CommonUtil.JSONDecodeFileInContent(relativePath)
    local path = UE.UKismetSystemLibrary.GetProjectContentDirectory()
    return CommonUtil.JSONDecodeFile(path .. relativePath)
end

--[[解码JSon格式的文件内容到Table  saveDir目录
relativePath 相对路径
]]
function CommonUtil.JSONDecodeFileInSave(relativePath)
    local path = UE.UKismetSystemLibrary.GetProjectSavedDirectory()
    return CommonUtil.JSONDecodeFile(path .. relativePath)
end

--[[
    解码JSon格式的文件内容到Table
    path 全路径，绝对路径
]]
function CommonUtil.JSONDecodeFile(path)
    local str = UE.UGFUnluaHelper.LoadFileToString(path)
	if str then
        local data = CommonUtil.JsonSafeDecode(str)
        return data
    end
    return nil
end

--[[
    保护的执行Json解析，避免解析出错导致逻辑块不能往下执行

    将lua table 转换成 JsonStr
]]
function CommonUtil.JsonSafeEncode(Object)
    local res,info = EnsureCall("Json Encode Error:", JSON.encode,JSON, Object)
    if res then
        return info
    end
    return nil
end
--[[
    保护的执行Json解析，避免解析出错导致逻辑块不能往下执行

    将JsonStr 转换成 lua table
]]
function CommonUtil.JsonSafeDecode(JsonStr)
    local res,info = EnsureCall("Json Decode Error:" .. JsonStr, JSON.decode,JSON, JsonStr)
    if res then
        return info
    end
    return nil
end

--[[
    保存内容到指定文件
    相对路径  相对saveDir
]]
function CommonUtil.SaveStringToFileInSave(str,relativePath)
    local path = UE.UKismetSystemLibrary.GetProjectSavedDirectory()
    return CommonUtil.SaveStringToFile(str,path .. relativePath)
end

--[[
    保存内容到指定文件
    全路径，绝对路径
]]
function CommonUtil.SaveStringToFile(str,path)
    UE.UGFUnluaHelper.SaveStringToFile(str,path)
end

--[[
    保存图片到指定文件
    相对路径  相对saveDir
]]
function CommonUtil.SaveTextureToFile(Texture,RelativePath,ImageType)
    local Path = UE.UKismetSystemLibrary.GetProjectSavedDirectory()
    local SavePath = Path .. RelativePath
    local ImageData = UE.UGFUnluaHelper.EncodeTextureToImageData(Texture, ImageType)
    if ImageData then
        return UE.UGFUnluaHelper.SaveArrayToFile(SavePath, ImageData)
    end
    return false
end

--[[
    到相对路径获取对应图片文件  相对saveDir
]]
function CommonUtil.GetTextureByFile(RelativePath)
    local Path = UE.UKismetSystemLibrary.GetProjectSavedDirectory()
    local SavePath = Path .. RelativePath
    local TheTexture = UE.UKismetRenderingLibrary.ImportFileAsTexture2D(_G.GameInstance,SavePath)
    return TheTexture
end

TimeRecorder = TimeRecorder or {}
if TimeRecorder.TimeOffset == nil then
    TimeRecorder.TimeOffset = 0
    TimeRecorder.TimeOffsetMilliseconds = 0
end
--[[
    本地时间戳(秒)
]]
function GetLocalTimestamp()
    return math.floor(GetLocalTimestampMillisecondsUtc()/1000)
end

--[[
    本地时间戳(毫秒)(Utc)
]]
function GetLocalTimestampMillisecondsUtc()
    return UE.UGFUnluaHelper.GetTimestampMillisecondsUtc()
end

--[[
    服务器时间戳(秒)
]]
function GetTimestamp()
    return GetLocalTimestamp() + TimeRecorder.TimeOffset;
end

--[[
    服务器时间戳(毫秒)
]]
function GetTimestampMilliseconds()
    return GetLocalTimestampMillisecondsUtc() + TimeRecorder.TimeOffsetMilliseconds;
end

--[[
    记录与服务器的时间差
]]
function SetTimestampOffsetMilliseconds(Offset)
    TimeRecorder.TimeOffsetMilliseconds = Offset;
    TimeRecorder.TimeOffset = math.ceil(Offset/1000)
    --通知C++层
    UE.UGFUnluaHelper.SetTimestampOffsetMilliseconds(Offset)
end

--[[
    判断目标对象是否可用，是否被标记移除
    对象为UObject
]]
function CommonUtil.IsValid(node)
    if node ~= nil and UE.UKismetSystemLibrary.IsValid(node) then
		return true
    end
    return false
end


function CommonUtil.Number2TArrayInt(num_list)
	local Indices = UE.TArray(0)
	for k,v in ipairs(num_list) do
		Indices:Add(v)
	end
	return Indices
end

mvcEntryActionCache = mvcEntryActionCache or {}
--[[
    执行依赖框架初始化的动作
    会检测框架是否初始化，如果是则立即执行
    如果不是，则会进行Cache，待框架初始化完成会进行调用
]]
function CommonUtil.DoMvcEntyAction(action)
    if MvcEntry then
        action();
    else
        table.insert(mvcEntryActionCache,action)
    end
end

--[[
    在框架初始化完成时进行调用
    对Cache的行为进行调用
]]
function CommonUtil.CheckMvcEntyActionCache()
    for k, v in pairs(mvcEntryActionCache) do
        v()
    end
    mvcEntryActionCache = {}
end

---获取当前场景的场景ID
---@return number 当前场景ID
function CommonUtil.GetCurSceneID()
    ---@type HallModel 
    local HallModel = MvcEntry:GetModel(HallModel)
    return HallModel:GetSceneID()
end

---通过HallSceneMgr切换场景
---@param SceneID number 需要切换到的目标场景ID
---    对应 HeroConfig.xlsx 中的 场景ID
---    对应 HallSceneConfig.csv 中的 SceneID
function CommonUtil.SwitchScene(SceneID)
    ---@type HallSceneMgr
    local HallSceneMgr = _G.HallSceneMgrInst
    if HallSceneMgr == nil then
        return
    end
    HallSceneMgr:SwitchScene(SceneID)
end

---通过HallSceneMgr切换场景粒子(HallBGEffectl)是否可见
function CommonUtil.ActiveHallBGEffect(bActive)
    ---@type HallSceneMgr
    local HallSceneMgr = _G.HallSceneMgrInst
    if HallSceneMgr == nil then
        return
    end
    HallSceneMgr:ActiveHallBGEffect(bActive)
end

function CommonUtil.SetActorHiddenByTag(Tag, bHide)
    ---@type HallSceneMgr
    local HallSceneMgr = _G.HallSceneMgrInst
    if HallSceneMgr == nil then
        return
    end
    HallSceneMgr:SetActorHiddenByTag(Tag, bHide)
end


--[[
    获取AvatarMgr
]]
function CommonUtil.GetHallAvatarMgr()
    local HallSceneMgr = _G.HallSceneMgrInst
	if HallSceneMgr == nil then
		return 
	end
	return HallSceneMgr.AvatarMgr
end

--[[
    获取CameraMgr
]]
function CommonUtil.GetHallCameraMgr()
    local HallSceneMgr = _G.HallSceneMgrInst
	if HallSceneMgr == nil then
		return 
	end
	return HallSceneMgr.CameraMgr
end

--[[
    获取穿戴Mgr
]]
function CommonUtil.GetHallApparelMgr()
    local HallSceneMgr = _G.HallSceneMgrInst
	if HallSceneMgr == nil then
		return 
	end
	return HallSceneMgr.ApparelMgr
end

--[[
    退出游戏，将关闭游戏客户端
]]
function CommonUtil.QuitGame(InContext)
    UE.UKismetSystemLibrary.QuitGame(InContext,CommonUtil.GetLocalPlayerC(InContext),UE.EQuitPreference.Quit,true)
end


--[[
    获取本地玩家Controller
]]
--临时修改在Charactor ReceiveBeginPlay 这一帧，通过UE.UGameplayStatics.GetPlayerController取值为空的情况
--后续需要修复，不要这种临时写法
-- CommonUtil.Fix_Controller = nil             
function CommonUtil.GetLocalPlayerC(InContext)
    InContext = InContext or _G.GameInstance
    local FirstPC = UE.UGameplayStatics.GetPlayerController(_G.GameInstance, 0)
    -- if not FirstPC and CommonUtil.Fix_Controller and CommonUtil.Fix_Controller:IsValid() then
    --     FirstPC = CommonUtil.Fix_Controller
    -- end
    return FirstPC
end

--- 将当前的主相机相机参数设置到动画相机上
function CommonUtil.SetMainCameraInViewTarget(BlendTIme)
    local LocalPC = CommonUtil.GetLocalPlayerC()
    if not LocalPC then
        return
    end
    local Location = LocalPC.PlayerCameraManager:GetCameraLocation()
    local CameraRot = LocalPC.PlayerCameraManager:GetCameraRotation()
    local FOVAngle = LocalPC.PlayerCameraManager:GetFOVAngle()
    print("AssignViewTarget", Location, CameraRot, FOVAngle)
    -- ---这里要将镜头控制器放到F或S上, 不然LS会将镜头切到默认的镜头控制器上
    -- UE.UGameHelper.SwitchSceneCameraToTransform(
    --     _G.HallSceneMgrInst,
    --     UE.UKismetMathLibrary.MakeTransform(Location, 
    --     CameraRot,  UE.FVector(1,1,1)), 
    --     0, 
    --     FOVAngle, 
    --     0, 
    --     true,true)
    local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
    CameraActor:K2_SetActorTransform(UE.UKismetMathLibrary.MakeTransform(Location, CameraRot,  UE.FVector(1,1,1)),false, UE.FHitResult(), false);
    CameraActor.CameraComponent:SetFieldOfView(FOVAngle)
    LocalPC:SetViewTargetWithBlend(CameraActor, BlendTIme or 0)
end

function CommonUtil.FixPlayerCameraPov()
    local LocalPC = CommonUtil.GetLocalPlayerC()
    local Location = LocalPC.PlayerCameraManager:GetCameraLocation()
    local Rotator = LocalPC.PlayerCameraManager:GetCameraRotation()
    local FOVAngle = LocalPC.PlayerCameraManager:GetFOVAngle()
    print("AssignViewTarget", Location, Rotator, FOVAngle)
    MvcEntry:SendMessage(CommonEvent.ON_FIX_PLAYER_CAMERA_POV, {
        Location=Location,
        Rotator=Rotator,
        FOV= FOVAngle,
    })
end

--[[
     (Platform names include Windows, Mac, Linux, IOS, Android, consoles, etc.). */
]]
function CommonUtil.IsPlatform_Windows()
    local PlatformName = UE.UGameplayStatics.GetPlatformName()
    if PlatformName == "Windows" then
        return true
    end
    return false
end
function CommonUtil.IsPlatform_IOS()
    local PlatformName = UE.UGameplayStatics.GetPlatformName()
    if PlatformName == "IOS" then
        return true
    end
    return false
end


--[[
    框架事件或者Model事件  注册和移除

    MsgList结构范例：
    --Model 想要处理对应事件的Model，空值表示框架事件
    --MsgName  事件名称
    --Func  处理回调
    --Priority 回调优先级，值越大越优先执行
	self.MsgList = {
		{Model = nil, MsgName = CommonEvent.ON_LOGIN_FINISHED,	Func = self.ON_LOGIN_FINISHED_Func  , Priority = 0},
	}
]]
function CommonUtil.MvcMsgRegisterOrUnRegister(Handler,MsgListTmp,bRegister)
	if MsgListTmp and #MsgListTmp > 0 then
		if bRegister then
			for _,v in ipairs(MsgListTmp) do
				if v.Model then
                    if v.Model == InputModel then
                        MvcEntry:GetModel(v.Model):AddListenerWithCheckInput(v.MsgName, v.Func,  Handler,v.Priority)
                    else
                        MvcEntry:GetModel(v.Model):AddListener(v.MsgName, v.Func,  Handler,v.Priority)
                    end
				else
					MvcEntry:AddMsgListener(v.MsgName, 	v.Func,  Handler);
				end
			end
		else
			for _,v in ipairs(MsgListTmp) do
				if v.Model then
					MvcEntry:GetModel(v.Model):RemoveListener(v.MsgName, 	v.Func,  Handler,v.Priority)
				else
					MvcEntry:RemoveMsgListener(v.MsgName, 	v.Func,  Handler);
				end
			end
		end
	end
end

--[[
    协议事件的 注册和移除

    ProtoList 结构范例：
    --MsgName  事件名称
    --Func  处理回调
	self.ProtoList = {
		{MsgName = pb_ResID.Account_RepPlayerInfo,	Func = self.Account_RepPlayerInfo_Func },
	}
]]
function CommonUtil.ProtoMsgRegisterOrUnRegister(Handler,MsgListTmp,bRegister)
    if not Handler:IsClass(GameController) then
        CError("CommonUtil:ProtoMsgRegisterOrUnRegister not type of [GameController]")
        return
    end
	if MsgListTmp and #MsgListTmp > 0 then
		if bRegister then
            for _,v in ipairs(MsgListTmp) do
                Handler:AddProtoRPC(v.MsgName, v.Func, Handler)
            end
		else
            for _,v in ipairs(MsgListTmp) do
                Handler:RemoveProtoRPC(v.MsgName, v.Func, Handler)
            end
		end
	end
end

--[[
    Mvvm绑定  绑定和解绑
    
    MvvmBindList 结构范例：
	--Model         绑定的指定Model
	--BindSource  	绑定的源（可以是回调，可以是具有SetText方法的UMG控件）
    --PropertyName  绑定的Model里面的属性名称
	--MvvmBindType  绑定类型
	MvvmBindList = {
		{ Model = UserModel, BindSource = self.LbName, PropertyName = "PlayerName", MvvmBindType = MvvmBindTypeEnum.SETTEXT }
	}
]]
function CommonUtil.MvvmBindRegisterOrUnRegister(MsgListTmp,bRegister)
	if MsgListTmp and #MsgListTmp > 0 then
		if bRegister then
			for _,v in ipairs(MsgListTmp) do
				MvcEntry:GetModel(v.Model):MvvmBind(v.BindSource, v.PropertyName,v.MvvmBindType)
			end
		else
            for _,v in ipairs(MsgListTmp) do
				MvcEntry:GetModel(v.Model):MvvmUnBind(v.BindSource, v.PropertyName,v.MvvmBindType)
			end
		end
	end
end


--[[
    MsgListGMP结构范例：
    --InBindObject 事件绑定的UObject 事件会跟随UObject的生命周期进行自动销毁
	--MsgName  事件名称
    --Func  处理回调
	--bCppMsg  是否是与C++交互的事件
	MsgListGMP = {
		{ InBindObject = xxx ,MsgName = xxx, Func = self.On_xxx, bCppMsg = true, WatchedObject = nil }
	}
]]
function CommonUtil.MsgGMPRegisterOrUnRegister(MsgListTmp,bRegister)
	if MsgListTmp and #MsgListTmp > 0 then
		if bRegister then
			for _,v in ipairs(MsgListTmp) do
                -- print_r(v,"MsgGMPRegisterOrUnRegister:",true)
				MsgHelper:Register(v.MsgName, v.InBindObject, v.Func, v.bCppMsg, v.WatchedObject)
			end
		else
            for _,v in ipairs(MsgListTmp) do
				MsgHelper:Unregister(v.MsgName, v.InBindObject, v.Func, v.bCppMsg, v.Handle)
			end
		end
	end
end

--[[
	TimerList = {               TimerHandler 隐藏值 ，当计时器生效时，此值会存在
	    {                       计时器结构范例（基于UObjectTick去实现）
	        TimeOffset          (必填) 单位是秒 0的话，遇到tick就会执行；-1的话，会在下一帧执行。
	        TimerType           (可选，默认为TimerTypeEnum.Timer) 计时器类型 
	        Func                (必填) 执行回调
	        Loop                (可选，默认为false) boolean 是否循环
	        Name                (可选) 计时器名称
	    },
	    {...}
	}
	
	TimerList = {
		{ TimeOffset = 1, Func = Bind(self,self.OnUpdate), Loop = false,TimerType = TimerTypeEnum.Timer, Name = Name}
	}
]]
function CommonUtil.TimerRegisterOrUnRegister(TimerList,bRegister)
	if TimerList and #TimerList > 0 then
		if bRegister then
			for _,v in ipairs(TimerList) do
                v.TimerType = v.TimerType or TimerTypeEnum.Timer
                if v.TimerHandler then
                    CWaring("CommonUtil.TimerRegisterOrUnRegister repeat Register")
                else
                    if v.TimerType == TimerTypeEnum.Timer then
                        local TimerHandler = Timer.InsertTimer(v.TimeOffset,v.Func,v.Loop,v.Name)
                        v.TimerHandler = TimerHandler
                    elseif v.TimerType == TimerTypeEnum.CoroutineTimer then
                        local TimerHandler = Timer.InsertCoroutineTimer(v.TimeOffset, v.Func, v.Name)
                        v.TimerHandler = TimerHandler
                    else
                        local TimerHandler = TimerDelegate.InsertTimer(v.TimeOffset,v.Func,v.Loop,v.Name)
                        v.TimerHandler = TimerHandler
                    end
                end
			end
		else
            for _,v in ipairs(TimerList) do
                v.TimerType = v.TimerType or TimerTypeEnum.Timer
				if v.TimerHandler then
                    if v.TimerType == TimerTypeEnum.Timer or v.TimerType == TimerTypeEnum.CoroutineTimer then
                        Timer.RemoveTimer(v.TimerHandler)
                    else
                        TimerDelegate.RemoveTimer(v.TimerHandler)
                    end
                    CWaring("CommonUtil.TimerRegisterOrUnRegister false" .. _)
                    v.TimerHandler = nil
                end
			end
		end
	end
end


--[[
    修复蓝图类路径
    
]]
function CommonUtil.FixBlueprintPathWithC(Path,Force)
    --[[
        已开启 UNLUA_LEGACY_BLUEPRINT_PATH 为True 来对路径进行Fix修复
        S1Game\Plugins\UnLua\Source\UnLua\UnLua.Build.cs

        不再需要下列逻辑，如需开启置Force为真即可
    ]]
    if Force then
        CWaring("Path:" .. Path)
        if string.sub(Path, string.len(Path)-1) ~= "_C" then
            Path = Path .. "_C"
        end
    end
    
    return Path
end


function CommonUtil.FixBlueprintPathWithoutPre(Path,Force)
    --[[
        已开启 UNLUA_LEGACY_BLUEPRINT_PATH 为True 来对路径进行Fix修复
        S1Game\Plugins\UnLua\Source\UnLua\UnLua.Build.cs

        不再需要下列逻辑 FixBlueprintPathWithC 如需开启置Force为真即可
    ]]
    local index1 = string.find(Path, "'")
    local index2 = string.find(Path, "'", index1+1)
    Path = string.sub(Path, index1+1,index2-1)
    if Force then
        Path = CommonUtil.FixBlueprintPathWithC(Path,true)
    end
    
    return Path
end

--[[
    检查帐号是否合法
]]
function CommonUtil.AccountCheckValid(Account,AccountCharSize,ShowTip)
    if (not Account) or (Account == "") then
        if ShowTip then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonUtil_Usernamecannotbeempt"))
        end
        return false
    end
    if AccountCharSize and AccountCharSize > 0 then
        if StringUtil.utf8StringLen(Account) > tonumber(AccountCharSize) then
            if ShowTip then
                UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonUtil_Thenameistoolong"))
            end
            return false
        end
    end

    local StrLen = string.len(Account)
	--[[
		大写字���：A到Z（26个字符）
		小写字母：a到z（26个字符）
		数字：0到9（10个字符）
		符号：（空格）!"#$%&'()*+,-./:<=>?@[\]^_`{|}~（33个字符）
	]]
	local Idx = #string.gsub(Account, "[^\33-\126]", "")		-- 有效字符
    if Idx ~= StrLen then
        if ShowTip then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonUtil_Invalidusername"))
        end
        return false
    end
    return true
end

--[[
    玩家名称验证合法性
]]
function CommonUtil.PlayerNameCheckValid(Name, CharSize, IsShowAlert)
    if string.len(Name) <= 0 then
        if IsShowAlert then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonUtil_Namecannotbeempty"))
        end
        return false
    end
    if CharSize and CharSize > 0 then
        if not CommonUtil.StringCharSizeCheck(Name, CharSize,IsShowAlert and G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonUtil_Thenameistoolong") or nil) then
            return false
        end
    end
    return true
end

--[[

]]
function CommonUtil.StringCharSizeCheck(StringValue,CharSizeLimit,IllegalTip,EmptyTip)
    local Lens = StringUtil.utf8StringLen(StringValue)
    if Lens <= 0 and EmptyTip then
        UIAlert.Show(EmptyTip)
        return false
    end
    if Lens > CharSizeLimit then
        if IllegalTip then
            UIAlert.Show(IllegalTip)
        end
        return false
    end
    return true
end

--[[
    判断当前是否在战斗中
    兼容Editor,非正常流程，直接战斗地图client模式启动这种
]]
function CommonUtil.IsInBattle()
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        return true
    end
    if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.VirtualHall) and not MvcEntry:GetModel(ViewModel):GetState(ViewConst.VirtualLogin) and not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelStartup) then
        --兼容Editor,非正常流程，直接战斗地图client模式启动这种（且PC还没初始化好的边界情况）
        if _G.GameInstance:GetGameStageType() == UE.EGameStageType.None then
            return true
        end
    end
    return false
end

--[[
    检查玩家是否在游戏中（不在登录界面）
]]
function CommonUtil.IsInGameScene()
    local TheIsInGameScene = (MvcEntry:GetModel(ViewModel):GetState(ViewConst.VirtualLogin) == false)
    if TheIsInGameScene == false or not CommonUtil.g_in_play then
        return false
    end
    return true
end

--[[
    判断是否Shipping环境
]]
function CommonUtil.IsShipping()
    if CommonUtil.__IsShipping == nil then
        local BuildType = UE.UGFUnluaHelper.GetBuildType()

        if BuildType == "Shipping" then
            CommonUtil.__IsShipping = true
        else
            CommonUtil.__IsShipping = false
        end
    end
    return CommonUtil.__IsShipping
end

function CommonUtil.NetLogUserName(UserName)
    UserName = UserName or ""
    Netlog.UserName = UserName
    if string.len(UserName) <= 0 then
	    CLog("CommonUtil.NetLogUserName UserName:Empty")
    else
        CLog("CommonUtil.NetLogUserName UserName:" .. UserName)
    end
end

--[[
    获取视口适配后的设计大小(注意不是实际大小)
]]
function CommonUtil.GetViewportSize(WorldContextObject)
    local ViewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(WorldContextObject)
    local ViewportScale = UE.UWidgetLayoutLibrary.GetViewportScale(WorldContextObject)
    ViewportSize.x = ViewportSize.x/ViewportScale
    ViewportSize.y = ViewportSize.y/ViewportScale

    
    return ViewportSize
end

--[[
    根据当前视口缩放，将获取到的ScreenPos修复到当前设计分辨率下的大小
]]
function CommonUtil.FixScreenPosByViewportScale(WorldContextObject,ScreenPos)
    local ViewportScale = UE.UWidgetLayoutLibrary.GetViewportScale(WorldContextObject)
    local ScreenPosFix = UE.UKismetMathLibrary.Divide_Vector2DFloat(ScreenPos,ViewportScale)
    return ScreenPosFix
end

--[[
    根据软引用路径 给 图片设置Texture显示
]]
function CommonUtil.SetBrushFromSoftObjectPath(Widget,SoftObjectPath,IsMatchSize)
    if not SoftObjectPath then
        return
    end
    local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(SoftObjectPath)
	if ImageSoftObjectPtr ~= nil then
		Widget:SetBrushFromSoftTexture(ImageSoftObjectPtr, IsMatchSize or false)
    else
        CWaring("ImageSoftObjectPtr not found:" .. SoftObjectPath)
	end
end

--[[
    根据软引用路径 给 图片设置Material显示
]]
function CommonUtil.SetBrushFromSoftMaterialPath(Widget,SoftObjectPath)
    local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(SoftObjectPath)
	if ImageSoftObjectPtr ~= nil then
		Widget:SetBrushFromSoftMaterial(ImageSoftObjectPtr)
    else
        CWaring("ImageSoftObjectPtr not found:" .. SoftObjectPath)
	end
end

--[[
    设置DynamicMaterial的Texture参数值
]]
function CommonUtil.SetMaterialTextureParamSoftObjectPath(Widget,ValueTextureKey,SoftObjectPath)
    local NewTexture = LoadObject(SoftObjectPath)
    if NewTexture ~= nil then
        local Material = Widget:GetDynamicMaterial()
        if Material then
            Material:SetTextureParameterValue(ValueTextureKey,NewTexture)
        else
            CWaring("SetMaterialTextureParamSoftObjectPath Widget Have Not Material " .. SoftObjectPath)
        end
    end
end

--[[
    设置UMG 控件的 FWidgetTransform 参数
]]
function CommonUtil.SetBrushRenderTransform(Widget, RenderTransform)
    if Widget == nil or RenderTransform == nil then
        return
    end

    Widget:SetRenderTransform(RenderTransform)
end
--[[
    设置TextBlock字体大小
]]
function CommonUtil.SetTextFontSize(TextBlock,FontSize)
    local FontInfo = TextBlock.Font
	FontInfo.Size = FontSize
	TextBlock:SetFont(FontInfo)
end

--[[
    设置TextBlock描边大小
]]
function CommonUtil.SetTextFontOutlineSize(TextBlock,OutlineSize)
    local FontInfo = TextBlock.Font
	FontInfo.OutlineSettings.OutlineSize = OutlineSize
	TextBlock:SetFont(FontInfo)
end
--[[
    为TextBlock设置颜色，基于Hex值 
    Opacity 不传默认为1
]]
function CommonUtil.SetTextColorFromeHex(TextBlock,Hex,Opacity)
    local ColorAndOpacity = TextBlock.ColorAndOpacity
    Opacity = Opacity or ColorAndOpacity.SpecifiedColor.A
    local TheLinearColor = UE.UGFUnluaHelper.FLinearColorFromHex(Hex)
    TheLinearColor.A = Opacity
    local TheSlateColor = UE.FSlateColor()
    TheSlateColor.SpecifiedColor = TheLinearColor
    TextBlock:SetColorAndOpacity(TheSlateColor)
end

--[[
    为RichText设置默认字体颜色，基于Hex值 
    Opacity 不传默认为1
]]
function CommonUtil.SetRichTextDefaultTextStyleColorFromHex(RichText,Hex,Opacity)
    if not RichText then
        return
    end
    local DefaultTextStyleOverride = RichText.DefaultTextStyleOverride
    local ColorAndOpacity = DefaultTextStyleOverride.ColorAndOpacity
    Opacity = Opacity or ColorAndOpacity.SpecifiedColor.A
    local TheLinearColor = UE.UGFUnluaHelper.FLinearColorFromHex(Hex)
    TheLinearColor.A = Opacity
    local TheSlateColor = UE.FSlateColor()
    TheSlateColor.SpecifiedColor = TheLinearColor
    RichText:SetDefaultColorAndOpacity(TheSlateColor)
end

--[[
    为TextBlock设置颜色，基于品质
]]
function CommonUtil.SetTextColorFromQuality(TextBlock,Quality)
    local TheSlateColor = CommonUtil.Conv_Quality2FSlateColor(Quality)
    if TheSlateColor ~= nil then
        TextBlock:SetColorAndOpacity(TheSlateColor)
    end
end

--- 给图片上色
---@param Image table
---@param Hex string
function CommonUtil.SetImageColorFromHex(Image,Hex)
    local TheLinearColor = UE.UGFUnluaHelper.FLinearColorFromHex(Hex)
    if TheLinearColor ~= nil then
        Image:SetColorAndOpacity(TheLinearColor)
    end
end

--- 给图片上色
---@param Image table
---@param Quality number
function CommonUtil.SetImageColorFromQuality(Image,Quality)
    local TheLinearColor = CommonUtil.Conv_Quality2FLinearColor(Quality)
    if TheLinearColor ~= nil then
        Image:SetColorAndOpacity(TheLinearColor)
    end
end

--[[
    为Image设置Tint颜色，基于Hex值 
    Opacity 不传默认为1
]]
function CommonUtil.SetBrushTintColorFromHex(Image,Hex,Opacity)
    local ColorAndOpacity = Image.ColorAndOpacity
    Opacity = Opacity or ColorAndOpacity.A
    local TheLinearColor = UE.UGFUnluaHelper.FLinearColorFromHex(Hex)
    TheLinearColor.A = Opacity
    local TheSlateColor = UE.FSlateColor()
    TheSlateColor.SpecifiedColor = TheLinearColor
    Image:SetBrushTintColor(TheSlateColor)
end

function CommonUtil.SetBorderBrushColorFromHex(Border,Hex,Opacity)
    local BrushColor = Border.BrushColor
    Opacity = Opacity or BrushColor.A
    local TheLinearColor = UE.UGFUnluaHelper.FLinearColorFromHex(Hex)
    TheLinearColor.A = Opacity
    Border:SetBrushColor(TheLinearColor)
end


local TheGetParentWidgetFunc = function(Widget)
    local ParentWidget = Widget:GetParent()
    if not ParentWidget then
        local TheOuter = UE.UKismetSystemLibrary.GetOuterObject(Widget)
        if TheOuter and TheOuter:IsA(UE.UWidgetTree) then
            TheOuter = UE.UKismetSystemLibrary.GetOuterObject(TheOuter)
            if TheOuter and TheOuter:IsA(UE.UUserWidget) then
                ParentWidget = TheOuter
            end
        end
    end
    return ParentWidget
end

--[[
    获取UMG组件的真实可见性
]]
function CommonUtil.GetWidgetIsVisibleReal(Widget)
    local IsVisible = not (Widget:GetVisibility() == UE.ESlateVisibility.Collapsed or Widget:GetVisibility() == UE.ESlateVisibility.Hidden)
    if IsVisible then
        local ParentWidget = TheGetParentWidgetFunc(Widget)
        local Count = 0
        local CheckVisibleInSwitcher = function(PreParentWidget, ParentWidget)
            if ParentWidget and ParentWidget:IsA(UE.UWidgetSwitcher) then
                if ParentWidget:GetActiveWidget() ~= PreParentWidget then
                    return false
                end
            end
            return true
        end
        while ParentWidget do
            if ParentWidget:GetVisibility() == UE.ESlateVisibility.Collapsed or ParentWidget:GetVisibility() == UE.ESlateVisibility.Hidden then
                IsVisible = false
                break
            end
            local PreParentWidget = ParentWidget
            ParentWidget = TheGetParentWidgetFunc(ParentWidget)
            if Count == 0 then
                IsVisible = CheckVisibleInSwitcher(Widget, PreParentWidget)
            else
                IsVisible = CheckVisibleInSwitcher(PreParentWidget, ParentWidget)
            end
            Count = Count + 1
            if not IsVisible then
                break
            end
        end
    end
    return IsVisible
end

--[[
    FLinerColor -> FSlateColor
]]
function CommonUtil.Conv_FLinearColor2FSlateColor(TheLinearColor)
    local TheSlateColor = UE.FSlateColor()
    TheSlateColor.SpecifiedColor = TheLinearColor
    return TheSlateColor
end

--[[
    将物品品质 转为 FLinearColor
    -- 也返回 品质名称，按需取用
]]
function CommonUtil.Conv_Quality2FLinearColor(Quality)
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
    if not QualityCfg then
        return nil
    end
    local Color = UE.UGFUnluaHelper.FLinearColorFromHex(QualityCfg[Cfg_ItemQualityColorCfg_P.HexColor])
    return Color, QualityCfg[Cfg_ItemQualityColorCfg_P.QualityName]
end

--[[
    将物品品质 转为 SlateColor
]]
function CommonUtil.Conv_Quality2FSlateColor(Quality)
    local TheLinearColor = CommonUtil.Conv_Quality2FLinearColor(Quality)
    if TheLinearColor then
        return CommonUtil.Conv_FLinearColor2FSlateColor(TheLinearColor)
    end
    return nil
end

--[[
    设置品质展示
    ---@param ItemId 到ItemConfig中索引品质的Id
    ---@param Widgets = {
                -- 均为可选传递，按需添加
                QualityBar 品质底色条
                QualityIcon 圆形品质Icon框
                -- QualityLevelText 显示品质等级（罗马数字）的文本 --此字段已经过期
            }
    ---@param Params = {
                -- 均为可选传递，自定义参数
                QualityBarOpacity 品质底色条透明度
            }
    
]]
function CommonUtil.SetQualityShow(ItemId,Widgets,Params)
    Params = Params or {}
    local QualityCfg = MvcEntry:GetModel(DepotModel):GetQualityCfgByItemId(ItemId)
    CommonUtil.SetQualityShowForQualityCfg(QualityCfg,Widgets,Params)
end

function CommonUtil.SetItemIconShow(ItemId,IconWidget)
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not ItemCfg then
        return
    end
    if ItemCfg[Cfg_ItemConfig_P.IconPath] ~= "" then
        IconWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(IconWidget,ItemCfg[Cfg_ItemConfig_P.IconPath],true)
    else
        IconWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

--[[
    根据ItemId获取对应大图Path，如果没有配置，则通过SetItemIconShow读取其IconPath
]]
function CommonUtil.SetItemImageShow(ItemId,IconWidget)
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not ItemCfg then
        return
    end
    if ItemCfg[Cfg_ItemConfig_P.ImagePath] ~= "" then
        IconWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(IconWidget,ItemCfg[Cfg_ItemConfig_P.ImagePath],true)
    else
        CommonUtil.SetItemIconShow(ItemId,IconWidget)
        --IconWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

--- 判断是否是英雄角色面板类型
function CommonUtil.CheckIsHeroBackgroundType(ItemId)
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
    if ItemCfg then
        if ItemCfg[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER and 
        (ItemCfg[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Background or 
        ItemCfg[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Pose or 
        ItemCfg[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Effect) 
        then
            return true
        else
            return false
        end
    end
    return false
end

---为角色面板制造数据
---@param Param table {HeroId:number, FloorId:number, RoleId:number, EffectId:number}
---@return table {HeroId:number, DisplayData:DisplayBoardNode}
function CommonUtil.MakeDisplayBoardNode(HeroId, Param)
    HeroId = HeroId or 0
    Param = Param or {}
    -- local EquippedFloorId = self.ModelHero:GetSelectedDisplayBoardFloorId(self.HeroId)
    -- local EquippedRoleId = self.ModelHero:GetSelectedDisplayBoardRoleId(self.HeroId)
    -- local EquippedEffectId = self.ModelHero:GetSelectedDisplayBoardEffectId(self.HeroId)

    local SlotToAchieveId = {}
    -- for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
    --     local AchieveId = self.ModelHero:GetSelectedDisplayBoardAchieveId(self.HeroId, Slot)
    --     SlotToAchieveId[Slot] = AchieveId
    -- end

    local SlotToStickerInfo = {}
    -- for Slot = 1, HeroDefine.STICKER_SLOT_NUM , 1 do
    --     ---@type LbStickerNode
    --     -- local StickerInfo = self.EditSlot2StickerMap[Slot]
    --     local StickerInfo = self.ModelHero:GetSelectedDisplayBoardSticker(self.HeroId, Slot)
    --     SlotToStickerInfo[Slot] = StickerInfo
    -- end

    ---@type DisplayBoardNode
    local DisplayData = {
        HeroId = Param.HeroId or 0,
        FloorId = Param.FloorId or 0,
        RoleId =  Param.RoleId or 0,
        EffectId = Param.EffectId or 0,
        SlotToAchieveId = SlotToAchieveId,
        SlotToStickerInfo = SlotToStickerInfo,
    }

    local Param = {
        HeroId = Param.HeroId or 0,
        DisplayData = DisplayData
    }

    return Param
end

function CommonUtil.SetQualityShowForQualityId(QualityId,Widgets,Params)
    Params = Params or {}
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,QualityId)
    CommonUtil.SetQualityShowForQualityCfg(QualityCfg,Widgets,Params)
end

function CommonUtil.SetQualityShowForQualityCfg(QualityCfg,Widgets,Params)
    if not QualityCfg then
        return
    end
    Params = Params or {}

    local HexColor = QualityCfg[Cfg_ItemQualityColorCfg_P.HexColor]
    -- 品质底色条
    if Widgets.QualityBar then
        Widgets.QualityBar:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushTintColorFromHex(Widgets.QualityBar, HexColor, Params.QualityBarOpacity or 1)
    end

    -- 圆形品质角标
    if Widgets.QualityIcon then
        local IconTexture = LoadObject(StringUtil.Format(QualityCfg[Cfg_ItemQualityColorCfg_P.CornerIconWithBg]..""))
        if IconTexture then
            Widgets.QualityIcon:SetBrushFromTexture(IconTexture)
        end
    end
    
    -- QualityLevelText 显示品质等级（罗马数字）的文本
    if Widgets.QualityLevelText then
        --注意!!! 显示品质等级（罗马数字）的文本, 这种方式已过期!!! 不要传 QualityLevelText 字段了QualityIcon 字段可以代替  QualityIcon +  QualityLevelText 的效果。
        Widgets.QualityLevelText:SetText(StringUtil.Format(QualityCfg[Cfg_ItemQualityColorCfg_P.Level]))
        Widgets.QualityLevelText:SetVisibility(UE.ESlateVisibility.Collapsed)
        CWaring("CommonUtil.SetQualityShowForQualityCfg(), Widgets.QualityLevelText is deserted !! ",true)
    end

    if Widgets.QualityText then
        CommonUtil.SetTextColorFromeHex(Widgets.QualityText, HexColor, Params.QualityTextOpacity or 1)
    end

    -- 品质背景框
    if Widgets.QualityBgIcon then
        local IconTexture = LoadObject(StringUtil.Format(QualityCfg[Cfg_ItemQualityColorCfg_P.DepotImgBg]..""))
        if IconTexture then
            Widgets.QualityBgIcon:SetBrushFromTexture(IconTexture)
        end
    end

    -- 品质竖条图
    if Widgets.QualityVerticalImg then
        local IconTexture = LoadObject(StringUtil.Format(QualityCfg[Cfg_ItemQualityColorCfg_P.VerticalBarImg]..""))
        if IconTexture then
            Widgets.QualityVerticalImg:SetBrushFromTexture(IconTexture)
        end
    end

    -- 品质竖条图
    if Widgets.CommonTipsBg then
        local IconTexture = LoadObject(StringUtil.Format(QualityCfg[Cfg_ItemQualityColorCfg_P.CommonTipsBg]..""))
        if IconTexture then
            Widgets.CommonTipsBg:SetBrushFromTexture(IconTexture)
        end
    end

    if Widgets.QualityColorImgs then
        for i, v in ipairs(Widgets.QualityColorImgs) do
            CommonUtil.SetBrushTintColorFromHex(v, HexColor, Params.QualityBarOpacity or 1)
        end
    end

    if Widgets.QualityColorTexts then
        for i, v in ipairs(Widgets.QualityColorTexts) do
            CommonUtil.SetTextColorFromeHex(v, HexColor, Params.QualityTextOpacity or 1)
        end
    end
end

-- 设置品质角标（带圆底）
function CommonUtil.SetQualityCornerIconWithBg(Widget,Quality)
    if not Widget then
        return
    end
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
    if not QualityCfg then
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(Widget,QualityCfg[Cfg_ItemQualityColorCfg_P.CornerIconWithBg])
end

-- 设置品质角标（不带圆底）
function CommonUtil.SetQualityCornerIconWithoutBg(Widget,Quality)
    if not Widget then
        return
    end
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
    if not QualityCfg then
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(Widget,QualityCfg[Cfg_ItemQualityColorCfg_P.CornerIcon])
end

-- 设置竖向品质底（用于英雄）
function CommonUtil.SetQualityBgVertical(Widget,Quality)
    if not Widget then
        return
    end
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
    if not QualityCfg then
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(Widget,QualityCfg[Cfg_ItemQualityColorCfg_P.BgImgVertical])
end

-- 设置横向向品质底（用于战备/载具）
function CommonUtil.SetQualityBgHorizontal(Widget,Quality)
    if not Widget then
        return
    end
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
    if not QualityCfg then
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(Widget,QualityCfg[Cfg_ItemQualityColorCfg_P.BgImgHorizontal])
end


--- 打乱源数组的顺序
---@param Array table
function CommonUtil.RandonTableList(Array)
    if not Array then
        return
    end

    local Ret = {}
    local Len = #Array
    while Len > 0 do
        local i = math.random(1, Len)
        table.insert(Ret, Array[i])
        Array[i] = Array[Len]
        Len = Len - 1
    end
    return Ret
end


function CommonUtil.Mysplit (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end


--[[
    形如(100700001,100700002,100700003),拆成数字数组
]]
function CommonUtil.SplitStringIdListToNumList(InputStringIdList)
    if InputStringIdList == nil or InputStringIdList == "" then 
        return {}
    end
    
    local IdList = {}
    local StringIdList = InputStringIdList:match("%((.-)%)")
    if StringIdList ~= nil and StringIdList ~= "" then 
        local List = StringIdList:gmatch("%d+")
        for Id in List do
            table.insert(IdList, tonumber(Id))
        end    
    end
    return IdList
end


--- 获取参数表的配置值
function CommonUtil.GetParameterConfig(ParameterCfg, DefaultValue)
    if not ParameterCfg then
        return DefaultValue
    end
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ParameterConfig,ParameterCfg.ParameterId)
    if not Cfg then
        -- body
        return DefaultValue
    end
    return Cfg.ParameterValue
end


-- 通过Id来获取List的前后Index，不单独使用
function CommonUtil.GetListIndex4Id(List, Id)
    for Idx, V in ipairs(List) do
        if V == Id then
            return Idx
        end
    end
    return 0
end

function CommonUtil.GetListNextIndex4Id(List, Id)
    local Idx = CommonUtil.GetListIndex4Id(List, Id)
    Idx = Idx + 1
    Idx = Idx <= #List and Idx or 1
    return Idx,List[Idx]
end

function CommonUtil.GetListPreIndex4Id(List, Id)
    local Idx = CommonUtil.GetListIndex4Id(List, Id)
    Idx = Idx - 1
    Idx = Idx > 0 and Idx or #List
    return Idx,List[Idx]
end

--[[
    向容器添加Child
    少创建多移除，仅适用于容器的子节点只有指定一种类型的情况
]]
function CommonUtil.AddChildToContainer(Container,Outter,ChildWBPPath,Count,Padding)
    local Index = 1
    local CurCount = Container:GetChildrenCount()
    local Diff = Count - CurCount
    if Diff < 0 then
        for Index = 1, -Diff do
            Container:RemoveChildAt(CurCount - Index - 1)
        end
    else
        local WidgetClass = UE.UClass.Load(ChildWBPPath)
        if WidgetClass then
            for Index = 1,Diff do
                local Widget = NewObject(WidgetClass, Outter)
                if Widget then
                    if Padding then
                        Widget.Padding.Left = Padding.Left
                        Widget.Padding.Top = Padding.Top
                        Widget.Padding.Right = Padding.Right
                        Widget.Padding.Bottom = Padding.Bottom
                        Widget:SetPadding(Widget.Padding)
                    end
                    Container:AddChild(Widget)
                end
            end
        end
    end
end

--[[
    大厅跳转页签
    TabKey： CommonConst.HL_PLAY
]]
function CommonUtil.SwitchHallTab(TabKey,TabParam)
    TabKey = TabKey or CommonConst.HL_PLAY
    local Param = {
        TabKey = TabKey,
        Param = TabParam,
    }
    MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.HALL_TAB_SWITCH,Param)
end

--[[
    设置FInputModeData
]]
function CommonUtil.SetInputModeData(LocalPC,InputModeData)
    if not InputModeData then
        CError("SetInputModeData InputModeData Error ",true)
        return
    end
    local InputModeType = InputModeData.InputModeType
    if not InputModeType then
        CError("SetInputModeData InputModeType Error ",true)
        return
    end
    LocalPC = LocalPC or UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    if InputModeType == UE.EInputModeType.UIOnly then
        UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(LocalPC,InputModeData.InWidgetToFocus,InputModeData.InMouseLockMode,InputModeData.bHideCursorDuringCapture,InputModeData.bFlushInput)
    elseif InputModeType == UE.EInputModeType.GameAndUI then
        UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(LocalPC,InputModeData.InWidgetToFocus,InputModeData.InMouseLockMode,InputModeData.bHideCursorDuringCapture,InputModeData.bFlushInput)
    elseif InputModeType == UE.EInputModeType.GameOnly then
        UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(LocalPC,InputModeData.InWidgetToFocus,InputModeData.InMouseLockMode,InputModeData.bHideCursorDuringCapture,InputModeData.bFlushInput)
    end
end

--[[
    尝试根据道具ID
    加载3D展示，并生产到当前持久关卡

    参数：
    SpawnParam = {
        ViewId
        Location
        Rotation
        Scale
        InstID
    }

    返回：
    成功返回Actor对象
    失败返回nil值
]]
function CommonUtil.TryShowAvatarInHallByItemId(ItemId,ShowParam)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    if not ShowParam then
        CWaring("TryShowAvatarInHallByItemId ShowParam nil")
        return
    end
    if not ShowParam.ViewID then
        CWaring("TryShowAvatarInHallByItemId ShowParam.ViewID nil")
        return
    end
    local ItemConfig = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId )
    if not ItemConfig then
        return
    end
    if not ShowParam.Scale then
        ShowParam.Scale = UE.FVector(1,1,1)
    end
    if not ShowParam.Location then
        ShowParam.Location = UE.FVector(0,0,0)
    end
    if not ShowParam.Rotation then
        ShowParam.Rotation = UE.FRotator(0, 0, 0)
    end
    if not ShowParam.InstID then
        ShowParam.InstID = 0
    end
    local Avatar = nil
    if ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER then 
        CWaring("OnShowAvator==================1")
        --角色/角色皮肤
        local HeroSkinConfig = nil
        local IsDisplayBoard = false
        if ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Hero then
            local SkinId = MvcEntry:GetModel(HeroModel):GetDefaultSkinIdByHeroId(ItemId)
            HeroSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.ItemId,SkinId)
        elseif ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Skin then
            HeroSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.ItemId,ItemId)
        elseif ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Background then
            IsDisplayBoard = true
        end
        local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
        if HallAvatarMgr == nil then
            return
        end
        if IsDisplayBoard then
            CWaring("OnShowAvator==================1-1")
            local  SpawnParam = {
                ViewID = ShowParam.ViewID,
                InstID = ShowParam.InstID,
                DisplayBoardID = ItemId,
                Location = ShowParam.Location,
                Rotation = ShowParam.Rotation,
                Scale = ShowParam.Scale
            }
            Avatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_DISPLAYBOARD, SpawnParam)
        else
            CWaring("OnShowAvator==================1-2")
            if not HeroSkinConfig then
                return
            end
            CWaring("OnShowAvator==================1-22")
            local SpawnHeroParam = {
                ViewID = ShowParam.ViewID,
                InstID = ShowParam.InstID,
                HeroId = HeroSkinConfig[Cfg_HeroSkin_P.HeroId],
                SkinID = HeroSkinConfig[Cfg_HeroSkin_P.SkinId],
                Location = ShowParam.Location,
                Rotation = ShowParam.Rotation,
                Scale = ShowParam.Scale
            }
            Avatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
            if Avatar ~= nil then				
                Avatar:OpenOrCloseCameraAction(false)
            end
        end
    elseif ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_WEAPON then
        --武器
        CWaring("OnShowAvator==================2")
        local WeaponSkinConfig = nil
        if ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Weapon then
            local SkinId = MvcEntry:GetModel(WeaponModel):GetWeaponDefaultSkinId(ItemId)
            WeaponSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.ItemId,SkinId)
        elseif ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Skin then
            WeaponSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.ItemId,ItemId)
        end
        local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
        if HallAvatarMgr == nil then
            return
        end
        if not WeaponSkinConfig then
            return
        end
        local SpawnHeroParam = {
            ViewID = ShowParam.ViewID,
            InstID = ShowParam.InstID,
            WeaponID = WeaponSkinConfig[Cfg_WeaponSkinConfig_P.WeaponId],
            SkinID = WeaponSkinConfig[Cfg_WeaponSkinConfig_P.SkinId],
            Location = ShowParam.Location,
            Rotation = ShowParam.Rotation,
            Scale = ShowParam.Scale
        }
        Avatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_WEAPON, SpawnHeroParam)
        if Avatar ~= nil then				
            Avatar:OpenOrCloseCameraAction(false)
        end
    elseif ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_VEHICLE then
        --载具
        CWaring("OnShowAvator==================3")
        local VehicleIdSkinConfig = nil
        if ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Vehicle then
            local SkinId = MvcEntry:GetModel(VehicleModel):GetVehicleDefaultSkinId(ItemId)
            VehicleIdSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig,Cfg_VehicleSkinConfig_P.ItemId,SkinId)
        elseif ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Skin then
            VehicleIdSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig,Cfg_VehicleSkinConfig_P.ItemId,ItemId)
        end
        local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
        if HallAvatarMgr == nil then
            return
        end
        if not VehicleIdSkinConfig then
            return
        end
        local SpawnVehicleParam = {
            ViewID = ShowParam.ViewID,
            InstID = ShowParam.InstID,
            VehicleID = VehicleIdSkinConfig[Cfg_VehicleSkinConfig_P.VehicleId],
            SkinID =  VehicleIdSkinConfig[Cfg_VehicleSkinConfig_P.SkinId],
            Location = ShowParam.Location,
            Rotation = ShowParam.Rotation,
            Scale = ShowParam.Scale
        }
        Avatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_VEHICLE, SpawnVehicleParam)
        if Avatar ~= nil then 
            Avatar:OpenOrCloseCameraAction(false)
            Avatar:OpenOrCloseAvatorRotate(false)
            Avatar:OpenOrCloseCameraMoveAction(false)
            Avatar:OpenOrCloseAutoRotateAction(false)
        end
    end
    return Avatar
end

--[[
    设置鼠标样式
    CursorType： GameConfig.CursorType
]]
function CommonUtil.SetCursorType(CursorType,Angle)
    -- CError("设置鼠标样式 CursorType = "..tostring(CursorType))
    if GameConfig.UseCursorType == CursorType then
        return
    end
    GameConfig.UseCursorType = CursorType
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_MouseCursorIconCfg,CursorType)
    if Cfg then
        local IconPath = Cfg[Cfg_MouseCursorIconCfg_P.IconPath]
        local Icon = LoadObject(IconPath)
        if Icon then
		    local UIManager = UE.UGUIManager.GetUIManager(_G.GameInstance)
            if UIManager then
                UIManager:SetCursorIconBrushByTexture(Icon)
                local TargetTransform = UE.FWidgetTransform()
                TargetTransform.Translation = UE.FVector2D(Cfg[Cfg_MouseCursorIconCfg_P.TranslationX] or 0, Cfg[Cfg_MouseCursorIconCfg_P.TranslationY] or 0)
                TargetTransform.Scale = UE.FVector2D(1, 1)
                TargetTransform.Angle = Angle or 0
                TargetTransform.Shear = UE.FVector2D(0, 0)
                CommonUtil.SetCursorTransform(TargetTransform)
            end
        end
    end
end

function CommonUtil.SetCursorTransform(TargetTransform)
    local UIManager = UE.UGUIManager.GetUIManager(_G.GameInstance)
    if UIManager then
        GameConfig.UseCursorTransform = TargetTransform
        UIManager:SetCursorRenderTransform(TargetTransform)
    end
end

function CommonUtil.SetCursorAngle(TargetAngle)
    local TargetTransform = GameConfig.UseCursorTransform or UE.FWidgetTransform()
    TargetTransform.Angle = TargetAngle or 0
    CommonUtil.SetCursorTransform(TargetTransform)
end

--- 根据ItemID获取原始ID与皮肤ID
---@param ItemID any
local function GetOriginalIDAndSkinID(InItemID)
    local ItemConfig = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, InItemID)
    if not ItemConfig then
        return nil
    end
    local OriginalID = InItemID
    local SkinID = InItemID
    --角色/角色皮肤
    if ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER then 
        if ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Hero then
            SkinID = MvcEntry:GetModel(HeroModel):GetDefaultSkinIdByHeroId(InItemID)
        elseif ItemConfig[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Skin then
            local HeroSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin, Cfg_HeroSkin_P.ItemId, InItemID)
            if HeroSkinConfig == nil then
                CError(string.format("GetOriginalIDAndSkinID:: Get Cfg_HeroSkin Failed !!! InItemID = [%s]", InItemID), true)
            else
                OriginalID = HeroSkinConfig and HeroSkinConfig[Cfg_HeroSkin_P.HeroId] or 0
            end
        end
        return OriginalID, SkinID
    end
    --武器
    if ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_WEAPON then
        if ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Weapon then
            SkinID = MvcEntry:GetModel(WeaponModel):GetWeaponDefaultSkinId(InItemID)
        elseif ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Skin then
            local WeaponSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig, Cfg_WeaponSkinConfig_P.ItemId, InItemID)
            if WeaponSkinConfig == nil then
                CError(string.format("GetOriginalIDAndSkinID:: Get Cfg_WeaponSkinConfig Failed !!! InItemID = [%s]", InItemID), true)
            else
                OriginalID = WeaponSkinConfig[Cfg_WeaponSkinConfig_P.WeaponId]
            end
        end
        return OriginalID, SkinID
    end
    --载具
    if ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_VEHICLE then
        if ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Vehicle then
            SkinID = MvcEntry:GetModel(VehicleModel):GetVehicleDefaultSkinId(InItemID)
        elseif ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Skin then
            local VehicleIdSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig, Cfg_VehicleSkinConfig_P.ItemId, InItemID)
            if VehicleIdSkinConfig == nil then
                CError(string.format("GetOriginalIDAndSkinID:: Get Cfg_VehicleSkinConfig Failed !!! InItemID = [%s]", InItemID), true)
            else
                OriginalID = VehicleIdSkinConfig[Cfg_VehicleSkinConfig_P.VehicleId]
            end
        end
        return OriginalID, SkinID
    end
    return OriginalID, SkinID
end

---构造一个 FWidgetTransform 结构体
---@param Translation UE.FVector2D
---@param Scale UE.FVector2D
---@param Angle number
---@param Shear UE.FVector2D
function CommonUtil.MakeFWidgetTransform(Translation, Scale, Angle, Shear)
    local RWTran = UE.FWidgetTransform()
    RWTran.Translation = Translation or UE.FVector2D(0, 0)
    RWTran.Scale = Scale or UE.FVector2D(1, 1)
    RWTran.Angle = Angle or 0
    RWTran.Shear = Shear or UE.FVector2D(0, 0)
    return RWTran
end

---@class RtShowTran 配置中获取的模型/图片的位置,旋转,缩放
---@field Pos UE.FVector 位置
---@field Rot UE.FRotator 旋转
---@field Scale UE.FVector 缩放
---@field RenderTran UE.FWidgetTransform 2D图片变换
---从配置中获取模型或图片的Transform信息,根据道具ID获取对应模型/icon的摆放 位置,旋转,缩放
---@param TransFormModuleID _G.ETransformModuleID.BP_SeasonPass.ModuleID 各自模块或界面ID.必传
---@param ItemID number 物品ID.必传
---@param InParam table:{DefPos:UE.FVector.模型位置, DefRot:UE.FRotator.模型旋转, DefScale:UE.FVector.模型缩放, DefRenderTran:UE.FWidgetTransform.图片默认参数} 代码给定的默认参数
---@return RtShowTran 配置中获取的模型/图片的位置,旋转,缩放
function CommonUtil.GetShowTranByItemID(TransformModuleID, ItemID, InParam)
    local ItemConfig = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemID)
    if not ItemConfig then
        CError(string.format("CommonUtil.GetShowTranByItemID:: Get ItemConfig Failed !!, TransformModuleID=[%s],ItemID=[%s]", TransformModuleID, ItemID), true)
        return {}
    end
    InParam = InParam or {}
    local ModuleID = TransformModuleID
    local ItemType = ItemConfig[Cfg_ItemConfig_P.Type]
    local ItemSubType = ItemConfig[Cfg_ItemConfig_P.SubType]
    -- 获取物品的原始ID与皮肤ID
    local OriginalID, SkinID = GetOriginalIDAndSkinID(ItemID)

    local SafeVecData = function(VecData, VecLen, DefaultVal)
        VecData = VecData or UE.TArray(0)
        DefaultVal = DefaultVal or 0
        local len = VecData:Length() 
        if len >= VecLen then
            return VecData
        end
        -- CWaring("CommonUtil.GetShowTranByItemID.SafeVecData:: 配置有问题!!!")
        -- local SafeVal = {}
        for idx = 1, VecLen, 1 do
            if idx <= len then
                -- SafeVal[idx] = VecData[idx]
            else
                -- SafeVal[idx] = DefaultVal
                VecData:Add(DefaultVal)
            end
        end
        -- return SafeVal
        return VecData
    end

    local FinalTran = {Pos = nil, Rot = nil, Scale = nil, RenderTran = nil}
    --TODO:获取基础Tran配置
    local BaseCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_TransformBaseCfg, {Cfg_TransformBaseCfg_P.ModuleID, Cfg_TransformBaseCfg_P.Type, Cfg_TransformBaseCfg_P.SubType}, {ModuleID, ItemType, ItemSubType})
    if BaseCfg == nil then
        if ItemSubType ~= "None" then
            BaseCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_TransformBaseCfg, {Cfg_TransformBaseCfg_P.ModuleID, Cfg_TransformBaseCfg_P.Type, Cfg_TransformBaseCfg_P.SubType}, {ModuleID, ItemType, "None"})    
        end
        if BaseCfg == nil then
            CWaring(string.format("CommonUtil.GetShowTranByItemID:: Get Cfg_TransformBaseCfg Failed !!! TransformModuleID=[%s],ItemID=[%s],ItemType=[%s],ItemSubType=[%s]", TransformModuleID, ItemID, ItemType, ItemSubType))
            FinalTran.Pos = InParam.DefPos
            FinalTran.Rot = InParam.DefRot
            FinalTran.Scale = InParam.DefScale

            FinalTran.RenderTran = InParam.DefRenderTran  or UE.FWidgetTransform()
            return FinalTran
        end
    end
    local BaseTran = {Pos = {0, 0, 0}, Rot = {0, 0, 0}, Scale = {1, 1, 1}, Pos2D = {0, 0}, Rot2D = {0}, Scale2D = {1, 1}}
    --3D数据
    BaseTran.Pos = SafeVecData(BaseCfg[Cfg_TransformBaseCfg_P.Pos], 3, 0)
    BaseTran.Rot = SafeVecData(BaseCfg[Cfg_TransformBaseCfg_P.Rot], 3, 0)
    BaseTran.Scale = SafeVecData(BaseCfg[Cfg_TransformBaseCfg_P.Scale], 3, 1)
    --2D数据
    BaseTran.Pos2D = SafeVecData(BaseCfg[Cfg_TransformBaseCfg_P.Pos2D], 2, 0)
    BaseTran.Rot2D = SafeVecData(BaseCfg[Cfg_TransformBaseCfg_P.Rot2D], 1, 0)
    BaseTran.Scale2D = SafeVecData(BaseCfg[Cfg_TransformBaseCfg_P.Scale2D], 2, 1)

    --TODO:获取偏移配置
    local DetlaCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_TransformDeltaCfg,{Cfg_TransformDeltaCfg_P.ModuleID, Cfg_TransformDeltaCfg_P.SkinID}, {ModuleID, SkinID})
    if DetlaCfg == nil then
        DetlaCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_TransformDeltaCfg,{Cfg_TransformDeltaCfg_P.ModuleID, Cfg_TransformDeltaCfg_P.ItemID, Cfg_TransformDeltaCfg_P.SkinID}, {ModuleID, OriginalID, 0})
        if DetlaCfg == nil then
            DetlaCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_TransformDeltaCfg,{Cfg_TransformDeltaCfg_P.ModuleID, Cfg_TransformDeltaCfg_P.Type, Cfg_TransformDeltaCfg_P.SubType}, {ModuleID, ItemType, ItemSubType})
            if DetlaCfg == nil then
                if ItemSubType ~= "None" then
                    DetlaCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_TransformDeltaCfg,{Cfg_TransformDeltaCfg_P.ModuleID, Cfg_TransformDeltaCfg_P.Type, Cfg_TransformDeltaCfg_P.SubType}, {ModuleID, ItemType, "None"})
                end
                if DetlaCfg == nil then
                    CWaring(string.format("CommonUtil.GetShowTranByItemID:: Get Cfg_TransformDeltaCfg Failed !!! TransformModuleID=[%s],ItemID=[%s],ItemType=[%s],ItemSubType=[%s],OriginalID=[%s],SkinID=[%s]", TransformModuleID, ItemID, ItemType, ItemSubType, OriginalID, SkinID))    
                end
            end
        end
    end
    local DetlaTran = nil
    if DetlaCfg then
        DetlaTran = {DtPos = nil, DtRot = nil, DtScale = nil, DtPos2D = nil, DtRot2D = nil, DtScale2D = nil}
        --3D数据-配置
        DetlaTran.DtPos = SafeVecData(DetlaCfg[Cfg_TransformDeltaCfg_P.DtPos], 3, 0)
        DetlaTran.DtRot = SafeVecData(DetlaCfg[Cfg_TransformDeltaCfg_P.DtRot], 3, 0)
        DetlaTran.DtScale = SafeVecData(DetlaCfg[Cfg_TransformDeltaCfg_P.DtScale], 3, 0)
        --2D数据-配置
        DetlaTran.DtPos2D = SafeVecData(DetlaCfg[Cfg_TransformDeltaCfg_P.DtPos2D], 2, 0)
        DetlaTran.DtRot2D = SafeVecData(DetlaCfg[Cfg_TransformDeltaCfg_P.DtRot2D], 1, 0)
        DetlaTran.DtScale2D = SafeVecData(DetlaCfg[Cfg_TransformDeltaCfg_P.DtScale2D], 2, 0)
    else
        DetlaTran = {DtPos = {0, 0, 0}, DtRot = {0, 0, 0}, DtScale = {0, 0, 0}, DtPos2D = {0, 0}, DtRot2D = {0}, DtScale2D = {0, 0}}
    end

    --TODO:计算最终数据
    FinalTran.Pos = UE.FVector(BaseTran.Pos[1] + DetlaTran.DtPos[1], BaseTran.Pos[2] + DetlaTran.DtPos[2], BaseTran.Pos[3] + DetlaTran.DtPos[3])
    FinalTran.Rot = UE.FRotator(BaseTran.Rot[1] + DetlaTran.DtRot[1], BaseTran.Rot[2] + DetlaTran.DtRot[2], BaseTran.Rot[3] + DetlaTran.DtRot[3])
    FinalTran.Scale = UE.FVector(BaseTran.Scale[1] + DetlaTran.DtScale[1], BaseTran.Scale[2] + DetlaTran.DtScale[2], BaseTran.Scale[3] + DetlaTran.DtScale[3])

    FinalTran.RenderTran = UE.FWidgetTransform()
    FinalTran.RenderTran.Translation = UE.FVector2D(BaseTran.Pos2D[1] + DetlaTran.DtPos2D[1], BaseTran.Pos2D[2] + DetlaTran.DtPos2D[2])
    FinalTran.RenderTran.Scale = UE.FVector2D(BaseTran.Scale2D[1] + DetlaTran.DtScale2D[1], BaseTran.Scale2D[2] + DetlaTran.DtScale2D[2]) 
    FinalTran.RenderTran.Angle = BaseTran.Rot2D[1] + DetlaTran.DtRot2D[1]

    return FinalTran
end

-- 根据自定义规则替换文本参数内容
function CommonUtil.FixCustomText(Text)
    local Pattern = "{CT.([^{}]+)%.(.-)}"

    local function PatchError(ErrorStr,Text,args)
        local ArgStr = ""
        if type(args) == "table" then
            for _,arg in ipairs(args) do
                ArgStr = ArgStr..","..arg
            end
        elseif type(args) == "string" then
            ArgStr = args
        end
        CError(ErrorStr..ArgStr,true)
        return string.gsub(Text,Pattern,"",1)   
    end

    for Key,Value in string.gmatch(Text,Pattern) do
        if Key == "TimeStamp" then
            -- 时间戳处理 {CT.TimeStamp.1715051324}
            local DateStr = TimeUtils.GetDateTimeStrFromTimeStamp(tonumber(Value))
            Text = string.gsub(Text,Pattern,DateStr,1)
        elseif Key == "TextId" then
            --  固定用配置的ID取 MiscTextConfig.xlsx 中的Des字段
            local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_MiscTextConfig,tonumber(Value))
            if Cfg then
                Text = string.gsub(Text,Pattern,Cfg[Cfg_MiscTextConfig_P.Des],1)
            else
                Text = PatchError("Patch Custom Text For TextId Error: ",Text, Value)
            end
        -- elseif Key == "" then
        -- todo 后续有新增自定义规则再往下拓展
        elseif G_CfgName2MainKey[Key] then
            -- 配置表处理
            if string.find(Value,"#") then
                local Params = string.split(Value,"#")
                if #Params == 2 then
                    local CfgKey = Params[1]
                    local TargetKey = Params[2]
                    if string.find(CfgKey,"|") then
                        -- 取指定key
                        local KeyParams = string.split(CfgKey,"|")
                        local CfgKeys = KeyParams[1]
                        local CfgValues = KeyParams[2]
                        if string.find(CfgKeys,",") then
                            -- 多Key模式 {CT.NarrativeCfg.Id,TabId|103,1#ContentName}
                            CfgKeys = string.split(CfgKeys,",")
                            CfgValues = string.split(CfgValues,",")
                        else
                            -- 单Key模式 {CT.HeroSkin.SkinId|200010003#SkinName}
                            CfgKeys = {CfgKeys}
                            CfgValues = {CfgValues}
                        end
                        if CfgKeys and CfgValues and #CfgKeys == #CfgValues then
                            for Index,CfgValue in ipairs(CfgValues) do
                                CfgValues[Index] = tonumber(CfgValue) or CfgValue
                            end
                            local Cfg = G_ConfigHelper:GetSingleItemByKeys(Key,CfgKeys,CfgValues)
                            if Cfg and Cfg[TargetKey] then
                                Text = string.gsub(Text,Pattern,Cfg[TargetKey],1)
                            else
                                Text = PatchError("Patch Custom Text For Cfg By Keys Error: ",Text, CfgKeys)
                            end
                        else
                            Text = PatchError("Patch Custom Text For Cfg By Keys Number Not Equal To Values Number: ",Text, CfgKeys)
                        end
                    else
                        -- 取MainKey {CT.HeroConfig.200010000#Name}
                        CfgKey = tonumber(CfgKey) or CfgKey
                        local Cfg = G_ConfigHelper:GetSingleItemById(Key,CfgKey)
                        if Cfg and Cfg[TargetKey] then
                            Text = string.gsub(Text,Pattern,Cfg[TargetKey],1)
                        else
                            Text = PatchError("Patch Custom Text For Cfg By Id Error: ",Text, CfgKey)
                        end
                    end
                else
                    Text = PatchError("Patch Custom Text For Cfg Param Number Error: ",Text,Value)
                end
            else
                Text = PatchError("Patch Custom Text For Cfg Without TargetKey: ",Text, {Key,Value})
            end    
        else
            Text = PatchError("Can't Patch Any Custom Text Rule: ",Text,Key)
        end
    end
    return Text
end

-- 设置图片类型角标
function CommonUtil.SetCornerTagImg(Img,TagId)
    if not Img or not(CommonUtil.IsValid(Img)) then
        CError("SetCornerTagImg Need Img",true)
        return
    end
    Img:SetVisibility(UE.ESlateVisibility.Collapsed)
    if not TagId then
        return
    end
    local CornerTagCfg = G_ConfigHelper:GetSingleItemById(Cfg_CornerTagCfg,TagId)
    if not CornerTagCfg then
        return
    end
    Img:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonUtil.SetBrushFromSoftObjectPath(Img,CornerTagCfg[Cfg_CornerTagCfg_P.TagImg])
end

-- 设置英雄头像类型角标
function CommonUtil.SetCornerTagHeroHead(BgImg,HeroHeadImg,HeroId,SkinId)
    if not (BgImg and HeroHeadImg) or not(CommonUtil.IsValid(BgImg)) or not(CommonUtil.IsValid(HeroHeadImg)) then
        CError("SetCornerTagWord Need BgImg and HeroHeadImg",true)
        return
    end
    BgImg:SetVisibility(UE.ESlateVisibility.Collapsed)
    HeroHeadImg:SetVisibility(UE.ESlateVisibility.Collapsed)
    if not HeroId then
        return
    end
    if not SkinId then
        SkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(HeroId)
    end
    if SkinId == 0 then
        return
    end
    local CornerTagCfg = G_ConfigHelper:GetSingleItemById(Cfg_CornerTagCfg,CornerTagCfg.HeroBg.TagId)
    if not CornerTagCfg then
        return
    end
    local HeroSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,SkinId)
    if not HeroSkinCfg then
        return
    end
    local HeadImgPath = HeroSkinCfg[Cfg_HeroSkin_P.PNGPathAnomaly]
    if HeadImgPath == "" then
        return
    end
    BgImg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    HeroHeadImg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonUtil.SetBrushFromSoftObjectPath(BgImg,CornerTagCfg[Cfg_CornerTagCfg_P.TagImg])
    CommonUtil.SetBrushFromSoftObjectPath(HeroHeadImg,HeadImgPath)
end

-- 设置文字类型角标
function CommonUtil.SetCornerTagWord(BgImg,WordText,WordId)
    if not (BgImg and WordText) or not(CommonUtil.IsValid(BgImg)) or not(CommonUtil.IsValid(WordText)) then
        CError("SetCornerTagWord Need BgImg and WordText",true)
        return
    end
    BgImg:SetVisibility(UE.ESlateVisibility.Collapsed)
    WordText:SetVisibility(UE.ESlateVisibility.Collapsed)
    if not WordId then
        return
    end
    local CornerTagWordCfg = G_ConfigHelper:GetSingleItemById(Cfg_CornerTagWordCfg,WordId)
    if not CornerTagWordCfg then
        return
    end
    BgImg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    WordText:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    WordText:SetText(StringUtil.Format(CornerTagWordCfg[Cfg_CornerTagWordCfg_P.WordText]))
    local ColorHex = CornerTagWordCfg[Cfg_CornerTagWordCfg_P.WordColor]
    CommonUtil.SetTextColorFromeHex(WordText,ColorHex)
    CommonUtil.SetImageColorFromHex(BgImg,ColorHex)
end


--设置通用的WBP_Common_Name的信息
--[[
    Param = {
        ItemId
        ItemName
        bCancelQuality
    }
]]
function CommonUtil.SetCommonName(WBP_Common_Name, Param)
    if WBP_Common_Name == nil or Param == nil then
        return
    end
    
    WBP_Common_Name.TextBlock_Name:SetText(Param.ItemName)

    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,Param.ItemId)
    if not(Param.bCancelQuality) and CfgItem then
        CommonUtil.SetQualityCornerIconWithoutBg(WBP_Common_Name.Img_Quality, CfgItem[Cfg_ItemConfig_P.Quality])
    end
end

--[[
    Lua的Sort是快排，不稳定
    这个方法是进行稳定排序，但会产生table的拷贝性能消耗,返回的是拷贝的副本列表
    注：！！ SortFunc给到的参数是IndexA和IndexB
]]
function CommonUtil.StableSort(List,SortFunc)
    if not List or #List == 0 then
        CError("CommonUtil.StableSort Need List")
        return List
    end
    if not SortFunc then
        CError("CommonUtil.StableSort Need SortFunc")
        return List
    end
    local Indices = {}
    for I = 1, #List do
        Indices[I] = I
    end
    table.sort(Indices,SortFunc)
    local TempList = {}
    for I = 1, #List do
        TempList[I] = DeepCopy(List[Indices[I]])
    end
    return TempList
end

---获取购买花费描述的Text
-- 确定要花 {0}{1} 解锁吗？
-- 确定要花 {0}{1} 购买吗？
---@param BuyType CommonConst.BuyType
function CommonUtil.GetBuyCostDescribeText(CurrencyType, Cost, BuyType)
    BuyType = BuyType or CommonConst.BuyType.DEFAULT
    local describe = ""
    if BuyType == CommonConst.BuyType.UNLOCK then
        -- describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Arsenal", "10009"), StringUtil.GetRichTextImgForId(CurrencyType), Cost) --确定要花{0}{1}，进行解锁吗？
        describe = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_Areyousureyouwanttou"),StringUtil.GetRichTextImgForId(CurrencyType), Cost) --确定要花 {0}{1} 解锁吗？
    else
        --是否消耗{0}{1}购买？
        -- describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop","ConfirmToBuy"),StringUtil.GetRichTextImgForId(Param.ItemId), Param.Cost)

        -- 确定要花 {0}{1} 购买吗？
        describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_SureWantToBuy"), StringUtil.GetRichTextImgForId(CurrencyType), Cost)
    end
  
    return describe
end

--根据道具ID获取所属者名称
---@return string|nil 返回string类型，如果没有找到则返回nil
function CommonUtil.GetOwnershipNameByItemID(ItemID)
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemID)
    if not CfgItem then
        return nil
    end
    local HeroID = 0
    if CfgItem[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER then
        if CfgItem[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Skin then
            local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.ItemId, ItemID)
            HeroID = Cfg and Cfg[Cfg_HeroSkin_P.HeroId] or 0
        elseif CfgItem[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Background then
            local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayFloor,Cfg_HeroDisplayFloor_P.ItemId, ItemID)
            HeroID = Cfg and Cfg[Cfg_HeroDisplayFloor_P.HeroId] or 0
        elseif CfgItem[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Effect then
            local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayEffect,Cfg_HeroDisplayEffect_P.ItemId, ItemID)
            HeroID = Cfg and Cfg[Cfg_HeroDisplayEffect_P.HeroId] or 0
        elseif CfgItem[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Pose then
            local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayRole,Cfg_HeroDisplayRole_P.ItemId, ItemID)
            HeroID = Cfg and Cfg[Cfg_HeroDisplayRole_P.HeroId] or 0
        elseif CfgItem[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Sticker then
            local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplaySticker,Cfg_HeroDisplaySticker_P.ItemId, ItemID)
            HeroID = Cfg and Cfg[Cfg_HeroDisplaySticker_P.HeroId] or 0
        end
        
        local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,HeroID)
        return CfgHero and CfgHero[Cfg_HeroConfig_P.Name] or nil
    elseif CfgItem[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_WEAPON then
        local WeaponID = 0
        if CfgItem[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Skin then
            local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.ItemId, ItemID)
            WeaponID = Cfg and Cfg[Cfg_WeaponSkinConfig_P.WeaponId] or 0
        end
        local CfgWeapon = G_ConfigHelper:GetSingleItemById(Cfg_WeaponConfig,WeaponID)
        return CfgWeapon and CfgWeapon[Cfg_WeaponConfig_P.Name] or nil
    elseif CfgItem[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_VEHICLE then
        local VehicleID = 0
        if CfgItem[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Skin then
            local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig,Cfg_VehicleSkinConfig_P.ItemId, ItemID)
            VehicleID = Cfg and Cfg[Cfg_VehicleSkinConfig_P.VehicleId] or 0
        end
        local CfgVehicle = G_ConfigHelper:GetSingleItemById(Cfg_VehicleConfig,VehicleID)
        return CfgVehicle and CfgVehicle[Cfg_VehicleConfig_P.Name] or nil
    end
    
end