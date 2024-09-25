--[[
    房间创建逻辑
]]
local class_name = "CustomRoomCreateLogic"
---@class CustomRoomCreateLogic
local CustomRoomCreateLogic = CustomRoomCreateLogic or BaseClass(GameMediator, class_name)

function CustomRoomCreateLogic:OnInit()
    self.BindNodes = {
		{UDelegate = self.View.WBP_CommonBtn_Arrow_Left.GUIButton_Main.OnClicked,Func = Bind(self, self.OnArrowBtnClickLeft)},
        {UDelegate = self.View.WBP_CommonBtn_Arrow_Right.GUIButton_Main.OnClicked,Func = Bind(self, self.OnArrowBtnClickRight)},

        {UDelegate = self.View.WBP_Room_Editable.Button_Min.OnClicked,Func = Bind(self, self.OnTeamMemberBtnClickLeft)},
        {UDelegate = self.View.WBP_Room_Editable.Button_Max.OnClicked,Func = Bind(self, self.OnTeamMemberBtnClickRight)},
	}

    self.TheCustomRoomModel = MvcEntry:GetModel(CustomRoomModel)
    self.TheUserModel = MvcEntry:GetModel(UserModel)

    self.MapPointItemList = {}

    self.Widget2ModeItem = {}
    self.TeamType2TeamMember = {
        [1] = 1,
        [2] = 2,
        [3] = 4,
    }
    self.RoomNameSizeLimit = CommonUtil.GetParameterConfig(ParameterConfig.RoomNameTextLength)
    self.RoomPwdSizeLimit = CommonUtil.GetParameterConfig(ParameterConfig.RoomPasswordTextLength)

    self.ViewType1Instance = UIHandler.New(self,self.View.WBP_Item_FPP, require("Client.Modules.CustomRoom.CustomRoomCommonWidget.CustomRoomTabWidgetLogic"), 
    {
        OnItemClick = Bind(self,self.OnViewTypeClick),
        ShowStr = self.TheCustomRoomModel:GetDesByViewType(1),
        InstanceId = 1,
    }).ViewInstance

    self.ViewType2Instance = UIHandler.New(self,self.View.WBP_Item_TPP, require("Client.Modules.CustomRoom.CustomRoomCommonWidget.CustomRoomTabWidgetLogic"), 
    {
        OnItemClick = Bind(self,self.OnViewTypeClick),
        ShowStr = self.TheCustomRoomModel:GetDesByViewType(3),
        InstanceId = 3,
    }).ViewInstance

    self.WatchType1Instance = UIHandler.New(self,self.View.Btn_Yes, require("Client.Modules.CustomRoom.CustomRoomCommonWidget.CustomRoomTabWidgetLogic"), 
    {
        OnItemClick = Bind(self,self.OnWatchTypeClick),
        ShowStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_open"),
        InstanceId = 1,
    }).ViewInstance
    self.WatchType2Instance = UIHandler.New(self,self.View.Btn_No, require("Client.Modules.CustomRoom.CustomRoomCommonWidget.CustomRoomTabWidgetLogic"), 
    {
        OnItemClick = Bind(self,self.OnWatchTypeClick),
        ShowStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_close"),
        InstanceId = 0,
    }).ViewInstance


    self.TeamType1Instance = UIHandler.New(self,self.View.WBP_TeamType1, require("Client.Modules.CustomRoom.CustomRoomCommonWidget.CustomRoomTeamTypeItemLogic"), 
    {
        OnItemClick = Bind(self,self.OnTeamTypeClick),
        MemberCount = 1,
    }).ViewInstance
    self.TeamType2Instance = UIHandler.New(self,self.View.WBP_TeamType2, require("Client.Modules.CustomRoom.CustomRoomCommonWidget.CustomRoomTeamTypeItemLogic"), 
    {
        OnItemClick = Bind(self,self.OnTeamTypeClick),
        MemberCount = 2,
    }).ViewInstance
    self.TeamType3Instance = UIHandler.New(self,self.View.WBP_TeamType3, require("Client.Modules.CustomRoom.CustomRoomCommonWidget.CustomRoomTeamTypeItemLogic"), 
    {
        OnItemClick = Bind(self,self.OnTeamTypeClick),
        MemberCount = 4,
    }).ViewInstance
    self.MemberCount2TeamType = {
        [1] = self.TeamType1Instance,
        [2] = self.TeamType2Instance,
        [4] = self.TeamType3Instance,
    }


    -- 房间名注册输入控件处理
    self.NamePutInst = UIHandler.New(self,self.View.WBP_Common_InputBox_1,require("Client.Modules.Common.CommonInputBoxLogic")
    ,{
        InputWigetName = "NameInput",
        FoucsViewId = ViewConst.CustomRoomCreate,
        DefaultName = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Room', "Lua_CustomRoomCreateMdt_ClickToSetName"),
    }).ViewInstance
    
    
    -- 密码注册输入控件处理
    self.PwdPutInst = UIHandler.New(self,self.View.WBP_Common_InputBox,require("Client.Modules.Common.CommonInputBoxLogic")
    ,{
        InputWigetName = "NameInput",
        FoucsViewId = ViewConst.CustomRoomCreate,
        OnTextCommittedEnterFunc = Bind(self,self.OnPwdInputEnterFunc),
    }).ViewInstance

     -- 注册队伍人数输入控件
    UIHandler.New(self,self.View.WBP_Room_Editable,require("Client.Modules.CustomRoom.CustomRoomCreate.CustomRoomEditableLogic"),{
        OnTextChangedFunc = Bind(self,self.OnTeamCountsInputChangedFunc),
        OnTextCommittedEnterFunc = Bind(self,self.OnTeamCountsInputEnterFunc),
    })
    self.TeamCountInputText = ""
    UIHandler.New(self,self.View.CommonBtn_1, WCommonBtnTips, 
    {
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_setup_Btn"),
        OnItemClick = Bind(self,self.OnCreateClicked),
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
    })
    UIHandler.New(self,self.View.CommonBtn_2, WCommonBtnTips, 
    {
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_cancel_Btn"),
        OnItemClick = Bind(self,self.OnEscClick),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.Escape,
    })
