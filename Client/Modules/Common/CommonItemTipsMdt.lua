--[[
    通用道具Tips界面
]]

local class_name = "CommonItemTipsMdt";
CommonItemTipsMdt = CommonItemTipsMdt or BaseClass(GameMediator, class_name);

function CommonItemTipsMdt:__init()
end

function CommonItemTipsMdt:OnShow(data)
end

function CommonItemTipsMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.WBP_CommonTipsView.BtnOutSide.OnClicked,	Func = self.GUIButton_Close_ClickFunc },
	}
    -- 这个界面无需输入事件，强制关闭WidgetFocus;避免当icon在滑动列表中，tips的显隐打乱了icon的Btn和列表直接的输入
    self.CloseWidgetFocus = true
end

--由mdt触发调用
--[[
    Param = {
        ItemId: 配置ID
        ItemUniqId [Optional] : 道具唯一ID
        ItemNum [Optional]: 展示数量
        ExpireTime [Optional]: 过期截止时间

        IsHideBtnOutside [Optional]: 传入true,会隐藏点击空白关闭功能。避免影响上层界面交互 （通常通过Hover打开此界面时需要)
        FocusWidget [Optional]: 附着的节点，传入则会将位置设置在该节点四周可放入位置
        FocusOffset [Optional]: 采样位置偏移 FVector2D
    }
]]
function M:OnShow(Params)
    if not Params or not Params.ItemId then
        CError("CommonItemTipsMdt Param Error")
        print_trackback()
        self:DoClose()
        return
    end
    self.Params = Params
    self.ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.Params.ItemId)
    if not self.ItemCfg then
        CError("CommonItemTipsMdt GetItemConfig Error; ItemId = "..Params.ItemId)
        print_trackback()
        self:DoClose()
        return
    end
    self.WBP_CommonTipsView.BtnOutSide:SetVisibility(self.Params.IsHideBtnOutside and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
    self:UpdateShow()
    self:AdjustShowPos()
end

function M:OnRepeatShow(Params)
    self:OnShow(Params)
end

function M:UpdateShow()
    -- Icon
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = self.Params.ItemId,
        ItemUniqId = self.Params.ItemUniqId or 0,
        -- ItemNum = self.Params.ItemNum or 0,
        ExpireTime = self.Params.ExpireTime or 0,
        ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
    }
    if not self.ItemIconCls then
        self.ItemIconCls = UIHandler.New(self,self.WBP_CommonTipsView.WBP_CommonItemIcon,CommonItemIcon,IconParam).ViewInstance
    else
        self.ItemIconCls:UpdateUI(IconParam)
    end

    local ItemCfg = self.ItemCfg
    local DepotModel = MvcEntry:GetModel(DepotModel)
    -- 名字
    self.WBP_CommonTipsView.GUITextBlockName:SetText(StringUtil.Format(ItemCfg[Cfg_ItemConfig_P.Name]))
    -- 类型名字
    self.WBP_CommonTipsView.Text_TypeName:SetText(StringUtil.Format(DepotModel:GetItemTypeShowByItemId(self.Params.ItemId,true)))
    -- 品质
    local Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
    if QualityCfg then
        -- local QualityName = QualityCfg[Cfg_ItemQualityColorCfg_P.QualityName]
        local ItemId = self.Params.ItemId
        local Widgets = {
            QualityBar = self.WBP_CommonTipsView.QualityBar,
            QualityIcon = self.WBP_CommonTipsView.GUIImageQuality,
            --QualityLevelText = self.WBP_CommonTipsView.GUITextBlock_QualityLevel,
        }
        CommonUtil.SetQualityShow(ItemId,Widgets)
        local QualityColor = UE.UGFUnluaHelper.FLinearColorFromHex(QualityCfg[Cfg_ItemQualityColorCfg_P.HexColor])
        local TheSlateColor = UE.FSlateColor()
        TheSlateColor.SpecifiedColor = QualityColor
        -- self.BorderQuality:SetBrushColor(QualityColor)
        -- self.LbQuality:SetText(StringUtil.Format(QualityName))
        -- CommonUtil.SetTextColorFromQuality(self.LbQuality,Quality)
        -- self.WBP_CommonTipsView.Bg_Line:SetBrushTintColor(CommonUtil.Conv_FLinearColor2FSlateColor(QualityColor))
        CommonUtil.SetBrushFromSoftObjectPath(self.WBP_CommonTipsView.Bg_Quality,QualityCfg[Cfg_ItemQualityColorCfg_P.CommonTipsBg])
        self.WBP_CommonTipsView.Text_TypeName:SetColorAndOpacity(TheSlateColor)
    end
        
    -- 描述
    self.WBP_CommonTipsView.LbTitle:SetText(ItemCfg[Cfg_ItemConfig_P.Des])
    if ItemCfg[Cfg_ItemConfig_P.DetailDes] and string.len(ItemCfg[Cfg_ItemConfig_P.DetailDes]) > 0 then
        self.WBP_CommonTipsView.LbDetails:SetText(ItemCfg[Cfg_ItemConfig_P.DetailDes])
        self.WBP_CommonTipsView.GUIOverlay_Des:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.WBP_CommonTipsView.GUIOverlay_Des:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    

    -- 已拥有/达到数量上限 文字显示
    local MaxCount = ItemCfg[Cfg_ItemConfig_P.MaxCount]
    if MaxCount > 0 then
        local HaveItemNum = 0
        if self.Params.ItemUniqId then
            HaveItemNum = DepotModel:GetItemCountByUniqId(self.Params.ItemUniqId)
        else
            HaveItemNum = DepotModel:GetItemCountByItemId(self.Params.ItemId)
        end
        if HaveItemNum >= MaxCount then
            self.WBP_CommonTipsView.Text_FullTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.WBP_CommonTipsView.Text_FullTips:SetText(StringUtil.Format(MaxCount>1 and G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonItemTipsMdt_Reachtheupperlimit") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonItemTipsMdt_Alreadyowned")))
        else
            self.WBP_CommonTipsView.Text_FullTips:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        self.WBP_CommonTipsView.Text_FullTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    -- 时间
    self.WBP_CommonTipsView.OverlayDate:SetVisibility(UE.ESlateVisibility.Collapsed)
    local CurTime = GetTimestamp()
    if self.Params.ExpireTime and self.Params.ExpireTime > 0 then
        -- 服务器传入的过期时间
        self.LeftTime = self.Params.ExpireTime - CurTime
        if self.LeftTime > 0 then
            self.WBP_CommonTipsView.OverlayDate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self:UpdateTimeShow()
            self:ScheduleTimeShowTick()
        else
            self:ClearTimeShowTick()
            self.WBP_CommonTipsView.OverlayDate:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    elseif  ItemCfg[Cfg_ItemConfig_P.TimeType] > 0 then
        -- 读取配置是否有限时
        --[[
            - 如果物品时限类别为1（获取后计时）
                - 时间＜1小时，则显示为“有效期：x分钟”
                - 时间＜1天，则显示为“有效期：x小时”
                - 时间≥1天，则显示为“有效期：x天”，向下取整
            - 如果物品时限类别为2、3（自然日时限），则黄字显示为“有效期：x月x日”
                - 自然日为今年，则显示为“有效期：x月x日”
                - 自然日不为今年，则显示为“有效期：x年x月x日”
        ]]
        local TimeType = ItemCfg[Cfg_ItemConfig_P.TimeType]
        local TimeStr = ItemCfg[Cfg_ItemConfig_P.TimeStr]
        local Str = ""
        if TimeType == 1 then
            local Seconds = tonumber(TimeStr)
            if not Seconds then
                return
            end
            local Minutes = math.floor(Seconds / 60)
            local Hours = math.floor(Seconds / 3600)
            local Days = math.floor(Seconds / 86400)
            if Seconds < 3600 then
                Str = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), Minutes, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonItemTipsMdt_minute"))
            elseif Seconds < 3600 * 24 then
                Str = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), Hours, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonItemTipsMdt_hour"))
            else
                Str = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), Days, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonItemTipsMdt_sky"))              
            end
        elseif TimeType == 2 or TimeType == 3 then
            -- 当日过期 or 次日过期
            local Year, Month, Day = TimeStr:match("(%d+)-(%d+)-(%d+)")
            if Year and Month and Day then
                local CurYear = tonumber(os.date("%Y",GetTimestamp()))
                if TimeType == 3 then
                    -- 次日过期
                    Day = Day + 1
                end
                Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonItemTipsMdt_monthday"),Month,Day)
                if CurYear and CurYear ~= tonumber(Year) then
                    Str = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_ThreeParam"), Year, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonItemTipsMdt_year"), Str)
                end
            end
        end
        self.WBP_CommonTipsView.LbDateTime:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonItemTipsMdt_Periodofvalidity"),Str))
        CommonUtil.SetTextColorFromeHex(self.WBP_CommonTipsView.LbDateTime,DepotConst.TimeTextColor.Normal)
        CommonUtil.SetBrushTintColorFromHex(self.WBP_CommonTipsView.GUIImage_Time,DepotConst.TimeTextColor.Normal)
        self.WBP_CommonTipsView.OverlayDate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    -- 分解
    self.WBP_CommonTipsView.Panel_Decompose:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.Params.DecomposeInfo then
        self.WBP_CommonTipsView.Panel_Decompose:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- 分解前图标
        local BeforeIconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = self.Params.ItemId,
            ItemNum = self.Params.ItemNum or 0,
            ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
        }
        if not self.DecomposeIconClsBefore then
            self.DecomposeIconClsBefore = UIHandler.New(self,self.WBP_CommonTipsView.WBP_CommonItemIcon_Before,CommonItemIcon,BeforeIconParam).ViewInstance
        else
            self.DecomposeIconClsBefore:UpdateUI(IconParam)
        end

        -- 分解后图标
        local AfterIconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = self.Params.DecomposeInfo.ItemId,
            ItemNum = self.Params.DecomposeInfo.ItemNum or 0,
            ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
        }
        if not self.DecomposeIconClsAfter then
            self.DecomposeIconClsAfter = UIHandler.New(self,self.WBP_CommonTipsView.WBP_CommonItemIcon_After,CommonItemIcon,AfterIconParam).ViewInstance
        else
            self.DecomposeIconClsAfter:UpdateUI(IconParam)
        end

        -- 分解后名称
        local AfterItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.Params.DecomposeInfo.ItemId)
        self.WBP_CommonTipsView.GUITextBlock_AfterName:SetText(StringUtil.Format(AfterItemCfg[Cfg_ItemConfig_P.Name]))
        CommonUtil.SetTextColorFromQuality(self.WBP_CommonTipsView.GUITextBlock_AfterName,AfterItemCfg[Cfg_ItemConfig_P.Quality])
    end
