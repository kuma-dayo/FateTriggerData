--[[
    角色详情界面
]] local class_name = "HeroDetailPanelMdt"

HeroDetailPanelMdt = HeroDetailPanelMdt or BaseClass(GameMediator, class_name)

--[[

    Tab分页类型

]]
HeroDetailPanelMdt.MenTabKeyEnum = {
    -- 技能详情
    Skill = 1,
    -- 皮肤详情
    Skin = 2,
    -- 数据
    Talent = 3,
    -- 展示板
    DisplayBoard = 4
}

--[[

    展示模式

]]
HeroDetailPanelMdt.ShowTypeEnum = {
    -- 普通

    NORMAL = 1,
    -- 详情

    DETAIL = 2
}

function HeroDetailPanelMdt:__init()
end

function HeroDetailPanelMdt:OnShow(data)
end

function HeroDetailPanelMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    -- -- 开启InputFocus避免隐藏Tab页时仍监听输入
    -- self.InputFocus = true

    self.TabTypeId2Vo = {
        [HeroDetailPanelMdt.MenTabKeyEnum.Skill] = {
            UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Hero/WBP_HeroSkillDetailLayer.WBP_HeroSkillDetailLayer",
            LuaClass = require("Client.Modules.Hero.HeroDetail.HeroSkillDetailLogic"),
            IdleLoopAnimClipKey = HeroModel.LSEventTypeEnum.IdleHeroTabDetail,
            ViewAllHide = true,
            ShowHeroDesc = true
        },
        [HeroDetailPanelMdt.MenTabKeyEnum.Skin] = {
            UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Hero/WBP_HeroSuitDetailLayer.WBP_HeroSuitDetailLayer",
            LuaClass = require("Client.Modules.Hero.HeroDetail.HeroSkinDetailLogic"),
            IdleLoopAnimClipKey = HeroModel.LSEventTypeEnum.IdleHeroTabSkin,
            ShowHeroDesc = true
        },
        [HeroDetailPanelMdt.MenTabKeyEnum.Talent] = {
            UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Hero/WBP_HeroDataLayer.WBP_HeroDataLayer",
            LuaClass = require("Client.Modules.Hero.HeroDetail.HeroRecordDataLogic"),
            IdleLoopAnimClipKey = HeroModel.LSEventTypeEnum.IdleHeroTabRune,
            ViewAllHide = true,
            ShowHeroDesc = true
        },
        [HeroDetailPanelMdt.MenTabKeyEnum.DisplayBoard] = {
            UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Hero/DisplayBoard/WBP_HeroDisplayBoard.WBP_HeroDisplayBoard",
            LuaClass = require("Client.Modules.Hero.HeroDetail.HeroDisplayBoardDetailLogic"),
            IdleLoopAnimClipKey = HeroModel.LSEventTypeEnum.IdleHeroTabDisplayBoard,
            ViewAllHide = true,
            ShowHeroDesc = false
        },
    }

    self.NeedLSKey2PropertyKey = {
        ["1_Default"] = HeroModel.LSEventTypeEnum.LSPathHeroMain2TabDetail,
        ["2_Default"] = HeroModel.LSEventTypeEnum.LSPathTabDetail2Skin,
        ["3_Default"] = HeroModel.LSEventTypeEnum.LSPathTabSkin2Rune,
        ["4_Default"] = HeroModel.LSEventTypeEnum.LSPathTabSkin2Rune,
        ["0_1"] = HeroModel.LSEventTypeEnum.LSPathHeroMain2TabDetail,
        ["0_2"] = HeroModel.LSEventTypeEnum.LSPathHeroMain2TabSkin,
        ["0_3"] = HeroModel.LSEventTypeEnum.LSPathHeroMain2TabRune,
        ["0_4"] = HeroModel.LSEventTypeEnum.LSPathHeroMain2TabRune,
        ["1_2"] = HeroModel.LSEventTypeEnum.LSPathTabDetail2Skin,
        ["1_3"] = HeroModel.LSEventTypeEnum.LSPathTabDetail2Rune,
        ["1_4"] = HeroModel.LSEventTypeEnum.LSPathTabDetail2Rune,
        ["2_1"] = HeroModel.LSEventTypeEnum.LSPathTabSkin2Detail,
        ["2_3"] = HeroModel.LSEventTypeEnum.LSPathTabSkin2Rune,
        ["2_4"] = HeroModel.LSEventTypeEnum.LSPathTabSkin2Rune,
        ["3_1"] = HeroModel.LSEventTypeEnum.LSPathTabRune2Detail,
        ["3_2"] = HeroModel.LSEventTypeEnum.LSPathTabRune2Skin,
        ["3_4"] = HeroModel.LSEventTypeEnum.LSPathTabRune2Skin,
        ["4_1"] = HeroModel.LSEventTypeEnum.LSPathHeroMain2TabDetail,
        ["4_2"] = HeroModel.LSEventTypeEnum.LSPathHeroMain2TabSkin,
        ["4_3"] = HeroModel.LSEventTypeEnum.LSPathHeroMain2TabRune,
        [StringUtil.FormatSimple("{0}_{1}", ViewConst.HeroPreView, HeroDetailPanelMdt.MenTabKeyEnum.Skill)] = HeroModel.LSEventTypeEnum.LSPathHeroPreview2Detail,
        [StringUtil.FormatSimple("{0}_{1}", ViewConst.HeroPreView, HeroDetailPanelMdt.MenTabKeyEnum.Skin)] = HeroModel.LSEventTypeEnum.LSPathHeroPreview2Skin
    }

    self.SequenceTag = tostring(ViewConst.HeroDetail)

    self.CommonTabUpBarInstance = UIHandler.New(self,self.WBP_Common_TabUpBar_02,CommonTabUpBar).ViewInstance

    -- self.MenuTabListCls = UIHandler.New(self, self.MenuTabList, CommonMenuTab, MenuTabParam).ViewInstance

    self.MsgList = {
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked },
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Tab), Func = self.OnViewAllClicked },
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.SpaceBar), Func = self.OnLikeClicked },
        -- {Model = HeroModel, MsgName = HeroModel.TRIGGER_HERO_SKIN_SHOW_CHANGE, Func = self.TRIGGER_HERO_SKIN_SHOW_CHANGE },
        { Model = HeroModel,  MsgName = HeroModel.ON_PLAYER_LIKE_HERO_CHANGE,  Func = self.ON_PLAYER_LIKE_HERO_CHANGE },
        {  Model = ViewModel,   MsgName = ViewConst.HeroPreView,   Func = Bind(self, self.HeroPreViewState) },
        { Model = HeroModel,  MsgName = HeroModel.HERO_QUICK_TAB_HERO_SELECT, Func = self.HERO_QUICK_TAB_HERO_SELECT },
    }

    UIHandler.New(
        self,
        self.CommonBtnTipsESC,
        WCommonBtnTips,
        {
            OnItemClick = Bind(self, self.OnEscClicked),
            CommonTipsID = CommonConst.CT_ESC,
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
            ActionMappingKey = ActionMappings.Escape
        }
    )

    UIHandler.New(
        self,
        self.CommonBtnTipsViewAll,
        WCommonBtnTips,
        {
            OnItemClick = Bind(self, self.OnViewAllClicked),
            CommonTipsID = CommonConst.CT_LShift,
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroDetailPanelMdt_Rolepreview_Btn"),
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
            ActionMappingKey = ActionMappings.LShift
        }
    )

    UIHandler.New(
        self,
        self.CommonBtnTipsLike,
        WCommonBtnTips,
        {
            OnItemClick = Bind(self, self.OnLikeClicked),
            CommonTipsID = CommonConst.CT_SPACE,
            ActionMappingKey = ActionMappings.SpaceBar,
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second
        }
    )

    self.QuickTabInst = UIHandler.New(self, self.WBP_Hero_QuickTab_List, require("Client.Modules.Hero.HeroQuickTabLogic")).ViewInstance

    -- self:InitCurrency()

    -- 皮肤红点

    ---@type CommonRedDot

    -- todo tab结构替换，带后续调整
    -- self.SkinRedDot =
    --     UIHandler.New(
    --     self,
    --     self.WBP_RedDotFactory,
    --     CommonRedDot,
    --     {
    --         RedDotKey = "TabHeroSkin_",
    --         RedDotSuffix = ""
    --     }
    -- ).ViewInstance

    self.IsCloseFromPreviewView = false
