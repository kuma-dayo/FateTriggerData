--- 视图控制器：社群关注主界面
local class_name = "ActivityDoubleHeroEvent"
local ActivityDoubleHeroEvent = BaseClass(ActivityViewBase, class_name)

function ActivityDoubleHeroEvent:OnInit(Param)
    ActivityDoubleHeroEvent.super.OnInit(self, Param)
    self.MsgList = {}
    self.BindNodes = {
        {UDelegate = self.View.Btn_Hero01.Button_ClickArea.OnClicked, Func = Bind(self, self.OnLeftBtnClick)},
        {UDelegate = self.View.Btn_Hero02.Button_ClickArea.OnClicked, Func = Bind(self, self.OnRightBtnClick)},
    }
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.Data = nil
    self.DescStrList = {}
    self.BtnSubList = {}
    self.CheckTimer = {}
end

function ActivityDoubleHeroEvent:OnShow(Param)
    if not Param or not Param.Id then
        CError("ActivityDoubleHeroEvent:OnShow Param is nil")
        return
    end
    CLog("ActivityDoubleHeroEvent:OnShow ActivityId:"..Param.Id)
    self.ActiveityID = Param.Id
    ---@type ActivityData
    self.Data = self.Model:GetData(Param.Id)
    if not self.Data then
        CError("ActivityDoubleHeroEvent:OnShow ActivityData is nil ActivityId:"..Param.Id)
        return
    end
    ---@type number[]
    self.BtnSubList = self.Data:GetSubItemsByType(Pb_Enum_ACTIVITY_SUB_ITEM_TYPE.ACTIVITY_SUB_ITEM_TYPE_SHARE)
    local DescSubList = self.Data:GetSubItemsByType(Pb_Enum_ACTIVITY_SUB_ITEM_TYPE.ACTIVITY_SUB_ITEM_TYPE_TEXT)
    if not DescSubList or not self.BtnSubList then
        CError("ActivityDoubleHeroEvent:OnShow SubListis nil")
        return
    end
    --文字描述
    for _, SubId in ipairs(DescSubList) do
        local SubData = self.Data:GetSubItemById(SubId)
        if SubData then
            table.insert(self.DescStrList, SubData:GetTittle())
        end
    end

    CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImage_Bg, self.Data:GetBigImg())
    self:UpdateDesc()
    self:UpdateHeroName()
    self:ScheduleTimeShowTick()
end

function ActivityDoubleHeroEvent:OnHide(Param)
    self.Data = nil
    self.DescStrList = nil
    self.BtnSubList = nil
    self:ClearTimeShowTick()
end

function ActivityDoubleHeroEvent:OnManualShow(Param)
    self:ScheduleTimeShowTick()
end

function ActivityDoubleHeroEvent:OnManualHide(Param)
    self:ClearTimeShowTick()
end

function ActivityDoubleHeroEvent:OnDestroy()
    ActivityDoubleHeroEvent.super.OnDestroy(self)
end

--更新左右文本描述
function ActivityDoubleHeroEvent:UpdateDesc()
    for i,Str in ipairs(self.DescStrList) do
        if CommonUtil.IsValid(self.View["TextDesc" .. i]) then
            self.View["TextDesc" .. i]:SetText(StringUtil.FormatText(Str))
        end
    end
end

--更新左右英雄名称
function ActivityDoubleHeroEvent:UpdateHeroName()
    for i,Id in ipairs(self.BtnSubList) do
        local SubData = self.Data:GetSubItemById(Id)
        if SubData then
            local Param = SubData:GetExtraParamByIndex(2)
            local HeroId = string.len(Param) > 0 and tonumber(Param) or 0
            local HeroCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, HeroId)
            if HeroCfg then
                if CommonUtil.IsValid(self.View["HeroName" .. i]) then
                    self.View["HeroName" .. i]:SetText(StringUtil.FormatText(HeroCfg[Cfg_HeroConfig_P.Name]))
                end
                if CommonUtil.IsValid(self.View["HeroRealName" .. i]) then
                    self.View["HeroRealName" .. i]:SetText(StringUtil.FormatText(HeroCfg[Cfg_HeroConfig_P.RealName]))
                end
            end
        end
    end
end

--更新左右倒计时
function ActivityDoubleHeroEvent:ScheduleTimeShowTick()
    self:ClearTimeShowTick()
    for i,Id in ipairs(self.BtnSubList) do
        local SubData = self.Data:GetSubItemById(Id)
        if CommonUtil.IsValid(self.View["PanelOpenTime" .. i]) and CommonUtil.IsValid(self.View["TextOpenTime" .. i]) then
            self.View["PanelOpenTime" .. i]:SetVisibility(UE.ESlateVisibility.Collapsed)
            if SubData then
                local Param = SubData:GetExtraParamByIndex(1)
                if string.len(Param) > 0 then
                    local EndTimeStamp = TimeUtils.TimeStampUTC0_FromTimeStr(Param)
                    self.View["PanelOpenTime" .. i]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    if self.CheckTimer[i] == nil then
                        self.CheckTimer[i] = Timer.InsertTimer(60,function()
                            local LeftTime = EndTimeStamp - GetTimestamp()
                            if CommonUtil.IsValid(self.View["PanelOpenTime" .. i]) and CommonUtil.IsValid(self.View["TextOpenTime" .. i]) then
                                self.View["TextOpenTime" .. i]:SetText(StringUtil.FormatText(StringUtil.FormatLeftTimeShowStrRuleOne(LeftTime)))
                                if LeftTime <= 0 then
                                    Timer.RemoveTimer(self.CheckTimer[i])
                                    self.CheckTimer[i] = nil
                                    self.View["PanelOpenTime" .. i]:SetVisibility(UE.ESlateVisibility.Collapsed)
                                end
                            else
                                Timer.RemoveTimer(self.CheckTimer[i])
                            end
                        end, true, "", true)
                    end
                end
            end
        end
    end
end

-- 关闭所有定时器
function ActivityDoubleHeroEvent:ClearTimeShowTick()
    for k, v in ipairs(self.CheckTimer) do
        Timer.RemoveTimer(v)
    end
    self.CheckTimer = {}
end

--左前往按钮点击事件
function ActivityDoubleHeroEvent:OnLeftBtnClick()
    local SubId = #self.BtnSubList > 0 and self.BtnSubList[1] or 0
    local SubData = self.Data:GetSubItemById(SubId)
    if not SubData then
        CError("ActivityDoubleHeroEvent:OnLeftBtnClick SubData nil")
        return
    end
    if self.Data:GetLeftTime() <= 0 then
        CWaring("Activity Is Out Of Date, ID Is:" .. self.ActiveityID)
        return
    end
    SubData:JumpView()
end

--右前往按钮点击事件
function ActivityDoubleHeroEvent:OnRightBtnClick()
    local SubId = #self.BtnSubList > 1 and self.BtnSubList[2] or 0
    local SubData = self.Data:GetSubItemById(SubId)
    if not SubData then
        CError("ActivityDoubleHeroEvent:OnRightBtnClick SubData nil")
        return
    end
    if self.Data:GetLeftTime() <= 0 then
        CWaring("Activity Is Out Of Date, ID Is:" .. self.ActiveityID)
        return
    end
    SubData:JumpView()
end

return ActivityDoubleHeroEvent
