--[[
    公用提示网页弹出框
]]
---@class UIWebBrowser
UIWebBrowser = UIWebBrowser or {}


--[[
    使用参考：    
    msgParam = {
      Url = "",
      TitleTxt = ""
    }
    UIWebBrowser.Show(msgParam)
]]

---展示通用网页弹窗
function UIWebBrowser.Show(msgParam)
    if not msgParam or not msgParam.Url then
        CError("UIWebBrowser Show msgParam Error")
        return
    end
    MvcEntry:OpenView(ViewConst.WebBrowseView, msgParam)
end


--[[
    网页弹出框Mdt类
]]
local class_name = "UIWebBrowserMdt"
UIWebBrowserMdt = UIWebBrowserMdt or BaseClass(GameMediator, class_name)

function UIWebBrowserMdt:__init()
end

function UIWebBrowserMdt:OnShow(data)
end

function UIWebBrowserMdt:OnHide()
end

--------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.BtnOutSide.OnClicked,		Func = self.OnCloseClicked },
        { UDelegate = self.WBP_CommonBtn_Close.GUIButton_Main.OnClicked, Func = self.OnCloseClicked },
        { UDelegate = self.WebBrowser.OnBeforePopup,	Func = self.OnBeforePopup},
        { UDelegate = self.WebBrowser.OnMouseEnterStateChanged,	Func = self.OnMouseEnterStateChanged},
	}
end

function M:OnShow(msg)
    self.MsgParam = msg
    if self.MsgParam == nil or self.MsgParam.Url == nil then
        return
    end
    
    self.WebBrowser:LoadURL(self.MsgParam.Url)
    self:SetTitle(self.MsgParam.TitleTxt)
end

function M:SetTitle(TitleTxt)
    if TitleTxt then
        self.Text_Title:SetText(TitleTxt)    
    end
end

function M:OnBeforePopup(Url, Frame)
    CWaring(StringUtil.Format("OnBeforePopup: Url:{0} Frame:{1}",Url, Frame))
    self.WebBrowser:LoadURL(Url)
end

function M:OnMouseEnterStateChanged(Enter)
    local LocalPC = CommonUtil.GetLocalPlayerC()
    if  LocalPC == nil then
        return
    end
    if Enter then
        LocalPC:SetUseSoftwareCursorWidgets(false)
    else
        LocalPC:SetUseSoftwareCursorWidgets(true)
    end
end

function M:OnCloseClicked()
    MvcEntry:CloseView(ViewConst.WebBrowseView)
end


return M