--[[
    自建房房间详情解耦逻辑
]]

local class_name = "CustomRoomDetailLogic"
local CustomRoomDetailLogic = BaseClass(nil, class_name)


function CustomRoomDetailLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    
    self.TheCustomRoomModel = MvcEntry:GetModel(CustomRoomModel)
    self.MsgList = 
    {
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_MASTER_UPDATE, Func = self.ON_ROOM_MASTER_UPDATE },
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_TEAM_MEMBER_UDPATE, Func = self.ON_ROOM_TEAM_MEMBER_UDPATE },
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_REFRESH, Func = self.ON_ROOM_REFRESH_Func },

        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_WATI_ENTING_BATTLE, Func = self.ON_ROOM_WATI_ENTING_BATTLE },
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_WATI_ENTING_BATTLE_BREAK, Func = self.ON_ROOM_WATI_ENTING_BATTLE_BREAK },
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_SPECTATOR_UPDATE, Func = self.ON_ROOM_SPECTATOR_UPDATE },
	}
    self.BindNodes = {
		{UDelegate = self.View.GUIButton_Copy.OnClicked,Func = Bind(self,self.OnMaterIdCopyClick)},
        {UDelegate = self.View.WBP_ReuseList.OnUpdateItem, Func = Bind(self, self.OnUpdateSpectatorItem)},
	}

    self.MasterHeadIconCls = nil

    self.TeamType2ReuseWidget = {
        [1] = self.View.WBP_ReuseList_One,
        [2] = self.View.WBP_ReuseList_Two,
        [4] = self.View.WBP_ReuseList_Four,
    }
    self.Widget2Item = {}
    self.Widget2SpectatorItem = {}
    self.TeamId2TeamItem = {}
    self.IsWaitingEntingBattle = false

    -- 创建房间按钮
    UIHandler.New(self, self.View.WBP_CommonBtn_StartGame, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnClickedStartGame),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetailLogic_Startthegame"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar
    })
end

--[[
    队长发生变更
]]
function CustomRoomDetailLogic:ON_ROOM_MASTER_UPDATE()
    self:UpdateMasterShow();
end
--[[
    成员发生改动（换队伍/变位置）
]]
function CustomRoomDetailLogic:ON_ROOM_TEAM_MEMBER_UDPATE(TeamIdList)
    -- print_r(TeamIdList,"CustomRoomDetailLogic:ON_ROOM_TEAM_MEMBER_UDPATE")
    for _,TeamId in ipairs(TeamIdList) do
        local TeamItem = self.TeamId2TeamItem[TeamId]
        if TeamItem then
            local TeamInfo = self.TheCustomRoomModel:GetTeamInfoByTeamId(TeamId)
            local param = {
                TeamId = TeamId,
                TeamInfo = TeamInfo,
                TeamType = self.CurEnterBaseInfo.TeamType,
            }
            TeamItem:SetData(param)
        end
    end
    self:UpdateTeamsMemeberNumsShow()
end

function CustomRoomDetailLogic:ON_ROOM_REFRESH_Func()
    self:UpdateUI()
end

function CustomRoomDetailLogic:ON_ROOM_WATI_ENTING_BATTLE()
    self.IsWaitingEntingBattle = true
    self:UpdateWaitingEntingBattleShow()
end
function CustomRoomDetailLogic:ON_ROOM_WATI_ENTING_BATTLE_BREAK()
    self.IsWaitingEntingBattle = false
    self:UpdateWaitingEntingBattleShow()
end

function CustomRoomDetailLogic:ON_ROOM_SPECTATOR_UPDATE()
    self.UpdateSpectatorShow()
end

function CustomRoomDetailLogic:OnShow(Param,IsFromCacheTrigger)
    if IsFromCacheTrigger then
        self.Handler:DynamicRegisterOrUnRegister(true)
    end

    self:UpdateUI()
end

function CustomRoomDetailLogic:OnHide()
    self.Handler:DynamicRegisterOrUnRegister(false)
end

