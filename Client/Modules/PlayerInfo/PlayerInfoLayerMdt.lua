---
--- Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 玩家个人空间框架，子页面搭载用
--- Created At: 2023/08/04 17:08
--- Created By: 朝文
---

--lua.do MvcEntry:OpenView(ViewConst.PlayerInfo)

require("Client.Modules.PlayerInfo.PlayerInfoModel")

local class_name = "PlayerInfoLayerMdt"
---@class PlayerInfoLayerMdt : GameMediator
PlayerInfoLayerMdt = PlayerInfoLayerMdt or BaseClass(GameMediator, class_name)

function PlayerInfoLayerMdt:__init()
end

function PlayerInfoLayerMdt:OnShow(data) end
function PlayerInfoLayerMdt:OnHide() end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    PlayerInfoLayerMdt.Const = PlayerInfoLayerMdt.Const or {
        TabList = {
            [1] = {
                Id = 1,
                TabName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_personalinformation_Btn")),
                FsmAction = "FSM_OpenPersonalInfoPage",
                ResourceCfg = PlayerInfoModel.Enum_SubPageCfg.PersonalInfoPage,
                ShowOthers = true,
                TitleName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_personalinformation_Btn")),
            },
            [2] = {
                Id = 2,
                TabName = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1062_Btn")),
                FsmAction = "FSM_OpenPersonalStatisticsPage",
                ResourceCfg = PlayerInfoModel.Enum_SubPageCfg.PersonalStatisticsPage,
                ShowOthers = true,
                TitleName = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1062_Btn")),
            },
            [3] = {
                Id = 3,
                TabName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_Historicalrecord_Btn")),
                FsmAction = "FSM_OpenMatchHistoryPage",
                ResourceCfg = PlayerInfoModel.Enum_SubPageCfg.MatchHistoryPage,
                ShowOthers = true,
                TitleName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_Historicalrecord_Btn")),
            },
            [4] = {
                Id = 4,
                TabName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_achievement_Btn")),
                FsmAction = "FSM_OpenAchievementPage",
                ResourceCfg = PlayerInfoModel.Enum_SubPageCfg.AchievementPage,
                ShowOthers = false,
                TitleName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_achievement_Btn")),
            }
        }
    }

    --1.构建一个状态机，用于管理切换状态
    local fsm_C = require("Client.Common.SimpleFSM")
    local initialState = "Empty"
    local events = {
        {eventName = "FSM_OpenPersonalInfoPage",    from = "*",   to = "PersonalInfoPage"},
        {eventName = "FSM_OpenPersonalStatisticsPage",   from = "*",   to = "PersonalStatisticsPage"},
        {eventName = "FSM_OpenMatchHistoryPage",    from = "*",   to = "MatchHistoryPage"},
        {eventName = "FSM_OpenAchievementPage",    from = "*",   to = "AchievementPage"},
    }
    self.fsm = fsm_C(self, initialState, events)

    --1.右下角返回按钮
    UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips,
            {
                OnItemClick = Bind(self, self.OnButtonClicked_Back),
                TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_return_Btn"),
                CommonTipsID = CommonConst.CT_ESC,
                ActionMappingKey = ActionMappings.Escape,
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
            })

    --2.右下角添加好友按钮
    UIHandler.New(self, self.CommonBtnTips_AddFriend, WCommonBtnTips,
            {
                OnItemClick = Bind(self, self.OnButtonClicked_AddFriend),
                TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_Addfriends"),
                CommonTipsID = CommonConst.CT_F,
                ActionMappingKey = ActionMappings.F,
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
            })

    UIHandler.New(self, self.CommonBtnTips_Achievement, WCommonBtnTips,
            {
                OnItemClick = Bind(self, self.OnButtonClicked_Achievement),
                TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_assemble_Btn"),
                CommonTipsID = CommonConst.CT_X,
                ActionMappingKey = ActionMappings.X,
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
            })
    
    UIHandler.New(self, self.CommonBtnTips_Report, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnButtonClicked_Report),
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_Report"),
        CommonTipsID = CommonConst.CT_R,
        ActionMappingKey = ActionMappings.R,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })
    
    self.IsStreamLevelLoading = false

    self.MsgList = {
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.SET_ADD_FRIEND_BTN_ISSHOW, Func = self.SetAddFriendBtnIsShow},
    }
end

