--[[
  G_ConfigHelper:GetStrFromCommonStaticST("Lua_FastLoad_Trunksmokingsuit"),
  "本地",
  "宁森私服",
  "成风私服",
  "海洋私服",
  "徐放私服",
  "旭尧私服",
  "天翊私服",
  "火山引擎测试服",
  "后台私服",
--]]

local AutoLogin = false          --开启快速登录，需要时填true即可

local FastLoad = {
    AccountID   = "bailixi",
    SeverName   = "trunk-冒烟服",
}

---自动登录检查，仅editor模式下生效
---@param SeverList table 服务器列表
function FastLoad.FastLoadCehck(SeverList)
    if not UE.UGFUnluaHelper.IsEditor() then return false end
    if not AutoLogin then return false end

    local Sever
    for _, severInfo in pairs(SeverList) do
        if severInfo.Name == FastLoad.SeverName then
            Sever = severInfo
            break
        end
    end
    if not Sever then return false end

    ---@type UserModel
    local Model = MvcEntry:GetModel(UserModel)
    Model.Ip = Sever.Ip
    Model.Port = Sever.Port
    Model.ServerId = Sever.ServerId or 0
    Model.SdkOpenId = FastLoad.AccountID
    MvcEntry:SendMessage(CommonEvent.CONNECT_TO_MAIN_SOCKET)
    return true
end

--[[ 打开这里，点击主界面的设置按钮就会触发下面的函数了
--]]
-- function FastLoad.CustomFunc()
    -- msgParam = {
    --     Url = "https://www.google.com/",
    --   }
    --   UIWebBrowser.Show(msgParam)

    -- MvcEntry:GetCtrl(ShopCtrl):SendPlayerRechargeReq(1)

	--内存GC的测试代码
	-- MvcEntry:GetCtrl(AsyncLoadAssetCtrl):UnLoadAll()
	-- collectgarbage("collect")
	-- MvcEntry:OpenView(ViewConst.LevelEmpty)
	--//
-- end


---【案例】匹配模拟测试代码
---如果想通过 lua.do 来调用，可使用下发代码来调用
--- lua.do local FastLoad = require("Client.Modules.DeveloperTools.FastLoad"); FastLoad.SimulateSendMatchReqWhenMatching();
function FastLoad.SimulateSendMatchReqWhenMatching()
    Timer.InsertCoroutineTimer(Timer.NEXT_TICK, function()
        local MatchModel = MvcEntry:GetModel(MatchModel)
        MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchRequesting)
        local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)
        MatchCtrl:SendMatchReq()
        coroutine.yield(0.3)
        MatchModel:SetMatchState(MatchModel.Enum_MatchState.Matching)
        MatchCtrl:SendMatchReq()
        coroutine.yield(0.5)
        MatchModel:SetMatchState(MatchModel.Enum_MatchState.MatchSuccess)
        MatchCtrl:SendMatchReq()
        coroutine.yield(3)
        MatchCtrl:OnMatchResultSync({
            Result = false,
            Msg = "TEST"
        })
    end)
end

--- lua.do local FastLoad = require("Client.Modules.DeveloperTools.FastLoad"); FastLoad.SimulateAddIntervalMenber();
function FastLoad.SimulateAddIntervalMenber(Count, Interval)
    Interval = Interval or 1
    Count = math.min(Count, 3)
    Timer.InsertCoroutineTimer(Timer.NEXT_TICK, function()
        for i = 1, Count do
            FastLoad.SimulateAddMenber(i)
            coroutine.yield(Interval)
        end
    end)
end

