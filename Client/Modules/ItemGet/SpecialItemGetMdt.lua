--[[
    特殊获取弹窗
]]

local class_name = "SpecialItemGetMdt";
SpecialItemGetMdt = SpecialItemGetMdt or BaseClass(GameMediator, class_name);

function SpecialItemGetMdt:__init()
end

function SpecialItemGetMdt:OnShow(data)
end

function SpecialItemGetMdt:OnHide()
end

-- 定义展示的特殊效果
SpecialItemGetMdt.EffectType = {
    Text = 1,   -- 提示文本
}

-- 定义展示的特殊效果
SpecialItemGetMdt.LSType = {
    Cam = 1,   -- 摄像机移动(废弃)
    Background = 2, --背景LS
    Hero = 3, --AvatarLS
    Gun = 4, --武器LS
    Vehicle = 7, --载具LS
    Ultra = 5, --特效预览(金色)
    Epic = 6 --特效预览(紫色)
}

SpecialItemGetMdt.LSPathDef = { --绑定配置的LSId
    [SpecialItemGetMdt.LSType.Hero] = HallLSCfg.LS_SPECIAL_CAM_CHAR.HallLSId,
    [SpecialItemGetMdt.LSType.Gun] = HallLSCfg.LS_SPECIAL_CAM_GUN.HallLSId,
    [SpecialItemGetMdt.LSType.Vehicle] = HallLSCfg.LS_SPECIAL_CAM_CAR.HallLSId,
    [SpecialItemGetMdt.LSType.Ultra] = {
        [SpecialItemGetMdt.LSType.Hero] = HallLSCfg.LS_SPECIAL_EFFICT_ULTRA_Hero.HallLSId,
        [SpecialItemGetMdt.LSType.Vehicle] = HallLSCfg.LS_SPECIAL_EFFICT_ULTRA_Car.HallLSId,
        [SpecialItemGetMdt.LSType.Gun] = HallLSCfg.LS_SPECIAL_EFFICT_ULTRA_Gun.HallLSId

    },
    [SpecialItemGetMdt.LSType.Epic] = {
        [SpecialItemGetMdt.LSType.Hero] = HallLSCfg.LS_SPECIAL_EFFICT_EPIC_Hero.HallLSId,
        [SpecialItemGetMdt.LSType.Vehicle] = HallLSCfg.LS_SPECIAL_EFFICT_EPIC_Car.HallLSId,
        [SpecialItemGetMdt.LSType.Gun] = HallLSCfg.LS_SPECIAL_EFFICT_EPIC_Gun.HallLSId
    }
}

SpecialItemGetMdt.CameraCfgIndex = {
    Hero = 9000,
    Gun = 9001,
    Vehicle = 9002,
}

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = {
		{ UDelegate = self.WBP_CommonBtn_Tips.GUIButton_Main.OnHovered,				Func = self.ShowEquippedTips },
		{ UDelegate = self.WBP_CommonBtn_Tips.GUIButton_Main.OnUnhovered,				Func = self.HideEquippedTips },
        { UDelegate = self.OnAnimationFinished_vx_commonpopup_special_01,	Func = self.On_vx_commonpopup_special_01_Finished },
        { UDelegate = self.OnAnimation_pre_in_event,	Func = self.On_OnAnimation_pre_in_event_func },
        { UDelegate = self.OnAnimation_pre_in_do_show_info_panel,	Func = self.OnAnimation_pre_in_do_show_info_panel_func }
    }
	self.MsgList = 
    {
        {Model = InputModel, MsgName = InputModel.ON_BEGIN_TOUCH,	Func = self.OnInputBeginTouch },
		{Model = InputModel, MsgName = InputModel.ON_END_TOUCH,		Func = self.OnInputEndTouch },
		{Model = HeroModel, MsgName = HeroModel.ON_HERO_LIKE_SKIN_CHANGE,		Func = self.OnEquipped },
		{Model = WeaponModel, MsgName = WeaponModel.ON_SELECT_WEAPON_SKIN,		Func = self.OnEquipped },
		{Model = VehicleModel, MsgName = VehicleModel.ON_SELECT_VEHICLE_SKIN,		Func = self.OnEquipped },
        {Model = HallModel, MsgName = HallModel.ON_SPECIAL_POP_LINE_EVENT,		Func = self.OnSpecialPopEvent}
        
    }
    -- 继续按钮
    UIHandler.New(self,self.WBP_CommonBtn_Continue, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.SpaceBar,
        OnItemClick = Bind(self,self.OnShowNext),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot", "Lua_SpecialItemGetMdt_Continue_Btn"),
    })

    -- 装备按钮
    self.EquipBtn = UIHandler.New(self,self.WBP_CommonBtn_Equip, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_E,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.E,
        OnItemClick = Bind(self,self.OnDoEquip),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot", "Lua_SpecialItemGetMdt_Equip_Btn"),
    }).ViewInstance
    self.WBP_CommonBtn_Equip:SetVisibility(UE.ESlateVisibility.Collapsed)

    --通用Touch输入
	UIHandler.New(self, self.WBP_Common_TouchInput, CommonTouchInput, 
    {})
    self.WBP_Common_TouchInput:SetVisibility(UE.ESlateVisibility.Collapsed)

    self.HeroModel = MvcEntry:GetModel(HeroModel)
    self.WeaponModel = MvcEntry:GetModel(WeaponModel)
    self.VehicleModel = MvcEntry:GetModel(VehicleModel)

    -- 展示的英雄/武器/载具id
    self.ShowItemId = 0
    -- 皮肤所属物品id
    self.OriginItemId = 0
    -- 当前已装备id
    self.EquippedId = 0

    self.DecomposeIconCls = nil
