--[[
    武器皮肤界面
]]

local class_name = "WeaponSkinMdt";
WeaponSkinMdt = WeaponSkinMdt or BaseClass(GameMediator, class_name);

require("Client.Modules.Arsenal.Weapon.WeaponSkinAttachSelectorLogic")

--标签类型
WeaponSkinMdt.MenTabKeyEnum = {
    --皮肤
    Skin = 1,
    --吊坠
    Pendant = 2,
}


function WeaponSkinMdt:__init()
end

function WeaponSkinMdt:OnShow(data)
end

function WeaponSkinMdt:OnHide()

end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.TabTypeId2Vo ={
        [WeaponSkinMdt.MenTabKeyEnum.Skin] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Arsenal/Weapon/WBP_WeaponSkinList.WBP_WeaponSkinList",
            LuaClass= require("Client.Modules.Arsenal.Weapon.WeaponSkinListLogic"),
        },
        [WeaponSkinMdt.MenTabKeyEnum.Pendant] = {
			UMGPATH="/Game/ddddluePrints/UMG/OutsideGame/Arsenal/Weapon/WBP_WeaponSkinPendant.WBP_WeaponSkinPendant",
            LuaClass= require("Client.Modules.Arsenal.Weapon.WeaponSkinPendantLogic"),
        },
    }
	self.MsgList = 
	{
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked},
		-- {Model = InputModel, MsgName = InputModel.ON_BEGIN_TOUCH,	Func = self.OnInputBeginTouch },
		-- {Model = InputModel, MsgName = InputModel.ON_END_TOUCH,	Func = self.OnInputEndTouch },
	}
    self.TheWeaponModel = MvcEntry:GetModel(WeaponModel)
    self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
end


--由mdt触发调用
function M:OnShow(data)
	self.CurSelectWeaponId = data.WeaponId or 0
	self.CurSelectWeaponSkinId = 0    
	self:InitCommonUI()
end

function M:OnShowAvator(Param,IsNotVirtualTrigger)
    if not IsNotVirtualTrigger then
        self:ShowWeaponSkinAvatar()
        
        local VoItem = self.TabTypeId2Vo[self.CurTabId]
        if VoItem ~= nil and VoItem.ViewItem ~= nil then
            VoItem.ViewItem:UpdateSelectSkinInfo()
            VoItem.ViewItem:RefreshWeaponSkinList()
        end
    end
end

function M:OnHideAvator(data)
	self:RemoveWeaponSkinAvatar()
end

function M:InitCommonUI()
    UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
    })

	local MenuTabParam = {
		ItemInfoList = {
            {Id=WeaponSkinMdt.MenTabKeyEnum.Skin,Widget=self.skinDetail,LabelStr=self.TheArsenalModel:GetArsenalText("10007_Btn")},
            {Id=WeaponSkinMdt.MenTabKeyEnum.Pendant,Widget=self.PendantDetail,LabelStr=self.TheArsenalModel:GetArsenalText("10007_Btn")},
        },
        CurSelectId = WeaponSkinMdt.MenTabKeyEnum.Skin,
        ClickCallBack = Bind(self,self.OnMenuBtnClick),
        ValidCheck = Bind(self,self.MenuValidCheck),
        HideInitTrigger = false,
		IsOpenKeyboardSwitch = true,
	}

    local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Weapon","11352"),
        CurrencyIDs = {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND},
        TabParam = MenuTabParam
    }
    self.CommonTabUpBarInstance = UIHandler.New(self,self.WBP_Common_TabUpBar_02,CommonTabUpBar,CommonTabUpBarParam).ViewInstance
    -- todo 当前不显示tab,待打开
    self.CommonTabUpBarInstance:SetTabVisibility(UE.ESlateVisibility.Collapsed) 
end

--按钮事件
function M:OnMenuBtnClick(Id, ItemInfo, IsInit)
    self.CurTabId = Id
	self:UpdateTabShow()
end

function M:MenuValidCheck(Id)
	-- if Id == WeaponSkinMdt.MenTabKeyEnum.Pendant then
	-- 	UIAlert.Show("功能未开放")
	-- 	return false
	-- end
    return true
end

--[[
    更新当前Tab页展示
]]
function M:UpdateTabShow()
    local VoItem = self.TabTypeId2Vo[self.CurTabId]
    if not VoItem then
        CError("WeaponSkinMdt:UpdateTabShow() VoItem nil")
        return
    end
    if not VoItem.ViewItem then
        local WidgetClassPath = VoItem.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget,self.Center)
        local ViewItem = UIHandler.New(self,Widget,VoItem.LuaClass).ViewInstance
        VoItem.ViewItem = ViewItem
        VoItem.View = Widget
    end

    for TheTabId,TheVo in pairs(self.TabTypeId2Vo) do
        local TheShow = false
        if TheTabId == self.CurTabId then
            TheShow = true
        end
        if TheVo.View then
            TheVo.View:SetVisibility(TheShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
    end
    local Param = {
        WeaponId = self.CurSelectWeaponId,
    }
    VoItem.ViewItem:OnShow(Param)

    if self.CurTabId == WeaponSkinMdt.MenTabKeyEnum.Skin then
        --TBT版本暂时屏蔽皮肤配件
        --配件选择
        -- if self.AttachmentSelectorInst == nil then
        --     self.AttachmentSelectorInst = UIHandler.New(self,self.WBP_AttachmentSelector, WeaponSkinAttachSelectorLogic, 
        --     {
        --         Handler = self
        --     }).ViewInstance
        -- end
        -- VoItem.ViewItem:SetAttachmentSelector(self.AttachmentSelectorInst)
    end
end

--[[
	展示选中皮肤模型
]]
function M:ShowWeaponSkinAvatar()
    self.TheWeaponModel:DispatchType(WeaponModel.ON_UPDATE_WEAPON_SKIN_SHOW, 
        {
            WeaponId = self.CurSelectWeaponId, 
            WeaponSkinId = self.CurSelectWeaponSkinId
        })
end

function M:RemoveWeaponSkinAvatar()
    self.TheWeaponModel:DispatchType(WeaponModel.ON_UPDATE_WEAPON_SKIN_HIDE)
end

function M:UpdateWeaponSkinAvatar(WeaponSkinId)
	if self.CurSelectWeaponSkinId ==  WeaponSkinId then
		return
	end
	self.CurSelectWeaponSkinId = WeaponSkinId
	self:ShowWeaponSkinAvatar()
end

--[[
]]
function M:OnEscClicked()
	MvcEntry:CloseView(ViewConst.WeaponSkin)
	return true
end

function M:OnInputBeginTouch()

    if self.bInputBeginTouch then
        return
    end
    self.bInputBeginTouch = true

    if self.VXE_Hall_Weapon_RotShow_In then
		self:VXE_Hall_Weapon_RotShow_In()
	end
end

function M:OnInputEndTouch()

    if not(self.bInputBeginTouch) then
        return
    end
    self.bInputBeginTouch = false
    
    if self.VXE_Hall_Weapon_RotShow_Out then
		self:VXE_Hall_Weapon_RotShow_Out()
	end
end


return M