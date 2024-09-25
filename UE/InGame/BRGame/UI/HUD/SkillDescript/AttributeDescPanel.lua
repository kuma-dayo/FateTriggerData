-- 技能详情面板
--
-- @COMPANY	ByteDance
-- @AUTHOR	王泽平
-- @DATE	2023.10.17

local AttributeDescPanel = Class("Common.Framework.UserWidget")

-- region Define

--页面模式
local EPageMode={
    Map = 0,    --小地图页面
    SkillDesc = 1,  --技能详情页面
    MicrochipDesc = 2 , --芯片详情页面
}

-- endregion

-------------------------------------------- Init/Destroy ------------------------------------

function AttributeDescPanel:OnInit()
    print("AttributeDescPanel >> OnInit")

    self.PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    -- region Event

    self.AttributeListWidget.OnUpdateItem:Add(self, self.OnAddAttributeDescWidget)

    self.ScrollOffset = 0
    -- endregion
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.BAG_FeatureSetUpdate, Func = self.OnUpdateItemFeatureSet,  bCppMsg = true },
        { MsgName = "UI.SkillDesc.Scroll", Func = self.OnUpdateScrollOffset,  bCppMsg = true },
	}
    
    self:InitData()
	UserWidget.OnInit(self)
end

function AttributeDescPanel:OnShow(InContext,InGeneicBlackboard)
    
end

function AttributeDescPanel:OnUpdateItemFeatureSet()
    self:ReadDataTable()
end


function AttributeDescPanel:InitData()
    print("AttributeDescPanel >> InitData")

        -- region Properties

        self.AttributeLst = {}
        self.AttributeSortLst = {}
        self.AttributeMaxNum = 0

        -- endregion

        self:ReadDataTable()
end

function AttributeDescPanel:OnDestroy()
    print("AttributeDescPanel >> OnDestroy")
	UserWidget.OnDestroy(self)
end


-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------


-- region 读表
function AttributeDescPanel:ReadDataTable()

    self.AttributeLst={}



    --region 读取附魔属性
    local TempGameplayTag = UE.FGameplayTag()
    TempGameplayTag.TagName = GameDefine.NTag.TABLE_EnhanceAttribute
    local EnhanceAttributeCfg = UE.UTableManagerSubsystem.GetDataTableByTag(self, TempGameplayTag)
    local EnhanceAttributeList = UE.UDataTableFunctionLibrary.GetDataTableRowNames(EnhanceAttributeCfg)

    self.AttributeMaxNum = EnhanceAttributeList:Length()
    for Row = 1, self.AttributeMaxNum do
        local DataTableRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(EnhanceAttributeCfg, EnhanceAttributeList:Get(Row))
        local EnhanceID = DataTableRow.EnhanceID
        self.AttributeLst[EnhanceID] = {
            Level = Row, 
            EnhanceData = DataTableRow ,
            bIsEquip = false , 
            bIsWeapon = false, 
            WeaponSlotIndex = -1,
        } 
    end


    self:GetEnhanceAttributeInfo()
    self.AttributeListWidget:Reload(self.AttributeMaxNum)

    -- self.AttributeListWidget:Clear()
    -- for index = 1, self.AttributeMaxNum do
    --     self.AttributeListWidget:AddOne(self.AttributeMaxNum)
    -- end

end
--endregion

function AttributeDescPanel:GetEnhanceAttributeInfo()

    self.AttributeSortLst ={}
    -- 根据物品ID更新词条
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempLocalPC then
        return
    end
    local TempBagComp = UE.UBagComponent.Get(TempLocalPC)
    if not TempBagComp then
        return
    end

    local AllOwnerAttrLst = {} 

    local InventoryList = TempBagComp:GetInventoryList()
    local EntriesArr = InventoryList.Entries
    for i = 1, EntriesArr:Length() do
        local Entries = EntriesArr:Get(i)
        local ItemObj = Entries.Instance

        local TempInventoryIdentity = ItemObj:GetInventoryIdentity()
        local ItemID = TempInventoryIdentity.ItemID
        local ItemInstanceID = TempInventoryIdentity.ItemInstanceID
        if ItemObj then
            print("AttributeDescPanel >> GetEnhanceAttributeInfo > ItemID= ",ItemID)
            if ItemObj:HasItemAttribute("EnhanceAttributeId") then
                local TempEnhanceId = ItemObj:GetItemAttributeFString("EnhanceAttributeId")
                if TempEnhanceId then
                    --已拥有
                    AllOwnerAttrLst[TempEnhanceId] = {ItemID = ItemID, ItemInstanceID = ItemInstanceID }
                    print("AttributeDescPanel >> GetEnhanceAttributeInfo > TempEnhanceId= ",TempEnhanceId)
                    print("AttributeDescPanel >> GetEnhanceAttributeInfo > AllOwnerAttrLst[TempEnhanceId]= ",AllOwnerAttrLst[TempEnhanceId])
                end
            end
        end
    end
    local WeaponSlotList = {}

    local ItemSlotDatas = TempBagComp:GetItemSlots()
    for i = 1, ItemSlotDatas:Length() do
        local WeaponSlotData = ItemSlotDatas[i]
        if WeaponSlotData.ItemType == "Weapon" then
            local EquipWeaponInstanceID = WeaponSlotData.InventoryIdentity.ItemInstanceID
            local EquipWeaponID = WeaponSlotData.InventoryIdentity.ItemID
            WeaponSlotList[i] = {WeaponInstanceID = EquipWeaponInstanceID ,WeaponID = EquipWeaponID}
        end
    end


    local OwneLst = {}
    local UnowneLst = {}
    local WeaponLst = {}
    
    for EnhanceID, Attr in pairs(self.AttributeLst) do
        local EnhanceIDStr = tostring(EnhanceID)
        local OwneAttr = AllOwnerAttrLst[EnhanceIDStr] --物品中有附魔数据 代表已装备
        if OwneAttr then
            Attr.bIsEquip = true
            local bIsFind = false
            for WeaponSlotIndex, WeaponData in pairs(WeaponSlotList) do
                if WeaponData.WeaponInstanceID == OwneAttr.ItemInstanceID then
                    Attr.bIsWeapon = true
                    Attr.WeaponIdx = WeaponSlotIndex
                    table.insert(WeaponLst,Attr)
                    bIsFind = true
                    break
                end
            end
            
            if not bIsFind then
                table.insert(OwneLst,Attr)
            end

        else
            table.insert(UnowneLst,Attr)
        end
    end

    --对已装备表排序
    table.sort(OwneLst, function(a, b)
        return a.Level < b.Level
    end)
    --对未装备表排序
    table.sort(UnowneLst,function(a, b)
        return a.Level < b.Level
    end)

    self:AppendTable(self.AttributeSortLst,WeaponLst)
    self:AppendTable(self.AttributeSortLst,OwneLst)
    self:AppendTable(self.AttributeSortLst,UnowneLst)

    -- GameLog.Dump(self.AttributeSortLst,self.AttributeSortLst)


    print("AttributeDescPanel >> GetEnhanceAttributeInfo > self.AttributeSortLst=",self.AttributeSortLst)