end

function M:HeroPreViewState(_,State)
    if not State then
        self.IsCloseFromPreviewView = true
    end
end

-- 初始化货币控制

function M:InitCurrency()
    local Param = {
        -- 道具图标
        ItemId = DepotConst.ITEM_ID_GOLDEN,
        -- Icon控件
        IconWidget = self.GUIImage_Gold,
        -- 文本控件（显示数量）
        LabelWidget = self.LbCurrencyGold
    }

    UIHandler.New(self, self.HorizontalBox_Gold, CommonCurrencyTip, Param)

    local Param1 = {
        -- 道具图标
        ItemId = DepotConst.ITEM_ID_DIAMOND,
        -- Icon控件
        IconWidget = self.GUIImage_Diamond,
        -- 文本控件（显示数量）
        LabelWidget = self.LbCurrencyDiamond
    }

    UIHandler.New(self, self.HorizontalBox_Diamond, CommonCurrencyTip, Param1)
end

--[[

    Param = {

        HeroId,

    }

]]
function M:OnShow(Param)
    self.Param = Param
    self.LastTabId = 0
    self.CurTabId = HeroDetailPanelMdt.MenTabKeyEnum.Skill
    self.CurShowType = HeroDetailPanelMdt.ShowTypeEnum.NORMAL
    self.HeroId = Param.HeroId
    -- todo tab结构替换，带后续调整
    -- self.SkinRedDot:ChangeKey("TabHeroSkin_", self.HeroId)
    self:InitTabInfo()
    self:UpdateHeroCommonShow()
    self:UpdateTabShow()
    if self.QuickTabInst then
        ---@type HeroQuickTabLogicParam
        local Param = {
            HeroId = self.HeroId,
        }
        self.QuickTabInst:UpdateUI(Param)
    end
