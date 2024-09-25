--[[
    控制界面打开管理
]]

local class_name = "ViewController"
---@class ViewController : UserGameController
ViewController = ViewController or BaseClass(UserGameController,class_name)
local TablePool = require("Common.Utils.TablePool")

-- 界面检测类型
ViewController.VIEW_CHECK_TYPE = {
    LoginEnterHall = 1,   -- 登录到进场动画播放完成期间
    -- Loading = 2,    -- Loading期间 -- todo 
    LoadingAndInGame = 2,    -- 大厅进局内Loading开始 -> 局内出大厅Loading结束 期间
    WhenMatchSuccess = 3, -- 匹配成功期间
    SpecialView = 4,    -- 特殊界面
    NotShowOnSettlement = 5,    -- 不可以在结算界面打开时候打开
}

-- 界面检测的白名单列表
ViewController.VIEW_CHECK_WHITE_LIST = {
    -- 进入大厅期间，不能进行Cache的界面
    [ViewController.VIEW_CHECK_TYPE.LoginEnterHall] = {
        [ViewConst.NameInputPanel] = 1,
        [ViewConst.Hall] = 1,
        [ViewConst.MessageBox] = 1,
        [ViewConst.MessageBoxNoTitle] = 1,
        [ViewConst.MessageBoxSystem] = 1,
        [ViewConst.EndinCG] = 1,
    },

    -- loading到局内到出来的loading结束之前，不能进行Cache的界面
    [ViewController.VIEW_CHECK_TYPE.LoadingAndInGame] = {
        [ViewConst.Loading] = 1,
        [ViewConst.MessageBox]          = 1,
        [ViewConst.MessageBoxNoTitle]   = 1,
        [ViewConst.MessageBoxSystem]    = 1,
        [ViewConst.HallSettlement]    = 1,
    },

    -- 匹配成功后允许展示的UMG界面ID列表
    [ViewController.VIEW_CHECK_TYPE.WhenMatchSuccess] = {
        [ViewConst.MessageBox]          = 1,
        [ViewConst.MessageBoxNoTitle]   = 1,
        [ViewConst.MessageBoxSystem]    = 1,
        [ViewConst.MatchSuccessPop]     = 1,
        [ViewConst.Loading]             = 1,
    },

    --[[
        特殊界面 过滤列表 涉及：
        1. ViewCtrlBase.show_view 中不执行 VirtualTriggerHide 
        2. ViewModel.Calculatelayer2OpenSortList 中，不被获取
    ]]
    [ViewController.VIEW_CHECK_TYPE.SpecialView] = {
        [ViewConst.TeamAndChat] = 1,
        [ViewConst.Loading] = 1,
    },
}

-- 界面检测的黑名单列表
ViewController.VIEW_CHECK_BLACK_LIST = {
    --[[ 
        战斗返回大厅后，弹出的界面需要区分可在结算界面打开 还是 需要等待结算关闭后才打开
        配置在此的是不能在结算打开期间出现的界面
    ]]
    [ViewController.VIEW_CHECK_TYPE.NotShowOnSettlement] = {
        [ViewConst.ItemGet] = 1,
        [ViewConst.SpecialItemGet] = 1,
        [ViewConst.SeasonBpLvUpgradeNormal] = 1,
        [ViewConst.SeasonBpLvUpgradeAdvance] = 1,
    }
}
-- Cached的来源:
ViewController.OPEN_CACHE_SOURCE = {
    LoginEnterHall = 1,    -- 登录到进场动画播放完成期间
    -- Loading = 2,    -- Loading期间
    LoadingAndInGame = 2,    -- 大厅进局内Loading开始 -> 局内出大厅Loading结束 期间
    WaitForSettlementToHall = 3,  -- 等待结算关闭到返回大厅后
}

function ViewController:__init()
    CWaring("==ViewController init")
    
    -- 缓存界面重新打开时的权重，值越大越慢打开（在越上层）.不配置的界面默认权重为0
    -- 新手引导 ＞ 登陆后活动拍脸图（未开发）＞段位提升弹窗＞BP等级提升＞特殊获取弹窗＞普通获取弹窗＞问卷弹窗
    self.CacheViewShowWeight = {
        [ViewConst.GuideKeySelectionMainPanel] = 4,
        [ViewConst.GuideStartGame] = 4,
        [ViewConst.GuideSettlement] = 4,
        [ViewConst.GuideChooseGender] = 4,
        
        [ViewConst.SeasonBpLvUpgradeNormal] = 3,
        [ViewConst.SeasonBpLvUpgradeAdvance] = 3,
        [ViewConst.SpecialItemGet] = 2,
        [ViewConst.ItemGet] = 2,
        [ViewConst.QuestionnairePop] = 1,
    }

    --额外的打开界面检测逻辑
    self.ExtraShowCheckFuncList = nil
    --额外的关闭界面检测逻辑
    self.ExtraCloseCheckFuncList = nil
    self:__DataInit()
