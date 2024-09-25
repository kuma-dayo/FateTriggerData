require "UnLua"
require ("InGame.BRGame.ItemSystem.ItemSystemHelper")
require ("InGame.BRGame.ItemSystem.PickSystemHelper")
require ("Common.Utils.StringUtil")

local SimpleReadyPickListUI = Class("Common.Framework.UserWidget")


function SimpleReadyPickListUI:OnInit()
    local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalGS = UE.UGameplayStatics.GetGameState(self)
    local LocalPS = PC and PC.PlayerState or nil

    self.MsgList = { {
        MsgName = "EnhancedInput.PickHoldPressStart",
        Func = self.PickHoldStart,
        bCppMsg = true,
        WatchedObject = nil
    },{
        MsgName = "EnhancedInput.PickHoldEnd",
        Func = self.PickHoldEnd,
        bCppMsg = true,
        WatchedObject = nil
    },  {
        MsgName = "EnhancedInput.PickSystem.LastPickOption",
        Func = self.LastPickOption,
        bCppMsg = true,
        WatchedObject = nil
    }, {
        MsgName = "EnhancedInput.PickSystem.NextPickOption",
        Func = self.NextPickOption,
        bCppMsg = true,
        WatchedObject = nil
    }, {
        MsgName = "PlayerState.Update.CollectGenePlayerIds",
        Func = self.CollectGenePlayerIds,
        bCppMsg = true,
        WatchedObject = LocalPS
    }, {
        MsgName = "Bag.ReadyPickup.Update",
        Func = self.UpdateTracePickup,
        bCppMsg = true,
        WatchedObject = nil
    }, {
        MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDying,
        Func = self.CharacterBeginDying,
        bCppMsg = true,
        WatchedObject = nil
    }, {
        MsgName = GameDefine.MsgCpp.PLAYER_OnEndDying,
        Func = self.CharacterEndDying,
        bCppMsg = true,
        WatchedObject = nil
    }, {
        MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDead,
        Func = self.CharacterBeginDead,
        bCppMsg = true,
        WatchedObject = nil
    }, {
        MsgName = GameDefine.MsgCpp.PLAYER_OnEndDead,
        Func = self.CharacterEndDead,
        bCppMsg = true,
        WatchedObject = nil
    }, {
        MsgName = "PickDropSystem.UpdatePickInfoMode",
        Func = self.SetPickInfoMode,
        bCppMsg = true,
        WatchedObject = nil
    }, {
        MsgName = GameDefine.Msg.PLAYER_ItemSlots,
        Func = self.ItemSlotChange,
        bCppMsg = true
    }, {
        MsgName = GameDefine.Msg.PLAYER_EquipmentHandleChange,
        Func = self.UpdateTracePickup,
        bCppMsg = true
    }, {
        MsgName = GameDefine.MsgCpp.PLAYER_CollectGenePlayerId,
        Func = self.OnCollectGenePlayerId,
        bCppMsg = true,
        WatchedObject = nil
    },
    {
        MsgName = "EnhancedInput.HoldReplcePick",
        Func = self.OnHoldReplcePick,
        bCppMsg = true,
        WatchedObject = nil
    },
    {
        MsgName = "UISync.Update.PlayerRespawningChange",
        Func = self.OnParachuteRespawningPlayerChange,
        bCppMsg = true,
        WatchedObject = LocalGS
    }}
    
    self.TraceItemUI:SetVisibility(UE.ESlateVisibility.Collapsed)

    self.ShowState = 0
    self.TraceItemUI:UnselectState()

    UserWidget.OnInit(self)
end

function SimpleReadyPickListUI:OnDestroy()
    UserWidget.OnDestroy(self)
end

function SimpleReadyPickListUI:SetPickInfoMode()
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if PickupSetting and self.isInSimpleList then
        self.PickInfoMode = PickupSetting.PickInfoMode
    end

    if self.PickInfoMode == 1 then
        self.TextBlock_ItemNameAndNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.TextBlock_ItemNameAndNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function SimpleReadyPickListUI:ItemSlotChange(InOwnerActor)
    self:UpdateTracePickup()
end

function SimpleReadyPickListUI:OnCollectGenePlayerId(InDescObj)
    self:UpdateTracePickup()
end

