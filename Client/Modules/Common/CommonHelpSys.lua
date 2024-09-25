--[[
    帮助界面
]]

local class_name = "CommonHelpSysMdt";
CommonHelpSysMdt = CommonHelpSysMdt or BaseClass(GameMediator, class_name);

function CommonHelpSysMdt:__init()
end

function CommonHelpSysMdt:OnShow(data)
end

function CommonHelpSysMdt:OnHide()
end

-------------------------------------------------------------------------------
--[[
    通用的HelpSysInnerView控件
]]
local HelpSysInnerView = BaseClass(nil, "HelpSysInnerView")
function HelpSysInnerView:OnInit()
    self.BindNodes = {
        {UDelegate =  self.View.WBP_List.OnUpdateItem, Func = Bind(self, self.OnUpdateItem)},
    }
end
--- OnShow
---@param Params number
function HelpSysInnerView:OnShow(Params)
    local Cfg = Params.Cfg
    local _, Contents = StringUtil.SplitTitleAndContentStrings(Cfg[Cfg_HelpSysConfig_P.Content])
    self.DataList = Contents
    self.View.WBP_List:Reload(#self.DataList)
end
function HelpSysInnerView:OnHide()
end

function HelpSysInnerView:OnUpdateItem(_, Widget, Index)
    local FixIndex = Index + 1
    local Data = self.DataList[FixIndex]
    if Data == nil then
        return
    end
    Widget.Text_Title:SetText(StringUtil.Format(Data.Title))
    Widget.RichText_Des:SetText(StringUtil.Format(Data.Content))
end
-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

M.UMGPath = '/Game/BluePrints/UMG/OutsideGame/HelpSys/WBP_HelpSys_InnerView.WBP_HelpSys_InnerView'
function M:OnInit()
end

function M:OnShow(Params)
    if not Params then
        CError("CommonHelpSysMdt Param Error")
        print_trackback()
        self:OnClose()
        return
    end

    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_HelpSysConfig, Params.Id)
    if not Cfg then
        CError("CommonHelpSysMdt cfg is nil id:"..Params.Id)
        return
    end

    local ContentWidgetCls = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(M.UMGPath))
    self.ContentWidget = NewObject(ContentWidgetCls, self)
    local PopUpBgParam = {
        TitleText = Cfg[Cfg_HelpSysConfig_P.MainTittle],
        ContentWidget = self.ContentWidget,
        BtnList = {
            [1] = {
                BtnParam = {
                    OnItemClick = Bind(self,self.OnClose),
                    TipStr = G_ConfigHelper:GetStrFromCommonStaticST("101"),
                    HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
                },
            },
        },
        CloseCb = Bind(self,self.OnClose)
    }
    UIHandler.New(self,self.WBP_CommonPopUp_Bg_L,CommonPopUpBgLogic,PopUpBgParam)
    UIHandler.New(self,self.ContentWidget,HelpSysInnerView,{Cfg = Cfg})
end

function M:OnHide()
end

--点击关闭界面
function M:OnClose()
    MvcEntry:CloseView(self.viewId)
end

return M