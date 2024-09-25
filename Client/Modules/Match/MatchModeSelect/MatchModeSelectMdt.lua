---
--- Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 大厅匹配入口
--- Created At: 2023/05/09 15:34
--- Created By: 朝文
---

require("Client.Modules.Match.MatchModeSelect.MatchModeSelectModel")
require("Client.Modules.Match.MatchSever.MatchSeverModel")

local class_name = "MatchModeSelectMdt"
---@class MatchModeSelectMdt : GameMediator
MatchModeSelectMdt = MatchModeSelectMdt or BaseClass(GameMediator, class_name)
MatchModeSelectMdt.Enum_PlayModeListDir = {
    Previous = 1,
    Next = 2,
}

function MatchModeSelectMdt:__init()
end

function MatchModeSelectMdt:OnShow(data)
end

function MatchModeSelectMdt:OnHide()
end

-------------------------------------------------------------------------------
---@class MatchModeSelectMdt_Obj:MatchModeSelectMdt
local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = {
        --自建房
        --{ UDelegate = self.GUIButton_CustomRoomEntry.OnClicked,	    Func = self.OnClick_CustomRoomEntry },
        --{ UDelegate = self.GUIButton_CustomRoomEntry.OnHovered,	    Func = self.OnHovered_CustomRoomEntry },
        --{ UDelegate = self.GUIButton_CustomRoomEntry.OnUnhovered,   Func = self.OnUnhovered_CustomRoomEntry },
        -- { UDelegate = self.WBP_CommonBtn_CustomRoom.GUIButton_Main.OnClicked,	    Func = self.OnClick_CustomRoomEntry },
    }

    self.MsgList = {
        --玩法模式列表 <- -> A D 控制
        {Model = InputModel,            MsgName = ActionPressed_Event(ActionMappings.Left),                         Func = Bind(self, self.OnSwitchPlayMode, MatchModeSelectMdt.Enum_PlayModeListDir.Previous)},
        {Model = InputModel,            MsgName = ActionPressed_Event(ActionMappings.Right),                        Func = Bind(self, self.OnSwitchPlayMode, MatchModeSelectMdt.Enum_PlayModeListDir.Next)},
        {Model = InputModel,            MsgName = ActionPressed_Event(ActionMappings.A),                            Func = Bind(self, self.OnSwitchPlayMode, MatchModeSelectMdt.Enum_PlayModeListDir.Previous)},
        {Model = InputModel,            MsgName = ActionPressed_Event(ActionMappings.D),                            Func = Bind(self, self.OnSwitchPlayMode, MatchModeSelectMdt.Enum_PlayModeListDir.Next)},

        --ping值变动
        {Model = MatchSeverModel,       MsgName = MatchSeverModel.ON_MATCH_SERVER_INFO_UPDATED,                     Func = Bind(self, self.ON_MATCH_SERVER_INFO_UPDATED_func)},
        
        --模式选择项目变动
        {Model = MatchModeSelectModel,  MsgName = MatchModeSelectModel.ON_MATCH_MODE_SEL_BATTLE_SEVER_ID_CHANGED,   Func = Bind(self, self.ON_MATCH_MODE_SEL_BATTLE_SEVER_ID_CHANGED_func)},    --已选的战斗服务器变动
        {Model = MatchModeSelectModel,	MsgName = MatchModeSelectModel.ON_MATCH_MODE_SEL_PLAY_MODE_ID_CHANGED,      Func = Bind(self, self.ON_MATCH_MODE_SEL_PLAY_MODE_ID_CHANGED_func) },      --已选的玩法模式id变动
        {Model = MatchModeSelectModel,	MsgName = MatchModeSelectModel.ON_MATCH_MODE_SEL_LEVEL_ID_CHANGED,          Func = Bind(self, self.ON_MATCH_MODE_SEL_LEVEL_ID_CHANGED_func) },          --已选的玩法关卡变动（可能会导致场景id和模式key变动）
        {Model = MatchModeSelectModel,	MsgName = MatchModeSelectModel.ON_MATCH_MODE_SEL_SCENE_ID_CHANGED,          Func = Bind(self, self.ON_MATCH_MODE_SEL_SCENE_ID_CHANGED_func) },          --已选的场景id变动
        {Model = MatchModeSelectModel,	MsgName = MatchModeSelectModel.ON_MATCH_MODE_SEL_MODE_ID_CHANGED,           Func = Bind(self, self.ON_MATCH_MODE_SEL_MODE_ID_CHANGED_func) },           --已选的模式key变动        
        {Model = MatchModeSelectModel,	MsgName = MatchModeSelectModel.ON_MATCH_MODE_FILL_TEAM_CHANGED,             Func = Bind(self, self.ON_MATCH_MODE_FILL_TEAM_CHANGED_func) },             --已选的补满队伍变动
        {Model = MatchModeSelectModel,	MsgName = MatchModeSelectModel.ON_MATCH_MODE_CROSS_PLATFORM_MATCH_CHANGED,  Func = Bind(self, self.ON_MATCH_MODE_CROSS_PLATFORM_MATCH_CHANGED_func) },  --已选的跨平台组队变动
        {Model = MatchModeSelectModel,	MsgName = MatchModeSelectModel.ON_MATCH_MODE_TEAM_TYPE_CHANGED,             Func = Bind(self, self.ON_MATCH_MODE_TEAM_TYPE_CHANGED_func) },             --已选的队伍人数类型变动
        {Model = MatchModeSelectModel,	MsgName = MatchModeSelectModel.ON_MATCH_MODE_PERSPECTIVE_CHANGED,           Func = Bind(self, self.ON_MATCH_MODE_PERSPECTIVE_CHANGED_func) },           --已选的视角变动
        
        --队伍变动
        {Model = TeamModel,             MsgName = TeamModel.ON_ADD_TEAM_MEMBER,                                     Func = Bind(self, self.ON_ADD_TEAM_MEMBER_func)},                           --当队伍人数变动时
        {Model = TeamModel,             MsgName = TeamModel.ON_DEL_TEAM_MEMBER,                                     Func = Bind(self, self.ON_DEL_TEAM_MEMBER_func)},                           --当队伍人数变动时
        {Model = TeamModel,             MsgName = TeamModel.ON_SELF_JOIN_TEAM,                                      Func = Bind(self, self.ON_SELF_JOIN_TEAM_func)},                            --自己加入队伍
        {Model = TeamModel,             MsgName = TeamModel.ON_TEAM_LEADER_CHANGED,                                 Func = Bind(self, self.ON_TEAM_LEADER_CHANGED_func)},                            --自己加入队伍
    }

	local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromOutgameStaticST("SD_ModeMap","1000"),
    }
    self.CommonTabUpBarInstance = UIHandler.New(self,self.WBP_Common_TabUpBar_02,CommonTabUpBar,CommonTabUpBarParam).ViewInstance

    ---@type WCommonBtnTips 详细说明按钮
    self.DetailDescBtn = UIHandler.New(self, self.WBP_CommonBtnTips_PlayModeDetail, WCommonBtnTips,
            {
                OnItemClick = Bind(self, self.OnButtonClick_PlayModeDetail),
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
                CommonTipsID = CommonConst.CT_E,
                TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_detaileddescription_Btn")),
                ActionMappingKey = ActionMappings.E
            }).ViewInstance

    ---@type WCommonBtnTips 确认按钮
    self.ConfirmBtn = UIHandler.New(self, self.WBP_CommonBtn_Confirm, WCommonBtnTips,
            {
                OnItemClick = Bind(self, self.OnButtonClick_Confirm),
                TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_confirm_Btn"),
                CommonTipsID = CommonConst.CT_SPACE,
                ActionMappingKey = ActionMappings.SpaceBar,
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            }).ViewInstance

            
    ---@type WCommonBtnTips 自建房按钮
    self.CustomRoomBtn = UIHandler.New(self, self.WBP_CommonBtn_CustomRoom, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnClick_CustomRoomEntry),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Room', "1179_Btn"),
        CommonTipsID = CommonConst.CT_F,
        ActionMappingKey = ActionMappings.F,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    }).ViewInstance
    
    ---@type WCommonBtnTips 返回按钮
    UIHandler.New(self, self.CommonBtnTips_Back, WCommonBtnTips,
            {
                OnItemClick = Bind(self, self.OnButtonClicked_Return),
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
                CommonTipsID = CommonConst.CT_ESC,
                TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_return_Btn"),
                ActionMappingKey = ActionMappings.Escape
            })
    
    ---@type MatchModeSelectItemWidgetStyle1 补满队伍按钮
    self.FillTeamCheckBox = UIHandler.New(self, self.WBP_ModeSelectItem_FillTeam, require("Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectItemWidgetStyle1"),
            {
                Text = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_Filltheteam")),
                ClickedCallback = Bind(self, self.OnButtonClick_FillTeam),
            }).ViewInstance

    ---@type MatchModeSelectItemWidgetStyle1 跨平台匹配按钮
    self.CrossPlatformMatchCheckBox = UIHandler.New(self, self.WBP_ModeSelectItem_CrossPlatformMatch, require("Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectItemWidgetStyle1"),
            {
                Text = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_Crossplatformmatchin")),
                ClickedCallback = Bind(self, self.OnButtonClick_CrossPlatformMatch),
            }).ViewInstance

    ---@type MatchModeSelectItemWidgetStyle2 单排按钮
    self.TeamTypeSolo = UIHandler.New(self, self.WBP_ModeSelectItem_Solo, require("Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectItemWidgetStyle2"),
            {
                DisplayIconNum = 1,
                DebugText = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_singlerow")),
                ClickedCallback = Bind(self, self.OnButtonClick_Solo),
            }).ViewInstance

    ---@type MatchModeSelectItemWidgetStyle2 双排按钮
    self.TeamTypeDue = UIHandler.New(self, self.WBP_ModeSelectItem_Due, require("Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectItemWidgetStyle2"),
            {
                DisplayIconNum = 2,
                DebugText = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_doublerow")),
                ClickedCallback = Bind(self, self.OnButtonClick_Due),
            }).ViewInstance

    ---@type MatchModeSelectItemWidgetStyle2 四排按钮
    self.TeamTypeQuad = UIHandler.New(self, self.WBP_ModeSelectItem_Quad, require("Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectItemWidgetStyle2"),
            {
                DisplayIconNum = 4,
                DebugText = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_Sipai")),
                ClickedCallback = Bind(self, self.OnButtonClick_Quad),
            }).ViewInstance

    ---@type MatchModeSelectItemWidgetStyle3 第三人称按钮
    self.PerspectiveThird = UIHandler.New(self, self.WBP_ModeSelectItem_TPP, require("Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectItemWidgetStyle3"),
            {
                Text = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_thirdperson")),
                ClickedCallback = Bind(self, self.OnButtonClick_TPP),
            }).ViewInstance

    ---@type MatchModeSelectItemWidgetStyle3 第一人称按钮
    self.PerspectiveFirst = UIHandler.New(self, self.WBP_ModeSelectItem_FPP, require("Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectItemWidgetStyle3"),
            {
                Text = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_firstperson")),
                ClickedCallback = Bind(self, self.OnButtonClick_FPP),
            }).ViewInstance

    ---@type CommonComboBox 服务器列表，因为需要传参，初始化，所以后续再进行赋值
    self.SeverListWidget = nil
    
    self.ServerList = {}        --服务器列表id
    self.CachePlayModeIds = {}  --缓存的玩法模式id
    self.CacheLeveIds = {}      --缓存的关卡id
    self.CacheSceneIds = {}     --缓存当前关卡每个level对应的场景id    
    self.InitSelectId = 0
