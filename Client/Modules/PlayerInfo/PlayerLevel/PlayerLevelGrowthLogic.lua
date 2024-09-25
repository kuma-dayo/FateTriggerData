--[[
   等级历程界面逻辑
]] 
local class_name = "PlayerLevelGrowthLogic"
local PlayerLevelGrowthLogic = BaseClass(UIHandlerViewBase, class_name)

function PlayerLevelGrowthLogic:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.View.WBP_ReuseList_FinalReward.OnUpdateItem,		Func = Bind(self,self.OnUpdateFinalRewardItem) },
        { UDelegate = self.View.WBP_List_Progress.OnUpdateItem,		Func = Bind(self,self.OnUpdateLevelGrowthItem) },
	}
    self.MsgList = {
        {Model = PlayerLevelGrowthModel, MsgName = PlayerLevelGrowthModel.ON_PLAYER_LEVEL_GROWTH_DATA_UPDATE_EVENT,	Func = Bind(self,self.UpdateUI) },
        {Model = PlayerLevelGrowthModel, MsgName = PlayerLevelGrowthModel.ON_PLAYER_LEVEL_GROWTH_REWARD_DATA_UPDATE_EVENT,	Func = Bind(self,self.UpdateLevelGrowthItemShow) },
	}

    ---@type UserModel
    self.UserModel = MvcEntry:GetModel(UserModel)
    
    ---@type PlayerLevelGrowthCtrl
    self.PlayerLevelGrowthCtrl = MvcEntry:GetCtrl(PlayerLevelGrowthCtrl)
    ---@type PlayerLevelGrowthModel
    self.PlayerLevelGrowthModel = MvcEntry:GetModel(PlayerLevelGrowthModel)

    -- 最终奖励列表
    self.FinalRewardIconList = {}
    -- 最终奖励item复用列表
    self.FinalRewardItemList = {}

    ---@type LevelGrowthInfo 最终奖励列表
    self.LevelGrowthInfoList = {}
    -- 最终奖励item复用列表
    self.LevelGrowthItemList = {}
end

function PlayerLevelGrowthLogic:OnShow()
    self:SendPlayerLevelGrowthReq()
end

function PlayerLevelGrowthLogic:OnHide()

end

-- 每次打开界面请求一次数据
function PlayerLevelGrowthLogic:SendPlayerLevelGrowthReq()
    self.PlayerLevelGrowthCtrl:SendProtoPlayerLevelReq()
end

-- 刷新UI
function PlayerLevelGrowthLogic:UpdateUI()
    self:UpdateLevelShow()
    self:UpdateFinalRewardShow()
    self:UpdateLevelGrowthItemShow()
end

-- 更新等级展示
function PlayerLevelGrowthLogic:UpdateLevelShow()
    local CurLevel, CurExperience = self.UserModel:GetPlayerLvAndExp()
    local MaxExperience = self.UserModel:GetPlayerMaxExpForLv(CurLevel)
    local IsMaxLevel = self.UserModel:CheckIsMaxLevel()
    self.View.WidgetSwitcher_Level:SetActiveWidget(IsMaxLevel and self.View.Panel_High or self.View.Panel_Low)
    self.View.Text_Level:SetText(CurLevel)
    self.View.Text_Progress:SetText(StringUtil.FormatSimple("{0}/<span color=\"#F5EFDF80\" size=\"19\">{1}</>", CurExperience, MaxExperience))

    local Progress = MaxExperience > 0 and CurExperience/MaxExperience or 0
    self.View.Image_RankProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", StringUtil.FormatFloat(Progress)) 
end

-- 更新最终奖励展示
function PlayerLevelGrowthLogic:UpdateFinalRewardShow()
    local PlayerLevelFinalRewardConfig = self.PlayerLevelGrowthModel:GetPlayerLevelFinalRewardConfig()
    if PlayerLevelFinalRewardConfig then
        local Desc = PlayerLevelFinalRewardConfig[Cfg_PlayerLevelFinalRewardConfig_P.Desc]
        local Level = PlayerLevelFinalRewardConfig[Cfg_PlayerLevelFinalRewardConfig_P.FinalLevel]
        local LevelDesc = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "Level")
        self.View.Text_AwardName:SetText(StringUtil.Format(Desc))
        self.View.Text_AwardLevel:SetText(StringUtil.Format(LevelDesc, Level))

        self.FinalRewardIconList = {}
        local iconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = PlayerLevelFinalRewardConfig[Cfg_PlayerLevelFinalRewardConfig_P.ShowItemId],
            ItemNum = PlayerLevelFinalRewardConfig[Cfg_PlayerLevelFinalRewardConfig_P.ShowItemNum],
            HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        }
        self.FinalRewardIconList[#self.FinalRewardIconList + 1] = iconParam
        self.View.WBP_ReuseList_FinalReward:Reload(#self.FinalRewardIconList);
    end
end

function PlayerLevelGrowthLogic:OnUpdateFinalRewardItem(Handler,Widget, Index)
	local FixIndex = Index + 1

	local TargetItem = self:CreateRewardIconItem(Widget)
	if TargetItem == nil then
		return
	end
    local param = self.FinalRewardIconList[FixIndex]
    if param then
        TargetItem:UpdateUI(param)
    end
end

function PlayerLevelGrowthLogic:CreateRewardIconItem(Widget)
    local Item = self.FinalRewardItemList[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, CommonItemIcon)
        self.FinalRewardItemList[Widget] = Item
    end
    return Item.ViewInstance
end

-- 更新等级成长item展示
function PlayerLevelGrowthLogic:UpdateLevelGrowthItemShow()
    local CurLevel = self.UserModel:GetPlayerLvAndExp()
    local JumpId = CurLevel
    self.LevelGrowthInfoList = self.PlayerLevelGrowthModel:GetLevelGrowthInfoList()
    self.View.WBP_List_Progress:Reload(#self.LevelGrowthInfoList)
    self.View.WBP_List_Progress:JumpByIdx(JumpId)
end

function PlayerLevelGrowthLogic:OnUpdateLevelGrowthItem(Handler,Widget, Index)
    local FixIndex = Index + 1

	local TargetItem = self:CreateLevelGrowthItem(Widget)
	if TargetItem == nil then
		return
	end
    local param = self.LevelGrowthInfoList[FixIndex]
    if param then
        TargetItem:UpdateUI(param)
    end
end

function PlayerLevelGrowthLogic:CreateLevelGrowthItem(Widget)
    local Item = self.LevelGrowthItemList[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.PlayerInfo.PlayerLevel.PlayerLevelGrowthItemLogic"))
        self.LevelGrowthItemList[Widget] = Item
    end
    return Item.ViewInstance
end

return PlayerLevelGrowthLogic
