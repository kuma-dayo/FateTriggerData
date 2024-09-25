--[[
    角色技能列表Item逻辑
]]
local class_name = "HeroSkillListItemLogic"
local HeroSkillListItemLogic = BaseClass(nil, class_name)


function HeroSkillListItemLogic:OnInit()
    self.BindNodes = 
    {
        -- 上层BtnClick会影响底层SkillBgBtn的Hover效果，也暂不明确为什么需要两个按钮，先删除，仅用SkillBgBtn，后续发现问题再调整 @chenyishui
		-- { UDelegate = self.View.BtnClick.OnClicked,				    Func = Bind(self,self.BtnClick) },
		{ UDelegate = self.View.SkillBgBtn.OnClicked,				    Func = Bind(self,self.BtnClick) },
		{ UDelegate = self.View.SkillBgBtn.OnHovered,				    Func = Bind(self,self.OnSkillBgBtnHovered) },
		{ UDelegate = self.View.SkillBgBtn.OnUnhovered,				    Func = Bind(self,self.OnSkillBgBtnUnhovered) },
	}
    self.InitContentPos = self.View.Content.Slot:GetPosition()
    self.OffsetPosition = UE.FVector2D()
    self.OffsetPosition.X = self.InitContentPos.X - 40
    self.OffsetPosition.Y = self.InitContentPos.Y
end

--[[
    local Param = {
        SkillId = self.SkillId
        ClickCallback
    }
]]
function HeroSkillListItemLogic:OnShow(Param)
    self:UpdateUI(Param);
end

function HeroSkillListItemLogic:UpdateUI(Param)
    if not Param then
        return
    end
    self.Param = Param
    self.SkillId = Param.SkillId
    self.ClickCallback = Param.ClickCallback
    self:UpdateShow();
end

function HeroSkillListItemLogic:OnHide()
end

function HeroSkillListItemLogic:OnManualHide()
    self:OnSkillBgBtnUnhovered()
end

function HeroSkillListItemLogic:UpdateShow()
    --TODO 更新技能展示
    local CfgHeroSkill = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkillCfg,self.SkillId)

    self.View.SkillName:SetText(StringUtil.Format(CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillName]))
    self.View.SkillDes:SetText(StringUtil.Format(CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillDesSimple]))
    self.View.SkillType:SetText(StringUtil.Format(CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillType]))

    local Param = {
        SkillId = self.SkillId,
    }
    if not self.SkillIconCls then
        self.SkillIconCls = UIHandler.New(self,self.View.WBP_CommonSkillIcon,CommonSkillIcon,Param).ViewInstance
    else
        self.SkillIconCls:UpdateUI(Param)
    end
end

function HeroSkillListItemLogic:SetActiveLightShow(IsShow)
    self.IsSelect = IsShow
    self.View.ActiveLight:SetVisibility(IsShow and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    self.View.SkillBgBtn:SetVisibility(IsShow and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
    -- local NameColor = IsShow and "1B2024" or "F5EFDF"
    -- CommonUtil.SetTextColorFromeHex(self.View.SkillName,NameColor)
    -- local DesColor = IsShow and "1B2024" or "A29F96"
    -- CommonUtil.SetTextColorFromeHex(self.View.SkillDes,DesColor)
    -- local TypeColor = IsShow and "F5EFDF" or "E47A30"
    -- CommonUtil.SetTextColorFromeHex(self.View.SkillType,TypeColor)
    -- self.SkillIconCls:SetSkillTagColor(IsShow and "1B2024" or nil)
    local IsSelect = IsShow and true or false
    self:PlayDynamicEffectIsSelect(IsSelect)
    --self.View.Content.Slot:SetPosition(IsShow and self.OffsetPosition or self.InitContentPos)
end

--[[
    点击回调
]]
function HeroSkillListItemLogic:BtnClick()
    if self.ClickCallback then
        self.ClickCallback()
    end
    -- self:PlayDynamicEffectIsSelect(true)
end

function HeroSkillListItemLogic:OnSkillBgBtnHovered()
    --self.View.Content.Slot:SetPosition(self.OffsetPosition)
end
function HeroSkillListItemLogic:OnSkillBgBtnUnhovered()
    if self.IsSelect then
        return
    end
    --self.View.Content.Slot:SetPosition(self.InitContentPos)
end

--[[
    播放选中/未选中动效
]]
function HeroSkillListItemLogic:PlayDynamicEffectIsSelect(InIsSelect)
    if InIsSelect then
        if self.View.VXE_Btn_Select then
            self.View:VXE_Btn_Select()
        end
    else
        if self.View.VXE_Btn_UnSelect then
            self.View:VXE_Btn_UnSelect()
        end
    end
end

return HeroSkillListItemLogic
