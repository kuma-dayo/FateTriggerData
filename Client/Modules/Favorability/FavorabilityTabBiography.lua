--[[
    好感度-传记页签
]]
local class_name = "FavorabilityTabBiography"
local FavorabilityTabBiography = BaseClass(UIHandlerViewBase, class_name)

-- FavorabilityTabBiography.MenuTabKeyEnum = {
--     Biography = 1, -- 传记
--     Items = 2, -- 道具
-- }
function FavorabilityTabBiography:OnInit()
    self.MsgList = {
        -- {Model = InputModel,MsgName = ActionPressed_Event(ActionMappings.MouseScrollUp),Func = Bind(self, self.OnMouseScrollUp)},
        -- {Model = InputModel,MsgName = ActionPressed_Event(ActionMappings.MouseScrollDown),Func = Bind(self, self.OnMouseScrollDown)},
    }
    self.BindNodes = {
		-- { UDelegate = self.View.Btn_Left.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnSwitchItem, -1) },
		-- { UDelegate = self.View.Btn_Right.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnSwitchItem, 1) },
        {UDelegate = self.View.ScrollBox_Content.OnUserScrolled, Func = Bind(self, self.OnContentListUserScrolled)},
	}

    -- self.ContentWidget = {
    --     [FavorabilityTabBiography.MenuTabKeyEnum.Biography] = self.View.Content_Biography,
    --     [FavorabilityTabBiography.MenuTabKeyEnum.Items] = self.View.Content_Items,
    -- }

    -- local MenuTabParam = {
    --     ItemInfoList = {
    --         {
    --             Id = FavorabilityTabBiography.MenuTabKeyEnum.Biography,
    --             LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityTabBiography_TabBiography")
    --         },
    --         {
    --             Id = FavorabilityTabBiography.MenuTabKeyEnum.Items,
    --             LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityTabBiography_TabItems")
    --         },
           
    --     },
    --     -- CurSelectId = FavorabilityTabBiography.MenuTabKeyEnum.Biography,
    --     ClickCallBack = Bind(self, self.OnMenuBtnClick),
    --     HideInitTrigger = true,
    --     IsOpenKeyboardSwitch2 = true
    -- }
    -- self.MenuTabListCls = UIHandler.New(self, self.View.WBP_Common_TabUp_03, CommonMenuTabUp, MenuTabParam).ViewInstance
    --- @type FavorabilityModel
    self.FavorModel = MvcEntry:GetModel(FavorabilityModel)
    -- self.MaxItemNum = 5
    -- self:InitItemPos()
end

