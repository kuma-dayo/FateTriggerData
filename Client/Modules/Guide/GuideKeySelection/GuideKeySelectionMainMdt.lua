--[[
    新手引导键鼠套装选择界面
]]
local class_name = "GuideKeySelectionMainMdt"
GuideKeySelectionMainMdt = GuideKeySelectionMainMdt or BaseClass(GameMediator, class_name)

function GuideKeySelectionMainMdt:__init()
end

function GuideKeySelectionMainMdt:OnShow(data)
end

function GuideKeySelectionMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    local BottomBtnDataList = {
        [1] = {
            OnItemClick = Bind(self, self.OnClickMakeSureBtn),
            CommonTipsID = CommonConst.CT_SPACE,
            ActionMappingKey = ActionMappings.SpaceBar,
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_confirm_Btn"),
        }
    }
    local PopParam = {
        ContentType = CommonPopUpPanel.ContentType.Content,
        IsCloseBtnVisible = false,
        ShowBottomPanel = true,
        BottomBtnDataList = BottomBtnDataList,
        HideOutsideText = true,
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
    ---@type QuestionnaireModel
    self.Model = MvcEntry:GetModel(QuestionnaireModel)
    self.Index2ItemInst = {}
    self.CurSelectIndex = 1
end

function M:OnHide()
end

function M:OnShow()
    local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Guide/WBP_Guide_KeySelection.WBP_Guide_KeySelection")
    local Widget = NewObject(WidgetClass, self)
    local Content = self.CommonPopUpPanel:GetContentPanel()
    UIRoot.AddChildToPanel(Widget,Content)
    Content.Slot.Padding.Top = -5
    Content.Slot:SetPadding(Content.Slot.Padding)
    
    Widget.Slot:SetAutoSize(true)

    for Index = 1, 4 do
        if not self.Index2ItemInst[Index] and CommonUtil.IsValid(Widget["WBP_Guide_Item" .. Index]) then
            local Param = {
                Index = Index,
                ClickCb = Bind(self, self.UpdateItem),
                CurSelectIndex = self.CurSelectIndex,
            }
            self.Index2ItemInst[Index] = UIHandler.New(self, Widget["WBP_Guide_Item" .. Index], require("Client.Modules.Guide.GuideKeySelection.GuideKeySelectionItemLogic"), Param).ViewInstance
        end
    end
end

function M:UpdateItem(Index)
    self.CurSelectIndex = Index
    for i, Widget in ipairs(self.Index2ItemInst) do
        Widget:UpdateBtnState(Index)
    end
end

--点击确认按钮事件
function M:OnClickMakeSureBtn()
    local NewSettingValue = UE.FSettingValue()
    NewSettingValue.Value_Int = self.CurSelectIndex - 1
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local TabTag  = UE.FGameplayTag()
	TabTag.TagName ="Setting.Key"
    SettingSubsystem:ForceApplySetting("Setting.Key.Solution",NewSettingValue,TabTag)
    
    self:OnGuideStepComplete()
end

-- 新手引导完成关闭弹窗
function M:OnGuideStepComplete()
    MvcEntry:GetModel(GuideModel):DispatchType(GuideModel.GUIDE_SET_NEXT_STEP, GuideModel.Enum_GuideStep.ChooseKeyScheme)
    MvcEntry:CloseView(self.viewId)
end

return M
