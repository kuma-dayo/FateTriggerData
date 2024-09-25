--[[
     赛季通行证升级界面（高级/豪华通行证）
]]

local class_name = "SeasonBpLvUpgradeAdvanceMdt";
SeasonBpLvUpgradeAdvanceMdt = SeasonBpLvUpgradeAdvanceMdt or BaseClass(GameMediator, class_name);

function SeasonBpLvUpgradeAdvanceMdt:__init()
end

function SeasonBpLvUpgradeAdvanceMdt:OnShow(data)
end

function SeasonBpLvUpgradeAdvanceMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.TheModel = MvcEntry:GetModel(SeasonBpModel)
    self.TheDepotModel = MvcEntry:GetModel(DepotModel)
    self.BindNodes = 
    {
		-- { UDelegate = self.Button_BGClose.OnClicked,	Func = self.Button_BGClose_OnClicked },
		{ UDelegate = self.WBP_ReuseList.OnUpdateItem,	Func = self.WBP_ReuseList_OnUpdateItem },
		{ UDelegate = self.WBP_ReuseList.OnScrollItem,	Func = self.WBP_ReuseList_OnScrollItem },
	}
    self.MsgList = {
        { Model = ViewModel, MsgName = ViewModel.ON_SATE_ACTIVE_CHANGED,    Func = self.ON_SATE_ACTIVE_CHANGED_FUNC },
    }

    UIHandler.New(self,self.WBP_CommonBtn_Weak_M, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.Button_BGClose_OnClicked),
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("GotIt_Btn")),
        ActionMappingKey = ActionMappings.SpaceBar
    })

    self.Widget2Handler1 = {}
    self.NornalGetRewardList = {}
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    self.PassStatus = self.TheModel:GetPassStatus()
	if not self.PassStatus.OldLevel then
		self.ContentCanGet:SetVisibility(UE.ESlateVisibility.Collapsed)
	end

	self.LbLevel:SetText(tostring(self.PassStatus.Level))
	self.LbLevel_1:SetText(tostring(self.PassStatus.Level))


	if self.PassStatus.OldLevel and self.PassStatus.OldLevel < self.PassStatus.Level then
		self:CalculateCanGetRewardList()
		if #self.NornalGetRewardList <= 0 then
			self.ContentCanGet:SetVisibility(UE.ESlateVisibility.Collapsed)
		else
			self.ContentCanGet:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			self.WBP_ReuseList:Reload(#self.NornalGetRewardList)
		end
	end

    self:PlayDynamicEffectOnShow(true)
end

function M:OnRepeatShow(Param)
    
end

function M:OnHide()
   
end

function M:CalculateCanGetRewardList()
	for i=(self.PassStatus.OldLevel + 1),self.PassStatus.Level do
		local RewardCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.SeasonBpId,Cfg_SeasonBpRewardCfg_P.Level},{self.PassStatus.SeasonBpId,i})
		local DropItemList = self.TheModel:GetDropItemListByBpReward(RewardCfg)--self.TheDepotModel:GetItemListForDropId(RewardCfg[Cfg_SeasonBpRewardCfg_P.DropId])
		if #DropItemList > 0 then
			ListMerge(self.NornalGetRewardList,DropItemList)
		end
	end
end

function M:WBP_ReuseList_OnUpdateItem(Widget,Index)
	local FixIndex = Index + 1

    if not self.Widget2Handler1[Widget] then
        self.Widget2Handler1[Widget]  = UIHandler.New(self,Widget,CommonItemIcon).ViewInstance
    end

    local ItemInfo = self.NornalGetRewardList[Index + 1]
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemInfo.ItemId,
        ItemNum = ItemInfo.ItemNum,
        -- ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.TIP,
        HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        ShowCount = true
    }
    self.Widget2Handler1[Widget]:UpdateUI(IconParam)
end

function M:WBP_ReuseList_OnScrollItem(StartIdx,EndIdx)

end

function M:Button_BGClose_OnClicked()
    MvcEntry:CloseView(self.viewId)
	self.TheModel:SetIsTryToPopUpgrade(self.PassStatus.PassType, false)
end

--[[
    播放显示退出动效
]]
function M:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_OutsideGame_Lvchange_In then
            self:VXE_OutsideGame_Lvchange_In()
        end
    else
        -- if self.VXE_HalllMain_Tab_Out then
        --     self:VXE_HalllMain_Tab_Out()
        -- end
    end
end

--策划特殊需求，赛季通行证升级弹窗打开期间，如果有特殊获取或通用获取弹窗打开，则关闭升级弹窗，临时处理
function M:ON_SATE_ACTIVE_CHANGED_FUNC(ViewId)
    if ViewId == ViewConst.SpecialItemGet or ViewId == ViewConst.ItemGet then
        self:Button_BGClose_OnClicked()
    end
end

return M
