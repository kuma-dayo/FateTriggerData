--[[
   赛季
]] 
local class_name = "SeasonBpGoodItemLogic"
local SeasonBpGoodItemLogic = BaseClass(UIHandlerViewBase, class_name)

function SeasonBpGoodItemLogic:OnInit()
    self.TheModel = MvcEntry:GetModel(SeasonBpModel)

    self.MsgList = 
    {
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_LEVEL_UPDATE, Func = self.UpdateSwitchState },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_AWARD_LEVEL_UPDATE, Func = self.UpdateSwitchState },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_MAIN_SELECT_SPECIAL_ITEM_SHOW, Func = self.UnSelect },
	}

    self.GoodsItemList = {}
    self.Index2WidgetList = {}
end

--[[
    {
        SeasonBpId
        Level
        ItemList 
                    -- local Item = {
                    --     ItemId = Id,
                    --     ItemNum = ItemNum * Count,
                    -- }
    }
]]
function SeasonBpGoodItemLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function SeasonBpGoodItemLogic:OnHide()
end

function SeasonBpGoodItemLogic:UpdateUI(Param)
    if not Param then
        return
    end
    self.Param = Param

    self.View.LbLevel:SetText(tostring(self.Param.Level))
    local AllChildren = self.View.ItemListBox:GetAllChildren()
    for k,v in pairs(AllChildren) do
        v:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    for k,Item in ipairs(self.Param.ItemList) do
        if not self.Index2WidgetList[k] then
            local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/Components/WBP_CommonItemIcon.WBP_CommonItemIcon")
            local Widget = NewObject(WidgetClass, self.View)
            self.View.ItemListBox:AddChild(Widget)
            self.Index2WidgetList[k] = Widget
        end
        self.Index2WidgetList[k].Padding.Right = 0
        if k ~= #self.Param.ItemList then
            self.Index2WidgetList[k].Padding.Right = 2
        end
        self.Index2WidgetList[k]:SetPadding(self.Index2WidgetList[k].Padding)
        self.Index2WidgetList[k]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self:UpdateSwitchState();
end

