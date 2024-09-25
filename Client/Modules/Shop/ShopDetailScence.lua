---@class ShopDetailScence 用来管理商城的场景相关的东西
---@field HideAvator function 

local class_name = "ShopDetailScence"
local ShopDetailScence = BaseClass(UIHandlerViewBase, class_name)

local ShopDetailLSTag = {
    ShopDetailModelLSQ = "ShopDetailModelLSQ",
}

function ShopDetailScence:OnInit()
    ---@type ShopModel
    self.ModelShop = MvcEntry:GetModel(ShopModel)
    ---@type SequenceCtrl
    self.LsSequenceCtrl = MvcEntry:GetCtrl(SequenceCtrl)
end

function ShopDetailScence:OnShow(Param)
    self:ResetData()

    self:SetActorHidden_SM_PickHero_3(false)
end

function ShopDetailScence:OnManualShow(Param)
    self:ResetData()

    self:SetActorHidden_SM_PickHero_3(false)
end

function ShopDetailScence:OnManualHide(Param)
    self:ResetData()
end

function ShopDetailScence:OnHide(Param)
    self:ResetData()
end

function ShopDetailScence:OnDestroy(Data,IsNotVirtualTrigger)
end

function ShopDetailScence:ResetData()
    self.bNeedRecommendOpen = true
    self.HeroInLSState = ShopDefine.ELSState.None
end

-------------------------------------------Avatar >>

function ShopDetailScence:GetViewKey()
    return self.WidgetBase.viewId
end

function ShopDetailScence:TryUpdateShowAvatar(GoodsInfo, ParentGoodsId, bInTheShop)
    CLog("ShopDetailScence:TryUpdateShowAvatar")

    self.bInTheShop = bInTheShop or false

    if GoodsInfo == nil then
        CError("ShopDetailScence:TryUpdateShowAvatar, GoodsInfo == nil .return")
        return
    end

    self.ParentGoodsId = ParentGoodsId or 0

    if GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Icon then
        
        self:HideAvator()
        self:ResetCurCamera_Inner()
        self:PlayHeroInOrOutLS(false, GoodsInfo)

        CWaring("ShopDetailScence:TryUpdateShowAvatar, GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Icon .return")
        return
    end

    self:UpdateShowAvatar(GoodsInfo)
end

