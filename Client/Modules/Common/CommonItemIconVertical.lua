--[[
    针对 WBP_CommonItemVertical 逻辑处理
]]
local class_name = "CommonItemIconVertical"
CommonItemIconVertical = BaseClass(UIHandlerViewBase, class_name)

---@class CommonItemIconParam
---@field ItemId number 配置ID
---@field ItemUniqId number?  道具唯一ID
---@field ReplaceIconPath string? 替换的Item图片
---@field ItemNum number? 展示数量
---@field ShowCount number?  是否展示数字，默认为true
---@field DecomposeInfo table? 分解信息，如果没有则为 nil     --     ItemId = 1,  [Optional] : 分解之后的物品id  --     ItemNum = 1, [optional] : 分解之后的物品数量
---@field ShowItemName boolean? 是否显示名称默认不显示
---@field OmitWhenOverMax boolean? 是否省略数量为999+,默认为false
---@field ShowEmpty boolean? 当此字段设置为true，并且没有给出itemId的时候，会显示为空状态
---@field ItemParentScale number? 受父节点影响的缩放值，例如有某一层父节点为ScaleBox。用于计算Tips的位置
-- 交互相关
---@field ClickCallBackFunc function? 点击回调
---@field PressCallBackFunc function? 点击回调
---@field ReleaseCallBackFunc function? 点击回调
---@field HoverCallBackFunc function? Hover回调
---@field UnhoverCallBackFunc function? Unhover回调
---@field IsBreakClick boolean? 是否在执行完ClickCallBackFunc后终止，不往下执行其余逻辑
---@field IsBreakHover boolean? 是否在执行完HoverCallBackFunc后终止，不往下执行其余逻辑
---@field IsBreakUnhover boolean? 是否在执行完UnhoverCallBackFunc后终止，不往下执行其余逻辑
---@field HoverScale number? OnHover时放大自身，默认为1，即不放大
---@field ClickMethod EButtonClickMethod.Type? 
-- 红点相关
---@field RedDotKey number|string? 红点前缀
---@field RedDotSuffix number|string? 红点后缀
---@field RedDotInteractType number CommonConst.RED_DOT_INTERACT_TYPE? 红点触发类型
-- 状态&角标相关
---@field SubScriptScale number? 右上角标签缩放
---@field IsGot boolean? 是否已领取 默认为false
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
---@field IsCheckAchievementCornerTag boolean? 是否检测达到数量上限标识 默认为false

function CommonItemIconVertical:OnInit()
    self.MsgList = {
        {Model = CommonModel, MsgName = CommonModel.CHECK_ITEM_COUNT_CORNER_TAG, Func = self.OnCheckItemCountCornerTag},
        {Model = CommonModel, MsgName = CommonModel.CHECK_ACHIEVEMENT_CORNER_TAG, Func = self.OnCheckAchievementCornerTag},
    }
    self.BindNodes = {}
    self:Init()
end

function CommonItemIconVertical:Init()
    self.IconParams = nil
    self.ClickCallBackFunc = nil
    self.HoverCallBackFunc = nil
    self.NoHoverScale = false

    self.View.ImageIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.GUIImageBtnBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
 
    self.SubScriptDefaultScale = 1
    self:Clear()
end

function CommonItemIconVertical:Clear()
    self.ItemShowState =  CommonConst.ITEM_SHOW_STATE_DEFINE.NONE
    self.LeftCornerTagId = 0    -- 左上角角标Id
    self.LeftCornerTagWordId = 0
    self.RightCornerTagId = 0   -- 右上角角标Id
    self.RightCornerTagWordId = 0
    self.MidCornerTagId = 0 -- 中心角标Id
    self.MidCornerTagWordId = 0

    if self.BindNodes then
        MsgHelper:OpDelegateList(self.View, self.BindNodes, false)
        self.BindNodes = {}
    end
end

function CommonItemIconVertical:OnShow(Param)
    if Param then
        self:UpdateUI(Param)
    end
end