end

-- 更新剩余时间显示
function M:UpdateTimeShow()
    if not CommonUtil.IsValid(self) then
        self:ClearTimeShowTick()
        print("CommonItemTipsMdt Already Releaed")
        return
    end
    local Str,Color = StringUtil.Conv_TimeShowStr(self.LeftTime,self.Params.ExpireTime)
    self.LbDateTime:SetText(Str)
    CommonUtil.SetTextColorFromeHex(self.WBP_CommonTipsView.LbDateTime,Color)
    CommonUtil.SetBrushTintColorFromHex(self.WBP_CommonTipsView.GUIImage_Time,Color)
end

-- 计算浮窗出现的位置
function M:AdjustShowPos()
    self.WBP_CommonTipsView.OverlayTips:SetRenderScale(UE.FVector2D(0.001,0.001))
    self:ClearPopTimer()
    -- Icon按钮存在Hover放大效果，下一帧再进行位置计算，避免放大影响了Position计算
    self.PopTimer = Timer.InsertTimer(-1,function ()
        if not CommonUtil.IsValid(self.WBP_CommonTipsView.OverlayTips) then
            return
        end
        self.WBP_CommonTipsView.OverlayTips:SetRenderScale(UE.FVector2D(1,1))
        self.WBP_CommonTipsView.OverlayTips:ForceLayoutPrepass()
        local ViewportSize = CommonUtil.GetViewportSize(self)
        -- local PanelSize = UE.USlateBlueprintLibrary.GetLocalSize(self.OverlayTips:GetCachedGeometry())
        local PanelSize = self.WBP_CommonTipsView.OverlayTips:GetDesiredSize()
        if not self.Params.FocusWidget then
            -- 没有要附着的点就居中显示
            self.WBP_CommonTipsView.OverlayTips.Slot:SetPosition(UE.FVector2D(ViewportSize.x/2-PanelSize.x/2,-ViewportSize.y/2+PanelSize.y/2))
        else
            local ShowPosition = self:CalculateFocusPos(ViewportSize,PanelSize)
            self.WBP_CommonTipsView.OverlayTips.Slot:SetPosition(ShowPosition)
        end
    end)