-- -- 记录五个初始位置
-- function FavorabilityTabBiography:InitItemPos()
--     self.ItemPos = {}
--     for I = 1,self.MaxItemNum do
--         local Widget = self.View["Item_"..I]
--         if Widget then
--             self.ItemPos[I] = Widget.Slot:GetPosition()
--         end
--         local ShowWidget = self.View["WBP_Favorability_TaskItem_"..I]
--         if ShowWidget then
--             ShowWidget.GUIImage_Selected:SetVisibility(I == 1 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
--         end
--     end
-- end

--[[
    Param = {
        HeroId
        TabKey
        SetSwitchBtnVisibleFunc
        SetAvatarVisibleFunc
    }
]]
function FavorabilityTabBiography:OnShow(Param)
    if not (Param and Param.HeroId) then
		return
	end
	self.HeroId = Param.HeroId
    -- self.SetSwitchBtnVisibleFunc = Param.SetSwitchBtnVisibleFunc
    -- self.SetAvatarVisibleFunc = Param.SetAvatarVisibleFunc
    self:UpdateBiographyPanel()
    -- self:UpdateItemsPanel()
    -- local TabKey = Param.TabKey or FavorabilityTabBiography.MenuTabKeyEnum.Biography
    -- self.MenuTabListCls:Switch2MenuTab(TabKey,true)
    self:OnContentListUserScrolled() --【埋点】进入界面先记录下初始值
    MvcEntry:GetModel(EventTrackingModel):SetHeroViewBegin(GetLocalTimestamp() or 0)
end

function FavorabilityTabBiography:OnHide()
    if self.SetSwitchBtnVisibleFunc then
        self.SetSwitchBtnVisibleFunc(false)
    end
end

function FavorabilityTabBiography:OnManualHide()
    if self.SetSwitchBtnVisibleFunc then
        self.SetSwitchBtnVisibleFunc(false)
    end
    if self.SetAvatarVisibleFunc then
        self.SetAvatarVisibleFunc(true)
    end
end

-- 更新传记界面内容
function FavorabilityTabBiography:UpdateBiographyPanel()
    local HeroConfig = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, self.HeroId)
    if not HeroConfig then
        CError("FavorabilityTabBiography Get HeroConfig Error",true)
        return
    end
    local HeroStoryConfig = G_ConfigHelper:GetSingleItemById(Cfg_HeroStoryConfig, self.HeroId)
    if not HeroStoryConfig then
        CError("FavorabilityTabBiography Get HeroStoryConfig Error",true)
        return
    end
    -- 图片
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImgIcon_HeroHalf, HeroConfig[Cfg_HeroConfig_P.FullBodyPNGPath],true)
    -- 姓名
    self.View.Text_Name:SetText(StringUtil.Format(HeroConfig[Cfg_HeroConfig_P.Name]))
    -- 性别
    self.View.Text_Gender:SetText(StringUtil.Format(HeroStoryConfig[Cfg_HeroStoryConfig_P.Sex]))
    -- 生日
    local Birthday = HeroStoryConfig[Cfg_HeroStoryConfig_P.Birthday]
    self.View.Text_Birthday:SetText(StringUtil.Format(Birthday))
    -- 身高
    self.View.Text_Height:SetText(StringUtil.Format("{0}cm",HeroStoryConfig[Cfg_HeroStoryConfig_P.Height]))
    -- 年龄
    self.View.Text_Age:SetText(StringUtil.Format(HeroStoryConfig[Cfg_HeroStoryConfig_P.Age]))
    -- 来自
    self.View.Text_From:SetText(StringUtil.Format(HeroStoryConfig[Cfg_HeroStoryConfig_P.Region]))
    -- 爱好
    self.View.Text_Hobby:SetText(StringUtil.Format(HeroStoryConfig[Cfg_HeroStoryConfig_P.Hobby]))
    -- 特长
    self.View.Text_Specialty:SetText(StringUtil.Format(HeroStoryConfig[Cfg_HeroStoryConfig_P.Features]))
    -- 传记标题
    self.View.Text_StoryTitle:SetText(StringUtil.Format(HeroStoryConfig[Cfg_HeroStoryConfig_P.StoryTitle]))
    -- 传记内容
    self.View.Text_Story:SetText(StringUtil.Format(HeroStoryConfig[Cfg_HeroStoryConfig_P.Story]))
end

