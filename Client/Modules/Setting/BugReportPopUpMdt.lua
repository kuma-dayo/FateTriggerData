--[[
    BUG上报界面
]] 
local class_name = "BugReportPopUpMdt";
BugReportPopUpMdt = BugReportPopUpMdt or BaseClass(GameMediator, class_name);

function BugReportPopUpMdt:__init()
    self:ConfigViewId(ViewConst.SettingBugReportPopUp)
end

function BugReportPopUpMdt:OnShow(data)
end

function BugReportPopUpMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.CheckBox.OnCheckStateChanged,				    Func = self.OnCheckStateChanged },
	}

    UIHandler.New(self,self.Btn_Cancel, WCommonBtnTips, 
    {
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Cancel"),
        OnItemClick = Bind(self,self.OnCancelClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.Escape,
    })
    --默认设置提交日志CHECKED
    self.CheckBox:SetIsChecked(true)
    self:UpdateSubCommitBtn()
end

function M:OnShow()
    CWaring("BugReportPopUpMdt ==== SHOW")
    self:ShowWBP_CommonPopUp_Bg_L()
end


function M:ShowWBP_CommonPopUp_Bg_L()
    local PopUpBgParam = {
		TitleText = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "11107"),
        CloseCb = Bind(self, self.OnCancelClicked),
	}
	if self.CommonPopUp_BgIns == nil or not(self.CommonPopUp_BgIns:IsValid()) then
		self.CommonPopUp_BgIns = UIHandler.New(self, self.WBP_CommonPopUp_Bg_L, CommonPopUpBgLogic, PopUpBgParam).ViewInstance
    else
        self.CommonPopUp_BgIns:ManualOpen(PopUpBgParam)
	end
end

function M:UpdateSubCommitBtn()
    local SDSettingTitleKey = self.CheckBox:IsChecked() and "11112_Btn" or "11113_Btn" 
    local Param =  {
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', SDSettingTitleKey),
        OnItemClick = Bind(self,self.OnSubmitClicked),
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
    }
    if self.SubmitInst == nil or not(self.SubmitInst:IsValid()) then
        self.SubmitInst = UIHandler.New(self, self.Btn_Submit, WCommonBtnTips,Param).ViewInstance
    else
        self.SubmitInst:UpdateItemInfo(Param)
    end
end


function M:OnCheckStateChanged()
    self:UpdateSubCommitBtn()
end


function M:OnCancelClicked()
    MvcEntry:CloseView(self.viewId)
end

function M:OnSubmitClicked()
    local LogTitle = self.TitleInput:GetText()
    if LogTitle == "" then
        return
    end
    local LogDesc = self.DesInput:GetText()
    local IsOK = UE.UGFUnluaHelper.ReportManualLog(LogTitle, LogDesc, self.CheckBox:IsChecked())
    if IsOK then
        local msgParam = {
            title =  StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "11107")),
            describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "11114")),
            rightBtnInfo = {
                callback = function()
                    self:OnCancelClicked()
                end
            }
        }
        UIMessageBox.Show(msgParam)
    end
end



return M