end

--[[
    这里的数据，在玩家登出时，会清理
]]
function ViewController:__DataInit()
    self.NeedCacheSource = {}
    self.CacheViewList = {}
    self.OpenOnSettlement = {}
    self.CachingSourceList = {}
end

--[[
    玩家登入
]]
function ViewController:OnLogin(data)
    CWaring("ViewController OnLogin")
end

function ViewController:OnLogout()
    self:__DataInit()
end

function ViewController:AddMsgListenersUser()
    self.MsgList = {
        {Model = nil, MsgName = CommonEvent.SHOW_VIEW_CHECK, Func = self.SHOW_VIEW_CHECK_Func }, 
        {Model = nil, MsgName = CommonEvent.HIDE_VIEW_CHECK, Func = self.HIDE_VIEW_CHECK_Func },
        {Model = HallModel, MsgName = HallModel.ON_START_ENTERING_HALL, Func = self.ON_START_ENTERING_HALL }, 
        {Model = HallModel, MsgName = HallModel.ON_HALL_READY_UPDATE, Func = Bind(self,self.OnHallReady) }, 
        {Model = CommonModel, MsgName = CommonModel.ON_ASYNC_LOADING_START_TO_BATTLE, Func = self.OnAsyncLoadingStartToBattle }, 
        {Model = CommonModel, MsgName = CommonModel.ON_ASYNC_LOADING_FINISHED_HALL, Func = self.OnAsyncLoadingFinishToHall }, 
        {Model = CommonModel, MsgName = CommonModel.ON_ASYNC_LOADING_FINISHED_BATTLE, Func = self.OnAsyncLoadingFinishToBattle }, 
    }
    -- self.MsgListGMP = {
	-- 	{ InBindObject = _G.MainSubSystem,	MsgName = "AsyncLoadingScreen_LoadingStarted",Func = Bind(self,self.OnAsyncLoadingScreenLoadingStarted), bCppMsg = true, WatchedObject = nil },
	-- 	{ InBindObject = _G.MainSubSystem,	MsgName = "AsyncLoadingScreen_LoadingFinished",Func = Bind(self,self.OnAsyncLoadingScreenLoadingFinished), bCppMsg = true, WatchedObject = nil },
    -- }
    --额外需要检测界面是否可以打开的逻辑方法
    self.ExtraShowCheckFuncList = {
        {Name = "CacheCheck",Func = Bind(self,self.DoCacheShowCheck)},
        {Name = "DoInGameCheck",Func = Bind(self,self.DoInGameCheck)},
    }
    self.ExtraCloseCheckFuncList = TablePool.Fetch("ViewController")

end

function ViewController:SHOW_VIEW_CHECK_Func(Event)
    -- print_r(Event,"ViewController:SHOW_VIEW_CHECK")
    local CanOpenResult = true
    for k,v in ipairs(self.ExtraShowCheckFuncList) do
        if not v.Func(Event) then
            CanOpenResult = false
            break
        end
    end

    if CanOpenResult then
        self:SendMessage(CommonEvent.SHOW_VIEW,Event)
    end
end

function ViewController:HIDE_VIEW_CHECK_Func(Event)
    -- print_r(Event,"ViewController:HIDE_VIEW_CHECK")
    local CanCloseResult = true
    for k,v in ipairs(self.ExtraCloseCheckFuncList) do
        if not v.Func(Event) then
            CanCloseResult = false
            break
        end
    end

    if CanCloseResult then
        self:SendMessage(CommonEvent.HIDE_VIEW,Event)
    end
end

--[[
    是否在检测白名单中
]]
function ViewController:IsInViewCheckWhiteList(CheckType,ViewId)
    if not ViewController.VIEW_CHECK_WHITE_LIST[CheckType] then
        -- 检测类型没配置白名单列表，默认可打开
        return true
    end
    if ViewController.VIEW_CHECK_WHITE_LIST[CheckType][ViewId] then
        return true
    end
    return false
