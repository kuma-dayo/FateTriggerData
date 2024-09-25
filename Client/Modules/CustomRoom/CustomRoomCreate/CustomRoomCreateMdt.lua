--[[
    创建房间弹窗界面
]]
local class_name = "CustomRoomCreateMdt"
CustomRoomCreateMdt = CustomRoomCreateMdt or BaseClass(GameMediator, class_name)

function CustomRoomCreateMdt:__init()
end

function CustomRoomCreateMdt:OnShow(data)
end

function CustomRoomCreateMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = {
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_ENTER_NOTIFY,	        Func = self.ON_ROOM_ENTER_NOTIFY_Func },
    }
    local PopParam = {
        -- TitleStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Createaroom")),
        ContentType = CommonPopUpPanel.ContentType.Content,
        CloseCb = Bind(self,self.OnEscClick),
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
end

function M:OnHide()
end

function M:OnShow()
    local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Room/WBP_Room_RoomCreate.WBP_Room_RoomCreate")
    local Widget = NewObject(WidgetClass, self)
    UIRoot.AddChildToPanel(Widget,self.CommonPopUpPanel:GetContentPanel())

    local Param = {
        CloseCb = Bind(self,self.OnEscClick),
    }
    if self.RoomCommonViewInst == nil then
        self.RoomCommonViewInst = UIHandler.New(self, Widget, require("Client.Modules.CustomRoom.CustomRoomCreate.CustomRoomCreateLogic"), Param).ViewInstance
    else 
        self.RoomCommonViewInst:UpdateUI(Param)
    end
end

function M:ON_ROOM_ENTER_NOTIFY_Func()
    self:OnEscClick()
end

function M:OnCreateClicked()
    if self.RoomCommonViewInst.OnCreateClicked then
        self.RoomCommonViewInst:OnCreateClicked()
    end
end

--点击关闭按钮事件
function M:OnEscClick()
    MvcEntry:CloseView(self.viewId)
end

return M
