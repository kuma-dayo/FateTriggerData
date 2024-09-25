--[[
    好感度主界面
]]

local class_name = "FavorablityMainMdt";
FavorablityMainMdt = FavorablityMainMdt or BaseClass(GameMediator, class_name);
-- TabKey
FavorablityMainMdt.MenuTabKeyEnum = {
    Inspiration = 1, -- 灵感
    Plot = 2, -- 思维密匣（剧情）
    Biography = 3, -- 传记
}
function FavorablityMainMdt:__init()
end

function FavorablityMainMdt:OnShow(data)
end

function FavorablityMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.TabTypeId2Vo ={
        [FavorablityMainMdt.MenuTabKeyEnum.Inspiration] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Favorability/WBP_Favorability_Tab_Inspiration.WBP_Favorability_Tab_Inspiration",
            LuaClass= require("Client.Modules.Favorability.FavorabilityTabInspiration"),
            IsAvrtarShowMid = true,
        },
        [FavorablityMainMdt.MenuTabKeyEnum.Plot] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Favorability/WBP_Favorability_Tab_Plot.WBP_Favorability_Tab_Plot",
            LuaClass= require("Client.Modules.Favorability.FavorabilityTabPlot"),
        },
        [FavorablityMainMdt.MenuTabKeyEnum.Biography] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Favorability/WBP_Favorability_Tab_Biography.WBP_Favorability_Tab_Biography",
            LuaClass= require("Client.Modules.Favorability.FavorabilityTabBiography"),
        },
    }
    self.MsgList = 
    {
        {Model = FavorabilityModel, MsgName = FavorabilityModel.FAVOR_VALUE_CHANGED,	Func = self.OnFavorValueChanged },
        {Model = DialogSystemModel, MsgName = DialogSystemModel.ON_PLAY_STORY,	Func = self.OnPlayStory },
        {Model = DialogSystemModel, MsgName = DialogSystemModel.ON_STOP_STORY,	Func = self.OnStoryPlayEnd },
        {Model = DialogSystemModel, MsgName = DialogSystemModel.ON_FINISH_STORY,	Func = self.OnStoryPlayEnd },
    }

    self.BindNodes = 
    {
	}
    self:InitCommonUI()
    --- @type HeroModel
    self.HeroModel = MvcEntry:GetModel(HeroModel)
    ---@type FavorabilityModel
    self.FavorModel = MvcEntry:GetModel(FavorabilityModel)

     -- Avatar不同状态下的位置和角度
    self.AvatarTransform = self.FavorModel:GetAvatarTransform()
    self.SequenceTag = "FavorablityMainMdt_"
end

function M:InitCommonUI()
    local MenuTabParam = {
		ItemInfoList = {
            {Id=FavorablityMainMdt.MenuTabKeyEnum.Inspiration,LabelStr= G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_HallTabFavorability_TabInspiration_Btn")},
            {Id=FavorablityMainMdt.MenuTabKeyEnum.Plot,LabelStr= G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_HallTabFavorability_TabPlot_Btn")},
            {Id=FavorablityMainMdt.MenuTabKeyEnum.Biography,LabelStr= G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_HallTabFavorability_TabBiography_Btn")},
        },
        CurSelectId = FavorablityMainMdt.MenuTabKeyEnum.Inspiration,
        ClickCallBack = Bind(self,self.OnMenuBtnClick),
        ValidCheck = Bind(self,self.MenuValidCheck),
        HideInitTrigger = true,
		IsOpenKeyboardSwitch = true,
	}

    local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_HallTabFavorability_Title_Btn"),
        CurrencyIDs = {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND},
        TabParam = MenuTabParam
    }
    self.CommonTabUpBarInstance = UIHandler.New(self,self.WBP_Common_TabUpBar_02,CommonTabUpBar,CommonTabUpBarParam).ViewInstance

    UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })
    UIHandler.New(self,self.CommonBtnTips_BackHall, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnBackHallClicked),
        CommonTipsID = CommonConst.CT_H,
        ActionMappingKey = ActionMappings.H,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_HallTabFavorability_BackHall_Btn")
    })

    UIHandler.New(self, self.CommonBtnTips_Switch, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ZOOMINOUT,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Favorability_Outside', "Lua_HallTabFavorability_Switch_Btn")
    })
    self.CommonBtnTips_Switch:SetVisibility(UE.ESlateVisibility.Collapsed)
end

