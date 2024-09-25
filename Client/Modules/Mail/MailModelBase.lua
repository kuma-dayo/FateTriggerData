--[[
    邮件数据模型基类
]]
local super = ListModel;
local class_name = "MailModelBase";

---@class MailModelBase : ListModel
---@field private super ListModel
MailModelBase = BaseClass(super, class_name);


--[[
    排序优先级：
    - 未读无附件= 未读带附件 ＞ 已读带附件 ＞ 已读无附件

    注意，有附件但是被领取状态下，属于无附件
]]
MailModelBase.MailStateTypeEnum = {
    --未读带附件
    UnReadWithAttached = 1,
    --未读无附件
    UnReadNoAttached = 2,
    --已读带附件
    ReadWithAttached = 3,
    --已读无附件
    ReadNoAttached = 4,
    NONE = 5,
}

function MailModelBase:__init()
    --杂项配置
    self.ParameterCfg = nil
    self:_dataInit()

    --排序规则: 这规则让人无语
    --[[
        未读带附件==未读无附件＞已读带附件＞已读无附件
        同一优先级下，(配置表内填的)发送时间越晚排序越靠前
        同一优先级下，且发送时间相同，则邮件ID越大越靠前
    ]]
    self.keepSortIndexFunc = function(A, B)
        if A == nil or B == nil then 
            return false
        end

        if not A.ReadFlag and B.ReadFlag then
            return true
        elseif A.ReadFlag and not B.ReadFlag then
            return false
        elseif A.ReadFlag and B.ReadFlag then
            local MailStateTypeA = self:CalculateMailStateType(A)
            local MailStateTypeB = self:CalculateMailStateType(B)
            if MailStateTypeA ~= MailStateTypeB then
                return MailStateTypeA < MailStateTypeB
            end
        end

        local SendTimeStampA = self:GetMailSendTimeStamp(A)
        local SendTimeStampB = self:GetMailSendTimeStamp(B)
        if SendTimeStampA ~= SendTimeStampB then
            return SendTimeStampA > SendTimeStampB
        end

        if A.MailTemplateId ~= B.MailTemplateId then
            return A.MailTemplateId > B.MailTemplateId
        end

        return A.MailUniqId > B.MailUniqId
    end
end

function MailModelBase:_dataInit()
    --已读没附件列表 (用于方便一键删除)
    self.ReadWithOutAttachMailList = {}
    --未读邮件  （用于方便计数显示）
    self.UnReadMailList = {}
    --带有附件的邮件  （用于一键领取）
    self.AttachedMailList = {}
    --设置初始数据标记
    self.MailDataDirty = true
end

--[[
    玩家登出时调用
]]
function MailModelBase:OnLogout(data)
    MailModelBase.super.OnLogout(self)
    self:_dataInit()
end

--[[
    重写父方法，返回唯一Key
]]
function MailModelBase:KeyOf(vo)
    return vo["MailUniqId"]
end

--[[
    重写父类方法，如果数据发生改变
    进行通知到这边的逻辑
]]
function MailModelBase:SetIsChange(value)
    MailModelBase.super.SetIsChange(self,value)
    if value then
        self.MailDataDirty = true
    end
end


