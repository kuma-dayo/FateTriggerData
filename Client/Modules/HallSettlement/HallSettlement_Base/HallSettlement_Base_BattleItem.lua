---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 局外结算界面战斗界面列表item
--- Created At: 2023/08/21 14:45
--- Created By: 朝文
---

local class_name = "HallSettlement_Base_BattleItem"
---@class HallSettlement_Base_BattleItem
local HallSettlement_Base_BattleItem = BaseClass(nil, class_name)

---三连按钮（添加好友 邀请 点赞）触发点击效果类型
HallSettlement_Base_BattleItem.Enum_TripleButtonClickType = {
    ---无效类型
    None = 0,
    ---普通点击
    Click = 1,
    ---长按类型
    LongPress = 2,
}

---点击按钮类型
HallSettlement_Base_BattleItem.Enum_ClickButtonType = {
    -- 无效类型
    None = 0,
    -- 添加好友
    AddFriend = 1,
    -- 邀请队伍
    InviteTeam = 2,
    -- 点赞
    Like = 3 
}

---三连按钮列表按钮列表
HallSettlement_Base_BattleItem.Const_TripleButtonInfoList = {
    [HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend] = {
        WidgetName = "WBP_Button_AddFriend",
    },
    [HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam] = {
        WidgetName = "WBP_Button_Invite",
    },
    [HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like] = {
        WidgetName = "WBP_Button_Like",
    },
}

function HallSettlement_Base_BattleItem:OnInit()
    self.ItemBaseRoot = self.View.WBP_Settlement_Data_PlayerListItem_Base
    self.BindNodes = {
        { UDelegate = self.ItemBaseRoot.GUIButton.OnClicked,    Func = Bind(self, self.OnButtonClicked) },
        { UDelegate = self.ItemBaseRoot.GUIButton.OnHovered,    Func = Bind(self, self.OnButtonHovered) },
        { UDelegate = self.ItemBaseRoot.GUIButton.OnUnhovered,  Func = Bind(self, self.OnButtonUnhovered) },
        { UDelegate = self.ItemBaseRoot.GUIButton.OnPressed,    Func = Bind(self, self.OnButtonPressed) },
        { UDelegate = self.ItemBaseRoot.GUIButton.OnReleased,   Func = Bind(self, self.OnButtonReleased) },

        { UDelegate = self.ItemBaseRoot.WBP_Button_AddFriend.GUIButton_Main.OnPressed,     Func = Bind(self,self.OnButtonPressed_AddFriend)},
        { UDelegate = self.ItemBaseRoot.WBP_Button_AddFriend.GUIButton_Main.OnReleased,     Func = Bind(self,self.OnButtonReleased_AddFriend)},
        { UDelegate = self.ItemBaseRoot.WBP_Button_AddFriend.GUIButton_Main.OnHovered,   Func = Bind(self,self.OnButtonOnHovered_AddFriend)},
        { UDelegate = self.ItemBaseRoot.WBP_Button_AddFriend.GUIButton_Main.OnUnhovered,   Func = Bind(self,self.OnButtonUnhovered_AddFriend)},
        
        { UDelegate = self.ItemBaseRoot.WBP_Button_Invite.GUIButton_Main.OnPressed,     Func = Bind(self,self.OnButtonPressed_InviteTeam)},
        { UDelegate = self.ItemBaseRoot.WBP_Button_Invite.GUIButton_Main.OnReleased,     Func = Bind(self,self.OnButtonReleased_InviteTeam)},
        { UDelegate = self.ItemBaseRoot.WBP_Button_Invite.GUIButton_Main.OnHovered,   Func = Bind(self,self.OnButtonOnHovered_InviteTeam)},
        { UDelegate = self.ItemBaseRoot.WBP_Button_Invite.GUIButton_Main.OnUnhovered,   Func = Bind(self,self.OnButtonUnhovered_InviteTeam)},
        
        { UDelegate = self.ItemBaseRoot.WBP_Button_Like.GUIButton_Main.OnPressed,       Func = Bind(self,self.OnButtonPressed_Like)},
        { UDelegate = self.ItemBaseRoot.WBP_Button_Like.GUIButton_Main.OnReleased,       Func = Bind(self,self.OnButtonReleased_Like)},
        { UDelegate = self.ItemBaseRoot.WBP_Button_Like.GUIButton_Main.OnHovered,   Func = Bind(self,self.OnButtonOnHovered_Like)},
        { UDelegate = self.ItemBaseRoot.WBP_Button_Like.GUIButton_Main.OnUnhovered,   Func = Bind(self,self.OnButtonUnhovered_Like)},
    }
    self.MsgList = {
        {Model = FriendModel, MsgName = FriendModel.ON_ADD_FRIEND,                     Func = Bind(self,self.UpdateFriendBtn)},

        {Model = TeamInviteModel, MsgName = ListModel.ON_CHANGED,                     Func = Bind(self,self.UpdateInviteBtn)},
        {Model = TeamInviteModel, MsgName = ListModel.ON_DELETED,                     Func = Bind(self,self.OnCancelTeamInvite)},
        {Model = TeamInviteModel, MsgName = TeamInviteModel.ON_APPEND_TEAM_INVITE,    Func = Bind(self,self.OnTeamInvite)},
        
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_GIVE_LIKE_SUCCESS, Func = Bind(self,self.ON_GIVE_LIKE_SUCCESS_func) },
    }

    -- 是否正在邀请
    self.IsInviting = false
    -- 是否已点赞
    self.IsLiked = false
    -- 是否自己
    self.IsSelf = false
    -- 是否选中状态
    self.IsSelectState = false

    ---@type HallSettlementModel
    self.HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)

    ---@type UserModel
    self.UserModel = MvcEntry:GetModel(UserModel)

    ---@type FriendModel
    self.FriendModel = MvcEntry:GetModel(FriendModel)

    ---长按的触发时间
    self.LongPressButtonTriggerTime = self.HallSettlementModel:GetLongPressButtonTriggerTime()
    ---三连的触发时间
    self.TripleButtonTriggerTime = self.HallSettlementModel:GetTripleButtonTriggerTime()

    --- 三连经过的时间
    self.TripleRecordTime = 0
    -- 当前点击按钮类型
    self.CurClickButtonType = HallSettlement_Base_BattleItem.Enum_ClickButtonType.None
    -- 当前按钮点击类型
    self.CurTripleButtonClickType = HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.None
    -- 当前触发的三连按钮类型
    self.CurTripleButtonTypeList = {}
    -- 是否初始化鼠标倒计时材质
    self.InitTripleButtonMouseMaterial = false

    -- 匹配模式类型
    self.MatchType = "Survive"
    self.SettlementItemType = 1