--[[
    Param = {
        HeroId, 
        TabId -- optional 默认为 FavorablityMainMdt.MenuTabKeyEnum.Inspiration
    }
]]
function M:OnShow(Param)
    if not Param then
        return
    end
    if Param.JumpParam then
        -- 通过跳转来的
        Param.HeroId,Param.TabId,Param.SubTabId = self.FavorModel:ParseFavorabilityJumpParams(Param.JumpParam)
    end
    if not Param.HeroId then
        CError("FavorablityMainMdt Need HeroId!")
        return
    end
    self.HeroId = Param.HeroId
    self.CurTabId = Param.TabId or FavorablityMainMdt.MenuTabKeyEnum.Inspiration
    if Param.TabId and Param.TabId ~= FavorablityMainMdt.MenuTabKeyEnum.Inspiration then
        -- 指定打开非第一页的页签，需要检测相机镜头
        self.NeedAdjustCam = true
    end
    self.SubTabId = Param.SubTabId

    local IsFirstEnter = self.FavorModel:IsFirstEnterFavor(self.HeroId)
    if IsFirstEnter then
        MvcEntry:GetCtrl(FavorabilityCtrl):SendProto_PlayerSetHeroFirstEnterFlagReq(self.HeroId)
    end
    -- self:OnMenuBtnClick(self.CurTabId,nil,true)
    self.CommonTabUpBarInstance:Switch2MenuTab(self.CurTabId,true)
    SoundMgr:PlaySound(SoundCfg.Music.MUSIC_FAVORABILITY)
end

function M:OnHide()

end

function M:GetViewKey()
    return self.viewId    
end

