--[[
    剧情表现对话界面
]]

local class_name = "DialogActionDialogMdt";
DialogActionDialogMdt = DialogActionDialogMdt or BaseClass(GameMediator, class_name);

function DialogActionDialogMdt:__init()
end

function DialogActionDialogMdt:OnShow(data)
end

function DialogActionDialogMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = 
    {
        -- {Model = HallModel, MsgName = HallModel.ON_INPUT_SHIELD_LAYER_HIDE_AFTER_INPUT,	Func = Bind(self, self.OnShowUI) },
    }
    self.BindNodes = 
    {
		{ UDelegate = self.WBP_CommonBtn_Log.GUIButton_Main.OnClicked,				    Func = self.OnClicked_WBP_CommonBtn_Log },
		{ UDelegate = self.GUIButton_ShowAllText.OnClicked,				    Func = self.OnClicked_GUIButton_ShowAllText },
	}

    -- 退出按钮
    UIHandler.New(self,self.CommonBtnTips_Quit, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
        OnItemClick = Bind(self,self.OnEscClicked),
    })
    self.CommonBtnTips_Quit:SetVisibility(UE.ESlateVisibility.Collapsed)

    -- 自动播放按钮
    self.AutoPlayBtn = UIHandler.New(self,self.CommonBtnTips_AutoPlay, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_A,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.A,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "Lua_DialogActionPictureMdt_DoAutoPlay_Btn"),
        OnItemClick = Bind(self,self.OnDoAutoPlay),
    }).ViewInstance
    self.CommonBtnTips_AutoPlay:SetVisibility(UE.ESlateVisibility.Collapsed)

    -- 跳过按钮
    UIHandler.New(self,self.CommonBtnTips_Skip, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_S,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.S,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "1101_Btn"),
        OnItemClick = Bind(self,self.OnDoSkip),
    })
    self.CommonBtnTips_Skip:SetVisibility(UE.ESlateVisibility.Collapsed)

     -- 继续按钮
     UIHandler.New(self,self.CommonBtnTips_Continue, WCommonBtnTips, 
     {
         CommonTipsID = CommonConst.CT_SPACE,
         HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
         ActionMappingKey = ActionMappings.SpaceBar,
         TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "Lua_DialogActionTaskMdt_Continue_Btn"),
         OnItemClick = Bind(self,self.OnClicked_GUIButton_ShowAllText),
     })
     
    --- @type HeroModel
    self.HeroModel = MvcEntry:GetModel(HeroModel)

    self.IsFinishPlay = false
end

--[[
    Param->SetStringField(TEXT("DialogText"), DialogText.ToString());
    Param->SetNumberField(TEXT("PlaySpeed"), PlaySpeed);
    Param->SetArrayField(TEXT("PreActionList"), TextJsonValueArray);
    Param->SetStringField(TEXT("AnimClipEventKey"), AnimClipEventKey);
    Param->SetStringField(TEXT("LSEventKey"), LSEventKey);
    Param->SetBoolField(TEXT("IsAutoPlay"), IsAutoPlay);
    Param->SetBoolField(TEXT("CanSkip"), CanSkip);
    Param->SetNumberField(TEXT("SkipToIndex"), double(SkipToIndex));
    Param->SetStringField(TEXT("SkipDes"), SkipDes.ToString());
    Param->SetBoolField(TEXT("CanQuit"), CanQuit);
    Param->SetNumberField(TEXT("Duration"), double(Duration));
    Param->SetBoolField(TEXT("IsCustomAvatarTransform"), IsCustomAvatarTransform);
    if(IsCustomAvatarTransform)
    Param->SetArrayField(TEXT("AvatorLocation"), LocationStringArray);
	Param->SetArrayField(TEXT("AvatarRotator"), RotatorStringArray);
]]
function M:OnShow(Param,IsRepeat)
    self.Param  = Param or {}
    self.IsAutoPlaying = MvcEntry:GetCtrl(DialogSystemCtrl):GetIsDialogAutoPlaying()
    self:UpdateAutoPlayState()
    self:UpdateComponentVisibility()
    self:UpdateDialog()
end

function M:OnRepeatShow(Param)
    self:OnShow(Param,true)
    -- self:UpdateAvatarAniAndLS()
    self:CheckPreLSEvents()
end

