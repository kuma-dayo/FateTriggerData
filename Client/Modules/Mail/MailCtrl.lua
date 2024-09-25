--[[
    邮件控制模块
]]
require("Client.Modules.Mail.MailModelBase");
require("Client.Modules.Mail.MailModelSystem");
require("Client.Modules.Mail.MailModelGift");
require("Client.Modules.Mail.MailModelMessage");


local class_name = "MailCtrl";
MailCtrl = MailCtrl or BaseClass(UserGameController,class_name);


function MailCtrl:__init()
    CWaring("==MailCtrl init")
end

function MailCtrl:Initialize()
    CWaring("==MailCtrl Initialize")
    --描述每个页签对应的Model类
    self.MailPageType2ModelClass = {
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_SYS] = MailModelSystem,
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_GIFT] = MailModelGift,
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_MSG] = MailModelMessage,
    }
    --描述每个页对应的杂项配置，用于获取邮件最大数量限制等等
    self.MailPageType2ParameterCfg = {
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_SYS] =  ParameterConfig.MailSysMax,
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_GIFT] = ParameterConfig.MailGiftMax,
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_MSG] = ParameterConfig.MailMsgMax,
    }
    for k,TheModelClass in ipairs(self.MailPageType2ModelClass) do
        local ParameterCfg = self.MailPageType2ParameterCfg[k]
        if ParameterCfg then
            self:GetModel(TheModelClass):SetParameterCfg(ParameterCfg)
        end
    end
end

--[[
    玩家登入的时候，进行请求数据
]]
function MailCtrl:OnLogin(data)
    --用于标记邮件数据有没有接收完成
    self.MailMessageInitedList = {
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_SYS] = false,
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_GIFT] = false,
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_MSG] = false,
    }
    for k, v in pairs(self.MailMessageInitedList) do
        self:SendProto_PlayerMailInfoListReq(k)
    end
end

--[[
    玩家登出
]]
function MailCtrl:OnLogout(data)
    CWaring("MailCtrl OnLogout")
    --用于标记邮件数据有没有接收完成
    self.MailMessageInitedList = {
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_SYS] = false,
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_GIFT] = false,
        [Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_MSG] = false,
    }
end

function MailCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.PlayerMailInfoListRsp,	Func = self.PlayerMailInfoListRsp_Func },
        {MsgName = Pb_Message.PlayerAddMailSyn,	Func = self.PlayerAddMailSyn_Func },
        {MsgName = Pb_Message.PlayerReadMailRsp,	Func = self.PlayerReadMailRsp_Func },
        {MsgName = Pb_Message.PlayerGetAppendRsp,	Func = self.PlayerGetAppendRsp_Func },
        {MsgName = Pb_Message.PlayerDeleteMailRsp,	Func = self.PlayerDeleteMailRsp_Func },
    }
end

--[[
    message MailInfoNode
    {
        int32 MailTemplateId        = 1;        // 邮件模板Id
        int64 SendPlayerId          = 2;        // 发件人角色Id,0,代表是服务器发送
        string SendPlayerName       = 3;        // 发送人名称，系统发送时，读配置
        int32 SendHeadId            = 4;        // 头像Id,系统发送时，读配置
        int64 ExpireTime            = 5;        // 过期时间
        int64 ReceiveTime           = 6;        // 接收邮件的时间戳
        bool  ReadFlag              = 7;        // true已读，false未读
        int64 MailUniqId            = 8;        // 邮件唯一Id
        repeated AppendInfo AppendList = 9;     // 附件列表
        bool  ReceiveAppend         = 10;       // true已经领取附件，false未领取
        string Title                = 11;       // 邮件自定义标题
        string Context              = 12;       // 邮件自定义内容
    }
    // 客户端请求邮件的详细信息
    message PlayerMailInfoListRsp
    {
        MAIL_PAGE_TYPE  PageType = 1;
        repeated MailInfoNode MailInfoList = 2;      // 邮件附件的唯一Id
    }
]]
function MailCtrl:PlayerMailInfoListRsp_Func(Msg)
    local TheModel = self:GetModelByPageType(Msg.PageType)
    if not TheModel then
        return
    end
    TheModel:SetMailInfoList(Msg.MailInfoList)

    self:CheckMailMessageInited(Msg.PageType)
end

--[[
    // 增加邮件同步信息
    message PlayerAddMailSyn
    {
        MAIL_PAGE_TYPE  PageType = 1;
        MailInfoNode  MailInfo     = 2;         // 增加的邮件信息
    }
]]
function MailCtrl:PlayerAddMailSyn_Func(Msg)
    local TheModel = self:GetModelByPageType(Msg.PageType)
    if not TheModel then
        return
    end
    TheModel:AddMailInfo(Msg.MailInfo)
end

--[[
    // 已读邮件应答
    message PlayerReadMailRsp
    {
        MAIL_PAGE_TYPE  PageType = 1;
        repeated int64 MailUniqIdList = 2;      // 已读成功邮件附件的唯一Id
    }
]]
function MailCtrl:PlayerReadMailRsp_Func(Msg)
    local TheModel = self:GetModelByPageType(Msg.PageType)
    if not TheModel then
        return
    end
    TheModel:UpdateMailReadFlag(Msg.MailUniqIdList)
end