--[[
    计算邮件的状态
]]
function MailModelBase:CalculateMailStateType(Mail)
    local MailStateType = MailModelBase.MailStateTypeEnum.NONE
    if not Mail.ReadFlag  then
        MailStateType = (#Mail.AppendList > 0 and not Mail.ReceiveAppend) and MailModelBase.MailStateTypeEnum.UnReadWithAttached or MailModelBase.MailStateTypeEnum.UnReadNoAttached
    else
        MailStateType = (#Mail.AppendList > 0 and not Mail.ReceiveAppend) and MailModelBase.MailStateTypeEnum.ReadWithAttached or MailModelBase.MailStateTypeEnum.ReadNoAttached
    end
    return MailStateType
end


--[[
    获取邮件表中发送时间的时间戳
]]
function MailModelBase:GetMailSendTimeStamp(Mail)
    if Mail.MailTemplateId == 0 then
        return 0
    end
    local CfgMailTemplate = G_ConfigHelper:GetSingleItemById(Cfg_MailConfig,Mail.MailTemplateId)
    if CfgMailTemplate == nil then
        return 0
    end
    if CfgMailTemplate[Cfg_MailConfig_P.UseConfigSendTime] then
        return CfgMailTemplate[Cfg_MailConfig_P.SendTimeTimestamp]
    else
        return Mail.ReceiveTime
    end
end


--[[
    重新计算Cache数据
    空间换性能
]]
function MailModelBase:CalculateMailDirty()
    if not self.MailDataDirty then
        return 
    end
    self.MailDataDirty = false

    --准备数据
    self.UnReadMailList = {}
    self.AttachedMailList = {}
    self.ReadWithOutAttachMailList = {}

    local dict = self:GetDataList() 
    for _,Vo in ipairs(dict) do
        if not Vo.ReadFlag then
            table.insert(self.UnReadMailList, Vo.MailUniqId)
        end
        local MailStateType = self:CalculateMailStateType(Vo)
        if MailStateType == MailModelBase.MailStateTypeEnum.ReadWithAttached 
            or MailStateType == MailModelBase.MailStateTypeEnum.UnReadWithAttached then
            table.insert(self.AttachedMailList, Vo.MailUniqId)
        end
        if MailStateType == MailModelBase.MailStateTypeEnum.ReadNoAttached then
            table.insert(self.ReadWithOutAttachMailList, Vo.MailUniqId)
        end
    end
end

--[[
    返回具体的邮件限制数量
]]
function MailModelBase:GetMailMaxLimit()
    return CommonUtil.GetParameterConfig(self.ParameterCfg,0)
end

--[[
    设置杂项表配置 (ParameterConfig)，用于获取相关参数
]]
function MailModelBase:SetParameterCfg(Cfg)
    self.ParameterCfg = Cfg
end

--[[
    获取邮件数量
]]
function MailModelBase:GetMailCount()
    self:CalculateMailDirty()
    return self:GetLength()
end


--获取已读没有附件的邮件
function MailModelBase:GetReadWithOutAttachMailList()
    self:CalculateMailDirty()
    return self.ReadWithOutAttachMailList
end

--获取未读的邮件
function MailModelBase:GetUnReadMailList()
    self:CalculateMailDirty()
    return self.UnReadMailList
end

--[[
    获取未读邮件数量
]]
function MailModelBase:GetUnReadMailCount()
    self:CalculateMailDirty()
    return #self.UnReadMailList
end

--获取带附件的邮件
function MailModelBase:GetAttachedMailList()
    self:CalculateMailDirty()
    return self.AttachedMailList
end


function MailModelBase:HasAttached(Mail)
    local TheMailStateType = self:CalculateMailStateType(Mail)
    if TheMailStateType == MailModelBase.MailStateTypeEnum.ReadWithAttached 
        or TheMailStateType == MailModelBase.MailStateTypeEnum.UnReadWithAttached then
        return true
    end
    return false
end

--[[
    初始化邮件列表（协议驱动）
]]
function MailModelBase:SetMailInfoList(MailInfoList)
    if MailInfoList == nil then
        return
    end
    self:SetDataList(MailInfoList)
end

--[[
    添加邮件（协议驱动）
]]
function MailModelBase:AddMailInfo(MailInfo)
    self:UpdateDatas({MailInfo})
end

--[[
    更新邮件已读状态（协议驱动）
]]
function MailModelBase:UpdateMailReadFlag(MailUniqIdList)
    if MailUniqIdList == nil then
        return
    end
    local DataList = {}
    for k, v in pairs(MailUniqIdList) do
        local MailData = self:GetData(v)
        if MailData ~= nil then
            MailData.ReadFlag = true
            table.insert(DataList, MailData)
        end
    end
    self:UpdateDatas(DataList)
end

--[[
    更新邮件附件已领取状态（协议驱动）
]]
function MailModelBase:UpdateMailReceiveAttachFlag(MailUniqIdList)
    if MailUniqIdList == nil then
        return
    end
    local DataList = {}
    for k, v in pairs(MailUniqIdList) do
        local MailData = self:GetData(v)
        if MailData ~= nil then
            MailData.ReceiveAppend = true
            --领取后，同时标记为已读
            -- MailData.ReadFlag = true
            table.insert(DataList, MailData)
        end
    end
    self:UpdateDatas(DataList)
end

--[[
    删除邮件（协议驱动）
]]
function MailModelBase:DeleteMailList(MailUniqIdList)
    if MailUniqIdList == nil then
        return
    end
    self:DeleteDatas(MailUniqIdList)
end

-- 检查邮件是否为调查问卷邮件
function MailModelBase:IsQuestionnaireMail(MailData)
    if not MailData or string.len(MailData.CustomData) <= 0 or tonumber(MailData.CustomData) == nil then
        return false
    end
    return tonumber(MailData.CustomData) > 0
end

function MailModelBase:SortItemTable(List)
    if not List then
        return
    end
    table.sort(List,self.keepSortIndexFunc)
end

function MailModelBase:DeleteInValidQuestionnaireMailByType(PageType)
    local MailList = self:GetDataList()
    local QuestionnaireModel = MvcEntry:GetModel(QuestionnaireModel)
    local List = {}
    for _,Vo in ipairs(MailList) do
        if self:IsQuestionnaireMail(Vo) and QuestionnaireModel:GetDataByID(tonumber(Vo.CustomData)) == nil then
            table.insert(List, Vo.MailUniqId)
        end
    end
    if #List > 0 then
        MvcEntry:GetCtrl(MailCtrl):SendProto_PlayerDeleteMailReq(PageType, List)
    end
end

return MailModelBase;