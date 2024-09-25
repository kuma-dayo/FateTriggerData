---
--- Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 大厅结算界面
--- Created At: 2023/04/07 16:48
--- Created By: 朝文
---

require("Client.Modules.HallSettlement.HallSettlementModel")
local MatchConst = require("Client.Modules.Match.MatchConst")

local class_name = "HallSettlementMdt"
---@class HallSettlementMdt : GameMediator
HallSettlementMdt = HallSettlementMdt or BaseClass(GameMediator, class_name)
--页签类型
HallSettlementMdt.Enum_TabType = {
    -- 战斗
    Battle = 1,
    -- -- 成长
    -- GrownUp = 2,
    -- 成就
    Achievement = 2
}

function HallSettlementMdt:__init()
end

function HallSettlementMdt:OnShow(data)
end

function HallSettlementMdt:OnHide()

end

-------------------------------------------------------------------------------

---@class HallSettlementMdt_Obj : UserWidgetBase
local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    HallSettlementMdt.Const = HallSettlementMdt.Const or {
        DefaultSelectTab = HallSettlementMdt.Enum_TabType.Battle,
        TabInfo = {
            --大逃杀模式
            [MatchConst.Enum_MatchType.Survive] = {
                [HallSettlementMdt.Enum_TabType.Battle] = {
                    TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_fight_Btn"),
                    IsOpen = true,
                    AttachLua = "Client.Modules.HallSettlement.HallSettlement_BR.HallSettlement_BR_Battle",
                    AttachBp = "/Game/BluePrints/UMG/OutsideGame/Settlement/RP/WBP_Settlement_RP_Battle.WBP_Settlement_RP_Battle",
                },
                -- [HallSettlementMdt.Enum_TabType.GrownUp] = {
                --     TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_growup"),
                --     TabWidgetName = "GrownupTab",
                --     IsOpen = false,
                --     AttachLua = nil,
                --     AttachBp = nil,
                --     IsHide = true
                -- },
                [HallSettlementMdt.Enum_TabType.Achievement] = {
                    TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_achievement_Btn"),
                    IsOpen = true,
                    AttachLua = "Client.Modules.Achievement.AchievementSettlement",
                    AttachBp = "/Game/BluePrints/UMG/OutsideGame/Achievement/WBP_Achievement_Settlement_Content.WBP_Achievement_Settlement_Content",
                }
            },
            --团队竞技模式
            [MatchConst.Enum_MatchType.TeamMatch] = {
                [HallSettlementMdt.Enum_TabType.Battle] = {
                    TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_fight_Btn"),
                    IsOpen = true,
                    AttachLua = "Client.Modules.HallSettlement.HallSettlement_TeamMatch.HallSettlement_TeamMatch_Battle",
                    AttachBp = "/Game/BluePrints/UMG/OutsideGame/Settlement/Team/WBP_Settlement_TeamMatch_Battle.WBP_Settlement_TeamMatch_Battle",
                },
                -- [HallSettlementMdt.Enum_TabType.GrownUp] = {
                --     TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_growup"),
                --     TabWidgetName = "GrownupTab",
                --     IsOpen = false,
                --     IsHide = true
                -- },
                [HallSettlementMdt.Enum_TabType.Achievement] = {
                    TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_achievement_Btn"),
                    IsOpen = true,
                    AttachLua = "Client.Modules.Achievement.AchievementSettlement",
                    AttachBp = "/Game/BluePrints/UMG/OutsideGame/Achievement/WBP_Achievement_Settlement_Content.WBP_Achievement_Settlement_Content",
                }
            },
            --个人死斗模式
            [MatchConst.Enum_MatchType.DeathMatch] = {
                [HallSettlementMdt.Enum_TabType.Battle] = {
                    TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_fight_Btn"),
                    IsOpen = true,
                    AttachLua = "Client.Modules.HallSettlement.HallSettlement_DeathMatch.HallSettlement_DeathMatch_Battle",
                    AttachBp = "/Game/BluePrints/UMG/OutsideGame/Settlement/Solo/WBP_Settlement_Solo_Battle.WBP_Settlement_Solo_Battle",
                },
                -- [HallSettlementMdt.Enum_TabType.GrownUp] = {
                --     TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_growup"),
                --     TabWidgetName = "GrownupTab",
                --     IsOpen = false,
                --     IsHide = true
                -- },
                [HallSettlementMdt.Enum_TabType.Achievement] = {
                    TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_achievement_Btn"),
                    IsOpen = true,
                    AttachLua = "Client.Modules.Achievement.AchievementSettlement",
                    AttachBp = "/Game/BluePrints/UMG/OutsideGame/Achievement/WBP_Achievement_Settlement_Content.WBP_Achievement_Settlement_Content",
                }
            },
            --征服模式
            [MatchConst.Enum_MatchType.Conqure] = {
                [HallSettlementMdt.Enum_TabType.Battle] = {
                    TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_fight_Btn"),
                    IsOpen = true,
                    AttachLua = "Client.Modules.HallSettlement.HallSettlement_Conqure.HallSettlement_Conqure_Battle",
                    AttachBp = "/Game/BluePrints/UMG/OutsideGame/Settlement/Conquest/WBP_Settlement_Conquest_Battle.WBP_Settlement_Conquest_Battle",
                },
                -- [HallSettlementMdt.Enum_TabType.GrownUp] = {
                --     TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_growup"),
                --     TabWidgetName = "GrownupTab",
                --     IsOpen = false,
                -- },
                [HallSettlementMdt.Enum_TabType.Achievement] = {
                    TabName = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_achievement_Btn"),
                    IsOpen = true,
                    AttachLua = "Client.Modules.Achievement.AchievementSettlement",
                    AttachBp = "/Game/BluePrints/UMG/OutsideGame/Achievement/WBP_Achievement_Settlement_Content.WBP_Achievement_Settlement_Content",
                }
            }
        }
    }

    self.PreviousSelectTabIndex = -1
    self.CurrentSelectTabIndex = -1
    -- key为页签ID value为界面组件
    self.ChildPanelList = {}
    -- 最大可同时展示messageItem数量
    self.MaxShowMessageItemNum = 3
    -- 当前信息item提示
    self.CurMessageTipItemIndex = 0
    -- 是否播放消息提示
    self.IsPlayMessageTip = true
    -- 结算数据是否更新 更新的情况 变更页签的时候也要刷新一下对应页签的展示
    self.ChangeDataTabList = {}

    self.MsgList =
    {
        {Model = TeamModel,  MsgName = TeamModel.ON_SELF_JOIN_TEAM,				   Func = self.OnSelfJoinTeam },
        {Model = TeamModel,  MsgName = TeamModel.ON_TEAM_MEMBER_PREPARE,		   Func = self.ON_TEAM_MEMBER_PREPARE_func },
        
        --{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked},
        {Model = HallSettlementModel,  MsgName = HallSettlementModel.ON_SETTLEMENT_PLAYER_ITEM_CLICK_EVENT,		   Func = self.ON_SETTLEMENT_PLAYER_ITEM_CLICK_EVENT_func },
        {Model = HallSettlementModel,  MsgName = HallSettlementModel.ON_MESSAGE_ITEM_ANIMATION_COMPLETE_EVENT,		   Func = self.ON_MESSAGE_ITEM_ANIMATION_COMPLETE_EVENT_func },
        {Model = HallSettlementModel,  MsgName = HallSettlementModel.ON_SETTLEMENT_DATA_STATE_UPDATE_EVENT,		   Func = self.ON_SETTLEMENT_DATA_STATE_UPDATE_EVENT_func },
        {Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,  Func = self.OnOtherViewClosed },
    }

    -- 策划需求不要这个返回按钮了
    self.WBP_CommonBtnTips_Back:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- UIHandler.New(self, self.WBP_CommonBtnTips_Back, WCommonBtnTips,
    --         {
    --             OnItemClick = Bind(self, self.OnButtonClick_QuitTeam),
    --             TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_return_Btn"),
    --             CommonTipsID = CommonConst.CT_ESC,
    --             ActionMappingKey = ActionMappings.Escape,
    --             HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    --         })

    -- 固定显示继续按钮
    self.WBP_CommonBtnTips_Continue:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.CommonBtnTips_Continue = UIHandler.New(self, self.WBP_CommonBtnTips_Continue, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnButtonClick_Continue),
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_continue_Btn"),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    }) 

    ---@type HallSettlement_PersonExp
    self.PersonExpWidget = UIHandler.New(self, self.WBP_PersonExpWidget, "Client.Modules.HallSettlement.HallSettlement_Widgets.HallSettlement_PersonExp").ViewInstance

    self.SeasonPassWidget = UIHandler.New(self, self.WBP_SeasonLevelWidget, require("Client.Modules.Season.Pass.SeasonBpLevelPanelLogic")).ViewInstance

    self.Text_Sys:SetText("")
    self.Text_Sys_1:SetText("")

    -- 页签列表
    self.TabListCls = UIHandler.New(self,self.WBP_Common_TabUp_02,CommonMenuTabUp).ViewInstance

    ---@type UserModel
    self.UserModel = MvcEntry:GetModel(UserModel)

    ---@type HallSettlementModel
    self.HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)

    --消息提示数据列表
    self.MessageTipList = {}
    -- 消息item列表
    self.MessaggItemList = {}