-- -- 更新物品界面内容
-- function FavorabilityTabBiography:UpdateItemsPanel()
--     if not self.StoryItemCfgs then
--         local StoryItemCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_StoryItemConfig,Cfg_StoryItemConfig_P.HeroId,self.HeroId)
--         if not StoryItemCfgs then
--             return
--         end
--         self.StoryItemCfgs =  StoryItemCfgs
--     end
--     self.ShowIndex = {}
--     local ItemCount = #self.StoryItemCfgs
--     if ItemCount > 5 then
--         for I = 1,3 do
--             self.ShowIndex[#self.ShowIndex + 1] = I
--         end
--         self.ShowIndex[#self.ShowIndex + 1] = ItemCount-1
--         self.ShowIndex[#self.ShowIndex + 1] = ItemCount
--     else
--         for I = 1,ItemCount do
--             self.ShowIndex[#self.ShowIndex + 1] = I
--         end
--     end
--     self:UpdateItemShow()
-- end

-- function FavorabilityTabBiography:OnSwitchItem(ChangeIndex)
--     for I,Index in ipairs(self.ShowIndex) do
--         Index = Index + ChangeIndex
--         if Index <= 0 then
--             Index = #self.StoryItemCfgs 
--         elseif Index > #self.StoryItemCfgs then
--             Index = 1
--         end
--         self.ShowIndex[I] = Index
--     end
--     self:UpdateItemShow()
-- end

-- function FavorabilityTabBiography:UpdateItemShow()
--     local Index = 1
--     for I,ShowIndex in ipairs(self.ShowIndex) do
--         local StoryItemCfg = self.StoryItemCfgs[ShowIndex]
--         local ShowWidget = self.View["Item_"..I]
        
--         if ShowWidget then
--             ShowWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--             ShowWidget.Slot:SetPosition(self.ItemPos[I])
--         end

--         local Widget = self.View["WBP_Favorability_TaskItem_"..I]
--         if Widget and StoryItemCfg then
--             self:UpdateItemWidget(Widget,StoryItemCfg)
--         end
--         Index = Index + 1
--     end
--     if #self.ShowIndex < 5 then
--         self.View["Item_"..#self.ShowIndex].Slot:SetPosition(self.ItemPos[5])
--     end
--     while self.View["Item_"..Index] do
--         self.View["Item_"..Index]:SetVisibility(UE.ESlateVisibility.Collapsed)
--         Index = Index + 1
--     end

--     local SelectCfg = self.StoryItemCfgs[self.ShowIndex[1]]
--     self.View.GUITextBlock_ItemName:SetText(SelectCfg[Cfg_StoryItemConfig_P.Name])
--     local IsUnlock = self.FavorModel:IsStoryItemUnlock(self.HeroId,SelectCfg[Cfg_StoryItemConfig_P.Id])
--     self.View.GUITextBlock_ItemDes:SetText(IsUnlock and SelectCfg[Cfg_StoryItemConfig_P.DesUnlock] or SelectCfg[Cfg_StoryItemConfig_P.DesLock])
-- end

-- function FavorabilityTabBiography:UpdateItemWidget(Widget,StoryItemCfg)
--     CommonUtil.SetBrushFromSoftObjectPath(Widget.GUIImage_Icon,StoryItemCfg[Cfg_StoryItemConfig_P.Icon],true)
--     local IsUnlock = self.FavorModel:IsStoryItemUnlock(self.HeroId, StoryItemCfg[Cfg_StoryItemConfig_P.Id])
--     Widget.LockPanel:SetVisibility(IsUnlock and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
-- end

-- function FavorabilityTabBiography:OnMenuBtnClick(Id, ItemInfo, IsInit)
--     self.CurTabId = Id
--     if not self.ContentWidget[self.CurTabId] then
--         CError("FavorabilityTabBiography Tab Without Content Widget,Id = "..self.CurTabId)
--         return
--     end
--     self.View.WidgetSwitcher_Content:SetActiveWidget(self.ContentWidget[self.CurTabId])
--     if self.SetSwitchBtnVisibleFunc then
--         self.SetSwitchBtnVisibleFunc(self.CurTabId == FavorabilityTabBiography.MenuTabKeyEnum.Items)
--     end
--     if self.SetAvatarVisibleFunc then
--         self.SetAvatarVisibleFunc(self.CurTabId == FavorabilityTabBiography.MenuTabKeyEnum.Biography)
--     end
-- end

-- function FavorabilityTabBiography:OnMouseScrollUp()
--     if self.CurTabId ~= FavorabilityTabBiography.MenuTabKeyEnum.Items then
--         return
--     end
--     self:OnSwitchItem(-1)
-- end

-- function FavorabilityTabBiography:OnMouseScrollDown()
--     if self.CurTabId ~= FavorabilityTabBiography.MenuTabKeyEnum.Items then
--         return
--     end
--     self:OnSwitchItem(1)
-- end

--[[
    【埋点】记录英雄对应传记阅读进度
]]
function FavorabilityTabBiography:OnContentListUserScrolled()
    local OffsetValue = self.View.ScrollBox_Content:GetScrollOffset()
    OffsetValue = math.floor(OffsetValue)
    local ContentHeight = self.View.ScrollBox_Content:GetScrollOffsetOfEnd()
    ContentHeight = math.floor(ContentHeight)
    if ContentHeight < 1 then
        MvcEntry:GetModel(EventTrackingModel):SetHeroReadData(0, self.HeroId)
        return
    end
    local ScrollProgress = math.floor((OffsetValue / ContentHeight) * 100)
    MvcEntry:GetModel(EventTrackingModel):SetHeroReadData(ScrollProgress, self.HeroId)
end

return FavorabilityTabBiography
