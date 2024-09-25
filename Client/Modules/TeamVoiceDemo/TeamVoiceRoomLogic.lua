--[[
    语音房间逻辑
]]
---@class TeamVoiceRoomLogic
local class_name = "TeamVoiceRoomLogic"
local TeamVoiceRoomLogic = BaseClass(nil, class_name)

function TeamVoiceRoomLogic:OnInit()
    self.BindNodes = 
	{
		{ UDelegate = self.View.BtnPublish.OnClicked,				Func = Bind(self,self.OnClicked_BtnPublish) },
		{ UDelegate = self.View.BtnUnPublish.OnClicked,				Func = Bind(self,self.OnClicked_BtnUnPublish) },
        { UDelegate = self.View.BtnOpenSpeaker.OnClicked,				Func = Bind(self,self.OnClicked_BtnOpenSpeaker) },
        { UDelegate = self.View.BtnCloseSpeaker.OnClicked,				Func = Bind(self,self.OnClicked_BtnCloseSpeaker) },
        { UDelegate = self.View.BtnLeaveRoom.OnClicked,				Func = Bind(self,self.OnClicked_BtnLeaveRoom)   },
	}

    self.MsgList =
    {
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_ROOM_USER_LIST_CHANGE, Func = self.ON_ROOM_USER_LIST_CHANGE},
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_ROOM_ROOMNAME_UPDATE, Func = self.ON_ROOM_TOKEN_UPDATE},
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_ROOM_USER_PUBLISH_STATE_CHANGE, Func = self.UpdateSelfPublishState},
    }
end


--[[
    local Param = {
        RoomId = RoomId
    }
]]
function TeamVoiceRoomLogic:OnShow(Param)
    self.RoomId = Param.RoomId
    self:UpdateSelfPublishState()
    self:UpdateSelfSpeakerState(false)
    self.UserId2Handler = {}
    self:ON_ROOM_USER_LIST_CHANGE()
end

function TeamVoiceRoomLogic:ON_ROOM_TOKEN_UPDATE()
    self.RoomName = MvcEntry:GetModel(GVoiceModel):GetRoomNameByRoomId(self.RoomId)
end

function TeamVoiceRoomLogic:OnHide()
    CWaring("TeamVoiceRoomLogic:OnHide")
end

function TeamVoiceRoomLogic:AddRoomMember(UserIdStr)
    local WidgetClassPath = "/Game/BluePrints/UMG/OutsideGame/TeamVoice/WBP_TeamVoiceRoomItem.WBP_TeamVoiceRoomItem"
    local WidgetClass = UE.UClass.Load(WidgetClassPath)
    local Widget = NewObject(WidgetClass, self.View)
    UIRoot.AddChildToPanel(Widget,self.View.VerticalContent)
    local Param = {
        RoomId = self.RoomId,
        UserIdStr = UserIdStr
    }
    local ViewItem = UIHandler.New(self,Widget,require("Client.Modules.TeamVoiceDemo.TeamVoiceRoomMemberLogic"),Param).ViewInstance

    self.UserId2Handler[UserIdStr] = ViewItem
end

function TeamVoiceRoomLogic:UpdateSelfPublishState(Param)
    if not self.RoomName then
        return
    end
    local PlayerIdStr = MvcEntry:GetModel(UserModel):GetPlayerIdStr()
    local TheBValue
    if not Param then
        TheBValue = MvcEntry:GetModel(GVoiceModel):GetUserPublishState(self.RoomName,PlayerIdStr)
    else
        if Param.RoomName ~= self.RoomName or Param.UserId ~= PlayerIdStr then
            return
        end
        TheBValue = Param.IsMicOpen
    end
    print("UpdateSelfPublishState "..(TheBValue and "true" or "false"))
    self.View.BtnPublish:SetVisibility((not TheBValue) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.BtnUnPublish:SetVisibility((TheBValue) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.LbSelfPublishState:SetText(TheBValue and G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3031") or G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3032"))
end

function TeamVoiceRoomLogic:UpdateSelfSpeakerState(IsSpeakerOpen)
    self.View.LbSelfSpeakerState:SetText(IsSpeakerOpen and G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3031") or G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3032"))
    self.View.BtnOpenSpeaker:SetVisibility((not IsSpeakerOpen) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.BtnCloseSpeaker:SetVisibility((IsSpeakerOpen) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function TeamVoiceRoomLogic:OnClicked_BtnPublish()
    if not MvcEntry:GetCtrl(GVoiceCtrl):TestMic() then
        UIAlert.Show(G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3002"))
        return
    end
    MvcEntry:GetCtrl(GVoiceCtrl):EnableRoomMicrophone(self.RoomName,true)
end

function TeamVoiceRoomLogic:OnClicked_BtnUnPublish()
    if not MvcEntry:GetCtrl(GVoiceCtrl):TestMic() then
        UIAlert.Show(G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3002"))
        return
    end
    MvcEntry:GetCtrl(GVoiceCtrl):EnableRoomMicrophone(self.RoomName,false)
end

function TeamVoiceRoomLogic:OnClicked_BtnOpenSpeaker()
    MvcEntry:GetCtrl(GVoiceCtrl):EnableRoomSpeaker(self.RoomName,true)
end

function TeamVoiceRoomLogic:OnClicked_BtnCloseSpeaker()
    MvcEntry:GetCtrl(GVoiceCtrl):EnableRoomSpeaker(self.RoomName,false)
end

function TeamVoiceRoomLogic:ON_ROOM_USER_LIST_CHANGE()
    if not self.RoomName then
        self.View.NContent:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    local SelfPlayerIdStr = MvcEntry:GetModel(UserModel):GetPlayerIdStr()
    local UserIdList = MvcEntry:GetModel(GVoiceModel):GetRoomUserList(self.RoomName)
    for k,v in pairs(UserIdList) do
        if v then
            if not self.UserId2Handler[k] and k ~= SelfPlayerIdStr then
                self:AddRoomMember(k)
            end
        end
    end
    
    local TheIsInRoom = MvcEntry:GetModel(GVoiceModel):IsUserIdInRoom(self.RoomName,SelfPlayerIdStr)
    self.View.NContent:SetVisibility(TheIsInRoom and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--[[
    点击离开房间
]]
function TeamVoiceRoomLogic:OnClicked_BtnLeaveRoom()
    if not self.RoomName then
        return
    end
    MvcEntry:GetCtrl(GVoiceCtrl):QuitRoom(self.RoomName)
end

return TeamVoiceRoomLogic
