--[[
    通用道具Tips界面
]]

local class_name = "CommonBaseTipsMdt";
CommonBaseTipsMdt = CommonBaseTipsMdt or BaseClass(GameMediator, class_name);

function CommonBaseTipsMdt:__init()
end

function CommonBaseTipsMdt:OnShow(data)
end

function CommonBaseTipsMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

---@class CommonShowTipsData
---@field IconParam CommonItemIconParam
---@field Tittle string
---@field SubTittle string
---@field ShowOneLine boolean?
---@field GetTimeStr string?
---@field Desc string
---@field DetailDesc string
---@field StateStr string?
---@field Quality number?
---@field HaveItemNum number?
---@field MaxCount number?
---@field TimeType number?
---@field TimeStr string?
---@field BeforeIconParam CommonItemIconParam?
---@field AfterIconParam CommonItemIconParam?
---@field DecomposeInfo table?
---@field IsHideBtnOutside boolean? 传入true,会隐藏点击空白关闭功能。避免影响上层界面交互 （通常通过Hover打开此界面时需要)
---@field FocusWidget boolean? 附着的节点，传入则会将位置设置在该节点四周可放入位置
---@field FocusOffset UE.FVector2D? 采样位置偏移 FVector2D
M.Data = nil

function M:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.WBP_CommonTipsView.BtnOutSide.OnClicked,	Func = self.GUIButton_Close_ClickFunc },
	}
    -- 这个界面无需输入事件，强制关闭WidgetFocus;避免当icon在滑动列表中，tips的显隐打乱了icon的Btn和列表直接的输入
    self.CloseWidgetFocus = true
end

function M:OnShow(Params)
    if not Params then
        CError("CommonBaseTipsMdt Param Error")
        print_trackback()
        self:DoClose()
        return
    end
    self.Data = Params
    self.WBP_CommonTipsView.BtnOutSide:SetVisibility(self.Data.IsHideBtnOutside and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
    self:UpdateShow()
    self:AdjustShowPos()
end

function M:OnRepeatShow(Params)
    self:OnShow(Params)
end

function M:UpdateShow()
    if not self.ItemIconCls then
        self.ItemIconCls = UIHandler.New(self,self.WBP_CommonTipsView.WBP_CommonItemIcon,CommonItemIcon, self.Data.IconParam).ViewInstance
    else
        self.ItemIconCls:UpdateUI(self.Data.IconParam)
    end

    -- 名字
    self.WBP_CommonTipsView.GUITextBlockName:SetText(StringUtil.Format(self.Data.Tittle))
    -- 类型名字
    self.WBP_CommonTipsView.Text_TypeName:SetText(StringUtil.Format(self.Data.SubTittle))
    
    -- 描述
    self.WBP_CommonTipsView.LbTitle:SetText(self.Data.Desc)
    self.WBP_CommonTipsView.LbDetails:SetText(self.Data.DetailDesc)
    self.WBP_CommonTipsView.Text_Level:SetText(self.Data.SubTittle)

    self.WBP_CommonTipsView.Text_Level:SetVisibility(self.Data.ShowOneLine and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.WBP_CommonTipsView.HBox_TypeName:SetVisibility(self.Data.ShowOneLine and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

    -- 品质
    if self.Data.Quality then
        CommonUtil.SetQualityShowForQualityId(self.Data.Quality, {
            QualityBar = self.WBP_CommonTipsView.QualityBar,
            QualityIcon = self.WBP_CommonTipsView.GUIImageQuality,
            -- QualityLevelText = self.WBP_CommonTipsView.GUITextBlock_QualityLevel,
            CommonTipsBg = self.WBP_CommonTipsView.Bg_Quality,
            QualityText =  self.WBP_CommonTipsView.GUITextBlock_QualityLevel,
            -- QualityColorImgs = {
            --     self.WBP_CommonTipsView.Bg_Line
            -- },
            QualityColorTexts = {
                self.WBP_CommonTipsView.Text_TypeName,
                self.WBP_CommonTipsView.Text_Level
            }
        })
    end
   
    -- 已拥有/达到数量上限 文字显示
    if self.Data.MaxCount and self.Data.MaxCount > 0 then
        if self.Data.HaveItemNum >= self.Data.MaxCount then
            self.WBP_CommonTipsView.Text_FullTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.WBP_CommonTipsView.Text_FullTips:SetText(StringUtil.Format(self.Data.MaxCount>1 and G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonBaseTipsMdt_Reachtheupperlimit") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonBaseTipsMdt_Alreadyowned")))
        else
            self.WBP_CommonTipsView.Text_FullTips:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    elseif self.Data.StateStr then
        self.WBP_CommonTipsView.Text_FullTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WBP_CommonTipsView.Text_FullTips:SetText(StringUtil.Format(self.Data.StateStr))
    else
        self.WBP_CommonTipsView.Text_FullTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    -- 时间
    self.WBP_CommonTipsView.OverlayDate:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_CommonTipsView.GUIImage_Time:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local CurTime = GetTimestamp()
    if self.Data.ExpireTime and self.Data.ExpireTime > 0 then
        -- 服务器传入的过期时间
        self.LeftTime = self.Data.ExpireTime - CurTime
        if self.LeftTime > 0 then
            self.WBP_CommonTipsView.OverlayDate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self:UpdateTimeShow()
            self:ScheduleTimeShowTick()
        else
            self:ClearTimeShowTick()
            self.WBP_CommonTipsView.OverlayDate:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    elseif  self.Data.TimeType and self.Data.TimeType > 0 then
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
        local TimeType = self.Data.TimeType
        local TimeStr = self.Data.TimeStr
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
                Str = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), Minutes, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonBaseTipsMdt_minute"))
            elseif Seconds < 3600 * 24 then
                Str = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), Hours, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonBaseTipsMdt_hour"))
            else
                Str = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), Days, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonBaseTipsMdt_sky"))
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
                Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonBaseTipsMdt_monthday"),Month,Day)
                if CurYear and CurYear ~= tonumber(Year) then
                    Str = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_ThreeParam"), Year, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonBaseTipsMdt_year"), Str)
                end
            end
        end
        self.WBP_CommonTipsView.LbDateTime:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonBaseTipsMdt_Periodofvalidity"),Str))
        CommonUtil.SetTextColorFromeHex(self.WBP_CommonTipsView.LbDateTime,DepotConst.TimeTextColor.Normal)
        CommonUtil.SetBrushTintColorFromHex(self.WBP_CommonTipsView.GUIImage_Time,DepotConst.TimeTextColor.Normal)
        self.WBP_CommonTipsView.OverlayDate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    elseif self.Data.GetTimeStr then
        self.WBP_CommonTipsView.OverlayDate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WBP_CommonTipsView.GUIImage_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_CommonTipsView.LbDateTime:SetText(self.Data.GetTimeStr)
        CommonUtil.SetTextColorFromeHex(self.WBP_CommonTipsView.LbDateTime,DepotConst.TimeTextColor.Normal)
    end

    -- 分解
    self.WBP_CommonTipsView.Panel_Decompose:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.Data.DecomposeInfo then
        self.WBP_CommonTipsView.Panel_Decompose:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- 分解前图标
        if not self.DecomposeIconClsBefore then
            self.DecomposeIconClsBefore = UIHandler.New(self,self.WBP_CommonTipsView.WBP_CommonItemIcon_Before,CommonItemIcon,self.Data.BeforeIconParam).ViewInstance
        else
            self.DecomposeIconClsBefore:UpdateUI(self.Data.IconParam)
        end

        -- 分解后图标
        if not self.DecomposeIconClsAfter then
            self.DecomposeIconClsAfter = UIHandler.New(self,self.WBP_CommonTipsView.WBP_CommonItemIcon_After,CommonItemIcon,self.Data.AfterIconParam).ViewInstance
        else
            self.DecomposeIconClsAfter:UpdateUI(self.Data.IconParam)
        end

        -- 分解后名称
        self.WBP_CommonTipsView.GUITextBlock_AfterName:SetText(self.Data.DecomposeInfo.Name)
        CommonUtil.SetTextColorFromQuality(self.WBP_CommonTipsView.GUITextBlock_AfterName,self.Data.DecomposeInfo.Quality)
    end