function CommonItemIconVertical:OnManualShow(Param)
    if Param then
        self:UpdateUI(Param)
    end
end

function CommonItemIconVertical:OnManualHide(Param)
end

function CommonItemIconVertical:OnHide(Param)
	self:Clear()
end

--- func desc
---@param Param CommonItemIconParam
---@param NotInit boolean
function CommonItemIconVertical:UpdateUI(Param, NotInit)
    if not NotInit then
        self:Init()
    end
    self.IconParams = Param
    if not self.IconParams then
        self:PopError("CommonItemIconVertical:UpdateUI IconParams Error")
        return
    end

    if self.IconParams.ItemId == nil or self.IconParams.ItemId <= 0 or self.IconParams.ShowEmpty then
        -- TODO 展示默认底图
        print(string.format("CommonItemIconVertical:UpdateUI ItemId = %s; ShowEmpty = %s Use Default Show!", tostring(self.IconParams.ItemId), tostring(self.IconParams.ShowEmpty)))
        if CommonUtil.IsValid(self.View.WidgetSwitcher_Content) and CommonUtil.IsValid(self.View.Empty) then
            self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.Empty)
        else
            self:PopError("CommonItemIconVertical:UpdateUI ItemId Error")
        end
        return
    end

    if CommonUtil.IsValid(self.View.WidgetSwitcher_Content) and CommonUtil.IsValid(self.View.Content) then
        self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.Content)
    end

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
    if Param.PressCallBackFunc then
        self.PressCallBackFunc = Param.PressCallBackFunc;
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

    if self.ClickCallBackFunc ~= nil then
        self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.MainBtn.OnClicked,Func = Bind(self,self.OnIconBtnClicked)}
    end
    if self.PressCallBackFunc then
        self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.MainBtn.OnPressed,Func = Bind(self,self.OnIconBtnPress)}
    end
    if self.ReleaseCallBackFunc then
        self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.MainBtn.OnReleased,Func = Bind(self,self.OnIconBtnReleased)}
    end
    self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.MainBtn.OnHovered,Func = Bind(self,self.OnIconBtnHoverd)}
    self.BindNodes[#self.BindNodes + 1] = {UDelegate = self.View.MainBtn.OnUnhovered,Func = Bind(self,self.OnIconBtnUnhoverd)}

    if Param.ClickMethod then
        self.View.MainBtn:SetClickMethod(Param.ClickMethod)
    end

    self:ReRegister()
    self:DoUpdate()
end

function CommonItemIconVertical:DoUpdate()
    if not self.IconParams then
        return
    end

  
    
    -- 道具
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, self.IconParams.ItemId)
    if not ItemCfg then
        self:PopError("CommonItemIconVertical:DoUpdate GetItemConfig Error!")
        return
    end

    local SubType = ItemCfg[Cfg_ItemConfig_P.SubType]

    --获取 IconPath,优先使用 ReplaceIconPath 字段,其次用  Cfg_ItemConfig_P.ImagePath 字段
    local IconPath = self.IconParams.ReplaceIconPath and self.IconParams.ReplaceIconPath or ItemCfg[Cfg_ItemConfig_P.ImagePath]

    local Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
    self:SetShowCount(self.IconParams.ItemNum)

    self.View.Root_SubScriptScale:SetUserSpecifiedScale(self.SubScriptScale)

    self:CheckCornerTag()
    self:SetIsGot(self.IconParams.IsGot,true)
    self:SetIsLock(self.IconParams.IsLock,true)
    self:UpdateIcon(IconPath, SubType)
    self:UpdateQuality(Quality)
    self:_UpdateShowStatus()
    self:RegisterRedDot()
end

function CommonItemIconVertical:PopError(ErrorStr)
    CError(ErrorStr)
    print_trackback()
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
end

