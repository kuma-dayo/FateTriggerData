--[[
    通用的CommonEntryIcon控件
]]
local class_name = "CommonEntryIcon"
CommonEntryIcon = CommonEntryIcon or BaseClass(nil, class_name)

CommonEntryIcon.UMGPath = '/Game/BluePrints/UMG/OutsideGame/Hall/WBP_Hall_ActivityEntrance.WBP_Hall_ActivityEntrance'

function CommonEntryIcon:OnInit()
    self.MsgList =
    {
		{Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_BANNERLIST_CHANGE, Func = Bind(self, self.OnBannerChanged)},
		{Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE, Func = Bind(self, self.OnAcChanged)},
        {Model = InputModel,MsgName = ActionPressed_Event(ActionMappings.MouseScrollUp),Func = Bind(self, self.OnMouseScrollUp)},
        {Model = InputModel,MsgName = ActionPressed_Event(ActionMappings.MouseScrollDown),Func = Bind(self, self.OnMouseScrollDown)},
    }

    self.BindNodes =
    {
		{ UDelegate = self.View.Btn_Entrance.OnClicked,				    Func = Bind(self, self.OnCicked) },
		{ UDelegate = self.View.Btn_State.OnClicked,				    Func = Bind(self, self.OnCicked) },
		{ UDelegate = self.View.Btn_State.OnPressed,				    Func = Bind(self, self.OnBtnPress) },
		{ UDelegate = self.View.Btn_State.OnReleased,				    Func = Bind(self, self.OnBtnReleased) },
        { UDelegate = self.View.Btn_State.OnHovered,				    Func = Bind(self, self.OnHovered) },
        { UDelegate = self.View.Btn_State.OnUnhovered,				    Func = Bind(self, self.OnUnhovered) },
	}
    ---@type ActivityModel
    self.AcModel = MvcEntry:GetModel(ActivityModel)
    self.ActivityBannerSwitchTime = CommonUtil.GetParameterConfig(ParameterConfig.ActivityBannerSwitchTime, 3000)/1000

    local TypeTabParam = {
        ClickCallBack = Bind(self, self.OnTypeBtnClick),
        HideInitTrigger = true
    }
    TypeTabParam.ItemInfoList = {}
    for index = 1, 3 do
        local TabItemInfo = {
            Id = index,
            Widget = self.View["WBP_Common_TabItem_"..index],
        }
        TypeTabParam.ItemInfoList[index] = TabItemInfo
    end
    self.TabListCls = UIHandler.New(self, self.View.MenuTabs, CommonMenuTab, TypeTabParam).ViewInstance
end

--- OnShow
---@param Params number
function CommonEntryIcon:OnShow(Param)
    self.Param = Param
    self:OnUpdateUI()
end

function CommonEntryIcon:OnManualShow()
    self:OnUpdateUI()
end

function CommonEntryIcon:OnUpdateUI()
    if not self.Param then
        CWaring("CommonEntryIcon:OnShow Param is nil")
        return
    end
    self.EntryId = self.Param.EntryId
    ---@type EntryData
    local EntryData = self.AcModel:GetEntryData(self.EntryId)
    if not EntryData then
        CWaring("CommonEntryIcon:OnShow EntryData is nil , EntryId:"..self.EntryId)
        return
    end

    self.View.Text_Name:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), EntryData:GetEntryText()))
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_BtnIcon, EntryData:GetEntryIcon())

    self:UpdateUI(true)

    self:RegCommonRedDot()
end