---@param GoodsInfo GoodsItem
function ShopDetailScence:UpdateShowAvatar(GoodsInfo)

    if GoodsInfo == nil then
        CError("ShopDetailScence:UpdateShowAvatar, GoodsInfo == nil .return")
        return
    end

    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, GoodsInfo.SceneModelSkinID)
    if ItemCfg == nil then
        CError(string.format("ShopDetailScence:UpdateShowAvatar, ItemCfg == nil!!!,GoodsId=[%s],SceneModelSkinID=[%s] .return",tostring(GoodsInfo.GoodsId),tostring(GoodsInfo.SceneModelSkinID)))
        return
    end

    self:HideAvator()
    self:ResetCurCamera_Inner()

    local DefPos = nil
    local DefRot = nil
    local bIsHeroBackgroundType = CommonUtil.CheckIsHeroBackgroundType(GoodsInfo.SceneModelSkinID)
    if bIsHeroBackgroundType then
        --角色展示面板
        DefPos = UE.FVector(80000, -2000, 191)
        DefRot = UE.FRotator(0.0, 90, 0)
    else
        DefPos = UE.FVector(80001, 290, 133)
        DefRot = UE.FRotator(-10.5, 53, 65)
    end

    ---@type RtShowTran
    local FinalTran = self.ModelShop:GetShopModeTranFinal(GoodsInfo.GoodsId, ETransformModuleID.Shop_Detail.ModuleID, true, DefPos, DefRot)
    local ShowParam = {
        ViewID = self:GetViewKey(),
        InstID = 0,
        Location = FinalTran.Pos,
        Rotation = FinalTran.Rot,
        Scale = FinalTran.Scale
    }

    self.CurShowAvatar = CommonUtil.TryShowAvatarInHallByItemId(GoodsInfo.SceneModelSkinID, ShowParam)
    if self.CurShowAvatar then
        if GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Hero then
            if bIsHeroBackgroundType then
                --英雄角色面版
                self:SetHeroDisplayBordUI(GoodsInfo, ItemCfg)
                self:PlayHeroInOrOutLS(false, GoodsInfo)
            else
                if GoodsInfo.GoodsId == ShopDefine.RecommendHeroGoodsId then
                    self:PlayHeroLS(GoodsInfo)
                
                    if self.bNeedRecommendOpen then
                        self.bNeedRecommendOpen = not(self.bNeedRecommendOpen)
                        -- self:PlayLSByState(ShopDefine.ELSState.RecommendOpen)
                        if self.bInTheShop then
                            self:PlayLSByState(ShopDefine.ELSState.ScrollTabOut)
                        else
                            -- self:PlayLSByState(ShopDefine.ELSState.RaffleLEDVisOff)
                        end
                    else
                        self:PlayHeroInOrOutLS(true, GoodsInfo)
                    end
                else
                    self:PlayHeroLS(GoodsInfo)
                    self:PlayHeroInOrOutLS(false, GoodsInfo)
                end
            end
        else
            local CameraFocusHeight = CommonUtil.GetParameterConfig(ParameterConfig.ShopWeaponFocusHeight, 100)
            local Offset = CommonUtil.GetParameterConfig(ParameterConfig.ShopWeaponFocusOffset, 100)
            local Offset_ZoomIn = CommonUtil.GetParameterConfig(ParameterConfig.ShopWeaponFocusOffset_ZoomIn, 0)

            --self.LsSequenceCtrl:StopSequenceByTag(ShopDetailLSTag.ShopDetailModelLSQ)
            -- 打开或者关闭  控制相机动作（FOV修改）
            self.CurShowAvatar:OpenOrCloseCameraAction(true)
            self.CurShowAvatar:OpenOrCloseAvatorRotate(true)
            local Distance = self.CurShowAvatar:GetDistanceFromCarmera()
            self.CurShowAvatar:ApplyCameraScrollConfigByKey("PreviewSroll")
            self.CurShowAvatar:SetCameraDistance(Distance - Offset_ZoomIn, Distance + Offset, CameraFocusHeight)
            self.CurShowAvatar:AdaptCameraDistanceMinAndMax()

            self:PlayHeroInOrOutLS(false, GoodsInfo)
        end
    else
        --TODO 设置2D图片
        CError(string.format("ShopDetailScence:UpdateShowAvatar, Create Avatar Failed!, GoodsID = %s, SceneModelSkinID = %s", tostring(GoodsInfo.GoodsId),tostring(GoodsInfo.SceneModelSkinID)), true)
    end
end

--- 重置相机
function ShopDetailScence:ResetCurCamera_Inner()
    CWaring("ShopDetailScence:ResetCurCamera_Inner --重置相机")
    ---@type HallSceneMgr
    local HallCameraMgr = CommonUtil.GetHallCameraMgr()
    if HallCameraMgr ~= nil then
        HallCameraMgr:ResetCurCamera()
    end
end

---英雄角色版
function ShopDetailScence:SetHeroDisplayBordUI(GoodsInfo, ItemCfg)
    if not(CommonUtil.IsValid(self.CurShowAvatar)) then
        return
    end

    if ItemCfg == nil then
        CError(string.format("ShopDetailScence:SetHeroDisplayBordUI, ItemCfg == nil!!!"))
        return
    end

    local SubType = ItemCfg[Cfg_ItemConfig_P.SubType]

    --角色展示面板
    local PtParam = {HeroId = 0, FloorId = 0, RoleId = 0, EffectId = 0}
    if SubType == DepotConst.ItemSubType.Background then
        PtParam.FloorId = GoodsInfo.SceneModelSkinID
    elseif SubType == DepotConst.ItemSubType.Pose then
        PtParam.RoleId = GoodsInfo.SceneModelSkinID
    elseif SubType == DepotConst.ItemSubType.Effect then
        PtParam.EffectId = GoodsInfo.SceneModelSkinID
    end
    local TempParam = CommonUtil.MakeDisplayBoardNode(nil, PtParam)

    self.CurShowAvatar:SetDisplayBordUiByParam(TempParam)
end

