require "UnLua"

local ChooseWeaponUI = Class("Client.Mvc.UserWidgetBase")

-- 初始化
function ChooseWeaponUI:OnInit()
    print("dyptest ChooseWeaponUI:OnInit")

    self.IsLoad = false
    self.GiveWeaponImmediately = true
    -- 缓存一份动态初始数据
    self.AllItemCombination = self.OriginalItemCombination

    -- Listen ChangeMode Message
    print("dyptest ChooseWeaponUI:OnInit MsgHelper:RegisterList -> self.MsgList_ChooseItemCombination")
    self.MsgList_ChooseItemCombination = {{
        MsgName = "GUV.ChooseItemCombination.ChangeMode",
        Func = self.OnChangeChooseMode,
        bCppMsg = true,
        WatchedObject = nil
    }}

    MsgHelper:RegisterList(self, self.MsgList_ChooseItemCombination)

    -- 初始先缓存一次人物的当前武器
    -- self.SelectedIndex = 1
    self.CacheItemCombinationGroup.ItemListArray:Clear()
    self.CurChooseGiveItemCombination = self.AllItemCombination.ItemGroupArray:Get(1)
    local Len = self.CurChooseGiveItemCombination.ItemListArray:Length()
    for i = 1, Len do
        local CurGiveItemList = UE.FGiveInventoryItemList()
        CurGiveItemList.ItemCellArray = self.CurChooseGiveItemCombination.ItemListArray:Get(Len - i + 1).ItemCellArray
        if self.CurChooseGiveItemCombination.ItemListArray:Get(Len - i + 1).DefaultItemCellArray:Length() > 0 then
            local DefaultMag =
                self.CurChooseGiveItemCombination.ItemListArray:Get(Len - i + 1).DefaultItemCellArray:Get(1)
            CurGiveItemList.ItemCellArray:Add(DefaultMag)
        end
        self.CacheItemCombinationGroup.ItemListArray:Add(CurGiveItemList)
    end

    --[[
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
    ]]

    self.GameState = UE.UGameplayStatics.GetGameState(self)

    UserWidgetBase.OnInit(self)
end


function ChooseWeaponUI:OnDestroy()
    print("dyptest ChooseWeaponUI:OnDestroy")
    if self.MsgList_ChooseItemCombination then
        print("dyptest ChooseWeaponUI:OnDestroy MsgHelper:UnregisterList -> self.MsgList_ChooseItemCombination")
        MsgHelper:UnregisterList(self, self.MsgList_ChooseItemCombination)
        self.MsgList_ChooseItemCombination = nil
    end

    self:UnListenGiveItemCombinationBegin()

    UserWidgetBase.OnDestroy(self)
end


-- 监听的人物初始化
function ChooseWeaponUI:OnCharacterBeginPlay()
    print("dyptest ChooseWeaponUI:OnCharacterBeginPlay")
    self:SendGiveItemMessage()
end

-- 发送物品进背包的消息
function ChooseWeaponUI:SendGiveItemMessage()
    print("dyptest ChooseWeaponUI:SendGiveItemMessage")
    -- MsgHelper:SendCpp(self, GameDefine.MsgCpp.Give_Item_Combination, self.CacheItemCombinationGroup)
    self:SendItemMessage_Blueprint()

end

-- 发送关闭UI的消息
function ChooseWeaponUI:SendCloseUIMessage()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    MsgHelper:SendCpp(LocalPC, GameDefine.MsgCpp.PC_Input_ItemCombination)
end

-- 打开UI
function ChooseWeaponUI:OnShow(Date, Blackboard)
    print("ChooseWeaponUI:OnShow",self.IsLoad)

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    --UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(LocalPC,self,UE.EMouseLockMode.DoNotLock,false)
    --UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(LocalPC,self)
    if self.IsLoad then
        local len_UINum = self.ChooseWeaponSingleUIList:Length()
        for i = 1, len_UINum do
            if self.SelectedIndex == i then
                self.ChooseWeaponSingleUIList:Get(i):ChangeSelectState(true)
            else
                self.ChooseWeaponSingleUIList:Get(i):ChangeSelectState(false)
            end
            self.ChooseWeaponSingleUIList:Get(i):ChangeMagUIState(false)
        end
        return
    else
        self.SelectedIndex = 1
        self.IsLoad = true
    end


    local AllStateTimeSelector = UE.FGenericBlackboardKeySelector()
    AllStateTimeSelector.SelectedKeyName = "AllStateTime"
    local OutAllStateTime, IsFindAllStateTime = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsFloat(
        Blackboard, AllStateTimeSelector)
    if not IsFindAllStateTime then
        print("ChooseWeaponUI:IsNotFindAllStateTime")
        return
    end
    self.AllStateTime = OutAllStateTime

    -- Confirm Button
    --self.WBP_CommonBtn_Confirm.GUIButton_Tips.OnClicked:Add(self, self.ClickConfirmButton)
    --self.WBP_CommonBtn_Confirm.GUIButton_Tips.OnHovered:Add(self, self.OnHoveredConfirmButton)
    --self.WBP_CommonBtn_Confirm.GUIButton_Tips.OnUnhovered:Add(self, self.OnUnhoveredConfirmButton)

    --self.WBP_CommonBtn_Confirm.ControlTipsTxt:SetText(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ChooseWeaponUI_Confirmselection"))
    self.WBP_CommonBtn_Confirm.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)

    UIHandler.New(self, self.WBP_CommonBtn_Confirm, WCommonBtnTips,
            {
                OnItemClick = Bind(self,self.ClickConfirmButton),
                TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_ChooseWeaponUI_Confirmselection"),
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            })


    -- Bind OnChooseSingleUIUpdate
    self.ChooseWeaponSingleUIList = UE.TArray(UE.UWidget)
    self.WBP_ReuseList.OnUpdateItem:Add(self, self.OnChooseSingleUIUpdate)

    -- Creat Weapon Single Widget
    local len = self.AllItemCombination.ItemGroupArray:Length()
    self.WBP_ReuseList:Reload(len)
