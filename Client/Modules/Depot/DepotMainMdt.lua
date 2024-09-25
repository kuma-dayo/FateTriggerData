--[[
    仓库主界面
]]

local class_name = "DepotMainMdt";
DepotMainMdt = DepotMainMdt or BaseClass(GameMediator, class_name);

local MaxShowNum = 99999999

function DepotMainMdt:__init()
end

function DepotMainMdt:OnShow(data)
    
end

function DepotMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.MsgList = 
    {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.GUIButton_Close_ClickFunc},
		{Model = DepotModel, MsgName = ListModel.ON_UPDATED, Func = self.OnDepotUpdate},
    }

    self.BindNodes = 
    {
		{ UDelegate = self.WBP_ThingReuseList.OnUpdateItem,		Func = self.OnUpdateItem },
	}
    self.Model = MvcEntry:GetModel(DepotModel)
    self.CurTabType = 0 -- 当前选中页签

    self:ResetSelect()

    self.UseBtnStr = {
        [Pb_Enum_ITEM_USE_TYPE.ITEM_USE_DROPID] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotMainMdt_use_Btn"),
        [Pb_Enum_ITEM_USE_TYPE.ITEM_USE_COMPOSE_ITEM] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotMainMdt_Compose"),
        [Pb_Enum_ITEM_USE_TYPE.ITEM_USE_ADD_GOLD_COF] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotMainMdt_use_Btn"),
        [Pb_Enum_ITEM_USE_TYPE.ITEM_USE_ADD_EXP_COF] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotMainMdt_use_Btn"),
    }

    self:InitBtns()
    self:InitTypeTab()
end

function M:OnHide()
    self.CurTabType = 0
    self.TabListCls = nil
    self.WBP_ThingReuseList.OnUpdateItem:Clear()
    self:ClearTimeShowTick()

    self.ItemIconClsList = {}
    self.Widget2ItemIconCls = {}
end

-- 通用按钮定义
function M:InitBtns()
    -- 返回
    UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.GUIButton_Close_ClickFunc),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotMainMdt_return_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })

    -- 使用
    self.UseBtnCls = UIHandler.New(self, self.GUIButton_Use, WCommonBtnTips, 
    {
        OnItemClick = Bind(self, self.GUIButton_Use_ClickFunc),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotMainMdt_use_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar
    }).ViewInstance
end

-- 初始化分类页签
function M:InitTypeTab()
    self.TabTypeList = {}   -- Type页签下包含的 道具类型(道具子类型) 列表
    local TypeTabParam = {
        ClickCallBack = Bind(self,self.OnTypeBtnClick),
        ValidCheck = Bind(self,self.TypeValidCheck),
        HideInitTrigger = true,
        IsOpenKeyboardSwitch = true,
	}
    TypeTabParam.ItemInfoList = {}
    local TabList = self.Model:GetDepotTabList()
    for Index,TabInfo in ipairs(TabList) do
        self.TabTypeList[TabInfo.TabType] = TabInfo.TypeList
        -- if Index > 1 then
        --     Widget.Padding.Left = -10
        -- end
        local TabItemInfo = {
            Id = Index,
            LabelStr = TabInfo.TabName,
        }
        TypeTabParam.ItemInfoList[#TypeTabParam.ItemInfoList + 1] = TabItemInfo
    end
    local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","1357"),
        CurrencyIDs = {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND},
        TabParam = TypeTabParam
    }
    self.TabListCls = UIHandler.New(self,self.WBP_Common_TabUpBar_02, CommonTabUpBar,CommonTabUpBarParam).ViewInstance
end

--仓库数据更新
function M:OnDepotUpdate()
    self:UpdateItemList()
end

--由mdt触发调用
--[[
    Param = {
        TabType  可指定选中页签  
    }
]]
function M:OnShow(Params)
    self.CurSelectType = 0
    if Params and Params.TabType then
        self.CurSelectType = Params.TabType
    end
    self.TabListCls:Switch2MenuTab(self.CurSelectType + 1,true)
    self.ItemIconClsList = {}
    self.Widget2ItemIconCls = {}
