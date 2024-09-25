
local class_name = "TeamVoiceDemoMdt"
TeamVoiceDemoMdt = TeamVoiceDemoMdt or BaseClass(GameMediator, class_name)


function TeamVoiceDemoMdt:__init()
end

function TeamVoiceDemoMdt:OnShow(data)
end

function TeamVoiceDemoMdt:OnHide()
end

-------------------------------------------------------------------------------

---@class TeamVoiceDemoMdtLua
local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
	self.BindNodes = 
	{
		{ UDelegate = self.BtnJoinRoom.OnClicked,				Func = self.OnClicked_BtnJoinRoom },
        { UDelegate = self.BtnReqToken.OnClicked,				Func = self.OnClicked_BtnReqToken },
        { UDelegate = self.BtnExit.OnClicked,				Func = self.OnClicked_BtnExit },
        { UDelegate = self.GUIButton_UpdateCoordinate.OnClicked,				Func = self.OnClicked_GUIButton_UpdateCoordinate },
	}
    self.MsgList =
    {

        {Model = GVoiceModel, MsgName = GVoiceModel.ON_ROOM_ROOMNAME_UPDATE, Func = self.ON_ROOM_TOKEN_UPDATE},
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_JOIN_ROOM_SUCCESS, Func = self.ON_JOIN_ROOM_SUCCESS},
    }
  
end

function M:OnShow(Param)
    local SelfUserId = MvcEntry:GetModel(UserModel):GetPlayerIdStr()
    self.LbPlayerId:SetText(SelfUserId)
    self:UpdateMicTest()
    self:UpdateTokenShow()
    self:UpdateTeamList()
end
function M:OnHide(Param)
    
end

function M:UpdateMicTest()
    local TheBValue = MvcEntry:GetCtrl(GVoiceCtrl):TestMic()
    self.LbMicroWarning:SetVisibility((not TheBValue) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function M:ON_ROOM_TOKEN_UPDATE(Param)
    self:UpdateTokenShow()
end

function M:UpdateTokenShow()
    local Token = MvcEntry:GetModel(GVoiceModel):GetRoomNameByRoomId(self.RoomId)
    local TheBValue = (Token ~= nil)
    self.RoomName = Token
    self.LbTokenShow:SetText(TheBValue and Token or G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3027"))
    self.BtnReqToken:SetVisibility((not TheBValue) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function M:CheckTokenValid(RoomId)
    local Token = MvcEntry:GetModel(GVoiceModel):GetRoomNameByRoomId(RoomId)
    if not Token then
        UIAlert.Show(G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3029"))
        return false
    end
    return true
end

function M:UpdateTeamList()
    self.RoomContent:ClearChildren()
    for k, v in ipairs(GVoiceModel.TestRoomId) do
        CWaring("UpdateTeamList Create Room " .. v)
        local RoomId = v

        local WidgetClassPath = "/Game/BluePrints/UMG/OutsideGame/TeamVoice/WBP_TeamVoiceRoom.WBP_TeamVoiceRoom"
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget,self.RoomContent)
        Widget.Slot.Padding.Right = 940
        Widget.Slot:SetPadding(Widget.Slot.Padding)
        local Param = {
            RoomId = RoomId
        }
        local ViewItem = UIHandler.New(self,Widget,require("Client.Modules.TeamVoiceDemo.TeamVoiceRoomLogic"),Param).ViewInstance
    end
end

function M:CheckAndReturnCurrentRoomId()
    local CurRoomId = self.LbRoomId:GetText()
    if string.len(CurRoomId) <= 0 then
        UIAlert.Show(G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3028"))
        return 
    end
    local ValidRoomId = false
    for k,v in ipairs(GVoiceModel.TestRoomId) do
        if v == CurRoomId then
            ValidRoomId = true
            break
        end
    end
    if not ValidRoomId then
        UIAlert.Show(G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3028"))
        return
    end
    return CurRoomId
end

--[[
    点击创建房间
]]
function M:OnClicked_BtnJoinRoom()
    local RoomId = self:CheckAndReturnCurrentRoomId()
    if not RoomId then
        return
    end
    if not self:CheckTokenValid(RoomId) then
        return
    end
    local SelfUserId = MvcEntry:GetModel(UserModel):GetPlayerIdStr()
    local Token = MvcEntry:GetModel(GVoiceModel):GetRoomNameByRoomId(RoomId)
    if not Token then
        UIAlert.Show(G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3027"))
        return
    end
    
    local TheIsInRoom = MvcEntry:GetModel(GVoiceModel):IsUserIdInRoom(Token,SelfUserId)
    if TheIsInRoom then
        UIAlert.Show(G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3030"))
        return
    end
    if self.CheckBox_IsRange:IsChecked() then
        MvcEntry:GetCtrl(GVoiceCtrl):JoinRangeRoom(Token)
    else
        MvcEntry:GetCtrl(GVoiceCtrl):JoinTeamRoom(Token)
    end
end

function M:UpdateCurRangeCoordinate()
    local X = tonumber(self.EditableText_X:GetText())
    local Y = tonumber(self.EditableText_Y:GetText())
    local Z = tonumber(self.EditableText_Z:GetText())
    local R = tonumber(self.EditableText_R:GetText())
    if self.RoomName and self.CheckBox_IsRange:IsChecked() and X and Y and Z and R then
        MvcEntry:GetCtrl(GVoiceCtrl):UpdateCoordinate(self.RoomName,X,Y,Z,R)
    end
end

function M:ON_JOIN_ROOM_SUCCESS()
    if self.CheckBox_IsRange:IsChecked() then
        self:UpdateCurRangeCoordinate()
    end
end

--[[
    点击申请Token
]]
function M:OnClicked_BtnReqToken()
    local RoomId = self:CheckAndReturnCurrentRoomId()
    if not RoomId then
        return
    end
    self.RoomId = RoomId
    MvcEntry:GetCtrl(GVoiceCtrl):SendProto_GetRtcTokenReq(tonumber(RoomId))
end

function M:OnClicked_GUIButton_UpdateCoordinate()
    self:UpdateCurRangeCoordinate()
end

function M:OnClicked_BtnExit()
    MvcEntry:GetCtrl(GVoiceCtrl):LeaveAllRoom()
    MvcEntry:CloseView(self.viewId)
end

return M