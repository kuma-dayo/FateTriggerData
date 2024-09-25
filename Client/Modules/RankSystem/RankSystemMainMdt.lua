--- 视图控制器
local class_name = "RankSystemMainMdt";
RankSystemMainMdt = RankSystemMainMdt or BaseClass(GameMediator, class_name);

function RankSystemMainMdt:__init()
end

function RankSystemMainMdt:OnShow(data)
    
end

function RankSystemMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = 
    {
        {Model = InputModel,MsgName = ActionPressed_Event(ActionMappings.Q),Func = Bind(self, self.OnLastClick)},
        {Model = InputModel,MsgName = ActionPressed_Event(ActionMappings.E),Func = Bind(self, self.OnNextClick)},
        -- {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED, Func = self.OnGetPlayerDetailInfo},
    }

    self.BindNodes = 
    {
		{UDelegate = self.WBP_Rank_Detail.WBP_ReuseList.OnUpdateItem,Func = Bind(self, self.OnUpdateItem)},
	}

    self.Model = MvcEntry:GetModel(RankSystemModel)
    self.SystemCtrl = MvcEntry:GetCtrl(RankSystemCtrl)
    self.CurTabType = 0
    self.CurTabIndex = 0
    self.SelectedModeID = 0
    self.Widget2Item = {}

    UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips, {
        OnItemClick = Bind(self, self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
    })

    self:InitTabInfo()
end

function M:OnHide()
    self.Model = nil
    self.SystemCtrl = nil
    self.CurTabType = 0
    self.CurTabIndex = 0
    self.SelectedModeID = 0
    self.Widget2Item = nil
end

function M:OnShow(Params)
    local ShowTab = (Params and Params.TabType) or 4
    self.TabListCls:Switch2MenuTab(ShowTab, true)
end

function M:OnLastClick()
    if self.CurTabIndex < 0 then
        return
    end
    self.TabListCls:Switch2MenuTab(math.max(self.CurTabIndex - 1, 1))
end

function M:OnNextClick()
    if self.CurTabIndex + 1 > self.MaxTabListNum then
        return
    end
    self.TabListCls:Switch2MenuTab(math.min(self.CurTabIndex + 1, self.MaxTabListNum))
end

--- 初始化tab
function M:InitTabInfo()
    local TypeTabParam = {
        ClickCallBack = Bind(self, self.OnTypeBtnClick),
        ValidCheck = Bind(self, self.TypeValidCheck),
        HideInitTrigger = true,
    }
    TypeTabParam.ItemInfoList = {}

    local Configs = G_ConfigHelper:GetDict(Cfg_RankTypeCfg)
    for _, Cfg in ipairs(Configs) do

        local TabItemInfo = {
            Id = Cfg[Cfg_RankTypeCfg_P.RankType],
            LabelStr = Cfg[Cfg_RankTypeCfg_P.RankTypeName],
            MenuData = Cfg[Cfg_RankTypeCfg_P.RankType]
        }
        TypeTabParam.ItemInfoList[#TypeTabParam.ItemInfoList + 1] = TabItemInfo

    end
    self.MaxTabListNum = #TypeTabParam.ItemInfoList
    local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Rank","1954"),
        CurrencyIDs = {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND},
        TabParam = TypeTabParam
    }
    self.TabListCls = UIHandler.New(self, self.WBP_Common_TabUpBar_02, CommonTabUpBar, CommonTabUpBarParam).ViewInstance
end

function M:TypeValidCheck(Type)
    return true
end

function M:OnTypeBtnClick(Index, ItemInfo, IsInit)
    if not ItemInfo.MenuData then
        CError("[RankSystemMainMdt]OnTypeBtnClick ItemInfo.MenuData is nil")
        return
    end
    self.CurTabIndex = Index
    self.SelectedModeID = 0
    self.CurTabType = ItemInfo.MenuData
    self:UpdateCombobox()
    self:UpdateRankInfo()
end

function M:UpdateRankInfo()
    print( self.CurTabType, self.SelectedModeID)
    local TypeID = self.Model:ConvertType2TypeId(self.CurTabType, self.SelectedModeID)
    self.SystemCtrl:GetRankList(TypeID, nil, Bind(self, self.UpdateRankList, TypeID))
    self:UpdateShowUnit()
