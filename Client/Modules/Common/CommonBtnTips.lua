--[[
    通用的CommonTips控件
]]
require "UnLua"

local class_name = "WCommonBtnTips"
---@class WCommonBtnTips
WCommonBtnTips = WCommonBtnTips or BaseClass(UIHandlerViewBase, class_name)
WCommonBtnTips.HoverFontStyleType = {
	None = 0,
	Main = 1,	-- 一级通用按钮
	Second = 2,	-- 二级通用按钮
}

WCommonBtnTips.ShowStyleType = {
    None = 0, -- 默认
    Price = 1 -- 带有价格标签
}

function WCommonBtnTips:OnInit(Param)
    self.BindNodes = {
		{ UDelegate = self.View.GUIButton_Tips.OnClicked,				Func = Bind(self,self.OnItemButtonClick) },
		-- Hover效果均放入动效实现
		-- { UDelegate = self.View.GUIButton_Tips.OnHovered,				Func = Bind(self,self.OnBtnHovered) },
		-- { UDelegate = self.View.GUIButton_Tips.OnUnhovered,				Func = Bind(self,self.OnBtnUnovered) },
	}
	if Param and Param.ActionMappingKey then
		self.MsgList =
		{
			{Model = InputModel, MsgName = ActionPressed_Event(Param.ActionMappingKey), Func = Bind(self,self.OnItemButtonClick) },
		}
	end

	-- 按钮文字的样式
	self.SpecialFontInfo = {
		[WCommonBtnTips.HoverFontStyleType.Second] = {
			["Normal"] = {Color = "F5EFDF"},
			["Black"] = {Color = "1B2024"},
		}
	}

	self.IsBtnEnabled = true
	self.InputFocus = true
end

--[[
	Param = {
		OnItemClick 		= function() end,						--【可选】点击回调
		TipStr				= "提示文本" 							--【可选】提示文本（如果有值 会优先使用此文本进行展示）
		bHideTipStr			= false									--【可选】提示文本（如果有值 会优先使用此文本进行展示
		CommonTipsID 		= CommonConst.CT_SPACE  				--【可选】提示ID，可以通过提示ID，获取提示按钮纹理及文本
		ActionMappingKey, 	= ActionMappings.Escape 				--【可选】对应的键盘按键，点击按钮也能触发回调，参考 ActionMappings (Const.lua)
		CheckButtonIsVisible = false,								--【可选】检查按钮真实可见性
		HoverFontStyleType  = WCommonBtnTips.HoverFontStyleType.None--【可选】Hover时字体的大小和颜色类型（可选） 默认不开 WCommonBtnTips.HoverFontStyleType.None
		SureNoMappingKey = false									--【可选】确定没有对应的键盘按键。只是用于不检测产生warning
		
		CurrencyId			= 1, 									--【可选】货币Id
		CurrencyNum  		= 1,									--【可选，CurrencyId有值时生效】货币数量
		CurrencyStr			= "xxx",								--【可选，CurrencyId有值时生效】展示货币时的描述字符串，跟CurrencyNum互斥
		ShowStyleType 		= WCommonBtnTips.ShowStyleType.Price	--【可选】可选择按钮显示的类型
		CommonPriceParam 	= { ... }								--【可选，ShowStyleType为Price时有效】价格参数,风格类型是Price时作为货币类型
		
		JumpIDList          = 1,                                    --【可选，ShowStyleType为Price时，将JumpIDList放进CommonPriceParam传入】需传TArray类型，按钮跳转ID列表，跳转界面及设置按钮文字
		JumpExtraCallBack 	= function() end,						--【可选】跳转时额外回调
	}
]]
function WCommonBtnTips:OnShow(Param)
	if not Param then
		return
	end
	self:CheckParam(Param)
	self:UpdateItemInfo(Param)
end

function WCommonBtnTips:OnHide()
end

function WCommonBtnTips:OnManualHide()
	-- 如果是被手动关闭。BindNodes监听会被移除。需要手动重置下UnHovered状态
	-- self:OnBtnUnovered()
end

function WCommonBtnTips:CheckParam(Param)
	if not Param then
		return
	end
	if (not Param.SureNoMappingKey and Param.CommonTipsID ~= nil and Param.ActionMappingKey == nil) then
		-- 只有按钮Icon，没有实际对应按键功能，warning提示。如实际需求如此，忽略此提示
		CWaring("WCommonBtnTips Use CommonTipsID without ActionMappingKey, Please Check!",true)
	end