end

function CustomRoomCreateLogic:OnShow(Param)
    self:UpdateUI(Param)
end
function CustomRoomCreateLogic:OnHide()
end

function CustomRoomCreateLogic:UpdateUI(Param)
    self.Param = Param or {}
    self.ModeIdList = self.TheCustomRoomModel:GetCanCreateModeIdList()
    self.CurSelectModeIndex = 1
    self.CurSelectModeId = self.ModeIdList[self.CurSelectModeIndex]

    local DefaultRoomName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_sroom"),StringUtil.StringTruncationByChar(self.TheUserModel:GetPlayerName(), "#")[1])
    self.NamePutInst:SetText(DefaultRoomName)

    local TheRoomCfg = G_ConfigHelper:GetSingleItemById(Cfg_CustomRoomConfig,self.CurSelectModeId)

    self.ViewType = 3
    self.CanSpectate = false
    self.CurTeamMemberType = 4
    self.CurTeamCount = TheRoomCfg[Cfg_CustomRoomConfig_P.DefaultTeamNum]

    self:UpdateModeListShow()
    self:OnSelectModeChange()
    
end

function CustomRoomCreateLogic:OnSelectModeChange()
    local TheRoomCfg = G_ConfigHelper:GetSingleItemById(Cfg_CustomRoomConfig,self.CurSelectModeId)

    self.CurSelectMapIndex = 1;
    self.CanSelectMapLength = TheRoomCfg[Cfg_CustomRoomConfig_P.SceneIds]:Num()

    self.TeamNumMinLow = TheRoomCfg[Cfg_CustomRoomConfig_P.TeamNumInterval]:Get(1)
    self.TeamNumMinMax = TheRoomCfg[Cfg_CustomRoomConfig_P.TeamNumInterval]:Num() > 1 and TheRoomCfg[Cfg_CustomRoomConfig_P.TeamNumInterval]:Get(2) or self.TeamNumMinLow
    
    self.MemberCount2TeamType = self.MemberCount2TeamType or {}
    for k,ViewInstance in pairs(self.MemberCount2TeamType) do
        ViewInstance:UnAvailable()
    end
    self.TeamMemberTypeList = {}
    local ExistConfig = false
    local RoomTypeList = TheRoomCfg[Cfg_CustomRoomConfig_P.TeamTypeList]
    for i=1,RoomTypeList:Num() do
        local TeamType = RoomTypeList:Get(i)
        local TheTeamTypeCfg = G_ConfigHelper:GetSingleItemById(Cfg_CustomRoomTeamTypeCfg,TeamType)

        local TeamMemberCount = TheTeamTypeCfg[Cfg_CustomRoomTeamTypeCfg_P.TeamNum]
        self.TeamMemberTypeList[#self.TeamMemberTypeList + 1] = TeamMemberCount
        if TeamMemberCount == self.CurTeamMemberType then
            ExistConfig = true
        end
        if self.MemberCount2TeamType[TeamMemberCount] then
            self.MemberCount2TeamType[TeamMemberCount]:DoAvailable()
        end
    end
    if not ExistConfig then
        self.CurTeamMemberType = self.TeamMemberTypeList[1]
    end

    if self.CurTeamCount < self.TeamNumMinLow or self.CurTeamCount > self.TeamNumMinMax then
        self.CurTeamCount = TheRoomCfg[Cfg_CustomRoomConfig_P.DefaultTeamNum]
    end

    if self.TeamNumMinLow ~= self.TeamNumMinMax then
        self.View.LbTeamCountLimit:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Maximumqueue"),self.TeamNumMinLow,self.TeamNumMinMax))
    else
        self.View.LbTeamCountLimit:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_TeamMaximum"),self.TeamNumMinLow))
    end

    self:UdpateTeamCountText()
    self:UpdateMapListShow();
    self:UpdateSelectMapShow()
    self:UpdateTeamTypeShow()
    self:UpdateViewTypeShow()
    self:UpdateCanSpectateShow()
end

function CustomRoomCreateLogic:UpdateModeListShow()
    self.CurSelectModeItem = nil
    local AllChildren = self.View.Panel_ModelItem:GetAllChildren()
    for k,v in pairs(AllChildren) do
        v:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    for Index,ModelId in ipairs(self.ModeIdList) do
        if (CommonUtil.IsValid(self.View["WBP_Room_RoomCreate_ModelItem_" .. Index])) then
            if not self.Widget2ModeItem[Index] then
                self.Widget2ModeItem[Index] = UIHandler.New(self, self.View["WBP_Room_RoomCreate_ModelItem_" .. Index], require("Client.Modules.CustomRoom.CustomRoomCreate.CustomRoomCreateModelItem")).ViewInstance
            end
            local TargetItem = self.Widget2ModeItem[Index]
            local TheRoomCfg = G_ConfigHelper:GetSingleItemById(Cfg_CustomRoomConfig,ModelId)
            local TheModeCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_ModeEntryCfg,ModelId)
            local ItemData = {
                ItemDataString = TheModeCfg[Cfg_ModeSelect_ModeEntryCfg_P.ModeName],
                ItemIndex = Index,
                ItemID = Index,
            }
            TargetItem:SetItemData(ItemData, Index, self.CurSelectModeIndex, ModelId, Bind(self,self.OnModeItemClick,TargetItem))
        
            if Index == self.CurSelectModeIndex then
                self.CurSelectModeItem = TargetItem
            end
        end
    end
