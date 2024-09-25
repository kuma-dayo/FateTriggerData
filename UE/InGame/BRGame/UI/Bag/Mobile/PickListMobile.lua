
require "UnLua"
require ("InGame.BRGame.ItemSystem.ItemSystemHelper")

local PickListMobile = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function PickListMobile:Initialize(Initializer)
end

function PickListMobile:OnInit()
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDying,	Func = self.CharacterBeginDying,        bCppMsg = true, WatchedObject = nil},
        { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDead,	Func = self.CharacterBeginDead,         bCppMsg = true, WatchedObject = nil},
        { MsgName = "Bag.ReadyPickup.Update",	            Func = self.ReadyPickupUpdate,          bCppMsg = true, WatchedObject = nil},
    }
    self.BindNodes = {
        { UDelegate = self.GUIButton_Switch.OnClicked,      Func = self.OnSwitchButtonClick },
        { UDelegate = self.GUIButton_Close.OnClicked,       Func = self.OnCloseButtonClick },
    }

    self:UpdateAutoPickBagOpen()

    UserWidget.OnInit(self)
end

function PickListMobile:OnDestroy()
    UserWidget.OnDestroy(self)
end

-------------------------------------------- Function ------------------------------------

function PickListMobile:Tick(MyGeometry, InDeltaTime)

end

function PickListMobile:OnSwitchButtonClick()
    if not self.BP_ItemList_M then
        return
    end
    self.BP_ItemList_M:SwitchCol()
    self.GUITextBlock_Switch:SetText(self.BP_ItemList_M.SingleCol and G_ConfigHelper:GetStrFromCommonStaticST("Lua_PickListMobile_singlefilerow") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_PickListMobile_biserial"))
end

function PickListMobile:OnCloseButtonClick()
    if self.CanvasPanel_List:IsVisible() then
        self.CanvasPanel_List:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.GUIImage_Icon:SetBrushFromSoftTexture(self.ShowImage)
    else
        self.GUIImage_Icon:SetBrushFromSoftTexture(self.HideImage)
        self.CanvasPanel_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self:UpdateAutoPickBagOpen()
end

function PickListMobile:UpdateAutoPickBagOpen()

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not LocalPC then
        return
    end
    local tPawn = LocalPC:GetPawn()
    if not tPawn then
        return
    end
    local AutoPickGA = UE.UPickupStatics.GetAutoPickupAbility(tPawn)
    if not AutoPickGA then
        return
    end
    AutoPickGA.bIsBagOpen = self.CanvasPanel_List:IsVisible()
end

function PickListMobile:ReadyPickupUpdate()
    if not self.BP_ItemList_M then
        return
    end
    self.BP_ItemList_M:ReadyPickupUpdate()
    if self.BP_ItemList_M:IsVisible() then
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function PickListMobile:CharacterBeginDying(InDyingMessageInfo)
    self:TryCloseUI(InDyingMessageInfo.DyingActor)
end

function PickListMobile:CharacterBeginDead(InDeadMessageInfo)
    self:TryCloseUI(InDeadMessageInfo.DeadActor)
end

function PickListMobile:TryCloseUI(InActor)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not InActor then return end
    if PlayerController == InActor:GetController() then
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

return PickListMobile