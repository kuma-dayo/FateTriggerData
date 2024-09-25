--[[
    好友管理 - 黑名单列表 - 列表Item
]]
local class_name = "FriendManagerTabBlackListItem"
local FriendManagerTabBlackListItem = BaseClass(nil, class_name)

function FriendManagerTabBlackListItem:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.WBP_Friend_Btn_Remove.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_WBP_Friend_Btn_Remove) },
		{ UDelegate = self.View.WBP_Friend_Btn_Remove.GUIButton_Main.OnHovered,				Func = Bind(self,self.OnHovered_WBP_Friend_Btn_Remove) },
		{ UDelegate = self.View.WBP_Friend_Btn_Remove.GUIButton_Main.OnUnhovered,				Func = Bind(self,self.OnUnhovered_WBP_Friend_Btn_Remove) },

        -- { UDelegate = self.View.GUIButton_Bg.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_Bg.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },

        { UDelegate = self.View.WBP_Friend_Btn_Add.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_WBP_Friend_Btn_Add) },
		{ UDelegate = self.View.WBP_Friend_Btn_Add.GUIButton_Main.OnHovered,				Func = Bind(self,self.OnHovered_WBP_Friend_Btn_Add) },
		{ UDelegate = self.View.WBP_Friend_Btn_Add.GUIButton_Main.OnUnhovered,				Func = Bind(self,self.OnUnhovered_WBP_Friend_Btn_Add) },
	}

    self.MsgList = {
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID, Func = Bind(self,self.OnGetPlayerInfo)},
    }

    -- self.View.WBP_Friend_Btn_Remove.TextTips:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabBlackListItem_Removefromtheblackli")))
    -- self.View.WBP_Friend_Btn_Add.TextTips:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabBlackListItem_Moveoutandaddasafrie")))
end

function FriendManagerTabBlackListItem:OnShow()
    ---@type FriendModel
    self.FriendModel = MvcEntry:GetModel(FriendModel)
end

function FriendManagerTabBlackListItem:OnHide()
    self.FriendModel = nil
end

--[[
    FriendBlackNode = {
        PlayerId = Data.PlayerId,
        OpTime = Data.OpTime,
    }
]]
function FriendManagerTabBlackListItem:UpdateUI(FriendBlackData)
    if not FriendBlackData then
        CError("FriendManagerTabBlackListItem FriendBlackData Error!!",true)
        return
    end
    if not self.PlayerId or self.PlayerId ~= FriendBlackData.PlayerId then
        self.PlayerId = FriendBlackData.PlayerId
        self.OpTime = FriendBlackData.OpTime
        -- MvcEntry:GetCtrl(PersonalInfoCtrl):SendGetPlayerBaseInfoReq(self.PlayerId)
        self.PlayerInfo = nil
        local PlayerInfo = MvcEntry:GetModel(PersonalInfoModel):GetPlayerDetailInfo(self.PlayerId)
        if PlayerInfo then
            self.PlayerInfo = PlayerInfo
            self:UpdatePlayerInfo()
        end
    else
        self:UpdatePlayerInfo()
    end
end

-- 更新玩家信息
function FriendManagerTabBlackListItem:UpdatePlayerInfo()
    if not self.PlayerInfo then
        return
    end
    -- 玩家名称
    -- self.View.LabelPlayerName:SetText(StringUtil.Format(self.PlayerInfo.PlayerName))
    local PlayerNameParam = {
        WidgetBaseOrHandler = self,
        TextBlockName = self.View.LabelPlayerName,
        PlayerId = self.PlayerId,
        DefaultStr = self.PlayerInfo.PlayerName,
        IsHideNum = true,
    }
    MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
    -- 头像
    self:UpdateHeadIcon()
end

-- 收到玩家信息
function FriendManagerTabBlackListItem:OnGetPlayerInfo(_,PlayerId)
    if not self.PlayerId or self.PlayerId ~= PlayerId then
        return
    end
    local PlayerInfo = MvcEntry:GetModel(PersonalInfoModel):GetPlayerDetailInfo(self.PlayerId)
    if not PlayerInfo then
        return
    end
    self.PlayerInfo = PlayerInfo
    self:UpdatePlayerInfo()
end

-- 更新玩家头像
function FriendManagerTabBlackListItem:UpdateHeadIcon()
    local Param = {
        PlayerId = self.PlayerId,
        PlayerName = self.PlayerInfo.PlayerName,
        NotNeedReqPlayerInfo = true,
        FilterOperateList = {CommonPlayerInfoHoverTipMdt.OperateTypeEnum.AddFriend,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.InviteTeam}
    }
    if not self.SingleHeadCls then
        self.SingleHeadCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.SingleHeadCls:UpdateUI(Param)
    end
end

-- 点击移出列表
function FriendManagerTabBlackListItem:OnClick_WBP_Friend_Btn_Remove()
    MvcEntry:GetCtrl(FriendCtrl):SendFriendSetPlayerBlackReq(self.PlayerId,false,false)
end

-- 点击移出并添加好友
function FriendManagerTabBlackListItem:OnClick_WBP_Friend_Btn_Add()
    MvcEntry:GetCtrl(FriendCtrl):SendFriendSetPlayerBlackReq(self.PlayerId,false,true)
end

----- Hover效果
function FriendManagerTabBlackListItem:OnHovered_WBP_Friend_Btn_Remove()
    local Param = {
        ParentWidgetCls = self,
        TipsStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabBlackListItem_Removefromtheblackli")),
        FocusWidget = self.View.WBP_Friend_Btn_Remove,
    }
    MvcEntry:OpenView(ViewConst.CommonHoverTips,Param)
    -- self.View.WBP_Friend_Btn_Remove.HoverTips:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    -- self:GUIButton_Bg_OnHovered()
end

function FriendManagerTabBlackListItem:OnUnhovered_WBP_Friend_Btn_Remove()
    MvcEntry:CloseView(ViewConst.CommonHoverTips)
    -- self.View.WBP_Friend_Btn_Remove.HoverTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self:GUIButton_Bg_OnUnhovered()
end

function FriendManagerTabBlackListItem:OnHovered_WBP_Friend_Btn_Add()
    local Param = {
        ParentWidgetCls = self,
        TipsStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabBlackListItem_Moveoutandaddasafrie")),
        FocusWidget = self.View.WBP_Friend_Btn_Add,
    }
    MvcEntry:OpenView(ViewConst.CommonHoverTips,Param)
    -- self.View.WBP_Friend_Btn_Add.HoverTips:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    -- self:GUIButton_Bg_OnHovered()
end

function FriendManagerTabBlackListItem:OnUnhovered_WBP_Friend_Btn_Add()
    MvcEntry:CloseView(ViewConst.CommonHoverTips)
    -- self.View.WBP_Friend_Btn_Add.HoverTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self:GUIButton_Bg_OnUnhovered()
end

-- function FriendManagerTabBlackListItem:GUIButton_Bg_OnHovered()
--     self.View.ListBg_Btn_Switch:SetActiveWidget(self.View.ListBg_Hover)
-- end

-- function FriendManagerTabBlackListItem:GUIButton_Bg_OnUnhovered()
--     self.View.ListBg_Btn_Switch:SetActiveWidget(self.View.ListBg_Normal)
-- end
return FriendManagerTabBlackListItem
