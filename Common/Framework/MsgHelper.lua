--
-- 消息
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2021.12.13
--

require ("UnLua")

local MsgHelper = _G.MsgHelper or BaseClass(nil,"MsgHelper")

function MsgHelper:__init()
	print(">> MsgHelper:Init, ...")

	--[[ self.MsgLists = {
		MsgName1 = { { Obj = BindObject, Func = BindFunc, bCppMsg = false,	WatchedObject = nil }, ... },
		MsgName2 = { { Obj = BindObject, Func = BindFunc, bCppMsg = true,	WatchedObject = xxx }, ... },
		...
	}]]
	self.MsgLists = {}
end

function MsgHelper:__dispose()
	print(">> MsgHelper:Destroy, ...")

	self.MsgLists = nil
end

-------------------------------------------- Function ------------------------------------

-- 注册监听
function MsgHelper:Register(InMsgName, InBindObject, InBindFunc, bCppMsg, InWatchedObject)
	if (not InMsgName) or (InMsgName == "") or ((not InBindObject) and (not InBindFunc)) then
		print(">>\t MsgHelper:Register Failed! ", InMsgName, ToObjName(InBindObject) , InBindObject, InBindFunc)
		return
	end

	-- 是否为C++消息绑定
	if bCppMsg then
		if 'userdata' == type(InBindObject.Object) then
			local Handle, CbIndex = ListenObjectMessage(InWatchedObject, InMsgName, InBindObject, InBindFunc)
			print(">>\t MsgHelper:Register[Cpp], ", InMsgName, ToObjName(InBindObject) , InBindObject, InBindFunc, Handle, CbIndex)
			return Handle, CbIndex
		end
		print_r(InBindObject)
		print(type(InBindObject))
		Error(">>\t MsgHelper:Register[Cpp], InBindObject is invalid!!!", InMsgName, ToObjName(InBindObject), InBindObject, InBindFunc,type(InBindObject.Object))
		return
	end

	-- TODO: Filter InBindObject or InBindFunc

	if not self.MsgLists[InMsgName] then self.MsgLists[InMsgName] = {} end
	
	print(">>\t MsgHelper:Register[Lua], ", InMsgName, ToObjName(InBindObject), InBindObject, InBindFunc)
	table.insert(self.MsgLists[InMsgName], { Object = InBindObject, Func = InBindFunc })
end

-- 注销监听
function MsgHelper:Unregister(InMsgName, InBindObject, InBindFunc, bCppMsg, InHandle)
	if (not InMsgName) or (InMsgName == "") or ((not InBindObject) and (not InBindFunc)) then
		print(">>\t MsgHelper:Unregister Failed! ", InMsgName, ToObjName(InBindObject) , InBindObject, InBindFunc)
		return
	end

	-- 是否为C++消息绑定
	if bCppMsg then
		if 'userdata' == type(InBindObject.Object) then
			print(">>\t MsgHelper:Unregister[Cpp], ", InMsgName, ToObjName(InBindObject), InBindObject, InBindFunc, InHandle)
			UnListenObjectMessage(InMsgName, InBindObject, InHandle)
			return
		end
		Error(">>\t MsgHelper:Unregister[Cpp], InBindObject is invalid!!!", InMsgName, ToObjName(InBindObject), InBindObject, InBindFunc)
		return
	end

	--print(">> MsgHelper:Unregister[Doing], ", InMsgName, InBindObject, InBindFunc, self.MsgLists[InMsgName])
	for MsgIdx, MsgContext in pairs(self.MsgLists[InMsgName] or {}) do
		--if (MsgContext.Object == InBindObject) and (MsgContext.Func == InBindFunc) then
		if (MsgContext.Object == InBindObject) or (MsgContext.Func == InBindFunc) then
			print(">>\t MsgHelper:Unregister[Lua], ", MsgIdx, InMsgName, ToObjName(MsgContext.Object), MsgContext.Func)
			table.remove(self.MsgLists[InMsgName], MsgIdx)
		end
	end
end

-- 发送消息
function MsgHelper:Send(InSender, InMsgName, InMsgBody, bNoPrintLog)
	if (not InMsgName) or (InMsgName == "") or (not self.MsgLists[InMsgName]) then
		return
	end
	
	local MsgContexts = self.MsgLists[InMsgName]
	for MsgIdx, MsgContext in pairs(MsgContexts) do
		if MsgContext.Func then
			if (not bNoPrintLog) then
				print(">>\t MsgHelper:Send, ", MsgIdx, InMsgName, ToObjName(MsgContext.Object), MsgContext.Func)
			end

			if MsgContext.Object then
				if (not InSender) or
				   (InSender.GetWorld and MsgContext.Object.GetWorld and
				   (InSender:GetWorld() == MsgContext.Object:GetWorld())) then
					local ErrorTypeStr = StringUtil.FormatSimple("MsgHelper Send1 failed with InMsgName:{0} ObjName:{1}",InMsgName,ToObjName(MsgContext.Object))
					local ok = EnsureCall(ErrorTypeStr,MsgContext.Func, MsgContext.Object, InMsgBody)
					if not ok then
						Error("MsgHelper", ">> Send[1], Fail! ", MsgIdx, InMsgName, ToObjName(MsgContext.Object), MsgContext.Func)
						Dump("MsgHelper, >> Send[1], Fail! ", MsgContext.Object, 9)
					end
				end
			else
				local ErrorTypeStr = StringUtil.FormatSimple("MsgHelper Send2 failed with InMsgName:{0}",InMsgName)
				local ok = EnsureCall(ErrorTypeStr,MsgContext.Func, InMsgBody)
				if not ok then
					Error("MsgHelper", ">> Send[2], Fail! ", MsgIdx, InMsgName, MsgContext.Func)
					Dump("MsgHelper, >> Send[2], Fail! ", MsgContext.Object, 9)
				end
			end
		end
	end
