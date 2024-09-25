local class_name = "HeroQuickTabHeroListItem"
local HeroQuickTabHeroListItem = BaseClass(nil, class_name)

---@class HeroQuickTabHeroListItemParam
---@field HeroId number 英雄ID
---@field SelectId number 选中英雄ID
---@field Index number 实际下标
---@field NeedUpdateAvatar boolean 是否更新大厅英雄页签Avatar
function HeroQuickTabHeroListItem:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.HeroPartListbtn.OnClicked, Func = Bind(self, self.OnClicked_BtnClick)},
        { UDelegate = self.View.HeroPartListbtn.OnHovered,				Func = Bind(self, self.OnBtnHovered) },
        { UDelegate = self.View.HeroPartListbtn.OnUnhovered,		    Func = Bind(self, self.OnBtnUnhovered) },
    }
    self.MsgList = 
    {
        { Model = HeroModel,  MsgName = HeroModel.HERO_QUICK_TAB_HERO_SELECT, Func = Bind(self, self.HERO_QUICK_TAB_HERO_SELECT) },
	}
end

function HeroQuickTabHeroListItem:OnShow(Param)
end

function HeroQuickTabHeroListItem:OnHide()
end

function HeroQuickTabHeroListItem:UpdateUI(Param)
    --TODO 根据数据进行展示
    self.Param = Param
    self.HeroId = self.Param.HeroId
    self.SelectId = self.Param.SelectId
    self:UpdateSkinStateShow()
    self.View.Quality_Img:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function HeroQuickTabHeroListItem:UpdateSkinStateShow()
    self.Select = self.SelectId == self.HeroId
    local HeroCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, self.HeroId)
    local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,HeroCfg[Cfg_HeroConfig_P.SkinId]) 

    CommonUtil.SetBrushFromSoftObjectPath(self.View.Icon_Head_Item, TblSkin[Cfg_HeroSkin_P.PNGPath])
    self.View:SetWidgetState(0, self.Select)
end

function HeroQuickTabHeroListItem:HERO_QUICK_TAB_HERO_SELECT(_, Param)
    if not Param or not Param.HeroId then
        return
    end
    self.Param.SelectId = Param.HeroId
    self.SelectId = Param.HeroId
    self:UpdateSkinStateShow()
end


function HeroQuickTabHeroListItem:OnClicked_BtnClick()
    if self.Select then
        return
    end
    MvcEntry:GetModel(HeroModel):DispatchType(HeroModel.HERO_QUICK_TAB_HERO_SELECT, self.Param)
end

function HeroQuickTabHeroListItem:OnBtnHovered()
    MvcEntry:GetModel(HeroModel):DispatchType(HeroModel.HERO_QUICK_TAB_HOVER)
    
end

function HeroQuickTabHeroListItem:OnBtnUnhovered()
    MvcEntry:GetModel(HeroModel):DispatchType(HeroModel.HERO_QUICK_TAB_UNHOVER)
    
end

return HeroQuickTabHeroListItem
