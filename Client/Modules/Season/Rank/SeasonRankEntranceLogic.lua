--[[
   排位入口显示逻辑
]] 
local class_name = "SeasonRankEntranceLogic"
local SeasonRankEntranceLogic = BaseClass(UIHandlerViewBase, class_name)

function SeasonRankEntranceLogic:OnInit()
    self.MsgList = {
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID, Func = self.OnGetPlayerDetailInfo},
    }

    ---@type SeasonRankModel
    self.SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)
    ---@type PersonalInfoModel
    self.PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)
    -- 自己的玩家ID
    self.MySelfPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()

    -- 排位相关信息
    self.MaxDivisionInfo = nil
end

function SeasonRankEntranceLogic:OnShow()
    self:UpdateUI()
end

-- 个人信息更新
function SeasonRankEntranceLogic:OnGetPlayerDetailInfo(PlayerId)
    if self.MySelfPlayerId == PlayerId then
        self:UpdateUI()
    end
end

function SeasonRankEntranceLogic:OnHide()

end

function SeasonRankEntranceLogic:UpdateUI()
    self.MaxDivisionInfo = self.PersonalInfoModel:GetMaxRankDivisionInfo(self.MySelfPlayerId)
    local IsHasRank = self.MaxDivisionInfo ~= nil and true or false
    self.View:SetVisibility(IsHasRank and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if IsHasRank then
        self:UpdateRankIcon()
        self:UpdateRankName()
        self:UpdateWinPoint()
    end
end

-- 更新排位图标
function SeasonRankEntranceLogic:UpdateRankIcon()
    if self.MaxDivisionInfo then
        local DivisionIconPath = self.SeasonRankModel:GetDivisionIconPathByDivisionId(self.MaxDivisionInfo.MaxDivisionId)
        if DivisionIconPath and DivisionIconPath ~= "" then
            CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Rank, DivisionIconPath) 
        end 
    end
end

-- 更新排位名称
function SeasonRankEntranceLogic:UpdateRankName()
    if self.MaxDivisionInfo then
        local DivisionName = self.SeasonRankModel:GetDivisionNameByDivisionId(self.MaxDivisionInfo.MaxDivisionId)
        --段位名称
        self.View.TextBlock_RankName:SetText(StringUtil.Format(DivisionName))
    end
end

-- 更新胜点信息
function SeasonRankEntranceLogic:UpdateWinPoint()
    if self.MaxDivisionInfo then
        local RankEloConfig = self.SeasonRankModel:GetSeasonRankEloConfigByDivisionId(self.MaxDivisionInfo.MaxDivisionId)
        if RankEloConfig then
            -- 当前胜点
            local CurWinPoint = self.MaxDivisionInfo.WinPoint or 0
            -- 最大胜点
            local MaxWinPoint = self.SeasonRankModel:GetMaxWinPointByDivisionId(self.MaxDivisionInfo.MaxDivisionId)
            local Progress = (CurWinPoint / MaxWinPoint) or 0
            self.View.Img_Progress:GetDynamicMaterial():SetScalarParameterValue("Progress", StringUtil.FormatFloat(Progress)) 
    
            self.View.TextBlock_CurPoint:SetText(StringUtil.FormatSimple(CurWinPoint))
            self.View.TextBlock_MaxPoint:SetText(StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_6"), MaxWinPoint))
        end 
    end
end

return SeasonRankEntranceLogic
