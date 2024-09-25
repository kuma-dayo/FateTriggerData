--- 视图控制器
local class_name = "ActivityTabListItem";
local ActivityTabListItem = BaseClass(nil, class_name);

function ActivityTabListItem:OnInit()
    self.MsgList =
    {
		{Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_TABLISTITEM_SELECT, Func = Bind(self, self.OnTabItemSelect)},
    }

    self.BindNodes =
    {
		{ UDelegate = self.View.btn_tab.OnClicked,				    Func = Bind(self, self.OnCicked) },
        { UDelegate = self.View.btn_tab.OnHovered,  Func = Bind(self,self.OnHover) },
		{ UDelegate = self.View.btn_tab.OnUnhovered,  Func = Bind(self,self.OnUnhovered) }
	}
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.Data = nil
    self.CurSelAcId = 0
end

function ActivityTabListItem:OnShow()
end

function ActivityTabListItem:OnHide()
    self.Data = nil
end

function ActivityTabListItem:SetData(AcId)
    ---@type ActivityData
    self.Data = self.Model:GetData(AcId)
    if not self.Data then
        return
    end
    local LanguageCallBack = function (Text)
        if CommonUtil.IsValid(self.View) and  CommonUtil.IsValid(self.View.GUITextBlock_Tiitle) then
            self.View.GUITextBlock_Tiitle:SetText(StringUtil.FormatText(Text))
        end
    end
    self.Data:GetTabTitle(LanguageCallBack)

    CommonUtil.SetBrushFromSoftObjectPath(self.View.Icon_Hover,self.Data:GetTabIcon())
    self.View:VXE_Btn_Normal()

    self:RegCommonRedDot()
end

function ActivityTabListItem:RegCommonRedDot()
    --TODO:注册 红点 控件
    if self.View.WBP_RedDotFactory then
        local AcId = self.Data.ID
        -- local RedDotKey = "ActivityType_"
        local RedDotKey = "ActivityTitle_"
        local RedDotSuffix = AcId
        if self.RedDotViewInstance == nil then
            self.RedDotViewInstance = UIHandler.New(self,  self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        else 
            self.RedDotViewInstance:ChangeKey(RedDotKey, RedDotSuffix)
        end 
    end
end

function ActivityTabListItem:InteractRedDot()
    if self.RedDotViewInstance then
        -- self.RedDotViewInstance:Interact()    
        ---@type RedDotCtrl
        local RedDotCtrl = MvcEntry:GetCtrl(RedDotCtrl)
        -- RedDotCtrl:Interact("ActivitySubItem_", self.SubData.SubItemId, RedDotModel.Enum_RedDotTriggerType.Click) 
        -- 注意:这里写死了ActivityType_
        RedDotCtrl:Interact("ActivityType_", self.Data.ID) 
    end
end

function ActivityTabListItem:OnCicked()
    if self.CurSelAcId == self.Data.ID then
        return
    end
    self.Model:DispatchType(ActivityModel.ACTIVITY_TABLISTITEM_SELECT, self.Data.ID)
end

function ActivityTabListItem:OnTabItemSelect(_, AcId)
    if self.Data.ID == AcId then
        self.View:VXE_Btn_Select()
        self:InteractRedDot()
    else
        self.View:VXE_Btn_Normal()
    end
    self.CurSelAcId = AcId
end

function ActivityTabListItem:OnHover()
    if self.CurSelAcId == self.Data.ID then
        return
    end
    self.View:VXE_Btn_Hover()
end

function ActivityTabListItem:OnUnhovered()
    if self.CurSelAcId == self.Data.ID then
        return
    end
    self.View:VXE_Btn_Normal()
end

return ActivityTabListItem