end

function CustomRoomCreateLogic:OnModeItemClick(TargetItem,ItemIndex,ItemData)
    if self.CurSelectModeIndex == ItemIndex then
        return
    end
    self.CurSelectModeIndex = ItemIndex
    self.CurSelectModeId = self.ModeIdList[self.CurSelectModeIndex]
    if self.CurSelectModeItem then
		self.CurSelectModeItem:UpdateSelect(self.CurSelectModeIndex);
	end
    if TargetItem then
        self.CurSelectModeItem = TargetItem
        self.CurSelectModeItem:UpdateSelect(self.CurSelectModeIndex);
    end

    self:OnSelectModeChange()
end

function CustomRoomCreateLogic:OnViewTypeClick(ViewType)
    --暂时屏蔽
    if self.ViewType == 3 then
        return
    end
    if self.ViewType == ViewType then
        return
    end
    self.ViewType = ViewType

    self:UpdateViewTypeShow()
end
function CustomRoomCreateLogic:OnWatchTypeClick(OnWatchType)
    --暂时屏蔽
    if not self.CanSpectate then
        return
    end
    local IsOpen = OnWatchType == 1 and true or false
    if self.CanSpectate == IsOpen then
        return
    end
    self.CanSpectate = IsOpen

    self:UpdateCanSpectateShow()
end
function CustomRoomCreateLogic:OnTeamTypeClick(MemberCount)
    if self.CurTeamMemberType == MemberCount then
        return
    end
    self.CurTeamMemberType = MemberCount

    self:UpdateTeamTypeShow()
end

function CustomRoomCreateLogic:UpdateMapListShow()
    local PointUMGPath = "/Game/BluePrints/UMG/OutsideGame/Room/WBP_LobbyRoomPointWidget.WBP_LobbyRoomPointWidget"
    for i=1,self.CanSelectMapLength do
        if not self.MapPointItemList[i] then
            local WidgetClass = UE.UClass.Load(PointUMGPath)
            local Widget = NewObject(WidgetClass, self)
            self.View.BoxMapPoints:AddChild(Widget)  

            self.MapPointItemList[i] = Widget
        end
    end
end

