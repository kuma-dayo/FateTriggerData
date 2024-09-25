---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 自建房内的信息
--- Created At: 2023/06/13 14:29
--- Created By: 朝文
---

local super = ListModel
local class_name = "CustomRoomDetailModel"
---@class CustomRoomDetailModel : ListModel
CustomRoomDetailModel = BaseClass(super, class_name)

CustomRoomDetailModel.CUSTOM_ROOM_ON_ROOM_MASTER_INFO_SYNC  = "CUSTOM_ROOM_ON_ROOM_MASTER_INFO_SYNC"         --房间队长信息同步
CustomRoomDetailModel.CUSTOM_ROOM_ON_ROOM_HERO_LIST_RSP     = "CUSTOM_ROOM_ON_ROOM_HERO_LIST_RSP"            --房间英雄列表更新
CustomRoomDetailModel.CUSTOM_ROOM_ON_SELECT_HERO_RSP        = "CUSTOM_ROOM_ON_SELECT_HERO_RSP"               --更换英雄
CustomRoomDetailModel.CUSTOM_ROOM_ON_SELECT_TEAM_RSP        = "CUSTOM_ROOM_ON_SELECT_TEAM_RSP"               --更换队伍

--Team
CustomRoomDetailModel.CUSTOM_ROOM_ON_TEAM_LIST_RSP  = "CUSTOM_ROOM_ON_TEAM_LIST_RSP"                        --获取房间队伍列表全量更新
CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_ADDED   = "CUSTOM_ROOM_ON_PLAYER_ADDED"                         --房间玩家发生变化-增加
CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_UPDATED = "CUSTOM_ROOM_ON_PLAYER_UPDATED"                       --房间玩家发生变化-更新
CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_REMOVED = "CUSTOM_ROOM_ON_PLAYER_REMOVED"                       --房间玩家发生变化-减少
CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_CHANGED = "CUSTOM_ROOM_ON_PLAYER_CHANGED"                       --房间玩家发生变化-增加|更新|减少

--PlayerInfo
CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_RSP     = "CUSTOM_ROOM_ON_PLAYER_INFO_RSP"                 --房间内的玩家信息全部更新下来，第一次进入自建房房内时触发
CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_ADDED   = "CUSTOM_ROOM_ON_PLAYER_INFO_ADD"                 --房间内的玩家信息发生变化-增加
CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_UPDATE  = "CUSTOM_ROOM_ON_PLAYER_INFO_UPDATE"              --房间内的玩家信息发生变化-更新
CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_REMOVE  = "CUSTOM_ROOM_ON_PLAYER_INFO_REMOVE"              --房间内的玩家信息发生变化-减少
CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_CHANGED = "CUSTOM_ROOM_ON_PLAYER_INFO_CHANGED"             --房间内的玩家信息发生变化-增加|更新|减少

--region CustomRoomInfo

--[[
    lua.do local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel);
    CustomRoomDetailModel:Debug_CustomRoomInfo()
--]]
function CustomRoomDetailModel:Debug_CustomRoomInfo()
    CLog("[cw] =============== Debug_CustomRoomInfo ===============")
    print_r(debug.traceback())
    print_r(self.CustomRoomInfo, "[cw] self.CustomRoomInfo")
end

--[[    
    newCustomRoomInfo = {
        Player = { 
            Name = "沦落", 
            TeamId = 1, 
            HeroId = 200010000, 
        },
        
        ErrorCode = 0, 
        
        Info = {
            State = 1, 
            RoomId = 1,            
            GameplayId = 123,
            LevelId = 123,
            ModeKey = "101_solo_fpp"
        },
        
        MasterInfo = {
            Name = "沦落", 
            PlayerId = 13237223431, 
        },
        
        Team = {
            [1] = {
                PlayerArray = { 
                    [1] = {
                        PlayerId = 13237223431, 
                        HeroId = 200010000, 
                        Name = "沦落", 
                        LobbyAddr = "172.17.0.3", 
                        TeamId = 1, 
                        TeamPosition = 1, 
                        bAIPlayer = false, 
                    },
                }
            }
        },
    }
--]]
---封装一个设置 CustomRoomInfo 的方法, 用于设置 当前房间信息，只有在下发自建房数据的时候走这里
---@param newCustomRoomInfo table
function CustomRoomDetailModel:SetRoomInfo(newCustomRoomInfo)
    CLog("[cw][CustomRoomDetailModel] SetCustomRoomInfo(" .. string.format("%s", newCustomRoomInfo) .. ")")
    if not newCustomRoomInfo then
         CError("[cw][CustomRoomDetailModel] trying to set a nil value to CustomRoomInfo, if you wanna do it, please use CleanCustomRoomInfo() instead")
    end
    
    self.CustomRoomInfo = newCustomRoomInfo
    local fixRes = self:_FixTeamInfoAndPlayerInfo()
    --如果 fixRes 是 "Async" 的话，就说明是异步，需要等待房间信息
    --self:Debug_CustomRoomInfo()