end

function M:InitTabInfo()
    local MenuTabParam = {
        ItemInfoList = {
            {
                Id = HeroDetailPanelMdt.MenTabKeyEnum.Skill,
                Widget = self.SkillDetail,
                LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroDetailPanelMdt_details_Btn")
            },
            {
                Id = HeroDetailPanelMdt.MenTabKeyEnum.Skin,
                Widget = self.SuitDetail,
                LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroDetailPanelMdt_skin_Btn"),
                RedDotKey = "TabHeroSkin_",
                RedDotSuffix = self.HeroId,
            },
            {
                Id = HeroDetailPanelMdt.MenTabKeyEnum.Talent,
                Widget = self.RuneDetail,
                LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_RoleRecord_Tittle_Btn"),
            },
            {
                Id = HeroDetailPanelMdt.MenTabKeyEnum.DisplayBoard,
                Widget = self.DisplayBoardDetail,
                LabelStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroDetailPanelMdt_Displayboard_Btn"),
                RedDotKey = "HeroDisplayBoard_",
                RedDotSuffix = self.HeroId,
            }
        },
        CurSelectId = HeroDetailPanelMdt.MenTabKeyEnum.Skill,
        ClickCallBack = Bind(self, self.OnMenuBtnClick),
        ValidCheck = Bind(self, self.MenuValidCheck),
        HideInitTrigger = true,
        IsOpenKeyboardSwitch = true,
        TabItemType = CommonMenuTabUp.TabItemTypeEnum.TYPE2
    }
    local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Hero","1562"),
        CurrencyIDs = {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND},
        TabParam = MenuTabParam
    }

    self.CommonTabUpBarInstance:OnShow(CommonTabUpBarParam)
end

function M:OnHide()
end

function M:OnShowAvator(Param, IsInit)
    -- local VoItem = self.TabTypeId2Vo[self.CurTabId]

    -- if not VoItem then
    --     return
    -- end

    -- if not IsInit then
    --     if VoItem.ViewItem.OnShowAvator then
    --         VoItem.ViewItem:OnShowAvator(Param, IsInit)
    --     end
    -- end
end

--[[

    通过切换动作Key，获取需要进行执行的LS路径

]]
function M:GetLSPathByNeedLSKey(LastTabId, CurTabId, SkinId)

    local NeedLSKey = StringUtil.FormatSimple("{0}_{1}", LastTabId, CurTabId)
    if self.IsCloseFromPreviewView then
        NeedLSKey = StringUtil.FormatSimple("{0}_{1}", ViewConst.HeroPreView, CurTabId)
        self.IsCloseFromPreviewView = false
    end

    local LSPath = nil

    local IsEnablePostProcess = false

   
    local PropertyKey = self.NeedLSKey2PropertyKey[NeedLSKey]

    if PropertyKey then
        LSPath, IsEnablePostProcess = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(SkinId, PropertyKey)

        if not LSPath then
            local NeedLSKeyFix = StringUtil.FormatSimple("{0}_Default", CurTabId)

            local PropertyKeyFix = self.NeedLSKey2PropertyKey[NeedLSKeyFix]

            if PropertyKeyFix then
                LSPath = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(SkinId, PropertyKeyFix)

                if LSPath then
                    CWaring(
                        "HeroDetailPanelMdt:UpdateAvatarShow LSPath not found:" ..
                            NeedLSKey .. " Use Fix Path:" .. LSPath
                    )
                end
            end
        end
    end

    return LSPath, IsEnablePostProcess
end

