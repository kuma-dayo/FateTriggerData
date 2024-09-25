---
--- Ctrl 模块，主要用于处理协议
--- Description: 玩家信息，历史战绩相关协议处理
--- Created At: 2023/08/04 17:47
--- Created By: 朝文
---

require("Client.Modules.PlayerInfo.MatchHistory.PlayerInfo_MatchHistoryModel")

local class_name = "PlayerInfo_MatchHistoryCtrl"
---@class PlayerInfo_MatchHistoryCtrl : UserGameController
---@field private model PlayerInfo_MatchHistoryModel
PlayerInfo_MatchHistoryCtrl = PlayerInfo_MatchHistoryCtrl or BaseClass(UserGameController, class_name)
PlayerInfo_MatchHistoryCtrl.Const = {
    MaxMatchHistoryRecordsRspLen = 20,  --一次最多可以拉取20条数据，如果少于20条则说明拉到头了
}

function PlayerInfo_MatchHistoryCtrl:__init()
    CWaring("[cw] PlayerInfo_MatchHistoryCtrl init")
    self.Model = nil
end

function PlayerInfo_MatchHistoryCtrl:Initialize()
    ---@type PlayerInfo_MatchHistoryModel
    self.Model = self:GetModel(PlayerInfo_MatchHistoryModel)
end

function PlayerInfo_MatchHistoryCtrl:AddMsgListenersUser()
    --添加协议回包监听事件
    self.ProtoList = {
        {MsgName = Pb_Message.RecordsRsp, Func = self.OnRecordsRsp},
        {MsgName = Pb_Message.DetailRecordRsp, Func = self.OnDetailRecordRsp},
    }
    self.MsgList = {
        { Model = ViewModel, MsgName = ViewConst.PlayerInfo,    Func = self.OnPlayerInfoState },
        { Model = ViewModel, MsgName = ViewModel.ON_REPEAT_SHOW .. ViewConst.PlayerInfo,    Func = self.OnPlayerInfoState },
    }
end

---进入战斗后数据会变化，依赖服务器存储的逻辑，客户端请求时需要从0开始重新请求。
---所以这里需要清空本地数据。
function PlayerInfo_MatchHistoryCtrl:OnPreEnterBattle()
    CLog("[cw][debug] PlayerInfo_MatchHistoryCtrl:OnPreEnterBattle()")
    self.Model:CleanIsGotAllMatchHistory()
    self.Model:Clean()
end

-- 打开&重复打开&关闭个人信息界面的时候 清空缓存的数据
function PlayerInfo_MatchHistoryCtrl:OnPlayerInfoState(State)
    -- 界面初始化的时候  先把数据清空一下
    self.Model:CleanIsGotAllMatchHistory()
    self.Model:Clean()
end


-----------------------------------------请求相关------------------------------

--- 获取历史战绩 ---
--region
---发送协议获取历史战绩
---@param RecordId number
---@param SeasonId number 赛季ID
---@param PlayerId number 查看玩家的ID
function PlayerInfo_MatchHistoryCtrl:SendRecordsReq(RecordId, SeasonId, PlayerId)
    PlayerId = PlayerId or MvcEntry:GetModel(UserModel):GetPlayerId()
    CLog("[cw] PlayerInfoCtrl:SendRecordsReq(" .. string.format("%s, %s, %s", tostring(RecordId), tostring(SeasonId), tostring(PlayerId)) .. ")")
    local Data = {
        RecordIdx = RecordId,
        SeasonId = SeasonId,
        PlayerId = PlayerId,
    }
    self:SendProto(Pb_Message.RecordsReq, Data, Pb_Message.RecordsRsp)
end

--[[
    Msg = {
        SeasonId = 1
        bIsEnd = false
        Records =  {
            [1] = {
                GameId = "12700116913955911"
                GeneralData = {
                    Rank = 1
                    GameplayCfg = {
                        GameplayId = 10001
                        LevelId = 101101
                        TeamType = "solo"
                        View = "fpp"
                    }
                    HeroId = 200020000
                    SkinId = 0
                    SurvialTime = 143.57386779785
                }
            }
        }
    }
--]]
---获取历史战绩协议回包
---@param Msg table
function PlayerInfo_MatchHistoryCtrl:OnRecordsRsp(Msg)
    CLog("[cw] PlayerInfoCtrl:OnRecordsRsp(" .. string.format("%s", Msg) .. ")")
    print_r(Msg, "[cw] OnRecordsRsp ====Msg")
    
    --如果拉之前就已经拉完了，则说明这次拉取是为了确定是否有新的历史记录
    if self.Model:GetIsGotAllMatchHistory() then
        --新增数据没有数据
        if not next(Msg.Records) then
            self.Model:SetIsGotAllMatchHistory(true)

        --新增数据小于20条
        elseif #Msg.Records < PlayerInfo_MatchHistoryCtrl.Const.MaxMatchHistoryRecordsRspLen then
            self.Model:SetIsGotAllMatchHistory(true)            
            local appendList = {}
            for i = #Msg.Records, 1, -1 do
                if self.Model:GetData(Msg.Records[i].GameId) then
                    break
                else
                    table.insert(appendList, Msg.Records[i])
                end
            end
            print_r(appendList, "[cw] ====appendList")
            self.Model:AppendListBegin(appendList)
            
        --走到这里说明新增数据大于20条，怎么说呢，重新拉取吧
        else
            self.Model:Clean()
            self.Model:SetIsGotAllMatchHistory(false)
            self.Model:AppendList(Msg.Records)
        end
        return
    end

    --如果之前还没有拉完，则需要判定一下是否有重复的数据，如果有重复的数据则需要重新拉    
    --如果没有数据，或者当前数据少于20条，则说明这里的数据已经拉完了
    if not next(Msg.Records) or #Msg.Records < PlayerInfo_MatchHistoryCtrl.Const.MaxMatchHistoryRecordsRspLen then
        self.Model:SetIsGotAllMatchHistory(true)
    end
    
    self.Model:AppendList(Msg.Records)
