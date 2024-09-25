--[[
    大厅 - 切页 - 英雄
]]
local class_name = "HallTabHero"
local HallTabHero = BaseClass(UIHandlerViewBase, class_name)
HallTabHero.Const = {    
    DefaultAvatarShowLocation = UE.FVector(20000, 0, 0),                              --默认3D角色模型展示的位置参数
    DefaultAvatarShowRotation = UE.FRotator(0, 0,0),                                 --默认3D角色模型展示的旋转参数
}

function HallTabHero:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.CurrentSelectedHeroID = nil                --当前选中的英雄ID
    self.Id2SkillWidgetList = {}                    --id对应的技能 widget列表

    self.SequenceTag = StringUtil.Format("{0}_{1}",ViewConst.Hall,CommonConst.HL_HERO)

    --2.先隐藏所有英雄列表中的控件，以防数据太少，填满不了对应的控件，展示有问题
    --TODO: 等待数据确认后可能还需要再确认以下这里的逻辑 by bailixi
    self:ShowAllHero()

    --1.监听键盘按键
    self.MsgList =
    {
        {Model = HeroModel,  MsgName = HeroModel.ON_NEW_HERO_UNLOCKED,	           Func = Bind(self, self.OnNewHeroUnlocked) },        
        {Model = HeroModel,  MsgName = HeroModel.ON_HERO_LIKE_SKIN_CHANGE,         Func = Bind(self, self.OnHeroSkinChange) },
        {Model = HeroModel, MsgName = HeroModel.ON_PLAYER_LIKE_HERO_CHANGE,        Func = Bind(self, self.ON_PLAYER_LIKE_HERO_CHANGE)},
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_SHOW_ITEM_CLICK,           Func = Bind(self, self.OnHeroClickCallBack)},
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_SHOW_ITEM_RIGHTCLICK,           Func = Bind(self, self.OnHeroLikeClickCallBack)},
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE, Func = Bind(self, self.ACTIVITY_ACTIVITYLIST_CHANGE_FUNC)},
		{Model = DepotModel,  	MsgName = DepotModel.ON_DEPOT_DATA_INITED,      Func = Bind(self, self.ON_DEPOT_DATA_INITED)},
        {Model = HeroModel, MsgName = HeroModel.HERO_QUICK_TAB_HERO_SELECT,           Func = Bind(self, self.HERO_QUICK_TAB_HERO_SELECT)},

        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Left), Func = Bind(self,self.OnADControlClick,-1) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Right), Func = Bind(self,self.OnADControlClick,1) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A), Func = Bind(self,self.OnADControlClick,-1) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self,self.OnADControlClick,1) },
    }

    --2.按钮点击事件绑定
    self.BindNodes = {        
        -- { UDelegate = self.View.GUIButtonUnlock.OnClicked, Func = Bind(self, self.OnUnlockButtonClick) },  --解锁按钮
    }
    
    --4.底部左侧返回按键
    local Btn = UIHandler.New(self, self.View.CommonBtnTips_ESC, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_return_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
    }).ViewInstance
    --5.底部左侧角色详情
    self.View.CommonBtnTips_ViewAll:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- Btn = UIHandler.New(self, self.View.CommonBtnTips_ViewAll, WCommonBtnTips, 
    -- {
    --     OnItemClick = Bind(self, self.OnPreviewBtnClicked),
    --     CommonTipsID = CommonConst.CT_LShift,
    --     TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_Rolepreview"),
    --     HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    --     ActionMappingKey = ActionMappings.LShift
    -- }).ViewInstance
    
    --6.喜欢按钮
    Btn = UIHandler.New(self, self.View.WBP_CommonBtn_Like, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnHeroLikeBtnClick),
        CommonTipsID = CommonConst.CT_F,
        ActionMappingKey = ActionMappings.F,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_Like_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    }).ViewInstance
    
    --7.右侧英雄列表下方的详细按钮
    Btn = UIHandler.New(self, self.View.WBP_HeroInfo, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnViewAllClicked),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_Roledetails_Btn"),
        ActionMappingKey = ActionMappings.SpaceBar,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    }).ViewInstance
    ---@type CommonRedDot
    self.RedDot = UIHandler.New(self, self.View.WBP_HeroInfo.WBP_RedDotFactory, CommonRedDot, {RedDotKey = "TabHero_", RedDotSuffix = self.CurrentSelectedHeroID}).ViewInstance

    --8.右侧英雄列表下方的解锁按钮
    self.UnlockBtn = UIHandler.New(self, self.View.WBP_CommonBtn_Unlock, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnUnlockButtonClick),
        CommonTipsID = CommonConst.CT_F,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_unlock_Btn"),
        ActionMappingKey = ActionMappings.F,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    }).ViewInstance
    -- 跳转好感度
    Btn = UIHandler.New(self, self.View.CommonBtnTips_Favor, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnJumpToFavor),
        CommonTipsID = CommonConst.CT_X,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_Goodwill_Btn"),
        ActionMappingKey = ActionMappings.X,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    }).ViewInstance

    self.NeedLSKey2PropertyKey = {
        [HeroDetailPanelMdt.MenTabKeyEnum.Skill] = HeroModel.LSEventTypeEnum.LSPathTabDetail2Main,
        [HeroDetailPanelMdt.MenTabKeyEnum.Skin] = HeroModel.LSEventTypeEnum.LSPathTabSkin2Main,
        [HeroDetailPanelMdt.MenTabKeyEnum.Talent] = HeroModel.LSEventTypeEnum.LSPathTabRune2Main,
        [HeroDetailPanelMdt.MenTabKeyEnum.DisplayBoard] = HeroModel.LSEventTypeEnum.LSPathTabDetail2Main,
        [ ViewConst.HeroPreView] = HeroModel.LSEventTypeEnum.LSPathHeroPreview2Main,
    }
    