function M:UpdateComponentVisibility()
    self.CommonBtnTips_Skip:SetVisibility(self.Param.CanSkip and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.CommonBtnTips_Quit:SetVisibility(self.Param.CanQuit and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.CommonBtnTips_AutoPlay:SetVisibility(self.Param.IsAutoPlay and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.WBP_Favorability_Plot_Dialogue:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function M:UpdateDialog()
    if not self.DialogContentCls then
        self.DialogContentCls = UIHandler.New(self,self.WBP_Favorability_Plot_Dialogue,require("Client.Modules.Dialog.DialogContentLogic")).ViewInstance
    end
    self.DialogContentCls:UpdateUI(self.Param,Bind(self,self.OnTextPlayFinish))
    self.Panel_Log:SetVisibility(UE.ESlateVisibility.Collapsed)
end

-- 文本动画播放结束
function M:OnTextPlayFinish()
    self.Panel_Log:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.IsFinishPlay = true
    if self.IsAutoPlaying then
        self:DoFinish()
    end
end

function M:UpdateAutoPlayState()
    local TipsKey = self.IsAutoPlaying and "Lua_DialogActionPictureMdt_AutoPlaying" or "Lua_DialogActionPictureMdt_DoAutoPlay_Btn"
    self.AutoPlayBtn:SetTipsStr(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", TipsKey))
end
-------------- avatar相关 -----------------------

function M:OnShowAvator()
    if self.Param.AnimClipEventKey ~= "" or self.Param.LSEventKey ~= "" or (self.Param.PreActionList and #self.Param.PreActionList > 0) then
        self:UpdateShowAvatar()
    else
        self:OnHideAvatorInner()
    end
end

function M:OnHideAvator()
    self:OnHideAvatorInner()
end

function M:OnHideAvatorInner()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then return end
    HallAvatarMgr:HideAvatarByViewID(self:GetViewKey())
end

function M:GetViewKey()
    return self.viewId
end

function M:GetAnimClipPath(SkinId)
    return self.HeroModel:GetAnimClipPathBySkinIdAndKey(SkinId,self.Param.AnimClipEventKey)
end

function M:UpdateShowAvatar()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    -- todo 是否会有非英雄avatar
    local CurHeroId = MvcEntry:GetCtrl(DialogSystemCtrl):GetPlayingStoryHeroId()
    if not CurHeroId then
        self:OnHideAvatorInner()
        return
    end
    local CurSkinId = self.HeroModel:GetFavoriteSkinIdByHeroId(CurHeroId)
    if self.CurrentSelectedHeroID and (self.CurrentSelectedHeroID ~= CurHeroId or self.CurSelectSkinId ~= CurSkinId)then
        self:OnHideAvatorInner()
    end
    self.CurrentSelectedHeroID = CurHeroId
    self.CurSelectSkinId = CurSkinId
    local AvatarTransform = MvcEntry:GetModel(FavorabilityModel):GetAvatarTransform().Mid
    local Location = AvatarTransform.Location
    local Rotation = AvatarTransform.Rotation
    if self.Param.IsCustomAvatarTransform then
        Location = UE.FVector(self.Param.AvatorLocation[0],self.Param.AvatorLocation[1],self.Param.AvatorLocation[2])
        Rotation = UE.FRotator(self.Param.AvatarRotator[0],self.Param.AvatarRotator[1],self.Param.AvatarRotator[2])
    end
    local SpawnHeroParam = {
        ViewID = self:GetViewKey(),
        InstID = 0,
        HeroId = self.CurrentSelectedHeroID,
        SkinID = self.CurSelectSkinId,
        Location = Location,
        Rotation = Rotation,
    }
    -- CWaring(StringUtil.Format("====={0},{1},{2}",SpawnHeroParam.Location.X,SpawnHeroParam.Location.Y,SpawnHeroParam.Location.Z))
    self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    self:UpdateShowAvatarAction()
    self:PlayCameraLS()
    self:CheckPreLSEvents()
    -- self:UpdateAvatarAniAndLS()
end

function M:PlayCameraLS()
    if not self.CurShowAvatar then
        return
    end
    local HallModel = MvcEntry:GetModel(HallModel)
    local CurSceneId = HallModel:GetSceneID()
    if CurSceneId == VirtualViewConfig[ViewConst.FavorablityMainMdt].VirtualSceneId then
        -- 目前仅针对好感度场景处理相机LS
        local LSPath = HallModel:GetLSPathById(HallModel.LSTypeIdEnum.LS_CAM_FAVOR_RESET)
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
            MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("CameraLS", function ()
                -- CWaring("FavorablityMainMdt:PlaySequenceByTag Suc")
            end, PlayParam)
        end
    end
end

function M:CheckPreLSEvents()
    local PreActionList = self.Param.PreActionList
    if PreActionList and #PreActionList > 0 then
        local PrePlayIndex = 1
        local function PlayPreLSAni()
            local ActionKey = PreActionList[PrePlayIndex]
            local SplitArray = StringUtil.Split(ActionKey,"#")
            local LSPathKey,AniClipKey = SplitArray[1] or "",SplitArray[2] or ""
            if AniClipKey and AniClipKey ~= "" then
                -- 如果配置有待机动画，播放待机循环
                local AnimClipPath = self:GetAnimClipPath(self.CurSelectSkinId,AniClipKey)
                if AnimClipPath then
                    self.CurShowAvatar:PlayAnimClip(AnimClipPath,true)
                end
            end
            if LSPathKey and LSPathKey ~= "" then
                local LSPath,IsPlayReverse = self:GetLSPathByNeedLSKey(self.CurSelectSkinId,LSPathKey)
                if LSPath then
                    -- 如果配置的是LS，播放LS，结束时播下一个
                    local PlayNext = function()
                        PrePlayIndex = PrePlayIndex + 1
                        if not PreActionList[PrePlayIndex] then
                            -- 播完所有了
                            self:UpdateAvatarAniAndLS()
                            return
                        end
                        PlayPreLSAni()
                    end
                    self:PlayTargetLS(LSPath,PlayNext,"PreLS",IsPlayReverse)
                else
                    self:UpdateAvatarAniAndLS()
                end
            else
                self:UpdateAvatarAniAndLS()
            end
        end
        PlayPreLSAni()
    else
        self:UpdateAvatarAniAndLS()
    end
end

function M:UpdateAvatarAniAndLS()
    -- 播放待机动画
    local AnimClipPath = self:GetAnimClipPath(self.CurSelectSkinId,self.Param.AnimClipEventKey)
    if AnimClipPath then
        self.CurShowAvatar:PlayAnimClip(AnimClipPath,true)
    end

    local LSPath,IsPlayReverse = self:GetLSPathByNeedLSKey(self.CurSelectSkinId,self.Param.LSEventKey)
    if LSPath then
        --播放镜头动画
        -- self:PlayTargetLS(LSPath,Bind(self,self.CheckNeedPlayGiftLS),"",IsPlayReverse)
        self:PlayTargetLS(LSPath,nil,"",IsPlayReverse)
    end
end

function M:GetAnimClipPath(SkinId,AnimClipEventKey)
    if AnimClipEventKey == "" then
        return nil
    end
    return self.HeroModel:GetAnimClipPathBySkinIdAndKey(self.CurSelectSkinId,AnimClipEventKey)
end

function M:GetLSPathByNeedLSKey(SkinId,LSEventKey)
    if not LSEventKey or LSEventKey == "" then
        return nil,nil
    end
    local LSPath = self.HeroModel:GetSkinLSPathBySkinIdAndKey(SkinId,LSEventKey)
    -- todo 暂无需求，预留参数
    local IsPlayReverse = false 
    return LSPath, IsPlayReverse
end

function M:PlayTargetLS(LSPath,Callback,SubTag,IsPlayReverse)
    SubTag = SubTag or ""
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
        IsPlayReverse = IsPlayReverse,
    }
    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(self:GetViewKey(), function ()
        if Callback then
            Callback()
        end
    end, PlayParam)
end

function M:UpdateShowAvatarAction()
    self.CurShowAvatar:OpenOrCloseCameraAction(false)
    self.CurShowAvatar:OpenOrCloseAvatorRotate(false)
    self.CurShowAvatar:OpenOrCloseGestureAction(true)
end

-- function M:PlayHeroVoice()
--     if self.Param.PlayVoiceEventName ~= "" then
--         SoundMgr:PlayHeroVoice(self.CurSelectSkinId, self.Param.PlayVoiceEventName)
--     end
-- end

------------------------------------- avatar 相关 -----------------------------------------------------

-- 停止自动播放
function M:StopAutoPlay()
    self.IsAutoPlaying = false
    self:UpdateAutoPlayState()
    MvcEntry:GetCtrl(DialogSystemCtrl):SetIsDialogAutoPlaying(self.IsAutoPlaying)
end

-- 显示全部文本
function M:OnClicked_GUIButton_ShowAllText()
    self:StopAutoPlay()
    if self.IsFinishPlay then
        self:OnEscClicked()
    else
        if self.DialogContentCls then
            self.DialogContentCls:ShowAllText()
        end        
    end
end

-- 展示对话日志
function M:OnClicked_WBP_CommonBtn_Log()
    self:StopAutoPlay()
    if self.FinishTimer then
        self:RemoveTimer(self.FinishTimer)
        self.FinishTimer = nil
    end
    MvcEntry:OpenView(ViewConst.DialogLog)
end

function M:OnDoSkip()
    MvcEntry:GetCtrl(DialogSystemCtrl):DoSkipToEnd(self.Param.SkipDes,self.Param.SkipToIndex)
end

function M:OnDoAutoPlay()
    self.IsAutoPlaying = not self.IsAutoPlaying
    self:UpdateAutoPlayState()
    MvcEntry:GetCtrl(DialogSystemCtrl):SetIsDialogAutoPlaying(self.IsAutoPlaying)
    if self.IsAutoPlaying and self.IsFinishPlay then
        self:DoFinish()
    end
end

function M:DoFinish()
    self.FinishTimer = self:InsertTimer(self.Param.Duration,function()
        self:OnEscClicked()
    end)
end

function M:OnEscClicked()
    if self.FinishTimer then
        self:RemoveTimer(self.FinishTimer)
        self.FinishTimer = nil
    end
    self.IsFinishPlay = false
    if self.Param.WithoutNext then
        -- MvcEntry:CloseView(self.viewId)
        MvcEntry:GetCtrl(DialogSystemCtrl):DoStopStory(self.viewId)
    else
       MvcEntry:GetCtrl(DialogSystemCtrl):FinishCurAction() 
    end
end

return M
