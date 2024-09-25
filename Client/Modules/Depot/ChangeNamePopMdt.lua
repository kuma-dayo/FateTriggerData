--[[
    改名卡操作界面
]]

local class_name = "ChangeNamePopMdt";
ChangeNamePopMdt = ChangeNamePopMdt or BaseClass(GameMediator, class_name);

function ChangeNamePopMdt:__init()
end

function ChangeNamePopMdt:OnShow(data)
    
end

function ChangeNamePopMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.MsgList = 
    {
		{Model = UserModel, MsgName = UserModel.ON_GET_RANDOM_NAME, Func = self.OnGetRandomName},
		{Model = UserModel, MsgName = UserModel.ON_CHECK_NAME_VALID_RESULT, Func = self.OnCheckNameValid},
		{Model = UserModel, MsgName = UserModel.ON_MODIFY_NAME_SUCCESS, Func = self.OnClicked_CloseView},
    }

    self.BindNodes = 
    {
        { UDelegate = self.BtnHoverTip.OnClicked,				Func = self.OnHoverTipClicked },
		{ UDelegate = self.BtnHoverTip.OnHovered,				Func = self.OnHoverTipHovered },
		{ UDelegate = self.BtnHoverTip.OnUnhovered,				Func = self.OnHoverTipOnUnhovered },
		{ UDelegate = self.BtnHoverTip.OnFocusLosted,				Func = self.OnHoverTipLostfocus },
        { UDelegate = self.WBP_ChangeNamePop.GUIButton_Main.OnClicked,				Func = self.OnClickedBtnRandom },
	}

    local PopUpBgParam = {
		HideCloseTip = true,
	}
	self.CommonPopUp_BgIns = UIHandler.New(self,self.WBP_CommonPopUp_Bg_L, CommonPopUpBgLogic, PopUpBgParam).ViewInstance

    self.Model = MvcEntry:GetModel(DepotModel)
    self.CharSizeLimit = CommonUtil.GetParameterConfig(ParameterConfig.NickNameLimit,14)
    local CommonDescCfg = G_ConfigHelper:GetSingleItemById(Cfg_CommonDesc,1001)
    if CommonDescCfg then
        self.GUITextTittle:SetText(StringUtil.Format(CommonDescCfg.Tittle))
        self.GUITextContent:SetText(StringUtil.Format(CommonDescCfg.Content))
    end
    self:InitBtns()
end

function M:OnHide()
   
end

-- 通用按钮定义
function M:InitBtns()
    -- 返回
    UIHandler.New(self, self.WBP_CommonBtn_Cancel, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnClicked_CloseView),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_ChangeNamePopMdt_return_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

   UIHandler.New(self, self.WBP_CommonBtn_Enter, WCommonBtnTips, 
    {
        OnItemClick = Bind(self, self.OnEnterFunc),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_ChangeNamePopMdt_Confirmmodification_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

    -- 注册输入控件处理
    UIHandler.New(self,self,CommonTextBoxInput,{
        InputWigetName = "NameInput",
        SizeLimit = self.CharSizeLimit,
        FoucsViewId = ViewConst.ChangeNamePopMdt,
        OnTextChangedFunc = self.ClearCheckResult,
        OnTextCommittedEnterFunc = self.OnEnterFunc,
    })
end
 
function M:ClearCheckResult()
    self.LbCheckResult:SetVisibility(UE.ESlateVisibility.Hidden)
    self.LbCheckResult:SetText("")
    if self.HadNameChecked then
        self.HadNameChecked = false
        self.NameInput:ResetTextColorAndOpacity()
    end
end

function M:OnGetRandomName(Name)
    self.NameInput:SetText(Name)
end

function M:OnClickedBtnRandom()
    MvcEntry:GetCtrl(UserCtrl):SendProto_RandomNameReq(true)
end
 
function M:OnClicked_CloseView()
    MvcEntry:CloseView(self.viewId)
end

function M:OnEnterFunc()
    self.CurPlayerName = self.NameInput:GetText()
    local FixPlayerName = StringUtil.Trim(self.CurPlayerName)
    if not CommonUtil.PlayerNameCheckValid(FixPlayerName,self.CharSizeLimit) then
        self:UpdateCreateFailResult(nil, StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_ChangeNamePopMdt_Namelengthdoesnotmee")))
        return
    end
    MvcEntry:GetCtrl(UserCtrl):SendProto_CheckNameReq(FixPlayerName)
end

function M:OnCheckNameValid(Msg)
    if Msg.ErrCode == 0 then
        local FixPlayerName = Msg.Name
        local msgParam = {
            describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_ChangeNamePopMdt_Areyousureyouwanttoc")),
            rightBtnInfo = {            
                name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_ChangeNamePopMdt_sure")),          
                callback =  function()
                    -- 请求改名
                    MvcEntry:GetCtrl(UserCtrl):ModifyNameReq(FixPlayerName)
                end  
            },
            leftBtnInfo = {        
                name = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_ChangeNamePopMdt_cancel_Btn")),          
            }    
        }
        UIMessageBox.Show(msgParam)
    else
        self:UpdateCreateFailResult(Msg.ErrCode)
    end
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
    self.LbCheckResult:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.LbCheckResult:SetText(Msg)
    self.LbCheckResult:SetColorAndOpacity(UIHelper.ToSlateColor_LC(UIHelper.LinearColor.Red))
    
    if string.len(self.NameInput:GetText()) > 0 then
        self.HadNameChecked = true
        self.NameInput:SetTextColorAndOpacity(UIHelper.ToSlateColor_LC(UIHelper.LinearColor.Red))
    end
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


return M