end

function HallTabHero:OnADControlClick(Value)
    if not self.HeroId2Index or not self.HeroIndex2HeroId then
        return
    end
    local Index = self.HeroId2Index[self.CurrentSelectedHeroID] or 0
    local MaxIndex = self.HeroId2Index[self.HeroIndex2HeroId[#self.HeroIndex2HeroId]] or 0
    local MinIndex = 1
    local NewIndex = Index + Value
    if NewIndex > MaxIndex then
        NewIndex = MinIndex
    end
    if NewIndex < MinIndex then
        NewIndex = MaxIndex
    end
    local NewHeroId = self.HeroIndex2HeroId[NewIndex]
    self:OnHeroItemClick(NewHeroId)
end

function HallTabHero:GetViewKey()
    return ViewConst.Hall*100 + CommonConst.HL_HERO
end
--[[
    Param = {
    }
]]
function HallTabHero:OnShow(Param)
    self:UpdateUI(Param)
    SoundMgr:PlaySound(SoundCfg.Music.MUSIC_HERO)
end
function HallTabHero:OnManualShow(Param)
    self:UpdateUI(Param)
    SoundMgr:PlaySound(SoundCfg.Music.MUSIC_HERO)
end

function HallTabHero:OnManualHide(Param)
    self.LastDetailTab = 0
end

function HallTabHero:OnHide()
    self.LastDetailTab = 0
end

function HallTabHero:UpdateUI(Param)
    local TInitialID = 0
    if Param and Param.SelectId and Param.SelectId > 0 then
        TInitialID = Param.SelectId
    else
         --1.进入界面时，默认选择用户标记喜欢的英雄，所以需要这里需要先获取到用户标记喜欢的英雄，然后遍历数据找到对应的数据索引
        ---@type HeroModel
        local HeroModel = MvcEntry:GetModel(HeroModel)
        TInitialID = HeroModel:GetFavoriteId()
    end
    self.LastDetailTab = 0
    self:OnHeroItemClick(TInitialID, true)
end


---更新界面上的按钮显示逻辑
function HallTabHero:OnNewHeroUnlocked(_, nHeroId)
    self:UpdateUnlockBtnState()
    self:UpdateLikeBtnShow()
end

---左键点击回调，选中（鼠标右键点击也会触发）
---@param Index number 控件索引
---@param InLikeClick boolean 是否通过右键回调过来的
function HallTabHero:OnHeroItemClick(HeroID,IsInit)
    local ConfigData = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.Id, HeroID)
    if not ConfigData then
        return 
    end
    if not IsInit and HeroID == self.CurrentSelectedHeroID then
        return
    end

    self.View.WBP_HeroNameAndDetailItem.HeroName:SetText(StringUtil.Format(ConfigData[Cfg_HeroConfig_P.Name]))
    -- if UE.UGFUnluaHelper.IsEditor() then
    --     self.View.WBP_HeroNameAndDetailItem.HeroName:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_2"), ConfigData[Cfg_HeroConfig_P.Name],tostring(HeroID)))
    -- end
    self.View.WBP_HeroNameAndDetailItem.HeroName_1:SetText(StringUtil.Format(ConfigData[Cfg_HeroConfig_P.RealName]))
    self.View.WBP_HeroNameAndDetailItem.HeroDetail:SetText(StringUtil.Format(ConfigData[Cfg_HeroConfig_P.HeroDescription]))

    local OldId = self.CurrentSelectedHeroID
    self.CurrentSelectedHeroID = HeroID
    self.RedDot:ChangeKey("TabHero_", self.CurrentSelectedHeroID)

    self:UpdateUnlockBtnState()
    self.View.WBP_HeroInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local IsFavorOpen = MvcEntry:GetModel(FavorabilityModel):IsFavorablityOpen(self.CurrentSelectedHeroID)
    self.View.CommonBtnTips_Favor:SetVisibility(IsFavorOpen and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    self:UpdateLikeBtnShow()
    self:UpdateSkillShow()
    self:UpdateFavorabilityPanel()

    if not IsInit then
        local CurSelectSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(self.CurrentSelectedHeroID)
        SoundMgr:PlayHeroVoice(CurSelectSkinId, SoundCfg.Voice.HERO_NEW_HERO_IN)
        self:HnadleShowAvator(OldId)
    end

    Timer.InsertTimer(0,function()
        MvcEntry:GetModel(HeroModel):DispatchType(HeroModel.ON_HERO_SHOW_ITEM_SELECT,{OldId = OldId, NewId = self.CurrentSelectedHeroID})
	end)
end

function HallTabHero:HnadleShowAvator(OldId)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then return end
    HallAvatarMgr:HideAvatarByAvatarID(self:GetViewKey(),OldId)
    self:UpdateShowAvatar()
end

function HallTabHero:OnShowAvator(Param,IsNotVirtualTrigger)
    self:UpdateShowAvatar(true)
end
function HallTabHero:OnHideAvator(Param,IsNotVirtualTrigger)
    self:OnHideAvatorInner()
end

--[[
    通过确认上次打开的英雄详情Tab分页数据，获取需要进行执行的LS路径
]]
function HallTabHero:GetLSPathByNeedLSKey(TabId,SkinId)
    local LSPath = nil
    if TabId > 0 then
        local PropertyKey = self.NeedLSKey2PropertyKey[TabId]
        if PropertyKey then
            CWaring("PropertyKey:" .. PropertyKey)
            LSPath = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(SkinId,PropertyKey)
        end
    end
    return LSPath
end

function HallTabHero:UpdateShowAvatar(InPlayCameraLS)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    -- self:OnHideAvatorInner()
    local CurSelectSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(self.CurrentSelectedHeroID)
    local SpawnHeroParam = {
        ViewID = self:GetViewKey(),
        InstID = 0,
        HeroId = self.CurrentSelectedHeroID,
        SkinID = CurSelectSkinId,
        Location = HallTabHero.Const.DefaultAvatarShowLocation,
        Rotation = HallTabHero.Const.DefaultAvatarShowRotation,
        PlayShowLS = self.LastDetailTab == 0
    }
    print_r(SpawnHeroParam,"UpdateShowAvatar",true)
    -- CWaring(StringUtil.Format("====={0},{1},{2}",SpawnHeroParam.Location.X,SpawnHeroParam.Location.Y,SpawnHeroParam.Location.Z))
    self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    self:UpdateShowAvatarAction()
    local IsCloseFromFavor = MvcEntry:GetModel(FavorabilityModel):GetIsCloseFromFavorMain()
    if IsCloseFromFavor then
        -- 从好感返回，不需要播放任何ls
        return
    end
    self:PlayCharaterLS(InPlayCameraLS)
    self.LastDetailTab = 0
end

function HallTabHero:PlayCharaterLS(InPlayCameraLS)
    local CurSelectSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(self.CurrentSelectedHeroID)
    -- MvcEntry:GetCtrl(SequenceCtrl):StopAllSequences()
    if InPlayCameraLS then
        -- CWaring("NeedLS========================")
        --播放镜头动画
        local SetBindings = {
            {
                ActorTag = "",
                Actor = self.CurShowAvatar:GetSkinActor(), 
                TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM,
            }
        }
        local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
        if CameraActor ~= nil then
            local CameraBinding = {
                ActorTag = "",
                Actor = CameraActor, 
                TargetTag = SequenceModel.BindTagEnum.CAMERA,
            }
            table.insert(SetBindings,CameraBinding)
        end

        local TabId = self.LastDetailTab
        local LSPath = self:GetLSPathByNeedLSKey(TabId,CurSelectSkinId)
        if not LSPath then
            LSPath = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_HERO_MAIN)
        end
        if LSPath then
            local PlayParam = {
                LevelSequenceAsset = LSPath,
                SetBindings = SetBindings,
                TransformOrigin = self.CurShowAvatar:GetTransform(),
                ForceStopAfterFinish = true,
                WaitUtilActorHasBeenPrepared = true
            }
            MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(StringUtil.FormatSimple("{0}_{1}",ViewConst.Hall,CommonConst.HL_HERO), function ()
                -- CWaring("HeroMdt:PlaySequenceByTag Suc")
            end, PlayParam)
        end
    else
        -- CWaring("Not NeedLS========================")
        --播放角色动画
        local SetBindingsAnim = {
            {
                ActorTag = "",
                Actor = self.CurShowAvatar:GetSkinActor(), 
                TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM,
            }
        }
        local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
        if CameraActor ~= nil then
            local CameraBinding = {
                ActorTag = "",
                Actor = CameraActor, 
                TargetTag = SequenceModel.BindTagEnum.CAMERA,
            }
            table.insert(SetBindingsAnim,CameraBinding)
        end
        local LevelSequenceAsset,IsEnablePostProcess = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(CurSelectSkinId,HeroModel.LSEventTypeEnum.LSPathHeroMainLS)
        local PlayParamAnim = {
            LevelSequenceAsset = LevelSequenceAsset,
            SetBindings = SetBindingsAnim,
            IsEnablePostProcess = IsEnablePostProcess,
            WaitUtilActorHasBeenPrepared = true
        }
        MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(StringUtil.FormatSimple("{0}_{1}_Anim",ViewConst.Hall,CommonConst.HL_HERO), function ()
            -- CWaring("HeroMdt:PlaySequenceByTag Suc")
        end, PlayParamAnim)
    end
end

function HallTabHero:OnHideAvatorInner()
    -- MvcEntry:GetCtrl(SequenceCtrl):StopAllSequences()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then return end
    HallAvatarMgr:HideAvatarByViewID(self:GetViewKey())
end

function HallTabHero:UpdateShowAvatarAction()
    self.CurShowAvatar:OpenOrCloseCameraAction(false)
    self.CurShowAvatar:OpenOrCloseAvatorRotate(false)
    self.CurShowAvatar:OpenOrCloseGestureAction(true)
end

--[[
Param = {
    HeroId = HeroId,
    SkinId = SkinId,
}
--]]
---当角色皮肤更换后触发，此时只要在当前展示的角色是指定角色时，才用处理
function HallTabHero:OnHeroSkinChange(_, Param)
    if not Param or not Param.HeroId or Param.HeroId ~= self.CurrentSelectedHeroID then return end
    if MvcEntry:GetCtrl(ViewRegister):IsViewBeVirtualHiding(ViewConst.Hall) then
        CWaring("HallTabHero:OnHeroSkinChange IsViewBeVirtualHiding,So return")
        return
    end
    self:UpdateShowAvatar()
end

--endregion AvatarDisplay

--region 底部按钮&右侧英雄列表 点击事件

---Esc点击，返回
function HallTabHero:OnEscClicked()
    CommonUtil.SwitchHallTab(CommonConst.HL_PLAY)
end

---解锁按钮点击
function HallTabHero:OnUnlockButtonClick()
    --1.优先本地检查是否满足解锁条件
    ---@type HeroModel
    local HeroModel = MvcEntry:GetModel(HeroModel)
    local RequiredItemId, RequiredItemNum = HeroModel:GetHeroUnlockRequirementsItems(self.CurrentSelectedHeroID)

    CLog("[cw] RequiredItemId: " .. tostring(RequiredItemId))
    CLog("[cw] RequiredItemNum: " .. tostring(RequiredItemNum))

    --1.1.如果前不够，这里直接return
    local DepotModel = MvcEntry:GetModel(DepotModel)
    local OwnedRequiredItemCount = DepotModel:GetItemCountByItemId(RequiredItemId)
    if OwnedRequiredItemCount < RequiredItemNum then
        local describeMsg = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_Insufficientcurrency"), DepotModel:GetItemName(RequiredItemId), RequiredItemNum, OwnedRequiredItemCount)
        local msgParam = {                                                                                      
            describe = describeMsg
        }
        UIMessageBox.Show(msgParam)
        return
    end

    --2.走到这里说明钱够了，这里整理数据，准备发送协议
    --2.1.发送协议函数体
    local sendReq = function()
        --发送协议
        ---@type HeroCtrl
        local Ctrl = MvcEntry:GetCtrl(HeroCtrl)
        Ctrl:SendProto_BuyHeroReq(self.CurrentSelectedHeroID)
    end

    --TODO: 策划后期应该会改这一块的显示 by bailixi
    --2.2.使用UIMessageBox发送协议
    local buyDescribeMsg = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_Doyouwanttousetobuy"), RequiredItemNum, DepotModel:GetItemName(RequiredItemId), DepotModel:GetItemName(self.CurrentSelectedHeroID)) 
    local msgParam = {
        describe = buyDescribeMsg,     --【必选】描述 
        leftBtnInfo = {},           --【可选】左按钮信息，无数据则不显示
        rightBtnInfo = {            --【可选】右铵钮信息，默认是【关闭弹窗】
            name = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HallTabHero_buy"),           --【可选】按钮名称，默认为【确认】
            callback = sendReq      --【可选】按钮回调
        },
    }
    UIMessageBox.Show(msgParam)
end

---Tab，全屏预览
function HallTabHero:OnPreviewBtnClicked()
    ---@type HeroModel
    local HeroModel = MvcEntry:GetModel(HeroModel)
    local SkinId = HeroModel:GetFavoriteSkinIdByHeroId(self.CurrentSelectedHeroID)
    local SkinDataList = {}

    local HeroDataList = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroConfig,Cfg_HeroConfig_P.IsShow,1)
    for k,v in ipairs(HeroDataList) do
        local SkinId = HeroModel:GetFavoriteSkinIdByHeroId(v[Cfg_HeroConfig_P.Id])
        local CfgHeroSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,SkinId)
        table.insert(SkinDataList,CfgHeroSkin)
    end
    local Param = {
        SkinId = SkinId,
        SkinDataList = SkinDataList,
        FromID = ViewConst.Hero
    }    
    MvcEntry:OpenView(ViewConst.HeroPreView, Param)