function CommonEntryIcon:RegCommonRedDot()
    --TODO:通用 红点 控件
    local RedDotKey = "Activity"
    local RedDotSuffix = ""
    if self.RedDotStateInstance == nil then
        if self.View.WBP_RedDotFactory then
            self.RedDotStateInstance = UIHandler.New(self, self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance    
        end
    else 
        self.RedDotStateInstance:ChangeKey(RedDotKey, RedDotSuffix)
    end  
    -- if self.RedDotEntranceInstance == nil then
    --     if self.View.Btn_Entrance.WBP_RedDotFactory then
    --         self.RedDotEntranceInstance = UIHandler.New(self, self.View.Btn_Entrance.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance    
    --     end
    -- else 
    --     self.RedDotEntranceInstance:ChangeKey(RedDotKey, RedDotSuffix)
    -- end  
end

-- 红点触发逻辑
function CommonEntryIcon:InteractRedDot()
    if self.RedDotStateInstance then
        self.RedDotStateInstance:Interact()
    end
    
    if self.RedDotEntranceInstance then
        self.RedDotEntranceInstance:Interact()
    end
end

function CommonEntryIcon:PlayBannerAnimation(IsBack)
    -- print("CommonEntryIcon:PlayBannerAnimation", IsBack)

    if not CommonUtil.IsValid(self.View) then
        self:ClearAutoTimer()
        return
    end
    if not self.BannerList or #self.BannerList <= 1 then
        return
    end

    IsBack = IsBack or false
    self.IsAnimation = true
    if IsBack then
        self.CurTabIndex = self.CurTabIndex - 1
        if self.CurTabIndex < 1 then
            self.CurTabIndex = #self.BannerList
        end
        self.View:VXE_Panel_Slide_Reverse()
        -- self.View:PlayAnimation(self.View.vx_slide_reverse)
        self.View.vx_slide_reverse:UnbindAllFromAnimationFinished(self.View)
        self.View.vx_slide_reverse:BindToAnimationFinished(self.View, function()
            self:AddAutoAnimationTimer()
        end)
    else
        self.CurTabIndex = self.CurTabIndex + 1
        if self.CurTabIndex > #self.BannerList then
            self.CurTabIndex = 1
        end
        self.View:VXE_Panel_Slide()
        -- self.View:PlayAnimation(self.View.vx_slide)
        self.View.vx_slide:UnbindAllFromAnimationFinished(self.View)
        self.View.vx_slide:BindToAnimationFinished(self.View, function()
            self:AddAutoAnimationTimer()
        end)
    end

    -- print("CommonEntryIcon:PlayBannerAnimation", self.CurTabIndex)

    if self.TabListCls then
        local BannerId = self.BannerList[self.CurTabIndex]
        if BannerId then
            self.TabListCls:OnTabItemClick(self.CurTabIndex)
        end
    end

    self:UpdateBanerShow(self.View.Panel_Normal_Main, self.CurTabIndex)
    self:UpdateBanerShow(self.View.Panel_Normal, self.LastTabIndex)

    self.LastTabIndex = self.CurTabIndex
end

function CommonEntryIcon:UpdateBanerShow(Widget,Index)
    local BannerId = self.BannerList[Index]
    if not BannerId then
        return
    end
    local TBannerData = self.AcModel:GetBannerData(BannerId)
    if not TBannerData then
        return
    end
    Widget.RichText_Normal:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), TBannerData:GetBannerText()))
    CommonUtil.SetBrushFromSoftObjectPath(Widget.Image_Activity_Normal,TBannerData:GetBannerImg())
end

