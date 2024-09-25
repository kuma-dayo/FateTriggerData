--[[
    玩家修改名称界面
]]
local class_name = "NameInputPanelMdt";
NameInputPanelMdt = NameInputPanelMdt or BaseClass(GameMediator, class_name);

function NameInputPanelMdt:__init()
end

function NameInputPanelMdt:OnShow(data)
	-- CLog("-----OnShow")
end

function NameInputPanelMdt:OnHide()
	-- CLog("-----OnHide")
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.LoginModel = MvcEntry:GetModel(LoginModel)
    self.UserModel = MvcEntry:GetModel(UserModel)

	self.BindNodes = {
		{ UDelegate = self.BtnHoverTip.OnClicked,				Func = self.OnHoverTipClicked },
		{ UDelegate = self.BtnHoverTip.OnHovered,				Func = self.OnHoverTipHovered },
		{ UDelegate = self.BtnHoverTip.OnUnhovered,				Func = self.OnHoverTipOnUnhovered },
		{ UDelegate = self.BtnHoverTip.OnFocusLosted,				Func = self.OnHoverTipLostfocus },
		{ UDelegate = self.WBP_Common_Btn_Head.Btn_List.OnClicked,				Func = self.OnRandomHeadIconClicked },
		{ UDelegate = self.WBP_Common_Btn_Random.GUIButton_Main.OnClicked,				Func = self.OnClickedBtnRandom },
        { UDelegate = self.BtnStartGame.OnClicked,				Func = self.OnClickedStartGame },
        { UDelegate = self.BtnClose.OnClicked,				Func = self.OnClicked_CloseView },
        { UDelegate = self.TxtPlayerName.OnTextChanged,		Func = self.PlayerNameInputChanged},
        { UDelegate = self.TxtPlayerName.OnTextCommitted,		Func = self.OnPlayerNameTextCommitted},
	}
    self.MvvmBindList = {
		{ Model = UserModel, BindSource = Bind(self,self.OnPlayerNameUpdate), PropertyName = "PlayerName", MvvmBindType = MvvmBindTypeEnum.CALLBACK }
	}
	self.MsgList = {
		{Model = UserModel, MsgName = UserModel.ON_PLAYER_CREATE_FAIL,	Func = self.ON_PLAYER_CREATE_FAIL_Func},
		{Model = UserModel, MsgName = UserModel.ON_GET_PALYER_HEAD_LISR_RESULT,	Func = self.OnGetPalyerHeadLisrResult},
	}

    local PopUpBgParam = {
		HideCloseTip = true,
	}
	self.CommonPopUp_BgIns = UIHandler.New(self,self.WBP_CommonPopUp_Bg_L, CommonPopUpBgLogic, PopUpBgParam).ViewInstance

    self.CharSizeLimit = CommonUtil.GetParameterConfig(ParameterConfig.NickNameLimit,14)
    self.MaxPlayerNameInputLength = 15 --限制最长字数
    self:RegisterChangeNameInfo()

    self.CurHeadIconIndex = 1
    self.CurHeadIconId = 0
    self.HadNameChecked = false

    local CommonDescCfg = G_ConfigHelper:GetSingleItemById(Cfg_CommonDesc,1001)
    if CommonDescCfg then
        self.GUITextTittle:SetText(StringUtil.Format(CommonDescCfg.Tittle))
        self.GUITextContent:SetText(StringUtil.Format(CommonDescCfg.Content))
    end
end

--由mdt触发调用
--[[

]]
function M:OnShow(Param)
    self.Param = Param
    self.Type = Param.Type
    if self.Type == self.LoginModel.NAMECHANGETYPE.LOGIN then --登录
        self.SwitcherPanel:SetActiveWidgetIndex(0)
        Timer.InsertTimer(-1,function ()
            if CommonUtil.IsValid(self.TxtPlayerName) then
                self.TxtPlayerName:SetKeyboardFocus()
            end
        end)
    elseif self.Type == self.LoginModel.NAMECHANGETYPE.CHANGENAME then --创角/修改昵称
        self.SwitcherPanel:SetActiveWidgetIndex(1)
        self:HandleCreatePlayerWidget()
    end
	self.CurPlayerName = ""