end

---空格点击，打开英雄详情
function HallTabHero:OnViewAllClicked()    
    --红点，点击一次打上标记
    self.RedDot:Interact()
    
    local Param = {
        HeroId = self.CurrentSelectedHeroID,
        CloseCallBack = function(TabId)
            self.LastDetailTab = TabId
        end
    }
    MvcEntry:OpenView(ViewConst.HeroDetail, Param)
end

---右键点击发送协议，告诉后台需要更换喜欢的角色
---@param Index number 控件索引
function HallTabHero:SetLikeHeroAction(HeroID)
    ---@type HeroCtrl
    local Ctrl = MvcEntry:GetCtrl(HeroCtrl)
    Ctrl:SendProto_SelectHeroReq(HeroID)
end

--endregion 底部按钮&右侧英雄列表 点击事件

---隐藏所有英雄列表中的控件
function HallTabHero:ShowAllHero()
    local cfgs = G_ConfigHelper:GetDict(Cfg_HeroTypeCofig)
    if not cfgs then
        return
    end

    local WidgetClass = UE4.UClass.Load(CommonUtil.FixBlueprintPathWithC("/Game/BluePrints/UMG/OutsideGame/Hero/WBP_HeroTabListItem.WBP_HeroTabListItem"))
    for _, v in ipairs(cfgs) do
        local CfgHeros = G_ConfigHelper:GetMultiItemsByKeys(Cfg_HeroConfig,{Cfg_HeroConfig_P.TypeId,Cfg_HeroConfig_P.IsShow}, {v[Cfg_HeroTypeCofig_P.Id],1})
        if #CfgHeros > 0 then
            local Widget = NewObject(WidgetClass, self.View)
            self.View.GUIHorizontalBox_TabList:AddChild(Widget)

            UIHandler.New(self, Widget, require("Client.Modules.Hero.HeroShowItemList"), {
                Type = v[Cfg_HeroTypeCofig_P.Id],
                Name = v[Cfg_HeroTypeCofig_P.Name],
                TypeIcon = v[Cfg_HeroTypeCofig_P.TypeIcon],
                CfgHeros = CfgHeros
            })

            for _, v in ipairs(CfgHeros) do
                self.HeroId2Index = self.HeroId2Index or {}
                self.HeroIndex2HeroId = self.HeroIndex2HeroId or {}
                table.insert(self.HeroIndex2HeroId, v[Cfg_HeroConfig_P.Id])
                self.HeroId2Index[v[Cfg_HeroConfig_P.Id]] = #self.HeroIndex2HeroId
            end
        end
    end