end

function WCommonBtnTips:OnItemButtonClick()
	-- CLog("ItemButton Clicked")
	if self.Param == nil then 
		return
	end
	if not self.IsBtnEnabled then
		return
	end
	
	if self.Param.CheckButtonIsVisible then
		--检查按钮运行时真实可见性，如果不可见，不响应事件
		if not CommonUtil.GetWidgetIsVisibleReal(self.View.GUIButton_Tips) then
			return
		end
	end
	-- 若JumpIDList不为nil时跳转至对应界面
	if self.Param.JumpIDList ~= nil and self.Param.JumpIDList:Length() > 0 then
		if self.Param.JumpExtraCallBack then
			self.Param.JumpExtraCallBack()
		end
		MvcEntry:GetCtrl(ViewJumpCtrl):JumpToByTArrayList(self.Param.JumpIDList)
		return
	end
    if self.Param.OnItemClick then
        self.Param.OnItemClick()
    end
	return true
end

function WCommonBtnTips:UpdateItemInfo(Param)
	if Param == nil then 
		CError("WCommonBtnTips Need Param !!",true)
		return 
	end
	if self.View == nil then 
		return 
	end
	self.Param = Param

	self.HoverFontStyleType = self.Param.HoverFontStyleType or WCommonBtnTips.HoverFontStyleType.None
    self.ShowStyleType = self.Param.ShowStyleType or WCommonBtnTips.ShowStyleType.None

	local CommonTipsCfg = nil
	local CommonTipsID = self.Param.CommonTipsID
	if CommonTipsID ~= nil and CommonTipsID ~= 0 then 
		CommonTipsCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_CommonBtnTipsConfig,
			Cfg_CommonBtnTipsConfig_P.TipsID, CommonTipsID)
		if CommonTipsCfg == nil then 
			CError("WCommonBtnTips:UpdateItemInfo CommonTipsCfg nil",true)
			return 
		end
		self.TipsIconPath = CommonTipsCfg.TipsIcon
		self.TipsBlackIconPath = CommonTipsCfg.TipsBlackIcon
		self:SetBtnIcon()
	else
		if CommonUtil.IsValid(self.View.ControlTipsIcon) then
			self.View.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)	
		end
	end

	local TipStr = ""
	if self.Param.CurrencyId then
		-- 展示需要购买的货币
		if self.Param.CurrencyStr then
			TipStr = self.Param.CurrencyStr
		else
			TipStr = self.Param.CurrencyNum or 0
		end
	else
		-- 默认隐藏货币
		self:SetCommonPriceHide(true)
		
		if self.Param.TipStr == nil then
			if CommonTipsCfg ~= nil then
				TipStr = CommonTipsCfg[Cfg_CommonBtnTipsConfig_P.TipsText] or ""
			end
		else 
			TipStr = self.Param.TipStr
		end
	end
	if self.Param.JumpIDList ~= nil and self.Param.JumpIDList:Length() > 0 then
		TipStr = MvcEntry:GetCtrl(ViewJumpCtrl):GetBtnName(self.Param.JumpIDList)
	end
	self.View.ControlTipsTxt:SetText(StringUtil.Format(TipStr))
	self:SetTipsStrHide(self.Param.bHideTipStr)

    self:HandleShowStyle()

	-- 设置按钮文本颜色
	if self.SpecialFontInfo[self.HoverFontStyleType] then
		local FontInfo = self.View.IsAlwaysBlack and self.SpecialFontInfo[self.HoverFontStyleType].Black or self.SpecialFontInfo[self.HoverFontStyleType].Normal
		if FontInfo then
			self:SetFont(FontInfo)
		end
	end
	self:SetBtnDisabledByJumpIdList()
end

function WCommonBtnTips:HandleShowStyle()
    if self.ShowStyleType == WCommonBtnTips.ShowStyleType.Price then
		self:SetCommonPriceHide(false)
		self:UpdatePriceShow(self.Param.CommonPriceParam)
	else
		self:SetCommonPriceHide(true)
		self:SetDiscountNodeHide(true)
    end
end

--- 设置价格节点是否隐藏
---@param bHide boolean true.代表隐藏
function WCommonBtnTips:SetCommonPriceHide(bHide)
	if CommonUtil.IsValid(self.View.WBP_CommonPriceNormal) then
		if bHide then
			self.View.WBP_CommonPriceNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
		else
			self.View.WBP_CommonPriceNormal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		end
	end

	if CommonUtil.IsValid(self.View.ScaleBox_Icon) then
		self.View.ScaleBox_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
	end	
