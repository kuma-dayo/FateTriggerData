--[[
    角色技能展示界面
]]

local class_name = "HeroSkillPreviewMdt";
HeroSkillPreviewMdt = HeroSkillPreviewMdt or BaseClass(GameMediator, class_name);


function HeroSkillPreviewMdt:__init()
end

function HeroSkillPreviewMdt:OnShow(data)
end

function HeroSkillPreviewMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.MsgList = 
    {
		-- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked },
        { Model = HeroModel,  MsgName = HeroModel.HERO_QUICK_TAB_HERO_SELECT, Func = self.HERO_QUICK_TAB_HERO_SELECT },
	}
    self.BindNodes = 
    {
		{ UDelegate = self.GUIButtonBgClose.OnClicked,				    Func = self.OnEscClicked },
	}
    UIHandler.New(self,self.CommonBtnTipsESC, WCommonBtnTips,
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroSkillPreviewMdt_return_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })
    self.CommonMediaCls = nil
    self.QuickTabInst = UIHandler.New(self, self.WBP_Hero_QuickTab_List, require("Client.Modules.Hero.HeroQuickTabLogic")).ViewInstance
end


--[[
    Param = {
        SkillId = self.SkillId,
        ShowGroupSkillList = true,
    }
]]
function M:OnShow(Param)
    self:UpdateUI(Param)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkillCfg,self.SkillId)
    if Cfg then
        ---@type HeroQuickTabLogicParam
        local Param = {
            HeroId = Cfg[Cfg_HeroSkillCfg_P.HeroID],
            NeedUpdateAvatar = true,
        }
        self.QuickTabInst:UpdateUI(Param)
    end
end

function M:OnHide()
    self.CommonMediaCls = nil
end

function M:UpdateUI(Param)
    self.SkillId = Param.SkillId
    self.ShowGroupSkillList = Param.ShowGroupSkillList
    self.SkillId2ViewInstance = {}

    local CfgHeroSkill = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkillCfg,self.SkillId)
    self.SkillInfoList:SetVisibility(self.ShowGroupSkillList and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if self.ShowGroupSkillList then
        local SkillList = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkillCfg,Cfg_HeroSkillCfg_P.SkillGroupId,CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillGroupId])
        for i=1,3 do
            local SkillItem = self["WBP_HeroSkill_ListItem_" .. i]
            local SkillCfg = SkillList[i]
            local SkillId = SkillCfg[Cfg_HeroSkillCfg_P.SkillId]
            local Param = {
                SkillId = SkillId,
                ClickCallback = Bind(self,self.OnSkillListItemClick,SkillId)
            }
            self.SkillId2ViewInstance[SkillId] = UIHandler.New(self,SkillItem, require("Client.Modules.Hero.Skill.HeroSkillListItemLogic"),Param).ViewInstance
        end
    end

    self:UpdateSkillShow()
end

function M:UpdateSkillShow()
    local CfgHeroSkill = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkillCfg,self.SkillId)
    CommonUtil.SetBrushFromSoftObjectPath(self.SkillIcon,CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillIcon])

    self.SkillName:SetText(StringUtil.Format(CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillName]))
    self.SKillDetailInfo:SetText(StringUtil.Format(CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillDesDetail]))
    self.SkillType:SetText(StringUtil.Format(CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillType]))
    self.CDNumber:SetText(StringUtil.Format("{0}s",CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillCd]))

    local CfgSkillTag = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkillTag,CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillTag])
    --TODO 更新技能标签展示
    self.SkillTag:SetText(StringUtil.Format(CfgSkillTag[Cfg_HeroSkillTag_P.SkillTagName]))

    for SkillId,ViewInstance in pairs(self.SkillId2ViewInstance) do
        ViewInstance:SetActiveLightShow(SkillId == self.SkillId)
        ViewInstance:PlayDynamicEffectIsSelect(SkillId == self.SkillId)
    end

    -- local MediaSource = LoadObject("FileMediaSource'/Game/Movies/HeroSkill/MV_SkillTest.MV_SkillTest'")
    -- self.MediaPlayer:OpenSource(MediaSource)
    local Param = {
        --MediaPlayer组件
        MediaPlayer = self.MediaPlayer,
        --MediaSource路径
        MediaSourcePath = CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillMovie],--"FileMediaSource'/Game/Movies/HeroSkill/MV_SkillTest.MV_SkillTest'",
        --WBP_Common_Video
		WBP_Common_Video = self.WBP_Common_Video,
        --是否自动播放
        AutoPlay = true,
    }
    if not self.CommonMediaCls then
        self.CommonMediaCls = UIHandler.New(self,self.WBP_Common_Video.PanelVideo, CommonMediaPlayer,Param).ViewInstance
    else
        self.CommonMediaCls:UpdateData(Param)
    end
end

--快速切换英雄详情事件
function M:HERO_QUICK_TAB_HERO_SELECT(Param)
    if not Param or not Param.HeroId then
        return
    end
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, Param.HeroId)
    if not CfgHero then
        return
    end
    local SkillList = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkillCfg,Cfg_HeroSkillCfg_P.SkillGroupId, CfgHero[Cfg_HeroConfig_P.SkillGroupId])
    if not SkillList or #SkillList < 1 then
        CWaring(StringUtil.Format("HeroSkillPreviewMdt:HERO_QUICK_TAB_HERO_SELECT SkillCfg Is nil SkillGroupId:{0}",CfgHero[Cfg_HeroConfig_P.SkillGroupId]))
        return
    end
    local SkillCfg = SkillList[1]
    local Param = {
        SkillId = SkillCfg[Cfg_HeroSkillCfg_P.SkillId],
        ShowGroupSkillList = self.ShowGroupSkillList,
    }
    self:UpdateUI(Param)
end

function M:OnSkillListItemClick(SkillId)
    if self.SkillId == SkillId then
        return
    end
    self.SkillId = SkillId
    self:UpdateSkillShow()
end

function M:OnEscClicked()
    MvcEntry:CloseView(self.viewId)
    return true
end

return M