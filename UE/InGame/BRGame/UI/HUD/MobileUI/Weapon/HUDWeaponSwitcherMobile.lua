--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ParentClassName = "InGame.BRGame.UI.HUD.Weapon.HUDWeaponSwitcherBase"
local HUDWeaponSwitcherBase = require(ParentClassName)
local HUDWeaponSwitcherMobile = Class(ParentClassName)

-------------------------------------------- Init/Destroy ------------------------------------

function HUDWeaponSwitcherMobile:OnInit()
    print("HUDWeaponSwitcherMobile", ">> OnInit[Start], ", GetObjectName(self))
    HUDWeaponSwitcherBase.OnInit(self)

    print("HUDWeaponSwitcherMobile", ">> OnInit[End], ", GetObjectName(self))
end

-------------------------------------------- Function ------------------------------------

-- 初始化武器栏信息(子控件数据)
function HUDWeaponSwitcherMobile:InitSubWidgetData()                   -- override
    --有多少个武器栏
    self.WeaponWidgetInfos = {}
    self.WeaponWidgetNum = 2
    for i = 1, self.WeaponWidgetNum do
        local WidgetIndex = (i - 1)
        local WeaponDetailKey = "BP_Mobile_WeaponDetail_" .. WidgetIndex

        local WeaponWidgetInfo = {
            WeaponDetail = self[WeaponDetailKey]
        }
        


        self.WeaponWidgetInfos[i] = WeaponWidgetInfo
        WeaponWidgetInfo.WeaponDetail:InitData(self,WidgetIndex,WeaponWidgetInfo)

    end
end


function HUDWeaponSwitcherMobile:UpdateWeaponInfo(InLocalPC)




    if not InLocalPC then return end

    local UpdateWeaponSlotIDSet = UE.TSet(0)
    UpdateWeaponSlotIDSet:Add(1)
    UpdateWeaponSlotIDSet:Add(2)


    local BagComponent = UE.UBagComponent.Get(InLocalPC)
    local ItemSlotDatas = BagComponent:GetItemSlots()



    local WeaponSlotDatas = {}
    local Index = 0
    for i = 1, ItemSlotDatas:Length() do
        local WeaponSlotData = ItemSlotDatas[i]
        if WeaponSlotData.ItemType == ItemSystemHelper.NItemSlotType.Weapon then
            -- body
            Index = Index+1
            WeaponSlotDatas[Index]=WeaponSlotData
        end
    end



    for i = 1, #WeaponSlotDatas do
        local WeaponSlotData = WeaponSlotDatas[i]

        if WeaponSlotData.ItemType ~= ItemSystemHelper.NItemSlotType.Weapon then
            goto continue
        end

        local WeaponWidgetInfo = self.WeaponWidgetInfos[WeaponSlotData.SlotID]


        if WeaponWidgetInfo then
            if UpdateWeaponSlotIDSet:Contains(WeaponSlotData.SlotID) then
                UpdateWeaponSlotIDSet:Remove(WeaponSlotData.SlotID)
            end


            if WeaponWidgetInfo.WeaponDetail then
                local CurrentInventoryIdentity = WeaponWidgetInfo.WeaponDetail:GetCurrentInventoryIdentity()
                if CurrentInventoryIdentity and (CurrentInventoryIdentity.ItemID == WeaponSlotData.InventoryIdentity.ItemID) and
                    (CurrentInventoryIdentity.ItemInstanceID == WeaponSlotData.InventoryIdentity.ItemInstanceID) then
                    WeaponWidgetInfo.WeaponDetail:UpdateInnerWeaponInfo(WeaponSlotData)
                else
                    WeaponWidgetInfo.WeaponDetail:ResetWidget()
                    WeaponWidgetInfo.WeaponDetail:UpdateInnerWeaponInfo(WeaponSlotData)
                end
            end


            local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(InLocalPC,
                WeaponSlotData.InventoryIdentity.ItemID)
            if not IngameDT then
                return
            end
            local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(
                WeaponSlotData.InventoryIdentity.ItemID))
            if not StructInfo_Item then
                return
            end
            if WeaponWidgetInfo.TxtTabName then
                local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
                WeaponWidgetInfo.TxtTabName:SetText(TranslatedItemName)
            end

            if WeaponSlotData.bActive then
                if WeaponWidgetInfo.ImgTabOn then
                    WeaponWidgetInfo.ImgTabOn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    WeaponWidgetInfo.ImgTabBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                end
                

                if WeaponWidgetInfo.TxtTabName then
                    WeaponWidgetInfo.TxtTabName:SetColorAndOpacity(self.EnableTxtTabColor)
                    WeaponWidgetInfo.TxtTabName:SetRenderOpacity(self.EnableTexTabOpacity)
                end

                if WeaponWidgetInfo.ImgTabNumBg then
                    local NewImgTabNumBgColor =
                        BattleUIHelper.GetMiscSystemValue(self, "WeaponImageColor", "TabActiveColor")
                    WeaponWidgetInfo.ImgTabNumBg:SetColorAndOpacity(NewImgTabNumBgColor)
                end
            else
                if WeaponWidgetInfo.ImgTabOn then
                    WeaponWidgetInfo.ImgTabOn:SetVisibility(UE.ESlateVisibility.Collapsed)
                    WeaponWidgetInfo.ImgTabBg:SetVisibility(UE.ESlateVisibility.Collapsed)
                end

                if WeaponWidgetInfo.TxtTabName then
                    WeaponWidgetInfo.TxtTabName:SetColorAndOpacity(self.DisableTxtTabColor) 
                    WeaponWidgetInfo.TxtTabName:SetRenderOpacity(self.DisableTexTabOpacity)
                end

                if WeaponWidgetInfo.ImgTabNumBg then
                    local NewImgTabNumBgColor = BattleUIHelper.GetMiscSystemValue(self, "WeaponImageColor",
                        "TabNotActiveColor")
                    WeaponWidgetInfo.ImgTabNumBg:SetColorAndOpacity(NewImgTabNumBgColor)
                end
            end

            WeaponWidgetInfo.WeaponDetail:SetActiveState(WeaponSlotData.bActive)
        end
        ::continue::
    end


    local ResetWeaponSlotIDs = UpdateWeaponSlotIDSet:ToArray()

    
    for i = 1, ResetWeaponSlotIDs:Length() do
        local TargetID = ResetWeaponSlotIDs:Get(i)
        if TargetID then
            local WeaponWidgetInfo = self.WeaponWidgetInfos[TargetID]
            if WeaponWidgetInfo and WeaponWidgetInfo.WeaponDetail then
                WeaponWidgetInfo.WeaponDetail:ResetWidget()
            end

        end
    end

end


function HUDWeaponSwitcherMobile:UpdateNotOwnerState(ItemSlotDatas)
    for index = 1, #self.WeaponWidgetInfos do
        local ItemSlotData = ItemSlotDatas[index]
        local WeaponWidgetInfo = self.WeaponWidgetInfos[index]
        local WeaponWidget = WeaponWidgetInfo.WeaponDetail
        if not ItemSlotData then
            WeaponWidget.WeaponContent:SetVisibility(UE.ESlateVisibility.Collapsed)
            WeaponWidget.GUICanvasPanelTile:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            WeaponWidget.WeaponContent:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
           -- WeaponWidget.GUICanvasPanelTile:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

return HUDWeaponSwitcherMobile