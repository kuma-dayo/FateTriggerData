--[[
    武器皮肤逻辑
]]

local class_name = "WeaponSkinListLogic"
local WeaponSkinListLogic = BaseClass(nil, class_name)

function WeaponSkinListLogic:OnInit()
	-- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
	self.MsgList = 
	{
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Left), Func = Bind(self,self.OnSwitchWeaponSkin, -1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Right), Func = Bind(self,self.OnSwitchWeaponSkin, 1)},
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A), Func = Bind(self,self.OnSwitchWeaponSkin, -1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self,self.OnSwitchWeaponSkin, 1)},
		{Model = WeaponModel, MsgName = WeaponModel.ON_SELECT_WEAPON_SKIN,	Func = Bind(self, self.OnUpdateSelectWeaponSkin) },
		{Model = WeaponModel, MsgName = WeaponModel.ON_UNLOCK_WEAPON_SKIN,	Func = Bind(self, self.OnUnLockWeaponSkin) },
	}

	self.WeaponSkinItemWidgetList = {}
    self.View.ReuseList_WeaponSkin.OnUpdateItem:Add(self.View, Bind(self,self.OnUpdateWeaponSkinItem))
	self.TheWeaponModel = MvcEntry:GetModel(WeaponModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
end


function WeaponSkinListLogic:OnShow(Param)
	if not Param then
        return
    end
	self.CurSelectWeaponId = Param.WeaponId
	self.CurSelectWeaponSkinId = self.TheWeaponModel:GetWeaponSkinId(Param.WeaponId)

	self.WeaponSkinList = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponSkinConfig, Cfg_WeaponSkinConfig_P.WeaponId, Param.WeaponId)
	table.sort(self.WeaponSkinList, function(A ,B)
		-- 1、被装备的武器皮肤，下次进入皮肤页面时，图标会无视排序规则被提前至首位
		-- 2、已获取排在未获取前
		-- 3、由高到低排列品级
		-- 4、同品级下则按照武器皮肤配置表中ID从小到大排列
		local SelectedA = self.CurSelectWeaponSkinId == A[Cfg_WeaponSkinConfig_P.SkinId]
		local SelectedB = self.CurSelectWeaponSkinId == B[Cfg_WeaponSkinConfig_P.SkinId]
		if SelectedA and not SelectedB then 
			return true
		elseif not SelectedA and SelectedB then
			return false
		else
			local HasA = self.TheWeaponModel:HasWeaponSkin(A[Cfg_WeaponSkinConfig_P.SkinId]) 
			local HasB = self.TheWeaponModel:HasWeaponSkin(B[Cfg_WeaponSkinConfig_P.SkinId]) 
			if HasA and not HasB then 
				return true
			elseif not HasA and HasB then
				return false
			else 
				local QualityA = self.TheWeaponModel:GetWeaponSkinQuality(A[Cfg_WeaponSkinConfig_P.SkinId])
				local QualityB = self.TheWeaponModel:GetWeaponSkinQuality(B[Cfg_WeaponSkinConfig_P.SkinId])
				if QualityA ~= QualityB then 
					return QualityA > QualityB
				end
			end
		end
		return A[Cfg_WeaponSkinConfig_P.SkinId] < B[Cfg_WeaponSkinConfig_P.SkinId]
	end)

	self:InitCommonUI()
	self:ReloadWeaponSkinList()
	self:UpdateSelectSkinAvatar(self.CurSelectWeaponSkinId)
end

function WeaponSkinListLogic:OnHide()
end

function WeaponSkinListLogic:SetAttachmentSelector(AttachmentSelector)
	self.AttachmentSelectorInst = AttachmentSelector
end

function WeaponSkinListLogic:InitCommonUI()
	--通用操作按钮：解锁
	self.UnlockBtnInst = UIHandler.New(self, self.View.Skin_UnlockBtn, WCommonBtnTips,
	{
		OnItemClick = Bind(self, self.OnUnlockBtn),
		CommonTipsID = CommonConst.CT_SPACE,
		TipStr = self.TheArsenalModel:GetArsenalText(10004),
		ActionMappingKey = ActionMappings.SpaceBar,
		CheckButtonIsVisible = true,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        JumpIDList = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(self.CurSelectWeaponSkinId)
	}).ViewInstance

	--通用操作按钮：装备
	UIHandler.New(self, self.View.Skin_SelectBtn, WCommonBtnTips,
	{
		OnItemClick = Bind(self, self.OnSelectBtn),
		CommonTipsID = CommonConst.CT_SPACE,
		TipStr = self.TheArsenalModel:GetArsenalText(10005),
		ActionMappingKey = ActionMappings.SpaceBar,
		CheckButtonIsVisible = true,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
	})

	--通用操作按钮：已装备
	UIHandler.New(self, self.View.Skin_SelectedBtn, WCommonBtnTips,
	{
		OnItemClick = Bind(self, self.OnSelectedBtn),
		TipStr = self.TheArsenalModel:GetArsenalText("10006_Btn"),
		CheckButtonIsVisible = true,
	}).ViewInstance:SetBtnEnabled(false)
