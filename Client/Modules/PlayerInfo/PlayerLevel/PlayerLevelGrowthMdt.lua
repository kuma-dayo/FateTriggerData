--[[
    等级成长历程界面
]]

local class_name = "PlayerLevelGrowthMdt";
PlayerLevelGrowthMdt = PlayerLevelGrowthMdt or BaseClass(GameMediator, class_name);

function PlayerLevelGrowthMdt:__init()
end

function PlayerLevelGrowthMdt:OnShow(data)
end

function PlayerLevelGrowthMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    local PopParam = {
        ContentType = CommonPopUpPanel.ContentType.Content,
        CloseCb = Bind(self,self.GUIButton_Close_ClickFunc),
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
end

function M:OnHide()
end

function M:OnShow()
    local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Information/GradeProcess/WBP_GradeProcess_Main.WBP_GradeProcess_Main")
    local Widget = NewObject(WidgetClass, self)
    UIRoot.AddChildToPanel(Widget,self.CommonPopUpPanel:GetContentPanel())

    Widget.Slot:SetAutoSize(true)
    if self.PlayerLevelGrowthViewInst == nil then
        self.PlayerLevelGrowthViewInst = UIHandler.New(self, Widget, require("Client.Modules.PlayerInfo.PlayerLevel.PlayerLevelGrowthLogic")).ViewInstance
    else 
        self.PlayerLevelGrowthViewInst:UpdateUI()
    end
end

--点击关闭按钮事件
function M:GUIButton_Close_ClickFunc()
    MvcEntry:CloseView(self.viewId)
end


return M
