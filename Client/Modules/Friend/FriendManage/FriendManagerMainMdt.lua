--[[
    好友管理主界面
]]

local class_name = "FriendManagerMainMdt";
FriendManagerMainMdt = FriendManagerMainMdt or BaseClass(GameMediator, class_name);

function FriendManagerMainMdt:__init()
end

function FriendManagerMainMdt:OnShow(data)
    
end

function FriendManagerMainMdt:OnHide()
end


--[[
    Tab分页类型
]]
FriendManagerMainMdt.TabKey = {
    -- 好友列表
    Friend = 1,
    -- -- 小队
    -- Team = 2,
    -- -- 好友推荐
    -- Recommend = 3,
    -- 黑名单
    BlackList = 2,
}

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.MsgList = 
    {
		-- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.GUIButton_Close_ClickFunc},
    }

    self.BindNodes = 
    {

	}
    self.Model = MvcEntry:GetModel(FriendModel)
    
    self.CurTabId = 0 -- 当前选中页签
    self:InitTabMenu()
    self:InitBtns()
end

function M:OnHide()
    self.CurTabId = 0
end

function M:InitTabMenu()
    self.TabTypeId2Vo ={
        [FriendManagerMainMdt.TabKey.Friend] = {

            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Friend/FriendManage/Friend/WBP_FriendManage_FriendPanel.WBP_FriendManage_FriendPanel",
            LuaClass=require("Client.Modules.Friend.FriendManage.FriendManagerTabFriendList"),
            TitleName = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerMainMdt_closeintimatefriend_Btn"),
        },

        -- [FriendManagerMainMdt.TabKey.Team] = nil,   -- TODO 待做

        -- [FriendManagerMainMdt.TabKey.Recommend] = nil,  -- TODO 待做

        [FriendManagerMainMdt.TabKey.BlackList] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Friend/FriendManage/Black/WBP_FriendManage_BlackPanel.WBP_FriendManage_BlackPanel",
            LuaClass=require("Client.Modules.Friend.FriendManage.FriendManagerTabBlackList"),
            TitleName = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerMainMdt_blacklist_Btn"),
        },
    }

    local MenuTabParam = {
		ItemInfoList = {
            {Id=FriendManagerMainMdt.TabKey.Friend,LabelStr=G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerMainMdt_closeintimatefriend_Btn")},
            -- {Id=FriendManagerMainMdt.TabKey.Team,Widget=self.TeamListDetail,LabelStr="小队"},
            -- {Id=FriendManagerMainMdt.TabKey.Recommend,Widget=self.RecommendDetail,LabelStr="好友推荐"},
            {Id=FriendManagerMainMdt.TabKey.BlackList,LabelStr=G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerMainMdt_blacklist_Btn")},
        },
        CurSelectId = FriendManagerMainMdt.TabKey.Friend,
        ClickCallBack = Bind(self,self.OnMenuBtnClick),
        ValidCheck = Bind(self,self.MenuValidCheck),
        HideInitTrigger = true,
        IsOpenKeyboardSwitch = true,
	}
    local CommonTabUpBarParam = {
        TabParam = MenuTabParam
    }
    self.MenuTabListCls = UIHandler.New(self,self.WBP_Common_TabUpBar_02, CommonTabUpBar,CommonTabUpBarParam).ViewInstance
end

-- 通用按钮定义
function M:InitBtns()
    -- 返回
    UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.GUIButton_Close_ClickFunc),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerMainMdt_return_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })
end

function M:OnShow(Param)
    Param = Param or {}
    self.CurTabId = Param.SelectTabId or FriendManagerMainMdt.TabKey.Friend
    if self.MenuTabListCls then
        self.MenuTabListCls:Switch2MenuTab(self.CurTabId,true)
    end
end

--[[
    更新当前Tab页展示
]]
function M:UpdateTabShow()
    local VoItem = self.TabTypeId2Vo[self.CurTabId]
    if not VoItem then
        CError("FriendManagerMainMdt:UpdateTabShow() VoItem nil")
        return
    end
    if not VoItem.ViewItem then
        local WidgetClassPath = VoItem.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget,self.Content)
        local ViewItem = UIHandler.New(self,Widget,VoItem.LuaClass).ViewInstance
        VoItem.ViewItem = ViewItem
        VoItem.View = Widget
        local Param = {
            -- TODO
        }
        VoItem.ViewItem:UpdateUI(Param)
    else
        VoItem.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- if VoItem.ViewItem.OnCustomShow then
        --     VoItem.ViewItem:OnCustomShow()
        -- end

        VoItem.ViewItem:ManualOpen()
    end
end

function M:OnMenuBtnClick(Id,ItemInfo,IsInit)
    if self.CurTabId and self.TabTypeId2Vo[self.CurTabId] and self.TabTypeId2Vo[self.CurTabId].View then
        -- 隐藏旧Tab
        self.TabTypeId2Vo[self.CurTabId].View:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- if self.TabTypeId2Vo[self.CurTabId].ViewItem.OnCustomHide then
        --     self.TabTypeId2Vo[self.CurTabId].ViewItem:OnCustomHide()
        -- end

        self.TabTypeId2Vo[self.CurTabId].ViewItem:ManualClose()
    end
    self.CurTabId = Id
    local TitleName = self.TabTypeId2Vo[self.CurTabId] and self.TabTypeId2Vo[self.CurTabId].TitleName or ""
    if self.MenuTabListCls then self.MenuTabListCls:UpdateTitleText(TitleName) end
    self:UpdateTabShow();
end

function M:MenuValidCheck(Id)
    if Id == FriendManagerMainMdt.TabKey.Team or Id == FriendManagerMainMdt.TabKey.Recommend then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerMainMdt_Functionisnotopen"))
        return false
    end
    return true
end

--关闭界面
function M:DoClose()
    MvcEntry:CloseView(self.viewId)
    return true
end

-- 点击关闭
function M:GUIButton_Close_ClickFunc()
    self:DoClose()
end

return M