function CustomRoomCreateLogic:UpdateSelectMapShow()
    local TheRoomCfg = G_ConfigHelper:GetSingleItemById(Cfg_CustomRoomConfig,self.CurSelectModeId)
    local CurSelectMapId = TheRoomCfg[Cfg_CustomRoomConfig_P.SceneIds]:Get(self.CurSelectMapIndex)

    local TheMapCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_SceneEntryCfg,CurSelectMapId)
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImgMap,TheMapCfg[Cfg_ModeSelect_SceneEntryCfg_P.ScenePreviewImgPath])

    for Index,Point in ipairs(self.MapPointItemList) do
        if Index > self.CanSelectMapLength then
            Point:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            Point:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

            Point.Image_HighLight:SetVisibility(Index == self.CurSelectMapIndex and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
            Point.Image_Gray:SetVisibility(Index ~= self.CurSelectMapIndex and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
    end
    self.View.LbMapName:SetText(TheMapCfg[Cfg_ModeSelect_SceneEntryCfg_P.SceneName])

    self:UpdateMapSelectArrowShow()
end


function CustomRoomCreateLogic:UpdateViewTypeShow()
    --第一人称按钮暂时锁住
    self.ViewType1Instance:UnAvailable()
    self.ViewType2Instance:UpdateSelect(self.ViewType)
end
function CustomRoomCreateLogic:UpdateCanSpectateShow()
    --观战按钮暂时锁住
    self.WatchType1Instance:UnAvailable()
    -- self.WatchType1Instance:UpdateSelect(self.CanSpectate and 1 or 0)
    self.WatchType2Instance:UpdateSelect(self.CanSpectate and 1 or 0)
end
function CustomRoomCreateLogic:UpdateTeamTypeShow()
    self.TeamType1Instance:UpdateSelect(self.CurTeamMemberType)
    self.TeamType2Instance:UpdateSelect(self.CurTeamMemberType)
    self.TeamType3Instance:UpdateSelect(self.CurTeamMemberType)
end


function CustomRoomCreateLogic:UpdateMapSelectArrowShow()
    if self.CanSelectMapLength <= 1 then
        self.View.Arrow_L:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Arrow_R:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.View.Arrow_L:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.Arrow_R:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

function CustomRoomCreateLogic:OnArrowBtnClickLeft()
    self:__OnArrowBtnClickInner(-1)
end
function CustomRoomCreateLogic:OnArrowBtnClickRight()
    self:__OnArrowBtnClickInner(1)
end
function CustomRoomCreateLogic:__OnArrowBtnClickInner(Value)
    self.CurSelectMapIndex = self.CurSelectMapIndex + Value

    if self.CurSelectMapIndex > self.CanSelectMapLength then
        self.CurSelectMapIndex = 1
    end
    if self.CurSelectMapIndex < 1 then
        self.CurSelectMapIndex = self.CanSelectMapLength
    end
    self:UpdateSelectMapShow()
end

function CustomRoomCreateLogic:OnTeamMemberBtnClickLeft()
    self:__OnTeamCountChangeBtnClickInner(-1)
end
function CustomRoomCreateLogic:OnTeamMemberBtnClickRight()
    self:__OnTeamCountChangeBtnClickInner(1)
end
function CustomRoomCreateLogic:__OnTeamCountChangeBtnClickInner(Value)
    -- if not self:CheckTeamCountsValid() then
    --     return
    -- end
    self.CurTeamCount = self.CurTeamCount + Value


    if self.CurTeamCount < self.TeamNumMinLow then
        self.CurTeamCount = self.TeamNumMinLow
    elseif self.CurTeamCount > self.TeamNumMinMax then
        self.CurTeamCount = self.TeamNumMinMax
    end

    self:UdpateTeamCountText()
end

function CustomRoomCreateLogic:UdpateTeamCountText()
    self.View.WBP_Room_Editable.EditableText:SetText(self.CurTeamCount .. "")
    self.TeamCountInputText = self.CurTeamCount .. ""

    self:UdpateTeamCountArrowShow()
end

function CustomRoomCreateLogic:UdpateTeamCountArrowShow()
    if self.TeamNumMinLow ~= self.TeamNumMinMax then
        self.View.WBP_Room_Editable.EditableText:SetVisibility(UE.ESlateVisibility.Visible)
        if self.CurTeamCount <= self.TeamNumMinLow then
            self.View.WBP_Room_Editable.Button_Min:SetIsEnabled(false)
        else
            self.View.WBP_Room_Editable.Button_Min:SetIsEnabled(true)
        end
        if self.CurTeamCount >= self.TeamNumMinMax then
            self.View.WBP_Room_Editable.Button_Max:SetIsEnabled(false)
        else
            self.View.WBP_Room_Editable.Button_Max:SetIsEnabled(true)
        end
    else
        self.View.WBP_Room_Editable.EditableText:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

        self.View.WBP_Room_Editable.Button_Min:SetIsEnabled(false)
        self.View.WBP_Room_Editable.Button_Max:SetIsEnabled(false)
    end
end

function CustomRoomCreateLogic:OnPwdInputEnterFunc()
   self:CheckPwdValid()
end

function CustomRoomCreateLogic:OnTeamCountsInputChangedFunc(_, HandlerView, InputText)
    self:CheckTeamCountsValid(true, InputText)
    self:UdpateTeamCountArrowShow()
end
function CustomRoomCreateLogic:OnTeamCountsInputEnterFunc(_, HandlerView,InputText)
    self:CheckTeamCountsValid(false, InputText)
    self:UdpateTeamCountArrowShow()
end

function CustomRoomCreateLogic:CheckTeamCountsValid(HideTip, InputText)
    if InputText then
        self.TeamCountInputText = InputText
    end
    -- 检测是否纯空格
    local TrimEmptyText = StringUtil.AllTrim(self.TeamCountInputText)
    if self.TeamCountInputText ~= "" and TrimEmptyText ~= "" then
        local TeamCount = tonumber(self.TeamCountInputText)
        if not TeamCount then
            if not HideTip then
                UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Theformatofteamquant"))
            end
            return false
        else
            self.CurTeamCount = TeamCount
            if TeamCount < self.TeamNumMinLow or TeamCount > self.TeamNumMinMax then
                if not HideTip then
                    if self.TeamNumMinLow ~= self.TeamNumMinMax then
                        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Maximumqueue"),self.TeamNumMinLow,self.TeamNumMinMax))
                    else
                        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Thenumberofteamscano"),self.TeamNumMinLow))
                    end
                end
                return false
            end
            return true,TeamCount
        end
    else
        if not HideTip then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Teamquantitycannotbe"))
        end
        return false
    end
    return true,""
end

function CustomRoomCreateLogic:CheckPwdValid()
    local InputText = self.PwdPutInst:GetText()
    -- 检测是否纯空格
    local TrimEmptyText = StringUtil.AllTrim(InputText)
    if InputText ~= "" and TrimEmptyText ~= "" then
        if not CommonUtil.StringCharSizeCheck(TrimEmptyText,self.RoomPwdSizeLimit,StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Passwordlengthcannot"),self.RoomPwdSizeLimit)) then
            return false
        end
        local PwdId = tonumber(InputText)
        if not PwdId then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Wrongpasswordformat"))
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

function CustomRoomCreateLogic:CheckRoomNameValid()
    local InputText = self.NamePutInst:GetText()
    -- 检测是否纯空格
    local TrimEmptyText = StringUtil.AllTrim(InputText)
    if not CommonUtil.StringCharSizeCheck(TrimEmptyText,self.RoomNameSizeLimit,StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Theroomnamecannotexc"),self.RoomNameSizeLimit),StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomCreateMdt_Theroomnamecannotbee"))) then
        return false
    end
    return true,InputText
end


--[[
    点击创建房间
]]
function CustomRoomCreateLogic:OnCreateClicked()
    local ValidResultPwd,Pwd = self:CheckPwdValid()
    if not ValidResultPwd then
        return
    end
    local ValidResultName,RoomName = self:CheckRoomNameValid()
    if not ValidResultName then
        return
    end
    if not self:CheckTeamCountsValid(false) then
        return
    end
    local TheRoomCfg = G_ConfigHelper:GetSingleItemById(Cfg_CustomRoomConfig,self.CurSelectModeId)
    local CurSelectMapId = TheRoomCfg[Cfg_CustomRoomConfig_P.SceneIds]:Get(self.CurSelectMapIndex)
    local Msg = {
        ModeId = self.CurSelectModeId,
        View = self.ViewType,
        TeamType = self.CurTeamMemberType,
        CanSpectate = self.CanSpectate,
        Passwd = Pwd,
        TeamNumLimit = self.CurTeamCount,
        CustomRoomName = RoomName,
        DsGroupId = MvcEntry:GetModel(MatchModel):GetSeverId(),
        ConfigId = self.CurSelectModeId,
        SceneId = CurSelectMapId,
    }
    MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_CreateRoomReq(Msg)
end

function CustomRoomCreateLogic:OnEscClick()
    if self.Param.CloseCb then
        self.Param.CloseCb()
    end
end

return CustomRoomCreateLogic
