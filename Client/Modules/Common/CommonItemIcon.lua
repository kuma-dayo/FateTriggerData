--[[
    通用的CommonItemIcon控件

    通用的物品Icon控件
]]
local class_name = "CommonItemIcon"
---@class CommonItemIcon
CommonItemIcon = CommonItemIcon or BaseClass(nil, class_name)

---@class CommonItemIconParam
---@field IconType CommonItemIcon.ICON_TYPE 图标所属类型，可根据不同类型做不同处理
---@field ItemId number 配置ID
---@field ItemUniqId number?  道具唯一ID
---@field ExpireTime number? 过期截止时间
---@field ItemNum number? 展示数量
---@field ShowCount number?  是否展示数字，默认为true
---@field DecomposeInfo table? 分解信息，如果没有则为 nil     --     ItemId = 1,  [Optional] : 分解之后的物品id  --     ItemNum = 1, [optional] : 分解之后的物品数量
---@field ShowItemName boolean? 是否显示名称默认不显示
---@field OmitWhenOverMax boolean? 是否省略数量为999+,默认为false
---@field ShowEmpty boolean? 当此字段设置为true，并且没有给出itemId的时候，会显示为空状态
---@field ItemParentScale number? 受父节点影响的缩放值，例如有某一层父节点为ScaleBox。用于计算Tips的位置
-- 交互相关
---@field bUseBtnEnhanced boolean?
---@field ClickFuncType boolean? CommonItemIcon.CLICK_FUNC_TYPE 点击响应类型，OnClick时选择不同的响应逻辑； 默认不响应
---@field HoverFuncType boolean? CommonItemIcon.HOVER_FUNC_TYPE Hover响应类型，OnHover时选择不同的响应逻辑； 默认不响应
---@field ClickCallBackFunc function? 点击回调
---@field DoubleClickCallFunc function? 双击击回调
---@field PressCallBackFunc function? 点击回调
---@field ReleaseCallBackFunc function? 点击回调
---@field DragCallBackFunc function? 拖拽回调
---@field HoverCallBackFunc function? Hover回调
---@field UnhoverCallBackFunc function? Unhover回调
---@field IsBreakClick boolean? 是否在执行完ClickCallBackFunc后终止，不往下执行其余逻辑
---@field IsBreakHover boolean? 是否在执行完HoverCallBackFunc后终止，不往下执行其余逻辑
---@field IsBreakUnhover boolean? 是否在执行完UnhoverCallBackFunc后终止，不往下执行其余逻辑
---@field HoverScale number? OnHover时放大自身，默认为1，即不放大
---@field ClickMethod EButtonClickMethod.Type? 
---@field HoverTipFocusOffset 道具TIPS弹窗采样位置偏移 FVector2D
-- 红点相关
---@field RedDotKey number|string? 红点前缀
---@field RedDotSuffix number|string? 红点后缀
---@field RedDotInteractType number CommonConst.RED_DOT_INTERACT_TYPE? 红点触发类型
-- 状态&角标相关
---@field SubScriptScale number? 右上角标签缩放
---@field IsGot boolean? 是否已领取 默认为false
---@field IsCanGet boolean? 是否能够领取状态 默认为false
---@field IsLock boolean? 是否锁定状态，默认为false
---@field IsOutOfDate boolean? 是否过期状态，默认为false
---@field LeftCornerTagId number? 左上角角标Id -- 对应 CornerTagCfg
---@field LeftCornerTagWordId number? 左上角角标文字Id -- 对应 CornerTagWordCfg 仅当角标类型为 CornerTagCfg.Word 生效
---@field LeftCornerTagHeroId number? 左上角角标英雄头像Id -- 仅当角标类型为 CornerTagCfg.HeroBg 生效
---@field LeftCornerTagHeroSkinId number? 左上角角标英雄头像皮肤Id -- 仅当角标类型为 CornerTagCfg.HeroBg 生效
---@field RightCornerTagId number? 右上角角标Id -- 对应 CornerTagCfg
---@field RightCornerTagWordId number? 右上角角标文字Id -- 对应 CornerTagWordCfg 仅当角标类型为 CornerTagCfg.Word 生效
---@field RightCornerTagHeroId number? 右上角角标英雄头像Id -- 仅当角标类型为 CornerTagCfg.HeroBg 生效
---@field RightCornerTagHeroSkinId number? 右上角角标英雄头像皮肤Id -- 仅当角标类型为 CornerTagCfg.HeroBg 生效
---@field MidCornerTagId number? 中心角标Id -- 对应 CornerTagCfg
---@field MidCornerTagWordId number? 中心角标文字Id -- 对应 CornerTagWordCfg 仅当角标类型为 CornerTagCfg.Word 生效
---@field MidCornerTagHeroId number? 中心角标英雄头像Id -- 仅当角标类型为 CornerTagCfg.HeroBg 生效
---@field MidCornerTagHeroSkinId number? 中心角标英雄头像皮肤Id -- 仅当角标类型为 CornerTagCfg.HeroBg 生效
-- 角标事件监听控制
---@field IsCheckMaxCount boolean? 是否检测达到数量上限标识 默认为false
---@field IsNotCheckItemCountCornerTag boolean? 是否关闭道具数量变动角标事件监听 默认为false
---@field IsNotCheckAchievementCornerTag boolean? 是否关闭成就角标变动事件监听 默认为false

CommonItemIcon.IconParams = nil