end


--[[
    Param = {
        ShowList = SpecialShowList, -- 特殊奖励的展示列表
        PopUpEffectId = PopUpEffectId,
        CloseCallback = ShowCommonItemGet,  -- 界面关闭回调
    }
]]
function M:OnShow(Param)
    if not (Param and Param.ShowList) or #Param.ShowList == 0 then
        CError("SpecialItemGetMdt OnShow Param Error !",true)
        self:OnEscClicked()
        return
    end
    MvcEntry:GetModel(HallModel):DispatchType(HallModel.SET_TEAMANDCHAT_VISIBLE,false)
    self.ShowList = Param.ShowList
    self.PopUpEffectId = Param.PopUpEffectId
    self.CloseCallback = Param.CloseCallback
    self.CurShowIndex = 1
    self:ShowViewInit()
end

function M:ShowViewInit()
    self.Common_Bottom_Bar:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Panel_SpecialTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PanelItemInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.VX_Light:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:DoShowItem()
    self:UpdateShowAvatar()
end

function M:PlayViewOpenEffect()
    if self.ItemType == Pb_Enum_ITEM_TYPE.ITEM_PLAYER and not self.IsSkin then
        self.VX_Text_OriginItemName:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.VXE_CommonPupup_Special_PreIn then
        self:VXE_CommonPupup_Special_PreIn()
    end
end

function M:PlayItemGetEffect()
    self.VX_Light:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.VXE_CommonPupup_Special_In then
        self:VXE_CommonPupup_Special_In()
    end
end

--[[
    实现右下角按钮和左上角信息页同步显示
]]
function M:OnAnimation_pre_in_do_show_info_panel_func()
    self.Common_Bottom_Bar:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.ShowItem and self.ShowItem.DecomposeInfo then
        self.Panel_DecomposeInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self:PopUpEffect()
end


function M:On_OnAnimation_pre_in_event_func()
    self:PlayLS()
end


function M:On_vx_commonpopup_special_01_Finished()
    --self:PlayLS()
end

function M:PlayLS()
    self.CurShowAvatar:Show(true, self.SkinId)
    if self.ItemType == Pb_Enum_ITEM_TYPE.ITEM_PLAYER then
        self:PlayHeroLS()
    elseif self.ItemType == Pb_Enum_ITEM_TYPE.ITEM_WEAPON then
        self:SetCameraFocalLength(SpecialItemGetMdt.CameraCfgIndex.Gun, UE.UGameHelper.GetCurrentSceneCamera())
        self:PlayEffectLSAnim(SpecialItemGetMdt.LSType.Gun)
    else
        self:SetCameraFocalLength(SpecialItemGetMdt.CameraCfgIndex.Vehicle, UE.UGameHelper.GetCurrentSceneCamera())
        self:PlayEffectLSAnim(SpecialItemGetMdt.LSType.Vehicle)
    end
end


function M:OnHide()
    MvcEntry:GetModel(HallModel):DispatchType(HallModel.SET_TEAMANDCHAT_VISIBLE,true)
end

function M:OnRepeatShow(Param)
    -- 打开期间又收到了 拼接到列表后面
    if not (Param and Param.ShowList) or #Param.ShowList == 0 then
        CError("SpecialItemGetMdt OnRepeatShow Param Error !",true)
        return
    end
    table.listmerge(self.ShowList,Param.ShowList)
end

