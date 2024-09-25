--[[
    赛季 - 切页 - 通行证
]]

local class_name = "SeasonTabPass"
local SeasonTabPass = BaseClass(UIHandlerViewBase, class_name)


function SeasonTabPass:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true

    self.SeasonBpModel = MvcEntry:GetModel(SeasonBpModel)
    self.SeasonBpCtrl = MvcEntry:GetCtrl(SeasonBpCtrl)

    self.MsgList = 
    {
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_INFO_INIT, Func = self.InitUI },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_PASS_BUY_SUC, Func = self.UpdateUI },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_LEVEL_UPDATE, Func = self.ON_SEASON_BP_LEVEL_UPDATE_FUNC },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_MAIN_SELECT_ITEM_SHOW, Func = self.ON_SEASON_BP_MAIN_SELECT_ITEM_SHOW },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_MAIN_SELECT_SPECIAL_ITEM_SHOW, Func = self.ON_SEASON_BP_MAIN_SELECT_SPECIAL_ITEM_SHOW },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_EXP_UPDATE, Func = self.ON_SEASON_BP_EXP_UPDATE_FUNC },
	}
    self.BindNodes = {
		{ UDelegate = self.View.BtnBpLevelBuy.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnBtnBpLevelBuyClick) },
        { UDelegate = self.View.GiftList.OnUpdateItem,Func = Bind(self, self.OnUpdateItem)}, 
        { UDelegate = self.View.GiftList.OnPreUpdateItem,Func = Bind(self, self.OnPreUpdateItem)},
        { UDelegate = self.View.GiftList.OnReloadFinish, Func = Bind(self, self.OnReloadFinish)},
        { UDelegate = self.View.GiftList.OnScrollItem,Func = Bind(self, self.OnScrollItem)},
        { UDelegate = self.View.GoodPreShowBtnClose.OnClicked, Func = Bind(self, self.OnBtnGoodWatchClick)},
    }


    local TaskBtnParam = {
        OnItemClick = Bind(self,self.OnClickedTask),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","Task_Btn"),
        CommonTipsID = CommonConst.CT_F,
		ActionMappingKey = ActionMappings.F 			
    }
    UIHandler.New(self, self.View.WBP_CommonBtn_Task, WCommonBtnTips,TaskBtnParam)

    local BuyBpBtnParam = {
        OnItemClick = Bind(self,self.OnClickedBuyBp),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","BuyBp"),
        CommonTipsID = CommonConst.CT_SPACE,
		ActionMappingKey = ActionMappings.SpaceBar			
    }
    UIHandler.New(self, self.View.WBP_CommonBtn_BuyBp, WCommonBtnTips,BuyBpBtnParam)

    UIHandler.New(self,self.View.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Esc_Btn")),
        ActionMappingKey = ActionMappings.Escape
    })
    self.PreviewHandle = UIHandler.New(self,self.View.CommonBtnTips_Preview, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnPreviewClicked),
        CommonTipsID = CommonConst.CT_LShift,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Weapon", "11360_Btn")),
        ActionMappingKey = ActionMappings.LShift
    }).ViewInstance
    self.Widget2Handler = {}
    self.Widget2HandlerSpecial = {}
    self.LightActor = nil
end

function SeasonTabPass:OnPreviewClicked()
    MvcEntry:OpenView(ViewConst.CommonPreview,{
        ItemId = self.CurSelectItemId,
        FromID = ViewConst.Season,
        CameraConfigType = HallModel.CAMERA_CONFIG_CONST.SEASON
    })
end

--[[
    Param = {
    }
]]
function SeasonTabPass:OnShow(Param)
    self:InitUI()
end
function SeasonTabPass:OnManualShow(Param)
    self:InitUI()
end
function SeasonTabPass:OnManualHide()
end


function SeasonTabPass:OnHide()
    self:OnHideAvator()
end