end

--[[
    Param 参考结构
    {
        DefaultSelectTab = 1,   --默认选中的页签，默认为
    }
]]
function M:OnShow(Param)
    self.Param = Param or {}
    self:InitTabListCls()
    self:UpdateSettlementDataState()

    if not self.HallSettlementModel.IsTest then
        MvcEntry:OpenView(ViewConst.TeamAndChat, {
            NeedDisplay = true,
            NeedPlayDisplayAnim = true,
            FromView = self.viewId
        })

        -- 通知界面管理Cache住不能在结算界面打开期间弹出的界面
        MvcEntry:GetCtrl(ViewController):SetNeedCacheViewOpen(ViewController.OPEN_CACHE_SOURCE.WaitForSettlementToHall,true)
    end
    -- 派发事件检测新手引导触发
    MvcEntry:GetModel(GuideModel):DispatchType(GuideModel.CHECK_GUIDE_SHOW_EVENT)
end

-- 如果结算数据属于loading状态 X秒（配置）后转换为失败状态
function M:StartCheckDataFailTimer()
    local SettlementDataStateType = self.HallSettlementModel:GetSettlementDataStateType()
    local DataFailTime = self.HallSettlementModel:GetCheckDataFailTime()
    self:ClearCheckDataFailTimer()
    self.DataFailTimer = self:InsertTimer(DataFailTime, function()
        self.HallSettlementModel:SetSettlementDataStateType(HallSettlementModel.Enum_SettlementDataStateType.GetDataFail)
    end, false)
