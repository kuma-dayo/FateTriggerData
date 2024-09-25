---
--- local Mdt 自建房 房间详情模块，用于控制 UMG 控件显示逻辑
--- Description: 
--- Created At: 2023/05/29 20:46
--- Created By: 朝文
---

require("Client.Modules.CustomRoom.CustomRoomDetail.CustomRoomDetailModel")

local class_name = "CustomRoomDetailMdt"
---@class CustomRoomDetailMdt
local CustomRoomDetailMdt = BaseClass(nil, class_name)

function CustomRoomDetailMdt:OnInit()
    --底部按钮
    ---@type CustomRoomButtonsMdt
    self.BottomBtns = UIHandler.New(self, self.View.WBP_HallCustomerRoom_BottomBtns,
            require("Client.Modules.CustomRoom.CustomRoomCommonWidget.CustomRoomButtonsMdt"),
            {
                --左侧大按钮
                Button1Info = {                     --如果没有配置则隐藏按钮
                    Text = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetailMdt_Exittheroom")),
                    Callback = Bind(self, self.OnButtonClicked_ExitRoom),
                },
                --右侧大按钮
                Button2Info = {                     --如果没有配置则隐藏按钮
                    Text = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetailMdt_Openthebattlefield")),
                    Callback = Bind(self, self.OnButtonClicked_EnterBattle),
                },
                --最左侧小按钮
                ButtonExtraInfo = {                 --如果没有配置则隐藏按钮
                    Text = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetailMdt_Refreshlist")),
                    Callback = Bind(self, self.OnButtonClicked_RefreshRoomInfo),
                }
            }).ViewInstance

    self.MsgList = {
        --{Model = CustomRoomListModel,   MsgName = CustomRoomListModel.ON_ROOM_INFO_RSP,	                        Func = Bind(self, self.ON_ROOM_INFO_RSP_func) },
        
        {Model = CustomRoomDetailModel, MsgName = CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_RSP,	        Func = Bind(self, self.CUSTOM_ROOM_ON_PLAYER_INFO_RSP_func) },
        {Model = CustomRoomDetailModel, MsgName = CustomRoomDetailModel.CUSTOM_ROOM_ON_ROOM_MASTER_INFO_SYNC,	Func = Bind(self, self.CUSTOM_ROOM_ON_ROOM_MASTER_INFO_SYNC_func) },
        {Model = CustomRoomDetailModel, MsgName = CustomRoomDetailModel.CUSTOM_ROOM_ON_ROOM_HERO_LIST_RSP,	    Func = Bind(self, self.CUSTOM_ROOM_ON_ROOM_HERO_LIST_RSP_func) },
        {Model = CustomRoomDetailModel, MsgName = CustomRoomDetailModel.CUSTOM_ROOM_ON_TEAM_LIST_RSP,	        Func = Bind(self, self.CUSTOM_ROOM_ON_TEAM_LIST_RSP_func) },
        {Model = CustomRoomDetailModel, MsgName = CustomRoomDetailModel.CUSTOM_ROOM_ON_SELECT_HERO_RSP,	        Func = Bind(self, self.CUSTOM_ROOM_ON_SELECT_HERO_RSP_func) },        
        {Model = CustomRoomDetailModel, MsgName = CustomRoomDetailModel.CUSTOM_ROOM_ON_SELECT_TEAM_RSP,	        Func = Bind(self, self.CUSTOM_ROOM_ON_SELECT_TEAM_RSP_func) },        
        
        {Model = CustomRoomDetailModel, MsgName = CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_CHANGED,          Func = Bind(self, self.CUSTOM_ROOM_ON_PLAYER_CHANGED_func) },
        {Model = CustomRoomDetailModel, MsgName = CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_CHANGED,     Func = Bind(self, self.CUSTOM_ROOM_ON_PLAYER_INFO_CHANGED_func) },
    }
end

