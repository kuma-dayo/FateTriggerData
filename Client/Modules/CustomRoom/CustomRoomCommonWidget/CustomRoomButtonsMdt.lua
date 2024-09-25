---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 自建房底部按钮
--- Created At: 2023/05/30 10:45
--- Created By: 朝文
---

local class_name = "CustomRoomButtonsMdt"
---@class CustomRoomButtonsMdt
local CustomRoomButtonsMdt = BaseClass(nil, class_name)

function CustomRoomButtonsMdt:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.Button_1.OnClicked,				Func = Bind(self,self.OnButtonClicked_Button_1) },
        { UDelegate = self.View.Button_2.OnClicked,				Func = Bind(self,self.OnButtonClicked_Button_2) },        
        { UDelegate = self.View.Button_Extra.OnClicked,			Func = Bind(self,self.OnButtonClicked_Button_Extra) },        
    }
end

function CustomRoomButtonsMdt:OnShow(Param)
    self.View.Button_1:SetVisibility(UE.ESlateVisibility.Hidden)
    self.View.Button_2:SetVisibility(UE.ESlateVisibility.Hidden)
    self.View.Button_Extra:SetVisibility(UE.ESlateVisibility.Hidden)
    
    if not Param then return end
    self:SetData(Param)
    self:UpdateView()
end

function CustomRoomButtonsMdt:OnHide() end

--[[
    Param = {
        --左侧大按钮
        Button1Info = {                     --如果没有配置则隐藏按钮
            Text = "",
            Callback = function() end,
        },
        --右侧大按钮
        Button2Info = {                     --如果没有配置则隐藏按钮
            Text = "",
            Callback = function() end,
        },
        --最左侧小按钮
        ButtonExtraInfo = {                 --如果没有配置则隐藏按钮
            Text = "",
            Callback = function() end,
        }
    }
--]]
function CustomRoomButtonsMdt:SetData(Param)
    self.Data = Param
end

function CustomRoomButtonsMdt:ShowButton_1() self.View.Button_2:SetVisibility(UE.ESlateVisibility.Visible) end
function CustomRoomButtonsMdt:HideButton_1() self.View.Button_2:SetVisibility(UE.ESlateVisibility.Collapsed) end
function CustomRoomButtonsMdt:ShowButton_2() self.View.Button_2:SetVisibility(UE.ESlateVisibility.Visible) end
function CustomRoomButtonsMdt:HideButton_2() self.View.Button_2:SetVisibility(UE.ESlateVisibility.Collapsed) end

function CustomRoomButtonsMdt:UpdateView()
    if not self.Data then return end

    if self.Data.Button1Info then
        self.View.Text_Button_1:SetText(StringUtil.Format(self.Data.Button1Info.Text or ""))
        self.View.Button_1:SetVisibility(UE.ESlateVisibility.Visible)        
    end

    if self.Data.Button2Info then
        self.View.Text_Button_2:SetText(StringUtil.Format(self.Data.Button2Info.Text or ""))
        self.View.Button_2:SetVisibility(UE.ESlateVisibility.Visible)        
    end

    if self.Data.ButtonExtraInfo then
        self.View.Text_Button_Extra:SetText(StringUtil.Format(self.Data.ButtonExtraInfo.Text or ""))
        self.View.Button_Extra:SetVisibility(UE.ESlateVisibility.Visible)
    end
end

function CustomRoomButtonsMdt:OnButtonClicked_Button_1()
    if not self.Data or not self.Data.Button1Info or not self.Data.Button1Info.Callback then return end

    self.Data.Button1Info.Callback()
end

function CustomRoomButtonsMdt:OnButtonClicked_Button_2()
    if not self.Data or not self.Data.Button1Info or not self.Data.Button2Info.Callback then return end

    self.Data.Button2Info.Callback()
end

function CustomRoomButtonsMdt:OnButtonClicked_Button_Extra()
    if not self.Data or not self.Data.ButtonExtraInfo or not self.Data.ButtonExtraInfo.Callback then return end

    self.Data.ButtonExtraInfo.Callback()
end


return CustomRoomButtonsMdt