function SimpleReadyPickListUI:UpdateTracePickup()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not LocalPC then
        return
    end

    -- 因为目前主端发死亡消息的地方，和查询人物状态的地方不一样，所以，两边都需要判断。
    local LocalPS = LocalPC.PlayerState
    if not LocalPS or not LocalPS:IsAlive() then
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    -- 因为目前主端发死亡消息的地方，和查询人物状态的地方不一样，所以，两边都需要判断。
    local Character = LocalPC:K2_GetPawn()
    if not Character or not UE.US1PickupStatics.IsPlayerAlive(Character) then
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    self.PickDropObj = PickSystemHelper.GetCurrentPickObj(Character)

    self.TraceItemUI:SetVisibility(UE.ESlateVisibility.Collapsed)

    if self.PickDropObj then

        for i = 1, self.PickDropObj.ItemInfo.Attribute:Length(), 1 do
            local tItemAttribute = self.PickDropObj.ItemInfo.Attribute:Get(i)
            if tItemAttribute and tItemAttribute.AttributeName == "PlayerName" then
                self.PlayerName = tItemAttribute.StrValue
            end
            if tItemAttribute and tItemAttribute.AttributeName == "PlayerId" then
                self.PlayerId = UE.UPickupStatics.Convert_StringToInt64(tItemAttribute.StrValue)
            end
        end


        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Hold_InputKeyHintImage:InitData()
        self.BP_InputKeyHintImage:InitData()
        --self.BP_InputKeyHintImage:InitNotifyHideObjects({self.Image_Key})
        local OwnerActor = self.PickDropObj:GetOwnerActor()
        if not OwnerActor then
            return
        end
        local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
        if not PickupSetting then
            return
        end
        if self.PickDropObj:IsBootyBox() then
            print("nzyp " .. "IsBootyBox")
            --隐藏去向
            self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.Collapsed)
            self:SetTitleState({
                State = 1
            })
            self.HorizontalBox_Mark:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.TraceItemUI:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.TextBlock_ItemNameAndNum:SetVisibility(UE.ESlateVisibility.Collapsed)
            if self.PlayerId then
                print("nzyp " .. "self.PlayerId" .. self.PlayerId)
                local RuleTag = UE.FGameplayTag()
                RuleTag.TagName = "GameplayAbility.GMS_GS.Respawn.Rule.Parachute"
                local ParachuteRule = UE.URespawnSubsystem.Get(self):GetGUVRespawnRule(RuleTag)
                print("nzyp " .. "ParachuteRule:")
                if ParachuteRule and ParachuteRule.RespawningPlayer:Contains(self.PlayerId) then
                    print("nzyp " .. "SetVisibility.SelfHitTestInvisible:" .. self.PlayerId)
                    self.HorizontalBox_Respawning:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                else
                    print("nzyp " .. "SetVisibility.Collapsed:" .. self.PlayerId)
                    self.HorizontalBox_Respawning:SetVisibility(UE.ESlateVisibility.Collapsed)
                end
            end

            if PickupSetting.IsShowPlayerNameWhenDeath then
                self.TextBlock_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_Thetrophyboxof"),self.PlayerName))
            else
                self.TextBlock_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_Materialbox")))
            end
        elseif not UE.UKismetTextLibrary.TextIsEmpty(OwnerActor:GetPickText()) then
            local PickText = OwnerActor:GetPickText()
            self.TextBlock_PickText:SetText(PickText)
            self:SetTitleState({
                State = 8
            })
            --隐藏去向
            self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            -- 处理物品名称和数量
            self.HorizontalBox_Mark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            if PickupSetting.PickInfoMode == 1 then
                self.TextBlock_ItemNameAndNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, self.PickDropObj.ItemInfo.ItemID)
                if not IngameDT then
                    return
                end
                local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(self.PickDropObj.ItemInfo.ItemID))
                if not StructInfo_Item then
                    return
                end
                local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
                self.TextBlock_ItemNameAndNum:SetText(TranslatedItemName .. "(" .. self.PickDropObj.ItemInfo.ItemNum .. ")")
            end
            -- 根据物品类型处理当前item的各种状态
            self:HandlPickItemState(self.PickDropObj)

            if self.TraceItemUI then
                self.TraceItemUI:SetDetail(self.PickDropObj, nil)
                self.TraceItemUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end
        end
    else -- 如果当前射线没命中任何东西，则不显示

        PickSystemHelper.SetReadyPickObj(Character, nil)
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CanvasPanel_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
        --隐藏去向
        self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

end

