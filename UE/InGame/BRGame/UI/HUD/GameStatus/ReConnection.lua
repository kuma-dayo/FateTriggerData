require "UnLua"

local ReConnection = Class("Common.Framework.UserWidget")


function ReConnection:OnInit()
    --print("ReConnection:OnInit")
   
        
    UserWidget.OnInit(self)
end

function ReConnection:OnShow(InContext,InGeneicBlackboard)
    self:VXE_HUD_Reconnection()
end


function ReConnection:OnClose(bDestroy)
   
    UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("NetWork.ReConnection.PopUp")
    local UIManager = UE.UGUIManager.GetUIManager(self)
        UIManager:TryCloseDynamicWidget("UMG_MainMenu")
   
end

function ReConnection:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:SetFocus(true)
end

function ReConnection:OnKeyDown(MyGeometry,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey ==self.IgnoreKey then      
        return UE.UWidgetBlueprintLibrary.UnHandled()
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function ReConnection:OnKeyUp(MyGeometry,InKeyEvent)
    
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == self.OpenMainMenu then 
        local UIManager = UE.UGUIManager.GetUIManager(self)
        UIManager:TryLoadDynamicWidget("UMG_MainMenu")
   end
    return UE.UWidgetBlueprintLibrary.Handled()
end

return ReConnection