end

--- 设置折扣节点是否隐藏
---@param bHide boolean true.代表隐藏
function WCommonBtnTips:SetDiscountNodeHide(bHide)
	if bHide then
		if self.View.VXE_CommonBtn_UseDiscount then
			self.View:VXE_CommonBtn_UseDiscount(false)
		end
	else
		if self.View.VXE_CommonBtn_UseDiscount then
			self.View:VXE_CommonBtn_UseDiscount(true)
		end
	end
end

--- 更新价格显示
---@param Params CommonPriceParam
function WCommonBtnTips:UpdatePriceShow(Params)
    if self.ShowStyleType == WCommonBtnTips.ShowStyleType.Price then
        if not CommonUtil.IsValid(self.View.WBP_CommonPriceNormal) then
			if self.Param.JumpIDList ~= nil and self.Param.JumpIDList:Length() > 0 then
				self.View.ControlTipsTxt:SetText(StringUtil.Format(MvcEntry:GetCtrl(ViewJumpCtrl):GetBtnName(self.Param.JumpIDList)))
			end
            return
        end
        if self.CommonPriceIns == nil or not(self.CommonPriceIns:IsValid()) then
			self.CommonPriceIns = UIHandler.New(self, self.View.WBP_CommonPriceNormal, CommonPrice, Params).ViewInstance
		else
			self.CommonPriceIns:UpdateItemInfo(Params)
		end

		if Params.SettlementSum and Params.SettlementSum.Discount and Params.SettlementSum.Discount > 0 then
			self:SetDiscountNodeHide(false)

			if CommonUtil.IsValid(self.View.LbDiscountPersent) then
				self.View.LbDiscountPersent:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_3"), Params.SettlementSum.Discount))	
			end
		else
			self:SetDiscountNodeHide(true)
		end
	else
		--TODO
		return
    end
end


---设置按钮图标
function WCommonBtnTips:SetBtnIcon()
	local CommonTipsID = self.Param and self.Param.CommonTipsID or 0
	if not (CommonTipsID ~= nil and CommonTipsID ~= 0) then 
		return
	end
	if not self.TipsIconPath then
		CError("WCommonBtnTips:SetBtnIcon TipsIconPath nil")
		return
	end
	local IsShowBlack = self.HoverFontStyleType == WCommonBtnTips.HoverFontStyleType.Main or self.View.IsAlwaysBlack
	local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(IsShowBlack and self.TipsBlackIconPath or self.TipsIconPath)
	if ImageSoftObjectPtr ~= nil then 
		if CommonUtil.IsValid(self.View.ControlTipsIcon) then
			self.View.ControlTipsIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr,true)
			self.View.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		end
	end
end

-- 设置货币展示以及按钮可交互性
function WCommonBtnTips:ShowCurrency(CurrencyId, CurrencyNum, List)
	self.Param.JumpIDList = List

	if CurrencyId and CurrencyNum then
		---@type SettlementSum
		local SettlementSum = {
			GoodsId = 0,
			Count = 1,
			CurrencyType = CurrencyId,
			TotalSettlementPrice = CurrencyNum,
			TotalPrice = CurrencyNum,
			TotalSuggestedPrice = CurrencyNum,
			TotalOwnPrice = CurrencyNum,
			Discount = 0
		}
		---@type CommonPriceParam
		local CommonPriceParam = {
			CurrencyType = CurrencyId,
			SettlementSum = SettlementSum,
			FreeStyle = CommonPrice.FreeStyle.Default,
			JumpIDList = List
		}
		self.Param.CommonPriceParam = CommonPriceParam
		self.ShowStyleType = WCommonBtnTips.ShowStyleType.Price

		self:SetCommonPriceHide(false)
		self:SetTipsStrHide(true)
		self:UpdatePriceShow(CommonPriceParam)
	else
		local TipStr = self.Param.JumpIDList ~= nil and self.Param.JumpIDList:Length() > 0 and MvcEntry:GetCtrl(ViewJumpCtrl):GetBtnName(self.Param.JumpIDList) or ""
		self.View.ControlTipsTxt:SetText(StringUtil.Format(TipStr))
	end

	self:SetBtnIcon()
	self:SetBtnEnabled(true)
	self:SetBtnDisabledByJumpIdList()
end

