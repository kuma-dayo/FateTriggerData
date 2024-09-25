---@class HallTabShopScene 用来管理商城的场景相关的东西

local class_name = "HallTabShopScene"
local HallTabShopScene = BaseClass(UIHandlerViewBase, class_name)

local HallShopLSTag = {
    ShopRecommendLSQ = "ShopRecommendModelLSQ",
}

function HallTabShopScene:OnInit()
    self.MsgList = {
        -- { Model = ShopModel, MsgName = ShopModel.ON_UPDATE_GOODS_MODEL_SHOW, Func = Bind(self, self.ON_UPDATE_GOODS_MODEL_SHOW_Func)},
        -- { Model = ShopModel, MsgName = ShopModel.ON_UPDATE_GOODS_MODEL_HIDE, Func = Bind(self, self.ON_UPDATE_GOODS_MODEL_HIDE_Func)},
    }

    ---@type ShopModel
    self.ModelShop = MvcEntry:GetModel(ShopModel) 

    ---@type SequenceCtrl
    self.LsSequenceCtrl = MvcEntry:GetCtrl(SequenceCtrl)

    self.NotifyUpdateModelCount = 0
end

function HallTabShopScene:OnShow(Param)
    -- CError("HallTabShopScene:OnShow")
    self:ResetData()

    self:SetIntermediaryAgent(Param.Agent)
end

function HallTabShopScene:OnManualShow(Param)
    -- CError("HallTabShopScene:OnManualShow")
    self:ResetData()
end

-- function HallTabShopScene:OnManualHide(Param)
--     -- CError("HallTabShopScene:OnManualHide")
--     self:ResetData()
-- end

function HallTabShopScene:OnHide(Param)
    -- CError("HallTabShopScene:OnHide")
    self:OnHideAvator_Inner()
    self:ResetData()
end

-- --[[
-- 	@param Data 自定义参数，首次创建时可能存在值
-- 	@param IsNotVirtualTrigger 是否  不是因为虚拟场景切换触发的
-- 		true  表示为初始化创建
-- 		false 表示为虚拟场景切换触发
-- ]]
-- function HallTabShopScene:OnShowAvator(Data,IsNotVirtualTrigger) 
--     --CError("HallTabShopScene:OnShowAvator, SequenceCtrl:   IsNotVirtualTrigger = "..tostring(IsNotVirtualTrigger))
--     -- print_trackback("HallTabShopScene:OnShowAvator")

--     if self.LastTabType == ShopDefine.RECOMMEND_PAGE then
--         local LastParam = MvcEntry:GetCtrl(ShopCtrl):GetLastShowParam()
--         self:HandleUpdateGoodsModel(LastParam)
--         if self.bNeedDelayPlayRecommendOpenLs then
--             self.bNeedDelayPlayRecommendOpenLs = false
--             self.NotifyUpdateModelCount = self.NotifyUpdateModelCount + 1
--             local Param = {
--                 ToLSState = ShopDefine.ELSState.RecommendOpen
--             }
--             self:PlaySwitchTabLS(Param)
--         end

--         self:SetActorHidden_SM_PickHero_3(true)
--     else
--         local Param = {
--             -- ToLSState = ShopDefine.ELSState.ScrollTabOut
--             ToLSState = ShopDefine.ELSState.RaffleLEDVisOff
--         }
--         self:PlaySwitchTabLS(Param)

--         self:SetActorHidden_SM_PickHero_3(false)
--     end
-- end

-- function HallTabShopScene:OnHideAvator(Data,IsNotVirtualTrigger) 
--     --CError("HallTabShopScene:OnHideAvator")
--     self.NotifyUpdateModelCount = 0
--     self:OnHideAvator_Inner()
-- end

-- function HallTabShopScene:OnDestroy(Data,IsNotVirtualTrigger)
--     -- CError("HallTabShopScene:OnDestroy")
-- end


function HallTabShopScene:HandleOnShowAvator(Param, IsNotVirtualTrigger, Param2)
    
end

function HallTabShopScene:HandleOnHideAvator(Param, IsNotVirtualTrigger, Param2)
    self.HeroInLSState = ShopDefine.ELSState.None
end

function HallTabShopScene:ResetData()
    self.ShowAvatarGoodsId = 0
end

function HallTabShopScene:SetShopTabType(ShopTabType)
    self.LastTabType = ShopTabType
end