end

--[[
    是否在检测黑名单中
]]
function ViewController:IsInViewCheckBlackList(CheckType,ViewId)
    if not ViewController.VIEW_CHECK_BLACK_LIST[CheckType] then
        -- 检测类型没配置黑名单列表，默认可打开
        return false
    end
    if ViewController.VIEW_CHECK_BLACK_LIST[CheckType][ViewId] then
        return true
    end
    return false
end

--[[
    检测界面当前不能打开，需要Cache住
]]
function ViewController:DoCacheShowCheck(Event)
    -- 是否需要缓存
    local UIResType = ViewConstConfig[Event.viewId].UIResType or GameMediator.UIResType.UMG
    local UILayerType = ViewConstConfig[Event.viewId].UILayerType or UIRoot.UILayerType.Pop
    if next(self.CachingSourceList) and UIResType == GameMediator.UIResType.UMG and UILayerType >= UIRoot.UILayerType.Pop then
        local VIEW_CHECK_TYPE = ViewController.VIEW_CHECK_TYPE
        local OPEN_CACHE_SOURCE = ViewController.OPEN_CACHE_SOURCE
        -- 检查类型对应的CacheSource
        local CacheSource2CheckTypeMap = {
            [OPEN_CACHE_SOURCE.LoginEnterHall] = VIEW_CHECK_TYPE.LoginEnterHall, 
            [OPEN_CACHE_SOURCE.LoadingAndInGame] = VIEW_CHECK_TYPE.LoadingAndInGame,
            [OPEN_CACHE_SOURCE.WaitForSettlementToHall] = VIEW_CHECK_TYPE.NotShowOnSettlement, 
        }
        -- for Type,Source in pairs(CheckTypeMap) do
        --     Type = tonumber(Type)
        --     -- 检测是否在白名单中。是则不进行Cache
        --     if self:IsInViewCheckWhiteList(Type,Event.viewId) then
        --         CWaring(StringUtil.FormatSimple("==== View In WhiteList. ViewId = {0} CheckType = {1} : ",Event.viewId,Type))
        --         return true
        --     end
        -- end
        local CanShow = true
        for CacheSource,_ in pairs(self.CachingSourceList) do
            CacheSource = tonumber(CacheSource)
            local CheckType = CacheSource2CheckTypeMap[CacheSource]
            if not CheckType then
                CWaring("DoCacheShowCheck CacheSource Can't Find CheckType, Source = "..tostring(CacheSource))
                CanShow = false
                break
            end
            if not self:IsInViewCheckWhiteList(CheckType,Event.viewId) or self:IsInViewCheckBlackList(CheckType,Event.viewId) then
                -- 1. 存在白名单配置，但不在白名单中
                -- 2. 存在黑名单配置，在黑名单中
                CanShow = false
                break
            end
        end
        if CanShow then
            CWaring(StringUtil.FormatSimple("==== View In WhiteList. ViewId = {0} ",Event.viewId))
            return true
        else
            CWaring("==== View Caching. Cache View : "..tostring(Event.viewId))
            self.CacheViewList[#self.CacheViewList + 1] = Event
            return false    
        end
    end
    return true
end


function ViewController:DoInGameCheck(Event)
    --合法性判断
    if not CommonUtil.IsValid(UIRoot.GetLayer(UIRoot.UILayerType.Scene)) then
        return false
    end
    --系统解锁判断
    local ViewId = Event.viewId
    if not MvcEntry:GetModel(NewSystemUnlockModel):IsSystemUnlock(ViewId,true) then
        return false
    end
    
    --匹配成功状态下，只允许特定的界面打开
    if ViewConstConfig[ViewId] and ViewConstConfig[ViewId].UIResType == GameMediator.UIResType.UMG then
        ---@type MatchModel
        local IsHallViewShow = self:GetModel(ViewModel):GetState(ViewConst.Hall)
        local MatchModel = MvcEntry:GetModel(MatchModel)
        if IsHallViewShow and MatchModel:IsMatchSuccessed() and not self:IsInViewCheckWhiteList(ViewController.VIEW_CHECK_TYPE.WhenMatchSuccess,ViewId) then
            CWaring("MatchSuccessed, abandon display view " .. tostring(ViewId))
            return  false
        end
    end
    return true
end

-- 设置是否需要缓存打开的界面
function ViewController:SetNeedCacheViewOpen(Source,IsCache)
    CWaring(StringUtil.Format("==== SetNeedCacheViewOpen Source = {0} IsCache = {1}",Source,tostring(IsCache)))
    self.NeedCacheSource[Source] = IsCache or nil
    if not IsCache then
        -- 关闭Cache时，检测是否还有其他因素需要Cache
        self.CachingSourceList[Source] = nil
        local HaveOtherCache = next(self.CachingSourceList)
        if not HaveOtherCache then
            -- 无任何Cache阻塞，打开Cache的所有界面
            CWaring("==== All View Cache Cleared")
            -- 打开前，根据优先级进行一次排序
            self.CacheViewList = self:SortViewForList(self.CacheViewList)
            self:OpenViewForList(self.CacheViewList)
            -- 打开完毕清除缓存
            self.CacheViewList = {}
        elseif table_leng(self.CachingSourceList) == 1 and  self.CachingSourceList[ViewController.OPEN_CACHE_SOURCE.WaitForSettlementToHall] then
            -- 仅剩结算Cache时，把能在结算界面打开的界面先打开了 -- TODO 后续是否由结算业务掌控这个打开的逻辑
            self:OpenViewForList(self.OpenOnSettlement)
            self.OpenOnSettlement = {}
        else
            CWaring("==== Can't Open Cache View : "..tostring(Event.viewId))
            print_r(self.CachingSourceList,"Now CachingSource")
        end
    else
        self.CachingSourceList[Source] = 1
    end
end

-- 对Cache的界面列表，根据优先级进行排序
function ViewController:SortViewForList(List)
    local SortFunc = function(IndexA,IndexB)
        local ViewA = List[IndexA]
        local ViewB = List[IndexB]
        local WeightA = self.CacheViewShowWeight[ViewA.viewId] or 0
        local WeightB = self.CacheViewShowWeight[ViewB.viewId] or 0
        return WeightB > WeightA
    end
    return CommonUtil.StableSort(List,SortFunc)
end

function ViewController:OpenViewForList(List)
    for I = 1, #List do
        local Event = List[I]
        CWaring("==== Open Cache View : "..tostring(Event.viewId))
        self:SHOW_VIEW_CHECK_Func(Event)
    end
end

--[[
    添加自定义开启检查事件
]]
function ViewController:AddExtraShowCheckFunc(TheName,TheFunc)
    for k,v in ipairs(self.ExtraShowCheckFuncList) do
        if v.Name == TheName then
            CError("ViewController:AddExtraShowCheckFunc Check Already Exist:" .. TheName,true)
            return
        end
    end
    self.ExtraShowCheckFuncList[#self.ExtraShowCheckFuncList + 1] = {Name = TheName,Func = TheFunc}
end
--[[
    移除自定义开启检查事件
]]
function ViewController:RemoveExtraShowCheckFunc(TheName)
    local NewList = TablePool.Fetch("ViewController")
    local ExistRemove = false
    for k,v in ipairs(self.ExtraShowCheckFuncList) do
        if v.Name ~= TheName then
            NewList[#NewList + 1] = v
        else
            ExistRemove = true
        end
    end
    TablePool.Recycle("ViewController", self.ExtraShowCheckFuncList)
    self.ExtraShowCheckFuncList = NewList

    if not ExistRemove then
        CError("ViewController:RemoveExtraShowCheckFunc Not Found:" .. TheName,true)
    end
end

--[[
    添加自定义关闭检查事件
]]
function ViewController:AddExtraCloseCheckFunc(TheName,TheFunc)
    for k,v in ipairs(self.ExtraCloseCheckFuncList) do
        if v.Name == TheName then
            CError("ViewController:AddExtraCloseCheckFunc Check Already Exist:" .. TheName,true)
            return
        end
    end
    self.ExtraCloseCheckFuncList[#self.ExtraCloseCheckFuncList + 1] = {Name = TheName,Func = TheFunc}
end
--[[
    移除自定义关闭检查事件
]]
function ViewController:RemoveExtraCloseCheckFunc(TheName)
    local NewList = TablePool.Fetch("ViewController")
    local ExistRemove = false
    for k,v in ipairs(self.ExtraCloseCheckFuncList) do
        if v.Name ~= TheName then
            NewList[#NewList + 1] = v
        else
            ExistRemove = true
        end
    end
    TablePool.Recycle("ViewController", self.ExtraCloseCheckFuncList)
    self.ExtraCloseCheckFuncList = NewList

    if not ExistRemove then
        CError("ViewController:RemoveExtraCloseCheckFunc Not Found:" .. TheName,true)
    end
end

function ViewController:CheckIsWaitForSettlement()
    if not self.NeedCacheSource[ViewController.OPEN_CACHE_SOURCE.WaitForSettlementToHall] then
        -- 结算界面未打开，不处理
        return
    end
    self.OpenOnSettlement = {}
    local TempList = {}
    for I = 1, #self.CacheViewList do
        local Event = self.CacheViewList[I]
        local ViewId = Event.viewId
        if not self:IsInViewCheckBlackList(ViewController.VIEW_CHECK_TYPE.NotShowOnSettlement,ViewId) then
            CWaring("==== View Will Show On Settlement : "..tostring(Event.viewId))
            self.OpenOnSettlement[#self.OpenOnSettlement + 1] = Event
        else
            TempList[#TempList + 1] = Event
        end
    end
    self.CacheViewList = TempList
end

--------------------------------------- 设置界面打开Cache ---------------------------------------------------------------

--[[
    登录成功 正在进入大厅
    开启进场ViewCache
]]
function ViewController:ON_START_ENTERING_HALL()
    CWaring("== ViewController ON_START_ENTERING_HALL")
    self:SetNeedCacheViewOpen(ViewController.OPEN_CACHE_SOURCE.LoginEnterHall,true)
end

--[[
    大厅进场完毕
]]
function ViewController:OnHallReady(_,IsFromReconnect)
    if not self:GetModel(HallModel):GetIsHallReady() then
        return
    end
    local IsFromReconnectStr = IsFromReconnect and "true" or "false"
    CWaring("== ViewController OnHallReady, IsReconnect = "..IsFromReconnectStr)
    self:SetNeedCacheViewOpen(ViewController.OPEN_CACHE_SOURCE.LoginEnterHall,false)
    if not IsFromReconnect then
        if self.NeedCacheSource[ViewController.OPEN_CACHE_SOURCE.WaitForSettlementToHall] then
            -- 大厅打开完毕后，才能打开经过结算Cache的界面
            self:SetNeedCacheViewOpen(ViewController.OPEN_CACHE_SOURCE.WaitForSettlementToHall,false)
        end
    end

end

--[[
    异步Loading加载开始
]]
-- function ViewController:OnAsyncLoadingScreenLoadingStarted()
--     CWaring("== ViewController AsyncLoadingScreen_LoadingStarted")
--     self:SetNeedCacheViewOpen(ViewController.OPEN_CACHE_SOURCE.Loading,true)
-- end

--[[
    异步Loading加载开始 从大厅准备进战斗
]]
function ViewController:OnAsyncLoadingStartToBattle()
    CWaring("== ViewController OnAsyncLoadingStartToBattle")
    self:SetNeedCacheViewOpen(ViewController.OPEN_CACHE_SOURCE.LoadingAndInGame,true)
end

--[[
    异步Loading加载完成
]]
-- function ViewController:OnAsyncLoadingScreenLoadingFinished()
--     CWaring("== ViewController AsyncLoadingScreen_LoadingFinished")
--     self:SetNeedCacheViewOpen(ViewController.OPEN_CACHE_SOURCE.Loading,false)
-- end

--[[
    异步Loading加载完成 从战斗返回大厅
]]
function ViewController:OnAsyncLoadingFinishToHall()
    CWaring("== ViewController OnAsyncLoadingFinishToHall")
    self:CheckIsWaitForSettlement()
    self:SetNeedCacheViewOpen(ViewController.OPEN_CACHE_SOURCE.LoadingAndInGame,false)
end

--[[
    异步Loading加载完成 从大厅进入战斗
]]
function ViewController:OnAsyncLoadingFinishToBattle()
    if not CommonUtil.IsInBattle() then
        -- Loading加载完成了，却没有进战斗，进入战斗失败
        CWaring("== ViewController OnAsyncLoadingFinishToBattle But Can't Join Battle")
        self:SetNeedCacheViewOpen(ViewController.OPEN_CACHE_SOURCE.LoadingAndInGame,false)
    end
end