end

function HallSettlement_Base_BattleItem:OnShow(Param)   

end
function HallSettlement_Base_BattleItem:OnHide()     
    ---清除定时器
    self:ClearTripleTimer()
end

--[[
    Param = {
        ...
        clickCallback = {}
    }
--]]
function HallSettlement_Base_BattleItem:SetData(Param, MatchType, SettlementItemType)
    self.Data = Param
    local PlayerId = self.Data.PlayerId
    self.IsSelf = PlayerId and tonumber(PlayerId) == self.UserModel:GetPlayerId()
    self.MatchType = MatchType
    self.SettlementItemType = SettlementItemType
end

function HallSettlement_Base_BattleItem:UpdateView()
    --1.更新头像
    self:UpdateHeadIcon()
    
    --2.更新名字
    self:UpdatePlayerName()

    --3.默认不选中，选中单独使用 Select 或 UnSelect 处理
    self.ItemBaseRoot.BgMine:SetVisibility(UE.ESlateVisibility.Hidden)
    self:_UpdateTextColor(false)

    --4.设置添加好友按钮显示，自己或者自己的好友不显示
    self:UpdateFriendBtn()

    --5.设置组队按钮显示,自己或者在队伍中，不显示
    self:UpdateInviteBtn()

    --6.设置点赞按钮显示,自己不显示 历史战绩模式不显示
    self:UpdateLikeBtn()

    --7.更新三连按钮相关显示
    self:ResetButtonDefaltState()
    self:ResetTripleButtonData()
    
    --TODO: 如果有其他需要更新的，再在后面加就行
end

---更新头像
function HallSettlement_Base_BattleItem:UpdateHeadIcon()
    local Data = self.Data

    local HeroTypeId = Data.HeroTypeId
    local HeroSkinCfg = MvcEntry:GetModel(HeroModel):GetDefaultSkinCfgByHeroId(HeroTypeId)
    if HeroSkinCfg then
        --1.1.头像图标
        CommonUtil.SetBrushFromSoftObjectPath(self.ItemBaseRoot.WBP_Head.GUIImage_Hero, HeroSkinCfg[Cfg_HeroSkin_P.PNGPathAnomaly])

        --1.2.位置信息
        self.ItemBaseRoot.WBP_Head.Text_Num:SetText(Data.PosInTeam)

        --1.3.位置颜色
        local MiscSystem = UE.UMiscSystem.GetMiscSystem(GameInstance)
        local NewLinearColor = MiscSystem.TeamColors:FindRef(tostring(Data.PosInTeam))
        self.ItemBaseRoot.WBP_Head.ImgBg:SetBrushTintColor(UIHelper.ToSlateColor_LC(NewLinearColor))
    else
        CError("[cw] cannot find icon base on the HeroTypeId(" .. tostring(HeroTypeId) .. ")")
    end
