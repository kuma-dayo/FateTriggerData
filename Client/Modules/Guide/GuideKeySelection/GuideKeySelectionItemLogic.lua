--- 视图控制器：新手键鼠套装选择项逻辑
local class_name = "GuideKeySelectionItemLogic"
local GuideKeySelectionItemLogic = BaseClass(UIHandlerViewBase, class_name)

function GuideKeySelectionItemLogic:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.View.GUIButton.OnClicked,	Func = Bind(self,self.OnBtnClick) },
	}
    self.Index = 1
end

--[[
    Param = {
        Index = 1                --【必选】选择项下标
        ClickCb = function() end --【可选】选择项点击回调
        CurSelectIndex = 1       --【可选】当前选择项下标
    }
]]
function GuideKeySelectionItemLogic:OnShow(Param)
    if not Param or not Param.Index then
        return
    end
    self.Index = Param.Index
    self.ClickCb = Param.ClickCb
    self.CurSelectIndex = Param.CurSelectIndex and Param.CurSelectIndex or 1
    self:UpdateUI()
end

function GuideKeySelectionItemLogic:OnHide()
end

function GuideKeySelectionItemLogic:UpdateUI()
    self.View:SetBtnState(self.CurSelectIndex == self.Index)
end

function GuideKeySelectionItemLogic:OnBtnClick()
    if self.CurSelectIndex == self.Index then
        return
    end
    if self.ClickCb then
        self.ClickCb(self.Index)
    end
end

function GuideKeySelectionItemLogic:UpdateBtnState(Index)
    self.CurSelectIndex = Index
    self.View:SetBtnState(Index == self.Index)
end

return GuideKeySelectionItemLogic
