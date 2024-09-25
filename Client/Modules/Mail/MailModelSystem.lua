--[[
    系统邮件数据模型
]]
local super = MailModelBase;
local class_name = "MailModelSystem";

---@class MailModelSystem : MailModelBase
---@field private super MailModelBase
MailModelSystem = BaseClass(super, class_name);
MailModelSystem.ON_MAIL_DATA_INITED = "ON_MAIL_DATA_INITED"     --邮件数据全部接收完成

return MailModelSystem;