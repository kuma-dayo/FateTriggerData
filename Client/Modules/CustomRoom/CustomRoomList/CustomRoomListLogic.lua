--[[
    自建房房间列表解耦逻辑
]]

local class_name = "CustomRoomListLogic"
local CustomRoomListLogic = BaseClass(nil, class_name)


function CustomRoomListLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.TheCustomRoomModle = MvcEntry:GetModel(CustomRoomModel)

    self.CurSelectModeIndex = nil
    self.ModeIndex2ModeId = {}
    self.IsNoPasswd = false
    self.SearchRoomActionFailed = false

    local TypeList = {}
    local ModeIdList = self.TheCustomRoomModle:GetCanCreateModeIdList()
    for k,ModeId in ipairs(ModeIdList) do
        local TheModeCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_ModeSelect_ModeEntryCfg,Cfg_ModeSelect_ModeEntryCfg_P.ModeId,ModeId)
        table.insert(TypeList, {
            ItemDataString = TheModeCfg[Cfg_ModeSelect_ModeEntryCfg_P.ModeName],
            ItemIndex = k,
            ItemID = ModeId,
        })
        if not self.CurSelectModeIndex then
            self.CurSelectModeIndex = k
        end
        self.ModeIndex2ModeId[k] = ModeId
    end
    local params = {
        OptionList = TypeList,
        DefaultSelect = self.CurSelectModeIndex,
        SelectCallBack = Bind(self, self.OnSelectionChanged)
    }
    UIHandler.New(self, self.View.WBP_ComboBox, CommonComboBox, params)

    self.MsgList = 
    {
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_LIST_UDPATE, Func = self.ON_ROOM_LIST_UDPATE_UDPATE },
        {Model = CustomRoomModel, MsgName = CustomRoomModel.ON_ROOM_SEARCH_RESULT_UDPATE, Func = self.ON_ROOM_SEARCH_RESULT_UDPATE },
	}
    self.BindNodes = 
    {
		{ UDelegate = self.View.WBP_Room_Btn.GUIButton_ClickArea.OnClicked,Func = Bind(self,self.OnClickPublicOnlyBtn) },

        { UDelegate = self.View.WBP_CommonBtn_Refresh.GUIButton_Main.OnClicked,Func = Bind(self,self.OnClicked_RefreshReq) },
        { UDelegate = self.View.WBP_Common_Search.WBP_Common_SocialBtn.GUIButton_Main.OnClicked,Func = Bind(self,self.OnClicked_Search) },
	}

    self.Widget2Item = {}
    self.View.WBP_RoomMainList.OnUpdateItem:Add(self.View, Bind(self,self.OnUpdateItem))


    -- 创建房间按钮
    UIHandler.New(self, self.View.Btn_CreateRoom, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnClicked_RoomCreate),
        CommonTipsID = CommonConst.CT_C,
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListLogic_Createaroom_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.C
    })

    -- 加入房间按钮
    self.CreateRoomBtnInstance =  UIHandler.New(self, self.View.Btn_JoinRoom, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnClicked_RoomJoin),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListLogic_Jointheroom_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar
    }).ViewInstance


    -- 注册输入控件处理
    self.InputBox = UIHandler.New(self,self.View.WBP_Common_Search,CommonTextBoxInput,{
        InputWigetName = "NameInput",
        FoucsViewId = ViewConst.CustomRoomPanel,
        OnTextChangedFunc = Bind(self,self.OnTextChangedFunc),
        OnTextCommittedEnterFunc = Bind(self,self.OnEnterFunc),
    }).ViewInstance
end

function CustomRoomListLogic:ON_ROOM_LIST_UDPATE_UDPATE()
    self:RefreshList()
end
function CustomRoomListLogic:ON_ROOM_SEARCH_RESULT_UDPATE(Info)
    self.SearchRoomActionFailed = not Info and true or false
    self:RefreshList()
end
function CustomRoomListLogic:OnClickPublicOnlyBtn()
    CWaring("OnClickPublicOnlyBtn")
    self.IsNoPasswd = not self.IsNoPasswd
    self:UpdateIsNoPasswdShow()
end
function CustomRoomListLogic:OnClicked_IsNoPasswdDefault()
    CWaring("OnClicked_IsNoPasswdDefault")
    self.IsNoPasswd = true
    self:UpdateIsNoPasswdShow()
end
function CustomRoomListLogic:OnClicked_RefreshReq()
    self.View.WBP_Common_Search.NameInput:SetText("")
    self:DoReqRooomList()
end
function CustomRoomListLogic:OnClicked_Search()
    self:DoRoomSearchAction()
end
function CustomRoomListLogic:OnTextChangedFunc(InputBox,InputTxt)
end

function CustomRoomListLogic:OnEnterFunc()
    if not CommonUtil.IsValid(self.View) then
        return
    end
    self:DoRoomSearchAction()
end
function CustomRoomListLogic:DoRoomSearchAction(IsFromClickSearch)
    local InputText = self.View.WBP_Common_Search.NameInput:GetText()
    -- 检测是否纯空格
    local TrimEmptyText = StringUtil.AllTrim(InputText)
    if InputText ~= "" and TrimEmptyText ~= "" then
        local InputRoomId = tonumber(InputText)
        if not InputRoomId then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListLogic_TheroomIDformatiswro"))
            return
        end
        MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_SearchRoomReq(InputRoomId);
    else
        if IsFromClickSearch then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListLogic_PleaseentertheroomID"))
        else
            self.TheCustomRoomModle:SetCurEnteredRoomInfo(nil)
            self.SearchRoomActionFailed = false
            self:RefreshList()
        end
    end
end