-- 更新Icon资源
function CommonItemIconVertical:UpdateIcon(IconPath, SubType)
    if SubType == DepotConst.ItemSubType.Background then
        self.View.ImageIcon:SetVisibility(UE.ESlateVisibility.Collapsed)

        if CommonUtil.IsValid(self.View.ImageDisplay1) then
            self.View.ImageDisplay1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            CommonUtil.SetBrushFromSoftObjectPath(self.View.ImageDisplay1, IconPath)
        end
        if CommonUtil.IsValid(self.View.ImageDisplay2) then
            self.View.ImageDisplay2:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        self.View.ImageIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.ImageIcon, IconPath)
        -- self.View.ImageIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- local IconImg = LoadObject(IconPath)
        -- if IconImg then
        --     self.View.ImageIcon:SetBrushFromTexture(IconImg)
        --     self.View.ImageIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- end

        if CommonUtil.IsValid(self.View.ImageDisplay1) then
            self.View.ImageDisplay1:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        if CommonUtil.IsValid(self.View.ImageDisplay2) then
            self.View.ImageDisplay2:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        
    end
end

-- 品质色
function CommonItemIconVertical:UpdateQuality(Quality)
    CommonUtil.SetQualityBgVertical(self.View.GUIImageBtnBg, Quality)
end

-- 设置数量
function CommonItemIconVertical:SetShowCount(Count)
    if not(CommonUtil.IsValid(self.View.TextNum)) then
        return
    end
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

------------------------------------------------红点 >>

-- 绑定红点
function CommonItemIconVertical:RegisterRedDot()
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
function CommonItemIconVertical:InteractRedDot(TriggerType)
    if self.RedDotInteractType ~= CommonConst.RED_DOT_INTERACT_TYPE.NONE and self.RedDotInteractType == TriggerType then
        if self.RedDotKey and self.ItemRedDot then
            self.ItemRedDot:Interact()
        end 
    end
end

------------------------------------------------红点 <<

------------------------------------------------Tag角标 >>

-- 设置IsGot状态
function CommonItemIconVertical:SetIsGot(IsGot,IsInit)
    if IsGot then
        if self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NONE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.GOT then
            CWaring("CommonItemIconVertical ShowState Will Change To Got From "..self.ItemShowState,true)
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

-- 同时设置选中和锁定状态
function CommonItemIconVertical:SetState(Param)
    self.IsSelect = Param.IsSelect
    self.NoHoverScale = self.IsSelect

    self.IsLock = Param.IsLock
    
    self:_UpdateState_VXE()
end

-- 设置选中(外部调用)
-- NoHoverScale 设为true，则当IsSelect为true时，OnHover的时候，不会放大
-- IsMulti 是否为多选
function CommonItemIconVertical:SetIsSelect(IsSelect, NoHoverScale, IsMulti)
    self.IsSelect = IsSelect
    self.NoHoverScale = NoHoverScale and self.IsSelect
    -- todo IsMulti 替换选中框图片
    self:_SetIsShowSelectedImg(IsSelect)
end

-- 选中图标(内部逻辑)
function CommonItemIconVertical:_SetIsShowSelectedImg(IsShow)
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

-- 设置锁定状态
function CommonItemIconVertical:SetIsLock(IsLock, IsInit)
    self.IsLock = IsLock
    if IsLock then
        if self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NONE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.LOCK then
            CWaring("CommonItemIconVertical ShowState Will Change To Lock From "..self.ItemShowState,true)
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
        self:_UpdateState_VXE()
    end
end

-- 更新锁定&选中状态
function CommonItemIconVertical:_UpdateState_VXE()
    -- UX动效控制效果
    if self.IsLock then self.View:VXE_Btn_Bg_Lock() else self.View:VXE_Btn_Bg_Unlock() end
    if self.IsSelect then self.View:VXE_Btn_Select() else self.View:VXE_Btn_UnSelect() end
end

-- 设置过期状态
function CommonItemIconVertical:SetIsOutOfDate(IsOutOfDate,IsInit)
    if IsOutOfDate then
        if self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NONE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.OUTOFDATE then
            CWaring("CommonItemIconVertical ShowState Will Change To OUTOFDATE From "..self.ItemShowState,true)
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
function CommonItemIconVertical:SetIsNew(IsNew,IsInit)
    if IsNew then
        if self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NONE and self.ItemShowState ~= CommonConst.ITEM_SHOW_STATE_DEFINE.NEW then
            CWaring("CommonItemIconVertical ShowState Will Change To NEW From "..self.ItemShowState,true)
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

