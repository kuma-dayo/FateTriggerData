
--- 视图控制器
local class_name = "GuideMainMdt";
GuideMainMdt = GuideMainMdt or BaseClass(GameMediator, class_name);

function GuideMainMdt:__init()
end

function GuideMainMdt:OnShow(data)
    
end

function GuideMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.InputFocus = true
    self.MsgList = 
    {
		{Model = GuideModel, MsgName = GuideModel.CLOSE_GUIDE_VIEW, Func = self.OnGuideClose},
    }

    -- self.BindNodes = 
    -- {
	-- 	{ UDelegate = self.GUIButton_Back.OnClicked,				    Func = self.GUIButton_Close_ClickFunc },
	-- }

    self.Model = MvcEntry:GetModel(GuideModel)
    self.GuideID = 100001
end

function M:OnHide()
    -- MvcEntry:GetModel(InputModel).Enable = true
end

function M:OnGuideClose()
    self:PlayAnimation(self.VX_GuideUI_Out)
    self.VX_GuideUI_Out:UnbindAllFromAnimationFinished(self)
    self.VX_GuideUI_Out:BindToAnimationFinished(self,function ()
        MvcEntry:CloseView(ViewConst.Guide)
    end)
end

function M:OnShow(Params)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_GuideConfig, self.GuideID)
    if not Cfg then
        MvcEntry:CloseView(ViewConst.Guide)
        return
    end
    self.Text_Tips:SetText(Cfg[Cfg_GuideConfig_P.Content])
    -- MvcEntry:GetModel(InputModel).Enable = false
    self:PlayAnimation(self.VX_GuideUI_In)
    self.VX_GuideUI_In:UnbindAllFromAnimationFinished(self)
    self.VX_GuideUI_In:BindToAnimationFinished(self,function ()
        self:PlayAnimation(self.VX_GuideUI_Loop, 0, 0)
        self:PlayAnimation(self.VX_GuideUI_Loop2, 0, 0)
    end)
end

return M
