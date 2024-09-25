--[[
    主界面弹出成员入队/退队 Item列表
]]

local class_name = "TeamNoticeItemListMdt";
TeamNoticeItemListMdt = TeamNoticeItemListMdt or BaseClass(GameMediator, class_name);

function TeamNoticeItemListMdt:__init()
end

function TeamNoticeItemListMdt:OnShow(data)
    
end

function TeamNoticeItemListMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.InputFocus = false
    self.ShowTypeId2Detail ={
        --单人提示Item
        [FriendConst.TEAM_NOTICE_ITEM_TYPE.SINGLE] = {UMGPATH="/Game/BluePrints/UMG/OutsideGame/Friend/Notice/WBP_Hall_PlayerTips.WBP_Hall_PlayerTips",
        LuaClass=require("Client.Modules.Friend.Notice.TeamTipsSingleItem")},
        --多人提示Item
        [FriendConst.TEAM_NOTICE_ITEM_TYPE.MULTI] = {UMGPATH="/Game/BluePrints/UMG/OutsideGame/Friend/Notice/WBP_Hall_TeamTips.WBP_Hall_TeamTips",
        LuaClass=require("Client.Modules.Friend.Notice.TeamTipsMultiItem")},
    }
end

--由mdt触发调用
function M:OnShow(Param)
    if not Param then
        print_trackback()
        MvcEntry:CloseView(self.viewId)
        return
    end
    self:UpdateShowItem(Param)
end

function M:OnRepeatShow(Param)
    if not Param then
        print_trackback()
        return
    end
    -- 追加数据
    self:UpdateShowItem(Param)
end

function M:UpdateShowItem(Param)
    local TypeId = Param.TipsViewType
    local Detail =  self.ShowTypeId2Detail[TypeId]
    if not Detail then
        CError("TeamNoticeItemListMdt:UpdateShowItem Detail nil:" .. TypeId,true)
        return
    end

    -- 每份提示数据都是一个单独的提示item。这里不缓存不复用
    local WidgetClass = UE.UClass.Load(Detail.UMGPATH)
    local Widget = NewObject(WidgetClass, self)
    self.ListBox:AddChild(Widget)
    UIHandler.New(self,Widget,Detail.LuaClass,Param)
end

function M:OnHide()
end

return M