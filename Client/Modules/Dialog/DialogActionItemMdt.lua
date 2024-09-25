--[[
    剧情表现礼物界面
]]

local class_name = "DialogActionItemMdt";
DialogActionItemMdt = DialogActionItemMdt or BaseClass(GameMediator, class_name);

function DialogActionItemMdt:__init()
end

function DialogActionItemMdt:OnShow(data)
end

function DialogActionItemMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.GUIButton_Close.OnClicked,				Func = Bind(self,self.OnContinueClicked) },
	}
    UIHandler.New(self,self.CommonBtnTips_Continue, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.SpaceBar,
        OnItemClick = Bind(self,self.OnContinueClicked),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "Lua_DialogActionTaskMdt_Continue_Btn"),
    })
end

--[[
    Param->SetStringField(TEXT("TitleText"), TitleText.ToString());
    Param->SetStringField(TEXT("Des"), Des.ToString());
    Param->SetNumberField(TEXT("ItemId"), double(ItemId));
]]
function M:OnShow(Param)
    self.Param  = Param or {}

    self.Img_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Panel_Lock:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local TitleStr = self.Param.TitleText or ""
    local DesStr = self.Param.Des or ""
    if self.Param.ItemId > 0 then
        local StoryItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_StoryItemConfig, self.Param.ItemId)
        if StoryItemCfg then
            -- todo 是否需要支持3d物品
            self.Img_Icon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            CommonUtil.SetBrushFromSoftObjectPath(self.Img_Icon,StoryItemCfg[Cfg_StoryItemConfig_P.Icon])
            local IsUnlock = false
            local HeroId = MvcEntry:GetCtrl(DialogSystemCtrl):GetPlayingStoryHeroId()
            if HeroId then
                IsUnlock = MvcEntry:GetModel(FavorabilityModel):IsStoryItemUnlock(HeroId, self.Param.ItemId)
                if IsUnlock then
                    self.Panel_Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
                end
            end
            if TitleStr == "" then
                TitleStr = StoryItemCfg[Cfg_StoryItemConfig_P.Name]
            end
            if DesStr == "" then
                DesStr = IsUnlock and StoryItemCfg[Cfg_StoryItemConfig_P.DesUnlock] or StoryItemCfg[Cfg_StoryItemConfig_P.DesLock]
            end
        end
    end

    self.Text_Title:SetText(StringUtil.Format(TitleStr))
    self.RichText_Des:SetText(StringUtil.Format(DesStr))
end

function M:OnContinueClicked()
    -- todo 任务是否需要判断 还是直接结束
    if self.Param.WithoutNext then
        -- MvcEntry:CloseView(self.viewId)
        MvcEntry:GetCtrl(DialogSystemCtrl):DoStopStory(self.viewId)
    else
       MvcEntry:GetCtrl(DialogSystemCtrl):FinishCurAction() 
    end
end


return M
