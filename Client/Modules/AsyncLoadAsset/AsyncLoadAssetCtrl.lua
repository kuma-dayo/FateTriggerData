--[[
    资源异步加载模块
]]
require("Client.Modules.AsyncLoadAsset.AsyncLoadAssetModel")

local class_name = "AsyncLoadAssetCtrl"
---@class AsyncLoadAssetCtrl : UserGameController
AsyncLoadAssetCtrl = AsyncLoadAssetCtrl or BaseClass(UserGameController,class_name)

function AsyncLoadAssetCtrl:__init()
    CWaring("==AsyncLoadAssetCtrl init")
    self.Model = nil
end

function AsyncLoadAssetCtrl:Initialize()
    ---@type UserModel
    self.Model = self:GetModel(AsyncLoadAssetModel)

    --[[
        用于给UObject加引用，避免被GC
        在合适的时机进行去引用，允许被GC
    ]]
    self.Path2RefDes = {}
    --[[
        记录资源的加载状态  目前为有值为True表示正在被预加载
    ]]
    self.Path2Loading = {}

    --[[
        不允许释放的资源列表
    ]]
    self.BlackPath2Unload = {}
end


function AsyncLoadAssetCtrl:AddMsgListenersUser()

end

function AsyncLoadAssetCtrl:CheckPathNeedAsyncLoad(Path)
    if not Path then
        CError("AsyncLoadAssetCtrl:CheckPathNeedAsyncLoad Path nil",true)
        return
    end
    if self.Path2RefDes[Path] then
        CWaring("AsyncLoadAssetCtrl:CheckPathNeedAsyncLoad The Asset Already in Ref:" .. Path)
        return false
    end
    if self.Path2Loading[Path] then
        CWaring("AsyncLoadAssetCtrl:CheckPathNeedAsyncLoad The Asset Already in Ref:" .. Path)
        return false
    end
    return true
end

--[[
    请求异步加载单个资源
    加载后的资源会强制进行引用，保证其避免被GC
    如需允许其GC，请手动进行Unload
]]
function AsyncLoadAssetCtrl:RequestAsyncLoad(Path,CompletedCallBack)
    if not self:CheckPathNeedAsyncLoad(Path) then
        if CompletedCallBack then
            CompletedCallBack()
        end
        return
    end
    self.Path2Loading[Path] = 1
    UE.UGFUnluaHelper.AsyncLoad(Path,function (ObjectPath,Object)
        self.Path2Loading[ObjectPath] = nil
        if Object then
            self:RefLoad(Path,Object)
        end
        if CompletedCallBack then
            CompletedCallBack()
        end
    end)
end

--[[
    请求异步加载多个资源
    加载后的资源会强制进行引用，保证其避免被GC
    如需允许其GC，请手动进行Unload
]]
function AsyncLoadAssetCtrl:RequestAsyncLoadList(PathList,CompletedCallBack)
    if not PathList and #PathList <= 0 then
        return
    end
    local FixPath = {}
    for k,Path in ipairs(PathList) do
        if self:CheckPathNeedAsyncLoad(Path) then
            self.Path2Loading[Path] = 1
            table.insert(FixPath,Path)
        end
    end
    if #FixPath > 0 then
        UE.UGFUnluaHelper.AsyncLoadList(FixPath,function (ObjectPathList,ObjectList)
            for k,Path in ipairs(ObjectPathList) do
                self.Path2Loading[Path] = nil

                local Object = ObjectList[k]
                self:RefLoad(Path,Object)
            end
            if CompletedCallBack then
                CompletedCallBack()
            end
        end)
    else
        if CompletedCallBack then
            CompletedCallBack()
        end
    end
end

function AsyncLoadAssetCtrl:RefLoad(Path,Object)
    -- CWaring("AsyncLoadAssetCtrl:RefLoad:" .. Path)
    local RefProxy = UnLua.Ref(Object)
    self.Path2RefDes[Path] = {
        RefProxy = RefProxy,
        Object = Object,
    }
end