-- 相关枚举定义
-- Icon类型
CommonItemIcon.ICON_TYPE = {
    NONE = 0,
    PROP = 1, -- 道具
    ACHIEVEMENT = 2, --成就

}
-- 点击响应类型
CommonItemIcon.CLICK_FUNC_TYPE = {
    NONE = 0,  -- 不响应，默认不响应
    TIP = 1, -- 弹出Tips
}
-- PC Hover响应类型
CommonItemIcon.HOVER_FUNC_TYPE = {
    NONE = 0,  -- 不响应，默认不响应
    TIP = 1, -- 弹出Tips
}


function CommonItemIcon:OnInit()
    self.MsgList = {
        {Model = CommonModel, MsgName = CommonModel.CHECK_ITEM_COUNT_CORNER_TAG, Func = self.OnCheckItemCountCornerTag},
        {Model = CommonModel, MsgName = CommonModel.CHECK_ACHIEVEMENT_CORNER_TAG, Func = self.OnCheckAchievementCornerTag},
    }
    self.BindNodes = {}
    self:Init()
end


function CommonItemIcon:Init()
    self.IconParams = nil
    self.IconType = CommonItemIcon.ICON_TYPE.NONE
    self.ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE    
    self.HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.NONE    
    self.ClickCallBackFunc = nil
    self.DoubleClickCallFunc = nil
    self.HoverCallBackFunc = nil
    self.NoHoverScale = false
    self.View.GUIImageIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.GUIImage_QualityBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.TextNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Img_FrameHint:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Img_Countdown_MI:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.SubScriptDefaultScale = 1
    self.CheckTime = nil

    self:Clear()
end

function CommonItemIcon:OnShow(Param)
    if Param then
        self:UpdateUI(Param)
    end
end

function CommonItemIcon:OnHide()
    self:HideTips()
	self:Clear()
end

function CommonItemIcon:Clear()
    self.ItemShowState =  CommonConst.ITEM_SHOW_STATE_DEFINE.NONE
    self.LeftCornerTagId = 0    -- 左上角角标Id
    self.LeftCornerTagWordId = 0
    self.RightCornerTagId = 0   -- 右上角角标Id
    self.RightCornerTagWordId = 0
    self.MidCornerTagId = 0 -- 中心角标Id
    self.MidCornerTagWordId = 0
    if self.AutoHideTimer then
        Timer.RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
    if self.BindNodes then
        MsgHelper:OpDelegateList(self.View, self.BindNodes, false)
        self.BindNodes = {}
    end

    self:ClearDoubleClickResetTimerInner()
end

--- func desc
---@param Param CommonItemIconParam
---@param NotInit boolean
function CommonItemIcon:UpdateUI(Param,NotInit)
    if not NotInit then
        self:Init()
    end
    self:ResetDoubleClickDataInner()

    self.IconParams = Param
    if not self.IconParams then
        self:PopError("CommonItemIcon:UpdateUI IconParams Error")
        return
    end

    if not self.IconParams.ItemId then
        if self.IconParams.ShowEmpty then
            self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.Empty)
        else
            self:PopError("CommonItemIcon:UpdateUI ItemId Error")
        end
        return
    end
    
    if self.IconParams.ItemId <= 0 then
        print("CommonItemIcon:UpdateUI ItemId = 0; Use Default Show!")
        -- TODO 展示默认底图
        return
    end
    self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.Content)
    self.IconType = Param.IconType or CommonItemIcon.ICON_TYPE.NONE
    self.ShowItemName = Param.ShowItemName or false
    self.SubScriptScale = Param.SubScriptScale or self.SubScriptDefaultScale
    -- 红点
    self.RedDotKey = Param.RedDotKey or nil
    self.RedDotSuffix = Param.RedDotSuffix or ""
    self.RedDotInteractType = Param.RedDotInteractType or CommonConst.RED_DOT_INTERACT_TYPE.NONE
    

    -- 处理点击/Hover相关
    if Param.ClickCallBackFunc then
        self.ClickCallBackFunc = Param.ClickCallBackFunc;
    end
    if Param.DoubleClickCallFunc then
        self.DoubleClickCallFunc = Param.DoubleClickCallFunc
    end
    if Param.PressCallBackFunc then
        self.PressCallBackFunc = Param.PressCallBackFunc;
    end
    if Param.DragCallBackFunc then
        self.DragCallBackFunc = Param.DragCallBackFunc;
    end
    if Param.ReleaseCallBackFunc then
        self.ReleaseCallBackFunc = Param.ReleaseCallBackFunc;
    end

    if Param.HoverCallBackFunc then
        self.HoverCallBackFunc = Param.HoverCallBackFunc;
    end
    if Param.UnhoverCallBackFunc then
        self.UnhoverCallBackFunc = Param.UnhoverCallBackFunc;
    end
    self:Clear()
    self.ClickFuncType = Param.ClickFuncType or CommonItemIcon.CLICK_FUNC_TYPE.NONE
    self.HoverFuncType = Param.HoverFuncType or CommonItemIcon.HOVER_FUNC_TYPE.NONE

    -- self.IconParams.bUseBtnEnhanced = true
    if not(self.IconParams.bUseBtnEnhanced) or not(CommonUtil.IsValid(self.View.WBP_CommonBtn_Enhanced)) then
        self.View.GUIButtonItem:SetVisibility(UE.ESlateVisibility.Visible)
        self.View.WBP_CommonBtn_Enhanced:SetVisibility(UE.ESlateVisibility.Collapsed)

        if self.ClickCallBackFunc ~= nil or self.ClickFuncType ~= CommonItemIcon.CLICK_FUNC_TYPE.NONE or self.DoubleClickCallFunc ~= nil then
            self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.GUIButtonItem.OnClicked,Func = Bind(self,self.OnIconBtnClicked)}
        end
        if self.PressCallBackFunc or Param.DragCallBackFunc then
            self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.GUIButtonItem.OnPressed,Func = Bind(self,self.OnIconBtnPress)}
        end
        if self.ReleaseCallBackFunc or Param.DragCallBackFunc then
            self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.GUIButtonItem.OnReleased,Func = Bind(self,self.OnIconBtnReleased)}
        end
        self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.GUIButtonItem.OnHovered,Func = Bind(self,self.OnIconBtnHoverd)}
        self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.GUIButtonItem.OnUnhovered,Func = Bind(self,self.OnIconBtnUnhoverd)}
        if Param.ClickMethod then
            self.View.GUIButtonItem:SetClickMethod(Param.ClickMethod)
        end
    else
        self.View.GUIButtonItem:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.WBP_CommonBtn_Enhanced:SetVisibility(UE.ESlateVisibility.Visible)
        
        local BtnParam = {
            OnBtnClicked = nil,
            OnBtnHold = nil,
            OnBtnDoubleClicked = nil,
            OnBtnPressed = nil,
            OnBtnReleased = nil,
        }
        if self.ClickCallBackFunc ~= nil or self.ClickFuncType ~= CommonItemIcon.CLICK_FUNC_TYPE.NONE then
            BtnParam.OnBtnClicked = Bind(self, self.OnIconBtnClicked)
        end
        if self.DoubleClickCallFunc ~= nil then
            BtnParam.OnBtnDoubleClicked = Bind(self, self.OnDoubleClickCallFunc) 
        end
        if self.PressCallBackFunc or Param.DragCallBackFunc then
            BtnParam.OnBtnReleased  = Bind(self,self.OnIconBtnReleased) 
        end
        if self.CommonBtnEnhancedIns == nil or not(self.CommonBtnEnhancedIns:IsValid()) then
            self.CommonBtnEnhancedIns = UIHandler.New(self, self.View.WBP_CommonBtn_Enhanced, require("Client.Modules.Common.CommonBtnEnhanced"), BtnParam).ViewInstance
        else
            self.CommonBtnEnhancedIns:ManualOpen(BtnParam)
        end
    end

    self:ReRegister()
    self:DoUpdate()
