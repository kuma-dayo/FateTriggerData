--[[
    系统菜单 - 聊天设置 - Item逻辑
]]
local class_name = "SystemMenuVoiceSettingItem"
local SystemMenuVoiceSettingItem = BaseClass(nil, class_name)

function SystemMenuVoiceSettingItem:OnInit(SettingInfo)
     ---@type SystemMenuModel
    self.SystemMenuModel = MvcEntry:GetModel(SystemMenuModel)
    self.BindNodes = {
		{ UDelegate = self.View.BtnOn.GUIButton_Click.OnClicked,				Func = Bind(self,self.OnClick_OnBtn) },
		{ UDelegate = self.View.BtnOff.GUIButton_Click.OnClicked,				Func = Bind(self,self.OnClick_OffBtn) },
		{ UDelegate = self.View.GUIButton_Bg.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
		{ UDelegate = self.View.BtnOn.GUIButton_Click.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
		{ UDelegate = self.View.BtnOff.GUIButton_Click.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
		{ UDelegate = self.View.GUIButton_Bg.OnUnhovered,				Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
		{ UDelegate = self.View.BtnOn.GUIButton_Click.OnUnhovered,				Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
		{ UDelegate = self.View.BtnOff.GUIButton_Click.OnUnhovered,				Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
	}

    self.MsgList = {
        {Model = BanModel, MsgName = BanModel.ON_BAN_STATE_CHANGED, Func = Bind(self,self.OnVoiceBanStateChanged)}
    }
    if SettingInfo and SettingInfo.ActionMappingKey then
		table.insert(self.MsgList,{Model = InputModel, MsgName = ActionPressed_Event(SettingInfo.ActionMappingKey), Func = Bind(self,self.OnClick_SwitchBtn) })
	end
end

function SystemMenuVoiceSettingItem:OnShow(SettingInfo)
    self.SettingType = SettingInfo.Type
    -- 设置名称
    self.View.NameBlock:SetText(StringUtil.Format(SettingInfo.Name or ""))
    -- 左按钮
    local LeftBtnSetting = SettingInfo.BtnConfigs.Left
    if LeftBtnSetting then
        self.View.BtnOn.GUITextBlock:SetText(StringUtil.Format(LeftBtnSetting.Title or ""))
        self.View.BtnOn.GUIButton_Click:SetIsEnabled(not LeftBtnSetting.IsDisabled)
    end
    -- 右按钮
    local RightBtnSetting = SettingInfo.BtnConfigs.Right
    if RightBtnSetting then
        self.View.BtnOff.GUITextBlock:SetText(StringUtil.Format(RightBtnSetting.Title or ""))
        self.View.BtnOff.GUIButton_Click:SetIsEnabled(not RightBtnSetting.IsDisabled)
    end
    self:UpdateSelect()
end

function SystemMenuVoiceSettingItem:OnHide()
   
end

function SystemMenuVoiceSettingItem:UpdateSelect()
    self.IsSettingSelect = self.SystemMenuModel:GetVoiceSetting(self.SettingType)
    self.View.BtnOn.GUIImageBG:SetVisibility(self.IsSettingSelect and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.BtnOff.GUIImageBG:SetVisibility(not self.IsSettingSelect and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    local ColorSelect,OpacitySelect = "#1B2024",1
    local ColorUnselect,OpacityUnselect = "#F5EFDF",0.7
    CommonUtil.SetTextColorFromeHex(self.View.BtnOn.GUITextBlock,self.IsSettingSelect and ColorSelect or ColorUnselect,self.IsSettingSelect and OpacitySelect or OpacityUnselect)
    CommonUtil.SetTextColorFromeHex(self.View.BtnOff.GUITextBlock,self.IsSettingSelect and ColorUnselect or ColorSelect,self.IsSettingSelect and OpacityUnselect or OpacitySelect)
end

function SystemMenuVoiceSettingItem:DoSelect(SettingState)
    if not self.SystemMenuModel:CanChangeVoiceSetting(self.SettingType, SettingState) then
        -- todo 是否需要提示
        return
    end

    self.SystemMenuModel:SetVoiceSetting(self.SettingType, SettingState)
    self:UpdateSelect()
end

function SystemMenuVoiceSettingItem:OnClick_OnBtn()
    if self.IsSettingSelect then
        return
    end

    if self.SettingType == SystemMenuConst.VoiceSettingType.VoiceIsOpen then
        if self.SystemMenuModel:HadShownVoiceApplyTips() then
            self:DoSelect(true)
        else
            self:RequestOpenVoicechat()
        end
    else
        self:DoSelect(true)
    end
end

---请求开启麦克分权限
function SystemMenuVoiceSettingItem:RequestOpenVoicechat()
    local formatStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Setting","Lua_SystemMenuMdt_Voicechat_OpenTip")--您是否同意Project N使用您的麦克风以开启语音聊天功能，若是拒绝将无法正常使用语音聊天功能
    local describe = StringUtil.Format(formatStr,G_ConfigHelper:GetStrFromOutgameStaticST("SD_Setting","Lua_Project_Name"))  
    local msgParam = {
        -- title = "ssss",
        describe = describe,
        leftBtnInfo = {
            name = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_Refuse_Btn") -- 拒绝
        },
        rightBtnInfo = {
            name = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_Agree_Btn"), -- 同意
            callback = function()
                self.SystemMenuModel:SaveHadShownVoiceApplyTips()
                self:DoSelect(true)
            end,
        },
        -- HideCloseTip = true,
        -- HideCloseBtn = true,
    }
    UIMessageBox.Show(msgParam)
end

function SystemMenuVoiceSettingItem:OnClick_OffBtn()
    if not self.IsSettingSelect then
        return
    end
    self:DoSelect(false)
end

function SystemMenuVoiceSettingItem:OnClick_SwitchBtn()
    if self.SettingType == SystemMenuConst.VoiceSettingType.VoiceIsOpen then
        if self.IsSettingSelect then
            self:DoSelect(not self.IsSettingSelect)
        else
            if self.SystemMenuModel:GetVoiceSettingBySettingType(self.SettingType) then
                self:DoSelect(not self.IsSettingSelect)
            else
                self:RequestOpenVoicechat()
            end
        end
    else
        self:DoSelect(not self.IsSettingSelect)
    end
end

function SystemMenuVoiceSettingItem:GUIButton_Bg_OnHovered()
    self.View.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function SystemMenuVoiceSettingItem:GUIButton_Bg_OnUnhovered()
    self.View.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function SystemMenuVoiceSettingItem:OnVoiceBanStateChanged(_,Msg)
    if not (Msg and Msg.BanType) or Msg.BanType ~= Pb_Enum_BAN_TYPE.BAN_VOICE then
        return
    end
    if self.SettingType == SystemMenuConst.VoiceSettingType.VoiceIsOpen then
        self:UpdateSelect()
    end    
end

return SystemMenuVoiceSettingItem
