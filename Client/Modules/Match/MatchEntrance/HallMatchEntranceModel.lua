---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 大厅匹配入口动画计算
--- Created At: 2023/06/29 10:28
--- Created By: 朝文
---

local super = GameEventDispatcher
local class_name = "HallMatchEntranceModel"
---@class HallMatchEntranceModel : GameEventDispatcher
HallMatchEntranceModel = BaseClass(super, class_name)

--匹配入口匹配成功动画播放完成
HallMatchEntranceModel.ON_MATCH_SUCCESS_ANIMATION_FINISHED     = "ON_MATCH_SUCCESS_ANIMATION_FINISHED"

function HallMatchEntranceModel:__init()
    self:DataInit()
end

---因为蓝图动画需要，在播放动画前先更新一下蓝图中的参数，方便动效同学根据参数进行调整。
---@param isCaptain boolean 是否是队长
---@param isReady boolean 是否已准备
---@param isMatching boolean 是否在匹配中
---@param isMatchingSuccess boolean 是否匹配成功了
function HallMatchEntranceModel:UpdateNextAnimData(isReady, isCaptain, isMatching, isMatchingSuccess)
    CLog("[cw][HallMatchEntranceModel]:UpdateNextAnimData(" .. string.format("%s, %s, %s, %s", isReady, isCaptain, isMatching, isMatchingSuccess) .. ")")

    --是否已准备
    if isReady ~= nil then
        self._NextStateDate.TeamInfo.isReady = isReady
    end
    
    --是否是队长
    if isCaptain ~= nil then
        self._NextStateDate.TeamInfo.isCaptain = isCaptain
    end

    --匹配中
    if isMatching ~= nil then
        self._NextStateDate.MatchInfo.isMatching = isMatching
    end

    if isMatchingSuccess ~= nil then
        self._NextStateDate.MatchInfo.isMatchingSuccess = isMatchingSuccess
    end
end

---初始化数据，用于第一次调用及登出的时候调用
function HallMatchEntranceModel:DataInit()
    --上一次动画使用的数据
    self._LastStateData = {
        TeamInfo = {                --队伍信息
            isCaptain = nil,            --是否是队长
            isReady = nil,              --是否已准备
        },
        MatchInfo = {               --匹配信息
            isMatching = nil,           --是否正在匹配中
            isMatchingSuccess = nil,    --匹配是否成功了
        }
    }

    --下一次动画使用的数据
    self._NextStateDate = {
        TeamInfo = {                --队伍信息，没有队伍则为nil
            isCaptain = nil,           --是否是队长
            isReady = nil,             --是否已准备
        },
        MatchInfo = {               --匹配信息
            isMatching = nil,           --是否正在匹配中
            isMatchingSuccess = nil,    --匹配是否成功了
        }
    }
end

---玩家登出时调用
function HallMatchEntranceModel:OnLogout(data)
    self:DataInit()
end

--队长队员切换
local Anim_ToTeammate           = "VXE_Hall_Transfer_ToTeammate"
local Anim_ToCaptain            = "VXE_Hall_Transfer_ToCaptain"
-- -- 单人成为队长
-- local Anim_SoloToCaptain        = "VXE_Hall_Transfer_Solo2Captain"
-- -- 队长变成单人
-- local Anim_CaptainToSolo        = "VXE_Hall_Transfer_Captain2Solo"
-- -- 队长变成队员
-- local Anim_CaptainToTeammate    = "VXE_Hall_Transfer_Captain2Teammate"
-- -- 队员变成队长
-- local Anim_TeammateToCaptain    = "VXE_Hall_Transfer_Teammate2Captain"

--准备未准备切换
local Anim_ToReady              = "VXE_Hall_Unready_Click"
local Anim_ToUnready            = "VXE_Hall_Already_Click"
--匹配状态切换
local Anim_StartMatching        = "VXE_Hall_Match_Start_Click"
local Anim_MatchCancel          = "VXE_Hall_Matching_Click"
local Anim_MatchSuccess         = "VXE_Hall_MatchSuccess"