---@param GoodsInfo GoodsItem
function ShopDetailScence:PlayHeroLS(GoodsInfo)
    if GoodsInfo == nil then
        return
    end

    if not(CommonUtil.IsValid(self.CurShowAvatar)) then
        return
    end

    local CameraFocusHeight = CommonUtil.GetParameterConfig(ParameterConfig.ShopCharaterFocusHeight, 100)
    local Offset = CommonUtil.GetParameterConfig(ParameterConfig.ShopCharaterFocusOffset, 100)
    local Offset_ZoomIn = CommonUtil.GetParameterConfig(ParameterConfig.ShopCharaterFocusOffset_ZoomIn, 0)

    -- local LSPath,IsEnablePostProcess = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(SkinId, HeroModel.LSEventTypeEnum.LSPathHeroMain2TabDetail)
    local LSPath,IsEnablePostProcess = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(GoodsInfo.SceneModelSkinID, GoodsInfo.EventName)
    -- LSPath = "LevelSequence'/Game/Arts/Lobby/Tab/Animations/Hero04/LS/LS_Tab_Hero04_Detail_To_Skin.LS_Tab_Hero04_Detail_To_Skin'"
    -- LSPath = "LevelSequence'/Game/Arts/Lobby/Tab/Animations/Hero04/LS/LS_Tab_Hero04_Skin_To_Rune.LS_Tab_Hero04_Skin_To_Rune'"
    -- LSPath = "LevelSequence'/Game/Arts/Lobby/HeroMain/Animations/Hero04/LS/LS_HeroMain_Hero04_Appear.LS_HeroMain_Hero04_Appear'"
    
    if LSPath == nil or LSPath == "" then
        if self.CurShowAvatar.OpenOrCloseAvatorRotate then
            -- 开启Avatar的Rotate
            self.CurShowAvatar:OpenOrCloseAvatorRotate(true)
        else
            CWaring("ShopDetailScence:PlayHeroLS, self.CurShowAvatar.OpenOrCloseAvatorRotate == nil !!!")
        end
        return 
    end
        
    local SetBindingsAnim = {}

    local HallActorAvatar = self.CurShowAvatar:GetSkinActor()
    if HallActorAvatar ~= nil then
        local SkinActorBinding = {
            ActorTag = "", -- 如场景中静态放置的可用tag搜索出Actor
            Actor = HallActorAvatar, -- 需要在播动画前生成Actor(且直接具有SkeletaMesh组件)
            TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM
        }
        table.insert(SetBindingsAnim, SkinActorBinding)
    end
   
    local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
    if CameraActor ~= nil then
        local CameraBinding = {
            ActorTag = "",
            Actor = CameraActor, 
            TargetTag = SequenceModel.BindTagEnum.CAMERA,
        }
        table.insert(SetBindingsAnim, CameraBinding)
    end

    local PlayParam = {
        LevelSequenceAsset = LSPath,
        SetBindings = SetBindingsAnim,
        TransformOrigin = self.CurShowAvatar:GetTransform(),
        -- NeedStopAllSequence = false,
        IsEnablePostProcess = IsEnablePostProcess,
        ForceStopAfterFinish = true,
        WaitUtilActorHasBeenPrepared = true
    }
    
    -- 禁止Avatar的Rotate
    self.CurShowAvatar:OpenOrCloseAvatorRotate(false)
    -- self.LsSequenceCtrl:StopSequenceByTag(ShopDetailLSTag.ShopDetailModelLSQ)

    local OnLSFinished = function()
        if self.CurShowAvatar then
            -- 开启Avatar的Rotate
            self.CurShowAvatar:OpenOrCloseAvatorRotate(true)
            -- self.CurShowAvatar:SetSkeleMeshRenderStencilState(0)
            
            local Distance = self.CurShowAvatar:GetDistanceFromCarmera()
            self.CurShowAvatar:ApplyCameraScrollConfigByKey("PreviewSroll")
            self.CurShowAvatar:SetCameraDistance(Distance - Offset_ZoomIn, Distance + Offset, CameraFocusHeight)
            self.CurShowAvatar:AdaptCameraDistanceMinAndMax()
            -- 打开或者关闭  控制相机动作（FOV修改）
            self.CurShowAvatar:OpenOrCloseCameraAction(true)
        end
        
        -- self:StopSequenceByTag_Inner(ShopDetailLSTag.ShopDetailModelLSQ)
    end 

    -- self.CurShowAvatar:SetSkeleMeshRenderStencilState(1)
    self.LsSequenceCtrl:PlaySequenceByTag(ShopDetailLSTag.ShopDetailModelLSQ, OnLSFinished, PlayParam)
