--[[
    角色展示预览界面
]] local class_name = "CommonPreview";
CommonPreview = CommonPreview or BaseClass(GameMediator, class_name);

function CommonPreview:__init()
end

function CommonPreview:OnShow(data)
end

function CommonPreview:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

M.SHOW_TYPE = {
    NONE = 0,
    HERO = 1,
    WEAPON = 2
}

function M:OnInit()
    UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips, {
        OnItemClick = Bind(self, self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second
    })
    UIHandler.New(self, self.CommonBtnTips_Rotate, WCommonBtnTips, {
        CommonTipsID = CommonConst.CT_ROTATE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.LeftMouseButton
    })
    UIHandler.New(self, self.CommonBtnTips_ZoomInOut, WCommonBtnTips, {
        CommonTipsID = CommonConst.CT_ZOOMINOUT,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second
    })
end

function M:OnShow(Param)
    self.ItemId = Param.ItemId
    self.EnableScroll = Param.EnableScroll == nil and true or Param.EnableScroll
    self.EnableMove = Param.EnableMove == nil and true or Param.EnableMove
    self.CameraConfigType = Param.CameraConfigType or HallModel.CAMERA_CONFIG_CONST.PREVIEW
    self.CustomPartList = Param.CustomPartList
    self.AvatarLocation = Param.Location or UE.FVector(20007, 0, 30)
    self.AvatarRotation = Param.Rotation or UE.FRotator(0, 0, 0)

    self.ShowType = M.SHOW_TYPE.NONE
    self:UpdateHeroCommonShow()
end

function M:OnHide()
end

function M:UpdateHeroCommonShow()
    local ItemConfig = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, self.ItemId)
    if not ItemConfig then
        CWaring("CommonPreview:UpdateHeroCommonShow ItemConfig Is nil")
        return
    end

    self.SpawnHeroParam = nil

    if ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER and ItemConfig[Cfg_ItemConfig_P.SubType] ~= DepotConst.ItemSubType.Background then 
        --角色/角色皮肤
        local CfgHeroSkin = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.ItemId,self.ItemId)
        if not CfgHeroSkin then
           return
        end
        local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, CfgHeroSkin[Cfg_HeroSkin_P.HeroId])
        if not CfgHero then
            return
        end
        self.WBP_HeroNameAndDetailItem.HeroName:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.Name]))
        self.WBP_HeroNameAndDetailItem.HeroName_1:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.RealName]))
        self.WBP_HeroNameAndDetailItem.HeroDetail:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.HeroDescription]))
        self.GUITBWeaponSkinName:SetText(StringUtil.Format(CfgHeroSkin[Cfg_HeroSkin_P.SkinName]))
        self.GUITBWeaponSkinDesc:SetText(StringUtil.Format(CfgHeroSkin[Cfg_HeroSkin_P.SkinDes]))
        -- 品质 
        local Widgets = {
            QualityIcon = self.GUIImageQuality
            -- QualityLevelText = self.GUITextBlock_QualityLevel,
        }
        CommonUtil.SetQualityShow(self.ItemId, Widgets)

        self.SpawnHeroParam = {
            ViewID = ViewConst.CommonPreview,
            InstID = 0,
            HeroId = CfgHeroSkin[Cfg_HeroSkin_P.HeroId],
            SkinID = CfgHeroSkin[Cfg_HeroSkin_P.SkinId],
            Location = self.AvatarLocation,
            Rotation = self.AvatarRotation,
            CustomPartList = self.CustomPartList
        }

        self.ShowType = M.SHOW_TYPE.HERO
    elseif ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_WEAPON then
        --武器
        local CfgHeroSkin = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.ItemId,self.ItemId)
        if not CfgHeroSkin then
            return
        end

        self.SpawnHeroParam = {
            ViewID = ViewConst.CommonPreview,
            InstID = 0,
            WeaponID = CfgHeroSkin[Cfg_WeaponSkinConfig_P.WeaponId],
            SkinID = CfgHeroSkin[Cfg_WeaponSkinConfig_P.SkinId],
            Location = self.AvatarLocation,
            Rotation = self.AvatarRotation,
        }

        self.ShowType = M.SHOW_TYPE.WEAPON
    elseif ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_VEHICLE then
        --载具
    end
end

function M:OnShowAvator()
    if not self.SpawnHeroParam then
        return
    end
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    if self.ShowType == M.SHOW_TYPE.HERO then
        self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, self.SpawnHeroParam)
    elseif self.ShowType == M.SHOW_TYPE.WEAPON then
        self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_WEAPON, self.SpawnHeroParam)
    end
    if not self.CurShowAvatar then
        return
    end
    self.CurShowAvatar:SetCapsuleComponentSize(400, 300)

    local SetCameraAction = function()
        local Config = nil
        if self.ShowType == M.SHOW_TYPE.HERO then
            Config = HallModel.CAMERA_CONFIG[self.CameraConfigType].Charater
        elseif self.ShowType == M.SHOW_TYPE.WEAPON then
            Config = HallModel.CAMERA_CONFIG[self.CameraConfigType].Weapon
        end
        if Config then
            self.CurShowAvatar:OpenOrCloseCameraAction(self.EnableScroll, Config.SRCROLL)
            self.CurShowAvatar:OpenOrCloseRightMouseAction(self.EnableMove, Config.MOVE)
            self.CurShowAvatar:SetCameraDistance(nil, nil, 170)
        end
    end

    local SetBindings = {}
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
        LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallLSCfg.LS_COMMON_PREVIEW_CAMERA.HallLSId),
        SetBindings = SetBindings,
        TransformOrigin = self.CurShowAvatar:GetTransform(),
        NeedStopAllSequence = true,
    }

    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("LSPreviewTag", function()
        CWaring("HeroMdt:PlaySequenceByTag Suc")
        SetCameraAction()
    end, PlayParam)
end

function M:OnHideAvator()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    HallAvatarMgr:HideAvatarByViewID(ViewConst.CommonPreview)
end

function M:OnEscClicked()
    MvcEntry:CloseView(self.viewId)
    return true
end

return M
