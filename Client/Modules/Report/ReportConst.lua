---
--- 举报常量
--- Description: ReportConst
--- Created At: 2023/09/01 16:55
--- Created By: 朝文
---

--local ReportConst = require("Client.Modules.Report.ReportConst")

---@class ReportConst
local ReportConst = {}
ReportConst.Enum_ReportScene = {
    ["InGame"]      = 1,  --局内
    ["Settlemnet"]  = 2,  --结算
    ["PersonInfo"]  = 3,  --个人信息
    ["Chat"]        = 4,  --聊天
}

--当举报的类型是文字信息的话，就需要传递这个值
ReportConst.Enum_MsgType = {
    ["PrivateChannal"]  = 3,    --私聊频道3
    ["WoldwideChannal"] = 4,    --世界聊天频道4
    ["UserNickName"]    = 11,   --用户昵称11
}

ReportConst.Enum_ReportContentCombineType = {
    Text            = 1,  --文本
    Audio           = 2,  --音频
    Image           = 3,  --图片
    Video           = 4,  --视频
    ImgText         = 5,  --图文
    RichText        = 6,  --富文本
}

--大厅使用的场景Id类型
ReportConst.Enum_HallReportSceneId = {
    HallSettlement  = "HallSettlement", --局外结算
    PersonalZone    = "PersonalZone"    --个人空间
}

return ReportConst
