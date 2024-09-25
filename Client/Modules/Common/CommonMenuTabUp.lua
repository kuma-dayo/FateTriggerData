--[[
    通用的CommonMenuTabUp控件 (tab分页)

    针对通用UMG蓝图  WBP_Common_TabUpBar_03
]]

local class_name = "CommonMenuTabUp"
---@class CommonMenuTabUp
CommonMenuTabUp = CommonMenuTabUp or BaseClass(nil, class_name)

--/Script/UMGEditor.WidgetBlueprint'/Game/BluePrints/UMG/Components/TabUpBar/WBP_Common_TabItem_03.WBP_Common_TabItem_03'
CommonMenuTabUp.TabItemTypeEnum = {
    TYPE1 = "WBP_Common_TabItem_01",
    TYPE2 = "WBP_Common_TabItem_02",
    TYPE3 = "WBP_Common_TabItem_03",
}

local TablePool = require("Common.Utils.TablePool")

function CommonMenuTabUp:OnInit()
    self.PageIndex2Widget = {}

    self.BindNodes = {}

    if self.View.Btn_LeftArrow and self.View.Btn_RightArrow then
        -- 兼容有些Tab没有这两个按钮
        local BindNodes = {
            { UDelegate = self.View.Btn_LeftArrow.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageArrowBtnClick,-1) },
            { UDelegate = self.View.Btn_RightArrow.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageArrowBtnClick,1) },
        }
        ListMerge(self.BindNodes,BindNodes)
    end
    self.SwitchBtnIcons = {
        [1] = {
            Left = self:GetTipsIconPath(CommonConst.CT_Q),
            Right = self:GetTipsIconPath(CommonConst.CT_E),
        },
        [2] = {
            Left = self:GetTipsIconPath(CommonConst.CT_Z),
            Right = self:GetTipsIconPath(CommonConst.CT_C),
        }
    }
end

--[[
    Param格式指引
	{
		ItemInfoList = {
            {
                --MenuId，可选，值为空则按下标顺序赋值
                Id, 
                --需要展示的文本 可选，值为空不做动作
                LabelStr
                NeedHide,
                -- 可选 红点前缀
                RedDotKey = self.RedDotKey,
                -- 可选 红点后缀
                RedDotSuffix = TabId,
                
            }
            ...
        },
        --当前选中的Id （可选，默认第一个）
        CurSelectId
        --是否规避掉第一次触发回调  默认不规避
        HideInitTrigger
        --点击Menu的固定回调，ID传值MenuId,ItemInfo传值对应Menu的描述信息 IsInit表示是否第一次
        ClickCallBack(Id,ItemInfo,IsInit)
        --MenuTab是否可用检测回调，需返回值
        ValidCheck(Id)
        --分页是否可用检测回调，需返回值
        ValidPageCheck(PageNum)
        -- 是否开启键盘Q/E切页, 默认不开启. 注：若开启，则 MenuId 必须连续
        IsOpenKeyboardSwitch
        --tabItem类型，会决定动态创建的Item资产不一样，默认是TYPE3
        TabItemType,
        --是否开启分页，开启后，同时展示的tab分页数量只有PageMaxNum数量，这时候QE到最后一项，会触发翻页
        PageMaxNum,
        --是否显示快捷翻页按钮，此按钮只针对开启分页启用，按钮响应会触发翻页
        ShowPageArrow,
        --是否page不可用时，仍然刷新页签展示，但不进行自动选中
        PageInvalidStillShow,
        --Item间隔 默认为0
        ItemPadding，
	}
]]
function CommonMenuTabUp:OnShow(Param)
    if not Param then
        return
    end
	self:UpdateUI(Param)
end

function CommonMenuTabUp:OnHide()
end

