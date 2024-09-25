
require("Client.Modules.Notice.NoticeModel");

local class_name = "NoticeCtrl";
---@class NoticeCtrl : UserGameController
---@field private super UserGameController
---@field private model NoticeModel
NoticeCtrl = NoticeCtrl or BaseClass(UserGameController, class_name);

function NoticeCtrl:__init()
    CWaring("==NoticeCtrl init")
    self.Model = nil
    self:CleanAutoCheckTimer()
end

function NoticeCtrl:Initialize()
    self.Model = self:GetModel(NoticeModel)
end

--- 玩家登出
---@param data any
function NoticeCtrl:OnLogout(data)
    CWaring("NoticeCtrl OnLogout")
    self:CleanAutoCheckTimer()
end

function NoticeCtrl:CleanAutoCheckTimer()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

function NoticeCtrl:AddMsgListenersUser()
    -- self.ProtoList = {
    --     {MsgName = Pb_Message.NoticeListSync, Func = self.OnNoticeListSync}
    -- }
    -- self.MsgList = {
    --     { Model = HallModel,    MsgName = HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,	Func = self.TriggerShow },
    -- }
end

function NoticeCtrl:OnNoticeListSync(Msg)
    if not Msg then
        return
    end
    print_r(Msg)
    self.Model:InitNoticeList(Msg.NoticeList)

    self:GetSingleton(CommonCtrl):TryFaceActionOrInCache(Bind(self,self.TriggerShow))
end

function NoticeCtrl:TriggerShow()
    -- if not IsVisible then
    --     return
    -- end
    self:CleanAutoCheckTimer()
    print("NoticeCtrl:TriggerShow=====1")
    local IsUnLock = MvcEntry:GetModel(NewSystemUnlockModel):IsSystemUnlock(ViewConst.Notice, false)
    if not IsUnLock then
        return
    end

    local TitleTabDataList = self.Model:GetTabDataList()
    if not TitleTabDataList or #TitleTabDataList == 0 then
        return
    end

    local LastTimeStamp = SaveGame.GetItem("LastTriggerOnDay")
    local NowTimeStamp = GetTimestamp()

    if LastTimeStamp and NowTimeStamp - LastTimeStamp < 0 then
        return
    end
    print("NoticeCtrl:TriggerShow=====2")
    local DelayTime = CommonUtil.GetParameterConfig(ParameterConfig.FirstShowNoticeDelayMS, 1000)/1000
    self.CheckTimer = Timer.InsertTimer(DelayTime,function()
        SaveGame.SetItem("LastTriggerOnDay", TimeUtils.GetOffsetDayZeroTime(NowTimeStamp, 1))
        MvcEntry:OpenView(ViewConst.Notice)
        self:CleanAutoCheckTimer()
	end)
end