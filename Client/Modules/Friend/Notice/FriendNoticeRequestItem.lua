--[[
    主界面 - 好友申请通知
]]

local class_name = "FriendNoticeRequestItem"
local FriendNoticeRequestItem = BaseClass(nil, class_name)

function FriendNoticeRequestItem:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.WBP_Common_SocialBtn_YES.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnClick_GUIButton_YES) },
        { UDelegate = self.View.WBP_Common_SocialBtn_NO.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnClick_GUIButton_NO) },
        -- { UDelegate = self.View.GUIButton_Bg.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_YES.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_NO.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_Bg.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
        -- { UDelegate = self.View.GUIButton_YES.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
        -- { UDelegate = self.View.GUIButton_NO.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
	}
    self.MsgList = {
        {Model = FriendApplyModel,MsgName = FriendApplyModel.ON_OPERATE_APPLY,Func = Bind(self,self.OnApplyListChanged)}
    }
    -- self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)
    self.InputFocus = false
end

--由mdt触发调用
--[[
    Param = {
        TypeId = FriendConst.LIST_TYPE_ENUM.FRIEND_REQUEST,
        Time
        ItemInfoList = {AddFriendApplyNode}
    }
]]
function FriendNoticeRequestItem:OnShow(Param)
    if not Param or not Param.ItemInfoList or #Param.ItemInfoList <= 0 then
        CError("FriendNoticeRequestItem:OnShow Param Error",true)
        return
    end
    local ItemInfoList = Param.ItemInfoList
    self.ShowItemList = self.ShowItemList or {}
    self.ShowItemList = ListMerge(self.ShowItemList,ItemInfoList)
    if not self.IsShow then
        self:UpdateNoticeShow()
        self.IsShow = true
    end
    self:UpdateMoreIconShow()
end

function FriendNoticeRequestItem:OnRepeatShow(Param)
    self:OnShow(Param)
end

function FriendNoticeRequestItem:OnHide()
    self:CleanAutoHideTimer()
end

function FriendNoticeRequestItem:UpdateNoticeShow()
    local ItemInfo = self.ShowItemList[1]
    if not ItemInfo then
        self:DoClose()
        return
    end
    self:ScheduleAutoHide(FriendConst.NOTICE_DURATION)
    local PlayerNameStr,PlayerNameIdStr = StringUtil.SplitPlayerName(ItemInfo.PlayerName,true)
    self.View.LbPlayerName:SetText(PlayerNameStr)
    self.View.Text_Id:SetText(PlayerNameIdStr)
    --更新玩家头像
    local Param = {
        PlayerId = ItemInfo.PlayerId,
        CloseAutoCheckFriendShow = true,
        ClickType = CommonHeadIcon.ClickTypeEnum.None
    }
    if not self.CommonHeadIconHandler then
        self.CommonHeadIconHandler = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.CommonHeadIconHandler:UpdateUI(Param)
    end
    self.View.LbTitle:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendNoticeRequestItem_Friendapplication")))
    
    self:UpdateMoreIconShow()
    -- 更新段位信息
    self:UpdateRankInfo(ItemInfo)
end

function FriendNoticeRequestItem:UpdateRankInfo(Data)
    if not Data then
        return
    end
    local RankData = MvcEntry:GetModel(PersonalInfoModel):GetMaxRankDivisionInfo(Data.PlayerId)
    if not RankData then
        self.View.Image_Rank:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Text_Rank:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    local SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)
    local DivisionIconPath = SeasonRankModel:GetDivisionIconPathByDivisionId(RankData.MaxDivisionId)
    if DivisionIconPath then
        CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Rank,DivisionIconPath)
        self.View.Image_Rank:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.View.Image_Rank:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    local DivisionText = SeasonRankModel:GetDivisionNameByDivisionId(RankData.MaxDivisionId)
    self.View.Text_Rank:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.Text_Rank:SetText(DivisionText)
end

function FriendNoticeRequestItem:UpdateMoreIconShow()
    self.View.NoticeNumber:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_5"),#self.ShowItemList))
    self.View.MoreIcon:SetVisibility(#self.ShowItemList > 1 and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--[[
    提示信息 超时 关闭
]]
function FriendNoticeRequestItem:ScheduleAutoHide(Duration)
    self:CleanAutoHideTimer()
    self.AutoHideTimer = Timer.InsertTimer(1,function()
        if self.SecondTick == FriendConst.NOTICE_DURATION then
            self:CleanAutoHideTimer()
		    self:ToNext()
        else
            self.SecondTick = self.SecondTick + 1
        end
	end,true)   
end

function FriendNoticeRequestItem:CleanAutoHideTimer()
    self.SecondTick = 0
    if self.AutoHideTimer then
        Timer.RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
end


function FriendNoticeRequestItem:OnClick_GUIButton_NO()
    if self.ShowItemList and self.ShowItemList[1] then
        MvcEntry:GetCtrl(FriendCtrl):SendProto_AddFriendOperateReq(self.ShowItemList[1].PlayerId,false)
    end
    self:ToNext()
end

function FriendNoticeRequestItem:OnClick_GUIButton_YES()
    if self.ShowItemList and self.ShowItemList[1] then
        MvcEntry:GetCtrl(FriendCtrl):SendProto_AddFriendOperateReq(self.ShowItemList[1].PlayerId,true)
    end
    self:ToNext()
end

function FriendNoticeRequestItem:ToNext()
    table.remove(self.ShowItemList,1)
    self:UpdateNoticeShow()
end

function FriendNoticeRequestItem:OnApplyListChanged(_,PlayerId)
    if PlayerId then
        if PlayerId == self.ShowItemList[1].PlayerId then
            -- 已操作了同意或拒绝，跳下一个
            self:ToNext()
        else
            local DeleteIndex = 0
            for Index,ItemInfo in ipairs(self.ShowItemList) do
                if ItemInfo.PlayerId == PlayerId then
                    DeleteIndex = Index
                    break
                end
            end
            if DeleteIndex > 0 then
                table.remove(self.ShowItemList,DeleteIndex)
                self:UpdateMoreIconShow()
            end
        end
    end
end

--关闭界面
function FriendNoticeRequestItem:DoClose()
    self.IsShow = false
    MvcEntry:GetModel(FriendModel):DispatchType(FriendModel.ON_HIDE_HALL_TIPS,FriendConst.LIST_TYPE_ENUM.FRIEND_REQUEST)
    
end

-- function FriendNoticeRequestItem:GUIButton_Bg_OnHovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBgHover)
--     local Color = "1B2024"
--     CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--     CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--     CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
-- end

-- function FriendNoticeRequestItem:GUIButton_Bg_OnUnhovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)
--     local Color = "F3ECDC"
--     CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--     CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--     CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
-- end


return FriendNoticeRequestItem