end

function WeaponSkinListLogic:ReloadWeaponSkinList()
	self.View.ReuseList_WeaponSkin:Reload(#self.WeaponSkinList)
end


function WeaponSkinListLogic:RefreshWeaponSkinList()
	self.View.ReuseList_WeaponSkin:Refresh()
end

function WeaponSkinListLogic:CreateWeaponSkinItem(Widget)
	local Item = self.WeaponSkinItemWidgetList[Widget]
	if not Item then
		local Param = {
			OnItemClick = Bind(self,self.OnWeaponSkinItemClick)
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Arsenal.Weapon.WeaponSkinListItem"), Param)
		self.WeaponSkinItemWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end

--[[
	武器皮肤Item被点击
]]
function WeaponSkinListLogic:OnWeaponSkinItemClick(Item, WeaponSkinInfo, DataIndex)
	if Item == nil or WeaponSkinInfo == nil then 
		return
	end
	local SkinId = WeaponSkinInfo[Cfg_WeaponSkinConfig_P.SkinId] 
	self.CurSelectWeaponSkinId = SkinId
	self:UpdateSelectSkinAvatar(SkinId)
	self:OnSelectWeaponSkinItem(Item)
end

function WeaponSkinListLogic:OnSelectWeaponSkinItem(Item)
	if self.CurSelectWeaponItem then
		self.CurSelectWeaponItem:UnSelect()
	end
	self.CurSelectWeaponItem = Item
	if self.CurSelectWeaponItem then
		self.CurSelectWeaponItem:Select()
	end
	self:UpdateSelectSkinInfo()
end

function WeaponSkinListLogic:OnUpdateWeaponSkinItem(Handler, Widget, Index)
	local i = Index + 1
	local WeaponSkin = self.WeaponSkinList[i]
	if WeaponSkin == nil then
		return
	end

	local ListItem = self:CreateWeaponSkinItem(Widget)
	if ListItem == nil then
		return
	end

    if WeaponSkin[Cfg_WeaponSkinConfig_P.SkinId] == self.CurSelectWeaponSkinId then
		self:OnSelectWeaponSkinItem(ListItem)
	else 
		ListItem:UnSelect()
	end
	ListItem:SetItemData(WeaponSkin, self.CurSelectWeaponId, i)
end

function WeaponSkinListLogic:UpdateSelectSkinInfo()
	--[[
		武器皮肤信息: 皮肤名称、描述、解锁花费
	]]--
	local Wsc = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig, 
		Cfg_WeaponSkinConfig_P.SkinId, self.CurSelectWeaponSkinId)
    if Wsc ~= nil then 
		self.View.GUITBWeaponSkinName:SetText(StringUtil.Format(Wsc[Cfg_WeaponSkinConfig_P.SkinName]))
		self.View.GUITBWeaponSkinDesc:SetText(StringUtil.Format(Wsc[Cfg_WeaponSkinConfig_P.SkinDesc]))

        local JumpID = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(Wsc[Cfg_WeaponSkinConfig_P.ItemId])
		if self.UnlockBtnInst then
			local UnlockItemId = Wsc[Cfg_WeaponSkinConfig_P.UnlockItemId]
			local UnlockItemNum = Wsc[Cfg_WeaponSkinConfig_P.UnlockItemNum]
			self.UnlockBtnInst:ShowCurrency(UnlockItemId, UnlockItemNum, JumpID)
		end
	end

	--[[
		当前武器的按钮状态：未解锁、已解锁、已装备
	]]--
	if not self.TheWeaponModel:HasWeaponSkin(self.CurSelectWeaponSkinId) then 
		self.View.WidgetSwitcherSkinStatus:SetActiveWidgetIndex(0)
	else
		if self.TheWeaponModel:GetWeaponSkinId(self.CurSelectWeaponId) ~= self.CurSelectWeaponSkinId then
			self.View.WidgetSwitcherSkinStatus:SetActiveWidgetIndex(1)
		else 
			self.View.WidgetSwitcherSkinStatus:SetActiveWidgetIndex(2)
		end
	end

	--[[
		解锁信息：
	]]--
	self.View.GUITBWeaponName:SetText(self.TheArsenalModel:GetArsenalText("10007_Btn"))

	--[[
		武器信息：武器总皮肤数量、武器已解锁皮肤数量
	]]--	
	local SkinCfgList = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponSkinConfig, 
		Cfg_WeaponSkinConfig_P.WeaponId, self.CurSelectWeaponId)
		if SkinCfgList ~= nil then
		--武器总皮肤数
		local TotalSkinNum = #SkinCfgList
		self.View.GUITBTotalNum:SetText(TotalSkinNum)
		--解锁皮肤数
		local UnlockedNum = 0
		for i=1, #SkinCfgList do
			local SkinCfg = SkinCfgList[i]
			if SkinCfg ~= nil then
				if self.TheWeaponModel:HasWeaponSkin(SkinCfg[Cfg_WeaponSkinConfig_P.SkinId]) then
					UnlockedNum = UnlockedNum + 1
				end
			end
			self.View.GUITBUnLockedNum:SetText(UnlockedNum)
		end
	end

	--配件槽位
	if self.AttachmentSelectorInst then
		self.AttachmentSelectorInst:UpdateShowData(self.CurSelectWeaponId, self.CurSelectWeaponSkinId)
		self.AttachmentSelectorInst:ShowAttachmentSlotList(true)
	end