function M:OnMenuBtnClick(Id, ItemInfo, IsInit)
    if self.CurTabId and self.TabTypeId2Vo[self.CurTabId] and self.TabTypeId2Vo[self.CurTabId].ViewItem then
        self.TabTypeId2Vo[self.CurTabId].ViewItem:ManualClose()
    end
    self.CurTabId = Id
    if not IsInit then
        -- 非初始化，需要校正Avatar相机LS
        self:UpdateAvatarShowCam()
    end
	self:UpdateTabShow()

    local ViewParam = {
        ViewId = ViewConst.FavorablityMainMdt,
        TabId = self.CurTabId,
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
end

function M:MenuValidCheck(Id)
    return true
end

--[[
    更新当前Tab页展示
]]
function M:UpdateTabShow()
    local VoItem = self.TabTypeId2Vo[self.CurTabId]
    if not VoItem then
        CError("FavorablityMainMdt:UpdateTabShow() VoItem nil")
        return
    end
    if not VoItem.ViewItem then
        local WidgetClassPath = VoItem.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget,self.Content)
        local ViewItem = UIHandler.New(self,Widget,VoItem.LuaClass).ViewInstance
        VoItem.ViewItem = ViewItem
        VoItem.View = Widget
    else
        VoItem.ViewItem:ManualOpen()
    end

    for TheTabId,TheVo in pairs(self.TabTypeId2Vo) do
        local TheShow = false
        if TheTabId == self.CurTabId then
            TheShow = true
        end
        if TheVo.View then
            TheVo.View:SetVisibility(TheShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
        if not TheShow and TheVo.ViewItem then
            TheVo.ViewItem:ManualClose()
        end
    end
    local Param = {
        HeroId = self.HeroId,
        SetSwitchBtnVisibleFunc = Bind(self, self.SetSwitchBtnVisible)
    }
    if self.CurTabId == FavorablityMainMdt.MenuTabKeyEnum.Inspiration then
        Param.SwitchShowStateCallback = Bind(self,self.OnSwitchShowState)
    -- elseif self.CurTabId == FavorablityMainMdt.MenuTabKeyEnum.Biography then
    elseif self.CurTabId == FavorablityMainMdt.MenuTabKeyEnum.Plot then
        Param.TabKey = self.SubTabId
        Param.SetAvatarVisibleFunc = Bind(self,self.SetAvatarVisibleFunc)
    end
    VoItem.ViewItem:OnShow(Param)
end

-------------------- avatar 相关 -----------------------------------------------------
function M:OnShowAvator(data)
    if self.IsPlayingStory then
        -- 剧情播放期间不响应
        return
    end
    self:UpdateShowAvatar()
end

function M:OnHideAvator(data)
    self:OnHideAvatorInner()
end

function M:UpdateShowAvatar()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    local CurSkinId = self.HeroModel:GetFavoriteSkinIdByHeroId(self.HeroId)
    if self.CurSelectSkinId ~= CurSkinId then
        self:OnHideAvatorInner()
    end
    self.CurSelectSkinId = CurSkinId
    -- local AvatarTransform = self.TabTypeId2Vo[self.CurTabId].IsAvrtarShowMid and self.AvatarTransform.Mid or self.AvatarTransform.Left
    local AvatarTransform = self.AvatarTransform.Mid
    local SpawnHeroParam = {
        ViewID = self:GetViewKey(),
        InstID = 0,
        HeroId = self.HeroId,
        SkinID = self.CurSelectSkinId,
        Location = AvatarTransform.Location,
        Rotation = AvatarTransform.Rotation,
    }
    -- CWaring(StringUtil.Format("====={0},{1},{2}",SpawnHeroParam.Location.X,SpawnHeroParam.Location.Y,SpawnHeroParam.Location.Z))
    self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    self:UpdateShowAvatarAction()
    self:PlayAnimClip(false)
    self:UpdateAvatarShowCam()
    self.IsAvatarVisible = true
end

function M:UpdateShowAvatarAction()
    self.CurShowAvatar:OpenOrCloseCameraAction(false)
    self.CurShowAvatar:OpenOrCloseAvatorRotate(false)
    self.CurShowAvatar:OpenOrCloseGestureAction(true)
end

function M:UpdateAvatarShowCam()
    if not self.CurShowAvatar then
        return
    end
    -- local AvatarTransform = self.TabTypeId2Vo[self.CurTabId].IsAvrtarShowMid and self.AvatarTransform.Mid or self.AvatarTransform.Left
    -- local ToTransform = self.CurShowAvatar:GetTransform()
    -- self.CurShowAvatar:K2_SetActorLocationAndRotation(AvatarTransform.Location,AvatarTransform.Rotation, false, nil, false)
    local IsShowInMid = self.TabTypeId2Vo[self.CurTabId].IsAvrtarShowMid or false
    if (self.IsShowInMid ~= nil or self.NeedAdjustCam) and IsShowInMid ~= self.IsShowInMid then
        local LSEventKey = IsShowInMid and HallModel.LSTypeIdEnum.LS_CAM_FAVOR_RESET or HallModel.LSTypeIdEnum.LS_CAM_FAVOR_OFFSET
        local LSPath = MvcEntry:GetModel(HallModel):GetLSPathById(LSEventKey)
        if LSPath then
            --播放镜头动画
            local SetBindings = {}
            local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
            if CameraActor ~= nil then
                local CameraBinding = {
                    ActorTag = "",
                    Actor = CameraActor, 
                    TargetTag = SequenceModel.BindTagEnum.CAMERA,
                }
                table.insert(SetBindings,CameraBinding)
            end
            
            local PlayParam = {
                LevelSequenceAsset = LSPath,
                SetBindings = SetBindings,
                TransformOrigin = self.CurShowAvatar:GetTransform(),
            }
            MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(self.SequenceTag.."CameraLS", function ()
                -- CWaring("FavorablityMainMdt:PlaySequenceByTag Suc")
            end, PlayParam)
            self.NeedAdjustCam = false
        end
    end
    self.IsShowInMid = IsShowInMid
end

function M:OnHideAvatorInner()
    if not self.IsAvatarVisible  then
        return
    end
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then return end
    HallAvatarMgr:HideAvatarByViewID(self:GetViewKey())
    self.IsAvatarVisible = false
    self.IsShowInMid = true -- 隐藏了就设置默认在中间，重新出现的时候如果不是中间需要播放回正LS
end

-- 根据送礼界面打开与否，切换播放不同的LS
function M:OnSwitchShowState(_,IsGiftPanelOpened)
    if not self.CurShowAvatar then
        return
    end
    local LSKey,LSPath = self:GetLSPathByNeedLSKey(IsGiftPanelOpened)
    if LSPath then
        self:PlayAvatarLS(LSKey,LSPath)
    end
    self:PlayAnimClip(IsGiftPanelOpened)
end

function M:PlayAvatarLS(LSKey,LSPath,CallFunc)
    if not self.CurShowAvatar then
        return
    end
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

    local PlayParam = {
        LevelSequenceAsset = LSPath,
        SetBindings = SetBindings,
        TransformOrigin = self.CurShowAvatar:GetTransform(),
        NeedStopAllSequence = true,
    }
    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(self.SequenceTag..LSKey, function ()
        if CallFunc then
            CallFunc()
        end
    end, PlayParam)
end

function M:PlayAnimClip(IsGiftPanelOpened)
    local ClipPath = self:GetAnimClipPath(IsGiftPanelOpened)
    if ClipPath then
        self.CurShowAvatar:PlayAnimClip(ClipPath,true)
    end
end

-- 获取LS路径
function M:GetLSPathByNeedLSKey(IsOpened)
    if not self.CurSelectSkinId then
        return nil,nil
    end
    local LSKey = IsOpened and HeroModel.LSEventTypeEnum.LSPathFavListOpened or HeroModel.LSEventTypeEnum.LSPathFavListClosed
    local LsPath = self.HeroModel:GetSkinLSPathBySkinIdAndKey(self.CurSelectSkinId,LSKey)
    return LSKey,LsPath
end

-- 获取待机动画路径
function M:GetAnimClipPath(IsOpened)
    if not self.CurSelectSkinId then
        return nil
    end
    local AnimClipEventKey = IsOpened and HeroModel.LSEventTypeEnum.IdleFavorGift or HeroModel.LSEventTypeEnum.IdleDefault
    return self.HeroModel:GetAnimClipPathBySkinIdAndKey(self.CurSelectSkinId,AnimClipEventKey)
end

--[[
    好感度数值变化
    Msg = 
    {
        int64 HeroId = 1;                   // 英雄Id
        int32 FavorBeforeLevel = 2;         // 增加好感度之前等级
        int32 FavorAfterLevel = 3;          // 增加好感度之后的等级
        int64 CurValue = 4;                 // 当前等级的好感度值
    }
]]
function M:OnFavorValueChanged(Msg)
    -- 播放收礼动画和语音
	if Msg.FavorBeforeLevel ~= Msg.FavorAfterLevel then
        local LSKey = nil
        local MaxLevel = self.FavorModel:GetMaxFavorLevel()
		local SoundVoiceKey = SoundCfg.Voice.FAVOR_LEVEL_UP
        if Msg.FavorAfterLevel == MaxLevel then
            -- 升到满级
            LSKey = HeroModel.LSEventTypeEnum.LSPathFavLevelMax
            SoundVoiceKey = SoundCfg.Voice.FAVOR_LEVEL_MAX
        else
            -- 仅升级未满级
            LSKey = HeroModel.LSEventTypeEnum.LSPathFavLevelUp
        end
        if self.CurSelectSkinId and LSKey then
            local LSPath = self.HeroModel:GetSkinLSPathBySkinIdAndKey(self.CurSelectSkinId,LSKey)
            if LSPath then
                local EndPlayCallFunc = function()
                    self.FavorModel:DispatchType(FavorabilityModel.LEVEL_LS_IS_PLAYING,false)
                end
                self.FavorModel:DispatchType(FavorabilityModel.LEVEL_LS_IS_PLAYING,true)
                self:PlayAvatarLS(LSKey,LSPath,EndPlayCallFunc)
            end
        end
        -- 播放语音
        local SkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(Msg.HeroId)
		if SkinId > 0 then
			SoundMgr:PlayHeroVoice(SkinId, SoundVoiceKey)
		end
    end
end

-- 设置切换按钮是否可见
function M:SetSwitchBtnVisible(IsVisible)
    self.CommonBtnTips_Switch:SetVisibility(IsVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-- 设置Avatar是否可见
function M:SetAvatarVisibleFunc(IsVisible)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then return end
    local ViewKey = self:GetViewKey()
    if self.IsAvatarVisible ~= IsVisible then
        HallAvatarMgr:ShowAvatarByViewID(ViewKey,IsVisible,self.CurSelectSkinId) 
        self.IsAvatarVisible = IsVisible
    end
end

function M:OnPlayStory()
    self.IsPlayingStory = true
end

function M:OnStoryPlayEnd()
    self.IsPlayingStory = false
    if not self.IsAvatarVisible then
        self:UpdateShowAvatar()
    end
end

-- Esc点击，返回上一级
function M:OnEscClicked()
    if self.CurTabId == FavorablityMainMdt.MenuTabKeyEnum.Biography then
        --需要先上报
        MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_HERO_INFO_EVENTTRACKING, {action = MvcEntry:GetModel(EventTrackingModel).CLICKHEROACTSCENE.READ})
    end
    self:DoClose()
end

function M:OnBackHallClicked()
    if self.CurTabId == FavorablityMainMdt.MenuTabKeyEnum.Biography then
        --需要先上报
        MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_HERO_INFO_EVENTTRACKING, {action = MvcEntry:GetModel(EventTrackingModel).CLICKHEROACTSCENE.READ})
    end
    self.FavorModel:SetIsCloseFromFavorMain(true)
    MvcEntry:GetCtrl(ViewJumpCtrl):HallTabSwitch(CommonConst.HL_PLAY)
end

function M:DoClose()
    self.FavorModel:SetIsCloseFromFavorMain(true)
    MvcEntry:CloseView(self.viewId)
end

return M
