--[[
    自建房
]]
local class_name = "CustomRoomMdt"
---@class CustomRoomMdt : GameMediator
CustomRoomMdt = CustomRoomMdt or BaseClass(GameMediator, class_name)

--[[
    展示模式
]]
CustomRoomMdt.ShowTypeEnum = {
    --房间列表
    ROOM_LIST = 1,
    --房间详情
    ROOM_DETAIL = 2,
}

function CustomRoomMdt:__init()
end

function CustomRoomMdt:OnShow(data) end
function CustomRoomMdt:OnHide() end

--------------------------------------------------------- Base ---------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.CurTabId = CustomRoomMdt.ShowTypeEnum.ROOM_LIST
    self.MsgList = 
    {
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_ENTER_NOTIFY, Func = self.ON_ROOM_ENTER_NOTIFY },
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_EXIT_NOTIFY, Func = self.ON_ROOM_EXIT_NOTIFY },
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_NAME_CHANGE, Func = self.ON_ROOM_NAME_CHANGE },
	}
    self.TheRoomModel = MvcEntry:GetModel(CustomRoomModel)

    self.TabTypeId2Vo ={
        [CustomRoomMdt.ShowTypeEnum.ROOM_LIST] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Room/WBP_Room_RoomList.WBP_Room_RoomList",
            LuaClass=require("Client.Modules.CustomRoom.CustomRoomList.CustomRoomListLogic"),
        },
        [CustomRoomMdt.ShowTypeEnum.ROOM_DETAIL] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Room/WBP_Room_RankList.WBP_Room_RankList",
            LuaClass=require("Client.Modules.CustomRoom.CustomRoomDetail.CustomRoomDetailLogic"),
        },
    }

	local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomMdt_Customroom"),
    }
    self.CommonTabUpBarInstance = UIHandler.New(self,self.WBP_Common_TabUpBar_02,CommonTabUpBar,CommonTabUpBarParam).ViewInstance

    UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
    })
end

function M:OnShow(Param)
    self:UpdateUI()
end
function M:OnHide()
end

function M:UpdateUI()
    self:CalculateCurShowType();

    self:UpdateContentShow();
    self:UpdateBaseShow()
end

function M:CalculateCurShowType()
    self.CurTabId = CustomRoomMdt.ShowTypeEnum.ROOM_LIST
    local EnterRoomInfo = self.TheRoomModel:GetCurEnteredRoomInfo()
    if EnterRoomInfo then
        self.CurTabId = CustomRoomMdt.ShowTypeEnum.ROOM_DETAIL
    end

    --TODO Fix 涉及到自建房界面切换，需要主动将头像操作界面进行关闭
    MvcEntry:CloseView(ViewConst.CommonPlayerInfoHoverTip)
end

function M:UpdateContentShow()
    local VoItem = self.TabTypeId2Vo[self.CurTabId]
    if not VoItem then
        CError("CustomRoomMdt:UpdateTabShow() VoItem nil")
        return
    end
    local IsFromCache = true
    if not VoItem.ViewItem then
        local WidgetClassPath = VoItem.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget,self.Content)
        local ViewItem = UIHandler.New(self,Widget,VoItem.LuaClass).ViewInstance
        VoItem.ViewItem = ViewItem
        VoItem.View = Widget

        IsFromCache = false
    end

    for TheTabId,TheVo in pairs(self.TabTypeId2Vo) do
        local TheShow = false
        if TheTabId == self.CurTabId then
            TheShow = true
        end
        if CommonUtil.IsValid(TheVo.View) then
            TheVo.View:SetVisibility(TheShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
        if not TheShow and TheVo.ViewItem then
            TheVo.ViewItem:OnHide()
        end
    end
    if IsFromCache then
        VoItem.ViewItem:OnShow(nil,true)
    end
end

function M:UpdateBaseShow()
    if self.CurTabId == CustomRoomMdt.ShowTypeEnum.ROOM_LIST then
        self.CommonTabUpBarInstance:UpdateTitleText(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomMdt_Customroom"))
    else
        local EnterRoomInfo = self.TheRoomModel:GetCurEnteredRoomInfo()
        self.CommonTabUpBarInstance:UpdateTitleText(EnterRoomInfo.BaseRoomInfo.CustomRoomName)
    end
end

--[[
    玩家进入房间
]]
function M:ON_ROOM_ENTER_NOTIFY()
    self:UpdateUI()
end
--[[
    玩家进入房间
]]
function M:ON_ROOM_EXIT_NOTIFY()
    self:UpdateUI()
end

--[[
    房间名称修改
]]
function M:ON_ROOM_NAME_CHANGE()
    self:UpdateBaseShow()
end


function M:OnEscClicked()
    if self.CurTabId == CustomRoomMdt.ShowTypeEnum.ROOM_LIST then
        MvcEntry:CloseView(self.viewId)
    else
        --请求退出房间
        local SelfUserId = MvcEntry:GetModel(UserModel):GetPlayerId()
        local RoomCount = self.TheRoomModel:GetCurEnterRoomPlayerNum()
        if self.TheRoomModel:IsMaster(SelfUserId) and RoomCount >=2 then
            local msgParam = {
                describe = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomMdt_Afterquittingtheowne"),
                leftBtnInfo = {},
                rightBtnInfo = {
                    callback = function()
                        --请求退出房间
                        local EnterRoomInfo = self.TheRoomModel:GetCurEnteredRoomInfo()
                        MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_ExitRoomReq(EnterRoomInfo.BaseRoomInfo.CustomRoomId)
                    end
                }
            }
            UIMessageBox.Show(msgParam)
        else
            --请求退出房间
            local EnterRoomInfo = self.TheRoomModel:GetCurEnteredRoomInfo()
            MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_ExitRoomReq(EnterRoomInfo.BaseRoomInfo.CustomRoomId)
        end
    end
end


return M