end

-- function CommonItemIcon:OnDepotModelChanged()
--     self:UpdateLeftTopTag()
-- end

function CommonItemIcon:DoUpdate()
    if not self.IconParams then
        return
    end
    local ICON_TYPE = CommonItemIcon.ICON_TYPE
    local IconPath, Quality
    if self.IconType == ICON_TYPE.PROP then
        -- 道具
        local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.IconParams.ItemId)
        if not ItemCfg then
            self:PopError("CommonItemIcon:DoUpdate GetItemConfig Error!")
            return
        end
        -- TODO 是否根据不同类型处理
        IconPath = ItemCfg[Cfg_ItemConfig_P.IconPath]
        Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
        self:SetShowCount(self.IconParams.ItemNum)
    elseif self.IconType == ICON_TYPE.ACHIEVEMENT then
        local Model = MvcEntry:GetModel(AchievementModel)
        ---@type AchievementData
        local Data = Model:GetData(self.IconParams.ItemId)
        if not Data then
            CError("CommonItemIcon:DoUpdate Data is nil id:"..self.IconParams.ItemId)
            return
        end
        
        -- IconPath = Data:GetIcon() 
        IconPath = Data:GetSmallIcon() --要求使用小图
        Quality = Data.Quality
    end

    self.View.Root_SubScriptScale:SetUserSpecifiedScale(self.SubScriptScale)

    self:CheckCornerTag()
    self:SetIsGot(self.IconParams.IsGot,true)
    self:SetIsLock(self.IconParams.IsLock,true)
    self:SetIsCanGet(self.IconParams.IsCanGet,true)
    self:UpdateIcon(IconPath)
    self:UpdateQuality(Quality)
    self:_UpdateShowStatus()
    self:RegisterRedDot()
end


-- 更新Icon资源
function CommonItemIcon:UpdateIcon(IconPath)
    self.View.GUIImageIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    local IconImg = LoadObject(IconPath)
    if IconImg then
        self.View.GUIImageIcon:SetBrushFromTexture(IconImg)
        self.View.GUIImageIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

function CommonItemIcon:UpdateSubScriptScale(Scale)
    self.SubScriptScale = Scale or self.SubScriptDefaultScale
    self.View.Root_SubScriptScale:SetUserSpecifiedScale(self.SubScriptScale)
end

-- 品质色
function CommonItemIcon:UpdateQuality(Quality)
    self.View.GUIImage_QualityBg:SetVisibility(UE.ESlateVisibility.Collapsed)
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
    if QualityCfg then
        local QualityBgPath = QualityCfg[Cfg_ItemQualityColorCfg_P.QualityBg]
        self.View.GUIImage_QualityBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImage_QualityBg,QualityBgPath)
        -- CommonUtil.SetImageColorFromQuality(self.View.QualityBar,Quality)
        --CommonUtil.SetTextColorFromQuality(self.View.GUITextBlock_Level,Quality)
    end
end

-- 设置数量
function CommonItemIcon:SetShowCount(Count)
    Count = Count or 0
    self.View.TextNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    if not self.IconParams or (self.IconParams and self.IconParams.ShowCount == false) or Count <= 1 then
        -- 设置不展示数量 或 数量未超过1
        return
    end
    self.View.TextNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if (self.IconParams.OmitWhenOverMax ~= nil and self.IconParams.OmitWhenOverMax) and Count > 999 then
        self.View.TextNum:SetText("999+")
    else
        self.View.TextNum:SetText(Count)
    end
    
    -- TODO 数字的各种显示格式，后续可拓展
