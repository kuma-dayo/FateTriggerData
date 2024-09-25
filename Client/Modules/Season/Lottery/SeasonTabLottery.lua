--[[
    赛季 - 切页 - 抽奖
]]

local class_name = "SeasonTabLottery"
local SeasonTabLottery = BaseClass(UIHandlerViewBase, class_name)


function SeasonTabLottery:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true


    self.BindNodes = {
		{ UDelegate = self.View.WBP_CommonBtn_Reward.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnRewardBtnClick) },
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,    Func = Bind(self, self.OnUpdateLeftItem)},
        { UDelegate = self.View.WBP_ReuseList_Reward.OnUpdateItem,    Func = Bind(self, self.OnUpdateRewardItem)},
    }

    self.MsgList = 
    {
        {Model = SeasonLotteryModel, MsgName = SeasonLotteryModel.ON_POOL_LOTTERY_INFO_UPDATE,	Func = self.ON_POOL_LOTTERY_INFO_UPDATE_Func },
        {Model = SeasonLotteryModel, MsgName = SeasonLotteryModel.ON_LOTTERY_ACTION_SUC,	Func =  self.ON_LOTTERY_ACTION_SUC_Func},
	}
    -- self.SubClassList = {}

    self.LotteryModel = MvcEntry:GetModel(SeasonLotteryModel)

    self.CommonCurrencyListView = UIHandler.New(self, self.View.WBP_CommonCurrency, CommonCurrencyList).ViewInstance
    -- table.insert(self.SubClassList,self.CommonCurrencyListView)

    self.BtnLotteryOne = UIHandler.New(self, self.View.WBP_CommonBtn_One, WCommonBtnTips).ViewInstance
    self.BtnLotteryTen = UIHandler.New(self, self.View.WBP_CommonBtn_Ten, WCommonBtnTips).ViewInstance
    -- table.insert(self.SubClassList,self.BtnLotteryOne)
    -- table.insert(self.SubClassList,self.BtnLotteryTen)


    local RuleInstance = UIHandler.New(self,self.View.CommonBtnTips_Rule, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnRuleViewClick),
        CommonTipsID = CommonConst.CT_I,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_HallTabSeason_Ruledescription")),
        ActionMappingKey = ActionMappings.I
    }).ViewInstance
    local RecordInstance = UIHandler.New(self,self.View.CommonBtnTips_LotteryRecord, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnRecordViewClick),
        CommonTipsID = CommonConst.CT_R,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_HallTabSeason_Extractrecords")),
        ActionMappingKey = ActionMappings.R
    }).ViewInstance
    local EscInstance = UIHandler.New(self,self.View.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_HallTabSeason_return")),
        ActionMappingKey = ActionMappings.Escape
    }).ViewInstance
    -- table.insert(self.SubClassList,RuleInstance)
    -- table.insert(self.SubClassList,RecordInstance)
    -- table.insert(self.SubClassList,EscInstance)

    self.LeftWidget2Hanler = {}
    self.RewardId2WidgetHandler = {}
end


--[[
    Param = {
    }
]]
function SeasonTabLottery:OnShow(Param)
    self:UpdateUI()
end
function SeasonTabLottery:OnManualShow(Param)
end

function SeasonTabLottery:OnHide()
end

function SeasonTabLottery:UpdateUI()
    self:UpdateLeftPanel()
end

-- -- 由 CommonHallTab 控制调用，显示当前页签时调用，重新注册监听事件
-- function SeasonTabLottery:OnCustomShow()
--     if self.IsHide then 
--         if self.MsgList then
--             CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,true)
--         end
--         if self.SubClassList then
--             for _,Btn in ipairs(self.SubClassList) do
--                 CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,true)
--             end
--         end
--         self.IsHide = false
--     end
-- end

-- -- 由 CommonHallTab 控制调用，隐藏当前页签时调用，销毁监听事件
-- function SeasonTabLottery:OnCustomHide()
--     CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,false)
--     if self.SubClassList then
--         for _,Btn in ipairs(self.SubClassList) do
-- 		    CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,false)
--         end
--     end
--     self.IsHide = true
-- end

function SeasonTabLottery:OnShowAvator(data)
end

function SeasonTabLottery:OnHideAvator(data)
end