end


function AttributeDescPanel:AppendTable(TableA,TableB)
    for i = 1, #TableB do
        table.insert(TableA,TableB[i])
    end
end



function AttributeDescPanel:OnAddAttributeDescWidget(Widget, Index)
    local AttributeDataSet = self.AttributeSortLst[Index+1]
    if not AttributeDataSet then return end
    local AttributeData = AttributeDataSet.EnhanceData
    local EnhanceID = AttributeData.EnhanceID
    local bIsEquip = AttributeDataSet.bIsEquip
    local bIsWeapon = AttributeDataSet.bIsWeapon
    local WeaponSlotIndex = AttributeDataSet.WeaponIdx
    local TagContainer = AttributeData.AllowedWeapons


    local TagWidgetNum = Widget.HBox_SkillGunDesWidget:GetChildrenCount()
    local TagArr = TagContainer.GameplayTags
    local TagArrNum = TagArr:Num()
    for i = 1, TagWidgetNum do

        if i <= TagArrNum  then
            local Tag = TagArr:Get(i)
            local CurrentTagWidget = Widget.HBox_SkillGunDesWidget:GetChildAt(i-1)
            if CurrentTagWidget then
                local SupportWeaponName = string.gsub(Tag.TagName, "Weapon.Type.", "")
                CurrentTagWidget.Text_Name:SetText(SupportWeaponName)
                CurrentTagWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end
        else
            local CurrentTagWidget = Widget.HBox_SkillGunDesWidget:GetChildAt(i-1)
            CurrentTagWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end


    end
    
    -- local TagWidgetCount = self.HBox_SkillGunDesWidget:GetChildrenCount()

    
    -- 更新图片
    local EnhanceIconSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(AttributeData.EnhanceIconSoft)
    Widget.Image_Icon:SetBrushFromSoftTexture(EnhanceIconSoftPtr)
    local TranslatedItemNameStr = StringUtil.Format(AttributeData.EnhanceName)
    Widget.Text_Name:SetText(TranslatedItemNameStr)
    local EnhanceDescriptionStr = StringUtil.Format(AttributeData.EnhanceDecription)
    Widget.Text_Des:SetText(EnhanceDescriptionStr)
    Widget:SetState(bIsEquip and 0 or 1)
    Widget.Text_Equip:SetVisibility(bIsEquip and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if bIsWeapon then
        Widget.SW_WeaponIndex:SetActiveWidgetIndex(WeaponSlotIndex-1)
    end
end


function AttributeDescPanel:OnAttributeScroll(InputAction)

    -- local ScrollValue = InputAction:GetRealValue()
    -- print("AttributeDescPanel >> OnAttributeScroll > ScrollValue=",ScrollValue)
    print("AttributeDescPanel >> OnAttributeScroll")
end

-- function AttributeDescPanel:OnMouseWheel(MyGeometry,MouseEvent)
--     local WheelDelta = UE.UKismetInputLibrary.PointerEvent_GetWheelDelta(MouseEvent)
--     print("SkillDescMainUI >> OnMouseWheel > WheelDelta=",WheelDelta)
--     local CurrWheelOffset = self.AttributeListWidget:GetScrollOffset()
--     CurrWheelOffset = CurrWheelOffset + WheelDelta*5.0
--     self.AttributeListWidget:SetScrollOffset(CurrWheelOffset)
--     return UE.UWidgetBlueprintLibrary.Handled()
-- end

function AttributeDescPanel:OnUpdateScrollOffset(InInputData)
    local MaxScrollEnd = self.AttributeListWidget:GetScrollOffsetOfEnd()-- + 100
    local InputActionValue = InInputData.InputActionValueCopy
    local WheelOffset = InputActionValue.Value.X
    local Offset = self.ScrollOffset - WheelOffset * self.ScrollSpeed
    self.ScrollOffset = math.clamp(Offset,MaxScrollEnd,0)
    self.AttributeListWidget:SetScrollOffset(self.ScrollOffset)
end

return AttributeDescPanel