end

function ShopDetailScence:HideAvator()
    self:StopSequenceByTag_Inner(ShopDetailLSTag.ShopDetailModelLSQ)

    if self.CurShowAvatar and self.CurShowAvatar.StopTransformLerp then
        self.CurShowAvatar:StopTransformLerp()
    end

    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    local ViewID = self:GetViewKey()
    HallAvatarMgr:HideAvatarByViewID(ViewID)
end

-------------------------------------------Avatar <<

-------------------------------------------LS >>

---播放推荐的英雄进入/淡出LS动画
function ShopDetailScence:PlayHeroInOrOutLS(bHeroIn, GoodsInfo)
    self.HeroInLSState = self.HeroInLSState or ShopDefine.ELSState.None
    
    if self.ParentGoodsId == ShopDefine.RecommendGoodsId then
        -- if bHeroIn then
        --     if self.HeroInLSState ~= ShopDefine.ELSState.RecommendHeroIn then
        --         self:StopPlayLSByState(self.HeroInLSState)
    
        --         self.HeroInLSState = ShopDefine.ELSState.RecommendHeroIn 
        --         self:PlayLSByState(self.HeroInLSState)
        --     end 
        --  else
        --     if self.HeroInLSState ~= ShopDefine.ELSState.RecommendOtherIn then
        --         self:StopPlayLSByState(self.HeroInLSState)
                
        --         self.HeroInLSState = ShopDefine.ELSState.RecommendOtherIn 
        --     end
        --     self:PlayLSByState(self.HeroInLSState)
        --  end
        self:PlayLSByState(ShopDefine.ELSState.RaffleLEDVisOff)
    else
        self:PlayLSByState(ShopDefine.ELSState.RaffleLEDVisOff)
    end
end

function ShopDetailScence:StopPlayLSByState(InLSState)
    ---@type ShopTabLSCfg
    local LSCfg = self.ModelShop:GetShopTabLSCfg(InLSState)
    if LSCfg then
        self:StopSequenceByTag_Inner(LSCfg.LSTag)
    end
end

function ShopDetailScence:PlayLSByState(InLSState)
    local LSCfg = self.ModelShop:GetShopTabLSCfg(InLSState)
    if LSCfg == nil then
        CError(string.format("ShopDetailScence:PlayLSByState, LSCfg == nil !!!! InLSState = %s", InLSState))
        return
    end

    if InLSState == ShopDefine.ELSState.RecommendOpen then
        self:PlayLSByLSCfg(LSCfg)
    elseif InLSState == ShopDefine.ELSState.RecommendHeroIn then
        self:PlayLSByLSCfg(LSCfg)
    elseif InLSState == ShopDefine.ELSState.RecommendOtherIn then
        self:PlayLSByLSCfg(LSCfg)
    elseif InLSState == ShopDefine.ELSState.ScrollTabIn then
        self:PlayLSByLSCfg(LSCfg)
    elseif InLSState == ShopDefine.ELSState.ScrollTabOut then
        self:PlayLSByLSCfg(LSCfg)
    elseif InLSState == ShopDefine.ELSState.RaffleLEDVisOff then
        self:PlayLSByLSCfg(LSCfg)
    elseif InLSState == ShopDefine.ELSState.RaffleLEDVisOn then
        self:PlayLSByLSCfg(LSCfg)
    else
        self:PlayLSByLSCfg(LSCfg)
    end
end