function SeasonTabPass:OnShowAvator(Data,IsNotVirtualTrigger)
    if IsNotVirtualTrigger then
        return
    end
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr ~= nil then
        HallAvatarMgr:ShowAvatarByViewID(self:ClassId(), false)
    end
    if self.CurSelectLevelSpecial == 0 then
        self.View.GoodImageSpecial:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.LbRewards:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.View.GoodImage:SetVisibility(UE.ESlateVisibility.Collapsed)
    if not self.CurSelectItemId or self.CurSelectItemId <= 0 then
        return
    end
    local ItemId = self.CurSelectItemId
    local ItemConfig = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
    if not ItemConfig then
        return
    end

    ---@type RtShowTran
    local FinalTran = CommonUtil.GetShowTranByItemID(ETransformModuleID.BP_SeasonPass.ModuleID, ItemId) or {}
    
    local ShowParam = {
        ViewID = self:ClassId(),
        InstID = 0,
        Location = UE.FVector(79987,-100,150),
        Rotation = UE.FRotator(0, 0, 90),
    }
    self.PreviewHandle:ManualClose()
    self:UpdatePointLightShow(false)
    if ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER then 
        --角色/角色皮肤
        local IsDisplayBoard = false
        if ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Background then
            IsDisplayBoard = true
        end
        if ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Hero or ItemConfig[Cfg_ItemConfig_P.SubType] ==  DepotConst.ItemSubType.Skin then
            self.PreviewHandle:ManualOpen()
        end
        if IsDisplayBoard then
            ShowParam.Location = FinalTran.Pos or UE.FVector(119741,200,295)
            ShowParam.Rotation = FinalTran.Rot or UE.FRotator(0, 90, 0)
            ShowParam.Scale = FinalTran.Scale or UE.FVector(0.11, 0.11, 0.11)
        else
            ShowParam.Location = FinalTran.Pos or UE.FVector(119741,120,190)
            ShowParam.Rotation = FinalTran.Rot or UE.FRotator(0, 0, 2)
            ShowParam.Scale = FinalTran.Scale or UE.FRotator(1, 1, 1)
        end
    elseif ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_WEAPON then
        --武器
        ShowParam.Location = FinalTran.Pos or UE.FVector(119741,500,300)
        ShowParam.Rotation = FinalTran.Rot or UE.FRotator(0, 90, 0)
        ShowParam.Scale = FinalTran.Scale or UE.FRotator(1, 1, 1)
        self:UpdatePointLightShow(true)
    elseif ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_VEHICLE then
        --载具
        ShowParam.Location = FinalTran.Pos or UE.FVector(119741,250,270)
        ShowParam.Rotation = FinalTran.Rot or UE.FRotator(-10, 30, 20)
        ShowParam.Scale = FinalTran.Scale or  UE.FVector(0.5, 0.5, 0.5)
    end
    local SpawnActor = CommonUtil.TryShowAvatarInHallByItemId(ItemId,ShowParam)
    if not SpawnActor then
        if ItemConfig[Cfg_ItemConfig_P.ImagePath] and string.len(ItemConfig[Cfg_ItemConfig_P.ImagePath]) > 0 then
            CWaring("OnShowAvator==================3:" .. ItemConfig[Cfg_ItemConfig_P.ImagePath])
            self.View.GoodImage:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            CommonUtil.SetBrushFromSoftObjectPath(self.View.GoodImage,ItemConfig[Cfg_ItemConfig_P.ImagePath],true)
            if FinalTran and FinalTran.RenderTran then
                CommonUtil.SetBrushRenderTransform(self.View.GoodImage, FinalTran.RenderTran)
            end
        end
    else
        local bIsHeroBackground = CommonUtil.CheckIsHeroBackgroundType(ItemId)
        if bIsHeroBackground then
            self:SetHeroDisplayBordUI(SpawnActor, ItemConfig)
        else
            SpawnActor:SetCapsuleComponentSize(400, 300)
        end
    end
end

function SeasonTabPass:SetHeroDisplayBordUI(SpawnActor, ItemCfg)
    if not(CommonUtil.IsValid(SpawnActor)) then
        return
    end

    if ItemCfg == nil then
        CError(string.format("SeasonTabPass-SetHeroDisplayBordUI() ItemCfg == nil!!!"))
        return
    end

    local SubType = ItemCfg[Cfg_ItemConfig_P.SubType]

    --角色展示面板
    local PtParam = {HeroId = 0, FloorId = 0, RoleId = 0, EffectId = 0}
    if SubType == DepotConst.ItemSubType.Background then
        PtParam.FloorId = ItemCfg[Cfg_ItemConfig_P.ItemId]
    elseif SubType == DepotConst.ItemSubType.Pose then
        PtParam.RoleId = ItemCfg[Cfg_ItemConfig_P.ItemId]
    elseif SubType == DepotConst.ItemSubType.Effect then
        PtParam.EffectId = ItemCfg[Cfg_ItemConfig_P.ItemId]
    end
    local TempParam = CommonUtil.MakeDisplayBoardNode(nil, PtParam)

    SpawnActor:SetDisplayBordUiByParam(TempParam)