function M:GetAnimClipPathByTabId(TabId, SkinId)
    local AnimClipPath = nil

    local VoItem = self.TabTypeId2Vo[TabId]

    if VoItem and VoItem.IdleLoopAnimClipKey then
        AnimClipPath = MvcEntry:GetModel(HeroModel):GetAnimClipPathBySkinIdAndKey(SkinId, VoItem.IdleLoopAnimClipKey)
    end

    return AnimClipPath
end

function M:UpdateAvatarShow(HeroId, SkinId, NeedLs, CustomPartList, IsSkinSwitch, IsQuickSwitch)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()

    if HallAvatarMgr == nil then
        return
    end

    MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(self.SequenceTag)

    HallAvatarMgr:ShowAvatarByViewID(ViewConst.HeroDetail, false)

    if not HeroId or not SkinId then
        return
    end

    local SpawnHeroParam = {
        ViewID = ViewConst.HeroDetail,
        InstID = 0,
        HeroId = HeroId,
        SkinID = SkinId,
        Location = UE.FVector(20000, 0, 0),
        Rotation = UE.FRotator(0, 0, 0),
        CustomPartList = CustomPartList,
        IsAnimBlend = true,
        PlayShowLS = IsSkinSwitch or IsQuickSwitch,
        ShowLSNeedWaitCharaterPrepared = false
    }

    self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    self.CurShowAvatar:OpenOrCloseCameraAction(false)
    self.CurShowAvatar:OpenOrCloseAvatorRotate(false)

    -- 此AnimClip取值
    self.CurShowAvatar:PlayAnimClip(self:GetAnimClipPathByTabId(self.CurTabId, SkinId), true)

    self:PlayCharaterLS(SkinId, IsSkinSwitch or IsQuickSwitch)
end

function M:PlayCharaterLS(SkinId, GoToEnd)

    local NeedLs = true
    if NeedLs then
        local LSPath, IsEnablePostProcess = self:GetLSPathByNeedLSKey(self.LastTabId, self.CurTabId, SkinId)

        if not LSPath then
            return
        end

        local HallActorAvatar = self.CurShowAvatar:GetSkinActor()

        local SetBindings = {
            {
                ActorTag = "", -- 如场景中静态放置的可用tag搜索出Actor
                Actor = HallActorAvatar, -- 需要在播动画前生成Actor(且直接具有SkeletaMesh组件)
                TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM
            }
        }

        local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
        if CameraActor ~= nil then
            local CameraBinding = {
                ActorTag = "",
                Actor = CameraActor,
                TargetTag = SequenceModel.BindTagEnum.CAMERA
            }

            table.insert(SetBindings, CameraBinding)
        end

        local PlayParam = {
            LevelSequenceAsset = LSPath,
            SetBindings = SetBindings,
            TransformOrigin = self.CurShowAvatar:GetTransform(),
            NeedStopAllSequence = not GoToEnd,
            IsEnablePostProcess = IsEnablePostProcess,
            UseCacheSequenceActorByTag = true,
            RestoreState = false,
            GoToEnd = GoToEnd
        }

        MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(
            self.SequenceTag,
            function()
                CWaring("HeroMdt:PlaySequenceByTag Suc")
            end,
            PlayParam
        )

        if self.CharaterShowItemFixTimer then
            Timer.RemoveTimer(self.CharaterShowItemFixTimer)
            self.CharaterShowItemFixTimer = nil
        end

        if GoToEnd then
            local Actors = HallActorAvatar:GetAttachedActors()
            for _, TActor in pairs(Actors) do
                TActor:SetActorHiddenInGame(true)
            end
            self.CharaterShowItemFixTimer = Timer.InsertTimer(0.3,function()
                for _, TActor in pairs(Actors) do
                    TActor:SetActorHiddenInGame(false)
                end
            end)
        end
    end
end

function M:OnHideAvator()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end

    HallAvatarMgr:HideAvatarByViewID(ViewConst.HeroDetail)
end

function M:UpdateHeroCommonShow()
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, self.HeroId)

    -- TODO 更新英雄名称及描述
    self.WBP_HeroNameAndDetailItem.HeroName:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.Name]))
    self.WBP_HeroNameAndDetailItem.HeroName_1:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.RealName]))
    self.WBP_HeroNameAndDetailItem.HeroDetail:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.HeroDescription]))
end

