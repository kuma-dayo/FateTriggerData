local  AchievementConst = require("Client.Modules.Achievement.AchievementConst")
--- 视图控制器
local class_name = "AchievementAssembleSlotItem";
local AchievementAssembleSlotItem = BaseClass(nil, class_name);

---@type AchievementData
AchievementAssembleSlotItem.Data = nil

function AchievementAssembleSlotItem:OnInit()
    self.MsgList = 
    {
		{Model = AchievementModel, MsgName = AchievementModel.ACHIEVE_STATE_CHANGE_ON_SLOT, Func = self.OnAchievementSlotChange},
    }

    self.BindNodes = 
    {
		{ UDelegate = self.View.Button_Slot.OnClicked,				    Func = Bind(self, self.OnCicked) },
		{ UDelegate = self.View.Button_Slot.OnHovered,				    Func = Bind(self, self.OnHovered) },
        { UDelegate = self.View.Button_Slot.OnUnhovered,				    Func = Bind(self, self.OnUnhovered) },
        { UDelegate = self.View.WBP_CommonSubscript_Sys.Btn_Delete.OnClicked,				    Func = Bind(self, self.OnCicked) },
        { UDelegate = self.View.WBP_CommonSubscript_Sys.Btn_Switch.OnClicked,				    Func = Bind(self, self.OnCicked) },
        { UDelegate = self.View.WBP_CommonItemIcon.GUIButtonItem.OnClicked,				    Func = Bind(self, self.OnCicked) },
	}
    self.Model = MvcEntry:GetModel(AchievementModel)
    self.Data = nil
    self.InIsSelect = false
end

function AchievementAssembleSlotItem:OnShow(Param)
    if not Param then
        return
    end
    self.Index = Param.Index
    self.SlotClickCallBack = Param.SlotClickCallBack
    self.View.PanelCommonSubscript_Sys:SetVisibility(UE.ESlateVisibility.Collapsed)
    local InitId = self.Model:GetSlotAchieveId(self.Index)
    if InitId and InitId > 0 then
        self:OnAchievementSlotChange({
            Slot = self.Index,
            Id = InitId
        })
    end
end

function AchievementAssembleSlotItem:OnHide()
    self.Data = nil
end
 
function AchievementAssembleSlotItem:OnCicked()
    if self.SlotClickCallBack then
        self.SlotClickCallBack(self.Index, 0, self.Data)
    end
end

function AchievementAssembleSlotItem:OnHovered()
    if self.SlotClickCallBack then
        self.SlotClickCallBack(self.Index, 1, self.Data)
    end
end

function AchievementAssembleSlotItem:SetBtnShow(InCanShow)
    self.View.Button_Slot:SetVisibility(InCanShow and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
end

function AchievementAssembleSlotItem:OnUnhovered()
    self:PlayEffectBySelect(self.InIsSelect)
end

function AchievementAssembleSlotItem:OnAchievementSlotChange(Param)
    if not Param then
        return
    end
    local Slot = Param.Slot
    if Slot ~= self.Index then
        return
    end

    if Param.Id and Param.Id > 0 then
        local Id = Param.Id
        self.Data = self.Model:GetData(Id)
        if not self.Data then
            return
        end
        self:SetActiveWidgetIndex(2)
        local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
            ItemId = Id,
        }
        if self.MoveItemIns then
            self.MoveItemIns:UpdateUI(IconParam)
        else
            self.MoveItemIns = UIHandler.New(self, self.View.WBP_CommonItemIcon, CommonItemIcon, IconParam).ViewInstance
        end

        self:UpdateCornerTag(CornerTagCfg.Delete.TagId)
        -- self.MoveItemIns:UpdateSubScriptScale(0.75)
    elseif Param.OldId then
        self.Data = nil
        self:SetActiveWidgetIndex(0)
    end
end

function AchievementAssembleSlotItem:SetActiveWidgetIndex(Index)
    if Index ~= 2 and self.Data then
        return
    end
    self.View.WidgetSwitcher_Icon:SetActiveWidgetIndex(Index)
    self.View.PanelCommonSubscript_Sys:SetVisibility(Index == 2 and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    self.View.Button_Slot:SetVisibility(Index == 2 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
end

function AchievementAssembleSlotItem:UpdateCornerTag(InTagId)
    if InTagId == CornerTagCfg.Delete.TagId then
        self.View.WBP_CommonSubscript_Sys.WidgetSwitcherState:SetActiveWidgetIndex(0)
    else
        self.View.WBP_CommonSubscript_Sys.WidgetSwitcherState:SetActiveWidgetIndex(1)
    end

    if not self.MoveItemIns then return end
    Timer.InsertTimer(0, function()
        -- local IconRightTagParam = {
        --     TagId = InTagId ~= nil and InTagId or CornerTagCfg.Delete.TagId,
        --     TagPos = CommonConst.CORNER_TAGPOS.Right,
        --     IsUpdate = true
        -- }
        -- self.MoveItemIns:SetCornerTag(IconRightTagParam)
        self.MoveItemIns.View.CornerTag_2:SetVisibility(UE.ESlateVisibility.Collapsed)
    end)
end

function AchievementAssembleSlotItem:PlayEffectBySelect(InIsSelect)
    self.InIsSelect = InIsSelect
    if InIsSelect then
        if self.View.AchievementAssembleSelect then
            self.View:AchievementAssembleSelect()
        end
    else
        if self.View.AchievementAssembleSelectEnd then
            self.View:AchievementAssembleSelectEnd()
        end
    end
end



return AchievementAssembleSlotItem
