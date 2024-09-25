--[[
    主界面弹出好友/组队申请Item列表
]]

local class_name = "FriendRequestItemListMdt";
FriendRequestItemListMdt = FriendRequestItemListMdt or BaseClass(GameMediator, class_name);

function FriendRequestItemListMdt:__init()
end

function FriendRequestItemListMdt:OnShow(data)
    
end

function FriendRequestItemListMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.InputFocus = false
    self.ShowTypeId2Detail ={
        --邀请入队Item
        [FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST] = {UMGPATH="/Game/BluePrints/UMG/OutsideGame/Friend/Notice/WBP_FriendNoticeInvite.WBP_FriendNoticeInvite",
        LuaClass=require("Client.Modules.Friend.Notice.FriendNoticeInviteItem")},
        --申请入队Item
        [FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST] = {UMGPATH="/Game/BluePrints/UMG/OutsideGame/Friend/Notice/WBP_FriendNoticeInvite.WBP_FriendNoticeInvite",
        LuaClass=require("Client.Modules.Friend.Notice.FriendNoticeInviteItem")},
        --申请合并队伍item
        [FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST] = {UMGPATH="/Game/BluePrints/UMG/OutsideGame/Friend/Notice/WBP_FriendNoticeInvite.WBP_FriendNoticeInvite",
        LuaClass=require("Client.Modules.Friend.Notice.FriendNoticeInviteItem")},
        --好友申请Item
        [FriendConst.LIST_TYPE_ENUM.FRIEND_REQUEST] = {UMGPATH="/Game/BluePrints/UMG/OutsideGame/Friend/Notice/WBP_FriendNoticeRequest.WBP_FriendNoticeRequest", 
        LuaClass = require("Client.Modules.Friend.Notice.FriendNoticeRequestItem")},
    }
    self.MsgList = 
    {
        {Model = FriendModel, MsgName = FriendModel.ON_HIDE_HALL_TIPS, Func = self.OnHideTips},
	}

    self.TypeId2ItemCls = {}
end

--由mdt触发调用
function M:OnShow(List)
    if not List or #List == 0 then
        print_trackback()
        MvcEntry:CloseView(self.viewId)
        return
    end
    self:UpdateShowList(List)
end

function M:OnRepeatShow(List)
    if not List or #List == 0 then
        print_trackback()
        return
    end
    -- 追加数据
    self:UpdateShowList(List)
end

function M:UpdateShowList(List)
    SoundMgr:PlaySound(SoundCfg.SoundEffects.PATERNER_CALL)
    for _,Param in ipairs(List) do
        local TypeId = Param.TypeId
        if not self.TypeId2ItemCls[TypeId] then
            local Detail =  self.ShowTypeId2Detail[TypeId]
            if Detail then
                local WidgetClass = UE.UClass.Load(Detail.UMGPATH)
                local Widget = NewObject(WidgetClass, self)
                self.ListBox:AddChild(Widget)
            
                -- Widget.Slot.Padding.Top = 10
                -- Widget.Slot:SetPadding(Widget.Slot.Padding)
            
                local Item = UIHandler.New(self,Widget,Detail.LuaClass,Param).ViewInstance
                if Item then
                    self.TypeId2ItemCls[TypeId] = Item
                else
                    CError("FriendRequestItemListMdt:UpdateShowList Item nil")
                end
            else
                CError("FriendRequestItemListMdt:UpdateShowList Detail nil:" .. TypeId,true)
            end
        else
            self.TypeId2ItemCls[TypeId]:OnRepeatShow(Param)
        end
    end
end

function M:OnHideTips(TypeId)
    if self.TypeId2ItemCls[TypeId] then
        self.TypeId2ItemCls[TypeId].View:RemoveFromParent()
        self.TypeId2ItemCls[TypeId] = nil
    end
    -- if #self.TypeId2ItemCls == 0 then
    if table_isEmpty(self.TypeId2ItemCls) then
        MvcEntry:CloseView(self.viewId)
    end
end

function M:OnHide()
end

return M