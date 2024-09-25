--[[
    基于 WBP_CommonPopPanel 的通用弹窗组件逻辑
]]

local class_name = "CommonPopUpPanel"
CommonPopUpPanel = CommonPopUpPanel or BaseClass(nil, class_name)

CommonPopUpPanel.TabUMGPath = "/Game/BluePrints/UMG/Components/CommonPopUp/WBP_CommonPopTabItem.WBP_CommonPopTabItem"
CommonPopUpPanel.ContentType = {
    Empty = 1,  -- 空界面
    List = 2,   -- 左侧列表，右侧内容
    Content = 3,    -- 全屏内容
}
function CommonPopUpPanel:OnInit()
    self.MsgList = 
    {
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnBtnOutsideClicked},
    }
    self.BindNodes = 
    {
        { UDelegate = self.View.WBP_Btn_close.GUIButton_Main.OnClicked,    Func = Bind(self,self.OnCloseBtnClicked) },
        { UDelegate = self.View.BtnOutSide.OnClicked,	Func = Bind(self,self.OnBtnOutsideClicked) },
        -- { UDelegate = self.View.WBP_CommonBtn_Close.GUIButton_Main.OnClicked,	Func = Bind(self,self.OnBtnOutsideClicked) },
        { UDelegate = self.View.CommonBtn_1.OnClicked,	Func = Bind(self,self.CommonBtn_1_ClickFunc) },
        { UDelegate = self.View.CommonBtn_2.OnClicked,	Func = Bind(self,self.CommonBtn_2_ClickFunc) },
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,	Func = Bind(self,self.OnUpdateContentItem) },
        { UDelegate = self.View.OnAnimationFinished_vx_commonpoppanel_out,	Func = Bind(self,self.On_vx_commonpopup_out_Finished) },
	}
    self:InitData()
    self.View.BottomPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function CommonPopUpPanel:InitData()
    self.TabListCls = nil
    self.ContentType = CommonPopUpPanel.ContentType.Empty
    --[[
        顶部Tab列表
        self.TitleTabDataList = {[1] = {TabId = xx,TabName = "xx"},[2] = {TabId = xx,TabName = "xx"},[3] = {TabId = xx,TabName = "xx"}...}
    ]]
    self.TitleTabDataList = {}   
    -- self.TitleTabItemList = {}
    self.SelectTabId = 1

    --[[
        左侧Tab列表
    ]]
    self.ContentTabDataList = {}
    self.ContentItemList = {}
    self.SelectContentId = 1
    ---@type WCommonBtnTips 
    --[[
        底部按钮列表,Param为WCommonBtnTips的Param
        self.BottomBtnDataList = {[1] = Param ,..}
    ]]
    self.BottomBtnDataList = {}
    self.ShowBottomPanel = false
    self.BottomTextStr = ""
    self.BottomBtnInstList = {}

    ---左侧内容标题红点组件列表
    self.ContentRedDotWidgetList = {}

    self.IsClosing = false --播放关闭动画时禁止在产生关闭行为
end

--[[
    Param = {
        --- 1. 如果顶部要显示Tab栏
        -- 顶部默认的选中id
        SelectTabId
        -- 顶部Tab栏数据
        TitleTabDataList = {[1] = {TabId = xx,TabName = "xx"},[2] = {TabId = xx,TabName = "xx"},[3] = {TabId = xx,TabName = "xx"}...}
        
        --- 2. 如果顶部要显示标题文字 
        -- 顶部标题文字 
        TitleStr
    
        --- 3. 内容相关
        -- 内容类型
        ContentType
        -- 当ContentType为List时有效 - 点击左侧列表，刷新右侧内容的回调
        OnRefreshListContentCb

        --- 4. 红点相关、
        TitleRedDotKey 标题红点前缀
        ContentRedDotKey 左侧内容标题前缀
        -- 有值的情况 需要注册红点

        -- 关闭回调，供点击外侧和关闭按钮使用
        CloseCb

        -- 是否显示关闭按钮
        IsCloseBtnVisible
        
        --- 5. 底部按钮面板
        -- 控制BottomPanel显示,默认隐藏
        ShowBottomPanel = false
        -- 控制底部按钮区域文字显示,默认隐藏
        BottomTextStr = ""
        -- 底部按钮参数列表WCommonBtnTips
        BottomBtnDataList = {[1] = Param ,..}
        -- 控制"点击空白处关闭"文字面板显示,默认隐藏
        HideOutsideText = false
    }
]]
function CommonPopUpPanel:OnShow(Param)
    if not Param then
        return
    end
    print("CommonPopUpPanel OnShow")
    self.IsClosing = false
    self:UpdateUI(Param)
