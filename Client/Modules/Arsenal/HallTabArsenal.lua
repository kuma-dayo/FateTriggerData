--[[
    大厅 - 切页 - 战备
]]

local class_name = "HallTabArsenal"
local HallTabArsenal = BaseClass(UIHandlerViewBase, class_name)

local WEAPON_ENTRY = {
    Weapon = 1,
    Vehicle = 2,
    Parachute = 3,
    Lock = 99,
}

function HallTabArsenal:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.MsgList = 
    {
		-- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = Bind(self,self.OnEscClicked) },
        {Model = WeaponModel, MsgName = WeaponModel.ON_SELECT_WEAPON,	Func = Bind(self, self.OnUpdateSelectWeapon) },
        {Model = WeaponModel, MsgName = WeaponModel.ON_SELECT_WEAPON_SKIN,	Func = Bind(self, self.OnUpdateSelectWeapon) },
        {Model = VehicleModel, MsgName = VehicleModel.ON_SELECT_VEHICLE,	Func = Bind(self, self.OnUpdateSelectVehicleAvatar) },
        {Model = VehicleModel, MsgName = VehicleModel.ON_SELECT_VEHICLE_SKIN,	Func = Bind(self, self.OnUpdateSelectVehicleAvatar) },
	}
    self:InitCommonUI()
	self.View.WBP_ReuseList.OnUpdateItem:Add(self.View, Bind(self,self.OnUpdateItem))

    self.TheVehicleModel = MvcEntry:GetModel(VehicleModel)
    self.TheWeaponModel =  MvcEntry:GetModel(WeaponModel)
    self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
    self.PlaySequenceByTagQuene = nil

    -- 入口红点item列表
    self.EntryRedDotItemList = {}
end

function HallTabArsenal:InitCommonUI()
    -- 此页签内子类的列表，用于Show/Hide时，注册和销毁监听的事件
    -- self.SubClassList = {}
     
    local Btn = UIHandler.New(self,self.View.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
    }).ViewInstance
    -- self.SubClassList[#self.SubClassList + 1] = Btn
end


function HallTabArsenal:GetViewKey()
    return ViewConst.Hall*100 + CommonConst.HL_ARSENAL
end

--[[
    Param = {
    }
]]
function HallTabArsenal:OnShow(Param)
    self:UpdateUI(Param)
    SoundMgr:PlaySound(SoundCfg.Music.MUSIC_WEAPON)
end

function HallTabArsenal:OnManualShow(Param)
    SoundMgr:PlaySound(SoundCfg.Music.MUSIC_WEAPON)
    self.PlaySequenceByTagQuene = nil
end

function HallTabArsenal:OnHide()
    self.View.WBP_ReuseList.OnUpdateItem:Clear()
end

-- -- 由 CommonHallTab 控制调用，显示当前页签时调用，重新注册监听事件
-- function HallTabArsenal:OnCustomShow()
--     if self.IsHide then 
--         if self.MsgList then
--             CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,true)
--         end
--         if self.SubClassList then
--             for _,Btn in ipairs(self.SubClassList) do
--                 CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,true)
--             end
--         end
--         self.IsHide = false
--     end
--     SoundMgr:PlaySound(SoundCfg.Music.MUSIC_WEAPON)
-- end

-- -- 由 CommonHallTab 控制调用，隐藏当前页签时调用，销毁监听事件
-- function HallTabArsenal:OnCustomHide()
-- 	CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,false)
--     if self.SubClassList then
--         for _,Btn in ipairs(self.SubClassList) do
-- 		    CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,false)
--         end
--     end
--     self.IsHide = true
-- end

function HallTabArsenal:UpdateUI(Param)
    self:InitEntranceIcons()
end