end

---更新玩家名字
function HallSettlement_Base_BattleItem:UpdatePlayerName()
    local Data = self.Data

    --2.设置名字   
    local PlayerName = Data.PlayerName or ""
    self.ItemBaseRoot.PlayerName:SetText(PlayerName)
end

--TODO: 重写，返回需要改变颜色的控件列表
---@return table
function HallSettlement_Base_BattleItem:GetAllNeedToChangeColorTextWidget()
    return {self.ItemBaseRoot.PlayerName}
end

---外部不要调用，这里用于更改文字颜色
function HallSettlement_Base_BattleItem:_UpdateTextColor(bIsSelect)
    --1.选取对应颜色
    local TargetColor
    if bIsSelect then
        TargetColor = self.ItemBaseRoot.SelectColor
    else
        TargetColor = self.IsSelf and self.ItemBaseRoot.MyselfColor or self.ItemBaseRoot.DefaultColor
    end

    if not TargetColor then
        CError("[cw] trying to set a illegal color to HallSettlementSubpageBattleItem")
        CError(debug.traceback())
        return
    end

    --2.设置颜色
    local List = self:GetAllNeedToChangeColorTextWidget()
    for _, TextWidget in pairs(List) do
        if TextWidget then TextWidget:SetColorAndOpacity(TargetColor) end
    end
end

---选中
function HallSettlement_Base_BattleItem:Select()
    if not self.IsSelectState then
        self.IsSelectState = true 
        self:ResetButtonDefaltState()
    end
    self.ItemBaseRoot.BgMine:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.ItemBaseRoot.WidgetSwitcher_state:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:_UpdateTextColor(true)
end

---未选中
function HallSettlement_Base_BattleItem:UnSelect()
    if self.IsSelectState then
        self.IsSelectState = false 
        self:ResetButtonDefaltState()
    end
    self.ItemBaseRoot.BgMine:SetVisibility(UE.ESlateVisibility.Hidden)
    self.ItemBaseRoot.WidgetSwitcher_state:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:_UpdateTextColor(false)
end

--region GUIButton

function HallSettlement_Base_BattleItem:OnButtonClicked()
    if self.Data and self.Data.clickCallback then
        print_r(self.Data, "[cw] self.Data")
        self.Data.clickCallback(self.Data)
    end
end

function HallSettlement_Base_BattleItem:OnButtonHovered()
    self.ItemBaseRoot.WidgetSwitcher_state:SetActiveWidgetIndex(1)
end

function HallSettlement_Base_BattleItem:OnButtonUnhovered()
    self.ItemBaseRoot.WidgetSwitcher_state:SetActiveWidgetIndex(0)
end

function HallSettlement_Base_BattleItem:OnButtonPressed()
    self.ItemBaseRoot.WidgetSwitcher_state:SetActiveWidgetIndex(2)
end

function HallSettlement_Base_BattleItem:OnButtonReleased()
    self.ItemBaseRoot.WidgetSwitcher_state:SetActiveWidgetIndex(0)
end

-- 重置按钮状态
function HallSettlement_Base_BattleItem:ResetButtonDefaltState()
    for ClickType, ButtonInfo in ipairs(HallSettlement_Base_BattleItem.Const_TripleButtonInfoList) do
        local ButtonWidget = self.ItemBaseRoot[ButtonInfo.WidgetName]
        if ButtonWidget then
            local EventName = ""
            -- 邀请按钮&取消邀请状态 事件名不太一样
            if ClickType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam and self.IsInviting then
                EventName = self.IsSelectState and "VXE_Btn_List_Default_DisInvite" or "VXE_Btn_Default_DisInvite"
            else
                EventName = self.IsSelectState and "VXE_Btn_List_Hover" or "VXE_Btn_List_Unhover"
            end
            if ButtonWidget[EventName] then
                ButtonWidget[EventName](ButtonWidget) 
            end
        end
    end
end