--[[
    Param 参考结构
    {
        SelectTabId = 1,        --打开页面选择的页签id，参考 PlayerInfoLayerMdt.Const.TabList 里面的枚举
        PlayerId = 100663302,   --打开用户的用户id（自己的页面有历史战绩的选项）
        OnShowParam = {},       --打开页签时需要传入的参数 any
    }
--]]
function M:OnShow(Param)
    self:UpdateUI(Param)
end

--[[
    Param 参考结构
    {
        SelectTabId = 1,    --打开页面选择的页签id，参考 PlayerInfoLayerMdt.Const.TabList 里面的枚举
        OnShowParam = {},   --打开页签时需要传入的参数 any
    }
--]]
function M:OnRepeatShow(Param)
    self:UpdateUI(Param, true)
end

function M:UpdateUI(Param, IsRepeat)
    IsRepeat = IsRepeat or false
    local _Param = Param or {}
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)    
    if Param and Param.JumpParam and Param.JumpParam:Length() > 0 then
        _Param.SelectTabId= tonumber(Param.JumpParam[1]) or PlayerInfoModel.Const.DefaultSelectTabId
        _Param.PlayerId = UserModel.PlayerId
        _Param.OnShowParam = UserModel.PlayerId
    end
    self.PlayerId = _Param.PlayerId
self.OnShowParam = _Param.OnShowParam
    
    self.IsSelf = UserModel:IsSelf(_Param.PlayerId)

    --重复打开当前界面
    local BeforeSelect = self.TabListCls and self.TabListCls:GetCurSelectID() or PlayerInfoModel.Const.DefaultSelectTabId
    local NewSelectTabId = _Param.SelectTabId or PlayerInfoModel.Const.DefaultSelectTabId
    
    --初始化切换tab列表
    local MenuTabParam = {
        ItemInfoList    = {},
        CurSelectId     = NewSelectTabId,
        ClickCallBack   = Bind(self, self.SwitchTabByIndex),
        ValidCheck      = Bind(self, self.MenuValidCheck),
        HideInitTrigger = true,
        IsOpenKeyboardSwitch = true,
        TabItemType = CommonMenuTabUp.TabItemTypeEnum.TYPE2,
    }
    for i, v in ipairs(PlayerInfoLayerMdt.Const.TabList) do
        local Show = self.IsSelf or (not self.IsSelf and v.ShowOthers)
        if i == 3 and not MvcEntry:GetCtrl(AchievementCtrl).IsOpen then
            Show = false
        end
        if Show then
            table.insert(MenuTabParam.ItemInfoList, {Id =  i, LabelStr = v.TabName})
        end
    end
    local TitleStr = PlayerInfoLayerMdt.Const.TabList and PlayerInfoLayerMdt.Const.TabList[NewSelectTabId] and PlayerInfoLayerMdt.Const.TabList[NewSelectTabId].TitleName or ""
    local CommonTabUpBarParam = {
        TitleTxt = TitleStr,
        TabParam = MenuTabParam
    }
    if not self.TabListCls then
        ---@type CommonMenuTab
        self.TabListCls = UIHandler.New(self, self.WBP_Common_TabUpBar_02, CommonTabUpBar, CommonTabUpBarParam).ViewInstance
    else
        self.TabListCls:RefreshUI(CommonTabUpBarParam)
    end


    --打开自己的界面
    if self.IsSelf then
        --处理货币显示
        self.TabListCls:UpdateCurrency({ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND})
    --打开其他人的界面
    else
        -- if self.TabListCls then self.TabListCls.CurSelectTabId = NewSelectTabId end
        --处理货币显示
        self.TabListCls:UpdateCurrency()
        
        MvcEntry:GetCtrl(AchievementCtrl):GetAchievementInfoReq(_Param.PlayerId)
    end

    local ReportShow = self.IsSelf and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible
    self.CommonBtnTips_Report:SetVisibility(ReportShow)
    
    if IsRepeat and BeforeSelect == NewSelectTabId then
        if self.SubPageContent and self.SubPageContent.OnRepeatShow then self.SubPageContent:OnRepeatShow(self.OnShowParam) end
    else
        local cfg = PlayerInfoLayerMdt.Const.TabList[NewSelectTabId]
        self.fsm[cfg.FsmAction](self.fsm, self.OnShowParam)
    end

    self:SetAchieveBtnIsShow(NewSelectTabId ~= 2 and NewSelectTabId ~= 3, NewSelectTabId == 1)
