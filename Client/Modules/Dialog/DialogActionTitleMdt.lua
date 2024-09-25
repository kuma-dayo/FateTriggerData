--[[
    剧情表现标题界面
]]

local class_name = "DialogActionTitleMdt";
DialogActionTitleMdt = DialogActionTitleMdt or BaseClass(GameMediator, class_name);

function DialogActionTitleMdt:__init()
end

function DialogActionTitleMdt:OnShow(data)
end

function DialogActionTitleMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
end

--[[
	Param->SetStringField(TEXT("TitleIndexStr"), TitleIndexStr);
	Param->SetStringField(TEXT("TitleText"), TitleText.ToString());
	Param->SetNumberField(TEXT("Duration"), double(Duration));
]]
function M:OnShow(Param)
    self.Param  = Param or {}
    -- if Param.BgImage ~= "" then
    --     CommonUtil.SetBrushFromSoftObjectPath(self.BgImage,Param.BgImage)
    -- end
    local TitleText = Param.TitleText ~= "" and Param.TitleText or MvcEntry:GetCtrl(DialogSystemCtrl):GetPlayingStoryPartName()
    local TitleIndexStr = Param.TitleIndexStr ~= "" and Param.TitleIndexStr or MvcEntry:GetCtrl(DialogSystemCtrl):GetPlayingStoryChapterName()
    self.Text_TitleIndex:SetText(StringUtil.Format(TitleIndexStr))
    self.Text_Title:SetText(StringUtil.Format(TitleText))
    local Duration = Param.Duration > 0 and Param.Duration or 1
    self:InsertTimer(Duration,function()
        self:OnEscClicked()
    end)
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
