--[[
    大厅 - 切页 - 赛季
]]

local class_name = "HallTabSeason"
local HallTabSeason = BaseClass(UIHandlerViewBase, class_name)


function HallTabSeason:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true

    self.TabTypeId2Vo = {
        [SeasonConst.TAB_TOPIC] = {
            UnActive = true,
        },
        [SeasonConst.TAB_PASS] = {
            UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Season/WBP_Season_PassPanel.WBP_Season_PassPanel",
            -- UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Season/WBP_Test.WBP_Test",
            LuaClass = require("Client.Modules.Season.Pass.SeasonTabPass"),
            VirtualSceneId = 1100,
        },
        [SeasonConst.TAB_RANK] = {
            UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Season/Season_Rank/WBP_Season_Rank_Panel.WBP_Season_Rank_Panel",
            LuaClass = require("Client.Modules.Season.Rank.SeasonTabRank"),
        },
        [SeasonConst.TAB_LOTTERY] = {
            UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Lottery/Main/WBP_Lottery_Main.WBP_Lottery_Main",
            LuaClass = require("Client.Modules.Season.Lottery.SeasonTabLottery"),
            VirtualSceneId = 800,
        },
    }

    local MenuTabParam = {
        ItemInfoList = {
            --TBT版本暂时屏蔽主题及抽奖页签
            -- {
            --     Id = SeasonConst.TAB_TOPIC,
            --     Widget = self.View.TabTopic,
            --     LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","SeasonTabTopic")
            -- },
            {
                Id = SeasonConst.TAB_PASS,
                Widget = self.View.TabPass,
                LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","SeasonTabPass_Btn"),
                -- 可选 红点前缀
                RedDotKey = "SeasonBp",
                -- 可选 红点后缀
                RedDotSuffix = "",
            },
            -- 策划需求在release上屏蔽排位入口
            -- {
            --     Id = SeasonConst.TAB_RANK,
            --     Widget = self.View.TabRank,
            --     LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","SeasonTabRank")
            -- },
            -- {
            --     Id = SeasonConst.TAB_LOTTERY,
            --     Widget = self.View.TabLottery,
            --     LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","SeasonTabLottery")
            -- },
        },
        CurSelectId = SeasonConst.TAB_PASS,
        ClickCallBack = Bind(self, self.OnMenuBtnClick),
        ValidCheck = Bind(self, self.MenuValidCheck),
        HideInitTrigger = true,
        IsOpenKeyboardSwitch = true
    }

    self.MenuTabListCls = UIHandler.New(self, self.View.WBP_Common_TabUp_03, CommonMenuTabUp, MenuTabParam).ViewInstance
    -- release 临时需求 屏蔽排位 需要连页签一起屏蔽  这块后面要删掉 @huangzhong
    if self.View.WBP_Common_TabUp_03 then
        self.View.WBP_Common_TabUp_03:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

--region AvatarDisplay
-- 外部调用 HallMdt -> WCommonHallTab
function HallTabSeason:OnShowAvator(Param,IsNotVirtualTrigger)
end
function HallTabSeason:OnHideAvator(Param,IsNotVirtualTrigger)
end

function HallTabSeason:UpdateUI(Param)
    
end

--[[
    Param = {
        TabId = 
    }
]]
function HallTabSeason:OnShow(Param,MvcParam)
    self:OnManualShow(Param)
end
function HallTabSeason:OnManualShow(Param)
    self.Param = Param
    self.CurTabId = Param and Param.TabId or SeasonConst.TAB_PASS
    if Param and Param.TabType then
        self.CurTabId = Param.TabType or SeasonConst.TAB_PASS
    end
    self.MenuTabListCls:Switch2MenuTab(self.CurTabId ,true)
    SoundMgr:PlaySound(SoundCfg.Music.MUSIC_SEASON)
end

function HallTabSeason:OnHide()
    -- --将所有下面的分页置为不可见，触发各自逻辑
    -- for TheTabId, TheVo in pairs(self.TabTypeId2Vo) do
    --     local TheShow = false
    --     if not TheShow and TheVo.ViewItem then
    --         TheVo.ViewItem:OnHide()
    --     end
    -- end
end

function HallTabSeason:OnMenuBtnClick(Id, ItemInfo, IsInit)
    self.CurTabId = Id
    self:UpdateTabShow()
    local ViewParam = {
        ViewId = ViewConst.Hall,
        TabId = CommonConst.HL_SEASON .. "-" .. Id
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
end

function HallTabSeason:MenuValidCheck(Id, IsClickTrgger)
    local Vo = self.TabTypeId2Vo[Id]
    if Vo.UnActive and IsClickTrgger then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("104"))
        return false
    end
    return true
end

function HallTabSeason:UpdateTabShow()
    local VoItem = self.TabTypeId2Vo[self.CurTabId]

    if not VoItem then
        CError("HallTabSeason:UpdateTabShow() VoItem nil")
        return
    end

    
    for TheTabId, TheVo in pairs(self.TabTypeId2Vo) do
        local TheShow = false
        if TheTabId == self.CurTabId then
            TheShow = true
        end
        if TheVo.View then
            TheVo.View:SetVisibility(
                TheShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed
            )
        end

        if not TheShow and TheVo.ViewItem then
            TheVo.ViewItem:ManualClose()
        end
    end

    local IsInit = false
    if not VoItem.ViewItem then
        local WidgetClassPath = VoItem.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self.View)
        UIRoot.AddChildToPanel(Widget, self.View.PanelContent)
        local ViewItem = UIHandler.New(self, Widget, VoItem.LuaClass, self.Param).ViewInstance
        VoItem.ViewItem = ViewItem
        VoItem.View = Widget
        IsInit = true
    end

    if not IsInit then
        VoItem.ViewItem:ManualOpen(self.Param)
    end
    if VoItem.VirtualSceneId and VoItem.VirtualSceneId > 0 then
        VoItem.ViewItem:DoSwitchVirtualScene(VoItem.VirtualSceneId)
    end
end


return HallTabSeason