-- 三连按钮按下状态切换
function HallSettlement_Base_BattleItem:OnButtonPressed_TripleButton(ButtonType, IsPressed)
    local ButtonInfo = HallSettlement_Base_BattleItem.Const_TripleButtonInfoList[ButtonType]
    local ButtonWidget = self.ItemBaseRoot[ButtonInfo.WidgetName]
    if ButtonWidget then
        local EventName = ""
        if IsPressed then
            -- 邀请按钮&取消邀请状态 事件名不太一样
            if ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam and self.IsInviting then
                EventName = self.IsSelectState and "VXE_Btn_List_Pressed_DisInvite" or "VXE_Btn_Pressed_DisInvite"
            else
                -- 按下 
                -- EventName = self.IsSelectState and "VXE_Btn_List_Pressed" or "VXE_Btn_List_Unhover"
            end
        else
            -- 邀请按钮&取消邀请状态 事件名不太一样
            if ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam and self.IsInviting then
                EventName = self.IsSelectState and "VXE_Btn_List_UnPressed_DisInvite" or "VXE_Btn_UnPressed_DisInvite"
            else
                -- 抬起
                -- EventName = self.IsSelectState and "VXE_Btn_List_UnPressed" or "VXE_Btn_UnPressed"
            end
        end
        if ButtonWidget[EventName] then
            ButtonWidget[EventName](ButtonWidget)  
        end
    end
end

-- 三连按钮hover状态切换
function HallSettlement_Base_BattleItem:OnButtonHover_TripleButton(ButtonType, IsHover)
    local ButtonInfo = HallSettlement_Base_BattleItem.Const_TripleButtonInfoList[ButtonType]
    local ButtonWidget = self.ItemBaseRoot[ButtonInfo.WidgetName]
    if ButtonWidget then
        local EventName = ""
        if IsHover then
            -- 邀请按钮&取消邀请状态 事件名不太一样
            if ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam and self.IsInviting then
                EventName = self.IsSelectState and "VXE_Btn_List_Hover_DisInvite" or "VXE_Btn_Hover_DisInvite"
            else
                -- EventName = self.IsSelectState and "VXE_Btn_List_Hover" or "VXE_Btn_Hover"
            end
        else
            -- 邀请按钮&取消邀请状态 事件名不太一样
            -- unhover
            if ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam and self.IsInviting then
                EventName = self.IsSelectState and "VXE_Btn_List_UnHover_DisInvite" or "VXE_Btn_UnHover_DisInvite"
            else
                -- EventName = self.IsSelectState and "VXE_Btn_List_UnHover" or "VXE_Btn_UnHover"
            end
        end
        if ButtonWidget[EventName] then
            ButtonWidget[EventName](ButtonWidget)  
        end
    end
end

--endregion GUIButton

--region 添加好友按钮

-- 更新好友按钮
function HallSettlement_Base_BattleItem:UpdateFriendBtn()
    --自己不显示
    local IsFriend = self.FriendModel:IsFriend(self.Data.PlayerId)
    local IsShowBtn = not self.IsSelf and not IsFriend 
    self.ItemBaseRoot.WBP_Button_AddFriend:SetVisibility(IsShowBtn and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden)
end

-- 添加好友按钮按下
function HallSettlement_Base_BattleItem:OnButtonPressed_AddFriend()
    self:OnButtonPressed_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend, true)

    self.CurTripleButtonClickType = HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.Click
    self.CurClickButtonType = HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend
    self:StartCheckLongPressTimer()
end

-- 添加好友按钮抬起
function HallSettlement_Base_BattleItem:OnButtonReleased_AddFriend()
    self:OnButtonPressed_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend, false)

    if self.CurTripleButtonClickType == HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.Click then
        self:ClearCheckLongPressTimer()
        self:OnTriggerAddFriendEvent()
    elseif self.CurTripleButtonClickType == HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.LongPress then
        self:CancelTripleButton()
    end
end

-- 添加好友按钮hover
function HallSettlement_Base_BattleItem:OnButtonOnHovered_AddFriend()
    self:OnButtonHover_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend, true)
end

-- 添加好友按钮unhovered
function HallSettlement_Base_BattleItem:OnButtonUnhovered_AddFriend()
    self:OnButtonHover_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend, false)

    if self.CurClickButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend then
        self:CancelTripleButton()
    end
end

-- 添加好友事件触发
function HallSettlement_Base_BattleItem:OnTriggerAddFriendEvent()
    if self.Data and self.Data.PlayerId then
        MvcEntry:GetCtrl(FriendCtrl):SendProto_AddFriendReq(self.Data.PlayerId)
    end
end

--endregion 添加好友按钮

