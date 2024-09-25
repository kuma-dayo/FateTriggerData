--[[
    邮件列表Item
]]
local class_name = "MailItem";
local MailItem =  BaseClass(nil, class_name);

function MailItem:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.Btn_Mail.OnClicked,				    Func = Bind(self,self.OnMailItemClicked) },
		-- { UDelegate = self.View.NotRead.OnClicked,				    Func = Bind(self,self.OnMailItemClicked) },
	}
end

function MailItem:OnShow(Param)
    self.Param = Param
	self.IsSelect = false
end

function MailItem:OnHide()
	self:ClearTimeShowTick()
end

function MailItem:OnMailItemClicked()
	if self.Param.OnItemClick then
        self.Param.OnItemClick(self, self.MailData, self.Index)

		self:InteractRedDot()
    end
end

function MailItem:SetGiftIconVisibility()
	local MailMainMdt = self.WidgetBase
	if MailMainMdt ~= nil then
		local HasAttach = MailMainMdt:GetCurTabMailModel():HasAttached(self.MailData)
		if HasAttach then
			self.View.GiftIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			return
		end
	end
	self.View.GiftIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function MailItem:RefreshItemState()
	self.View:SetItemState(self.MailData and self.MailData.ReadFlag, self.IsSelect)
	-- self.View.Image_Hover:SetRenderOpacity(self.IsSelect and 1 or 0)
	-- self.View:SetItemState(false, self.IsSelect)
	-- if self.MailData and self.MailData.ReadFlag then
	-- 	-- self.View.HaveReadMask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	-- 	-- CommonUtil.SetImageColorFromHex(self.View.HeadIcon, "969696FF")
	-- 	self.View.MailStateSwitcher:SetActiveWidget(self.View.AlreadyRead)
	-- else
	-- 	-- self.View.HaveReadMask:SetVisibility(UE.ESlateVisibility.Collapsed)
	-- 	-- CommonUtil.SetImageColorFromHex(self.View.HeadIcon, UIHelper.HexColor.White)
	-- 	self.View.MailStateSwitcher:SetActiveWidget(self.View.NotRead)
	-- end
end

function MailItem:SetItemData(MailData, Index)
	if MailData == nil or Index == nil then
		return
	end
	self.Index = Index
	self.MailData = MvcEntry:GetCtrl(MailCtrl):ConvertMailInfo(MailData)
	self.HasAttach = self.WidgetBase ~= nil and self.WidgetBase:GetCurTabMailModel():HasAttached(self.MailData)

	if MailData.TitleTextId > 0 then
		local LanguageCallBack = function (TextStr)
			if not CommonUtil.IsValid(self.View) then
				return
			end
			self.View.MailTitle:SetText(TextStr)
		end
		MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(MailData.TitleTextId, LanguageCallBack)
	else
		self.View.MailTitle:SetText(MailData.Title)
	end
	self.View.MailSender:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Mail', "Lua_MailItem_From"),MailData.SendPlayerName))
	-- 时间
	self.LeftTime = MailData.ExpireTime > 0 and MailData.ExpireTime - GetTimestamp() or 0
	if self.LeftTime > 0 then
		self:UpdateTimeShow()
		self:ScheduleTimeShowTick()
	else
		self:ClearTimeShowTick()
		--没有过期时间的，不显示时间文本
		if MailData.ExpireTime == 0 then
			self.View.MailExpireTime:SetVisibility(UE.ESlateVisibility.Collapsed)
		else
			self:UpdateTimeShow()
		end
	end
	 
	CommonUtil.SetBrushFromSoftObjectPath(self.View.HeadIcon,self.MailData.HeadIcon)
	-- CommonUtil.SetMaterialTextureParamSoftObjectPath(self.View.HeadIcon,"Target",self.MailData.HeadIcon)
	self:SetGiftIconVisibility()
	
	self:HandleStateShow()
	self:RegisterRedDot()
end

-- 时间刷新显示
function MailItem:ScheduleTimeShowTick()
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
function MailItem:UpdateTimeShow()
    if not CommonUtil.IsValid(self.View) then
        self:ClearTimeShowTick()
        print("Mail Already Releaed")
        return
    end
    if not self.MailData then
        return
    end
	self:UpdateTimeTextColor()
	self.View.MailExpireTime:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.MailExpireTime:SetText(StringUtil.FormatExpireTimeShowStr(self.LeftTime, self.MailData.ExpireTime))
end

function MailItem:ClearTimeShowTick()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end


function MailItem:Select()
	self.IsSelect = true
	self:HandleStateShow()
end

function MailItem:UnSelect()
	self.IsSelect = false
	self:HandleStateShow()
end

function MailItem:HandleStateShow()
	--更新邮件item状态
	self:RefreshItemState()
end

--更新倒计时文字颜色
function MailItem:UpdateTimeTextColor()
	--未读状态，且时间低于一天，显示红色
	if self.LeftTime and self.LeftTime < 60 * 60 * 24 and self.MailData and not self.MailData.ReadFlag then
		if self.View.VXE_Mail_List_TimeWillExpired then
			self.View:VXE_Mail_List_TimeWillExpired()
			self.View.IsWillExpired = true
		end
	else
		self.View.IsWillExpired = false
	end
end

-- 绑定红点
function MailItem:RegisterRedDot()
	if self.MailData then
	    local WBP_RedDotFactory = self.View.WBP_RedDotFactory
		if WBP_RedDotFactory then
			WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			local RedDotKey = "MailTabItem_"
			local RedDotSuffix = self.MailData.MailUniqId
			if not self.ItemRedDot then
				self.ItemRedDot = UIHandler.New(self, WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
			else 
				self.ItemRedDot:ChangeKey(RedDotKey, RedDotSuffix)
			end  
		end
	end
end

-- 红点触发逻辑
function MailItem:InteractRedDot()
    if self.ItemRedDot then
        self.ItemRedDot:Interact()
    end
end

return MailItem