end

function M:OnShow(Param)

    self.InitSelectId = 0

    if Param and Param.JumpParam and Param.JumpParam:Length() > 0 then
        self.InitSelectId = tonumber(Param.JumpParam[1]) or 0
    end

    --底部模式列表
    self._Widget2PlayModeListItem = {}
    self.WBP_ReuseList_PlayModeList.OnUpdateItem:Add(self, self.OnPlayModeListItemUpdate)

    --右侧场景列表
    self._Widget2SceneItem = {}
    self.WBP_ReuseList_Scene.OnUpdateItem:Add(self, self.OnItemSceneUpdate)

    --TODO: 目前不显示排位相关
    -- self.WBP_RankWidget:SetVisibility(UE.ESlateVisibility.Collapsed)

    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    --初始化服务器列表展示
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    self.ServerList = MatchSeverModel:GetDataList()
    local IsShowModeSelectServerList = MatchModeSelectModel:GetIsShowModeSelectServerList()
    self.WBP_ModeMapServerList:SetVisibility(IsShowModeSelectServerList and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.SeverListWidget = UIHandler.New(self, self.WBP_ModeMapServerList, CommonComboBox, {
        OptionList = self.ServerList,
        DefaultSelect = 1,
        SelectCallBack = Bind(self, self.OnSeverSelectionChanged),
        ListItemClass = "Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectSeverItem"
    }).ViewInstance
    
    --默认设置选中的服务器，并触发后续刷新，玩法模式等
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local SeverId = MatchModel:GetSeverId()
    if not SeverId then
        CWaring("[cw] Delay not got yet, choose first DsGroupId as SeverId")
        local _, severCfg = next(MatchSeverModel:GetDataList())
        SeverId = severCfg and severCfg.DsGroupId
        MatchModel:SetSeverId(SeverId)
    end
    MatchModeSelectModel:_SetCurSelServeId(SeverId)
end

function M:OnHide()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    MatchModeSelectModel:_CleanCurSelServeId()
    MatchModeSelectModel:_CleanCurSelFillTeam()
    MatchModeSelectModel:_CleanCurSelCrossPlatformMatch()
    MatchModeSelectModel:_CleanCurSelPlayModeId()
    MatchModeSelectModel:_CleanCurSelLevelId()
    MatchModeSelectModel:_CleanCurSelSceneId()
    MatchModeSelectModel:_CleanCurSelModeId()
    MatchModeSelectModel:_CleanCurSelTeamType()
    MatchModeSelectModel:_CleanCurSelPerspective()

    self.WBP_ReuseList_PlayModeList.OnUpdateItem:Clear()
    self.WBP_ReuseList_Scene.OnUpdateItem:Clear()

    if self.CountDownTimer then
        Timer.RemoveTimer(self.CountDownTimer)
        self.CountDownTimer = nil
    end
    self.InitSelectId = 0
end

--------------------------------------------------------- 背景 --------------------------------------------------------- 
--region
---更新背景图片展示
function M:UpdateBg()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local SelPlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local ImgPath = MatchModeSelectModel:GetPlayModeCfg_BigBackgroundImgPath(SelPlayModeId)
    CommonUtil.SetBrushFromSoftObjectPath(self.Img_Bg, ImgPath)
end
--endregion
---------------------------------- 上方区域 (玩法模式名、模式剩余时间、模式描述、模式详情、服务器列表) -----------------------------
--region

---更新模式名
function M:Update_PlayModeName()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local PlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local PlayModeName = MatchModeSelectModel:GetPlayModeCfg_PlayModeName(PlayModeId)
    self.Text_PlayModeName:SetText(PlayModeName)
end

---更新剩余时间
function M:Update_PlayModeLeftTime()
    if self.CountDownTimer then
        Timer.RemoveTimer(self.CountDownTimer)
        self.CountDownTimer = nil
    end
    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local PlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local startTime = MatchModeSelectModel:GetPlayModeCfg_StartTime(PlayModeId) or -1
    local endTime = MatchModeSelectModel:GetPlayModeCfg_EndTime(PlayModeId) or -1
    local IsOpen = MatchModeSelectModel:GetPlayModeCfg_IsOpen(PlayModeId)

    --这里说明是永久开放的
    if startTime == 0 and endTime == 0 then
        --隐藏倒计时相关控件
        self.Canvas_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Text_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
        
    --这里配置了开启时间
    else
        local curTimeStamp = GetTimestamp()
        --入口开启了且再时间限制内
        if startTime <= curTimeStamp and curTimeStamp <= endTime and IsOpen then
            local function _UpdateTIme()
                local _timeStamp = GetTimestamp()
                local dif = endTime - _timeStamp
                local timeStr = TimeUtils.GetTimeString_CountDownStyle(dif)
                self.Text_Time:SetText(timeStr)
                return dif
            end

            --显示倒计时相关控件，并初始化显示文字
            _UpdateTIme()
            self.Canvas_Time:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Text_Time:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

            --开始倒计时
            self.CountDownTimer = Timer.InsertTimer(1, function()
                local dif = _UpdateTIme()
                if dif == 0 then
                    --TODO: 这里应该触发一个刷新事件                    
                end
            end, true)

        --未开启
        else
            --隐藏倒计时相关控件
            self.Canvas_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.Text_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

---更新模式描述
function M:Update_PlayModeDesc()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local PlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local PlayModeDesc = MatchModeSelectModel:GetPlayModeCfg_PlayModeDesc(PlayModeId)
    self.Text_PlayModeDesc:SetText(PlayModeDesc)
end

---打开玩法详情弹窗
function M:OnButtonClick_PlayModeDetail()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local Params = {
        PlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    }
    MvcEntry:OpenView(ViewConst.MatchModeSelect_PopMessageMdt, Params)    

    -- 触发红点
    self:InteractRedDot()
end

---服务器列表点击回调
---@param selectIndex number 选中的服务器列表索引
function M:OnSeverSelectionChanged(selectIndex)
    if not self.SeverListWidget then return end

    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    local Data = self.ServerList[selectIndex]
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    MatchModeSelectModel:_SetCurSelServeId(Data.DsGroupId)

    local ping = Data.Ping or 0
    local ChangeServerTipText = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "ChangeServerTip"), Data.Area)
    local TipText = StringUtil.Format("<span color=\"#FFFFFF\" size=\"20\">{0}</><span color=\"#22A699\" size=\"20\">{1}</>", ChangeServerTipText, G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "GoodNetworkStatus"))
    if ping > MatchSeverModel.Const.MaxYellowDelay then
        UIAlert.Show(StringUtil.Format(TipText))
    elseif ping > MatchSeverModel.Const.MaxGreenDelay then
        UIAlert.Show(StringUtil.Format(TipText))
    else
        UIAlert.Show(StringUtil.Format(TipText))
    end