end

function M:ClearPopTimer()
    if self.PopTimer then
        Timer.RemoveTimer(self.PopTimer)
    end
    self.PopTimer = nil
end
 
-- 计算在附着点的哪一侧位置显示
function M:CalculateFocusPos(ViewportSize,PanelSize)
    local _,FocusPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,self.Params.FocusWidget:GetCachedGeometry(),self.Params.FocusOffset or UE.FVector2D(0,0))
    local FocusSize = UE.USlateBlueprintLibrary.GetLocalSize(self.Params.FocusWidget:GetCachedGeometry())
    -- local FocusScale = self.Params.FocusWidget.RenderTransform.Scale
    -- local FocusSize = self.Params.FocusWidget:GetDesiredSize()
    local ParentScale = 1
    if self.Params.ParentScale then
        ParentScale = self.Params.ParentScale
    else
        ParentScale = self:CheckParentHaveScaleBoxUserSpecified(self.Params.FocusWidget) 
    end
    FocusSize.X = FocusSize.X * ParentScale
    FocusSize.Y = FocusSize.Y * ParentScale
    local WidgetPaddingRight = 0
    if self.Params.FocusWidget.Padding then
        WidgetPaddingRight = self.Params.FocusWidget.Padding.Right * ParentScale
    end
    local PosX,PosY = 0,0
    local TopPadding = FocusPosition.Y  - PanelSize.Y
    local LeftPadding = FocusPosition.X
    local SafeOffset = 0.5
    local TopSafeOffset = 2
    if TopPadding > 0 then
        -- 优先放顶部
        PosY = ViewportSize.Y - FocusPosition.Y + SafeOffset
        if LeftPadding > PanelSize.X - FocusSize.X then
            -- 优先靠左展示，与Widget右对齐
            PosX = FocusPosition.X - PanelSize.X + FocusSize.X - SafeOffset - WidgetPaddingRight
        else
            -- 靠右展示，与Widget左对齐
            PosX = FocusPosition.X + SafeOffset
        end
    else
        -- 顶部放不下 放左/右侧 与Widget顶对齐
        PosY = ViewportSize.Y - FocusPosition.Y - PanelSize.Y + TopSafeOffset
        if LeftPadding > PanelSize.X then
            -- 靠左显示
            PosX = FocusPosition.X - PanelSize.X - SafeOffset
        else
            -- 靠右显示
            PosX = FocusPosition.X + FocusSize.X + SafeOffset - WidgetPaddingRight
        end
    end
    return UE.FVector2D(PosX,-PosY)