-- 检测角标
function CommonItemIconVertical:CheckCornerTag()
    if not self.IconParams then
        return
    end

    self:CheckPropItemCornerTag()

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

function CommonItemIconVertical:SetCornerTag(TagParam)
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
function CommonItemIconVertical:_UpdateShowStatus()
    -- self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.View.Img_Countdown_MI:SetVisibility(UE.ESlateVisibility.Collapsed)    
    -- self.View.Img_NewGetFrame:SetVisibility(UE.ESlateVisibility.Collapsed)    
        
    -- -- 遮罩设置
    -- if self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.LOCK then
    --     self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     self.View.ImgBg_Mask:SetColorAndOpacity(self.View.MaskColor_Lock)
    -- elseif self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.GOT then
    --     self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     self.View.ImgBg_Mask:SetColorAndOpacity(self.View.MaskColor_Got)
    -- elseif self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.OUTOFDATE then
    --     self.View.ImgBg_Mask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     self.View.ImgBg_Mask:SetColorAndOpacity(self.View.MaskColor_OutOfDate)
    -- elseif self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.TIMER then
    --     self.View.Img_Countdown_MI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)   
    --     -- todo 开启倒计时
    -- elseif self.ItemShowState == CommonConst.ITEM_SHOW_STATE_DEFINE.NEW then
    --     self.View.Img_NewGetFrame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)    
    -- end

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

    -- local ParamMid = {
    --     TagPos = CommonConst.CORNER_TAGPOS.Mid,
    --     TagId = self.MidCornerTagId,
    --     TagWordId = self.MidCornerTagWordId,
    --     TagHeroId = self.MidCornerTagHeroId,
    --     TagHeroSkinId = self.MidCornerTagHeroSkinId,
    -- }
    -- self:_SetCornerTagShow(ParamMid)
end


function CommonItemIconVertical:_SetCornerTagShow(TagParam)
    local TagPos = TagParam.TagPos
    local TagPanel = self.View["CornerTag_"..TagPos]
    if not TagPanel then
        CError("CommonItemIconVertical:_SetCornerTagShow Not Found Panel For Pos = "..TagPos)
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

    local TagImgWdiget = self.View["CornerTagImg_"..TagPos]
    local Tag_HeroHeadWidget = self.View["CornerTag_HeroHead_"..TagPos]
    local TagText_ImgWidget = self.View["CornerTagText_Img_"..TagPos]
    local TagText_WordWiget = self.View["CornerTagText_Word_"..TagPos]
    if CommonUtil.IsValid(TagImgWdiget) then
        TagImgWdiget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if CommonUtil.IsValid(Tag_HeroHeadWidget) then
        Tag_HeroHeadWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if CommonUtil.IsValid(TagText_ImgWidget) then
        TagText_ImgWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if CommonUtil.IsValid(TagText_WordWiget) then
        TagText_WordWiget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    local TagType = CornerTagCfg[Cfg_CornerTagCfg_P.TagType]
    if TagType == CommonConst.CORNER_TYPE.IMG then
        CommonUtil.SetCornerTagImg(TagImgWdiget, TagId)
    elseif TagType == CommonConst.CORNER_TYPE.HERO_HEAD then
        CommonUtil.SetCornerTagHeroHead(TagImgWdiget, Tag_HeroHeadWidget, TagParam.TagHeroId, TagParam.TagHeroSkinId)
    elseif TagType == CommonConst.CORNER_TYPE.WORD then
        CommonUtil.SetCornerTagWord(TagText_ImgWidget, TagText_WordWiget, TagParam.TagWordId)
    end
end

------------------------------------------------Tag角标 <<