--根据跳转ID设置按钮文字
-- NeedSetDisableState 是否需要在不可跳转时置灰按钮设置文字‘不可获取’
function WCommonBtnTips:SetBtnJumpIdList(JumpIDList,NeedSetDisableState)
	self.Param.JumpIDList = JumpIDList
	if not JumpIDList or JumpIDList:Length() == 0  then
		-- CError("WCommonBtnTips:UpdateBtnStrByJumpListID JumpIDList nil")
		if NeedSetDisableState then
			-- 没有配置则按钮置灰显示‘无法获取’
			self:SetBtnEnabled(false, G_ConfigHelper:GetStrFromCommonStaticST("Lua_WCommonBtnTips_CannotGet_Btn"))
		end
		return
	end
	self:SetBtnEnabled(true)

	local TipStr = MvcEntry:GetCtrl(ViewJumpCtrl):GetBtnName(self.Param.JumpIDList) or ""
	self.View.ControlTipsTxt:SetText(StringUtil.Format(TipStr))
	self:SetBtnIcon()
	self:SetBtnDisabledByJumpIdList()
end

-- 设置按钮文本（会隐藏货币图标，一般用于货币按钮购买后的切换）
function WCommonBtnTips:SetTipsStr(TipsStr)
	self.ShowStyleType = WCommonBtnTips.ShowStyleType.None

	self.View.ControlTipsTxt:SetText(StringUtil.Format(TipsStr))
	self:SetTipsStrHide(false)
	self:SetCommonPriceHide(true)
end

--- 设置按钮文本是否被Hide
---@param bHide boolean true.代表需要隐藏
function WCommonBtnTips:SetTipsStrHide(bHide)
	bHide = bHide or false
	if CommonUtil.IsValid(self.View.GUIVerticalBox_ControlTips) then
		if bHide then
			self.View.GUIVerticalBox_ControlTips:SetVisibility(UE.ESlateVisibility.Collapsed)
		else
			self.View.GUIVerticalBox_ControlTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		end
	end
end

-- 设置按钮是否灰置 （按钮文本参数 TipsStr 可选）
---@param CheckJumpIDList 是否判断跳转ID，若为true且跳转类型为4,则不可取消置灰
function WCommonBtnTips:SetBtnEnabled(IsEnabled,TipsStr, CheckJumpIDList)
	if CheckJumpIDList and MvcEntry:GetCtrl(ViewJumpCtrl):GetJumpTypeByTArrayList(self.Param.JumpIDList) == ViewJumpCtrl.JumpTypeDefine.DisabledBtn and IsEnabled then
		return
	end
	self.IsBtnEnabled = IsEnabled
	self.View.GUIButton_Tips:SetIsEnabled(IsEnabled)

	if IsEnabled then
		if self.View.VXE_CommonBtn_Normal then
			self.View:VXE_CommonBtn_Normal()
		end
	else
		if self.View.VXE_CommonBtn_Disable then
			self.View:VXE_CommonBtn_Disable()
		end
	end

	if TipsStr and TipsStr ~= "" then
		self.View.ControlTipsTxt:SetText(StringUtil.Format(TipsStr))
	end
end

function WCommonBtnTips:SetFont(FontInfo)
	if FontInfo.Size then
		CommonUtil.SetTextFontSize(self.View.ControlTipsTxt,FontInfo.Size)
	end
	if FontInfo.Color then
		CommonUtil.SetTextColorFromeHex(self.View.ControlTipsTxt,FontInfo.Color)
	end
	if FontInfo.OutlineSize then
		CommonUtil.SetTextFontOutlineSize(self.View.ControlTipsTxt,FontInfo.OutlineSize)
	end
end

-- 通过JumpIDList设置按钮灰置以及无交互性,隐藏PC热键按钮图标
function WCommonBtnTips:SetBtnDisabledByJumpIdList()
	if MvcEntry:GetCtrl(ViewJumpCtrl):GetJumpTypeByTArrayList(self.Param.JumpIDList) == ViewJumpCtrl.JumpTypeDefine.DisabledBtn then
		self:SetBtnEnabled(false)
		if CommonUtil.IsValid(self.View.ControlTipsIcon) then
			self.View.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)	
		end
	end
end
 
--设置按钮无响应
---@type IsCantHit boolean 代表按钮无响应
function WCommonBtnTips:SetBtnIsCantHit(IsCantHit)
	local State = IsCantHit and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Visible
	self.View.GUIButton_Tips:SetVisibility(State)
end

return WCommonBtnTips