function SimpleReadyPickListUI:UpdateLittlePickList()
    local CurrentPickObjNearby = PickSystemHelper.GetCurrentPickObjNearby(UE.UGameplayStatics.GetPlayerCharacter(self, 0))
    if not CurrentPickObjNearby then
        return
    end
    local WidgetNum = self.HorizontalBox_LittleList:GetChildrenCount()
    local MinNum = math.min(WidgetNum, CurrentPickObjNearby:Length())
    for i = 1, WidgetNum, 1 do
        local ChildWidget = self.HorizontalBox_LittleList:GetChildAt(i - 1)
        if ChildWidget then
            if i <= MinNum then
                ChildWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                ChildWidget:SetDetail(CurrentPickObjNearby:Get(i))
            else
                ChildWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
    end
end

-- 集成所有处理各种item的状态
function SimpleReadyPickListUI:HandlPickItemState(InPickupObj)
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not LocalPC then
        return
    end

    if not InPickupObj then
        return
    end

    -- 处理类型
    local CurItemType, IsFindType = UE.UItemSystemManager.GetItemDataFName(LocalPC, InPickupObj.ItemInfo.ItemID,
        "ItemType", GameDefine.NItemSubTable.Ingame, "SimpleReadyPickListUI:HandlPickItemState")
    if not IsFindType then
        return
    end

    local BagComp = UE.UBagComponent.Get(LocalPC)
    if not BagComp then
        return
    end

    --【【背包】背包物品道具栏装满后，对地面上可堆叠物品（投掷物、成长货币弹药等）虽然能直接拾取但是显示”长按替换“】https://www.tapd.cn/68880148/bugtrace/bugs/view/1168880148001041291
    -- 这里多加了两个判断 对强化货币Currency和子弹Bullet也进行了特殊处理
    if CurItemType == ItemSystemHelper.NItemType.Weapon then
        self:HandleWeaponState(InPickupObj)
    elseif CurItemType == ItemSystemHelper.NItemType.Attachment then
        self:HandleAttachState(InPickupObj)
    elseif CurItemType == ItemSystemHelper.NItemType.ArmorHead or CurItemType == ItemSystemHelper.NItemType.ArmorBody or CurItemType == ItemSystemHelper.NItemType.Bag then
        self:HandleEquipmentState(InPickupObj)
    elseif CurItemType == ItemSystemHelper.NItemType.Currency then
        self:HandleCurrency(InPickupObj)
    elseif CurItemType == ItemSystemHelper.NItemType.Bullet then
        self:HandleBullet(InPickupObj)
    else
        self:HandleWeightState(InPickupObj)
        self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    --显示弹药去向
    if CurItemType == "Bullet" then
        local ItemSlotArray = BagComp:GetSlotsByType("Weapon")
        if not ItemSlotArray or ItemSlotArray:Length() == 0 then
            return
        end
        local ShowWeaponID = nil
        local ShowSlotID = nil
        for i = 1, ItemSlotArray:Length() do
            local itemSlot = ItemSlotArray:Get(i)
            if not itemSlot then
                goto continue
            end

            -- 找到武器所需的子弹ID
            local BulletID, IsFindBullet = UE.UItemSystemManager.GetItemDataInt32(LocalPC, itemSlot.InventoryIdentity.ItemID,
                "BulletItemID", GameDefine.NItemSubTable.Ingame, "SimpleReadyPickListUI:HandlPickItemState")
            if not IsFindBullet then
                goto continue
            end

            if BulletID == InPickupObj.ItemInfo.ItemID then
                if not ShowWeaponID and not ShowSlotID then
                    ShowWeaponID = itemSlot.InventoryIdentity.ItemID
                    ShowSlotID = itemSlot.SlotID
                elseif itemSlot.bActive then
                    ShowWeaponID = itemSlot.InventoryIdentity.ItemID
                    ShowSlotID = itemSlot.SlotID
                end
            end
            ::continue::
        end

        if ShowWeaponID and ShowSlotID then
            self.WidgetSwitcher_Index:SetActiveWidgetIndex(ShowSlotID-1)
            self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.WidgetSwitcher_Tip:SetActiveWidgetIndex(0)
            self.WidgetSwitcher_UpDown:SetActiveWidgetIndex(0)
            self:VXE_HUD_Tips_PickArrow_Down()
            local CurrentNum = BagComp:GetItemNumByItemID(InPickupObj.ItemInfo.ItemID)
            if CurrentNum ~= 0 then
                self.GUITextBlockNum:SetText(tostring(CurrentNum))
                self.HorizontalBox_CurBullet:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                self.BP_LittlePickItem_BulletType:SetDetail(InPickupObj)
            else
                self.HorizontalBox_CurBullet:SetVisibility(UE.ESlateVisibility.Collapsed)
            end

            local WeaponIcon, IsExistWeaponIcon = UE.UItemSystemManager.GetItemDataFString(self, 
                ShowWeaponID, "FlowImage", GameDefine.NItemSubTable.Ingame,"SimpleReadyPickListUI:HandlPickItemState")
            if IsExistWeaponIcon then
                local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(WeaponIcon)
                self.GUIImage_Gun:SetBrushFromSoftTexture(ImageSoftObjectPtr)
            end
        else
            self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