end

---封装一个获取 CustomRoomInfo 的方法，用于获取 当前房间信息
---@return table
function CustomRoomDetailModel:GetRoomInfo()
    return self.CustomRoomInfo
end

---封装一个清空 CustomRoomInfo 的方法，用于去除 当前房间信息
function CustomRoomDetailModel:CleanInfo()
    self.CustomRoomInfo = nil
    --self:Debug_CustomRoomInfo()
end

--region 房间信息 Info

---封装一个获取 CustomRoomInfo 的方法，用于获取 当前房间信息ID
---@return number
function CustomRoomDetailModel:GetRoomInfo_RoomId()
    --self:Debug_CustomRoomInfo()
    if not self.CustomRoomInfo or not self.CustomRoomInfo.Info then return 0 end
    return self.CustomRoomInfo.Info.RoomId
end

---封装一个获取 CustomRoomInfo 的方法，用于获取 当前房间PlayModeId
---@return number
function CustomRoomDetailModel:GetRoomInfo_PlayModeId()
    --self:Debug_CustomRoomInfo()
    return self.CustomRoomInfo.Info.GameplayId
end

---封装一个获取 CustomRoomInfo 的方法，用于获取 当前房间LevelId
---@return number
function CustomRoomDetailModel:GetRoomInfo_LevelId()
    --self:Debug_CustomRoomInfo()
    return self.CustomRoomInfo.Info.LevelId
end
---封装一个获取 CustomRoomInfo 的方法，用于获取 当前房间ModeKey
---@return number
function CustomRoomDetailModel:GetRoomInfo_ModeKey()
    --self:Debug_CustomRoomInfo()
    return self.CustomRoomInfo.Info.ModeKey
end

--endregion 房间信息 Info

--region 房主 MasterInfo
--[[
    newCustomRoomMasterInfo = {
        Name = bailixi,
        PlayerId = 10569646082,
    }
--]]
---封装一个设置 CustomRoomMasterInfo 的方法, 用于设置 房主信息
---@param newCustomRoomMasterInfo table<masterName:string, masterId: number>
function CustomRoomDetailModel:UpdateMasterInfo(newCustomRoomMasterInfo)
    if not newCustomRoomMasterInfo then
        CError("[cw][CustomRoomDetailModel] trying to set a nil value to CustomRoomMasterInfo, if you wanna do it, please use CleanCustomRoomMasterInfo() instead")
    end
    if not self.CustomRoomInfo then self.CustomRoomInfo = {} end

    --这里看一下是否和缓存一致，如果一致没有必要通知刷新
    local diff = false
    if self.CustomRoomInfo.MasterInfo then
        if self.CustomRoomInfo.MasterInfo.PlayerId ~= newCustomRoomMasterInfo.PlayerId then diff = true end
        if self.CustomRoomInfo.MasterInfo.Name ~= newCustomRoomMasterInfo.Name then diff = true end
    end
    if not diff then return end
    
    --走到这里说明信息不一致，需要更新并抛出事件更新
    self.CustomRoomInfo.MasterInfo = newCustomRoomMasterInfo
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_ROOM_MASTER_INFO_SYNC)
    --self:Debug_CustomRoomInfo()
end

---封装一个获取 CustomRoomMasterInfo 的方法，用于获取 房主信息
---@return string 房主昵称
function CustomRoomDetailModel:GetMasterInfo_MasterName()
    if self.CustomRoomInfo.MasterInfo then
        return self.CustomRoomInfo.MasterInfo.Name
    else
        return ""
    end
end