end

function CommonPopUpPanel:UpdateUI(Param)
     -- 顶部标题/Tab
     self.SelectTabId = Param.SelectTabId or 1
     self.TitleTabDataList = Param.TitleTabDataList
     self.OnTitleTabBtnClickCb = Param.OnTitleTabBtnClickCb
     self.OnTitleTabValidCheckFunc = Param.OnTitleTabValidCheckFunc
     -- 底部按钮面板
     self.ShowBottomPanel = Param.ShowBottomPanel and Param.ShowBottomPanel or false
     self.BottomTextStr = Param.BottomTextStr and Param.BottomTextStr or ""
     self.BottomBtnDataList = Param.BottomBtnDataList and Param.BottomBtnDataList or {}
 
     -- 标题文字
     self.TitleStr = Param.TitleStr
 
     -- 内容类型
     self.ContentType = Param.ContentType or CommonPopUpPanel.ContentType.Empty
 
     -- 红点相关
     self.TitleRedDotKey = Param.TitleRedDotKey
     self.ContentRedDotKey = Param.ContentRedDotKey
 
     -- 左侧列表点击回调
     self.OnRefreshListContentCb = Param.OnRefreshListContentCb
 
     -- 底部按钮 TODO 未有使用需求，有需求再补充逻辑
 
     -- 显示关闭按钮
     if Param.IsCloseBtnVisible then
         self.View.WBP_Btn_close:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
     else
         self.View.WBP_Btn_close:SetVisibility(UE.ESlateVisibility.Collapsed)
     end
 
     -- 关闭回调
     self.CloseCb = Param.CloseCb
 
     self:SetTitleTab()
     self:SetTitleText()
 
     -- Content类型
     self:SwitchContent()

    self:PlayDynamicEffectOnShow(true)

    -- 底部按钮面板
    self:SetBottomButton()
    
    -- "点击空白处关闭"文字面板
    self.View.OutsideTextPanel:SetVisibility(Param.HideOutsideText and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
end

function CommonPopUpPanel:OnHide()
    print("CommonPopUpPanel OnHide")
    for _,Widget in pairs(self.ContentItemList) do
        Widget.GUIButton_TabBg.OnClicked:Clear()
    end
    self:InitData()
end

-- 设置内容类型
function CommonPopUpPanel:SetContentType(Type)
    self.ContentType = Type
    self:SwitchContent()
end

-- 切换内容状态
function CommonPopUpPanel:SwitchContent()
    if self.ContentType == CommonPopUpPanel.ContentType.Empty then
        self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.EmptyContent)
    elseif self.ContentType == CommonPopUpPanel.ContentType.List then
        self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.ListContent)
    elseif self.ContentType == CommonPopUpPanel.ContentType.Content then
        self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.ContentPanel)
    end
end

-- 顶部显示标题
function CommonPopUpPanel:SetTitleText()
    if not self.TitleStr or self.TitleStr =="" then
        self.View.Title:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.View.Title:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.Text_Title:SetText(StringUtil.Format(self.TitleStr))
end

