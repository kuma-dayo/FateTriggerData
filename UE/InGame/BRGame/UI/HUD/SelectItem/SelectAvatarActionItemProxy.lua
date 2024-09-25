local SelectAvatarActionItemProxy = 
{
	currentSelectIndex = 0,
	SelectMaxNum = 1
}

function SelectAvatarActionItemProxy:Init(InOwner)
    print("[yddhu]SelectAvatarActionItemProxy:Init")

	SelectAvatarActionItemProxy.SelectMaxNum = InOwner.AvatarActionConfigs:Num()
end

function SelectAvatarActionItemProxy.GetSelectItemIdMap(InOwner)
	local TargetData = UE.TArray(UE.int32)
	
	local Config = InOwner.AvatarActionConfigs:GetRef(SelectAvatarActionItemProxy.currentSelectIndex + 1)
	if Config then
		for i = 1, Config.ItemDataList:Num() do
			TargetData:AddUnique(i - 1)
		end
	end

	return TargetData
end

function SelectAvatarActionItemProxy.GetItemDataConfig(WidgetOwner, Index)
	local Config = WidgetOwner.AvatarActionConfigs:GetRef(SelectAvatarActionItemProxy.currentSelectIndex + 1)
	if Config then
		return Config.ItemDataList:Get(Index + 1) or {}
	end
	return {}
end

function SelectAvatarActionItemProxy.GetTexture2D(WidgetOwner, Index)
	return SelectAvatarActionItemProxy.GetItemDataConfig(WidgetOwner, Index).ItemIcon
end

function SelectAvatarActionItemProxy.UpdateSelectName(WidgetOwner,Index)
	return SelectAvatarActionItemProxy.GetItemDataConfig(WidgetOwner, Index).ItemName
end

function SelectAvatarActionItemProxy.UpdateSelectDescribe(WidgetOwner,Index)
	return SelectAvatarActionItemProxy.GetItemDataConfig(WidgetOwner, Index).ItemDescribes
end

function SelectAvatarActionItemProxy.GetLayoutVisibility(InOwner, ItemId)
	local NameVis,DescribeVis,LVis,MVis,RVis
	LVis = UE.ESlateVisibility.Collapsed
    MVis = UE.ESlateVisibility.Collapsed
	RVis = UE.ESlateVisibility.Collapsed
	if ItemId then
		NameVis = UE.ESlateVisibility.SelfHitTestInvisible
		DescribeVis = UE.ESlateVisibility.SelfHitTestInvisible
	else
		NameVis = UE.ESlateVisibility.Collapsed
		DescribeVis = UE.ESlateVisibility.Collapsed
	end
	return NameVis,DescribeVis,LVis,MVis,RVis
end

function SelectAvatarActionItemProxy.GetNumDetail(InOwner, ItemId)
	return nil,nil
end

function SelectAvatarActionItemProxy.GetNameDetail(InOwner, ItemId)
	return SelectAvatarActionItemProxy.GetItemDataConfig(InOwner, ItemId).ItemName, UIHelper.ToSlateColor_LC(UIHelper.LinearColor.White)
end

function SelectAvatarActionItemProxy.GetInfiniteDetail(InOwner, ItemId)
	return false
end

function SelectAvatarActionItemProxy.ShouldTriggerOperation(InOwner, MouseKey, IsMouseDown)
	print("[yddhu]SelectAvatarActionItemProxy.ShouldTriggerOperation", MouseKey)
	if MouseKey == "Gamepad_RightStick_Release" and IsMouseDown then
		return true,true
	end
	return false,true
end

function SelectAvatarActionItemProxy.TriggerOperation(WidgetOwner, ItemId)
    local InputAction = SelectAvatarActionItemProxy.GetItemDataConfig(WidgetOwner, ItemId).ItemInputAction
    if not InputAction or not InputAction:IsValid() then
        print("[yddhu]SelectAvatarActionItemProxy.TriggerOperation. InValid InputAction. ItemId = ", ItemId)
        return
    end

    local GTInputManager = UE.UGTInputManager.GetGTInputManager(WidgetOwner)
    if GTInputManager then
        local SelfPC = UE.UGameplayStatics.GetPlayerController(WidgetOwner, 0)
        if SelfPC then
			local IAValue = UE.FInputActionValue()
			IAValue.ValuE = UE.FVector(1, 0, 0)
            GTInputManager:TriggerInputAction(InputAction, UE.ETriggerEvent.Triggered, IAValue, SelfPC, nil)
        end
    end
end

function SelectAvatarActionItemProxy.ShouldClose(InOwner, MouseKey, IsMouseDown)
	return true
end

function SelectAvatarActionItemProxy.TriggerClose(InOwner, ItemId)
end

function SelectAvatarActionItemProxy.SwitchCurrentSelectIndex(bTurnLeft)
	if bTurnLeft then
		SelectAvatarActionItemProxy.currentSelectIndex = (SelectAvatarActionItemProxy.currentSelectIndex - 1) % SelectAvatarActionItemProxy.SelectMaxNum
	else
		SelectAvatarActionItemProxy.currentSelectIndex = (SelectAvatarActionItemProxy.currentSelectIndex + 1) % SelectAvatarActionItemProxy.SelectMaxNum
	end
end

return SelectAvatarActionItemProxy