--[[
    // 领取附件的返回
    message PlayerGetAppendRsp
    {
        MAIL_PAGE_TYPE  PageType = 1;
        repeated int64 MailUniqIdList = 2;      // 领取邮件附件成功的唯一Id
    }
]]
function MailCtrl:PlayerGetAppendRsp_Func(Msg)
    local TheModel = self:GetModelByPageType(Msg.PageType)
    if not TheModel then
        return
    end
    TheModel:UpdateMailReceiveAttachFlag(Msg.MailUniqIdList)
    --一键领取后将对应邮件的读取状态变为已读
    self:SendProto_PlayerReadMailReq(Msg.PageType, Msg.MailUniqIdList)
end

--[[
    // 请求删除邮件应答
    message PlayerDeleteMailRsp
    {
        MAIL_PAGE_TYPE  PageType = 1;
        repeated int64 MailUniqIdList = 2;      // 已经删除邮件附件的唯一Id
    }
]]
function MailCtrl:PlayerDeleteMailRsp_Func(Msg)
    local TheModel = self:GetModelByPageType(Msg.PageType)
    if not TheModel then
        return
    end
    TheModel:DeleteMailList(Msg.MailUniqIdList)
end

--------------------------------------------请求相关------------------------------------------------------------------------
--[[
    客户端请求邮件的详细信息,根据类型
]]
function MailCtrl:SendProto_PlayerMailInfoListReq(PageType)
    local Msg = {
        PageType = PageType,
    }
    self:SendProto(Pb_Message.PlayerMailInfoListReq, Msg)
end

--[[
    已读邮件
]]
function MailCtrl:SendProto_PlayerReadMailReq(PageType, MailUniqIdList)
    local Msg = {
        PageType = PageType,
        MailUniqIdList = MailUniqIdList,
    }
    self:SendProto(Pb_Message.PlayerReadMailReq, Msg)
end


--[[
    领取附件
]]
function MailCtrl:SendProto_PlayerGetAppendReq(PageType, MailUniqIdList)
    local Msg = {
        PageType = PageType,
        MailUniqIdList = MailUniqIdList,
    }
    self:SendProto(Pb_Message.PlayerGetAppendReq, Msg)
end

--[[
    删除邮件
]]
function MailCtrl:SendProto_PlayerDeleteMailReq(PageType, MailUniqIdList)
    local Msg = {
        PageType = PageType,
        MailUniqIdList = MailUniqIdList,
    }
    self:SendProto(Pb_Message.PlayerDeleteMailReq, Msg)
end

--------------------------------------------其它-----------------------------------

--[[
    根据页签类型获取对应的Model类
]]
function MailCtrl:GetModelByPageType(PageType)
    local ModelCalss =  self.MailPageType2ModelClass[PageType]
    return ModelCalss and self:GetModel(ModelCalss) or nil
end

--[[
    根据服务器定义的邮件唯一ID获取对应的邮件消息
]]
---@param MailUniqId number 邮件唯一ID
function MailCtrl:GetMailInfoByMailUniqId(MailUniqId)
    for index, value in pairs(self.MailPageType2ModelClass) do
        local TheModel = self:GetModel(value)
        if TheModel then
            local MailInfo = TheModel:GetData(MailUniqId)
            if MailInfo then
                return MailInfo
            end
        end
    end
    return nil
end

--[[
    转换待显示的邮件数据
    如果有模板情况下，优先取模板数据进行展示
]]
function MailCtrl:ConvertMailInfo(MailInfo)
    if MailInfo == nil then
        return
    end
    if MailInfo.MailTemplateId > 0 then
        local CfgMailTemplate = G_ConfigHelper:GetSingleItemById(Cfg_MailConfig,MailInfo.MailTemplateId)
        if CfgMailTemplate ~= nil then
            MailInfo.SendPlayerName = CfgMailTemplate[Cfg_MailConfig_P.Sender]
            MailInfo.HeadIcon =  CfgMailTemplate[Cfg_MailConfig_P.HeadIcon]
            MailInfo.Title = string.len(MailInfo.Title) > 0 and MailInfo.Title or CfgMailTemplate[Cfg_MailConfig_P.Title]
            MailInfo.Context = string.len(MailInfo.Context) > 0 and MailInfo.Context or CfgMailTemplate[Cfg_MailConfig_P.Content]

            if CfgMailTemplate[Cfg_MailConfig_P.UseConfigSendTime] then
                MailInfo.RealSendTime = TimeUtils.TimeStampUTC0_FromTimeStr(CfgMailTemplate[Cfg_MailConfig_P.SendTime])
            else
                MailInfo.RealSendTime = MailInfo.ReceiveTime
            end
        end
    end
    return MailInfo
end

--检测邮箱数据是否接收完成 是的话 抛出事件
function MailCtrl:CheckMailMessageInited(PageType)
    self.MailMessageInitedList[PageType] = true
    local AlReady = true
    for k, v in pairs(self.MailMessageInitedList) do
        if v == false then
            AlReady = false
            break
        end
    end
    if AlReady then
        local TheModel = self:GetModelByPageType(Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_SYS)
        if TheModel then
            TheModel:DispatchType(MailModelSystem.ON_MAIL_DATA_INITED)
        end
        self:DeleteInValidQuestionnaireMail()
    end
end

function MailCtrl:DeleteInValidQuestionnaireMail()
    for Type,TheModelClass in ipairs(self.MailPageType2ModelClass) do
        local Model = self:GetModel(TheModelClass)
        if Model then
            Model:DeleteInValidQuestionnaireMailByType(Type)
        end
    end

end