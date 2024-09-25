--[[
    局外结算玩家详情按钮界面
]]

local class_name = "HallSettlementDetailBtnMdt";
HallSettlementDetailBtnMdt = HallSettlementDetailBtnMdt or BaseClass(GameMediator, class_name);

-- 按钮状态类型
HallSettlementDetailBtnMdt.Enum_BtnStateType = {
    -- 普通态
    Normal = 1,
    -- 选中态
    Select = 2,
    -- hover态
    Hover = 3,
}

-- 按钮类型
HallSettlementDetailBtnMdt.Enum_BtnType = {
    -- 个人信息
    PersonalInfo = 1,
    -- 邀请队伍
    InviteTeam = 2,
    -- 私聊
    PrivateChat = 3,
}

function HallSettlementDetailBtnMdt:__init()
end

function HallSettlementDetailBtnMdt:OnShow(data)
end

function HallSettlementDetailBtnMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = {
        { UDelegate = self.BtnOutSide.OnClicked,    Func = self.OnClick_CloseBtn },
    }
    self.MsgList = {
        { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_DETAIL_INFO_CHANGED,    Func = self.OnGetPlayerDetailInfo },
    }

    self.SelectPlayerId = nil
    self.PlayerName = nil
    -- 按钮复用列表
    self.BtnItemList = {}
end

--[[
    Param = {
        SelectPlayerId 选择的玩家ID
        PlayerName 玩家名称 组队的时候需要使用
    }
]]
function M:OnShow(Param)
    self.SelectPlayerId = Param.SelectPlayerId
    self.PlayerName = Param.PlayerName
    self:UpdateUI()
end

function M:OnRepeatShow(Param)
    self:OnShow(Param)
end

-- 刷新UI
function M:UpdateUI()
    self:UpdateBtnShow()
    self:UpdateDetailBtnPosition()
end

-- 更新详情按钮位置
function M:UpdateDetailBtnPosition()
    local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
    local _,CurViewPortPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(self,MousePos)
    CurViewPortPos.Y = CurViewPortPos.Y + 10
    self.Panel_DetailBtn.Slot:SetPosition(CurViewPortPos)
end

-- 更新按钮显示
function M:UpdateBtnShow()
    local BtnInfoList = {
        {
            BtnType = HallSettlementDetailBtnMdt.Enum_BtnType.PersonalInfo,
            BtnText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "PersonalInformation"),
            ClickCallBackFunc = Bind(self,self.OnButtonPersonalInfoClicked),
        },
        {
            BtnType = HallSettlementDetailBtnMdt.Enum_BtnType.InviteTeam,
            BtnText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "InviteTeam"),
            ClickCallBackFunc = Bind(self,self.OnButtonInviteTeamClicked),
        },
    }

    --好友才允许私聊
    local IsFriend = MvcEntry:GetModel(FriendModel):IsFriend(self.SelectPlayerId)
    if IsFriend then
        local PrivateChatBtnInfo = {
            BtnType = HallSettlementDetailBtnMdt.Enum_BtnType.PrivateChat,
            BtnText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "PrivateChat"),
            ClickCallBackFunc = Bind(self,self.OnButtonPrivateChatClicked),
        } 
        BtnInfoList[#BtnInfoList + 1] = PrivateChatBtnInfo
    end

    for _, BtnItem in pairs(self.BtnItemList) do
        if BtnItem and BtnItem.View then
            BtnItem.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    for Index, BtnInfo in ipairs(BtnInfoList) do
        local Item = self.BtnItemList[Index]
        local Param = {
            ItemDataString = BtnInfo.BtnText,
            ItemIndex = Index,
            ItemID = BtnInfo.BtnType,
        }
        if not (Item and CommonUtil.IsValid(Item.View)) then
            local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/Components/ComboBox/WBP_ComboBoxItem.WBP_ComboBoxItem")
            local Widget = NewObject(WidgetClass, self)
            self.VerticalBox_BtnList:AddChild(Widget)
            Item = UIHandler.New(self,Widget,ComboBoxItem,Param).ViewInstance
            self.BtnItemList[Index] = Item
        end
        Item.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        Item:SetItemData(Param, Index, -1, BtnInfo.ClickCallBackFunc)
    end
end

--个人信息按钮点击
function M:OnButtonPersonalInfoClicked()
    if not self.SelectPlayerId then return end
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLookUpDetailReq(self.SelectPlayerId)
end

--邀请队伍按钮点击
function M:OnButtonInviteTeamClicked()
    if not self.SelectPlayerId or not self.PlayerName then return end
    ---@type TeamInviteModel
    local TeamInviteModel = MvcEntry:GetModel(TeamInviteModel)
    local InviteData = TeamInviteModel:GetData(self.SelectPlayerId)
    local IsInviting = InviteData ~= nil
    if not IsInviting then
        MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteReq(self.SelectPlayerId,self.PlayerName,Pb_Enum_TEAM_SOURCE_TYPE.HALL_SETTLEMENT)
        self:OnClick_CloseBtn() 
    else
        local TipText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "11450")
        UIAlert.Show(TipText)
    end