end

---更新已选择的服务器信息
--- 地域 地区 延迟
function M:UpdateSelectSeverDisplay()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local SelectedSeverId = MatchModeSelectModel:_GetCurSelServeId()
    if not SelectedSeverId then return end
    
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    local Data = MatchSeverModel:GetData(SelectedSeverId)
    if not Data then return end
    
    local Root = self.SeverListWidget.View
    --区域和地区文字显示
    Root.Text_SeverRegion:SetText(StringUtil.Format(Data.Region))
    Root.Text_SeverPlace:SetText(StringUtil.Format(Data.Area))    

    --延迟文字
    local delay = MatchSeverModel:GetDsPingByDsGroupId(SelectedSeverId)
    --delay = tonumber(math.min(tonumber(delay), MatchSeverModel.Const.MaxDisplayDelay))    --max 999
    local tip = "{0}ms"
    --延迟文字颜色
    if delay <= MatchSeverModel.Const.MaxGreenDelay then
        Root.Text_SeverLag:SetColorAndOpacity(self.SeverListWidget.View.Green)     --蓝图字段
    elseif delay <= MatchSeverModel.Const.MaxYellowDelay then
        Root.Text_SeverLag:SetColorAndOpacity(self.SeverListWidget.View.Yellow)    --蓝图字段
    else
        Root.Text_SeverLag:SetColorAndOpacity(self.SeverListWidget.View.Red)       --蓝图字段\
        tip = ">{0}ms"
        delay = MatchSeverModel.Const.MaxYellowDelay
    end
    Root.Text_SeverLag:SetText(StringUtil.Format(tip, delay))
end

--endregion
------------------------------------------ 下方区域 (玩法模式列表、自建房、确认按钮、)------------------------------------------
--region

