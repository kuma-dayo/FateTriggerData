--[[    
    赛季行证购买界面
]] 
local class_name = "SeasonBpBuyPanelMdt"

SeasonBpBuyPanelMdt = SeasonBpBuyPanelMdt or BaseClass(GameMediator, class_name)

function SeasonBpBuyPanelMdt:__init()
end

function SeasonBpBuyPanelMdt:OnShow(data)
end

function SeasonBpBuyPanelMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.TheModel = MvcEntry:GetModel(SeasonBpModel)
    UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Esc_Btn")),
        ActionMappingKey = ActionMappings.Escape
    })

    UIHandler.New(self, self.WBP_CommonCurrency, CommonCurrencyList, {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND})

    self.BindNodes = {
		{ UDelegate = self.GUIButtonLeftBuy.OnClicked,				Func = Bind(self,self.OnClickButtonBuy,Pb_Enum_PASS_TYPE.PREMIUM) },
        { UDelegate = self.GUIButtonRightBuy.OnClicked,				Func = Bind(self,self.OnClickButtonBuy,Pb_Enum_PASS_TYPE.DELUXE) },

        { UDelegate = self.WBP_ReuseList_Left.OnUpdateItem,Func = Bind(self, self.OnUpdateItemLeft)}, 
        { UDelegate = self.WBP_ReuseList_Right.OnUpdateItem,Func = Bind(self, self.OnUpdateItemRight)}, 
    }

    self.MsgList = 
    {
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_PASS_BUY_SUC, Func = self.OnEscClicked },
	}
end

function M:OnShow(Param)
    -- self.LbTime:SetText(self.TheModel:GetEndTimeShow())
    if not self.CounDownTimer then
        self.CounDownTimer = self:InsertTimerByEndTime(self.TheModel:GetEndTime(),function (TimeStr,ResultParam)
            self.LbTime:SetText(self.TheModel:FormatEndTimeShow(TimeStr))
        end)
    end
    local PassStatus = self.TheModel:GetPassStatus()
    if PassStatus.PassType ~= Pb_Enum_PASS_TYPE.BASIC then
        self.Content_Right:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Content_Left:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.LeftRewardItemList = self.TheModel:GetSpecialRewardItemListByBpId(Pb_Enum_PASS_TYPE.PREMIUM)
    self.RightRewardItemList = self.TheModel:GetSpecialRewardItemListByBpId(Pb_Enum_PASS_TYPE.PREMIUM)
    local LeftBpCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpListCfg,{Cfg_SeasonBpListCfg_P.SeasonBpId,Cfg_SeasonBpListCfg_P.BpTypeId},{PassStatus.SeasonBpId,Pb_Enum_PASS_TYPE.PREMIUM})
    local RightBpCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpListCfg,{Cfg_SeasonBpListCfg_P.SeasonBpId,Cfg_SeasonBpListCfg_P.BpTypeId},{PassStatus.SeasonBpId,Pb_Enum_PASS_TYPE.DELUXE})
    self.LeftWidget2Handler = {}
    self.RightWidget2Handler = {}
    self:UpdateBpShow(LeftBpCfg,self.LbLeftName,self.LeftDesList,self.WBP_ReuseList_Left,self.GUICurrencyImageLeft,self.LbPriceLeft,#self.LeftRewardItemList,self.LeftWidget2Handler,true)
    self:UpdateBpShow(RightBpCfg,self.LbRightName,self.RightDesList,self.WBP_ReuseList_Right,self.GUICurrencyImageRight,self.LbPriceRight,#self.RightRewardItemList,self.RightWidget2Handler,false)
    self:PlayDynamicEffectOnShow(true)
end

function M:UpdateBpShow(BpCfg,LbName,DesList,WBP_ReuseList,GUICurrencyImage,LbPrice,RewardCount,Widget2Handler,IsLeft)
    table_clear(Widget2Handler)
    local ItemPath = "/Game/BluePrints/UMG/OutsideGame/Season/WBP_Season_Buy_ContentItem_Right"
    if IsLeft then
        ItemPath = "/Game/BluePrints/UMG/OutsideGame/Season/WBP_Season_Buy_ContentItem_Left"
    end
    LbName:SetText(BpCfg[Cfg_SeasonBpListCfg_P.Name])
    DesList:ClearChildren()
    local PadingOffset = {
        0,
        10
    }
    for k,DesStr in pairs(BpCfg[Cfg_SeasonBpListCfg_P.DesList]) do
        local WidgetClass = UE.UClass.Load(ItemPath)
        local Widget = NewObject(WidgetClass, self)
        DesList:AddChild(Widget)

        local Offset = PadingOffset[k] or 0
        if IsLeft then
            Widget.Padding.Right = Offset
            Widget.Slot:SetHorizontalAlignment(UE.EHorizontalAlignment.HAlign_Right)
        else
            Widget.Padding.Left = Offset
            Widget.Slot:SetHorizontalAlignment(UE.EHorizontalAlignment.HAlign_Left)
        end
        Widget:SetPadding(Widget.Padding)

        Widget.LbDes:SetText(StringUtil.Format(DesStr))
    end

    WBP_ReuseList:Reload(RewardCount)

    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,BpCfg[Cfg_SeasonBpListCfg_P.UnlockItemId])
    CommonUtil.SetBrushFromSoftObjectPath(GUICurrencyImage,CfgItem[Cfg_ItemConfig_P.IconPath])
    LbPrice:SetText(tostring(BpCfg[Cfg_SeasonBpListCfg_P.UnlockItemNum]))
end

function M:OnHide()
end


function M:OnUpdateItemLeft(_,Widget, Index)
    if not self.LeftWidget2Handler[Widget] then
        self.LeftWidget2Handler[Widget]  = UIHandler.New(self,Widget,CommonItemIcon).ViewInstance
    end

    local ItemInfo = self.LeftRewardItemList[Index + 1]
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemInfo.ItemId,
        ItemNum = ItemInfo.ItemNum,
        -- ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.TIP,
        HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        ShowCount = true
    }
    self.LeftWidget2Handler[Widget]:UpdateUI(IconParam)
