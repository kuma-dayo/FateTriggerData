--[[
    大厅侧边菜单栏界面
]]

local class_name = "HallMenuEntryMdt";
HallMenuEntryMdt = HallMenuEntryMdt or BaseClass(GameMediator, class_name);

function HallMenuEntryMdt:__init()
end

function HallMenuEntryMdt:OnShow(data)
    
end

function HallMenuEntryMdt:OnHide()
end

-------------------------------------------------------------------------------

local HallMenuEntry = Class("Client.Mvc.UserWidgetBase")

-- 入口类型枚举
HallMenuEntry.ENTRY_TYPE = {
    Depot = 1,  -- 仓库
}


-- 入口红点
HallMenuEntry.ENTRYR_REDDOT_INFO = {
    [HallMenuEntry.ENTRY_TYPE.Depot] = {
        RedDotKey = "Depot",
        RedDotSuffix = "",
    }
}
function HallMenuEntry:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.GUIButton_Close.OnClicked,   Func = self.DoClose },
        { UDelegate = self.BtnOutSide.OnClicked,	Func = self.DoClose },
        { UDelegate = self.OnAnimationFinished_vx_hall_entrance_close,	Func = Bind(self,self.On_vx_hall_entrance_close_Finished) },

	}

    self.MsgList = 
    {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.DoClose },
    }

    self.EntryBtns = {}
    self.CurSelectIndex = 0
    self.CurSelectItem = nil
    -- 红点缓存组件
    self.ItemRedDotList = {}
end

function HallMenuEntry:OnHide()
    for Index,Btn in pairs(self.EntryBtns) do
        Btn.OnClicked:Clear()
    end
	self.WBP_EntranceReuseList.OnUpdateItem:Clear()
    self.EntryBtns = {}
    self.CurSelectIndex = 0
    self.CurSelectItem = nil
end

--由mdt触发调用
function HallMenuEntry:OnShow(Params)
	self.WBP_EntranceReuseList.OnUpdateItem:Add(self, self.OnUpdateItem)
    self.EntryCfgList = G_ConfigHelper:GetDict(Cfg_HallMenuEntryCfg)
    if self.EntryCfgList ~= nil then
        self.WBP_EntranceReuseList:Reload(#self.EntryCfgList)
    end

    self:PlayDynamicEffectOnShow(true)
end

function HallMenuEntry:OnUpdateItem(Widget, I)
	local Index = I + 1
    local EntryCfg = self.EntryCfgList[Index]
    if EntryCfg == nil then
		return
	end

    local EntryType = EntryCfg[Cfg_HallMenuEntryCfg_P.EntryType]
    -- Icon
    local IconImg = LoadObject(EntryCfg[Cfg_HallMenuEntryCfg_P.EntryIcon])
    if IconImg then
        Widget.EntranceImage_Normal:SetBrushFromTexture(IconImg)
        Widget.EntranceImage_Hover:SetBrushFromTexture(IconImg)
        Widget.EntranceImage_Click:SetBrushFromTexture(IconImg)
        Widget.EntranceBg_Normal:SetBrushFromTexture(IconImg)
        Widget.EntranceBg_Hover:SetBrushFromTexture(IconImg)
        Widget.EntranceBg_Click:SetBrushFromTexture(IconImg)
    end
    -- Name
    Widget.EntranceName_Normal:SetText(StringUtil.Format(EntryCfg[Cfg_HallMenuEntryCfg_P.EntryName]))
    Widget.EntranceName_Hover:SetText(StringUtil.Format(EntryCfg[Cfg_HallMenuEntryCfg_P.EntryName]))
    Widget.EntranceName_Click:SetText(StringUtil.Format(EntryCfg[Cfg_HallMenuEntryCfg_P.EntryName]))
    -- Btn
    Widget.GUIButtonEntrance.OnClicked:Clear()
    Widget.GUIButtonEntrance.OnClicked:Add(self, Bind(self,self.OnEntryClicked,Widget,Index))
    self.EntryBtns[Index] = Widget.GUIButtonEntrance
    -- IsSelected
    local IsSelected = self.CurSelectIndex == Index
    if IsSelected then
        self.CurSelectItem = Widget
    end
    Widget.GUIImageSelect:SetVisibility(IsSelected and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    self:RegisterRedDot(EntryType, Widget)
end

-- function HallMenuEntry:OnRepeatShow(Param)
-- end

--[[
	入口Item被点击
]]
function HallMenuEntry:OnEntryClicked(Widget,Index)
    if self.CurSelectItem and self.CurSelectIndex ~= Index then
        self.CurSelectItem.GUIImageSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.CurSelectIndex = Index
    self.CurSelectItem = Widget
    self.CurSelectItem.GUIImageSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    local EntryCfg = self.EntryCfgList[Index]
    local EntryType = EntryCfg and EntryCfg[Cfg_HallMenuEntryCfg_P.EntryType] or nil
    self:InteractRedDot(EntryType)
    if EntryCfg and EntryCfg[Cfg_HallMenuEntryCfg_P.ViewId] then

        MvcEntry:OpenView(EntryCfg[Cfg_HallMenuEntryCfg_P.ViewId])
        -- 目前需求是打开界面的时候关闭自身界面。后续有要求不关闭的再在这里特殊处理
        self:DoClose()
    end
end

--关闭界面
function HallMenuEntry:DoClose()
    --MvcEntry:CloseView(self.viewId)
    self:PlayDynamicEffectOnShow(false)
end

-- 绑定红点
function HallMenuEntry:RegisterRedDot(EntryType, Widget)
    local RedDotInfo = HallMenuEntry.ENTRYR_REDDOT_INFO[EntryType]
    if RedDotInfo and RedDotInfo.RedDotKey then
        local RedDotKey = RedDotInfo.RedDotKey
        local RedDotSuffix = RedDotInfo.RedDotSuffix
        if not self.ItemRedDotList[EntryType] then
            self.ItemRedDotList[EntryType] = UIHandler.New(self, Widget.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        else 
            self.ItemRedDotList[EntryType]:ChangeKey(RedDotKey, RedDotSuffix)
        end  
    end
end

-- 红点触发逻辑
function HallMenuEntry:InteractRedDot(EntryType)
    if self.ItemRedDotList[EntryType] then
        self.ItemRedDotList[EntryType]:Interact()
    end 
end

--[[
    播放显示退出动效
]]
function HallMenuEntry:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Hall_Entrance_List_Open then
            self:VXE_Hall_Entrance_List_Open()
        end
    else
        if self.VXE_Hall_Entrance_List_Close then
            self:VXE_Hall_Entrance_List_Close()
        end
    end
end

function HallMenuEntry:On_vx_hall_entrance_close_Finished()
    MvcEntry:CloseView(self.viewId)
end


return HallMenuEntry