-- 顶部显示Tab栏
function CommonPopUpPanel:SetTitleTab()
    if not self.TitleTabDataList or #self.TitleTabDataList == 0 then
        self.View.Tab:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    -- local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(CommonPopUpPanel.TabUMGPath))
    -- if not WidgetClass then
    --     CError("CommonPopUpPanel ResetTitleTab WidgetClass Error",true)
    --     return
    -- end
    -- self.View.Tab:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- local TabParam = {
    --     ClickCallBack = Bind(self,self.OnTitleTabBtnClick),
    --     ValidCheck = Bind(self,self.OnTitleTabValidCheck),
    --     HideInitTrigger = true,
    -- }

    -- local Index = 1
    -- TabParam.ItemInfoList = {}
    -- for I,TabData in ipairs(self.TitleTabDataList) do
    --     local Widget = self.TitleTabItemList[Index]
    --     if not Widget then
    --         Widget = NewObject(WidgetClass, self.View)
    --         if Widget then
    --             self.View.MenuTabList:AddChild(Widget)
    --             self.TitleTabItemList[Index] = Widget

    --             self:RegisterRedDot(self.TitleRedDotKey, TabData.TabId, Widget)
    --         else
    --             CError("CommonPopUpPanel:ResetTitleTab NewWidget Error",true)
    --             return
    --         end
    --     end
    --     Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     local TabItemInfo = {
    --         Id = TabData.TabId,
    --         Widget = Widget,
    --         LabelStr = TabData.TabName,
    --     }
    --     TabParam.ItemInfoList[Index] = TabItemInfo
    --     Index = Index + 1
    -- end
    -- while self.TitleTabItemList[Index] do
    --     self.TitleTabItemList[Index]:SetVisibility(UE.ESlateVisibility.Collapsed)
    --     Index = Index + 1
    -- end
    -- if not self.TabListCls then
    --     self.TabListCls = UIHandler.New(self,self.View.MenuTabList, CommonMenuTab,TabParam).ViewInstance
    -- else
    --     self.TabListCls:Reset(TabParam)
    -- end

    local TabParam = {
        ClickCallBack = Bind(self,self.OnTitleTabBtnClick),
        ValidCheck = Bind(self,self.OnTitleTabValidCheck),
        HideInitTrigger = true,
        TabItemType = CommonMenuTabUp.TabItemTypeEnum.TYPE2,
        
    }
    TabParam.ItemInfoList = {}
    for Index,TabData in ipairs(self.TitleTabDataList) do
        local TabItemInfo = {
            Id = TabData.TabId,
            LabelStr = TabData.TabName,
            -- 可选 红点前缀
            RedDotKey = TabData.RedDotKey,
            -- 可选 红点后缀
            RedDotSuffix = TabData.RedDotSuffix,
        }
        TabParam.ItemInfoList[Index] = TabItemInfo
    end
    TabParam.IsOpenKeyboardSwitch = #TabParam.ItemInfoList > 1
    if not self.TabListCls then
        self.TabListCls =  UIHandler.New(self,self.View.WBP_Common_TabUp_02,CommonMenuTabUp).ViewInstance
    end
    self.TabListCls:UpdateUI(TabParam)
    self.View.Tab:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

-- 触发第一次点击Tab
function CommonPopUpPanel:TriggerInitTabClick()
    if self.TabListCls then
        self.TabListCls:OnTabItemClick(self.SelectTabId,true,true)
    end
end

-- 点击顶部Tab栏
function CommonPopUpPanel:OnTitleTabBtnClick(TabId,MenuItem,IsInit)
    self.SelectTabId = TabId
    if self.OnTitleTabBtnClickCb then
        self.OnTitleTabBtnClickCb(TabId,MenuItem,IsInit)
    end
end

function CommonPopUpPanel:OnTitleTabValidCheck(TabId)
    if self.OnTitleTabValidCheckFunc then
        return self.OnTitleTabValidCheckFunc(TabId)
    end
    return true
end