function CommonMenuTabUp:UpdateUI(Param)
    if not Param then
        CWaring("CommonMenuTabUp:UpdateUI Param nil")
        return
    end
    self.Param = Param
    
    if not self.Param.ItemInfoList or not self.Param.ClickCallBack then
        CError("CommonMenuTabUp:OnShow Param Invalid,Please Check!!!")
        return
    end
    if #self.Param.ItemInfoList <= 0 then
        CError("CommonMenuTabUp:OnShow self.Param.ItemInfoList <= 0,Please Check!!!")
        return
    end
    self.CurSelectTabId = -1
    self.AllTabId2Index = {}
    self.Param.ItemInfoList[1].Id = self.Param.ItemInfoList[1].Id or 1
    self.CurSelectTabId = self.Param.CurSelectId or self.Param.ItemInfoList[1].Id
    self.IdxToRedDotViewInstance = {}
    local CurSelectIndex = 1
    for Idx,ItemInfo in ipairs(self.Param.ItemInfoList) do
        ItemInfo.Idx = Idx
        ItemInfo.Id = ItemInfo.Id or Idx
        
        if self.CurSelectTabId == ItemInfo.Id then
            CurSelectIndex = Idx
        end
        self.AllTabId2Index[ItemInfo.Id] = Idx
    end
    self.MinIndex = 1
    self.MaxIndex = 1
    self.RedDotWidgetList = {}
    if not self.Param.TabItemType then
        self.Param.TabItemType = CommonMenuTabUp.TabItemTypeEnum.TYPE3
    end
    -- 类型2的时候默认加7.5像素间隔
    local DefaultItemPadding = self.Param.TabItemType == CommonMenuTabUp.TabItemTypeEnum.TYPE2 and 7.5 or 0
    self.ItemPadding = self.Param.ItemPadding or DefaultItemPadding
    
    self.PageMaxNum = self.Param.PageMaxNum or #self.Param.ItemInfoList
    self.PageSwitchFuncOpen = false
    if self.Param.PageMaxNum and #self.Param.ItemInfoList > self.PageMaxNum then
        self.PageSwitchFuncOpen = true
        self.MaxPageNum = math.floor(#self.Param.ItemInfoList/4) + 1
    end
    self.MinIndex = 1
    self.MaxIndex = self.PageMaxNum
    local BindNodesChange = false
    local index = 1
    for Idx=1,self.PageMaxNum do
        if not self.PageIndex2Widget[Idx] then
            local WidgetClass = UE.UClass.Load(StringUtil.FormatSimple("/Game/BluePrints/UMG/Components/TabUpBar/{0}.{0}",self.Param.TabItemType))
            local Widget = NewObject(WidgetClass, self.View)
            self.View.TabItemList:AddChild(Widget)
            self.PageIndex2Widget[Idx] = Widget

            Widget.Padding.Right = 0
            if Idx ~= self.PageMaxNum then
                Widget.Padding.Right = self.ItemPadding
            end
            Widget:SetPadding(Widget.Padding)
    

            local BindNodes = {
                {UDelegate = self.PageIndex2Widget[Idx].GUIButton_TabBg.OnClicked,Func = Bind(self,self.OnTabItemClickEvent,Idx)},
            }
            self.BindNodes = ListMerge(self.BindNodes,BindNodes)
            BindNodesChange = true
        else
            self.PageIndex2Widget[Idx]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
        --TODO:注册红点
        if self.Param.ItemInfoList and self.Param.ItemInfoList[Idx] and self.PageIndex2Widget[Idx] then
            self:RegCommonRedDot(Idx, self.PageIndex2Widget[Idx], self.Param.ItemInfoList[Idx].RedDotKey, self.Param.ItemInfoList[Idx].RedDotSuffix)
        end
        index = index + 1
    end

    --隐藏多余Widget
    while self.PageIndex2Widget[index] do
        self.PageIndex2Widget[index]:SetVisibility(UE.ESlateVisibility.Collapsed)
        index = index + 1
    end

    -- 开启键盘Q/E切页
    self.View.LeftSwitchTabIconLeft:SetVisibility((Param.IsOpenKeyboardSwitch or Param.IsOpenKeyboardSwitch2) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.RightSwitchTabIconRight:SetVisibility((Param.IsOpenKeyboardSwitch or Param.IsOpenKeyboardSwitch2) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if Param.IsOpenKeyboardSwitch then
        self.MsgList = {
            {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Q), Func = Bind(self,self.OnSwitchMenuTab,-1)},
		    {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.E), Func = Bind(self,self.OnSwitchMenuTab,1) },
        }
        self.InputFocus = true
        self:SetSwitchBtnIcon(1)
        
    elseif Param.IsOpenKeyboardSwitch2 then
        -- 开启键盘Z/C切页
        self.MsgList = {
            {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Z), Func = Bind(self,self.OnSwitchMenuTab,-1)},
		    {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.C), Func = Bind(self,self.OnSwitchMenuTab,1) },
        }
        self.InputFocus = true
        self:SetSwitchBtnIcon(2)
    end
    if BindNodesChange then
        self:ReRegister()
    end
    if self.View.PageArrowLeft and self.View.PageArrowRight then
        -- 兼容有些Tab没有这两个按钮
        if self.PageSwitchFuncOpen and self.Param.ShowPageArrow then
            self.View.PageArrowLeft:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.PageArrowRight:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.View.PageArrowLeft:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.PageArrowRight:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    self:UpdateCurSelect(self.CurSelectTabId)
    if self.Param.HideInitTrigger then
        if not self:CheckMenuTabValid(self.CurSelectTabId) then
            --当前选中不可用，参数错误
            CError("CommonMenuTabUp:OnShow CurSelectTabId Not Valid ,Please Check")
        end
    else
        self:OnTabItemClick(self.CurSelectTabId,true,true)
    end