end

-- 更新技能显示列表
function  HallTabHero:UpdateSkillShow()
    print("HallTabHero:UpdateSkillShow", self.CurrentSelectedHeroID)
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, self.CurrentSelectedHeroID)
    local SkillGroupId = CfgHero[Cfg_HeroConfig_P.SkillGroupId]
    local SkillList = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkillCfg,Cfg_HeroSkillCfg_P.SkillGroupId,SkillGroupId)
    for i=1,3 do
        local SkillItem = self.View["WBP_HeroSkill_ListItem_" .. i]
        local SkillCfg = SkillList[i]
        if not SkillCfg then
            CError("HallTabHero:UpdateSkillShow SkillCfg is nil")
            return
        end
        local Param = {
            SkillId = SkillCfg[Cfg_HeroSkillCfg_P.SkillId],
            ClickCallback = Bind(self,self.OnSkillListItemClick,SkillCfg[Cfg_HeroSkillCfg_P.SkillId])
        }
        if self.Id2SkillWidgetList[i] then
            self.Id2SkillWidgetList[i]:OnShow(Param)
        else
            self.Id2SkillWidgetList[i] = UIHandler.New(self,SkillItem, require("Client.Modules.Hero.Skill.HeroSkillListItemLogic"),Param).ViewInstance
            
        end
    end