end

function SeasonTabPass:OnHideAvator()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then return end
    HallAvatarMgr:HideAvatarByViewID(self:ClassId())
end

function SeasonTabPass:InitUI()
    self.SeasonBpId = self.SeasonBpModel:GetSeasonBpId()
    self.CurSelectItemId = 0
    self.CurSelectLevel = 0
    self.CurSelectLevelSpecial = 0
    self.Level2ItemList = {}
    self.BpLevelMax = 0
    self.LevelList = {}
    self.ShowDataList = {}
    self.CurNeedJumpIdx = 0
    self.StartItemIndex = -1
    self.EndItemIndex = -1
    self.View.ContentRoot:SetVisibility(self.SeasonBpId > 0 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if self.SeasonBpId <= 0 then
        --TODO 请求赛季通行证数据
        self.SeasonBpCtrl:SendProto_PassStatusReq(true)
    else
        self:UpdateUI();
    end
	local LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_SEASON_PASS_BACKGROUND)
    if LevelSequenceAsset then
		local PlayParam = {
			LevelSequenceAsset = LevelSequenceAsset,
		}
		MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("LS_SEASON_PASS_BACKGROUND", function ()
			CWaring("SeasonTabPass:PlaySequenceByTag Suc")
		end, PlayParam)
    end
end

