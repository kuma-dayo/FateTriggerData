require "UnLua"
require "InGame.BRGame.GameDefine"

local BagListUI = Class("Common.Framework.UserWidget")

function BagListUI:OnInit()
	self.MsgList = {
		
    }
    MsgHelper:RegisterList(self, self.MsgList)

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempBagComp = UE.UBagComponent.Get(LocalPC)

    UserWidget.OnInit(self)
end

function BagListUI:OnDestroy()
	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end

    UserWidget.OnDestroy(self)
end

function BagListUI:OnMouseButtonDown(MyGeometry, MouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function BagListUI:OnMouseButtonDoubleClick(MyGeometry, MouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function BagListUI:OnDragEnter(MyGeometry, PointerEvent, Operation)
    -- 暂不处理，转发
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
end

function BagListUI:OnDragLeave(PointerEvent, Operation)
    -- 暂不处理，转发
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end

function BagListUI:OnDrop(MyGeometry, PointerEvent, Operation)
    -- 暂不处理，转发
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end

return BagListUI