end

-- 清除定时器
function M:ClearCheckDataFailTimer()
    if self.DataFailTimer then
        self:RemoveTimer(self.DataFailTimer)
    end
    self.DataFailTimer = nil
end

-- 结算数据状态发生变化  需要刷新界面
function M:ON_SETTLEMENT_DATA_STATE_UPDATE_EVENT_func()
    self.ChangeDataTabList = {
        [HallSettlementMdt.Enum_TabType.Battle] = true,
        [HallSettlementMdt.Enum_TabType.Achievement] = true,
    }
    self:UpdateSettlementDataState()
end

-- 根据结算数据刷新界面UI
function M:UpdateSettlementDataState()
    local SettlementDataStateType = self.HallSettlementModel:GetSettlementDataStateType()
    if SettlementDataStateType == HallSettlementModel.Enum_SettlementDataStateType.Loading then
        self.Switcher_Main:SetActiveWidget(self.LoadingPanel)
        self:StartCheckDataFailTimer()
    elseif SettlementDataStateType == HallSettlementModel.Enum_SettlementDataStateType.GetDataFail then
        self.Switcher_Main:SetActiveWidget(self.EmptyPanel)
        -- 更新一下UI
        self:SwitchTabByIndex(self.CurrentSelectTabIndex)
    elseif SettlementDataStateType == HallSettlementModel.Enum_SettlementDataStateType.Normal then
        self.Switcher_Main:SetActiveWidget(self.ContentPanel)
        self:UpdateShow()
        self:ClearCheckDataFailTimer()
        -- 更新一下UI
        self:SwitchTabByIndex(self.CurrentSelectTabIndex)
    end
end

-- 初始化页签组件
function M:InitTabListCls()
    -- 初始化切换tab列表
    local MenuTabParam = {
        TabItemType = CommonMenuTabUp.TabItemTypeEnum.TYPE2,
        ItemInfoList    = {},
        CurSelectId     = self.Param.DefaultSelectTab or HallSettlementMdt.Const.DefaultSelectTab,
        ClickCallBack   = Bind(self, self.SwitchTabByIndex),
        ValidCheck      = Bind(self, self.MenuValidCheck),
        IsOpenKeyboardSwitch = true,
    }

    local CurGameType = self.HallSettlementModel:GetSettlementCacheType()
    local CurGameTypeTabInfo = HallSettlementMdt.Const.TabInfo[CurGameType]
    for i, v in ipairs(CurGameTypeTabInfo) do
        if not v. IsHide then
            table.insert(MenuTabParam.ItemInfoList, {Id = i, LabelStr = v.TabName})
        end 
    end
    self.TabListCls:UpdateUI(MenuTabParam)
end

-- 有结算数据的时候走一下刷新
function M:UpdateShow()
    --2.更新左上角游戏信息
    self:UpdateBattleInfo()
    self:UpdateDisplayBoardAvatarShow()
    self:UpdateCurrencyDisplayShow()
    self:UpdateMessageTipShow()

    --3.同步队伍中的状态信息
    self:_ChangeTeamStatusToGameResult()
    
    --4.显示玩家等级变动
    local lvl, exp = self.HallSettlementModel:GetBeforeLvlExp()
    local GainedExp = self.HallSettlementModel:GetGainedExp()
    self.PersonExpWidget:InitExpDispaly({Level = lvl, Exp = exp})    
    self:InsertTimer(Timer.NEXT_FRAME, function()
        self.PersonExpWidget:AddExp(GainedExp)
    end, false)
    -- 刷新一下通行证数据
    self.SeasonPassWidget:UpdateUI()