end
function M:OnUpdateItemRight(_,Widget, Index)
    if not self.RightWidget2Handler[Widget] then
        self.RightWidget2Handler[Widget]  = UIHandler.New(self,Widget,CommonItemIcon).ViewInstance
    end

    local ItemInfo = self.RightRewardItemList[Index + 1]
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemInfo.ItemId,
        ItemNum = ItemInfo.ItemNum,
        -- ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.TIP,
        HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        ShowCount = true
    }
    self.RightWidget2Handler[Widget]:UpdateUI(IconParam)
end


function M:OnEscClicked()
    MvcEntry:CloseView(self.viewId)
end

function M:OnClickButtonBuy(PassType)
    local PassStatus = self.TheModel:GetPassStatus()
    local BpCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpListCfg,{Cfg_SeasonBpListCfg_P.SeasonBpId,Cfg_SeasonBpListCfg_P.BpTypeId},{PassStatus.SeasonBpId,PassType})
    local Param = {
        ItemId = BpCfg[Cfg_SeasonBpListCfg_P.UnlockItemId],
        Cost = BpCfg[Cfg_SeasonBpListCfg_P.UnlockItemNum],
        SucThenActionCallback = function()
            --TODO 请求购买
            MvcEntry:GetCtrl(SeasonBpCtrl):SendProto_BuyPassReq(PassStatus.SeasonBpId,PassType)
        end,
    }
	MvcEntry:GetCtrl(ShopCtrl):CheckItemEnoughThenAction(Param,true)
end

--[[
    播放显示退出动效
]]
function M:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Outside_SeasonBuy_In then
            self:VXE_Outside_SeasonBuy_In()
        end
    else
        -- if self.VXE_HalllMain_Tab_Out then
        --     self:VXE_HalllMain_Tab_Out()
        -- end
    end
end

return M