--------------- ContentType = List ------------------------------------
-- 设置左侧内容列表 
---@field ContentTabDataList = {[1] = {Id = xx, Name = "xx"}, [2] = {Id = xx, Name = "xx"},..}
function CommonPopUpPanel:SetContentList(ContentTabDataList,NotResetId)
    self.ContentTabDataList = ContentTabDataList
    if not self.ContentTabDataList or #self.ContentTabDataList == 0 then
        return
    end
    if not NotResetId then
        self.SelectContentId = self.ContentTabDataList[1].Id
    end
    self.View.WBP_ReuseList:Reload(#self.ContentTabDataList)
    self:OnClickContentItem(self.SelectContentId,true)
end

function CommonPopUpPanel:OnUpdateContentItem(_,Widget, I)
    local Index = I + 1
    local ContentData = self.ContentTabDataList[Index]
    if not ContentData then
        CWaring("CommonPopUpPanel:OnUpdateContentItem GetContentData Error; Index = "..tostring(Index))
        return
    end
    local Id = ContentData.Id
    Widget.LbName:SetText(ContentData.Name)
    self:SetBtnIsSelect(Widget,Id == self.SelectContentId)
    Widget.GUIButton_TabBg.OnClicked:Clear()
    Widget.GUIButton_TabBg.OnClicked:Add(self.View,Bind(self,self.OnClickContentItem,Id))
    self.ContentItemList[Id] = Widget

    self:RegisterRedDot(self.ContentRedDotKey, Id, Widget)
end

-- 点击左侧内容列表Item
function CommonPopUpPanel:OnClickContentItem(Id,IsForce)
    if not IsForce and self.SelectContentId and Id == self.SelectContentId then
        return
    end
    if self.SelectContentId and self.ContentItemList[self.SelectContentId] then
        local OldSelectWidget = self.ContentItemList[self.SelectContentId]
        -- OldSelectWidget.WidgetSwitcher:SetActiveWidget(OldSelectWidget.Normal)
        self:SetBtnIsSelect(OldSelectWidget,false)
    end
    self.SelectContentId = Id
    local NewSelectWidget = self.ContentItemList[self.SelectContentId]
    if NewSelectWidget then
        -- NewSelectWidget.WidgetSwitcher:SetActiveWidget(NewSelectWidget.Select)
        self:SetBtnIsSelect(NewSelectWidget,true)
    end
    self:OnRefreshListContent(self.SelectTabId,self.SelectContentId)

    self:InteractRedDot(self.ContentRedDotKey, self.SelectContentId)
end

function CommonPopUpPanel:SetBtnIsSelect(BtnWidget,IsSelect)
    if IsSelect then
        BtnWidget.GUIButton_TabBg:SetIsEnabled(false)
        if BtnWidget.VXE_Btn_Selected then
            BtnWidget:VXE_Btn_Selected()
        end
    else
        if BtnWidget.VXE_Btn_UnSelected then
            BtnWidget:VXE_Btn_UnSelected()
        end
        BtnWidget.GUIButton_TabBg:SetIsEnabled(true)
    end
end

-- 右侧内容为可滑动
function CommonPopUpPanel:AddWidgetToContentScroll(Widget)
    if not Widget then
        return
    end
    self.View.ContentSubPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.ContentScroll:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.ContentScroll:ClearChildren()
    self.View.ContentScroll:AddChild(Widget)
end

-- 右侧内容为不可滑动
function CommonPopUpPanel:AddWidgetToContentSubPanel(Widget)
    if not Widget then
        return
    end
    self.View.ContentScroll:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.ContentSubPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.ContentSubPanel:ClearChildren()
    self.View.ContentSubPanel:AddChild(Widget)
end

-- 刷新右侧内容
function CommonPopUpPanel:OnRefreshListContent(SelectTabId,SelectContentId)
    self.View.ContentScroll:ScrollToStart()
    if self.OnRefreshListContentCb then
        self.OnRefreshListContentCb(SelectTabId,SelectContentId)
    end
end

function CommonPopUpPanel:GetContentPanel()
    return self.View.ContentPanel
end

--[[
    播放显示退出动效
]]
function CommonPopUpPanel:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.View.VXE_CommonPopup_L_In then
            self.View:VXE_CommonPopup_L_In()
        end
    else
        if self.View.VXE_CommonPopup_L_Out then
            self.View:VXE_CommonPopup_L_Out()
        end
    end
end

--------------- 红点相关逻辑 ------------------------------------------------
--- 注册红点信息
---@param RedDotKey string  红点前缀
---@param RedDotSuffix string 红点后缀
---@param RedDotWidget any 红点控件
function CommonPopUpPanel:RegisterRedDot(RedDotKey, RedDotSuffix, RedDotWidget)
    if RedDotKey and RedDotSuffix and RedDotWidget and RedDotWidget.WBP_RedDotFactory then
        local MarkKey = self:ContactKey(RedDotKey, RedDotSuffix)
        if not self.ContentRedDotWidgetList[MarkKey] then
            RedDotWidget.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.ContentRedDotWidgetList[MarkKey] = UIHandler.New(self, RedDotWidget.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        end
    end
end

--- 触发红点点击操作
---@param RedDotKey string  红点前缀
---@param RedDotSuffix string 红点后缀
function CommonPopUpPanel:InteractRedDot(RedDotKey, RedDotSuffix)
    if RedDotKey and RedDotSuffix then
        MvcEntry:GetCtrl(RedDotCtrl):Interact(RedDotKey, RedDotSuffix)
    end
end

---拼接红点标识符
function CommonPopUpPanel:ContactKey(RedDotKey, RedDotSuffix)
    local MarkKey = RedDotKey .. RedDotSuffix
    return MarkKey
end

--------------- ContentType = Content ------------------------------------
-- TODO 

--------------- ContentType = Empty ------------------------------------

function CommonPopUpPanel:SetEmptyTips(EmptyTips,EmptyTips1)
    self.View.EmptyTips:SetText(EmptyTips)
    if EmptyTips1 then
        self.View.EmptyTips1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.EmptyTips1:SetText(EmptyTips1)
    else
        self.View.EmptyTips1:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end
------------------- 底部按钮相关接口
function CommonPopUpPanel:SetBottomButton()
    self.View.BottomPanel:SetVisibility(self.ShowBottomPanel and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    --底部文字
    self.View.BottomText:SetVisibility(string.len(self.BottomTextStr) > 0 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.BottomText:SetText(self.BottomTextStr)
    --底部按钮
    local Index = 1
    repeat
        local Widget = self.View["CommonBtn_" .. Index]
        if not CommonUtil.IsValid(Widget) then
            break
        end
        Index = Index + 1
        Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
    until Index > 5

    for i, Param in ipairs(self.BottomBtnDataList) do
        local Widget = self.View["CommonBtn_" .. i]
        if CommonUtil.IsValid(Widget) then
            Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            if not self.BottomBtnInstList[i] then
                self.BottomBtnInstList[i] = UIHandler.New(self, Widget, WCommonBtnTips, Param).ViewInstance
            end
        end
    end
end

function CommonPopUpPanel:CommonBtn_1_ClickFunc()
    
end

function CommonPopUpPanel:CommonBtn_2_ClickFunc()
    
end

function CommonPopUpPanel:OnBtnOutsideClicked()
    -- if self.CloseCb then
    --     self.CloseCb()
    -- end
    self:OnCloseViewByAction()
end

function CommonPopUpPanel:OnCloseBtnClicked()
    -- if self.CloseCb then
    --     self.CloseCb()
    -- end
    self:OnCloseViewByAction()
end

function CommonPopUpPanel:On_vx_commonpopup_out_Finished()
    if self.CloseCb then
        self.CloseCb()
    end
end

function CommonPopUpPanel:OnCloseViewByAction()
    if not self.CloseCb or self.IsClosing then
        return
    end
    self.IsClosing = true
    self:PlayDynamicEffectOnShow(false)
end
return CommonPopUpPanel