--[[
    更新状态显示
    
    未解锁
    待领取
    已领取
]]
function SeasonBpGoodItemLogic:UpdateSwitchState()
    local PassStatus = self.TheModel:GetPassStatus()
    local CfgBpReward = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.Level,Cfg_SeasonBpRewardCfg_P.SeasonBpId},{self.Param.Level,self.Param.SeasonBpId})
    local NextCfgBpReward = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.Level,Cfg_SeasonBpRewardCfg_P.SeasonBpId},{self.Param.Level + 1,self.Param.SeasonBpId})

    local IsLock = false
    local IsGot = false
    local CanGet = false
    if CfgBpReward[Cfg_SeasonBpRewardCfg_P.TypeId] ~= 0 then
        if PassStatus.PassType == Pb_Enum_PASS_TYPE.BASIC then
            IsLock = true
        else
            IsGot = PassStatus.AdvanceAwardeLevel >= CfgBpReward[Cfg_SeasonBpRewardCfg_P.Level] 
        end
    else
        IsGot = PassStatus.BasicAwardedLevel >= CfgBpReward[Cfg_SeasonBpRewardCfg_P.Level] 
    end
    -- CWaring("IsLock:" .. (IsLock and "1" or "0"))
    local AlreadyAchieve = PassStatus.Level >= CfgBpReward[Cfg_SeasonBpRewardCfg_P.Level] 
    local IsCurShow = PassStatus.Level == CfgBpReward[Cfg_SeasonBpRewardCfg_P.Level]
    local Path1 = "Texture2D'/Game/Arts/UI/2DTexture/Season/T_Season_Gift_Progress_Dot_Show.T_Season_Gift_Progress_Dot_Show'"
    local Path2 = "Texture2D'/Game/Arts/UI/2DTexture/Season/T_Season_Gift_Progress_Dot_Get.T_Season_Gift_Progress_Dot_Get'"
    local Path = IsCurShow and Path1 or Path2
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Img_Pro_Dot, Path)
    
    self.View.Img_Bar_Line:SetVisibility((IsCurShow or not AlreadyAchieve) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)--进度条后端粗线
    local ShowFrontLine = not AlreadyAchieve and string.len(CfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemTinyIconPath]) > 0
    self.View.Img_Bar_Line_1:SetVisibility(ShowFrontLine and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)--进度条前端粗线
    local HexColor = "#1B2024"
    local Opacity = 0.6
    --进度条只有空和满之分，满的时候不同进度值（应当理解为进度值为1）是为了视觉效果
    if PassStatus.Level >= self.Param.Level then
        HexColor = "#F5EFDF"
        Opacity = 1
        if PassStatus.Level > self.Param.Level then
            if NextCfgBpReward and string.len(NextCfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemTinyIconPath]) > 0 then
                self.View.GUIProgressBar_Exp:SetPercent(0.93)
            else
                self.View.GUIProgressBar_Exp:SetPercent(1)
            end
        else
            --当前展示的奖励进度条为1视觉上会多出一部分
            if #self.Param.ItemList > 1 then
                --有两个奖励道具，按照UX要求这里设置进度条为0.95视觉效果最好
                self.View.GUIProgressBar_Exp:SetPercent(0.95)
            else
                --只有一个奖励道具，按照UX要求这里设置进度条为0.9视觉效果最好
                self.View.GUIProgressBar_Exp:SetPercent(0.9)
            end
        end
    else
        self.View.GUIProgressBar_Exp:SetPercent(0)
    end
    CommonUtil.SetBrushTintColorFromHex(self.View.Img_Bar_Line, HexColor, Opacity)
    self.View.Img_Pro_Dot:SetVisibility(AlreadyAchieve and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.LbLevel:SetVisibility((IsCurShow or not AlreadyAchieve) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    if AlreadyAchieve and not IsGot then
        CanGet = true
    end
    self.View.Image_RedDot:SetVisibility(CanGet and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    for k,Item in ipairs(self.Param.ItemList) do
        local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = Item.ItemId,
            ItemNum = Item.ItemNum,
            ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
            ShowCount = true,
            ClickCallBackFunc = Bind(self,self.OnSeasonItemClick,Item.ItemId),
            IsGot = IsGot,
            IsLock = IsLock,
            IsCanGet = CanGet
        }
        if not self.GoodsItemList[k] then
            self.GoodsItemList[k] = UIHandler.New(self,self.Index2WidgetList[k],CommonItemIcon,IconParam).ViewInstance
        else
            self.GoodsItemList[k]:UpdateUI(IconParam)
        end
    end

    self.View.WidgetSwitcher:SetActiveWidgetIndex(CfgBpReward[Cfg_SeasonBpRewardCfg_P.TypeId] == Pb_Enum_PASS_TYPE.BASIC and 0 or 1)
    -- self.View.Free:SetVisibility(CfgBpReward[Cfg_SeasonBpRewardCfg_P.TypeId] == Pb_Enum_PASS_TYPE.BASIC and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)--删除

end

function SeasonBpGoodItemLogic:OnSeasonItemClick(ItemId)
    local NeedReqReward = false
    local PassStatus = self.TheModel:GetPassStatus()
    local CfgBpReward = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.Level,Cfg_SeasonBpRewardCfg_P.SeasonBpId},{self.Param.Level,self.Param.SeasonBpId})
    if PassStatus.Level >= self.Param.Level then
        if CfgBpReward[Cfg_SeasonBpRewardCfg_P.TypeId] ~= 0 then
            if PassStatus.AdvanceAwardeLevel < self.Param.Level and PassStatus.PassType ~= Pb_Enum_PASS_TYPE.BASIC then
                NeedReqReward = true
            end
        else
            if PassStatus.BasicAwardedLevel < self.Param.Level then
                NeedReqReward = true
            end
        end
    end
    if NeedReqReward then
        --TODO 申请领取奖励
        MvcEntry:GetCtrl(SeasonBpCtrl):SendProto_RecvPassRewardReq()
    else
        --TODO 切换当前展示
        self.TheModel:DispatchType(SeasonBpModel.ON_SEASON_BP_MAIN_SELECT_ITEM_SHOW,{ItemId = ItemId,Level = self.Param.Level})
    end
end

function SeasonBpGoodItemLogic:Select(CurSelectItemId)
    for k,HandlerView in ipairs(self.GoodsItemList) do
        if HandlerView:GetItemId() == CurSelectItemId then
            HandlerView:SetIsSelect(true,true)
        else
            HandlerView:SetIsSelect(false,true)
        end
    end
    -- self.View.GUIButton_50:SetIsEnabled(false)
end

function SeasonBpGoodItemLogic:UnSelect()
    for k,HandlerView in ipairs(self.GoodsItemList) do
        HandlerView:SetIsSelect(false,true)
    end
    -- self.View.GUIButton_50:SetIsEnabled(true)
end


return SeasonBpGoodItemLogic