end

-- 发送消息Cpp
function MsgHelper:SendCpp(InSender, InMsgName, ...)
	--print(">> MsgHelper:SendCpp, ", InSender, InMsgName, ...)

	NotifyObjectMessage(InSender, InMsgName, ...)
end

--[[
	注册/注销多条消息
	InBindObject
	InMsgList = {
		{ MsgName = xxx, Func = self.On_xxx, bCppMsg = false },
		...
	}
]]
function MsgHelper:RegisterList(InBindObject, InMsgList)
	--print(">> MsgHelper:RegisterList, ", InBindObject, InMsgList)
	
	for _, MsgElem in ipairs(InMsgList) do
		local Handle, CbIndex = self:Register(MsgElem.MsgName, InBindObject, MsgElem.Func, MsgElem.bCppMsg, MsgElem.WatchedObject)
		MsgElem.Handle = Handle
		--print(">>>>> MsgHelper:RegisterList, ", MsgElem.MsgName, InBindObject, MsgElem.bCppMsg, MsgElem.Handle, MsgElem.WatchedObject, Handle, CbIndex)
	end
end
function MsgHelper:UnregisterList(InBindObject, InMsgList)
	--print(">> MsgHelper:UnregisterList, ", InBindObject, InMsgList)

	for _, MsgElem in ipairs(InMsgList) do
		self:Unregister(MsgElem.MsgName, InBindObject, MsgElem.Func, MsgElem.bCppMsg, MsgElem.Handle)
	end
end

-- 
function MsgHelper:ReleaseInvalidObject()
	print(">> MsgHelper:ReleaseInvalidObject[Begin], ...")
	
	for MsgName, MsgContexts in pairs(self.MsgLists or {}) do
		for MsgIdx, MsgContext in pairs(MsgContexts) do
			local UObject = MsgContext.Object and MsgContext.Object.Object or nil
			if UObject and (not UE.UKismetSystemLibrary.IsValid(UObject)) then
				table.remove(self.MsgLists[MsgName], MsgIdx)
			end
		end
	end
end

-------------------------------------------- Delete ------------------------------------

-- 注册/注销 多播委托
--[[
	InBindObject:	UObject
	InNodeList:		{ { UDelegate = self.Btnxxx.OnClicked, Func = self.OnClicked_xxx }, ... }
	bAddDelegate:	添加/移除
]]
function MsgHelper:OpDelegateList(InBindObject, InNodeList, bAddDelegate)
    if (not InBindObject) or (not InNodeList) then return end
	if not UE.UKismetSystemLibrary.IsValid(InBindObject) then
        print_trackback()
        return
    end
	for _, Node in ipairs(InNodeList) do
		if Node.UDelegate and Node.Func then
			if bAddDelegate then
				Node.UDelegate:Add(InBindObject, Node.Func)
			else
				Node.UDelegate:Remove(InBindObject, Node.Func)
			end
		end
	end
end


-- 注册/注销 单播委托
--[[
	InBindObject:	UObject
	InNodeList:		{ { UDelegate = self.Btnxxx.OnClicked, Func = self.OnClicked_xxx }, ... }
	bAddDelegate:	添加/移除
]]
function MsgHelper:OpUniDelegateList(InBindObject, InNodeList, bAddDelegate)
    if (not InBindObject) or (not InNodeList) then return end
	if not UE.UKismetSystemLibrary.IsValid(InBindObject) then
        print_trackback()
        return
    end
	for _, Node in ipairs(InNodeList) do
		if Node.UDelegate and Node.Func then
			if bAddDelegate then
				Node.UDelegate:Bind(InBindObject, Node.Func)
			else
				Node.UDelegate:Unbind()
			end
		end
	end
end

-------------------------------------------- Debug ------------------------------------

function MsgHelper.Print()
	local self = MsgHelper
	print(">> MsgHelper:Print, ...")

	for MsgName, MsgContexts in pairs(self.MsgLists) do
		for MsgIdx, MsgContext in pairs(MsgContexts) do
			print(">>\t MsgHelper:Print, ", MsgName, MsgIdx, ToObjName(MsgContext.Object), MsgContext.Func)
		end
	end

	--Dump(self, self, 5)
end


return MsgHelper
