--[[
    剧情表现纯文本界面
]]

local class_name = "DialogActionTextMdt";
DialogActionTextMdt = DialogActionTextMdt or BaseClass(GameMediator, class_name);

function DialogActionTextMdt:__init()
end

function DialogActionTextMdt:OnShow(data)
end

function DialogActionTextMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.RichText_Content.OnHyperlinkHovered,				    Func = self.OnHoverKeyText },
		{ UDelegate = self.RichText_Content.OnHyperlinkUnhovered,				    Func = self.OnUnhoverKeyText },
	}

    UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
        OnItemClick = Bind(self,self.OnEscClicked),
    })
    
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    self.Param  = Param or {}
    local TitleText = Param.TitleText ~= "" and Param.TitleText or ""
    local Des = Param.Des ~= "" and Param.Des or ""
    self.Text_Title:SetText(StringUtil.Format(TitleText))
    self.RichText_Content:SetText(StringUtil.Format(Des))
    self.ScrollBox_Content:ScrollToStart()
end

function M:OnRepeatShow(Param)
end

function M:OnHide()
end

function M:OnHoverKeyText(ActionKey)
    local Param = {
        KeyWord = ActionKey,
        FromViewId = self.viewId
    }
    MvcEntry:OpenView(ViewConst.CommonKeyWordTips,Param)
end

function M:OnUnhoverKeyText(ActionKey)
    MvcEntry:CloseView(ViewConst.CommonKeyWordTips)
end

function M:OnEscClicked()
    if self.Param.WithoutNext then
        -- MvcEntry:CloseView(self.viewId)
        MvcEntry:GetCtrl(DialogSystemCtrl):DoStopStory(self.viewId)
    else
       MvcEntry:GetCtrl(DialogSystemCtrl):FinishCurAction() 
    end
end


return M
