--[[
   个人信息 - 最近访客Item逻辑
]] 
local class_name = "PersonalInfoGuestItem"
local PersonalInfoGuestItem = BaseClass(nil, class_name)

function PersonalInfoGuestItem:OnInit()
    self.MsgList = {
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID,Func = Bind(self,self.OnGetPlayerBaseInfo) },
        { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_DETAIL_INFO_CHANGED,    Func = self.OnGetPlayerDetailInfo },
    }
    self.BindNodes = {
		{ UDelegate = self.View.Button.OnClicked,				Func = Bind(self,self.OnClick_JumpToPlayerInfo) },
    }
    self.SingleHeadCls = nil
end

--[[
    local Param = {
        GusetInfo
    }

    RecordInfo
    message RecentVisitorNode
    {
        int64 PlayerId = 1;                 // 访问者PlayerId
        int64 VisitorTime = 2;              // 访问时间
    }
]]
function PersonalInfoGuestItem:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function PersonalInfoGuestItem:OnHide()
end

function PersonalInfoGuestItem:UpdateUI(Param)
    self.GuestInfo = Param.GuestInfo
    if not self.GuestInfo then
        return
    end
    -- 请求玩家名字
    self.View.Text_PlayerName:SetText("")
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendGetPlayerBaseInfoReq(self.GuestInfo.PlayerId)
    -- 头像
    local Param = {
        PlayerId = self.GuestInfo.PlayerId,
        CloseOnlineCheck = true,
        CloseAutoCheckFriendShow = true,
    }
    if not self.SingleHeadCls then
        self.SingleHeadCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.SingleHeadCls:UpdateUI(Param)
    end
    
    -- 时间
    self.View.Text_Time:SetText(self:GetShowTimeStr(self.GuestInfo.VisitorTime))
end

--[[
  - 每个当地时区自然日的 23 点 59 分前：显示今天
  - 每个当地时区自然日的 23 点 59 分后：显示昨天
  - 2-3 天：3 天内
  - 3-5 天：5 天内
  - 5-7：本周
  - 7-14：上周
  - 14+：15 天前
]]
function PersonalInfoGuestItem:GetShowTimeStr(TargetTimestamp)
    local CurrentTime = GetTimestamp()
    local BaseTime = os.time({
        year = os.date("%Y", CurrentTime),
        month = os.date("%m", CurrentTime),
        day = os.date("%d", CurrentTime) - 1,
        hour = 23,
        min = 59,
        sec = 0
     })
    
    local Str = ""
    local OneDay = 3600 * 24
    local DiffTime = BaseTime - TargetTimestamp
    if DiffTime < 0 then
        Str = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PersonalInfoGuestItem_today")
    elseif DiffTime <= OneDay then
        Str = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PersonalInfoGuestItem_yesterday")
    elseif DiffTime <= 3 * OneDay then
        Str = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PersonalInfoGuestItem_Withindays")
    elseif DiffTime <= 5 * OneDay then
        Str = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PersonalInfoGuestItem_Withinfivedays")
    elseif DiffTime <= 7 * OneDay then
        Str = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PersonalInfoGuestItem_thisweek")
    elseif DiffTime <= 14 * OneDay then
        Str = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PersonalInfoGuestItem_lastweek")
    else
        Str = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PersonalInfoGuestItem_daysago")
    end
    return StringUtil.Format(Str)
end

function PersonalInfoGuestItem:OnGetPlayerBaseInfo(_,PlayerId)
    if not self.GuestInfo or self.GuestInfo.PlayerId ~= PlayerId then
        return
    end
    local PlayerData = MvcEntry:GetModel(PersonalInfoModel):GetPlayerDetailInfo(self.GuestInfo.PlayerId)
    if PlayerData then
        self.View.Text_PlayerName:SetText(PlayerData.PlayerName)
    end
end

-- 点击 打开个人信息
function PersonalInfoGuestItem:OnClick_JumpToPlayerInfo()
    self.IsJumping = true
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLookUpDetailReq(self.GuestInfo.PlayerId)
end

function PersonalInfoGuestItem:OnGetPlayerDetailInfo(TargetPlayerId)
    if self.IsJumping and self.GuestInfo.PlayerId == TargetPlayerId then
        local Param = {
            PlayerId = self.GuestInfo.PlayerId,
            SelectTabId = 1,
            OnShowParam = self.GuestInfo.PlayerId
        }
        MvcEntry:OpenView(ViewConst.PlayerInfo, Param)
        self.IsJumping = false
    end
end

return PersonalInfoGuestItem
