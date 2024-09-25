---
--- Ctrl 模块，主要用于处理协议
--- Description: 玩家信息
--- Created At: 2023/08/04 17:08
--- Created By: 朝文
---

require("Client.Modules.PlayerInfo.PlayerInfoModel")

local class_name = "PlayerInfoCtrl"
---@class PlayerInfoCtrl : UserGameController
PlayerInfoCtrl = PlayerInfoCtrl or BaseClass(UserGameController, class_name)

function PlayerInfoCtrl:__init()
    CWaring("[cw] PlayerInfoCtrl init")
    self.Model = nil
end

function PlayerInfoCtrl:Initialize()
    self.Model = self:GetModel(PlayerInfoModel)
end

function PlayerInfoCtrl:AddMsgListenersUser()
    --添加协议回包监听事件
    self.ProtoList = {
    }
end

-----------------------------------------请求相关------------------------------