-- 如果是武器
function SimpleReadyPickListUI:HandleWeaponState(InPickupObj)
    if not InPickupObj then
        return
    end
    local tPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not tPC then
        return
    end

    local tPawn = tPC:GetPawn()
    if not tPawn then
        return
    end
    
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if PickupSetting and PickupSetting.UseHoldReplace and InPickupObj:IsBetter(tPawn) <= 0 then
        self:SetTitleState({
            State = 4
        })

        --显示配件去向
        --配件
        if InPickupObj.CacheAvailableAttachmentIds and InPickupObj.CacheAvailableAttachmentIds:Length() > 0 then
            self.WidgetSwitcher_Tip:SetActiveWidgetIndex(2)
            self.WidgetSwitcher_UpDown:SetActiveWidgetIndex(1)
            self:VXE_HUD_Tips_PickArrow_Up()
            self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            local ChildrenCount = self.HorizontalBox_AvailableAttachment:GetChildrenCount()
            local ArrayNum = InPickupObj.CacheAvailableAttachmentIds:Length()
            self.GUITextBlock_AttachmentNum:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_Youcanequip"), ArrayNum))
            local LoopNum = math.max(ArrayNum, ChildrenCount)

            for i = 1, LoopNum do
                if i > ArrayNum then
                    local ToCollapseWidget = self.HorizontalBox_AvailableAttachment:GetChildAt(i-1)
                    if ToCollapseWidget then
                        ToCollapseWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                    goto continue
                end
                local AttachmentItemID = InPickupObj.CacheAvailableAttachmentIds:Get(i)
                local TargetWidget = nil
                if i <= ChildrenCount then
                    TargetWidget = self.HorizontalBox_AvailableAttachment:GetChildAt(i-1)
                    TargetWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                else
                    TargetWidget = UE.UWidgetBlueprintLibrary.Create(self, self.LittlePickItem)
                    self.HorizontalBox_AvailableAttachment:AddChildToHorizontalBox(TargetWidget)
                end

                if TargetWidget then
                    TargetWidget:SetDetailByItemId(AttachmentItemID)
                end
                ::continue::
            end
        end
    else
        self:SetTitleState({
            State = 1
        })

        --隐藏去向
        self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 如果是配件
function SimpleReadyPickListUI:HandleAttachState(InPickupObj)
    if not InPickupObj then
        return
    end
    local tPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not tPC then
        return
    end
    local tPawn = tPC:GetPawn()
    if not tPawn then
        return
    end
    local BagComp = UE.UBagComponent.Get(tPC)
    if not BagComp then
        return
    end

    local TempIsBetter = InPickupObj:IsBetter(tPawn)
    if TempIsBetter > 0 then
        self:SetTitleState({
            State = 1
        })
    else
        self:HandleWeightState(InPickupObj)
    end

    if TempIsBetter > 0 then
        --显示配件去向
        --武器
        if InPickupObj.CacheBetterWeaponId and InPickupObj.CacheBetterWeaponId > 0 then
            self.WidgetSwitcher_Tip:SetActiveWidgetIndex(1)
            self.WidgetSwitcher_UpDown:SetActiveWidgetIndex(0)
            self:VXE_HUD_Tips_PickArrow_Down()
            self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            local WeaponIcon, IsExistWeaponIcon = UE.UItemSystemManager.GetItemDataFString(self, 
                InPickupObj.CacheBetterWeaponId, "FlowImage", GameDefine.NItemSubTable.Ingame,"SimpleReadyPickListUI:HandleAttachState")
            if IsExistWeaponIcon then
                local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(WeaponIcon)
                self.GUIImage_Gun_1:SetBrushFromSoftTexture(ImageSoftObjectPtr)
            end
        end
        --槽位
        if InPickupObj.CacheBetterWeaponSlotId and InPickupObj.CacheBetterWeaponSlotId > 0 then
            self.WidgetSwitcher:SetActiveWidgetIndex(InPickupObj.CacheBetterWeaponSlotId-1)
        end
        --配件
        if InPickupObj.CacheBetterAttachmentId and InPickupObj.CacheBetterAttachmentId > 0 then
            self.HorizontalBox_Replace:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.BP_LittlePickItem_Replace:SetDetailByItemId(InPickupObj.CacheBetterAttachmentId)
        else
            self.HorizontalBox_Replace:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        --隐藏去向
        self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