function CustomRoomDetailLogic:UpdateUI()
    self.CurEnterRoomInfo = self.TheCustomRoomModel:GetCurEnteredRoomInfo()
    if not self.CurEnterRoomInfo then
        CError("CustomRoomDetailLogic:OnShow CurEnterRoomInfo nil")
        return
    end
    self.CurEnterBaseInfo = self.CurEnterRoomInfo.BaseRoomInfo
    self.CurSelectModeId = self.CurEnterBaseInfo.ConfigId

    -- print_r(self.CurEnterRoomInfo,"CustomRoomDetailLogic:CurEnterRoomInfo")
    local TheRoomCfg = G_ConfigHelper:GetSingleItemById(Cfg_CustomRoomConfig,self.CurSelectModeId)
    self.TeamCountMax = self.CurEnterRoomInfo.TeamNumLimit--TheRoomCfg[Cfg_CustomRoomConfig_P.TeamNumInterval]:Get(2)
    self.TeamMap = self.CurEnterRoomInfo.TeamList
    -- print_r(self.TeamMap,"CustomRoomDetailLogic:TeamMap")

    for TeamType,Widget in pairs(self.TeamType2ReuseWidget) do
        Widget:SetVisibility(TeamType == self.CurEnterBaseInfo.TeamType and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    end
    self.TeamId2TeamItem = {}
    self.ReuseListTeam= self.TeamType2ReuseWidget[self.CurEnterBaseInfo.TeamType]
    self.ReuseListTeam.OnUpdateItem:Add(self.View, Bind(self,self.OnUpdateTeamItem))
    self.ReuseListTeam:Reload(self.TeamCountMax)
    
    --暂时隐藏观战
    self.View.CanvasPanel_Watch:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.WidgetSwitcher_Watch:SetActiveWidgetIndex(self.CurEnterBaseInfo.CanSpectate and 0 or 1)
    self:UpdateBaseShow()
    self:UpdateMasterShow()
    self:UpdateTeamsMemeberNumsShow()
    self:UpdateSpectatorShow()
    self:UpdateWaitingEntingBattleShow(true)
end

function CustomRoomDetailLogic:OnUpdateTeamItem(Handler,Widget, Index)
	local TeamId = Index + 1
	local TeamInfo = self.TeamMap[TeamId] and self.TeamMap[TeamId].PlayerInfoList
    -- if TeamInfo then
    --     print_r(TeamInfo,"CustomRoomDetailLogic:TeamInfo")
    -- end

	local TargetItem = self:CreateItem(Widget)
	if TargetItem == nil then
		return
	end
    local param = {
        TeamId = TeamId,
        TeamInfo = TeamInfo,
        TeamType = self.CurEnterBaseInfo.TeamType,
    }
	TargetItem:SetData(param)
    self.TeamId2TeamItem[TeamId] = TargetItem
end

function CustomRoomDetailLogic:CreateItem(Widget)
	local Item = self.Widget2Item[Widget]
	if not Item then
		Item = UIHandler.New(self,Widget,require("Client.Modules.CustomRoom.CustomRoomDetail.CustomRoomTeamItemLogic"))
		self.Widget2Item[Widget] = Item
	end
	return Item.ViewInstance
end


--[[
    更新基础展示
    模式地图等等
]]
function CustomRoomDetailLogic:UpdateBaseShow()
    local TheTeamTypeCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_CustomRoomTeamTypeCfg,Cfg_CustomRoomTeamTypeCfg_P.TeamNum,self.CurEnterBaseInfo.TeamType)
    local TheModeCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_ModeEntryCfg,self.CurEnterBaseInfo.ConfigId)
    local TheMapCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_SceneEntryCfg,self.CurEnterBaseInfo.SceneId)

    self.View.LbModeName:SetText(TheModeCfg[Cfg_ModeSelect_ModeEntryCfg_P.ModeName])
    self.View.LbMapName:SetText(TheMapCfg[Cfg_ModeSelect_SceneEntryCfg_P.SceneName])
    self.View.LbTeamType:SetText(TheTeamTypeCfg[Cfg_CustomRoomTeamTypeCfg_P.TeamTypeDes])
    self.View.LbViewType:SetText(self.TheCustomRoomModel:GetDesByViewType(self.CurEnterBaseInfo.View))
    self.View.LbRoomIDNumber:SetText(self.CurEnterBaseInfo.CustomRoomId)