--region 组队按钮
---更新邀请好友按钮
function HallSettlement_Base_BattleItem:UpdateInviteBtn()
    CLog("[cw] HallSettlement_Base_BattleItem:UpdateInviteBtn")
    if not self.Data or not self.Data.PlayerId then return end

    --队友不显示
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsInMyTeam = TeamModel:IsInMyTeam(self.Data.PlayerId)

    local IsShowBtn = not self.IsSelf and not IsInMyTeam
    --只处理陌生人的情况
    self.ItemBaseRoot.WBP_Button_Invite:SetVisibility(IsShowBtn and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden)
    ---@type TeamInviteModel
    local TeamInviteModel = MvcEntry:GetModel(TeamInviteModel)
    local InviteData = TeamInviteModel:GetData(self.Data.PlayerId)

    self.IsInviting = InviteData ~= nil
    -- hz 临时屏蔽
    -- root.WBP_Button_Invite.IsBtnInviteState = self.IsInviting
    -- root.WBP_Button_Invite.TextTips:SetText(StringUtil.Format(self.IsInviting and G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlement_Canceltheinvitation") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlement_Inviteateam")))

    -- 给按钮蓝图变量赋值，要在播放动效之前，动效依赖此变量
    self.ItemBaseRoot.WBP_Button_Invite.IsBtnInviteState = self.IsInviting
    if self.IsInviting then
        -- local EventName = self.IsSelectState and "VXE_Btn_Inviting_Success" or "VXE_Btn_Inviting_Success"
        -- -- 进入邀请状态
        -- if  self.ItemBaseRoot.WBP_Button_Invite[EventName] then
        --     self.ItemBaseRoot.WBP_Button_Invite[EventName](self.ItemBaseRoot.WBP_Button_Invite) 
        -- end
        -- 进入邀请状态
        if self.ItemBaseRoot.WBP_Button_Invite.VXE_Btn_Inviting_Success then
            self.ItemBaseRoot.WBP_Button_Invite:VXE_Btn_Inviting_Success()
        end
    else
        -- local EventName = self.IsSelectState and "VXE_Btn_List_Default" or "VXE_Btn_Default"
        -- -- 取消邀请，进入普通状态
        -- self.ItemBaseRoot.WBP_Button_Invite[EventName](self.ItemBaseRoot.WBP_Button_Invite)

                --     if self.View.WBP_Common_InviteBtn_Add.VXE_Btn_Invite_Cancel_Success then
        --         self.View.WBP_Common_InviteBtn_Add:VXE_Btn_Invite_Cancel_Success()
        --     end

        -- 进入邀请状态
        if self.ItemBaseRoot.WBP_Button_Invite.VXE_Btn_Invite_Cancel_Success then
            self.ItemBaseRoot.WBP_Button_Invite:VXE_Btn_Invite_Cancel_Success()
        end
    end

        -- -- 给按钮蓝图变量赋值，要在播放动效之前，动效依赖此变量
        -- self.View.WBP_Common_InviteBtn_Add.IsBtnInviteState = IsOperating
        -- -- 初始化不需要播放动效
        -- if IsOperating then
        --     -- 进入邀请状态
        --     if self.View.WBP_Common_InviteBtn_Add.VXE_Btn_Inviting_Success then
        --         self.View.WBP_Common_InviteBtn_Add:VXE_Btn_Inviting_Success()
        --     end
        -- elseif not IsInit and IsInInvitingState then
        --     -- 原来在邀请状态，现在非操作中，播放取消邀请
        --     if self.View.WBP_Common_InviteBtn_Add.VXE_Btn_Invite_Cancel_Success then
        --         self.View.WBP_Common_InviteBtn_Add:VXE_Btn_Invite_Cancel_Success()
        --     end
        -- end
end

-- 邀请组队按钮按下
function HallSettlement_Base_BattleItem:OnButtonPressed_InviteTeam()
    self:OnButtonPressed_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam, true)

    self.CurTripleButtonClickType = HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.Click
    self.CurClickButtonType = HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam
    self:StartCheckLongPressTimer()
end

-- 邀请组队按钮抬起
function HallSettlement_Base_BattleItem:OnButtonReleased_InviteTeam()
    self:OnButtonPressed_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam, false)

    if self.CurTripleButtonClickType == HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.Click then
        self:ClearCheckLongPressTimer()
        self:OnTriggerInviteTeamEvent()
    elseif self.CurTripleButtonClickType == HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.LongPress then
        self:CancelTripleButton()
    end
end

-- 邀请组队按钮hover
function HallSettlement_Base_BattleItem:OnButtonOnHovered_InviteTeam()
    self:OnButtonHover_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam, true)
end

-- 邀请组队按钮unhovered
function HallSettlement_Base_BattleItem:OnButtonUnhovered_InviteTeam()
    self:OnButtonHover_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam, false)

    if self.CurClickButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam then
        self:CancelTripleButton()
    end
end