end

-- 更新好感度面板
function HallTabHero:UpdateFavorabilityPanel()
    if not self.FavorabilityEntranceIns then
        self.FavorabilityEntranceIns = UIHandler.New(self,self.View.WBP_Hero_Favorability_Entrance,require("Client.Modules.Favorability.FavorabilityEntranceLogic")).ViewInstance
    end
    self.FavorabilityEntranceIns:UpdateUI(self.CurrentSelectedHeroID)
end

function HallTabHero:OnHeroClickCallBack(_,HeroID)
    self:OnHeroItemClick(HeroID)
end

function HallTabHero:OnHeroLikeClickCallBack(_,HeroID)
    self:SetLikeHeroAction(HeroID)
end

function HallTabHero:OnHeroLikeBtnClick()
    self:SetLikeHeroAction(self.CurrentSelectedHeroID)
end

-- 更新喜欢按钮状态
function HallTabHero:UpdateLikeBtnShow()
    local ConfigData = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.Id, self.CurrentSelectedHeroID)
    if not ConfigData then
        return 
    end
    local heroModel = MvcEntry:GetModel(HeroModel)
    local IsGot = heroModel:CheckGotHeroById(ConfigData[Cfg_HeroConfig_P.Id])
    if self.CurrentSelectedHeroID == MvcEntry:GetModel(HeroModel):GetFavoriteId() or not IsGot then
        self.View.WBP_CommonBtn_Like:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.View.WBP_CommonBtn_Like:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

