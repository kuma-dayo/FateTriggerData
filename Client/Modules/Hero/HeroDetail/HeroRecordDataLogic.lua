--[[
    角色展示板详情解耦逻辑
]]

---@class HeroRecordDataLogic
local class_name = "HeroRecordDataLogic"
local HeroRecordDataLogic = BaseClass(nil, class_name)

HeroRecordDataLogic.ShowType = {
    ---数据
    RecordData = 0,
    ---历史战绩
    HistoryData = 1,
}

function HeroRecordDataLogic:OnInit()
    self.InputFocus = true
    self.BindNodes = 
    {
		{ UDelegate = self.View.BtnShowChart.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnMoreClicked) },
		{ UDelegate = self.View.WBP_ReuseList_ChartList.OnUpdateItem,				    Func = Bind(self,self.OnUpdateItem) },
		{ UDelegate = self.View.WBP_ReuseList_ChartList.OnScrollItem,				    Func = Bind(self,self.OnScrollItem) },
		{ UDelegate = self.View.WBP_ReuseList_ChartList.ScrollBoxList.OnUserScrolled,				    Func = Bind(self,self.OnUserScrolled) },
        
	}
    self.MsgList = 
    {
        {Model = HeroModel, MsgName = HeroModel.HERO_RECORD_DATA_CHANGE, Func = self.OnRecordDataChange },
        {Model = HeroModel, MsgName = HeroModel.HERO_RECORD_HISTORY_DATA_CHANGE, Func = self.OnRecordHistoryDataChange },
	}

    self.SkillNodeMap = {}
    self.RankStartIdx = 0
end

function HeroRecordDataLogic:InitSeasonComboBox()
    self.CurSelectSeasonId = MvcEntry:GetModel(SeasonModel):GetCurrentSeasonId()
    if self.CurSelectSeasonId == -1 then
        return
    end

    local SeasonConfigList = MvcEntry:GetModel(SeasonRankModel):GetSeasonConfigList()
    local OptionList = {}
    local DefaultSelect = 1
    for Index, SeasonConfig in ipairs(SeasonConfigList) do
        OptionList[#OptionList + 1] = {
            ItemDataString = SeasonConfig.SeasonName,
            ItemIndex = Index,
            ItemID = SeasonConfig.SeasonId,
        }
        if self.CurSelectSeasonId == SeasonConfig.SeasonId then
            DefaultSelect = Index
        end
    end
    local params = {
      OptionList = OptionList,
      DefaultSelect = DefaultSelect,
      SelectCallBack = Bind(self, self.OnSelectionSeasonChanged)
  }
    if not self.ComboBoxInst then
        self.ComboBoxInst = UIHandler.New(self, self.View.WBP_ComboBoxSeason, CommonComboBox, params).ViewInstance
    else
        self.ComboBoxInst:UpdateUI(params)
    end
end

-- 选择赛季页签回调
function HeroRecordDataLogic:OnSelectionSeasonChanged(Index, IsInit, Data)
    if not IsInit then
        self.CurSelectSeasonId = Data.ItemID
    end
    self.RankAverageValue = 0
    MvcEntry:GetCtrl(HeroCtrl):ReqHeroSeasonHeroRecordData(self.CurSelectSeasonId,self.HeroId)
    MvcEntry:GetCtrl(HeroCtrl):ReqHeroSeasonHeroHistoryData(self.CurSelectSeasonId,self.HeroId)
end


function HeroRecordDataLogic:OnShow(Param)
    if not Param or not Param.HeroId then
        CWaring("RecordSkillDataItem:SetData Param is nil")
        return
    end
    self.HeroId = Param.HeroId
    self.CurShowType = HeroRecordDataLogic.ShowType.RecordData
    self:InitSeasonComboBox()
    -- self:OnShowAvator()
end

function HeroRecordDataLogic:OnHide()
    self.Widget2Item = nil
    self.SkillNodeMap =  nil
    self:ClearTimer()
    self:ClearScrollTimer()
end

