local class_name = "RankSystemItem"
local RankSystemItem = BaseClass(nil, class_name)

function RankSystemItem:OnInit()
    self.MsgList = 
    {
        -- {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED, Func = self.OnGetPlayerDetailInfo},
    }
    self.BindNodes = 
    {
		{UDelegate = self.View.ListBtn.GUIButton_Main.OnClicked,Func = Bind(self, self.OnLikeClick)},
	}
end

function RankSystemItem:OnShow()

end

function RankSystemItem:OnHide()
end


function RankSystemItem:UpdateRankInfo(CurTabType)
    if not self.RankInfo then
        return
    end
    local PlayerId = self.RankInfo.Key
    self.View.ScoreText:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), self.RankInfo.Score, RankSystemModel.UnitText[CurTabType].Unit))
    self.View.RankText:SetText(StringUtil.Format(self.RankInfo.Rank + 1))

    local DetailInfo = MvcEntry:GetModel(PersonalInfoModel):GetPlayerDetailInfo(PlayerId)
    if DetailInfo then
        self.View.PlayerNameText:SetText(StringUtil.Format(DetailInfo.PlayerName))
    end

    local IsSelf = MvcEntry:GetModel(UserModel):IsSelf(PlayerId)
    local Color = "#F5EFDFFF"
    if IsSelf then
        Color = "#E47A30FF"
    end
    CommonUtil.SetTextColorFromeHex(self.View.RankText, Color)
    CommonUtil.SetTextColorFromeHex(self.View.ScoreText, Color)
    CommonUtil.SetTextColorFromeHex(self.View.PlayerNameText, Color)

    local Param = {
        PlayerId = PlayerId,
        -- PlayerName = DetailInfo.PlayerName,
        -- ClickType         = CommonHeadIcon.ClickTypeEnum.None ,
        CloseAutoCheckFriendShow = true,
        CloseOnlineCheck = true,
        -- NotNeedReqPlayerInfo = true
        NeedSyncWidgets = {
            NameWidget = self.View.PlayerNameText
        }
    }
    if not self.HeadCls then
        self.HeadCls = UIHandler.New(self, self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.HeadCls:UpdateUI(Param)
    end

    self.View.ListBtn:SetVisibility(IsSelf and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
end

function RankSystemItem:OnLikeClick()
    if not self.RankInfo then
        return
    end
    self.View.ListBtn:StopAnimation(self.View.ListBtn.vx_btn_addone)
    self.View.ListBtn:PlayAnimation(self.View.ListBtn.vx_btn_addone)
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLikeHeartReq(self.RankInfo.Key)
end
---
function RankSystemItem:UpdateUI(Data, CurTabType)
    if not Data  then
        CError("RankSystemItem Param Error",true)
        return
    end
    
    self.RankInfo = Data
    self:UpdateRankInfo(CurTabType)
end

return RankSystemItem