end

function M:UpdateRankList(TypeID, List)
    self.RankList = List or {}
    if #self.RankList < 1 then
        self.WBP_Rank_Detail.WidgetSwitcher:SetActiveWidgetIndex(1)
        return
    end
    self.WBP_Rank_Detail.WidgetSwitcher:SetActiveWidgetIndex(0)
    self:UpdateRankForHead()
    local Count = math.max(#self.RankList - 3, 0)
    self.WBP_Rank_Detail.WBP_ReuseList:Reload(Count)
    self:UpdateSelfRankInfo(TypeID)
end

function M:OnGetPlayerDetailInfo()
    self:UpdateRankForHead()
end

function M:UpdateRankForHead()
    if not self.RankList then
        return
    end
    local WBP_Rank_Detail = self.WBP_Rank_Detail
    -- WBP_Rank_Detail.No1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    WBP_Rank_Detail.SwitcherNo2:SetActiveWidgetIndex(1)
    WBP_Rank_Detail.SwitcherNo3:SetActiveWidgetIndex(1)
    if #self.RankList >= 1 then
        -- WBP_Rank_Detail.No1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:UpdateRankForHeadIndex(1, WBP_Rank_Detail.PlayerHead1, WBP_Rank_Detail.PlayerName1, WBP_Rank_Detail.Score1, WBP_Rank_Detail.ListBtn1)
    end
    if #self.RankList >= 2 then
        WBP_Rank_Detail.SwitcherNo2:SetActiveWidgetIndex(0)
        -- WBP_Rank_Detail.No2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:UpdateRankForHeadIndex(2, WBP_Rank_Detail.PlayerHead2, WBP_Rank_Detail.PlayerName2, WBP_Rank_Detail.Score2, WBP_Rank_Detail.ListBtn2)
    end
    if #self.RankList >= 3 then
        WBP_Rank_Detail.SwitcherNo3:SetActiveWidgetIndex(0)
        -- WBP_Rank_Detail.No3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:UpdateRankForHeadIndex(3, WBP_Rank_Detail.PlayerHead3, WBP_Rank_Detail.PlayerName3, WBP_Rank_Detail.Score3, WBP_Rank_Detail.ListBtn3)
    end
end


function M:OnLikeClick(ListBtn, PlayerId)
    ListBtn:StopAnimation(ListBtn.vx_btn_addone)
    ListBtn:PlayAnimation(ListBtn.vx_btn_addone)
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLikeHeartReq(PlayerId)
end

function M:UpdateRankForHeadIndex(Index,InCommonHeadIcon, PlayerNameText, ScoreText, ListBtn)
    if not self.RankList[Index] then
        return
    end
    self.HeadCls = self.HeadCls or {}
    local PlayerId = self.RankList[Index].Key

    if ListBtn and ListBtn.GUIButton_Main then
        ListBtn.GUIButton_Main.OnClicked:Clear()
        ListBtn.GUIButton_Main.OnClicked:Add(self, Bind(self, self.OnLikeClick, ListBtn, PlayerId))
        ListBtn:SetVisibility(MvcEntry:GetModel(UserModel):IsSelf(PlayerId) and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
    end

    ScoreText:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), self.RankList[Index].Score, RankSystemModel.UnitText[self.CurTabType].Unit))

    local DetailInfo = MvcEntry:GetModel(PersonalInfoModel):GetPlayerDetailInfo(PlayerId)
    if DetailInfo then
        PlayerNameText:SetText(StringUtil.Format(DetailInfo.PlayerName))
    end
    
    local Param = {
        PlayerId = PlayerId,
        -- PlayerName = DetailInfo.PlayerName,
        -- ClickType         = CommonHeadIcon.ClickTypeEnum.None,
        CloseAutoCheckFriendShow = true,
        CloseOnlineCheck = true,
        -- NotNeedReqPlayerInfo = true
        NeedSyncWidgets = {
            NameWidget = PlayerNameText
        }
    }
    if not self.HeadCls[Index] then
        self.HeadCls[Index] = UIHandler.New(self, InCommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.HeadCls[Index]:UpdateUI(Param)
    end
end

function M:UpdateSelfRankInfo(TypeID)
    if not self.SelfHeadCls then
        local PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
        local PlayerName = MvcEntry:GetModel(UserModel):GetPlayerName()
        self.WBP_Rank_Detail.SelfPlayerName:SetText(PlayerName)
        local Param = {
            PlayerId = PlayerId,
            PlayerName = PlayerName,
            -- ClickType         = CommonHeadIcon.ClickTypeEnum.None,
            CloseAutoCheckFriendShow = true,
            CloseOnlineCheck = true,
            -- NotNeedReqPlayerInfo = true
        }
        self.SelfHeadCls = UIHandler.New(self,self.WBP_Rank_Detail.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    end

    MvcEntry:GetCtrl(RankSystemCtrl):GetSelfRankInfo(TypeID, function(Info)
        local ShowRank
        if Info and Info.Rank and Info.Rank < 100 then
            ShowRank = StringUtil.Format(Info.Rank + 1)
        else
            ShowRank = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_RankSystemMainMdt_Notonthelist"))
        end
        self.WBP_Rank_Detail.SelfRank:SetText(ShowRank)
        self.WBP_Rank_Detail.SelfScore:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), Info and Info.Score or "0", RankSystemModel.UnitText[self.CurTabType].Unit))
    end, true)
