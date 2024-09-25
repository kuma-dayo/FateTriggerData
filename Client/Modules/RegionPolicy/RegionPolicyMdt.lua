
--- 区域政策
local class_name = "RegionPolicyMdt";
RegionPolicyMdt = RegionPolicyMdt or BaseClass(GameMediator, class_name);


function RegionPolicyMdt:__init()
end

function RegionPolicyMdt:OnShow(data)
    
end

function RegionPolicyMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    
    ---@type SystemMenuModel
    self.SystemMenuModel = MvcEntry:GetModel(SystemMenuModel)

    -- self.MsgList = 
    -- {
    -- }

    self.BindNodes = {
        -- { UDelegate = self.BP_RichText1.OnHyperlinkHovered,	Func = self.OnHoverKeyText },
        -- { UDelegate = self.BP_RichText2.OnHyperlinkUnhovered, Func = self.OnUnhoverKeyText },

        { UDelegate = self.BP_RichText1.OnHyperlinkClicked,	Func = self.OnClickedOpenServiceBtn },--打开服务条款
        { UDelegate = self.BP_RichText2.OnHyperlinkClicked, Func = self.OnClickedOpenPrivacyBtn },--打开隐私条款
	}
end

function M:OnShow(Params)
    self.SelectedIndex = -1
    self.SelectedRegionPolicyCfg = nil
    ---是否选择了服务条款
    self.bSelectedService = false
    ---是否选择了隐私政策
    self.bSelectedPrivacy = false

    self:ShowWBPCommonPopUpBgL()
    self:ShowRegionComboBox()
    self:InitAndShowBtns()
    self:RefreshBtnsState()
end

function M:OnRepeatShow(Params)
	-- MvcEntry:CloseView(ViewConst.NameInputPanel)
    self:OnShow(Params)
end

function M:OnHide()
    
end

function M:ShowWBPCommonPopUpBgL()
    local PopUpBgParam = {
		TitleText = G_ConfigHelper:GetStrFromCommonStaticST("Lua_Statement_SelectArea"), --请选择国家或地区
		HideCloseTip = true,
        HideCloseBtn = true,
        -- CloseCb =  Bind(self,self.OnClicked_CancelBtn),
        -- CloseCb =  Bind(self,self.OnClicked_ConfirmBtn),
	}
    if self.CommonPopUpBgHandle == nil or not(self.CommonPopUpBgHandle:IsValid()) then
        self.CommonPopUpBgHandle = UIHandler.New(self, self.WBP_CommonPopUp_Bg_L, CommonPopUpBgLogic, PopUpBgParam)
    else
        self.CommonPopUpBgHandle:ManualOpen(PopUpBgParam)
    end
end

---地区选择
function M:ShowRegionComboBox()
    self.RegionPolicyList = {}

    local RegionPolicyNameList = {}
    local Cfgs = G_ConfigHelper:GetDict(Cfg_RegionPolicyConfig)
    for key, Cfg in ipairs(Cfgs) do
        table.insert(RegionPolicyNameList, {ItemDataString = StringUtil.Format(Cfg[Cfg_RegionPolicyConfig_P.Region])})
        table.insert(self.RegionPolicyList, Cfg)
    end

    self.SelectedIndex = -1
    local ComboBoxParam = {
        OptionList = RegionPolicyNameList, 
        DefaultSelect = self.SelectedIndex,
        DefaultTip = G_ConfigHelper:GetStrFromCommonStaticST("Lua_Statement_SelectAreaYou"),-- 请选择你的国家或地区
        SelectCallBack = Bind(self, self.OnSelectionChangedRegion)
    }
    if self.CommonComboBoxIns == nil or not(self.CommonComboBoxIns:IsValid()) then
        self.CommonComboBoxIns = UIHandler.New(self, self.WBP_ComboBox, CommonComboBox, ComboBoxParam).ViewInstance
    else
        self.CommonComboBoxIns:ManualOpen(ComboBoxParam)
    end
end

function M:OnSelectionChangedRegion(Index)
    if self.SelectedIndex == Index then
        return
    end
    self.SelectedIndex = Index

    ---是否选择了服务条款
    self.bSelectedService = false
    ---是否选择了隐私政策
    self.bSelectedPrivacy = false

    self.SelectedRegionPolicyCfg = self.RegionPolicyList[Index]
    -- self:RefreshRegionPolicy(self.SelectedRegionPolicyCfg)
    self:RefreshBtnsState()
end

-- ---隐私,政策展示
-- function M:RefreshRegionPolicy(Cfg)
    
-- end