---如果想通过 lua.do 来调用，可使用下发代码来调用
--- lua.do local FastLoad = require("Client.Modules.DeveloperTools.FastLoad"); FastLoad.SimulateAddMenber();
function FastLoad.SimulateAddMenber(Count)
    Count = Count or 1
    Count = math.min(Count, 3)
    local Uid = MvcEntry:GetModel(UserModel):GetPlayerId()
    local Member = {}

    local HeroCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.IsShow, 1)
    local HeroSkinList = {}
    for _, v in pairs(HeroCfgs) do
        local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.HeroId,v[Cfg_HeroConfig_P.Id])
        HeroSkinList = ListMerge(HeroSkinList,Cfgs)
    end
    local WeaponCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponConfig, Cfg_WeaponConfig_P.IsShow, true)
    local WeaponSkinList = {}
    for _, v in pairs(WeaponCfgs) do
        local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.WeaponId,v[Cfg_WeaponConfig_P.WeaponId])
        WeaponSkinList = ListMerge(WeaponSkinList,Cfgs)
    end
    for i = 0, Count do
        local RandomHeroIndex = math.random(1,#HeroSkinList)
        local RandomWeaponIndex = math.random(1,#WeaponSkinList)
        Member[Uid + i] = {
            WeaponId = WeaponSkinList[RandomWeaponIndex][Cfg_WeaponSkinConfig_P.WeaponId],
            WeaponSkinId = WeaponSkinList[RandomWeaponIndex][Cfg_WeaponSkinConfig_P.SkinId],
            PlayerId = Uid + i,
            PlayerName = "AlanJohnson"..(Uid + i),
            PlatformId = 0,
            JoinTime = 1720249737,
            Addr = 0,
            HeadId = 600010001,
            Status = 1,
            HeroSkinId = HeroSkinList[RandomHeroIndex][Cfg_HeroSkin_P.SkinId],
            HeroId = HeroSkinList[RandomHeroIndex][Cfg_HeroSkin_P.HeroId]
        }
        print_r(Member[Uid + i])
    end
    local TeamInfo = {
        LeaderId = Uid,
        PlayerCnt = Count + 1,
        LevelId = 1011001,
        CreateTime = 1720249737,
        TeamId = 29041360897,
        View = 3,
        TeamType = 4,
        TargetId = Uid,
        GameplayId = 10001,
        Reason = 1,
        IsCrossPlatform = true,
        Members =  Member,
        InviteList = {},
        ApplyList = {},
        MergeRecvList = {},
        MergeSendList = {}
    }
    MvcEntry:GetModel(TeamModel):SetTeamInfo(TeamInfo)
end

--- lua.do local FastLoad = require("Client.Modules.DeveloperTools.FastLoad"); FastLoad.SimulateChangeMenber();
function FastLoad.SimulateChangeMenber(i)
    local Uid = MvcEntry:GetModel(UserModel):GetPlayerId()

    local HeroCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.IsShow, 1)
    local HeroSkinList = {}
    for _, v in pairs(HeroCfgs) do
        local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.HeroId,v[Cfg_HeroConfig_P.Id])
        HeroSkinList = ListMerge(HeroSkinList,Cfgs)
    end
    local WeaponCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponConfig, Cfg_WeaponConfig_P.IsShow, true)
    local WeaponSkinList = {}
    for _, v in pairs(WeaponCfgs) do
        local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.WeaponId,v[Cfg_WeaponConfig_P.WeaponId])
        WeaponSkinList = ListMerge(WeaponSkinList,Cfgs)
    end
    local RandomHeroIndex = math.random(1,#HeroSkinList)
    local RandomWeaponIndex = math.random(1,#WeaponSkinList)
    local Member = {
        WeaponId = WeaponSkinList[RandomWeaponIndex][Cfg_WeaponSkinConfig_P.WeaponId],
        WeaponSkinId = WeaponSkinList[RandomWeaponIndex][Cfg_WeaponSkinConfig_P.SkinId],
        PlayerId = Uid + i,
        PlayerName = "AlanJohnson"..(Uid + i),
        PlatformId = 0,
        JoinTime = 1720249737,
        Addr = 0,
        HeadId = 600010001,
        Status = 1,
        HeroSkinId = HeroSkinList[RandomHeroIndex][Cfg_HeroSkin_P.SkinId],
        HeroId = HeroSkinList[RandomHeroIndex][Cfg_HeroSkin_P.HeroId]
    }
    MvcEntry:GetModel(TeamModel):DispatchType(TeamModel.ON_TEAM_MEMBER_HERO_INFO_CHANGED,Member)
end

--- lua.do local FastLoad = require("Client.Modules.DeveloperTools.FastLoad"); FastLoad.ChangeMenberWeapon();
function FastLoad.ChangeMenberWeapon()
    local Uid = MvcEntry:GetModel(UserModel):GetPlayerId()
    local WeaponCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponConfig, Cfg_WeaponConfig_P.IsShow, true)
    local WeaponSkinList = {}
    for _, v in pairs(WeaponCfgs) do
        local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.WeaponId,v[Cfg_WeaponConfig_P.WeaponId])
        WeaponSkinList = ListMerge(WeaponSkinList,Cfgs)
    end
    local RandomWeaponIndex = math.random(1,#WeaponSkinList)
    -- local WeaponId = WeaponSkinList[RandomWeaponIndex][Cfg_WeaponSkinConfig_P.WeaponId]
    local WeaponSkinId = WeaponSkinList[RandomWeaponIndex][Cfg_WeaponSkinConfig_P.SkinId]

    local RandomIndex = math.random(0,5)
    MvcEntry:GetModel(HallModel):DispatchType(
        HallModel.ON_HERO_PUTON_WEAPON, 
        {HeroInstID = Uid + RandomIndex, WeaponSkinID = WeaponSkinId, AnimControl = true, PlayDissolveLS = true})
end

--- lua.do local FastLoad = require("Client.Modules.DeveloperTools.FastLoad"); FastLoad.ForcePlayIdleLS(1);
function FastLoad.ForcePlayIdleLS(ID)
    MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_HALL_LS_CHANGE_TEST, {IsClick = false, ID = ID})
