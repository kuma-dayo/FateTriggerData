--[[
    关服提示界面
]]

local class_name = "ServerCloseNoticeMdt";
ServerCloseNoticeMdt = ServerCloseNoticeMdt or BaseClass(GameMediator, class_name);

function ServerCloseNoticeMdt:__init()
end

function ServerCloseNoticeMdt:OnShow(data)
end

function ServerCloseNoticeMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    -- self.CommonPopUpPanel = UIHandler.New(self, self.WBP_CommonPopPanel, CommonPopUpPanel).ViewInstance

    local UMGPath = '/Game/BluePrints/UMG/OutsideGame/Login/WBP_ServerCloseContent.WBP_ServerCloseContent'
    local ContentWidgetCls = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(UMGPath))
    self.ContentWidget = NewObject(ContentWidgetCls, self)

	-- 设置通用背景部分
    local PopUpBgParam = {
        TitleText =  G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","ServerCloseNoticeTitle"),
        ContentWidget = self.ContentWidget,
        CloseCb = Bind(self,self.OnClicked_CancelBtn),
        CloseTipText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","ServerCloseTipText"),
    }
    self.CommonPopUpBgLogicCls = UIHandler.New(self,self.WBP_CommonPopUp_Bg_L,CommonPopUpBgLogic,PopUpBgParam).ViewInstance
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    local DesValue = MvcEntry:GetCtrl(LoginCtrl):GetServerCloseInfo()
    self.ContentWidget.LbDes:SetText(DesValue or "None")
end

function M:OnRepeatShow(Param)
    
end

function M:OnHide()
   
end


function M:OnClicked_CancelBtn()
    CommonUtil.QuitGame(self)
end


return M
