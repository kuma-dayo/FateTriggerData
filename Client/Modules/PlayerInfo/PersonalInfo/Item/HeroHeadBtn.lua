local class_name = "HeroHeadBtn"
---@class HeroHeadBtn
local HeroHeadBtn = BaseClass(nil, class_name)

function HeroHeadBtn:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.Button.OnClicked,	Func = Bind(self,self.Button_OnClicked) },
	}

end

function HeroHeadBtn:OnShow()
end


function HeroHeadBtn:OnHide()
end

function HeroHeadBtn:SetData(Param)
    self.Param = Param
    self:UpdateIcon()
end

function HeroHeadBtn:UpdateData(Param)
    self.Param = self.Param or {}
    self.Param.Data = Param.Data
    self.Param.HeroSkinId = Param.HeroSkinId
    self:UpdateIcon()
end

function HeroHeadBtn:UpdateIcon()
    local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,self.Param.HeroSkinId)
    if not TblSkin then
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.HeroIcon,TblSkin[Cfg_HeroSkin_P.PNGPath])
end

function HeroHeadBtn:Select()
    self.IsSelect = true
    self.View.Image_Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.Button:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function HeroHeadBtn:UnSelect()
    self.IsSelect = false
    self.View.Image_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Button:SetVisibility(UE.ESlateVisibility.Visible)
end

function HeroHeadBtn:Button_OnClicked()
    if self.Param and self.Param.ClickFunc then
        self.Param.ClickFunc()
    end
end

return HeroHeadBtn