--[[
    更新左边列表展示
    更新不同的奖池列表
]]
function SeasonTabLottery:UpdateLeftPanel()
    self.PoolOpenList = self.LotteryModel:GetOpenPoolList()
    self.LeftContentItemList = {}
    self.View.WBP_ReuseList:Reload(#self.PoolOpenList)

    self.CurSelectPoolId = 0
    if #self.PoolOpenList > 0 then
        self.CurSelectPoolId = self.PoolOpenList[1].PrizePoolId
    else
        CWaring("SeasonTabLottery:UpdateLeftPanel PoolOpen Empty")
        UIAlert.Show("SeasonTabLottery:UpdateLeftPanel PoolOpen Empty")
    end
    self:UpdateCenterPanel()
    self:UpdateRightPanel()
end

function SeasonTabLottery:UpdateCenterPanel()
    --TODO 根据奖池区分不同展示未做
end
function SeasonTabLottery:UpdateRightPanel()
    --TODO 更新货币
    local PrizePoolConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePoolConfig,self.CurSelectPoolId)
    self.CommonCurrencyListView:UpdateShowByParam({ShopDefine.CurrencyType.DIAMOND,PrizePoolConfig[Cfg_PrizePoolConfig_P.OneNeedItemId]})

    --TODO 更新抽奖按钮显示
    local LotteryOneNum = 1
    local OneParam = {
        OnItemClick = Bind(self,self.OnClicked_LotteryBtn,LotteryOneNum),
        CurrencyId = PrizePoolConfig[Cfg_PrizePoolConfig_P.OneNeedItemId],
        CurrencyStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_HallTabSeason_Extracttimes"),PrizePoolConfig[Cfg_PrizePoolConfig_P.OneNeedItemIdNum],LotteryOneNum),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    }
    self.BtnLotteryOne:UpdateItemInfo(OneParam)
    local LotteryTenNum = 10
    local TenParam = {
        OnItemClick = Bind(self,self.OnClicked_LotteryBtn,LotteryTenNum),
        CurrencyId = PrizePoolConfig[Cfg_PrizePoolConfig_P.OneNeedItemId],
        CurrencyStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_HallTabSeason_Extracttimes"),PrizePoolConfig[Cfg_PrizePoolConfig_P.OneNeedItemIdNum] * LotteryTenNum,LotteryTenNum),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    }
    self.BtnLotteryTen:UpdateItemInfo(TenParam)

    --TODO 更新大背景图
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImageBg,PrizePoolConfig[Cfg_PrizePoolConfig_P.PrizeBackground])

    --TODO 更新奖励图
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImagePrize,PrizePoolConfig[Cfg_PrizePoolConfig_P.PrizePic])

    --TODO 更新奖励名称
    self.View.LbNamePrize:SetText(PrizePoolConfig[Cfg_PrizePoolConfig_P.PrizeName])
    --TODO 更新奖池名称
    self.View.LbPoolName:SetText(PrizePoolConfig[Cfg_PrizePoolConfig_P.PoolName])
    --TODO 更新奖池描述
    self.View.LbRichPoolDes:SetText(PrizePoolConfig[Cfg_PrizePoolConfig_P.PoolDes])

    --TODO 更新奖池抽奖描述
    self:UpdateBodiLotteryTip()

    --TODO 更新奖励预览列表  
    self:UpdateRewardList()
end

function SeasonTabLottery:UpdateBodiLotteryTip(IsUpdate)
    if IsUpdate then
        local PrizePoolConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePoolConfig,self.CurSelectPoolId)
        local BaodiCount = MvcEntry:GetModel(SeasonLotteryModel):GetBaodiCountByPoolId(self.CurSelectPoolId)
        local BaodiCountShow = PrizePoolConfig[Cfg_PrizePoolConfig_P.BaoDiOneMax] - BaodiCount
        self.View.LbRichLotteryDes:SetText(StringUtil.Format(PrizePoolConfig[Cfg_PrizePoolConfig_P.BaodiDes],BaodiCountShow))

        --TODO 更新当日已抽次数 （未做）
        self.View.LbDayCountLimit:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_HallTabSeason_Maximumdailywithdraw"),MvcEntry:GetModel(SeasonLotteryModel):GetDayCountByPoolId(self.CurSelectPoolId),PrizePoolConfig[Cfg_PrizePoolConfig_P.DayCountMax]))
    else
        self.View.LbRichLotteryDes:SetText("--")
        MvcEntry:GetCtrl(SeasonCtrl):SendProto_PlayerLotteryInfoReq(self.CurSelectPoolId)
    end
end

--[[
    更新奖励预览列表
]]
function SeasonTabLottery:UpdateRewardList()
    self.RewardPreviewShowNum = 4
    self.RewardPreviewList = MvcEntry:GetModel(SeasonLotteryModel):GetPreviewPrizeListByPoolId(self.CurSelectPoolId)
    self.View.WBP_ReuseList_Reward:Reload(self.RewardPreviewShowNum)
end

