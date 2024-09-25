--[[
   排位信息item
]] 
local class_name = "SeasonRankItemLogic"
local SeasonRankItemLogic = BaseClass(UIHandlerViewBase, class_name)

function SeasonRankItemLogic:OnInit()
    self.MsgList = {

	}
    ---@type SeasonRankCtrl
    self.SeasonRankCtrl = MvcEntry:GetCtrl(SeasonRankCtrl)

    ---@type SeasonRankModel
    self.SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)
    -- 大段位相关配置信息
    ---@type SeasonBigDivisionInfo
    self.BigDivisionInfo = nil

    -- 小段位相关配置信息
    ---@type SeasonSmallDivisionInfo[]
    self.SmallDivisionInfoList = nil

    -- 此大段位是否只有一个小段位  是的话 UI需要切换显示
    self.IsOnlyOneRank = false

    -- 个人排位信息
    ---@type SeasonPersonalDivisionInfo
    self.PersonalDivisionInfo = nil

    -- 段位分布信息列表 key为唯一段位ID value为段位分布信息列表
    ---@type SeasonDistributionInfo[]
    self.DistributionInfoList = nil

    -- 奖励状态列表 table key为唯一段位ID value为服务器下发的奖励状态 
    self.RewardIdAndStatusList = nil
    
    -- 奖励item
    self.RewardItemCls = nil

    -- 小段位item的数量
    self.SmallDivisionItemNum = 4
end

--[[
    Param = { 
        -- 大段位相关配置信息 
        BigDivisionInfo
        -- 小段位相关配置信息
        SmallDivisionInfoList
    }
]]
function SeasonRankItemLogic:OnShow(Param)
    if not Param or not Param.BigDivisionInfo or not Param.SmallDivisionInfoList then
        return
    end
    self.Param = Param
    self.BigDivisionInfo = Param.BigDivisionInfo
    self.SmallDivisionInfoList = Param.SmallDivisionInfoList
    self.IsOnlyOneRank = self.BigDivisionInfo.SmallDivisionNum == 1
    ---@type DivisionFontColorInfo
    self.DivisionFontColorInfo = SeasonRankModel.Const_DivisionFontColorInfoList[self.BigDivisionInfo.BigDivisionId] 

    self:InitUI()
end

function SeasonRankItemLogic:OnHide()

end

function SeasonRankItemLogic:InitUI()
    self:UpdateRankConfigInfo()
end

