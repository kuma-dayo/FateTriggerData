
--[[
    区域政策
]]
local class_name = "RegionPolicyCtrl"
---@class RegionPolicyCtrl : UserGameController
RegionPolicyCtrl = RegionPolicyCtrl or BaseClass(UserGameController, class_name)

--- UserGameController:OnLogin(data)            --用户登入，用于初始化数据,当玩家帐号信息同步完成，会触发
--- UserGameController:OnLogout(data)           --用户登出，用于清除旧用户的数据相关  data有值表示为断线重连
--- UserGameController:OnPreEnterBattle()          --用户从大厅进入战斗处理的逻辑（即将进入，还未进入）
--- UserGameController:OnPreBackToHall()           --用户从战斗返回大厅处理的逻辑（即将进入，还未进入）
--- UserGameController:AddMsgListenersUser()    --填写需要监听的事件


function RegionPolicyCtrl:__init()

end

function RegionPolicyCtrl:Initialize()
end

---用户登入，用于初始化数据,当玩家帐号信息同步完成，会触发
function RegionPolicyCtrl:OnLogin(data)
end

---用户登出，用于清除旧用户的数据相关  data有值表示为断线重连
function RegionPolicyCtrl:OnLogout(data)
end

---用户从大厅进入战斗处理的逻辑（即将进入，还未进入）
function RegionPolicyCtrl:OnPreEnterBattle()
end

---用户从战斗返回大厅处理的逻辑（即将进入，还未进入）
function RegionPolicyCtrl:OnPreBackToHall()
end

---填写需要监听的事件
function RegionPolicyCtrl:AddMsgListenersUser()
	self.MsgList = {}
end

