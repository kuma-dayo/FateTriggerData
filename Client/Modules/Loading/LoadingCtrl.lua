--[[
    异步登录Loading模块管理
]]
local class_name = "LoadingCtrl"
---@class LoadingCtrl : UserGameController
LoadingCtrl = LoadingCtrl or BaseClass(UserGameController,class_name)

LoadingCtrl.TypeEnum = {
	--大厅进战斗
	HALL_TO_BATTLE = 0,
	--战斗回大厅
	BATTLE_TO_HALL = 1,
	--其它，待定
	OTHER = 2,
}

function LoadingCtrl:__init()
    CWaring("==LoadingCtrl init")
end

function LoadingCtrl:Initialize()
    self:DataInit()
end

function LoadingCtrl:DataInit()
    self.ImgSelect = nil
    self.MovieSelect = nil
    self.TipSelectList = nil
    self.NeedPreloadList = nil


    self.ShowParamKey2TipsList = {}
    self.ShowParamKey2ImgsList = {}

    self.TypeEnum2ParameterConfigKey = {
        [LoadingCtrl.TypeEnum.HALL_TO_BATTLE] = ParameterConfig.LoadingTipsNumStart,
        [LoadingCtrl.TypeEnum.BATTLE_TO_HALL] = ParameterConfig.LoadingTipsNumEnd,
    }
end

function LoadingCtrl:OnLogout()
    self:UnloadListInner()
end

function LoadingCtrl:AddMsgListenersUser()
    self.MsgList = {
        { Model = CommonModel, MsgName = CommonModel.ON_ASYNC_LOADING_FINISHED,    Func = self.ON_ASYNC_LOADING_FINISHED_Func },
    }

    self.MsgListGMP = {
		-- { InBindObject = _G.MainSubSystem,	MsgName = ConstUtil.MsgCpp.ASYNCLOADINGSCREEN_SHOW,Func = Bind(self,self.OnAsyncLoadingStartLoadingScreen), bCppMsg = true, WatchedObject = nil },
		{ InBindObject = _G.MainSubSystem,	MsgName = ConstUtil.MsgCpp.ASYNCLOADINGSCREEN_HIDE,Func = Bind(self,self.OnAsyncLoadingStopLoadingScreen), bCppMsg = true, WatchedObject = nil },
    }
end

-- --[[
--     通知Loading界面展示
-- ]]
-- function LoadingCtrl:OnAsyncLoadingStartLoadingScreen()
--     if not UE.UAsyncLoadingScreenLibrary.GetIsEnablePureUMGPlan() then
--         return
--     end
--     CWaring("LoadingCtrl:OnAsyncLoadingStartLoadingScreen")
--     self:OpenView(ViewConst.Loading)
-- end

--[[
    通知Loading界面展示
    由LoadingJobLogic 触发
]]
function LoadingCtrl:TriggerStartLoadingScreen(LoadingShowParam)
    CWaring("LoadingCtrl:OnAsyncLoadingStartLoadingScreen")
    self:OpenView(ViewConst.Loading,LoadingShowParam)
end
--[[
    通知Loading界面关闭
]]
function LoadingCtrl:OnAsyncLoadingStopLoadingScreen()
    if not UE.UAsyncLoadingScreenLibrary.GetIsEnablePureUMGPlan() then
        return
    end
    CWaring("LoadingCtrl:OnAsyncLoadingStopLoadingScreen")
    self:GetModel(CommonModel):DispatchType(CommonModel.ON_ASYNC_LOADING_SHOW_STOP)
end


function LoadingCtrl:GenerateShowKey(LoadingShowParam)
    return StringUtil.FormatSimple("{0}_{1}_{2}_{3}_{4}",LoadingShowParam.TypeEnum,LoadingShowParam.ModeId,LoadingShowParam.SceneId)
end

