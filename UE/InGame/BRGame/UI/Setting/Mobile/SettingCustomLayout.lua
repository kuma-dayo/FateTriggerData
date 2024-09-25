

local SettingCustomLayout = Class("Common.Framework.UserWidget")

function SettingCustomLayout:OnInit()
    self.MsgList = {
       
        { MsgName = "UIEvent.GenerateScreenshot",	Func = self.SuccessGenerateScreenshot,   bCppMsg = true},
       
    }
    UserWidget.OnInit(self)
end

function SettingCustomLayout:RefreshActiveLayout(InIndex)
    print("SettingCustomLayout:RefreshActiveLayout InIndex",InIndex,"self.ActiveIndex",self.ActiveIndex)
   if InIndex == self.ActiveIndex then
        return 
   end
    self.ItemBox:GetChildAt(self.ActiveIndex).WidgetSwitcher:SetActiveWidgetIndex(0)
    self.ItemBox:GetChildAt(self.ActiveIndex).IsActive = false
    self.ActiveIndex = InIndex
    local SettingValue = UE.FSettingValue()
    SettingValue.Value_Int = InIndex
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    SettingSubsystem:ApplySetting(self.ParentTag.TagName,SettingValue)
end

function SettingCustomLayout:OnShow(data)
    print("SettingCustomLayout:OnShow")
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local ImgBg = nil
    for i=0,self.ItemBox:GetChildrenCount()-1 do
        ImgBg = SettingSubsystem.MobileCustomLayoutSolution:FindRef(i).NewLayoutImg
        if ImgBg ==nil  then
            ImgBg = SettingSubsystem.MobileCustomLayoutSolution:FindRef(i).DefaultLayoutImg
      
        end
        self.ItemBox:GetChildAt(i).Image:SetBrushfromSoftTexture(ImgBg)
    end
end

function SettingCustomLayout:RefreshEditLayout(InIndex)
    print("SettingCustomLayout:RefreshEditLayout InIndex",InIndex,"self.ActiveIndex",self.ActiveIndex)
    local UserWidget = nil 
    for i=0,self.ItemBox:GetChildrenCount()-1 do
        UserWidget = self.ItemBox:GetChildAt(i)
        UserWidget:OnUnhoveredReset()
    end
end

function SettingCustomLayout:SuccessGenerateScreenshot(Index)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local tmp = SettingSubsystem.MobileCustomLayoutSolution:FindRef(Index).NewLayoutImg
    print("SettingCustomLayout:SuccessGenerateScreenshot",Index,tmp)
    self.ItemBox:GetChildAt(Index).Image:SetBrushfromSoftTexture(tmp)
end

return SettingCustomLayout