---状态计算公式
---@param Pre table 之前的状态
---@param Cur table 当前的状态
---@return string[] 动画事件名称
local function _InnerCalculate(Pre, Cur)
    if not Pre or not next(Pre) or not Cur or not next(Cur) then
        CLog("[cw] HallSettlementModel:_Calculate_V2(" .. string.format("%s, %s", Pre, Cur) .. ")")
        CError(debug.traceback())
        return {} 
    end
    
    local PreTeamInfo = Pre.TeamInfo    --之前在队伍中的状态情况，如果之前不在队伍中的话，则为nil    
    local PreMatchInfo = Pre.MatchInfo  --之前匹配状态的数据，是否在匹配中
    
    local CurTeamInfo = Cur.TeamInfo    --当前在队伍中的状态情况，如果当前不在队伍中的话，则为nil    
    local CurMatchInfo = Cur.MatchInfo  --当前的匹配状态，是否在匹配中

    --需要播放的动画列表
    local _Anims = {}
    local function _AddAnim(anim) table.insert(_Anims, anim) end
    
    --如果匹配成功，就播放匹配成功动画，其他状态变化就无需担心了
    if CurMatchInfo.isMatchingSuccess then
        if PreMatchInfo.isMatching then
            return { Anim_MatchSuccess }
        else
            return { Anim_StartMatching, Anim_MatchSuccess}
        end
    elseif PreMatchInfo.isMatchingSuccess and not CurMatchInfo.isMatchingSuccess then
        -- 匹配成功 -> 匹配失败
        return {Anim_MatchCancel}
    end
    
    --1.处理匹配状态
    -- 匹配中 -> 匹配中
    if PreMatchInfo.isMatching and CurMatchInfo.isMatching then
        --do nothing
    -- 未匹配 -> 未匹配
    elseif not PreMatchInfo.isMatching and not CurMatchInfo.isMatching then
        --do nothing
    -- 匹配中 -> 未匹配
    elseif PreMatchInfo.isMatching and not CurMatchInfo.isMatching then
        _AddAnim(Anim_MatchCancel)
    -- 未匹配 -> 匹配中
    elseif not PreMatchInfo.isMatching and CurMatchInfo.isMatching then
        _AddAnim(Anim_StartMatching)
    end
    
    --2.处理 单人-队长-准备队员-未准备队员的状态转变
    -- 单人 -> 单人
    if not PreTeamInfo and not CurTeamInfo then
        --do nothing

    -- 单人 -> 队伍(队长、准备队员、未准备队员)
    elseif not PreTeamInfo and CurTeamInfo then
        -- 单人 -> 队长
        if CurTeamInfo.isCaptain then
            -- _AddAnim(Anim_SoloToCaptain)
        -- 单人 -> 准备队员
        elseif CurTeamInfo.isReady then
            _AddAnim(Anim_ToTeammate)
        -- 单人 -> 未准备队员
        elseif not CurTeamInfo.isReady then
            _AddAnim(Anim_ToTeammate)
        end

    -- 队伍(队长、准备队员、未准备队员) -> 单人
    elseif PreTeamInfo and not CurTeamInfo then
        -- 队长 -> 单人
        if PreTeamInfo.isCaptain then
            -- _AddAnim(Anim_CaptainToSolo)
        -- 准备队员 -> 单人
        elseif PreTeamInfo.isReady then
            _AddAnim(Anim_ToCaptain)
        -- 未准备队员 -> 单人
        elseif not PreTeamInfo.isReady then
            _AddAnim(Anim_ToCaptain)
        end

    -- 队伍(队长、准备队员、未准备队员) -> 队伍(队长、准备队员、未准备队员)
    elseif PreTeamInfo and CurTeamInfo then
        -- 队长 -> 队伍(队长、准备队员、未准备队员)
        if PreTeamInfo.isCaptain then
            -- 队长 -> 队长
            if CurTeamInfo.isCaptain then
                --do nothing
            -- 队长 -> 准备队员
            elseif CurTeamInfo.isReady then
                _AddAnim(Anim_ToTeammate)
                -- _AddAnim(Anim_CaptainToTeammate)
            -- 队长 -> 未准备队员
            elseif not CurTeamInfo.isReady then
                _AddAnim(Anim_ToTeammate)
                -- _AddAnim(Anim_CaptainToTeammate)
            end

        -- 准备队员 -> 队伍(队长、准备队员、未准备队员)
        elseif PreTeamInfo.isReady then
            -- 准备队员 -> 队长
            if CurTeamInfo.isCaptain then
                _AddAnim(Anim_ToCaptain)
                -- _AddAnim(Anim_TeammateToCaptain)
            -- 准备队员 -> 准备队员
            elseif CurTeamInfo.isReady then
                -- do nothing
            -- 准备队员 -> 未准备队员
            elseif not CurTeamInfo.isReady then
                _AddAnim(Anim_ToUnready)
            end

        -- 未准备队员 -> 队伍(队长、准备队员、未准备队员)
        elseif not PreTeamInfo.isReady then
            -- 未准备队员 -> 队长
            if CurTeamInfo.isCaptain then
                _AddAnim(Anim_ToCaptain)
                -- _AddAnim(Anim_TeammateToCaptain)
            -- 未准备队员 -> 准备队员
            elseif CurTeamInfo.isReady then
                _AddAnim(Anim_ToReady)
            -- 未准备队员 -> 未准备队员
            elseif not CurTeamInfo.isReady then
                --do nothing
            end
        end
    end

    return _Anims
end

