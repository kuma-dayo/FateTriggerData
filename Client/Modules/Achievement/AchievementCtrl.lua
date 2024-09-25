
require("Client.Modules.Achievement.AchievementModel");
local  AchievementConst = require("Client.Modules.Achievement.AchievementConst")
local class_name = "AchievementCtrl";
---@class AchievementCtrl : UserGameController
---@field private super UserGameController
---@field private model AchievementModel
AchievementCtrl = AchievementCtrl or BaseClass(UserGameController, class_name);

AchievementCtrl.test = false
AchievementCtrl.IsOpen = true

function AchievementCtrl:__init()
    CWaring("==AchievementCtrl init")
    self.Model = nil
    self.CacheGetAchvCfgDataMissionID = 0 -- 缓存获取成就配置数据的MissionId
    self.CacheIsPlayingHallLS = false -- 缓存是否正在播放大厅LS
    self.GetPlayerAchiListCallBack = nil
end

function AchievementCtrl:Initialize()
    self.Model = self:GetModel(AchievementModel)
end

---@param data any
function AchievementCtrl:OnLogin(data)
    CWaring("AchievementCtrl OnLogin")
    if self.test then
        local datas = self.Model:GetDataList()
        for i, v in ipairs(datas) do
            v.CanLevelUp = math.random(0,1) == 1
            --v.State = math.random(0,1) == 1 and 1 or 2
            v.LV = math.floor(math.random(1,5))
            v.Quality = math.floor(math.random(1,5))
            v.MaxLV = 5
            v.Count = math.floor(math.random(0,100))
            v.CurProgress = math.floor(math.random(0,1000))
            v.MaxProgress = 1000
            v.State = AchievementConst.OWN_STATE.Not
            if v.State == AchievementConst.OWN_STATE.Have then
                v.GetTimeStamp = math.floor(math.random(0,1000000000))
            end
            self.Model:UpdateCompleteList(v)
        end
    end
end

--- 玩家登出
---@param data any
function AchievementCtrl:OnLogout(data)
    CWaring("AchievementCtrl OnLogout")
end

function AchievementCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.GetAchievementInfoRsp, Func = self.OnGetAchievementInfoRsp},
        {MsgName = Pb_Message.SetAchievementSlotRsp, Func = self.OnSetAchievementSlotRsp},
        {MsgName = Pb_Message.RemoveAchievementSlotRsp, Func = self.OnRemoveAchievementSlotRsp},
        {MsgName = Pb_Message.AchievementInfoUpdateNotify, Func = self.OnAchievementInfoUpdateNotify},
    }
    self.MsgList = {
        --Model = ViewModel, MsgName = ViewConst.VirtualLogin,  Func = self.OnVirtualLoginState
        {Model = HallModel, 	MsgName = HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,	Func = self.On_TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_Func },
    }
end

function AchievementCtrl:OnGetAchievementInfoRsp(Res)
    if not self.IsOpen then
        return
    end
    print_r(Res, "===========================AchievementCtrl OnGetAchievementInfoRsp")

    if Res.PlayerId == 0 then
        Res.PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    end

    local IsOthers = not MvcEntry:GetModel(UserModel):IsSelf(Res.PlayerId)
    if not IsOthers then
        self.Model:InitData()
    end

    -- message AchievementInfoNode
    -- {
    --     int64 AchvId      = 1;    // 成就Id
    --     int64 FinishTime  = 2;    // 完成时间
    --     int32 FinishCnt   = 3;    // 完成次数
    -- }

    local tempData = {
        AchvId = 2,
        FinishTime = "2023.10.23",
        FinishCnt = 2
    }
    AchievementInfoList = Res.AchievementInfo
    --table.insert(AchievementInfoList, tempData)

    local AchvCfg = nil
    local tempMissionIDMap = {} --过滤下重复组Id，取最高Id，以免覆盖

    table.sort(AchievementInfoList, function(a, b)
        return a.AchvId > b.AchvId
    end)

    for k, v in pairs(AchievementInfoList) do
        local Data
        AchvCfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCfg, v.AchvId)

        if AchvCfg and not tempMissionIDMap[AchvCfg.MissionID] then
            tempMissionIDMap[AchvCfg.MissionID] = AchvCfg.MissionID
            if IsOthers then
                ---@type AchievementData
                Data = self.Model:GetPlayerAchieveData(Res.PlayerId, v.AchvId, AchvCfg.MissionID)
            else
                ---@type AchievementData
                Data = self.Model:GetData(AchvCfg.MissionID)
            end
            if Data then
                Data.State = AchievementConst.OWN_STATE.Have
    
                Data:UpdateDataFromCfgId(v.AchvId, AchvCfg.SubID)
                --Data.State = v.CurLevel > 0 and AchievementConst.OWN_STATE.Have or AchievementConst.OWN_STATE.Not
                Data.GetTimeStamp = v.FinishTime
                Data.Count = v.FinishCnt
                Data.LV = 0
                Data.CurProgress = 0
                if not IsOthers then
                    self.Model:UpdateCompleteList(Data)
                end            
            end
        end

    end

    if IsOthers and self.GetPlayerAchiListCallBack then
        self.GetPlayerAchiListCallBack(self.Model:GetPlayerCompleteList(Res.PlayerId))
        self.GetPlayerAchiListCallBack = nil
    end

    if Res.SlotMap then
        for i = 1, 3 do
            local SlotData = Res.SlotMap[i]
            self.Model:AddPlayerSlotByGroupId(i, SlotData, Res.PlayerId)
        end
    end

    self.Model:DispatchType(AchievementModel.ACHIEVE_PLAYER_DATA_UPDATE, Res.PlayerId) 