end

-----反复打开界面，例如跳转回来时触发的逻辑
--function M:OnRepeatShow(data)
--end

function M:OnHide()
    --1.清空Avatar(提审版本不适用)
    --local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    --HallAvatarMgr:HideAvatarByViewID(ViewConst.HallSettlement)

    --2.清空大厅结算缓存
    self.HallSettlementModel:ClearSettlementData()

    self:ClearCheckDataFailTimer()
end

---这里需要额外同步队伍房间的状态，告知服务器局外打开了结算面板，还属于结算界面。
---与后台沟通，队伍状态与玩家状态属于俩个不同的系统，为了解耦，这里单独处理一下。 
---在结算界面，告诉后台玩家状态为 结算中
function M:_ChangeTeamStatusToGameResult()
    CLog("[cw] M:_ChangeTeamStatusToGameResult()")
    
    --1.非队伍不发送
    local MyPlayerId = self.UserModel:GetPlayerId()
    
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsInTeam = TeamModel:IsInTeam(MyPlayerId)
    if not IsInTeam then
        CLog("[cw] solo, do not need to update room info")
        return
    end

    --2.打开结算面板，发送在结算中的状态
    ---@type TeamCtrl
    local TeamCtrl = MvcEntry:GetCtrl(TeamCtrl)    
    TeamCtrl:ChangeMyTeamMemberStatusToGAME_RESULT()
end

---更新左上角游戏信息
function M:UpdateBattleInfo()
    self.Text_Sys:SetText(self.HallSettlementModel:GetGameMode())
    self.Text_Sys_1:SetText(self.HallSettlementModel:GetMapName())
    
    local MatchType = self.HallSettlementModel:GetSettlementCacheType()
    --大逃杀模式和死斗模式，显示 排名/总队伍数
    if MatchType == MatchConst.Enum_MatchType.Survive or
            MatchType == MatchConst.Enum_MatchType.DeathMatch then      
        local IsWin = self.HallSettlementModel:GetRankNum() == 1
        self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(IsWin and 1 or 2)
        local RankNumber = IsWin and self.RankNumber_1 or self.RankNumber_2
        local All = IsWin and self.All_1 or self.All_2            
        RankNumber:SetText(self.HallSettlementModel:GetRankNum())
        All:SetText(self.HallSettlementModel:GetTotalTeams())
    --征服模式和团竞模式显示 胜利/失败
    elseif MatchType == MatchConst.Enum_MatchType.Conqure or
            MatchType == MatchConst.Enum_MatchType.TeamMatch then
        if self.HallSettlementModel:GetRankNum() == 1 then
            self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(1)
        else
            self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(2)
        end
    end
end

--刷新角色背景板展示
function M:UpdateDisplayBoardAvatarShow()
    local SettlementDataStateType = self.HallSettlementModel:GetSettlementDataStateType()
    if SettlementDataStateType == HallSettlementModel.Enum_SettlementDataStateType.Normal then
        if not self.CurShowAvatar then
            local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
            if HallAvatarMgr == nil then
                return
            end
    
            --适配相机的 Pitch 值
            local Pitch = 0
            ---@type HallCameraMgr
            local HallCameraMgr = CommonUtil.GetHallCameraMgr()
            if HallCameraMgr ~= nil then
                local Rot = HallCameraMgr:GetCurCameraRotator()
                if Rot then
                    -- CLog("SSSSSSSSSSSSSSSSSS Rot = "..table.tostring(Rot))
                    Pitch = Rot.Pitch * (-1)
                end
            end
    
            self.HeroId = self.HallSettlementModel:GetLastMatchPlayerUsedHeroId()
            local direction = self:GetDistanceFromCarmera(self.HeroBoardVar)
            local SpawnParam = {
                ViewID = ViewConst.HallSettlement,
                InstID = 0,
                DisplayBoardID = self.HeroId,
                Location = self.HeroBoardVar,
                Rotation = UE.FRotator(Pitch, 90, 0),
                -- TrackingFocus = true,
                FocusMethodSetting = {
                    FocusMethod = UE.ECameraFocusMethod.Manual,
                    ManualFocusDistance = direction,
                    FocusSettingsStruct = self.FocusSettingsStruct
                },
                Scale = UE.FVector(self.HeroBoardScale, self.HeroBoardScale, self.HeroBoardScale)
            }
    
            self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_DISPLAYBOARD, SpawnParam)
            self.CurShowAvatar:SetDisplayId(self.HeroId)
        end
        local IsHidden = self.CurrentSelectTabIndex ~= HallSettlementMdt.Enum_TabType.Achievement
        self.CurShowAvatar:SetActorHiddenInGame(IsHidden) 
    end