function SimpleReadyPickListUI:HandleBullet(InPickupObj)
    --子弹类型处理
    
    --先置条件判断
    local tPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not tPC then
        return
    end
    local BagComp = UE.UBagComponent.Get(tPC)
    if not BagComp then
        return
    end

    local CurItemType = self:GetItemType(InPickupObj)

    local TempCanObtainResult = BagComp:CanAddInventoryItem(InPickupObj.ItemInfo, nil)
    if TempCanObtainResult.Result and TempCanObtainResult.CanObtainNum > 0 then
        -- 显示 "拾取"
        self:SetTitleState({
            State = 1
        })
    else
        -- 显示 "不能拾取"
        self:SetTitleState({
            State = 2,
            ItemType = CurItemType
        })
    end
end

function SimpleReadyPickListUI:HandleCurrency(InPickupObj)
    --强化货币类型处理
    --先置条件判断
    local tPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not tPC then
        return
    end
    local BagComp = UE.UBagComponent.Get(tPC)
    if not BagComp then
        return
    end


    --判断当前背包强化货币数+ItemObject数量 <= 最大堆叠数
    local CurItemMaxStack, IsFindMaxStack = UE.UItemSystemManager.GetItemDataInt32(tPC, InPickupObj.ItemInfo.ItemID,
    "MaxStack", GameDefine.NItemSubTable.Ingame, "SimpleReadyPickListUI:HandleCurrency")

    local CurItemType = self:GetItemType(InPickupObj)

    local ItemNumInBag = BagComp:GetItemNumByItemID(InPickupObj.ItemInfo.ItemID)

    if IsFindMaxStack then
        local PostPickNum = ItemNumInBag + InPickupObj.ItemInfo.ItemNum
        if PostPickNum <= CurItemMaxStack then
            --显示 "拾取"
            self:SetTitleState({
                State = 1
            })
        else
            --显示 "不能拾取"
            self:SetTitleState({
                State = 2,
                ItemType = CurItemType,
            })
        end
    end

    --如果你有4000个，但是地面上有 6001个，最大堆叠数是10000，按理来讲应该显示"只能拾取 6000/10000"，拾取后地面剩余1
    --但是遗憾的是：地面上6001 + 4000 > 10000，6001个强化货币连一个都拾取不了，不知道是不是策划的需求？ 
end

function SimpleReadyPickListUI:OnLoadAttachmentDataAsset(InPickupObj, InWeaponHandle)
    if not InPickupObj then
        return
    end
    local tPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not tPC then
        return
    end
    local BagComp = UE.UBagComponent.Get(tPC)
    if not BagComp then
        return
    end
    local CurItemType = self:GetItemType(InPickupObj)
    local IsInBag = not UE.UGWSWeaponWorldSubsystem.CanAttachToWeapon(tPC, InWeaponHandle, self.AttachmentDataAsset)
    if IsInBag then
        local WeightRemain = BagComp:GetMaxWeight() - BagComp:GetCurWeight()
        if WeightRemain <= 0 then
            self:SetTitleState({
                State = 2,
                ItemType = CurItemType,
            })
        else
            local CurItemWeight, IsFindWeight = UE.UItemSystemManager.GetItemDataInt32(tPC, InPickupObj.ItemInfo.ItemID,
                "Weight", GameDefine.NItemSubTable.Ingame, "SimpleReadyPickListUI:HandleAttachState")
            if IsFindWeight then
                local TotalWeight = CurItemWeight * InPickupObj.ItemInfo.ItemNum
                if TotalWeight > WeightRemain then
                    self:SetTitleState({
                        State = 2,
                        ItemType = CurItemType,
                    })
                else
                    self:SetTitleState({
                        State = 1
                    })
                end
            end
        end
    else
        self:SetTitleState({
            State = 1
        })
    end
end

