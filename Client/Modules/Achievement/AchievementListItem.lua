local  AchievementConst = require("Client.Modules.Achievement.AchievementConst")
--- 视图控制器
local class_name = "AchievementListItem";
local AchievementListItem = BaseClass(nil, class_name);

---@type AchievementData
AchievementListItem.Data = nil

function AchievementListItem:OnInit()
    self.MsgList = 
    {
		{Model = AchievementModel, MsgName = AchievementModel.ACHIEVE_DATA_UPDATE, Func = Bind(self, self.OnAchievementUpdate)},
    }

    self.BindNodes = 
    {
		{ UDelegate = self.View.LockBtn.OnClicked,				    Func = Bind(self, self.OnCicked) },
		{ UDelegate = self.View.GetBtn.OnClicked,				    Func = Bind(self, self.OnCicked) },
        { UDelegate = self.View.LockBtn.OnClicked,				Func = Bind(self, self.OnBtnClickAreaClicked) },
        { UDelegate = self.View.LockBtn.OnHovered,				Func = Bind(self, self.OnBtnClickAreaHovered) },
        { UDelegate = self.View.LockBtn.OnUnhovered,		    Func = Bind(self, self.OnBtnClickAreaUnhovered) },
        { UDelegate = self.View.LockBtn.OnPressed,				    Func = Bind(self,self.OnBtnClickAreaOnPressed) },
		{ UDelegate = self.View.LockBtn.OnReleased,				    Func = Bind(self,self.OnBtnClickAreaOnReleased) },
        { UDelegate = self.View.GetBtn.OnClicked,				Func = Bind(self, self.OnBtnClickAreaClicked) },
        { UDelegate = self.View.GetBtn.OnHovered,				Func = Bind(self, self.OnBtnClickAreaHovered) },
        { UDelegate = self.View.GetBtn.OnUnhovered,		    Func = Bind(self, self.OnBtnClickAreaUnhovered) },
        { UDelegate = self.View.GetBtn.OnPressed,				    Func = Bind(self,self.OnBtnClickAreaOnPressed) },
		{ UDelegate = self.View.GetBtn.OnReleased,				    Func = Bind(self,self.OnBtnClickAreaOnReleased) },
	}
    self.Model = MvcEntry:GetModel(AchievementModel)
    self.Data = nil
    self.TaskData = nil
    self.IsHave = false
end

function AchievementListItem:OnShow()
    self.View:RemoveAllActiveWidgetStyleFlags()
    self.View.WBP_Luck:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function AchievementListItem:OnHide()
    self.Data = nil
    self.TaskData = nil
end