--[[
    卸载单个资源
    解引用
]]
function AsyncLoadAssetCtrl:UnLoad(Path)
    if self.Path2Loading[Path] then
        CWaring("AsyncLoadAssetCtrl:UnLoad The Asset is Loading:" .. Path)
        return
    end
    if self.BlackPath2Unload[Path] then
        CWaring("AsyncLoadAssetCtrl:UnLoad The Asset is in BlackList:" .. Path)
        return
    end
    CWaring("AsyncLoadAssetCtrl:UnLoad Path:" .. Path)
    local RefDes = self.Path2RefDes[Path]
    if RefDes then
        --[[
            针对UnRef（解引用）操作有两种模式
            一种是对Ref置空，但依赖luagc（collectgarbage("collect")），需要等到下次luaGC才能解除对UObject的引用
            一种是直接对UObject调用UnLua.Unref解引用

            参考：https://github.com/Tencent/UnLua/blob/v2.3.2/Docs/CN/UnLua_Programming_Guide.md#%E4%BA%94%E5%9E%83%E5%9C%BE%E5%9B%9E%E6%94%B6

            使用控制台命令查看对象和类的引用情况：
            查看指定类的引用列表：Obj List Class=ReleaseUMG_Root_C
            查看指定对象的引用链：Obj Refs Name=ReleaseUMG_Root_C_0

            预加载WBP_HallMain情况下
            StartupPanel界面，WBP_HallCommonTab_C 类的引用数量为2   
                为什么为2，
                    因为WBP_HallCommonTab_C本身UClass加载好了（就是存起来了）占引用1
                    WBP_HallMain_C依赖WBP_HallCommonTab_C，占引用1
            进到大厅界面，，WBP_HallCommonTab_C 类的引用数量为3
                为什么为3
                    因为实例了WBP_HallCommonTab_C添加到了舞台 占引用1  2+1 = 3  
        ]]
        if CommonUtil.IsValid(RefDes.Object) then
            -- CWaring("AsyncLoadAssetCtrl:UnLoad Path Suc:" .. Path)
            UnLua.Unref(RefDes.Object)
        end
        RefDes.RefProxy = nil
    end
    self.Path2RefDes[Path] = nil
end

--[[
    卸载多个资源
    解引用
]]
function AsyncLoadAssetCtrl:UnLoadList(PathList)
    if not PathList or #PathList <= 0 then
        CWaring("AsyncLoadAssetCtrl:UnLoadList PathList nil")
        return
    end
    for k,v in pairs(PathList) do
        self:UnLoad(v)
    end
end

--[[
    卸载全部资源
    解引用
]]
function AsyncLoadAssetCtrl:UnLoadAll()
    for k,v in pairs(self.Path2RefDes) do
        self:UnLoad(k)
    end
end

--[[
    添加不释放的资源列表
]]
function AsyncLoadAssetCtrl:AddUnLoadBlackPathList(List)
    for k,v in ipairs(List) do
        self.BlackPath2Unload[v] = 1
    end
end
--[[
    移除不释放的资源列表
]]
function AsyncLoadAssetCtrl:RemoveUnLoadBlackPathList(List)
    for k,v in ipairs(List) do
        self.BlackPath2Unload[v] = nil
    end
end


--[[
    启动异步加载，加载Model列表资源
]]
function AsyncLoadAssetCtrl:StartAyncLoad(AsyncPreLoadAssetList,OnAyncLoadCallback)
    local NeedPreLoadAssetList = {}
    local BlackPathList = {}
    for _, V in ipairs(AsyncPreLoadAssetList) do
        if not self.Path2RefDes[V.Path] then
            table.insert(NeedPreLoadAssetList, V.Path)
            if V.IsPersistence then
                table.insert(BlackPathList, V.Path)
            end
        else
            CWaring("AsyncLoadAssetCtrl:StartAyncLoad Asset Already Ref:" .. V.Path)
        end
    end
    self:AddUnLoadBlackPathList(BlackPathList)
	self:RequestAsyncLoadList(NeedPreLoadAssetList, function()
        if OnAyncLoadCallback ~= nil then
            OnAyncLoadCallback()
        end
    end)
end
