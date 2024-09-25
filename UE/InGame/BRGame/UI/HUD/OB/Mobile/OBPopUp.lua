--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR 公亮亮
-- @DATE 2024.5.14
--

local class_name = "OBPopUp"
OBPopUp = OBPopUp or BaseClass(GameMediator, class_name);

function OBPopUp:__init()
    
    print("UnLua_OBPopUp:__init")
    self:ConfigViewId(ViewConst.BackToLobbyConfirm)
    
end

require "UnLua"

---@type BP_OBPopUp_C
local OBPopUp = Class("Client.Mvc.UserWidgetBase")

function OBPopUp:OnInit()
    print("UnLua_OBPopUp >> OnInit")

    self.BindNodes ={
        { UDelegate = self.BP_Button_Strong_First.Button.OnClicked, Func = self.OnClicked_Button_Cancel },
        { UDelegate = self.BP_Button_Weak_First.Button.OnClicked, Func = self.OnClicked_Button_Confirm},
    }

    self.BP_Button_Strong_First.Text:SetText(StringUtil.Format("取消"))
    self.BP_Button_Weak_First.Text:SetText(StringUtil.Format("确认"))
    self.Text_Content:SetText(StringUtil.Format("比赛尚未结束，你确定要退出观战吗？"))

    UserWidgetBase.OnInit(self)
end

function OBPopUp:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    print("UnLua_OBPopUp:OnTipsInitialize")
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
end

function OBPopUp:OnDestroy()
    print("UnLua_OBPopUp >> OnDestroy")
	UserWidget.OnDestroy(self)
end

function OBPopUp:OnClicked_Button_Cancel()  -- 点击取消按钮
    print("UnLua_OBPopUp >> OnClicked_Button_Cancel")

    if self.MvcCtrl and self.viewId then
        MvcEntry:CloseView(self.viewId)
        return
    end
   
    self:SetFocus(false)
    
    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    TipsManager:RemoveTipsUI("OBPopUp")
end

function OBPopUp:OnClicked_Button_Confirm()  -- 点击确认按钮
    print("UnLua_OBPopUp >> OnClicked_Button_Confirm")

    self.UIManager = UE.UGUIManager.GetUIManager(self)
    self.UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")

    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    TipsManager:RemoveTipsUI("OBPopUp")
end

function OBPopUp:OnKeyDown(MyGeometry,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    --print("BackToLobbyConfirm:OnKeyDown",PressKey)
    if PressKey == self.BP_Button_Strong_First.Button  then
        self:OnClicked_Button_Cancel()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif  PressKey == BP_Button_Weak_First.Button  then
        self:OnClicked_Button_Confirm()
        return UE.UWidgetBlueprintLibrary.Handled()
    else -- 点击空白位置
        self:OnClicked_Button_Cancel()
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    return UE.UWidgetBlueprintLibrary.Unhandled()
end

return OBPopUp