end

--[[
    更新房主相关展示
]]
function CustomRoomDetailLogic:UpdateMasterShow()
    -- CommonHeadIcon
    local MasterPlayerInfo = self.TheCustomRoomModel:GetRoomPlayerInfoById(self.CurEnterBaseInfo.MasterId)
    local Param = {
        PlayerId = self.CurEnterBaseInfo.MasterId,
        PlayerName = MasterPlayerInfo.PlayerName,
        FilterOperateList = {CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Chat},
        CloseAutoCheckFriendShow = true,
    }
    if not self.MasterHeadIconCls then
        self.MasterHeadIconCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.MasterHeadIconCls:UpdateUI(Param)
    end

    self.View.LabelPlayerName:SetText((StringUtil.Format(StringUtil.StringTruncationByChar(MasterPlayerInfo.PlayerName, "#")[1])))

    local IsMaster = self.TheCustomRoomModel:IsMaster(MvcEntry:GetModel(UserModel):GetPlayerId())
    self.View.WBP_CommonBtn_StartGame:SetVisibility(IsMaster and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--[[
    更新当前队伍展示
]]
function CustomRoomDetailLogic:UpdateTeamsMemeberNumsShow()
    self.View.LbPlayerCount:SetText(StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"),self.TheCustomRoomModel:GetCurEnterRoomPlayerNum(),self.CurEnterBaseInfo.MaxPlayerNum))
end

--[[
    更新观战列表展示
]]
function CustomRoomDetailLogic:UpdateSpectatorShow()
    self.View.Text_Count:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"), self.CurEnterBaseInfo.CurSpectatorNum, self.CurEnterBaseInfo.MaxSpectatorNum))
    if self.CurEnterBaseInfo.CanSpectate then
        self.View.WBP_ReuseList:Reload(self.CurEnterBaseInfo.MaxSpectatorNum)
    end
end

function CustomRoomDetailLogic:UpdateWaitingEntingBattleShow(IsInit)
    self.View.PanelWaitingEnterGame:SetVisibility(self.IsWaitingEntingBattle and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    if not IsInit then
        if self.IsWaitingEntingBattle then
            InputShieldLayer.Add(180,60,function ()
                CWaring("CustomRoomDetailLogic:UpdateWaitingEntingBattleShow IsWaitingEntingBattle Timeout")
                self.IsWaitingEntingBattle = false
                self:UpdateWaitingEntingBattleShow()
            end)
        else
            InputShieldLayer.Close()
        end
    end
end

function CustomRoomDetailLogic:OnUpdateSpectatorItem(Handler,Widget, Index)
	local Pos = Index + 1
	local SpectatorInfo = self.TheCustomRoomModel:GetSpectatorIdByPos(Pos)

	local TargetItem = self:CreateSpectatorItem(Widget)
	if TargetItem == nil then
		return
	end
    local param = {
        Pos = Pos,
        SpectatorInfo = SpectatorInfo,
    }
	TargetItem:SetData(param)
end

function CustomRoomDetailLogic:CreateSpectatorItem(Widget)
	local Item = self.Widget2SpectatorItem[Widget]
	if not Item then
		Item = UIHandler.New(self,Widget,require("Client.Modules.CustomRoom.CustomRoomDetail.CustomRoomSpectatorItemLogic"))
		self.Widget2SpectatorItem[Widget] = Item
	end
	return Item.ViewInstance
end

function CustomRoomDetailLogic:OnMaterIdCopyClick()
    UE.UGFUnluaHelper.ClipboardCopy(StringUtil.ConvertFText2String(self.CurEnterBaseInfo.CustomRoomId))
    UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetailLogic_Copysucceeded"))
end

--[[
    点击开始游戏
]]
function CustomRoomDetailLogic:OnClickedStartGame()
    if self.IsWaitingEntingBattle then
        return
    end
    --请求开始游戏
    MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_StartGameReq(self.TheCustomRoomModel:GetCurEnteredRoomId())

    -- UIAlert.Show("功能未做")
end



return CustomRoomDetailLogic
