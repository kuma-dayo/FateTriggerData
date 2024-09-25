--[[
    房间观战列表Item逻辑
]]
local class_name = "CustomRoomSpectatorItemLogic"
local CustomRoomSpectatorItemLogic = BaseClass(nil, class_name)

function CustomRoomSpectatorItemLogic:OnInit()
    self.TheCustomRommModel = MvcEntry:GetModel(CustomRoomModel)
    self.TheUserModel = MvcEntry:GetModel(UserModel)

    self.BindNodes = 
    {
		{ UDelegate = self.View.Btn_WatchPlayer.OnClicked,Func = Bind(self,self.BtnClick) },
	}
end
function CustomRoomSpectatorItemLogic:OnShow(Param)
end

--[[
    local Param = {
        Pos = Pos,
        SpectatorInfo = SpectatorInfo,
    }
]]
function CustomRoomSpectatorItemLogic:SetData(Param)
    if not Param then
        return
    end
    self.Pos = Param.Pos
    self.SpectatorInfo = Param.SpectatorInfo
    self.Param = Param
    self.IsSelf = false

    if self.SpectatorInfo then
        self.View.Panel_Head:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.Panel_Name:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        --更新房主旗帜
        self.View.Image_Flag:SetVisibility(self.TheCustomRommModel:IsMaster(self.SpectatorInfo.PlayerId) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        self.IsSelf = self.TheUserModel:IsSelf(self.SpectatorInfo.PlayerId)

        --更新头像
        local Param = {
            PlayerId = self.SpectatorInfo.PlayerId,
            PlayerName = self.SpectatorInfo.PlayerName,
            FilterOperateList = {CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Chat},
            CloseAutoCheckFriendShow = true,
        }
        if not self.HeadIconCls then
            self.HeadIconCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
        else
            self.HeadIconCls:UpdateUI(Param,true)
        end

        --更新玩家名称
        if self.IsSelf then
            self.View.WidgetSwitcher_PlayerName:SetActiveWidget(self.View.LabelPlayerName_My)
            self.View.LabelPlayerName_My:SetText(StringUtil.Format(StringUtil.StringTruncationByChar(self.SpectatorInfo.PlayerName, "#")[1]))
        else
            self.View.WidgetSwitcher_PlayerName:SetActiveWidget(self.View.LabelPlayerName_Other)
            self.View.LabelPlayerName_Other:SetText(StringUtil.Format(StringUtil.StringTruncationByChar(self.SpectatorInfo.PlayerName, "#")[1]))
        end
    else
        self.View.Image_Flag:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Panel_Head:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Panel_Name:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    --玩家位置序号
    self.View.Text_TeamNumber1:SetText(self.Pos)
    self.View.Text_TeamNumberMy:SetText(self.Pos)
    self.View.WidgetSwitcher_Number:SetActiveWidget(not self.IsSelf and self.View.Text_TeamNumber1 or self.View.Text_TeamNumberMy)
end

function CustomRoomSpectatorItemLogic:OnHide()
end

function CustomRoomSpectatorItemLogic:UpdateShow()

end

function CustomRoomSpectatorItemLogic:BtnClick()
    if self.SpectatorInfo then
        return
    end
    --空位置可以跳入
end

return CustomRoomSpectatorItemLogic
