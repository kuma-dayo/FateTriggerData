require("Core.BaseClass");
require("Core.Events.EventDispatcher");

local  class_name = 'ViewModel';
--[[输入文本域]]
---管理全部view的激活状态
---@class ViewModel : EventDispatcher
ViewModel = ViewModel or BaseClass(EventDispatcher, class_name);

--[[有View重复打开事件]]
ViewModel.ON_REPEAT_SHOW = "ON_REPEAT_SHOW";
--[[有View显示状态改变]]
ViewModel.ON_SATE_CHANGED = "ON_SATE_CHANGED";
--[[
    有View显示状态改变
    回参：
    ViewId
]]
ViewModel.ON_SATE_ACTIVE_CHANGED = "ON_SATE_ACTIVE_CHANGED";
--[[
    有View显示状态改变
    回参：
        ViewId
]]
ViewModel.ON_SATE_DEACTIVE_CHANGED = "ON_SATE_DEACTIVE_CHANGED";
--[[有View开始OnShow了]]
ViewModel.ON_VIEW_ON_SHOW = "ON_VIEW_ON_SHOW_";

--[[当执行close AllPopViews时的事件]]
ViewModel.ON_CLOSE_ALLPOPVIEWS = "ON_CLOSE_ALLPOPVIEWS";
--[[当执行close AllViews时的事件]]
ViewModel.ON_CLOSE_ALLVIEWS = "ON_CLOSE_ALLVIEWS";
--[[有View显示状态改变完成后 - 在GameMediator.Show后]]
ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED = "ON_AFTER_SATE_ACTIVE_CHANGED";
--[[有View显示状态改变完成后 - 在GameMediator.Hide后]]
ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED = "ON_AFTER_SATE_DEACTIVE_CHANGED";

--[[地图开始加载  传参为地图名称]]
ViewModel.ON_PRE_LOAD_MAP = "ON_PRE_LOAD_MAP"
--[[地图加载成功  传参为地图名称]]
ViewModel.ON_POST_LOAD_MAP = "ON_POST_LOAD_MAP"

function ViewModel:__init()
	-- self.__class_name = class_name;
	self.view_name = "ViewModel";
	self.openIndex = 0;
    self.openMap = {};
    self.nameMap = {};
    self.filterMap = {};
    self.filterMapLogout = {};
    self.layerMap = {};
    self.layer2OpenSortListDirty = {}
    self.layer2OpenSortList = {}

    --[[当前展示 流关卡ID 保证唯一]]
    self.show_LEVEL_STREAM = 0
    --[[当前展示 关卡ID 保证唯一]]
    self.show_LEVEL = 0
    --[[上个关卡ID]]
    self.last_LEVEL = 0

    --[[当前展示关卡ID包括虚拟关卡,不包括被虚拟依赖的真实关卡ID]]
    self.show_LEVEL_Fix = 0
    --[[上个关卡ID包括虚拟关卡,不包括被虚拟依赖的真实关卡ID]]
    self.last_LEVEL_Fix = 0
end

function ViewModel:__dispose()
	self.openIndex = 0;
    self.openMap = nil;
    self.nameMap = nil;
    self.filterMap = nil;
    self.filterMapLogout = nil;
    self.layerMap = nil;

    self.layer2OpenSortListDirty = {}
    self.layer2OpenSortList = {}
end
--[[
    记录view的状态
]]
---记录view的激活状态
---@param viewId number view ID
---@param active boolean 是否激活
---@param param table 额外参数
---@param layer view 所在的层级
---@return void
function ViewModel:SetState(viewId, active, param, layer)
    local StateChange = false
    if active then
        self.openIndex = self.openIndex + 1;
        param = param or {viewId = viewId};
        self.openMap[viewId] = param;
        param.showIndex = self.openIndex;
        if not layer then
            CError("ViewModel:SetState Param layer nil,ViewId is:" .. viewId,true)
            return
        end
        StateChange = true
    else
        if self.openMap[viewId] then
            self.openMap[viewId] = nil;
            StateChange = true
        end
    end
    if layer then
        self.layerMap[viewId] = layer;
    end
    
    if StateChange then
        layer = self.layerMap[viewId]
        self.layer2OpenSortListDirty[layer] = true
    end
    self:DispatchType(viewId, active);
    self:DispatchType(ViewModel.ON_SATE_CHANGED, viewId);
    if active then
        self:DispatchType(ViewModel.ON_SATE_ACTIVE_CHANGED, viewId);
    else
        self:DispatchType(ViewModel.ON_SATE_DEACTIVE_CHANGED, viewId);
    end
end

function ViewModel:GetState(viewId)
    local param = self.openMap[viewId];
    return param ~= nil;
