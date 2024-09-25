require "UnLua"
require ("InGame.BRGame.ItemSystem.PickSystemHelper")

local ReadyPickList = Class("Common.Framework.UserWidget")

function ReadyPickList:Initialize(Initializer)
    self.ReadyPickShowNum = 0
    self.TraceBootyBox = false
end

function ReadyPickList:OnInit()
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDying,	Func = self.CharacterBeginDying,        bCppMsg = true, WatchedObject = nil},
        { MsgName = GameDefine.MsgCpp.PLAYER_OnEndDying,	Func = self.CharacterEndDying,          bCppMsg = true, WatchedObject = nil},
        { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDead,	Func = self.CharacterBeginDead,         bCppMsg = true, WatchedObject = nil},
        { MsgName = GameDefine.MsgCpp.PLAYER_OnEndDead,	    Func = self.CharacterEndDead,           bCppMsg = true, WatchedObject = nil},
    }
    UserWidget.OnInit(self)
end

function ReadyPickList:OnDestroy()
    UserWidget.OnDestroy(self)
end

function ReadyPickList:Tick(MyGeometry, InDeltaTime)

end

function ReadyPickList:ReadyPickupUpdate()
    local Character = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
    if not Character then
        return
    end

    -- 重置个数
    self.ReadyPickShowNum = 0
    -- 隐藏所有 子Widget
    local AllChildWidget = self.VerticalBox_List:GetAllChildren()
    local ChildNum = AllChildWidget:Length()
    for index = 1, ChildNum, 1 do
        local Widget = AllChildWidget:GetRef(index)
        if Widget then
            Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    local PickList = PickSystemHelper.GetLastReadyToPickObjArray(Character)
    if not PickList then
        return
    end
    local PickSetting = UE.UPickupManager.GetGPSSeting(self)

    --拿到瞄准的物品
    local TracePickupObj = PickSystemHelper.GetCurrentPickObj(Character)
    if TracePickupObj then
        self.TraceBootyBox = TracePickupObj:IsBootyBox()
    end

    self.PickupObjArray:Clear()
    for index = 1, PickList:Length(), 1 do
        local PickupObj = PickList:Get(index)
        if not PickupObj then
            goto continue
        end
        -- 如果是当前瞄准的物品，则不会在列表处理
        if TracePickupObj and PickupObj == TracePickupObj then
            goto continue
        end

        local NotLoopToMax = self.ReadyPickShowNum < self.VerticalBox_List:GetChildrenCount()
        local OldChildWidget = self.VerticalBox_List:GetChildAt(self.ReadyPickShowNum)
        if OldChildWidget and NotLoopToMax then
            OldChildWidget:SetDetail(PickupObj)
            OldChildWidget:SetVisibility(UE.ESlateVisibility.Visible)
            self.ReadyPickShowNum = self.ReadyPickShowNum + 1
            self.PickupObjArray:Add(PickupObj)
        else
            local ReadyPickWidget = UE.UWidgetBlueprintLibrary.Create(self, self.ReadyPickWidgetClass)
            if ReadyPickWidget then
                ReadyPickWidget:SetDetail(PickupObj)
                local verticalslot = self.VerticalBox_List:AddChild(ReadyPickWidget)
                if verticalslot then
                    local margin = UE.FMargin()
                    margin.Top = 4.0
                    verticalslot:SetPadding(margin)
                end
                self.PickupObjArray:Add(PickupObj)
                self.ReadyPickShowNum = self.ReadyPickShowNum + 1
            end
        end

        if self.ReadyPickShowNum >= PickSetting.SimplePickListShowNum then
            break
        end
        ::continue::
    end

    PickSystemHelper.SetSimpleListDataArray(Character, self.PickupObjArray)
end

--从1开始
function ReadyPickList:GetPickObjAt(InIndex)
    local PickDetailWidget = self.VerticalBox_List:GetChildAt(InIndex-1)
    if not PickDetailWidget then
        return nil
    end
    return PickDetailWidget.PickupObj
end

function ReadyPickList:SetPickBgCheckBox(InIndex)
    print("ReadyPickList >> SetPickBgCheckBox > InIndex:",InIndex)
    local PickDetailWidget = self.VerticalBox_List:GetChildAt(InIndex-1)
    local Count = self.VerticalBox_List:GetChildrenCount()
    for index = 0, Count-1 do
        local ChildWidget = self.VerticalBox_List:GetChildAt(index)
        ChildWidget:UnselectState()
    end

    if not PickDetailWidget and InIndex-1<0 then
        return nil
    end
    PickDetailWidget:SelectedState()
end


function ReadyPickList:CharacterBeginDying(InDyingMessageInfo)

end

function ReadyPickList:CharacterEndDying(InDyingMessageInfo)
end

function ReadyPickList:CharacterBeginDead(InDeadMessageInfo)

end

function ReadyPickList:CharacterEndDead(InDeadMessageInfo)
end

return ReadyPickList