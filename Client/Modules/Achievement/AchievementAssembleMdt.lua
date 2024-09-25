local AchievementConst = require("Client.Modules.Achievement.AchievementConst")
local AchievementAssembleListItemGroup = require("Client.Modules.Achievement.AchievementAssembleListItemGroup")
local AchievementAssembleSlotItem = require("Client.Modules.Achievement.AchievementAssembleSlotItem")
--- 视图控制器
local class_name = "AchievementAssembleMdt";
AchievementAssembleMdt = AchievementAssembleMdt or BaseClass(GameMediator, class_name);

function AchievementAssembleMdt:__init()
    self:ConfigViewId(ViewConst.AchievementAssemble)
end

function AchievementAssembleMdt:OnShow(data)
    
end

function AchievementAssembleMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    -- self.MsgList = 
    -- {
	-- 	{Model = AchievementModel, MsgName = ListModel.ON_UPDATED, Func = self.OnAchievementUpdate},
    -- }
    self:InitViewWidget()

    self.MsgList = 
	{
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnCloseFunc},
	}

    self.BindNodes = 
    {
		{ UDelegate = self.WBP_CommonPopPanel.BtnOutSide.OnClicked,				    Func = Bind(self,self.OnCloseFunc)},
        --{ UDelegate = self.WBP_CommonBtn_Close.GUIButton_Main.OnClicked,	Func = Bind(self,self.OnCloseFunc) },
        {UDelegate = self.Widget.WBP_ReuseListEx.OnUpdateItem,Func = Bind(self, self.OnUpdateItem)},
        {UDelegate = self.Widget.WBP_ReuseListEx.OnPreUpdateItem,Func = Bind(self, self.OnPreUpdateItem)},
	}

    self.Model = MvcEntry:GetModel(AchievementModel)
    self:InitTabInfo()

    self.SlotListCls = {}
    for i = 1, 3 do
        self.SlotListCls[i] = UIHandler.New(self, self.Widget["WBP_Achievement_Slot_"..i], AchievementAssembleSlotItem, {
            Index = i,
            SlotClickCallBack = Bind(self, self.SlotClickCallBack)
        }).ViewInstance
    end
    self.MoveItem:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function M:InitViewWidget()
    local PopParam = {
        TitleStr = "",
        ContentType = CommonPopUpPanel.ContentType.Content,
        CloseCb = Bind(self, self.OnCloseFunc),
    }
    self.CommonPopUpPanel = UIHandler.New(self, self.WBP_CommonPopPanel, CommonPopUpPanel, PopParam).ViewInstance

    local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Achievement/WBP_Achievement_AssemblyPop_New.WBP_Achievement_AssemblyPop_New")
    self.Widget = NewObject(WidgetClass, self)
    UIRoot.AddChildToPanel(self.Widget, self.CommonPopUpPanel:GetContentPanel())
    self.Widget.Slot:SetAutoSize(true)
    self.MoveItem = self.Widget.MoveItem
end