function CustomRoomDetailMdt:OnShow(Param)
    self._Widget2TeamListItem = {}
    self.View.WBP_ReuseList_TeamInfo.OnUpdateItem:Add(self.View, Bind(self, self.OnTeamListItemUpdate))

    self._Widget2HeroListItem = {}
    self.View.WBP_ReuseList_Hero.OnUpdateItem:Add(self.View, Bind(self, self.OnHeroListItemUpdate))

    ---@type CustomRoomDetailCtrl
    local CustomRoomDetailCtrl = MvcEntry:GetCtrl(CustomRoomDetailCtrl)
    CustomRoomDetailCtrl:SendHeroListReq()                                  --请求可选英雄列表
    CustomRoomDetailCtrl:SendTeamListReq()                                  --请求队伍信息列表
    CustomRoomDetailCtrl:SendRoomPlayerInfoReq()                            --请求玩家信息列表（目前来看这一块没有什么实际的用处，用户信息可以从队伍信息列表中推出来）

    --处理自动登录
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    if UserModel.IsLoginByCMD and UserModel.CMDSelectHeroId then
        CustomRoomDetailCtrl:SendSelectHeroReq(UserModel.CMDSelectHeroId)

        --这一步之后，自动登录就结束了
        UserModel.IsLoginByCMD = false
    end
end

function CustomRoomDetailMdt:OnHide()
    self.View.WBP_ReuseList_TeamInfo.OnUpdateItem:Clear()
    self.View.WBP_ReuseList_Hero.OnUpdateItem:Clear()
end

function CustomRoomDetailMdt:UpdateView()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:UpdateView()")
    self:UpdateTitle()
    self:UpdateGameType()
    self:UpdatePlayerCount()
    self:UpdateTeamList()
    self:UpdateHeroList()
    self:UpdateBottomBtnsDisplay()
end

---更新房间 标题
function CustomRoomDetailMdt:UpdateTitle()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:UpdateTitle()")
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local CustomRoomMasterName = CustomRoomDetailModel:GetMasterInfo_MasterName()
    self.View.Text_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetailMdt_sroom"), CustomRoomMasterName))
end

---更新房间 比赛模式
function CustomRoomDetailMdt:UpdateGameType()  
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:UpdateGameType()")
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local ModeKey = CustomRoomDetailModel:GetRoomInfo_ModeKey()
    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local ModeName = MatchModeSelectModel:GetModeEntryCfg_ModeName(ModeKey)
    
    self.View.TxtModeName:SetText(ModeName)
end

---更新房间 当前人数/总人数
function CustomRoomDetailMdt:UpdatePlayerCount()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:UpdatePlayerCount()")
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local ModeKey = CustomRoomDetailModel:GetRoomInfo_ModeKey()
    local CurPlayerCount = CustomRoomDetailModel:GetCurPlayerCount()    
    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local MaxPlayerNum = MatchModeSelectModel:GetModeEntryCfg_MaxPlayer(ModeKey)
    
    self.View.TxtJoinNum:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"),CurPlayerCount, MaxPlayerNum))
end

---更新底部按钮显示
function CustomRoomDetailMdt:UpdateBottomBtnsDisplay()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:UpdateBottomBtns()")
    if not self.BottomBtns then return end

    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local MasterID = CustomRoomDetailModel:GetMasterInfo_MasterID()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = UserModel:GetPlayerId()
    
    if MasterID == PlayerId then
        self.BottomBtns:ShowButton_1()
        self.BottomBtns:ShowButton_2()
        self.View.HorBoxAINum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.BottomBtns:ShowButton_1()
        self.BottomBtns:HideButton_2()
        self.View.HorBoxAINum:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

------------------------------------------------------- 左侧队伍 ---------------------------------------------------------

function CustomRoomDetailMdt:UpdateTeamList()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:UpdateTeamList()")
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local ModeKey = CustomRoomDetailModel:GetRoomInfo_ModeKey()
    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local MaxTeamNum = MatchModeSelectModel:GetModeEntryCfg_MaxTeam(ModeKey)
    
    self.View.WBP_ReuseList_TeamInfo:Reload(MaxTeamNum)
end

