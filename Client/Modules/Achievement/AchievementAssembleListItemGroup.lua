local  AchievementConst = require("Client.Modules.Achievement.AchievementConst")
--- 视图控制器
local class_name = "AchievementAssembleListItemGroup";
local AchievementAssembleListItemGroup = BaseClass(nil, class_name);

---@type AchievementData[]
AchievementAssembleListItemGroup.DataList = nil
AchievementAssembleListItemGroup.WidgetList = nil

function AchievementAssembleListItemGroup:OnInit()
    self.DataList = nil
    self.CallBack = nil
    self.WidgetList = {}
end

function AchievementAssembleListItemGroup:OnShow()
end

function AchievementAssembleListItemGroup:OnHide()
    self.Data = nil
    self.WidgetList = nil
end

function AchievementAssembleListItemGroup:SetData(List, CallBack)
    self.DataList = List
    self.CallBack = CallBack
    for i = 1, 6 do
        repeat
            local ItemId = List[i]
            local parentWidget = self.View["WBP_CommonItemIcon_"..i]
            parentWidget.RootName:SetVisibility(UE.ESlateVisibility.Collapsed)
            local Widget = parentWidget.WBP_CommonItemIcon
            local IconParam = {
                IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
                ItemId = ItemId,
                DragCallBackFunc = Bind(self, self.DragCallBackFunc),
                ClickMethod = UE.EButtonClickMethod.DownAndUp,
                HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
                ShowItemName = true,
                IsCheckAchievementCornerTag = true
            }
            if not ItemId then
                Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
                break
            end
            Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            local Data = MvcEntry:GetModel(AchievementModel):GetData(ItemId)
            parentWidget.RootName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            parentWidget.GUITextBlock_Name:SetText(Data:GetName())
    
            if not self.WidgetList[i] then
                self.WidgetList[i] = UIHandler.New(self, Widget, CommonItemIcon, IconParam).ViewInstance
            else
                self.WidgetList[i]:UpdateUI(IconParam)
            end
        until true
    end
end

function AchievementAssembleListItemGroup:DragCallBackFunc(Param)
    if self.CallBack then
        self.CallBack(Param.ItemId, Param.DragType)
    end
end

return AchievementAssembleListItemGroup
