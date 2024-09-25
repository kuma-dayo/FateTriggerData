
local super = ListModel;
local class_name = "NoticeModel";

---@class NoticeModel : ListModel
---@field private super ListModel
NoticeModel = BaseClass(super, class_name);

function NoticeModel:__init()
    self:_dataInit()
end

function NoticeModel:_dataInit()
    self:Clean()
    self.NoticeCategoryList = nil
    self.DataListByCategory = nil
end

---@param data any
function NoticeModel:OnLogin(data)
    CWaring("NoticeModel OnLogin")
end

--- 玩家登出时调用
---@param data any
function NoticeModel:OnLogout(data)
    NoticeModel.super.OnLogout(self)
    self:_dataInit()
end

--- 重写父方法,返回唯一Key
---@param vo any
function NoticeModel:KeyOf(vo)
    return vo["Id"]
end

--- 重写父类方法,如果数据发生改变
--- 进行通知到这边的逻辑
---@param vo any
function NoticeModel:SetIsChange(value)
    NoticeModel.super.SetIsChange(self, value)
end 

function NoticeModel:InitNoticeCategoryList()
    if self.NoticeCategoryList then
        return
    end

    self.NoticeCategoryList = {}
    local NoticeCategoryConfigs = G_ConfigHelper:GetDict(Cfg_NoticeCategoryConfig)
    if not NoticeCategoryConfigs then
        CError("NoticeCategoryConfigs is nil, need check!")
        return
    end
    for _, Cfg in pairs(NoticeCategoryConfigs) do
        local IsShow = Cfg[Cfg_NoticeCategoryConfig_P.IsShow]
        local TabId = Cfg[Cfg_NoticeCategoryConfig_P.CategoryId]
        ---@class NoticeCategoryList
        ---@field TabId number
        ---@field Prority number
        ---@field TabName string
        ---@field IsShow boolean
        ---@field TabIcon string
        local Item = {
            TabId = TabId,
            Prority = Cfg[Cfg_NoticeCategoryConfig_P.Prority],
            TabName = Cfg[Cfg_NoticeCategoryConfig_P.CategoryName],
            IsShow = IsShow,
            TabIcon = Cfg[Cfg_NoticeCategoryConfig_P.TabIcon],
        }
        local DataList = self:GetContentDataList(TabId)
        if IsShow and DataList and #DataList > 0 then
            table.insert(self.NoticeCategoryList, Item)
        end
    end
    self.NoticeCategoryList = self:SortTabList(self.NoticeCategoryList)
end 

function NoticeModel:GetTabDataList()
    return self.NoticeCategoryList
end 

function NoticeModel:InitNoticeList(NoticeList)
    if not NoticeList then
        CError("NoticeConfigs is nil, need check!")
        return
    end
    if #NoticeList == 0 then
        return
    end
    local List = {}
    self.DataListByCategory = {}
    local NowTimeStamp = GetTimestamp()
    for _, Id in ipairs(NoticeList) do
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_NoticeConfig, Id)
        if not Cfg then
            CError("[NoticeModel]InitNoticeList Cfg is nil, Id="..Id)
            return
        end
        local CategoryID = Cfg[Cfg_NoticeConfig_P.CategoryId]
        local BeginTime = Cfg.BeginTimeTimestamp
        local EndTime = Cfg.EndTimeTimestamp
        if  (not BeginTime and not EndTime) or (BeginTime and EndTime and NowTimeStamp - BeginTime >= 0 and EndTime - NowTimeStamp > 0) then
             ---@class NoticeItem
            ---@field Id number
            ---@field CategoryID number
            ---@field Name string
            ---@field Pic string
            ---@field Prority number
            ---@field Content string
            ---@field BeginTime number
            ---@field EndTime number
            local NoticeItem = {
                Id = Id,
                CategoryID = CategoryID,
                Name = Cfg[Cfg_NoticeConfig_P.Tittle],
                Prority = Cfg[Cfg_NoticeConfig_P.Prority],
                Pic = Cfg[Cfg_NoticeConfig_P.Pic],
                Content = Cfg[Cfg_NoticeConfig_P.Content],
                BeginTime = BeginTime,
                EndTime = EndTime,
            }
            if self.DataListByCategory[CategoryID] == nil then
                self.DataListByCategory[CategoryID] = {}
            end
            table.insert(self.DataListByCategory[CategoryID], NoticeItem)
            table.insert(List, NoticeItem)
        end
    end
    for Key, TempList in pairs(self.DataListByCategory) do
        self.DataListByCategory[Key] = self:SortNoticeList(TempList)
    end
    self:SetDataList(List)
    self:InitNoticeCategoryList()
end 

function NoticeModel:GetContentDataList(CategoryID)
    if self.DataListByCategory == nil then
        CError("[NoticeModel] GetContentDataList DataListByCategory is nil")
        return nil
    end
    if self.DataListByCategory[CategoryID] then
        return self.DataListByCategory[CategoryID]
    end
    return nil
end

--- 排序
---@param NoticeItem[]
function NoticeModel:SortNoticeList(NoticeItemList)
    table.sort(NoticeItemList, function(a, b)
        ---排序优先级数字越大排序越靠前
        if a.Prority ~= b.Prority then
            return a.Prority > b.Prority
        else
            return a.Id > b.Id
        end
    end)
    return NoticeItemList
end

--- 排序
function NoticeModel:SortTabList(TabItemList)
    table.sort(TabItemList, function(a, b)
        ---排序优先级数字越大排序越靠前
        if a.Prority ~= b.Prority then
            return a.Prority > b.Prority
        else
            return a.TabId > b.TabId
        end
    end)
    return TabItemList
end
return NoticeModel;