--[[
    State = {
        TeamInfo = {            --队伍信息，没有队伍则为nil
            isCaptain = true,   --是否是队长
            isReady = true,     --是否已准备
        },
        MatchInfo = {           --匹配信息
            isMatching = true,  --是否正在匹配中
            isMatchingSuccess = nil,    --匹配是否成功了
        }
    }
--]]
---存储匹配入口需要的数据
---@param State table
function HallMatchEntranceModel:StoreData(State)
    local function _store(key1, key2)
        self._LastStateData[key1][key2] = State[key1][key2]
        self._NextStateDate[key1][key2] = State[key1][key2]
    end

    _store("TeamInfo", "isCaptain")
    _store("TeamInfo", "isReady")
    _store("MatchInfo", "isMatching")
    _store("MatchInfo", "isMatchingSuccess")    
end

function HallMatchEntranceModel:_Debug_LogOldState(LogKey)
    if LogKey then
        LogKey = "[" .. tostring(LogKey) .. "]"
    else
        LogKey = ""
    end
    
    CLog("[cw][HallMatchEntranceModel][Old]" .. tostring(LogKey) .. "        " .. 
            " isReady: " .. tostring(self._LastStateData.TeamInfo.isReady) ..
            ",isCaptain: " .. tostring(self._LastStateData.TeamInfo.isCaptain)  ..
            ",isMatching: " .. tostring(self._LastStateData.MatchInfo.isMatching) ..
            ",isMatchingSuccess: " .. tostring(self._LastStateData.MatchInfo.isMatchingSuccess))
end

function HallMatchEntranceModel:_Debug_LogNewState(LogKey)
    if LogKey then
        LogKey = "[" .. tostring(LogKey) .. "]"
    else
        LogKey = ""
    end
    
    CLog("[cw][HallMatchEntranceModel][New]" .. tostring(LogKey) .. "        " ..
            " isReady: " .. tostring(self._NextStateDate.TeamInfo.isReady) ..
            ",isCaptain: " .. tostring(self._NextStateDate.TeamInfo.isCaptain)  ..
            ",isMatching: " .. tostring(self._NextStateDate.MatchInfo.isMatching) ..
            ",isMatchingSuccess: " .. tostring(self._NextStateDate.MatchInfo.isMatchingSuccess))
end

---判断是否存在之前的数据
---@return boolean 是否存在存储的数据
function HallMatchEntranceModel:HasStoreData()
    return self._NextStateDate and next(self._NextStateDate)
end

---@return table
function HallMatchEntranceModel:GetStoreData()
    return self._NextStateDate
end

---在使用完数据后，需要更新一下缓存的数据
function HallMatchEntranceModel:ReplaceOldDate()
    local function _fix(key1, key2)
        self._LastStateData[key1][key2] = self._NextStateDate[key1][key2]
    end

    _fix("TeamInfo", "isCaptain")
    _fix("TeamInfo", "isReady")
    _fix("MatchInfo", "isMatching")
    _fix("MatchInfo", "isMatchingSuccess")
end

function HallMatchEntranceModel:ClearStoreData()
    self._LastStateData = {
        TeamInfo = {                --队伍信息
            isCaptain = nil,            --是否是队长
            isReady = nil,              --是否已准备
        },
        MatchInfo = {               --匹配信息
            isMatching = nil,           --是否正在匹配中
            isMatchingSuccess = nil,    --匹配是否成功了
        }
    }

    --下一次动画使用的数据
    self._NextStateDate = {
        TeamInfo = {                --队伍信息，没有队伍则为nil
            isCaptain = nil,           --是否是队长
            isReady = nil,             --是否已准备
        },
        MatchInfo = {               --匹配信息
            isMatching = nil,           --是否正在匹配中
            isMatchingSuccess = nil,    --匹配是否成功了
        }
    }
end

---@return boolean 两个状态是否一致
local function _IsSame(LState, RState)
    if not LState and not RState then return true end
    if not LState or not RState then return false end
    
    --对比所有的字段，判断是否一致
    local res, continue = true, true    
    local function _Compare(key1, key2)
        if not continue then return end
        if LState[key1][key2] ~= RState[key1][key2] then
            res = false
            continue = false
        end
    end
    _Compare("TeamInfo", "isCaptain")
    _Compare("TeamInfo", "isReady")
    _Compare("MatchInfo", "isMatching")
    _Compare("MatchInfo", "isMatchingSuccess")
    
    return res
end

---外部调用计算动画逻辑
---@return string[] 需要播放的动画事件列表
function HallMatchEntranceModel:Calculate()    
    if _IsSame(self._LastStateData, self._NextStateDate) then
        --CLog("[cw][HallMatchEntranceModel]: Same state with last, do not need to update")
        return {}
    end

    self:_Debug_LogOldState()
    self:_Debug_LogNewState()
    return _InnerCalculate(self._LastStateData, self._NextStateDate)
end

return HallMatchEntranceModel