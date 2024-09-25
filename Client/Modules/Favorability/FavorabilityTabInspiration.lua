--[[
    好感度-灵感页签
]]
local class_name = "FavorabilityTabInspiration"
local FavorabilityTabInspiration = BaseClass(UIHandlerViewBase, class_name)


function FavorabilityTabInspiration:OnInit()
    self.BindNodes = {
    	{ UDelegate = self.View.WBP_ThingReuseList.OnUpdateItem,	Func = Bind(self,self.WBP_ThingReuseList_OnUpdateItem) },
		{ UDelegate = self.View.WBP_ThingReuseList.OnDoReload,	Func = Bind(self,self.WBP_ThingReuseList_OnDoReload) },
		{ UDelegate = self.View.WBP_ReuseListEx_Reward.OnUpdateItem,	Func = Bind(self,self.WBP_ReuseListEx_Reward_OnUpdateItem) },
		{ UDelegate = self.View.BtnOutSide.OnClicked,				    Func = Bind(self,self.OnHideGiftPanel) },
		{ UDelegate = self.View.WBP_Favorability_GiftBtn.GUIButton_Main.OnClicked,	Func = Bind(self,self.OnShowGiftPanel) },
	}

    self.MsgList = 
	{
        {Model = FavorabilityModel, MsgName = FavorabilityModel.ON_SEND_GIFT_SUCCESSED, Func = Bind(self,self.OnSendGiftSuccess)},
        {Model = FavorabilityModel, MsgName = FavorabilityModel.LEVEL_LS_IS_PLAYING, Func = Bind(self,self.OnLevelLSIsPlaying)},
	}

	--- @type HeroModel
    self.HeroModel = MvcEntry:GetModel(HeroModel)
    --- @type FavorabilityModel
    self.FavorModel = MvcEntry:GetModel(FavorabilityModel)
    --- @type DepotModel
    self.DepotModel = MvcEntry:GetModel(DepotModel)
	self.IsGiftPanelVisible = false
	self.WidgetToRewardItem = {}
    self.Index2GiftWidget = {}
	self.GiftItemIconCls = {}
    self.LastSelectGift = nil
	self.SliderCls = nil
    self.CurValue = 0
	self.SendGiftUnlockPartId = 0
	self.IsLevelLSPlaying = false
	self.LevelBeforeSendGift = nil
    self:InitCommonUI()
end

function FavorabilityTabInspiration:InitCommonUI()
	self.FavorabilityInfoIns = UIHandler.New(self,self.View.WBP_Favorability_LeveInfo_Item,require("Client.Modules.Favorability.FavorabilityInfoLogic")).ViewInstance
	self.GiftBtn = UIHandler.New(self,self.View.CommonBtnTips_Gift, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnClickGiftBtn),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityGiftMdt_givepresentasagift"),
    }).ViewInstance
end

--[[
    Param = {
		HeroId
    }
]]
function FavorabilityTabInspiration:OnShow(Param)
	if not (Param and Param.HeroId) then
		return
	end
	self.HeroId = Param.HeroId
	self.SwitchShowStateCallback = Param.SwitchShowStateCallback
    self.FavorabilityInfoIns:UpdateUI(self.HeroId)
	self:UpdateRewardList()
	self:UpdateGiftPanel()
end

function FavorabilityTabInspiration:OnManualShow()
	if self.IsGiftPanelVisible then
		self:SetGiftPanelIsVisible(false)
	end
end

function FavorabilityTabInspiration:OnHide()
end

function FavorabilityTabInspiration:OnManualHide()
end