end

function M:OnHide() 
    -- MvcEntry:GetCtrl(ViewRegister):RegisterVirtualLevelView(ViewConst.PlayerInfo,nil)
end

function M:OnShowAvator()
    if self.SubPageContent and self.SubPageContent.OnShowAvator then
        self.SubPageContent:OnShowAvator()
    end
end

function M:OnHideAvator()
    if self.SubPageContent and self.SubPageContent.OnHideAvator then
        self.SubPageContent:OnHideAvator()
    end
end

---封装一个卸载子界面的方法
function M:UnloadSubPage()
    if not self.SubPageContent then return end

    self.Center:ClearChildren()
    self.SubPageContent = nil
end

---封装一个加载子界面的方法
---@param ConfigData table 参考 PlayerInfoModel.Enum_SubPageCfg.RoomListPage|CreateRoomPage|RoomDetailPage
---@vararg any 构造时所需要的数据
function M:LoadSubPage(ConfigData, ...)
    --1.读取不到配置就弹窗
    local luaPath = ConfigData.LuaPath
    local bpPath = ConfigData.BpPath
    if not luaPath or not bpPath then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_Functionisnotopen"))
        return
    end

    --2.走到这里就说明有配置，则加载对应的蓝图和lua，进行一个挂载
    local WidgetClass = UE4.UClass.Load(bpPath)
    local Widget = NewObject(WidgetClass, self)
    UIRoot.AddChildToPanel(Widget, self.Center)
    self.SubPageContent = UIHandler.New(self, Widget, require(luaPath), self.OnShowParam).ViewInstance
end

---切换页签按钮点击回调
function M:SwitchTabByIndex(Index)
    local cfg = PlayerInfoLayerMdt.Const.TabList[Index]
    if not cfg then return end
    if not self.CommonBtnTips_Achievement then return end
    --修改标题名称
    if self.TabListCls then self.TabListCls:UpdateTitleText(cfg.TitleName) end
    self:SetAchieveBtnIsShow(cfg.Id ~= 2 and cfg.Id ~= 3, cfg.Id == 1)
    --触发状态机转换
    if self.fsm and self.fsm[cfg.FsmAction] then self.fsm[cfg.FsmAction](self.fsm, self.OnShowParam) end

    local ViewParam = {
        ViewId = ViewConst.PlayerInfo,
        TabId = Index
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)

    self:SetBtnNameColorToBlack(Index == 4, self.CommonBtnTips_Achievement)
    self:SetBtnNameColorToBlack(true, self.CommonBtnTips_ESC)
    MvcEntry:GetModel(PlayerInfoModel):SetCurSelectTab(Index)
end

---切换页签按钮检查
function M:MenuValidCheck(Index)
    if self.IsStreamLevelLoading then
        return false
    end
    
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    -- if self.PlayerId ~= UserModel:GetPlayerId() then return false end
    
    local cfg = PlayerInfoLayerMdt.Const.TabList[Index]
    if not cfg or not cfg.ResourceCfg or not cfg.ResourceCfg.LuaPath or not cfg.ResourceCfg.BpPath then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_Functionisnotopen"))
        return false
    end
    
    return true
end