-- 处理重量或者格子
function SimpleReadyPickListUI:HandleWeightState(InPickupObj)
    if not InPickupObj then
        return
    end
    local tPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not tPC then
        return
    end
    local BagComp = UE.UBagComponent.Get(tPC)
    if not BagComp then
        return
    end
    local CurItemType = self:GetItemType(InPickupObj)
    if BagComp:IsWeightMode() then
        local WeightRemain = BagComp:GetMaxWeight() - BagComp:GetCurWeight()
        if WeightRemain < 0 then
            self:SetTitleState({
                State = 2,
                ItemType = CurItemType,
            })
        else
            local CurItemWeight, IsFindWeight = UE.UItemSystemManager.GetItemDataInt32(tPC, InPickupObj.ItemInfo.ItemID,
                "Weight", GameDefine.NItemSubTable.Ingame, "SimpleReadyPickListUI:UpdateTracePickup")
            if not IsFindWeight then
                return
            end

            local TotalWeight = CurItemWeight * InPickupObj.ItemInfo.ItemNum
            if TotalWeight <= WeightRemain then
                self:SetTitleState({
                    State = 1
                })
            else
                if CurItemWeight > WeightRemain then
                    self:SetTitleState({
                        State = 2,
                        ItemType = CurItemType,
                    })
                else
                    local tCanPickNum = math.floor(WeightRemain / CurItemWeight)
                    self:SetTitleState({
                        State = 3,
                        CanPickNum = tCanPickNum,
                        TotalNum = InPickupObj.ItemInfo.ItemNum
                    })
                end
            end
        end
    else
        local TempCanObtainResult = BagComp:CanAddInventoryItem(InPickupObj.ItemInfo, nil)
        if TempCanObtainResult.Result and TempCanObtainResult.CanObtainNum > 0 then
            if TempCanObtainResult.CanObtainNum < InPickupObj.ItemInfo.ItemNum then
                --、拾取部分
                self:SetTitleState({
                    State = 3,
                    CanPickNum = TempCanObtainResult.CanObtainNum,
                    TotalNum = InPickupObj.ItemInfo.ItemNum
                })
            elseif TempCanObtainResult.CanObtainNum == InPickupObj.ItemInfo.ItemNum then
                -- 拾取
                self:SetTitleState({
                    State = 1
                })
            else
                if BagComp:GetMaxSlotNum() > BagComp:GetCurSlotNum() then
                    -- 拾取
                    self:SetTitleState({
                        State = 1
                    })
                else
                    --4、替换
                    self:SetTitleState({
                        State = 4
                    })
                end

            end
        else
            self:SetTitleState({
                State = 2,
                ItemType = CurItemType,
            })
        end
    end
end

-- 处理装备
function SimpleReadyPickListUI:HandleEquipmentState(InPickupObj)
    if not InPickupObj then
        return
    end
    local tPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not tPC then
        return
    end
    local tPawn = tPC:GetPawn()
    if not tPawn then
        return
    end
    
    --隐藏去向
    self.CanvasPanelTip:SetVisibility(UE.ESlateVisibility.Collapsed)
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if PickupSetting and PickupSetting.bOnlyPickHigherLevel then

        if InPickupObj:IsBetter(tPawn) <= 0 and not InPickupObj.bShouldTapToPick then
            if InPickupObj.bShouldHoldToPick then
                self:SetTitleState({ State = 4 })
            else
                self:SetTitleState({ State = 5 })
            end
            return
        end

    end
    if InPickupObj.bShouldHoldToPick then
        self:SetTitleState({ State = 9 })
    else
        self:SetTitleState({ State = 1 })
    end
end

function SimpleReadyPickListUI:GetItemType(InPickupObj)
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not LocalPC then return nil end

    if not InPickupObj then return nil end

    local CurItemType, IsFindType = UE.UItemSystemManager.GetItemDataFName(LocalPC, InPickupObj.ItemInfo.ItemID,
        "ItemType", GameDefine.NItemSubTable.Ingame, "SimpleReadyPickListUI:HandlPickItemState")
    if not IsFindType then return nil end

    return CurItemType
end

function SimpleReadyPickListUI:IsPropInBag(ItemType)
    if not ItemType then
        return false
    end

    local bIsProp = (ItemType == ItemSystemHelper.NItemType.Potion 
    or ItemType == ItemSystemHelper.NItemType.Attachment 
    or ItemType == ItemSystemHelper.NItemType.Throwable 
    or ItemType == ItemSystemHelper.NItemType.Other)

    return bIsProp
end

