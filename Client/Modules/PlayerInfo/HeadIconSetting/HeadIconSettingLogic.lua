--[[
   个人信息 - 个性化设置逻辑
]] 
local class_name = "HeadIconSettingLogic"
local HeadIconSettingLogic = BaseClass(nil, class_name)

function HeadIconSettingLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.PlatformName = UE.UGameplayStatics.GetPlatformName()
    self.MsgList = {
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_SELECT_ITEM,Func = Bind(self,self.OnSelectItem) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_SELECT_ITEM_AND_EDIT,Func = Bind(self,self.OnSelectItemAndEdit) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_ICON_UNLOCK,Func = Bind(self,self.OnHeadIconOrFrameUnlock) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_USE_HEAD_ICON,Func = Bind(self,self.OnHeadIconOrFrameUpdate) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_FRAME_UNLOCK,Func = Bind(self,self.OnHeadIconOrFrameUnlock) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_WIDGET_UNLOCK,Func = Bind(self,self.OnHeadWidgetUnlock) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_FRAME_AND_WIDGET_CHANGED,Func = Bind(self,self.OnHeadFrameAndWidgetChanged) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_WIDGET_COUNT_CHANGED,Func = Bind(self,self.OnHeadWidgetCountChanged) },
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_CUSTOM_HEAD_INFO_CHANGED,Func = Bind(self,self.OnCustomHeadInfoChanged)},
    }
    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseListEx.OnUpdateItem,    Func = Bind(self, self.OnUpdateShowList)},
        { UDelegate = self.View.WBP_SliderBarEx.Slider.OnValueChanged, Func = Bind(self, self.OnSliderValueChanged) },
        { UDelegate = self.View.WBP_Back.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClicked_BackChange) },
        { UDelegate =  self.View.WBP_SliderBarEx.Slider.OnMouseCaptureBegin,Func = Bind(self,self.OnMouseCaptureBeginFunc)},
        { UDelegate =  self.View.WBP_SliderBarEx.Slider.OnMouseCaptureEnd,Func = Bind(self,self.OnMouseCaptureEndFunc)},
        { UDelegate =  self.View.WBP_SliderBarEx.Slider.OnControllerCaptureEnd,Func = Bind(self,self.OnControllerCaptureEndFunc)},
    }
    
    self.View.WBP_SliderBarEx.Panel_Point:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    ---@type HeadIconSettingModel
    self.HeadIconSettingModel = MvcEntry:GetModel(HeadIconSettingModel)
    self:DataInit()
end

function HeadIconSettingLogic:DataInit()
    self.Widget2Handler = {}
    self.HeadWidgetCls = nil
    self.DetailParam = nil
    self.DetailCfg = nil
    self.DetailCfgKey = nil
end

--[[
    local Param = {
        SettingType = self.SelectTabId,
    }
]]
function HeadIconSettingLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function HeadIconSettingLogic:OnHide()
    self.HeadIconSettingModel:SetItemSelectParam(nil)
    self:DataInit()
end

function HeadIconSettingLogic:UpdateUI(Param)
    self.SettingType = Param.SettingType
    if not self.SettingType then
        CError("HeadIconSettingLogic Need A SettingType!",true)
        return
    end
    self:ResetHeadDefaultIcon()
    self:UpdateShowList()
end

-- 页签切换的时候重置头像组件纹理
function HeadIconSettingLogic:ResetHeadDefaultIcon()
    if self.SettingType == HeadIconSettingModel.SettingType.HeadIcon then
        if self.Widget2Handler then
            for _, ViewHandler in pairs(self.Widget2Handler) do
                if ViewHandler and ViewHandler.ResetHeadDefaultIcon then
                    ViewHandler:ResetHeadDefaultIcon()
                end
            end
        end
    end
end

