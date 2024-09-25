local class_name = "HeroSkinListItem"
local HeroSkinListItem = BaseClass(nil, class_name)


function HeroSkinListItem:OnInit()
    self.MsgList = {
		{Model = HeroModel, MsgName = HeroModel.ON_HERO_LIKE_SKIN_CHANGE,	Func = Bind(self,self.UpdateSkinStateShow) },
        {Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = Bind(self,self.ON_ITEM_UPDATED_MAP_CUSTOM_Func) },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_LIKE_SKIN_CHANGE, Func = self.ON_HERO_LIKE_SKIN_CHANGE_Func },
        {Model = HeroModel,  MsgName = HeroModel.ON_HERO_SKIN_SUIT_SELECT,	           Func = Bind(self, self.UpdateBtnState) }, 
	}
    self.BindNodes = 
    {
		-- { UDelegate = self.View.WBP_CommonItemVertical.GetBtn.OnClicked,				    Func = Bind(self,self.OnClicked_BtnClick) },
		-- { UDelegate = self.View.WBP_CommonItemVertical.LockBtn.OnClicked,				    Func = Bind(self,self.OnClicked_BtnClick) },
	}
    -- self.CommonHeroSkinItemCls = UIHandler.New(self,self.View.WBP_CommonItemVertical,require("Client.Modules.Common.CommonHeroSkinItemLogic")).ViewInstance
    self.CommonHeroSkinItemCls = UIHandler.New(self,self.View.WBP_CommonItemVertical,CommonItemIconVertical).ViewInstance
    self.CurSelectId = 0
end

function HeroSkinListItem:OnShow(Param)

end

function HeroSkinListItem:OnHide()
end

--[[
    {
        SkinId = SkinId,
        HeroId = self.HeroId,
        ClickFunc
        Index
    }
]]
function HeroSkinListItem:OnManualShow()
    self.CurSelectId = 0
    self:UpdateUI()
end
function HeroSkinListItem:SetData(Param)
    --TODO 根据数据进行展示
    self.Param = Param
    self.SkinIDArr = self.Param.SkinIDArr
    self.SkinId = self.Param.SkinId
    self.HeroId = self.Param.HeroId


    -- CLog("[hz] self.RedDot" .. tostring(self.SkinId))
    -- local RedDotKey = "TabHeroSkinItem_"
    -- local RedDotSuffix = self.SkinId
    -- if self.RedDot then
    --     self.RedDot:ChangeKey(RedDotKey, RedDotSuffix)
    -- else
    --     self.View.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     ---@type CommonRedDot
    --     self.RedDot = UIHandler.New(self, self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
    -- end
    self:UpdateUI()
end

function HeroSkinListItem:UpdateUI()
    --TODO 状态展示
    self:UpdateImgShow()
    self:UpdateSkinStateShow()

    -- TODO 特殊描述标签 暂时隐藏 后续有需求再打开
    self.View.WBP_CommonSpecialMark:SetVisibility(UE.ESlateVisibility.Collapsed)
end

--[[
    状态显示
    已装备
    未解锁
    已解锁未装备
]]
function HeroSkinListItem:UpdateSkinStateShow()
    local IsLock = true
    for i, v in ipairs(self.SkinIDArr) do
        local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,v) 
        local TheItemId = TblSkin[Cfg_HeroSkin_P.ItemId]
        if MvcEntry:GetModel(DepotModel):GetItemCountByItemId(TheItemId) > 0 then
            IsLock = false
            break
        end
    end
    
    -- self.View.WBP_CommonItemVertical:SetWidgetState(IsLock and 1 or 0, self.IsSelect)
    if self.CommonHeroSkinItemCls then
        local Param = {
            IsSelect = self.IsSelect,
            IsLock = IsLock
        }
        self.CommonHeroSkinItemCls:SetState(Param)
        self.CommonHeroSkinItemCls:SetIsLock(IsLock)
    end
end

function HeroSkinListItem:GetIndex()
    return self.Param.Index
end

function HeroSkinListItem:UpdateBtnState(_, Param)
    self.IsSelect = table.contains(self.SkinIDArr, Param.SkinId)
    self.CurSelectId = Param.SkinId
    self:UpdateSkinStateShow()
end

function HeroSkinListItem:OnClicked_BtnClick()
    MvcEntry:GetModel(HeroModel):DispatchType(HeroModel.ON_HERO_SKIN_SUIT_SELECT, {HeroId = self.HeroId,SkinId = self.SkinId, SkinIDArr = self.SkinIDArr, Item = self})
end

function HeroSkinListItem:ON_ITEM_UPDATED_MAP_CUSTOM_Func(Handler,ChangeMap)
    if self.ItemIdOfSkin and ChangeMap[self.ItemIdOfSkin] then
        self:UpdateSkinStateShow()
    end
