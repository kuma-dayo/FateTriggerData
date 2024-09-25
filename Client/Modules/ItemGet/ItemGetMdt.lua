---
--- Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 通用物品获得界面UI
--- Created At: 2023/03/27 17:17
--- Created By: 朝文
---

require("Client.Modules.Common.CommonItemIcon")
require("Client.Modules.Common.CommonBtnTips")

local class_name = "ItemGetMdt"
---@class ItemGetMdt : GameMediator
ItemGetMdt = ItemGetMdt or BaseClass(GameMediator, class_name)


function ItemGetMdt:__init()
end

---@param Param ItemGetOnShowParam 展示物品获得面板的参数
function ItemGetMdt:OnShow(Param)
    ---@type ItemGetModel
    local Model = MvcEntry:GetModel(ItemGetModel)
    Model:SetDataList(Param.PrizeItemList)
    Model:SetCustomerTittle(Param.Title)
    Model:SetCustomerHint(Param.Tips)
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = {}
    self.BindNodes = {
        -- {UDelegate = self.Button_BGClose.OnClicked,				Func = self.OnClicked_BGClose},

    }

    --默认隐藏按钮，需要的话通过传参来启用
    self.WBP_CommonBtn_Left:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_CommonBtn_Right:SetVisibility(UE.ESlateVisibility.Collapsed)

    ItemGetMdt.Const = ItemGetMdt.Const or {
        DefaultItemInfo = {                                                     --物品列表默认参数
            clickFunc           = CommonItemIcon.CLICK_FUNC_TYPE.NONE,          --点击无响应
            hoverFunc           = CommonItemIcon.HOVER_FUNC_TYPE.TIP,           --hover有tip
            hoverScaleRate      = 1.15,                                         --hover默认缩放
        },
        DefaultLeftBtnInfo = {                                                  --左侧按钮默认信息，没有传则不显示
            name                = G_ConfigHelper:GetStrFromCommonStaticST("Lua_ItemGetMdt_cancel"),                                         --默认文字展示
            iconID              = CommonConst.CT_ESC,                           --默认图标展示
            actionMappingKey    = ActionMappings.Escape,                        --默认按键映射
            style               = WCommonBtnTips.HoverFontStyleType.Main,       --默认样式
        },
        DefaultRightBtnInfo = {                                                 --右侧按钮默认信息，没有传则不显示
            name                = G_ConfigHelper:GetStrFromCommonStaticST("Lua_ItemGetMdt_confirm"),                                         --默认文字展示
            iconID              = CommonConst.CT_SPACE,                         --默认图标展示
            actionMappingKey    = ActionMappings.SpaceBar,                      --默认按键映射
            style               = WCommonBtnTips.HoverFontStyleType.Main,       --默认样式
        }
    }

    ---@type ItemGetModel
    -- local Model = MvcEntry:GetModel(ItemGetModel)
    local PopUpBgParam = {
        -- TitleText = StringUtil.Format(Model:GetTittleText()),
        CloseCb = Bind(self,self.OnClicked_BGClose),
        HideCloseTip = false,
    }
    self.CommonPopUpWigetLogic = UIHandler.New(self,self.WBP_CommonPopUp_Bg_L,CommonPopUpBgLogic,PopUpBgParam).ViewInstance 
end

