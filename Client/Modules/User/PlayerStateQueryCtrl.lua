--[[
    玩家状态轮询控制器
    用于注册是否需要进行状态轮询，这里指进行轮询的逻辑控制，查询信息调用UserModel的状态查询接口
]]

local class_name = "PlayerStateQueryCtrl"
---@class PlayerStateQueryCtrl : UserGameController
PlayerStateQueryCtrl = PlayerStateQueryCtrl or BaseClass(UserGameController,class_name)


function PlayerStateQueryCtrl:__init()
    CWaring("==PlayerStateQueryCtrl init")
    -- 查询间隔 /s
    self.QueryTime = 1
    -- 查询的玩家信息列表
    self.QueryIdMap = {}
    self.QueryIdList = {}
	self.ViewQueryList = {}
end

--[[
    玩家登入
]]
function PlayerStateQueryCtrl:OnLogin(data)

end

--[[
    玩家登出
]]
function PlayerStateQueryCtrl:OnLogout(data)
    self:StopQueryTimer()
    self.QueryIdMap = {}
    self.QueryIdList = {}
	self.ViewQueryList = {}
end

--[[
    进入战斗
]]
function PlayerStateQueryCtrl:OnPreEnterBattle()
    self:StopQueryTimer()
end

--[[
    回到大厅
]]
function PlayerStateQueryCtrl:OnAfterBackToHall()
    self:StartQueryTimer()
end

--[[
    加入需要查询的Id列表（记得移除）
]]
function PlayerStateQueryCtrl:PushQueryPlayerIdList(PlayerIdList)
    if not PlayerIdList or #PlayerIdList == 0 then
        return
    end
    for _, PlayerId in ipairs(PlayerIdList) do
        self:PushQueryPlayerId(PlayerId)
    end
end

-- 移除查询的id列表
function PlayerStateQueryCtrl:DeleteQueryPlayerIdList(PlayerIdList)
    if not PlayerIdList or #PlayerIdList == 0 then
        return
    end
    for _, PlayerId in ipairs(PlayerIdList) do
        self:DeleteQueryPlayerId(PlayerId)
    end
end

--[[
    加入需要查询的Id（记得移除）
]]
function PlayerStateQueryCtrl:PushQueryPlayerId(PlayerId)
    if not PlayerId then
        return
    end
    self.QueryIdMap[PlayerId] = self.QueryIdMap[PlayerId] or 0
    if self.QueryIdMap[PlayerId] == 0 then
        self.QueryIdList[#self.QueryIdList + 1] = PlayerId
    end
    self.QueryIdMap[PlayerId] = self.QueryIdMap[PlayerId] + 1
    if not self.QueryTimer then
        self:StartQueryTimer()
    end
end

-- 移除查询的id
function PlayerStateQueryCtrl:DeleteQueryPlayerId(PlayerId)
    if not PlayerId then
        return
    end
    if not self.QueryIdMap[PlayerId] or self.QueryIdMap[PlayerId] == 0 then
        return
    end
    self.QueryIdMap[PlayerId] = self.QueryIdMap[PlayerId] - 1
    if self.QueryIdMap[PlayerId] == 0 then
        local Index = nil
        for I,InPlayerId in ipairs(self.QueryIdList) do
            if InPlayerId == PlayerId then
                Index = I
                break
            end
        end
        if Index then
            table.remove(self.QueryIdList,Index)
        end
    end
    if #self.QueryIdList == 0 then
        self:StopQueryTimer()
    end
end

--[[
    加入需要查询的Id列表
    WidgetBaseOrHandler 为UUserWidget或UIHandle，会在UI移除的时候，自动将查询的Id去除
    使用这种只要保证信息与WidgetBaseOrHandler生命周期一致即可
]]
function PlayerStateQueryCtrl:PushQueryPlayerIdListByView(WidgetBaseOrHandler,PlayerIdList)
    if not PlayerIdList or #PlayerIdList == 0 then
        return
    end
    for _, PlayerId in ipairs(PlayerIdList) do
        self:PushQueryPlayerIdByView(WidgetBaseOrHandler,PlayerId)
    end
end

--[[
    加入需要查询的Id
    WidgetBaseOrHandler 为UUserWidget或UIHandle，会在UI移除的时候，自动将查询的Id去除
    使用这种只要保证信息与WidgetBaseOrHandler生命周期一致即可
]]
function PlayerStateQueryCtrl:PushQueryPlayerIdByView(WidgetBaseOrHandler,PlayerId)
    if not WidgetBaseOrHandler then
		CError("PlayerStateQueryCtrl PushQueryPlayerIdByView WidgetBaseOrHandler nil,please check",true)
		return
	end
    if WidgetBaseOrHandler.IsClass and WidgetBaseOrHandler.Handler and WidgetBaseOrHandler.Handler.IsClass and WidgetBaseOrHandler.Handler:IsClass(UIHandler) then
		WidgetBaseOrHandler = WidgetBaseOrHandler.Handler
    end
    if not self.ViewQueryList[WidgetBaseOrHandler] then
        self.ViewQueryList[WidgetBaseOrHandler] = {}
        WidgetBaseOrHandler:RegisterDisposeUICallBack(Bind(self,self.RemoveViewQuery,WidgetBaseOrHandler),self)
        WidgetBaseOrHandler:RegisterDestructUICallBack(Bind(self,self.RemoveViewQuery,WidgetBaseOrHandler),self)
    end
    self.ViewQueryList[WidgetBaseOrHandler][PlayerId] = self.ViewQueryList[WidgetBaseOrHandler][PlayerId] or 0
    self.ViewQueryList[WidgetBaseOrHandler][PlayerId] = self.ViewQueryList[WidgetBaseOrHandler][PlayerId] + 1
    self:PushQueryPlayerId(PlayerId)
end

--------------------- private -------------------------------------------------------------------------------
function PlayerStateQueryCtrl:RemoveViewQuery(Handler)
    local CountMap = self.ViewQueryList[Handler]
    if not CountMap then
        CError("PlayerStateQueryCtrl RemoveViewQuery Handler Error!!",true)
        return
    end
    for PlayerId,Count in pairs(CountMap) do
        for I= 1,Count do
            self:DeleteQueryPlayerId(PlayerId)
        end
    end
    Handler:UnRegisterDisposeUICallBack(self)
    Handler:UnRegisterDestructUICallBack(self)
    self.ViewQueryList[Handler] = nil
end

function PlayerStateQueryCtrl:StartQueryTimer()
    self:StopQueryTimer()
    if not self.QueryIdList or #self.QueryIdList == 0 then
        return
    end
    self.QueryTimer = Timer.InsertTimer(self.QueryTime,function ()
        if not self.QueryIdList or #self.QueryIdList == 0 then
            self:StopQueryTimer()
            return
        end
        MvcEntry:GetModel(UserModel):GetPlayerState(self.QueryIdList)
    end,true)    
end

function PlayerStateQueryCtrl:StopQueryTimer()
    if self.QueryTimer then
        Timer.RemoveTimer(self.QueryTimer)
    end
    self.QueryTimer = nil
end