function HallTabShopScene:SetIntermediaryAgent(Agent)
    self.HallTabShopIns = Agent
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function HallTabShopScene:GetViewKey()
    -- return ViewConst.Hall * 100 + CommonConst.HL_SHOP
    return self.TransparentViewId
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------Model >>

---尝试更新模型
function HallTabShopScene:TryUpdateShowAvatar(GoodsId, TranModuleID, AuxParam)
    GoodsId = GoodsId or 0
    TranModuleID = TranModuleID or ETransformModuleID.Shop_Recommend.ModuleID

    CWaring(string.format("HallTabShopScene:TryUpdateShowAvatar, self.ShowAvatarGoodsId = [%s], GoodsId = [%s]", tostring(self.ShowAvatarGoodsId), tostring(GoodsId)))

    if GoodsId <= 0 then
        CError("HallTabShopScene:TryUpdateShowAvatar, HallAvatarMgr == nil !!!! return.")
        return
    end

    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        CError("HallTabShopScene:TryUpdateShowAvatar, HallAvatarMgr == nil !!!! return.")
        return
    end

    ---@type GoodsItem
    local GoodsInfo = self.ModelShop:GetData(GoodsId)
    if GoodsInfo == nil then
        CError("HallTabShopScene:TryUpdateShowAvatar, GoodsInfo == nil !!!! return.")
        return
    end

    if GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Icon then
        CWaring("HallTabShopScene:TryUpdateShowAvatar, GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Icon !!!! return.")
        return
    end

    if GoodsInfo.SceneModelSkinID <= 0 then
        CError("HallTabShopScene:TryUpdateShowAvatar, GoodsInfo.SceneModelSkinID <= 0 !!!! return.")
        return
    end

    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, GoodsInfo.SceneModelSkinID)
    if ItemCfg == nil then
        CError(string.format("HallTabShopScene:TryUpdateShowAvatar, ItemCfg == nil!!!,GoodsId=[%s],SceneModelSkinID=[%s], return.", tostring(GoodsId), tostring(GoodsInfo.SceneModelSkinID)))
        return 
    end
    
    self.ShowAvatarGoodsId = GoodsId

    self:UpdateShowAvatar(GoodsInfo, TranModuleID, AuxParam)
end

---展示商品Avatar
---@param GoodsInfo GoodsItem
function HallTabShopScene:UpdateShowAvatar(GoodsInfo, TranModuleID, AuxParam)
    CWaring("HallTabShopScene:UpdateShowAvatar 11111111111")

    if GoodsInfo == nil then
        CError("HallTabShopScene:UpdateShowAvatar, GoodsInfo == nil !!!! return.")
        return
    end

    self:HideAvator_Inner()
    --重置相机
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
    local FinalTran = self.ModelShop:GetShopModeTranFinal(GoodsInfo.GoodsId, TranModuleID, true, DefPos, DefRot)
    local ShowParam = {
        ViewID = self:GetViewKey(),
        InstID = 0,
        Location = FinalTran.Pos,
        Rotation = FinalTran.Rot,
        Scale = FinalTran.Scale
    }

    CWaring("HallTabShopScene:UpdateShowAvatar 222222222222222222222")

    self.CurShowAvatar = CommonUtil.TryShowAvatarInHallByItemId(GoodsInfo.SceneModelSkinID, ShowParam)
    if self.CurShowAvatar then
        if self.CurShowAvatar.OpenOrCloseCameraAction then
            self.CurShowAvatar:OpenOrCloseCameraAction(false)    
        end

        if GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Hero then
            if bIsHeroBackgroundType then
                --角色展示面板
                self:SetHeroDisplayBordUI(GoodsInfo)
                self:PlayHeroInOrOutLS(false)
            else
                if GoodsInfo.GoodsId == ShopDefine.RecommendHeroGoodsId then
                    self:PlayHeroLS(GoodsInfo)
                    if AuxParam.bNeedPlayOpenLSMark then
                        self:PlayLSByState(ShopDefine.ELSState.RecommendOpen)
                        if self.HallTabShopIns and self.HallTabShopIns:IsValid() then
                            self.HallTabShopIns:ClearPlayOpenLSMark()
                        end
                    else
                        self:PlayHeroInOrOutLS(true)
                    end
                else
                    self:PlayHeroLS(GoodsInfo)
                    self:PlayHeroInOrOutLS(false)
                end
            end
        else
            self.CurShowAvatar:OpenOrCloseAvatorRotate(true)
            self:PlayHeroInOrOutLS(false)
        end
    else
        CError(string.format("HallTabShopScene:UpdateShowAvatar, self.CurShowAvatar == nil !!!! Create Avatar Failed! GoodsId = [%s],SceneModelSkinID = [%s]", tostring(GoodsInfo.GoodsId), tostring(GoodsInfo.SceneModelSkinID)), true)
    end
