--[[
    好感度-思维密匣页签
]]
local class_name = "FavorabilityTabPlot"
local FavorabilityTabPlot = BaseClass(UIHandlerViewBase, class_name)

FavorabilityTabPlot.MenuTabKeyEnum = {
    Plot = 1, -- 剧情
    Items = 2, -- 道具
}
function FavorabilityTabPlot:OnInit()
    self.BindNodes = {
    	{ UDelegate = self.View.WBP_ReuseList_ChapterList.OnPreUpdateItem,	Func = Bind(self,self.WBP_ReuseList_ChapterList_OnPreUpdateItem) },
		{ UDelegate = self.View.WBP_ReuseList_ChapterList.OnUpdateItem,	Func = Bind(self,self.WBP_ReuseList_ChapterList_OnUpdateItem) },
		{ UDelegate = self.View.Btn_Left.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnSwitchItem, -1) },
		{ UDelegate = self.View.Btn_Right.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnSwitchItem, 1) },
	}

	self.MsgList = {
        {Model = FavorabilityModel, MsgName = FavorabilityModel.FAVOR_STORY_UPDATED,	Func = Bind(self,self.UpdateShowList) },
        {Model = TaskModel, MsgName = TaskModel.TASK_ACCEPT_NOTIFY,	Func = Bind(self,self.UpdateShowList) },
		{Model = InputModel,MsgName = ActionPressed_Event(ActionMappings.MouseScrollUp),Func = Bind(self, self.OnMouseScrollUp)},
        {Model = InputModel,MsgName = ActionPressed_Event(ActionMappings.MouseScrollDown),Func = Bind(self, self.OnMouseScrollDown)},
	}
	--- @type HeroModel
    self.HeroModel = MvcEntry:GetModel(HeroModel)
    --- @type FavorabilityModel
    self.FavorModel = MvcEntry:GetModel(FavorabilityModel)


	self.ContentWidget = {
        [FavorabilityTabPlot.MenuTabKeyEnum.Plot] = self.View.Content_Plot,
        [FavorabilityTabPlot.MenuTabKeyEnum.Items] = self.View.Content_Items,
    }

	local MenuTabParam = {
        ItemInfoList = {
            {
                Id = FavorabilityTabPlot.MenuTabKeyEnum.Plot,
                LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityTabPlot_SubTabPlot_Btn")
            },
            {
                Id = FavorabilityTabPlot.MenuTabKeyEnum.Items,
                LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityTabPlot_SubTabItems_Btn")
            },
           
        },
        ClickCallBack = Bind(self, self.OnMenuBtnClick),
        HideInitTrigger = true,
        IsOpenKeyboardSwitch2 = true
    }
    self.MenuTabListCls = UIHandler.New(self, self.View.WBP_Common_TabUp_03, CommonMenuTabUp, MenuTabParam).ViewInstance

	self.MaxItemNum = 5
    self:InitItemPos()
end