function AchievementListItem:SetData(Id, PlayerId)
    self.IsSelf = true
    if PlayerId and PlayerId > 0 then
        self.IsSelf = MvcEntry:GetModel(UserModel):IsSelf(PlayerId)
    end
    
    self.Data = self.Model:GetPlayerData(Id, PlayerId)
    self.IsHave = self.Data:IsUnlock()

    self.Data = self.IsSelf and self.Model:GetItemShowInfo(self.Data, self.Data.Quality == 1 and not self.IsHave) or self.Data
    self.IsHave = self.Data:IsUnlock()

    local hasMissionId = G_ConfigHelper:GetMultiItemsByKey(Cfg_AchievementCfg, Cfg_AchievementCfg_P.MissionID, self.Data.ID)

    self.View:RemoveAllActiveWidgetStyleFlags()
    if self.IsHave then
        self.View.GUITextBlock_Get:SetText(self.Data:GetTimeStr())
    end
    self.TaskData = MvcEntry:GetModel(TaskModel):GetData(self.Data.TaskId)

    self.View.GUITextBlock_Count:SetVisibility(self.Data.Count > 1 and self.IsHave and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.GUITextBlock_Count:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_7"), self.Data.Count))
    self.View.StateWidgetSwitcher:SetActiveWidgetIndex(self.Data.State - 1)
    self.View.WBP_Luck:SetVisibility(self.IsHave == true and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
    self.View.GUITextBlock_Get:SetVisibility(self.IsHave == true and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    local itemName = StringUtil.FormatText(self.Data:GetName())
    self.View.GUITextBlock_Name:SetText(itemName)
    self.View.GUIProgressBar:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Progress:SetVisibility(UE.ESlateVisibility.Collapsed)
    

    if self.TaskData ~= nil and self.IsSelf then
        local curProgress = self.Data.CurProgress
        local maxProgress = self.Data.MaxProgress--StringUtil.FormatText("/{0}",self.Data.MaxProgress)
        local prossList = self.TaskData.TargetProcessList --获取任务完成目标列表
        if prossList ~= nil and #prossList > 0 then --#prossList正常情况下不会出现无TargetProcessList,这里针对意外情况可能出现展示Bug做个兼容
            curProgress = prossList[1].ProcessValue --当前进度值
            maxProgress = prossList[1].MaxProcess or 0 --最大进度值
            self.View.GUIProgressBar:SetPercent(maxProgress < 1 and 0 or curProgress / maxProgress)
            self.View.Progress:SetVisibility(maxProgress < 1 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
        else
            maxProgress = 0
            self.View.GUITextBlock_Name:SetText(StringUtil.FormatText("任务进度数据异常")) --向策划和程序公示
            CError("prossList is null or prossList len less than 1!!!!!!!!!!!")
        end
        local isLoop = self.Data.IsLoop --是否循环展示
        local hasGroup = #hasMissionId > 1 --是否是个组
        local isNotHave = not self.IsHave --是否未获得
    
        local isShowProcess = (hasGroup or isNotHave or isLoop) and self.IsSelf
        self.View.GUIProgressBar:SetVisibility((isShowProcess and maxProgress > 0) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        self.View.Progress:SetVisibility((isShowProcess and maxProgress > 0) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

        self.View.Progress:SetText(curProgress .. "/" .. maxProgress)
    end

    CommonUtil.SetBrushFromSoftObjectPath(self.View.AchievementIcon,self.Data:GetIcon())
    CommonUtil.SetBrushFromSoftObjectPath(self.View.QualityImg, self.Data:GetItemShowImgByQualityLv(self.Data.Quality))
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Img_Quality, self.Data:GetItemSmallQuelityImgByQualityLv(self.Data.Quality))
    self:OnBtnClickAreaUnhovered()
end

function AchievementListItem:OnCicked()
    --屏蔽判断原因：可查看他人获得的成就信息
    -- if not self.IsSelf then
    --     return
    -- end

    local ViewOpenData = {
        Id = self.Data.ID,
    }

    MvcEntry:OpenView(ViewConst.AchievementTip, ViewOpenData)
end

function AchievementListItem:OnAchievementUpdate(_, Id)
    if self.Data and self.Data.ID ~= Id then
        return
    end
    self:SetData(Id)
end

function AchievementListItem:OnBtnClickAreaClicked()
    if self.IsHave then
        if self.View.VXE_Btn_LockHover then
            self.View:VXE_Btn_LockHover()
        end
    else
        if self.View.VXE_Btn_LockHover then
            self.View:VXE_Btn_LockHover()
        end
    end
end

function AchievementListItem:OnBtnClickAreaHovered()
    if self.IsHave then
        if self.View.VXE_Btn_Hover then
            self.View:VXE_Btn_Hover()
        end
    else
        if self.View.VXE_Btn_LockHover then
            self.View:VXE_Btn_LockHover()
        end
    end
end

function AchievementListItem:OnBtnClickAreaUnhovered()
    if self.IsHave then
        if self.View.VXE_Btn_UnHover then
            self.View:VXE_Btn_UnHover()
        end
    else
        if self.View.VXE_Btn_LockUnHover then
            self.View:VXE_Btn_LockUnHover()
        end
    end
end

function AchievementListItem:OnBtnClickAreaOnPressed()
    if self.IsHave then
        if self.View.VXE_Btn_Press then
            self.View:VXE_Btn_Press()
        end
    else
        if self.View.VXE_Btn_LockPress then
            self.View:VXE_Btn_LockPress()
        end
    end
end

function AchievementListItem:OnBtnClickAreaOnReleased()
    if self.IsHave then
        if self.View.VXE_Btn_Release then
            self.View:VXE_Btn_Release()
        end
    else
        if self.View.VXE_Btn_LockRelease then
            self.View:VXE_Btn_LockRelease()
        end
    end
end

return AchievementListItem