---打开界面时处理一下界面文字展示，及列表内容刷新
---调用接口、Param数据格式请参考
---@see ItemGetCtrl#ShowItemGet
function M:OnShow(Param)
    --0.初始化数据
     Param = Param or {}
    self.itemWidgetList = {}

    --1.Esc按键功能处理，如果不存在冲突，则使用Esc可以关闭界面
    --如果不存在Esc键冲突，则使用Esc键作为关闭界面按键
    --左键检查，左键默认是Esc，需要检查是否存在冲突
    if Param and Param.leftBtnInfo then 
        if not Param.leftBtnInfo.actionMappingKey then
            CWaring("[cw] not Param.leftBtnInfo.actionMappingKey, means it use Default Esc for action, default Esc close function will not Regist")
        elseif Param.leftBtnInfo.actionMappingKey == ActionMappings.Escape then
            CWaring("[cw] Param.leftBtnInfo.actionMappingKey == ActionMappings.Escape, default Esc close function will not Regist")
        else
            table.insert(self.MsgList, {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = Bind(self, self.OnClicked_BGClose) })
            self:ReRegister()
        end
    --右键检查，只要不是Esc就行
    elseif Param and Param.rightBtnInfo and Param.rightBtnInfo.actionMappingKey and Param.rightBtnInfo.actionMappingKey == ActionMappings.Escape then
        CWaring("[cw] Param.rightBtnInfo.actionMappingKey == ActionMappings.Escape, default Esc close function will not Regist")
    --左右键都没有，则可以注册Esc关闭功能
    else
        table.insert(self.MsgList, {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = Bind(self, self.OnClicked_BGClose) })        
        self:ReRegister()
    end

    --2.设置标题
    -- self.TextBlock_Title:SetText(Model:GetTittleText())
    ---@type ItemGetModel
    local Model = MvcEntry:GetModel(ItemGetModel)
    if self.CommonPopUpWigetLogic then
        self.CommonPopUpWigetLogic:UpdateTitleText(StringUtil.Format(Model:GetTittleText()))	
    end

    --3.设置提示
    self.TextBlock_Tips:SetText(Model:GetHintText())

    --4.计算 WBP_ReuseList 控件的Offset，使需要展示的物品居中显示
    --4.1.获取基础数据(后续如有相似需求，修改这一部分参数即可)
    local reuseListWidget = self.WBP_ReuseList
    local dataLength = Model:GetLength()
    local reuseListSizeX = reuseListWidget.Slot:GetSize().X
    local reuseListSizeY = reuseListWidget.Slot:GetSize().Y
    local reuseListItemSize = reuseListWidget:GetItemWidth()
    local reuseListItemOffsetX = reuseListWidget:GetPaddingX()
    local reuseListItemOffsetY = reuseListWidget:GetPaddingY()
    --4.2.计算每一行最大支持多少个item，并计算间隔
    local maxColItemNum = (reuseListSizeX + reuseListItemOffsetX)//(reuseListItemSize + reuseListItemOffsetX)
    local colCount = math.min(dataLength, maxColItemNum)
    local rowCount = math.ceil(dataLength/colCount)
    local totalWidth = reuseListWidget:GetItemInitPaddingX() + (reuseListItemSize + reuseListItemOffsetX) * colCount - reuseListItemOffsetX
    local totalHeight = reuseListWidget:GetItemInitPaddingY() + (reuseListItemSize + reuseListItemOffsetY) * rowCount - reuseListItemOffsetY
    local totalOffsetX = reuseListSizeX - totalWidth
    local halfOffsetX = totalOffsetX/2
    --4.3.赋值，设置Offset，使需要展示的内容居中显示
    local newOffset = reuseListWidget.Slot:GetOffsets()
    newOffset.Left = halfOffsetX
    newOffset.Bottom = math.min(reuseListSizeY,totalHeight)
    reuseListWidget.Slot:SetOffsets(newOffset)
        
    --5.列表处理
    reuseListWidget.OnUpdateItem:Add(self, self.OnUpdateItem)
    reuseListWidget:Reload(dataLength)
    
    --6.按钮处理
    self:UpdateLeftBtnDisplay(Param.leftBtnInfo)
    self:UpdateRightBtnDisplay(Param.rightBtnInfo)

    -- 频繁打开关闭此界面，这个全屏按钮会概率不进入OnMouseEnter，从而不进入Hover状态，导致点击无效
    -- 故加此接口，打开界面强行将Hover设置为true。 @chenyishui
    -- self.Button_BGClose:ForceSetHoveredAttribute(true)
end

function M:OnRepeatShow(Param)
    self:OnShow(Param)
end