---@param InLSCfg ShopTabLSCfg
function ShopDetailScence:PlayLSByLSCfg(InLSCfg)
    CWaring(string.format("ShopDetailScence:PlayLSByLSCfg, Play LS,Tag = %s, LSCfg = %s", InLSCfg.LSTag, table.tostring(InLSCfg)))

    local HallLSCfg = G_ConfigHelper:GetSingleItemById(Cfg_HallLSCfg, InLSCfg.HallLSId)
    if HallLSCfg == nil then
        CError(string.format("ShopDetailScence:PlayLSByLSCfg, HallLSCfg == nil !!!! LSState=[%s],LSTag=[%s],HallLSId=[%s]", InLSCfg.LSState, InLSCfg.LSTag, InLSCfg.HallLSId), true)
        return
    end

    local LSPath = HallLSCfg[Cfg_HallLSCfg_P.LSPath]
    local IsEnablePostProcess = InLSCfg.bPostProcess
    local bUseCache = InLSCfg.bUseCache
    local bNeedStopAfterFinish = InLSCfg.bNeedStopAfterFinish

    local SetBindingsAnim = {}
    -- local HallActorAvatar = self.CurShowAvatar:GetSkinActor()
    -- if HallActorAvatar then
    --     local SkinActorBinding = {
    --         ActorTag = "", -- 如场景中静态放置的可用tag搜索出Actor
    --         Actor = HallActorAvatar, -- 需要在播动画前生成Actor(且直接具有SkeletaMesh组件)
    --         TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM
    --     }
    --     table.insert(SetBindingsAnim, SkinActorBinding)
    -- end
    -- local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
    -- if CameraActor ~= nil then
    --     local CameraBinding = {
    --         ActorTag = "", -- 如场景中静态放置的可用tag搜索出Actor
    --         Actor = CameraActor, 
    --         TargetTag = SequenceModel.BindTagEnum.CAMERA,
    --     }
    --     table.insert(SetBindingsAnim, CameraBinding)
    -- end

    local PlayParam = {
        LevelSequenceAsset = LSPath,
        SetBindings = SetBindingsAnim,
        -- TransformOrigin = self.CurShowAvatar:GetTransform(),
        -- NeedStopAllSequence = false,
        -- IsEnablePostProcess = IsEnablePostProcess,
        UseCacheSequenceActorByTag = bUseCache,
        NeedStopAfterFinish = bNeedStopAfterFinish
    }

    local OnLSFinished = function()
        CWaring("ShopDetailScence:PlayLSByLSCfg, OnLSFinished InLSCfg.LSTag= " .. InLSCfg.LSTag)
        self.LsSequenceCtrl:StopSequenceByTag(InLSCfg.LSTag)

        if InLSCfg.LSState == ShopDefine.ELSState.RecommendOpen then
            if self.CurShowAvatar then
                self.CurShowAvatar:SetSkeleMeshRenderStencilState(0) 
            end
        end
    end
    if InLSCfg.LSState == ShopDefine.ELSState.RecommendOpen then
        if self.CurShowAvatar then
            self.CurShowAvatar:SetSkeleMeshRenderStencilState(1) 
        end
    end
    self.LsSequenceCtrl:PlaySequenceByTag(InLSCfg.LSTag, OnLSFinished, PlayParam)
end

---停止所有的 LS 
function ShopDetailScence:StopAllSequences_Inner()
    CWaring("ShopDetailScence:StopAllSequences_Inner, 停止所有的 LS !!! ")
    self.LsSequenceCtrl:StopAllSequences()
end

---停止指定的 LS
function ShopDetailScence:StopSequenceByTag_Inner(InTag)
    CWaring(string.format("ShopDetailScence:StopSequenceByTag_Inner, 停止指定的 LS !!! InTag = %s", tostring(InTag)))
    self.LsSequenceCtrl:StopSequenceByTag(InTag)
end

-------------------------------------------LS <<

---特殊处理 屏蔽 商城场景中 SM_PickHero_3 Actor
function ShopDetailScence:SetActorHidden_SM_PickHero_3(bHide)
    CLog("ShopDetailScence:SetActorHidden_SM_PickHero_3")

    local Tag = "SM_PickHero_3"
    CommonUtil.SetActorHiddenByTag(Tag, bHide)

    if bHide then
        -- CommonUtil.ActiveHallBGEffect(false)
        -- self:InsertTimer(Timer.NEXT_FRAME, function()
        --     CommonUtil.ActiveHallBGEffect(false)
        -- end, false)
    else
        CommonUtil.ActiveHallBGEffect(true)
    end

    -- local HallSceneMgr = _G.HallSceneMgrInst
    -- if HallSceneMgr == nil then
    --     return
    -- end
    -- local Actors = UE.UGameplayStatics.GetAllActorsWithTag(HallSceneMgr, Tag)
	-- if Actors:Num() > 0 then
	-- 	for k, TempActor in pairs(Actors) do
	-- 		-- TempActor:SetActorHiddenInGame(bHide)
    --         CError(string.format("DDDDDDDDDDDDDDDDDDDDD  TempActor.bHidden = %s",TempActor.bHidden))
	-- 	end
	-- end
end



return ShopDetailScence