end

-- 检测角标
function CommonItemIcon:CheckCornerTag()
    if not self.IconParams then
        return
    end
    if self.IconParams.IconType == CommonItemIcon.ICON_TYPE.PROP then
        self:CheckPropItemCornerTag()
    elseif self.IconParams.IconType == CommonItemIcon.ICON_TYPE.ACHIEVEMENT then
        self:CheckAchieveItemCornerTag()
    end
    if self.IconParams.LeftCornerTagId then
        local Param = {}
        Param.TagPos = CommonConst.CORNER_TAGPOS.Left
        Param.TagId = self.IconParams.LeftCornerTagId
        Param.TagWordId = self.IconParams.LeftCornerTagWordId
        Param.TagHeroId = self.IconParams.LeftCornerTagHeroId
        Param.TagHeroSkinId = self.IconParams.LeftCornerTagHeroSkinId
        self:SetCornerTag(Param)
    end
    if self.IconParams.RightCornerTagId then
        local Param = {}
        Param.TagPos = CommonConst.CORNER_TAGPOS.Right
        Param.TagId = self.IconParams.RightCornerTagId
        Param.TagWordId = self.IconParams.RightCornerTagWordId
        Param.TagHeroId = self.IconParams.RightCornerTagHeroId
        Param.TagHeroSkinId = self.IconParams.RightCornerTagHeroSkinId
        self:SetCornerTag(Param)
    end
    if self.IconParams.MidCornerTagId then
        local Param = {}
        Param.TagPos = CommonConst.CORNER_TAGPOS.Mid
        Param.TagId = self.IconParams.MidCornerTagId
        Param.TagWordId = self.IconParams.MidCornerTagWordId
        Param.TagHeroId = self.IconParams.MidCornerTagHeroId
        Param.TagHeroSkinId = self.IconParams.MidCornerTagHeroSkinId
        self:SetCornerTag(Param)
    end
end

-- 检测设置道具类型图标的角标
function CommonItemIcon:CheckPropItemCornerTag()
    if not (self.IconParams and self.IconParams.ItemId) then
        return
    end
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.IconParams.ItemId)
    if not ItemCfg then
        return
    end
    -- 达到数量上限
    self:CheckItemMaxCount()

    -- 是否分解
    if self.IconParams.DecomposeInfo then
        local Param = {}
        Param.TagPos = CommonConst.CORNER_TAGPOS.Right
        Param.TagId = CornerTagCfg.Discompose.TagId
        self:SetCornerTag(Param)
    end

    -- 配置读取的
    -- 1. 优先按ItemId索引
    local ItemIdentificationCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_ItemIdentificationCfg,Cfg_ItemIdentificationCfg_P.ItemId,self.IconParams.ItemId)
    if not ItemIdentificationCfg then
        -- 2. 按 物品类别+物品子类 索引
        ItemIdentificationCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_ItemIdentificationCfg,
            {Cfg_ItemIdentificationCfg_P.Type,Cfg_ItemIdentificationCfg_P.SubType},
            {ItemCfg[Cfg_ItemConfig_P.Type],ItemCfg[Cfg_ItemConfig_P.SubType]})
        if not ItemIdentificationCfg then
            -- 3. 按 物品类别 索引
            ItemIdentificationCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_ItemIdentificationCfg,Cfg_ItemIdentificationCfg_P.Type,ItemCfg[Cfg_ItemConfig_P.Type])
        end
    end
    if ItemIdentificationCfg then
        local Param = {}
        Param.TagPos = ItemIdentificationCfg[Cfg_ItemIdentificationCfg_P.TagPos]
        Param.TagId = ItemIdentificationCfg[Cfg_ItemIdentificationCfg_P.TagId]
        Param.TagWordId = ItemIdentificationCfg[Cfg_ItemIdentificationCfg_P.TagWord]
        self:SetCornerTag(Param)
    end
end

-- 达到数量上限 角标检测
function CommonItemIcon:CheckItemMaxCount()
    if self.IconParams.IsCheckMaxCount then
        local IsMax = false
        local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.IconParams.ItemId)
        local MaxCount = ItemCfg and ItemCfg[Cfg_ItemConfig_P.MaxCount] or 0
        if MaxCount > 0 then
            local Count = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.IconParams.ItemId)
            if  Count >= MaxCount then
                local Param = {}
                Param.TagPos = CommonConst.CORNER_TAGPOS.Right
                Param.TagId = CornerTagCfg.Word.TagId
                Param.TagWordId = CornerTagWordCfg.Max.WordId
                self:SetCornerTag(Param)
                IsMax = true
            end
        end
        if not IsMax and self.RightCornerTagWordId == CornerTagWordCfg.Max.WordId then
            self.RightCornerTagId = 0
            self.RightCornerTagWordId = 0
        end
    end
end

-- 检测设置成就类型图标的角标
function CommonItemIcon:CheckAchieveItemCornerTag()
    if not self.IconParams then
        return
    end
    local Model = MvcEntry:GetModel(AchievementModel)
    local Data = Model:GetData(self.IconParams.ItemId)
    if not Data then
        return
    end
    -- 仅处理右角标，有其余的再自行拓展
    local Param = { TagPos = CommonConst.CORNER_TAGPOS.Right}
    if Data:IsEquiped() then
        Param.TagId = CornerTagCfg.Equipped.TagId
    elseif Data:IsDeleted() then
        -- todo
    elseif Data:IsDrag() then
        -- todo
    elseif Data:IsNoOperation() then
        -- todo
    end
    self:SetCornerTag(Param)
    self:SetIsLock(not Data:IsUnlock(),true)