function SeasonTabPass:UpdateUI()
    local PassStatus = self.SeasonBpModel:GetPassStatus()
    local CfgSeason = G_ConfigHelper:GetSingleItemById(Cfg_SeasonBpCfg,self.SeasonBpId)

    -- self.View.LbBpSeasonName:SetText(CfgSeason[Cfg_SeasonBpCfg_P.Name])
    -- self.View.LbRichTime:SetText(self.SeasonBpModel:GetEndTimeShow())
    if not self.CounDownTimer then
        self.CounDownTimer = self:InsertTimerByEndTime(self.SeasonBpModel:GetEndTime(),function (TimeStr,ResultParam)
            self.View.LbRichTime:SetText(self.SeasonBpModel:FormatEndTimeShow(TimeStr))
        end)
    end

    self:CalculateInitSelectItemId()
    -- CWaring("Reload Num:" .. #self.ShowDataList)
    self.Level2WidgetHandler = {}
    self.Level2WidgetHandlerSpecial = {}
    self.View.GiftList:Reload(#self.ShowDataList)

    self:UpdateBpLevelShow()
    self:UpdateBpLevelBtnShow()
    self:UpdateSelectGoodShow();
    self:UpdateGoodWatchShow(true)
    

    self.View.WBP_CommonBtn_BuyBp:SetVisibility(PassStatus.PassType == Pb_Enum_PASS_TYPE.BASIC and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    --通行证背景
    -- CommonUtil.SetBrushFromSoftObjectPath(self.View.Img_Pass_Bg)
end

--[[
    计算当前默认选中的奖励ITEM
    规则如下：
    - 每次进入通行证页面时,会默认选中当前等级的首个奖励
]]
function SeasonTabPass:CalculateInitSelectItemId()
    local PassStatus = self.SeasonBpModel:GetPassStatus()
    self.BpLevelMax = 0
    self.Level2ShowIndex = {}
    self.LevelList = {}
    self.Index2IsSpecial = {}
    -- local AwardedLevel = self.SeasonBpModel:GetAwardedLevel()
    -- local AwardedLevelNext = AwardedLevel + 1
    local CurLevel = PassStatus.Level
    local NeedShowRewardList = G_ConfigHelper:GetMultiItemsByKey(Cfg_SeasonBpRewardCfg,Cfg_SeasonBpRewardCfg_P.SeasonBpId,self.SeasonBpId)
    for Idx,Reward in ipairs(NeedShowRewardList) do
        local ResultOk = false
        local RewardLevel = Reward[Cfg_SeasonBpRewardCfg_P.Level]
        local DropItemList = self.SeasonBpModel:GetDropItemListByBpReward(Reward)--MvcEntry:GetModel(DepotModel):GetItemListForDropId(Reward[Cfg_SeasonBpRewardCfg_P.DropId])
        if #DropItemList > 0 then
            if self.CurSelectItemId <= 0 then
                if RewardLevel >= CurLevel then
                    ResultOk = true
                end
            end
            if ResultOk then
                self.CurSelectItemId = DropItemList[1].ItemId
                self.CurNeedJumpIdx = #self.ShowDataList
                self.CurSelectLevel = Reward[Cfg_SeasonBpRewardCfg_P.Level]
            end
            self.Level2ItemList[RewardLevel] = DropItemList

            --特殊节点
            if string.len(Reward[Cfg_SeasonBpRewardCfg_P.SpecialItemTinyIconPath]) > 0 then
                self.Index2IsSpecial[#self.ShowDataList + 1] = true
                self.ShowDataList[#self.ShowDataList + 1] = RewardLevel
            end
            --正常节点
            self.Index2IsSpecial[#self.ShowDataList + 1] = false
            self.ShowDataList[#self.ShowDataList + 1] = RewardLevel
            self.LevelList[#self.LevelList + 1] = Reward[Cfg_SeasonBpRewardCfg_P.Level]
            self.Level2ShowIndex[Reward[Cfg_SeasonBpRewardCfg_P.Level]] = #self.LevelList
        end
        if RewardLevel > self.BpLevelMax then
            self.BpLevelMax = RewardLevel
        end
    end
    if not self.CurSelectItemId then
        self.CurSelectLevel = self.LevelList[#self.LevelList]
        local ItemList =  self.Level2ItemList[self.CurSelectLevel]
        self.CurSelectItemId = ItemList[1]
    end
    CWaring("self.CurSelectItemId:" .. self.CurSelectItemId)
    CWaring("self.CurSelectLevel:" .. self.CurSelectLevel)
end

function SeasonTabPass:OnUpdateItem(Handler,Widget, Index)
    local BpLevel = self.ShowDataList[Index + 1]
    local IsSpecialShow = self.Index2IsSpecial[Index + 1]
    -- CWaring("OnUpdateItem:" .. Index)

    if not IsSpecialShow then
        if not self.Widget2Handler[Widget] then
            self.Widget2Handler[Widget] = UIHandler.New(self,Widget,require("Client.Modules.Season.Pass.SeasonBpGoodItemLogic"))
        end
    
        local Param = {
            SeasonBpId = self.SeasonBpId,
            Level = BpLevel,
            ItemList = self.Level2ItemList[BpLevel],
        }
        self.Widget2Handler[Widget].ViewInstance:UpdateUI(Param)
    
        if self.CurSelectLevel == BpLevel then
            self.Widget2Handler[Widget].ViewInstance:Select(self.CurSelectItemId)
        else
            self.Widget2Handler[Widget].ViewInstance:UnSelect()
        end
        self.Level2WidgetHandler[BpLevel] = self.Widget2Handler[Widget]
    else
        ---@type SeasonBpSpecialGoodItemLogicParam
        local Param = {
            SeasonBpId = self.SeasonBpId,
            Lv = BpLevel,
        }
        if not self.Widget2HandlerSpecial[Widget] then
            self.Widget2HandlerSpecial[Widget] = UIHandler.New(self, Widget, require("Client.Modules.Season.Pass.SeasonBpSpecialGoodItemLogic"), Param)
        else
            self.Widget2HandlerSpecial[Widget].ViewInstance:UpdateUI(Param)
        end
        if self.CurSelectLevelSpecial == BpLevel then
            self.Widget2HandlerSpecial[Widget].ViewInstance:Select(self.CurSelectItemId)
        else
            self.Widget2HandlerSpecial[Widget].ViewInstance:UnSelect()
        end
        self.Level2WidgetHandlerSpecial[BpLevel] = self.Widget2HandlerSpecial[Widget]
    end
end

function SeasonTabPass:OnPreUpdateItem(_, Index)
	-- CLog("=============OnPreUpdateItem"..Index)
    local Data = self.ShowDataList[Index + 1]
    if self.Index2IsSpecial[Index + 1] then
        -- ‘换一批’按钮
        self.View.GiftList:ChangeItemClassForIndex(Index, "")
    else
        self.View.GiftList:ChangeItemClassForIndex(Index, 0)
    end
end

function SeasonTabPass:OnReloadFinish()
    if self.CurNeedJumpIdx > 0 then
        CWaring("self.CurNeedJumpIdx:" .. self.CurNeedJumpIdx)
        self.View.GiftList:JumpByIdxStyle(self.CurNeedJumpIdx-1,UE.EReuseListExJumpStyle.Begin)
        -- self.View.GiftList:JumpByIdx(self.CurNeedJumpIdx-1)
    end
    self.CurNeedJumpIdx = 0
end

function SeasonTabPass:OnScrollItem(_, Start, End)
    self.StartItemIndex = Start
    self.EndItemIndex = End
    -- CWaring("self.StartItemIndex:" .. self.StartItemIndex)
    -- CWaring("self.EndItemIndex:" .. self.EndItemIndex)
end

function SeasonTabPass:UpdateBpLevelShow()
    local PassStatus = self.SeasonBpModel:GetPassStatus()
    local CfgBpReward = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.Level,Cfg_SeasonBpRewardCfg_P.SeasonBpId},{PassStatus.Level,PassStatus.SeasonBpId})

    self.View.LbLevel:SetText(string.format("%02d", PassStatus.Level))
    self.View.LbExp:SetText(tostring(PassStatus.Exp))
    if not CfgBpReward then
        CWaring(StringUtil.FormatSimple("SeasonBpLevelPanelLogic:UpdateUI CfgBpReward is nil, Level is{0}, SeasonBpId is{1}"), PassStatus.Level, PassStatus.SeasonBpId)
        return
    end
    self.View.LbExpMax:SetText(tostring(CfgBpReward[Cfg_SeasonBpRewardCfg_P.NeedExp]))

    local Rate = PassStatus.Exp/CfgBpReward[Cfg_SeasonBpRewardCfg_P.NeedExp]

    self.View.ProgressLv:SetPercent(Rate)
end

--更新购买等级按钮是否可见
function SeasonTabPass:UpdateBpLevelBtnShow()
    local IsLevelMax = false
    local PassStatus = self.SeasonBpModel:GetPassStatus()
    if PassStatus.Level >= self.BpLevelMax then
        IsLevelMax = true
    end
    self.View.BtnBpLevelBuy:SetVisibility(IsLevelMax and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
end

--[[
    更新当前选择物品展示
]]
function SeasonTabPass:UpdateSelectGoodShow()
    ---@type CommonDescriptionParam
    local CfgBpReward = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.Level,Cfg_SeasonBpRewardCfg_P.SeasonBpId},{self.CurSelectLevel,self.SeasonBpId})
    local Param = {
        HideBtnSearch = true,
        ItemID = self.CurSelectItemId,
        ShowHighLevelTag = CfgBpReward ~= nil and CfgBpReward[Cfg_SeasonBpRewardCfg_P.TypeId] > 0,
        ShowFreeTagTag = CfgBpReward ~= nil and CfgBpReward[Cfg_SeasonBpRewardCfg_P.TypeId] == Pb_Enum_PASS_TYPE.BASIC
    }
    if not self.CommonDescriptionCls then
        self.CommonDescriptionCls = UIHandler.New(self,self.View.WBP_Common_Description, CommonDescription, Param).ViewInstance
    else
        self.CommonDescriptionCls:UpdateUI(Param)
    end

    self:UpdateIconBg(self.CurSelectLevel)
    self:OnShowAvator()
end

--[[
    根据当前是否是预览状态，更新展示
]]
function SeasonTabPass:UpdateGoodWatchShow(ForceResume)
    if ForceResume then
        self.View.DownPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    local CurVisible = self.View.DownPanel:GetVisibility()
    self.View.GoodPreShowBtnClose:SetVisibility(CurVisible == UE.ESlateVisibility.SelfHitTestInvisible and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
end

--更新2D物品背景底框
function SeasonTabPass:UpdateIconBg(Level)
    self.View.GoodImageBg:SetVisibility(UE.ESlateVisibility.Collapsed)
    local CfgBpReward = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.Level,Cfg_SeasonBpRewardCfg_P.SeasonBpId},{Level,self.SeasonBpId})
    if string.len(CfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemBgPath]) == 0 then
        return
    end
    self.View.GoodImageBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonUtil.SetBrushFromSoftObjectPath(self.View.GoodImageBg, CfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemBgPath], true)
end

--更新武器的点光源显示
function SeasonTabPass:UpdatePointLightShow(IsShow)
    if not self.LightActor then
        local World = UE.UKismetSystemLibrary.GetWorld(_G.GameInstance)
        local APointLightList = UE.TArray(UE.APointLight)
        UE.UGameplayStatics.GetAllActorsOfClass(World, UE.APointLight, APointLightList)
        for i=1, APointLightList:Num() do
            local APointLight = APointLightList:Get(i)
            if APointLight:ActorHasTag("SeasonTabPassWeapon") then
                self.LightActor = APointLight
            end
        end
    end
    if not self.LightActor then
        return
    end
    self.LightActor.LightComponent:SetVisibility(IsShow)
end

--常规奖励道具点击事件
function SeasonTabPass:ON_SEASON_BP_MAIN_SELECT_ITEM_SHOW(Param)
    local ItemId = Param.ItemId
    local Level = Param.Level
    if self.CurSelectItemId == ItemId and self.CurSelectLevel == Level then
        return
    end
    self.View.LbRewards:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.CurSelectLevelSpecial = 0
    local OldSelectLevel = self.CurSelectLevel
    local OldHandler = self.Level2WidgetHandler[self.CurSelectLevel]
    self.CurSelectItemId = ItemId
    self.CurSelectLevel = Level
    local NewHandler = self.Level2WidgetHandler[self.CurSelectLevel]
    if NewHandler then
        NewHandler.ViewInstance:Select(self.CurSelectItemId)
    end
    if OldSelectLevel ~= self.CurSelectLevel then
        if OldHandler then
            OldHandler.ViewInstance:UnSelect()
        end
    end
    self:UpdateSelectGoodShow();
end

--特殊奖励道具点击事件
function SeasonTabPass:ON_SEASON_BP_MAIN_SELECT_SPECIAL_ITEM_SHOW(Lv)
    if self.CurSelectLevelSpecial == Lv then
        return
    end
    self.View.LbRewards:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.GoodImage:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.CurSelectItemId = 0
    self.CurSelectLevel = 0

    local OldSelectLevel = self.CurSelectLevelSpecial
    local OldHandler = self.Level2WidgetHandlerSpecial[OldSelectLevel]
    self.CurSelectLevelSpecial = Lv
    local NewHandler = self.Level2WidgetHandlerSpecial[self.CurSelectLevelSpecial]
    if NewHandler then
        NewHandler.ViewInstance:Select()
    end
    if OldHandler then
        OldHandler.ViewInstance:UnSelect()
    end


    if self.CommonDescriptionCls then
        self.CommonDescriptionCls:SetViewVisible(false)
    end
    self:UpdateIconBg(self.CurSelectLevelSpecial)
    --隐藏Avatar
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then return end
    HallAvatarMgr:HideAvatarByViewID(self:ClassId())
    --显示特殊节点物品
    local CfgBpReward = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.Level,Cfg_SeasonBpRewardCfg_P.SeasonBpId},{self.CurSelectLevelSpecial,self.SeasonBpId})
    if string.len(CfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemBigIconPath]) > 0 then
        self.View.GoodImageSpecial:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GoodImageSpecial, CfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemBigIconPath], true)
    end
    self.PreviewHandle:ManualClose()