--[[
    玩家装备英雄产生变化
]]
function HallTabHero:ON_PLAYER_LIKE_HERO_CHANGE(_, Data)
    self:OnHeroItemClick(Data.NewId)
    self:UpdateLikeBtnShow()
end

-- 跳转好感度
function HallTabHero:OnJumpToFavor()
    local Param = {
        HeroId = self.CurrentSelectedHeroID
    }
    MvcEntry:OpenView(ViewConst.FavorablityMainMdt,Param)
end

function HallTabHero:OnSkillListItemClick(SkillId)
    local ViewParam = {
        ViewId = ViewConst.Hall,
        TabId = CommonConst.HL_HERO .. "-" .. SkillId
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
    local Param = {
        SkillId = SkillId,
        ShowGroupSkillList = true,
    }
    MvcEntry:OpenView(ViewConst.HeroSkillPreView,Param)
end

--断线重连回来触发获得新英雄，刷新按钮状态
function HallTabHero:ON_DEPOT_DATA_INITED()
    self:UpdateUnlockBtnState()
    self:UpdateLikeBtnShow()
end

function HallTabHero:ACTIVITY_ACTIVITYLIST_CHANGE_FUNC()
    self:UpdateUnlockBtnState()
    self:UpdateLikeBtnShow()
end

--更新当前选中英雄未解锁按钮状态
function HallTabHero:UpdateUnlockBtnState()
    local ConfigData = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.Id, self.CurrentSelectedHeroID)
    if not ConfigData then
        return 
    end
    local heroModel = MvcEntry:GetModel(HeroModel)
    local IsGot = heroModel:CheckGotHeroById(ConfigData[Cfg_HeroConfig_P.Id])
    self.View.WBP_CommonBtn_Unlock:SetVisibility(IsGot and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
    if not IsGot then
        local JumpID = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(ConfigData[Cfg_HeroConfig_P.ItemId])
        self.UnlockBtn:ShowCurrency(ConfigData[Cfg_HeroConfig_P.UnlockItemId], ConfigData[Cfg_HeroConfig_P.UnlockItemNum],JumpID)
    end
end

function HallTabHero:HERO_QUICK_TAB_HERO_SELECT(_,Param)
    if not Param or not Param.HeroId then
        return
    end
    local IsInit = not Param.NeedUpdateAvatar
    self:OnHeroItemClick(Param.HeroId, IsInit)
end
return HallTabHero
