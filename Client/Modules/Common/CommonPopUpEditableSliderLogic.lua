--[[
    用于 WBP_CommonPopUp_Content_EditableSlider 的逻辑块
]]

local class_name = "CommonPopUpEditableSliderLogic"
CommonPopUpEditableSliderLogic = CommonPopUpEditableSliderLogic or BaseClass(UIHandlerViewBase, class_name)

function CommonPopUpEditableSliderLogic:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.WBP_ReuseList.OnUpdateItem,				Func = Bind(self,self.OnUpdateItem) },
    }
    self.MaxCol = 8
    self.LimitMaxNum = 100
    self.IconClsList = {}
end

--[[
    Param = {
        -- 1. 展示的道具列表 适用于展示固定，滑动条只改变列表道具数量
            ItemList = {
                [1] = {ItemId,ItemNum},...
            }
        -- 2. 设置展示的道具列表 适用于根据滑动条选择的数量，展示不同的道具列表
            GetItemListFunc
        ------------------------------------
        -- 都不传不显示描述文字
        -- 描述文字 适用于固定描述
        DesStr
        -- 动态设置描述文字的回调接口
        GetDesStrFunc
        ------------------------------------
        -- 最大可选择数量
        MaxNum
    }
]]
function CommonPopUpEditableSliderLogic:OnShow(Param)
    if not Param then
        return
    end
    if not (Param.ItemList or Param.GetItemListFunc) then
        CError("CommonPopUpEditableSliderLogic Need ItemList")
        return
    end
    if not Param.MaxNum then
        CError("CommonPopUpEditableSliderLogic Must Assign MaxNum")
        return
    end
    self.Param = Param
    self.SelectNum = 1
    self.ItemList = {}
    self.GetItemListFunc = nil
    if Param.ItemList then
        self.ItemList = Param.ItemList
    else
        -- 初始化选择数量1获取展示的道具列表
        self.GetItemListFunc = Param.GetItemListFunc
        self.ItemList = self.GetItemListFunc(self.SelectNum) 
    end
    self.IconWidgetList = {}
    self.IconClsList = {}
    self:UpdateItemListShow()
    
    self.ParentValueChangeCallBack = Param.ValueChangeCallBack
    -- 初始化滑动块逻辑
    UIHandler.New(self, self.View.WBP_CommonEditableSlider, CommonEditableSlider, {
        ValueChangeCallBack = Bind(self, self.ValueChangeCallBack),
        MaxValue = math.min(Param.MaxNum,self.LimitMaxNum),
    })

    self.GetDesStrFunc = Param.GetDesStrFunc
    self:UpdateDesStr()
end

function CommonPopUpEditableSliderLogic:OnHide()
    self.ItemList = {}
    self.IconClsList = {}
    self.IconWidgetList = {}
    self.ValueChangeCallBack = nil
    self.GetItemListFunc = nil
    self.GetDesStrFunc = nil
end

-- 更新道具展示列表
function CommonPopUpEditableSliderLogic:UpdateItemListShow()
    if not self.ItemList then
        return
    end
    local ShowNum = #self.ItemList
    local IsMultiLine = ShowNum > self.MaxCol 
    self.View.WidgetSwitcher_Item:SetActiveWidget(IsMultiLine and self.View.MultiLine or self.View.SingleLine)
    if IsMultiLine then
        self.View.WBP_ReuseList:Reload(ShowNum)
    else
        local WidgetCls = UE4.UClass.Load(CommonUtil.FixBlueprintPathWithC(CommonItemIconUMGPath))
        for Index = 1,ShowNum do
            local IconWidget = self.IconWidgetList[Index]
            if not IconWidget then
                IconWidget = NewObject(WidgetCls,self.View)
                self.View.WrapBox:AddChild(IconWidget)
                self.IconWidgetList[Index] = IconWidget
            end
            self:SetItemIcon(Index,IconWidget)
        end
    end
end

function CommonPopUpEditableSliderLogic:OnUpdateItem(_,Widget, I)
    local Index = I + 1
    self:SetItemIcon(Index,Widget)
end

function CommonPopUpEditableSliderLogic:SetItemIcon(Index,IconWidget)
    local ItemInfo = self.ItemList[Index]
    if not ItemInfo then
        CError("CommonPopUpEditableSliderLogic:SetItemIcon ItemInfo Error For Index = "..Index)
        return
    end
    local Count = ItemInfo.ItemNum or self.SelectNum
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemInfo.ItemId,
        ItemNum = Count,
    }
    local IconWidgetCls = self.IconClsList[Index]
    if not IconWidgetCls then
        IconWidgetCls = UIHandler.New(self,IconWidget,CommonItemIcon,IconParam).ViewInstance
        self.IconClsList[Index] = IconWidgetCls
    else
        IconWidgetCls:UpdateUI(IconParam)
    end
end

-- 更新描述文字
function CommonPopUpEditableSliderLogic:UpdateDesStr()
    self.View.RichText_Des:SetVisibility(UE.ESlateVisibility.Collapsed)
    if not self.Param then
        return
    end
    if self.Param.DesStr then
        self.View.RichText_Des:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.RichText_Des:SetText(self.Param.DesStr)
    elseif self.GetDesStrFunc then
        self.View.RichText_Des:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.RichText_Des:SetText(self.GetDesStrFunc(self.SelectNum))
    end
end

-- 滑动条数值改变
function CommonPopUpEditableSliderLogic:ValueChangeCallBack(Value)
    self.SelectNum = Value
    
    if self.ParentValueChangeCallBack then
        self.ParentValueChangeCallBack(Value)
    end

    if self.GetItemListFunc then
        self.ItemList = self.GetItemListFunc(self.SelectNum)
    end
    self:UpdateItemListShow()
    if self.GetDesStrFunc then
        self:UpdateDesStr()
    end
    
end




return CommonPopUpEditableSliderLogic