-- 具体特殊奖励展示逻辑
--[[
    ShowItem = {
        ItemId = 1,                                             --【*必填*】物品ID
        ItemNum = 1,                                            --【*必填*】物品数量
        DecomposeInfo = {                                       --【可选】如果这个物品包含分解信息，则在这里指明
            ItemId = 1,                                         --【可选】分解之后的物品id
            ItemNum = 1,                                        --【可选】分解之后的物品数量
        }
    }
]]
function M:DoShowItem()
    local ShowItem = self.ShowList[self.CurShowIndex]
    self.ShowItem = ShowItem
    if not ShowItem then
        CError("SpecialItemGetMdt DoShowItem Error,Index = "..self.CurShowIndex,true)
        self:OnEscClicked()
        return
    end

    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ShowItem.ItemId)
    if not ItemCfg then
        CError("SpecialItemGetMdt ItemCfg Error ! Id = "..ShowItem.ItemId,true)
        self:OnEscClicked()
        return
    end
    self.ShowItemId = ShowItem.ItemId
    local ItemType = ItemCfg[Cfg_ItemConfig_P.Type]
    local ItemSubType = ItemCfg[Cfg_ItemConfig_P.SubType]
    self.ItemType = ItemType
    -- 标题文本
    local ItemTypeNameConfig = G_ConfigHelper:GetSingleItemByKeys(Cfg_ItemTypeNameConfig,{Cfg_ItemTypeNameConfig_P.Type,Cfg_ItemTypeNameConfig_P.SubType},{ItemType,ItemSubType})
    if ItemTypeNameConfig then
        self.Text_Title:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Text_Title:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot", "Lua_SpecialItemGetMdt_GetTitle"),ItemTypeNameConfig[Cfg_ItemTypeNameConfig_P.ShowName]))
    else
        self.Text_Title:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    -- 名称
    local Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
    self.Quality = Quality
    -- 背景板
    MvcEntry:GetModel(ItemGetModel):DispatchType(ItemGetModel.ON_SET_SPECIAL_GET_BG,Quality)
    self.Text_ItemName:SetText(ItemCfg[Cfg_ItemConfig_P.Name])
    CommonUtil.SetTextColorFromQuality(self.Text_ItemName,Quality)
    -- 品质角标
    CommonUtil.SetQualityCornerIconWithBg(self.GUIImage_Quality,Quality)
    -- 皮肤类型处理
    local ITEM_TYPE = Pb_Enum_ITEM_TYPE
    self.IsSkin = (ItemType == ITEM_TYPE.ITEM_PLAYER or ItemType == ITEM_TYPE.ITEM_WEAPON or ItemType == ITEM_TYPE.ITEM_VEHICLE) and ItemSubType == DepotConst.ItemSubType.Skin
    if self.IsSkin then
        self.Panel_SkinInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WBP_CommonBtn_Equip:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Text_OriginItemName:SetText(self:GetSkinOriginItemName(ShowItem.ItemId))
        self:UpdateEquipedInfo()
    else
        self.EquippedId = 0
        self.OriginItemId = 0
        self.Panel_SkinInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_CommonBtn_Equip:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    -- 分解
    if ShowItem.DecomposeInfo then
        --self.Panel_DecomposeInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local DecomposeItemId = ShowItem.DecomposeInfo.ItemId
        local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = DecomposeItemId,
            ItemNum = ShowItem.DecomposeInfo.ItemNum,
            ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
            HoverFuncType = CommonItemIcon.CLICK_FUNC_TYPE.TIP,
            ShowCount = true,
        }
        if not self.DecomposeIconCls then
            self.DecomposeIconCls = UIHandler.New(self, self.WBP_CommonItemIcon_Decompose, CommonItemIcon, IconParam).ViewInstance
        else
            self.DecomposeIconCls:UpdateUI(IconParam)
        end
        local DecomposeItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,DecomposeItemId)
        if DecomposeItemCfg then
            self.Text_DecomposeName:SetText(DecomposeItemCfg[Cfg_ItemConfig_P.Name])
            local Quality = DecomposeItemCfg[Cfg_ItemConfig_P.Quality]
            CommonUtil.SetTextColorFromQuality(self.Text_DecomposeName,Quality)
            local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
            if QualityCfg then
                CommonUtil.SetBrushTintColorFromHex(self.Image_DecomposeQuality,QualityCfg[Cfg_ItemQualityColorCfg_P.HexColor])
                CommonUtil.SetBrushTintColorFromHex(self.Image_DecomposeQualityBar,QualityCfg[Cfg_ItemQualityColorCfg_P.HexColor])
            end
        else
            self.Text_DecomposeName:SetText("")
        end
    else
        self.Panel_DecomposeInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    -- -- 特殊提示
    -- --self.Panel_SpecialTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- if self.PopUpEffectId and self.PopUpEffectId > 0 then
    --     local EffectCfg = G_ConfigHelper:GetSingleItemById(Cfg_SpecialGetEffectCfg,self.PopUpEffectId)
    --     if EffectCfg then
    --         local EffectType = EffectCfg[Cfg_SpecialGetEffectCfg_P.EffectType]
    --         if EffectType == SpecialItemGetMdt.EffectType.Text then
    --             self.Panel_SpecialTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --             self.Text_Time:SetText(EffectCfg[Cfg_SpecialGetEffectCfg_P.Des])
    --         end
    --     end
    -- end
    
    if self.VXE_CommonPopUp_QualityColor then
        self:VXE_CommonPopUp_QualityColor()
    end