end

---重置相机
function HallTabShopScene:ResetCurCamera_Inner()
    CWaring("HallTabShopScene:ResetCurCamera_Inner --重置相机")

    ---@type HallCameraMgr
    local HallCameraMgr = CommonUtil.GetHallCameraMgr()
    if HallCameraMgr ~= nil then
        HallCameraMgr:ResetCurCamera()
    end
end

---设置英雄角色面板信息
function HallTabShopScene:SetHeroDisplayBordUI(GoodsInfo)
    if not(CommonUtil.IsValid(self.CurShowAvatar)) then
        CError(string.format("HallTabShopScene:SetHeroDisplayBordUI, self.CurShowAvatar == nil!!! return."))
        return
    end

    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, GoodsInfo.SceneModelSkinID)
    if ItemCfg == nil then
        CError(string.format("HallTabShopScene:SetHeroDisplayBordUI, ItemCfg == nil!!! return."))
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
function HallTabShopScene:PlayHeroLS(GoodsInfo)
    if not(CommonUtil.IsValid(self.CurShowAvatar)) then
        CError(string.format("HallTabShopScene:PlayHeroLS, self.CurShowAvatar == nil!!! return."))
        return
    end

    -- local LSPath,IsEnablePostProcess = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(SkinId, HeroModel.LSEventTypeEnum.LSPathHeroMain2TabDetail)
    local LSPath,IsEnablePostProcess = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(GoodsInfo.SceneModelSkinID, GoodsInfo.EventName)
    -- LSPath = nil
    if LSPath == nil or LSPath == "" then
        --没有 LS
        if self.CurShowAvatar.OpenOrCloseAvatorRotate then
            -- 开启Avatar的Rotate
            self.CurShowAvatar:OpenOrCloseAvatorRotate(true)
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
            ActorTag = "", -- 如场景中静态放置的可用tag搜索出Actor
            Actor = CameraActor, 
            TargetTag = SequenceModel.BindTagEnum.CAMERA,
        }
        table.insert(SetBindingsAnim, CameraBinding)
    end

    local PlayParam = {
        LevelSequenceAsset = LSPath,
        SetBindings = SetBindingsAnim,
        TransformOrigin = self.CurShowAvatar:GetTransform(),
        NeedStopAllSequence = false,
        IsEnablePostProcess = IsEnablePostProcess,
        ForceStopAfterFinish = true,
        WaitUtilActorHasBeenPrepared = true
    }
    
    -- 禁止Avatar的Rotate
    self.CurShowAvatar:OpenOrCloseAvatorRotate(false)
    local OnLSFinished = function()
        if self.CurShowAvatar then
            -- 开启Avatar的Rotate
            self.CurShowAvatar:OpenOrCloseAvatorRotate(true)
            -- self.CurShowAvatar:SetSkeleMeshRenderStencilState(0)
        end
        -- self:StopSequenceByTag_Inner(HallShopLSTag.ShopRecommendLSQ)
    end 

    -- self.CurShowAvatar:SetSkeleMeshRenderStencilState(1)
    self.LsSequenceCtrl:PlaySequenceByTag(HallShopLSTag.ShopRecommendLSQ, OnLSFinished, PlayParam)
end

---屏蔽模型展示1
function HallTabShopScene:OnHideAvator_Inner()
    self.ShowAvatarGoodsId = 0
    self:HideAvator_Inner()
end

---屏蔽模型展示2
function HallTabShopScene:HideAvator_Inner()
    self:StopSequenceByTag_Inner(HallShopLSTag.ShopRecommendLSQ)

    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end

    HallAvatarMgr:HideAvatarByViewID(self:GetViewKey())
end

-------------------------------------------------------------------------------Model <<

-------------------------------------------------------------------------------LS >>

