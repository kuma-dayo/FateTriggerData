--[[
	邮件详情界面
]]
local class_name = "MailDetailLogic";
local MailDetailLogic = BaseClass(nil, class_name);

function MailDetailLogic:OnInit()
    self.BindNodes = 
    {
		-- { UDelegate = self.View.BtnCloseDetail.OnClicked,				    Func = Bind(self,self.OnCloseDetailClicked) },
		{ UDelegate = self.View.WBP_ReuseList.OnUpdateItem,				    Func = Bind(self,self.OnUpdateMailAttachItem) },
	}

	UIHandler.New(self,self.View.Btn_MailGetAward, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnGUIButtonGetClicked),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Mail', "Lua_MailDetailLogic_Receiveareward_Btn"),
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })
	
	UIHandler.New(self,self.View.Btn_MailDelete, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnGUIButtonDeleteOneClicked),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Mail', "Lua_MailDetailLogic_delete_Btn"),
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
		
    })
	
	-- self.View.ButtonStateWidgetSwitcher
end

--[[
	Param = {
		MailData --邮件信息
		PageType --页签类型
	}
]]
function MailDetailLogic:OnShow(Param)
	if Param == nil or not Param.MailData or not Param.PageType then
		return
	end
    self.MailData = Param.MailData
	self.MailAttachItemWidgetList = {}
	self:UpdateMailDetail(Param)
end

function MailDetailLogic:OnHide()
	self:ClearTimeShowTick()
end

function MailDetailLogic:UpdateMailDetail(Param)
	if Param == nil or not Param.MailData then
		return
	end
	local MailData = Param.MailData
	if Param.PageType ~= nil then
		self.PageType = Param.PageType
	end
	self.MailData = MvcEntry:GetCtrl(MailCtrl):ConvertMailInfo(MailData)

	self.View.ContentScrollBox:ScrollToStart()
	
	if self.MailData.TitleTextId > 0 then
		local LanguageCallBack = function (TextStr)
			if not CommonUtil.IsValid(self.View) then
				return
			end
			self.View.MailTitle:SetText(TextStr)
		end
		MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(self.MailData.TitleTextId, LanguageCallBack)
	else
		self.View.MailTitle:SetText(self.MailData.Title)
	end
	self.View.FromWho:SetText(self.MailData.SendPlayerName)

	self.View.Time:SetText(TimeUtils.GetDateFromTimeStamp(MailData.RealSendTime))
	
	if self.MailData.ContextTextId > 0 then
		local LanguageCallBack = function (TextStr)
			if not CommonUtil.IsValid(self.View) then
				return
			end
			self.View.MailContent:SetText(TextStr)
		end
		MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(self.MailData.ContextTextId, LanguageCallBack)
	else
		self.View.MailContent:SetText(self.MailData.Context)
	end
	
	CommonUtil.SetBrushFromSoftObjectPath(self.View.HeadIcon,self.MailData.HeadIcon)
	-- 时间
	self.LeftTime = MailData.ExpireTime > 0 and MailData.ExpireTime - GetTimestamp() or 0
	if self.LeftTime > 0 then
		self.View.TimeExpireBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self:UpdateTimeShow()
		self:ScheduleTimeShowTick()
		self:UpdateTimeShowColor()
	else
		self:ClearTimeShowTick()
		self.View.TimeExpireBox:SetVisibility(UE.ESlateVisibility.Hidden)
	end
	self:SetGiftIconVisibility()
	self:RefreshMailAttachedList()
	self:RefreshAttachStatusButton()
	self:RefreshReadFlag()

	self:SetMailRead()
end

function MailDetailLogic:UpdateTimeShowColor()
    if not CommonUtil.IsValid(self.View.TimeExpire) then
        return
    end
	local MailMainMdt = self.WidgetBase
	if MailMainMdt == nil then
		return
	end
	local HasAttach = MailMainMdt:GetCurTabMailModel():HasAttached(self.MailData)
	if self.LeftTime < 60 * 60 * 24 and HasAttach then
		CommonUtil.SetTextColorFromeHex(self.View.TimeExpire,"FA090CCC")
	else
		CommonUtil.SetTextColorFromeHex(self.View.TimeExpire,"F5EFDF")
	end
end

function MailDetailLogic:OnCloseDetailClicked()
	self:UpdateMailDetailVisibility(false)
	self:ClearTimeShowTick()
end

function MailDetailLogic:OnGUIButtonGetClicked()
	local MailMainMdt = self.WidgetBase
	if MailMainMdt == nil then
		return
	end
	if self.MailData == nil then
		return
	end
	local HasAttach = MailMainMdt:GetCurTabMailModel():HasAttached(self.MailData)
	if not HasAttach then 
		return
	end
	MvcEntry:GetCtrl(MailCtrl):SendProto_PlayerGetAppendReq(self.PageType, 
		{self.MailData.MailUniqId})
end

