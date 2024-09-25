--
-- Object Base
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.01.17
--

if GameLog then GameLog.AddToBlackList("ObjectBase") end

local ObjectBase = Class()


-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Override ------------------------------------

-------------------------------------------- Init/Destroy ------------------------------------

function ObjectBase:ctor(...)
	print("ObjectBase", ">> ctor, ...")
    
end

function ObjectBase:Init(...)
	print("ObjectBase", ">> Init, ...")

    self:OnInit(...)
end

function ObjectBase:Destroy(...)
	print("ObjectBase", ">> Destroy, ...")

    self:OnDestroy(...)
end

-------------------------------------------- Get/Set ------------------------------------

function ObjectBase:GetName()
    return self.__cname
end

function ObjectBase:IsInited()
    return self.bIsInited
end

-------------------------------------------- Function ------------------------------------

function ObjectBase:OnInit(...)
	print("ObjectBase", ">> OnInit, ...")
    --Dump()
    
	-- { { UDelegate = self.Btnxxx.OnClicked, Func = ObjectBase.OnClicked_xxx }, ... }
    --self.BindNodes = {}

    -- { { MsgName = MsgDefine.xxx,	Func = self.On_xxx, bCppMsg = false }, ... }
    --self.MsgList = {}

    -- 注册节点监听
    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, true)
    end
    -- 注册消息监听
    if self.MsgList then
	    MsgHelper:RegisterList(self, self.MsgList)
    end

    self.bIsInited = true
end

function ObjectBase:OnDestroy(...)
	print("ObjectBase", ">> OnDestroy, ...")

    -- 注销节点监听
	if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, false)
		self.BindNodes = nil
	end
    -- 注销消息监听
	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end
    
    self.bIsInited = false
end

return ObjectBase