end

--- lua.do local FastLoad = require("Client.Modules.DeveloperTools.FastLoad"); FastLoad.ForcePlayClickLS(1);
function FastLoad.ForcePlayClickLS(ID)
    MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_HALL_LS_CHANGE_TEST, {IsClick = true, ID = ID})
end

--- lua.do local FastLoad = require("Client.Modules.DeveloperTools.FastLoad"); FastLoad.SimulateGotoBattle();
function FastLoad.SimulateGotoBattle()
    Timer.InsertCoroutineTimer(Timer.NEXT_TICK, function()
        MvcEntry:GetModel(MatchModel):DispatchType(MatchModel.ON_MATCH_SUCCESS, nil)
        coroutine.yield(1)
        MvcEntry:GetModel(MatchModel):DispatchType(MatchModel.ON_GAMEMATCH_DSMETA_SYNC, {
            DsMetaSrc = 0,
            DsMeta = {
                GameId = "11111",
                Ip = "11111",
                Port = 11111,
                PlayerId = 211,
                EncryptKey = "211",
                ServerPublicKey = "211",
                ServerKeyMD5 = "211",
                DsGroupId = 1111,
                -- string GameId = 1; // GameId
                -- string Ip = 2; // Ds Ip
                -- int32 Port = 3; // Ds Port
                -- string GameBranch = 4; // GameBranch 不知道具体用处
                -- int64 PlayerId = 5; // 玩家PlayerId
                -- bool bAsanDs = 6; //ds是否是Asan版
            
                -- bytes EncryptKey       = 7; // 加密密钥
                -- string ServerPublicKey  = 8; // 后台DH生成的公钥（根据ClientPubicKey）
                -- string ServerKeyMD5     = 9; // DSKey的MD5值
                -- int32 DsGroupId = 10;    // 战斗集群Id
            }
        })
        coroutine.yield(10)
        _G.GameInstance:SetGameStageType(UE.EGameStageType.Travel2Battle)
        MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP)
        MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.TravelFailure)
        -- MvcEntry:GetCtrl(AsyncLoadAssetCtrl):UnLoadAll()
        -- collectgarbage("collect")
        -- MvcEntry:OpenView(ViewConst.LevelEmpty)

        -- coroutine.yield(1)
        
        -- LuaGC()
        -- local Param = {
        --     ExitBattleReason = ConstUtil.ExitBattleReson.Normal,
        -- }
        -- MvcEntry:OpenView(ViewConst.VirtualHall,Param)
    end)
end

-- lua.do local FastLoad = require("Client.Modules.DeveloperTools.FastLoad"); FastLoad.UpdateShowAvatar();
function FastLoad.UpdateShowAvatar(ViewID, HeroID)
    ViewID = ViewID or 1000
    HeroID = HeroID or 200070000
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    local HeroSkinList = {}
    local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.HeroId,HeroID)
    HeroSkinList = ListMerge(HeroSkinList,Cfgs)
    local RandomHeroIndex = math.random(1,#HeroSkinList)

    local SpawnHeroParam = {
        ViewID = ViewID,
        InstID = 0,
        HeroId = HeroID,
        SkinID = HeroSkinList[RandomHeroIndex][Cfg_HeroSkin_P.SkinId],
        PlayShowLS = true
    }
    print_r(SpawnHeroParam,"UpdateShowAvatar",true)
    local CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    
    local SetBindingsAnim = {
        {
            ActorTag = "",
            Actor = CurShowAvatar:GetSkinActor(), 
            TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM,
        }
    }
    local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
    if CameraActor ~= nil then
        local CameraBinding = {
            ActorTag = "",
            Actor = CameraActor, 
            TargetTag = SequenceModel.BindTagEnum.CAMERA,
        }
        table.insert(SetBindingsAnim,CameraBinding)
    end
    local PlayParamAnim = {
        LevelSequenceAsset = "LevelSequence'/Game/Arts/Lobby/HeroMain/Animations/LS_Cam_Hall_To_HeroMain.LS_Cam_Hall_To_HeroMain'",
        SetBindings = SetBindingsAnim,
        WaitUtilActorHasBeenPrepared = true
    }
    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(StringUtil.FormatSimple("{0}_{1}_Anim",ViewConst.Hall,CommonConst.HL_HERO), function ()
        -- CWaring("HeroMdt:PlaySequenceByTag Suc")
    end, PlayParamAnim)
end

return FastLoad