end


function ChooseWeaponUI:OnHoveredConfirmButton()
    -- self.WBP_CommonBtn_Confirm.ControlTipsIcon:SetColorAndOpacity(self.ConfirmButtonHoverColor)
    self.WBP_CommonBtn_Confirm.ControlTipsTxt:SetColorAndOpacity(self.ConfirmButtonHoverColor)
end

function ChooseWeaponUI:OnUnhoveredConfirmButton()
    -- self.WBP_CommonBtn_Confirm.ControlTipsIcon:SetColorAndOpacity(self.ConfirmButtonUnhoverColor)
    -- self.WBP_CommonBtn_Confirm:SetForegroundColor(self.ConfirmButtonForegroundColor)
    self.WBP_CommonBtn_Confirm.ControlTipsTxt:SetColorAndOpacity(self.ConfirmButtonUnhoverColor)
end

function ChooseWeaponUI:OnChooseSingleUIUpdate(Widget, Index)
    local i = Index + 1
    local CurCombinationSingleWidget = Widget
    if CurCombinationSingleWidget.ChooseItemCombination then
        CurCombinationSingleWidget.ChooseItemCombination:Add(self, self.ChooseItemCombination)
    end
    CurCombinationSingleWidget:InitItemCombinationId(self.AllItemCombination.ItemGroupArray:GetRef(i), i)

    -- 初始默认选择第一个
    if i == 1 then
        self.ChooseWeaponSingleUIList:Clear()
        CurCombinationSingleWidget:ChangeSelectState(true)
    end

    self.ChooseWeaponSingleUIList:Add(CurCombinationSingleWidget)
end

-- 子UI选择完物品组合和准镜
function ChooseWeaponUI:ChooseItemCombination(MainMagId, SecondMagId, Index)
    self.CacheSelectedIndex = Index
    -- 修改对应武器套装初始准镜
    self.CurChooseGiveItemCombination = self.AllItemCombination.ItemGroupArray:GetRef(Index)
    self.CurChooseGiveItemCombination.ItemListArray:GetRef(1).DefaultItemCellArray:GetRef(1).ItemId = MainMagId
    self.CurChooseGiveItemCombination.ItemListArray:GetRef(2).DefaultItemCellArray:GetRef(1).ItemId = SecondMagId
    -- 更改完后，并不会写入缓存，而是点击确认按钮后才会

    -- 改变子UI选择状态
    -- 需要改变其他子UI的准镜界面显示状态
    local len_UINum = self.ChooseWeaponSingleUIList:Length()
    for i = 1, len_UINum do
        if self.ChooseWeaponSingleUIList:Get(i).Index == Index then
            self.ChooseWeaponSingleUIList:Get(i):ChangeSelectState(true)
            -- self.ChooseWeaponSingleUIList:Get(i):ChangeMagUIState(true)
        else
            self.ChooseWeaponSingleUIList:Get(i):ChangeSelectState(false)
            self.ChooseWeaponSingleUIList:Get(i):ChangeMagUIState(false)
        end
    end

end