function M:InitTabInfo()
    local TypeTabParam = {
        ClickCallBack = Bind(self, self.OnTypeBtnClick),
        ValidCheck = Bind(self, self.TypeValidCheck),
        HideInitTrigger = true
    }
    TypeTabParam.ItemInfoList = {}

    local GroupConfigs = G_ConfigHelper:GetDict(Cfg_AchievementGroupConfig)
    for _, Cfg in ipairs(GroupConfigs) do

        local TabItemInfo = {
            Id = Cfg[Cfg_AchievementGroupConfig_P.TypeGroup],
            LabelStr = Cfg[Cfg_AchievementGroupConfig_P.TypeName],
        }
        TypeTabParam.ItemInfoList[#TypeTabParam.ItemInfoList + 1] = TabItemInfo
    end

    self.TabListCls = UIHandler.New(self, self.Widget.WBP_Common_TabUp_03, CommonMenuTabUp, TypeTabParam).ViewInstance
    self.TabIndex = 0
end

function M:OnHide()
    self.DataList = nil
    self.Widget2Item = nil
    self.SlotListCls = nil
end

function M:OnShow(Params)
    print("============ AchievementAssembleMdt")
    self.DataList = {}
    self.Widget2Item = {}

    self.WBP_CommonPopPanel.WidgetSwitcher_Title:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_CommonPopPanel.GUISizeBox_2:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self.WBP_CommonPopPanel.Panel_bg:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_CommonPopPanel.WidgetSwitcher_Content:SetActiveWidgetIndex(3)
    self.WBP_CommonPopPanel.WBP_Btn_close:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TabListCls:Switch2MenuTab(0 ,true)

end

function M:OnTypeBtnClick(Index, ItemInfo, IsInit)
    self.DataList = {}
    local DataList = G_ConfigHelper:GetMultiItemsByKey(Cfg_AchievementCategoryConfig,Cfg_AchievementCategoryConfig_P.TypeGroup,ItemInfo.Id)
    local TempCutRepeatData = {}
    for _,v in ipairs(DataList) do
        local TypeId = v[Cfg_AchievementCategoryConfig_P.TypeGroup]
        local TempDataList = self.Model:GetCompleteListByType(TypeId)
        if TempDataList and #TempDataList > 0 then
            local TempList = {}
            for i, ItemId in ipairs(TempDataList) do
                if not TempCutRepeatData[ItemId] then
                    if i % 6 == 0 then --当前视觉一排放6个
                        table.insert(TempList, ItemId)
                        table.insert(self.DataList, {Style = 0, TypeId = TypeId, List = TempList})
                        TempList = {}
                    else
                        table.insert(TempList, ItemId)
                    end
                    TempCutRepeatData[ItemId] = ItemId
                end
            end
            if #TempList > 0 then
                table.insert(self.DataList, {Style = 0, TypeId = TypeId, List = TempList})
            end
        end
    end

    if #self.DataList == 0 then
        self.Widget.WidgetSwitcher:SetActiveWidgetIndex(0)
    else
        self.Widget.WBP_ReuseListEx:Reload(#self.DataList)
        self.Widget.WidgetSwitcher:SetActiveWidgetIndex(1)
    end
end

function M:TypeValidCheck(Type)
    return true
end

function M:CreateItem(Widget, Data)
    local Item = self.Widget2Item[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, AchievementAssembleListItemGroup)
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function M:OnUpdateItem(_, Widget, Index)
    local FixIndex = Index + 1
    local Data = self.DataList[FixIndex]
    if Data == nil then
        return
    end
    if Data.Style == 1 then
        if Widget.Text_Title then
            Widget.Text_Title:SetText(StringUtil.FormatText(Data.NameStr))
        end
    else
        local TargetItem = self:CreateItem(Widget, Data)
        if TargetItem == nil then
            return
        end
        TargetItem:SetData(Data.List, Bind(self, self.OnItemCallBack))
    end
end

function M:OnPreUpdateItem(_, Index)
    local FixIndex = Index + 1
    local Data = self.DataList[FixIndex]
    if Data ~= nil then
        self.Widget.WBP_ReuseListEx:ChangeItemClassForIndex(Index, Data.Style)
    end
end

function M:OnCloseFunc()
    MvcEntry:CloseView(ViewConst.AchievementAssemble)
end

function M:OnItemCallBack(Id, Type)
    self.SelectId = nil
    local Data = self.Model:GetData(Id)
    if not Data or not Data:IsUnlock() or Data:IsEquiped() then
        return
    end
    self.IsMoving = Type == CommonConst.DRAG_TYPE_DEFINE.DRAG_END
    if Type == CommonConst.DRAG_TYPE_DEFINE.DRAG_BEGIN then
        self:SetSlotsBtnShow(true) --拖拽开始的时候得释放出上层Btn以接收事件监听
        self.AutoHideTimer = Timer.InsertTimer(Timer.NEXT_TICK,function()
            local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
            local _,CurViewPortPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(self, MousePos)
            CurViewPortPos.Y = CurViewPortPos.Y - 250
            self.MoveItem.Slot:SetPosition(CurViewPortPos)
        end, true)

        self.MoveItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
            ItemId = Id,
        }
        if self.MoveItemIns then
            self.MoveItemIns:UpdateUI(IconParam)
        else
            self.MoveItemIns = UIHandler.New(self, self.MoveItem, CommonItemIcon, IconParam).ViewInstance
        end
        -- self.MoveItemIns:UpdateSubScriptScale(0.75)
    else
        if self.AutoHideTimer then
            Timer.RemoveTimer(self.AutoHideTimer)
        end
        self.AutoHideTimer = nil    
        self.MoveItem:SetVisibility(UE.ESlateVisibility.Collapsed)
        if self.MoveItemIns then
            self.MoveItemIns:OnHide()
        end
    end
    if Type == CommonConst.DRAG_TYPE_DEFINE.DRAG_BEGIN or Type == CommonConst.DRAG_TYPE_DEFINE.CLICK then
        self:RefreshSlotState(1)
    end
    print("============ OnItemCallBack", Id, Type)
    self.SelectId = Id
    if Type == CommonConst.DRAG_TYPE_DEFINE.DRAG_END then
        Timer.InsertTimer(0.3,function()
            self.SelectId = nil
            self:RefreshSlotState(0)
            self:SetSlotsBtnShow(false) --【有个未发现的bug先顺便本地提前修复下】拖拽结束的时候得屏蔽上层Btn，避免干扰底部通用Item的按钮Hover事件，影响动画效果
        end)
    end
end
function M:SlotClickCallBack(Index, Type, Data)
    -- print("============ SlotClickCallBack", Index, Type, self.SelectId, self.IsMoving)
    if Type == 1 and not self.IsMoving then
        return
    end

    if not self.SelectId then
        if Data then
            Data.Deleted = Type == 0 --新增Delete状态支持
            if Type == 0 then
                MvcEntry:GetCtrl(AchievementCtrl):EquipSlotAchieveReq(Data.ID, 0)
            end
        end
        return
    end
    self:RefreshSlotState(0)
    MvcEntry:GetCtrl(AchievementCtrl):EquipSlotAchieveReq(self.SelectId, Index)
    self.SelectId = nil
end

function M:RefreshSlotState(Index)
    for i = 1, 3 do
        self.SlotListCls[i]:SetActiveWidgetIndex(Index ~= 1 and Index or 0) --状态为1的部分目前已无效，仅仅作为支持老逻辑
        self.SlotListCls[i]:UpdateCornerTag(Index == 1 and CornerTagCfg.Replace.TagId or CornerTagCfg.Delete.TagId)
        self.SlotListCls[i]:PlayEffectBySelect(Index == 1)
    end
end

function M:SetSlotsBtnShow(InCanShow)
    for i = 1, 3 do
        self.SlotListCls[i]:SetBtnShow(InCanShow)
    end
end


return M
