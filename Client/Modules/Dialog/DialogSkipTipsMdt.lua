--[[
    剧情表现跳过提示界面
]]

local class_name = "DialogSkipTipsMdt";
DialogSkipTipsMdt = DialogSkipTipsMdt or BaseClass(GameMediator, class_name);

function DialogSkipTipsMdt:__init()
end

function DialogSkipTipsMdt:OnShow(data)
end

function DialogSkipTipsMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()

    self.BindNodes = 
    {
		{ UDelegate = self.Button_BGClose.OnClicked,	Func = self.OnCancelSkip },
	}

    UIHandler.New(self,self.WBP_CommonBtn_Cancel, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.Escape,
        OnItemClick = Bind(self,self.OnCancelSkip),
    })
    UIHandler.New(self,self.WBP_CommonBtn_Enter, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "1101_Btn"),
        OnItemClick = Bind(self,self.OnEnterSkip),
    })
end

--[[
    
]]
function M:OnShow(Param)
    self.Param = Param
    self.TextBlock_Title:SetText(Param.TitleStr)
    self.RichText_Content:SetText(Param.DesStr)
end

function M:OnHide()
end

function M:OnEnterSkip()
    MvcEntry:GetCtrl(DialogSystemCtrl):DoFinishStory()
    MvcEntry:CloseView(self.viewId)
end

function M:OnCancelSkip()
    MvcEntry:CloseView(self.viewId)
end

return M
