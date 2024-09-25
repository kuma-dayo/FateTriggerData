--[[
    用于 WBP_CommonPopUp_Bg 的逻辑块
]]

local class_name = "CommonPopUpBgLogic"
CommonPopUpBgLogic = CommonPopUpBgLogic or BaseClass(UIHandlerViewBase, class_name)

---@class TextBlockTitleType 标题样式
local TextBlockTitleType = {
    --默认样式
    Default = 0,
    --物品名字样式
    ItemName = 1
}

function CommonPopUpBgLogic:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.Button_BGClose.OnClicked,				Func = Bind(self,self.OnButton_BGCloseClicked) },
        { UDelegate = self.View.OnAnimationFinished_vx_commonpopup_out,	Func = Bind(self,self.On_vx_commonpopup_out_Finished) },
	}
    self.ContentWidget = nil
    self.IsClosing = false --播放关闭动画时禁止在产生关闭行为
    self.BtnList = {}
    self.DefaultBtnUMGPath = {
        ["Weak"] = "/Game/BluePrints/UMG/Components/WBP_CommonBtn_Weak.WBP_CommonBtn_Weak",
        ["Strong"] = "/Game/BluePrints/UMG/Components/WBP_CommonBtn_Strong.WBP_CommonBtn_Strong",
    }
end

--[[
    Param = {
        -- 标题文字
        TitleText,
        -- 标题品质
        Quality,
        -- 内容节点
        ContentWidget
        -- 按钮列表
        BtnList = {
            [1] = {
                BtnWidget -- [可选] 不传则使用默认 WBP_CommonBtn_Weak_M/WBP_CommonBtn_Strong_M
                IsWeak -- true WBP_CommonBtn_Weak_M/ false WBP_CommonBtn_Strong_M
                BtnParam  -- 传入则用WCommonBtnTips处理按钮
                -- 非默认按钮 传入CallFunc会添加到OnClicked
                OnClickedCallFunc,
                -- 创建按钮后的回调 返回按钮的一些数据
                OnCreateBtnCallFunc,

            },...
        }
        -- 关闭按钮回调
        CloseCb

        --关闭提示文字
        CloseTipText
        -- 隐藏点击空白处关闭提示
        HideCloseTip
        -- 隐藏点击按钮
        HideCloseBtn
    }
]]
function CommonPopUpBgLogic:OnShow(Param)
    if not Param then
        return
    end

    self.IsClosing = false
    -- 标题文字
    self:UpdateTitleText(Param.TitleText or "")
    self:UpdateTitleQuality(Param.Quality)

    if Param.CloseTipText and self.View.TextBlock_Tips then
        self.View.TextBlock_Tips:SetText(Param.CloseTipText)
    end

    -- 内容节点
    if Param.ContentWidget and CommonUtil.IsValid(Param.ContentWidget) then
        self.ContentWidget = Param.ContentWidget
        self.View.ContentSlot:AddChild(self.ContentWidget)
        self.ContentWidget.Slot:SetHorizontalAlignment(UE.EHorizontalAlignment.HAlign_Fill)
        self.ContentWidget.Slot:SetVerticalAlignment(UE.EVerticalAlignment.VAlign_Fill)
    end
    -- 按钮列表
    if Param.BtnList and #Param.BtnList > 0 then
        self:UpdateBtnList(Param.BtnList)
    end
    self.View.CloseTipNode:SetVisibility(Param.HideCloseTip and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible )
    self.View.Button_BGClose:SetVisibility(Param.HideCloseBtn and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible )

    self.CloseCb = Param.CloseCb

    self:PlayDynamicEffectOnShow(true)
end

function CommonPopUpBgLogic:OnManualShow(Param)
    self:OnShow(Param)
end

function CommonPopUpBgLogic:OnHide()
    self:ClearAllBtnEvents()
end

--[[
    播放显示退出动效
]]
function CommonPopUpBgLogic:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.View.VXE_CommonPopup_L_In then
            self.View:VXE_CommonPopup_L_In()
        end
    else
        if self.View.VXE_CommonPopup_L_Out then
            self.View:VXE_CommonPopup_L_Out()
        end
    end
end