---封装一个获取 CustomRoomMasterInfo 的方法，用于获取 房主信息
---@return number 房主ID
function CustomRoomDetailModel:GetMasterInfo_MasterID()
    if self.CustomRoomInfo.MasterInfo then
        return self.CustomRoomInfo.MasterInfo.PlayerId
    else
        return 0
    end
end
--endregion 房主

--region 玩家信息 Player
--Player = { 
--    Name = "沦落", 
--    TeamId = 1, 
--    HeroId = 200010000, 
--},

function CustomRoomDetailModel:GetCustomRoomInfo_PlayerTeamIndex()
    return self.CustomRoomInfo.Player.TeamId
end

function CustomRoomDetailModel:SetCustomRoomInfo_PlayerTeamId(newTeamId)
    CLog("[cw][CustomRoomDetailModel] SetCUstomRoomInfo_PlayerTeamId(" .. string.format("%s", newTeamId) .. ")")
    self.CustomRoomInfo.Player.TeamId = newTeamId

    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_SELECT_TEAM_RSP)
end

function CustomRoomDetailModel:SetCustomRoomInfo_PlayerHeroId(newHeroId)
    CLog("[cw][CustomRoomDetailModel] SetCustomRoomInfo_PlayerHeroId(" .. string.format("%s", newHeroId) .. ")")
    self.CustomRoomInfo.Player.HeroId = newHeroId
    
    local PlayerTeamPlayerInfoRef = self:GetCustomRoomInfo_PlayerTeamPlayerInfoRef()
    PlayerTeamPlayerInfoRef.HeroId = newHeroId
    
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_SELECT_HERO_RSP)
end

function CustomRoomDetailModel:GetCustomRoomInfo_PlayerHeroId()
    return self.CustomRoomInfo.Player.HeroId
end

--endregion 玩家信息 Player

--function CustomRoomDetailModel:TriggerAllDelayFunc()
--    if self._delayCall then
--        for k, v in pairs(self._delayCall) do v(self) end
--    end
--end

--region 队伍信息 Team

function CustomRoomDetailModel:_FixTeamInfoAndPlayerInfo()
    self.PlayerInfo = {}
    self._PlayerInfoCount = 0
    
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local ModeKey = CustomRoomDetailModel:GetRoomInfo_ModeKey()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local maxTeamPlayerNum = MatchModeSelectModel:GetModeEntryCfg_MaxTeamPlayer(ModeKey)
    local maxTeamNum = MatchModeSelectModel:GetModeEntryCfg_MaxTeam(ModeKey)
    
    for TeamIndex = 1, maxTeamNum do
        if not self.CustomRoomInfo.Team[TeamIndex] then self.CustomRoomInfo.Team[TeamIndex] = {} end
        if not self.CustomRoomInfo.Team[TeamIndex].PlayerArray then self.CustomRoomInfo.Team[TeamIndex].PlayerArray = {} end
        local Teammates = self.CustomRoomInfo.Team[TeamIndex].PlayerArray
        for PosIndex = 1, maxTeamPlayerNum do
            local _PlayerInfo = Teammates[PosIndex]
            if not _PlayerInfo then
                Teammates[PosIndex] = {
                    TeamId = TeamIndex,
                    TeamPosition = PosIndex
                }
            else
                if _PlayerInfo.PlayerId then
                    self.PlayerInfo[_PlayerInfo.PlayerId] = {
                        HeroId      = _PlayerInfo.HeroId,
                        Name        = _PlayerInfo.Name,
                        PlayerId    = _PlayerInfo.PlayerId,
                        TeamId      = _PlayerInfo.TeamId,
                        TeamPosition = _PlayerInfo.TeamPosition,
                    }
                    self._PlayerInfoCount = self._PlayerInfoCount + 1
                end
            end
        end
    end
end

--[[
newTeamInfo = { 
    [1] = { 
        PlayerArray = {
            [1] = { 
                TeamPosition = 1, 
                Name = "bailixi", 
                PlayerId = 1325400068, 
                LobbyAddr = "lobby-0", 
                TeamId = 1, 
                bAIPlayer = false, 
                HeroId = 200010000, 
            },
            [2] = {}
            }
        }
    },
    [2] = {
        PlayerArray = {}
    } 
}
--]]
function CustomRoomDetailModel:UpdateCustomRoomInfo_Team(newTeamInfo)
    self.CustomRoomInfo.Team = newTeamInfo
    self:_FixTeamInfoAndPlayerInfo()
    
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_TEAM_LIST_RSP)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_CHANGED)
end