-- 刷新入口列表
function HallTabArsenal:InitEntranceIcons()
    self.EntryList = {
        [1] = WEAPON_ENTRY.Weapon,
        [2] = WEAPON_ENTRY.Vehicle,
        [3] = WEAPON_ENTRY.Lock,
        [4] = WEAPON_ENTRY.Lock,
    }
    self.Entry2Index = {}
    for Index,EntryType in ipairs(self.EntryList) do
        self.Entry2Index[EntryType] = Index
    end
    self.View.WBP_ReuseList:Reload(#self.EntryList)
end

function HallTabArsenal:OnUpdateItem(_,Widget, Index)
    local FixIndex = Index  + 1
    local EntryType = self.EntryList[FixIndex]

    local ItemInfo = nil
    local Icon,Name,IsLock = nil,"",false
    if EntryType == WEAPON_ENTRY.Weapon then
        ItemInfo = self:GetWeaponEntranceInfo()
    elseif EntryType == WEAPON_ENTRY.Vehicle then
        ItemInfo = self:GetVehicleEntranceInfo()
    elseif EntryType == WEAPON_ENTRY.Lock then
        ItemInfo = self:GetLockEntranceInfo()
    end
    self:UpdateEntranceIcon(EntryType,Widget,ItemInfo)
    self:RegisterRedDot(EntryType,Widget, ItemInfo)
end

--武器入口
function HallTabArsenal:GetWeaponEntranceInfo()
    local SelectWeaponId = self.TheWeaponModel:GetSelectWeaponId()
    local SelectSkinWeaponId = self.TheWeaponModel:GetWeaponSelectSkinId(SelectWeaponId)
    local WSCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, SelectSkinWeaponId)
    if WSCfg ~= nil then 
        return {
            ItemId = WSCfg[Cfg_WeaponSkinConfig_P.ItemId],
            ItemIcon = WSCfg[Cfg_WeaponSkinConfig_P.SkinListIcon],
            ItemName = self.TheArsenalModel:GetArsenalText(10002),
            bCancelQuality = true,
            RedDotKey = "ArsenalWeapon",
            RedDotSuffix = "",
        }
    end
end

--载具入口
function HallTabArsenal:GetVehicleEntranceInfo()
    local SelectVehicleId = self.TheVehicleModel:GetSelectVehicleId()
    local SelectVehicleSkinId = self.TheVehicleModel:GetVehicleSelectSkinId(SelectVehicleId)
    local VSCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinConfig, SelectVehicleSkinId)
   if VSCfg ~= nil then 
        return {
            ItemId = VSCfg[Cfg_VehicleSkinConfig_P.ItemId],
            ItemIcon = VSCfg[Cfg_VehicleSkinConfig_P.SkinListIcon],
            ItemName = self.TheArsenalModel:GetArsenalText(10003),
            bCancelQuality = true,
            RedDotKey = "ArsenalVehicle",
            RedDotSuffix = "",
        }
   end
end


function HallTabArsenal:GetLockEntranceInfo()
    
end

