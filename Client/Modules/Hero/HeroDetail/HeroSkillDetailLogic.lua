--[[
    角色技能详情解耦逻辑
]]

local class_name = "HeroSkillDetailLogic"
local HeroSkillDetailLogic = BaseClass(UIHandlerViewBase, class_name)


function HeroSkillDetailLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    UIHandler.New(self, self.View.WBP_CommonBtn_Strong_L, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnClickGoToBtn),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Hero", "Lua_HeroSkillDetailLogic_GoTo_Btn"),
        CommonTipsID = CommonConst.CT_F,
        ActionMappingKey = ActionMappings.F,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

    self.BindNodes = 
    {
        { UDelegate = self.View.OnAnimationFinished_vx_hero_detail_out,	Func = Bind(self,self.On_vx_hero_detail_out_Finished) },
	}

end

--[[
    local Param = {
        HeroId = self.HeroId
    }
]]
function HeroSkillDetailLogic:OnShow(Param)
    if not Param then
        return
    end
    self.HeroId = Param.HeroId
    self:UpdateShow();
end

function HeroSkillDetailLogic:OnManualShow(Param)
    if not Param then
        return
    end
    self.HeroId = Param.HeroId
    self:UpdateShow();
end

function HeroSkillDetailLogic:UpdateUI(Param)
    if not Param then
        return
    end
    self.HeroId = Param.HeroId
    self:UpdateShow();
end

function HeroSkillDetailLogic:OnHide()
end

function HeroSkillDetailLogic:OnShowAvator(Param, IsInit, IsSkinSwitch, IsQuickSwitch)
    local NeedShowHeroId = self.HeroId
    local SkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(NeedShowHeroId)
    self.WidgetBase:UpdateAvatarShow(NeedShowHeroId, SkinId, true, nil, IsSkinSwitch, IsQuickSwitch)
end

function HeroSkillDetailLogic:UpdateShow()
    --TODO 更新技能展示
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,self.HeroId)
    if CfgHero then
        local SkillGroupId = CfgHero[Cfg_HeroConfig_P.SkillGroupId]
        local SkillList = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkillCfg,Cfg_HeroSkillCfg_P.SkillGroupId,SkillGroupId)
    
        self.View.Text_Des:SetText(CfgHero[Cfg_HeroConfig_P.HeroBiography])
    end
    self:PlayDynamicEffectByLike(true)
    -- self:OnShowAvator()
end

function HeroSkillDetailLogic:OnSkillListItemClick(SkillId)
    local Param = {
        SkillId = SkillId,
        ShowGroupSkillList = true,
    }
    MvcEntry:OpenView(ViewConst.HeroSkillPreView,Param)
end

function HeroSkillDetailLogic:OnViewAllClicked()
    local SkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(self.HeroId)
    local SkinDataList = {}

    local HeroDataList = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroConfig,Cfg_HeroConfig_P.IsShow,1)
    for k,v in ipairs(HeroDataList) do
        local SkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(v[Cfg_HeroConfig_P.Id])
        local CfgHeroSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,SkinId)
        table.insert(SkinDataList,CfgHeroSkin)
    end
    local Param = {
        SkinId = SkinId,
        SkinDataList = SkinDataList,
        FromID = HeroDetailPanelMdt.MenTabKeyEnum.Skill
    }
    MvcEntry:OpenView(ViewConst.HeroPreView,Param)
end

-- 前往好感度传记界面按钮点击
function HeroSkillDetailLogic:OnClickGoToBtn()
    local Param = {
        HeroId = self.HeroId,
        TabId = FavorablityMainMdt.MenuTabKeyEnum.Biography,
    }
    MvcEntry:OpenView(ViewConst.FavorablityMainMdt,Param)
end

--[[
    播放显示退出动效
]]
function HeroSkillDetailLogic:PlayDynamicEffectByLike(InIsShow)
    if InIsShow then
        if self.View.VXE_Hall_Hero_Detail_In then
            self.View:VXE_Hall_Hero_Detail_In()
        end
    else
        if self.View.VXE_Hall_Hero_Detail_Out then
            self.View:VXE_Hall_Hero_Detail_Out()
        end
    end
end

function HeroSkillDetailLogic:On_vx_hero_detail_out_Finished()
    
end


return HeroSkillDetailLogic
