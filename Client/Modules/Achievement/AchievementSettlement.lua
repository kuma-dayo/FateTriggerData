local AchievementConst = require("Client.Modules.Achievement.AchievementConst")
local AchievementListItem = require("Client.Modules.Achievement.AchievementListItem")
--- 视图控制器
local class_name = "AchievementSettlement";
local AchievementSettlement = BaseClass(nil, class_name);

---@type AchievementData
AchievementSettlement.Data = nil

function AchievementSettlement:OnInit()
    -- self.MsgList = 
    -- {
	-- 	{Model = AchievementModel, MsgName = ListModel.ON_UPDATED, Func = self.OnAchievementUpdate},
    -- }

    self.BindNodes = 
    {
        {UDelegate = self.View.WBP_ReuseList.OnUpdateItem, Func = Bind(self, self.OnUpdateItem)},
    	-- { UDelegate = self.GUIButton_Back.OnClicked,				    Func = self.GUIButton_Close_ClickFunc },
    }
    self.Model = MvcEntry:GetModel(AchievementModel)
    self.ChangeList = nil
    self.Widget2Item = {}
    self.AchieveIdList = {}
    self.PopNodeData = {}
end

function AchievementSettlement:OnShow()
    self:UpdateSettlementDataState()
end

-- 根据结算数据刷新界面UI
function AchievementSettlement:UpdateSettlementDataState()
    ---@type HallSettlementModel
    local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
    local SettlementDataStateType = HallSettlementModel:GetSettlementDataStateType()
    if SettlementDataStateType == HallSettlementModel.Enum_SettlementDataStateType.Normal then
        self.View.Panel_Loading:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Panel_Main:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:UpdateShow()
    elseif SettlementDataStateType == HallSettlementModel.Enum_SettlementDataStateType.Loading then
        self.View.Panel_Loading:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.Panel_Main:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.View.Panel_Loading:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Panel_Main:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 根据结算数据刷新UI
function AchievementSettlement:UpdateShow()
    local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
    local archiIds = HallSettlementModel:GetTask2AchieveIdList()
    local mapLen = 0
    for k, v in pairs(archiIds) do
        local AchvCfgData = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCfg, v)
        local AchiData = self.Model:GetData(AchvCfgData.MissionID)
        if AchiData then
            mapLen = mapLen + 1
            table.insert(self.AchieveIdList, v)
        end
    end

    self:InitPopNodeList()
    local CompleteCount = mapLen
    self.View.GUIText_Num:SetText(StringUtil.FormatText(CompleteCount))
    self.View.WidgetSwitcher:SetActiveWidgetIndex(CompleteCount < 1 and 1 or 0)
    if CompleteCount > 0 then
        self.View.WBP_ReuseList:Reload(CompleteCount)
    end
end

function AchievementSettlement:InitPopNodeList()
    local AchvCfgData = nil
    local AchiData = nil
    for _, Id in pairs(self.AchieveIdList) do
        AchvCfgData = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCfg, Id)
        if AchvCfgData then
            AchiData = self.Model:GetData(AchvCfgData.MissionID)
            if AchiData then
                table.insert(self.PopNodeData, {
                    Icon  = AchiData:GetIcon(),
                    Tittle = AchiData:GetName(),
                    Desc = AchiData:GetName(),
                    SubDesc = AchiData:GetCurQualityCap(),
                    SubDescHex = AchiData:GetCurQualityColor(),
                })
            end
        end
    end
end

function AchievementSettlement:OnHide()
    self.Widget2Item = {}
    self.ChangeList = nil
end
 

function AchievementSettlement:CreateItem(Widget, Data)
    local Item = self.Widget2Item[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, AchievementListItem)
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function AchievementSettlement:OnUpdateItem(_, Widget, Index)
    local FixIndex = Index + 1

    local AchvCfgData = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCfg, self.AchieveIdList[FixIndex])
    if AchvCfgData then
        local AchiData = self.Model:GetData(AchvCfgData.MissionID)
        if AchiData then
            AchiData.State = AchievementConst.OWN_STATE.Have
            AchiData:UpdateDataFromCfgId(self.AchieveIdList[FixIndex], AchvCfgData.SubID)
            local Data = AchvCfgData.MissionID--self.ChangeList[FixIndex]
            if Data == nil then
                return
            end
            local TargetItem = self:CreateItem(Widget, Data)
            if TargetItem == nil then
                return
            end
            TargetItem:SetData(Data, self.PlayerId)
        end
    end
end

return AchievementSettlement