end


function M:UpdateShowUnit()
    local UnitConstant = RankSystemModel.UnitText[self.CurTabType]
    -- self.WBP_Rank_Detail.SelfUnitText:SetText(UnitConstant.Unit)
    -- self.WBP_Rank_Detail.UnitText1:SetText(UnitConstant.Unit)
    -- self.WBP_Rank_Detail.UnitText2:SetText(UnitConstant.Unit)
    -- self.WBP_Rank_Detail.UnitText3:SetText(UnitConstant.Unit)
    self.WBP_Rank_Detail.ScoreText:SetText(UnitConstant.ShowUnit)
end

function M:UpdateCombobox()
    self.ModeTypeList = self.ModeTypeList or {}
    if not self.ModeTypeList[self.CurTabType] then
        self.ModeTypeList[self.CurTabType] = {}
        local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_RankConfig, Cfg_RankConfig_P.RankType, self.CurTabType)
        if not Cfgs then
            CWaring("[RankSystemMainMdt] UpdateCombobox Cfgs is nil, RankType = " .. self.CurTabType)
            return
        end
        local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
        for _, v in pairs(Cfgs) do
            local Item = nil
            if v[Cfg_RankConfig_P.ModeType] == 0 then
                Item = {ItemDataString = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_RankSystemMainMdt_Allmodes")), ItemID = 0}
            else
                local ModeName = MatchModeSelectModel:GetModeEntryCfg_ModeName(v[Cfg_RankConfig_P.ModeType])
                Item = {ItemDataString = StringUtil.Format(ModeName), ItemID = v[Cfg_RankConfig_P.ModeType]}
            end
            table.insert(self.ModeTypeList[self.CurTabType],Item)
        end
    end

    local Show = #self.ModeTypeList[self.CurTabType] > 1
    self.WBP_ComboBox:SetVisibility(Show and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
    if not Show then
        return
    end
    local params = {
        OptionList = self.ModeTypeList[self.CurTabType],
        DefaultSelect = 1,
        SelectCallBack = Bind(self, self.OnSelectionChangedSeason)
    }
    if not self.Combobox then
        self.Combobox = UIHandler.New(self, self.WBP_ComboBox, CommonComboBox, params).ViewInstance
    else
        self.Combobox:UpdateUI(params)
    end
end

function M:OnSelectionChangedSeason(Index, IsInit, Data)
	CLog("Index = "..Index)
	self.SelectedModeID = (Data and Data.ItemID) or 0
    if not IsInit then
        self:UpdateRankInfo()
    end
end

function M:GetOrCreateListItem(Widget)
    local Item = self.Widget2Item[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.RankSystem.RankSystemItem"))
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function M:OnUpdateItem(_, Widget,I)
    local Index = I + 4
    local Data = self.RankList[Index]
    if not Data then
        CError("OnUpdateItem Error For Index = "..Index,true)
        return
    end
    local Item = self:GetOrCreateListItem(Widget)
    Item:UpdateUI(Data, self.CurTabType)
end

function M:OnEscClicked()
    MvcEntry:CloseView(ViewConst.RankSystemMain)
end
return M
