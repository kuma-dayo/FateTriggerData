--[[
    通用的CommonMenuTab控件

    通用菜单Menu控件，控用一系列WBP_CommonTab_NormalItem结构类似的Menu对象，实现点击回调，选中与非选中效果切换等等
    WBP_CommonTab_NormalItem 必要结构如下
    1.GUIButton_TabBg  GUIButton按钮用于响应点击
    2. 动效 用于切换Tab选中状态表现： VXE_Btn_Selected 选中 / VXE_Btn_UnSelected 非选中 
    3.LbName Tab的文本    （可选）
    4.Image_Icon Tab带的图标 （可选）
]]

local class_name = "CommonMenuTab"
---@class CommonMenuTab
CommonMenuTab = CommonMenuTab or BaseClass(nil, class_name)

function CommonMenuTab:OnInit()
end
--[[
    Param格式指引
	{
		ItemInfoList = {
            {
                --MenuId，可选，值为空则按下标顺序赋值
                Id, 
                --Menu控制本身
                Widget,
                --需要展示的文本 可选，值为空不做动作
                LabelStr
                --每个Tab的小图标(可选)
                TabIcon,
                --是否需要隐藏，默认为false（可选）
                NeedHide,
                --菜单数据
                MenuData
                --红点前缀
                RedDotKey,
                --红点后缀
                RedDotSuffix
            }
            ...
        },
        --当前选中的MenuId （可选，默认第一个）
        CurSelectId
        --是否规避掉第一次触发回调  默认不规避
        HideInitTrigger
        --点击Menu的固定回调，ID传值MenuId,ItemInfo传值对应Menu的描述信息 IsInit表示是否第一次
        ClickCallBack(Id,ItemInfo,IsInit)
        --MenuTab是否可用检测回调，需返回值
        ValidCheck(Id)
        -- 是否开启键盘Q/E切页, 默认不开启. 注：若开启，则 MenuId 必须连续
        IsOpenKeyboardSwitch
        -- 是否开启键盘Z/C切页, 默认不开启. 注：若开启，则 MenuId 必须连续
        IsOpenKeyboardSwitch2
	}
]]
function CommonMenuTab:OnShow(Param)
    if not Param then
        return
    end
	self.Param = Param
    
    if not self.Param.ItemInfoList or not self.Param.ClickCallBack then
        CError("CommonMenuTab:OnShow Param Invalid,Please Check!!!")
        return
    end
    -- self.TabList = {}
    self.TabId2Item = {}
    self.BindNodes = {}
    self.MinTabId = 1
    self.MaxTabId = 1
    self.Index2TabId = {}
    self.RedDotWidgetList = {}
    for Idx,ItemInfo in ipairs(self.Param.ItemInfoList) do
        ItemInfo.Idx = Idx
        ItemInfo.Id = ItemInfo.Id or Idx
        self.MinTabId = math.min(self.MinTabId,ItemInfo.Id)
        self.MaxTabId = math.max(self.MaxTabId,ItemInfo.Id)
        if self.TabId2Item[ItemInfo.Id] then
            CError("CommonMenuTab ItemInfoList Repeat Id:" .. ItemInfo.Id,true)
        end
        self.TabId2Item[ItemInfo.Id] = ItemInfo
        self.Index2TabId[Idx] = ItemInfo.Id

        -- 需求隐藏第一个Item的线
        if Idx == 1 and ItemInfo.Widget.ImgLine then
            ItemInfo.Widget.ImgLine:SetVisibility(UE.ESlateVisibility.Collapsed)
        end 

        self.BindNodes[#self.BindNodes + 1] = {UDelegate = ItemInfo.Widget.GUIButton_TabBg.OnClicked,Func = Bind(self,self.OnTabItemClickEvent,ItemInfo.Id)}

        --更新显示名称
        if ItemInfo.LabelStr then
            if ItemInfo.Widget.LbName then
                ItemInfo.Widget.LbName:SetText(StringUtil.Format(ItemInfo.LabelStr))
            end
        end

        if ItemInfo.TabIcon then
             if ItemInfo.Widget.Image_Icon then
                CommonUtil.SetBrushFromSoftObjectPath(ItemInfo.Widget.Image_Icon, ItemInfo.TabIcon)
            end
        end

        if ItemInfo.NeedHide then
            ItemInfo.Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            ItemInfo.Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
        
        --注册红点逻辑
        if ItemInfo.Widget.WBP_RedDotFactory then
            if ItemInfo.RedDotKey and ItemInfo.RedDotSuffix then
                if not self.RedDotWidgetList[ItemInfo.Id] then
                    ItemInfo.Widget.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    self.RedDotWidgetList[ItemInfo.Id] = UIHandler.New(self, ItemInfo.Widget.WBP_RedDotFactory, CommonRedDot, {RedDotKey = ItemInfo.RedDotKey, RedDotSuffix = ItemInfo.RedDotSuffix}).ViewInstance
                end
            else
                ItemInfo.Widget.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
    end

    -- 开启键盘Q/E切页
    if Param.IsOpenKeyboardSwitch then
        self.MsgList = {
            {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Q), Func = Bind(self,self.OnSwitchMenuTab,-1)},
		    {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.E), Func = Bind(self,self.OnSwitchMenuTab,1) },
        }
        self.InputFocus = true
    elseif Param.IsOpenKeyboardSwitch2 then
        -- 开启键盘Z/C切页
        self.MsgList = {
            {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Z), Func = Bind(self,self.OnSwitchMenuTab,-1)},
		    {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.C), Func = Bind(self,self.OnSwitchMenuTab,1) },
        }
        self.InputFocus = true
    end

    self:ReRegister()
    self.CurSelectTabId = -1
    local CurSelectTabIdTmp = self.Param.CurSelectId or 1
    if self.Param.HideInitTrigger then
        self.CurSelectTabId = CurSelectTabIdTmp
        if not self:CheckMenuTabValid(self.CurSelectTabId) then
            --当前选中不可用，参数错误
            CError("CommonMenuTab:OnShow CurSelectTabId Not Valid ,Please Check")
        end
    else
        self:OnTabItemClick(CurSelectTabIdTmp,true)
    end
    self:UpdateCurSelect()