---获取或创建一个使用lua绑定的控件
---@return CustomRoomDetailTeamListMdt
function CustomRoomDetailMdt:_GetOrCreateReuseTeamListItem(Widget)
    local Item = self._Widget2TeamListItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.CustomRoom.CustomRoomDetail.CustomRoomDetail_TeamListMdt"))
        self._Widget2TeamListItem[Widget] = Item
    end

    return Item.ViewInstance
end

---更新 WBP_ReuseList_TeamInfo 的函数
---@param Widget userdata 控件
---@param Index number 在lua侧使用需要 +1
function CustomRoomDetailMdt:OnTeamListItemUpdate(_, Widget, Index)
    local FixedIndex = Index + 1

    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local Data = CustomRoomDetailModel:GetCustomRoomInfo_TeamByIndex(FixedIndex)

    if not Data then CLog("[cw] CustomRoomDetailMdt:OnTeamListItemUpdate: Cannot get Info by FixedIndex: " .. tostring(FixedIndex)) return end

    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local ModeKey = CustomRoomDetailModel:GetRoomInfo_ModeKey()
    local MaxTeamPlayerNum = MatchModeSelectModel:GetModeEntryCfg_MaxTeamPlayer(ModeKey)
    
    local TargetItem = self:_GetOrCreateReuseTeamListItem(Widget)
    if not TargetItem then return end

    TargetItem:SetTeamIndex(FixedIndex)
    TargetItem:SetMaxTeamPlayerNum(MaxTeamPlayerNum)
    TargetItem:SetData(Data)
    TargetItem:UpdateView()
end

------------------------------------------------------- 右侧英雄 ---------------------------------------------------------