end

--- 能够领取状态
function CommonItemIcon:SetIsCanGet(IsCanGet,IsInit)
    if IsCanGet then
        if self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NONE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.CANGET then
            CWaring("CommonItemIcon ShowState Will Change To Got From "..self.ItemShowState,true)
        end
        self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.CANGET
    else
        if self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.CANGET then
            self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.NONE
        end
    end
    if not IsInit then
        self:_UpdateShowStatus()
    end
end

function CommonItemIcon:SetIsGot(IsGot,IsInit)
    if IsGot then
        if self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NONE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.GOT then
            CWaring("CommonItemIcon ShowState Will Change To Got From "..self.ItemShowState,true)
        end
        self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.GOT
        self.MidCornerTagId = CornerTagCfg.Got.TagId
    else
        if self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.GOT then
            self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.NONE
            if self.MidCornerTagId == CornerTagCfg.Got.TagId then
                self.MidCornerTagId = 0
            end
        end
    end
    if not IsInit then
        self:_UpdateShowStatus()
    end
end

function CommonItemIcon:IsLock()
    return self.ItemShowState  == CommonConst.ITEM_SHOW_STATE_DEFINE.LOCK
end

-- 设置锁定
function CommonItemIcon:SetIsLock(IsLock,IsInit)
    if IsLock then
        if self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NONE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.LOCK then
            CWaring("CommonItemIcon ShowState Will Change To Lock From "..self.ItemShowState,true)
        end
        self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.LOCK
        self.RightCornerTagId = CornerTagCfg.Lock.TagId
    else
        if self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.LOCK then
            self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.NONE
            if self.RightCornerTagId == CornerTagCfg.Lock.TagId then
                self.RightCornerTagId = 0
            end
        end
    end
    if not IsInit then
        self:_UpdateShowStatus()
    end
end

-- 设置过期
function CommonItemIcon:SetIsOutOfDate(IsOutOfDate,IsInit)
    if IsOutOfDate then
        if self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NONE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.OUTOFDATE then
            CWaring("CommonItemIcon ShowState Will Change To OUTOFDATE From "..self.ItemShowState,true)
        end
        self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.OUTOFDATE
        self.LeftCornerTagId = CornerTagCfg.Outdate.TagId
    else
        if self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.OUTOFDATE then
            self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.NONE
            if self.LeftCornerTagId == CornerTagCfg.Outdate.TagId then
                self.LeftCornerTagId = 0
            end
        end
    end
    if not IsInit then
        self:_UpdateShowStatus()
    end
end

-- 新获得状态
function CommonItemIcon:SetIsNew(IsNew,IsInit)
    if IsNew then
        if self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NONE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NEW then
            CWaring("CommonItemIcon ShowState Will Change To NEW From "..self.ItemShowState,true)
        end
        self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.NEW
    else
        if self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.NEW then
            self.ItemShowState = CommonConst.ITEM_SHOW_STATE_DEFINE.NONE
        end
    end
    if not IsInit then
        self:_UpdateShowStatus()
    end
end

function CommonItemIcon:SetCornerTag(TagParam)
    local TagPos = TagParam.TagPos
    if TagPos == CommonConst.CORNER_TAGPOS.Left then
        self.LeftCornerTagId = TagParam.TagId
        self.LeftCornerTagWordId = TagParam.TagWordId
        self.LeftCornerTagHeroId = TagParam.TagHeroId
        self.LeftCornerTagHeroSkinId = TagParam.TagHeroSkinId
    elseif TagPos == CommonConst.CORNER_TAGPOS.Right then
        self.RightCornerTagId = TagParam.TagId
        self.RightCornerTagWordId = TagParam.TagWordId
        self.RightCornerTagHeroId = TagParam.TagHeroId
        self.RightCornerTagHeroSkinId = TagParam.TagHeroSkinId
    elseif TagPos == CommonConst.CORNER_TAGPOS.Mid then
        self.MidCornerTagId = TagParam.TagId
        self.MidCornerTagWordId = TagParam.TagWordId
        self.MidCornerTagHeroId = TagParam.TagHeroId
        self.MidCornerTagHeroSkinId = TagParam.TagHeroSkinId
    end

    if TagParam.IsUpdate then
        self:_UpdateShowStatus()
    end
end

