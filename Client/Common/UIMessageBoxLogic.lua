local Const = {
    DefaultLeftBtnTipIcon = CommonConst.CT_BACK,
    DefaultLeftBtnActionMappingKey = ActionMappings.Escape,
    
    DefaultRightBtnTipIcon = CommonConst.CT_SPACE,
    DefaultRightBtnActionMappingKey = ActionMappings.SpaceBar,
    
    DefaultZOrder = 100,
}

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    Const.DefaultTitle = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_pointout")
    Const.DefaultLeftBtnName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_cancel_Btn")
    Const.DefaultRightBtnName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_confirm_Btn")
    self.BindNodes = 
    {
		{ UDelegate = self.TextBlock_Detail.OnHyperlinkClicked,		Func = self.OnHyperlinkClicked },
	}
    
    self.WCommonBtn_Cancel:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WCommonBtn_Confirm:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.TextBlock_Warning then
        self.TextBlock_Warning:SetVisibility(UE.ESlateVisibility.Collapsed)
    end    
end

function M:OnShow(msg)
    self.MsgParam = msg
    
    -- --1.设置标题
    -- if self.TextBlock_Title then
    --     self.MsgParam.title = self.MsgParam.title or Const.DefaultTitle
    --     self.TextBlock_Title:SetText(StringUtil.Format(self.MsgParam.title))
    -- end

    local PopUpBgParam = {
		TitleText = self.MsgParam.title,
		HideCloseTip = self.MsgParam.HideCloseTip or false,
        HideCloseBtn = self.MsgParam.HideCloseBtn or false,
        CloseCb =  Bind(self,self.OnClicked_CancelBtn),
        -- CloseCb =  Bind(self,self.OnClicked_ConfirmBtn),
	}
    if self.CommonPopUpBgIns == nil or not(self.CommonPopUpBgIns:IsValid()) then
        self.CommonPopUpBgIns = UIHandler.New(self,self.WBP_CommonPopUp_Bg_L, CommonPopUpBgLogic, PopUpBgParam).ViewInstance
    else
        self.CommonPopUpBgIns:ManualOpen(PopUpBgParam)
    end
    
    
    --2.设置描述
    self.TextBlock_Detail:SetText(StringUtil.Format(self.MsgParam.describe))
 

    if self.TextBlock_Warning and self.MsgParam.warningDec then
        self.TextBlock_Warning:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TextBlock_Warning:SetText(StringUtil.Format(self.MsgParam.warningDec))
    end

    --3.处理右【确认】侧按钮显示，右侧遵循之前的逻辑，一定会展示
    self.MsgParam.rightBtnInfo = self.MsgParam.rightBtnInfo or {}
    self.MsgParam.rightBtnInfo.name = self.MsgParam.rightBtnInfo.name or Const.DefaultRightBtnName
    self.MsgParam.rightBtnInfo.iconID = self.MsgParam.rightBtnInfo.iconID or Const.DefaultRightBtnTipIcon
    self.MsgParam.rightBtnInfo.actionMappingKey = self.MsgParam.rightBtnInfo.actionMappingKey or Const.DefaultRightBtnActionMappingKey
    
    self.WCommonBtn_Confirm:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local Param = {
        OnItemClick = Bind(self,self.OnClicked_ConfirmBtn),
        CommonTipsID = self.MsgParam.rightBtnInfo.iconID,
        TipStr = self.MsgParam.rightBtnInfo.name,
        ActionMappingKey = self.MsgParam.rightBtnInfo.actionMappingKey,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    }

    if self.WCommonBtn_ConfirmIns == nil or not(self.WCommonBtn_ConfirmIns:IsValid()) then
        self.WCommonBtn_ConfirmIns = UIHandler.New(self, self.WCommonBtn_Confirm, WCommonBtnTips,Param).ViewInstance
    else
        self.WCommonBtn_ConfirmIns:ManualOpen(Param)
    end
    

    --4.处理左侧【取消】按钮显示，这里只有有参数才做展示
    if self.MsgParam.leftBtnInfo then
        self.MsgParam.leftBtnInfo.name = self.MsgParam.leftBtnInfo.name or Const.DefaultLeftBtnName
        self.MsgParam.leftBtnInfo.iconID = self.MsgParam.leftBtnInfo.iconID or Const.DefaultLeftBtnTipIcon
        self.MsgParam.leftBtnInfo.actionMappingKey = self.MsgParam.leftBtnInfo.actionMappingKey or Const.DefaultLeftBtnActionMappingKey

        self.WCommonBtn_Cancel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local CancelParam ={
            OnItemClick = Bind(self,self.OnClicked_CancelBtn),
            CommonTipsID = self.MsgParam.leftBtnInfo.iconID,
            TipStr = self.MsgParam.leftBtnInfo.name,
            ActionMappingKey = self.MsgParam.leftBtnInfo.actionMappingKey,
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        }
        if self.WCommonBtn_CancelIns == nil or not(self.WCommonBtn_CancelIns:IsValid()) then
            self.WCommonBtn_CancelIns = UIHandler.New(self, self.WCommonBtn_Cancel, WCommonBtnTips,CancelParam).ViewInstance
        else
            self.WCommonBtn_CancelIns:ManualOpen(CancelParam)
        end
    end
    -- 放到InputCtrl中统一处理
    -- -- 当此界面打开时，缓存当前的InputModeData，将InputMode改为GameAndUI，待界面关闭，再设回缓存的Mode
    -- local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    -- if LocalPC then
    --     self.CurInputModeData = LocalPC:GetCurInputModeData()
    --     UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(LocalPC,self,UE.EMouseLockMode.DoNotLock,false)
    -- else
    --     CWaring("UIMessageBoxLogic Can't Get LocalPC !",true)
    -- end