end

-- 更新获得金币展示
function M:UpdateCurrencyDisplayShow()
    self.WBP_CurrencyDisplay_Tips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local TotalGoldNum, AdditiveCardAddGoldNum, ConversionGoldNum = self.HallSettlementModel:GetAddGoldInfo()
    local IsHasAdditiveCard = AdditiveCardAddGoldNum and AdditiveCardAddGoldNum > 0
    self.WBP_CurrencyDisplay_Tips.Panel_AdditiveCard:SetVisibility(IsHasAdditiveCard and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.WBP_CurrencyDisplay_Tips.Text_Total:SetText(StringUtil.Format("{0}", TotalGoldNum))
    self.WBP_CurrencyDisplay_Tips.Text_AdditiveCardNum:SetText(StringUtil.Format("+{0}", AdditiveCardAddGoldNum))
    self.WBP_CurrencyDisplay_Tips.Text_ConversionNum:SetText(StringUtil.Format("{0}", ConversionGoldNum))
end

--- 获取距离相机的距离
function M:GetDistanceFromCarmera(Location)
	local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return nil
	end
	local direction = Location - CameraActor:K2_GetActorLocation()
	direction = UE.UKismetMathLibrary.Normal(direction)
	local targetLocation = CameraActor:K2_GetActorLocation() + direction
	local distance = UE.UKismetMathLibrary.Vector_Distance(Location, targetLocation)
	return distance
end

-- 监听界面关闭事件  需要在loading界面关闭才开始播放消息item
function M:OnOtherViewClosed(ViewId)
    -- 操作菜单界面关闭，隐藏选中图片
    if ViewId == ViewConst.Loading then
        self:UpdateMessageTipShow()
    end
end

--更新右侧消息提示展示
function M:UpdateMessageTipShow()
    local LoadingShowState = MvcEntry:GetModel(ViewModel):GetState(ViewConst.Loading)
    -- 判断一下loading界面是否关闭
    if self.IsPlayMessageTip and not LoadingShowState then
        self.IsPlayMessageTip = false
           -- 默认从4开始
        self.CurMessageTipItemIndex = self.MaxShowMessageItemNum + 1
        self.MessageTipList = self.HallSettlementModel:GetMessageTipList()
        self.MessaggItemList = {}
        -- 前面几个需要加延迟显示
        local DelayTime = 0.1
        -- 只主动添加前3个  因为表现形式不一样
        for Index = 1, self.MaxShowMessageItemNum, 1 do
            local MessageTip = self.MessageTipList[Index]
            if MessageTip then
                local DelayPlayerAnimationTime = Index * DelayTime
                self.MessaggItemList[#self.MessaggItemList + 1] = self:CreateMessageTipShow(MessageTip, Index, DelayPlayerAnimationTime)
            end
        end 
    end
end

-- 收到消息item动画播放完成  检测当前状态
function M:ON_MESSAGE_ITEM_ANIMATION_COMPLETE_EVENT_func()
    local MessageTip = self.MessageTipList[self.CurMessageTipItemIndex]
    if #self.MessaggItemList == self.MaxShowMessageItemNum or not MessageTip then
        local IsAllIdle = true
        local AnimationCompleteIndex = nil
        local AlReadyPlayAnimationOutIndex = nil
        for Index, Value in ipairs(self.MessaggItemList) do
            ---@type HallSettlement_MessageTipItem
            local MessageItem = Value
            if MessageItem:GetIsPlayerAnimation() then
                IsAllIdle = false
                break
            end
            if not AnimationCompleteIndex and MessageItem:GetIsAnimationComplete() then
                AnimationCompleteIndex = Index
            end
            if not AlReadyPlayAnimationOutIndex and MessageItem:GetIsAlReadyPlayAnimationOut() then
                AlReadyPlayAnimationOutIndex = Index
            end
        end
        -- 所有item的动画都播完才执行下一步
        if IsAllIdle then
            if AnimationCompleteIndex then
                ---@type HallSettlement_MessageTipItem
                local AnimationCompleteItem = self.MessaggItemList[AnimationCompleteIndex]
                if AnimationCompleteItem then
                    AnimationCompleteItem:OnClearItem()
                    table.remove(self.MessaggItemList, AnimationCompleteIndex)
                    for Index, Value in ipairs(self.MessaggItemList) do
                        ---@type HallSettlement_MessageTipItem
                        local MessageItem = Value
                        if MessageItem then
                            MessageItem:OnPlayerAnimation() 
                        end
                    end
                end
            elseif AlReadyPlayAnimationOutIndex then
                ---@type HallSettlement_MessageTipItem
                local MessageItem = self.MessaggItemList[AlReadyPlayAnimationOutIndex]
                if MessageItem then
                    MessageItem:OnPlayerAnimation()
                end
            else
                for Index, Value in ipairs(self.MessaggItemList) do
                    ---@type HallSettlement_MessageTipItem
                    local MessageItem = Value
                    if MessageItem then
                        MessageItem:OnPlayerAnimation()
                    end
                end
            end
        end
    elseif MessageTip then
        local IsAllIdle = true
        local AnimationCompleteIndex = nil
        local AlReadyPlayAnimationOutIndex = nil
        for Index, Value in ipairs(self.MessaggItemList) do
            ---@type HallSettlement_MessageTipItem
            local MessageItem = Value
            if MessageItem:GetIsPlayerAnimation() then
                IsAllIdle = false
                break
            end
        end
        if IsAllIdle then
            self.CurMessageTipItemIndex = self.CurMessageTipItemIndex + 1
            local Index = #self.MessaggItemList + 1
            self.MessaggItemList[Index] = self:CreateMessageTipShow(MessageTip, Index) 
        end
    end
end

-- 创建消息item  OnShow后会自动播放动效  播放完会自动删除
function M:CreateMessageTipShow(MessageTip, PositionIndex, DelayPlayerAnimationTime)
    local Param = {
        MessageTip = MessageTip,
        PositionIndex = PositionIndex,
        DelayPlayerAnimationTime = DelayPlayerAnimationTime,
    }
    local WidgetClass = UE.UClass.Load(HallSettlementModel.MessageTipItem.UMGPATH)
    local Widget = NewObject(WidgetClass, self)
    self.Panel_MessageTip:AddChild(Widget)
    local Item = UIHandler.New(self,Widget,require(HallSettlementModel.MessageTipItem.LuaClass)).ViewInstance
    Item:OnShow(Param)   
    return Item
end

---点击触发的页签切换
---@param Index number
function M:SwitchTabByIndex(Index)
    self:OnSelectTab(self.CurrentSelectTabIndex, Index)
end

---用于检查页签是否可用
---@param Index number 页签索引
---@return boolean 页签是否可用
function M:MenuValidCheck(Index)
    CLog("[cw] M:MenuValidCheck(" .. string.format("%s", Index) .. ")")
    local CurGameType = self.HallSettlementModel:GetSettlementCacheType()
    local CurGameTypeTabInfo = HallSettlementMdt.Const.TabInfo[CurGameType]
    if not CurGameTypeTabInfo or not CurGameTypeTabInfo[Index] or not CurGameTypeTabInfo[Index].IsOpen then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_Functionisnotopen"))
        return false
    end
    
    return true
end

---当新页签选中时，会触发这里
---@param OldTabIndex number 旧的页签索引
---@param NewTabIndex number 新的页签索引
function M:OnSelectTab(OldTabIndex, NewTabIndex)
    self.PreviousSelectTabIndex = OldTabIndex    
    self.CurrentSelectTabIndex = NewTabIndex
    
    --1.旧ui卸载
    self:UnloadPanelContent(OldTabIndex)

    --2.新ui挂载
    self:ShowTab(NewTabIndex)

    self:UpdateDisplayBoardAvatarShow()
end

---隐藏挂载的界面蓝图
function M:UnloadPanelContent(OldTabIndex)
    local ChildPanel = self.ChildPanelList[OldTabIndex]
    if ChildPanel then
        ChildPanel.View:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---根据页签索引，挂载新的界面蓝图
---@param TabIndex number 需要处理的页签索引
function M:ShowTab(TabIndex)
    local ChildPanel = self.ChildPanelList[TabIndex]
    -- 是否新增的panel
    local IsAddPanel = false
    if not ChildPanel then
        local CurGameType = self.HallSettlementModel:GetSettlementCacheType()
        local CurGameTypeTabInfo = HallSettlementMdt.Const.TabInfo[CurGameType]
        if not CurGameTypeTabInfo or not CurGameTypeTabInfo[TabIndex] then
            CError("[cw] trying to show a illegal tab with index " .. tostring(TabIndex))
            return 
        end
        
        --没有配置的话证明功能未开放
        local luaPath = CurGameTypeTabInfo[TabIndex].AttachLua
        local bpPath = CurGameTypeTabInfo[TabIndex].AttachBp
        if not luaPath or not bpPath then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_Functionisnotopen"))
            return
        end

        --走到这里就说明有配置，则加载对应的蓝图和lua，进行一个挂载
        local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(bpPath))
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget, self.PanelContent)
        local Param = {
            Teammates = self.HallSettlementModel:GetTeammates(),
            MatchType = self.HallSettlementModel:GetSettlementCacheType(),
        }
        ChildPanel = UIHandler.New(self, Widget, luaPath, Param).ViewInstance 
        self.ChildPanelList[TabIndex] = ChildPanel
        IsAddPanel = true
    end
    ChildPanel.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    -- 结算数据状态变更&非新增panel才需要手动刷新一次
    if self.ChangeDataTabList[TabIndex] then
        self.ChangeDataTabList[TabIndex] = false
        if not IsAddPanel then
            local Param = {
                Teammates = self.HallSettlementModel:GetTeammates(),
                MatchType = self.HallSettlementModel:GetSettlementCacheType(),
            }
            ChildPanel:OnShow(Param)
        end
    end