end

function AchievementCtrl:OnAchievementInfoUpdateNotify(Res)
    if not self.IsOpen then
        return
    end
    print_r(Res, "===========================AchievementCtrl OnAchievementInfoUpdateNotify")
    local AchvCfgData = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCfg, Res.AchvId)
    local Data = self.Model:GetData(AchvCfgData.MissionID)
    if not Data then 
        CError("AchievementCtrl:OnAchievementInfoUpdateNotify>>>>>>>>>> Data is nil!!Please check the AchvCfgData.MissionID")
        return 
    end
    Data.GetTimeStamp = Res.FinishTime
    Data.Count = Res.FinishCnt
    Data.State = AchievementConst.OWN_STATE.Have
    local NeedShowUpLvPop = Data:UpdateLV(AchvCfgData.Quality)
    if NeedShowUpLvPop then
        self.Model:UpdateCompleteList(Data)
        if self.CacheIsPlayingHallLS then --如果在播放大厅角色入场动画行为就缓存先不展示弹窗
			self.CacheGetAchvCfgDataMissionID = AchvCfgData.MissionID
        else
            self:AchieveInfoChangedRes(AchvCfgData.MissionID)
		end
    end
    Data:UpdateDataFromCfgId(Res.AchvId, AchvCfgData.SubID)

    self.Model:DispatchType(AchievementModel.ACHIEVE_DATA_UPDATE, AchvCfgData.MissionID) 
end

function AchievementCtrl:On_TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_Func(IsPlayOnFinished)
    self.CacheIsPlayingHallLS = not IsPlayOnFinished
    if IsPlayOnFinished and self.CacheGetAchvCfgDataMissionID > 0 then
        self:AchieveInfoChangedRes(self.CacheGetAchvCfgDataMissionID)
        self.CacheGetAchvCfgDataMissionID = 0
    end
end


function AchievementCtrl:GetAchievementInfoReq(PlayerId, GetPlayerAchiListCallBack, IsHideNetLoading)
    if not self.IsOpen then
        return
    end
    self.GetPlayerAchiListCallBack = GetPlayerAchiListCallBack
    if PlayerId ~= 0 and not MvcEntry:GetModel(UserModel):IsSelf(PlayerId) and self.GetPlayerAchiListCallBack then
        local Data = self.Model:GetPlayerCompleteList(PlayerId)
        if Data then
            self.GetPlayerAchiListCallBack(Data)
            self.GetPlayerAchiListCallBack = nil
            return
        end
    end
     
    local Msg = {
        PlayerId = PlayerId,
    }
    local RecvCmd = Pb_Message.GetAchievementInfoRsp
    if IsHideNetLoading then
        RecvCmd = nil
    end
    self:SendProto(Pb_Message.GetAchievementInfoReq, Msg, RecvCmd)
end

