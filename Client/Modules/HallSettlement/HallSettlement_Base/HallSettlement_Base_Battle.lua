---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 结算战斗页面基类
--- Created At: 2023/08/21 14:41
--- Created By: 朝文
---

local class_name = "HallSettlement_Base_Battle"
---@class HallSettlement_Base_Battle
local HallSettlement_Base_Battle = BaseClass(nil, class_name)

function HallSettlement_Base_Battle:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.WBPReuseList.OnUpdateItem,				Func = Bind(self, self.OnUpdateItem) },
    }
    self.MsgList = {
        {Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,  Func = self.OnOtherViewClosed },
    }
    
    self.CurSelectItemInfo = nil
    self._Widget2Item = {}
    -- 队友以及自己的信息
    self.Teammates = {}
    -- 匹配模式类型
    self.MatchType = "Survive"
    ---@type HallSettlementModel
    self.HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
end
--[[
    Param = {
        Teammates   队友以及自己的信息 map<int64, GamePlayerSettlementSync> PlayerArray
        MatchType  匹配类型 参考 MatchConst.Enum_MatchType
        SettlementItemType  结算item类型  参考 HallSettlementModel.Enum_SettlementItemType
    }
]]
function HallSettlement_Base_Battle:OnShow(Param)
    if Param then
        self.Teammates = Param.Teammates
        self.MatchType = Param.MatchType
        self.SettlementItemType = Param.SettlementItemType or HallSettlementModel.Enum_SettlementItemType.Settlement
        print_r(self.Teammates, "[cw] ====self.Teammates")    
        self.View.WBPReuseList:Reload(#self.Teammates) 

        if self.View.Panel_Attribute then
            -- 根据结算数据的情况隐藏属性栏
            local SettlementDataStateType = self.HallSettlementModel:GetSettlementDataStateType()
            local IsShowAttribute = SettlementDataStateType ~= HallSettlementModel.Enum_SettlementDataStateType.GetDataFail
            self.View.Panel_Attribute:SetVisibility(IsShowAttribute and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed) 
        end
    end
end

function HallSettlement_Base_Battle:OnHide() end

--TODO: 子类重写这一块
---@return string 列表下的item的lua路径
function HallSettlement_Base_Battle:GetBattleItemLuaPath()
    return "Client.Modules.HallSettlement.HallSettlement_Base.HallSettlement_Base_BattleItem"
end

---获取或创建一个使用lua绑定的控件
---@return table
function HallSettlement_Base_Battle:_GetOrCreateReuseItem(Widget)
    local Item = self._Widget2Item[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, self:GetBattleItemLuaPath())
        self._Widget2Item[Widget] = Item
    end

    return Item.ViewInstance
end

---更新 WBP_ReuseList 的函数
---@param Widget userdata 控件
---@param Index number 在lua侧使用需要 +1
function HallSettlement_Base_Battle:OnUpdateItem(Handler, Widget, Index)
    local FixIndex = Index + 1

    local Data = self.Teammates[FixIndex]
    if not Data then
        CError("[cw] Trying to access an illegal index(" .. tostring(FixIndex) .. ") of data")
        return
    end

    local TargetItem = self:_GetOrCreateReuseItem(Widget)
    if not TargetItem then return end
    if Data.IsEmptyBroad then
        TargetItem.ItemBaseRoot.WidgetSwitcher:SetActiveWidget(TargetItem.ItemBaseRoot.Loading)
    else
        TargetItem.ItemBaseRoot.WidgetSwitcher:SetActiveWidget(TargetItem.ItemBaseRoot.Main)
        Data.clickCallback = function(_data) self:OnSubItemClicked(_data) end
        TargetItem:SetData(Data, self.MatchType, self.SettlementItemType)
        TargetItem:UpdateView()
    end
end

-- 监听界面关闭事件
function HallSettlement_Base_Battle:OnOtherViewClosed(ViewId)
    -- 操作菜单界面关闭，关闭所有选中效果
    if ViewId == ViewConst.HallSettlementDetailBtn then
        self:OnSubItemClicked(nil)
    end
end

---子条目点击回调
function HallSettlement_Base_Battle:OnSubItemClicked(_Data)
    self.CurSelectItemInfo = _Data
    for k, widget in pairs(self._Widget2Item) do
        local Instance = widget.ViewInstance
        if Instance then
            if self.CurSelectItemInfo and Instance.Data and Instance.Data.PlayerId == self.CurSelectItemInfo.PlayerId then
                Instance:Select()
                -- local root = Instance.View.WBP_Settlement_Data_PlayerListItem_Base
                -- local ShowPosition = UE.USlateBlueprintLibrary.GetLocalSize(root.Panel_PlayerDetail:GetCachedGeometry())
                local Param = {
                    -- ShowPosition = ShowPosition,
                    SelectPlayerId = _Data.PlayerId,
                    PlayerName = _Data.PlayerName,
                }
                self.HallSettlementModel:DispatchType(HallSettlementModel.ON_SETTLEMENT_PLAYER_ITEM_CLICK_EVENT, Param)
            else
                Instance:UnSelect()
            end 
        end
    end
end

return HallSettlement_Base_Battle