end

-- 往外检测一定层数（目前定3层）的父节点，看是否有ScaleBox进行了自定义Scale设置
function M:CheckParentHaveScaleBoxUserSpecified(FocusWidget)
    local CheckLayerCount = 3
    local TheScale = 1
    if not FocusWidget then
        return TheScale
    end
    local ParentWidget = FocusWidget:GetParent()
    local Count = 1
    while ParentWidget do
        if Count > CheckLayerCount then
            break
        end
        if ParentWidget:IsA(UE.UScaleBox) and ParentWidget.Stretch == UE.EStretch.UserSpecified then
            TheScale = ParentWidget.UserSpecifiedScale
            break
        end
        -- 这里不考虑Parent是WidgetTree的情况了
        ParentWidget = ParentWidget:GetParent()
        Count = Count + 1
    end
    return TheScale
end

-- 时间刷新显示
function M:ScheduleTimeShowTick()
    self:ClearTimeShowTick()
    self.CheckTimer = Timer.InsertTimer(1,function()
        self.LeftTime = self.LeftTime - 1
		self:UpdateTimeShow()
        if self.LeftTime <= 0 then
            self:ClearTimeShowTick()
        end
	end,true)   
end

function M:ClearTimeShowTick()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

function M:OnHide()
    self:ClearTimeShowTick()
    self:ClearPopTimer()
    self.ItemIconCls = nil
    self.DecomposeIconClsBefore = nil
    self.DecomposeIconClsAfter = nil
end

--关闭界面
function M:DoClose()
    MvcEntry:CloseView(self.viewId)
end

--点击关闭界面
function M:GUIButton_Close_ClickFunc()
    self:DoClose()
    return true
end

return M