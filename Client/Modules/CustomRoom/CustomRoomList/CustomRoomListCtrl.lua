---
--- Ctrl 模块，主要用于处理协议
--- Description: 自建房房间列表协议相关
--- Created At: 2023/07/05 14:41
--- Created By: 朝文
---

local class_name = "CustomRoomListCtrl"
---@class CustomRoomListCtrl : UserGameController
CustomRoomListCtrl = CustomRoomListCtrl or BaseClass(UserGameController, class_name)

function CustomRoomListCtrl:__init() end
function CustomRoomListCtrl:Initialize() end
function CustomRoomListCtrl:AddMsgListenersUser()
    -- self.ProtoList = {
    --     { MsgName = Pb_Message.RoomInfoRsp,	    Func = self.OnRoomInfoRsp },
    -- }
end

-----------------------------------------请求相关------------------------------

------------------
--- 请求房间列表 ---
------------------

---【发包】请求房间列表信息
---@param RoomId number 参数为0的话标识获取全部房间列表
function CustomRoomListCtrl:SendRoomInfoReq(RoomId)
    CLog("[cw] CustomRoomListCtrl:SendRoomInfoReq(" .. string.format("%s", RoomId) .. ")")
    local Data = {
        InRoomId = RoomId or 0        
    }
    self:SendProto(Pb_Message.RoomInfoReq, Data)
end

--[[
Msg = {
    --房间列表
    RoomInfo = {
        [1] = {
            RoomId = 1,
            MasterInfo = {
                PlayerId = 13237223429,
                Name = "微凉",
            },
            RepeatSelectHero = 0,
            PlayerNum = 1,
            TeamType = 1,
            State = 1,
            GameplayId = 10101,
            LevelId = 1000,
            View = 1/3,
            TeamType = 1/2/4,
         },
    }
}
--]]
---【回包】服务器返回的房间列表信息
---@param Msg table
function CustomRoomListCtrl:OnRoomInfoRsp(Msg)
    CLog("[cw][CustomRoomListCtrl] OnRoomInfoRsp(" .. string.format("%s", Msg) .. ")")
    local RoomInfo = Msg.RoomInfo
    print_r(RoomInfo, "[cw] ====RoomInfo")
    
    ---@type CustomRoomListModel
    local CustomRoomListModel = MvcEntry:GetModel(CustomRoomListModel)
    CustomRoomListModel:SetDataList(RoomInfo)
    CustomRoomListModel:DispatchType(CustomRoomListModel.ON_ROOM_INFO_RSP)
end