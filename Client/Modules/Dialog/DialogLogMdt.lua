--[[
    剧情对话日志界面
]]

local class_name = "DialogLogMdt";
DialogLogMdt = DialogLogMdt or BaseClass(GameMediator, class_name);

function DialogLogMdt:__init()
end

function DialogLogMdt:OnShow(data)
end

function DialogLogMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.WBP_ReuseListEx_Content.OnUpdateItem,				    Func = self.OnUpdateItem },
	}
    UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
        OnItemClick = Bind(self,self.OnEscClicked),
    })
    self.HeroModel = MvcEntry:GetModel(HeroModel)
end

function M:OnShow()
    local DialogSystemCtrl = MvcEntry:GetCtrl(DialogSystemCtrl)
    self.Text_TitleIndex:SetText(DialogSystemCtrl:GetPlayingStoryChapterName())
    self.Text_Title:SetText(DialogSystemCtrl:GetPlayingStoryPartName())
    self.DialogLogList = MvcEntry:GetModel(DialogSystemModel):GetCacheDialogList()
    self.WBP_ReuseListEx_Content:Reload(#self.DialogLogList)
end

function M:OnUpdateItem(Widget,Index)
    local FixIndex = Index + 1
    local Param = self.DialogLogList[FixIndex]
    if not Param then
        return
    end
    Widget.Text_Title:SetText(MvcEntry:GetCtrl(DialogSystemCtrl):GetPlayingStoryHeroName())
    Widget.RichText_Des:SetText(self.DialogLogList[FixIndex].DialogText)
end

function M:OnEscClicked()
    MvcEntry:CloseView(self.viewId)
end

return M
