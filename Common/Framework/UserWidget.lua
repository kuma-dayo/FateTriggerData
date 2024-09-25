--
-- UserWidget
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2021.12.13
--

if GameLog then GameLog.AddToBlackList("UserWidget") end

--assert(ObjectBase, ">> UserWidget, ObjectBase is nil!!!")

local UserWidget = Class("Common.Framework.ObjectBase")

-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Override ------------------------------------
--[[
	生命周期
	Construct
	OnInit
	OnShow
	OnClose
	Destruct
	OnDestroy
]]
function UserWidget:Construct()
	print("UserWidget", ">> Construct, ", GetObjectName(self))

	--[[
	self.VarWhitelist = {}
	self.UserWidget = nil
	self.PathWidget = nil
	self.BindScript = nil

	self.bCloseDestroy = false
	self.bCanCloseByEsc = false
	self.bIsCloseManually = false
	
	self.UELevelName = UELevelNameEnum.F
	self.UIViewZOrder = UIZOrderEnum.F1
	]]

    --self.Overridden.Construct(self)
	self.IsConstruct = true
	self.IsDisposeUI = false
	self:DataInitInner()
	self:OnInit()
	self:ShowUIByNodeConstruct()
end

function UserWidget:DataInitInner()
	--注册ShowUI和DisposeUI的回调
	self.ShowUICallBackList = {}
	self.DisposeUICallBackList = {}
	self.DestructUICallBackList = {}
end

function UserWidget:Destruct()
	print("UserWidget", ">> Destruct, ", GetObjectName(self))

    --self.Overridden.Destruct(self)
	if  self.IsConstruct then
		self:DisposeUIByNodeDestruct()
	else
		-- 防止有子类继承，但覆盖了Construct，没有调用Super
		CError("UserWidget: Not Construct! Please Check Is Override :" ..  GetObjectName(self),true)
	end
	self:OnDestroy()
end

-------------------------------------------- Init/Destroy ------------------------------------

--
function UserWidget:OnInit()
	print("UserWidget", ">> OnInit, ", GetObjectName(self))
	--Dump(self, self, 9)
	ObjectBase.OnInit(self)
end

--
function UserWidget:OnDestroy()
	print("UserWidget", ">> OnDestroy, ", GetObjectName(self))

	ObjectBase.OnDestroy(self)

	--self:Destroy()			-- 释放引用(Lua)	LuaLib_Object.Destroy
	--self:RemoveFromViewport()	-- 强制移除(UObject)
	--self:Release()			-- 释放引用(Lua)

	self.VarWhitelist = self.VarWhitelist or {}
	for Key, Value in pairs(self) do
		if ('Object' ~= Key) and ('Super' ~= Key) and ('function' ~= type(Value)) then
			if ('VarWhitelist' ~= Key) and (not self.VarWhitelist[Key]) then
				self[Key] = nil
			end
		end
	end
end

-------------------------------------------- OnShow/OnClose ------------------------------------
function UserWidget:OnShow()
	self:ShowUIByOnShow()
end

function UserWidget:OnClose()
	self:DisposeUIByOnClose()
end

-------------------------------------------- Get/Set ------------------------------------

-------------------------------------------- Function ------------------------------------

-- 添加设置ZOrder
function UserWidget:AddToViewportImpl(InZOrder)
	self:AddToViewport(InZOrder or self.UIViewZOrder)
end

-------------------------------------------- Callable ------------------------------------

-------------------------------------------- Show/Close ------------------------------------

function UserWidget:ShowUIByNodeConstruct()
	-- CWaring("UserWidget:ShowUIByNodeConstruct:" ..  GetObjectName(self))
	self:ShowUIInner(true)
end
function UserWidget:ShowUIByOnShow()
	-- CWaring("UserWidget:ShowUIByOnShow:" ..  GetObjectName(self))
	if not self.IsDisposeUI then
		return
	end
	self:ShowUIInner()
end

function UserWidget:DisposeUIByNodeDestruct()
	-- CWaring("UserWidget:DisposeUIByNodeDestruct:" ..  GetObjectName(self))
	self:DisposeUIInner()
	self:DestructUIInner()
end

function UserWidget:DisposeUIByOnClose()
	-- CWaring("UserWidgetBase:DisposeUIByOnClose:" ..  GetObjectName(self))
	self:DisposeUIInner()