-- 1、普通 2、超重 3、拾取部分 4、替换 5、已装备更高品质道具 6、显示附近 7、拾取胶囊 8、采用接口通用文字 9、拾取/长按替换
function SimpleReadyPickListUI:SetTitleState(InTable)
    self.ShowState = InTable.State
    print("nzyp " .. "ShowState:" .. self.ShowState)
    self.ImageNotEnough:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WS_KeyIcon:SetActiveWidgetIndex(0)
    if InTable.State == 1 then
        self.TextBlock_CantPick:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TextBlock_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_collect")))
        self.TextBlock_Title:SetColorAndOpacity(self.NormalTextColor)
    elseif InTable.State == 2 then
        self.TextBlock_CantPick:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TextBlock_CantPick:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_Insufficientspace")))

        local bIsProp =self:IsPropInBag(InTable.ItemType)
        if bIsProp then
            self.WS_KeyIcon:SetActiveWidgetIndex(1)
            self.TextBlock_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromIngameStaticST("SD_Bag", "2018")))
        else
            self.WS_KeyIcon:SetActiveWidgetIndex(0)
            self.TextBlock_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_Insufficientspace")))
        end

        self.TextBlock_CantPick:SetColorAndOpacity(self.WarningTextColor)
        self.ImageNotEnough:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TextBlock_Title:SetColorAndOpacity(self.InvalidTextColor)
    elseif InTable.State == 3 then
        self.TextBlock_CantPick:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TextBlock_CantPick:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_Canonlypickup")) .. InTable.CanPickNum .. "/" .. InTable.TotalNum)
        self.TextBlock_CantPick:SetColorAndOpacity(self.NormalTextColor)
        self.TextBlock_Title_Only:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_Canonlypickup")))
        self.TextBlock_PickNum:SetText(tostring(InTable.CanPickNum))
        self.TextBlock_AllNum:SetText(tostring(InTable.TotalNum))
        self.CanPickNum = InTable.CanPickNum
    elseif InTable.State == 5 then
        self.TextBlock_Title:SetColorAndOpacity(self.InvalidTextColor)
        self.TextBlock_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_Equippedwithhigherqu")))
    elseif InTable.State == 6 then
        self.TextBlock_Title:SetColorAndOpacity(self.NormalTextColor)
        self.TextBlock_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_nearby")))
    elseif InTable.State == 8 then
        self.WidgetSwitcher_Title:SetActiveWidgetIndex(4)

    elseif InTable.State == 9 then
        self.TextBlock_CantPick:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TextBlock_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SimpleReadyPickListUI_PickLongPressReplace")))
        self.TextBlock_Title:SetColorAndOpacity(self.NormalTextColor)
        self.WS_KeyIcon:SetActiveWidgetIndex(1)
    end


    if InTable.State == 4 then
        self.WidgetSwitcher_Title:SetActiveWidgetIndex(1)
    elseif InTable.State == 3 then
        self.WidgetSwitcher_Title:SetActiveWidgetIndex(5)
    elseif InTable.State == 7 then
        self.WidgetSwitcher_Title:SetActiveWidgetIndex(2)
    elseif InTable.State == 8 then
        self.WidgetSwitcher_Title:SetActiveWidgetIndex(4)
    else
        self.WidgetSwitcher_Title:SetActiveWidgetIndex(0)
    end

end

function SimpleReadyPickListUI:PickHoldStart()
    print("SimpleReadyPickListUI >> PickHoldStart")
    if self:IsVisible() and self.ShowState == 4 then
        self:PlayHoldSound(true)
    end
    --背包已满动效
    if self:IsVisible() and self.ShowState == 2 then
        self.TextBlock_CantPick:SetColorAndOpacity(self.WarningTextColor)
        self:VXE_HUD_Tips_BagFull()        
    end
end

function SimpleReadyPickListUI:PickHoldEnd()
    print("SimpleReadyPickListUI >> PickHoldEnd")
    self:PlayHoldSound(false)
end

function SimpleReadyPickListUI:PlayHoldSound(IsStart)
    if IsStart then
        UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Weapon_Replace")
    else
        UE.UGTSoundStatics.PostAkEvent(self, "AKE_Stop_UI_Weapon_Replace")
    end
end

function SimpleReadyPickListUI:CollectGenePlayerIds(InAsRespawnerGene)
    if not InAsRespawnerGene then
        return
    end
    self:UpdateTracePickup()

end

function SimpleReadyPickListUI:CharacterBeginDying(InDyingMessageInfo)
    print("nzyp " .. "CharacterBeginDying")
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not InDyingMessageInfo then
        return
    end
    local Character = InDyingMessageInfo.DyingActor
    if not Character then
        return
    end
    if PlayerController == Character:GetController() then
        -- 因为目前主端发死亡消息的地方，和查询人物状态的地方不一样，所以，两边都需要判断。
        self:TryCloseUI(Character)
    end
end

