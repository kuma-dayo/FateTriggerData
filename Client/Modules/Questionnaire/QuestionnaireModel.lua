--[[
    调查问卷数据模型
]]
local QuestionnaireInfoData = require("Client.Modules.Questionnaire.QuestionnaireInfoData")
local super = ListModel;
local class_name = "QuestionnaireModel";

---@class QuestionnaireModel : ListModel
---@field private super ListModel
QuestionnaireModel = BaseClass(super, class_name)

QuestionnaireModel.QUESTIONNAIRE_MAIN_PANEL_TAB_SELECT = "QUESTIONNAIRE_MAIN_PANEL_TAB_SELECT"
QuestionnaireModel.QUESTIONNAIRE_LIST_INFO_CHANGED = "QUESTIONNAIRE_LIST_INFO_CHANGED"

function QuestionnaireModel:__init()
    self:_dataInit()
end

function QuestionnaireModel:_dataInit()
    --未完成的调查问卷数据列表
    self.QuestionnaireInfoList = {}
    --需要弹脸的弹窗的问卷ID
    self.PopQuestionnaireIDList = {}
    --问卷ID对应未完成的调查问卷数据列表
    self.ID2QuestionnaireInfoList = {}
    --旧的未完成的调查问卷数据列表长度
    self.OldDataListLength = 0
end

function QuestionnaireModel:OnLogin(data)
end

function QuestionnaireModel:OnLogout(data)
    QuestionnaireModel.super.OnLogout(self)
    self:_dataInit()
end

-------- 对外接口 -----------

--[[
    获取可展示的问卷调查并排序
    排序规则：1、若有传ID值，则将对应ID排在最前2、结束时间少于24小时则排前（且存在多个少于24小时的时间越短越靠前）3、配置中的sort降序排序
    可展示规则：1、未过期2、未完成
]]
---@param ID number|nil 
function QuestionnaireModel:GetQuestionnaireCanShowCfgList(ID)
    local FirstID = ID ~= nil and ID or ""
    local List = {}
    ---@type QuestionnaireInfoData
    for _,v in pairs(self.QuestionnaireInfoList) do
        if not self:ChceckQuestionnaireIsOutOfDate(v.StartTimeTimestamp, v.EndTimeTimestamp) then
            table.insert(List, v);
        end
    end
    local OneDaySecond = 60 * 60 * 24
    table.sort(List, function(a, b)
        local FirstA = FirstID == a.ID and 1 or 0
        local FirstB = FirstID == b.ID and 1 or 0
        if FirstA ~= FirstB then
            return FirstA > FirstB
        end
        local timeA = a.EndTimeTimestamp - GetTimestamp() <= OneDaySecond and 1 or 0
        local timeB = b.EndTimeTimestamp - GetTimestamp() <= OneDaySecond and 1 or 0
        if timeA == 1 and timeB == 0 then
            return true
        elseif timeA == 0 and timeB == 1 then
            return false
        elseif timeA == 1 and timeB == 1 and a.EndTimeTimestamp ~= b.EndTimeTimestamp then
            return a.EndTimeTimestamp < b.EndTimeTimestamp
        else
            return a.Sort > b.Sort
        end
    end)
    return List
end

--检查问卷调查是否已完成
---@param ID number
function QuestionnaireModel:ChceckQuestionnaireIsFinish(ID)
    local st = false
    ---@type QuestionnaireInfoData
    for _,v in pairs(self.QuestionnaireInfoList) do
        if ID == v.ID then
            st = false
            break
        end
    end
    return st
end

--通过服务器id获取对应问卷平台回调id
---@param ZoneIdList
function QuestionnaireModel:GetCallBackIdByZoneIdList(ZoneIdList)
    local CallBackId = 1
    local ZoneId = MvcEntry:GetModel(UserModel).ZoneID
    if ZoneIdList == nil or #ZoneIdList == 0 then
        CError("QuestionnaireModel:GetCallBackIdByZoneIdList ZoneIdList is nil")
        return CallBackId
    end
    for i, v in pairs(ZoneIdList) do
        if ZoneId == v then
            CallBackId = i
            break
        end
    end
    return CallBackId
end

--[[
    检查问卷调查是否已过期
    StartTime 开始时间戳
    EndTime 结束时间戳
]]
---@param StartTime number
---@param EndTime number
function QuestionnaireModel:ChceckQuestionnaireIsOutOfDate(StartTime, EndTime)
    local CurTime = GetTimestamp()
    
    return StartTime > CurTime or EndTime < CurTime
end

--获取需要弹窗的问卷ID 字符串长度大于0则需要弹窗
function QuestionnaireModel:GetPopQuestionnaireID()
    local ID = table.remove(self.PopQuestionnaireIDList, 1)
    return ID ~= nil and ID or 0
end

--根据问卷ID获取对应数据信息
---@param ID number
---@return QuestionnaireInfoData
function QuestionnaireModel:GetDataByID(ID)
    return self.ID2QuestionnaireInfoList[ID]
end

function QuestionnaireModel:SetOldDataListLength(Num)
    self.OldDataListLength = Num
end

--获取为旧未完成问卷数据列表长度
function QuestionnaireModel:GetOldDataListLength()
    return self.OldDataListLength or 0
end

-------- 协议数据处理接口 -----------

--[[
	Msg = {
	    int64 QuestionnaireId = 1;
	}
]]
function QuestionnaireModel:On_QuestionnaireDeliverySync(Msg)
    table.insert(self.PopQuestionnaireIDList, Msg.QuestionnaireId)
end

--[[
	Msg = {
	    repeated QuestionnaireInfoBase QuestionnaireInfos = 1;    // 玩家还未填写的问卷Id组
	}
]]
function QuestionnaireModel:On_QuestionnairesSync(Msg)
    self.QuestionnaireInfoList = {}
    self.ID2QuestionnaireInfoList = {}
    for _,v in pairs(Msg.QuestionnaireInfos) do
        ---@type QuestionnaireInfoData
        local Data = PoolManager.GetInstance(QuestionnaireInfoData)
        Data:InitFromCfgId(v)
        table.insert(self.QuestionnaireInfoList, Data)
        self.ID2QuestionnaireInfoList[Data.ID] = Data
    end
    self:DispatchType(QuestionnaireModel.QUESTIONNAIRE_LIST_INFO_CHANGED)
end
