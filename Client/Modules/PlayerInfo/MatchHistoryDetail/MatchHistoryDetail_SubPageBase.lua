---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 历史记录细节子面板基类
--- Created At: 2023/08/15 14:07
--- Created By: 朝文
---

local class_name = "MatchHistoryDetail_SubpageBase"
---@class MatchHistoryDetail_SubpageBase
local MatchHistoryDetail_SubpageBase = BaseClass(nil, class_name)

function MatchHistoryDetail_SubpageBase:OnInit()
    self._Widget2HistoryDetailItem = {}
    self.BindNodes = {
        { UDelegate = self.View.WBPReuseList.OnUpdateItem,  Func = Bind(self,self.OnHistoryDetailItemUpdate) },
    }
end

function MatchHistoryDetail_SubpageBase:OnShow(Param) end
function MatchHistoryDetail_SubpageBase:OnHide() end

--TODO: 子类重写这一块，返回子物品的lua路径
---@return string lua路径
function MatchHistoryDetail_SubpageBase:GetPageItemLuaPath()
    return ""
end

--TODO: 子类重写这一块，返回子物品的数据
---@param FixedIndex number 从1开始的索引
---@return any 索引对应的数据
function MatchHistoryDetail_SubpageBase:GetPageItemDataByIndex(FixedIndex)
    return nil
end

function MatchHistoryDetail_SubpageBase:SetData(Param)
    self.Data = Param
    --TODO: 后续需要根据自己需要整理数据
end

--TODO: 子类重写这一块，指定需要刷新的数据长度
function MatchHistoryDetail_SubpageBase:UpdateView()
    --self.View.WBPReuseList:Reload(#self.Data.DetailData.BrSettlement.PlayerArray)
end

---获取或创建一个使用lua绑定的控件
function MatchHistoryDetail_SubpageBase:_GetOrCreateReuseHistoryDetailItem(Widget)
    local Item = self._Widget2HistoryDetailItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require(self:GetPageItemLuaPath()))
        self._Widget2HistoryDetailItem[Widget] = Item
    end

    return Item.ViewInstance
end

---更新 WBP_ReuseList 的函数
---@param Widget userdata 控件
---@param Index number 在lua侧使用需要 +1
function MatchHistoryDetail_SubpageBase:OnHistoryDetailItemUpdate(_, Widget, Index)
    local FixedIndex = Index + 1

    --local Data = self.Data.DetailData.BrSettlement.PlayerArray[FixedIndex]
    local Data = self:GetPageItemDataByIndex(FixedIndex)
    if not Data then
        CLog("[cw][MatchHistoryDetail_SubpageBase] Cannot get Info by FixedIndex: " .. tostring(FixedIndex))
        return
    end

    local TargetItem = self:_GetOrCreateReuseHistoryDetailItem(Widget)
    if not TargetItem then return end

    Data.clickCallback = function(_data) self:OnSubItemClicked(_data) end
    TargetItem:SetData(Data)
    TargetItem:UpdateView()
end

---子条目点击回调
function MatchHistoryDetail_SubpageBase:OnSubItemClicked(_Data)
    self.CurSelectItemInfo = _Data
    for k, widget in pairs(self._Widget2HistoryDetailItem) do
        local Instance = widget.ViewInstance
        if Instance.Data.PlayerId == _Data.PlayerId then
            Instance:Select()
        else
            Instance:UnSelect()
        end
    end
end

return MatchHistoryDetail_SubpageBase