end

--由mdt触发调用
function M:OnHide()
end

function M:HandleCreatePlayerWidget()
    Timer.InsertTimer(-1,function ()
        if CommonUtil.IsValid(self.NameInput) then
            self.NameInput:SetKeyboardFocus()
        end
    end)
    MvcEntry:GetCtrl(UserCtrl):SendProtoGetHeadListReq()
end

function M:NameInputChangedPlayerName(InText)
    print("[NameInputPanel]NameInputChangedPlayerName:Text",InText)
    self:ClearCheckResult()
end

function M:NameInputCommittedPlayerName(InText, InCommitMethod)
	print("NameInputPanelMdt", ">> OnTextCommitted_PlayerName...".. InText .. " - " .. InCommitMethod)

	if InCommitMethod == UE.ETextCommit.OnEnter then
		self:OnClickedCreatePlayer()
	end
end

function M:RegisterChangeNameInfo()
    UIHandler.New(self,self.WBP_CommonBtnNormal, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnClickedCreatePlayer),
        CommonTipsID = CommonConst.CT_ENTER,
        ActionMappingKey = ActionMappings.Enter,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_NameInputPanelMdt_setup_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main
    })
     -- 注册输入控件处理
     UIHandler.New(self,self,CommonTextBoxInput,{
        InputWigetName = "NameInput",
        SizeLimit = self.CharSizeLimit,
        FoucsViewId = ViewConst.NameInputPanel,
        OnTextChangedFunc = self.NameInputChangedPlayerName,
        OnTextCommittedEnterFunc = self.OnClickedCreatePlayer,
    })
end

function M:UpdatePlayerName(InName, bNotUpdateText)
	self.CurPlayerName = InName or ""
	if not bNotUpdateText then
		self.NameInput:SetText(tostring(self.CurPlayerName))
	end
end