-- 更新Icon的展示样式
function CommonItemIcon:_UpdateShowStatus()
    if not CommonUtil.IsValid(self.View.ImgBg_Mask) then
        CError("CommonItemIcon:_UpdateShowStatus ImgBg_Mask is invalid")
        return
    end
    self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Img_Countdown_MI:SetVisibility(UE.ESlateVisibility.Collapsed)    
    self.View.Img_NewGetFrame:SetVisibility(UE.ESlateVisibility.Collapsed)    
        
    -- 遮罩设置
    if self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.LOCK then
        self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.ImgBg_Mask:SetColorAndOpacity(self.View.MaskColor_Lock)
    elseif self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.GOT then
        self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.ImgBg_Mask:SetColorAndOpacity(self.View.MaskColor_Got)
        if self.View.VXE_CommonItem_Claimed then
            self.View:VXE_CommonItem_Claimed()
        end
    elseif self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.OUTOFDATE then
        self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.ImgBg_Mask:SetColorAndOpacity(self.View.MaskColor_OutOfDate)
    elseif self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.TIMER then
        self.View.Img_Countdown_MI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)    
        -- todo 开启倒计时
    elseif self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.NEW then
        self.View.Img_NewGetFrame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)    
    elseif self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.CANGET then
        -- 能够领取状态
        if self.View.VXE_CommonItem_Available then
            self.bCanGet_VXE = true
            self.View:VXE_CommonItem_Available()
        end
    end

    if self.bCanGet_VXE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.CANGET  then
        self.bCanGet_VXE = false
        if self.View.VXE_CommonItem_Claimed then
            self.View:VXE_CommonItem_Claimed()
        end
    end

    -- 角标设置
    local ParamLeft = {
        TagPos = CommonConst.CORNER_TAGPOS.Left,
        TagId = self.LeftCornerTagId,
        TagWordId = self.LeftCornerTagWordId,
        TagHeroId = self.LeftCornerTagHeroId,
        TagHeroSkinId = self.LeftCornerTagHeroSkinId,
    }
    self:_SetCornerTagShow(ParamLeft)
    local ParamRight = {
        TagPos = CommonConst.CORNER_TAGPOS.Right,
        TagId = self.RightCornerTagId,
        TagWordId = self.RightCornerTagWordId,
        TagHeroId = self.RightCornerTagHeroId,
        TagHeroSkinId = self.RightCornerTagHeroSkinId,
    }
    self:_SetCornerTagShow(ParamRight)
    local ParamMid = {
        TagPos = CommonConst.CORNER_TAGPOS.Mid,
        TagId = self.MidCornerTagId,
        TagWordId = self.MidCornerTagWordId,
        TagHeroId = self.MidCornerTagHeroId,
        TagHeroSkinId = self.MidCornerTagHeroSkinId,
    }
    self:_SetCornerTagShow(ParamMid)
end

function CommonItemIcon:_SetCornerTagShow(TagParam)
    local TagPos = TagParam.TagPos
    local TagPanel = self.View["CornerTag_"..TagPos]
    if not TagPanel then
        CError("SetCornerTagShow Not Found Panel For Pos = "..TagPos)
        return
    end
    local TagId = TagParam.TagId
    if not TagId or TagId <= 0 then
        TagPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    local CornerTagCfg = G_ConfigHelper:GetSingleItemById(Cfg_CornerTagCfg,TagId)
    if not CornerTagCfg then
        return
    end
    TagPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.View["CornerTagImg_"..TagPos] then
        self.View["CornerTagImg_"..TagPos]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.View["CornerTag_HeroHead_"..TagPos] then
        self.View["CornerTag_HeroHead_"..TagPos]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.View["CornerTagText_Img_"..TagPos] then
        self.View["CornerTagText_Img_"..TagPos]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.View["CornerTagText_Word_"..TagPos] then
        self.View["CornerTagText_Word_"..TagPos]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    local TagType = CornerTagCfg[Cfg_CornerTagCfg_P.TagType]
    if TagType == CommonConst.CORNER_TYPE.IMG then
        CommonUtil.SetCornerTagImg(self.View["CornerTagImg_"..TagPos],TagId)
    elseif TagType == CommonConst.CORNER_TYPE.HERO_HEAD then
        CommonUtil.SetCornerTagHeroHead(self.View["CornerTagImg_"..TagPos],self.View["CornerTag_HeroHead_"..TagPos],TagParam.TagHeroId, TagParam.TagHeroSkinId)
    elseif TagType == CommonConst.CORNER_TYPE.WORD then
        CommonUtil.SetCornerTagWord(self.View["CornerTagText_Img_"..TagPos],self.View["CornerTagText_Word_"..TagPos],TagParam.TagWordId)
    end
    --角标动效
    if self.View["VXE_CornerTag_"..TagPos] then
        self.View["VXE_CornerTag_"..TagPos](self.View)
    end
end

-- 设置选中(外部调用)
-- NoHoverScale 设为true，则当IsSelect为true时，OnHover的时候，不会放大
-- IsMulti 是否为多选
function CommonItemIcon:SetIsSelect(IsSelect,NoHoverScale,IsMulti)
    self.IsSelect = IsSelect
    self.NoHoverScale = NoHoverScale and self.IsSelect
    -- todo IsMulti 替换选中框图片
    self:_SetIsShowSelectedImg(IsSelect)
end

-- 选中图标(内部逻辑)
function CommonItemIcon:_SetIsShowSelectedImg(IsShow)
    local DoShow = self.IsSelect or IsShow
    if DoShow then
        if self.View.VXE_Btn_Select then
            self.View:VXE_Btn_Select()
        end
    else
        if self.View.VXE_Btn_UnSelect then
            self.View:VXE_Btn_UnSelect()
        end
    end
end

-- 设置提示（外部调用）
-- IsStrong 是否强提示，默认为false
function CommonItemIcon:SetIsPrompt(IsPrompt,IsStrong)
    if IsPrompt then
        self.View.Img_FrameHint:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.Img_FrameHint:SetColorAndOpacity(IsStrong and self.View.PromptColor_Strong or self.View.PromptColor_Weak)
    else
        self.View.Img_FrameHint:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 是否遮罩
function CommonItemIcon:SetIsMask(IsMask)
    if IsMask then
        self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.ImgBg_Mask:SetColorAndOpacity(self.View.MaskColor_Got)
    else
        self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 点击图标
function CommonItemIcon:OnIconBtnClicked()
    if not self.IconParams then
        return
    end
    self:InteractRedDot(CommonConst.RED_DOT_INTERACT_TYPE.CLICK)
    if self.ClickCallBackFunc then
        local Params = {
            Icon = self.View,
            ItemId = self.IconParams.ItemId,
        }
        self.ClickCallBackFunc(Params);

        if not(self.IconParams.bUseBtnEnhanced) then
            self:CheckIsDoubleClickInner()
        end

        if self.IconParams.IsBreakClick then
            return
        end
    else
        if not(self.IconParams.bUseBtnEnhanced) then
            self:CheckIsDoubleClickInner()
        end
    end
    local CLICK_FUNC_TYPE = CommonItemIcon.CLICK_FUNC_TYPE
    if self.ClickFuncType == CLICK_FUNC_TYPE.NONE then
        return
    elseif self.ClickFuncType == CLICK_FUNC_TYPE.TIP then
        self:ShowTips()
       
    end