---播放推荐的英雄进入/淡出LS动画
function HallTabShopScene:PlayHeroInOrOutLS(bHeroIn)
    self.HeroInLSState = self.HeroInLSState or ShopDefine.ELSState.None
    if bHeroIn then
       if self.HeroInLSState ~= ShopDefine.ELSState.RecommendHeroIn then
            self.HeroInLSState = ShopDefine.ELSState.RecommendHeroIn 
            self:PlayLSByState(self.HeroInLSState)
       end 
    else
        if self.HeroInLSState ~= ShopDefine.ELSState.RecommendOtherIn then
            self.HeroInLSState = ShopDefine.ELSState.RecommendOtherIn 
        end
        self:PlayLSByState(self.HeroInLSState)
    end
end

function HallTabShopScene:StopPlayLSByState_Inner(InLSState)
    ---@type ShopTabLSCfg
    local LSCfg = self.ModelShop:GetShopTabLSCfg(InLSState)
    if LSCfg then
        self:StopSequenceByTag_Inner(LSCfg.LSTag)
    end
end

function HallTabShopScene:PlaySwitchTabLS(Param)
    Param = Param or {}
    local ToLSState = Param.ToLSState or ShopDefine.ELSState.None

    if ToLSState ~= ShopDefine.ELSState.None then
        -- if self.LastTabType == ShopDefine.RECOMMEND_PAGE and ToLSState == ShopDefine.ELSState.RecommendOpen then
        --     CError("HallTabShopScene:PlaySwitchTabLS self.LastTabType xxx")
        --     -- self:PlayLSByState(ToLSState) 
        --     -- if self.NotifyUpdateModelCount < 1 then
        --     --     self.bNeedDelayPlayRecommendOpenLs = true
        --     --     return
        --     -- end
        -- end

        if ToLSState == ShopDefine.ELSState.ScrollTabIn then
            self:StopPlayLSByState_Inner(ShopDefine.ELSState.ScrollTabOut)
        elseif ToLSState == ShopDefine.ELSState.ScrollTabOut then
            self:StopPlayLSByState_Inner(ShopDefine.ELSState.ScrollTabIn)
        end

        self:PlayLSByState(ToLSState) 
        
        self.LastTabLSState = ToLSState
    end
end

function HallTabShopScene:PlayLSByState(InLSState)
    local LSCfg = self.ModelShop:GetShopTabLSCfg(InLSState)
    -- LSCfg = nil
    if LSCfg == nil then
        CError(string.format("HallTabShopScene:PlayLSByState, LSCfg == nil !!!! InLSState = %s", InLSState))
        return
    end

    -- if InLSState == ShopDefine.ELSState.ScrollTabOut 
    -- or InLSState == ShopDefine.ELSState.ScrollTabIn 
    -- -- or InLSState == ShopDefine.ELSState.RecommendOtherIn 
    -- then
    -- else
    --     return
    -- end
    -- if InLSState == ShopDefine.ELSState.RecommendOpen or InLSState == ShopDefine.ELSState.ScrollTabIn then
    --     else
    --         return
    -- end

    if InLSState == ShopDefine.ELSState.RecommendOpen then
        self:PlayLSByLSCfg(LSCfg)
        self:SetActorHidden_SM_PickHero_3(true)
    elseif InLSState == ShopDefine.ELSState.RecommendHeroIn then
        self:PlayLSByLSCfg(LSCfg)
        self:SetActorHidden_SM_PickHero_3(true)
    elseif InLSState == ShopDefine.ELSState.RecommendOtherIn then
        self:PlayLSByLSCfg(LSCfg)
        self:SetActorHidden_SM_PickHero_3(true)
    elseif InLSState == ShopDefine.ELSState.ScrollTabIn then
        self:PlayLSByLSCfg(LSCfg)
        self:SetActorHidden_SM_PickHero_3(true)
    elseif InLSState == ShopDefine.ELSState.ScrollTabOut then
        self:PlayLSByLSCfg(LSCfg)
        self:SetActorHidden_SM_PickHero_3(false)
    else
        self:PlayLSByLSCfg(LSCfg)
    end
end