function AchievementCtrl:EquipSlotAchieveReq(AchvGroupId, SlotId)
    if not self.IsOpen then
        return
    end
    if self.test then
        if SlotId ~= 0 then
            self:OnSetAchievementSlotRsp( {
                AchvGroupId = AchvGroupId,
                SlotPos = SlotId,
            })
        else
            self:OnRemoveAchievementSlotRsp( {
                AchvGroupId = AchvGroupId,
                SlotPos = SlotId,
            })
        end
        return
    end

    if SlotId == 0 then
        local Msg = {
            AchvGroupId = AchvGroupId,
        }
        self:SendProto(Pb_Message.RemoveAchievementSlotReq, Msg, Pb_Message.RemoveAchievementSlotRsp)
    else
        local Msg = {
            AchvGroupId = AchvGroupId,
            SlotPos = SlotId,
        }
        self:SendProto(Pb_Message.SetAchievementSlotReq, Msg, Pb_Message.SetAchievementSlotRsp)
    end

end

function AchievementCtrl:OnSetAchievementSlotRsp(Res)
    self.Model:AddSlot(Res.SlotPos, Res.AchvGroupId) 
end

function AchievementCtrl:OnRemoveAchievementSlotRsp(Res)
    self.Model:RemoveSlotById(Res.AchvGroupId)
end

function AchievementCtrl:AchieveInfoChangedRes(AchieveId)
    local Data = self.Model:GetData(AchieveId)
    if not Data then
        return
    end

    if CommonUtil.IsInBattle() then
        --self:ShowGetInGame(Data)
        return
    end

    --local IsGetInSettle = Data:IsShowBigPop()

    if self.Model:GetLoadingType() == LoadingCtrl.TypeEnum.BATTLE_TO_HALL or MvcEntry:GetModel(ViewModel):GetState(ViewConst.HallSettlement) then --结算不弹窗
        --self:ShowGetInGame(Data)
        return
    end
    
    if Data:IsHighQuality() then
        MvcEntry:OpenView(ViewConst.AchievementGetHigh, {Id = AchieveId})
    else
        MvcEntry:OpenView(ViewConst.AchievementGetNormal, {Id = AchieveId})
    end
end

function AchievementCtrl:ShowGetInGame(InData)
    local Data = self.Model:GetItemShowInfo(InData, InData.Quality == 1 and InData.LV == 1)
    local ItemGetData = {}
    table.insert(ItemGetData, {
        Icon  = InData:GetIcon(),
        Tittle = InData:GetName(),
        Desc = InData:GetName(),
        SubDesc = InData:GetCurQualityCap(),
        SubDescHex = InData:GetCurQualityColor(),
    })
    CommonPopQueue.Show(ItemGetData, AchievementConst.PopShowWidgetUMGPath)
end

function AchievementCtrl:SettlementDataTest(IsSettle)
    if self.test then
        local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
        local GameId = IsSettle and "12700116937976351" or "0"

        local count = IsSettle and math.floor(math.random(1,10)) or 1

        local AchievementInfo = {}
        for i = 1, count do
            local TempCfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCfg, i)
            table.insert(AchievementInfo, {
                AchvId      = i,
                AchvGroupId = TempCfg[Cfg_AchievementCfg_P.MissionID],
                SubId       = TempCfg[Cfg_AchievementCfg_P.SubID],
                CurLevel    = math.floor(math.random(1,5)),
                Progress    = math.floor(math.random(0,TempCfg[Cfg_AchievementCfg_P.DisplayConditionNum])),
                FinishTime  = math.floor(math.random(1,1000000000)),
                FinishCnt   = math.floor(math.random(1,5)),
                CurProgress = 0,
            })
        end
    end
end

