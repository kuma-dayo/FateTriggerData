--[[
    管理玩家基本信息的同步
]]
local class_name = "PlayerBaseInfoSyncCtrl"
---@class PlayerBaseInfoSyncCtrl : UserGameController
PlayerBaseInfoSyncCtrl = PlayerBaseInfoSyncCtrl or BaseClass(UserGameController, class_name)

-- 注册监听类型
PlayerBaseInfoSyncCtrl.RegistType = {
    PlayerName = 1,     -- 玩家名称
}

function PlayerBaseInfoSyncCtrl:__init()
    CWaring("PlayerBaseInfoSyncCtrl init")
    ---@type PersonalInfoModel
    self.PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)
    ---@type PersonalInfoCtrl
    self.PersonalInfoCtrl = MvcEntry:GetCtrl(PersonalInfoCtrl)
    ---@type FriendModel
    self.FriendModel = MvcEntry:GetModel(FriendModel)
    self.RegistWidget2PlayerId = {} -- 注册控件 -> 玩家id

    self.RegistList = {}
    self.ViewQueryList = {}
end

function PlayerBaseInfoSyncCtrl:AddMsgListenersUser()
    self.MsgList = {
		{Model = PersonalInfoModel,  	MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID,      Func = self.OnGetBaseInfoForId},
    }
end

--[[
    注册玩家名字加入轮询更新
    PlayerNameParam = {
        WidgetBaseOrHandler: 对应的界面类，用于轮询监听生命周期，管理轮询的移除
        TextBlockName: 需要设置名称的TextBlock
        TextBlockId: 需要设置名称后缀Id的TextBlock
        PlayerId: 需要查询的玩家Id
        DefaultStr: 从轮询数据缓存中查找不到时显示的默认文本
        IsFormatName: 是否调用StringUtil.FormatName 处理文本
        IsHideNum: 是否不显示名称后缀
        NameTextPattern: 对名称文本显示的拓展显示，例如 正在和{0}聊天 {0}填充PlayerName
    }
    
]] 
function PlayerBaseInfoSyncCtrl:RegistPlayerNameUpdate(PlayerNameParam)
    local WidgetBaseOrHandler = PlayerNameParam.WidgetBaseOrHandler
    local TextBlockName = PlayerNameParam.TextBlockName
    local TextBlockId = PlayerNameParam.TextBlockId
    local PlayerId = PlayerNameParam.PlayerId
    if not TextBlockName or not (TextBlockName:IsA(UE.UTextBlock) or TextBlockName:IsA(UE.URichTextBlock)) then
        CError("PlayerBaseInfoSyncCtrl RegistPlayerNameUpdate TextBlockName Error,please check",true)
		return
    end
    
    if not self:CheckCanRegist(WidgetBaseOrHandler, TextBlockName, PlayerId) then
        return
    end
    local WidgetName = WidgetBaseOrHandler:GetName()
    self.PersonalInfoCtrl:QueryPlayerBaseInfoByView(WidgetBaseOrHandler,PlayerId,false)

    if WidgetBaseOrHandler.IsClass and WidgetBaseOrHandler.Handler and WidgetBaseOrHandler.Handler.IsClass and WidgetBaseOrHandler.Handler:IsClass(UIHandler) then
		WidgetBaseOrHandler = WidgetBaseOrHandler.Handler
    end
    if not self.ViewQueryList[WidgetBaseOrHandler] then
        self.ViewQueryList[WidgetBaseOrHandler] = 1
        WidgetBaseOrHandler:RegisterDisposeUICallBack(Bind(self,self.RemoveViewQuery,WidgetBaseOrHandler),self)
        WidgetBaseOrHandler:RegisterDestructUICallBack(Bind(self,self.RemoveViewQuery,WidgetBaseOrHandler),self)
    end

    PlayerNameParam.Type = PlayerBaseInfoSyncCtrl.RegistType.PlayerName
    self.RegistList[PlayerId] = self.RegistList[PlayerId] or {}
    self.RegistList[PlayerId][WidgetBaseOrHandler] = self.RegistList[PlayerId][WidgetBaseOrHandler] or {}
    self.RegistList[PlayerId][WidgetBaseOrHandler][TextBlockName] = PlayerNameParam
    self:UpdatePlayerName(PlayerNameParam)
end

-- 取消注册
function PlayerBaseInfoSyncCtrl:UnregistPlayerNameUpdate(WidgetBaseOrHandler,TextBlockName)
    local CurRegistPlayerId = self.RegistWidget2PlayerId[TextBlockName]
    if CurRegistPlayerId and self.RegistList[CurRegistPlayerId] and self.RegistList[CurRegistPlayerId][WidgetBaseOrHandler] and self.RegistList[CurRegistPlayerId][WidgetBaseOrHandler][TextBlockName] then
        self.RegistWidget2PlayerId[TextBlockName] = nil
        self.RegistList[CurRegistPlayerId][WidgetBaseOrHandler][TextBlockName] = nil
        if not next(self.RegistList[CurRegistPlayerId][WidgetBaseOrHandler]) then
            self:RemoveViewQuery(WidgetBaseOrHandler)
        end
    end
end

