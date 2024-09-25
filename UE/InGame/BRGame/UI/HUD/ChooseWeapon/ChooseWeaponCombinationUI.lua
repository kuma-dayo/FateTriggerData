require "UnLua"

local ChooseWeaponCombinationUI = Class("Common.Framework.UserWidget")

function ChooseWeaponCombinationUI:Construct()
    self.IsLoad = false
    self.GiveWeaponImmediately = true

     --Listen ChangeMode Message
     self.MsgList_ChooseItemCombination = {
        { MsgName = "GUV.ChooseItemCombination.ChangeMode",    Func = self.OnChangeChooseMode,   bCppMsg = true, WatchedObject = nil },
    }
    MsgHelper:RegisterList(self, self.MsgList_ChooseItemCombination)

    --初始先缓存一次人物的当前武器
    self.CacheItemCombinationGroup.ItemListArray:Clear()
    local DefaultGroup = self.AllItemCombination.ItemGroupArray:Get(1)
    local Len = DefaultGroup.ItemListArray:Length()
    for i = 1 , Len do
        local CurGiveItemList = UE.FGiveInventoryItemList()
        CurGiveItemList.ItemCellArray = DefaultGroup.ItemListArray:Get(Len - i +1).ItemCellArray
        if DefaultGroup.ItemListArray:Get(Len - i +1).DefaultItemCellArray:Length() > 0 then
            local DefaultMag = DefaultGroup.ItemListArray:Get(Len - i +1).DefaultItemCellArray:Get(1)
            CurGiveItemList.ItemCellArray:Add(DefaultMag)
        end
        self.CacheItemCombinationGroup.ItemListArray:Add(CurGiveItemList)  
    end
end

--监听的人物初始化
function ChooseWeaponCombinationUI:OnCharacterBeginPlay()
    self:SendGiveItemMessage()
end

--发送物品进背包的消息
function ChooseWeaponCombinationUI:SendGiveItemMessage()
    MsgHelper:SendCpp(self, GameDefine.MsgCpp.Give_Item_Combination, self.CacheItemCombinationGroup)
    --self:SendItemMessage_Blueprint()
end

--发送关闭UI的消息
function ChooseWeaponCombinationUI:SendCloseUIMessage()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    MsgHelper:SendCpp(LocalPC, GameDefine.MsgCpp.PC_Input_ItemCombination)
end

--打开UI
function ChooseWeaponCombinationUI:OnShow()
    print("ChooseWeaponCombinationUI:OnShow")

    if self.IsLoad then
        return
    else
        self.IsLoad = true
    end 

    --Bind Click
    self.GUIButton.OnClicked:Add(self, self.CloseUI)

    --Creat Weapon Single Widget
    local len = self.AllItemCombination.ItemGroupArray:Length()
    for i = 1, len do
        local CurCombinationSingleWidget = UE.UWidgetBlueprintLibrary.Create(self, self.CombinationSingleClass)

        if CurCombinationSingleWidget.ChooseItemCombination then
            CurCombinationSingleWidget.ChooseItemCombination:Add(self, self.ChooseItemCombination)
        end

        CurCombinationSingleWidget:InitItemCombinationId(self.AllItemCombination.ItemGroupArray:GetRef(i))
        self.HorizontalBox:AddChildToHorizontalBox(CurCombinationSingleWidget)
    end

end

--子UI选择完物品组合和准镜
function ChooseWeaponCombinationUI:ChooseItemCombination(ItemGroup, MagItemList)
    --缓存本地待下发物品组合
    self.CacheItemCombinationGroup = ItemGroup
    --self.CacheItemCombinationGroup.ItemListArray:Add(MagItemList)
    --self.CacheItemSingle = MagItemList

    --关闭
    self:CloseUI()
end

--控制鼠标显隐
function ChooseWeaponCombinationUI:SetShowCursor(ShowCursor)
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        LocalPC.bShowMouseCursor = ShowCursor
    if ShowCursor then
        UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(LocalPC, null, UE.EMouseLockMode.DoNotLock, false)
        self:SetFocus()
    else
        UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(LocalPC, false)
    end
end

--关闭UI
function ChooseWeaponCombinationUI:CloseUI()
    if self.GiveWeaponImmediately then
        self:SendGiveItemMessage()
    end

    --local UIManager = UE.UGUIManager.GetUIManager(self)
    --TryCloseDynamicWidget("UMG_ChooseWeaponCombination")
    self:SendCloseUIMessage()
end

--改变下发模式（默认立即下发）
function ChooseWeaponCombinationUI:OnChangeChooseMode(GiveWeaponImmediately)
    self.GiveWeaponImmediately = GiveWeaponImmediately

    if not GiveWeaponImmediately then
        self.MsgList_GiveItemCombination = {
            { MsgName = "GUV.GiveItemCombination.Begin",    Func = self.OnCharacterBeginPlay,   bCppMsg = true, WatchedObject = nil },
        }
        MsgHelper:RegisterList(self, self.MsgList_GiveItemCombination)
    else
        MsgHelper:UnRegisterList(self, self.MsgList_GiveItemCombination)
    end
    
end
--
return ChooseWeaponCombinationUI