end


--[[
	显示UI的详细逻辑
]]
function UserWidget:ShowUIInner(IsInit)
	if not IsInit and self.IsDisposeUI == false then
		CError("UserWidget:ShowUIInner Repeat ShowUIInner:" ..  GetObjectName(self),true)
		return
	end
	self.IsDisposeUI = false
	if not IsInit then
		if not self.ShowUICallBackList then
			self.ShowUICallBackList = {}
			CError("UserWidget: ShowUICallBackList nil",true)
		end
		for _,V in pairs(self.ShowUICallBackList) do
			V()
		end
	end
end


--[[
	不显示UI的详细逻辑
]]
function UserWidget:DisposeUIInner()
	if self.IsDisposeUI then
		CWaring("UserWidget:DisposeUIInner IsDisposeUI true,So return:" ..  GetObjectName(self))
		return
	end
	self.IsDisposeUI = true
	if not self.DisposeUICallBackList then
		self.DisposeUICallBackList = {}
		CError("UserWidget: DisposeUICallBackList nil",true)
	end
	for _,V in pairs(self.DisposeUICallBackList) do
		V()
	end
end

function UserWidget:DestructUIInner()
	if not self.DestructUICallBackList then
		self.DestructUICallBackList = {}
		CError("UserWidget: DestructUICallBackList nil",true)
	end
	for _,V in pairs(self.DestructUICallBackList) do
		V()
	end
	self:DataInitInner()
end


--[[
	动态添加UI可用行为回调
]]
function UserWidget:RegisterShowUICallBack(Cb,Handler)
	if not self.ShowUICallBackList then
		self.ShowUICallBackList = {}
		CError("UserWidget: ShowUICallBackList nil",true)
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidget:RegisterShowUICallBack target:{0} source:{1} sourcename:{2}", GetObjectName(self),ClassId,HandlerViewName))
	self.ShowUICallBackList[ClassId] = Cb
end
function UserWidget:UnRegisterShowUICallBack(Handler)
	if not self.ShowUICallBackList then
		self.ShowUICallBackList = {}
		CError("UserWidget: ShowUICallBackList nil",true)
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidget:UnRegisterShowUICallBack target:{0} source:{1} sourcename:{2}", GetObjectName(self),ClassId,HandlerViewName))
	self.ShowUICallBackList[ClassId] = nil
end

--[[
	动态添加UI不可用行为回调
]]
function UserWidget:RegisterDisposeUICallBack(Cb,Handler)
	if not self.DisposeUICallBackList then
		self.DisposeUICallBackList = {}
		CError("UserWidget: DisposeUICallBackList nil",true)
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidget:RegisterDisposeUICallBack target:{0} source:{1} sourcename:{2}", GetObjectName(self),ClassId,HandlerViewName))
	self.DisposeUICallBackList[ClassId] = Cb
end
function UserWidget:UnRegisterDisposeUICallBack(Handler)
	if not self.DisposeUICallBackList then
		self.DisposeUICallBackList = {}
		CError("UserWidget: DisposeUICallBackList nil",true)
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidget:UnRegisterDisposeUICallBack target:{0} source:{1} sourcename:{2}", GetObjectName(self),ClassId,HandlerViewName))
	self.DisposeUICallBackList[ClassId] = nil
end

--[[
	动态添加UI被销毁行为回调
]]
function UserWidget:RegisterDestructUICallBack(Cb,Handler)
	if not self.DestructUICallBackList then
		self.DestructUICallBackList = {}
		CError("UserWidget: DestructUICallBackList nil",true)
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidget:RegisterDestructUICallBack target:{0} source:{1} sourcename:{2}", GetObjectName(self),ClassId,HandlerViewName))
	self.DestructUICallBackList[ClassId] = Cb
end
function UserWidget:UnRegisterDestructUICallBack(Handler)
	if not self.DestructUICallBackList then
		self.DestructUICallBackList = {}
		CError("UserWidget: DestructUICallBackList nil",true)
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidget:UnRegisterDestructUICallBack target:{0} source:{1} sourcename:{2}", GetObjectName(self),ClassId,HandlerViewName))
	self.DestructUICallBackList[ClassId] = nil
end

return UserWidget