-- 右侧等级奖励列表
function FavorabilityTabInspiration:UpdateRewardList()
	local RewardCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_FavorDropCfg,Cfg_FavorDropCfg_P.HeroId,self.HeroId)
	if not RewardCfgs then
		CError("UpdateRewardList Error For RewardCfg")
		return
	end
	self.RewardCfgs = RewardCfgs
	self.View.WBP_ReuseListEx_Reward:Reload(#RewardCfgs)
end

-- 右侧等级奖励列表 - Item
function FavorabilityTabInspiration:WBP_ReuseListEx_Reward_OnUpdateItem(_,Widget,Index)
	local FixIndex = Index + 1
	local RewardCfg = self.RewardCfgs[FixIndex]
	if not RewardCfg then
		return
	end
	local ItemCls = self.WidgetToRewardItem[Widget]
	if not ItemCls then
		ItemCls = UIHandler.New(self,Widget,require("Client.Modules.Favorability.FavorabilityRewardItemLogic")).ViewInstance
		self.WidgetToRewardItem[Widget] = ItemCls
	end
	local Param = {
		HeroId = self.HeroId,
		RewardCfg = RewardCfg,
		MaxLevel = #self.RewardCfgs
	}
	ItemCls:UpdateUI(Param)
end


-- 左侧送礼界面
function FavorabilityTabInspiration:UpdateGiftPanel()
    self.ShowGiftCfgs = {}
    local Cfgs = G_ConfigHelper:GetDict(Cfg_FavorItemExpCfg)
    if Cfgs then
	
		self.ShowGiftCfgs = Cfgs
	end
	self:SortShowGifts()
    local reuseListWidget = self.View.WBP_ThingReuseList
    local DataLength = #self.ShowGiftCfgs
	local reuseListSizeX = reuseListWidget.Slot:GetSize().X
    local reuseListSizeY = reuseListWidget.Slot:GetSize().Y
    local reuseListItemSize = reuseListWidget:GetItemWidth()
    local reuseListItemOffsetX = reuseListWidget:GetPaddingX()
    local reuseListItemOffsetY = reuseListWidget:GetPaddingY()
    local maxColItemNum = (reuseListSizeX + reuseListItemOffsetX)//(reuseListItemSize + reuseListItemOffsetX)
    local colCount = math.min(DataLength, maxColItemNum)
    local rowCount = math.ceil(DataLength/colCount)
    local totalHeight = reuseListWidget:GetItemInitPaddingY() + (reuseListItemSize + reuseListItemOffsetY) * rowCount - reuseListItemOffsetY
    local newOffset = reuseListWidget.Slot:GetOffsets()
    newOffset.Bottom = math.min(reuseListSizeY,totalHeight)
    reuseListWidget.Slot:SetOffsets(newOffset)

	self.View.WBP_ThingReuseList:Reload(DataLength)
end

function FavorabilityTabInspiration:SortShowGifts()
	if not self.ShowGiftCfgs or #self.ShowGiftCfgs == 0 then
		return
	end
	table.sort(self.ShowGiftCfgs,function (ItemCfgA, ItemCfgB)
		local ItemIdA = ItemCfgA[Cfg_FavorItemExpCfg_P.ItemId]
		local ItemIdB = ItemCfgB[Cfg_FavorItemExpCfg_P.ItemId]
		local HaveNumA = self.DepotModel:GetItemCountByItemId(ItemIdA)
		local HaveNumB = self.DepotModel:GetItemCountByItemId(ItemIdB)
		if HaveNumA == 0 and HaveNumB > 0 then
			return false
		elseif HaveNumA > 0 and HaveNumB == 0 then
			return true
		else
			return ItemIdA > ItemIdB
		end
	end)
end

-- Widget: WBP_Favorability_RewardItem
function FavorabilityTabInspiration:WBP_ThingReuseList_OnUpdateItem(_,Widget,Index)
	local FixIndex = Index + 1
	local Cfg = self.ShowGiftCfgs[FixIndex]
	if not Cfg then
		return
	end
    local ItemCls = self.GiftItemIconCls[Widget]
    self.Index2GiftWidget[FixIndex] = Widget
    if not ItemCls then
        ItemCls = UIHandler.New(self,Widget,CommonItemIcon).ViewInstance
        self.GiftItemIconCls[Widget] = ItemCls
    end
	local ItemId = Cfg[Cfg_FavorItemExpCfg_P.ItemId]
	local HaveNum = self.DepotModel:GetItemCountByItemId(ItemId)
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemId,
        ItemNum = HaveNum,
        ClickCallBackFunc = Bind(self,self.OnItemClick,FixIndex),
        IsBreakClick = true,
		IsNotCheckItemCountCornerTag = true
    }
    ItemCls:UpdateUI(IconParam)
    ItemCls:SetIsMask(HaveNum == 0)
end

function FavorabilityTabInspiration:WBP_ThingReuseList_OnDoReload()
	-- -- 默认选中第一个
	if not self.LastSelectGift then
		self:OnItemClick(1)
	end