function HeroRecordDataLogic:ClearScrollTimer()
    if self.ScrollTimer then
        Timer.RemoveTimer(self.ScrollTimer)
        self.ScrollTimer = nil
    end
end

function HeroRecordDataLogic:OnManualShow(Param)
    self:UpdateUI(Param)
end

function HeroRecordDataLogic:UpdateUI(Param)
    if not Param or not Param.HeroId then
        CWaring("RecordSkillDataItem:UpdateUI Param is nil")
        return
    end
    self.HeroId = Param.HeroId
    -- self:UpdateShowData()
    self:InitSeasonComboBox()
    self.View.WBP_ReuseList_ChartList:ScrollToStart()
    -- self.RankAverageValue = 0
    -- self.CurShowType = HeroRecordDataLogic.ShowType.RecordData
    -- MvcEntry:GetCtrl(HeroCtrl):ReqHeroSeasonHeroRecordData(self.CurSelectSeasonId,self.HeroId)
    -- MvcEntry:GetCtrl(HeroCtrl):ReqHeroSeasonHeroHistoryData(self.CurSelectSeasonId,self.HeroId)
end

function HeroRecordDataLogic:OnManualHide()
    MvcEntry:CloseView(ViewConst.CommonHoverTips)
    self:ClearTimer()
    self:ClearScrollTimer()
end

function HeroRecordDataLogic:OnShowAvator(Param, IsInit, IsSwitch, IsQuickSwitch)
    local SkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(self.HeroId)
    self.WidgetBase:UpdateAvatarShow(self.HeroId, SkinId, true, nil, IsSwitch, IsQuickSwitch)
end

function HeroRecordDataLogic:OnHideAvator(Param,IsNotVirtualTrigger)
end

function HeroRecordDataLogic:OnMoreClicked()
    self.CurShowType = HeroRecordDataLogic.ShowType.HistoryData - self.CurShowType
    self:UpdateShowData()
end

