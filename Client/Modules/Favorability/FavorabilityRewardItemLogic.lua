--[[
    好感度 - 灵感 - 奖励Item
]]
local class_name = "FavorabilityRewardItemLogic"
local FavorabilityRewardItemLogic = BaseClass(nil, class_name)

FavorabilityRewardItemLogic.SHOW_STATE = {
    LOCK = 1,   -- 锁定
    CAN_RECEIVE = 2, -- 可领取
    GOT = 3,   -- 已领取
}
function FavorabilityRewardItemLogic:OnInit()
    self.BindNodes = {
    	{ UDelegate = self.View.GUIButton_List.OnClicked,	Func = Bind(self,self.GUIButton_List_OnClicked) },
	}

    self.MsgList = {
        {Model = FavorabilityModel, MsgName = FavorabilityModel.FAVOR_VALUE_CHANGED, Func = Bind(self,self.OnFavorValueChanged)},
        {Model = FavorabilityModel, MsgName = FavorabilityModel.ON_RECEIVE_REWARD_SUCCESSED, Func = Bind(self,self.UpdateRewardStatus)},
    }

     ---@type FavorabilityModel
    self.FavorModel = MvcEntry:GetModel(FavorabilityModel)
    self.RewardIconWidgetList = {}
    self.RewardWidgetToIconCls = {}
    self.ShowState = FavorabilityRewardItemLogic.SHOW_STATE.LOCK
    self.FinalRewardSkinCfg = nil
end


function FavorabilityRewardItemLogic:OnShow()
end

function FavorabilityRewardItemLogic:OnHide()
end

--[[
    Param = {
        HeroId 
		RewardCfg: Cfg_FavorDropCfg
        MaxLevel
    }
]]
function FavorabilityRewardItemLogic:UpdateUI(Param)
    if not (Param and Param.HeroId and  Param.RewardCfg) then
        return
    end
    self.HeroId = Param.HeroId
    self.ShowLevel = Param.RewardCfg[Cfg_FavorDropCfg_P.Level]
    self.IsMax = self.ShowLevel == Param.MaxLevel
    self.View.Text_Level:SetText(string.format("%02d", self.ShowLevel))
    self:UpdateShowState()
    self:UpdateRewardItems(Param.RewardCfg[Cfg_FavorDropCfg_P.DropId])
    self:UpdateStateAnimate()
end

-- 更新展示状态
function FavorabilityRewardItemLogic:UpdateShowState()
    local CurLevel = self.FavorModel:GetCurFavorLevel(self.HeroId)
    if self.ShowLevel > CurLevel then
        self.ShowState = FavorabilityRewardItemLogic.SHOW_STATE.LOCK
    else
        local IsGot = self.FavorModel:IsRewardGot(self.HeroId,self.ShowLevel)
        self.ShowState = IsGot and FavorabilityRewardItemLogic.SHOW_STATE.GOT or FavorabilityRewardItemLogic.SHOW_STATE.CAN_RECEIVE
    end
end

function FavorabilityRewardItemLogic:UpdateStateAnimate()
    if self.ShowState == FavorabilityRewardItemLogic.SHOW_STATE.LOCK then
        if self.View.VXE_List_Lock then
            self.View:VXE_List_Lock()
        end
    elseif self.ShowState == FavorabilityRewardItemLogic.SHOW_STATE.CAN_RECEIVE then
        if self.View.VXE_List_Available then
            self.View:VXE_List_Available()
        end
    elseif self.ShowState == FavorabilityRewardItemLogic.SHOW_STATE.GOT then
        if self.View.VXE_List_Completed then
            self.View:VXE_List_Completed()
        end
    end
end