---@param InLSCfg ShopTabLSCfg
function HallTabShopScene:PlayLSByLSCfg(InLSCfg)
    CWaring(string.format("HallTabShopScene:PlayLSByLSCfg, Play LS,Tag = %s, LSCfg = %s", InLSCfg.LSTag, table.tostring(InLSCfg)))

    local HallLSCfg = G_ConfigHelper:GetSingleItemById(Cfg_HallLSCfg, InLSCfg.HallLSId)
    if HallLSCfg == nil then
        CError(string.format("HallTabShopScene:PlayLSByLSCfg, HallLSCfg == nil !!!! LSState=[%s],LSTag=[%s],HallLSId=[%s]", InLSCfg.LSState, InLSCfg.LSTag, InLSCfg.HallLSId), true)
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
        CWaring("HallTabShopScene:PlayLSByLSCfg, OnLSFinished InLSCfg.LSTag= " .. InLSCfg.LSTag)
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
function HallTabShopScene:StopAllSequences_Inner()
    CWaring("HallTabShopScene:StopAllSequences_Inner, 停止所有的 LS !!! ")
    self.LsSequenceCtrl:StopAllSequences()
end

---停止指定的 LS
function HallTabShopScene:StopSequenceByTag_Inner(InTag)
    CWaring(string.format("HallTabShopScene:StopSequenceByTag_Inner, 停止指定的 LS !!! InTag = %s", tostring(InTag)))
    self.LsSequenceCtrl:StopSequenceByTag(InTag)
end


-------------------------------------------------------------------------------LS <<

-------------------------------------------------------------------------------Event >>
-- ---广播消息隐藏模型
-- function HallTabShopScene:ON_UPDATE_GOODS_MODEL_HIDE_Func(_, Param)
--     if Param == nil then
--         CError("HallTabShopScene:ON_UPDATE_GOODS_MODEL_HIDE_Func, Param == nil !!!! return.")
--         return
--     end
--     self.TransparentViewId = Param.TransparentViewId
--     self:OnHideAvator_Inner()
-- end

function HallTabShopScene:UpdateHideAvator(Param)
    self.TransparentViewId = Param.TransparentViewId
    self:OnHideAvator_Inner()
end

-- ---广播消息展示模型
-- function HallTabShopScene:ON_UPDATE_GOODS_MODEL_SHOW_Func(_, Param)
--     CWaring("HallTabShopScene:ON_UPDATE_GOODS_MODEL_SHOW_Func,  广播消息展示模型 !")

--     self.NotifyUpdateModelCount = self.NotifyUpdateModelCount + 1
--     self:HandleUpdateGoodsModel(Param)
-- end

function HallTabShopScene:UpdateShowAvator(Param, AuxParam)
    self:HandleUpdateGoodsModel(Param, AuxParam)
end

---处理模型显示
function HallTabShopScene:HandleUpdateGoodsModel(Param, AuxParam)
    if Param == nil then
        Param = self.LastParam or nil
    end
    if not Param then
        CWaring("HallTabShopScene:HandleUpdateGoodsModel, Param == nil !!!! return.")
        return
    end
    self.LastParam = Param
    local GoodsId = Param.GoodsId or 0
    local TranModuleID = Param.ETranModuleID or ETransformModuleID.Shop_Recommend.ModuleID
    self.TransparentViewId = Param.TransparentViewId

    if self.ShowAvatarGoodsId == GoodsId then
        CWaring(string.format("HallTabShopScene:HandleUpdateGoodsModel, self.ShowAvatarGoodsId == GoodsId !!!! GoodsId = %s .return.", GoodsId))
        return
    end

    ---@type GoodsItem
    local GoodsInfo = self.ModelShop:GetData(GoodsId)
    if not GoodsInfo then
        CError("HallTabShopScene:HandleUpdateGoodsModel, Param == nil !!!! return.", true)
        return
    end

    if GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Icon then
        CWaring("HallTabShopScene:HandleUpdateGoodsModel, GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Icon")

        self.ShowAvatarGoodsId = GoodsId

        self:HideAvator_Inner()

        --重置相机
        self:ResetCurCamera_Inner()

        self:PlayHeroInOrOutLS(false)
        return
    end

    self:TryUpdateShowAvatar(GoodsId, TranModuleID, AuxParam)
end

-------------------------------------------------------------------------------Event <<

---特殊处理 屏蔽 商城场景中 SM_PickHero_3 Actor
function HallTabShopScene:SetActorHidden_SM_PickHero_3(bHide)
    local Tag = "SM_PickHero_3"
    CommonUtil.SetActorHiddenByTag(Tag, bHide)

    if bHide then
        CommonUtil.ActiveHallBGEffect(false)
        self:InsertTimer(Timer.NEXT_FRAME, function()
            CommonUtil.ActiveHallBGEffect(false)
        end, false)
    else
        CommonUtil.ActiveHallBGEffect(true)
    end
end

return HallTabShopScene