end
--endregion

--- 获取历史战绩详情 ---
--region
---获取历史战绩详情数据
---@param GameId number 游戏Id
---@param SeasonId number 赛季Id
---@param PlayerId number 查看玩家的ID
function PlayerInfo_MatchHistoryCtrl:SendDetailRecordReq(GameId, SeasonId, PlayerId)
    PlayerId = PlayerId or MvcEntry:GetModel(UserModel):GetPlayerId()
    local Data = {
        SeasonId = tonumber(SeasonId),
        GameId   = GameId,
        PlayerId = PlayerId,
    }
    self:SendProto(Pb_Message.DetailRecordReq, Data, Pb_Message.DetailRecordRsp)
end


--[[
    Msg = { 
        DetailRecord = {
            --这里只会存在一种数据类型
            --【optional】大逃杀模式
            [1] = {
                BrSettlement = {
                    RemainingPlayers = 1 
                    RemainingTeams = 1 
                    GameId = "127001169174013985" 
                    TeamId = 1 
                    PlayerArray = { 
                        2835349508 = { 
                            RemainingPlayers = 1 
                            RemainingTeams = 1 
                            bRespawnable = false 
                            SkinId = 0 
                            bIsTeamOver = true 
                            PosInTeam = 1 
                            PlayerSurvivalTime = 143.57386779785 
                            HeroTypeId = 200020000 
                            RescueTimes = 0 
                        } 
                        2835349505 = {
                            ...
                        }
                    }
                }
            }
            --【optional】团竞、死斗、征服模式类型
            [1] = {
                CampSettlement = {
                    TeamRank = 1,
                    GameId = "127001169174013985"
                    PlayerArray = { 
                        2835349508 = { 
                            RemainingPlayers = 1 
                            RemainingTeams = 1 
                            bRespawnable = false 
                            SkinId = 0 
                            bIsTeamOver = true 
                            PosInTeam = 1 
                            PlayerSurvivalTime = 143.57386779785 
                            HeroTypeId = 200020000 
                            RescueTimes = 0 
                        } 
                        2835349505 = {
                            ...
                        }
                    }
                }
            }
        }
    }
--]]
---历史战绩详情数据回包
function PlayerInfo_MatchHistoryCtrl:OnDetailRecordRsp(Msg)
    CLog("[cw] PlayerInfo_MatchHistoryCtrl:OnDetailRecordInfoRsp(" .. string.format("%s", Msg) .. ")")
    print_r(Msg, "[cw] ====Msg")
    
    self.Model:AddDetailRecord(Msg.DetailRecord)

    if self.OpenHistoryViewCallBack then
        self.OpenHistoryViewCallBack()
        self.OpenHistoryViewCallBack = nil
    end
end
--endregion


function PlayerInfo_MatchHistoryCtrl:OpenHistoryView(GameId, SeasonId, PlayerId)
    SeasonId = SeasonId or MvcEntry:GetModel(SeasonModel):GetCurrentSeasonId()
    PlayerId = PlayerId or MvcEntry:GetModel(UserModel):GetPlayerId()
    --如果已经存在历史记录了，则不需要请求，直接打开就好
    ---@type PlayerInfo_MatchHistoryModel
    local PlayerInfo_MatchHistoryModel = MvcEntry:GetModel(PlayerInfo_MatchHistoryModel)
    if PlayerInfo_MatchHistoryModel:IsGotDetailRecordById(GameId) then
        MvcEntry:OpenView(ViewConst.MatchHistoryDetail, {GameId = GameId})
        return
    end

    --如果不存在，则需要请求并记录一下
    self:SendDetailRecordReq(GameId, SeasonId, PlayerId)
    self.OpenHistoryViewCallBack = function()
        self:OpenHistoryView(GameId, SeasonId, PlayerId)
    end
end