--[[
    点击请求创建/换名
]]
function M:OnClickedCreatePlayer()
    self.CurPlayerName = self.NameInput:GetText()
    print("[NameInputPanel]OnClickedCreatePlayer:Text",self.CurPlayerName)
    local FixPlayerName = StringUtil.Trim(self.CurPlayerName)
    if not CommonUtil.PlayerNameCheckValid(FixPlayerName,self.CharSizeLimit) then
        self:UpdateCreateFailResult(nil, StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_NameInputPanelMdt_Namelengthdoesnotmee")))
        return
    end

    --请求创角
    local req = {
        UserId = self.Param.UserId,
        PlayerName = FixPlayerName,
        HeadId = self.CurHeadIconId
    }
    MvcEntry:GetCtrl(UserCtrl):SendProto_CreatePlayerReq(req)
end

function M:OnClickedBtnRandom()
    MvcEntry:GetCtrl(UserCtrl):SendProto_RandomNameReq()
end
 
function M:ClearCheckResult()
    self.LbCheckResult:SetVisibility(UE.ESlateVisibility.Hidden)
    self.LbCheckResult:SetText("")
    if self.HadNameChecked then
        self.HadNameChecked = false
        self.NameInput:ResetTextColorAndOpacity()
    end
end


function M:ON_PLAYER_CREATE_FAIL_Func(ErrorCode)
    self:UpdateCreateFailResult(ErrorCode)
end

function M:UpdateCreateFailResult(ErrorCode,Msg)
    if ErrorCode then
        local MsgObject = {
            ErrCode = ErrorCode,
            ErrCmd = "",
            ErrMsg = "",
        }
        local TipStr = MvcEntry:GetCtrl(ErrorCtrl):GetErrorTipByMsg(MsgObject)
        Msg = TipStr
    end
    local Success = false
    self.LbCheckResult:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.LbCheckResult:SetText(Msg)
    self.LbCheckResult:SetColorAndOpacity(UIHelper.ToSlateColor_LC(Success and UIHelper.LinearColor.Green or UIHelper.LinearColor.Red))
    
    if not Success and string.len(self.NameInput:GetText()) > 0 then
        self.HadNameChecked = true
        self.NameInput:SetTextColorAndOpacity(UIHelper.ToSlateColor_LC(UIHelper.LinearColor.Red))
    end
end

function M:PlayerNameInputChanged(Text)
    print("[NameInputPanel]PlayerNameInputChanged:Text",Text)
end

function M:OnPlayerNameTextCommitted()
    local InputStr = self.TxtPlayerName:GetText()
    print("[NameInputPanel]OnPlayerNameTextCommitted:InputStr",InputStr)
    local FixInputName = StringUtil.Trim(InputStr)
    print("[NameInputPanel]OnPlayerNameTextCommitted:FixInputName",FixInputName)
    self.TxtPlayerName:SetText(FixInputName)
end


function M:OnClickedStartGame()
    local InputName = self.TxtPlayerName:GetText()
    print("[NameInputPanel]OnClickedStartGame:InputName",InputName)
    local FixInputName = StringUtil.Trim(InputName)
    print("[NameInputPanel]OnClickedStartGame:FixInputName",FixInputName)
    if not CommonUtil.AccountCheckValid(FixInputName,self.CharSizeLimit,true) then
        return false
    end
    
    MvcEntry:GetCtrl(LoginCtrl):TryLogin(FixInputName)
    MvcEntry:CloseView(ViewConst.NameInputPanel)
end

--[[
    玩家名称更新
]]
function M:OnPlayerNameUpdate()
    self:UpdatePlayerName(MvcEntry:GetModel(UserModel):GetPlayerName())
end

--- 获取玩家可选头像列表
function M:OnGetPalyerHeadLisrResult()
    self:RandomPlayerHeadList()
    self:UpdatePlayerHeadIcon()
end

function M:RandomPlayerHeadList()
    if #self.UserModel.PlayerHeadList < 0 then
        CLog("[PlayerHeadList] is nil")
        return
    end
    self.CurHeadIconIndex = 1
    self.UserModel.PlayerHeadList = CommonUtil.RandonTableList(self.UserModel.PlayerHeadList)
    self.CurHeadIconId = self.UserModel.PlayerHeadList[self.CurHeadIconIndex]
end

function M:UpdatePlayerHeadIcon()
    local HeroHeadCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroHeadConfig,Cfg_HeroHeadConfig_P.HeadId,self.CurHeadIconId)
    if not HeroHeadCfg then
        return
    end

	local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(HeroHeadCfg.IconPath)
	if ImageSoftObjectPtr ~= nil then
		self.GUIImage_PlayerHeadIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
	end
end

function M:OnRandomHeadIconClicked()
    self.CurHeadIconIndex = self.CurHeadIconIndex + 1
    if self.CurHeadIconIndex >  #self.UserModel.PlayerHeadList then
        self:RandomPlayerHeadList()
    else
        self.CurHeadIconId = self.UserModel.PlayerHeadList[self.CurHeadIconIndex]
    end
    CLog("[OnRandomHeadIconClicked] CurHeadIconIndex:" .. self.CurHeadIconIndex)
    self:UpdatePlayerHeadIcon()
end

function M:HandleTipShow(Show)
    if Show then
        self.NameInputTip:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
        self.NameInputTip:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end
function M:OnHoverTipHovered()
    self:HandleTipShow(true)
end
function M:OnHoverTipOnUnhovered()
    self:HandleTipShow(false)
end
function M:OnHoverTipClicked()
    self:HandleTipShow(true)
end
function M:OnHoverTipLostfocus()
    self:HandleTipShow(false)
end

function M:OnClicked_CloseView()
    MvcEntry:CloseView(ViewConst.NameInputPanel)
end


return M