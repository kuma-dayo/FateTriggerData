--[[
    新手引导选择性别界面
]]

local class_name = "GuideChooseGenderMdt";
GuideChooseGenderMdt = GuideChooseGenderMdt or BaseClass(GameMediator, class_name);

function GuideChooseGenderMdt:__init()
end

function GuideChooseGenderMdt:OnShow(data)
end

function GuideChooseGenderMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()

    local UMGPath = '/Game/BluePrints/UMG/OutsideGame/Guide/WBP_Guide_Gift.WBP_Guide_Gift'
    local ContentWidgetCls = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(UMGPath))
    self.ContentWidget = NewObject(ContentWidgetCls, self)
    local PopUpBgParam = {
        TitleText = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Guide", "SelectGift")),
        ContentWidget = self.ContentWidget,
        HideCloseTip = true,
    }
    self.CommonPopUpWigetLogic = UIHandler.New(self,self.WBP_CommonPopUp_Bg_L,CommonPopUpBgLogic,PopUpBgParam).ViewInstance
    self.GuideChooseGenderLogic = UIHandler.New(self,self.ContentWidget,require("Client.Modules.Guide.GuideChooseGender.GuideChooseGenderLogic")).ViewInstance
    self.SelectItemId = nil
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    self:UpdateGiftShow()
    self:UpdateBtnShow()
end

function M:OnRepeatShow(Param)
    
end

-- 更新礼物展示
function M:UpdateGiftShow()
    if self.GuideChooseGenderLogic then
        local Param = {
            ClickCb = Bind(self, self.OnClickGiftItem)
        }
        self.GuideChooseGenderLogic:OnShow(Param)
    end
end

-- 礼物点击回调
function M:OnClickGiftItem(SelectItemId)
    self.SelectItemId = SelectItemId
    self:UpdateBtnShow()
end

-- 更新按钮的显示
function M:UpdateBtnShow()
    local IsBtnEnable = self.SelectItemId ~= nil and true or false
    local BtnList = {
        [1] = {
            BtnParam = {
                IsEnabled = IsBtnEnable,
                OnItemClick = Bind(self,self.OnEquipBtnClick),
                TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Guide", "EquipHeadWidget")),
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            },
        },
    }
    self.CommonPopUpWigetLogic:UpdateBtnList(BtnList)
end

-- 装备按钮点击 
function M:OnEquipBtnClick()
    if self.SelectItemId then
        ---@type GuideCtrl
        local GuideCtrl = MvcEntry:GetCtrl(GuideCtrl)
        GuideCtrl:SendPlayerChooseGenderReq(self.SelectItemId)

        self:OnGuideStepComplete()
    end
end

function M:OnHide()
   
end

-- 新手引导完成关闭弹窗
function M:OnGuideStepComplete()
    local Tip = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Guide", "EquipSuccessTip")
    local ItemName = MvcEntry:GetModel(DepotModel):GetItemName(self.SelectItemId)
    UIAlert.Show(StringUtil.Format(Tip, ItemName))
    MvcEntry:GetModel(GuideModel):DispatchType(GuideModel.GUIDE_SET_NEXT_STEP, GuideModel.Enum_GuideStep.ChooseGender)
    self:OnClose()
end

-- 关闭界面
function M:OnClose()
    MvcEntry:CloseView(self.viewId)
end

return M
