--[[
   个人信息 - 个性化设置 - 单个头像Item - WBP_ImformationHeadListItemWidget
]] 
local class_name = "HeadIconSettingItem"
local HeadIconSettingItem = BaseClass(nil, class_name)

function HeadIconSettingItem:OnInit()
    self.MsgList = {
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_SELECT_ITEM,Func = Bind(self,self.UpdateSelect) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_SELECT_ITEM_AND_EDIT,Func = Bind(self,self.UpdateSelect) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_ICON_UNLOCK,Func = Bind(self,self.UpdateState) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_USE_HEAD_ICON,Func = Bind(self,self.UpdateState) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_FRAME_UNLOCK,Func = Bind(self,self.UpdateState) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_WIDGET_UNLOCK,Func = Bind(self,self.UpdateState) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_FRAME_AND_WIDGET_CHANGED,Func = Bind(self,self.UpdateState) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_WIDGET_COUNT_CHANGED,Func = Bind(self,self.UpdateState) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.CLEAR_SELECT,Func = Bind(self,self.OnUnselect) },
    }
    self.BindNodes = {
		{ UDelegate = self.View.GUIButton.OnClicked,				Func = Bind(self,self.OnClick_Btn) },
    }
    ---@type HeadIconSettingModel
    self.HeadIconSettingModel = MvcEntry:GetModel(HeadIconSettingModel)
    self.HeadWidgetCls = nil
end


function HeadIconSettingItem:OnShow()
end

function HeadIconSettingItem:OnHide()
    
end

--[[
    local Param = {
        SettingType -- 设置类型（头像/头像框/挂件）,
        SeriesId  -- 系列Id,
        Id  -- 数据Id,
        IsFirstSeries -- 是否排序的第一个系列（用于初始选中）,
        IsFirstData -- 是否排序的第一个数据（用于初始选中）,
    }
]]
function HeadIconSettingItem:UpdateUI(Param)
    if not Param then
        CError("HeadIconSettingItem UpdateUI Need Param!",true)
        return
    end
    self.Param = Param
    -- 是否自定义头像
    self.IsCustomHead = self.Param.SettingType == HeadIconSettingModel.SettingType.HeadIcon and self.HeadIconSettingModel:CheckIsCustomHead(self.Param.Id)
    self:UpdateDetail()
    self:UpdateState()
    self:UpdateSelect()
    self:RegisterRedDot()
end

-- 更新详情内容 WBP_HeadDetailWidget
function HeadIconSettingItem:UpdateDetail()
    local HeadDetailParam = {
        SettingType = self.Param.SettingType,
        Id = self.Param.Id,
        IsShowWeight = true,
        JustShowWidget = true,
    }
    self.View.Panel_EditHead:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.WBP_HeadDetailWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if not self.HeadWidgetCls then
        self.HeadWidgetCls = UIHandler.New(self,self.View.WBP_HeadDetailWidget,require("Client.Modules.PlayerInfo.HeadIconSetting.HeadDetailWidget"),HeadDetailParam).ViewInstance
    else
        self.HeadWidgetCls:UpdateUI(HeadDetailParam)
    end
end

-- 更新是否解锁 & 是否使用中 & 是否自定义头像
function HeadIconSettingItem:UpdateState()
    self.IsUsing = false
    if self.IsCustomHead then
        self.View.Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- 是否使用中
        self.IsUsing = self.HeadIconSettingModel:IsSettingUsing(self.Param.SettingType,self.Param.Id)
        self.View.Image_Using:SetVisibility(self.IsUsing and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

        local IsHasCustomHead = self.HeadIconSettingModel:CheckMySelfIsHasCustomHead()
        self.View.Panel_EditHead:SetVisibility(IsHasCustomHead and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

        self.View.WBP_HeadDetailWidget:SetVisibility(IsHasCustomHead and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

        -- 头像是否审核中
        local IsToExamine = self.HeadIconSettingModel:CheckMySelfIsToExamineCustomHead(self.Param.Id)
        self.View.Panel_Check:SetVisibility(IsToExamine and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    else
        local IsUnlock = self.HeadIconSettingModel:IsSettingUnlock(self.Param.SettingType,self.Param.Id)
        if IsUnlock then
            -- 已解锁
            self.View.Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
            -- 是否使用中
            self.IsUsing = self.HeadIconSettingModel:IsSettingUsing(self.Param.SettingType,self.Param.Id)
            self.View.Image_Using:SetVisibility(self.IsUsing and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        else
            -- 未解锁
            self.View.Image_Using:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.Lock:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        end
        self.View.Panel_Check:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function HeadIconSettingItem:OnClick_Btn()
    self.SelectParam = {
        SettingType = self.Param.SettingType,
        Id = self.Param.Id
    }
    self.HeadIconSettingModel:SetItemSelectParam(self.SelectParam)
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_SELECT_ITEM,self.SelectParam)

    self:InteractRedDot()
end

function HeadIconSettingItem:UpdateSelect()
    self.SelectParam = self.HeadIconSettingModel:GetItemSelectParam()
    if self.SelectParam and self.Param.Id == self.SelectParam.Id then
        self:OnSelect()
    else
        self:OnUnselect()
    end
end

function HeadIconSettingItem:OnSelect()
    if self.View.VXE_Btn_Selected then
        self.View:VXE_Btn_Selected()
    end
end

function HeadIconSettingItem:OnUnselect()
    if self.View.VXE_Btn_UnSelected then
        self.View:VXE_Btn_UnSelected()
    end
end

-- 绑定红点
function HeadIconSettingItem:RegisterRedDot()
    local RedDotKeyList = {
        [HeadIconSettingModel.SettingType.HeadIcon] = "InformationPersonalHeadIconItem_",
        [HeadIconSettingModel.SettingType.HeadFrame] = "InformationPersonalHeadIconFrameItem_",
        [HeadIconSettingModel.SettingType.HeadWidget] = "InformationPersonalHeadWidgetItem_",
    }
    local RedDotKey = RedDotKeyList[self.Param.SettingType]
    local RedDotSuffix = self.Param.Id
    if not self.RedDotItem then
        self.RedDotItem = UIHandler.New(self,  self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance 
    else
        self.RedDotItem:ChangeKey(RedDotKey, RedDotSuffix)
    end
end

-- 红点触发逻辑
function HeadIconSettingItem:InteractRedDot()
    if self.RedDotItem then
        self.RedDotItem:Interact()
    end
end

return HeadIconSettingItem