end

function WeaponSkinListLogic:UpdateSelectSkinAvatar(WeaponSkinId)
	if self.WidgetBase == nil then
		return
	end
	self.WidgetBase:UpdateWeaponSkinAvatar(WeaponSkinId)
end

--[[
    左右箭头按键切换皮肤
]]
function WeaponSkinListLogic:OnSwitchWeaponSkin(Direction)
	local SkidIdList = {}
	for _, V in ipairs(self.WeaponSkinList) do
		table.insert(SkidIdList, V.SkinId)
	end
	local WeaponSkinIndex, SelectWeaponSkinId = 0, 0
	if Direction > 0 then 
		WeaponSkinIndex, SelectWeaponSkinId = CommonUtil.GetListNextIndex4Id(SkidIdList, self.CurSelectWeaponSkinId)
	else 
		WeaponSkinIndex, SelectWeaponSkinId = CommonUtil.GetListPreIndex4Id(SkidIdList, self.CurSelectWeaponSkinId)
	end
	--CLog(StringUtil.Format("SwitchWeaponSkin: CurSelection={0}-{1}",WeaponSkinIndex, SelectWeaponSkinId))
	self.CurSelectWeaponSkinId = SelectWeaponSkinId
	self:UpdateSelectSkinAvatar(SelectWeaponSkinId)
	self:RefreshWeaponSkinList()
	self.View.ReuseList_WeaponSkin:JumpByIdxStyle(WeaponSkinIndex-1,UE.EReuseListJumpStyle.Content)
	return true
end


--解锁
function WeaponSkinListLogic:OnUnlockBtn()
	local Wsc = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig, 
		Cfg_WeaponSkinConfig_P.SkinId, self.CurSelectWeaponSkinId)
    if Wsc == nil then 
		return
	end
	local CurrencyId = Wsc[Cfg_WeaponSkinConfig_P.UnlockItemId]
	local Cost = Wsc[Cfg_WeaponSkinConfig_P.UnlockItemNum] or 0
	local Balance = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(CurrencyId)
	local ItemName = MvcEntry:GetModel(DepotModel):GetItemName(CurrencyId)
	if Balance < Cost then
		local msgParam = {
			describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10008), ItemName) --{0}不够，无法解锁！
		}
		UIMessageBox.Show(msgParam)
		return
	end
	local msgParam = {
		-- describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10009), StringUtil.GetRichTextImgForId(CurrencyId), Cost), --确定要花{0}{1}，进行解锁吗？
		describe = CommonUtil.GetBuyCostDescribeText(CurrencyId, Cost, CommonConst.BuyType.UNLOCK),--确定要花 {0}{1} 解锁吗？
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
				MvcEntry:GetCtrl(ArsenalCtrl):SendProto_BuyWeaponSkinReq(self.CurSelectWeaponId, 
						self.CurSelectWeaponSkinId)
			end
		}
	}
	UIMessageBox.Show(msgParam)
end

--装备
function WeaponSkinListLogic:OnSelectBtn()
	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_SelectWeaponSkinReq(self.CurSelectWeaponId, 
		self.CurSelectWeaponSkinId)
end

--已装备
function WeaponSkinListLogic:OnSelectedBtn()
	CLog("Selected: SkinId = "..self.CurSelectWeaponSkinId)
end

--装备皮肤回调
function WeaponSkinListLogic:OnUpdateSelectWeaponSkin()
	self:UpdateSelectSkinInfo()
	self:RefreshWeaponSkinList()
end

--购买解锁皮肤回调
function WeaponSkinListLogic:OnUnLockWeaponSkin()
	self:UpdateSelectSkinInfo()
	self:RefreshWeaponSkinList()
end


return WeaponSkinListLogic