local AchievementListItem = require("Client.Modules.Achievement.AchievementListItem")
local AchievementConst = require("Client.Modules.Achievement.AchievementConst")
--- 视图控制器
local class_name = "TabAchievement";
local TabAchievement = BaseClass(nil, class_name);

function TabAchievement:OnInit()
    -- self.MsgList = 
    -- {
    -- 	{Model = AchievementModel, MsgName = ListModel.ON_UPDATED, Func = self.OnAchievementUpdate},
    -- }

    self.BindNodes = 
    {
        {UDelegate = self.View.WBP_Achievement_Content.WBP_ReuseList.OnUpdateItem, Func = Bind(self, self.OnUpdateItem)},
        {UDelegate = self.View.WBP_Achievement_Content.WBP_Common_Btn.Btn_List.OnClicked, Func = Bind(self, self.OnOpenHeroClicked)},
    	-- { UDelegate = self.GUIButton_Back.OnClicked,				    Func = self.GUIButton_Close_ClickFunc },
    }

    self.Model = MvcEntry:GetModel(AchievementModel)
    self:InitTabInfo()
end

function TabAchievement:OnHide()
    self.DataList = nil
    self.Widget2Item = nil
end

function TabAchievement:OnShow(Params)
    self.PlayerId = Params or 0
    self.Model:SetPersonInfoPlayerId(self.PlayerId)
    self.IsSelf = MvcEntry:GetModel(UserModel):IsSelf(self.PlayerId)

    self.DataList = {}
    self.Widget2Item = {}
    self.TabListCls:Switch2MenuTab(0 ,true)

    --self.View.MenuTabList:SetVisibility(self.IsSelf and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.WBP_Achievement_Content.GUIImage2:SetColorAndOpacity(UE.FLinearColor(0.30, 0.30, 0.30, 1))
    self.View.WBP_Achievement_Content.WidgetSwitcher:SetVisibility(self.IsSelf and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
 
end

--[[
    设置英雄灰化状态同时设置按钮显示样式
]]
function TabAchievement:SetHeroGetTipsShow(InIsShow)
    if not InIsShow then
        self.View.WBP_Achievement_Content.WBP_Common_Btn:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
      
    self.View.WBP_Achievement_Content.WBP_Common_Btn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --CommonUtil.SetImageColorFromHex(self.View.WBP_Achievement_Content.WBP_Common_Btn.Icon_Normal, "#E9E7E44D")
    self.View.WBP_Achievement_Content.WBP_Common_Btn.Img_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.WBP_Achievement_Content.WBP_Common_Btn.Text_Count:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Achievement", "1268")))
end


function TabAchievement:InitTabInfo()
    local TypeTabParam = {
        ClickCallBack = Bind(self, self.OnTypeBtnClick),
        ValidCheck = Bind(self, self.TypeValidCheck),
        HideInitTrigger = true
    }
    TypeTabParam.ItemInfoList = {}

    local GroupConfigs = G_ConfigHelper:GetDict(Cfg_AchievementGroupConfig)
    for _, Cfg in ipairs(GroupConfigs) do

        local TabItemInfo = {
            Id = Cfg[Cfg_AchievementGroupConfig_P.TypeGroup],
            LabelStr = Cfg[Cfg_AchievementGroupConfig_P.TypeName],
        }
        TypeTabParam.ItemInfoList[#TypeTabParam.ItemInfoList + 1] = TabItemInfo
    end

    self.TabListCls = UIHandler.New(self, self.View.WBP_Common_TabUp_03, CommonMenuTabUp, TypeTabParam).ViewInstance
    self.TabIndex = 0
end

function TabAchievement:OnTypeBtnClick(Index, ItemInfo, IsInit)
    local DataList = self.Model:GetTabDataByTypeID(ItemInfo.Id)--G_ConfigHelper:GetMultiItemsByKey(Cfg_AchievementCategoryConfig,Cfg_AchievementCategoryConfig_P.TypeGroup,ItemInfo.Id)
    self.View.WBP_Achievement_Content.WBP_ComboBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.WBP_Achievement_Content.WidgetSwitcher:SetActiveWidgetIndex(0)
    local ViewParam = {
        ViewId = ViewConst.PlayerInfo,
        TabId = MvcEntry:GetModel(PlayerInfoModel).Enum_SubPageCfg.AchievementPage.Id .."-" .. Index
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)

    if not DataList then 
        self:RefreshList(0)
        return
    end
    if #DataList == 0 then
        self:RefreshList(ItemInfo.Id)
        if Index == AchievementConst.GROUP_DEF.HERO then
            self.View.WBP_Achievement_Content.WidgetSwitcher:SetActiveWidgetIndex(2)
        end
    elseif #DataList > 1 then
        self.View.WBP_Achievement_Content.WBP_ComboBox:SetVisibility(UE.ESlateVisibility.Visible)
        -- self.View.WBP_Achievement_Content.HeroLock:SetVisibility(UE.ESlateVisibility.Visible)
        if Index == AchievementConst.GROUP_DEF.HERO then
            self.View.WBP_Achievement_Content.WidgetSwitcher:SetActiveWidgetIndex(1)
        end
        local TypeList = {}
        for k, v in ipairs(DataList) do
            local NameStr = ""
            local HeroCfgData = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCategoryConfig, v[Cfg_AchievementCfg_P.SecTypeID])
            local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, HeroCfgData.AttachHeroID)
            if CfgHero then
                NameStr = CfgHero[Cfg_HeroConfig_P.Name]
            end
            table.insert(TypeList, {
                ItemDataString = NameStr,
                ItemIndex = k,
                ItemID = v[Cfg_AchievementCategoryConfig_P.TypeID],
            })
        end

        local DefaultSelect = SaveGame.GetItem("AchievementDefaultSelect")
        DefaultSelect = DefaultSelect or 1

        local params = {
            OptionList = TypeList,
            DefaultSelect = DefaultSelect,
            SelectCallBack = Bind(self, self.OnSelectionChanged)
        }
        if not self.Combobox then
            self.Combobox = UIHandler.New(self, self.View.WBP_Achievement_Content.WBP_ComboBox, CommonComboBox, params).ViewInstance
        else
            self.Combobox:UpdateUI(params)
        end
    end

end

function TabAchievement:TypeValidCheck(Type)
    return true
end

function TabAchievement:OnSelectionChanged(Index, IsInit, Data)
	CLog("Index = "..Index)
    SaveGame.SetItem("AchievementDefaultSelect", Index)
    self:RefreshList(Data and Data.ItemID, Index, Data and Data.ItemDataString)
end

function TabAchievement:RefreshList(Type, ItemIndex, ItemDataString)
    local ShowIndex = 0
    local ItemList = self.Model:GetTabDataByTypeID(Type)
    self.View.WBP_Achievement_Content.WidgetSwitcher:SetActiveWidgetIndex(0)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCategoryConfig, Type)
    if ItemList and #ItemList > 0 then
        Cfg = ItemList[ItemIndex]
    end
    if not Cfg then
        return
    end

    if Cfg[Cfg_AchievementCfg_P.TypeID] == AchievementConst.GROUP_DEF.HERO then
        local HeroCfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCategoryConfig, Cfg[Cfg_AchievementCfg_P.SecTypeID])
        local IsGot = MvcEntry:GetModel(HeroModel):CheckGotHeroById(HeroCfg[Cfg_AchievementCategoryConfig_P.AttachHeroID])
        ShowIndex = IsGot and 1 or 2
        CommonUtil.SetBrushFromSoftObjectPath(self.View.WBP_Achievement_Content["GUIImage_Back"..ShowIndex],HeroCfg[Cfg_AchievementCategoryConfig_P.CategoryPic])
        CommonUtil.SetBrushFromSoftObjectPath(self.View.WBP_Achievement_Content["GUIImage"..ShowIndex],HeroCfg[Cfg_AchievementCategoryConfig_P.CategoryPic])
        self.View.WBP_Achievement_Content["GUITextBlock_Name"..ShowIndex]:SetText(StringUtil.FormatText(ItemDataString))
        self.View.WBP_Achievement_Content.WidgetSwitcher:SetActiveWidgetIndex(ShowIndex)
        self:SetHeroGetTipsShow(ShowIndex == 2)
    end

    self.CurTypeId = Type
    if self.IsSelf then
        local List = self.Model:GetListByType(Type) or {}
        local CompleteList = self.Model:GetCompleteListByType(Type) or {}
        if self.View.WBP_Achievement_Content["GUIText_CurNum"..ShowIndex] then
            self.View.WBP_Achievement_Content["GUIText_CurNum"..ShowIndex]:SetText(StringUtil.FormatText(#CompleteList))
        end
        if self.View.WBP_Achievement_Content["GUIText_TotalNum"..ShowIndex] then
            self.View.WBP_Achievement_Content["GUIText_TotalNum"..ShowIndex]:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_6"),#List))
        end

        if Type == AchievementConst.GROUP_DEF.HERO then
            local HeroList = List
            List = table.sort(HeroList)
            List = {HeroList[ItemIndex]}
        end
        self:RefreshPlayerList(List)
    else
        MvcEntry:GetCtrl(AchievementCtrl):GetAchievementInfoReq(self.PlayerId, Bind(self, self.RefreshPlayerList))
    end
end

function TabAchievement:RefreshPlayerList(List)
    List = List or {}
    self.DataList = List
    if #self.DataList == 0 then
        
    end
    self.View.WBP_Achievement_Content.WBP_ReuseList:Reload(#self.DataList)
end

function TabAchievement:CreateItem(Widget, Data)
    local Item = self.Widget2Item[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, AchievementListItem)
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function TabAchievement:OnUpdateItem(_, Widget, Index)
    local FixIndex = Index + 1
    local Data = self.DataList[FixIndex]
    if Data == nil then
        return
    end
    local TargetItem = self:CreateItem(Widget, Data)
    if TargetItem == nil then
        return
    end
    TargetItem:SetData(Data, self.PlayerId)
end

function TabAchievement:OnOpenHeroClicked()
    if not self.CurTypeId or self.CurTypeId == 0 then
        return
    end
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCategoryConfig,self.CurTypeId)
    if not Cfg then
        return
    end
    if Cfg[Cfg_AchievementCategoryConfig_P.TypeGroup] ~= AchievementConst.GROUP_DEF.HERO then
        return
    end
    local HeroId = Cfg[Cfg_AchievementCategoryConfig_P.AttachHeroID]
    local IsGot = MvcEntry:GetModel(HeroModel):CheckGotHeroById(HeroId)
    if IsGot then
        return
    end
    MvcEntry:CloseView(ViewConst.PlayerInfo)
    CommonUtil.SwitchHallTab(CommonConst.HL_HERO, { SelectIndex = HeroId} )
end

return TabAchievement