function M:SetAddFriendBtnIsShow(IsShow)
    self.CommonBtnTips_AddFriend:SetVisibility(IsShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end
function M:SetAchieveBtnIsShow(IsShow, SetScale)
    if not MvcEntry:GetCtrl(AchievementCtrl).IsOpen then
        self.CommonBtnTips_Achievement:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    if not self.IsSelf or not IsShow then
        self.CommonBtnTips_Achievement:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.CommonBtnTips_Achievement:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.CommonBtnTips_Achievement:SetRenderScale(not SetScale and UE.FVector2D(1,1) or UE.FVector2D(0,0))
    end 
end

function M:OnButtonClicked_Back()
    -- 当子页存在NeedToHandleClose方法，且返回true时，表示这个关闭操作由子页逻辑控制，不关闭界面
    if not (self.SubPageContent and self.SubPageContent.NeedToHandleClose and self.SubPageContent:NeedToHandleClose()) then        
        MvcEntry:CloseView(ViewConst.PlayerInfo)
    end
end

function M:OnButtonClicked_AddFriend()
    if self.SubPageContent and self.SubPageContent.OnClickAddFriendBtn then
        self.SubPageContent:OnClickAddFriendBtn()
    end
end

function M:OnButtonClicked_Achievement()
    MvcEntry:OpenView(ViewConst.AchievementAssemble)
end

--[[
    举报
]]
function M:OnButtonClicked_Report()
    local PlayerInfo = MvcEntry:GetModel(PersonalInfoModel):GetPlayerDetailInfo(self.PlayerId)
    local ReportConst = require("Client.Modules.Report.ReportConst")
    local Param = {
        ReportScene = ReportConst.Enum_ReportScene.PersonInfo,
        ReportSceneId = ReportConst.Enum_HallReportSceneId.PersonalZone,
        ReportPlayers = {                                                           --【必填】可供举报的玩家列表，至少有一名玩家
            [1] = {
                PlayerId = self.PlayerId,                                                       --【必填】被举报的玩家ID
                PlayerName = PlayerInfo.PlayerName                                           --【必填】被举报的玩家名字
            }
        },
    }
    MvcEntry:GetCtrl(ReportCtrl):HallReport(Param)
end

--[[
    根据页签不同改变右下按钮文字颜色
]]
function M:SetBtnNameColorToBlack(InIsToBlack, InCommonBtnPanel)
    local SlateColor = UE.FSlateColor()
    SlateColor.SpecifiedColor = UIHelper.LinearColor.White--UE.FLinearColor(0.01096, 0.014444, 0.017642, 1)
    if InIsToBlack then
        SlateColor.SpecifiedColor = UIHelper.LinearColor.Black
    end
    InCommonBtnPanel.ControlTipsTxt:SetColorAndOpacity(SlateColor)
end

--------------------------------------------------------- fsm ----------------------------------------------------------

function M:OnStateChanged(Event, From, To, ...)
    CLog("[cw] M:OnStateChanged(" .. string.format("%s, %s, %s", Event, From, To) .. ")")
end

-------------
--- Empty ---
-------------

function M:OnEnter_Empty(Event, From, To, ...)  self:UnloadSubPage()                end
function M:On_Empty(Event, From, To, ...)                                           end
function M:OnLeave_Empty(Event, From, To, ...)                                      end

------------------------
--- PersonalInfoPage ---
------------------------

function M:OnEnter_PersonalInfoPage(Event, From, To, ...)
    self:LoadSubPage(PlayerInfoModel.Enum_SubPageCfg.PersonalInfoPage, ...)
end

function M:On_PersonalInfoPage(Event, From, To, ...)
    self.Bg:SetVisibility(UE.ESlateVisibility.Collapsed)
    local content = self.SubPageContent
    if content and content.UpdateView then
        content:UpdateView()
    end
end

function M:OnLeave_PersonalInfoPage(Event, From, To, ...)
    self:UnloadSubPage()
end

------------------------
--- PersonalStatisticsPage ---
------------------------

function M:OnEnter_PersonalStatisticsPage(Event, From, To, ...)
    self:LoadSubPage(PlayerInfoModel.Enum_SubPageCfg.PersonalStatisticsPage, ...)
end

function M:On_PersonalStatisticsPage(Event, From, To, ...)
    self.Bg:SetVisibility(UE.ESlateVisibility.Collapsed)
    local content = self.SubPageContent
    if content and content.UpdateView then
        content:UpdateView()
    end
end

function M:OnLeave_PersonalStatisticsPage(Event, From, To, ...)
    self:UnloadSubPage()
end

------------------------
--- MatchHistoryPage ---
------------------------

function M:OnEnter_MatchHistoryPage(Event, From, To, ...)
    self:LoadSubPage(PlayerInfoModel.Enum_SubPageCfg.MatchHistoryPage)
end

function M:On_MatchHistoryPage(Event, From, To, ...)
    self.Bg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function M:OnLeave_MatchHistoryPage(Event, From, To, ...)
    self:UnloadSubPage()
end


function M:OnEnter_AchievementPage(Event, From, To, ...)
    self:LoadSubPage(PlayerInfoModel.Enum_SubPageCfg.AchievementPage)
end

function M:On_AchievementPage(Event, From, To, ...)
    self.Bg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function M:OnLeave_AchievementPage(Event, From, To, ...)
    self:UnloadSubPage()
end
--------------------------------------------------------- end ----------------------------------------------------------

return M