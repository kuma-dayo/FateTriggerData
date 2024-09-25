--[[
    系统菜单 - 队伍管理 - 队伍语音item
]]
local class_name = "SystemMenuTeamVoiceItem"
local SystemMenuTeamVoiceItem = BaseClass(nil, class_name)

function SystemMenuTeamVoiceItem:OnInit(SettingInfo)
     ---@type SystemMenuModel
    self.SystemMenuModel = MvcEntry:GetModel(SystemMenuModel)
     ---@type GVoiceModel
    self.GVoiceModel = MvcEntry:GetModel(GVoiceModel)
    self.BindNodes = {
        { UDelegate = self.View.Slider.OnValueChanged, Func = Bind(self,self.OnSliderValueChanged) },
        { UDelegate = self.View.Button_Voice.OnClicked, Func = Bind(self,self.OnVoiceSwitchButtonClicked) },
        { UDelegate = self.View.Button_Add.OnClicked,Func = Bind(self,self.OnVoiceAddClicked) },
        { UDelegate = self.View.Button_Sub.OnClicked,Func = Bind(self,self.OnVoiceSubClicked) },
        { UDelegate = self.View.OnCustomMouseEnterEvent,Func = Bind(self,self.OnMouseEnter) },
        { UDelegate = self.View.OnCustomMouseLeaveEvent,Func = Bind(self,self.OnMouseLeave) },
    }


    self.MsgList = {
        {Model = SystemMenuModel, MsgName = SystemMenuModel.ON_VOICE_OPEN_STATE_CHANGED, Func = Bind(self,self.UpdateVoiceSwitchButton)},
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_ROOM_USER_SUBSCRIBE_STATE_CHANGE, Func = Bind(self,self.OnVoiceSubscribeStateChange)},
        {Model = BanModel, MsgName = BanModel.ON_BAN_STATE_CHANGED, Func = Bind(self,self.OnBanStateChange)},
    }

    self.MAX_VOICE = 100
    self.MIN_VOICE = 0
end

function SystemMenuTeamVoiceItem:OnMouseEnter()
    self:GUIButton_Bg_OnHovered()
end

function SystemMenuTeamVoiceItem:OnMouseLeave()
    self:GUIButton_Bg_OnUnhovered()
end

function SystemMenuTeamVoiceItem:OnShow()
end

function SystemMenuTeamVoiceItem:OnHide()
end

function SystemMenuTeamVoiceItem:UpdateUI(TeamMember)
    self.PlayerId = TeamMember.PlayerId
    self.PlayerIdStr = tostring(self.PlayerId)
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    self.IsSelf = self.PlayerId == MyPlayerId
    self.RoomName = MvcEntry:GetModel(TeamModel):GetTeamVoiceRoomName()
    -- 头像
     local Param = {
        PlayerId = TeamMember.PlayerId,
        CloseAutoCheckFriendShow = true,
        CloseOnlineCheck = true
    }
    if not  self.SingleHeadIconCls then
        self.SingleHeadIconCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else 
        self.SingleHeadIconCls:UpdateUI(Param)
    end
    -- 名字
    self.View.PlayerNameTextBlock:SetText(TeamMember.PlayerName)
    
    -- 音量
    self.SavedVolume = self.SystemMenuModel:GetSavedVolume(self.PlayerId)
    self:UpdateVoiceSwitchButton(true)
end

function SystemMenuTeamVoiceItem:UpdateVoiceSwitchButton(IsInit)
    local IsVoiceOpen = self.SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceIsOpen)
    self:OnSliderValueChanged(nil,self.SavedVolume/100,IsInit)
    self.IsSubscribing = self.GVoiceModel:GetUserSubscribeState(self.RoomName,self.PlayerIdStr) 
    local IsEnable = IsVoiceOpen and self.IsSubscribing
    self.View.Slider:SetIsEnabled(IsEnable)
    self.View.ProgressBar:SetIsEnabled(IsEnable)
    self:UpdateVoiceButton(IsEnable)
end

--更新小喇叭图标
function SystemMenuTeamVoiceItem:UpdateVoiceButton(bIsActive)
    local ChildrenCount = self.View.Button_Voice:GetChildrenCount()
    for index = 0, ChildrenCount-1 do
        local OverlayWidget = self.View.Button_Voice:GetChildAt(index)
        local SizeBoxWidget = OverlayWidget:GetChildAt(1)
        local SwitcherWidget = SizeBoxWidget:GetChildAt(0)
        SwitcherWidget:SetActiveWidgetIndex(bIsActive and 0 or 1)
    end
end

function SystemMenuTeamVoiceItem:UpdateVolume()
    self.View.Slider:SetValue(self.SavedVolume / 100)
    self.View.ProgressBar:SetPercent(self.SavedVolume / 100)
    self.View.TxtVoice:SetText(self.SavedVolume)
end

