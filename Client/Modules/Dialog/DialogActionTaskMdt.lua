--[[
    剧情表现任务界面
]]

local class_name = "DialogActionTaskMdt";
DialogActionTaskMdt = DialogActionTaskMdt or BaseClass(GameMediator, class_name);

function DialogActionTaskMdt:__init()
end

function DialogActionTaskMdt:OnShow(data)
end

function DialogActionTaskMdt:OnHide()
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
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "Lua_DialogActionTaskMdt_Continue_Btn"),
        OnItemClick = Bind(self,self.OnContinueClicked),
    })
end

--[[
    Param->SetStringField(TEXT("TitleText"), TitleText.ToString());
    Param->SetStringField(TEXT("Des"), Des.ToString());
    Param->SetNumberField(TEXT("ItemId"), double(ItemId));
]]
function M:OnShow(Param)
    self.Param  = Param or {}

    self.Text_Title:SetText(StringUtil.Format(self.Param.TitleText))
    self:RemoveAllActiveWidgetStyleFlags()
    if self.Param.ItemId > 0 then
        self:AddActiveWidgetStyleFlags(1)
        local StoryItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_StoryItemConfig, self.Param.ItemId)
        if StoryItemCfg then
            CommonUtil.SetBrushFromSoftObjectPath(self.Img_Icon,StoryItemCfg[Cfg_StoryItemConfig_P.Icon])
        end
        self.RichText_Des:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.RichText_Des_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.RichText_Des_1:SetText(StringUtil.Format(self.Param.Des))
    else
        self:AddActiveWidgetStyleFlags(0)
        self.RichText_Des:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.RichText_Des_1:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.RichText_Des:SetText(StringUtil.Format(self.Param.Des))
    end
    -- 上报任务接取
    MvcEntry:GetCtrl(DialogSystemCtrl):DoReceiveTask()
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