-- 更新奖励展示
function FavorabilityRewardItemLogic:UpdateRewardItems(DropId)
    local RewardList = MvcEntry:GetModel(DepotModel):GetItemListForDropId(DropId)
    if not RewardList or #RewardList == 0 then
        self.View.WidgetSwitcher_Reward:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.View.WidgetSwitcher_Reward:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.WidgetSwitcher_Reward:SetActiveWidget(self.IsMax and self.View.Content_Max or self.View.Content_Normal)
    local IsGot =  self.ShowState == FavorabilityRewardItemLogic.SHOW_STATE.GOT
    local IsLock =  self.ShowState == FavorabilityRewardItemLogic.SHOW_STATE.LOCK
    if self.IsMax then
        -- 满级奖励
        local FinalReward = RewardList[1]
        local ItemId = FinalReward.ItemId
        local HeroSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin, Cfg_HeroSkin_P.ItemId, ItemId)
        if not HeroSkinConfig then
            self.View.GUIImage_Photo:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.Text_SkinName:SetVisibility(UE.ESlateVisibility.Collapsed)
            return
        end
        self.FinalRewardSkinCfg = HeroSkinConfig
        self.View.GUIImage_Photo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.Text_SkinName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.Text_SkinName:SetText(HeroSkinConfig[Cfg_HeroSkin_P.SkinName])
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImage_Photo,HeroSkinConfig[Cfg_HeroSkin_P.HalfBodyHorPath])
        self.View.isLockButAvailable = IsLock    -- 蓝图变量，用于动效控制
        if IsGot or IsLock then
            self.View.WidgetSwitcher_StateIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.WidgetSwitcher_StateIcon:SetActiveWidget(IsGot and self.View.ImgIcon_Got or self.View.ImgIcon_Locked)
        else
            self.View.WidgetSwitcher_StateIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        self.View.isLockButAvailable = false    -- 蓝图变量，用于动效控制
        -- 普通奖励
        local Index = 1
        --[[
            RewardInfo = {
                ItemId = xx,
                Num = 1
            }
        ]]
        for _,RewardInfo in ipairs(RewardList) do
            local RewardWidget  = self.RewardIconWidgetList[Index]
            if not RewardWidget then
                local WidgetClass = UE.UClass.Load(CommonItemIconUMGPath)
                RewardWidget = NewObject(WidgetClass, self.View)
                if Index > 1 then
                    RewardWidget.Padding.Left = 15
                    RewardWidget:SetPadding(RewardWidget.Padding)
                end
                self.View.RewardPanel:AddChild(RewardWidget)
                self.RewardIconWidgetList[Index] = RewardWidget
            else
                RewardWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end
            local IconParam = {
                IconType = CommonItemIcon.ICON_TYPE.PROP,
                ItemId = RewardInfo.ItemId,
                ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
                HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
                IsGot = IsGot,
                IsLock = IsLock,
                ItemParentScale = self.View.Content_Normal.UserSpecifiedScale,
                ClickCallBackFunc = Bind(self,self.GUIButton_List_OnClicked)
            }
            if not (IsGot or IsLock) then
                IconParam.RightCornerTagId = CornerTagCfg.Gift.TagId
            end
            local IconCls = self.RewardWidgetToIconCls[RewardWidget]
            if not IconCls then
                IconCls = UIHandler.New(self,RewardWidget,CommonItemIcon,IconParam).ViewInstance
                self.RewardWidgetToIconCls[RewardWidget] = IconCls
            else
                IconCls:UpdateUI(IconParam)
            end
            Index = Index + 1
        end
        while self.RewardIconWidgetList[Index] do
            self.RewardIconWidgetList[Index]:SetVisibility(UE.ESlateVisibility.Collapsed)
            Index = Index + 1
        end
    end
end

function FavorabilityRewardItemLogic:GUIButton_List_OnClicked()
    if self.ShowState ~= FavorabilityRewardItemLogic.SHOW_STATE.CAN_RECEIVE then
        if self.IsMax and self.FinalRewardSkinCfg then
            local AvatarTransform = self.FavorModel:GetAvatarTransform()
            -- 皮肤预览奖励
            local Param = {
                SkinId = self.FinalRewardSkinCfg[Cfg_HeroSkin_P.SkinId],
                HeroId = self.FinalRewardSkinCfg[Cfg_HeroSkin_P.HeroId],
                Location = AvatarTransform.Mid.Location,
                Rotation = AvatarTransform.Mid.Rotation,
                FromID = ViewConst.FavorablityMainMdt,
            }
            -- 要依赖好感度的场景，修改场景注册为好感度对应的
            MvcEntry:GetCtrl(ViewRegister):RegisterVirtualLevelView(ViewConst.HeroPreView,VirtualViewConfig[ViewConst.FavorablityMainMdt].VirtualSceneId)
            MvcEntry:OpenView(ViewConst.HeroPreView,Param)
        end
        return
    end
    if not self.HeroId then
        return
    end
    -- 请求领取
    MvcEntry:GetCtrl(FavorabilityCtrl):SendProto_PlayerGetFavorLevelPrizeReq(self.HeroId)
end

-- 更新奖励展示情况
function FavorabilityRewardItemLogic:UpdateRewardStatus()
    self:UpdateShowState()    
    self:UpdateStateAnimate()
    if not self.IsMax then
        -- 非满级，需要更新Icon的状态
        for _,IconCls in pairs(self.RewardWidgetToIconCls) do
            IconCls:SetIsGot(self.ShowState == FavorabilityRewardItemLogic.SHOW_STATE.GOT)
            IconCls:SetIsLock(self.ShowState == FavorabilityRewardItemLogic.SHOW_STATE.LOCK)
        end
    else
        local IsGot =  self.ShowState == FavorabilityRewardItemLogic.SHOW_STATE.GOT
        local IsLock =  self.ShowState == FavorabilityRewardItemLogic.SHOW_STATE.LOCK
        if IsGot or IsLock then
            self.View.WidgetSwitcher_StateIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.WidgetSwitcher_StateIcon:SetActiveWidget(IsGot and self.View.ImgIcon_Got or self.View.ImgIcon_Locked)
        else
            self.View.WidgetSwitcher_StateIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function FavorabilityRewardItemLogic:OnFavorValueChanged(_,Msg)
	if Msg.FavorBeforeLevel ~= Msg.FavorAfterLevel then
        self:UpdateRewardStatus()
    end
end

return FavorabilityRewardItemLogic
