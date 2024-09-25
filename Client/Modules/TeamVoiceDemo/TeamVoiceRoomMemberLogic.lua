--[[
    语音房间 玩家逻辑
]]
---@class TeamVoiceRoomMemberLogic
local class_name = "TeamVoiceRoomMemberLogic"
local TeamVoiceRoomMemberLogic = BaseClass(nil, class_name)

function TeamVoiceRoomMemberLogic:OnInit()
    self.BindNodes = 
	{
		{ UDelegate = self.View.BtnSubscribe.OnClicked,				Func = Bind(self,self.OnClicked_BtnSubscribe) },
		{ UDelegate = self.View.BtnUnSubscribe.OnClicked,				Func = Bind(self,self.OnClicked_BtnUnSubscribe) },
	}

    self.MsgList =
    {
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_ROOM_USER_LIST_CHANGE, Func = self.UpdateSubscribeStateShow},
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_ROOM_USER_SUBSCRIBE_STATE_CHANGE, Func = self.UpdateSubscribeStateShow},
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_ROOM_USER_PUBLISH_STATE_CHANGE, Func = self.UpdateSubscribeStateShow},
    }
end

--[[
   local Param = {
        RoomId = self.RoomId,
        UserIdStr = UserIdStr
    }
]]
function TeamVoiceRoomMemberLogic:OnShow(Param)
    self.RoomId = Param.RoomId
    self.UserIdStr = Param.UserIdStr
    self.View.LbUserId:SetText(self.UserIdStr)
    self.RoomName = MvcEntry:GetModel(GVoiceModel):GetRoomNameByRoomId(self.RoomId)
    self.MemberId = MvcEntry:GetModel(GVoiceModel):GetUserMemberId(self.RoomName,self.UserIdStr)
    self.View.LbMemberId:SetText(self.MemberId)
    self:UpdateSubscribeStateShow()
end

function TeamVoiceRoomMemberLogic:OnHide()
end

--[[
    更新是否订阅显示
]]
function TeamVoiceRoomMemberLogic:UpdateSubscribeStateShow()
    if not self.RoomName then
        return
    end
    local TheInRoomValue = MvcEntry:GetModel(GVoiceModel):IsUserIdInRoom(self.RoomName,self.UserIdStr)
    self.View.LbIsInRoom:SetText(TheInRoomValue and G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3031") or G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3032"))

    local TheBValue = MvcEntry:GetModel(GVoiceModel):GetUserPublishState(self.RoomName,self.UserIdStr)
    self.View.LbPublishState:SetText(TheBValue and G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3031") or G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3032"))

    local SelfPlayerIdStr = MvcEntry:GetModel(UserModel):GetPlayerIdStr()
    local TheBValueSub = self.UserIdStr ~= SelfPlayerIdStr and MvcEntry:GetModel(GVoiceModel):GetUserSubscribeState(self.RoomName,self.UserIdStr)
    self.View.LbSubscribeState:SetText(TheBValueSub and G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3031") or G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3032"))

    self.View.BtnSubscribe:SetVisibility((not TheBValueSub) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.BtnUnSubscribe:SetVisibility((TheBValueSub) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function TeamVoiceRoomMemberLogic:OnClicked_BtnSubscribe()
    if self.MemberId then
        MvcEntry:GetCtrl(GVoiceCtrl):ForbidMemberVoice(self.RoomName,self.MemberId,false)
    end
end

function TeamVoiceRoomMemberLogic:OnClicked_BtnUnSubscribe()
    if self.MemberId then
        MvcEntry:GetCtrl(GVoiceCtrl):ForbidMemberVoice(self.RoomName,self.MemberId,true)
    end
end

function TeamVoiceRoomMemberLogic:ON_ROOM_USER_SUBSCRIBE_STATE_CHANGE()
    self:UpdateSubscribeStateShow();
end

return TeamVoiceRoomMemberLogic