-- 关闭UI
function ChooseWeaponUI:ClickConfirmButton()
    -- 缓存本地待下发物品组合
    -- 将FChooseItemCombineGroup转换为FGiveInventoryItemList
    self.CacheItemCombinationGroup.ItemListArray:Clear()
    local Len_Item = self.CurChooseGiveItemCombination.ItemListArray:Length()
    for i = 1, Len_Item do
        local CurItemList = UE.FGiveInventoryItemList()
        CurItemList.ItemCellArray = self.CurChooseGiveItemCombination.ItemListArray:Get(Len_Item - i + 1).ItemCellArray
        if self.CurChooseGiveItemCombination.ItemListArray:Get(Len_Item - i + 1).DefaultItemCellArray:Length() > 0 then
            CurItemList.ItemCellArray:Add(self.CurChooseGiveItemCombination.ItemListArray:Get(Len_Item - i + 1)
                                              .DefaultItemCellArray:Get(1))
        end
        self.CacheItemCombinationGroup.ItemListArray:Add(CurItemList)
    end

    -- 将所有子UI的准镜状态都设置为关闭
    local len_UINum = self.ChooseWeaponSingleUIList:Length()
    for i = 1, len_UINum do
        self.ChooseWeaponSingleUIList:Get(i):ChangeMagUIState(false)
    end

    -- 更改当前选择组合ID
    self.SelectedIndex = self.CacheSelectedIndex

    if self.GiveWeaponImmediately then
        self:SendGiveItemMessage()
    end

    self:SendCloseUIMessage()
end

-- 改变下发模式（默认立即下发）
function ChooseWeaponUI:OnChangeChooseMode(GiveWeaponImmediately)
    print("dyptest ChooseWeaponUI:OnChangeChooseMode",GiveWeaponImmediately)
    self.GiveWeaponImmediately = GiveWeaponImmediately

    -- 这里因为GiveWeaponImmediately只会是false，所以不再做判断，并且在 listen 之前强制 unlisten
    -- if not GiveWeaponImmediately then
    -- else
    -- end

    -- 解绑
    self:UnListenGiveItemCombinationBegin()
    --MsgHelper:UnRegisterList(self, self.MsgList_GiveItemCombination)

    -- 绑定
    print("dyptest ChooseWeaponUI:OnChangeChooseMode ListenObjectMessage->GUV.GiveItemCombination.Begin")
    self.HandleGiveItemCombinationBegin = ListenObjectMessage(nil, "GUV.GiveItemCombination.Begin", self, self.OnCharacterBeginPlay)

    -- self.MsgList_GiveItemCombination = {{
    --     MsgName = "GUV.GiveItemCombination.Begin",
    --     Func = self.OnCharacterBeginPlay,
    --     bCppMsg = true,
    --     WatchedObject = nil
    -- }}
    -- MsgHelper:RegisterList(self, self.MsgList_GiveItemCombination)
    self.Text_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Text_Tips:SetVisibility(UE.ESlateVisibility.Visible)

    -- 这里隐含了一个业务情况，就是从服务器调用 OnChangeChooseMode(false) 的时机。
    -- 可能当前玩家可能手中没有正确的武器，需要重新下发一次，是为了简化流程，才在 OnChangeChooseMode 触发时，重新下发一次当前选择武器。
    self:SendGiveItemMessage()
    -- self:CloseUI()

end


function ChooseWeaponUI:Tick(MyGeometry, InDeltaTime)
    if self.GiveWeaponImmediately then
        local RemainTime = self.AllStateTime - self.GameState:GetReplicatedWorldTimeSeconds()
        if RemainTime >= 0 then
            local IntRemainTime = UE.UKismetMathLibrary.FCeil(RemainTime)
            self.Text_Time:SetText(self:FormatTime(IntRemainTime))
        else
        end
    else
        return
    end
end

-- 将总时长（秒）转化为{X}min:{Y}sec 并且不足两位数时转化为{0X}
function ChooseWeaponUI:FormatTime(InTime)
    local Min = math.floor(InTime / 60)
    local Sec = InTime % 60
    local FormatMin = Min >= 10 and (Min) or ("0" .. Min)
    local FormatSec = Sec >= 10 and (Sec) or ("0" .. Sec)
    return (FormatMin .. ":" .. FormatSec)
end

--截取按键输入，防止点击背景时开枪（分支临时修改，主干UI会做统一处理）
-- function ChooseWeaponUI:OnKeyDown(MyGeometry,InKeyEvent)  
--     local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
--     --print("BackToLobbyConfirm:OnKeyDown",PressKey)
--     return UE.UWidgetBlueprintLibrary.Handled()
-- end

--

--function ChooseWeaponUI:OnClose(Destroy)
    --local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    --UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(LocalPC)
--end

function ChooseWeaponUI:UnListenGiveItemCombinationBegin()
    print("dyptest ChooseWeaponUI:UnListenGiveItemCombinationBegin")
    if self.HandleGiveItemCombinationBegin then
        if self.HandleGiveItemCombinationBegin ~= 0 then
            print("ChooseWeaponUI:UnListenGiveItemCombinationBegin UnListenObjectMessage->GUV.GiveItemCombination.Begin")
            UnListenObjectMessage("GUV.GiveItemCombination.Begin", self, self.HandleGiveItemCombinationBegin)
            self.HandleGiveItemCombinationBegin = nil
        end
    end
end


return ChooseWeaponUI

