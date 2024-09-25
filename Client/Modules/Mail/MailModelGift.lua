--[[
    礼物邮件数据模型
]]
local super = MailModelBase;
local class_name = "MailModelGift";

---@class MailModelGift : MailModelBase
---@field private super MailModelBase
MailModelGift = BaseClass(super, class_name);


return MailModelGift;