end

---当队伍信息变动的时候，需要上报当前还在结算状态
---    单人模式下，在结算界面中加入了新的队伍
---    组队情况下，被邀请进入了新的队伍，此时会触发离队再进队，此时监听同一个事件即可。
function M:OnSelfJoinTeam()
    --同步队伍中的状态信息
    self:_ChangeTeamStatusToGameResult()
end

---在界面打开的时候，始终让自己的队伍状态处于结算中
function M:ON_TEAM_MEMBER_PREPARE_func(InMemberInfo)    
    --1.非玩家自己的信息不处理
    local MyPlayerId = self.UserModel:GetPlayerId()
    if InMemberInfo.PlayerId ~= MyPlayerId then return end

    --2.进队之列的操作会的导致自身状态变动，此时需要修改调整状态为结算中
    if InMemberInfo.Status ~= Pb_Enum_TEAM_MEMBER_STATUS.SETTLE then
        --队伍中，数据更新和同步有点问题，后续详细看一下那一块，目前先延迟处理
        self:InsertTimer(0.3, function()
                self:_ChangeTeamStatusToGameResult()
            end)
    end
end

---点击玩家item回调
function M:ON_SETTLEMENT_PLAYER_ITEM_CLICK_EVENT_func(Param)
    if Param.SelectPlayerId then
        local MyPlayerId = self.UserModel:GetPlayerId()
        if MyPlayerId ~= Param.SelectPlayerId and Param.SelectPlayerId then
            local Param = {
                SelectPlayerId = Param.SelectPlayerId,
                PlayerName = Param.PlayerName,
            }
            MvcEntry:OpenView(ViewConst.HallSettlementDetailBtn, Param)
        end
    end