function CustomRoomDetailModel:GetCustomRoomInfo_Team()
    return self.CustomRoomInfo.Team
end

function CustomRoomDetailModel:GetCustomRoomInfo_TeamByIndex(TeamIndex)
    if not TeamIndex then 
        CError("[cw] TeamIndex is nil") 
        CError(debug.traceback()) 
        return nil 
    end
    
    if TeamIndex > #self.CustomRoomInfo.Team then
        CError("[cw] TeamIndex(" .. tostring(TeamIndex) .. ") is greater than TeamLen(" .. tostring(#self.CustomRoomInfo.Team) .. ")")
        return nil 
    end
    
    return self.CustomRoomInfo.Team[TeamIndex].PlayerArray
end

--[[
    InOpInfo = { 
        OpType = 1,
        TeamId = 1,
        PlayerId = 4278190083,
        Name = "bailixi2",
        MasterInfo = {
            Name = "bailixi",
            PlayerId = 1325400068
        },
        HeroId = 200020000,
        TeamPosition = 2,
    } 
--]]
function CustomRoomDetailModel:Team_AddNewPlayer(PlayerInfo)
    --print_r(PlayerInfo, "[cw]Team_AddNewPlayer PlayerInfo====")
    local TeamId = PlayerInfo.TeamId
    local TeamPosition = PlayerInfo.TeamPosition
    local PlayerId = PlayerInfo.PlayerId
    local Name = PlayerInfo.Name
    local HeroId = PlayerInfo.HeroId
    
    self.CustomRoomInfo.Team[TeamId].PlayerArray[TeamPosition] = {
        TeamPosition = TeamPosition,
        Name = Name,
        PlayerId = PlayerId,
        LobbyAddr = nil,
        TeamId = TeamId,
        bAIPlayer = false,
        HeroId = HeroId,
    }
    
    self:AddPlayerInfo(PlayerInfo)
    -- self:UpdateMasterInfo(PlayerInfo.MasterInfo)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_ADDED)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_CHANGED)
end

--[[
    PlayerInfo = {
        HeroId = 200020000,
        Name = "bailixi2",
        PlayerId = 4278190083,
        TeamId = 2,
        TeamPosition = 1,
        OpType = 3,
        MasterInfo = {,
            PlayerId = 1325400068,
            Name = "bailixi",
        }
    }
--]]
function CustomRoomDetailModel:Team_UpdatePlayer(PlayerInfo)
    --print_r(PlayerInfo, "[cw] ====Team_UpdatePlayer PlayerInfo")
    --老数据
    local OldTeamId         = self.PlayerInfo[PlayerInfo.PlayerId].TeamId
    local OldTeamPosition   = self.PlayerInfo[PlayerInfo.PlayerId].TeamPosition
    local OldPlayerId       = self.PlayerInfo[PlayerInfo.PlayerId].PlayerId
    local OldName           = self.PlayerInfo[PlayerInfo.PlayerId].Name
    local OldHeroId         = self.PlayerInfo[PlayerInfo.PlayerId].HeroId
    --新数据
    local TeamId            = PlayerInfo.TeamId
    local TeamPosition      = PlayerInfo.TeamPosition
    local PlayerId          = PlayerInfo.PlayerId
    local Name              = PlayerInfo.Name
    local HeroId            = PlayerInfo.HeroId

    self.CustomRoomInfo.Team[OldTeamId].PlayerArray[OldTeamPosition] = { TeamId = OldTeamId, TeamPosition = OldTeamPosition}
    self.CustomRoomInfo.Team[TeamId].PlayerArray[TeamPosition] = {
        TeamPosition = TeamPosition,
        Name = Name,
        PlayerId = PlayerId,
        LobbyAddr = nil,
        TeamId = TeamId,
        bAIPlayer = false,
        HeroId = HeroId,
    }

    self:UpdatePlayerInfo(PlayerInfo)
    -- self:UpdateMasterInfo(PlayerInfo.MasterInfo)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_UPDATED)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_CHANGED)
end

