--[[
    角色展示预览界面
]]

local class_name = "HeroPreViewPanelMdt";
HeroPreViewPanelMdt = HeroPreViewPanelMdt or BaseClass(GameMediator, class_name);


function HeroPreViewPanelMdt:__init()
end

function HeroPreViewPanelMdt:OnShow(data)
end

function HeroPreViewPanelMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    -- FromID在这个Map中，则展示为右侧样式
    self.ShowRightView = {
        [ViewConst.FavorablityMainMdt] = 1
    }
    -- 使用的CameraConfig的key 以及是否开启鼠标右键操作, 不传为"PreviewSroll"和"PreviewMove"
    self.UseCameraConfigKeys = {
        [ViewConst.FavorablityMainMdt] = {
            Scroll = "FavorCharacterScroll",
            Move = "FavorCharacterMove",
            OpenOrCloseRightMouseAction = true
        }
    }
    self.BindNodes = 
    {
		-- { UDelegate = self.GUIButton_Left.OnClicked,				    Func = self.OnClicked_GUIButton_Left },
		-- { UDelegate = self.GUIButton_Right.OnClicked,				    Func = self.OnClicked_GUIButton_Right },
	}
    self.MsgList = 
    {
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked },
		-- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Left), Func = self.OnClicked_GUIButton_Left },
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Right), Func = self.OnClicked_GUIButton_Right },
	}

    UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })
    self.RotateBtn = UIHandler.New(self,self.CommonBtnTips_Rotate, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ROTATE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.LeftMouseButton,
    }).ViewInstance
    self.ZoomInOutBtn = UIHandler.New(self,self.CommonBtnTips_ZoomInOut, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ZOOMINOUT,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    }).ViewInstance

    self.NeedLSKey2PropertyKey = {
        [StringUtil.FormatSimple("{0}_{1}", HeroDetailPanelMdt.MenTabKeyEnum.Skill, ViewConst.HeroPreView)] = HeroModel.LSEventTypeEnum.LSPathHeroDetail2Preview,
        [StringUtil.FormatSimple("{0}_{1}", HeroDetailPanelMdt.MenTabKeyEnum.Skin, ViewConst.HeroPreView)] = HeroModel.LSEventTypeEnum.LSPathHeroSkin2Preview,
        [StringUtil.FormatSimple("{0}_{1}", ViewConst.Hero, ViewConst.HeroPreView)] = HeroModel.LSEventTypeEnum.LSPathHeroMain2Preview,
    }
end


--[[
    Param = {
        HeroId
        SkinId
        SkinDataList
        FromID
        CustomPartList

        Location
        Rotation
    }
]]
function M:OnShow(Param)
    self.CurShowIndex = -1
    self.SkinId = Param.SkinId
    self.SkinDataList = Param.SkinDataList
    self.FromID = Param.FromID
    self.CustomPartList = Param.CustomPartList
    self.AvatarLocation = Param.Location or UE.FVector(20000, 0, 0)
    self.AvatarRotation = Param.Rotation or UE.FRotator(0, 0, 0)
    -- self.RotateBtn:SetBtnIsCantHit(true)
    -- self.ZoomInOutBtn:SetBtnIsCantHit(true)

    if self.SkinDataList and #self.SkinDataList > 1 then
        self.DataListSize = #self.SkinDataList
        for i=1,#self.SkinDataList do
            local SkinData = self.SkinDataList[i]
            if SkinData[Cfg_HeroSkin_P.SkinId] == self.SkinId then
                self.CurShowIndex = i
            end
        end
    end

    self:UpdateHeroCommonShow()
    self:UpdateViewStyle()
    -- self:UpdateArrowShow()
end
function M:OnHide()
    --可能某些系统在打开时候会修改依赖的场景ID， 关闭时候恢复默认场景ID注册
    MvcEntry:GetCtrl(ViewRegister):RegisterVirtualLevelView(self.viewId,VirtualViewConfig[self.viewId].VirtualSceneId)
end

function M:UpdateHeroCommonShow()
    local CfgHeroSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,self.SkinId)
    if not CfgHeroSkin then
        return
    end
    local HeroId = CfgHeroSkin[Cfg_HeroSkin_P.HeroId]
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,HeroId)
    if not CfgHero then
        return
    end
    self.WBP_HeroNameAndDetailItem.HeroName:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.Name]))
    self.WBP_HeroNameAndDetailItem.HeroName_1:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.RealName]))
    self.WBP_HeroNameAndDetailItem.HeroDetail:SetText(StringUtil.Format(CfgHero[Cfg_HeroConfig_P.HeroDescription]))

    local Param = {
        HideBtnSearch = true,
        ItemID = self.SkinId,
    }
    if not self.CommonDescriptionCls then
        self.CommonDescriptionCls = UIHandler.New(self,self.WBP_Common_Description, CommonDescription, Param).ViewInstance
    else
        self.CommonDescriptionCls:UpdateUI(Param)
    end