end

function M:PopUpEffect()
    if self.PopUpEffectId and self.PopUpEffectId > 0 then
        local EffectCfg = G_ConfigHelper:GetSingleItemById(Cfg_SpecialGetEffectCfg,self.PopUpEffectId)
        if EffectCfg then
            local EffectType = EffectCfg[Cfg_SpecialGetEffectCfg_P.EffectType]
            if EffectType == SpecialItemGetMdt.EffectType.Text then
                self.Panel_SpecialTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                self.Text_Time:SetText(EffectCfg[Cfg_SpecialGetEffectCfg_P.Des])
            end
        end
    end
end


-- 获取皮肤所属的物品名称
function M:GetSkinOriginItemName(ItemId)
    self.OriginItemId = 0
    local OriginItemName = ""
    local ItemType = self.ItemType
    local ITEM_TYPE = Pb_Enum_ITEM_TYPE
    if ItemType == ITEM_TYPE.ITEM_PLAYER then
        local HeroSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.ItemId,ItemId)
        if HeroSkinCfg then
            local HeroId = HeroSkinCfg[Cfg_HeroSkin_P.HeroId]
            self.OriginItemId = HeroId
            local HeroConfig = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,HeroId)
            if HeroConfig then
                OriginItemName = HeroConfig[Cfg_HeroConfig_P.Name]
            end
        end
    elseif ItemType == ITEM_TYPE.ITEM_WEAPON then
        local WeaponSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.ItemId,ItemId)
        if WeaponSkinCfg then
            local WeaponId = WeaponSkinCfg[Cfg_WeaponSkinConfig_P.WeaponId]
            self.OriginItemId = WeaponId
            local WeaponCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponConfig,WeaponId)
            if WeaponCfg then
                OriginItemName = MvcEntry:GetModel(DepotModel):GetItemName(WeaponCfg[Cfg_WeaponConfig_P.ItemId])
            end
        end
    elseif ItemType == ITEM_TYPE.ITEM_VEHICLE then
        local VehicleSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig,Cfg_VehicleSkinConfig_P.ItemId,ItemId)
        if VehicleSkinCfg then
            local VehicleId = VehicleSkinCfg[Cfg_VehicleSkinConfig_P.VehicleId]
            self.OriginItemId = VehicleId
            local VehicleCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleConfig,VehicleId)
            if VehicleCfg then
                OriginItemName = VehicleCfg[Cfg_VehicleConfig_P.Name]
            end
        end
    end
    return OriginItemName
end