--[[
    PlayerInfo = { 
        OpType = 2, 
        TeamPosition = 1, 
        Name = "bailixi", 
        MasterInfo =  {, 
            PlayerId = 4278190083, 
            Name = "bailixi2", 
        } 
        HeroId = 200010000, 
        PlayerId = 1325400068, 
        TeamId = 1, 
        }
--]]
function CustomRoomDetailModel:Team_RemovePlayer(PlayerInfo)    
    --print_r(PlayerInfo, "[cw] ====Team_RemovePlayer PlayerInfo")

    --老数据
    local OldTeamId         = self.PlayerInfo[PlayerInfo.PlayerId].TeamId
    local OldTeamPosition   = self.PlayerInfo[PlayerInfo.PlayerId].TeamPosition
    local OldPlayerId       = self.PlayerInfo[PlayerInfo.PlayerId].PlayerId
    local OldName           = self.PlayerInfo[PlayerInfo.PlayerId].Name
    local OldHeroId         = self.PlayerInfo[PlayerInfo.PlayerId].HeroId

    self.CustomRoomInfo.Team[OldTeamId].PlayerArray[OldTeamPosition] = { TeamId = OldTeamId, TeamPosition = OldTeamPosition}

    self:RemovePlayerInfo(PlayerInfo)
    -- self:UpdateMasterInfo(PlayerInfo.MasterInfo)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_REMOVED)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_CHANGED)
end

function CustomRoomDetailModel:GetCustomRoomInfo_PlayerTeam()
    local TeamId = self:GetCustomRoomInfo_PlayerTeamIndex()
    local Teammates = self:GetCustomRoomInfo_TeamByIndex(TeamId) 
    return Teammates
end

function CustomRoomDetailModel:GetCustomRoomInfo_PlayerTeamPlayerInfoRef()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = UserModel:GetPlayerId()
    local Team = self:GetCustomRoomInfo_PlayerTeam()
    for i, v in ipairs(Team) do
        if v.PlayerId == PlayerId then
            return v
        end
    end
    
    return nil
end

function CustomRoomDetailModel:GetHeroSelectByTeammate(TestHero)
    local Team = self:GetCustomRoomInfo_PlayerTeam()
    for k, v in ipairs(Team) do
        if v.HeroId == TestHero then
            return v
        end
    end
    
    return nil
end

--endregion 队伍信息 Team

--endregion CustomRoomInfo

--region PlayerInfo

--[[
    newPlayersInfo = {
        [1] = { 
            HeroId = 200010000,
            Name = "bailixi",
            PlayerId = 1325400068,
            TeamId = 1,
            TeamPosition = 1,
        },
        [2] = {
            HeroId = 200020000,
            Name = "bailixi2",
            PlayerId = 4278190083,
            TeamId = 2,
            TeamPosition = 1,
        }
    }
--]]
---@param newPlayersInfo table 服务器同步的玩家信息
function CustomRoomDetailModel:UpdateCustomRoomInfo_PlayersInfo(newPlayersInfo)
    self.PlayerInfo = {}
    self._PlayerInfoCount = 0
    for _, PlayerInfo in pairs(newPlayersInfo) do
        self.PlayerInfo[PlayerInfo.PlayerId] = {
            HeroId      = PlayerInfo.HeroId,
            Name        = PlayerInfo.Name,
            PlayerId    = PlayerInfo.PlayerId,
            TeamId      = PlayerInfo.TeamId,
            TeamPosition = PlayerInfo.TeamPosition,
        }
        self._PlayerInfoCount = self._PlayerInfoCount + 1
    end
    
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_RSP)
end

--[[
    InOpInfo = { 
        OpType = 1,
        TeamId = 1,
        PlayerId = 4278190083,
        Name = "bailixi2",
        MasterInfo = {
            Name = "bailixi",
            PlayerId = 1325400068
        },
        HeroId = 200020000,
        TeamPosition = 2,
    } 
--]]
function CustomRoomDetailModel:AddPlayerInfo(PlayerInfo)
    --print_r(PlayerInfo, "[cw] ====AddPlayerInfo PlayerInfo")
    self.PlayerInfo[PlayerInfo.PlayerId] = {
        HeroId      = PlayerInfo.HeroId,
        Name        = PlayerInfo.Name,
        PlayerId    = PlayerInfo.PlayerId,
        TeamId      = PlayerInfo.TeamId,
        TeamPosition = PlayerInfo.TeamPosition,
    }    
    self._PlayerInfoCount = self._PlayerInfoCount + 1
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_ADDED)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_CHANGED)
end