end

function CommonMenuTab:OnHide()
end

--[[
    重置内容
]]
function CommonMenuTab:Reset(Param)
    self:OnShow(Param)
end

--[[
    更新当前选中Tab显示
]]
function CommonMenuTab:UpdateCurSelect()
    for _,ItemInfo in ipairs(self.Param.ItemInfoList) do
        self:UpdateMenuItemShow(ItemInfo.Id, true)
    end
end

function CommonMenuTab:UpdateMenuItemShow(TabId, IsInit)
    if TabId == -1 then
        return
    end
    IsInit = IsInit or false
    local MenuItem = self.TabId2Item[TabId]
    if not MenuItem then
        CError("CommonMenuTab:UpdateMenuItemShow MenuItem nil")
        return
    end
    if MenuItem.Id == self.CurSelectTabId then
        -- 选中态目标不再触发hover效果及点击反馈
        if MenuItem.Widget.GUIButton_TabBg then
            MenuItem.Widget.GUIButton_TabBg:SetIsEnabled(false)
        end
        if IsInit then --第一次进入
            if MenuItem.Widget.VXE_Btn_Selected_Once then
                MenuItem.Widget:VXE_Btn_Selected_Once()
            end
        else
            if MenuItem.Widget.VXE_Btn_Selected then
                MenuItem.Widget:VXE_Btn_Selected()
            end
        end
    else
        if IsInit then --第一次进入
            if MenuItem.Widget.VXE_Btn_UnSelected_Once then
                MenuItem.Widget:VXE_Btn_UnSelected_Once()
            end
        else
            if MenuItem.Widget.VXE_Btn_UnSelected then
                MenuItem.Widget:VXE_Btn_UnSelected()
            end
        end

        -- 选中态目标不再触发hover效果及点击反馈
        if MenuItem.Widget.GUIButton_TabBg then
            MenuItem.Widget.GUIButton_TabBg:SetIsEnabled(true)
        end
    end
end

--[[
    TabItem点击
    TabId
]]

function CommonMenuTab:OnTabItemClickEvent(TabId)
    self:OnTabItemClick(TabId)
end

function CommonMenuTab:OnTabItemClick(TabId,IsInit,IsForceSelect)
    if self.CurSelectTabId == TabId and not IsForceSelect then
        return
    end
    if not self:CheckMenuTabValid(TabId) then
        return
    end
    local LastSelectId = self.CurSelectTabId
    self.CurSelectTabId = TabId
    self:UpdateMenuItemShow(LastSelectId, IsInit)
    self:UpdateMenuItemShow(self.CurSelectTabId, IsInit)
    self:InteractRedDot(TabId)

    local MenuItem = self.TabId2Item[self.CurSelectTabId]
    if MenuItem and self.Param.ClickCallBack then
        self.Param.ClickCallBack(self.CurSelectTabId,MenuItem,IsInit)
    end
end

--- 触发红点点击操作
---@param TabId number|string  页签id
function CommonMenuTab:InteractRedDot(TabId)
    if TabId and self.RedDotWidgetList[TabId] then
        self.RedDotWidgetList[TabId]:Interact()
    end
end

--[[
    检测MenuTab是否可切换
]]
function CommonMenuTab:CheckMenuTabValid(TabId)
    if not self.Param.ValidCheck then
        return true
    end
    local Result = self.Param.ValidCheck(TabId)
    if  not Result then
        --MenuTab检测不可用
        return false
    end
    return true
end

function CommonMenuTab:SetTabItemVisibility(TabId, Show)
    local MenuItem = self.TabId2Item[TabId]
    MenuItem.NeedHide = not Show
    MenuItem.Widget:SetVisibility(Show and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

CommonMenuTab._RecursionTImes = 0
function CommonMenuTab:GetAvailableIndex(Direction, SelectTabId)
    if self._RecursionTImes > self.MaxTabId then
        return self.MinTabId
    end
    self._RecursionTImes = self._RecursionTImes + 1
    local SelectId = Direction > 0 and SelectTabId + 1 or SelectTabId - 1
    if SelectId > self.MaxTabId then
        SelectId = self.MinTabId
    elseif SelectId < self.MinTabId then
        SelectId = self.MaxTabId
    end
    local MenuItem = self.TabId2Item[SelectId]
    if not MenuItem or MenuItem.NeedHide then
        return self:GetAvailableIndex(Direction, SelectId)
    end
    return SelectId
end
--[[
    通过快捷键切页
]]

function CommonMenuTab:OnSwitchMenuTab(Direction)
    local SelectId = self:GetAvailableIndex(Direction, self.CurSelectTabId)
    self._RecursionTImes = 0
    self:OnTabItemClick(SelectId)
    return true
end

--[[
    通过MenuTabId主动触发切换动作
]]
function CommonMenuTab:Switch2MenuTab(TabId,IsForceSelect)
    self:OnTabItemClick(TabId,false,IsForceSelect)
end

return CommonMenuTab