function M:InitAndShowBtns()
    
    --同时选择服务条款与隐私条款
    if CommonUtil.IsValid(self.WBP_SelectButton1) then
        if self.WBP_SelectButton1Ins == nil or not(self.WBP_SelectButton1Ins:IsValid()) then
            local CheckBoxParam = {
                OnCheckStateChanged = Bind(self, self.OnCheckStateChanged_All),
                bIsChecked = self.bSelectedService and self.bSelectedPrivacy
            }
            self.WBP_SelectButton1Ins = UIHandler.New(self, self.WBP_SelectButton1, CommonCheckBox, CheckBoxParam).ViewInstance
        end
    end

    --服务条款
    if CommonUtil.IsValid(self.WBP_SelectButton2) then
        if self.WBP_SelectButton2Ins == nil or not(self.WBP_SelectButton2Ins:IsValid()) then
            local CheckBoxParam = {
                OnCheckStateChanged = Bind(self, self.OnCheckStateChanged_Service),
                bIsChecked = self.bSelectedService 
            }
            self.WBP_SelectButton2Ins = UIHandler.New(self, self.WBP_SelectButton2, CommonCheckBox, CheckBoxParam).ViewInstance
        end
    end

    --隐私条款
    if CommonUtil.IsValid(self.WBP_SelectButton3) then
        if self.WBP_SelectButton3Ins == nil or not(self.WBP_SelectButton3Ins:IsValid()) then
            local CheckBoxParam = {
                OnCheckStateChanged = Bind(self, self.OnCheckStateChanged_Privacy),
                bIsChecked =  self.bSelectedPrivacy
            }
            self.WBP_SelectButton3Ins = UIHandler.New(self, self.WBP_SelectButton3, CommonCheckBox, CheckBoxParam).ViewInstance
        end
    end

    --确认按钮
    if CommonUtil.IsValid(self.WBP_CommonBtn_Strong) then
        if self.ConfirmBtnIns == nil or not(self.ConfirmBtnIns:IsValid()) then
            local BtnParam = {
                OnItemClick = Bind(self, self.OnClicked_ConfirmBtn),
                CommonTipsID = CommonConst.CT_SPACE,
                ActionMappingKey = ActionMappings.SpaceBar,
                TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_confirm_Btn"), --确认
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            }
           --确认按钮
           self.ConfirmBtnIns = UIHandler.New(self, self.WBP_CommonBtn_Strong, WCommonBtnTips, BtnParam).ViewInstance
        end
    end
end

function M:RefreshBtnsState()

    --检测是否禁用CheckBox
    local bIsDisableCheckBox = not(self.SelectedIndex > 0 and true or false)
    if bIsDisableCheckBox and not(self.DisableTip) then
        self.DisableTip = G_ConfigHelper:GetStrFromCommonStaticST("Lua_Statement_SelectAreaYou") -- 请选择你的国家或地区
    end

    --隐私条款勾选按钮+服务条款勾选按钮
    if self.WBP_SelectButton1Ins and self.WBP_SelectButton1Ins:IsValid() then
        local bIsChecked = self.bSelectedService and self.bSelectedPrivacy
        self.WBP_SelectButton1Ins:SetIsChecked(bIsChecked)

        self.WBP_SelectButton1Ins:SetCheckBoxDisable(bIsDisableCheckBox,self.DisableTip)
    end

    --服务条款勾选按钮
    if self.WBP_SelectButton2Ins and self.WBP_SelectButton2Ins:IsValid() then
        self.WBP_SelectButton2Ins:SetIsChecked(self.bSelectedService)    

        self.WBP_SelectButton2Ins:SetCheckBoxDisable(bIsDisableCheckBox,self.DisableTip)
    end

    --隐私条款勾选按钮
    if self.WBP_SelectButton3Ins and self.WBP_SelectButton3Ins:IsValid() then
        self.WBP_SelectButton3Ins:SetIsChecked(self.bSelectedPrivacy)    

        self.WBP_SelectButton3Ins:SetCheckBoxDisable(bIsDisableCheckBox,self.DisableTip)
    end

    --处理确定按钮
    if self.ConfirmBtnIns  and self.ConfirmBtnIns:IsValid() then
        local bEnabled = self.bSelectedService and self.bSelectedPrivacy
        self.ConfirmBtnIns:SetBtnEnabled(bEnabled)
    end
end

---打开窗口URL
function M:ShowWdnAndOpenURL(Title, URL)
    local msgParam = {
        Url = URL,
        TitleTxt = Title,
    }
    UIWebBrowser.Show(msgParam)
end

---------------------------------Btn Event >>

---点击确定按钮
function M:OnClicked_ConfirmBtn()
    ---关闭此界面
    MvcEntry:CloseView(ViewConst.RegionPolicyPopup)

    local RegionID = self.SelectedRegionPolicyCfg[Cfg_RegionPolicyConfig_P.RegionID]
    self.SystemMenuModel:SetRegionPolicy(RegionID)

    SaveGame.SetItem(SystemMenuConst.RegionPolicyIdKey, RegionID, nil,true)
end

function M:OnCheckStateChanged_All(bIsChecked)
    self.bSelectedService = bIsChecked
    self.bSelectedPrivacy = bIsChecked

    self:RefreshBtnsState()
end

---点击选择服务条款
function M:OnCheckStateChanged_Service(bIsChecked)
    ---是否选择了服务条款
    self.bSelectedService = bIsChecked

    self:RefreshBtnsState()
end

---点击选择隐私政策
function M:OnCheckStateChanged_Privacy(bIsChecked)
    ---是否选择了隐私政策
    self.bSelectedPrivacy = bIsChecked

    self:RefreshBtnsState()
end

---点击打开服务条款
function M:OnClickedOpenServiceBtn()
    if self.SelectedRegionPolicyCfg then
        local Title = G_ConfigHelper:GetStrFromCommonStaticST("Lua_Statement_Service")--服务条款
        local URL = self.SelectedRegionPolicyCfg[Cfg_RegionPolicyConfig_P.UserAgreementURL]
        self:ShowWdnAndOpenURL(Title, URL)
    else
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_Statement_SelectAreaYou")) -- 请选择你的国家或地区
    end
end

---点击打开隐私政策
function M:OnClickedOpenPrivacyBtn()
    if self.SelectedRegionPolicyCfg then
        local Title = G_ConfigHelper:GetStrFromCommonStaticST("Lua_Statement_Privacy")--隐私条款
        local URL = self.SelectedRegionPolicyCfg[Cfg_RegionPolicyConfig_P.PrivacyPolicyURL]
        self:ShowWdnAndOpenURL(Title, URL)
    else
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_Statement_SelectAreaYou"))-- 请选择你的国家或地区
    end
end



---------------------------------Btn Event <<



return M