-- 更新已装备信息
function M:UpdateEquipedInfo()
    if self.OriginItemId == 0 then
        CWaring("UpdateEquipedInfo OriginItemId is 0!")
        return
    end
    self.EquippedId = 0
    local ItemType = self.ItemType
    local IsVec = false -- Tips是否竖向展示
    local ITEM_TYPE = Pb_Enum_ITEM_TYPE
    if ItemType == ITEM_TYPE.ITEM_PLAYER then
        IsVec = true
        self.EquippedId = self.HeroModel:GetFavoriteSkinIdByHeroId(self.OriginItemId)
    elseif ItemType == ITEM_TYPE.ITEM_WEAPON then
        self.EquippedId = self.WeaponModel:GetWeaponSelectSkinId(self.OriginItemId)
    elseif ItemType == ITEM_TYPE.ITEM_VEHICLE then
        self.EquippedId = self.VehicleModel:GetVehicleSelectSkinId(self.OriginItemId)
    end
    if self.EquippedId == 0 then
        return
    end
    self.WidgetSwitcher_TipsContent:SetActiveWidget(IsVec and self.TipsContent_Vec or self.TipsContent_Hor)
    if IsVec then
        local EquippedSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin, self.EquippedId)
        if not EquippedSkinCfg then
            return
        end
        -- 已装备皮肤名称
        self.Text_EquipmentName:SetText(EquippedSkinCfg[Cfg_HeroSkin_P.SkinName])
        -- 已装备皮肤图片
        CommonUtil.SetBrushFromSoftObjectPath(self.Img_Icon_Vec, EquippedSkinCfg[Cfg_HeroSkin_P.HalfBodyBGPNGPath])
        -- 已装备皮肤品质
        local EquippedSkinItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,EquippedSkinCfg[Cfg_HeroSkin_P.ItemId])
        if EquippedSkinItemCfg then
            self.Img_Quality_Vec:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            CommonUtil.SetQualityBgVertical(self.Img_Quality_Vec,EquippedSkinItemCfg[Cfg_ItemConfig_P.Quality])
        else
            self.Img_Quality_Vec:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        local ItemName = ""
        local ImgPath,ItemId = nil,nil
        if ItemType == ITEM_TYPE.ITEM_WEAPON then
            local EquippedSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, self.EquippedId)
            if EquippedSkinCfg then
                ItemName = EquippedSkinCfg[Cfg_WeaponSkinConfig_P.SkinName]
                ImgPath = EquippedSkinCfg[Cfg_WeaponSkinConfig_P.SkinListIcon]
                ItemId = EquippedSkinCfg[Cfg_WeaponSkinConfig_P.ItemId]
            end
        elseif ItemType == ITEM_TYPE.ITEM_VEHICLE then
            local EquippedSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinConfig, self.EquippedId)
            if EquippedSkinCfg then
                ItemName = EquippedSkinCfg[Cfg_VehicleSkinConfig_P.SkinName]
                ImgPath = EquippedSkinCfg[Cfg_VehicleSkinConfig_P.SkinListIcon]
                ItemId = EquippedSkinCfg[Cfg_VehicleSkinConfig_P.ItemId]
            end
        end
        -- 已装备皮肤名称
        local Param = {
            ItemId = self.EquippedId,
            ItemName = ItemName
        }
        CommonUtil.SetCommonName(self.WBP_Common_Name,Param)
        -- 已装备皮肤图片
        if ImgPath then
            self.Img_Icon_Hor:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            CommonUtil.SetBrushFromSoftObjectPath(self.Img_Icon_Hor,ImgPath)
        else
            self.Img_Icon_Hor:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        -- 已装备皮肤品质
        if ItemId then
            local EquippedSkinItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
            if EquippedSkinItemCfg then
                self.Img_Quality_Hor:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                CommonUtil.SetQualityBgHorizontal(self.Img_Quality_Hor,EquippedSkinItemCfg[Cfg_ItemConfig_P.Quality])
            else
                self.Img_Quality_Hor:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        else
            self.Img_Quality_Hor:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    local EquipBtnTipsKey = self.EquippedId == self.ShowItemId and "Lua_SpecialItemGetMdt_EquippedTips" or "Lua_SpecialItemGetMdt_Equip_Btn"
    self.EquipBtn:SetTipsStr(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot",EquipBtnTipsKey))
end

----------------------------

function M:OnShowAvator()
    self:PlayViewOpenEffect()
end

function M:UpdateShowAvatar()
    if self.HallAvatarMgr == nil then
        local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
        if HallAvatarMgr == nil then
            return
        end  
        self.HallAvatarMgr = HallAvatarMgr
    end
    
    MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(tostring(self.viewId))
    if self.CurShowAvatar then
        self.HallAvatarMgr:ShowAvatarByViewID(self.viewId, false)
        self.CurShowAvatar = nil
    end
    local ItemType = self.ItemType
    local ITEM_TYPE = Pb_Enum_ITEM_TYPE
    if ItemType == ITEM_TYPE.ITEM_PLAYER then
        local HeroId,SkinId
        if self.IsSkin then
            HeroId = self.OriginItemId
            SkinId = self.ShowItemId
        else
            HeroId = self.ShowItemId
            SkinId = self.HeroModel:GetDefaultSkinIdByHeroId(HeroId)
        end
        self.SkinId = SkinId
        self:UpdateHeroAvatarShow(HeroId,SkinId)
        self.WBP_Common_TouchInput:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif ItemType == ITEM_TYPE.ITEM_WEAPON then
        local WeaponId,SkinId
        if self.IsSkin then
            WeaponId = self.OriginItemId
            SkinId = self.ShowItemId
        else
            WeaponId = self.ShowItemId
            SkinId = self.WeaponModel:GetWeaponDefaultSkinId(WeaponId)
        end
        self.SkinId = SkinId
        self:UpdateWeaponAvatarShow(WeaponId,SkinId)
        self.WBP_Common_TouchInput:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif ItemType == ITEM_TYPE.ITEM_VEHICLE then
        self:SetTranslucencyReflectionsFrontLayer(true)  --载具类型需开启，开启后，半透模型会在上层
        local VehicleId,SkinId
        if self.IsSkin then
            VehicleId = self.OriginItemId
            SkinId = self.ShowItemId
        else
            VehicleId = self.ShowItemId
            SkinId = self.VehicleModel:GetVehicleDefaultSkinId(VehicleId)
        end
        self.SkinId = SkinId
        self:UpdateVehicleAvatarShow(VehicleId,SkinId)
        self.WBP_Common_TouchInput:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self.CurShowAvatar:Show(false)
end

-- 更新英雄模型
function M:UpdateHeroAvatarShow(HeroId,SkinId)
    if not HeroId or not SkinId then
        return
    end
    self.AvatarShowType = HallAvatarMgr.AVATAR_HERO
    local TheTrans = CommonUtil.GetShowTranByItemID(ETransformModuleID.Speical_Get.ModuleID,self.ShowItemId)
    local SpawnHeroParam = {
        ViewID = self.viewId,
        InstID = 0,
        HeroId = HeroId,
        SkinID = SkinId,
        Location = TheTrans.Pos,
        Rotation = TheTrans.Rot,
		Scale = TheTrans.Scale,
    }

    self.HeroId = HeroId

    self.CurShowAvatar = self.HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    -- self.HallAvatarMgr:HideAvatarByViewID(self.viewId)
    self.CurShowAvatar:SetSkeleMeshRenderStencilState(1)
end

--[[
    HeroLS
]]
function M:PlayHeroLS()
    local TheTrans = CommonUtil.GetShowTranByItemID(ETransformModuleID.Speical_Get.ModuleID, self.ShowItemId)

    local SpawnHeroParam = {
        ViewID = self.viewId,
        InstID = 0,
        HeroId = self.HeroId,
        SkinID = self.SkinId,
        Location = TheTrans.Pos,
        Rotation = TheTrans.Rot,
		Scale = TheTrans.Scale,
    }

    --self.CurShowAvatar = self.HallAvatarMgr:ShowAvatar(self.AvatarShowType and self.AvatarShowType or HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    if self.CurShowAvatar then
        self.CurShowAvatar:OpenOrCloseCameraAction(false)
        self.CurShowAvatar:OpenOrCloseAvatorRotate(false)

        -- 此AnimClip取值
        local AniClipPath = self.HeroModel:GetAnimClipPathBySkinIdAndKey(self.SkinId, HeroModel.LSEventTypeEnum.IdleDefault)
        self.CurShowAvatar:PlayAnimClip(AniClipPath, true)
        local SetBindings = {
            {
                ActorTag = "", --如场景中静态放置的可用tag搜索出Actor
                Actor = self.CurShowAvatar:GetSkinActor(), 
                TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM,
            },
            {
                ActorTag = "",
                Actor = self.CurShowAvatar:GetSkinActor(), 
                TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_COMPONENT,
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

        local LevelSequenceAsset, IsEnablePostProcess = self.HeroModel:GetSkinLSPathBySkinIdAndKey(self.SkinId, HeroModel.LSEventTypeEnum.LSPathHeroMainLS)
        local PlayParam = {
            LevelSequenceAsset = LevelSequenceAsset,
            SetBindings = SetBindings,
            TransformOrigin = self.CurShowAvatar:GetTransform(),
            IsEnablePostProcess = IsEnablePostProcess,
            UseCacheSequenceActorByTag = true,
            RestoreState = false,
            WaitUtilActorHasBeenPrepared = true,
            ForceStopAfterFinish = true
        }

        self:SetCameraFocalLength(SpecialItemGetMdt.CameraCfgIndex.Hero, CameraActor)
        self:PlayEffectLSAnim(SpecialItemGetMdt.LSType.Hero)

        MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("CameraLSPopHero", function ()
            -- todo
            if self.CurShowAvatar then
                self.CurShowAvatar:OpenOrCloseAvatorRotate(true)
                self.CurShowAvatar:SetCapsuleComponentSize(400, 300)
                if self.ItemType == Pb_Enum_ITEM_TYPE.ITEM_PLAYER then
                    self.CurShowAvatar:SetSkeleMeshRenderStencilState(0)
                end
            end
            --self:PlayItemGetEffect()
        end, PlayParam)
    end
end

-- 更新武器模型
function M:UpdateWeaponAvatarShow(WeaponId,SkinId)
    if not WeaponId or not SkinId then
        return
    end
    local TheTrans = CommonUtil.GetShowTranByItemID(ETransformModuleID.Speical_Get.ModuleID,self.ShowItemId)
    local SpawnParam = {
		ViewID = self.viewId,
		InstID = 0,
		WeaponID = WeaponId,
		SkinID = SkinId,
		Location = TheTrans.Pos,
        Rotation = TheTrans.Rot,
		Scale = TheTrans.Scale,
		ForbidUseRelativeTransform = false,
		UserSelectPartCache = true,
	}
    self.CurShowAvatar = self.HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_WEAPON, SpawnParam)
    if self.CurShowAvatar ~= nil then
		self.CurShowAvatar:OpenOrCloseCameraMoveAction(false)
		self.CurShowAvatar:OpenOrCloseAvatorRotate(true)
		self.CurShowAvatar:OpenOrCloseGestureAction(true)
        self.CurShowAvatar:OpenOrCloseCameraAction(false)
        
    end

    print_r(SpawnParam, "========SpawnParam==========")
end

-- 更新载具模型
function M:UpdateVehicleAvatarShow(VehicleId,SkinId)
    if not VehicleId or not SkinId then
        return
    end
    local TheTrans = CommonUtil.GetShowTranByItemID(ETransformModuleID.Speical_Get.ModuleID,self.ShowItemId)
    local SpawnParam = {
		ViewID = self.viewId,
		InstID = 0,
		VehicleID = VehicleId,
		SkinID = SkinId,
		Location = TheTrans.Pos,
        Rotation = TheTrans.Rot,
		Scale = TheTrans.Scale,
		-- IsTransformOverrideBySkin = true,
		-- OpenCheckCameraSpringArm = true,
	}
    self.CurShowAvatar = self.HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_VEHICLE, SpawnParam)
    if self.CurShowAvatar ~= nil then				
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnParam.Location, 
        SpawnParam.Rotation, SpawnParam.Scale)
        self.CurShowAvatar:SetTransformInLua(SpawnTrans)
		-- self.CurShowAvatar:CheckCameraSpringArm()
		self.CurShowAvatar:OpenOrCloseCameraMoveAction(false)
		self.CurShowAvatar:OpenOrCloseAvatorRotate(true)
		self.CurShowAvatar:OpenOrCloseGestureAction(true)
		self.CurShowAvatar:OpenOrCloseAutoRotateAction(false)
		self.CurShowAvatar:OpenOrCloseCameraTranslation(false)
		-- --重置位置
		--self.CurShowAvatar:ResetCameraSpringArmRotation()
		--self.CurShowAvatar:SetCameraFocusTracking()	
    end
    --self.PanelItemInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function M:PlayEffectLSAnim(InType)
    local PlayUltraParam = {
        LevelSequenceAsset = self.Quality < 4 and MvcEntry:GetModel(HallModel):GetLSPathById(SpecialItemGetMdt.LSPathDef[SpecialItemGetMdt.LSType.Epic][InType]) or MvcEntry:GetModel(HallModel):GetLSPathById(SpecialItemGetMdt.LSPathDef[SpecialItemGetMdt.LSType.Ultra][InType]),
        SetBindings = {},
    }

    self:PlayCameraLS(InType)

    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(tostring(self.viewId), function ()
        self.PanelItemInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end, PlayUltraParam)
end

--[[
    播放摄像机LS
]]
function M:PlayCameraLS(InLSType, InCallBack)
    --播放镜头动画
    local SetBindings = {}
    local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
    if CameraActor ~= nil then
        local CameraBinding = {
            ActorTag = "",
            Actor = CameraActor, 
            TargetTag = SequenceModel.BindTagEnum.CAMERA,
        }
        table.insert(SetBindings, CameraBinding)
    end
    local Transform = CameraActor:GetTransform().Translation--self.CurShowAvatar:GetTransform().Translation
    local Rotation = UE.FRotator(0, 0, 0)
    local Scale = UE.FVector(1.0, 1.0, 1.0)
    local TargetTranform = UE.UKismetMathLibrary.MakeTransform(Transform, Rotation, Scale)

    self.LsOriginTargetTranform = self.CurShowIndex == 1 and TargetTranform or self.LsOriginTargetTranform

    local PlayParam = {
        LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(SpecialItemGetMdt.LSPathDef[InLSType]),
        SetBindings = SetBindings,
        TransformOrigin = self.LsOriginTargetTranform,
    }

    local IsSpecailPickHeroToHiden = InLSType ~= SpecialItemGetMdt.LSType.Vehicle
    CommonUtil.SetActorHiddenByTag("Specail_PickHero", IsSpecailPickHeroToHiden)

    MvcEntry:GetCtrl(SequenceCtrl):StopAllSequences()
    
    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("CameraLSPopSpecialGet", function ()
        -- CWaring("FavorablityMainMdt:PlaySequenceByTag Suc")
        if InCallBack then
            InCallBack()
        end
    end, PlayParam)
end

function M:OnHideAvator()
    MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(tostring(self.viewId))
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr ~= nil then
		HallAvatarMgr:HideAvatarByViewID(self.viewId)
	end
end

function M:OnInputBeginTouch()
    if self.ItemType ~= Pb_Enum_ITEM_TYPE.ITEM_VEHICLE then
        return
    end
	self.IsTouched = true
end

function M:OnInputEndTouch()
    if self.ItemType ~= Pb_Enum_ITEM_TYPE.ITEM_VEHICLE then
        return
    end
	self.IsTouched = false
end

----------------------------

-- 展示已装备
function M:ShowEquippedTips()
    if self.EquippedId == 0 then
        return
    end
    self.Panel_Tips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

-- 隐藏已装备
function M:HideEquippedTips()
    if self.EquippedId == 0 then
        return
    end
    self.Panel_Tips:SetVisibility(UE.ESlateVisibility.Collapsed)
end

-- 继续展示下一个特殊奖励，没有下一个则关闭界面
function M:OnShowNext()
    if self.CurShowIndex == #self.ShowList then
        self:OnEscClicked()
    else
        self.CurShowIndex = self.CurShowIndex + 1
        -- self:DoShowItem()
        -- self:UpdateShowAvatar()
        -- self:PlayLS()
        self:PlayViewOpenEffect()
        self:ShowViewInit()
    end
end

-- 装备当前奖励
function M:OnDoEquip()
    if not self.IsSkin then
        return
    end
    if not (self.ShowItemId and self.OriginItemId) then
        return
    end
    if MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.ShowItemId) == 0 then
        CLog("OnDoEquip Item Not Unlock!")
        return
    end

    local ItemType = self.ItemType
    local ITEM_TYPE = Pb_Enum_ITEM_TYPE
    if ItemType == ITEM_TYPE.ITEM_PLAYER then
        -- 检测是否已解锁英雄
        if not self.HeroModel:CheckGotHeroById(self.OriginItemId) then
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_SpecialItemGetMdt_HeroLockTips"))
            return
        end
        if self.HeroModel:GetFavoriteSkinIdByHeroId(self.OriginItemId) == self.ShowItemId then
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_SpecialItemGetMdt_EquippedTips"))
            return
        end
        -- 为英雄装备自己想要的皮肤
        MvcEntry:GetCtrl(HeroCtrl):SendProto_SelectHeroSkinReq(self.OriginItemId,self.ShowItemId)
        -- 触发红点消除
        MvcEntry:GetCtrl(RedDotCtrl):Interact("TabHeroSkinItem_", self.ShowItemId)
    elseif ItemType == ITEM_TYPE.ITEM_WEAPON then
        if self.WeaponModel:GetWeaponSelectSkinId(self.OriginItemId) == self.ShowItemId then
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_SpecialItemGetMdt_EquippedTips"))
            return
        end
        MvcEntry:GetCtrl(ArsenalCtrl):SendProto_SelectWeaponSkinReq(self.OriginItemId,self.ShowItemId)
        -- 触发红点消除
        MvcEntry:GetCtrl(RedDotCtrl):Interact("ArsenalWeaponSkinItem_", self.ShowItemId)
    elseif ItemType == ITEM_TYPE.ITEM_VEHICLE then
        if self.VehicleModel:GetVehicleSelectSkinId(self.OriginItemId) == self.ShowItemId then
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_SpecialItemGetMdt_EquippedTips"))
            return
        end
        MvcEntry:GetCtrl(ArsenalCtrl):SendProto_SelectVehicleSkinReq(self.OriginItemId,self.ShowItemId)
        -- 触发红点消除
        MvcEntry:GetCtrl(RedDotCtrl):Interact("ArsenalVehicleSkinItem_", self.ShowItemId)
    end