-- 更新入口展示
function HallTabArsenal:UpdateEntranceIcon(EntryType, Widget, ItemInfo)
    local IsLock = ItemInfo == nil 
    Widget:SetVisibility(IsLock and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    if IsLock then 
        return 
    end
    CommonUtil.SetBrushFromSoftObjectPath(Widget.GUIImageSelectWeaponSkin,ItemInfo.ItemIcon)
    CommonUtil.SetCommonName(Widget.WBP_Common_Name, ItemInfo)
    
    Widget.GUIButtonItem.OnClicked:Clear()
    Widget.GUIButtonItem.OnHovered:Clear()
    Widget.GUIButtonItem.OnUnhovered:Clear()
    Widget.GUIButtonItem.OnPressed:Clear()
    Widget.GUIButtonItem.OnReleased:Clear()

    Widget.GUIButtonItem.OnClicked:Add(self.View,Bind(self,self.OnEntryClick,EntryType))
    Widget.GUIButtonItem.OnHovered:Add(self.View,Bind(self,self.OnEntryHovered,EntryType))
    Widget.GUIButtonItem.OnUnhovered:Add(self.View,Bind(self,self.OnEntryUnhovered,EntryType))
end

function HallTabArsenal:OnEntryClick(EntryType)
    if EntryType == WEAPON_ENTRY.Weapon then
        MvcEntry:OpenView(ViewConst.WeaponDetail)
    elseif EntryType == WEAPON_ENTRY.Vehicle then
        MvcEntry:OpenView(ViewConst.VehicleDetail)
    end
    local ViewParam = {
        ViewId = ViewConst.Hall,
        TabId = CommonConst.HL_ARSENAL .. "-" .. EntryType
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)

    self:InteractRedDot(EntryType)
end

function HallTabArsenal:OnEntryHovered(EntryType)
    if EntryType == WEAPON_ENTRY.Weapon then
        self:OpenOrCloseWeaponShine(true)
    elseif EntryType == WEAPON_ENTRY.Vehicle then
        self:OpenOrCloseVehilceShine(true)
    end
    -- if not self.IsTabClosing then
    --     self:PlayeCameraFocusLS(EntryType)
    -- end
end

function HallTabArsenal:OnEntryUnhovered(EntryType)
    if EntryType == WEAPON_ENTRY.Weapon then
        self:OpenOrCloseWeaponShine(false)
    elseif EntryType == WEAPON_ENTRY.Vehicle then
        self:OpenOrCloseVehilceShine(false)
    end
    -- if not self.IsTabClosing then
    --     self:PlayeCameraFocusLS()
    -- end
end


function HallTabArsenal:OnShowAvator(data)
    self.IsTabClosing = false
    self:ShowCharacterAvatar()
    self:ShowVehicleAvatar()
end

function HallTabArsenal:OnHideAvator(data)
    self.IsTabClosing = true
    self:HideCharacterAvatar()
    self:HideVehicleAvatar()
    MvcEntry:GetCtrl(SequenceCtrl):StopAllSequences()
end

function HallTabArsenal:ShowCharacterAvatar()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr == nil then
		return 
	end

    local CurSelectHeroId = MvcEntry:GetModel(HeroModel):GetFavoriteId()
    local CurSelectSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(CurSelectHeroId)
    if self.LastSelectCharacterSkinId ~= nil and self.LastSelectCharacterSkinId ~= 0 then
        HallAvatarMgr:HideAvatarByViewID(self:GetViewKey(), self.LastSelectCharacterSkinId)
    end
    self.LastSelectCharacterSkinId = CurSelectSkinId

    local TheTrans = CommonUtil.GetShowTranByItemID(ETransformModuleID.Arsenal_HallTabHero.ModuleID, CurSelectSkinId)
    local SpawnHeroParam = {
		ViewID = self:GetViewKey(),
		InstID = self:GetViewKey(),
		HeroId = CurSelectHeroId,
		SkinID = CurSelectSkinId,
        Location = TheTrans.Pos, -- UE.FVector(59999, -53, 0),
        Rotation = TheTrans.Rot,  -- UE.FRotator(0, 5, 0),
        Scale = TheTrans.Scale,
        DisablePostProgress = true
	}
    local HeroAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    if HeroAvatar ~= nil then 
        HeroAvatar:OpenOrCloseAvatorRotate(false)
        HeroAvatar:OpenOrCloseCameraAction(false)
        HeroAvatar:OpenOrCloseCameraMoveAction(false)
    end
    self.CurHeroAvatar = HeroAvatar

    --穿
    self:CharacterPutOnWeaponAvatar()
    self:OpenOrCloseWeaponShine(false)
end

function HallTabArsenal:HideCharacterAvatar()
    --脱
    self:CharacterTakeOffWeaponAvatar()

    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr ~= nil then
        local InstID = self:GetViewKey()
        HallAvatarMgr:HideAvatarByAvatarID(InstID)	
	end
end

function HallTabArsenal:ShowVehicleAvatar()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr == nil then
		return 
	end
    local SelectVehicleId = self.TheVehicleModel:GetSelectVehicleId()
    local SelectVehicleSkinId = self.TheVehicleModel:GetVehicleSelectSkinId(SelectVehicleId)
    if SelectVehicleSkinId == 0 then
        return
    end
    if self.LastSelectVehicleSkinId ~= nil and self.LastSelectVehicleSkinId ~= 0 then
        HallAvatarMgr:HideAvatarByViewID(self:GetViewKey(), self.LastSelectVehicleSkinId)
    end
    self.LastSelectVehicleSkinId = SelectVehicleSkinId

    local TheTrans = CommonUtil.GetShowTranByItemID(ETransformModuleID.Arsenal_HallTabVehicle.ModuleID, SelectVehicleSkinId)
    local SpawnVehicleParam = {
		ViewID = self:GetViewKey(),
		InstID = 0,
		VehicleID = SelectVehicleId,
		SkinID =  SelectVehicleSkinId,
        Location = TheTrans.Pos, --UE.FVector(59948,-277, 0),
        Rotation = TheTrans.Rot, --UE.FRotator(0, 137.5, 0),
        Scale = TheTrans.Scale,
	}
    local VehicleAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_VEHICLE, SpawnVehicleParam)
    if VehicleAvatar ~= nil then 
        VehicleAvatar:OpenOrCloseCameraAction(false)
        VehicleAvatar:OpenOrCloseAvatorRotate(false)
        VehicleAvatar:OpenOrCloseCameraMoveAction(false)
        VehicleAvatar:OpenOrCloseAutoRotateAction(false)
        --重置位置
        VehicleAvatar:K2_SetActorRotation(TheTrans.Rot, false)
		VehicleAvatar:K2_SetActorLocation(TheTrans.Pos, false, nil, false)
    end
    self.CurVehicleAvatar = VehicleAvatar
    self:OpenOrCloseVehilceShine(false)
end