end

function CommonItemIcon:OnIconBtnPress()
    if not self.IconParams then
        return
    end
    self.BeginCick = false
    local Params = {
        Handle = self,
        Icon = self.View,
        ItemId = self.IconParams.ItemId,
        DragType = CommonConst.DRAG_TYPE_DEFINE.DRAG_BEGIN
    }
    self.AutoHideTimer = Timer.InsertTimer(0.3,function()
        self.BeginCick = true
        if self.DragCallBackFunc then
            --CError("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX Press")
            self.DragCallBackFunc(Params);
        end
	end)
    if self.PressCallBackFunc then
        self.PressCallBackFunc(Params);
    end
end

function CommonItemIcon:OnIconBtnReleased()
    if not self.IconParams then
        return
    end

    local Params = {
        Handle = self,
        Icon = self.View,
        ItemId = self.IconParams.ItemId,
        DragType = CommonConst.DRAG_TYPE_DEFINE.NONE
    }

    if self.BeginCick then
        Params.DragType = CommonConst.DRAG_TYPE_DEFINE.DRAG_END
        self.BeginCick = false
    else
        Params.DragType = CommonConst.DRAG_TYPE_DEFINE.CLICK
    end
     
    if self.DragCallBackFunc then
        --CError("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX Released")
        self.DragCallBackFunc(Params);
    end

    if self.ReleaseCallBackFunc then
        self.ReleaseCallBackFunc(Params);
    end
    if self.AutoHideTimer then
        Timer.RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
end

-- Hover图标
function CommonItemIcon:OnIconBtnHoverd()
    -- print("OnIconBtnHoverd")
    if not self.IconParams then
        return
    end
    -- 视觉确认现hover效果放入动效处理，不再做放大操作 
    -- if self.IconParams.HoverScale and self.IconParams.HoverScale > 1 then
    --     self.OriScale = UE.FVector2D(self.View.RenderTransform.Scale.X,self.View.RenderTransform.Scale.Y)
    --     if not self.NoHoverScale then
    --         self.View:SetRenderScale(UE.FVector2D(self.IconParams.HoverScale,self.IconParams.HoverScale))
    --     end
    -- end
    if self.HoverCallBackFunc then
        local Params = {
            Icon = self.View,
            ItemId = self.IconParams.ItemId,
        }
        self.HoverCallBackFunc(Params);

        if self.IconParams.IsBreakHover then
            return
        end
    end
    local HOVER_FUNC_TYPE = CommonItemIcon.HOVER_FUNC_TYPE
    if self.HoverFuncType == HOVER_FUNC_TYPE.NONE then
        return
    elseif self.HoverFuncType == HOVER_FUNC_TYPE.TIP then
        self:ShowTips(true)
    end
end

--Unhover
function CommonItemIcon:OnIconBtnUnhoverd()
    -- print("OnIconBtnUnhoverd")
    if not self.IconParams then
        return
    end
    -- 视觉确认现hover效果放入动效处理，不再做放大操作 
    -- if self.IconParams.HoverScale and self.IconParams.HoverScale > 1 then
    --     self.View:SetRenderScale(self.OriScale)
    -- end
    if self.UnhoverCallBackFunc then
        local Params = {
            Icon = self.View,
            ItemId = self.IconParams.ItemId,
        }
        self.UnhoverCallBackFunc(Params);
        if self.IconParams.IsBreakUnhover then
            return
        end
    end
    local HOVER_FUNC_TYPE = CommonItemIcon.HOVER_FUNC_TYPE
    if self.HoverFuncType == HOVER_FUNC_TYPE.NONE then
        return
    elseif self.HoverFuncType == HOVER_FUNC_TYPE.TIP then
        self:HideTips()
    end
end

-- 弹出Tips
function CommonItemIcon:ShowTips(IsFromHover)
    if not self.IconParams then
        return
    end
     if self.IconType == CommonItemIcon.ICON_TYPE.PROP then
        -- 道具
        local Params = {
            ItemId = self.IconParams.ItemId,
            ItemUniqId = self.IconParams.ItemUniqId or 0,
            ExpireTime = self.IconParams.ExpireTime or 0,
            ItemNum = self.IconParams.ItemNum or 0,
            FocusWidget = self.View,
            IsHideBtnOutside = IsFromHover,
            DecomposeInfo = self.IconParams.DecomposeInfo,
            ParentScale = self.IconParams.ItemParentScale,
            FocusOffset = self.IconParams.HoverTipFocusOffset,
        }
        MvcEntry:OpenView(ViewConst.CommonItemTips, Params)
    elseif self.IconType == CommonItemIcon.ICON_TYPE.ACHIEVEMENT then
        local Model = MvcEntry:GetModel(AchievementModel)
        ---@type AchievementData
        local Data = Model:GetData(self.IconParams.ItemId)
        if not Data then
            CError("CommonItemIcon:DoUpdate Data is nil id:"..self.IconParams.ItemId)
            return
        end
        ---@type CommonShowTipsData
        local Params = {
            IconParam = {
                IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
                ItemId = self.IconParams.ItemId,
            },
            Tittle = Data:GetName(),
            SubTittle = Data:GetCurQualityCap(),
            Desc = Data:GetDesc(),
            DetailDesc = StringUtil.Format(Data:GetCondition(), Data:GetCondiNum()),
            IsHideBtnOutside = IsFromHover,
            FocusWidget = self.View,
            ShowOneLine = true,
            GetTimeStr = Data:GetTimeStr(),
            Quality = Data.Quality,
            StateStr = Data:GetStateStr()
        }
        MvcEntry:OpenView(ViewConst.CommonBaseTip, Params)
    end