function CommonPopUpBgLogic:UpdateTitleQuality(Quality)
    
    if not(CommonUtil.IsValid(self.View.Image_Icon)) then
        ---设置标题颜色
        if self.View.SwitchTitleTypeIn_BP then
            self.View:SwitchTitleTypeIn_BP(TextBlockTitleType.Default)
        end
        return
    end

    if not(Quality) then
        self.View.Image_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)

        ---设置标题颜色
        if self.View.SwitchTitleTypeIn_BP then
            self.View:SwitchTitleTypeIn_BP(TextBlockTitleType.Default)
        end
        return
    end

    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg, Quality)
    if QualityCfg then
        -- 品质色
        local Widgets = { 
            QualityIcon = self.View.Image_Icon,
            -- QualityText = self.View.GUITextBlock_Name 
        }
        -- CommonUtil.SetQualityShow
        CommonUtil.SetQualityShowForQualityCfg(QualityCfg, Widgets)

        self.View.Image_Icon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        ---设置标题颜色
        if self.View.SwitchTitleTypeIn_BP then
            self.View:SwitchTitleTypeIn_BP(TextBlockTitleType.ItemName)
        end
    else
        self.View.Image_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)

        ---设置标题颜色
        if self.View.SwitchTitleTypeIn_BP then
            self.View:SwitchTitleTypeIn_BP(TextBlockTitleType.Default)
        end
    end
end

-- 标题文字
function CommonPopUpBgLogic:UpdateTitleText(TitleStr)
    self.View.TextBlock_Title:SetText(TitleStr)
end

-- 按钮列表
function CommonPopUpBgLogic:UpdateBtnList(BtnList)
    self:ClearAllBtnEvents()
    self.View.ButtonSlot:ClearChildren()
    self.BtnList = {}
    self.IsAddCustomEvent = false
    self.BtnWidget2HandlerList = {}
    for Index, BtnData in ipairs(BtnList) do
        local BtnWidget = BtnData.BtnWidget
        if not BtnWidget then
            local BtnWidgetCls  = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(BtnData.IsWeak and self.DefaultBtnUMGPath.Weak or self.DefaultBtnUMGPath.Strong))
            BtnWidget = NewObject(BtnWidgetCls, self.View)
            self.View.ButtonSlot:AddChild(BtnWidget)
            if Index > 1 then
                local NewPadding = BtnWidget.Slot.Padding
                NewPadding.Left = 22
                BtnWidget.Slot:SetPadding(NewPadding)
            end
        end
        if BtnData.BtnParam then
            -- 采用 WCommonBtnTips 处理
            local BtnCls = UIHandler.New(self, BtnWidget, WCommonBtnTips,BtnData.BtnParam).ViewInstance
            if BtnData.BtnParam.IsEnabled ~= nil then
                BtnCls:SetBtnEnabled(BtnData.BtnParam.IsEnabled)
            end
            if BtnData.OnCreateBtnCallFunc then
                local Param = {Index = Index, BtnWidget = BtnWidget, BtnCls = BtnCls}
                BtnData.OnCreateBtnCallFunc(Param)
            end
            self.BtnWidget2HandlerList[BtnWidget] = BtnCls
        elseif BtnData.OnClickedCallFunc then
            self.IsAddCustomEvent = true
            BtnWidget.OnClicked:Add(BtnData.OnClickedCallFunc)
            if BtnData.OnCreateBtnCallFunc then
                local Param = {Index = Index, BtnWidget = BtnWidget, BtnCls = nil}
                BtnData.OnCreateBtnCallFunc(Param)
            end
        end
        self.BtnList[#self.BtnList + 1] = BtnWidget
    end
end

function CommonPopUpBgLogic:GetBtnList()
    return self.BtnList
end

function CommonPopUpBgLogic:GetBtnHandler(BtnIndex)
    local BtnWidget = self.BtnList[BtnIndex]
    if BtnWidget ~= nil then
        return self.BtnWidget2HandlerList[BtnWidget]
    end
end

function CommonPopUpBgLogic:ClearAllBtnEvents()
    if not self.IsAddCustomEvent then
        return
    end
    self.BtnList = self.BtnList or {}
    for _,Btn in ipairs(self.BtnList) do
        Btn.OnClicked:Clear() 
    end
end

function CommonPopUpBgLogic:OnButton_BGCloseClicked()
    -- if self.CloseCb then
    --     self.CloseCb()
    -- end
    self:OnCloseViewByAction()
end

function CommonPopUpBgLogic:On_vx_commonpopup_out_Finished()
    if self.CloseCb then
        self.CloseCb()
    end
end

function CommonPopUpBgLogic:OnCloseViewByAction()
    if not self.CloseCb or self.IsClosing then
        return
    end
    self.IsClosing = true
    self:PlayDynamicEffectOnShow(false)
end

return CommonPopUpBgLogic