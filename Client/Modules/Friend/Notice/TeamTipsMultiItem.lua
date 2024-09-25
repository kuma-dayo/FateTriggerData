--[[
    主界面 - 入队/退队 - 多人样式 - 通知 
]]

local class_name = "TeamTipsMultiItem"
local TeamTipsMultiItem = BaseClass(nil, class_name)

function TeamTipsMultiItem:OnInit()
    self.CommonHeadIconWidget = {
        self.View.WBP_CommonHeadIcon,
        self.View.WBP_CommonHeadIcon_1,
        self.View.WBP_CommonHeadIcon_2,
    }
    self.CommonHeadIconCls = {}

    self.TipsStr = {
        [FriendConst.TEAM_SHOW_TIPS_TYPE.ADD] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_TeamTipsMultiItem_Jointheteamsuccessfu"),
        [FriendConst.TEAM_SHOW_TIPS_TYPE.EXIT] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_TeamTipsMultiItem_Quittheteam"),
        [FriendConst.TEAM_SHOW_TIPS_TYPE.REJECT_INVITE] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_TeamTipsMultiItem_Refuseaninvitation"),
        [FriendConst.TEAM_SHOW_TIPS_TYPE.REJECT_APPLY] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_TeamTipsMultiItem_Rejectanapplication"),
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
function TeamTipsMultiItem:OnShow(Param)
    if not Param then
        CError("TeamTipsMultiItem:OnShow Param Error",true)
        return
    end
    
    self.Params = Param
    self:UpdateNoticeShow()
end

function TeamTipsMultiItem:OnHide()
    self:CleanAutoHideTimer()
end

function TeamTipsMultiItem:UpdateNoticeShow()
    local Type = self.Params.Type
    self.View:SetActiveWidgetStyleFlags(self.RejectType[Type] and {1} or {0})
    self.View.LbTips:SetText(StringUtil.Format(self.TipsStr[Type] or ""))

    -- 刷新队伍头像
    local MemberList = self.Params.MemberList
    if MemberList then
        local Index = 1
        for _,Member in ipairs(MemberList) do
            local ItemWidget = self.CommonHeadIconWidget[Index]
            ItemWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            local PlayerId = Member.k
            -- 更新头像展示
            local Param = {
                PlayerId = PlayerId,
                IsCaptain =  PlayerId == self.Params.LeaderId,
                ClickType = CommonHeadIcon.ClickTypeEnum.None
            }
            if not  self.CommonHeadIconCls[Index] then
                self.CommonHeadIconCls[Index] = UIHandler.New(self,ItemWidget, CommonHeadIcon,Param).ViewInstance
            else 
                self.CommonHeadIconCls[Index]:UpdateUI(Param)
            end
            Index = Index + 1
        end
        for I = Index,#self.CommonHeadIconWidget do
            self.CommonHeadIconWidget[I]:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    self:ScheduleAutoHide()
end

--[[
    提示信息 超时 关闭
]]
function TeamTipsMultiItem:ScheduleAutoHide()
    self:CleanAutoHideTimer()
    self.AutoHideTimer = Timer.InsertTimer(FriendConst.NOTICE_TIPS_DURATION,function()
        self.AutoHideTimer = nil
		self:DoClose()
	end)   
end

function TeamTipsMultiItem:CleanAutoHideTimer()
    self.SecondTick = 0
    if self.AutoHideTimer then
        Timer.RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
end

--关闭界面
function TeamTipsMultiItem:DoClose()
    self.View:RemoveFromParent()
end


return TeamTipsMultiItem