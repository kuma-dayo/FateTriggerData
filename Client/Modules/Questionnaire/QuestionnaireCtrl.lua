--[[
    调查问卷协议处理模块
]]
require("Client.Modules.Questionnaire.QuestionnaireModel")
local class_name = "QuestionnaireCtrl"
---@class QuestionnaireCtrl : UserGameController
QuestionnaireCtrl = QuestionnaireCtrl or BaseClass(UserGameController,class_name)


function QuestionnaireCtrl:__init()
    CWaring("==QuestionnaireCtrl init")
    ---@type QuestionnaireModel
	self.QuestionnaireModel = MvcEntry:GetModel(QuestionnaireModel)
end

function QuestionnaireCtrl:Initialize()
end

--[[
    玩家登入
]]
function QuestionnaireCtrl:OnLogin(data)
    CWaring("QuestionnaireCtrl OnLogin")
end


function QuestionnaireCtrl:AddMsgListenersUser()
    self.ProtoList = {
		{MsgName = Pb_Message.QuestionnaireDeliverySync,	Func = self.QuestionnaireDeliverySync_Func },
		{MsgName = Pb_Message.QuestionnairesSync,	Func = self.QuestionnairesSync_Func },
    }
end

--Questionnaire.proto

--[[
	Msg = {
	    string QuestionnaireId = 1;
	}
]]
function QuestionnaireCtrl:QuestionnaireDeliverySync_Func(Msg)
	-- print("QuestionnaireCtrl:QuestionnaireDeliverySync_Func ID is:" .. Msg.QuestionnaireId)
	self.QuestionnaireModel:On_QuestionnaireDeliverySync(Msg)
    self:GetSingleton(CommonCtrl):TryFaceActionOrInCache(Bind(self,self.PopQuestionnaireMdt), function()
		local HallTabType = MvcEntry:GetModel(HallModel):GetCurHallTabType()
		return HallTabType == CommonConst.HL_PLAY
	end)
end

function QuestionnaireCtrl:PopQuestionnaireMdt()
	local ID = self.QuestionnaireModel:GetPopQuestionnaireID()
    local Data = self.QuestionnaireModel:GetDataByID(ID)
	if ID > 0 and Data ~= nil then
		MvcEntry:OpenView(ViewConst.QuestionnairePop, ID)
	end
end

--[[
	Msg = {
	    repeated QuestionnaireInfoBase QuestionnaireInfos = 1;    // 玩家还未填写的问卷Id组
	}
]]
function QuestionnaireCtrl:QuestionnairesSync_Func(Msg)
	print_r(Msg, "QuestionnaireCtrl:QuestionnairesSync_Func")
	self.QuestionnaireModel:On_QuestionnairesSync(Msg)
	MvcEntry:GetModel(ActivityModel):On_QuestionnairesSync(Msg)
	local OldLength = self.QuestionnaireModel:GetOldDataListLength()
	--未完成调查问卷数量有减少
	if OldLength > 0 and OldLength > #Msg.QuestionnaireInfos then
		MvcEntry:GetCtrl(MailCtrl):DeleteInValidQuestionnaireMail()
	end
	self.QuestionnaireModel:SetOldDataListLength(#Msg.QuestionnaireInfos)
	
end
------------------------------------请求相关----------------------------

--[[
	// 客户端已经弹窗后的ACK
    string QuestionnaireId = 1;
]]
function QuestionnaireCtrl:SendProtoQuestionnaireShowAckReq(QuestionnaireId)
	local Msg = {
		QuestionnaireId = QuestionnaireId,
	}
	self:SendProto(Pb_Message.QuestionnaireShowAckReq, Msg)
end


