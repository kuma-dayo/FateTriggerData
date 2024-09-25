--[[
   英雄详情快速切换控件逻辑
]] 
local class_name = "HeroQuickTabLogic"
local HeroQuickTabLogic = BaseClass(UIHandlerViewBase, class_name)
---@class HeroQuickTabLogicParam
---@field HeroId number 英雄ID
---@field NeedUpdateAvatar boolean 【可选】是否更新大厅英雄页签Avatar

function HeroQuickTabLogic:OnInit()
    self.InputFocus = true
    self.BindNodes = {
		{ UDelegate = self.View.List.OnUpdateItem,   Func = Bind(self, self.OnUpdateItem) },
        { UDelegate = self.View.List.OnReloadFinish, Func = Bind(self, self.OnReloadFinish) },
        { UDelegate = self.View.List.OnScrollItem,   Func = Bind(self, self.OnScrollItem) },
    }
    self.MsgList = 
    {
        { Model = HeroModel,  MsgName = HeroModel.HERO_QUICK_TAB_HOVER,	                     Func = Bind(self, self.HERO_QUICK_TAB_HOVER) },   
        { Model = HeroModel,  MsgName = HeroModel.HERO_QUICK_TAB_UNHOVER,	                 Func = Bind(self, self.HERO_QUICK_TAB_UNHOVER) }, 
        { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.MouseScrollUp),   Func = Bind(self, self.OnMouseScrollUp) },
        { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.MouseScrollDown), Func = Bind(self, self.OnMouseScrollDown) }, 
        { Model = HeroModel,  MsgName = HeroModel.HERO_QUICK_TAB_HERO_SELECT,                Func = Bind(self, self.HERO_QUICK_TAB_HERO_SELECT) }, 
	}
    self.Widget2Handler = {}
    self.IsHovered = false
end

function HeroQuickTabLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function HeroQuickTabLogic:OnHide()
    self:CleanJumpTimer()
end

function HeroQuickTabLogic:UpdateUI(Param)
    if not Param then
        return
    end
    self.SelectId = Param.HeroId
    self.NeedUpdateAvatar = Param.NeedUpdateAvatar
    self.StartItemIndex = -1
    self.EndItemIndex = -1
    self.DataList = {}
    self.BaseNum = 0
    self.SelectIndex = 0
    self.ShowIndex = 0
    self.OneScreenNum = 5
    local Cfgs = G_ConfigHelper:GetDict(Cfg_HeroConfig)
    if not Cfgs then
        return
    end
    self.BaseNum = #Cfgs
    --一共添加3屏的英雄数量以供滑动
    for j = 1, 3 do
        for i, v in ipairs(Cfgs) do
            if self.SelectIndex == 0 and self.SelectId == v[Cfg_HeroConfig_P.Id] then
                self.SelectIndex = i
            end
            self.DataList[#self.DataList+1] = v[Cfg_HeroConfig_P.Id]
        end
    end
    self.View.List:Reload(#self.DataList)
    self.ShowIndex = self.SelectIndex
    ---列表不响应鼠标滚轮事件
    self.View.List.ScrollBoxList:SetConsumeMouseWheel(UE.EConsumeMouseWheel.Never)
end

function HeroQuickTabLogic:OnUpdateItem(Handler,Widget, Index)
    local FixIndex = Index + 1
    local HeroId = self.DataList[FixIndex]
    -- CWaring("OnUpdateItem:" .. Index)

    if not self.Widget2Handler[Widget] then
        self.Widget2Handler[Widget] = UIHandler.New(self,Widget,require("Client.Modules.Hero.HeroQuickTabHeroListItem"))
    end
    ---@type HeroQuickTabHeroListItemParam
    local Param = {
        HeroId = HeroId,
        Index = FixIndex,
        SelectId = self.SelectId,
        NeedUpdateAvatar = self.NeedUpdateAvatar or false,
    }
    self.Widget2Handler[Widget].ViewInstance:UpdateUI(Param)
end

function HeroQuickTabLogic:OnReloadFinish()
    self:JumpToMiddle(self.SelectIndex)
end

--将列表滑动至3屏英雄中间屏所在位置
function HeroQuickTabLogic:JumpToMiddle(ShowIndex, NeedFix)
    local Index = ShowIndex
    if NeedFix then
        local HeroId = self.DataList[ShowIndex + 1] and self.DataList[ShowIndex + 1] or self.DataList[1]
        for i, v in ipairs(self.DataList) do
            if v == HeroId then
                Index = i
                break
            end
        end
    end
    self.View.List:JumpByIdxStyle(Index + self.BaseNum - 1,UE.EReuseListExJumpStyle.Begin)
end

function HeroQuickTabLogic:OnScrollItem(_, Start, End)
    self.StartItemIndex = Start
    self.EndItemIndex = End
    --最后一个的索引减去第一个的索引等于显示的一屏数量减1时，即滑动完成
    if End - Start == self.OneScreenNum - 1 then
        if Start == 0 or #self.DataList - 1  == End then
            self:CleanJumpTimer()
            self.JumpTimer = Timer.InsertTimer(Timer.NEXT_FRAME,function ()
                self:JumpToMiddle(Start, true)
                self:CleanJumpTimer()
            end)
        end
    end
    -- CWaring("self.StartItemIndex:" .. self.StartItemIndex)
    -- CWaring("self.EndItemIndex:" .. self.EndItemIndex)
end

function HeroQuickTabLogic:HERO_QUICK_TAB_UNHOVER()
    self.IsHovered = false
end

function HeroQuickTabLogic:HERO_QUICK_TAB_HOVER()
    self.IsHovered = true
end

function HeroQuickTabLogic:HERO_QUICK_TAB_HERO_SELECT(_, Param)
    if not Param or not Param.SelectId then
        return
    end
    self.SelectId = Param.SelectId
end

function HeroQuickTabLogic:OnMouseScrollUp()
    if not self.IsHovered then
        return
    end
    self:ScrollToItem(-1)
end

function HeroQuickTabLogic:OnMouseScrollDown()
    if not self.IsHovered then
        return
    end
    self:ScrollToItem(1)
end

function HeroQuickTabLogic:ScrollToItem(Value)
    local Index = self.StartItemIndex + Value
    self.View.List:JumpByIdxStyle(Index,UE.EReuseListExJumpStyle.Begin)
end

function HeroQuickTabLogic:CleanJumpTimer()
    if self.JumpTimer then
        Timer.RemoveTimer(self.JumpTimer)
    end
    self.JumpTimer = nil
end

return HeroQuickTabLogic
