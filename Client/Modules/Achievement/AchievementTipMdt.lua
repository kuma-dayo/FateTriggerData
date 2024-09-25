local  AchievementConst = require("Client.Modules.Achievement.AchievementConst")
--- 视图控制器
local class_name = "AchievementTipMdt";
AchievementTipMdt = AchievementTipMdt or BaseClass(GameMediator, class_name);

function AchievementTipMdt:__init()
    self:ConfigViewId(ViewConst.AchievementTip)
end

function AchievementTipMdt:OnShow(data)
    
end

function AchievementTipMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

---@type AchievementData
M.Data = nil

function M:OnInit()
    -- self.MsgList = 
    -- {
	-- 	{Model = AchievementModel, MsgName = ListModel.ON_UPDATED, Func = self.OnAchievementUpdate},
    -- }

    self.MsgList = 
	{
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnCloseFunc},
	}

    self.BindNodes = 
    {
		{ UDelegate = self.WBP_CommonPopUp_Bg_L.Button_BGClose.OnClicked,				    Func = Bind(self, self.OnCloseFunc) },
	}

    self.Model = MvcEntry:GetModel(AchievementModel)

    UIHandler.New(self, self.WBP_CommonBtn_Strong_M, WCommonBtnTips,
    {
        OnItemClick = Bind(self,self.OnCloseFunc),
        ActionMappingKey = ActionMappings.SpaceBar,
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Achievement', "Lua_AchievementTipMdt_gotit_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })
    UIHandler.New(self, self.WBP_CommonBtn_Weak_M, WCommonBtnTips,
    {
        OnItemClick = Bind(self,self.OnOpenAssemble),
        ActionMappingKey = ActionMappings.F,
        CommonTipsID = CommonConst.CT_F,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Achievement', "Lua_AchievementTipMdt_Toassemble_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })
end

function M:OnHide()
    
end

function M:OnShow(InParam)
    local InNeedShowBtn = InParam.InNeedShowBtn
    if InNeedShowBtn == nil then InNeedShowBtn = true end
    local PlayerId = self.Model:GetPersonInfoPlayerId()
    local IsSelf = PlayerId == 0 and true or MvcEntry:GetModel(UserModel):IsSelf(PlayerId)
    self.Data = IsSelf and self.Model:GetData(InParam.Id) or self.Model:GetPlayerData(InParam.Id, PlayerId)
    local Data = IsSelf and self.Model:GetItemShowInfo(self.Data, self.Data.Quality == 1 and not self.Data:IsUnlock()) or self.Data
    --local ItemNameAndLevel = Data:GetName() .. Data:GetCurQualityCap()
    self.WBP_CommonPopUp_Bg_L.TextBlock_Title:SetText(Data:GetName())
    --self.GUITextBlock_Level:SetText(Data:GetCurQualityCap())
    local TipDesc = Data:GetDesc()
    self.DescTip:SetVisibility((not TipDesc or #TipDesc < 1) and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    if TipDesc then
        self.GUITextBlock_Desc:SetText(Data:GetDesc())
    end
    self.GUITextBlock_Condi:SetText(StringUtil.Format(Data:GetCondition(), Data:GetCondiNum())) --GetCondiNum

    --模拟测试查看他人成就信息
    --IsSelf = not IsSelf

    local InNeedShowDesc = IsSelf and InNeedShowBtn

    self.StateWidgetSwitcher:SetVisibility(InNeedShowDesc and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    local WidgetIndex = Data.State - 1

    if InNeedShowDesc then
        WidgetIndex = self:GetWidgetSwitcherIndex(Data)
        self.StateWidgetSwitcher:SetActiveWidgetIndex(WidgetIndex)
    end

    local IsHave = WidgetIndex > 0--Data.State == AchievementConst.OWN_STATE.Have
    self.WBP_CommonBtn_Weak_M:SetVisibility((IsHave and InNeedShowDesc) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.WidgetSwitcher:SetActiveWidgetIndex(Data:IsHighQuality() and 1 or 0)
    CommonUtil.SetBrushFromSoftObjectPath(self.AchievementIcon,Data:GetIcon())

    -- CommonUtil.SetImageColorFromHex(self.Qulity_Weak1, self.Model.ItemGetPopNormalColor[Data.Quality].Qua1)

    CommonUtil.SetBrushFromSoftObjectPath(self.Qulity_Weak, Data:GetShowGetPopItemImgByQualityLv(Data.Quality))
    CommonUtil.SetBrushFromSoftObjectPath(self.Qulity_Strong, Data:GetShowGetPopItemImgByQualityLv(Data.Quality))

    self.WBP_CommonPopUp_Bg_L.Image_Icon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonUtil.SetBrushFromSoftObjectPath(self.WBP_CommonPopUp_Bg_L.Image_Icon, Data:GetItemTipQualityImgByQualityLv(Data.Quality))
    --CommonUtil.SetTextColorFromQuality(self.GUITextBlock_Level,Data.Quality)
    --CommonUtil.SetImageColorFromQuality(self.Quality_Light,Data.Quality)
end

--[[
    获取展示的已获取或未获取所对应的WidgetSwitcherIndex
]]
function M:GetWidgetSwitcherIndex(InData)
    local HasMissionIds = G_ConfigHelper:GetMultiItemsByKey(Cfg_AchievementCfg, Cfg_AchievementCfg_P.MissionID, InData.ID)
    local WidgetIndex = InData.State - 1
    if #HasMissionIds > 1 then
        WidgetIndex = 0
        if InData.Quality == #HasMissionIds then
            WidgetIndex = InData.State
            if InData.Count < 1 then
                local task = MvcEntry:GetModel(TaskModel):GetData(InData.TaskId)
                if task then
                    local taskList = task.TargetProcessList
                    if taskList ~= nil and #taskList > 0 then
                        WidgetIndex = taskList[1].ProcessValue < taskList[1].MaxProcess and 0 or 1
                    end
                end 
            end
        end 
    end
    return WidgetIndex
end

function M:OnCloseFunc()
    MvcEntry:CloseView(ViewConst.AchievementTip)
end

function M:OnOpenAssemble()
    self:OnCloseFunc()
    MvcEntry:OpenView(ViewConst.AchievementAssemble)
end

return M