function SeasonTabLottery:OnUpdateLeftItem(Handler,Widget, I)
    local Index = I + 1
    local ContentData = self.PoolOpenList[Index]
    if not ContentData then
        CWaring("SeasonTabLottery:OnUpdateLeftItem GetContentData Error; Index = "..tostring(Index))
        return
    end
    if not self.LeftWidget2Hanler[Widget] then
        self.LeftWidget2Hanler[Widget] = UIHandler.New(self,Widget,require("Client.Modules.Season.Lottery.SeasonTabLotteryLeftItemLogic"))
    end

    local PrizePoolId = ContentData.PrizePoolId
    local IsSelect = PrizePoolId == self.CurSelectPoolId
    local Param = {
        ContentData = ContentData,
        OnClickCallBack = Bind(self,self.OnClickLeftContentItem,PrizePoolId),
    }
    self.LeftWidget2Hanler[Widget].ViewInstance:UpdateUI(Param)

    if IsSelect then
        self.LeftWidget2Hanler[Widget].ViewInstance:Select()
    else
        self.LeftWidget2Hanler[Widget].ViewInstance:UnSelect()
    end
    self.LeftContentItemList[PrizePoolId] = self.LeftWidget2Hanler[Widget].ViewInstance
end

function SeasonTabLottery:OnUpdateRewardItem(Handler,Widget, I)
    local Index = I + 1
    local RewardData = self.RewardPreviewList[Index]
    if not RewardData then
        CWaring("SeasonTabLottery:OnUpdateRewardItem RewardData Error; Index = "..tostring(Index))
        return
    end
    --TODO 未做
    local PreviewPrizeId = RewardData[Cfg_PrizePreviewConfig_P.PreviewPrizeId]
    if not self.RewardId2WidgetHandler[PreviewPrizeId] then
        self.RewardId2WidgetHandler[PreviewPrizeId] = UIHandler.New(self,Widget,CommonItemIcon)
    end
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = RewardData[Cfg_PrizePreviewConfig_P.ItemId],
        ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
        ShowCount = false,
        HoverScale = 1.15,
        HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
    }
    self.RewardId2WidgetHandler[PreviewPrizeId].ViewInstance:UpdateUI(IconParam,true)
end

function SeasonTabLottery:OnClickLeftContentItem(PrizePoolId,Handler)
    if PrizePoolId == self.CurSelectPoolId then
        CWaring("SeasonTabLottery:OnClickLeftContentItem Repeat Select PoolId:" .. PrizePoolId)
        return
    end
    local OldWidget = self.LeftContentItemList[self.CurSelectPoolId]
    if OldWidget then
        OldWidget:UnSelect()
    end
    self.CurSelectPoolId = PrizePoolId
    local NewWidget = self.LeftContentItemList[self.CurSelectPoolId]
    if NewWidget then
        NewWidget:Select()
    end
    self:UpdateCenterPanel()
    self:UpdateRightPanel()
end

--[[
    保底次数更新
]]
function SeasonTabLottery:ON_POOL_LOTTERY_INFO_UPDATE_Func()
    self:UpdateBodiLotteryTip(true)
end
--[[
    抽奖成功回调
]]
function SeasonTabLottery:ON_LOTTERY_ACTION_SUC_Func()
    
end

--[[
    奖励预览点击
]]
function SeasonTabLottery:OnRewardBtnClick()
    --TODO 打开奖励预览界面 
    local Param = {
        PrizePoolId = self.CurSelectPoolId
    }
    MvcEntry:OpenView(ViewConst.SeanLotteryPrizePreview,Param)
end

--[[
    点击查看规则
]]
function SeasonTabLottery:OnRuleViewClick()
    -- UIAlert.Show("功能未做")
    local Param = {
        PrizePoolId = self.CurSelectPoolId
    }
    MvcEntry:OpenView(ViewConst.SeasonLotteryRule,Param)
end
--[[
    点击查看抽奖记录
]]
function SeasonTabLottery:OnRecordViewClick()
    -- UIAlert.Show("功能未做")
    local Param = {
        PrizePoolId = self.CurSelectPoolId
    }
    MvcEntry:OpenView(ViewConst.SeasonLotteryRecord,Param)
end

--[[
    返回
]]
function SeasonTabLottery:OnEscClicked()
    CommonUtil.SwitchHallTab(CommonConst.HL_PLAY)
end

--[[
    点击抽奖
]]
function SeasonTabLottery:OnClicked_LotteryBtn(LotteryNum)
    if not MvcEntry:GetModel(SeasonLotteryModel):CheckLotteryDayCountLimit(self.CurSelectPoolId,LotteryNum,true) then
        return
    end
    local PrizePoolConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePoolConfig,self.CurSelectPoolId)
    local NeedItemId = PrizePoolConfig[Cfg_PrizePoolConfig_P.OneNeedItemId]

    if not MvcEntry:GetCtrl(ShopCtrl):CheckShopItemEnoughThenAction(NeedItemId,PrizePoolConfig[Cfg_PrizePoolConfig_P.OneNeedGoodId],LotteryNum,Bind(self,self.OnClicked_LotteryBtn,LotteryNum),true) then
        return
    end
    MvcEntry:GetCtrl(SeasonCtrl):SendProto_PlayerLotteryReq(self.CurSelectPoolId,LotteryNum)
end


return SeasonTabLottery