------------------------------------------------BtnEvent >>
-- 点击图标
function CommonItemIconVertical:OnIconBtnClicked()
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

        if self.IconParams.IsBreakClick then
            return
        end
    end
end



function CommonItemIconVertical:OnIconBtnPress()
    if not self.IconParams then
        return
    end
    self.BeginCick = false
    local Params = {
        Handle = self,
        Icon = self.View,
        ItemId = self.IconParams.ItemId,
        -- DragType = CommonConst.DRAG_TYPE_DEFINE.DRAG_BEGIN
    }

    if self.PressCallBackFunc then
        self.PressCallBackFunc(Params);
    end
end

function CommonItemIconVertical:OnIconBtnReleased()
    if not self.IconParams then
        return
    end

    local Params = {
        Handle = self,
        Icon = self.View,
        ItemId = self.IconParams.ItemId,
        -- DragType = CommonConst.DRAG_TYPE_DEFINE.NONE
    }

    if self.BeginCick then
        -- Params.DragType = CommonConst.DRAG_TYPE_DEFINE.DRAG_END
        self.BeginCick = false
    else
        -- Params.DragType = CommonConst.DRAG_TYPE_DEFINE.CLICK
    end
     
    if self.ReleaseCallBackFunc then
        self.ReleaseCallBackFunc(Params);
    end
end

-- Hover图标
function CommonItemIconVertical:OnIconBtnHoverd()
    -- print("OnIconBtnHoverd")
    if not self.IconParams then
        return
    end
    if self.IconParams.HoverScale and self.IconParams.HoverScale > 1 then
        self.OriScale = UE.FVector2D(self.View.RenderTransform.Scale.X,self.View.RenderTransform.Scale.Y)
        if not self.NoHoverScale then
            self.View:SetRenderScale(UE.FVector2D(self.IconParams.HoverScale,self.IconParams.HoverScale))
        end
    end
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


end

--Unhover
function CommonItemIconVertical:OnIconBtnUnhoverd()
    -- print("OnIconBtnUnhoverd")
    if not self.IconParams then
        return
    end
    if self.IconParams.HoverScale and self.IconParams.HoverScale > 1 then
        self.View:SetRenderScale(self.OriScale)
    end
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
end

------------------------------------------------BtnEvent <<



------------------------------------------------角标变动相关事件 <<

------ 角标变动相关事件


-- 检测设置道具类型图标的角标
function CommonItemIconVertical:CheckPropItemCornerTag()
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
function CommonItemIconVertical:CheckItemMaxCount()
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


-- -- 检测设置成就类型图标的角标
-- function CommonItemIconVertical:CheckAchieveItemCornerTag()
--     if not self.IconParams then
--         return
--     end
--     local Model = MvcEntry:GetModel(AchievementModel)
--     local Data = Model:GetData(self.IconParams.ItemId)
--     if not Data then
--         return
--     end
--     -- 仅处理右角标，有其余的再自行拓展
--     local Param = { TagPos = CommonConst.CORNER_TAGPOS.Right}
--     if Data:IsEquiped() then
--         Param.TagId = CornerTagCfg.Equipped.TagId
--     elseif Data:IsDeleted() then
--         -- todo
--     elseif Data:IsDrag() then
--         -- todo
--     elseif Data:IsNoOperation() then
--         -- todo
--     end
--     self:SetCornerTag(Param)
--     self:SetIsLock(not Data:IsUnlock(),true)
-- end

function CommonItemIconVertical:OnCheckItemCountCornerTag()

    self:CheckItemMaxCount()
    self:_UpdateShowStatus()
end

function CommonItemIconVertical:OnCheckAchievementCornerTag(Param)

    if Param.Id ~= self.IconParams.ItemId and Param.OldId ~= self.IconParams.ItemId then
        return
    end
    self:CheckAchieveItemCornerTag()
    self:_UpdateShowStatus()
end

------------------------------------------------角标变动相关事件 <<


function CommonItemIconVertical:GetItemId()
    return self.IconParams and self.IconParams.ItemId or 0
end


return CommonItemIconVertical