end

function M:OnEquipped()
    -- 判断当前展示的是皮肤才弹提示（如果是非皮肤，在获得的时候，服务器会推送选中默认皮肤，也会收到这个事件
    if self.IsSkin then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_SpecialItemGetMdt_EquippedTips"))
        self:UpdateEquipedInfo()
    end
end

function M:OnEscClicked()
    if self.ItemType == Pb_Enum_ITEM_TYPE.ITEM_VEHICLE then
        self:SetTranslucencyReflectionsFrontLayer(false)
    end
    MvcEntry:CloseView(self.viewId)
    if self.CloseCallback then
        -- CB会打开ItemGet.等ItemGet关闭再检测
        self.CloseCallback()
    else
        -- 检测是否还有奖励展示
        MvcEntry:GetCtrl(ItemGetCtrl):CheckHaveItemGetNeedToShow()
    end
end

function M:OnSpecialPopEvent()
    self:PlayItemGetEffect()
end

function M:SetCameraFocalLength(InCameraIndex, InCameraActor)
    local CameraConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_HallCameraConfig, Cfg_HallCameraConfig_P.CameraID, InCameraIndex)
    if CameraConfig == nil then
        return
    end

    local CineCameraComponent = InCameraActor:GetCineCameraComponent()
    CineCameraComponent:SetCurrentFocalLength(CameraConfig[Cfg_HallCameraConfig_P.CurrentFocalLength])
end

--[[
    开关半透反射
]]
function M:SetTranslucencyReflectionsFrontLayer(InOnShow)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, StringUtil.FormatSimple("r.Lumen.TranslucencyReflections.FrontLayer.Allow {0}", InOnShow and "1" or "0"), PlayerController)
    UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, StringUtil.FormatSimple("r.Lumen.TranslucencyReflections.FrontLayer.Enable {0}", InOnShow and "1" or "0"), PlayerController)
end

return M