end

function HeroSkinListItem:UpdateImgShow()
    self.IsSelect = false
    local FavoriteSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(self.HeroId)
    if table.contains(self.SkinIDArr, FavoriteSkinId) then
        self.SkinId = FavoriteSkinId
        self.IsSelect = true
    end

    if self.CurSelectId > 0 then
        self.IsSelect = table.contains(self.SkinIDArr, self.CurSelectId)
    end
    
    -- local IsLock = true
    -- for i, v in ipairs(self.SkinIDArr) do
    --     local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,v) 
    --     local TheItemId = TblSkin[Cfg_HeroSkin_P.ItemId]
    --     if MvcEntry:GetModel(DepotModel):GetItemCountByItemId(TheItemId) > 0 then
    --         IsLock = false
    --         break
    --     end
    -- end

    -- if self.CommonHeroSkinItemCls then
    --     local Param = {
    --         HeroSkinId = self.SkinId,
    --         BtnClickFunc = Bind(self,self.OnClicked_BtnClick),
    --         IsSelect = self.IsSelect,
    --         IsLock = IsLock,
    --     }
    --     self.CommonHeroSkinItemCls:SetData(Param)
    -- end

    local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,self.SkinId)
    if not TblSkin then
        return
    end
    self.ItemIdOfSkin = TblSkin[Cfg_HeroSkin_P.ItemId]
    -- Icon
    local HalfBodyBGPNGPath = TblSkin[Cfg_HeroSkin_P.HalfBodyBGPNGPath]

    local CornerTagInfo =self:GetCornerTagParam()
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = self.ItemIdOfSkin,
        ReplaceIconPath = HalfBodyBGPNGPath,
        ClickCallBackFunc = Bind(self, self.OnClicked_BtnClick),
        -- ClickMethod = UE.EButtonClickMethod.DownAndUp,
        -- HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        ShowItemName = false,

        RightCornerTagId = CornerTagInfo.TagId,
        RightCornerTagHeroId = CornerTagInfo.TagHeroId,
        RightCornerTagHeroSkinId = CornerTagInfo.TagHeroSkinId,
        -- IsLock = CornerTagInfo.IsLock,
        -- IsGot = CornerTagInfo.IsGot,
        -- IsOutOfDate = CornerTagInfo.IsOutOfDate,
        RedDotKey = "TabHeroSkinItem_",
        RedDotSuffix = self.SkinId,
        RedDotInteractType = CommonConst.RED_DOT_INTERACT_TYPE.CLICK,
    }
    if self.CommonHeroSkinItemCls then
        self.CommonHeroSkinItemCls:UpdateUI(IconParam)    
    end
    
    --TODO Icon展示
    -- CommonUtil.SetBrushFromSoftObjectPath(self.View.WBP_CommonItemVertical.ImageIcon,TblSkin[Cfg_HeroSkin_P.HalfBodyBGPNGPath])
    -- --品质
    -- local ItemId = TblSkin[Cfg_HeroSkin_P.ItemId]
    -- local Widgets = {
    --     QualityBar = self.View.QualityBar,
    --     QualityIcon = self.View.GUIImageQuality,
    --     -- QualityLevelText = self.View.GUITextBlock_QualityLevel,
    -- }
    -- CommonUtil.SetQualityShow(ItemId,Widgets)

    self.View.TypeWidgetSwitcher:SetActiveWidgetIndex(TblSkin[Cfg_HeroSkin_P.SuitType])
    self.View.SuitNum:SetText(StringUtil.FormatText(#self.SkinIDArr))
end


---@return CornerTagParam
function HeroSkinListItem:GetCornerTagParam()
    local TagParam = {
        TagPos = CommonConst.CORNER_TAGPOS.Right,
        TagId = 0,
        TagWordId = 0,
        TagHeroId = 0,
        TagHeroSkinId = 0
    }

    local IsLock = true
    for i, v in ipairs(self.SkinIDArr) do
        local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin, v) 
        local TheItemId = TblSkin[Cfg_HeroSkin_P.ItemId]
        if MvcEntry:GetModel(DepotModel):GetItemCountByItemId(TheItemId) > 0 then
            IsLock = false
            break
        end
    end

    if IsLock then
        -- 没有拥有
        TagParam.TagId = CornerTagCfg.Lock.TagId
        return TagParam
    end

    -- local FavoriteSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(self.HeroId)
    -- if table.contains(self.SkinIDArr, FavoriteSkinId) then
    --     self.SkinId = FavoriteSkinId
    --     self.IsSelect = true
    -- end

    -- if self.IsSelect then
    --     return TagParam
    -- end

    return TagParam
end



function HeroSkinListItem:ON_HERO_LIKE_SKIN_CHANGE_Func()
    self:UpdateImgShow()
end


return HeroSkinListItem