function MailDetailLogic:OnGUIButtonDeleteOneClicked()
	local MailMainMdt = self.WidgetBase
	if MailMainMdt == nil then
		return
	end
	if self.MailData == nil then
		return
	end
	local HasAttach = MailMainMdt:GetCurTabMailModel():HasAttached(self.MailData)
	if HasAttach then 
		return
	end
	MvcEntry:GetCtrl(MailCtrl):SendProto_PlayerDeleteMailReq(self.PageType, {self.MailData.MailUniqId})
end


function MailDetailLogic:UpdateMailDetailVisibility(IsVisible)
	if not IsVisible then 
		self.View.LeftUI:SetVisibility(UE.ESlateVisibility.Collapsed)
	else 
		self.View.LeftUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	end
end

function MailDetailLogic:IsVisible()
	return self.View.LeftUI:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible
end

function MailDetailLogic:SetGiftIconVisibility()
	-- local MailMainMdt = self.WidgetBase
	-- if MailMainMdt ~= nil then
	-- 	local HasAttach = MailMainMdt:GetCurTabMailModel():HasAttached(self.MailData)
	-- 	if HasAttach then
	-- 		self.View.GiftIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	-- 		return
	-- 	end
	-- end
	-- self.View.GiftIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function MailDetailLogic:RefreshReadFlag()
	-- if self.MailData and self.MailData.ReadFlag then
	-- 	self.View.GTBRead:SetText(StringUtil.Format("已读"))
	-- else
	-- 	self.View.GTBRead:SetText(StringUtil.Format(""))
	-- end
end


function MailDetailLogic:SetMailRead()
	if self.MailData == nil then
		return
	end
	if self.MailData.ReadFlag then
		return
	end
	local MailMainMdt = self.WidgetBase
	if MailMainMdt == nil then
		return
	end
	CLog("SetMailRead MailUniqId = "..self.MailData.MailUniqId)
	
	local PageType = MailMainMdt:GetPageTypeByCurTab()
	MvcEntry:GetCtrl(MailCtrl):SendProto_PlayerReadMailReq(PageType, 
		{self.MailData.MailUniqId})
end


-- 时间刷新显示
function MailDetailLogic:ScheduleTimeShowTick()
    self:ClearTimeShowTick()
    self.CheckTimer = Timer.InsertTimer(1,function()
        self.LeftTime = self.LeftTime - 1
		self:UpdateTimeShow()
        if self.LeftTime <= 0 then
            self:ClearTimeShowTick()
        end
	end,true)   
end

-- 更新剩余时间显示
function MailDetailLogic:UpdateTimeShow()
    if not CommonUtil.IsValid(self.View) then
        self:ClearTimeShowTick()
        print("Mail Already Releaed")
        return
    end
    if not self.MailData then
        return
    end
    self.View.TimeExpire:SetText(StringUtil.FormatExpireTimeShowStr(self.LeftTime, self.MailData.ExpireTime))
end

function MailDetailLogic:ClearTimeShowTick()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

function MailDetailLogic:RefreshMailAttachedList()
	if self.MailData == nil then
		return
	end
	if #self.MailData.AppendList == 0 then
		self.View.RewardRoot:SetVisibility(UE.ESlateVisibility.Collapsed)
		return
	end
	self.View.RewardRoot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

	table.sort(self.MailData.AppendList, function(a, b)
		local Cfg_A =  G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,a.ItemId)
		local Cfg_B =  G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,b.ItemId)
		if Cfg_A and Cfg_B then
			local Quality_A = Cfg_A[Cfg_ItemConfig_P.Quality]
			local Quality_B = Cfg_B[Cfg_ItemConfig_P.Quality]
			if Quality_A ~= Quality_B then
				return Quality_A > Quality_B
			else
				return a.ItemId < b.ItemId
			end
		end
	end)
	self.View.WBP_ReuseList:Reload(#self.MailData.AppendList)
end

function MailDetailLogic:RefreshAttachStatusButton()
	if self.MailData == nil then
		return
	end
	local MailMainMdt = self.WidgetBase
	if MailMainMdt == nil then
		return
	end
	local HasAttach = MailMainMdt:GetCurTabMailModel():HasAttached(self.MailData)
	self.View.Btn_MailGetAward:SetVisibility(HasAttach and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
	self.View.Btn_MailDelete:SetVisibility(HasAttach and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
end

function MailDetailLogic:OnUpdateMailAttachItem(Handler, Widget, Index)
	if self.MailData == nil then
		return
	end
	local i = Index + 1
	local MailAttachData = self.MailData.AppendList[i]
	if MailAttachData == nil then
		return
	end

	local IconParam = {
		IconType = CommonItemIcon.ICON_TYPE.PROP,
		ItemId = MailAttachData.ItemId,
		ItemUniqId = MailAttachData.ItemId,
		ItemNum = MailAttachData.ItemNum,
		HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
		IsGot = self.MailData.ReceiveAppend,
	}
	local Item = self.MailAttachItemWidgetList[Widget]
	if not Item then
		Item = UIHandler.New(self, Widget, CommonItemIcon, IconParam).ViewInstance
		self.MailAttachItemWidgetList[Widget] = Item
	else
		Item:UpdateUI(IconParam)
	end
end

return MailDetailLogic