function HallTabArsenal:HideVehicleAvatar()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr ~= nil then
        local SelectVehicleId = self.TheVehicleModel:GetSelectVehicleId()
        HallAvatarMgr:HideAvatarByAvatarID(self:GetViewKey(), SelectVehicleId)
	end
end

--穿戴武器
function HallTabArsenal:CharacterPutOnWeaponAvatar()
    local SelectWeaponId = self.TheWeaponModel:GetSelectWeaponId()
    local SelectSkinWeaponId = self.TheWeaponModel:GetWeaponSelectSkinId(SelectWeaponId)
    if SelectSkinWeaponId == 0 then
        return
    end

    if not self.CurHeroAvatar then
        return
    end
    local CurSelectHeroId = MvcEntry:GetModel(HeroModel):GetFavoriteId()
    local CurSelectSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(CurSelectHeroId)
    local WeaponMappingCfg = MvcEntry:GetModel(WeaponModel):GetWeaponAnimMappingCfg(SelectSkinWeaponId,CurSelectSkinId)
    if WeaponMappingCfg then
        self.CurHeroAvatar:PlayAnimClip(WeaponMappingCfg[Cfg_WeaponAnimMappingCfg_P.AnimClipIdle])
    end

    MvcEntry:GetModel(HallModel):DispatchType(
        HallModel.ON_HERO_PUTON_WEAPON, 
        {
            HeroInstID = self:GetViewKey(), 
            WeaponSkinID = SelectSkinWeaponId,
            AnimControl = true
        })
end

--脱掉武器
function HallTabArsenal:CharacterTakeOffWeaponAvatar()
    MvcEntry:GetModel(HallModel):DispatchType(
        HallModel.ON_HERO_TAKEOFF_WEAPON, 
        {
            HeroInstID =  self:GetViewKey(),
        })
end

function HallTabArsenal:UpdateSelectWeaponAvatar()
    local SelectWeaponId = self.TheWeaponModel:GetSelectWeaponId()
    local SelectWeaponSkinId = self.TheWeaponModel:GetWeaponSelectSkinId(SelectWeaponId)
    if SelectWeaponSkinId ~= 0 then
        self:CharacterPutOnWeaponAvatar()
    else
        self:CharacterTakeOffWeaponAvatar()
    end
end

function HallTabArsenal:UpdateSelectVehicleAvatar()
    local SelectVehicleId = self.TheVehicleModel:GetSelectVehicleId()
    local SelectVehicleSkinId = self.TheVehicleModel:GetVehicleSelectSkinId(SelectVehicleId)
    if SelectVehicleSkinId ~= 0 then
        self:ShowVehicleAvatar()
    else
        self:HideVehicleAvatar()
    end
end

--展示载具回调
function HallTabArsenal:OnUpdateSelectVehicleAvatar()
    self:UpdateSelectVehicleAvatar()
    local Index = self.Entry2Index[WEAPON_ENTRY.Vehicle]
    if Index and Index > 0 then
        self.View.WBP_ReuseList:RefreshOne(Index-1)
    end
end

--展示武器回调
function HallTabArsenal:OnUpdateSelectWeapon()
    self:UpdateSelectWeaponAvatar()
    local Index = self.Entry2Index[WEAPON_ENTRY.Weapon]
    if Index and Index > 0 then
        self.View.WBP_ReuseList:RefreshOne(Index-1)
    end
end

function HallTabArsenal:OnEscClicked()
    CommonUtil.SwitchHallTab(CommonConst.HL_PLAY)
end


--[[
	开启关闭车身扫光
]]
function HallTabArsenal:OpenOrCloseVehilceShine(Value)
    if self.CurVehicleAvatar == nil then
        return
    end
	local SkinActor = self.CurVehicleAvatar:GetSkinActor()
	if SkinActor == nil then
		return
	end
    self.TheArsenalModel:SwitchPostProcessVolume(1)
	local RootComponent = SkinActor:K2_GetRootComponent()
	local AllMeshComponents = RootComponent:GetChildrenComponents(true)
	local Num =  AllMeshComponents:Num()
	for i=1, Num do
		local MeshComponent = AllMeshComponents:Get(i)
		if MeshComponent and MeshComponent:Cast(UE.UMeshComponent) then
			if Value and MeshComponent ~= SkinActor.AO_Plane  then
                MeshComponent:SetGameplayStencilState(3)
			else
				MeshComponent:SetGameplayStencilState(0)
			end
		end	
	end
end