-- 记录五个初始位置
function FavorabilityTabPlot:InitItemPos()
    self.ItemPos = {}
    for I = 1,self.MaxItemNum do
        local Widget = self.View["Item_"..I]
        if Widget then
            self.ItemPos[I] = Widget.Slot:GetPosition()
        end
        local ShowWidget = self.View["WBP_Favorability_TaskItem_"..I]
        if ShowWidget then
            ShowWidget.GUIImage_Selected:SetVisibility(I == 1 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
    end
end

--[[
    Param = {
		HeroId
		SetSwitchBtnVisibleFunc
        SetAvatarVisibleFunc
        TabKey
    }
]]
function FavorabilityTabPlot:OnShow(Param)
	if not (Param and Param.HeroId) then
		return
	end
	self.HeroId = Param.HeroId
	self.SetSwitchBtnVisibleFunc = Param.SetSwitchBtnVisibleFunc
    self.SetAvatarVisibleFunc = Param.SetAvatarVisibleFunc
	self:UpdateShowList()
    self:UpdateItemsPanel()
    local TabKey = Param.TabKey or FavorabilityTabPlot.MenuTabKeyEnum.Plot
    self.MenuTabListCls:Switch2MenuTab(TabKey,true)
end

function FavorabilityTabPlot:OnHide()
	if self.SetSwitchBtnVisibleFunc then
        self.SetSwitchBtnVisibleFunc(false)
    end
end

function FavorabilityTabPlot:OnManualHide()
    if self.SetSwitchBtnVisibleFunc then
        self.SetSwitchBtnVisibleFunc(false)
    end
    if self.SetAvatarVisibleFunc then
        self.SetAvatarVisibleFunc(true)
    end
end

-- 更新剧情列表
function FavorabilityTabPlot:UpdateShowList()
	local HeroStoryList = self.FavorModel:GetHeroStoryShowList(self.HeroId)
	if not HeroStoryList then
		CError("FavorabilityTabPlot GetHeroStoryList Error For HeroId = "..self.HeroId)
		return
	end
	self.HeroStoryList = HeroStoryList
	self.View.WBP_ReuseList_ChapterList:Reload(#HeroStoryList)
end

function FavorabilityTabPlot:WBP_ReuseList_ChapterList_OnPreUpdateItem(_, Index)
	local FixIndex = Index + 1
	local StoryCfg = self.HeroStoryList[FixIndex]
	if not StoryCfg then
		return
	end
	
	local IsKeyPart = StoryCfg[Cfg_FavorStoryConfig_P.IsKeyPart]
	if IsKeyPart then
		self.View.WBP_ReuseList_ChapterList:ChangeItemClassForIndex(Index,"")
	else
		self.View.WBP_ReuseList_ChapterList:ChangeItemClassForIndex(Index,"SubItem")
	end
end

function FavorabilityTabPlot:WBP_ReuseList_ChapterList_OnUpdateItem(_, Widget,Index)
	local FixIndex = Index + 1
	local StoryCfg = self.HeroStoryList[FixIndex]
	if not StoryCfg then
		return
	end
	local IsKeyPart = StoryCfg[Cfg_FavorStoryConfig_P.IsKeyPart]
	if IsKeyPart then
		self:UpdateMainTypeWidget(Widget,FixIndex,StoryCfg)
	else
		self:UpdateSubTypeWidget(Widget,FixIndex,StoryCfg)
	end
end

-- 主段落类型
function FavorabilityTabPlot:UpdateMainTypeWidget(Widget,FixIndex,StoryCfg)
	-- Widget.TopPaddingBox:SetVisibility(FixIndex == 1 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
	Widget.Text_ChapterNum:SetText(string.format("%02d",StoryCfg[Cfg_FavorStoryConfig_P.PartIndexStr]))
	Widget.Text_ChapterName:SetText(StringUtil.Format(StoryCfg[Cfg_FavorStoryConfig_P.PartName]))
	local PartId = StoryCfg[Cfg_FavorStoryConfig_P.PartId]
	local Status = self.FavorModel:GetPartStatus(self.HeroId,PartId)
	Widget.GUIButton_List.OnClicked:Clear()
	Widget.TipsItem:SetVisibility(UE.ESlateVisibility.Collapsed)
	
	local Type = StoryCfg[Cfg_FavorStoryConfig_P.Type]
	if Status ~= FavorabilityConst.STORY_STATUS.LOCK then
		Widget.GUIButton_List:SetVisibility(UE.ESlateVisibility.Visible)
		Widget.GUIButton_List.OnClicked:Add(self.View,Bind(self,self.PlayDialog,StoryCfg))
		Widget.WidgetSwitcher_StateIcon:SetActiveWidget(Widget.ImgIcon_Play)
		if Status == FavorabilityConst.STORY_STATUS.COMPLETED then
			-- 已完成
			if Widget.VXE_List_Completed then
				Widget:VXE_List_Completed()
			end
		else
			-- 进行中
			if Type == FavorabilityConst.STORY_TYPE.TASK then
				local TaskModel =  MvcEntry:GetModel(TaskModel)
				local TaskId = StoryCfg[Cfg_FavorStoryConfig_P.TaskId]
				-- 任务类型
				local TaskData = TaskModel:GetData(TaskId)
				if not TaskData then
					-- 未接取
					if Widget.VXE_List_Doing then
						Widget:VXE_List_Doing()
					end
					Widget.Text_Completed:SetVisibility(UE.ESlateVisibility.Collapsed)
				else
					Widget.TipsItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
					if Widget.TipsItem.VXE_TIPS_STATE then
						Widget.TipsItem:VXE_TIPS_STATE()
					end
					Widget.TipsItem.Content_RichText_Tips:SetText(TaskModel:GetTaskDescription(TaskId))
					Widget.Text_Completed:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
					if TaskData.State >= Pb_Enum_TASK_TYPE_STATE.TASK_TYPE_FINISH then
						-- 任务已完成，好感度未上报完成
						if Widget.VXE_List_Available then
							Widget:VXE_List_Available()
						end
						Widget.Text_Completed:SetText(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityTabPlot_TaskFinish"))
					else
						if Widget.VXE_List_Doing then
							Widget:VXE_List_Doing()
						end
						Widget.Text_Completed:SetText(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_FavorabilityTabPlot_TaskDoing"))
					end
				end
			else
				Widget.TipsItem:SetVisibility(UE.ESlateVisibility.Collapsed)
				-- 剧情类型
				if Widget.VXE_List_Doing then
					Widget:VXE_List_Doing()
				end
				Widget.Text_Completed:SetVisibility(UE.ESlateVisibility.Collapsed)
			end
		end
	else
		-- 锁定
		if Widget.VXE_List_Lock then
			Widget:VXE_List_Lock()
		end
		Widget.GUIButton_List:SetVisibility(UE.ESlateVisibility.Collapsed)
		Widget.WidgetSwitcher_StateIcon:SetActiveWidget(Widget.ImgIcon_Locked)
	end
end

-- 物料类型
function FavorabilityTabPlot:UpdateSubTypeWidget(Widget,FixIndex,StoryCfg)
	if Widget.VXE_NORMAL_STATE then
		Widget:VXE_NORMAL_STATE()
	end
	Widget.Text_StoryTitle:SetText(StoryCfg[Cfg_FavorStoryConfig_P.PartName])
	Widget.GUIButton_List.OnClicked:Clear()
	Widget.GUIButton_List.OnClicked:Add(self.View,Bind(self,self.PlayDialog,StoryCfg))
end

function FavorabilityTabPlot:PlayDialog(StoryCfg)
	if not StoryCfg then
		return
	end
	MvcEntry:GetCtrl(DialogSystemCtrl):PlayStory(StoryCfg)
end

-- 更新物品界面内容
function FavorabilityTabPlot:UpdateItemsPanel()
    if not self.StoryItemCfgs then
        local StoryItemCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_StoryItemConfig,Cfg_StoryItemConfig_P.HeroId,self.HeroId)
        if not StoryItemCfgs then
            return
        end
        self.StoryItemCfgs =  StoryItemCfgs
    end
    self.ShowIndex = {}
    local ItemCount = #self.StoryItemCfgs
    if ItemCount > 5 then
        for I = 1,3 do
            self.ShowIndex[#self.ShowIndex + 1] = I
        end
        self.ShowIndex[#self.ShowIndex + 1] = ItemCount-1
        self.ShowIndex[#self.ShowIndex + 1] = ItemCount
    else
        for I = 1,ItemCount do
            self.ShowIndex[#self.ShowIndex + 1] = I
        end
    end
    self:UpdateItemShow()
end

function FavorabilityTabPlot:OnSwitchItem(ChangeIndex)
    for I,Index in ipairs(self.ShowIndex) do
        Index = Index + ChangeIndex
        if Index <= 0 then
            Index = #self.StoryItemCfgs 
        elseif Index > #self.StoryItemCfgs then
            Index = 1
        end
        self.ShowIndex[I] = Index
    end
    self:UpdateItemShow()
end

function FavorabilityTabPlot:UpdateItemShow()
    local Index = 1
    for I,ShowIndex in ipairs(self.ShowIndex) do
        local StoryItemCfg = self.StoryItemCfgs[ShowIndex]
        local ShowWidget = self.View["Item_"..I]
        
        if ShowWidget then
            ShowWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            ShowWidget.Slot:SetPosition(self.ItemPos[I])
        end

        local Widget = self.View["WBP_Favorability_TaskItem_"..I]
        if Widget and StoryItemCfg then
            self:UpdateItemWidget(Widget,StoryItemCfg)
        end
        Index = Index + 1
    end
    if #self.ShowIndex < 5 then
        self.View["Item_"..#self.ShowIndex].Slot:SetPosition(self.ItemPos[5])
    end
    while self.View["Item_"..Index] do
        self.View["Item_"..Index]:SetVisibility(UE.ESlateVisibility.Collapsed)
        Index = Index + 1
    end

    local SelectCfg = self.StoryItemCfgs[self.ShowIndex[1]]
    self.View.GUITextBlock_ItemName:SetText(SelectCfg[Cfg_StoryItemConfig_P.Name])
    local IsUnlock = self.FavorModel:IsStoryItemUnlock(self.HeroId,SelectCfg[Cfg_StoryItemConfig_P.Id])
    self.View.GUITextBlock_ItemDes:SetText(IsUnlock and SelectCfg[Cfg_StoryItemConfig_P.DesUnlock] or SelectCfg[Cfg_StoryItemConfig_P.DesLock])
end

function FavorabilityTabPlot:UpdateItemWidget(Widget,StoryItemCfg)
    CommonUtil.SetBrushFromSoftObjectPath(Widget.GUIImage_Icon,StoryItemCfg[Cfg_StoryItemConfig_P.Icon],true)
    local IsUnlock = self.FavorModel:IsStoryItemUnlock(self.HeroId, StoryItemCfg[Cfg_StoryItemConfig_P.Id])
    Widget.LockPanel:SetVisibility(IsUnlock and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
end

function FavorabilityTabPlot:OnMenuBtnClick(Id, ItemInfo, IsInit)
    self.CurTabId = Id
    if not self.ContentWidget[self.CurTabId] then
        CError("FavorabilityTabPlot Tab Without Content Widget,Id = "..self.CurTabId)
        return
    end
    self.View.WidgetSwitcher_Content:SetActiveWidget(self.ContentWidget[self.CurTabId])
    if self.SetSwitchBtnVisibleFunc then
        self.SetSwitchBtnVisibleFunc(self.CurTabId == FavorabilityTabPlot.MenuTabKeyEnum.Items)
    end
    if self.SetAvatarVisibleFunc then
        self.SetAvatarVisibleFunc(self.CurTabId == FavorabilityTabPlot.MenuTabKeyEnum.Plot)
    end
end

function FavorabilityTabPlot:OnMouseScrollUp()
    if self.CurTabId ~= FavorabilityTabPlot.MenuTabKeyEnum.Items then
        return
    end
    self:OnSwitchItem(-1)
end

function FavorabilityTabPlot:OnMouseScrollDown()
    if self.CurTabId ~= FavorabilityTabPlot.MenuTabKeyEnum.Items then
        return
    end
    self:OnSwitchItem(1)
end

return FavorabilityTabPlot
