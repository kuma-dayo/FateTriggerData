---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 临时自建房入口
--- Created At: 2023/05/09 18:07
--- Created By: 朝文
---

local class_name = "CustomRoomEntryMdt"
---@class CustomRoomEntryMdt
local CustomRoomEntryMdt = BaseClass(nil, class_name)

function CustomRoomEntryMdt:OnShow(Param)
end

function CustomRoomEntryMdt:OnHide(Param)
end

function CustomRoomEntryMdt:OnInit()
    self.MsgList = {
        --匹配状态数据
        { Model = MatchModel, MsgName = MatchModel.ON_MATCHING_STATE_CHANGE, Func = Bind(self, self.ON_MATCHING_STATE_CHANGE_func) },--匹配状态变动
        { Model = TeamModel,  MsgName = TeamModel.ON_TEAM_INFO_CHANGED,      Func = Bind(self, self.ON_TEAM_INFO_CHANGED_func) },
    }

    self.BindNodes =
    {
        { UDelegate = self.View.BtnBuildRoom.OnClicked,	Func = Bind(self, self.OnClicked_BuildRoom) }
    }
end

function CustomRoomEntryMdt:UpdateView()
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsSelfInTeam = TeamModel:IsSelfInTeam()

    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local isMatchIdle = MatchModel:GetMatchState() == MatchModel.Enum_MatchState.MatchIdle

    if IsSelfInTeam or not isMatchIdle then
        self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

function CustomRoomEntryMdt:OnClicked_BuildRoom()
    --MvcEntry:OpenView(ViewConst.CustomRoomPanel)
end

function CustomRoomEntryMdt:ON_TEAM_INFO_CHANGED_func()
    self:UpdateView()
end

---匹配状态变动处理
function CustomRoomEntryMdt:ON_MATCHING_STATE_CHANGE_func(Handler, Msg)
    local OldMatchState = Msg.OldMatchState
    local NewMatchState = Msg.NewMatchState

    --1.无匹配状态
    local MatchState = MatchModel.Enum_MatchState
    if NewMatchState == MatchState.MatchIdle then
        --self.View:VX_Hall_CustomRoom_Cancel()
        --2.请求匹配中
    elseif NewMatchState == MatchState.MatchRequesting then
        --doNothing
        --3.匹配中
    elseif NewMatchState == MatchState.Matching then
        --self.View:VX_Hall_CustomRoom_Matching()        
        --4.匹配成功
    elseif NewMatchState == MatchState.MatchSuccess then
        --doNothing
        --5.匹配失败
    elseif NewMatchState == MatchState.MatchFail then
        --doNothing
        --6.匹配取消了
    elseif NewMatchState == MatchState.MatchCanceled then
        --doNothing
    end

    self:UpdateView()
end

return CustomRoomEntryMdt