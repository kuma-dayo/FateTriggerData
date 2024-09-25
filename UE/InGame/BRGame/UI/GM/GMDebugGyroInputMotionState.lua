local class_name = "GMDebugGyroInputMotionState"
GMDebugGyroInputMotionState = GMDebugGyroInputMotionState or BaseClass(GameMediator, class_name)

function GMDebugGyroInputMotionState:__init()
end

function GMDebugGyroInputMotionState:OnShow(InData)

end

function GMDebugGyroInputMotionState:OnHide()
	
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    print("GMDebugGyroInputMotionState:OnInit")

    self.BindNodes ={
        { UDelegate = self.Button_Close.OnClicked, Func = self.OnCloseClick },
        { UDelegate = self.Button_SwitchEnableFov.OnClicked, Func = self.OnSwitchEnableFovClick },
    }
    
    UserWidgetBase.OnInit(self)
end

function M:OnDestroy()
    print("GMDebugGyroInputMotionState:OnDestroy")

    UserWidgetBase.OnDestroy(self)
end

function M:RefreshUI()
    local S1InputSubsystem = UE.US1InputSubsystem.Get(self)
    if S1InputSubsystem then
        if S1InputSubsystem.bEnableProcessFovByGyro then
            self.GUITextBlock_SwitchEnableFov:SetText("点击关闭FOV控制")
        else
            self.GUITextBlock_SwitchEnableFov:SetText("点击打开FOV控制")
        end
    end
end

--由mdt触发调用
--[[

]]
function M:OnShow(Param)
    print("GMDebugGyroInputMotionState:OnShow")

    self:RefreshUI()
end

--由mdt触发调用
function M:OnHide()
    print("GMDebugGyroInputMotionState:OnHide")
end

function M:CloseSelf()
    MvcEntry:CloseView(self.viewId)
end

function M:OnCloseClick()
    print("GMDebugGyroInputMotionState:OnCloseClick")

    if self.MvcCtrl and self.viewId then
        self:CloseSelf()
    else
        local UIManager = UE.UGUIManager.GetUIManager(self)
        if UIManager then
            UIManager:TryCloseDynamicWidget("UMG_DebugGyroInputMotionState")
        end
    end
end

function M:OnSwitchEnableFovClick()
    print("GMDebugGyroInputMotionState:OnSwitchEnableFovClick")

	local S1InputSubsystem = UE.US1InputSubsystem.Get(self)
    if S1InputSubsystem then
        S1InputSubsystem.bEnableProcessFovByGyro = not S1InputSubsystem.bEnableProcessFovByGyro
        self:RefreshUI()
    end
end

return M