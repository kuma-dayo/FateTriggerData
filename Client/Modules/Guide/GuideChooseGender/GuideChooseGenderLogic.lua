--- 新手引导-选择礼物逻辑
local class_name = "GuideChooseGenderLogic"
local GuideChooseGenderLogic = BaseClass(UIHandlerViewBase, class_name)
local HeadWidgetUtil = require("Client.Modules.PlayerInfo.HeadIconSetting.HeadWidgetUtil")

function GuideChooseGenderLogic:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.View.Button_Gift_1.OnClicked,	Func = Bind(self,self.OnBtnClick, 1) },
        { UDelegate = self.View.Button_Gift_2.OnClicked,	Func = Bind(self,self.OnBtnClick, 2) },
	}

    self.GiftItemList = {}
    self.ClickCb = nil
    self.CurSelectIndex = nil

    ---@type DepotModel
    self.DepotModel = MvcEntry:GetModel(DepotModel)
    ---@type HeadIconSettingModel
    self.HeadIconSettingModel = MvcEntry:GetModel(HeadIconSettingModel)
end

--[[
    Param = {
        ClickCb = function() end --【必选】选择项点击回调
    }
]]
function GuideChooseGenderLogic:OnShow(Param)
    if not Param then
        return
    end
    self.ClickCb = Param.ClickCb
    self:UpdateUI()
end

function GuideChooseGenderLogic:OnHide()
end

function GuideChooseGenderLogic:UpdateUI()
    self:UpdateGiftShow()
end

-- 更新礼物展示
function GuideChooseGenderLogic:UpdateGiftShow()
    local GuideHeadWighetMale = CommonUtil.GetParameterConfig(ParameterConfig.GuideHeadWighetMale, 600030005)
    local GuideHeadWighetFemale = CommonUtil.GetParameterConfig(ParameterConfig.GuideHeadWighetFemale, 600030006)
    self.GiftItemList = {}
    self.GiftItemList[1] = GuideHeadWighetMale
    self.GiftItemList[2] = GuideHeadWighetFemale
    for Index, ItemId in ipairs(self.GiftItemList) do
        local Panel_Widget = self.View["Panel_Widget_" .. Index]
        self:UpdateGiftItem(Panel_Widget, ItemId)
    end
end

-- 更新礼物展示
function GuideChooseGenderLogic:UpdateGiftItem(Panel_Widget, ItemId)
    if Panel_Widget then
        local ShowWidgetList = {}
        local HeadWidgetId = ItemId
        local Cfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadWidget, HeadWidgetId)
        if Cfg then
            local ShowWidgetInfo = {
                Angle = 0,
                Cfg = Cfg,
            }
            table.insert(ShowWidgetList,ShowWidgetInfo)
        end
        local HeadIconSize = Panel_Widget.Slot:GetSize().X
        HeadWidgetUtil.CreateHeadWidgets(Panel_Widget, self.View, ShowWidgetList, HeadIconSize/HeadWidgetUtil.DefaultSize) -- 挂件设置界面头像大小/通用头像大小98
    end
end

function GuideChooseGenderLogic:OnBtnClick(Index)
    if self.CurSelectIndex == Index then
        return
    end
    self.CurSelectIndex = Index
    self:UpdateBtnState()
    local SelectItemId = self.GiftItemList[self.CurSelectIndex]
    if self.ClickCb then
        self.ClickCb(SelectItemId)
    end
end

function GuideChooseGenderLogic:UpdateBtnState()
    for Index, _ in ipairs(self.GiftItemList) do
        local EventName = self.CurSelectIndex == Index and "VXE_Btn" .. tostring(Index) .. "_Select" or "VXE_Btn" .. tostring(Index) .. "_UnSelect"
        if self.View[EventName] then
            self.View[EventName](self.View)
        end
    end
end

return GuideChooseGenderLogic