function CustomRoomListLogic:UpdateIsNoPasswdShow(IsInit)
    self.View.WBP_Room_Btn.WidgetSwitcher_Icon:SetActiveWidgetIndex(self.IsNoPasswd and 1 or 0)
    if not IsInit then
        self:RefreshList()
    end
end
function CustomRoomListLogic:UpdateJoinRoomButtonState()
    self.CreateRoomBtnInstance:SetBtnEnabled(self.CurSelectRoomIndex and true or false)
end

function CustomRoomListLogic:OnClicked_RoomCreate()
    --创建房间
    MvcEntry:OpenView(ViewConst.CustomRoomCreate)
end
function CustomRoomListLogic:OnClicked_RoomJoin()
    --加入房间
    if not self.CurSelectRoomIndex then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListLogic_Pleaseselecttheroomy"))
        return
    end
    local RoomInfo = self.DataList[self.CurSelectRoomIndex]
    if RoomInfo.Status == Pb_Enum_CUSTOMROOM_STATUS.CUSTOMROOM_ST_GAME then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListLogic_Thespecifiedroomhass"))
        return
    end
    if RoomInfo.IsLock then
        --TODO 弹窗，需要先输入密码 未做
        local RoomId = RoomInfo.CustomRoomId
        local Param = {
            RoomId = RoomId,
            RoomInfo = RoomInfo,
        }
        MvcEntry:OpenView(ViewConst.CustomRoomJoinNeedPwd,Param)
    else
        MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_JoinRoomReq(RoomInfo.CustomRoomId,"",Pb_Enum_CUSTOMROOM_JOIN_SRC.JOIN_SRC_NORMAL)
    end
end

function CustomRoomListLogic:OnShow(Param,IsFromCacheTrigger)
    if IsFromCacheTrigger then
        self.Handler:DynamicRegisterOrUnRegister(true)
    end
    self:UpdateIsNoPasswdShow(true)
    self:DoReqRooomList()
    self.View.WBP_Common_Search.NameInput:SetText("")
    self.View.WBP_Common_Search.NameInput:SetHintText(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Room', "1159"))
end

function CustomRoomListLogic:OnHide()
    self.Handler:DynamicRegisterOrUnRegister(false)
end

function CustomRoomListLogic:OnSelectionChanged(Index, IsInit, Data)
	CLog("Index = "..Index)
    if not IsInit then
        self.CurSelectModeIndex = Index
        self:DoReqRooomList()
    end
end

function CustomRoomListLogic:DoReqRooomList()
    self.SearchRoomActionFailed = false
    local ModeId = self.ModeIndex2ModeId[self.CurSelectModeIndex]
    MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_RoomListReq(ModeId,self.IsNoPasswd)
end


function CustomRoomListLogic:RefreshList()
    self.DataList = {}
    self.CurSelectRoomIndex = nil
    self.CurSelectRoomItem = nil

    if not self.SearchRoomActionFailed then
        local CurSearchInfo = self.TheCustomRoomModle:GetCurSearchRoomInfo()
        if CurSearchInfo then
            self.DataList = {CurSearchInfo}
            self.CurSelectRoomIndex = 1
        else
            if self.IsNoPasswd then
                self.DataList = {}
                local TheTmpRoomList = self.TheCustomRoomModle:GetRoomList()
                for k,v in ipairs(TheTmpRoomList) do
                    if not v.IsLock then
                        self.DataList[#self.DataList + 1] = v
                    end
                end
            else
                self.DataList = self.TheCustomRoomModle:GetRoomList()
            end
        end
    end

    if #self.DataList <= 0 then
        if self.SearchRoomActionFailed then
            self.View.WidgetSwitcher_State:SetActiveWidget(self.View.Panel_Empty)
        else
            self.View.WidgetSwitcher_State:SetActiveWidget(self.View.Empty)
        end
    else
        self.View.WidgetSwitcher_State:SetActiveWidget(self.View.WBP_RoomMainList)
        self.View.WBP_RoomMainList:Reload(#self.DataList)
    end
    self:UpdateJoinRoomButtonState()
end


function CustomRoomListLogic:OnUpdateItem(Handler,Widget, Index)
	local FixIndex = Index + 1
	local RoomBaseData = self.DataList[FixIndex]
	if RoomBaseData == nil then
		return
	end

	local TargetItem = self:CreateItem(Widget)
	if TargetItem == nil then
		return
	end
    local RoomId = RoomBaseData.CustomRoomId
    local param = {
        RoomId = RoomId,
        RoomInfo = RoomBaseData,
        ClickFunc = Bind(self,self.OnRoomItemClick,RoomId,FixIndex,TargetItem),
        Index = FixIndex,
    }
	TargetItem:SetData(param)
    if self.CurSelectRoomIndex and FixIndex == self.CurSelectRoomIndex then
        TargetItem:Select()
        self.CurSelectRoomItem = TargetItem
    else
        TargetItem:UnSelect()
    end
end

function CustomRoomListLogic:CreateItem(Widget)
	local Item = self.Widget2Item[Widget]
	if not Item then
		Item = UIHandler.New(self,Widget,require("Client.Modules.CustomRoom.CustomRoomList.CustomRoomListItemLogic"))
		self.Widget2Item[Widget] = Item
	end
	return Item.ViewInstance
end

function CustomRoomListLogic:OnRoomItemClick(RoomId,FixIndex,TargetItem)
    if FixIndex == self.CurSelectRoomIndex then
        return
    end
    self.CurSelectRoomIndex = FixIndex
    if self.CurSelectRoomItem then
		self.CurSelectRoomItem:UnSelect();
	end
    if TargetItem then
        self.CurSelectRoomItem = TargetItem
        self.CurSelectRoomItem:Select();
    end

    self:UpdateJoinRoomButtonState()
end

return CustomRoomListLogic
