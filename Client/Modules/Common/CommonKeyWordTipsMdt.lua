--[[
    关键词提示文本界面
]]

local class_name = "CommonKeyWordTipsMdt";
CommonKeyWordTipsMdt = CommonKeyWordTipsMdt or BaseClass(GameMediator, class_name);

function CommonKeyWordTipsMdt:__init()
end

function CommonKeyWordTipsMdt:OnShow(data)
end

function CommonKeyWordTipsMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = 
    {
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,  Func = self.OnOtherViewClosed},
	
	}
end


---@field KeyWord string 对应 StoryKeyConfig KeyWord字段
function M:OnShow(Param)
    if not (Param and Param.KeyWord and Param.FromViewId) then
        MvcEntry:CloseView(self.viewId)
        return
    end
    self.FromViewId = Param.FromViewId
    local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
    local _,CurViewPortPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(self,MousePos)
    CurViewPortPos.X = CurViewPortPos.X + 10
    CurViewPortPos.Y = CurViewPortPos.Y + 10
    self.MainPanel.Slot:SetPosition(CurViewPortPos)
    self:UpdateText(Param.KeyWord)
end

function M:OnHide()
end

function M:UpdateText(KeyWord)
    local KeyWordCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_StoryKeyConfig, Cfg_StoryKeyConfig_P.KeyWord, KeyWord)
    if not KeyWordCfg then
        CError("CommonKeyWordTipsMdt Error For KeyWord = "..KeyWord)
        MvcEntry:CloseView(self.viewId)
        return
    end
    self.Text_Title:SetText(KeyWordCfg[Cfg_StoryKeyConfig_P.ShowText])
    self.RichText_Content:SetText(KeyWordCfg[Cfg_StoryKeyConfig_P.ShowTipsDes])
end

function M:OnOtherViewClosed(ViewId)
    if ViewId == self.FromViewId then
        MvcEntry:CloseView(self.viewId)
    end
end



return M