--[[
    计算出，符合ModeId及SceneId对应的展示列表
]]
function LoadingCtrl:GenerateCacheByShowParam(LoadingShowParam,ShowKey)
    if not self.ShowParamKey2TipsList[ShowKey] then
        self.ShowParamKey2TipsList[ShowKey] = self.ShowParamKey2TipsList[ShowKey] or {}
        -- local LoadingTipsList = G_ConfigHelper:GetDict(Cfg_LoadingTipsCfg)
        local LoadingTipsList = G_ConfigHelper:GetMultiItemsByKey(Cfg_LoadingTipsCfg,Cfg_LoadingTipsCfg_P.Stage,LoadingShowParam.TypeEnum)
        LoadingTipsList = LoadingTipsList or {}
        CWaring("LoadingCtrl LoadingTipsList Length:" .. #LoadingTipsList .. "|TypeEnum:" .. LoadingShowParam.TypeEnum)
        for k,v in ipairs(LoadingTipsList) do
            local Useful = true
            repeat
                if v[Cfg_LoadingTipsCfg_P.ModeId] > 0 and LoadingShowParam.ModeId > 0 and v[Cfg_LoadingTipsCfg_P.ModeId] ~= LoadingShowParam.ModeId then
                    print("LoadingCtrl:GenerateCacheByShowParam Tip ModeId Limit:" .. v[Cfg_LoadingTipsCfg_P.ID])
                    Useful = false
                    break
                end
                if v[Cfg_LoadingTipsCfg_P.SceneId] > 0 and LoadingShowParam.SceneId > 0 and v[Cfg_LoadingTipsCfg_P.SceneId] ~= LoadingShowParam.SceneId then
                    print("LoadingCtrl:GenerateCacheByShowParam Tip SceneId Limit:" .. v[Cfg_LoadingTipsCfg_P.ID])
                    Useful = false
                    break
                end
            until true
            if Useful then
                self.ShowParamKey2TipsList[ShowKey][#self.ShowParamKey2TipsList[ShowKey] + 1] = v
            end
        end
    end
    --TODO 计算出，符合ModeId及SceneId对应的展示列表
    if not self.ShowParamKey2ImgsList[ShowKey] then
        self.ShowParamKey2ImgsList[ShowKey] = self.ShowParamKey2ImgsList[ShowKey] or {}
        -- local LoadingImgsList = G_ConfigHelper:GetDict(Cfg_LoadingImagesCfg)
        local LoadingImgsList = G_ConfigHelper:GetMultiItemsByKey(Cfg_LoadingImagesCfg,Cfg_LoadingImagesCfg_P.Stage,LoadingShowParam.TypeEnum)
        LoadingImgsList = LoadingImgsList or {}
        CWaring("LoadingCtrl LoadingImgsList Length:" .. #LoadingImgsList .. "|TypeEnum:" .. LoadingShowParam.TypeEnum)
        for k,v in ipairs(LoadingImgsList) do
            local Useful = true
            repeat
                if v[Cfg_LoadingImagesCfg_P.ModeId] > 0 and LoadingShowParam.ModeId > 0 and v[Cfg_LoadingImagesCfg_P.ModeId] ~= LoadingShowParam.ModeId then
                    print("LoadingCtrl:GenerateCacheByShowParam Img ModeId Limit:" .. v[Cfg_LoadingImagesCfg_P.ID])
                    Useful = false
                    break
                end
                if v[Cfg_LoadingImagesCfg_P.SceneId] > 0 and LoadingShowParam.SceneId > 0 and v[Cfg_LoadingImagesCfg_P.SceneId] ~= LoadingShowParam.SceneId then
                    print("LoadingCtrl:GenerateCacheByShowParam Img SceneId Limit:" .. v[Cfg_LoadingImagesCfg_P.ID])
                    Useful = false
                    break
                end
            until true
            if Useful then
                self.ShowParamKey2ImgsList[ShowKey][#self.ShowParamKey2ImgsList[ShowKey] + 1] = v
            end
        end
    end
end

--[[
    根据LoadingShowParam 参数，随机出当前需要展示的内容

    LoadingShowParam 参数内容
    TypeId 类型Id，  1表示Tip  2表示Img
]]
function LoadingCtrl:CalculateShowCfgList(LoadingShowParam,TypeId,ShowNum)
    --TODO 随机Tips
    local ShowKey = self:GenerateShowKey(LoadingShowParam)
    self:GenerateCacheByShowParam(LoadingShowParam,ShowKey)
    local CanShowCfgsList = {}
    -- local CanShowCfgsListWeight = 0
    local List = nil
    local LevelLimitKey = ""
    local BattleTimeMinKey = ""
    local BattleTimeMaxKey = ""
    local SettlementRankLimitKey = ""
    local WeightKey = ""
    local IdKey = ""
    if TypeId == 1 then
        List = self.ShowParamKey2TipsList[ShowKey]
        LevelLimitKey = Cfg_LoadingTipsCfg_P.LevelLimit
        BattleTimeMinKey = Cfg_LoadingTipsCfg_P.BattleTimeMin
        BattleTimeMaxKey = Cfg_LoadingTipsCfg_P.BattleTimeMax
        SettlementRankLimitKey = Cfg_LoadingTipsCfg_P.SettlementRankLimit
        WeightKey = Cfg_LoadingTipsCfg_P.Weight
        IdKey = Cfg_LoadingTipsCfg_P.ID
    else
        List = self.ShowParamKey2ImgsList[ShowKey]
        LevelLimitKey = Cfg_LoadingImagesCfg_P.LevelLimit
        BattleTimeMinKey = Cfg_LoadingImagesCfg_P.BattleTimeMin
        BattleTimeMaxKey = Cfg_LoadingImagesCfg_P.BattleTimeMax
        SettlementRankLimitKey = Cfg_LoadingImagesCfg_P.SettlementRankLimit
        WeightKey = Cfg_LoadingImagesCfg_P.Weight
        IdKey = Cfg_LoadingImagesCfg_P.ID
    end
    for k,v in ipairs(List) do
        local Useful = true
        repeat
            local LevelLimitArray = v[LevelLimitKey]
            if LevelLimitArray:Num() >= 2  then
                --TODO 判断是否在等级区间
                if not (LoadingShowParam.Level >= LevelLimitArray:Get(1) and LoadingShowParam.Level <= LevelLimitArray:Get(2)) then
                    print("LoadingCtrl:CalculateShowCfgList LevelLimit:" .. TypeId .. "|" .. v[IdKey])
                    Useful = false
                    break
                end
            end
            if v[BattleTimeMinKey] > 0 then
                --最低对局次数限制
                if LoadingShowParam.BattleTime < v[BattleTimeMinKey] then
                    print("LoadingCtrl:CalculateShowCfgList BattleTimeMin:" .. TypeId .. "|" .. v[IdKey])
                    Useful = false
                    break
                end
            end
            if v[BattleTimeMaxKey] > 0 then
                --最大对局次数限制
                if LoadingShowParam.BattleTime > v[BattleTimeMaxKey] then
                    print("LoadingCtrl:CalculateShowCfgList BattleTimeMax:" .. TypeId .. "|" .. v[IdKey])
                    Useful = false
                    break
                end
            end
            local SettlementRankLimitArray = v[SettlementRankLimitKey]
            if SettlementRankLimitArray:Num() >= 2 then
                --TODO 判断是否在结算排名区间
                if not (LoadingShowParam.SettlementRankIndex >= SettlementRankLimitArray:Get(1) and LoadingShowParam.SettlementRankIndex <= SettlementRankLimitArray:Get(2)) then
                    print("LoadingCtrl:CalculateShowCfgList SettlementRankLimit:" .. TypeId .. "|" .. v[IdKey])
                    Useful = false
                    break
                end
            end
        until true
        if Useful then
            CanShowCfgsList[#CanShowCfgsList + 1] = v
            -- CanShowCfgsListWeight = CanShowCfgsListWeight + v[WeightKey]
        end
    end

    local TheRandomSelectFunc = function(RandomShowCfgList)
        CWaring("LoadingCtrl:TheRandomSelectFunc:" .. #RandomShowCfgList)
        local WeightMax = 0
        for k, v in ipairs(RandomShowCfgList) do
            WeightMax = WeightMax + v[WeightKey]
        end
        local Cfg = nil
        local Index = 0
        local RandomValue =	math.random(0, WeightMax)
        local TempMax = 0
        for k, v in ipairs(RandomShowCfgList) do
            TempMax = TempMax + v[WeightKey]
            if TempMax >= RandomValue then
                CWaring("LoadingCtrl:TheRandomSelectFunc Suc  AllWeight:" .. WeightMax .. "|RandowValue:" .. RandomValue .. "|TempMax:" .. TempMax .. "|IndexId:" .. v[IdKey] .. "|IndexWeight:" .. v[WeightKey])
                Cfg = v
                Index = k
                break
            end
        end
        return Cfg,Index
    end

    local CfgSelectList = {}
    if ShowNum <= 1 then
        local Cfg = TheRandomSelectFunc(CanShowCfgsList)
        if Cfg then
            CfgSelectList[#CfgSelectList + 1] = Cfg
        end
    elseif #CanShowCfgsList <= ShowNum then
        for i=1,ShowNum do
            CfgSelectList[#CfgSelectList + 1] = CanShowCfgsList[i]
        end
    else
        --TODO 需要进行ShowNum随机
        for i=1,ShowNum do
            local Cfg,Index = TheRandomSelectFunc(CanShowCfgsList)
            if Cfg then
                CfgSelectList[#CfgSelectList + 1] = Cfg
                table.remove(CanShowCfgsList,Index)
            end
        end
    end
    return CfgSelectList
end

--[[
    LoadingShowParam = {
        TypeEnum = LoadingCtrl.TypeEnum.BATTLE_TO_HALL,
        --模式Id
        ModeId = 1,
        --场景Id
        SceneId = 2,
        --玩家当前等级
        Level = 3,
        --总战斗次数
        BattleTime = 1,
        --结算排名（可选）
        SettlementRankIndex = 1,
    }
]]
function LoadingCtrl:ReqLoadingScreenShow(LoadingShowParam,CallBackFunc)
    if UE.UAsyncLoadingScreenLibrary.GetIsEnableLoadingScreen() then
        --TODO 根据 LoadingShowParam传参，进行Loading显示计算
        LoadingShowParam.TypeEnum = LoadingShowParam.TypeEnum or LoadingCtrl.TypeEnum.BATTLE_TO_HALL
        MvcEntry:GetModel(EventTrackingModel):SetLoadingType(LoadingShowParam.TypeEnum) --缓存loading类型
        local TheMatchModel = self:GetModel(MatchModel)
        local TheUserModel = self:GetModel(UserModel)
        local TheHallSettlementModel = self:GetModel(HallSettlementModel)
        local ThePlayerStatModel = self:GetModel(PlayerStatModel)
        LoadingShowParam.ModeId = LoadingShowParam.ModeId or TheMatchModel:GetModeId()
        LoadingShowParam.SceneId = LoadingShowParam.SceneId or TheMatchModel:GetSceneId()
        LoadingShowParam.Level = LoadingShowParam.Level or TheUserModel:GetPlayerLv()
        LoadingShowParam.BattleTime = LoadingShowParam.BattleTime or ThePlayerStatModel:GetValueWithStatTypeAndItemKey(Pb_Enum_PLAYER_STAT_TYPE.STAT_BATTLE_MODE)
        LoadingShowParam.SettlementRankIndex = LoadingShowParam.SettlementRankIndex or TheHallSettlementModel:GetRankNum()

        print_r(LoadingShowParam,"LoadingCtrl:ReqLoadingScreenShow LoadingShowParam:",true)

        if self.NeedPreloadList then
            --进行旧资产的主动unref
            self:UnloadListInner()
        end
        
        self.NeedPreloadList = {
            {
                Path = "/Game/BluePrints/UMG/OutsideGame/Loading/WBP_Loading3.WBP_Loading3_C",
                IsPersistence = false
            }
        }
        
        local NeedShowTipNum = CommonUtil.GetParameterConfig(self.TypeEnum2ParameterConfigKey[LoadingShowParam.TypeEnum],2)
        local CfgTipsList = self:CalculateShowCfgList(LoadingShowParam,1,NeedShowTipNum)
        if CfgTipsList and #CfgTipsList > 0 then
            self.TipSelectList = {}
            for _,CfgTips in ipairs(CfgTipsList) do
                if string.len(CfgTips[Cfg_LoadingTipsCfg_P.Tip]) > 0 then
                    self.TipSelectList[#self.TipSelectList + 1] = CfgTips[Cfg_LoadingTipsCfg_P.Tip] 
                    CWaring("LoadingCtrl:ReqLoadingScreenShow TipSelectList:" .. StringUtil.ConvertFText2String(CfgTips[Cfg_LoadingTipsCfg_P.Tip]))
                else
                    CWaring("LoadingCtrl:ReqLoadingScreenShow Cfg_LoadingTipsCfg_P Tip Empty:" .. CfgTips[Cfg_LoadingTipsCfg_P.ID])
                end
            end
        else
            print_r(LoadingShowParam,"LoadingCtrl:ReqLoadingScreenShow CfgTipsList not found!",true)
        end

        local CfgImgsList = self:CalculateShowCfgList(LoadingShowParam,2,1)
        if CfgImgsList and #CfgImgsList > 0 then
            local CfgImgs = CfgImgsList[1]
            if string.len(CfgImgs[Cfg_LoadingImagesCfg_P.ImgBackground]) > 0 then
                self.ImgSelect = CfgImgs[Cfg_LoadingImagesCfg_P.ImgBackground]
                local PreloadItem = {
                    Path = self.ImgSelect,
                    IsPersistence = false
                }
                table.insert(self.NeedPreloadList, PreloadItem)

                CWaring("LoadingCtrl:ReqLoadingScreenShow ImgSelect:" .. self.ImgSelect)
            else
                CWaring("LoadingCtrl:ReqLoadingScreenShow Cfg_LoadingImagesCfg_P Tip Empty:" .. CfgImgs[Cfg_LoadingImagesCfg_P.ID])
            end
        else
            print_r(LoadingShowParam,"LoadingCtrl:ReqLoadingScreenShow CfgImgsList not found!",true)
        end
        

        --TODO 进行Loading展示的依赖资源预加载，异步加载成功之后，再执行Loading显示及CallBackFunc
        local Job = require("Client.Modules.Loading.LoadingJobLogic").New()
        Job:ReqLoading(LoadingShowParam,self.NeedPreloadList,CallBackFunc)

        return Job
    else
        CallBackFunc()
        return nil
    end
end

function LoadingCtrl:GetTipSelectList()
    return self.TipSelectList  or {}
end

function LoadingCtrl:GetImgSelect()
    return self.ImgSelect or nil
end

function LoadingCtrl:ON_ASYNC_LOADING_FINISHED_Func()
    self:UnloadListInner()
end

function LoadingCtrl:UnloadListInner()
    --需要主动UnRef已加载的资产
    if self.NeedPreloadList then
        local PathList = {}
        for k,v in pairs(self.NeedPreloadList) do
            PathList[#PathList + 1] = v.Path
        end
        self:GetSingleton(AsyncLoadAssetCtrl):UnLoadList(PathList)
    end
    self.NeedPreloadList = nil
end