function HeroRecordDataLogic:UpdateShowData()
    self.View.DataDetail:SetActiveWidgetIndex(self.CurShowType)

    self.DataList = MvcEntry:GetModel(HeroModel):GetHeroDataHistoryRecord(self.CurSelectSeasonId, self.HeroId) or {}
    if self.CurShowType == HeroRecordDataLogic.ShowType.RecordData then

    elseif self.CurShowType == HeroRecordDataLogic.ShowType.HistoryData then
        self.View.ListWidgetSwitcher:SetActiveWidgetIndex(#self.DataList == 0 and 1 or 0)
        self.View.WBP_ReuseList_ChartList:Reload(#self.DataList)

        self.DataListArr = {}
        for _, v in ipairs(self.DataList) do
            table.insert(self.DataListArr, v.PowerScore)
        end

        self.RankAverageValue = self:GetHeroDataRecordByKey("DivisionAvgHeroPowerScore")
        self.View.WBP_ReuseList_ChartList.GUILineWidget.AverageValue = self.RankAverageValue
        self.View.WBP_ReuseList_ChartList.GUILineWidget:SetPoints(self.DataListArr)
        local Position = self.View.WBP_ReuseList_ChartList.GUILineWidget:GetValuePositon(0, self.RankAverageValue)
        self.View.ImgDottedLine.Slot:SetPosition(UE.FVector2D(0, Position.Y))
    end

    for i = 1, 5 do
        local Widget = self.View["ImgData"..i]
        if self.DataList[i] then
            Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            CommonUtil.SetBrushTintColorFromHex(Widget, self.DataList[i].PowerScoreInc > 0 and "0BF28BFF" or "F5EFDFFF")
        else
            Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function HeroRecordDataLogic:ClearTimer()
    if self.LoadTimer then
        Timer.RemoveTimer(self.LoadTimer)
        self.LoadTimer = nil
    end
    self.IsLoadingRecord = false
end
function HeroRecordDataLogic:OnScrollItem(_, StartIdx,EndIdx)
    self.View.WBP_ReuseList_ChartList.GUILineWidget:SetShowLine(StartIdx)
    local Position = self.View.WBP_ReuseList_ChartList.GUILineWidget:GetValuePositon(0, self.RankAverageValue)
    self.View.ImgDottedLine.Slot:SetPosition(UE.FVector2D(0, Position.Y))
end

function HeroRecordDataLogic:OnUserScrolled()
    if #self.DataList == 0 then
        return
    end

    if self.CurShowTipParam then
        self:HandleCommonHoverTipsVisible(false)
        self:ClearScrollTimer()
        self.ScrollTimer = Timer.InsertTimer(0.3, function()
            self:ClearScrollTimer()
            if self.CurShowTipParam then
                self:HandleCommonHoverTipsVisible(true, self.CurShowTipParam.Tip, self.CurShowTipParam.Index)
            end
        end)
    end

    local Offset = self.View.WBP_ReuseList_ChartList:GetScrollOffset()
    local MaxOffset = self.View.WBP_ReuseList_ChartList:GetScrollOffsetOfEnd()
    if MaxOffset < 100 or Offset < MaxOffset then 
        return 
    end
    if self.IsLoadingRecord then
        return
    end
    self.LoadTimer = Timer.InsertTimer(2, function()
        self:ClearTimer()
        self.IsLoadingRecord = false
    end)
    MvcEntry:GetCtrl(HeroCtrl):ReqHeroSeasonHeroHistoryData(self.CurSelectSeasonId,self.HeroId, #self.DataList)
    self.IsLoadingRecord = true
end

function HeroRecordDataLogic:GetHeroDataRecordByKey(Key)
    return MvcEntry:GetModel(HeroModel):GetHeroDataRecord(self.CurSelectSeasonId, self.HeroId, Key)
end

function HeroRecordDataLogic:GetHeroDataRecordRateByKey(Key1, Key2, Rate, Default, Format2)
    Format2 = Format2 or false
    Default = Default or 0
    Rate = Rate or 1
    local Value1 = self:GetHeroDataRecordByKey(Key1)
    local Value2 = self:GetHeroDataRecordByKey(Key2)
    if Value1 == 0 then
        return 0
    end
    if Value2 == 0 then
        return Default * Rate
    end
    return string.format(StringUtil.FormatSimple("%.{0}f", Format2 and "2" or "0"), Value1 / Value2 * Rate)
end

function HeroRecordDataLogic:UpdateDetailData()
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, self.HeroId)
    self.View.GUITextBlock_HeroName:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.Name]))
    -- self.View.WBP_HeroNameAndDetailItem.HeroName:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.Name]))
    -- self.View.WBP_HeroNameAndDetailItem.HeroName_1:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.RealName]))
    -- self.View.WBP_HeroNameAndDetailItem.HeroDetail:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.HeroDescription]))

    self.View.GUITextBlock_PowerScore:SetText(self:GetHeroDataRecordByKey("PowerScore"))
    self.View.GUITextBlock_TotKill:SetText(self:GetHeroDataRecordByKey("TotKill"))
    self.View.GUITextBlock_KillDeathRatio:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self:GetHeroDataRecordRateByKey("TotKill", "TotDeath", 1, 1, true)) )
    self.View.GUITextBlock_RecordsNum:SetText(self:GetHeroDataRecordByKey("RecordsNum"))
    self.View.GUITextBlock_TotDamage:SetText(self:GetHeroDataRecordByKey("TotDamage"))
    self.View.GUITextBlock_DamageRecordsRatio:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self:GetHeroDataRecordRateByKey("TotDamage", "RecordsNum")) )
    self.View.GUITextBlock_RankRecordsRatio:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self:GetHeroDataRecordRateByKey("TotRank", "RecordsNum")) )
    self.View.GUITextBlock_Rank5RecordsRatio:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_1"), self:GetHeroDataRecordRateByKey("Top5Num", "RecordsNum", 100)) )
    self.View.GUITextBlock_SurvivalTimeRecordsRatio:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self:GetHeroDataRecordRateByKey("TotSurvivalTime", "RecordsNum")) )
    self.View.GUITextBlock_TotRescue:SetText(self:GetHeroDataRecordByKey("TotRescue"))
    self.View.GUITextBlock_TotRespawn:SetText(self:GetHeroDataRecordByKey("TotRespawn"))

    self.View.GUITextBlock_MaxDamage:SetText(self:GetHeroDataRecordByKey("MaxDamage"))
    self.View.GUITextBlock_MaxKill:SetText(self:GetHeroDataRecordByKey("MaxKill"))


    local CfgHeroSkills = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkillStatisticsCfg, Cfg_HeroSkillStatisticsCfg_P.HeroID, self.HeroId)
    if not CfgHeroSkills then
        return
    end
    local Index = 1
    local SkillRecordValueList = MvcEntry:GetModel(HeroModel):GetHeroDataRecord(self.CurSelectSeasonId, self.HeroId, "HeroSkillPerfs")
    for _, v in pairs(CfgHeroSkills) do
        if not CommonUtil.IsValid(self.View["WBP_HeroDataSkillItem_"..Index]) then
            break
        end
        local SkillId = v[Cfg_HeroSkillStatisticsCfg_P.SkillId]
        local Param = {SkillId = SkillId, RecordValue = (type(SkillRecordValueList) == "table" and SkillRecordValueList) and SkillRecordValueList[SkillId] or 0}
        if not self.SkillNodeMap[Index] then
            self.SkillNodeMap[Index] = UIHandler.New(self,self.View["WBP_HeroDataSkillItem_"..Index],require("Client.Modules.Hero.HeroDetail.RecordData.RecordSkillDataItem"),Param).ViewInstance
        else
            self.SkillNodeMap[Index]:SetData(Param)
        end
        Index = Index + 1
    end
