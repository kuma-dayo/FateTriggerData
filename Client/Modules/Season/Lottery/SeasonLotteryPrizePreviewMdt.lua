--[[
    赛季，抽奖奖励预览界面
]] local class_name = "SeasonLotteryPrizePreviewMdt";
SeasonLotteryPrizePreviewMdt = SeasonLotteryPrizePreviewMdt or BaseClass(GameMediator, class_name);

SeasonLotteryPrizePreviewMdt.PreviewItemType = {
    -- 单独一个占一行
    LARGE = "Litem",
    MIDDLE = "MItem",
    NORMAL = "Default"
}

function SeasonLotteryPrizePreviewMdt:__init()
end

function SeasonLotteryPrizePreviewMdt:OnShow(data)
end

function SeasonLotteryPrizePreviewMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.CommonCurrencyListView = UIHandler.New(self, self.WBP_CommonCurrency, CommonCurrencyList).ViewInstance

    UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips, {
        OnItemClick = Bind(self, self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_SeasonLotteryPrizePreviewMdt_return")),
        ActionMappingKey = ActionMappings.Escape
    })

    self.BindNodes = {{
        UDelegate = self.WBP_ReuseListEx.OnUpdateItem,
        Func = self.OnUpdateItem
    }, {
        UDelegate = self.WBP_ReuseListEx.OnPreUpdateItem,
        Func = self.OnPreUpdateItem
    }}

    self.Widget2HandlerList = {}
    self.PrizeId2Handler = {}

    self.HeroInstID = self.viewId .. "100"
    self.WeaponInstID = self.viewId .. "200"
end

--[[
    Param = {
        PrizePoolId
    }
]]
function M:OnShow(Param)
    self.PrizePoolId = Param.PrizePoolId

    -- TODO 更新货币展示
    local PrizePoolConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePoolConfig, self.PrizePoolId)
    self.CommonCurrencyListView:UpdateShowByParam({ShopDefine.CurrencyType.DIAMOND,
                                                   PrizePoolConfig[Cfg_PrizePoolConfig_P.OneNeedItemId]})

    self.PrizePreviewList = MvcEntry:GetModel(SeasonLotteryModel):GetPreviewPrizeListByPoolId(self.PrizePoolId)
    if not self.PrizePreviewList or #self.PrizePreviewList <= 0 then
        CError("self.PrizePreviewList Empty", true)
        return
    end
    self.CurSelectPrize = self.PrizePreviewList[1][Cfg_PrizePreviewConfig_P.PreviewPrizeId]
    self:UpdateLefListPanel()
    self:UpdateRightPanel()
end

function M:OnHide()
end

function M:OnShowAvator(Data, IsNotVirtualTrigger)
    if not IsNotVirtualTrigger then
        self:UpdateAvatarOrPicShow()
    end
end

function M:OnHideAvator(Data, IsNotVirtualTrigger)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then return end
    HallAvatarMgr:HideAvatarByViewID(self.viewId)
end