end

--function M:OnEscClicked()
    --目前要求不做处理，先预留
--end

---返回大厅
function M:GoBackToHall()
    --1.播放英雄语音(目前仅大逃杀模式才播放)
    if self.HallSettlementModel:IsGameType_Survive() then
        ---@type HallSettlementCtrl
        local HallSettlementCtrl = MvcEntry:GetCtrl(HallSettlementCtrl)
        HallSettlementCtrl:PlayHeroVoiceBySituation()
    end

    --2.关闭界面    
    if not self.HallSettlementModel.IsTest then
        --MvcEntry:CloseView(ViewConst.TeamAndChat)
        MvcEntry:GetModel(TeamModel):DispatchType(TeamModel.ON_CLOSE_TEAM_AND_CHAT_VIEW_BY_ACTION)
    end
    self:InsertTimer(Timer.NEXT_FRAME, function()
        self:DoClose()
    end)
end


---点击退出按钮，
--- 组队情况下 退出队伍并返回大厅 
--- 单人情况下 返回大厅 
function M:OnButtonClick_QuitTeam()
    -- 新手引导相关 点击就触发关闭界面
    MvcEntry:GetModel(GuideModel):DispatchType(GuideModel.GUIDE_STEP_COMPLETE)

    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local bIsSelfInTeam = TeamModel:IsSelfInTeam()

    --1.组队逻辑
    if bIsSelfInTeam then
        local function Quit()
            --1.发送退队申请
            ---@type TeamCtrl
            local TeamCtrl = MvcEntry:GetCtrl(TeamCtrl)
            TeamCtrl:SendTeamQuitReq()

            --2.播放英雄语音(目前仅大逃杀模式才播放)
            if self.HallSettlementModel:IsGameType_Survive() then
                ---@type HallSettlementCtrl
                local HallSettlementCtrl = MvcEntry:GetCtrl(HallSettlementCtrl)
                HallSettlementCtrl:PlayHeroVoiceBySituation()
            end

            --3.关闭界面
            if not self.HallSettlementModel.IsTest then
                --MvcEntry:CloseView(ViewConst.TeamAndChat)
                TeamModel:DispatchType(TeamModel.ON_CLOSE_TEAM_AND_CHAT_VIEW_BY_ACTION)
            end
            self:InsertTimer(Timer.NEXT_FRAME, function()
                self:DoClose()
            end)
        end

        --这里二次弹窗确认退队
        local msgParam = {
            title = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_Confirmationofquitti"),           --【可选】标题，默认为【提示】
            describe = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_Quitthecurrentteam"), --【必选】描述
            leftBtnInfo = {             --【可选】左按钮信息，无数据则不显示            
            },
            rightBtnInfo = {            --【可选】右铵钮信息，默认是【关闭弹窗】             
                name = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlementMdt_quit"),           --【可选】按钮名称，默认为【确认】
                callback = Quit,        --【可选】按钮回调            
            },
        }
        UIMessageBox.Show(msgParam)

    --2.单人逻辑
    else
        --1.播放英雄语音(目前仅大逃杀模式才播放)
        if self.HallSettlementModel:IsGameType_Survive() then
            ---@type HallSettlementCtrl
            local HallSettlementCtrl = MvcEntry:GetCtrl(HallSettlementCtrl)
            HallSettlementCtrl:PlayHeroVoiceBySituation()
        end

        --2.关闭界面
        if not self.HallSettlementModel.IsTest then
            --MvcEntry:CloseView(ViewConst.TeamAndChat)
            TeamModel:DispatchType(TeamModel.ON_CLOSE_TEAM_AND_CHAT_VIEW_BY_ACTION)
        end
        self:InsertTimer(Timer.NEXT_FRAME, function()
            self:DoClose()
        end)
    end