-- 检查参数是否可以注册
function PlayerBaseInfoSyncCtrl:CheckCanRegist(WidgetBaseOrHandler, Widget, PlayerId)
    if not WidgetBaseOrHandler then
		CError("PlayerBaseInfoSyncCtrl WidgetBaseOrHandler nil,please check",true)
		return false
	end
    if not PlayerId then    
        CError("PlayerBaseInfoSyncCtrl PlayerId Error,please check",true)
		return false
    end

    local CurRegistPlayerId = self.RegistWidget2PlayerId[Widget]
    if CurRegistPlayerId then
        if  CurRegistPlayerId == PlayerId then
            -- 已经注册过相同信息
            CLog("PlayerBaseInfoSyncCtrl: The Widget And PlayerId Is Already Registed")
            return
        else
            -- 之前绑定的别的Id 需要去掉别的Id相对于的绑定信息
            self.PersonalInfoCtrl:RemoveQueryPlayerBaseInfoByView(WidgetBaseOrHandler,CurRegistPlayerId)
            if WidgetBaseOrHandler.IsClass and WidgetBaseOrHandler.Handler and WidgetBaseOrHandler.Handler.IsClass and WidgetBaseOrHandler.Handler:IsClass(UIHandler) then
                WidgetBaseOrHandler = WidgetBaseOrHandler.Handler
            end
            if self.RegistList[CurRegistPlayerId] and self.RegistList[CurRegistPlayerId][WidgetBaseOrHandler] then
                self.RegistList[CurRegistPlayerId][WidgetBaseOrHandler][Widget] = nil
                if not next(self.RegistList[CurRegistPlayerId][WidgetBaseOrHandler]) then
                    self.RegistList[CurRegistPlayerId][WidgetBaseOrHandler] = nil
                    if not next(self.RegistList[CurRegistPlayerId]) then
                        self.RegistList[CurRegistPlayerId] = nil
                    end
                end
            end
            
        end
    end
    self.RegistWidget2PlayerId[Widget] = PlayerId
    return true
end

function PlayerBaseInfoSyncCtrl:RemoveViewQuery(Handler)
    if not self.ViewQueryList[Handler] then
        CError("PlayerBaseInfoSyncCtrl RemoveViewQuery Handler Error!!",true)
        return
    end
    for PlayerId,HandlerList in pairs(self.RegistList) do
        if self.RegistList[PlayerId][Handler] then
            local WidgetList = self.RegistList[PlayerId][Handler]
            for Widget,_ in pairs(WidgetList) do
                self.RegistWidget2PlayerId[Widget] = nil
            end
            self.RegistList[PlayerId][Handler] = nil
        end
        if not next(self.RegistList[PlayerId]) then
            self.RegistList[PlayerId] = nil
        end
    end
    Handler:UnRegisterDisposeUICallBack(self)
    Handler:UnRegisterDestructUICallBack(self)
    self.ViewQueryList[Handler] = nil
end


-- 玩家信息更新
function PlayerBaseInfoSyncCtrl:OnGetBaseInfoForId(PlayerId)
    if self.RegistList[PlayerId] then
        self:OnBaseInfoUpdate(PlayerId)
    end
    if self.FriendModel:GetData(PlayerId) then
        -- 如果查询的人是好友，将好友数据脏标记打开
        self.FriendModel:SetIsChange(true)
    end
end

function PlayerBaseInfoSyncCtrl:OnBaseInfoUpdate(PlayerId)
    local RegistType = PlayerBaseInfoSyncCtrl.RegistType
    local HandlerList = self.RegistList[PlayerId]
    for Handler,WidgetList in pairs(HandlerList) do
        for Widget,PlayerNameParam in pairs(WidgetList) do
            if PlayerNameParam.Type == RegistType.PlayerName then
                self:UpdatePlayerName(PlayerNameParam)
            else
                -- todo 其他字段 其他类型 设置
            end
        end
    end
end

-- 更新玩家名称
function PlayerBaseInfoSyncCtrl:UpdatePlayerName(PlayerNameParam)
    local TextBlockName = PlayerNameParam.TextBlockName
    if not TextBlockName or not CommonUtil.IsValid(TextBlockName) then
        return
    end
    local PlayerInfo = self.PersonalInfoModel:GetPlayerDetailInfo(PlayerNameParam.PlayerId)
    if not PlayerInfo then
        return
    end
    
    local PlayerName = PlayerInfo.PlayerName or PlayerNameParam.DefaultStr
    
    local TextBlockId = PlayerNameParam.TextBlockId
    if TextBlockId or PlayerNameParam.IsHideNum then
        -- 需要切割数字单独显示或者隐藏数字的，才需要进行名称字符切割
        local NameIdStr = ""
        PlayerName,NameIdStr = StringUtil.SplitPlayerName(PlayerName,true)
        if TextBlockId then
            if PlayerNameParam.IsHideNum then
                TextBlockId:SetVisibility(UE.ESlateVisibility.Collapsed)
            else
                TextBlockId:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                TextBlockId:SetText(NameIdStr)
            end
        end
    end
    if PlayerNameParam.IsFormatName then
        PlayerName = StringUtil.FormatName(PlayerName)
    elseif PlayerNameParam.NameTextPattern then
        PlayerName = StringUtil.Format(PlayerNameParam.NameTextPattern,PlayerName)
    end
    TextBlockName:SetText(PlayerName)
end