---更新玩法列表
function M:UpdatePlayModeList()
    self.WBP_ReuseList_PlayModeList:Reload(#self.CachePlayModeIds)
    if self.InitSelectId > 0 then
        local FoundIndex = -1
        for Index, v in ipairs(self.CachePlayModeIds) do
            if v == self.InitSelectId then
                FoundIndex = Index - 1
                break
            end
            if FoundIndex >= 0 then
                break
            end
        end
        if FoundIndex >= 0 then
            Timer.InsertTimer(0.1, function()
                self.WBP_ReuseList_PlayModeList:JumpByIdx(FoundIndex)
                Timer.InsertTimer(0.1, function()
                    MvcEntry:GetModel(MatchModeSelectModel):DispatchType(MatchModeSelectModel.ON_MATCH_MODE_MANUAL_SELECT, self.InitSelectId)
                    self.InitSelectId = 0
                end)
            end)
        end
    end
end

---获取或创建一个使用lua绑定的控件
---@return MatchModeSelectPlayModeItem
function M:_GetOrCreateReusePlayModeListItem(Widget)
    local Item = self._Widget2PlayModeListItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectPlayModeItem"))
        self._Widget2PlayModeListItem[Widget] = Item
    end
    
    return Item.ViewInstance
end

---更新 WBP_ReuseList_PlayModeList 的函数
---@param Widget userdata 控件
---@param Index number 在lua侧使用需要 +1
function M:OnPlayModeListItemUpdate(Widget, Index)
    local FixedIndex = Index + 1

    local PlayModeId = self.CachePlayModeIds[FixedIndex]    
    if not PlayModeId then
        PlayModeId("[cw] Cannot get PlayModeId by FixedIndex: " .. tostring(FixedIndex))
        return
    end
    
	local TargetItem = self:_GetOrCreateReusePlayModeListItem(Widget)
    if not TargetItem then return end

    local Data = {
        PlayModeId = PlayModeId,
        ClickCallback = function() self:OnPlayModeListItemClicked(PlayModeId) end
    }    
    TargetItem:SetData(Data)
    TargetItem:UpdateView()
    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local SelPlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    if SelPlayModeId == PlayModeId then
        TargetItem:SwitchState_Select()
    else
        TargetItem:SwitchState_Unselect()
    end    
end

---玩法模式item点击回调
function M:OnPlayModeListItemClicked(PlayModeId)
    CLog("[cw] PlayModeId: " .. tostring(PlayModeId))
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    MatchModeSelectModel:_SetCurSelPlayModeId(PlayModeId)

    local ViewParam = {
        ViewId = ViewConst.MatchModeSelect,
        TabId = PlayModeId
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
end

---使用 AD 或 ←→ 控制列表选择
---@param Direction number 方向枚举，参考
---@see MatchModeSelectMdt#Enum_PlayModeListDir
function M:OnSwitchPlayMode(Direction)
    --这里不会有很多模式，先不增加变量记录索引了，遍历一遍吧
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local CurSelPlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local NextPlayModeIndex
    for i = 1, #self.CachePlayModeIds do
        if self.CachePlayModeIds[i] == CurSelPlayModeId then
            if Direction == MatchModeSelectMdt.Enum_PlayModeListDir.Next then
                if i == #self.CachePlayModeIds then
                    NextPlayModeIndex = 1
                else
                    NextPlayModeIndex = i + 1
                end
            elseif Direction == MatchModeSelectMdt.Enum_PlayModeListDir.Previous then
                if i == 1 then
                    NextPlayModeIndex = #self.CachePlayModeIds
                else
                    NextPlayModeIndex = i - 1
                end
            end
            break
        end
    end

    local NextPlayModeId = self.CachePlayModeIds[NextPlayModeIndex]
    if NextPlayModeId == CurSelPlayModeId then return end

    MatchModeSelectModel:_SetCurSelPlayModeId(NextPlayModeId)
    self.WBP_ReuseList_PlayModeList:JumpByIdxStyle(NextPlayModeIndex - 1, UE.EReuseListJumpStyle.Content)
end

---更新确认按钮显示
function M:Update_ConfirmBtn()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local IsOpen = MatchModeSelectModel:GetPlayModeCfg_IsOpen(MatchModeSelectModel:_GetCurSelPlayModeId())
    local IsPlayModeInTime = MatchModeSelectModel:GetPlayModeCfg_IsInTime(MatchModeSelectModel:_GetCurSelPlayModeId())
    local IsLevelInTime = MatchModeSelectModel:GetGameLevelEntryCfg_IsInTime(MatchModeSelectModel:_GetCurSelLevelId())
    local IsFullFill = MatchModeSelectModel:IsAllMatchDataSelected()
        
    --不可用
    if not IsOpen or not IsFullFill or not IsPlayModeInTime or not IsLevelInTime then
        self.ConfirmBtn:SetBtnEnabled(false, StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_Notavailable_Btn")))
    --可用
    else
        self.ConfirmBtn:SetBtnEnabled(true, StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_confirm_Btn")))
    end
end

---内部存储数据
function M:_InternalSaveData()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    --整理玩家当前设置的数据
    local SeverId = MatchModeSelectModel:_GetCurSelServeId()
    local PlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local Perspective = MatchModeSelectModel:_GetCurSelPerspective()
    local TeamType = MatchModeSelectModel:_GetCurSelTeamType()
    local LevelId = MatchModeSelectModel:_GetCurSelLevelId()
    local SceneId = MatchModeSelectModel:_GetCurSelSceneId()
    local ModeId = MatchModeSelectModel:_GetCurSelModeId()
    local IsCrossPlayFormMatch = MatchModeSelectModel:_GetCurSelCrossPlatformMatch()
    local IsFillTeam = MatchModeSelectModel:_GetCurSelFillTeam()

    ---@type MatchCtrl
    local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)
    MatchCtrl:ChangeMatchModeInfo({
        PlayModeId         = PlayModeId,
        Perspective        = Perspective,
        TeamType           = TeamType,
        LevelId            = LevelId,
        SceneId            = SceneId,
        ModeId             = ModeId,
        CrossPlatformMatch = IsCrossPlayFormMatch,
        FillTeam           = IsFillTeam,
        SeverId            = SeverId,
    })
end

---确认按钮点击回调
function M:OnButtonClick_Confirm()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local IsFullFill = MatchModeSelectModel:IsAllMatchDataSelected()
    local IsPlayModeInTime = MatchModeSelectModel:GetPlayModeCfg_IsInTime(MatchModeSelectModel:_GetCurSelPlayModeId())
    local IsLevelInTime = MatchModeSelectModel:GetGameLevelEntryCfg_IsInTime(MatchModeSelectModel:_GetCurSelLevelId())
    local CurSelPlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local IsOpen = MatchModeSelectModel:GetPlayModeCfg_IsOpen(CurSelPlayModeId)

    if not IsOpen or not IsFullFill or not IsPlayModeInTime or not IsLevelInTime then return end    

    --如果是队员操作，则阻挡一下
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if TeamModel:IsSelfTeamNotCaptain() then
        UIAlert(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_Onlythecaptaincancha")))
        return
    end

    --如果所选择的模式和已选的模式一样，则不需要处理
    if MatchModeSelectModel:IsSameConfigWithMatchModel() then
        MvcEntry:CloseView(ViewConst.MatchModeSelect)
        return
    end
    
    local msgParam = {
        describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_Doyouwanttosavethemo")),
        leftBtnInfo = {
            name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_cancel")),
            iconID = CommonConst.CT_BACK,
            actionMappingKey = ActionMappings.Escape,
        },
        rightBtnInfo = {
            name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_preserve_Btn")),
            callback = function() 
                self:_InternalSaveData()
                MvcEntry:CloseView(ViewConst.MatchModeSelect)
            end,
            iconID = CommonConst.CT_SPACE,
            actionMappingKey = ActionMappings.SpaceBar,
        },
    }
    UIMessageBox.Show(msgParam)
end

---返回按钮点击回调
function M:OnButtonClicked_Return()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    if not MatchModeSelectModel:IsSameConfigWithMatchModel() then
        local msgParam = {
            describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_Doyouwanttosavethemo")),
            leftBtnInfo = {
                name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_no_Btn")),
                callback = function() MvcEntry:CloseView(ViewConst.MatchModeSelect) end,
                iconID = CommonConst.CT_BACK,
                actionMappingKey = ActionMappings.Escape,
            },
            rightBtnInfo = {
                name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_preserve_Btn")),
                callback = function() 
                    self:_InternalSaveData()
                    MvcEntry:CloseView(ViewConst.MatchModeSelect)
                end,
                iconID = CommonConst.CT_SPACE,
                actionMappingKey = ActionMappings.SpaceBar,
            },
        }
        UIMessageBox.Show(msgParam)
        return
    end
    
    MvcEntry:CloseView(ViewConst.MatchModeSelect)
end

---自建房相关
function M:OnClick_CustomRoomEntry()
    MvcEntry:OpenView(ViewConst.CustomRoomPanel)
end
function M:OnHovered_CustomRoomEntry() end
function M:OnUnhovered_CustomRoomEntry() end

--endregion
----------------------------------- 中间&右侧区域 (场景列表、补满队伍、跨平台匹配、队伍人数、视角) --------------------------------
--region

--region WBP_ReuseList_Scene
function M:UpdateSceneList()
    self.WBP_ReuseList_Scene:Reload(#self.CacheSceneIds)
end

---获取或创建一个使用lua绑定的控件
---@return MatchModeSelectSceneItem
function M:_GetOrCreateReuseSceneItem(Widget)
    local Item = self._Widget2SceneItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.Match.MatchModeSelect.MatchModeSelectWidgets.MatchModeSelectSceneItem"))
        self._Widget2SceneItem[Widget] = Item
    end
    
    return Item.ViewInstance
end

---更新 WBP_ReuseList_Scene 的函数
---@param Widget userdata 控件
---@param Index number 在lua侧使用需要 +1
function M:OnItemSceneUpdate(Widget, Index)
    local FixedIndex = Index + 1

    local LevelId = self.CacheLeveIds[FixedIndex]
    local SceneId = self.CacheSceneIds[FixedIndex]
    if not SceneId then
        CLog("[cw] Cannot get SceneId by FixedIndex: " .. tostring(FixedIndex))
        return
    end
    
	local TargetItem = self:_GetOrCreateReuseSceneItem(Widget)
    if not TargetItem then return end

    local Data = {
        LevelId = LevelId,
        SceneId = SceneId,
        ClickCallback = function() self:OnSceneListItemClicked(LevelId) end
    }
    
    TargetItem:SetData(Data)
    TargetItem:UpdateView()
end

---场景列表item点击回调
function M:OnSceneListItemClicked(LevelId)
    CLog("[cw] M:OnSceneListItemClicked(" .. string.format("%s", LevelId) .. ")")
    
    --目前这里是不可用点击的，每个模式下只有一个可以用的场景，这里不应该有选择的功能
    -----@type MatchModeSelectModel
    --local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    --local curSelLevelId = MatchModeSelectModel:_GetCurSelLevelId()
    --if curSelLevelId == LevelId then CLog("[cw] same LevelId with last, return") return end
    --
    --MatchModeSelectModel:_SetCurSelLevelId(LevelId)
end

--endregion WBP_ReuseList_Scene

--region 补满队伍
---更新补满队伍显示
function M:Update_FillTeam()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local PlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local IsAllowAutoFill = MatchModeSelectModel:GetPlayModeCfg_IsAllowAutoFill(PlayModeId)
    
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local MyTeamMemberCount = TeamModel:GetMyTeamMemberCount()
    local TeamType = MatchModeSelectModel:_GetCurSelTeamType()
    -- local IsSuit = MyTeamMemberCount <= (TeamType or 0)
    -- 相等的时候，也是不适用补满队伍的 @chenyishui
    local IsSuit = MyTeamMemberCount < (TeamType or 0)
    
    --不适用或者当前队伍人数大于等于所选的队伍人数
    if not IsAllowAutoFill or not IsSuit then
        self.FillTeamCheckBox:SwitchState_Unavailable()
        return
    end
    
    --可用选中
    if MatchModeSelectModel:_GetCurSelFillTeam() then
        self.FillTeamCheckBox:SwitchState_Select()
        
    --可用未选中
    else
        self.FillTeamCheckBox:SwitchState_Normal()
    end
end

---补满队伍点击回调
function M:OnButtonClick_FillTeam()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local PlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local IsAllowAutoFill = MatchModeSelectModel:GetPlayModeCfg_IsAllowAutoFill(PlayModeId)
    if not IsAllowAutoFill then return end
    
    local IsSelected = MatchModeSelectModel:_GetCurSelFillTeam()
    MatchModeSelectModel:_SetCurSelFillTeam(not IsSelected)
end
--endregion

--region 跨平台匹配
---更新跨平台匹配显示
function M:Update_CrossPlatformMatch()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local PlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local IsCrossPlayFormMatch = MatchModeSelectModel:GetPlayModeCfg_IsCrossPlayFormMatch(PlayModeId)
        
    --不适用
    if not IsCrossPlayFormMatch then
        self.CrossPlatformMatchCheckBox:SwitchState_Unavailable()
        return 
    end
    
    --可用选中
    if MatchModeSelectModel:_GetCurSelCrossPlatformMatch() then
        self.CrossPlatformMatchCheckBox:SwitchState_Select()
        
    --可用未选中
    else
        self.CrossPlatformMatchCheckBox:SwitchState_Normal()
    end
end

---跨平台匹配点击回调
function M:OnButtonClick_CrossPlatformMatch()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local PlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local IsCrossPlayFormMatch = MatchModeSelectModel:GetPlayModeCfg_IsCrossPlayFormMatch(PlayModeId)
    if not IsCrossPlayFormMatch then return end    
    
    local IsSelected = MatchModeSelectModel:_GetCurSelCrossPlatformMatch()
    MatchModeSelectModel:_SetCurSelCrossPlatformMatch(not IsSelected)
end
--endregion

--region 队伍模式
---更新队伍模式显示
function M:Update_TeamType()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)    
    local CurPlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local MatchConst = require("Client.Modules.Match.MatchConst")
    local TeamType = MatchModeSelectModel:_GetCurSelTeamType()    
    local function _InnerSwitch(checkFunc, teamType, widgetName)
        if checkFunc(MatchModeSelectModel, CurPlayModeId) then
            if TeamType == teamType then self[widgetName]:SwitchState_Select() else self[widgetName]:SwitchState_UnSelect() end
        else
            self[widgetName]:SwitchState_Unavailable()
        end
    end
    
    _InnerSwitch(MatchModeSelectModel.GetPlayModeCfg_TeamType_Solo,  MatchConst.Enum_TeamType.solo, "TeamTypeSolo")
    _InnerSwitch(MatchModeSelectModel.GetPlayModeCfg_TeamType_Duo,   MatchConst.Enum_TeamType.duo,  "TeamTypeDue")
    _InnerSwitch(MatchModeSelectModel.GetPlayModeCfg_TeamType_Squad, MatchConst.Enum_TeamType.squad,"TeamTypeQuad")
end

---单人模式点击回调
function M:OnButtonClick_Solo()
    CLog("[cw] M:OnButtonClick_Solo()")
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local MatchConst = require("Client.Modules.Match.MatchConst")
    MatchModeSelectModel:_SetCurSelTeamType(MatchConst.Enum_TeamType.solo)
end

---双人模式点击回调
function M:OnButtonClick_Due()
    CLog("[cw] M:OnButtonClick_Due()")
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local MatchConst = require("Client.Modules.Match.MatchConst")
    MatchModeSelectModel:_SetCurSelTeamType(MatchConst.Enum_TeamType.duo)
end

---四人模式点击回调
function M:OnButtonClick_Quad()
    CLog("[cw] M:OnButtonClick_Quad()")
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local MatchConst = require("Client.Modules.Match.MatchConst")
    MatchModeSelectModel:_SetCurSelTeamType(MatchConst.Enum_TeamType.squad)
end
--endregion

--region 视角
---更新视角显示
function M:Update_Perspective()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local CurPlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local Perspective = MatchModeSelectModel:_GetCurSelPerspective()
    local function _InnerSwitch(checkFunc, perspective, widgetName)
        if checkFunc(MatchModeSelectModel, CurPlayModeId) then
            if Perspective == perspective then self[widgetName]:SwitchState_Select() else self[widgetName]:SwitchState_UnSelect() end
        else
            self[widgetName]:SwitchState_Unavailable()
        end
    end

    local MatchConst = require("Client.Modules.Match.MatchConst")
    _InnerSwitch(MatchModeSelectModel.GetPlayModeCfg_Perspective_FPP, MatchConst.Enum_View.fpp, "PerspectiveFirst")
    _InnerSwitch(MatchModeSelectModel.GetPlayModeCfg_Perspective_TPP, MatchConst.Enum_View.tpp, "PerspectiveThird")
end

---点击第三人称视角按钮回调
function M:OnButtonClick_TPP()
    CLog("[cw] M:OnButtonClick_TPP()")
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local MatchConst = require("Client.Modules.Match.MatchConst")
    MatchModeSelectModel:_SetCurSelPerspective(MatchConst.Enum_View.tpp)
end

---点击第一人称视角按钮回调
function M:OnButtonClick_FPP()
    CLog("[cw] M:OnButtonClick_FPP()")
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local MatchConst = require("Client.Modules.Match.MatchConst")
    MatchModeSelectModel:_SetCurSelPerspective(MatchConst.Enum_View.fpp)
end
--endregion

--endregion
-------------------------------------- 事件相关 (每个已选择的参数的变动，会引起其他参数的变动)------------------------------------
--region

---服务器id更新
function M:ON_MATCH_MODE_SEL_BATTLE_SEVER_ID_CHANGED_func()
    --1.更新服务器展示
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local SelectedSeverId = MatchModeSelectModel:_GetCurSelServeId()
    self:UpdateSelectSeverDisplay()
    
    --2.更新玩法模式列表
    --  如果没有配置玩法模式id，则需隐藏一些东西
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    self.CachePlayModeIds = MatchSeverModel:GetData(SelectedSeverId).GameplayIds
    if not next(self.CachePlayModeIds) then        
        --清空玩法模式、玩法描述、时间、背景
        self:UpdateBg()
        self:Update_PlayModeName()
        self:Update_PlayModeLeftTime()
        self:Update_PlayModeDesc()
        
        --清空玩法模式(PlayModeId)
        self.CachePlayModeIds = {}
        self:UpdatePlayModeList()
        MatchModeSelectModel:_CleanCurSelPlayModeId()
        self:Update_CrossPlatformMatch()
        self:Update_FillTeam()

        --清空关卡(LevelId)
        self.CacheLeveIds = {}
        MatchModeSelectModel:_CleanCurSelLevelId()

        --清空场景(SceneId)
        self.CacheSceneIds = {}
        self:UpdateSceneList()
        MatchModeSelectModel:_CleanCurSelSceneId()

        --清空模式(ModeId)        
        MatchModeSelectModel:_CleanCurSelModeId()

        --清空队伍类型(TeamMode)
        MatchModeSelectModel:_CleanCurSelTeamType()
        self:Update_TeamType()
        
        --清空视角(Perspective)
        MatchModeSelectModel:_CleanCurSelPerspective()
        self:Update_Perspective()

        --更新按钮显示
        self:Update_ConfirmBtn()
        return
    end

    --3.这里需要看一下存不存在与已选择的PlayModeId一样的模式id，如果有则选择，没有的话则选择第一个
    -- print_r(self.CachePlayModeIds, "[cw] ====self.CachePlayModeIds")
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local PlayModeId = MatchModel:GetPlayModeId()
    local bFound = false
    for _, CurPlayModeId in pairs(self.CachePlayModeIds) do
        if CurPlayModeId == PlayModeId then
            bFound = true
            break
        end
    end
    --如果当前列表没有已选择的模式，则选择第一个
    if not bFound then 
        local newPlayModeId = self.CachePlayModeIds[next(self.CachePlayModeIds)]
        CLog("[cw] select PlayModeId(" .. tostring(PlayModeId) .. ") is not found in this list, change to " .. tostring(newPlayModeId) .. "")
        PlayModeId = newPlayModeId
    end
    MatchModeSelectModel:_SetCurSelPlayModeId(PlayModeId)
end

---服务器列表中的信息更新了，这里需要更新一下各个服务器的延迟
function M:ON_MATCH_SERVER_INFO_UPDATED_func()
    self:UpdateSelectSeverDisplay()
end

---玩法模式Id(PlayModeId)更新
---     1.模式名
---     2.模式描述
---     3.模式背景
---     4.模式剩余时间
---     5.玩法模式列表更新
---     6.补满队伍 
---     7.跨平台匹配 
---     8.可选队伍类型更新
---     9.可选视角更新
---     10.LevelId列表更新排序
---     11.选中第一个LevelId
---         SceneId 更新
---             场景列表刷新
---         ModeId 更新
---         确认按钮状态
function M:ON_MATCH_MODE_SEL_PLAY_MODE_ID_CHANGED_func()
    --TODO: 这里默认解锁，未解锁逻辑后续处理 by bailixi
    self.WidgetSwitcher_Scene:SetActiveWidgetIndex(1)

    -- 1.模式名
    self:Update_PlayModeName()

    --2.模式描述    
    self:Update_PlayModeDesc()

    --3.模式背景    
    self:UpdateBg()

    --4.模式剩余时间    
    self:Update_PlayModeLeftTime()

    --5.玩法模式列表更新    
    self:UpdatePlayModeList()

    --这里需要延迟更新一下东西
    self._delayUpdate = true
    self._delayUpdateFunc = {}
    
    --6.补满队伍
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local PlayModeId = MatchModel:GetPlayModeId()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local CurSelectPlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()    
    --6.1.如果所选模式和已选的模式是同一个，则使用相同的补满队伍选项
    local IsAllowAutoFill = MatchModeSelectModel:GetPlayModeCfg_IsAllowAutoFill(CurSelectPlayModeId)
    if PlayModeId == CurSelectPlayModeId then
        if not IsAllowAutoFill then
            --如果不可用，则说明策划期望此项默认勾选不可改变
            MatchModeSelectModel:_SetCurSelFillTeam(true)
        else
            local IsFillTeam = MatchModel:GetIsFillTeam()
            MatchModeSelectModel:_SetCurSelFillTeam(IsFillTeam)
        end
    --6.2.否则就勾上（0表示策划希望默认勾选，且不能改变；1表示策划默认用户勾选，且允许用户取消勾选）
    else
        MatchModeSelectModel:_SetCurSelFillTeam(true)
    end
    --self:Update_FillTeam()
    
    --7.跨平台匹配
    --7.1.如果所选模式和已选的模式是同一个，则使用相同的跨平台匹配选项
    if PlayModeId == CurSelectPlayModeId then
        local IsCrossPlayFormMatch = MatchModel:GetIsCrossPlatformMatch()
        MatchModeSelectModel:_SetCurSelCrossPlatformMatch(IsCrossPlayFormMatch)
    --7.2.否则遵循使用配置默认的选项
    else
        local IsAllowCrossPlatformMatch = MatchModeSelectModel:GetPlayModeCfg_IsCrossPlayFormMatch(CurSelectPlayModeId)
        MatchModeSelectModel:_SetCurSelCrossPlatformMatch(IsAllowCrossPlatformMatch)
    end
    --self:Update_CrossPlatformMatch()
    
    --8.可选队伍类型更新    
    --8.1.如果所选模式和已选的模式是同一个，则使用相同的队伍模式
    if PlayModeId == CurSelectPlayModeId then
        local teamType = MatchModel:GetTeamType()
        MatchModeSelectModel:_SetCurSelTeamType(teamType)
    --8.2.否则遵循优先选择 四排>双排>单排
    else
        local MatchConst = require("Client.Modules.Match.MatchConst")
        if MatchModeSelectModel:GetPlayModeCfg_TeamType_Squad(CurSelectPlayModeId) then
            CLog("[cw] GetPlayModeCfg_TeamType_Squad")
            MatchModeSelectModel:_SetCurSelTeamType(MatchConst.Enum_TeamType.squad)
        elseif MatchModeSelectModel:GetPlayModeCfg_TeamType_Duo(CurSelectPlayModeId) then
            CLog("[cw] GetPlayModeCfg_TeamType_Duo")
            MatchModeSelectModel:_SetCurSelTeamType(MatchConst.Enum_TeamType.duo)
        elseif MatchModeSelectModel:GetPlayModeCfg_TeamType_Solo(CurSelectPlayModeId) then
            CLog("[cw] GetPlayModeCfg_TeamType_Solo")
            MatchModeSelectModel:_SetCurSelTeamType(MatchConst.Enum_TeamType.solo)
        end
    end

    --9.可选视角更新
    --9.1.如果所选模式和已选的模式是同一个，则使用相同的视角
    if PlayModeId == CurSelectPlayModeId then
        local perspective = MatchModel:GetPerspective()
        MatchModeSelectModel:_SetCurSelPerspective(perspective)
    --9.2.否则遵循优先选择 第三人称>第一人称
    else
        local MatchConst = require("Client.Modules.Match.MatchConst")
        if MatchModeSelectModel:GetPlayModeCfg_Perspective_TPP(CurSelectPlayModeId) then
            MatchModeSelectModel:_SetCurSelPerspective(MatchConst.Enum_View.tpp)
        elseif MatchModeSelectModel:GetPlayModeCfg_Perspective_FPP(CurSelectPlayModeId) then
            MatchModeSelectModel:_SetCurSelPerspective(MatchConst.Enum_View.fpp)
        end
    end

    --10.LevelId列表更新排序，获取当前选择的玩法模式配置的SceneId和ModeId，在此之前需要先排序
    local LevelIds = MatchModeSelectModel:GetPlayModeCfg_LevelIds(CurSelectPlayModeId) or {}
    -- 10.1 在时间内的排在前面，没有在时间内的排在后面
    local tmpSortList = {}
    for _, levelId in pairs(LevelIds) do
        local tmp = {
            levelId = levelId, 
            startTime = MatchModeSelectModel:GetGameLevelEntryCfg_StartTime(levelId), 
            endTime = MatchModeSelectModel:GetGameLevelEntryCfg_EndTime(levelId), 
            isInTime = MatchModeSelectModel:GetGameLevelEntryCfg_IsInTime(levelId),
        }
        table.insert(tmpSortList, tmp)
    end
    table.sort(tmpSortList, function(a, b)
        if a.isInTime and b.isInTime then
            return a.startTime < b.startTime 
        elseif not a.isInTime and b.isInTime then
            return a.startTime < b.startTime
        elseif a.isInTime then
            return true
        elseif b.isInTime then
            return false
        end
    end)

    -- 10.2 缓存数据
    self.CacheLeveIds = {}
    self.CacheModeIds = {}
    self.CacheSceneIds = {}
    for index, tmpSortInfo in pairs(tmpSortList) do
        self.CacheLeveIds[index] = tmpSortInfo.levelId
        self.CacheModeIds[index] = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(tmpSortInfo.levelId)
        self.CacheSceneIds[index] = MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(tmpSortInfo.levelId)
    end

    --11.选中第一个LevelId
    -- 11.1 如果第一个场景有配置，则默认选择第一个场景 
    local defaultSelLevelId = self.CacheLeveIds[1]
    if defaultSelLevelId then
        MatchModeSelectModel:_SetCurSelLevelId(defaultSelLevelId)
        --后续监听 MatchModeSelectModel 中 CurSelLevelId 变动，进行进一步更新
        
    -- 11.2 如果没有LevelId，则需要禁用 补满队伍按钮、跨平台匹配按钮、队伍模式、视角、确定按钮
    else
        -- 11.2.1 清空场景列表数据
        self.CacheSceneIds = {}
        MatchModeSelectModel:_CleanCurSelSceneId()
        self:UpdateSceneList()

        -- 11.2.2 清空模式列表数据 
        self.CacheModeIds = {}
        MatchModeSelectModel:_CleanCurSelModeId()
        
        -- 11.2.3 清空所选的队伍类型
        MatchModeSelectModel:_CleanCurSelTeamType()
        self.TeamTypeSolo:SwitchState_Unavailable()
        self.TeamTypeDue:SwitchState_Unavailable()
        self.TeamTypeQuad:SwitchState_Unavailable()
        
        -- 11.2.4 清空所选的视角
        MatchModeSelectModel:_CleanCurSelPerspective()
        self.PerspectiveFirst:SwitchState_Unavailable()
        self.PerspectiveThird:SwitchState_Unavailable()        

        -- 11.2.5 补满队伍按钮
        self.FillTeamCheckBox:SwitchState_Unavailable()
        
        -- 11.2.6 跨平台匹配按钮
        self.CrossPlatformMatchCheckBox:SwitchState_Unavailable()
        
        -- 11.2.7 确认按钮显示
        self:Update_ConfirmBtn()
    end

    self:RegisterRedDot()
end

---关卡id(LevelId)更新
---     1. SceneId 更新
---         场景列表刷新
---     2. ModeId 更新
---     3. 确认按钮状态
function M:ON_MATCH_MODE_SEL_LEVEL_ID_CHANGED_func()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local curSelLevelId = MatchModeSelectModel:_GetCurSelLevelId()
    if not curSelLevelId then
        MatchModeSelectModel:_CleanCurSelSceneId()
        MatchModeSelectModel:_CleanCurSelModeId()
        CError("[cw] curSelLevelId is nil, please check")
        return
    end
    
    -- 1.SceneId 更新，确定了LevelId之后，就可以马上确定SceneId
    local sceneId = MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(curSelLevelId)
    --有可以选择的场景，则直接选择
    if sceneId then
        MatchModeSelectModel:_SetCurSelSceneId(sceneId)
        --后续监听 MatchModeSelectModel 中 CurSelSceneId 变动，进行进一步更新 
        
    --走到这里说明配置有问题，或者没有配置，清空一下需要展示的列表
    else
        self.CacheSceneIds = {}
        MatchModeSelectModel:_CleanCurSelSceneId()
        self:UpdateSceneList()
    end
    
    -- 2.ModeId 更新，确定了LevelId之后，就可以马上确定ModeId
    local modeId = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(curSelLevelId)
    --有对应的模式id组，则直接选择
    if modeId then
        MatchModeSelectModel:_SetCurSelModeId(modeId)
        --后续监听 MatchModeSelectModel 中 CurSelModeId 变动，进行进一步更新 
        
    --走到这里说明配置有问题，或者没有配置，模式ID为空
    else
        self.CacheModeIds = {}
        MatchModeSelectModel:_CleanCurSelModeId()
    end

    -- 如果没有数据，则说明配置有问题，不要显示按钮了
    if not sceneId or not modeId then
        -- 清空所选的队伍类型
        MatchModeSelectModel:_CleanCurSelTeamType()
        self.TeamTypeSolo:SwitchState_Unavailable()
        self.TeamTypeDue:SwitchState_Unavailable()
        self.TeamTypeQuad:SwitchState_Unavailable()

        -- 清空所选的视角
        MatchModeSelectModel:_CleanCurSelPerspective()
        self.PerspectiveFirst:SwitchState_Unavailable()
        self.PerspectiveThird:SwitchState_Unavailable()

        -- 禁用补满队伍按钮
        self.FillTeamCheckBox:SwitchState_Unavailable()

        -- 禁用跨平台匹配按钮
        self.CrossPlatformMatchCheckBox:SwitchState_Unavailable()
    end
    
    -- 3. 更新确认按钮状态
    self:Update_ConfirmBtn()
end

---场景id(SceneId)发生变动，刷新场景列表
function M:ON_MATCH_MODE_SEL_SCENE_ID_CHANGED_func()
    self:UpdateSceneList()
end

---模式id变动，需要整理出符合的模式key
function M:ON_MATCH_MODE_SEL_MODE_ID_CHANGED_func()
    --目前模式改变并不会影响什么展示
end

---补满队伍选项变动
function M:ON_MATCH_MODE_FILL_TEAM_CHANGED_func()
    self:Update_FillTeam()
end

---跨平台选项变动
function M:ON_MATCH_MODE_CROSS_PLATFORM_MATCH_CHANGED_func()
    self:Update_CrossPlatformMatch()
end

---队伍模式（单排/双排/四排）变动时
function M:ON_MATCH_MODE_TEAM_TYPE_CHANGED_func()
    self:Update_TeamType()
    self:Update_FillTeam()
end

---视角（第一人称/第三人称）变动时
function M:ON_MATCH_MODE_PERSPECTIVE_CHANGED_func()
    self:Update_Perspective()
end

---当人数增加或减少的时候，需要更新一下补满队伍的选项
function M:ON_ADD_TEAM_MEMBER_func() self:Update_FillTeam() end
function M:ON_DEL_TEAM_MEMBER_func() self:Update_FillTeam() end

local function _InnerCloseCheck()
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if TeamModel:IsSelfInTeam() and TeamModel:IsSelfTeamNotCaptain() then
        MvcEntry:CloseView(ViewConst.MatchModeSelect)
        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectMdt_Modeselectionfunctio")))
    end
end

---加入队伍后，非队员需要关闭界面
function M:ON_SELF_JOIN_TEAM_func()
    _InnerCloseCheck()
end

---当队长变动后，非队员需要关闭界面
function M:ON_TEAM_LEADER_CHANGED_func()
    _InnerCloseCheck()
end
--endregion

--------------红点相关--------------
-- 绑定红点
function M:RegisterRedDot()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local SelPlayModeId = MatchModeSelectModel:_GetCurSelPlayModeId()
    local WBP_RedDotFactory = self.WBP_RedDotFactory
    WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local RedDotKey = "LevelDetails_"
    local RedDotSuffix = SelPlayModeId
    if not self.ItemRedDot then
        self.ItemRedDot = UIHandler.New(self, WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
    else 
        self.ItemRedDot:ChangeKey(RedDotKey, RedDotSuffix)
    end  
end

-- 红点触发逻辑
function M:InteractRedDot()
    if self.ItemRedDot then
        self.ItemRedDot:Interact()
    end
end
--------------红点相关--------------

return M