end

---注册 红点 控件
function CommonMenuTabUp:RegCommonRedDot(Idx, Widget, RedDotKey, RedDotSuffix)
    if Widget.WBP_RedDotFactory then
        if RedDotKey and RedDotSuffix then
            Widget.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.IdxToRedDotViewInstance = self.IdxToRedDotViewInstance or {}
            local RedDotViewInstance = self.IdxToRedDotViewInstance[Idx]
            if RedDotViewInstance == nil then
                RedDotViewInstance = UIHandler.New(self,  Widget.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
                self.IdxToRedDotViewInstance[Idx] = RedDotViewInstance
            else 
                RedDotViewInstance:ChangeKey(RedDotKey, RedDotSuffix)
            end 
        else
            Widget.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

-- 红点触发逻辑
function CommonMenuTabUp:InteractRedDot(Idx)
    if self.IdxToRedDotViewInstance[Idx] then
        local RedDotViewInstance = self.IdxToRedDotViewInstance[Idx]
        if RedDotViewInstance then
            RedDotViewInstance:Interact()
        end 
    end
end

--[[
    重置内容
]]
function CommonMenuTabUp:Reset(Param)
    self:UpdateUI(Param)
end

--[[
    更新当前选中Tab显示
]]
function CommonMenuTabUp:UpdateCurSelect(SelectTabId)
    if self.CurSelectTabId < 0 then
        return
    end
    if SelectTabId then
        self.CurSelectTabId = SelectTabId
    end
    local CurSelectIndex = self.AllTabId2Index[self.CurSelectTabId]
    self.CurSelectPage = math.floor(CurSelectIndex/4) + 1
    if CurSelectIndex%4 == 0 then
        self.CurSelectPage = self.CurSelectPage - 1
    end
    self:UpdatePageShow()
    for Idx=1,self.PageMaxNum do
        local ItemListIndex = (self.CurSelectPage-1)*self.PageMaxNum + Idx
        local ItemInfo = self.Param.ItemInfoList[ItemListIndex]
        self:UpdateMenuItemShow(ItemInfo.Id,true)
    end
end

function CommonMenuTabUp:UpdateMenuItemShow(TabId,IsInit)
    if TabId == -1 then
        return
    end
    local MenuItem = self.TabId2Item[TabId]
    if not MenuItem then
        -- CError("CommonMenuTabUp:UpdateMenuItemShow MenuItem nil",true)
        return
    end
    local Idx = self.TabId2Index[TabId]
    -- CWaring("UpdateMenuItemShow:" .. Idx)
    -- CWaring("UpdateMenuItemShowMenuItem.Id:" .. MenuItem.Id)
    -- CWaring("self.CurSelectTabId:" .. self.CurSelectTabId)
    local Widget = self.PageIndex2Widget[Idx]
    self:UpdateWidgetSelectState(MenuItem.Id == self.CurSelectTabId,Widget,IsInit)
end

function CommonMenuTabUp:UpdateWidgetSelectState(IsSelect,Widget,IsInit)
    if not CommonUtil.IsValid(Widget) then
        CError("UpdateWidgetSelectState Widget Invalid!",true)
        return
    end
    if IsSelect then
        -- 选中态目标不再触发hover效果及点击反馈
        if Widget.GUIButton_TabBg then
            Widget.GUIButton_TabBg:SetIsEnabled(false)
        end
        if Widget.VXE_Btn_Selected then
            Widget:VXE_Btn_Selected()
        end
    else
        if Widget.VXE_Btn_UnSelected then
            Widget:VXE_Btn_UnSelected()
        end
        -- 选中态目标不再触发hover效果及点击反馈
        if Widget.GUIButton_TabBg then
            Widget.GUIButton_TabBg:SetIsEnabled(true)
        end
    end
end

--[[
    TabItem点击
    TabId
]]

function CommonMenuTabUp:OnTabItemClickEvent(Idx)
    local ItemListIndex = (self.CurSelectPage-1)*self.PageMaxNum + Idx
    local ItemInfo = self.Param.ItemInfoList[ItemListIndex]
    local TabId = ItemInfo.Id
    CWaring("CommonMenuTabUp:OnTabItemClickEvent:" .. TabId)
    self:OnTabItemClick(TabId)

    self:InteractRedDot(Idx)
end

function CommonMenuTabUp:OnTabItemClick(TabId,IsInit,IsForceSelect)
    if self.CurSelectTabId == TabId and not IsForceSelect then
        return
    end
    if not self:CheckMenuTabValid(TabId,true) then
        return
    end
    local LastSelectId = self.CurSelectTabId
    self.CurSelectTabId = TabId
    self:UpdateMenuItemShow(LastSelectId)
    self:UpdateMenuItemShow(self.CurSelectTabId)

    local MenuItem = self.TabId2Item[self.CurSelectTabId]
    if MenuItem and self.Param.ClickCallBack then
        self.Param.ClickCallBack(self.CurSelectTabId,MenuItem,IsInit)
    end
end


--[[
    检测MenuTab是否可切换
]]
function CommonMenuTabUp:CheckMenuTabValid(TabId,IsClickTrgger)
    if not self.Param.ValidCheck then
        return true
    end
    local Result = self.Param.ValidCheck(TabId,IsClickTrgger)
    if not Result then
        --MenuTab检测不可用
        return false
    end
    return true
end

--[[
    检测Page分页是否可切换
]]
function CommonMenuTabUp:CheckPageValid(Page)
    if not self.Param.ValidPageCheck then
        return true
    end
    local Result = self.Param.ValidPageCheck(Page)
    if not Result then
        --Page分页检测不可用
        return false
    end
    return true
end


--[[
    _RecursionTImes 作用为防止，所有Item不可用时,GetAvailableIndex递归调用死循环
]]
-- CommonMenuTabUp._RecursionTImes = 0
function CommonMenuTabUp:GetAvailableIndex(Direction, SelectTabId)
    -- if self._RecursionTImes > self.MaxIndex then
    --     return self.MinIndex
    -- end
    -- self._RecursionTImes = self._RecursionTImes + 1
    local IsPageChange = false
    local CurSelectIndex = self.TabId2Index[SelectTabId]
    local SelectIndex = Direction > 0 and CurSelectIndex + 1 or CurSelectIndex - 1
    local TheSelectPage = 0
    if SelectIndex > self.MaxIndex then
        SelectIndex = self.MinIndex
        if self.PageSwitchFuncOpen then
            if self.CurSelectPage < self.MaxPageNum then
                TheSelectPage = self.CurSelectPage + 1
                SelectIndex = self.MinIndex
                IsPageChange = true
            end
        end
    elseif SelectIndex < self.MinIndex then
        SelectIndex = self.MaxIndex
        if self.PageSwitchFuncOpen then
            if self.CurSelectPage > 1 then
                TheSelectPage = self.CurSelectPage - 1
                SelectIndex = self.PageMaxNum
                IsPageChange = true
            end
        end
    end
    local PageValid = true
    if IsPageChange then
        if not self:CheckPageValid(TheSelectPage) then
            PageValid = false
        end
        if not self.Param.PageInvalidStillShow then
            return
        end
        if not PageValid then
            self.CacheSelectTabId = self.CurSelectTabId
        end
        self.CurSelectPage = TheSelectPage
        CWaring("UpdatePageShow:" .. self.CurSelectPage)
        self:UpdatePageShow(true)
    end
    local TabId = self.Index2TabId[SelectIndex]
    if PageValid then
        if self.CacheSelectTabId then
            TabId = self.CacheSelectTabId
            self.CacheSelectTabId = nil
        else
            local MenuItem = self.TabId2Item[TabId]
            if not MenuItem or MenuItem.NeedHide then
                -- return self:GetAvailableIndex(Direction, TabId)
                if Direction > 0 then
                    SelectIndex = SelectIndex-1
                else
                    SelectIndex = self.MinIndex
                end
                TabId = self.Index2TabId[SelectIndex]
            end
        end
    else
        TabId = self.CurSelectTabId
    end
    CWaring("GetAvailableIndex:" .. TabId)
    return TabId
end
function CommonMenuTabUp:UpdatePageShow(NeedCleanSelect)
    self.TabId2Item = {}
    self.Index2TabId = {}
    self.TabId2Index = {}
    for Idx=1,self.PageMaxNum do
        local Widget = self.PageIndex2Widget[Idx]
        if NeedCleanSelect then
            self:UpdateWidgetSelectState(false,Widget)
        end
        local ItemListIndex = (self.CurSelectPage-1)*self.PageMaxNum + Idx
        local ItemInfo = self.Param.ItemInfoList[ItemListIndex]
        if not ItemInfo then
            if self.PageSwitchFuncOpen then
                Widget:SetVisibility(UE.ESlateVisibility.Hidden)
            else
                Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        else
            Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            if self.TabId2Item[ItemInfo.Id] then
                CError("CommonMenuTabUp ItemInfoList Repeat Id:" .. ItemInfo.Id,true)
            end
            self.TabId2Item[ItemInfo.Id] = ItemInfo
            self.Index2TabId[Idx] = ItemInfo.Id
            self.TabId2Index[ItemInfo.Id] = Idx

            --更新显示名称
            if ItemInfo.LabelStr then
                CWaring("ItemInfo.LabelStr:" .. ItemInfo.LabelStr)
                Widget.LbName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                Widget.LbName:SetText(StringUtil.Format(ItemInfo.LabelStr))
            else
                Widget.LbName:SetVisibility(UE.ESlateVisibility.Collapsed)
            end


            if ItemInfo.NeedHide then
                Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
            else
                Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end

            if not self:CheckMenuTabValid(ItemInfo.Id,false) then
                if Widget.VXE_Btn_disable then
                    Widget:VXE_Btn_disable()
                end
            else
                if Widget.VXE_Btn_UnDisable then
                    Widget:VXE_Btn_UnDisable()
                end
            end
        end
    end
end
--[[
    通过快捷键切页
]]
function CommonMenuTabUp:OnSwitchMenuTab(Direction)
    if not self:CheckPageValid(self.CurSelectPage) then
        self:OnPageArrowBtnClick(Direction)
        return
    end
    local SelectId = self:GetAvailableIndex(Direction, self.CurSelectTabId)
    if Direction > 0 and not self:CheckMenuTabValid(SelectId,false) then
        self:OnPageArrowBtnClick(Direction)
    else
        self:OnTabItemClick(SelectId)
    end
    return true
end

function CommonMenuTabUp:OnPageArrowBtnClick(Direction)
    local SelectPage = Direction > 0 and self.CurSelectPage + 1 or self.CurSelectPage - 1
    if SelectPage > self.MaxPageNum then
        SelectPage = self.MaxPageNum 
    elseif SelectPage < 1 then
        SelectPage = 1
    end
    local PageValid = true
    if not self:CheckPageValid(SelectPage) then
        PageValid = false
    end
    if not self.Param.PageInvalidStillShow then
        return
    end
    if self.CurSelectPage == SelectPage then
        return
    end
    if not PageValid then
        self.CacheSelectTabId = self.CurSelectTabId
    end
    self.CurSelectPage = SelectPage
    self:UpdatePageShow(true)
    if PageValid then
        local TabId = self.Index2TabId[1]
        if Direction < 0 then
            TabId = self.Index2TabId[self.PageMaxNum]
        end
        if self.CacheSelectTabId then
            TabId = self.CacheSelectTabId
            self.CacheSelectTabId = nil
        end
        self:OnTabItemClick(TabId,false,true)
    end
end

--[[
    通过MenuTabId主动触发切换动作
]]
function CommonMenuTabUp:Switch2MenuTab(TabId,IsForceSelect)
    self:UpdateCurSelect(TabId)
    self:OnTabItemClick(TabId,false,IsForceSelect)
end

function CommonMenuTabUp:GetTipsIconPath(CommonTipsID)
    local CommonTipsCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_CommonBtnTipsConfig,
    Cfg_CommonBtnTipsConfig_P.TipsID, CommonTipsID)
    if not CommonTipsCfg then
        CError("CommonMenuTabUp:GetTipsIconPath Error Id = "..CommonTipsID,true)
        return nil
    end
    return CommonTipsCfg[Cfg_CommonBtnTipsConfig_P.TipsIcon]
end

function CommonMenuTabUp:SetSwitchBtnIcon(Index)
    if not self.SwitchBtnIcons[Index] then
        return
    end
    if self.SwitchBtnIcons[Index].Left then
        CommonUtil.SetBrushFromSoftObjectPath(self.View.LeftSwitchTabIconLeft,self.SwitchBtnIcons[Index].Left)
    end
    if self.SwitchBtnIcons[Index].Right then
        CommonUtil.SetBrushFromSoftObjectPath(self.View.RightSwitchTabIconRight,self.SwitchBtnIcons[Index].Right)
    end
end

return CommonMenuTabUp