end
--[[记录名称]]
function ViewModel:SetName(viewId, name)
	self.nameMap[viewId] = name;
end
--[[读取名称]]
function ViewModel:GetName(viewId)
	return self.nameMap[viewId];
end
--[[所在图层]]
function ViewModel:GetLayerType(viewId)
	return self.layerMap[viewId];
end

function ViewModel:Calculatelayer2OpenSortList(layer)
    if self.layer2OpenSortListDirty[layer] == nil or self.layer2OpenSortListDirty[layer] == true then
        local list = {};
            local TheViewController =MvcEntry:GetCtrl(ViewController)
            for k, v in pairs(self.openMap) do
            -- SpecialViewList 中的界面，不参与获取
            if self:GetState(v.viewId) and layer == self.layerMap[v.viewId] and not TheViewController:IsInViewCheckWhiteList(ViewController.VIEW_CHECK_TYPE.SpecialView, v.viewId)  then
                table.insert(list, v);
            end
        end
        self.sortByShowIndex = self.sortByShowIndex or function(a, b)
            return (a.showIndex > b.showIndex) and true or false
        end
        table.sort(list, self.sortByShowIndex);
        self.layer2OpenSortList[layer] = list
    end
    self.layer2OpenSortListDirty[layer] = false
end

--[[
    取出对应层级打开的列表
    返回的值是排序后的

    排序是按视觉，从近到远（上层的排在前面，showIndex值大的排在前面）
]]
function ViewModel:GetOpenList(layer)
    self:Calculatelayer2OpenSortList(layer)
    return self.layer2OpenSortList[layer]
end
--[[
    取出打开的列表2
    层级列表下的所有已打开界面
]]
function ViewModel:GetOpenListByLayerList(layerList)
    local resultList = {}
    for i=1,#layerList do
        local layer = layerList[i]
        local list = self:GetOpenList(layer)
        resultList = ListMerge(resultList,list)
    end
    return resultList;
end
--[[取出打开的列表3]]
function ViewModel:GetOpenListFilterLayers(FilterLayerList)
    local list = {};
    local FilterLayerMap = {}
    for k,v in ipairs(FilterLayerList) do
        FilterLayerMap[v] = 1
    end
    for k, v in pairs(self.openMap) do
        if self:GetState(v.viewId) and not FilterLayerMap[self.layerMap[v.viewId]] then
            table.insert(list, v);
        end
    end
    return list;
end

function ViewModel:GetOpenLastView()
    local list = {
        UIRoot.UILayerType.Dialog,
        UIRoot.UILayerType.Pop,
        UIRoot.UILayerType.Fix,
    }
    for i,v in ipairs(list) do
        local openList = self:GetOpenList(v)
        if #openList > 0 then
            return openList[1]
        end
    end
    return nil
end

--找最后一个打开且开启了InputFocus的界面
function ViewModel:GetOpenLastViewWithInputFocus()
    local list = {
        UIRoot.UILayerType.Dialog,
        UIRoot.UILayerType.Pop,
        UIRoot.UILayerType.Fix,
    }
    for i,v in ipairs(list) do
        local openList = self:GetOpenList(v)
        if #openList > 0 then
            for _,view in ipairs(openList) do
                local mdt =  MvcEntry:GetCtrl(ViewRegister):GetView(view.viewId)
                if mdt and mdt.view and mdt.view.InputFocus then
                    return view
                end
            end
        end
    end
    return nil
end


function ViewModel:SetFilterId(viewId, filter)
    if (filter == true) then
        self.filterMap[viewId] = true;
    else
        self.filterMap[viewId] = nil;
    end
end

function ViewModel:SetFilterIdLogout(viewId, filter)
    if (filter == true) then
        self.filterMapLogout[viewId] = true;
    else
        self.filterMapLogout[viewId] = nil;
    end
end

function ViewModel:IsFilterId(viewId)
    return self.filterMap[viewId];
end

function ViewModel:IsFilterIdLogout(viewId)
    return self.filterMapLogout[viewId];
end


--[[
 * 记录当前已经打开的窗口,不含场景类型（记录在过滤表中）
 *]]
function ViewModel:RecordOpenList(layer)
    self.lastViewList = {};
    local list = self:GetOpenList(layer);
    --记录未关闭的窗口
    for k, v in ipairs(list) do
        if(not self:IsFilterId(v.viewId)) then
           table.insert(self.lastViewList, v);
        end
    end
    return self.lastViewList;
end
--[[
 * 获取上次记录打开的UI列表信息
]]
function ViewModel:GetLastViewList()
    --返回副本，避免数组操作变化
    return table.concat(self.lastViewList);
end
--[[
 * 清除记录
]]
function ViewModel:clearLastViewList()
    self.lastViewList = nil;
end