-- 更新左侧展示列表
function HeadIconSettingLogic:UpdateShowList()
    self.SeriesCfgs = self.HeadIconSettingModel:GetHeadSettingSeriesCfgs(self.SettingType)
    if not self.SeriesCfgs then
        CError("HeadIconSettingLogic GetHeadSettingSeriesCfgs Error For Type = "..self.SettingType,true)
        return
    end
    if self.SettingType == HeadIconSettingModel.SettingType.HeadWidget then
        -- 头像挂件 默认不选中
        self.DetailParam = {
            SettingType = self.SettingType,
        }
    else
        -- 头像 & 头像框 默认选中装配的那个
        self.DetailParam = {
            SettingType = self.SettingType,
            Id = self.HeadIconSettingModel:GetUsingId(self.SettingType),
            IsShowWholeHead = true,
        }
        self.HeadIconSettingModel:SetItemSelectParam(self.DetailParam)
    end
    self.View.WBP_ReuseListEx:Reload(#self.SeriesCfgs)
    self.View.WBP_ReuseListEx:ScrollToStart()
    self:UpdateDetail()
end

function HeadIconSettingLogic:OnUpdateShowList(Handler,Widget, I)
    local Index = I + 1
    local SeriesCfg = self.SeriesCfgs[Index]
    if not self.Widget2Handler[Widget] then
        local ViewHandler = UIHandler.New(self,Widget,require("Client.Modules.PlayerInfo.HeadIconSetting.HeadIconSettingSeriesItem")).ViewInstance
        self.Widget2Handler[Widget] = ViewHandler
    end

    -- local _,SeriesCfgKey = self.HeadIconSettingModel:GetSettintSeriesCfgNameAndKey(self.SettingType)
    local Param = {
        SettingType = self.SettingType,
        SeriesCfg = SeriesCfg,
        -- IsFirstSeries = SeriesCfg[SeriesCfgKey.SeriesId] == self.SeriesCfgs[1][SeriesCfgKey.SeriesId]
    }
    self.Widget2Handler[Widget]:UpdateUI(Param)
end

-- 刷新右侧展示内容
function HeadIconSettingLogic:UpdateDetail()
    -- 头像区域
    if not self.HeadWidgetCls then
        self.HeadWidgetCls = UIHandler.New(self,self.View.WBP_HeadDetailWidget,require("Client.Modules.PlayerInfo.HeadIconSetting.HeadDetailWidget"),self.DetailParam).ViewInstance
    else
        self.HeadWidgetCls:UpdateUI(self.DetailParam)
    end
    
    self.DetailCfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(self.DetailParam.SettingType,self.DetailParam.Id)
    if self.DetailParam.Id and not self.DetailCfg then
        CError(StringUtil.Format("HeadIconSettingLogic:GetHeadIconSettintCfg Error For Type ={0} Id = {1}",self.DetailParam.SettingType,self.DetailParam.Id),true)
        return
    end
    local _,CfgKey = self.HeadIconSettingModel:GetSettintCfgNameAndKey(self.DetailParam.SettingType)
    if not CfgKey then
        CError(StringUtil.Format("HeadIconSettingLogic:GetSettintCfgNameAndKey Error For Type ={0}",self.DetailParam.SettingType),true)
        return
    end
    self.DetailCfgKey = CfgKey
    -- 是否为自定义头像
    local IsCustomHead = self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadIcon and self.HeadIconSettingModel:CheckIsCustomHead(self.DetailParam.Id)
    -- 名称
    if self.DetailCfg then
        self.View.Text_Name:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.Text_Name:SetText(self.DetailCfg[CfgKey.IconName] or "")
    else
        self.View.Text_Name:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    -- 操作区域
    if self.SettingType == HeadIconSettingModel.SettingType.HeadWidget then
        -- 头像挂件逻辑单独处理
        self.View.WidgetSwitcher_Type:SetActiveWidget(self.View.HeadFrame)
        -- self.View.Panel_FrameWeight:SetVisibility(UE.ESlateVisibility.Collapsed) 
        self:UpdateHeadWidgetDetail()
    else
        if IsCustomHead then
            self.View.WidgetSwitcher_Type:SetActiveWidget(self.View.HeadCustom)
            self:UpdateCustomHeadDetail()
        else
            self.View.WidgetSwitcher_Type:SetActiveWidget(self.View.HeadFrame)
            self:UpdateHeadIconAndFrameDetail()
        end
    end
end
------------------------------------------------
-- 头像&头像框 右侧详情
function HeadIconSettingLogic:UpdateHeadIconAndFrameDetail()
    self.View.EidPanel:SetActiveWidget(self.View.Panel_Normal)
    self.View.Panel_NeedWeight:SetVisibility(UE.ESlateVisibility.Collapsed)
    local IsHeadFrame = self.SettingType == HeadIconSettingModel.SettingType.HeadFrame
    self.View.HorizontalBox_WeightGrid:SetVisibility(IsHeadFrame and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.Container_WeightGrid:SetVisibility(IsHeadFrame and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.Text_ToSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Panel_Top:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- 头像框容量
    if self.SettingType == HeadIconSettingModel.SettingType.HeadFrame then
        -- self.View.Panel_FrameWeight:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        local MaxWeight = self.DetailCfg[Cfg_HeadFrameCfg_P.MaxWeight]
        self.View.Text_FrameWeight:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_8"),MaxWeight))
        CommonUtil.AddChildToContainer(self.View.Container_WeightGrid,self.View,"/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/Item/WBP_FrameNumStateWidget.WBP_FrameNumStateWidget",MaxWeight,self.View.FrameRightBottomPadding)
    else
        -- self.View.Panel_FrameWeight:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self:UpdateBtnAndTips()
end
------------------------------------------------

------------------------------------------------
-- 自定义头像 右侧详情
function HeadIconSettingLogic:UpdateCustomHeadDetail()
    local IsToExamine = self.HeadIconSettingModel:CheckMySelfIsToExamineCustomHead()
    self.View.Panel_Check:SetVisibility(IsToExamine and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.Panel_NeedWeight:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Panel_Top:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:UpdateBtnAndTips()
end
------------------------------------------------

-- 头像挂件 右侧详情
function HeadIconSettingLogic:UpdateHeadWidgetDetail()
    self.View.EidPanel:SetActiveWidget(self.View.Panel_Normal)
    self.View.WBP_Back:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.HorizontalBox_WeightGrid:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Container_WeightGrid:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Panel_Top:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- 下方操作
    local IsSelect = self.DetailParam.Id ~= nil
    if IsSelect then
        -- 有选中挂件
        self.View.Text_ToSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Panel_NeedWeight:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        local Weight = self.DetailCfg[self.DetailCfgKey.Weight]
        CommonUtil.AddChildToContainer(self.View.Container_NeedWeight,self.View,"/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/Item/WBP_ImformationCircleWidget3.WBP_ImformationCircleWidget3",Weight,self.View.WidgetRightBottomPadding)
        self:UpdateBtnAndTips()
        self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_SET_HEAD_WIDGET_CAN_SELECT,false)
    else
        -- 未选中
        -- self.View.WBP_OperateButton:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.WBP_NormalOperateButton:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Text_Tips:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Panel_NeedWeight:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Text_ToSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_SET_HEAD_WIDGET_CAN_SELECT,true)
    end
    self:UpdateWeightPanel()
end

-- 更新当前容量展示
function HeadIconSettingLogic:UpdateWeightPanel()
    local WeightInfo = self.HeadIconSettingModel:GetWeightInfo(self.DetailParam.Id)
    local IsFull = WeightInfo.Full and WeightInfo.Full > 0
    local TotalWeight = IsFull and WeightInfo.Full or WeightInfo.Total
    local UseWeight = WeightInfo.Use
    local ToUseWeight = WeightInfo.ToUse
    self.View.Text_WeightInfo:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"),IsFull and TotalWeight or WeightInfo.Use,WeightInfo.Total))
    CommonUtil.AddChildToContainer(self.View.Container_Weight,self.View,"/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/Item/WBP_ImformationCircleWidget1.WBP_ImformationCircleWidget1",TotalWeight,self.View.WidgetRightTopPadding) 
    for Index = 1, TotalWeight do
        local Child = self.View.Container_Weight:GetChildAt(Index-1)
        if Child then
            if IsFull then
                Child.WidgetSwitcher_State:SetActiveWidget(Child.Image_Full)
            elseif Index <= UseWeight then
                Child.WidgetSwitcher_State:SetActiveWidget(Child.Image_Use)
            elseif Index > UseWeight and Index <= UseWeight + ToUseWeight then
                Child.WidgetSwitcher_State:SetActiveWidget(Child.Image_ToUse)
            else
                Child.WidgetSwitcher_State:SetActiveWidget(Child.Image_Empty)
            end
        end
    end
end

------------------------------------------------

-- 右侧按钮和文本
function HeadIconSettingLogic:UpdateBtnAndTips()
    local Cfg = self.DetailCfg
    local CfgKey = self.DetailCfgKey
    -- 是否是头像挂件
    local IsHeadWidget = self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadWidget
    local IsCustomHead = self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadIcon and self.HeadIconSettingModel:CheckIsCustomHead(self.DetailParam.Id)
    local IsUnlock = self.HeadIconSettingModel:IsSettingUnlock(self.DetailParam.SettingType,self.DetailParam.Id)
    -- 是否解锁
    local BtnParam,TipsStr = nil,nil
    local CustomBtnParam = nil
    local CustomEquipBtnParam = nil
    -- 是否已装配
    local IsUsing = self.HeadIconSettingModel:IsSettingUsing(self.DetailParam.SettingType,self.DetailParam.Id)
    if IsHeadWidget and IsUnlock and not IsUsing and self.HeadIconSettingModel:IsFullWeight(self.DetailParam.Id) then
        BtnParam = {
            IsEnabled = false,
            TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_offcapacity"),
        }
    elseif IsCustomHead then
        -- TipsStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1051")
        TipsStr = nil-- 冷却暂时不做 所以屏蔽提示
        local IsHasCustomHead = self.HeadIconSettingModel:CheckMySelfIsHasCustomHead()
        CustomBtnParam = {
            IsEnabled = true,
            OnItemClick = Bind(self,self.ChangeCustomHead),
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1052_Btn")
        }
        CustomEquipBtnParam = {
            IsEnabled = not IsUsing and IsHasCustomHead,
            OnItemClick = Bind(self,self.CustomHeadAssemble),
            TipStr = IsUsing and G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_Equipped_Btn") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_equipment_Btn")
        }
    else
        if IsUnlock then
            -- 已解锁
            local TipStr = IsUsing and (IsHeadWidget and G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_adjust") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_Equipped_Btn")) or (IsHeadWidget and G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_add_Btn") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_equipment_Btn"))
            if IsHeadWidget and IsUsing then
                BtnParam = {
                    IsEnabled = true,
                    OnItemClick = Bind(self,self.EnterWidgetEditMode),
                    TipStr = TipStr,
                }
            else
                BtnParam = {
                    IsEnabled = not IsUsing,
                    OnItemClick = Bind(self,self.OnReqPutOn),
                    TipStr = TipStr,
                }
            end
        else
            -- 未解锁
            local CanUnlock = Cfg[CfgKey.CanUnlock] > 0
            if CanUnlock then
                local JumpID = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(self.DetailParam.Id)
                -- 可解锁 
                BtnParam = {
                    IsEnabled = true,
                    CurrencyId = Cfg[CfgKey.UnlockItemId],
                    CurrencyNum = Cfg[CfgKey.UnlockItemNum],
                    OnItemClick = Bind(self,self.OnShowUnlockTips,Cfg[CfgKey.UnlockItemId],Cfg[CfgKey.UnlockItemNum]),
                    JumpIDList = JumpID,
                }
            else
                -- 不可解锁
                TipsStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_Staytuned")
            end
        end
    end
    -- 操作按钮的处理
    self.View.WBP_NormalOperateButton:SetVisibility(BtnParam ~= nil and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    if BtnParam then
        BtnParam.CommonTipsID = CommonConst.CT_SPACE
        BtnParam.HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main
        BtnParam.ActionMappingKey = ActionMappings.SpaceBar
        if not self.OperateBtnCls then
            self.OperateBtnCls = UIHandler.New(self, self.View.WBP_NormalOperateButton, WCommonBtnTips,BtnParam).ViewInstance
        else
            self.OperateBtnCls:UpdateItemInfo(BtnParam)
        end
        self.OperateBtnCls:SetBtnEnabled(BtnParam.IsEnabled,BtnParam.TipStr)
    end
    
    -- 自定义头像按钮的处理
    self.View.WBP_SelectImageBtn:SetVisibility(CustomBtnParam ~= nil and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    if CustomBtnParam then
        CustomBtnParam.HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main
        if not self.SelectImageBtnCls then
            self.SelectImageBtnCls = UIHandler.New(self, self.View.WBP_SelectImageBtn, WCommonBtnTips,CustomBtnParam).ViewInstance
        else
            self.SelectImageBtnCls:UpdateItemInfo(CustomBtnParam)
        end
        self.SelectImageBtnCls:SetBtnEnabled(CustomBtnParam.IsEnabled,CustomBtnParam.TipStr)
    end
    -- 自定义头像装配
    self.View.WBP_CommonBtn_Strong_M:SetVisibility(CustomEquipBtnParam ~= nil and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    if CustomEquipBtnParam then
        CustomEquipBtnParam.HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main
        if not self.CustomEquipBtnCls then
            self.CustomEquipBtnCls = UIHandler.New(self, self.View.WBP_CommonBtn_Strong_M, WCommonBtnTips,CustomEquipBtnParam).ViewInstance
        else
            self.CustomEquipBtnCls:UpdateItemInfo(CustomEquipBtnParam)
        end
        self.CustomEquipBtnCls:SetBtnEnabled(CustomEquipBtnParam.IsEnabled,CustomEquipBtnParam.TipStr)
    end

    -- 提示文本
    self.View.Text_Tips:SetVisibility(TipsStr ~= nil and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if TipsStr then
        self.View.Text_Tips:SetText(StringUtil.Format(TipsStr))
    end
end

-- 请求头像 | 头像框 装备
function HeadIconSettingLogic:OnReqPutOn()
    ---@type PersonalInfoCtrl
    local PersonalInfoCtrl = MvcEntry:GetCtrl(PersonalInfoCtrl)
    if self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadIcon then
        PersonalInfoCtrl:SendProto_PlayerSelectHeadReq(self.DetailParam.Id)
    elseif self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadFrame then
        PersonalInfoCtrl:RequestChangeHeadFrame(self.DetailParam.Id)
    elseif self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadWidget then
        -- 进入挂件编辑模式
        self.HeadIconSettingModel:AddHeadWidgetTemp(self.DetailParam.Id)
        self:EnterWidgetEditMode()
    end
end

function HeadIconSettingLogic:OnShowUnlockTips(UnlockItemId,UnlockItemNum)
    if MvcEntry:GetModel(DepotModel):IsEnoughByItemId(UnlockItemId,UnlockItemNum) then
        local msgParam = {
            -- describe = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_Areyousureyouwanttou"),StringUtil.GetRichTextImgForId(UnlockItemId), UnlockItemNum),
            describe = CommonUtil.GetBuyCostDescribeText(UnlockItemId, UnlockItemNum, CommonConst.BuyType.UNLOCK), --确定要花 {0}{1} 解锁吗？
            leftBtnInfo = {},
            rightBtnInfo = {
                callback = function()
                    self:OnReqUnlock()
                end
            }
        }
        UIMessageBox.Show(msgParam)
    else
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_Insufficientpropsunl"))
    end
end

-- 请求头像 | 头像框 解锁
function HeadIconSettingLogic:OnReqUnlock()
    local PersonalInfoCtrl = MvcEntry:GetCtrl(PersonalInfoCtrl)
    if self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadIcon then
        PersonalInfoCtrl:SendProto_PlayerBuyHeadReq(self.DetailParam.Id)
    elseif self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadFrame then
        PersonalInfoCtrl:SendProto_PlayerBuyHeadFrameReq(self.DetailParam.Id)
    elseif self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadWidget then
        PersonalInfoCtrl:SendProto_PlayerBuyHeadWidgetReq(self.DetailParam.Id)
    end
end

--[[
    SelectParam = {
        SettingType,
        SeriesId ,
        Id
    }
]]
function HeadIconSettingLogic:OnSelectItem(_,SelectParam)
    if not SelectParam or SelectParam.SettingType ~= self.SettingType then
        return
    end
    self.DetailParam = {
        SettingType = SelectParam.SettingType,
        Id = SelectParam.Id,
        IsShowWholeHead = true,
    }
    self:UpdateDetail()
end

function HeadIconSettingLogic:OnSelectItemAndEdit(_,SelectParam)
    self:OnSelectItem(_,SelectParam)
    self:EnterWidgetEditMode()
end

-- 收到头像/头像框/解锁
function HeadIconSettingLogic:OnHeadIconOrFrameUnlock(_,Id)
    if not self.DetailParam or Id ~= self.DetailParam.Id then
        return
    end
    self.View.WBP_ReuseListEx:Reload(#self.SeriesCfgs)
    self:UpdateBtnAndTips()
end

function HeadIconSettingLogic:OnHeadIconOrFrameUpdate(_,Id)
    if not self.DetailParam or Id ~= self.DetailParam.Id then
        return
    end
    self:UpdateBtnAndTips()
end

-- 收到头像组件解锁
function HeadIconSettingLogic:OnHeadWidgetUnlock(_,Id)
    if not self.DetailParam or Id ~= self.DetailParam.Id then
        return
    end
    self.View.WBP_ReuseListEx:Reload(#self.SeriesCfgs)
    self:UpdateWeightPanel()
    self:UpdateBtnAndTips()
end

-- 收到穿戴头像框和挂件列表更新
function HeadIconSettingLogic:OnHeadFrameAndWidgetChanged()
    if self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadFrame then
        self:UpdateBtnAndTips()
    elseif self.DetailParam.SettingType == HeadIconSettingModel.SettingType.HeadWidget then
        self:ResetHeadWidgetSelectState()
    end
end

-- 挂件数量变化
function HeadIconSettingLogic:OnHeadWidgetCountChanged()
    self:UpdateWeightPanel()
end

-- 自定义头像信息发生变化
function HeadIconSettingLogic:OnCustomHeadInfoChanged()
    if not self.DetailParam then
        return
    end
    self.View.WBP_ReuseListEx:Reload(#self.SeriesCfgs)
    self.View.WBP_ReuseListEx:ScrollToStart()
    self:UpdateDetail()
end

function HeadIconSettingLogic:ResetHeadWidgetSelectState()
    self.DetailParam.Id = nil
    self:UpdateDetail()
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.CLEAR_SELECT)
end

------------------------------------------------------------------------

-- 头像框调整
function HeadIconSettingLogic:EnterWidgetEditMode()
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_HEAD_WIDGET_EDITING, self.DetailParam.Id)
    self.View.EidPanel:SetActiveWidget(self.View.Panel_Edit)
    local BtnParam = {
        IsEnabled = true,
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingLogic_accomplish"),
        OnItemClick = Bind(self,self.OnFinishEdit),
    }
    if not self.WidgetEditBtnCls then
        self.WidgetEditBtnCls = UIHandler.New(self, self.View.WBP_OperateButton, WCommonBtnTips,BtnParam).ViewInstance
    else
        self.WidgetEditBtnCls:UpdateItemInfo(BtnParam)
    end
    self.View.WBP_Back:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- 设置初始角度
    local CurAngle = self.HeadIconSettingModel:GetHeadWidgetAngle(self.DetailParam.Id)
    self.View.WBP_SliderBarEx:SetValue(CurAngle/360)
    self.HeadIconSettingModel:PushRotationCache(CurAngle,true)
end

-- 自定义头像装配
function HeadIconSettingLogic:CustomHeadAssemble()
    -- 自定义头像ID传0
    self:OnReqPutOn()
end

-- 更换自定义头像
function HeadIconSettingLogic:ChangeCustomHead()
    if self.IsSelectingFile then
        return
    end
    self.IsSelectingFile = true
    local FilePath = UE.UGameHelper.OpenFileAndGetFilePath("Select Image", "JPG Files (*.jpg)|*.jpg|JPEG Files (*.jpeg)|*.jpeg|PNG Files (*.png)|*.png")
    self.IsSelectingFile = false
    if FilePath and FilePath ~= "" then
        local Param = {
            FilePath = FilePath
        }
        MvcEntry:OpenView(ViewConst.EditImageMdt, Param)
    end
end 

-- 滑动条进度变化
function HeadIconSettingLogic:OnSliderValueChanged(_,Value)
    local Msg = {
        HeadWidgetId = self.DetailParam.Id,
        Angle = math.floor(Value*360)
    }
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_ADJUST_HEAD_WIDGET_ANGLE,Msg)
end

-- 监听开始点击的鼠标位置
function HeadIconSettingLogic:OnMouseCaptureBeginFunc()
    local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
    self.MouseStartPosX = MousePos.X
end

-- 监听完成拖动，保存为一步操作
function HeadIconSettingLogic:OnMouseCaptureEndFunc()
    local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
    if self.MouseStartPosX and math.abs(MousePos.X - self.MouseStartPosX) < 2 then
        -- 点击（非拖动），判断吸附点
        local CurValue = self.View.WBP_SliderBarEx:GetValue()
        local PointAngle = 0
        while PointAngle <= 360 do
            -- 小于10度则吸附
            local Angle = math.floor(CurValue*360)
            if math.abs(Angle-PointAngle) < 10 then
                self.View.WBP_SliderBarEx:SetValue(PointAngle/360)
                break
            end
            PointAngle = PointAngle + 90
        end
    end
    self:SaveOperation()
end
function HeadIconSettingLogic:OnControllerCaptureEndFunc()
    self:SaveOperation()
end
function HeadIconSettingLogic:SaveOperation()
    local CurValue = self.View.WBP_SliderBarEx:GetValue()
    local Angle = math.floor(CurValue*360)
    self.HeadIconSettingModel:PushRotationCache(Angle)
    self.HeadIconSettingModel:UpdateHeadWidgetAngle(self.DetailParam.Id,Angle)
end

-- 点击回退
function HeadIconSettingLogic:OnClicked_BackChange()
    -- 获取上次角度
    local LastAngle = self.HeadIconSettingModel:PopRotationCache()
    if not LastAngle then
        -- 没有角度记录则说明上一步是添加，回退则删除
        self.HeadIconSettingModel:DelHeadWidgetTemp(self.DetailParam.Id)
    else
        self.View.WBP_SliderBarEx:SetValue(LastAngle/360)
        self:OnSliderValueChanged(nil,LastAngle/360)
        self.HeadIconSettingModel:UpdateHeadWidgetAngle(self.DetailParam.Id,LastAngle)
    end
end

-- 点击跳转到某个角度
function HeadIconSettingLogic:OnClicked_ChangeToAngle(Angle)
    self.View.WBP_SliderBarEx:SetValue(Angle/360)
    self:OnSliderValueChanged(nil,Angle/360)
    self:SaveOperation()
end

-- 完成调整
function HeadIconSettingLogic:OnFinishEdit()
    MvcEntry:GetCtrl(PersonalInfoCtrl):RequestChangeHeadWidget()
end

return HeadIconSettingLogic
