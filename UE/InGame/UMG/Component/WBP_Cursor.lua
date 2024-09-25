--[[
鼠标控件
支持功能：
1. 环形进度条
author: yangyang.658@bytedance.com
update time: 2023-11-07 17:30:16
--]]

local WBP_Cursor = Class("Common.Framework.UserWidget")

function WBP_Cursor:OnInit()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:Init_CircleProgress()
    -- local World = self:GetWorld()
   self.MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
   self.GUIManager = UE.UGUIManager.GetUIManager(self)
   self:InitCursorStyle()
   self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    UserWidget.OnInit(self)
end

function WBP_Cursor:InitCursorStyle()
    self.CurInputType = UE.ECommonInputNotifyType.PC
    self.GamepadSystem = UE.UGenericGamepadUMGSubsystem.Get(self)
    if self.GamepadSystem and self.GamepadSystem:IsInGamepadInput() then
        self.CurInputType = UE.ECommonInputNotifyType.Gamepad
    end 
    self:ChangeCursorIcon()
end

function WBP_Cursor:OnCustomCommonInputNotify(InCurType)
    self:UpdateCursorStyle(InCurType)
end

function WBP_Cursor:UpdateCursorStyle(InCurType)
    if self.CurInputType == InCurType then
        return
    end
    if self.CurInputType ~= InCurType then
        self.CurInputType = InCurType
    end
    if not self.GUIManager or not self.MiscSystem then
        return
    end
    
    self:ChangeCursorIcon()
end

function WBP_Cursor:ChangeCursorIcon()
    if self.CurInputType == UE.ECommonInputNotifyType.Gamepad then
        local HandleCursor =  self.MiscSystem.HandleCursor
        if HandleCursor then
            self.GUIManager:SetCursorIconBrushByTexture(HandleCursor)
        end
    elseif self.CurInputType == UE.ECommonInputNotifyType.PC then
        local PCCursor =  self.MiscSystem.PCCursor
        if PCCursor then
            self.GUIManager:SetCursorIconBrushByTexture(PCCursor)
        end
    end
end

function WBP_Cursor:OnDestroy()
    UserWidget.OnDestroy(self)
end

function WBP_Cursor:StartCursorProgress(InCurrentCursorProgressTime, InMaxCursorProgressTime)
    self.Overridden.StartCursorProgress(self, InCurrentCursorProgressTime, InMaxCursorProgressTime)
    self:SetVisibility_CircleProgress(true)
end

function WBP_Cursor:EndCursorProgress()
    self.Overridden.EndCursorProgress(self)
    self:SetVisibility_CircleProgress(false)
end

-- 初始化：圆形进度条
function WBP_Cursor:Init_CircleProgress()
    -- 校验进度条控件是否存在
    if not self.ImageProgress then
        return
    end

    -- 设置动态材质实例到图片控件
    self.ImageProgress:SetBrushFromMaterial(self.CursorProgressMatInstanceDynamic)
    self:SetVisibility_CircleProgress(false)
end

-- 设置可见性：圆形进度条
function WBP_Cursor:SetVisibility_CircleProgress(IsShow)
    if self.ImageProgress then
        if IsShow then
            self.ImageProgress:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.ImageProgress:SetVisibility(UE.ESlateVisibility.Hidden)
        end
    end
end

return WBP_Cursor