-- 更新排位配置信息
function SeasonRankItemLogic:UpdateRankConfigInfo()
    local LineColor = self.DivisionFontColorInfo and self.DivisionFontColorInfo.DivisionLineColor or "#FFFFFF"
    local RankFontColor = self.DivisionFontColorInfo and self.DivisionFontColorInfo.DivisionFontColor or "#FFFFFF"

    CommonUtil.SetBrushFromSoftObjectPath(self.View.Img_RankIcon, self.BigDivisionInfo.DivisionIconPath) 
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Img_CurrentRankIcon, self.BigDivisionInfo.DivisionIconPath) 
    self.View.TextBlock_BigRank:SetText(StringUtil.Format(self.BigDivisionInfo.BigDivisionName))
    self.View.TextBlock_CurBigRank:SetText(StringUtil.Format(self.BigDivisionInfo.BigDivisionName))
    CommonUtil.SetTextColorFromeHex(self.View.TextBlock_CurBigRank, RankFontColor) 

    local IsSingle = (self.BigDivisionInfo.BigDivisionId % 2) ~= 0 
    self.View.WidgetSwitcherBg:SetActiveWidget(IsSingle and self.View.ListItemBg_One or self.View.ListItemBg_Two)
    self.View.ImgBgLine_Two:SetVisibility(self.BigDivisionInfo.IsHighestDivision and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

    self.View.WidgetSwitcher_Bar:SetActiveWidget(self.IsOnlyOneRank and self.View.VerticalBox_OnlyOne or self.View.VerticalBox_Normal)
    self.View.TextBlock_OneRank:SetText(StringUtil.Format(self.BigDivisionInfo.BigDivisionName))


    local SmallDivisionInfoList = self.SmallDivisionInfoList or {}
    CommonUtil.SetImageColorFromHex(self.View.Img_Division_Line, LineColor)
    for Index = 1, self.SmallDivisionItemNum do
        local SmallRankItem = not self.IsOnlyOneRank and self.View["WBP_Season_Rank_Short_Item_" .. Index] or nil
        local Image_Bar = self.IsOnlyOneRank and self.View["Image_BarOnlyOne_" .. Index] or self.View["Image_Bar_" .. Index]
        ---@type SeasonSmallDivisionInfo
        local SmallDivisionInfo = SmallDivisionInfoList[Index]
        local IsHasRankInfo = SmallDivisionInfo ~= nil
        if SmallRankItem then
            SmallRankItem:SetVisibility(IsHasRankInfo and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
            if SmallDivisionInfo then
                SmallRankItem.TextBlock_Rank:SetText(StringUtil.Format(SmallDivisionInfo.SmallDivisionName))   
                CommonUtil.SetTextColorFromeHex(SmallRankItem.TextBlock_Rank, RankFontColor)
            end
        end
        if Image_Bar then
            Image_Bar:SetVisibility(IsHasRankInfo and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
            if SmallDivisionInfo and SmallDivisionInfo.DivisionHistogramMaterialPath ~= "" then
                CommonUtil.SetBrushFromSoftMaterialPath(Image_Bar, SmallDivisionInfo.DivisionHistogramMaterialPath)
            end
        end
    end
end

-- 更新UI
function SeasonRankItemLogic:UpdateUI(DistributionInfoList, PersonalDivisionInfo, RewardIdAndStatusList)
    if DistributionInfoList and PersonalDivisionInfo and RewardIdAndStatusList then
        self.DistributionInfoList = DistributionInfoList
        self.PersonalDivisionInfo = PersonalDivisionInfo
        self.RewardIdAndStatusList = RewardIdAndStatusList 
        
        -- 玩家是否处于当前大段位
        self.IsCurrentBigRankLevel = self.BigDivisionInfo.BigDivisionId == self.PersonalDivisionInfo.BigDivisionId

        self:UpdateRankPeopleInfo()
        self:UpdateSelfRankInfo()
        self:UpdateRewardInfo()
    end
end

-- 更新段位人数信息
function SeasonRankItemLogic:UpdateRankPeopleInfo()
    ---@type SeasonSmallDivisionInfo[]
    local SmallDivisionInfoList = self.SmallDivisionInfoList
    local Const_MaxBarChartHeight = SeasonRankModel.Const_MaxBarChartHeight
    -- 小段位内的最大高度
    local SmallDivisionMaxHeight = 0
    if self.IsCurrentBigRankLevel then
        local OffsetHeight = 50
        -- 要计算出当前段位内最高高度的小段位 用于计算半透明图长度
        for _, SmallDivisionInfo in pairs(SmallDivisionInfoList) do
            local DistributionInfo = self.DistributionInfoList[SmallDivisionInfo.DivisionId] 
            if DistributionInfo then
                local HeightRatio = DistributionInfo.MaxDivisionPeople > 0 and (math.floor((DistributionInfo.DivisionPeople/DistributionInfo.MaxDivisionPeople)*1000))/1000 or 0
                local ImageBarHeight =  HeightRatio * Const_MaxBarChartHeight
                local MaxImageBarHeight = ImageBarHeight + OffsetHeight
                SmallDivisionMaxHeight = MaxImageBarHeight > SmallDivisionMaxHeight and MaxImageBarHeight or SmallDivisionMaxHeight
            end
        end 
    end
    for Index = 1, self.SmallDivisionItemNum do
        local Image_Bar = self.IsOnlyOneRank and self.View["Image_BarOnlyOne_" .. Index] or self.View["Image_Bar_" .. Index]
        local SmallDivisionInfo = SmallDivisionInfoList[Index]
        local IsHasRankInfo = SmallDivisionInfo and true or false
        local DistributionInfo = IsHasRankInfo and self.DistributionInfoList[SmallDivisionInfo.DivisionId] or nil
        if Image_Bar and DistributionInfo then
            local HeightRatio = DistributionInfo.MaxDivisionPeople > 0 and (math.floor((DistributionInfo.DivisionPeople/DistributionInfo.MaxDivisionPeople)*1000))/1000 or 0
            local ImageBarHeight =  HeightRatio * Const_MaxBarChartHeight
            local ImageBarMaterial = Image_Bar:GetDynamicMaterial()
            if ImageBarMaterial then
                local Line1_Length = 1
                local Line2_Length = 0
                -- 是否玩家所处段位 & 不是单独的段位 需要做特殊处理
                local IsPlayerRank = SmallDivisionInfo.DivisionId == self.PersonalDivisionInfo.CurDivisionId
                if IsPlayerRank and not self.IsOnlyOneRank and SmallDivisionMaxHeight > ImageBarHeight and SmallDivisionMaxHeight > 0 then
                    Line1_Length = math.floor((ImageBarHeight/SmallDivisionMaxHeight)*1000)/1000
                    Line2_Length = 1 - Line1_Length
                    ImageBarHeight = SmallDivisionMaxHeight
                end 
                ImageBarMaterial:SetScalarParameterValue("Line1_Length", Line1_Length)
                ImageBarMaterial:SetScalarParameterValue("Line2_Length", Line2_Length)

                local ImageSize = Image_Bar.Slot:GetSize()
                ImageSize.Y = ImageBarHeight
                Image_Bar.Slot:SetSize(ImageSize)

                -- 柱状图颜色赋值
                if self.DivisionFontColorInfo then
                    local ColorFromHex = self.DivisionFontColorInfo.BarColor
                    local ShowColor = UE.UGFUnluaHelper.FLinearColorFromHex(self.DivisionFontColorInfo.BarColor)
                    local ShowBottomColor = UE.UGFUnluaHelper.FLinearColorFromHex(self.DivisionFontColorInfo.BarBottomColor)
                    ShowColor.A = self.DivisionFontColorInfo.BarAlpha
                    ShowBottomColor.A = self.DivisionFontColorInfo.BarAlpha
                    ImageBarMaterial:SetVectorParameterValue("Line1_ColorBottom",ShowBottomColor) 
                    ImageBarMaterial:SetVectorParameterValue("Line1_ColorTop",ShowColor) 
                    ImageBarMaterial:SetVectorParameterValue("Line2_Color",ShowColor) 
                end
            end
        end
    end
end

-- 更新自己的段位信息
function SeasonRankItemLogic:UpdateSelfRankInfo()
    self.View.CurrentRank:SetVisibility(self.IsCurrentBigRankLevel and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.VerticalBox_Rank:SetVisibility(not self.IsCurrentBigRankLevel and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.Img_Bg_Show:SetVisibility(self.IsCurrentBigRankLevel and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if self.IsCurrentBigRankLevel then
        local SmallDivisionInfo = self.SmallDivisionInfoList[self.PersonalDivisionInfo.SmallDivisionId]
        if SmallDivisionInfo then
            self.View.TextBlock_CurSmallRank:SetText(StringUtil.Format(SmallDivisionInfo.SmallDivisionName))
            self.View.TextBlock_WinPoint:SetText(self.PersonalDivisionInfo.WinPoint) 
        end
    end

    for Index = 1, self.SmallDivisionItemNum do
        ---@type SeasonSmallDivisionInfo
        local SmallDivisionInfo = self.SmallDivisionInfoList[Index]
        local SmallRankItem = not self.IsOnlyOneRank and self.View["WBP_Season_Rank_Short_Item_" .. Index] or nil
        if SmallDivisionInfo and SmallRankItem then
            -- 是否玩家所处段位 & 不是单独的段位 需要做特殊处理
            local IsPlayerRank = SmallDivisionInfo.DivisionId == self.PersonalDivisionInfo.CurDivisionId
            SmallRankItem.Img_Bg_Line:SetVisibility(IsPlayerRank and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
    end
end

-- 更新奖励状态信息
function SeasonRankItemLogic:UpdateRewardInfo()
    -- 目前一个大段只有一个奖励 先这么处理 有需求后面再拓展
    local RewardSmallDivisionInfo = nil
    for _, SmallDivisionInfo in pairs(self.SmallDivisionInfoList) do
        if SmallDivisionInfo.DivisionRewardId then
            RewardSmallDivisionInfo = SmallDivisionInfo
            break
        end
    end
    if RewardSmallDivisionInfo then
        local RewardDivisionId = RewardSmallDivisionInfo.DivisionId
        local RewardStatus = self.RewardIdAndStatusList[RewardDivisionId] or Pb_Enum_EDivisionRewardStatus.Locked
        local IsGotReward = RewardStatus == Pb_Enum_EDivisionRewardStatus.Obtained
        local IsLock = RewardStatus == Pb_Enum_EDivisionRewardStatus.Locked
        -- 未领取并且当前段位等级大于奖励段位
        local IsCanGetReward = RewardStatus == Pb_Enum_EDivisionRewardStatus.Unobtained
        local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = RewardSmallDivisionInfo.DivisionRewardId or 0,
            ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
            HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
            ClickCallBackFunc = IsCanGetReward and Bind(self,self.OnRewardItemClick, RewardDivisionId) or nil,
            IsGot = IsGotReward,
            IsLock = IsLock,
        }
        if not self.RewardItemCls then
            self.RewardItemCls = UIHandler.New(self,self.View.WBP_CommonItemIcon,CommonItemIcon,IconParam).ViewInstance
        else
            self.RewardItemCls:UpdateUI(IconParam)
        end 
    else
        CError("SeasonRankItemLogic:UpdateReward RewardSmallDivisionInfo Is Nil")
    end
end

-- 奖励按钮点击
function SeasonRankItemLogic:OnRewardItemClick(RewardDivisionId)
    local CurSelectSeasonId, CurSelectRankPlayMapId = self.SeasonRankModel:GetCurSelectQueryParam()
    if CurSelectSeasonId and CurSelectRankPlayMapId and RewardDivisionId then
        self.SeasonRankCtrl:SendProto_DivisionRewardReq(CurSelectSeasonId, CurSelectRankPlayMapId, RewardDivisionId) 
    end
end

-- 获取当前段位的柱状图坐标
function SeasonRankItemLogic:GetCurRankImageBarScreenPos(DivisionId)
    local ScreenPos = UE.FVector2D(0,0)
    local ImageSize = UE.FVector2D(0,0)
    for Index = 1, self.SmallDivisionItemNum do
        local SmallDivisionInfo = self.SmallDivisionInfoList[Index]
        if SmallDivisionInfo.DivisionId == DivisionId then
            local Image_Bar = self.IsOnlyOneRank and self.View["Image_BarOnlyOne_" .. Index] or self.View["Image_Bar_" .. Index]
            if Image_Bar then
                Image_Bar:ForceLayoutPrepass()
                ImageSize = Image_Bar.Slot:GetSize()
                -- 在屏幕上的位置
                ScreenPos = UE.USlateBlueprintLibrary.LocalToAbsolute(Image_Bar:GetCachedGeometry(), UE.FVector2D(0,0)) 
                
            end
            break;
        end
    end
    return ScreenPos, ImageSize
end

return SeasonRankItemLogic