end

function HeroRecordDataLogic:CreateItem(Widget)
    self.Widget2Item = self.Widget2Item or {}
    local Item = self.Widget2Item[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget,  require("Client.Modules.Hero.HeroDetail.RecordData.RecordDataListItem"))
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function HeroRecordDataLogic:OnUpdateItem(_, Widget, Index)
    local FixIndex = Index + 1
    local RecordData = self.DataList[FixIndex]
    if RecordData == nil then
        return
    end
    local TargetItem = self:CreateItem(Widget)
    if TargetItem == nil then
        return
    end
    TargetItem:SetData(Index, {
        SeasonId = self.CurSelectSeasonId,
        HeroId = self.HeroId,
        Data = RecordData,
        ItemCallBack = Bind(self, self.OnItemCallBack)
    })

end

function HeroRecordDataLogic:OnItemCallBack(Widget, IsHover, Tip, Index)
    if IsHover then
        self:HandleCommonHoverTipsVisible(IsHover, Tip, Index)
        self.CurShowTipParam = {
            Index = Index,
            Tip = Tip
        }
    else
        self:HandleCommonHoverTipsVisible(IsHover)
        self.CurShowTipParam = nil
    end
end

function HeroRecordDataLogic:HandleCommonHoverTipsVisible(Show, Tip, Index)
    if Show then
        self.View.WBP_ReuseList_ChartList.Point_Root:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local Pos = self.View.WBP_ReuseList_ChartList.GUILineWidget:GetValuePositon(Index, self.DataListArr[Index + 1])
        self.View.WBP_ReuseList_ChartList.Point_Root.Slot:SetPosition(Pos)
        local Param = {
            ParentWidgetCls = self,
            TipsStr = Tip,
            FocusWidget = self.View.WBP_ReuseList_ChartList.Point_Root,
        }
        MvcEntry:OpenView(ViewConst.CommonHoverTips,Param)
    else
        self.View.WBP_ReuseList_ChartList.Point_Root:SetVisibility(UE.ESlateVisibility.Collapsed)
        MvcEntry:CloseView(ViewConst.CommonHoverTips)
    end
end

function HeroRecordDataLogic:OnRecordDataChange()
    self:UpdateDetailData()
end
function HeroRecordDataLogic:OnRecordHistoryDataChange()
    self:UpdateShowData()
end


return HeroRecordDataLogic
