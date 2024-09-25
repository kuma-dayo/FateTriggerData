---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 自建房房间列表信息
--- Created At: 2023/05/30 10:40
--- Created By: 朝文
---

--- 存储了房间列表相关的信息，
---
--- 1) 本地缓存的所有房间信息
---     mDataList = {                       -> GetDataList():table
---                                         <- SetDataList(table):void
---     }
---
--- 3) 当前选择的房间详情
---     CurSelRoomInfo = {                  -> GetCurSelRoomInfo():table
---                                         <- SetCurSelRoomInfo(newCurSelRoomInfo):void
---                                         x  CleanCurSelRoomInfo():void
---         GameplayId = 10101,
---         LevelId = 1000,
---         ModeKey = "101_solo_fpp", 
---         TeamType = 1, 
---         MasterInfo = {, 
---             Name = "bailixi2", 
---             PlayerId = 6392119303, 
---         } 
---         RepeatSelectHero = 0, 
---         State = 1,                      -> GetCurSelRoomInfo_State():number
---         PlayerNum = 1, 
---         RoomId = 1,                     -> GetCurSelRoomInfo_RoomId():number
--- }
---
--- 4) 通用接口
---     -> GetRoomInfo_State(RoomId):table
---     -> IsRoomState_None(RoomId):boolean
---     -> IsRoomState_Idle(RoomId):boolean
---     -> IsRoomState_Warmup(RoomId):boolean
---     -> IsRoomState_InBattle(RoomId):boolean
---     -> IsRoomState_Settlement(RoomId):boolean
---     -> IsRoomState_Recycle(RoomId):boolean
---

local super = ListModel
local class_name = "CustomRoomListModel"
---@class CustomRoomListModel : ListModel
CustomRoomListModel = BaseClass(super, class_name)
CustomRoomListModel.Enum_RoomState = {
    None        = 0, 
    Idle        = 1, 
    Warmup      = 2, 
    InBattle    = 3, 
    Settlement  = 4, 
    Recycle     = 5,
}

CustomRoomListModel.Enum_RoomMod = {
    Single  = 1, --单排
    Double  = 2, --双排
    Clone   = 3, --复选      
    Four    = 4, --四排
}

CustomRoomListModel.ON_SELECT_ITEM = "ON_SELECT_ITEM"       --选中新的条目
CustomRoomListModel.ON_ROOM_INFO_RSP = "ON_ROOM_INFO_RSP"   --房间信息更新了

function CustomRoomListModel:KeyOf(vo)
    if vo["RoomId"] then
        return vo["RoomId"]
    end
    return CustomRoomListModel.super.KeyOf(self, vo)
end

function CustomRoomListModel:__init()
    --根据状态来排序
    self.keepSortIndexFunc = function (a, b) return a.State < b.State end    
    self:DataInit()
end

--region CurSelRoomInfo

--[[
newCurSelRoomInfo =  { 
    GameplayId = 10101,
    LevelId = 1000,
    ModeKey = "101_solo_fpp",
    TeamType = 1, 
    MasterInfo = {, 
        Name = "bailixi2", 
        PlayerId = 6392119303, 
    } 
    RepeatSelectHero = 0, 
    State = 1, 
    PlayerNum = 1, 
    RoomId = 1, 
} 
--]]
---封装一个设置 CurSelRoomInfo 的方法, 用于设置 用户当前选择的房间信息
---@param newCurSelRoomInfo table
function CustomRoomListModel:SetCurSelRoomInfo(newCurSelRoomInfo)
    print_r(newCurSelRoomInfo, "[cw] newCurSelRoomInfo")
    if not newCurSelRoomInfo then
         CError("[cw] trying to set a nil value to CurSelRoomInfo in CustomRoomListModel:SetCurSelRoomInfo")
    end
    
    self.CurSelRoomInfo = newCurSelRoomInfo
    self:DispatchType(CustomRoomListModel.ON_SELECT_ITEM)
end

---封装一个获取 CurSelRoomInfo 的方法，用于获取 用户当前选择的房间信息
---@return table 当前房间信息
function CustomRoomListModel:GetCurSelRoomInfo()
    return self.CurSelRoomInfo
end

---封装一个获取 CurSelRoomInfo 的方法，用于获取 用户当前选择的房间信息
---@return number 当前选择的房间的ID
function CustomRoomListModel:GetCurSelRoomInfo_RoomId()
    if not self.CurSelRoomInfo or not self.CurSelRoomInfo.RoomId then
        CWaring("[cw] Cannot get RoomId, cause Current RoomInfo is nil, please set it before get it.")
        return nil
    end
    return self.CurSelRoomInfo.RoomId
end

---封装一个获取 CurSelRoomInfo 的方法，用于获取 用户当前选择的房间信息
---@return number 当前选择的房间的状态
function CustomRoomListModel:GetCurSelRoomInfo_State()
    if not self.CurSelRoomInfo or not self.CurSelRoomInfo.State then
        CError("[cw] Cannot get State, cause Current RoomInfo is nil, please set it before get it.")
        return CustomRoomListModel.Enum_RoomState.None
    end
    return self.CurSelRoomInfo.State
end

---封装一个清空 CurSelRoomInfo的方法，用于去除 用户当前选择的房间信息
function CustomRoomListModel:CleanCurSelRoomInfo()
    self.CurSelRoomInfo = nil
end

--endregion CurSelRoomInfo

---判断传入的房间是否已经满员了
---@param RoomId number 房间id
function CustomRoomListModel:IsRoomPlayerFull(RoomId)
    local Data = self:GetData(RoomId)
    if not Data or not next(Data) then
        CError("[cw] No data found for room(" .. tostring(RoomId) .. "), Please check your usage")
        CError(debug.traceback())
        return true
    end
    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local CurPlayerNum = Data.PlayerNum
    local MaxPlayerNum = MatchModeSelectModel:GetModeEntryCfg_MaxPlayer(Data.ModeKey)

    return MaxPlayerNum > 0 and CurPlayerNum >= MaxPlayerNum
end

function CustomRoomListModel:GetRoomInfo_State(RoomId)
    local Data = self:GetData(RoomId)
    if Data then return Data.State end
    
    return nil
end 
function CustomRoomListModel:IsRoomState_None(RoomId)       return self:GetRoomInfo_State(RoomId) == CustomRoomListModel.Enum_RoomState.None        end
function CustomRoomListModel:IsRoomState_Idle(RoomId)       return self:GetRoomInfo_State(RoomId) == CustomRoomListModel.Enum_RoomState.Idle        end
function CustomRoomListModel:IsRoomState_Warmup(RoomId)     return self:GetRoomInfo_State(RoomId) == CustomRoomListModel.Enum_RoomState.Warmup      end
function CustomRoomListModel:IsRoomState_InBattle(RoomId)   return self:GetRoomInfo_State(RoomId) == CustomRoomListModel.Enum_RoomState.InBattle    end
function CustomRoomListModel:IsRoomState_Settlement(RoomId) return self:GetRoomInfo_State(RoomId) == CustomRoomListModel.Enum_RoomState.Settlement  end
function CustomRoomListModel:IsRoomState_Recycle(RoomId)    return self:GetRoomInfo_State(RoomId) == CustomRoomListModel.Enum_RoomState.Recycle     end

---初始化数据，用于第一次调用及登出的时候调用
function CustomRoomListModel:DataInit()
    self.CurSelRoomInfo = nil
end

---玩家登出时调用
function CustomRoomListModel:OnLogout(data)
    self:DataInit()
end

return CustomRoomListModel