end

function M:OnRepeatShow(Params)
    if Params and Params.bRepeatShow then
        self:OnShow(Params)
    end
end

function M:OnHide()

end

---左侧按钮/取消按钮点击函数，点击后优先触发回调，然后再关闭界面
function M:OnClicked_CancelBtn()
    if self.MsgParam and self.MsgParam.leftBtnInfo and self.MsgParam.leftBtnInfo.callback then
        self.MsgParam.leftBtnInfo.callback()
    end
    
    self:_DoClose()
end

---右侧按钮/确认点击函数，点击后优先触发回调，然后再关闭界面
function M:OnClicked_ConfirmBtn()
    if self.MsgParam and self.MsgParam.rightBtnInfo then
        if self.MsgParam.rightBtnInfo.callback then
            self.MsgParam.rightBtnInfo.callback()
        end
        -- if self.MsgParam.rightBtnInfo.bNotClose then
        --     Timer.InsertTimer(3, function ()
        --         self:_DoClose()
        --     end
        --     )
        --     return
        -- end
    end

    if self.MsgParam and self.MsgParam.rightBtnInfo and self.MsgParam.rightBtnInfo.DelayCloseTime and self.MsgParam.rightBtnInfo.DelayCloseTime > 0 then
        self:AddOrCleanDelayCloseTimer(true, self.MsgParam.rightBtnInfo.DelayCloseTime)
    else
        self:_DoClose()
    end
end

function M:AddOrCleanDelayCloseTimer(IsAdd,DelayTime)
    if self.DelayCloseTimerHandler then
        self:RemoveTimer(self.DelayCloseTimerHandler)
        self.DelayCloseTimerHandler = nil
    end
    if IsAdd then
        self.DelayCloseTimerHandler = self:InsertTimer(DelayTime,function ()
            self:_DoClose()
        end)
    end
end

---关闭界面函数，会触发关闭界面回调
function M:_DoClose()
    -- -- 界面关闭，设回缓存的InputMode
    -- if self.CurInputModeData then
    --     CommonUtil.SetInputModeData(self.CurInputModeData)
    -- end
    if self.MsgParam and self.MsgParam.closeCallback then
        self.MsgParam.closeCallback()
    end
    self:AddOrCleanDelayCloseTimer(false)
    MvcEntry:CloseView(self.viewId)

    if self.MsgParam and self.MsgParam.closeAfterCallback then
        self.MsgParam.closeAfterCallback()
    end
end

function M:OnHyperlinkClicked(Action)
    if self.MsgParam and self.MsgParam.hyperlinkCallback then
        self.MsgParam.hyperlinkCallback(Action)
    end
end


return M