--[[
    更新左边列表展示
]]
function M:UpdateLefListPanel()
    self.ScrollIndexInfoList = {}

    local Index = 1
    while Index <= #self.PrizePreviewList do
        -- CWaring("Index:" .. Index)
        if Index == 1 then
            local PrizePreview = self.PrizePreviewList[Index]
            if PrizePreview[Cfg_PrizePreviewConfig_P.IsMainReward] then
                local NextPrizePreview = self.PrizePreviewList[Index + 1]
                if NextPrizePreview and NextPrizePreview[Cfg_PrizePreviewConfig_P.IsMainReward] then
                    -- MItem
                    local IndexInfo = {
                        PreviewItemType = SeasonLotteryPrizePreviewMdt.PreviewItemType.MIDDLE,
                        PrizeList = {PrizePreview, NextPrizePreview}
                    }
                    table.insert(self.ScrollIndexInfoList, IndexInfo)
                    Index = Index + 1
                else
                    -- LItem
                    local IndexInfo = {
                        PreviewItemType = SeasonLotteryPrizePreviewMdt.PreviewItemType.LARGE,
                        PrizeList = {PrizePreview}
                    }
                    table.insert(self.ScrollIndexInfoList, IndexInfo)
                end
            end
        else
            -- Default
            local PrizePreview = self.PrizePreviewList[Index]
            local NextPrizePreview = self.PrizePreviewList[Index + 1]
            local IndexInfo = {
                PreviewItemType = SeasonLotteryPrizePreviewMdt.PreviewItemType.NORMAL,
                PrizeList = {PrizePreview, NextPrizePreview}
            }
            table.insert(self.ScrollIndexInfoList, IndexInfo)
            Index = Index + 1
        end
        Index = Index + 1
    end

    self.WBP_ReuseListEx:Reload(#self.ScrollIndexInfoList)
end

function M:OnUpdateItem(Widget, Index)
    local FixedIndex = Index + 1
    local IndexInfo = self.ScrollIndexInfoList[FixedIndex]

    -- TODO 根据不同类型，去解耦不同逻辑 
    local ItemPreName = "WBP_Lottery_ListItem_"
    local PreviewItemType = IndexInfo.PreviewItemType
    if not self.Widget2HandlerList[Widget] then
        if PreviewItemType == SeasonLotteryPrizePreviewMdt.PreviewItemType.MIDDLE or PreviewItemType ==
            SeasonLotteryPrizePreviewMdt.PreviewItemType.NORMAL then
            -- 存在两个实例Item，需要实例两个
            for Index, PrizeInfo in ipairs(IndexInfo.PrizeList) do
                local WidgetKey = ItemPreName .. Index
                if Widget[WidgetKey] then
                    local Handler = UIHandler.New(self, Widget[WidgetKey], require(
                        "Client.Modules.Season.Lottery.SeasonLotteryPrizePreviewItemLogic"))
                    self.Widget2HandlerList[Widget] = self.Widget2HandlerList[Widget] or {}
                    table.insert(self.Widget2HandlerList[Widget], Handler)
                end
            end
        else
            -- 只存在一个实例Item，实例自身即可
            local Handler = UIHandler.New(self, Widget,
                require("Client.Modules.Season.Lottery.SeasonLotteryPrizePreviewItemLogic"))
            self.Widget2HandlerList[Widget] = self.Widget2HandlerList[Widget] or {}
            table.insert(self.Widget2HandlerList[Widget], Handler)
        end
    end
    if not self.Widget2HandlerList[Widget] then
        print_r(IndexInfo)
        CError("M:OnUpdateItem self.Widget2HandlerList Empty")
        return
    end
    for Index, Handler in ipairs(self.Widget2HandlerList[Widget]) do
        local PrizeInfo = IndexInfo.PrizeList[Index]
        if PrizeInfo then
            local PrizeId = PrizeInfo[Cfg_PrizePreviewConfig_P.PreviewPrizeId]
            -- CWaring("PrizeId:" .. PrizeId)
            local Param = {
                PrizeId = PrizeId,
                PreviewItemType = PreviewItemType,
                PrizeClickCallback = Bind(self, self.OnPreviewPrizeClick)
            }
            Handler.ViewInstance:ShowUI()
            Handler.ViewInstance:UpdateUI(Param)

            self.PrizeId2Handler[PrizeId] = Handler

            if PrizeId == self.CurSelectPrize then
                Handler.ViewInstance:Select()
            else
                Handler.ViewInstance:UnSelect()
            end
        else
            Handler.ViewInstance:HideUI()
        end
    end
end
function M:OnPreUpdateItem(Index)
    local FixedIndex = Index + 1

    local IndexInfo = self.ScrollIndexInfoList[FixedIndex]
    if IndexInfo.PreviewItemType == SeasonLotteryPrizePreviewMdt.PreviewItemType.NORMAL then
        self.WBP_ReuseListEx:ChangeItemClassForIndex(Index, "")
    else
        self.WBP_ReuseListEx:ChangeItemClassForIndex(Index, IndexInfo.PreviewItemType)
    end
end

--[[
    更新右侧内容展示
]]
function M:UpdateRightPanel()
    local PrizePreviewConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePreviewConfig, self.CurSelectPrize)
    local ItemId = PrizePreviewConfig[Cfg_PrizePreviewConfig_P.ItemId]
    local TheDepotModel = MvcEntry:GetModel(DepotModel)
    local TheQualityCfg = TheDepotModel:GetQualityCfgByItemId(ItemId)
    -- TODO 更新道具名称
    self.LbPrizeName:SetText(TheDepotModel:GetItemName(ItemId))
    self.LbQualityLevel:SetText(TheQualityCfg[Cfg_ItemQualityColorCfg_P.Level])

    -- TOOD 更新道具类别 及 根据品质设置好其颜色
    self.LbPrizeTypeName:SetText(TheDepotModel:GetItemTypeShowByItemId(ItemId))
    CommonUtil.SetTextColorFromeHex(self.LbPrizeTypeName, TheDepotModel:GetHexColorByItemId(ItemId))

    CommonUtil.SetBrushFromSoftObjectPath(self.GUIImageQuality,TheQualityCfg[Cfg_ItemQualityColorCfg_P.CornerIconWithBg])

    -- TODO 更新奖励描述
    self.LbPrizeDes:SetText(PrizePreviewConfig[Cfg_PrizePreviewConfig_P.PreviewPrizeDes])

    self:UpdateAvatarOrPicShow()
end