end

---点击继续按钮，根据不同情况触发不同逻辑
--- 单人情况下 自动开始匹配并返回大厅
--- 组队情况下 
---     队长： 如果其他队员都准备好了，则开始自动匹配，并返回大厅；如果还有其他队友没有准备好，返回大厅，等待其他队友准备好后再开始自动匹配。
---     队员： 准备，并返回大厅
function M:OnButtonClick_Continue()
    -- 新手引导相关 点击就触发关闭界面
    MvcEntry:GetModel(GuideModel):DispatchType(GuideModel.GUIDE_STEP_COMPLETE)

    --1.多人情况下，需要调整队伍状态为准备中；单人无队伍状态，无需调整
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if not TeamModel:IsSelfInTeam() then
        CLog("[cw] HallSettlementMdt Continue, Singleplayer, no need to change state")
    else
        CLog("[cw] HallSettlementMdt Continue, Multiplayer, need to change state to ready")
        ---@type TeamCtrl
        local TeamCtrl = MvcEntry:GetCtrl(TeamCtrl)
        TeamCtrl:ChangeMyTeamMemberStatusToReady()
    end
    
    -- 策划需求：不需要自动匹配的操作了@huangzhong
    -- --自动匹配
    -- ---@type MatchCtrl
    -- local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)
    -- MatchCtrl:AutoMatchReq()

    -- 目前改成监听大厅avatar事件播放
    -- local SettlementDataStateType = self.HallSettlementModel:GetSettlementDataStateType()
    -- if SettlementDataStateType == HallSettlementModel.Enum_SettlementDataStateType.Normal then
    --     --播放英雄语音(目前仅大逃杀模式才播放)
    --     if self.HallSettlementModel:IsGameType_Survive() then
    --         ---@type HallSettlementCtrl
    --         local HallSettlementCtrl = MvcEntry:GetCtrl(HallSettlementCtrl)
    --         HallSettlementCtrl:PlayHeroVoiceBySituation()
    --     end
    -- end

    --关闭界面
    if not self.HallSettlementModel.IsTest then
        --MvcEntry:CloseView(ViewConst.TeamAndChat)
        TeamModel:DispatchType(TeamModel.ON_CLOSE_TEAM_AND_CHAT_VIEW_BY_ACTION)
    end
    self:InsertTimer(Timer.NEXT_FRAME, function()
        self:DoClose()
    end)
end

function M:OnHideAvator()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()

    if HallAvatarMgr == nil then
        return
    end

    HallAvatarMgr:HideAvatarByViewID(ViewConst.HallSettlement)
end

-- 获取继续按钮大小 目前用于新手引导做按钮大小适配
function M:OnGetBtnContinueSize()
    self.WBP_CommonBtnTips_Continue:ForceLayoutPrepass()
    local Size = self.WBP_CommonBtnTips_Continue:GetDesiredSize()
    return Size
end

function M:DoClose()
    self:OnHideAvator()
    MvcEntry:CloseView(ViewConst.HallSettlement)
    -- 重置下测试字段，避免通过gm打开此界面，参数未重置回去
    self.HallSettlementModel.IsTest = false
    --触发一下关闭界面回调
    self.HallSettlementModel:ExecuteHideViewCallback()
end

return M