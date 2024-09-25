--[[
    添加好友界面
]]

local class_name = "FriendAddMdt";
FriendAddMdt = FriendAddMdt or BaseClass(GameMediator, class_name);

function FriendAddMdt:__init()
end

function FriendAddMdt:OnShow(data)
end

function FriendAddMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.BtnCopy.GUIButton_Main.OnClicked,				Func = self.OnClicked_BtnCopy },
	}

    self.MsgList = 
    {
		-- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked},
        {Model = FriendModel, MsgName = FriendModel.ON_QUERY_PLAYERID, Func = self.OnGetPlayerId},
    }

    -- 背景控件处理
    local PopUpBgParam = {
        TitleText = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "1418"),
        CloseCb = Bind(self,self.OnEscClicked)
    }
    UIHandler.New(self,self.WBP_CommonPopUp_Bg_L,CommonPopUpBgLogic,PopUpBgParam)
    UIHandler.New(self,self.Close, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendAddMdt_cancel_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })
    UIHandler.New(self,self.Confirm, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnClicked_SearchFriend),
        CommonTipsID = CommonConst.CT_ENTER,
        ActionMappingKey = ActionMappings.Enter,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendAddMdt_confirm_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

    self.CharSizeLimit = 60

    -- 注册输入控件处理
    self.CommonInputBoxLogic = UIHandler.New(self,self.WBP_Common_InputBox,require("Client.Modules.Common.CommonInputBoxLogic")
    ,{
        InputWigetName = "NameInput",
        SizeLimit = self.CharSizeLimit,
        FoucsViewId = ViewConst.FriendAdd,
        OnTextChangedFunc = Bind(self,self.UpdatePlayerName),
        OnTextCommittedEnterFunc = Bind(self,self.OnClicked_SearchFriend),
        OnClearedFunc = Bind(self,self.OnEscClicked),
    }).ViewInstance

end


--由mdt触发调用
function M:OnShow(data)
    self.CurPlayerName = ""
    self.LbId:SetText(MvcEntry:GetModel(UserModel).PlayerId .. "")
    MvcEntry:GetModel(FriendModel):SetAddFriendModule(GameModuleCfg.FriendSearchId.ID)
end

function M:OnHide()
    MvcEntry:GetModel(FriendModel):ClearAddFriendModule(GameModuleCfg.FriendSearchId.ID)
end

function M:UpdatePlayerName(InName, bNotUpdateText)
	self.CurPlayerName = InName or ""
	if not bNotUpdateText then
		self.CommonInputBoxLogic:SetText(tostring(self.CurPlayerName))
	end
end

--[[
    点击请求搜索好友
]]
function M:OnClicked_SearchFriend()
    self.CurPlayerName = self.CommonInputBoxLogic:GetText()
    CWaring("self.CurPlayerName:" .. self.CurPlayerName)
    self.CurPlayerName = StringUtil.Trim(self.CurPlayerName)
    -- if not CommonUtil.PlayerNameCheckValid(self.CurPlayerName,self.CharSizeLimit) then
    --     return
    -- end
    if MvcEntry:GetModel(FriendModel):CheckIsFriendListFull() then
        return
    end
    if string.len(self.CurPlayerName) <= 0 then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendAddMdt_Cannotqueryemptyname"))
        return
    elseif StringUtil.utf8StringLen(self.CurPlayerName) > tonumber(self.CharSizeLimit) then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendAddMdt_Inputistoolong"))
        return
    end

    if MvcEntry:GetModel(UserModel):IsSelf(self.CurPlayerName) or  MvcEntry:GetModel(UserModel):IsSelfByName(self.CurPlayerName)then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendAddMdt_Cantaddyourself"))
        return
    end

    -- 先向服务器要回PlayerId,后续查重等都通过PlayerId判断
    MvcEntry:GetCtrl(FriendCtrl):SendFriendPlayerDataReq(self.CurPlayerName)
end

function M:OnGetPlayerId(PlayerId)
    if MvcEntry:GetModel(FriendModel):IsFriend(PlayerId) then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendAddMdt_Thisplayerisalreadyy"))
        return
    end
    MvcEntry:GetCtrl(FriendCtrl):SendProto_AddFriendReq(PlayerId)
    -- MvcEntry:CloseView(self.viewId)
end

--[[
    点击复制
]]
function M:OnClicked_BtnCopy()
    -- UIAlert.Show("功能未做")
    UE.UGFUnluaHelper.ClipboardCopy(StringUtil.ConvertFText2String(self.LbId:GetText()))
    UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendAddMdt_Copysucceeded"))
end

function M:OnEscClicked()
    MvcEntry:CloseView(self.viewId)
    return true
end

return M