function SystemMenuTeamVoiceItem:OnSliderValueChanged(_,Value_f,IsInit)
    -- 部分情况存在精度问题。例如 math.floor(0.29*100) = 28 以及 29可能给过来是28.9999999
    local Value = math.floor((Value_f + 0.0001) *1000/10)
    if IsInit then
        self:UpdateVolume()
        return
    end
    if self.SavedVolume ~= Value then
        local GVoiceCtrl = MvcEntry:GetCtrl(GVoiceCtrl)
        local MemberId = self.GVoiceModel:GetUserMemberId(self.RoomName,self.PlayerIdStr)
        if not MemberId then
            CError("GetUserMemberId Error For Id = "..self.PlayerIdStr)
            return
        end
        self.SavedVolume = Value
        self.SystemMenuModel:SaveVolume(self.PlayerId,self.SavedVolume)
        if Value > 0 then
            if not self.IsSubscribing then
                GVoiceCtrl:ForbidMemberVoice(self.RoomName,MemberId,false)
            end
            GVoiceCtrl:SetPlayerVolume(self.PlayerId,Value)
        else
            GVoiceCtrl:ForbidMemberVoice(self.RoomName,MemberId,true)
        end
        self:UpdateVolume()
    end
end

function SystemMenuTeamVoiceItem:OnVoiceSubscribeStateChange(_,Param)
    if not Param or Param.RoomName ~= self.RoomName or tonumber(Param.UserId) ~= self.PlayerId then
		return
	end
    self:UpdateVoiceSwitchButton()
end

--点击 小喇叭按钮
function SystemMenuTeamVoiceItem:OnVoiceSwitchButtonClicked()
    local IsVoiceOpen = self.SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceIsOpen)
    if not IsVoiceOpen then
        return
    end
    local MemberId = self.GVoiceModel:GetUserMemberId(self.RoomName,self.PlayerIdStr)
    if not MemberId then
        CError("GetUserMemberId Error For Id = "..self.PlayerIdStr)
        return
    end
    self.IsSubscribing = not self.IsSubscribing
    MvcEntry:GetCtrl(GVoiceCtrl):ForbidMemberVoice(self.RoomName,MemberId,not self.IsSubscribing)
end

--点击 音量加
function SystemMenuTeamVoiceItem:OnVoiceAddClicked()
    local IsVoiceOpen = self.SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceIsOpen)
    if not IsVoiceOpen then
        return
    end
    local TmpVolume = math.clamp(self.SavedVolume + 1,self.MIN_VOICE,self.MAX_VOICE)
    self:OnSliderValueChanged(nil,TmpVolume/100)
end

--点击 音量减
function SystemMenuTeamVoiceItem:OnVoiceSubClicked()
    local IsVoiceOpen = self.SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceIsOpen)
    if not IsVoiceOpen then
        return
    end
    local TmpVolume = math.clamp(self.SavedVolume - 1,self.MIN_VOICE,self.MAX_VOICE)
    self:OnSliderValueChanged(nil,TmpVolume/100)
end

function SystemMenuTeamVoiceItem:GUIButton_Bg_OnHovered()
    self.View.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.ProgressBar:SetRenderScale(self.View.ProgressBarHoverScale)
    --滑动条选中态
    self.View.Slider:SetRenderScale(self.View.SliderHoverScale)
    self.View.Slider:SetVisibility(UE.ESlateVisibility.Visible)
    --文字选中态
    self.View.PlayerNameTextBlock:SetColorAndOpacity(self.View.TextHoveredColor)
    self.View.TxtVoice:SetColorAndOpacity(self.View.TextHoveredColor)
    local TmpFont = self.View.TxtVoice.Font
    TmpFont.Size = self.View.TextSizeHovered
    self.View.TxtVoice:SetFont(TmpFont)

    self.View.GUIImage_Normol:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.GUIImage_HoverFrame:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
end

function SystemMenuTeamVoiceItem:GUIButton_Bg_OnUnhovered()
    self.View.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.ProgressBar:SetRenderScale(self.View.ProgressBarUnhoverScale)
    --滑动条未选中态
    self.View.Slider:SetRenderScale(self.View.SliderUnhoverScale)
    self.View.Slider:SetVisibility(UE.ESlateVisibility.Collapsed)
    --文字未选中态
    self.View.PlayerNameTextBlock:SetColorAndOpacity(self.View.TextUnhoveredColor)
    self.View.TxtVoice:SetColorAndOpacity(self.View.TextUnhoveredColor)
    local TmpFont = self.View.TxtVoice.Font
    TmpFont.Size = self.View.TextSizeUnhovered
    self.View.TxtVoice:SetFont(TmpFont)

    self.View.GUIImage_Normol:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.View.GUIImage_HoverFrame:SetVisibility(UE.ESlateVisibility.Collapsed)

    self.View.ImgVoiceOn:SetColorAndOpacity(self.ImgUnhoveredColor)
    self.View.ImgVoiceOff:SetColorAndOpacity(self.ImgUnhoveredColor)
end

function SystemMenuTeamVoiceItem:OnBanStateChange(_, Msg)
    if not (Msg and Msg.BanType) or Msg.BanType ~= Pb_Enum_BAN_TYPE.BAN_VOICE then
        return
    end
    self:UpdateVoiceSwitchButton()
end

return SystemMenuTeamVoiceItem