function AchievementCtrl:TestSettlementView()
    if self.test then
        local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
        HallSettlementModel.IsTest = true;
        local Msg = {
                GameId = "12700116937976351",
                GameplayCfg = {
                        TeamType = 4,
                        GameplayId = 10005,
                        View = 3,
                        LevelId = 1011001,
                },
                Level = 2,
                Experience = 50,
                DeltaExperience = 10,
                TeamRank = 1,
                TeamCount = 100,
                GrowthGoldMoney = 20,            
                GoldMoneyBase = 40,              
                GoldMoneyCofTotal = 80,             
                -- 任务成就映射map, key为任务id，value为成就id
                Task2AchieveIds = {
                    [10000084] = 4,
                    [10000081] = 1,
                    [10000082] = 2,
                    [10000083] = 3
                },
                -- 当前对局完成的任务,key为任务id，value为任务来源
                CompletedTasks = {
                    [10000142] = 1,
                    [10000143] = 1,
                    [10000145] = 1,
                    [10000002] = 1,
                    [10000003] = 1,
                    [10000004] = 1,
                },
                -- 结算获取的奖励物品
                RewardItems = {
                    {
                        ItemId = 900000001;
                        ItemCount = 999;
                        RewardType = 0;
                    },
                    {
                        ItemId = 130000006;
                        ItemCount = 10000;
                        RewardType = 2;
                    },
                },
                
                PlayerArray = {
                        [1] = {
                                PlayerId = --[[MvcEntry:GetModel(UserModel):GetPlayerId()--]] 123456789,
                                HeroTypeId = 200010000,
                                SkinId = 200010001,
                                PlayerName = "Myself",
                                PlayerSurvivalTime = 1234,
                                PlayerKill = 1,
                                PlayerAssist = 2,
                                RescueTimes = 3,
                                KnockDown = 5,
                                RespawnTimes = 12,
                                PlayerDamage = 1234,
                                PosInTeam = 1
                        },
                        [2] = {
                                PlayerId = 671088643,
                                HeroTypeId = 200030000,
                                SkinId = 200030001,
                                PlayerName = "Npc1",
                                PlayerSurvivalTime = 1111,
                                PlayerKill = 3,
                                RescueTimes = 4,
                                KnockDown = 5,
                                PlayerAssist = 4,
                                RespawnTimes = 22,
                                PlayerDamage = 333334,
                                PosInTeam = 2
                        },
                        [3] = {
                                PlayerId = 100663304,
                                HeroTypeId = 200030000,
                                SkinId = 200030001,
                                PlayerName = "Npc1",
                                PlayerSurvivalTime = 1111,
                                PlayerKill = 3,
                                RescueTimes = 4,
                                KnockDown = 5,
                                PlayerAssist = 4,
                                RespawnTimes = 22,
                                PlayerDamage = 333334,
                                PosInTeam = 2
                        },
                        [4] = {
                                PlayerId = 100663305,
                                HeroTypeId = 200030000,
                                SkinId = 200030001,
                                PlayerName = "Npc1",
                                PlayerSurvivalTime = 1111,
                                PlayerKill = 3,
                                RescueTimes = 4,
                                KnockDown = 5,
                                PlayerAssist = 4,
                                RespawnTimes = 22,
                                PlayerDamage = 333334,
                                PosInTeam = 2
                        },
                        [5] = {
                                PlayerId = 100663306,
                                HeroTypeId = 200030000,
                                SkinId = 200030001,
                                PlayerName = "Npc1",
                                PlayerSurvivalTime = 1111,
                                PlayerKill = 3,
                                RescueTimes = 4,
                                KnockDown = 5,
                                PlayerAssist = 4,
                                RespawnTimes = 22,
                                PlayerDamage = 333334,
                                PosInTeam = 2
                        },
                        [6] = {
                                PlayerId = 100663307,
                                HeroTypeId = 200030000,
                                SkinId = 200030001,
                                PlayerName = "Npc1",
                                PlayerSurvivalTime = 1111,
                                PlayerKill = 3,
                                RescueTimes = 4,
                                KnockDown = 5,
                                PlayerAssist = 4,
                                RespawnTimes = 22,
                                PlayerDamage = 333334,
                                PosInTeam = 2
                        },
                },
                PlayModeId = 1,                                                --玩法模式ID，用以区分是否为排位/匹配/非积分模式
                OldDivisionId = 9;                                                  --上一个段位Id
                NewDivisionId = 9;                                                --当前段位Id
                WinPoint = 30;                                                         --当前胜点
                DeltaWinPoint=-20;                                                  --变化的胜点
                DeltaRankRating = -5;                                                      --变化的排名分
                PerformanceRating= -15;                                               --当前的表现分 
                GradeName="B";                                              --评价等级
                OwnerId = 0
        };
        local MatchConst = require("Client.Modules.Match.MatchConst");
        HallSettlementModel:SetSettlementData(MatchConst.Enum_MatchType.Survive, Msg, true);
        local HallSettlementCtrl = MvcEntry:GetCtrl(HallSettlementCtrl);
        local beforeCameraId = MvcEntry:GetModel(HallModel).CurCameraIndex;
        local Callback = function()
                local HallCameraMgr = CommonUtil.GetHallCameraMgr();
                HallCameraMgr:SwitchCamera(beforeCameraId, 0, "", "");
        end;
        HallSettlementCtrl:TryingToShowHallSettlement(Callback);
    end
end