-- 邀请组队事件触发
function HallSettlement_Base_BattleItem:OnTriggerInviteTeamEvent()
    ---@type TeamCtrl
    local TeamCtrl = MvcEntry:GetCtrl(TeamCtrl)
    if self.IsInviting then
        local Msg  = { InviteeId = self.Data.PlayerId }
        TeamCtrl:SendTeamInviteCancelReq(Msg)

        local TipText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "11452")
        UIAlert.Show(TipText)
    else
        local SourceType = self.SettlementItemType == HallSettlementModel.Enum_SettlementItemType.History and Pb_Enum_TEAM_SOURCE_TYPE.SCORE_HISTORY or Pb_Enum_TEAM_SOURCE_TYPE.LAYER_SETTLEMENT
        TeamCtrl:SendTeamInviteReq(self.Data.PlayerId, self.Data.PlayerName, SourceType)
    end 
end

--endregion 组队按钮

--region 点赞按钮

---更新点赞按钮展示
function HallSettlement_Base_BattleItem:UpdateLikeBtn()
    if self.IsSelf or self.SettlementItemType == HallSettlementModel.Enum_SettlementItemType.History then
        self.ItemBaseRoot.WBP_Button_Like:SetVisibility(UE.ESlateVisibility.Hidden)
    else
        self.ItemBaseRoot.WBP_Button_Like:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if self.IsLiked then
            self.ItemBaseRoot.WBP_Button_Like:SetColorAndOpacity(UIHelper.LinearColor.Grey)
            self.ItemBaseRoot.WBP_Button_Like:SetIsEnabled(false)
        end 
    end
end

---点赞按钮按下
function HallSettlement_Base_BattleItem:OnButtonPressed_Like()
    self:OnButtonPressed_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like, true)

    self.CurTripleButtonClickType = HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.Click
    self.CurClickButtonType = HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like
    self:StartCheckLongPressTimer()
end

---点赞按钮抬起
function HallSettlement_Base_BattleItem:OnButtonReleased_Like()
    self:OnButtonPressed_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like, false)

    if self.CurTripleButtonClickType == HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.Click then
        self:ClearCheckLongPressTimer()
        self:OnTriggerLikeEvent()
    elseif self.CurTripleButtonClickType == HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.LongPress then
        self:CancelTripleButton()
    end
end

-- 点赞按钮hover
function HallSettlement_Base_BattleItem:OnButtonOnHovered_Like()
    self:OnButtonHover_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like, true)
end

---点赞按钮unhovered
function HallSettlement_Base_BattleItem:OnButtonUnhovered_Like()
    self:OnButtonHover_TripleButton(HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like, false)

    if self.CurClickButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like then
        self:CancelTripleButton()
    end
end

-- 触发点赞操作
function HallSettlement_Base_BattleItem:OnTriggerLikeEvent()
    if not self.IsLike then
        local GameId = self.HallSettlementModel:GetGameId()
        self.HallSettlementModel:AddLike(GameId, nil, self.Data.PlayerId)
    end
end

--endregion 点赞按钮

---检测此按钮类型是否可以触发三联效果
function HallSettlement_Base_BattleItem:CheckIsCanTriggerButtonEvent(ButtonType)
    local IsCanTrigger = false
    if ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend then
        IsCanTrigger = self.ItemBaseRoot.WBP_Button_AddFriend:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible 
    elseif ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam then
        IsCanTrigger = not self.IsInviting and self.ItemBaseRoot.WBP_Button_Invite:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible 
    elseif ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like then
        IsCanTrigger = self.ItemBaseRoot.WBP_Button_Like:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible 
    end
    return IsCanTrigger    
end