end

-- 关闭Tips
function CommonItemIcon:HideTips()
    local ViewId
    if (self.ClickFuncType == CommonItemIcon.CLICK_FUNC_TYPE.TIP or self.HoverFuncType == CommonItemIcon.HOVER_FUNC_TYPE.TIP) then
        if self.IconType == CommonItemIcon.ICON_TYPE.PROP then
            ViewId = ViewConst.CommonItemTips
        elseif self.IconType == CommonItemIcon.ICON_TYPE.ACHIEVEMENT then
            ViewId = ViewConst.CommonBaseTip
        end
    end
    if ViewId and MvcEntry:GetModel(ViewModel):GetState(ViewId) then
        MvcEntry:CloseView(ViewId)
    end
end

function CommonItemIcon:PopError(ErrorStr)
    CError(ErrorStr)
    print_trackback()
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
end

-- 绑定红点
function CommonItemIcon:RegisterRedDot()
    local IsHasRedDot = self.RedDotKey and true or false
    self.View.WBP_RedDotFactory:SetVisibility(IsHasRedDot and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if IsHasRedDot then
        local RedDotKey = self.RedDotKey
        local RedDotSuffix = self.RedDotSuffix
        if not self.ItemRedDot then
            self.ItemRedDot = UIHandler.New(self, self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        else 
            self.ItemRedDot:ChangeKey(RedDotKey, RedDotSuffix)
        end 
    end
end

-- 红点触发逻辑
---@param TriggerType number 红点触发操作类型
function CommonItemIcon:InteractRedDot(TriggerType)
    if self.RedDotInteractType ~= CommonConst.RED_DOT_INTERACT_TYPE.NONE and self.RedDotInteractType == TriggerType then
        if self.RedDotKey and self.ItemRedDot then
            self.ItemRedDot:Interact()
        end 
    end
end

function CommonItemIcon:GetItemId()
    return self.IconParams and self.IconParams.ItemId or 0
end

------ 角标变动相关事件

function CommonItemIcon:OnCheckItemCountCornerTag()
    if not (self.IconParams and self.IconParams.IconType == CommonItemIcon.ICON_TYPE.PROP) or self.IconParams.IsNotCheckItemCountCornerTag then
        return
    end
    self:CheckItemMaxCount()
    self:_UpdateShowStatus()
end

function CommonItemIcon:OnCheckAchievementCornerTag(Param)
    if not (self.IconParams and self.IconParams.IconType == CommonItemIcon.ICON_TYPE.ACHIEVEMENT) or self.IconParams.IsNotCheckAchievementCornerTag then
        return
    end
    if Param.Id ~= self.IconParams.ItemId and Param.OldId ~= self.IconParams.ItemId then
        return
    end
    self:CheckAchieveItemCornerTag()
    self:_UpdateShowStatus()
end


----------------------双击相关逻辑:非增强输入模式 >>

---双击事件
function CommonItemIcon:OnDoubleClickCallFunc()
    if self.DoubleClickCallFunc then
        local Params = {
            Icon = self.View,
            ItemId = self.IconParams.ItemId,
        }
        self.DoubleClickCallFunc(Params)
    end
end

---检查是否双击
function CommonItemIcon:CheckIsDoubleClickInner()
    if self.IconParams.bUseBtnEnhanced or self.DoubleClickCallFunc == nil then
        return
    end
    local UtcNow = UE.UKismetMathLibrary.UtcNow()
    -- CLog(string.format("CheckIsDoubleClick 1 UtcNow = %s,self.NoteId = %s, self.CheckTime = %s",tostring(UtcNow),tostring(self.NoteId),tostring(self.CheckTime)))
    if self.CheckTime then
        local tt = UE.UKismetMathLibrary.Subtract_DateTimeDateTime(UtcNow, self.CheckTime)
        local tt2 = UE.UKismetMathLibrary.GetTotalMilliseconds(tt)
        -- local tt3 = UE.UKismetMathLibrary.GetMilliseconds(tt)
        -- CError(string.format("CheckIsDoubleClick 2 UtcNow - self.CheckTime = %s,tt3=%s",tostring(tt2), tostring(tt3)))
        if tt2 < CommonConst.DOUBLECLICKTIME * 1000 then
            -- 成功双击
            self:OnDoubleClickCallFunc()
        end
        self:ResetDoubleClickDataInner()
    else
        self.CheckTime = UtcNow

        self:ClearDoubleClickResetTimerInner()
        self.DoubleClickResetTimer = self:InsertTimer(CommonConst.DOUBLECLICKTIME, function()
            self:ResetDoubleClickDataInner()
        end, false)
    end
end

---重置双击数据
function CommonItemIcon:ResetDoubleClickDataInner()
    self.CheckTime = nil
    self:ClearDoubleClickResetTimerInner()
end

function CommonItemIcon:ClearDoubleClickResetTimerInner()
    if self.DoubleClickResetTimer then
        self:RemoveTimer(self.DoubleClickResetTimer)
    end
    self.DoubleClickResetTimer = nil
end

----------------------双击相关逻辑:非增强输入模式 <<

return CommonItemIcon