end

--私聊按钮点击
function M:OnButtonPrivateChatClicked()
    if not self.SelectPlayerId then return end
    local Param = {
        TargetPlayerId = self.SelectPlayerId
    }
    MvcEntry:OpenView(ViewConst.Chat,Param)

    self:OnClick_CloseBtn()
end

--收到返回的信息，再打开个人中心界面
function M:OnGetPlayerDetailInfo(TargetPlayerId)
    if self.SelectPlayerId == TargetPlayerId then
        local Param = {
            PlayerId = self.SelectPlayerId,
            SelectTabId = 1,
            OnShowParam = TargetPlayerId
        }
        MvcEntry:OpenView(ViewConst.PlayerInfo, Param)
        self:OnClick_CloseBtn()
    end
end

-- -- 更新按钮的hover状态
-- function M:UpdateBtnHoverState(BtnType)
--     local Widget = self.View["WBP_SettlmentDetailWidget" .. BtnType]
--     if Widget then
--         self:OnUpdateBtnState(Widget, self.Enum_BtnStateType.Hover)
--     end
-- end

-- -- 更新按钮的unhover状态
-- function M:UpdateBtnUnhoverState(BtnType)
--     local Widget = self.View["WBP_SettlmentDetailWidget" .. BtnType]
--     if Widget then
--         self:OnUpdateBtnState(Widget, self.Enum_BtnStateType.Normal)
--     end
-- end

-- -- 更新按钮点击状态
-- function M:UpdateBtnClickState(BtnType)
--     for i = 1, 3 do
--         local Widget = self.View["WBP_SettlmentDetailWidget" .. i]
--         if Widget then
--             local BtnStateType = BtnType == i and self.Enum_BtnStateType.Select or self.Enum_BtnStateType.Normal
--             self:OnUpdateBtnState(Widget, BtnStateType)
--         end
--     end
-- end

-- -- 更新按钮的显示状态
-- function M:OnUpdateBtnState(BtnWidget, BtnStateType)
--     if BtnStateType == self.Enum_BtnStateType.Select then
--         BtnWidget.WidgetSwitcher:SetActiveWidget(BtnWidget.Select) 
--     elseif BtnStateType == self.Enum_BtnStateType.Normal then
--         BtnWidget.WidgetSwitcher:SetActiveWidget(BtnWidget.Normal) 
--     elseif BtnStateType == self.Enum_BtnStateType.Hover then
--         BtnWidget.WidgetSwitcher:SetActiveWidget(BtnWidget.Hover) 
--     end
-- end

-- 关闭界面
function M:OnClick_CloseBtn()
    MvcEntry:CloseView(self.viewId)
end

return M
