require "UnLua"

local BirthLandEditCurrency = Class("Client.Mvc.UserWidgetBase")

function BirthLandEditCurrency:OnInit()
    print("BirthLandEditCurrency:OnInit")
    UserWidget.OnInit(self)
   
    if self.WBP_CommonPopUp_Bg_L.TextBlock_Title then
        self.WBP_CommonPopUp_Bg_L.TextBlock_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_Currency_BroughtInNumber")))
    end
    
    -- WBP_CommonEditableSlider（滑动条）
    self.SliderInst = UIHandler.New(self, self.WBP_CommonEditableSlider, CommonEditableSlider).ViewInstance 

    -- WBP_CommonBtn_Weak_M_New (取消)
    UIHandler.New(self, self.WBP_CommonBtn_Weak_M_New, WCommonBtnTips, {
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_cancel")),
        CommonTipsID = CommonConst.CT_ESC,
        OnItemClick = Bind(self, self.OnBtnClickedESC),
    })

    -- WBP_CommonBtn_Strong_M_New（确认）
    UIHandler.New(self, self.WBP_CommonBtn_Strong_M_New, WCommonBtnTips, {
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_confirm")),
        TipTxt = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_Currency_CurrentHaving")),
        CommonTipsID = CommonConst.CT_SPACE,
        OnItemClick = Bind(self, self.OnBtnClickedSpace),
    })
end

function BirthLandEditCurrency:OnClose()
    print("BirthLandEditCurrency:OnClose")
end

function BirthLandEditCurrency:OnDestroy()
    print( "BirthLandEditCurrency:OnDestroy")
    UserWidget.OnDestroy(self)
end

function BirthLandEditCurrency:OnShow(InContext, Blackboard)
    local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackboardKeySelector.SelectedKeyName ="BirthlandAbilityPtr"
    local BirthlandAbilityPtr, bFindAbility = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsObject(Blackboard, BlackboardKeySelector)
    if BirthlandAbilityPtr == nil then
        CError("BirthLandEditCurrency:OnShow Failed, BirthlandAbilityPtr=nil !!", true)
        return
    end

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPS = LocalPC.OriginalPlayerState
    print("BirthLandEditCurrency:OnShow PlayerId="..LocalPS:GetPlayerId()..", MaxInitCurrencyToCarry="..BirthlandAbilityPtr.MaxInitCurrencyToCarry)

    local PlayerExInfo = UE.UPlayerExSubsystem.Get(self):GetPlayerExInfoByPlayerState(LocalPS)
    if PlayerExInfo == nil then
        CError("BirthLandEditCurrency:OnShow Failed, PlayerExInfo=nil !!", true)
        return
    end

    local LobbyCurrency = PlayerExInfo:GetLobbyVirtualCurrency()
    self.Text_Currency:SetText(LobbyCurrency)

    -- WBP_CommonEditableSlider
    local SliderMaxValue = (BirthlandAbilityPtr.MaxInitCurrencyToCarry > LobbyCurrency) and LobbyCurrency or BirthlandAbilityPtr.MaxInitCurrencyToCarry
    self.CurSliderValue = PlayerExInfo:GetBaseVirtualCurrency()
    print("BirthLandEditCurrency:OnShow ".."CurSliderValue="..self.CurSliderValue)

    local SliderParam = {
        Gap = 50,
        MinValue = 0,
        MaxValue = SliderMaxValue,
        AllowMaxIsZero = true,
        DefaultValue = self.CurSliderValue,
        ValueChangeCallBack = Bind(self, self.SliderValueChangeCallBack),
    }
    self.SliderInst:UpdateItemInfo(SliderParam)
    
    print("BirthLandEditCurrency:OnShow End")
end


function BirthLandEditCurrency:InitWidget()
    print("BirthLandEditCurrency:InitWidget")
end

function BirthLandEditCurrency:CloseSelf()
    print("BirthLandEditCurrency CloseSelf")
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager then
        print("close self")
        UIManager:TryCloseDynamicWidget("UMG_Birthland_EditCurrency")
    end
end

function BirthLandEditCurrency:OnKeyDown(MyGeometry, InKeyEvent)
    local MouseKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    
    if MouseKey.KeyName == "Escape" then
        self:CloseSelf()
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    return UE.UWidgetBlueprintLibrary.Unhandled()
end


function BirthLandEditCurrency:OnBtnClickedESC()
    self:CloseSelf()
end


function BirthLandEditCurrency:OnBtnClickedSpace()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPS = LocalPC.OriginalPlayerState
    print("BirthLandEditCurrency:OnBtnClickedSpace PlayerId="..LocalPS:GetPlayerId()..", CurSliderValue="..self.CurSliderValue)

    local PlayerExInfo = UE.UPlayerExSubsystem.Get(self):GetPlayerExInfoByPlayerState(LocalPS)
    if PlayerExInfo then
        PlayerExInfo:ServerRPC_SetBaseVirtualCurrency(self.CurSliderValue)
    end
    
    self:CloseSelf()
end


function BirthLandEditCurrency:SliderValueChangeCallBack(CurValue)
    print("BirthLandEditCurrency:SliderValueChangeCallBack CurValue="..CurValue)
    self.CurSliderValue = CurValue
end

return BirthLandEditCurrency