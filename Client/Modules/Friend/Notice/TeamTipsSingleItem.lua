--[[
    主界面 - 入队/退队 - 单人样式 - 通知 
]]

local class_name = "TeamTipsSingleItem"
local TeamTipsSingleItem = BaseClass(nil, class_name)

function TeamTipsSingleItem:OnInit()
    self.TipsStr = {
        [FriendConst.TEAM_SHOW_TIPS_TYPE.ADD] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_TeamTipsSingleItem_Jointheteamsuccessfu"),
        [FriendConst.TEAM_SHOW_TIPS_TYPE.EXIT] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_TeamTipsSingleItem_Quittheteam"),
        [FriendConst.TEAM_SHOW_TIPS_TYPE.REJECT_INVITE] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_TeamTipsSingleItem_Refuseaninvitation"),
        [FriendConst.TEAM_SHOW_TIPS_TYPE.REJECT_APPLY] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_TeamTipsSingleItem_Rejectanapplication"),
        [FriendConst.TEAM_SHOW_TIPS_TYPE.ADD_FRIEND] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_TeamTipsSingleItem_Toaddfriendsaboveyou"),
    }

    self.RejectType = {
        [FriendConst.TEAM_SHOW_TIPS_TYPE.EXIT] = 1,
        [FriendConst.TEAM_SHOW_TIPS_TYPE.REJECT_INVITE] = 1,
        [FriendConst.TEAM_SHOW_TIPS_TYPE.REJECT_APPLY] = 1,
    }

end

--由mdt触发调用
--[[
    Param = {
        TipsViewType = FriendConst.TEAM_NOTICE_ITEM_TYPE, -- 单人/多人
        Type = FriendConst.TEAM_SHOW_TIPS_TYPE , -- 队伍提示类型
        -----
        Member , -- 单人样式参数
        -----
        MemberList ,  -- 多人样式参数
        LeaderId ,  -- 多人样式参数
    }
]]
function TeamTipsSingleItem:OnShow(Param)
    if not Param then
        CError("TeamTipsSingleItem:OnShow Param Error",true)
        return
    end
    
    self.Params = Param
    self:UpdateNoticeShow()
end

function TeamTipsSingleItem:OnHide()
    self:CleanAutoHideTimer()
end

function TeamTipsSingleItem:UpdateNoticeShow()
    local Type = self.Params.Type
    self.View:SetActiveWidgetStyleFlags(self.RejectType[Type] and {1} or {0})
    self.View.LbTips:SetText(StringUtil.Format(self.TipsStr[Type] or ""))
    local PlayerId = self.Params.Member.k or self.Params.Member.PlayerId
    if not PlayerId then
        CError("TeamTipsSingleItem PlayerId Error !!",true)
        return
    end
    --更新玩家头像
    local Param = {
        PlayerId = PlayerId,
        ClickType = CommonHeadIcon.ClickTypeEnum.None,
    }
    if not self.CommonHeadIconHandler then
        self.CommonHeadIconHandler = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.CommonHeadIconHandler:UpdateUI(Param)
    end
    self:ScheduleAutoHide()
end

--[[
    提示信息 超时 关闭
]]
function TeamTipsSingleItem:ScheduleAutoHide()
    self:CleanAutoHideTimer()
    self.AutoHideTimer = Timer.InsertTimer(FriendConst.NOTICE_TIPS_DURATION,function()
        self.AutoHideTimer = nil
		self:DoClose()
	end)   
end

function TeamTipsSingleItem:CleanAutoHideTimer()
    self.SecondTick = 0
    if self.AutoHideTimer then
        Timer.RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
end

--关闭界面
function TeamTipsSingleItem:DoClose()
    self.View:RemoveFromParent()
end


return TeamTipsSingleItem