end

function SeasonTabPass:ON_SEASON_BP_LEVEL_UPDATE_FUNC()
    self:UpdateBpLevelShow()
end

function SeasonTabPass:ON_SEASON_BP_EXP_UPDATE_FUNC()
    self:UpdateBpLevelShow()
    self:UpdateBpLevelBtnShow()
end

function SeasonTabPass:OnBtnBpLevelBuyClick()
    -- UIAlert.Show("功能还未开发")
    local Param = {
        SeasonBpId = self.SeasonBpId
    }
    MvcEntry:OpenView(ViewConst.SeasonBpBuyLevel,Param)
end
function SeasonTabPass:OnClickedTask()
    -- UIAlert.Show("功能还未开发")
    MvcEntry:OpenView(ViewConst.SeasonBpTask)
end
function SeasonTabPass:OnClickedBuyBp()
    local PassStatus = self.SeasonBpModel:GetPassStatus()
    if PassStatus.PassType ~= Pb_Enum_PASS_TYPE.BASIC then
        return
    end
    --TODO 打开通行证购买界面
    MvcEntry:OpenView(ViewConst.SeasonBpBuy)
end
function SeasonTabPass:OnEscClicked()
    --TODO 返回游戏大厅
    CommonUtil.SwitchHallTab(CommonConst.HL_PLAY)
end
function SeasonTabPass:OnBtnGoodWatchClick()
    local CurVisible = self.View.DownPanel:GetVisibility()
    self.View.DownPanel:SetVisibility(CurVisible == UE.ESlateVisibility.SelfHitTestInvisible and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    self:UpdateGoodWatchShow()
end

return SeasonTabPass