function SimpleReadyPickListUI:CharacterEndDying(InDyingMessageInfo)
    if not InDyingMessageInfo then return end
    local Character = InDyingMessageInfo.DyingActor
end

function SimpleReadyPickListUI:CharacterBeginDead(InDeadMessageInfo)
    print("nzyp " .. "CharacterEndDying")
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not InDeadMessageInfo then
        return
    end
    local Character = InDeadMessageInfo.DeadActor
    if not Character then
        return
    end
    if PlayerController == Character:GetController() then
        -- 因为目前主端发死亡消息的地方，和查询人物状态的地方不一样，所以，两边都需要判断。
        self:TryCloseUI(Character)
    end
end

function SimpleReadyPickListUI:CharacterEndDead(InDeadMessageInfo)
    if not InDeadMessageInfo then return end
    local Character = InDeadMessageInfo.DeadActor
end

function SimpleReadyPickListUI:TryCloseUI(InCharacter)
    print("nzyp " .. "TryCloseUI")
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function SimpleReadyPickListUI:OnHoldReplcePick(InInputData)
    print("SimpleReadyPickListUI >> OnHoldReplcePick InInputData.TriggerEvent=",InInputData.TriggerEvent)

    if not self.PickDropObj  then
        self.QuickPickObj = nil
        return
    end

    
    local TriggerEvent = InInputData.TriggerEvent
    if TriggerEvent == UE.ETriggerEvent.Started then
        self.QuickPickObj = self.PickDropObj 
    elseif TriggerEvent == UE.ETriggerEvent.Canceled then
        self.QuickPickObj = nil
    elseif TriggerEvent == UE.ETriggerEvent.Triggered then 
        self:OpenPropQuickPickUI()
    end

    print("SimpleReadyPickListUI >> OnHoldReplcePick self.QuickPickObj=",self.QuickPickObj)
    -- InInputData.TriggerEvent
end


function SimpleReadyPickListUI:OpenPropQuickPickUI()
    print("SimpleReadyPickListUI:OpenPropQuickPickUI")
    --判断背包是否已满
    --判断是否可以拾取
    --判断物品类型是否属于道具栏

    if not self.QuickPickObj then
        return
    end

    local tPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not tPC then
        return
    end

    local tPawn = tPC:GetPawn()
    if not tPawn then
        return
    end

    local BagComp = UE.UBagComponent.Get(tPC)
    if not BagComp then
        return
    end

    local ItemInfo = self.QuickPickObj.ItemInfo
    
    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(tPawn, ItemInfo.ItemID, "ItemType",GameDefine.NItemSubTable.Ingame, "SimpleReadyPickListUI.OpenPropQuickPickUI")

    if not IsFindItemType then
        return false
    end


    if CurrentItemType == ItemSystemHelper.NItemType.Potion or CurrentItemType == ItemSystemHelper.NItemType.Throwable or
        CurrentItemType == ItemSystemHelper.NItemType.Attachment or CurrentItemType == ItemSystemHelper.NItemType.Other then
        -- 属于道具栏 药品 投掷物 配件

        local CurSlotNum = BagComp:GetCurSlotNum()
        local MaxSlotNum = BagComp:GetMaxSlotNum()
        local RemainSlot = MaxSlotNum - CurSlotNum
        if RemainSlot <= 0 then
            -- 背包满了

            local GameplayTagContainer = UE.FGameplayTagContainer()
            local OutCanObtainResult, PickResultNum = self.QuickPickObj:CanPick(tPawn, 0, UE.EPickReason.PR_Player,GameplayTagContainer)
            if PickResultNum <= 0 then
                -- CanPick 不能拾取



                local UIManager = UE.UGUIManager.GetUIManager(self)
                if UIManager then
                    local GenericBlackboardContainer = UE.FGenericBlackboardContainer()
                    local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
                    BlackboardKeySelector.SelectedKeyName = "QuickPickObj"
                    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsObject(GenericBlackboardContainer,
                        BlackboardKeySelector, self.QuickPickObj)
                    self.QuikPickUI = UIManager:TryLoadDynamicWidget("UMG_QuickPick", GenericBlackboardContainer, true)
                end
            end
        end
    end

end

function SimpleReadyPickListUI:OnParachuteRespawningPlayerChange(InPlayerId, IsAddNotRemove)
    if not self.PlayerId then
        return
    end
    if InPlayerId ~= self.PlayerId then
        return
    end

    if IsAddNotRemove then
        self.HorizontalBox_Respawning:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.HorizontalBox_Respawning:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

return SimpleReadyPickListUI
