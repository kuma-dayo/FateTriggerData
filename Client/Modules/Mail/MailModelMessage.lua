--[[
    消息中心邮件数据模型
]]
local super = MailModelBase;
local class_name = "MailModelMessage";

---@class MailModelMessage : MailModelBase
---@field private super MailModelBase
MailModelMessage = BaseClass(super, class_name);


return MailModelMessage;