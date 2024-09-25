--[[
    LoadingJobLogic 回调类
]] 
local class_name = "LoadingJobLogic"
local LoadingJobLogic = BaseClass(nil, class_name)


function LoadingJobLogic:__init()
    self.IsWorking = false
end

function LoadingJobLogic:ReqLoading(LoadingShowParam,NeedPreloadList, CallBackFunc)
    if self.IsWorking then
        CError("LoadingJobLogic Already IsWorking")
        return
    end
    self.CallBackFunc =  CallBackFunc
    self.LoadingShowParam =  LoadingShowParam
    self.IsWorking = true

    if not NeedPreloadList or #NeedPreloadList <= 0 then
        self:OnLoadSucCallback()
    else
        MvcEntry:GetCtrl(AsyncLoadAssetCtrl):StartAyncLoad(NeedPreloadList, Bind(self,self.OnLoadSucCallback))
    end
end

function LoadingJobLogic:Close()
    self.IsWorking = false
end

function LoadingJobLogic:OnLoadSucCallback()
    if not self.IsWorking then
        return
    end
    self.IsWorking = false
    -- UE.UAsyncLoadingScreenLibrary.SetLoadingScreenIndex(0)
    -- UE.UAsyncLoadingScreenLibrary.PreLoadResDepend()
    -- UE.UAsyncLoadingScreenLibrary.SetNeedShowLoadingProgress(true)
    -- -- 这边手动强制开启LoadingScreen
    -- UE.UAsyncLoadingScreenLibrary.StartLoadingScreen()

    --开启Loading界面展示
    MvcEntry:GetCtrl(LoadingCtrl):TriggerStartLoadingScreen(self.LoadingShowParam)
    
    if self.CallBackFunc then
        self.CallBackFunc()
    end
end

return LoadingJobLogic