--[[
	开启关闭武器扫光
]]
function HallTabArsenal:OpenOrCloseWeaponShine(Value)    
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    local HallHero = HallAvatarMgr:GetHallAvatar(self:GetViewKey())
    if HallHero == nil then 
        return 
    end
    local SlotAvatarInfo = HallHero:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_MAINWEAPON)
    local WeaponAvatar = SlotAvatarInfo and SlotAvatarInfo.AvatarActor
    if WeaponAvatar == nil then
        return
    end
    self.TheArsenalModel:SwitchPostProcessVolume(1)
	local RootComponent = WeaponAvatar:K2_GetRootComponent()
	local AllMeshComponents = RootComponent:GetChildrenComponents(true)
	local Num =  AllMeshComponents:Num()
	for i=1, Num do
		local MeshComponent = AllMeshComponents:Get(i)
		if MeshComponent and MeshComponent:Cast(UE.UMeshComponent) then
			if Value then
                MeshComponent:SetGameplayStencilState(3)
			else
                MeshComponent:SetGameplayStencilState(0)
			end
		end	
	end
end

function HallTabArsenal:PlayeCameraFocusLS(EntryType)
    local LSParam = nil
    if EntryType == WEAPON_ENTRY.Vehicle then
        LSParam = {
            LSId = HallModel.LSTypeIdEnum.LS_ARSENAL_HALL_FOCUS_CAR,
            Tag = "CameraLS_Vehicle",
            FocusMethodSetting = {
                FocusMethod = UE.ECameraFocusMethod.Manual,
                ManualFocusDistance = 100000,
            },
            ManualFocusMethodSetting = true
        }
    elseif EntryType == WEAPON_ENTRY.Weapon then
        LSParam = {
            LSId = HallModel.LSTypeIdEnum.LS_ARSENAL_HALL_FOCUS_CHAR,
            Tag = "CameraLS_Character",
            FocusMethodSetting = {
                FocusMethod = UE.ECameraFocusMethod.Manual,
                ManualFocusDistance = 100000,
            },
            ManualFocusMethodSetting = true
        }
    else
        LSParam = {
            LSId = HallModel.LSTypeIdEnum.LS_ARSENAL_HALL,
            Tag = "CameraLS_Arsenal",
            FocusMethodSetting = {
                FocusMethod = UE.ECameraFocusMethod.Disable,
            },
            ManualFocusMethodSetting = false
        }
    end

    local Tag2Type = {
        ["CameraLS_Vehicle"] = WEAPON_ENTRY.Vehicle,
        ["CameraLS_Character"] = WEAPON_ENTRY.Weapon,
        ["CameraLS_Arsenal"] = nil,
    }

    if LSParam == nil then
        return
    end
    local LSPath = MvcEntry:GetModel(HallModel):GetLSPathById(LSParam.LSId)
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
            FocusMethodSetting = LSParam.FocusMethodSetting,
            ManualFocusMethodSetting = LSParam.ManualFocusMethodSetting,
            UseCacheSequenceActorByTag = true,
            RestoreState = false,
        }
        self.PlaySequenceByTagQuene = self.PlaySequenceByTagQuene or {}
        local QueneCount = 0
        for _, v in pairs(self.PlaySequenceByTagQuene) do
            if v then
                QueneCount = QueneCount + 1
            end
        end
        if QueneCount >= 1 then
            self.PendingSequence = LSParam.Tag
            return
        end

        self.PlaySequenceByTagQuene[LSParam.Tag] = true
        MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(LSParam.Tag, function ()
            self.PlaySequenceByTagQuene[LSParam.Tag] = false
            if self.PendingSequence == LSParam.Tag then
                self.PendingSequence = nil
                return
            end
            if self.PendingSequence then
                self:PlayeCameraFocusLS(Tag2Type[self.PendingSequence])
            end
        end, PlayParam)
    end
end

----------------------------------------------reddot >>
-- 绑定红点
function HallTabArsenal:RegisterRedDot(EntryType, Widget, ItemInfo)
    if Widget.WBP_RedDotFactory and ItemInfo and ItemInfo.RedDotKey then
        local RedDotKey = ItemInfo.RedDotKey
        local RedDotSuffix = ItemInfo.RedDotSuffix or ""
        local RedDotItem = self.EntryRedDotItemList[EntryType]
        if not RedDotItem then
            self.EntryRedDotItemList[EntryType] = UIHandler.New(self,  Widget.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        else
            RedDotItem:ChangeKey(RedDotKey, RedDotSuffix)
        end
    end
end

-- 红点触发逻辑
function HallTabArsenal:InteractRedDot(EntryType)
    if self.EntryRedDotItemList[EntryType] then
        self.EntryRedDotItemList[EntryType]:Interact()
    end
end
----------------------------------------------reddot >>


return HallTabArsenal