function M:UpdateAvatarOrPicShow()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr ~= nil then
        HallAvatarMgr:ShowAvatarByViewID(self.viewId, false)
    end
    
    local PrizePreviewConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePreviewConfig, self.CurSelectPrize)
    -- TODO 显示对应的Avatar
    if PrizePreviewConfig[Cfg_PrizePreviewConfig_P.PreviewShowIcon] and string.len(PrizePreviewConfig[Cfg_PrizePreviewConfig_P.PreviewShowIcon]) > 0 then
        self.ImageContent:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.ImageContent,PrizePreviewConfig[Cfg_PrizePreviewConfig_P.PreviewShowIcon],true)

        local ItemId = PrizePreviewConfig[Cfg_PrizePreviewConfig_P.ItemId]
        ---@type RtShowTran
        local FinalTran = CommonUtil.GetShowTranByItemID(ETransformModuleID.BP_LotteryDetail.ModuleID, ItemId)
        if FinalTran and FinalTran.RenderTran then
            CommonUtil.SetBrushRenderTransform(self.ImageContent, FinalTran.RenderTran)
        end
    else
        self.ImageContent:SetVisibility(UE.ESlateVisibility.Collapsed)

        -- 尝试去显示Avatar
        local ItemId = PrizePreviewConfig[Cfg_PrizePreviewConfig_P.ItemId]
        local ItemConfig = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)

        local PrizeLocationValue = PrizePreviewConfig[Cfg_PrizePreviewConfig_P.PrizeLocation]
        local PrizeRotatorValue = PrizePreviewConfig[Cfg_PrizePreviewConfig_P.PrizeRotator]
        local PrizeScaleValue = PrizePreviewConfig[Cfg_PrizePreviewConfig_P.PrizeScale]
        local TheLocation = UE.FVector(PrizeLocationValue:Get(1),PrizeLocationValue:Get(2),PrizeLocationValue:Get(3))
        local TheRotator = UE.FRotator(PrizeRotatorValue:Get(1),PrizeRotatorValue:Get(2),PrizeRotatorValue:Get(3))
        local TheScale = UE.FVector(PrizeScaleValue:Get(1),PrizeScaleValue:Get(2),PrizeScaleValue:Get(3))

        --代码中设置3D模型的默认Transform信息
        local DefParam = {DefPos = TheLocation, DefRot = TheRotator, DefScale = TheScale}
        ---@type RtShowTran 从配置中获取3D模型Transform信息
        local FinalTran = CommonUtil.GetShowTranByItemID(ETransformModuleID.BP_LotteryDetail.ModuleID, ItemId, DefParam)

        if ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER then
            --角色
            local HeroSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.ItemId,ItemId)
            local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
            if HallAvatarMgr == nil then
                return
            end
            local SpawnHeroParam = {
                ViewID = self.viewId,
                InstID = 0,
                HeroId = HeroSkinConfig[Cfg_HeroSkin_P.HeroId],
                SkinID = HeroSkinConfig[Cfg_HeroSkin_P.SkinId],
                Location = FinalTran.Pos or TheLocation,--UE.FVector(79987,-100,30),
                Rotation = FinalTran.Rot or TheRotator,--UE.FRotator(0, 0, 2),
                Scale = FinalTran.Scale or TheScale,
            }
            local Avatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
            if Avatar ~= nil then				
                Avatar:OpenOrCloseCameraAction(false)
                Avatar:SetCapsuleComponentSize(400, 300)
            end
        elseif ItemConfig[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_WEAPON then
            --武器
            local WeaponSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,Cfg_WeaponSkinConfig_P.ItemId,ItemId)
            local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
            if HallAvatarMgr == nil then
                return
            end
            local SpawnHeroParam = {
                ViewID = self.viewId,
                InstID = 0,
                WeaponID = WeaponSkinConfig[Cfg_WeaponSkinConfig_P.WeaponId],
                SkinID = WeaponSkinConfig[Cfg_WeaponSkinConfig_P.SkinId],
                Location = FinalTran.Pos or TheLocation,--UE.FVector(79987,0,135),
                Rotation = FinalTran.Rot or TheRotator,--UE.FRotator(0, 90, 2),
                Scale = FinalTran.Scale or TheScale,
            }
            local Avatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_WEAPON, SpawnHeroParam)
            if Avatar ~= nil then				
                Avatar:OpenOrCloseCameraAction(false)
            end
        end
    end
end


function M:OnPreviewPrizeClick(PreviewPrizeId)
    if PreviewPrizeId == self.CurSelectPrize then
        CWaring("M:OnPreviewPrizeClick same click")
        return
    end
    local Handler = self.PrizeId2Handler[self.CurSelectPrize]
    if Handler then
        Handler.ViewInstance:UnSelect()
    end
    self.CurSelectPrize = PreviewPrizeId
    Handler = self.PrizeId2Handler[self.CurSelectPrize]
    if Handler then
        Handler.ViewInstance:Select()
    end
    self:UpdateRightPanel()
end

--[[
    关闭界面(自身)
]]
function M:OnEscClicked()
    MvcEntry:CloseView(self.viewId)
end

return M