end

-- 更新剩余时间显示
function M:UpdateTimeShow()
    if not CommonUtil.IsValid(self) then
        self:ClearTimeShowTick()
        print("CommonBaseTipsMdt Already Releaed")
        return
    end
    local Str,Color = StringUtil.Conv_TimeShowStr(self.WBP_CommonTipsView.LeftTime,self.Data.ExpireTime)
    self.WBP_CommonTipsView.LbDateTime:SetText(Str)
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
        if not self.Data.FocusWidget then
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
    local _,FocusPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,self.Data.FocusWidget:GetCachedGeometry(),self.Data.FocusOffset or UE.FVector2D(0,0))
    local FocusSize = UE.USlateBlueprintLibrary.GetLocalSize(self.Data.FocusWidget:GetCachedGeometry())
    local FocusScale = self.Data.FocusWidget.RenderTransform.Scale
    -- local FocusSize = self.Params.FocusWidget:GetDesiredSize()
    -- self.Params.ParentScale = self.Params.ParentScale or 1
    -- FocusSize.X = FocusSize.X * self.Params.ParentScale
    -- FocusSize.Y = FocusSize.Y * self.Params.ParentScale
    local PosX,PosY = 0,0
    local TopPadding = FocusPosition.Y  - PanelSize.Y
    local LeftPadding = FocusPosition.X
    local SafeOffset = 0.5
    if TopPadding > 0 then
        -- 优先放顶部
        PosY = ViewportSize.Y - FocusPosition.Y + SafeOffset
        if LeftPadding > PanelSize.X - FocusSize.X then
            -- 优先靠左展示，与Widget右对齐
            PosX = FocusPosition.X - PanelSize.X + FocusSize.X - SafeOffset
        else
            -- 靠右展示，与Widget左对齐
            PosX = FocusPosition.X + SafeOffset
        end
    else
        -- 顶部放不下 放左/右侧 与Widget顶对齐
        PosY = ViewportSize.Y - FocusPosition.Y - PanelSize.Y - SafeOffset
        if LeftPadding > PanelSize.X then
            -- 靠左显示
            PosX = FocusPosition.X - PanelSize.X - SafeOffset
        else
            -- 靠右显示
            PosX = FocusPosition.X + FocusSize.X + SafeOffset
        end
    end
    return UE.FVector2D(PosX,-PosY)
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