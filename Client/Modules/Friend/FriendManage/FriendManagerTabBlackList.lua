--[[
    好友管理 - 页签 - 黑名单
]]

local class_name = "FriendManagerTabBlackList"
local FriendManagerTabBlackList = BaseClass(UIHandlerViewBase, class_name)


function FriendManagerTabBlackList:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    ---@type FriendModel
    self.FriendModel = MvcEntry:GetModel(FriendModel)
    ---@type FriendBlackListModel
    self.FriendBlackListModel = MvcEntry:GetModel(FriendBlackListModel)
    self.MsgList = 
    {
        {Model = FriendBlackListModel, MsgName = FriendBlackListModel.ON_BLACKLIST_CHANGED, Func = Bind(self,self.UpdateBlackList)},
    }
    self.BindNodes = {
		{ UDelegate = self.View.WBP_ReuseList_BlackList.OnUpdateItem,				Func = Bind(self,self.OnUpdateItem) },
    }
end

function FriendManagerTabBlackList:OnShow()
    
end
function FriendManagerTabBlackList:OnManualShow()
    self:UpdateBlackList()
end

function FriendManagerTabBlackList:OnHide()
end

-- function FriendManagerTabBlackList:OnCustomShow()
--     if self.Widget2ItemCls then
--         for Widget,ItemCls in pairs(self.Widget2ItemCls) do
--             if CommonUtil.IsValid(Widget) and ItemCls.OnCustomShow then
--                 ItemCls:OnCustomShow()
--             end
--         end
--     end
--     if self.IsHide then 
--         if self.MsgList then
--             CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,true)
--         end
--         if self.SubClassList then
--             for _,Btn in ipairs(self.SubClassList) do
--                 CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,true)
--             end
--         end
--         self.IsHide = false
--     end
--     self:UpdateBlackList()
-- end

-- function FriendManagerTabBlackList:OnCustomHide()
--     if self.Widget2ItemCls then
--         for Widget,ItemCls in pairs(self.Widget2ItemCls) do
--             if CommonUtil.IsValid(Widget) and ItemCls.OnCustomHide then
--                 ItemCls:OnCustomHide()
--             end
--         end
--     end
--     if self.MsgList then
--         CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,false)
--     end
--     if self.SubClassList then
--         for _,Btn in ipairs(self.SubClassList) do
-- 		    CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,false)
--         end
--     end
--     self.IsHide = true
-- end

function FriendManagerTabBlackList:UpdateUI()
    self.Widget2ItemCls = {}
    self.Index2Widget = {}
    self:UpdateBlackList()
end

-- 更新黑名单列表显示
function FriendManagerTabBlackList:UpdateBlackList()
    local BlackList,BlackList2PlayerId = self.FriendBlackListModel:GetBlackList()
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendGetPlayerListBaseInfoReq(BlackList2PlayerId)
    self.BlackList = BlackList
    local TotalNum = #self.BlackList
    if TotalNum > 0 then
        self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.BlackListContent)
        self.View.GUITextBlock_Num:SetText(TotalNum)
        self.View.WBP_ReuseList_BlackList:Reload(TotalNum)
    else
        self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.EmptyContent)
    end
end

function FriendManagerTabBlackList:OnUpdateItem(_, Widget, I)
    local Index = I + 1
    self.Index2Widget[Index] = Widget
    local BlackListData = self.BlackList[Index]
    local ItemCls = self.Widget2ItemCls[Widget]
    if not ItemCls then
        ItemCls = UIHandler.New(self,Widget,require("Client.Modules.Friend.FriendManage.FriendManagerTabBlackListItem")).ViewInstance
        self.Widget2ItemCls[Widget] = ItemCls
    end
    ItemCls:UpdateUI(BlackListData)
end

return FriendManagerTabBlackList
