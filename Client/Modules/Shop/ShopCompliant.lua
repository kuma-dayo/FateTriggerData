--[[
    商城合规
]] --
require "UnLua"

local class_name = "ShopCompliant"
---@class ShopCompliant
ShopCompliant = ShopCompliant or BaseClass(nil, class_name)

function ShopCompliant:OnInit(Param)
    self.BindNodes = {
        {UDelegate = self.View.CommonBtnTips_Compliant1.Btn_List.OnClicked, Func = Bind(self, self.OnCompliant1Clicked)},
        {UDelegate = self.View.CommonBtnTips_Compliant2.Btn_List.OnClicked, Func = Bind(self, self.OnCompliant2Clicked)}
    }

    self:InitCompliantUI()
end

function ShopCompliant:OnShow(Param)
 
end

function ShopCompliant:OnHide()
end

function ShopCompliant:InitCompliantUI()
    self.View.CommonBtnTips_Compliant1.Img_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.CommonBtnTips_Compliant1.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.CommonBtnTips_Compliant1.Text_Count:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "11204"))

    self.View.CommonBtnTips_Compliant2.Img_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.CommonBtnTips_Compliant2.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.CommonBtnTips_Compliant2.Text_Count:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "11205"))
end

-- 合规1
function ShopCompliant:OnCompliant1Clicked()
    local msgParam = {
        title = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "11204"),
        describe = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "11203")
        -- warningDec = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "11203"),
    }

    UIMessageBox.Show(msgParam)
end

-- 合规2
function ShopCompliant:OnCompliant2Clicked()
    local msgParam = {
        title = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "11205"),
        describe = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "11203")
        -- warningDec = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "11203"),
    }
    UIMessageBox.Show_System(msgParam)
end

return ShopCompliant