function M:OnHide()
    self.WBP_ReuseList.OnUpdateItem:Clear()
    self.itemWidgetList = {}
end

function M:UpdateLeftBtnDisplay(BtnInfo)
    if not BtnInfo then return end
    
    UIHandler.New(self, self.WBP_CommonBtn_Left, WCommonBtnTips,
            {
                OnItemClick = BtnInfo.callback and Bind(self, BtnInfo.callback) or Bind(self, self.OnClicked_BGClose),
                CommonTipsID = BtnInfo.iconID or ItemGetMdt.Const.DefaultLeftBtnInfo.iconID,
                TipStr = BtnInfo.name or ItemGetMdt.Const.DefaultLeftBtnInfo.name,
                ActionMappingKey = BtnInfo.actionMappingKey or ItemGetMdt.Const.DefaultLeftBtnInfo.actionMappingKey,
                HoverFontStyleType = BtnInfo.style or ItemGetMdt.Const.DefaultLeftBtnInfo.style,
            })

    self.WBP_CommonBtn_Left:SetVisibility(UE.ESlateVisibility.Visible)
end

function M:UpdateRightBtnDisplay(BtnInfo)
    if not BtnInfo then return end
    
    UIHandler.New(self, self.WBP_CommonBtn_Right, WCommonBtnTips,
            {
                OnItemClick = BtnInfo.callback and Bind(self, BtnInfo.callback) or Bind(self, self.OnClicked_BGClose),
                CommonTipsID = BtnInfo.iconID or ItemGetMdt.Const.DefaultRightBtnInfo.iconID,
                TipStr = BtnInfo.name or ItemGetMdt.Const.DefaultRightBtnInfo.name,
                ActionMappingKey = BtnInfo.actionMappingKey or ItemGetMdt.Const.DefaultRightBtnInfo.actionMappingKey,
                HoverFontStyleType = BtnInfo.style or ItemGetMdt.Const.DefaultRightBtnInfo.style,
            })
    
    self.WBP_CommonBtn_Right:SetVisibility(UE.ESlateVisibility.Visible)
end

---如果当前的widget并没有被UIHandler给初始化过，就初始化一次，否则直接读取缓存就行
---@return CommonItemIcon
function M:CreateItem(Widget)
    local Item = self.itemWidgetList[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, CommonItemIcon)
        self.itemWidgetList[Widget] = Item
    end
    return Item.ViewInstance
end

---更新中间物品的显示
function M:OnUpdateItem(Widget, Index)
    --1.数据读取及控件判空保护
    local FixIndex = Index + 1
    ---@type ItemGetModel
    local Model = MvcEntry:GetModel(ItemGetModel)
    local Data = Model:GetDataList()[FixIndex]
    if Data == nil then CError("[cw] self.DataList[" .. tostring(Index) .. "] is nil, please check it") CError(debug.traceback()) return end

    local TargetItem = self:CreateItem(Widget)
    if TargetItem == nil then CError("[cw] TargetItem of index(" .. tostring(Index) .. ") is nil, please check it") CError(debug.traceback()) return end

    --2.更新通用物品组件，使用内部UpdateUI接口更新显示
    local param = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = Data.ItemId,
        ItemNum = Data.ItemNum,
        DecomposeInfo = Data.DecomposeInfo,
        ClickFuncType = Data.ClickFuncType or ItemGetMdt.Const.DefaultItemInfo.clickFunc,
        HoverFuncType = Data.HoverFuncType or ItemGetMdt.Const.DefaultItemInfo.hoverFunc,
        HoverScale = Data.HoverScale or ItemGetMdt.Const.DefaultItemInfo.hoverScaleRate,
    }
    TargetItem:UpdateUI(param)
end

---按钮点击函数
function M:OnClicked_BGClose()
    -- self:RemoveFromParent()
    MvcEntry:CloseView(self.viewId)
    -- 检测是否还有奖励展示
    MvcEntry:GetCtrl(ItemGetCtrl):CheckHaveItemGetNeedToShow()
end

return M