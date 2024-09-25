--[[
    角色法福详情解耦逻辑
]]

local class_name = "HeroRuneDetailLogic"
local HeroRuneDetailLogic = BaseClass(nil, class_name)


function HeroRuneDetailLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
end

function HeroRuneDetailLogic:OnShow(Param)
    if not Param then
        return
    end
    self.HeroId = Param.HeroId
    self:UpdateShow();
end

function HeroRuneDetailLogic:OnHide()
end

function HeroRuneDetailLogic:OnShowAvator(Param,IsInit)
    local NeedShowHeroId = self.HeroId
    local SkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(NeedShowHeroId)
    self.WidgetBase:UpdateAvatarShow(NeedShowHeroId,SkinId,true)
end

function HeroRuneDetailLogic:UpdateShow()
    self:OnShowAvator()
end


return HeroRuneDetailLogic
