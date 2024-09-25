--[[
    自建房加入，需要进行密码输入
]]
local class_name = "CustomRoomJoinNeedPwdMdt"
---@class CustomRoomJoinNeedPwdMdt : GameMediator
CustomRoomJoinNeedPwdMdt = CustomRoomJoinNeedPwdMdt or BaseClass(GameMediator, class_name)

function CustomRoomJoinNeedPwdMdt:__init()
end

function CustomRoomJoinNeedPwdMdt:OnShow(data) end
function CustomRoomJoinNeedPwdMdt:OnHide() end

--------------------------------------------------------- Base ---------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = {
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_ENTER_NOTIFY,	        Func = self.ON_ROOM_ENTER_NOTIFY_Func },
    }

    -- 注册输入控件处理
    self.PwdPutInst = UIHandler.New(self,self.WBP_InputPassword,require("Client.Modules.Common.CommonInputBoxLogic")
    ,{
        InputWigetName = "NameInput",
        FoucsViewId = ViewConst.CustomRoomJoinNeedPwd,
        -- OnTextChangedFunc = Bind(self,self.OnPwdInputChangedFunc),
        OnTextCommittedEnterFunc = Bind(self,self.OnPwdInputEnterFunc),
    }).ViewInstance

    UIHandler.New(self,self.WBP_CommonBtn_Cancel, WCommonBtnTips, 
    {
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomJoinNeedPwdMdt_cancel"),
        OnItemClick = Bind(self,self.OnCancelClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.Escape,
    })

    UIHandler.New(self,self.WBP_CommonBtn_Join, WCommonBtnTips, 
    {
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomJoinNeedPwdMdt_join"),
        OnItemClick = Bind(self,self.OnJoinClicked),
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.SpaceBar,
    })
    local PopUpBgParam = {
        CloseCb = Bind(self,self.OnCancelClicked),
    }
    self.CommonPopUpWigetLogic = UIHandler.New(self,self.WBP_CommonPopUp_Bg_L,CommonPopUpBgLogic,PopUpBgParam).ViewInstance
end

function M:ON_ROOM_ENTER_NOTIFY_Func()
    self:OnEscClick()
end

--[[
    local Param = {
        RoomId = RoomId,
        RoomInfo = RoomInfo,
    }
    BaseRoomInfoMsg
]]
function M:OnShow(Param)
    self.Param = Param

    self.RoomInfo = self.Param.RoomInfo
    self.RoomId = self.Param.RoomId

    --更新房间名称
    -- self.Text_Title:SetText(self.RoomInfo.CustomRoomName)
    self.CommonPopUpWigetLogic:UpdateTitleText(self.RoomInfo.CustomRoomName)
end
function M:OnHide()
end

function M:OnPwdInputEnterFunc()
    self:CheckPwdValid()
end

function M:CheckPwdValid()
    local InputText = self.PwdPutInst:GetText()
    -- 检测是否纯空格
    local TrimEmptyText = StringUtil.AllTrim(InputText)
    if InputText ~= "" and TrimEmptyText ~= "" then
        local PwdId = tonumber(InputText)
        if not PwdId then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomJoinNeedPwdMdt_Wrongpasswordformat"))
            return false
        else
            if PwdId == 0 then
                PwdId = InputText
            end
            return true,PwdId
        end
    end
    return true,""
end

function M:OnCancelClicked()
    self:OnEscClick()
end

function M:OnEscClick()
    MvcEntry:CloseView(self.viewId)
end

function M:OnJoinClicked()
    local ValidResultPwd,Pwd = self:CheckPwdValid()
    if not ValidResultPwd then
        return
    end
    --请求加入
    MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_JoinRoomReq(self.RoomId,Pwd .. "",Pb_Enum_CUSTOMROOM_JOIN_SRC.JOIN_SRC_NORMAL)
end

return M