--region 定时器相关
--启动长按检测定时器
function HallSettlement_Base_BattleItem:StartCheckLongPressTimer()
    CLog("[hz] HallSettlement_Base_BattleItem 启动长按检测定时器")
    self:ClearCheckLongPressTimer()
    self.CheckLongPressTimer = Timer.InsertTimer(self.LongPressButtonTriggerTime,function()
        local ButtonTypeList = {HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend, HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam, HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like}
        self.CurTripleButtonTypeList = {}
        for _, ButtonType in ipairs(ButtonTypeList) do
            local IsCanTriggerTriple = self:CheckIsCanTriggerButtonEvent(ButtonType)
            if IsCanTriggerTriple then
                self.CurTripleButtonTypeList[#self.CurTripleButtonTypeList + 1] = ButtonType
            end
        end
        if #self.CurTripleButtonTypeList > 0 then
            self:StartTripleButton()
        end
	end)   
end

--移除长按检测定时器
function HallSettlement_Base_BattleItem:ClearCheckLongPressTimer()
    if self.CheckLongPressTimer then
        Timer.RemoveTimer(self.CheckLongPressTimer)
    end
    self.CheckLongPressTimer = nil
end

--启动三连按钮检测定时器
function HallSettlement_Base_BattleItem:StartCheckTripleButtonTimer()
    CLog("[hz] HallSettlement_Base_BattleItem 启动三连按钮检测定时器")
    self:ClearCheckTripleButtonTimer()
    self.CheckTripleButtonTimer = Timer.InsertTimer(self.TripleButtonTriggerTime,function()
        self:CompleteTripleButton()
	end)   
end

-- 开始触发鼠标的长按进度条
function HallSettlement_Base_BattleItem:StartMouseLongPressProgressBar()
    local UIManager = UE.UGUIManager.GetUIManager(self.View)
    if UIManager then
        self:UpdateMouseLongPressProgressBarMaterial()
        UIManager:SetCursorStartLongPress(true, self.TripleButtonTriggerTime, 0.0)  
    end
end

-- 停止触发鼠标的长按进度条
function HallSettlement_Base_BattleItem:StopMouseLongPressProgressBar()
    local UIManager = UE.UGUIManager.GetUIManager(self.View)
    if UIManager then
        self:UpdateMouseLongPressProgressBarMaterial()
        UIManager:SetCursorStartLongPress(false, self.TripleButtonTriggerTime, 0.0)
    end
end

-- 更新鼠标的长按进度条材质显示
function HallSettlement_Base_BattleItem:UpdateMouseLongPressProgressBarMaterial()
    if not self.InitTripleButtonMouseMaterial then
        self.InitTripleButtonMouseMaterial = true
        local MaterialPath, MaterialParam = self.HallSettlementModel:GetTripleButtonMouseMaterialParam(self.MatchType)
        if MaterialPath then
            local MaterialObj = LoadObject(MaterialPath)
            if MaterialObj then
                local UIManager = UE.UGUIManager.GetUIManager(self.View)
                if UIManager then
                    UIManager:SetCursorLongPressMaterialAndParameterName(MaterialObj, MaterialParam) 
                end
            end 
        end
    end
end

--移除三连按钮检测定时器
function HallSettlement_Base_BattleItem:ClearCheckTripleButtonTimer()
    if self.CheckTripleButtonTimer then
        Timer.RemoveTimer(self.CheckTripleButtonTimer)
    end
    self.CheckTripleButtonTimer = nil
end

-- 开始记录三连经过的时间的定时器 用于进度条变化 0.1S触发
function HallSettlement_Base_BattleItem:StartRecordTimeTickTimer()
    self:ClearRecordTimeTickTimer()

    local AddTime = 0.1
    self.RecordTimeTickTimer = Timer.InsertTimer(AddTime,function()
        self.TripleRecordTime = self.TripleRecordTime + AddTime
        self:UpdateTripleButtonProgress()
	end, true, "RecordTimeTickTimer", true)   
end

-- 更新三连按钮的进度条
function HallSettlement_Base_BattleItem:UpdateTripleButtonProgress()
    local Progress = self.TripleRecordTime / self.TripleButtonTriggerTime
    self.ItemBaseRoot.ImgEnergyProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", Progress)   
end

-- 移除记录三连经过的时间的定时器
function HallSettlement_Base_BattleItem:ClearRecordTimeTickTimer()
    self.TripleRecordTime = 0
    if self.RecordTimeTickTimer then
        Timer.RemoveTimer(self.RecordTimeTickTimer)
    end
    self.RecordTimeTickTimer = nil
end

--移除三连相关的定时器
function HallSettlement_Base_BattleItem:ClearTripleTimer()
    self:ClearCheckLongPressTimer()
    self:ClearCheckTripleButtonTimer()
    self:ClearRecordTimeTickTimer()
end

--endregion 定时器相关

--region 三连按钮相关

---开始触发三连按钮  
function HallSettlement_Base_BattleItem:StartTripleButton()
    CLog("[hz] HallSettlement_Base_BattleItem 开始触发三连按钮")
    self.CurTripleButtonClickType = HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.LongPress
    self:StartCheckTripleButtonTimer()
    -- self:StartMouseLongPressProgressBar() 视觉确认不需要鼠标倒计时
    self:UpdateTripleButtonEventShow()
    self:UpdateTripleButtonProgressShow()
    self:UpdateTripleButtonProgress()
    self:StartRecordTimeTickTimer()
end

---设置三连按钮状态
function HallSettlement_Base_BattleItem:UpdateTripleButtonEventShow()
    local IsTripleButton = self.CurTripleButtonClickType == HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.LongPress
    for _, ButtonType in ipairs(self.CurTripleButtonTypeList) do
        -- self:OnButtonPressed_TripleButton(ButtonType, IsTripleButton)
        local ButtonInfo = HallSettlement_Base_BattleItem.Const_TripleButtonInfoList[ButtonType]
        local ButtonWidget = self.ItemBaseRoot[ButtonInfo.WidgetName]
        if ButtonWidget then
            local EventName = ""
            if IsTripleButton then
                EventName = "VXE_Btn_Pressed_Hold"
            else
                EventName = "VXE_Btn_Pressed_Hold_Done"
            end
            if ButtonWidget[EventName] then
                ButtonWidget[EventName](ButtonWidget) 
            end
        end
    end
end

---更新三连进度条展示
function HallSettlement_Base_BattleItem:UpdateTripleButtonProgressShow()
    local IsTripleButton = self.CurTripleButtonClickType == HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.LongPress
    self.ItemBaseRoot.ImgEnergyProgress:SetVisibility(IsTripleButton and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.ItemBaseRoot.Progress_Bg:SetVisibility(IsTripleButton and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

---取消触发三连按钮  
function HallSettlement_Base_BattleItem:CancelTripleButton()
    CLog("[hz] HallSettlement_Base_BattleItem 取消触发三连按钮")
    
    -- self:StopMouseLongPressProgressBar()
    self:ResetTripleButtonData()
end

---完成触发三连按钮  
function HallSettlement_Base_BattleItem:CompleteTripleButton()
    CLog("[hz] HallSettlement_Base_BattleItem 完成触发三连按钮")
    self:OnTriggerBtnEvent()
    self:ResetTripleButtonData()
end

-- 执行三连触发事件
function HallSettlement_Base_BattleItem:OnTriggerBtnEvent()
    for _, ButtonType in ipairs(self.CurTripleButtonTypeList) do
        if ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.AddFriend then
            self:OnTriggerAddFriendEvent()
        elseif ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.InviteTeam then
            self:OnTriggerInviteTeamEvent()
        elseif ButtonType == HallSettlement_Base_BattleItem.Enum_ClickButtonType.Like then
            self:OnTriggerLikeEvent()
        end
    end

    if #self.CurTripleButtonTypeList > 0 then
        local TipText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "11451")
        UIAlert.Show(TipText)
    end
end

---重置三连数据
function HallSettlement_Base_BattleItem:ResetTripleButtonData()
    self.CurTripleButtonClickType = HallSettlement_Base_BattleItem.Enum_TripleButtonClickType.None
    self.CurClickButtonType = HallSettlement_Base_BattleItem.Enum_ClickButtonType.None
    self:UpdateTripleButtonEventShow()
    self:UpdateTripleButtonProgressShow()
    self.CurTripleButtonTypeList = {}
    self:ClearTripleTimer()
end

--endregion 三连按钮相关
------------------------------------------------------- 事件相关 ---------------------------------------------------------

--- 收到邀请
function HallSettlement_Base_BattleItem:OnTeamInvite(_, InviteListInfo)
    if InviteListInfo and InviteListInfo.Invitee and InviteListInfo.Invitee.PlayerId == self.Data.PlayerId then
        self:UpdateInviteBtn()
    end
end

--- 取消邀请
function HallSettlement_Base_BattleItem:OnCancelTeamInvite(_, KeyList)
    for _,PlayerId in ipairs(KeyList) do
        if PlayerId == self.Data.PlayerId then
            self:UpdateInviteBtn()
            break
        end
    end
end

function HallSettlement_Base_BattleItem:ON_GIVE_LIKE_SUCCESS_func(_, Msg)
    CLog("[cw][debug] HallSettlement_Base_BattleItem:ON_GIVE_LIKE_SUCCESS_func(" .. string.format("%s, %s", tostring(_), tostring(Msg)) .. ")")
    print_r(Msg, "[cw][debug] ON_GIVE_LIKE_SUCCESS_func ====Msg")
    CLog("[cw][debug] self.Data.PlayerId: " .. tostring(self.Data.PlayerId))
    --点赞成功，禁用按钮
    if Msg and tonumber(Msg.TargetPlayerId) == tonumber(self.Data.PlayerId) then
        self.ItemBaseRoot:StopAnimation(self.ItemBaseRoot.vx_HotAdd)
        self:InsertTimer(Timer.NEXT_TICK, function()
            self.ItemBaseRoot:PlayAnimation(self.ItemBaseRoot.vx_HotAdd)
            self.IsLiked = true
            self:UpdateLikeBtn()
        end)
    end
end

return HallSettlement_Base_BattleItem