end

function FavorabilityTabInspiration:SetGiftPanelIsVisible(IsVisible,NotCallback)
	self.IsGiftPanelVisible = IsVisible
	self.View.BtnOutSide:SetVisibility(IsVisible and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
	self.View.GiftPanel:SetVisibility(IsVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
	if not NotCallback and self.SwitchShowStateCallback then
		self:SwitchShowStateCallback(IsVisible)
	end
end

function FavorabilityTabInspiration:OnShowGiftPanel()
	self:SetGiftPanelIsVisible(true)
end

function FavorabilityTabInspiration:OnHideGiftPanel()
	if self.IsLevelLSPlaying then
		return
	end
	self:SetGiftPanelIsVisible(false)
end

-- 选择礼品部分显示
function FavorabilityTabInspiration:UpdateSelectInfo(Index)
	local FavorItemExpCfg = self.ShowGiftCfgs[Index]
	if not FavorItemExpCfg then
		return
	end
	local ItemId = FavorItemExpCfg[Cfg_FavorItemExpCfg_P.ItemId]
	local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
	if not ItemCfg then
		return
	end
	self.SelectIndex = Index
    self.SelectItemId = ItemId
	self.View.Text_ItemName:SetText(ItemCfg[Cfg_ItemConfig_P.Name])
    self.View.Text_ItemDes:SetText(ItemCfg[Cfg_ItemConfig_P.Des])
	self:UpdateGiftBtnStatus()
end

-- 更新送礼按钮的展示状态
function FavorabilityTabInspiration:UpdateGiftBtnStatus()
	local CurLevel = self.FavorModel:GetCurFavorLevel(self.HeroId)
	self.SendGiftUnlockPartId = self.FavorModel:GetSendGiftUnlockPartId(self.HeroId,CurLevel)
	self.View.Panel_NumSlider:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.PanelJumpPartTips:SetVisibility(UE.ESlateVisibility.Collapsed)
	if self.SendGiftUnlockPartId == 0 then
		local IsFullLevel = self.FavorModel:IsFavorFullLevel(self.HeroId)
		local HaveNum = self.DepotModel:GetItemCountByItemId(self.SelectItemId)
		if HaveNum > 0 then
			if not IsFullLevel then
				if HaveNum > 1 then
					self.View.Panel_NumSlider:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
					local Param = {
						ValueChangeCallBack = Bind(self, self.ValueChangeCallBack),
						MaxValue = HaveNum
					}
					if not self.SliderCls then
						self.SliderCls = UIHandler.New(self, self.View.WBP_CommonEditableSlider, CommonEditableSlider, Param).ViewInstance
					else
						self.SliderCls:UpdateItemInfo(Param)
					end
				else
					self.CurValue = 1
				end
			end
			self.GiftBtn:SetBtnJumpIdList(nil)
			self.GiftBtn:SetBtnEnabled(not IsFullLevel, IsFullLevel and G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityGiftMdt_Thegradeisfull") or G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityGiftMdt_givepresentasagift"))
		else
			-- 设置跳转
			local ItemConfig = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, self.SelectItemId)
			if ItemConfig then
				self.GiftBtn:SetBtnJumpIdList(ItemConfig[Cfg_ItemConfig_P.JumpID])
			end
		end
	else
		-- 去完成剧情
		local StoryCfg = G_ConfigHelper:GetSingleItemById(Cfg_FavorStoryConfig, self.SendGiftUnlockPartId)
		if StoryCfg then
			self.View.PanelJumpPartTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			local TipsStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityTabInspiration_JumpToStoryTips")
			self.View.Text_JumpPartTips:SetText(StringUtil.Format(TipsStr,StoryCfg[Cfg_FavorStoryConfig_P.ChapterName]))
		end
		self.GiftBtn:SetBtnEnabled(true,G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityTabInspiration_GoToComplete"))
	end
end

function FavorabilityTabInspiration:ValueChangeCallBack(CurValue)
	local FixValue = self.FavorModel:FixMaxExpItemCount(self.HeroId,self.SelectItemId,CurValue)
	if self.SliderCls and FixValue < CurValue then
		UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityTabInspiration_SliderMaxTips"))
		self.SliderCls:SetCurValue(FixValue)
	    self.CurValue = FixValue
	else
	    self.CurValue = CurValue
	end
end

function FavorabilityTabInspiration:OnClickGiftBtn()
	if self.SendGiftUnlockPartId > 0 then
		-- 跳转到剧情
		local StoryCfg = self.FavorModel:GetCanPlayStory(self.HeroId,self.SendGiftUnlockPartId)
		if StoryCfg then
			-- 有可播放的剧情则跳转剧情
			MvcEntry:GetCtrl(DialogSystemCtrl):PlayStory(StoryCfg)
		else
			-- 没有则跳转大厅 todo 未来可能修改为调整模式选择
			self.FavorModel:SetIsCloseFromFavorMain(true)
    		MvcEntry:GetCtrl(ViewJumpCtrl):HallTabSwitch(CommonConst.HL_PLAY)
		end
	else
		-- 送礼
		if self.SelectItemId and self.CurValue > 0 then
			self.LevelBeforeSendGift = self.FavorModel:GetCurFavorLevel(self.HeroId)
			local Param = {
				HeroId = self.HeroId,
				ItemId = self.SelectItemId,
				ItemNum = self.CurValue,
			}
			MvcEntry:GetCtrl(FavorabilityCtrl):SendProto_PlayerSendHeroGiftReq(Param)
		end
	end
end

--[[
	送礼成功
	Msg = {
		int64 HeroId = 1;                   // 赠送英雄Id
		int64 ItemId = 2;                   // 赠送物品Id
		int64 ItemNum= 3;                   // 赠送物品数量    
	}
]]
function FavorabilityTabInspiration:OnSendGiftSuccess(_,Msg)
	for _,IconItemCls in pairs(self.GiftItemIconCls) do
		local ItemId = IconItemCls:GetItemId()
		if ItemId then
			local HaveNum = self.DepotModel:GetItemCountByItemId(ItemId)
			IconItemCls:SetShowCount(HaveNum)
			IconItemCls:SetIsMask(HaveNum == 0)
		end
	end
	-- self:SortShowGifts()
	-- self.View.WBP_ThingReuseList:Reload(#self.ShowGiftCfgs)
    self:UpdateGiftBtnStatus()

	local CurLevel = self.FavorModel:GetCurFavorLevel(self.HeroId)
	if self.LevelBeforeSendGift and CurLevel == self.LevelBeforeSendGift then
		-- 送完未升级的情况，根据赠送的道具播放语音
		-- 如果是升级了，在 FavorablityMainMdt 的升级表现中播放 这里不处理
		-- 播放语音
		local IsFavor = false
		local FavorItemCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_FavorItemExpCfg,{Cfg_FavorItemExpCfg_P.HeroId,Cfg_FavorItemExpCfg_P.ItemId},{Msg.HeroId,Msg.ItemId})
		if FavorItemCfg then
			IsFavor = FavorItemCfg[Cfg_FavorItemExpCfg_P.IsFavor]
		end
		local SoundVoiceKey = SoundCfg.Voice.FAVOR_NOT_LIKE
		if IsFavor then
			local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, Msg.ItemId)
			if ItemCfg then
				local Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
				if Quality >= 4 then
					SoundVoiceKey = SoundCfg.Voice.FAVOR_HIGH_LIKE
				else
					SoundVoiceKey = SoundCfg.Voice.FAVOR_LOW_LIKE
				end
			end
		end
		local SkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(Msg.HeroId)
		if SkinId > 0 then
			SoundMgr:PlayHeroVoice(SkinId, SoundVoiceKey)
		end
	end
	self.LevelBeforeSendGift = nil
end


function FavorabilityTabInspiration:OnItemClick(Index)
    if self.LastSelectGift then
        self.LastSelectGift:SetIsSelect(false)
    end
    local Widget = self.Index2GiftWidget[Index]
    if not Widget then
        return
    end
    local SelectGift = self.GiftItemIconCls[Widget]
    if SelectGift then
        SelectGift:SetIsSelect(true,true)
        self.LastSelectGift = SelectGift
        self:UpdateSelectInfo(Index)
    end
end

function FavorabilityTabInspiration:OnLevelLSIsPlaying(_,IsPlaying)
	self.IsLevelLSPlaying = IsPlaying
end

return FavorabilityTabInspiration