end

-- 展示左侧/右侧
function M:UpdateViewStyle()
    local IsShowRight = self.FromID and self.ShowRightView[self.FromID]
    self.WidgetSwitcher_Content:SetActiveWidget(IsShowRight and self.Content_Right or self.Content_Left)
    -- 蓝图函数
    self:SetDescriptionPosType(IsShowRight and 1 or 0)
end


function M:OnShowAvator()
    self:UpdateShowAvator(self.SkinId)
end

function M:UpdateShowAvator(SkinId)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr == nil then
		return 
	end
    local CfgHeroSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,SkinId)
    local HeroId = CfgHeroSkin[Cfg_HeroSkin_P.HeroId]
    HallAvatarMgr:HideAvatarByViewID(ViewConst.HeroPreView)
    local SpawnHeroParam = {
		ViewID = ViewConst.HeroPreView,
		InstID = 0,
		HeroId = HeroId,
		SkinID = SkinId,
        Location = self.AvatarLocation,
        Rotation = self.AvatarRotation,
        CustomPartList =  self.CustomPartList
	}
    self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    if not self.CurShowAvatar then
        return
    end
    
    --将后处理打开
    -- self.CurShowAvatar:SetPostProcessSwitch(true)

    local NeedLSKey = StringUtil.FormatSimple("{0}_{1}", self.FromID, ViewConst.HeroPreView)
    local PropertyKey = self.NeedLSKey2PropertyKey[NeedLSKey]
    if not PropertyKey then
        -- 没有LS播放情况下直接更新。有LS等LS播放完成回调再更新
        self:UpdateCameraConfig()
        return
    end
    local LSPath, IsEnablePostProcess = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(SkinId,PropertyKey)
    if not LSPath then
        return
    end
    MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag("LSPreviewTag")
    local HallActorAvatar = self.CurShowAvatar:GetSkinActor()
    local SetBindings = {
        {
            ActorTag = "", --如场景中静态放置的可用tag搜索出Actor
            Actor = HallActorAvatar, --需要在播动画前生成Actor(且直接具有SkeletaMesh组件)
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
        IsEnablePostProcess = IsEnablePostProcess
    }

    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("LSPreviewTag", function ()
        CWaring("HeroMdt:PlaySequenceByTag Suc")
        self:UpdateCameraConfig()
    end, PlayParam)
end

function M:UpdateCameraConfig()
    if not self.CurShowAvatar then
        return
    end
    local bOpenOrCloseRightMouseAction = true
    local CameraScrollConfigKey,CameraMoveConfigKey = "PreviewSroll","PreviewMove"
    local UseConfig = self.UseCameraConfigKeys[self.FromID]
    if UseConfig then
        bOpenOrCloseRightMouseAction = UseConfig.OpenOrCloseRightMouseAction or false
        CameraScrollConfigKey = UseConfig.Scroll
        CameraMoveConfigKey = UseConfig.Move
    end
    
    self.CurShowAvatar:SetCapsuleComponentSize(400, 300)
    self.CurShowAvatar:OpenOrCloseRightMouseAction(bOpenOrCloseRightMouseAction)
    self.CurShowAvatar:ApplyCameraScrollConfigByKey(CameraScrollConfigKey)
    self.CurShowAvatar:ApplyCameraMoveConfigByKey(CameraMoveConfigKey)
    self.CurShowAvatar:SetCameraDistance(nil, nil, 170)
end

function M:OnHideAvator()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr == nil then
		return 
	end
    HallAvatarMgr:HideAvatarByViewID(ViewConst.HeroPreView)
end

-- function M:OnClicked_GUIButton_Left()
--     self:OnArrowBtnClick(-1)
--     return true
-- end

-- function M:OnClicked_GUIButton_Right()
--     self:OnArrowBtnClick(1)
--     return true
-- end

--[[
    Value
    -1 表示上一个
    1  表示下一个
]]
function M:OnArrowBtnClick(Value)
    if  (Value < 0 and self.CurShowIndex <= 1) then
        self.CurShowIndex = self.DataListSize
    elseif(Value > 0 and self.CurShowIndex>= self.DataListSize) then
        self.CurShowIndex = 1
    else
        self.CurShowIndex = self.CurShowIndex + Value
    end
    local Data = self.SkinDataList[self.CurShowIndex]
    self.SkinId = Data[Cfg_HeroSkin_P.SkinId]

    self:UpdateShowAvator(self.SkinId)
end

--[[
    更新左右箭头展示
]]
function M:UpdateArrowShow()
    if self.CurShowIndex < 0 then
        self.GUIButton_Left:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.GUIButton_Right:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function M:OnEscClicked()
    MvcEntry:CloseView(self.viewId)
    return true
end

return M