end

-- 重置选中回第一个格子
function M:ResetSelect()
    self.CurSelectItemIndex = 1 -- 当前页签下选中的格子索引 （由Id去定索引，Id为空选第一个）
    self.CurSelectItemId = nil -- 当前选中的道具Id
    self.NextSelectItemId = nil -- 当前选中的道具下一个格子的道具Id
    self:UpdateSelectItemId()
end

function M:UpdateItemList(IsReset)
    local TypeList =  self.TabTypeList[self.CurTabType]
    if not TypeList then
        -- 全部
        self.ItemList = self.Model:GetDepotItemList()
    else
        self.ItemList = {}
        -- 合并该页签包含的所有指定物品类型列表
        for ItemType, SubTypeList in pairs(TypeList) do
            local List = self.Model:GetDepotItemList(ItemType,SubTypeList)
            if List and #List > 0 then
                ListMerge(self.ItemList,List)
            end
        end
        -- 合并后重新排序
        self.ItemList = self.Model:SortItems(self.ItemList)
    end
    self.WidgetSwitcher_State:SetActiveWidget(#self.ItemList > 0 and self.Panel_Content or self.EmptyTips)
    if IsReset then
        --重置选择分页第一个物品
        self:ResetSelect()
    else
        -- 数据发生变动，要重新遍历找回原先选中的索引，更新当前选中
        if not (self.CurSelectItemId or self.NextSelectItemId) then
            self:ResetSelect()
        else
            local CurSelectIndex, NextSelectIndex = nil,nil
            -- for Index,Item in ipairs(self.ItemList) do
            -- 修改为倒序查找，使用道具后，数量少的会往后排、
            for Index = #self.ItemList, 1, -1 do
                local Item = self.ItemList[Index]
                if self.CurSelectItemId and Item.ItemId == self.CurSelectItemId then
                    CurSelectIndex = Index
                    -- 能找到原先选中的，就选中该项
                    break
                end
                if self.NextSelectItemId and Item.ItemId == self.NextSelectItemId then
                    NextSelectIndex = Index
                end
            end
            self.CurSelectItemIndex = CurSelectIndex or NextSelectIndex or 1
            -- 更新了选中位置，要重新更新当前选中物品和下个选中物品
            self:UpdateSelectItemId()
        end
    end
    if #self.ItemList > 0 then
        local Num = math.max(80, #self.ItemList)
        self.WBP_ThingReuseList:Reload(Num)
    end
    if IsReset then
        self.WBP_ThingReuseList:ScrollToStart()
    end
    self:UpdateItemDetail()
end

function M:OnUpdateItem(Widget, I)
    local Index = I + 1
    local ItemData = self.ItemList[Index]
    local IconParam = {
        ShowEmpty = true,
    }
    
    if ItemData then
        IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = ItemData.ItemId,
            ItemUniqId = ItemData.ItemUniqId,
            ItemNum = ItemData.ItemNum,
            OmitWhenOverMax = true,
            ExpireTime = ItemData.ExpireTime,
            ClickCallBackFunc = Bind(self,self.OnItemClick,Index),
            IsBreakClick = true,
            HoverScale = 1.15,
            RedDotKey = "DepotItem_",
            RedDotSuffix = ItemData.ItemUniqId,
            RedDotInteractType = CommonConst.RED_DOT_INTERACT_TYPE.CLICK,
        }
    end
    local ItemIconCls = self.Widget2ItemIconCls[Widget]
    if not ItemIconCls then
        ItemIconCls = UIHandler.New(self,Widget,CommonItemIcon,IconParam).ViewInstance
        self.Widget2ItemIconCls[Widget] = ItemIconCls
    else
        ItemIconCls:UpdateUI(IconParam)
    end
    self.ItemIconClsList[Index] = ItemIconCls
    local IsSelected = self.CurSelectItemIndex == Index
    ItemIconCls:SetIsSelect(IsSelected,true)
end

function M:OnTypeBtnClick(Index,ItemInfo,IsInit)
    self.CurTabType = Index - 1
    self:UpdateItemList(true)
end

function M:TypeValidCheck(Type)
    return true
end

-- 点击道具
function M:OnItemClick(Index,Param)
    if self.CurSelectItemIndex ~= Index and self.ItemIconClsList[self.CurSelectItemIndex] then
        self.ItemIconClsList[self.CurSelectItemIndex]:SetIsSelect(false,true)
    end
    self.CurSelectItemIndex = Index
    if not self.ItemList[self.CurSelectItemIndex] then
        CError("DepotMainMdt OnItemClick can't get iteminfo for index"..self.CurSelectItemIndex)
        print_trackback() 
    end
    self:UpdateSelectItemId()
    self.ItemIconClsList[self.CurSelectItemIndex]:SetIsSelect(true,true)
    self:UpdateItemDetail()
end

    -- 选中当前的，记录下一个格子的道具id，如果没下一个格子就选上一个 - 用于当前道具使用消耗完，要切到下一个格子去选中
function M:UpdateSelectItemId()
    if not self.ItemList or #self.ItemList == 0 then
        self.CurSelectItemId = nil
        self.NextSelectItemId = nil
        return
    end
    self.CurSelectItemId = self.ItemList[self.CurSelectItemIndex].ItemId
    if self.ItemList[self.CurSelectItemIndex + 1] then
        self.NextSelectItemId = self.ItemList[self.CurSelectItemIndex + 1].ItemId
    elseif self.ItemList[self.CurSelectItemIndex - 1] then
        self.NextSelectItemId = self.ItemList[self.CurSelectItemIndex - 1].ItemId
    else
        self.NextSelectItemId = nil
    end
end

-- 刷新右侧物品详情内容显示
function M:UpdateItemDetail()
    if not (self.ItemList and self.CurSelectItemIndex and self.ItemList[self.CurSelectItemIndex]) then
        -- 没有可选择的物品
        return
    end
    local SelectedItem = self.ItemList[self.CurSelectItemIndex]
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,SelectedItem.ItemId)
    if not ItemCfg then
        return
    end
    -- 品质相关
    local Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
    if QualityCfg then
        CommonUtil.SetBrushFromSoftObjectPath(self.Image_QualityBg,QualityCfg[Cfg_ItemQualityColorCfg_P.DepotImgBg])
    end
    local Widgets = {
        QualityBar = self.Image_QualityLine,
        QualityIcon = self.Image_IconQuality,
        -- QualityLevelText = self.WBP_CommonQualityLevel.GUITextBlock_QualityLevel,
    }
    CommonUtil.SetQualityShow(SelectedItem.ItemId,Widgets)
    -- 名称
    self.LbName:SetText(StringUtil.Format(ItemCfg[Cfg_ItemConfig_P.Name]))
    -- 品类名称
    self.Text_TypeName:SetText(StringUtil.Format(self.Model:GetItemTypeShowByItemId(SelectedItem.ItemId,true)))
    -- 数量显示的是总数量，不是单个堆叠数量
    local ItemNum = self.Model:GetItemCountByUniqId(SelectedItem.ItemUniqId)
    if ItemNum >= 1 then
        -- self.LbNum:SetText(StringUtil.Format("数量:{0}",ItemNum > 999 and "999+" or ItemNum))
        if ItemNum > MaxShowNum then
            self.LbNum:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_12"),MaxShowNum)) --x{0}+
        else
            self.LbNum:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_8"),ItemNum)) --x{0}
        end
    end
    -- 大图
    -- local DetailImg = LoadObject(ItemCfg[Cfg_ItemConfig_P.ImagePath])
    -- if DetailImg then
    --     self.ItemDetailImg:SetBrushFromTexture(DetailImg)
    -- end
    if ItemCfg[Cfg_ItemConfig_P.ImagePath] ~= "" then
        self.ItemDetailImg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.ItemDetailImg,ItemCfg[Cfg_ItemConfig_P.ImagePath],true)
    else
        CWaring("ItemCfg Can't Get ImgPath for id = "..SelectedItem.ItemId)
        self.ItemDetailImg:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    -- 描述
    self.LbTitle:SetText(ItemCfg[Cfg_ItemConfig_P.Des])
    self.LbDetails:SetText(ItemCfg[Cfg_ItemConfig_P.DetailDes])
    -- 达到上限/已拥有 文本提示
    local MaxCount = ItemCfg[Cfg_ItemConfig_P.MaxCount]
    if MaxCount > 0 and ItemNum >= MaxCount then
        self.Text_FullTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Text_FullTips:SetText(StringUtil.Format(MaxCount>1 and G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotMainMdt_Reachtheupperlimit") or G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotMainMdt_Alreadyowned")))
    else
        self.Text_FullTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    -- 时间
    self.LeftTime = SelectedItem.ExpireTime > 0 and SelectedItem.ExpireTime - GetTimestamp() or 0
    if self.LeftTime > 0 then
        self.OverlayDate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:UpdateTimeShow()
        self:ScheduleTimeShowTick()
    else
        self:ClearTimeShowTick()
        self.OverlayDate:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    -- 按钮处理
    local UseType = ItemCfg[Cfg_ItemConfig_P.UseType] 
    local CanUse = self.Model:CanItemUseForUseType(UseType)
    self.UseBtnCls.View:SetVisibility(CanUse and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    if CanUse then
        self.UseBtnCls:SetTipsStr(StringUtil.Format(self.UseBtnStr[UseType] or G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotMainMdt_use_Btn")))
    end
end

-- 更新剩余时间显示
function M:UpdateTimeShow()
    if not CommonUtil.IsValid(self) then
        self:ClearTimeShowTick()
        print("DepotMainMdt Already Releaed")
        return
    end
    if not self.ItemList[self.CurSelectItemIndex] then
        return
    end
    local Str,Color = StringUtil.Conv_TimeShowStr(self.LeftTime,self.ItemList[self.CurSelectItemIndex].ExpireTime)
    self.LbDateTime:SetText(Str)
    CommonUtil.SetTextColorFromeHex(self.LbDateTime,Color)
    CommonUtil.SetBrushTintColorFromHex(self.GUIImage_Time,Color)
end

--关闭界面
function M:DoClose()
    MvcEntry:CloseView(self.viewId)
    return true
end

-- 点击关闭
function M:GUIButton_Close_ClickFunc()
    self:DoClose()
    return true
end

-- 点击使用按钮
function M:GUIButton_Use_ClickFunc()
    local SelectedItem = self.ItemList[self.CurSelectItemIndex]
    if not SelectedItem then
        return
    end
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,SelectedItem.ItemId)
    if not ItemCfg then
        return
    end
    local UseType = ItemCfg[Cfg_ItemConfig_P.UseType]
    -- TODO 这块后续应该需要整理成通用接口
    if UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_DROPID or UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_ADD_GOLD_COF or UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_ADD_EXP_COF then
        -- 手动使用
        -- TODO 后续可加上选择数量界面
        local UseCount =  1
        MvcEntry:GetCtrl(DepotCtrl):SendPlayerUseItemReq(SelectedItem.ItemId,UseCount,SelectedItem.ItemUniqId)
    elseif UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_COMPOSE_ITEM then
        -- 合成物品
        local CanCompose,NeedCount = self.Model:CanCompose(SelectedItem.ItemId)
        if CanCompose then
            MvcEntry:GetCtrl(DepotCtrl):SendPlayerUseItemReq(SelectedItem.ItemId,NeedCount,SelectedItem.ItemUniqId)
        end
        
    elseif UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_CLINET_OPEN_UI then
        local JumpId = tonumber(ItemCfg[Cfg_ItemConfig_P.UseParam])
        MvcEntry:GetCtrl(ViewJumpCtrl):JumpTo(JumpId)
    end
end

-- 时间刷新显示
function M:ScheduleTimeShowTick()
    self:ClearTimeShowTick()
    self.CheckTimer = Timer.InsertTimer(1,function()
        self.LeftTime = self.LeftTime - 1
		self:UpdateTimeShow()
        if self.LeftTime <= 0 then
            self:ClearTimeShowTick()
        end
	end,true)   
end

function M:ClearTimeShowTick()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

return M