function CustomRoomDetailMdt:UpdateHeroList()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:UpdateHeroList()")
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local HeroList = CustomRoomDetailModel:GetCustomRoomHeroList()
    self.View.WBP_ReuseList_Hero:Reload(#HeroList)
end

---获取或创建一个使用lua绑定的控件
---@return CustomRoomDetailHeroListItemMdt
function CustomRoomDetailMdt:_GetOrCreateReuseHeroListItem(Widget)
    local Item = self._Widget2HeroListItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.CustomRoom.CustomRoomDetail.CustomRoomDetail_HeroListItemMdt"))
        self._Widget2HeroListItem[Widget] = Item
    end
    
    return Item.ViewInstance
end

---更新 View.WBP_ReuseList_Hero 的函数
---@param Widget userdata 控件
---@param Index number 在lua侧使用需要 +1
function CustomRoomDetailMdt:OnHeroListItemUpdate(_, Widget, Index)
    local FixedIndex = Index + 1

    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local HeroList = CustomRoomDetailModel:GetCustomRoomHeroList()
    local Data = HeroList[FixedIndex]
    
	local TargetItem = self:_GetOrCreateReuseHeroListItem(Widget)
    if not TargetItem then return end

    TargetItem:SetData(Data)
    TargetItem:UpdateView()
end

------------------------------------------------------- 按钮相关 ---------------------------------------------------------

function CustomRoomDetailMdt:OnButtonClicked_RefreshRoomInfo()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:OnButtonClicked_RefreshRoomInfo()")
    
    ---@type CustomRoomModel
    local CustomRoomModel = MvcEntry:GetModel(CustomRoomModel)
    if CustomRoomModel:IsInEnteringBattle() then UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetailMdt_Enterthebattleplease"))) return end
    
    ---@type CustomRoomDetailCtrl
    local CustomRoomDetailCtrl = MvcEntry:GetCtrl(CustomRoomDetailCtrl)
    CustomRoomDetailCtrl:SendTeamListReq()
end

function CustomRoomDetailMdt:OnButtonClicked_ExitRoom()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:OnButtonClicked_ExitRoom()")
    
    ---@type CustomRoomModel
    local CustomRoomModel = MvcEntry:GetModel(CustomRoomModel)
    if CustomRoomModel:IsInEnteringBattle() then
        local Param = { describe = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetailMdt_Thegamehasstartedsoy") }
        UIMessageBox.Show(Param)
        return
    end
    
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local RoomId = CustomRoomDetailModel:GetRoomInfo_RoomId()

    ---@type CustomRoomCtrl
    local CustomRoomCtrl = MvcEntry:GetCtrl(CustomRoomCtrl)
    CustomRoomCtrl:SendExitRoomReq(RoomId)
end

function CustomRoomDetailMdt:OnButtonClicked_EnterBattle()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:OnButtonClicked_EnterBattle()")
    
    --1.当前状态为进入战斗时，不需要处理
    ---@type CustomRoomModel
    local CustomRoomModel = MvcEntry:GetModel(CustomRoomModel)
    if CustomRoomModel:IsInEnteringBattle() then
        local Param = { describe = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetailMdt_Enterthebattleplease")) }
        UIMessageBox.Show(Param)
        CWaring("[cw] CurState is EnteringBattle, no need to re enter battle")
        return
    end
    
    --2.发送协议进入战斗
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local CurSelRoomId = CustomRoomDetailModel:GetRoomInfo_RoomId()
    local AiTexts = StringUtil.Split(self.View.TxtAINum:GetText(), ":")
    local BattleConfig = {
        AINum = AiTexts[1] or 0,
        AITeamMode = AiTexts[2],
    }

    ---@type CustomRoomCtrl
    local CustomRoomCtrl = MvcEntry:GetCtrl(CustomRoomCtrl)
    CustomRoomCtrl:SendEnterBattleReq(CurSelRoomId, BattleConfig)    
end

---点击右下角返回键
function CustomRoomDetailMdt:OnButtonClicked_Return()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:OnButtonClicked_Return()")
    self:OnButtonClicked_ExitRoom()
end

------------------------------------------------------- 事件相关 ---------------------------------------------------------

function CustomRoomDetailMdt:CUSTOM_ROOM_ON_PLAYER_INFO_RSP_func()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:CUSTOM_ROOM_ON_PLAYER_INFO_RSP_func()")
    self:UpdatePlayerCount()
end

function CustomRoomDetailMdt:CUSTOM_ROOM_ON_ROOM_MASTER_INFO_SYNC_func()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:CUSTOM_ROOM_ON_ROOM_MASTER_INFO_SYNC_func()")
    self:UpdateTitle()
    self:UpdateBottomBtnsDisplay()
end

function CustomRoomDetailMdt:CUSTOM_ROOM_ON_ROOM_HERO_LIST_RSP_func()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:CUSTOM_ROOM_ON_ROOM_HERO_LIST_RSP_func()")
    self:UpdateHeroList()
end

function CustomRoomDetailMdt:CUSTOM_ROOM_ON_TEAM_LIST_RSP_func()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:CUSTOM_ROOM_ON_TEAM_LIST_RSP_func()")
    self:UpdateHeroList()
    self:UpdateTeamList()
end

function CustomRoomDetailMdt:CUSTOM_ROOM_ON_SELECT_HERO_RSP_func()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:CUSTOM_ROOM_ON_SELECT_HERO_RSP_func()")    
    self:UpdateHeroList()
    self:UpdateTeamList()
end

function CustomRoomDetailMdt:CUSTOM_ROOM_ON_SELECT_TEAM_RSP_func()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:CUSTOM_ROOM_ON_SELECT_TEAM_RSP_func()")
    self:UpdateTeamList()
    self:UpdateHeroList()
end

function CustomRoomDetailMdt:CUSTOM_ROOM_ON_PLAYER_CHANGED_func()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:CUSTOM_ROOM_ON_PLAYER_CHANGED_func()")
    self:UpdatePlayerCount()
end

function CustomRoomDetailMdt:CUSTOM_ROOM_ON_PLAYER_INFO_CHANGED_func()
    CLog("[cw][CustomRoomDetailMdt] CustomRoomDetailMdt:CUSTOM_ROOM_ON_PLAYER_INFO_CHANGED_func()")
    self:UpdateTeamList()
    self:UpdateHeroList()
end

--------------------------------------------------------- end ----------------------------------------------------------

return CustomRoomDetailMdt