function CustomRoomDetailModel:UpdatePlayerInfo(PlayerInfo)   
    --print_r(PlayerInfo, "[cw] ====UpdatePlayerInfo PlayerInfo")
    --这里检查是否一致，一致则不更新
    local continue, same = true, true
    local function _check(key)
        if not continue then return end
        if self.PlayerInfo[key] ~= PlayerInfo[key] then
            continue = false
            same = false
        end
    end
    
    _check("HeroId")
    _check("Name")
    _check("PlayerId")
    _check("TeamId")
    _check("TeamPosition")
    if same then return end
    
    self.PlayerInfo[PlayerInfo.PlayerId] = {
        HeroId      = PlayerInfo.HeroId,
        Name        = PlayerInfo.Name,
        PlayerId    = PlayerInfo.PlayerId,
        TeamId      = PlayerInfo.TeamId,
        TeamPosition = PlayerInfo.TeamPosition,
    }
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_UPDATE)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_CHANGED)
end

function CustomRoomDetailModel:RemovePlayerInfo(PlayerInfo)
    --print_r(PlayerInfo, "[cw] ====RemovePlayerInfo PlayerInfo")
    self.PlayerInfo[PlayerInfo.PlayerId] = nil
    self._PlayerInfoCount = self._PlayerInfoCount - 1
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_REMOVE)
    self:DispatchType(CustomRoomDetailModel.CUSTOM_ROOM_ON_PLAYER_INFO_CHANGED)
end

---@return number 获取当前房间内的玩家数量
function CustomRoomDetailModel:GetCurPlayerCount()
    return self._PlayerInfoCount
end

--endregion PlayerInfo


--region CustomRoomHeroList

---封装一个设置 CustomRoomHeroList 的方法, 用于设置 自建房可选英雄列表
---@param newCustomRoomHeroList table
function CustomRoomDetailModel:SetCustomRoomHeroList(newCustomRoomHeroList)
    if not newCustomRoomHeroList then
         CError("[cw] CustomRoomDetailModel trying to set a nil value to CustomRoomHeroList, if you wanna do it, please use CleanCustomRoomHeroList() instead")
    end
    self.CustomRoomHeroList = newCustomRoomHeroList
end

---封装一个获取 CustomRoomHeroList 的方法，用于获取 自建房可选英雄列表
---@return table
function CustomRoomDetailModel:GetCustomRoomHeroList()
    return self.CustomRoomHeroList
end

---封装一个清空 CustomRoomHeroList 的方法，用于去除 自建房可选英雄列表
function CustomRoomDetailModel:CleanCustomRoomHeroList()
    self.CustomRoomHeroList = nil
end

--endregion CustomRoomHeroList

function CustomRoomDetailModel:__init()
    self:DataInit()
end

---初始化数据，用于第一次调用及登出的时候调用
function CustomRoomDetailModel:DataInit()
    self.CustomRoomInfo = {
        --[[
        Player = {
            Name = "沦落",
            TeamId = 1,
            HeroId = 200010000,
        },

        ErrorCode = 0,

        Info = {
            State = 1,
            RoomId = 1,
        },

        MasterInfo = {
            Name = "沦落",
            PlayerId = 13237223431,
        },
        Team = {
            [1] = {
                [1] = {
                    PlayerId = 13237223431,
                    HeroId = 200010000,
                    Name = "沦落",
                    LobbyAddr = "172.17.0.3",
                    TeamId = 1,
                    TeamPosition = 1,
                    bAIPlayer = false,
                }
            },
        },
        --]]
    }    
    
    self.PlayerInfo = {
        --[[
        [13237223431] = {
            HeroId      = 200010000,
            Name        = "沦落",
            PlayerId    = 13237223431,
            TeamId      = 1,
            TeamPosition = 1,
        } 
        --]]
    }
    self._PlayerInfoCount = 0
    
    --自建房可选英雄列表, 赋值参考 
    ---@see CustomRoomDetailCtrl#OnHeroListRsp
    self.CustomRoomHeroList = {}
end

---玩家登出时调用
function CustomRoomDetailModel:OnLogout(data)
    self:DataInit()
end

return CustomRoomDetailModel