--[[

    更新当前Tab页展示

]]
function M:UpdateTabShow()
    local VoItem = self.TabTypeId2Vo[self.CurTabId]

    if not VoItem then
        CError("HeroDetailPanelMdt:UpdateTabShow() VoItem nil")

        return
    end
    local PosX = self.WBP_Hero_QuickTab_List.Slot:GetPosition().X
    local PosY = self.CurTabId ~= HeroDetailPanelMdt.MenTabKeyEnum.DisplayBoard and 467 or 179
    self.WBP_Hero_QuickTab_List.Slot:SetPosition(UE.FVector2D(PosX,PosY))
    self.WBP_HeroNameAndDetailItem:SetVisibility(VoItem.ShowHeroDesc and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    self.SequenceTag = StringUtil.FormatSimple("HeroDetailPanel_{0}",self.CurTabId)
    local Param = {
        HeroId = self.HeroId
    }
    local IsInit = false
    if not VoItem.ViewItem then
        local WidgetClassPath = VoItem.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget, self.PanelContent)
        local ViewItem = UIHandler.New(self, Widget, VoItem.LuaClass,Param).ViewInstance
        VoItem.ViewItem = ViewItem
        VoItem.View = Widget

        IsInit = true
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

    self.CommonBtnTipsViewAll:SetVisibility(
        VoItem.ViewAllHide and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible
    )
    if not IsInit then
        VoItem.ViewItem:ManualOpen(Param)
    end
    self:UpdateCommonBtnTipsShow()
end

function M:UpdateCommonBtnTipsShow()
    self.WidgetSwitcherLike:SetVisibility(
        (self.CurTabId == HeroDetailPanelMdt.MenTabKeyEnum.Skill and UE.ESlateVisibility.SelfHitTestInvisible or
            UE.ESlateVisibility.Collapsed)
    )

    if self.CurTabId == HeroDetailPanelMdt.MenTabKeyEnum.Skill then
        if self.HeroId == MvcEntry:GetModel(HeroModel):GetFavoriteId() then
            self.WidgetSwitcherLike:SetActiveWidget(self.AlreadyLike)
        else
            self.WidgetSwitcherLike:SetActiveWidget(self.CommonBtnTipsLike)
        end
    end
end

function M:OnMenuBtnClick(Id, ItemInfo, IsInit)
    if self.CurTabId ~= Id then
        self.LastTabId = self.CurTabId
    end

    self.CurTabId = Id
    self:UpdateTabShow()
    -- todo tab结构替换，带后续调整
    -- if Id == HeroDetailPanelMdt.MenTabKeyEnum.Skin then
    --     self.SkinRedDot:Interact()
    -- end
end

function M:MenuValidCheck(Id)
    return true
end

--[[

    关闭自身

]]
function M:OnEscClicked()
    if self.Param.CloseCallBack then
        self.Param.CloseCallBack(self.CurTabId)
    end

    MvcEntry:CloseView(self.viewId)

    return true
end

--[[

    打开展示预览界面

]]
function M:OnViewAllClicked()
    local VoItem = self.TabTypeId2Vo[self.CurTabId]

    if VoItem.ViewItem.OnViewAllClicked then
        VoItem.ViewItem:OnViewAllClicked()
    end
    return true
end

-- function M:TRIGGER_HERO_SKIN_SHOW_CHANGE(SkinId)

--     self:UpdateAvatarShow(self.HeroId,SkinId)

-- end

function M:OnLikeClicked()
    if self.CurTabId ~= HeroDetailPanelMdt.MenTabKeyEnum.Skill then
        return
    end

    if self.HeroId == MvcEntry:GetModel(HeroModel):GetFavoriteId() then
        return
    end
    MvcEntry:GetCtrl(HeroCtrl):SendProto_SelectHeroReq(self.HeroId)
end

--[[

    玩家装备英雄产生变化

]]
function M:ON_PLAYER_LIKE_HERO_CHANGE()
    self:UpdateCommonBtnTipsShow()
end

--快速切换英雄详情事件
function M:HERO_QUICK_TAB_HERO_SELECT(Param)
    if not Param or not Param.HeroId then
        return
    end
    self.HeroId = Param.HeroId
    self:InitTabInfo()
    local VoItem = self.TabTypeId2Vo[self.CurTabId]
    if not VoItem then
        CError("HeroDetailPanelMdt:HERO_QUICK_TAB_HERO_SELECT() VoItem nil")
        return
    end
    self:UpdateHeroCommonShow()
    local Param = {
        HeroId = self.HeroId
    }
    if VoItem.ViewItem.UpdateUI then
        VoItem.ViewItem:UpdateUI(Param)
    end
    if VoItem.ViewItem.OnShowAvator then
        VoItem.ViewItem:OnShowAvator(Param, true, false, true)
    end
    self:UpdateCommonBtnTipsShow()
end

return M