function CommonEntryIcon:UpdateTabList()
    if not self.BannerList or #self.BannerList < 1 then
        self.View.MenuTabs:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.View.MenuTabs:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    for index = 1, 3 do
        self.TabListCls:SetTabItemVisibility(index, index <= #self.BannerList)
    end

    local BannerId = self.BannerList[self.CurTabIndex]
    if BannerId then
        self.TabListCls:OnTabItemClick(self.CurTabIndex)
    end
end

function CommonEntryIcon:OnHide()
    self:ClearAutoTimer()
    self.RedDotStateInstance = nil
    self.RedDotEntranceInstance = nil
end
function CommonEntryIcon:OnTypeBtnClick()
end

function CommonEntryIcon:OnCicked()
    if self.IsSlide then
        return
    end
    -- CError("======================OnCicked")

    local IconName = "活动入口"
    local FctTab = 11
    local AttachAcId = nil
    if self.BannerList then
        local BannerIdStr = self.BannerList[self.CurTabIndex]
        if BannerIdStr then
            local Acid, _ = self.AcModel:ConvertStr2AcidAndBannerId(BannerIdStr)
            AttachAcId = Acid
            IconName = "活动Banner"
            FctTab = 10
        end
    end

    local IconData = {
        icon_name = IconName,
        fct_type = ViewConst.Hall, --点击来源
        fct_tab = FctTab,
        click_count = 1
    }

    MvcEntry:GetModel(EventTrackingModel):ReqIconClicked(IconData)

    MvcEntry:GetCtrl(ActivityCtrl):OpenActivityByEntry(self.EntryId, AttachAcId)

    self:AddAutoAnimationTimer()

    self:InteractRedDot()
end


function CommonEntryIcon:OnBtnPress()
    -- CError("======================OnBtnPress")
    self.BeginSlide = false
    self.DragUp = nil
    local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
    local _,CurViewPortPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(self.View, MousePos)
    self.BeginClickMousePos = CurViewPortPos
    self:HandleUserDragTimer()
    self:ClearAutoTimer()
end

function CommonEntryIcon:HandleUserDragTimer()
    self:ClearUserDragTimer()
    self.UserDragTimer = Timer.InsertTimer(Timer.NEXT_TICK,function()
        local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform()
        local _,NewMousePos = UE.USlateBlueprintLibrary.AbsoluteToViewport(self.View, MousePos)
        -- print("======================HandleUserDragTimer", NewMousePos)
        if self.BeginClickMousePos - NewMousePos == UE.FVector2D(0, 0) then
            return
        end
        -- print("======================HandleUserDragTimer", self.BeginClickMousePos)
        if not self.BeginSlide then
            self.BeginSlide = true
        end

        if not self.BannerList or #self.BannerList <= 1 then
            self:ClearUserDragTimer()
            return
        end

        local Diff = NewMousePos - self.BeginClickMousePos
        Diff.Y = 0
        local FixPos = 0
        Diff.X = Diff.X > 0 and Diff.X + FixPos or Diff.X - FixPos
        Diff.X = math.min(Diff.X, self.View.ENTRY_PANNEL_WIDTH)
        Diff.X = math.max(Diff.X, -self.View.ENTRY_PANNEL_WIDTH)
        local DragUp = Diff.X > 0
        if self.DragUp ~= DragUp then
            local TempTabIndex
            if DragUp then
                TempTabIndex = self.CurTabIndex - 1
                if TempTabIndex < 1 then
                    TempTabIndex = #self.BannerList
                end
            else
                TempTabIndex = self.CurTabIndex + 1
                if TempTabIndex > #self.BannerList then
                    TempTabIndex = 1
                end
            end
            self:UpdateBanerShow(self.View.Panel_Normal, TempTabIndex)
            self.DragUp = DragUp
        end
        -- CError("======================UserDragTimer"..Diff.X)

        if self.View.Panel_Normal_Main:GetVisibility() ~= UE.ESlateVisibility.SelfHitTestInvisible then
            self.View.Panel_Normal_Main:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
        if self.View.Panel_Normal:GetVisibility() ~= UE.ESlateVisibility.SelfHitTestInvisible then
            self.View.Panel_Normal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
        self.View.Panel_Normal_Main:SetRenderTranslation(Diff)
        self.View.Panel_Normal_Main:SetRenderOpacity(1)
        local DiffValue = Diff.X > 0 and -self.View.ENTRY_PANNEL_WIDTH or self.View.ENTRY_PANNEL_WIDTH
        Diff.X = Diff.X + DiffValue
        self.View.Panel_Normal:SetRenderTranslation(Diff)
        self.View.Panel_Normal:SetRenderOpacity(1)
    end, true)
end

function CommonEntryIcon:ClearUserDragTimer()
    -- CError("======================ClearUserDragTimer")
    if self.UserDragTimer then
        Timer.RemoveTimer(self.UserDragTimer)
    end
    self.UserDragTimer = nil
end

function CommonEntryIcon:ClearAutoTimer()
    if self.AutoTimer then
        Timer.RemoveTimer(self.AutoTimer)
    end
    self.AutoTimer = nil
end

function CommonEntryIcon:AddAutoAnimationTimer()
    print("CommonEntryIcon:AddAutoAnimationTimer")
    self.IsAnimation = false
    self:ClearAutoTimer()
    if self.BannerList and #self.BannerList > 1 then
        self.AutoTimer = Timer.InsertTimer(self.ActivityBannerSwitchTime,function()
            self:PlayBannerAnimation()
        end, true)
    end
end

function CommonEntryIcon:OnBtnReleased()
    -- CError("======================OnBtnReleased")
    if self.BeginSlide then
        self.IsSlide = true
        self.BeginSlide = false
        -- CError("======================OnBtnReleased Diff"..Diff.X)
        self:PlayBannerAnimation(self.DragUp)
    else
        self.IsSlide = false
    end
    self:ClearUserDragTimer()
end

function CommonEntryIcon:OnHovered()
    self.IsHovered = true
end
function CommonEntryIcon:OnUnhovered()
    self.IsHovered = false
end

function CommonEntryIcon:OnBannerChanged(Data)
    self:UpdateUI()
end

function CommonEntryIcon:UpdateUI(Init)
    print("CommonEntryIcon:UpdateUI", Init)
    self.BannerList = {}

    local BannerList = self.AcModel:GetShowBannerList(self.EntryId)
    if not BannerList then
        self.View:SetCusWidgetState(true)
        return
    end

    for i = 1, 3 do
        if BannerList[i] then
            table.insert(self.BannerList, BannerList[i])
        end
    end

    print_r(self.BannerList, "CommonEntryIcon:UpdateTabList")

    self.CurTabIndex = 1
    self.LastTabIndex = self.CurTabIndex

    self:UpdateTabList()

    local AnimationFinishedFunc = function()
        print("CommonEntryIcon:AnimationFinishedFunc")
        self:AddAutoAnimationTimer()
    end

    if not self.BannerList or #self.BannerList < 1 then
        self.View:SetCusWidgetState(true)
        AnimationFinishedFunc()
    else
        self.View:SetCusWidgetState(false)
        self:UpdateBanerShow(self.View.Panel_Normal_Main, self.CurTabIndex)
        if Init then
            self:PlayDynamicEffectOnShow(true)
            -- self.View:PlayAnimation(self.View.vx_hall_activity_in)
            self.View.vx_hall_activity_in:UnbindAllFromAnimationFinished(self.View)
            self.View.vx_hall_activity_in:BindToAnimationFinished(self.View, function()
                AnimationFinishedFunc()
            end)
        else
            AnimationFinishedFunc()
        end
    end

    self.IsSlide = false
end

function CommonEntryIcon:OnAcChanged()
end

function CommonEntryIcon:OnMouseScrollUp()
    if self.IsAnimation or not self.IsHovered then
        return
    end
    self:PlayBannerAnimation(true)
end

function CommonEntryIcon:OnMouseScrollDown()
    if self.IsAnimation or not self.IsHovered then
        return
    end
    self:PlayBannerAnimation(false)
end

--[[
    播放显示退出动效
]]
function CommonEntryIcon:PlayDynamicEffectOnShow(InIsOnShow)
    print("CommonEntryIcon:PlayDynamicEffectOnShow", InIsOnShow)
    if InIsOnShow then
        if self.View.VXE_Hall_Activity_In then
            self.View:VXE_Hall_Activity_In()
        end
    else
        if self.View.VXE_Hall_Activity_Out then --退出暂时没有处理
            self.View:VXE_Hall_Activity_Out()
        end
    end
end

return CommonEntryIcon
