--[[
    角色展示板详情解耦逻辑
]]

---@class HeroDisplayBoardDetailLogic
local class_name = "HeroDisplayBoardDetailLogic"
local HeroDisplayBoardDetailLogic = BaseClass(nil, class_name)

function HeroDisplayBoardDetailLogic:OnInit()
    -- -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    -- self.DefaultAvatarLocation = UE.FVector(19957.0, -279.0, 125)
    -- self.DefaultAvatarLocation2 = UE.FVector(19965.0, -279.0, 125)

    self.BindNodes = {
        
	}
    
    self.MsgList = {
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_SELECT, Func = self.ON_HERO_DISPLAYBOARD_FLOOR_SELECT_Func },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_ROLE_SELECT, Func = self.ON_HERO_DISPLAYBOARD_ROLE_SELECT_Func },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_SELECT, Func = self.ON_HERO_DISPLAYBOARD_EFFECT_SELECT_Func },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_STICKER_SELECT, Func = self.ON_HERO_DISPLAYBOARD_STICKER_SELECT_Func },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_SELECT, Func = self.ON_HERO_DISPLAYBOARD_ACHIEVE_SELECT_Func },
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.SpaceBar), Func = self.OnSpaceBarClick },
	}

    self.TabTypeId2Vo = {
        [EHeroDisplayBoardTabID.Floor.TabId] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Hero/DisplayBoard/WBP_HeroDisplayBoardTabCommon.WBP_HeroDisplayBoardTabCommon",
            LuaClass=require("Client.Modules.Hero.HeroDetail.DisplayBoard.FloorChooseLogic"),
            RedDotKey = "HeroDisplayBoardFloorTab_",
        },
        [EHeroDisplayBoardTabID.Role.TabId] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Hero/DisplayBoard/WBP_HeroDisplayBoardTabCommon.WBP_HeroDisplayBoardTabCommon",
            LuaClass=require("Client.Modules.Hero.HeroDetail.DisplayBoard.RoleChooseLogic"),
            RedDotKey = "HeroDisplayBoardRoleTab_",
        },
        [EHeroDisplayBoardTabID.Effect.TabId] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Hero/DisplayBoard/WBP_HeroDisplayBoardTabCommon.WBP_HeroDisplayBoardTabCommon",
            LuaClass=require("Client.Modules.Hero.HeroDetail.DisplayBoard.EffectChooseLogic"),
            RedDotKey = "HeroDisplayBoardEffectTab_",
        },
        [EHeroDisplayBoardTabID.Sticker.TabId] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Hero/DisplayBoard/WBP_HeroDisplayBoardTabSticker.WBP_HeroDisplayBoardTabSticker",
            LuaClass=require("Client.Modules.Hero.HeroDetail.DisplayBoard.StickerChooseLogic"),
            RedDotKey = "HeroDisplayBoardStickerTab_",
        },
        [EHeroDisplayBoardTabID.Achieve.TabId] = {
            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Hero/DisplayBoard/WBP_HeroDisplayBoardTabAchieve.WBP_HeroDisplayBoardTabAchieve",
            LuaClass=require("Client.Modules.Hero.HeroDetail.DisplayBoard.AchieveChooseLogic")
        }
    }

    -- 页签红点列表
    self.TabRedDotItemList = {}
    self.ReActiveByUpdateUI = false
end


--[[
    local Param = {
        HeroId = self.HeroId
    }
]]
function HeroDisplayBoardDetailLogic:OnShow(Param)
    CLog("HeroDisplayBoardDetailLogic:OnShow")
    if not Param then
        return
    end
    self.Param = Param
    self.HeroId = self.Param.HeroId
    self.ModelHero = MvcEntry:GetModel(HeroModel)
    self.SequenceTag = "HeroDisplayBoardDetailLogic"
    self.CurTabId = EHeroDisplayBoardTabID.Floor.TabId
    self:InitCommonUI()
    -- self:UpdateShow()
    self:UpdateNameDetailShow(false)
end

function HeroDisplayBoardDetailLogic:OnManualShow(Param)
    CLog("HeroDisplayBoardDetailLogic:OnManualShow")
    self:UpdateUI(Param)
end

function HeroDisplayBoardDetailLogic:OnManualHide(Param)
    CLog("HeroDisplayBoardDetailLogic:OnManualHide")
    self:UpdateNameDetailShow(true)
    MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(self.SequenceTag)
end

function HeroDisplayBoardDetailLogic:UpdateUI(Param)
    if not Param then
        return
    end
    self.ReActiveByUpdateUI = true
    self.Param = Param
    self.HeroId = self.Param.HeroId
    self:InitCommonUI()
    self:UpdateNameDetailShow(false)
    self:ShowDisplayBoardAvatar()
end

function HeroDisplayBoardDetailLogic:OnShowAvator(Param, IsNotVirtualTrigger)
    CLog(string.format("HeroDisplayBoardDetailLogic:OnShowAvator self.CurTabId = [%s]", tostring(self.CurTabId)))

    self.WidgetBase:UpdateAvatarShow(nil,nil,true)

    ---@type ViewModel
	local ViewModel = MvcEntry:GetModel(ViewModel) 
	local TopView = ViewModel:GetOpenLastView()
    -- CError("dddddddddddddddddddddddddddddddddddd TopView.viewId = "..tostring(TopView.viewId))
	if TopView and TopView.viewId == ViewConst.HeroDisplayBoardStickerEdit then
        CWaring("HeroDisplayBoardDetailLogic:OnShowAvator 角色面板贴纸正在编辑! 2205")
        self:ShowDisplayBoardAvatar()
        local InParam = { bHide = true}
        self:SetAvatarHiddenInGame(InParam)
		return
    else
        self:ShowDisplayBoardAvatar()
	end	
    -- self:AdjustDisplayBoardPosition()
end

function HeroDisplayBoardDetailLogic:OnHideAvator(Param, IsNotVirtualTrigger)
    -- CError("SSSSSSSSSSSS OnHideAvator")
    self:HideDisplayBoardAvatar()
end

function HeroDisplayBoardDetailLogic:OnHide()
    MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(self.SequenceTag)
    self:HideDisplayBoardAvatar()
end

function HeroDisplayBoardDetailLogic:InitCommonUI()
    -- 从配置中获取有效的 MenuTab 菜单项，并排序
    local GetVaildMenuCfgs = function()
        local CfgList = {}
        local Dict = G_ConfigHelper:GetDict(Cfg_HeroDisplayBoardTabConfig)
        for k, Cfg in pairs(Dict) do
            if Cfg[Cfg_HeroDisplayBoardTabConfig_P.IsOpen] then
                table.insert(CfgList,Cfg)
            end
            table.sort(CfgList, function(CfgA, CfgB)
                if CfgA[Cfg_HeroDisplayBoardTabConfig_P.SortIdx] ~= CfgB[Cfg_HeroDisplayBoardTabConfig_P.SortIdx]then
                    return CfgA[Cfg_HeroDisplayBoardTabConfig_P.SortIdx] < CfgB[Cfg_HeroDisplayBoardTabConfig_P.SortIdx]
                end
                return CfgA[Cfg_HeroDisplayBoardTabConfig_P.TabId] < CfgB[Cfg_HeroDisplayBoardTabConfig_P.TabId]
            end)
        end
        return CfgList
    end

    local MenuCfgList = GetVaildMenuCfgs()
    local ItemInfoList = {}
    local CurSelectId = 0
    for idx, MenuCfg in pairs(MenuCfgList) do
        local Id = MenuCfg[Cfg_HeroDisplayBoardTabConfig_P.TabId]
        local RedDotKey = self.TabTypeId2Vo[Id] and self.TabTypeId2Vo[Id].RedDotKey or nil
        table.insert(ItemInfoList,{
            Id = Id,
            LabelStr = MenuCfg[Cfg_HeroDisplayBoardTabConfig_P.TabName],
            -- 可选 红点前缀
            RedDotKey = RedDotKey,
            -- 可选 红点后缀
            RedDotSuffix = self.HeroId,
        })

        if CurSelectId <= 0 then
            CurSelectId =  MenuCfg[Cfg_HeroDisplayBoardTabConfig_P.TabId] 
        end
    end

    local MenuTabParam = {
        ItemInfoList = ItemInfoList,
        CurSelectId = CurSelectId,
        ClickCallBack = Bind(self,self.OnMenuBtnClick),
        ValidCheck = Bind(self,self.MenuValidCheck),
        HideInitTrigger = false,
        IsOpenKeyboardSwitch2 = true
    }
    if not self.MenuTabListCls then
        self.MenuTabListCls = UIHandler.New(self, self.View.WBP_Common_TabUp_03, CommonMenuTabUp, MenuTabParam).ViewInstance
    else
        self.MenuTabListCls:UpdateUI(MenuTabParam)
    end

    -- --通用操作按钮：一键搭配
    -- UIHandler.New(self, self.View.GUIButtonAllFit, WCommonBtnTips,
    -- {
    --     OnItemClick = Bind(self, self.OnGUIButtonSelect),
    --     TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroDisplayBoardDetailLogic_Onekeycollocation"),
    --     CheckButtonIsVisible = true,
    --     HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    -- })
    -- self.DefaultButtonAllFitPosition = self.View.GUIButtonAllFit.Slot:GetPosition()
end

function HeroDisplayBoardDetailLogic:UpdateShow()
    self:OnShowAvator()
end

function HeroDisplayBoardDetailLogic:UpdateNameDetailShow(IsShow)
    -- self.WidgetBase.WBP_HeroNameAndDetailItem:SetVisibility(IsShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function HeroDisplayBoardDetailLogic:SetAvatarHiddenInGame(Param)
    local bHide = Param.bHide or false
    local bReShowDisplayBoard = Param.bReShowDisplayBoard or false 

    if self.CurShowAvatar and self.CurAvatarPos then
        -- 为了解决 角色面板 贴纸瞬间位移而 采用的方案
        local pos = UE.FVector(self.CurAvatarPos.X, self.CurAvatarPos.Y, self.CurAvatarPos.Z)
        if bHide then
            pos.Z = pos.Z + 10000
            self.CurShowAvatar:K2_SetActorLocation(pos, false, nil, false)
        else
            self.CurShowAvatar:K2_SetActorLocation(pos, false, nil, false) 
        end
    else
        CError(string.format("HeroDisplayBoardDetailLogic:SetAvatarHiddenInGame,CurShowAvatar == nil or CurAvatarPos == nil,CurTabId=[%s],bHide=[%s], CurAvatarPos =[%s], bReShowDisplayBoard=[%s]", tostring(self.CurTabId), tostring(bHide), table.tostring(self.CurAvatarPos),tostring(bReShowDisplayBoard)))
    end

    CLog(string.format("HeroDisplayBoardDetailLogic:SetAvatarHiddenInGame,self.CurTabId=[%s],bHide=[%s], CurAvatarPos = [%s],bReShowDisplayBoard=[%s]", tostring(self.CurTabId), tostring(bHide), table.tostring(self.CurAvatarPos),tostring(bReShowDisplayBoard)))

    if bReShowDisplayBoard then
        self:ShowDisplayBoardAvatar()
    end

    -- if self.CurShowAvatar then
    --     self.CurShowAvatar:SetActorHiddenInGame(bHide) 
    -- end
    -- if not(bHide) then
    --     self:ShowDisplayBoardAvatar()
    -- end
end

--- 获取距离相机的距离
function HeroDisplayBoardDetailLogic:GetDistanceFromCarmera(Location)
	local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return nil
	end
	local direction = Location - CameraActor:K2_GetActorLocation()
	direction = UE.UKismetMathLibrary.Normal(direction)
	local targetLocation = CameraActor:K2_GetActorLocation() + direction
	local distance = UE.UKismetMathLibrary.Vector_Distance(Location, targetLocation)
	return distance
end

function HeroDisplayBoardDetailLogic:ShowDisplayBoardAvatar()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end

    -- local Location = self.View.DefaultAvatarLocation
    local Location = self:GetBoardInitPosition()
    local direction = self:GetDistanceFromCarmera(Location)

    CLog(string.format("HeroDisplayBoardDetailLogic:ShowDisplayBoardAvatar Location =[%s]",table.tostring(Location)))

    local FocusMethodSetting = nil
    if CommonUtil.IsValid(self.View) and self.View.FocusSettingsStruct then
        FocusMethodSetting = {
            -- FocusMethod = UE.ECameraFocusMethod.Disable,--禁用聚焦
            FocusMethod = self.View.FocusSettingsStruct.FocusMethod,
            ManualFocusDistance = self.View.FocusSettingsStruct.ManualFocusDistance,
            FocusSettingsStruct = self.View.FocusSettingsStruct
        }
    end

    local SpawnParam = {
        ViewID = ViewConst.HeroDisplayBoardView,
        InstID = 0,
        DisplayBoardID = self.HeroId,
        Location = Location,
        Rotation = UE.FRotator(0, 90, 0),
        -- Scale = UE.FVector(0.11, 0.11, 0.11),
        Scale = self.View.Board3DScale,
        FocusMethodSetting = FocusMethodSetting,
    }

    if not self.CurShowAvatar then
        self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_DISPLAYBOARD, SpawnParam)
    else 
        self.CurShowAvatar:Show(true,SpawnParam)
    end
    self.CurAvatarPos = Location
    self.CurShowAvatar:SetActorHiddenInGame(false)

    -- 播放LS
    local LSPath = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_HEROMAIN_TAB_DISPLAYBOARD)
    if LSPath and LSPath ~= "" then
        local SetBindings = {
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

        local PlayParam = {
            LevelSequenceAsset = LSPath,
            SetBindings = SetBindings,
            -- TransformOrigin = self.CurShowAvatar:GetTransform(),
            NeedStopAllSequence = true,
        }
        MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(self.SequenceTag, function()
            if self.CurShowAvatar then
                self.CurShowAvatar:SetActorHiddenInGame(false)
                CLog(string.format("HeroDisplayBoardDetailLogic:ShowDisplayBoardAvatar, LS End !! Location=[%s]", self.CurShowAvatar:K2_GetActorLocation()))
            end
        end, PlayParam)
    end
end

function HeroDisplayBoardDetailLogic:HideDisplayBoardAvatar()
    MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(self.SequenceTag)

    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr ~= nil then
        HallAvatarMgr:HideAvatarByViewID(ViewConst.HeroDisplayBoardView)    
    end

    -- local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    -- if HallAvatarMgr == nil then
    --     return
    -- end
    -- HallAvatarMgr:ShowAvatarByViewID(ViewConst.HeroDisplayBoardView, false)
end

-- function HeroDisplayBoardDetailLogic:ShowSelectedDisplay()
--     local Param = 
--     {
--         DisplayId = self.HeroId,
--     }
--     self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_SHOW, Param)
--     self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_ROLE_SHOW, Param)
--     self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_SHOW, Param)
--     self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_STICKER_SHOW, Param)
--     self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_SHOW, Param)
-- end


--按钮事件
function HeroDisplayBoardDetailLogic:OnMenuBtnClick(Id, ItemInfo, IsInit)
    self.CurTabId = Id
    
    CLog(string.format("HeroDisplayBoardDetailLogic:OnMenuBtnClick, self.CurTabId = [%s]", tostring(self.CurTabId)))

	self:UpdateTabShow()
    self:AdjustDisplayBoardPosition()
    self:AdjustButtonAllFitPosition()
end

function HeroDisplayBoardDetailLogic:MenuValidCheck(Id)
    return true
end

--[[
    更新当前Tab页展示
]]
function HeroDisplayBoardDetailLogic:UpdateTabShow()
    local VoItem = self.TabTypeId2Vo[self.CurTabId]
    if not VoItem then
        CError("HeroDisplayBoardDetailLogic:UpdateTabShow() VoItem nil")
        return
    end

    local Param = {
        TabId = self.CurTabId, 
        HeroId = self.HeroId, 
        OnChooseBoradItem = Bind(self, self.OnChooseBoradItem),
        OnRequestAvatarHiddenInGame = Bind(self, self.SetAvatarHiddenInGame)
    }

    if not VoItem.ViewItem then
        local WidgetClassPath = VoItem.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self.View)
        UIRoot.AddChildToPanel(Widget,self.View.PanelContent)
       
        local ViewItemHandle = UIHandler.New(self, Widget, VoItem.LuaClass, Param)
        VoItem.ViewItemHandle = ViewItemHandle
        VoItem.ViewItem = ViewItemHandle.ViewInstance
        VoItem.View = Widget
    end

    -- for TheTabId,TheVo in pairs(self.TabTypeId2Vo) do
    --     local TheShow = false
    --     if TheTabId == self.CurTabId then
    --         TheShow = true
    --     end
    --     if TheVo.View then
    --         TheVo.View:SetVisibility(TheShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    --         if not TheShow then
    --             TheVo.ViewItemHandle:ManualClose()
    --         end
    --     end
    -- end

    for TheTabId, TheVo in pairs(self.TabTypeId2Vo) do
        if TheVo.ViewItemHandle and TheVo.ViewItemHandle:IsValid() then
            if TheTabId == self.CurTabId then
                --TheVo.ViewItemHandle:ManualOpen(Param)
            else
                TheVo.ViewItemHandle:ManualClose()
            end
        end
    end

    --被UpdateUI激活时，不会调子项的OnManualShow,所以这里手动调用UpdateUI
    if self.ReActiveByUpdateUI and VoItem.ViewItem.UpdateUI then
        VoItem.ViewItem:UpdateUI(Param)
        self.ReActiveByUpdateUI = false
    end
    -- VoItem.ViewItem:OnShow(Param)
    VoItem.ViewItemHandle:ManualOpen(Param)
    self:Refresh3DDisplayBoard()
end

function HeroDisplayBoardDetailLogic:OnChooseBoradItem(Param)
    if not(CommonUtil.IsValid(self.View.WBP_Common_Description)) then
        return
    end

    local TabId = Param.TabId
    local BoradId = Param.BoradId

    if BoradId == 0 then
        self.View.WBP_Common_Description:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    else
        self.View.WBP_Common_Description:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    
    local Param = {
        HideBtnSearch = true,
        ItemID = 0,
    }

    if TabId == EHeroDisplayBoardTabID.Floor.TabId then
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayFloor, BoradId)
        Param.ItemID = Cfg and Cfg[Cfg_HeroDisplayFloor_P.ItemId] or 0
    elseif TabId == EHeroDisplayBoardTabID.Role.TabId then
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayRole, BoradId)
        Param.ItemID = Cfg and Cfg[Cfg_HeroDisplayRole_P.ItemId] or 0
    elseif TabId == EHeroDisplayBoardTabID.Effect.TabId then
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayEffect, BoradId)
        Param.ItemID = Cfg and Cfg[Cfg_HeroDisplayEffect_P.ItemId] or 0
    elseif TabId == EHeroDisplayBoardTabID.Sticker.TabId then
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplaySticker, BoradId)
        Param.ItemID = Cfg and Cfg[Cfg_HeroDisplaySticker_P.ItemId] or 0
    elseif TabId == EHeroDisplayBoardTabID.Achieve.TabId then
        Param.ItemID = BoradId
    end

    if not self.CommonDescriptionCls then
        self.CommonDescriptionCls = UIHandler.New(self,self.View.WBP_Common_Description, CommonDescription, Param).ViewInstance
    else
        if TabId == EHeroDisplayBoardTabID.Achieve.TabId then
            self.CommonDescriptionCls:SetViewVisible(false)
        else
            self.CommonDescriptionCls:UpdateUI(Param)    
        end
    end
end

function HeroDisplayBoardDetailLogic:AdjustDisplayBoardPosition()
    if self.CurShowAvatar == nil then
        return
    end

    local Location = self:GetBoardInitPosition()
    self.CurAvatarPos = Location
    self.CurShowAvatar:K2_SetActorLocation(Location, false, nil, false)
end

function HeroDisplayBoardDetailLogic:AdjustButtonAllFitPosition()
    if self.CurTabId == EHeroDisplayBoardTabID.Floor.TabId
    or self.CurTabId == EHeroDisplayBoardTabID.Role.TabId 
    or self.CurTabId == EHeroDisplayBoardTabID.Effect.TabId then
        -- self.View.GUIButtonAllFit.Slot:SetPosition(UE.FVector2D(-14, -174.0))
    else
        -- self.View.GUIButtonAllFit.Slot:SetPosition(UE.FVector2D(436, -174.0))
    end
end

function HeroDisplayBoardDetailLogic:GetBoardInitPosition()
    local Location = self.View.DefaultAvatarLocation
    if self.CurTabId == EHeroDisplayBoardTabID.Floor.TabId
    or self.CurTabId == EHeroDisplayBoardTabID.Role.TabId
    or self.CurTabId == EHeroDisplayBoardTabID.Effect.TabId then
        Location = self.View.DefaultAvatarLocation
    else
        Location = self.View.StickerAvatarLocation
    end
    return Location
end


--[[
    当前编辑角色的完整套装＞每一层放已拥有的最高品级资源（品级相同时随机）＞某一层没有已获取的资源时就不放
]]
function HeroDisplayBoardDetailLogic:GetTheBestFloorId(HeroId)
    local DataList = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroDisplayFloor,Cfg_HeroDisplayFloor_P.HeroId, HeroId)
    local TheBestId = 0
    local TheBestItemId = 0

    for _, v in ipairs(DataList) do
        local Id = v[Cfg_HeroDisplayFloor_P.Id]
        local ItemId = v[Cfg_HeroDisplayFloor_P.ItemId]
        if MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) > 0 then
            if TheBestId == 0 then
                TheBestId = Id
                TheBestItemId = ItemId
            else
                local TheBestItemIdCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, TheBestItemId)
                local TheItemIdCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
                if TheItemIdCfg[Cfg_ItemConfig_P.Quality] > TheBestItemIdCfg[Cfg_ItemConfig_P.Quality] then
                    TheBestId = Id
                    TheBestItemId = ItemId
                end
            end
        end
    end
    return TheBestId
end

function HeroDisplayBoardDetailLogic:GetTheBestRoleId(HeroId)
    local DataList = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroDisplayRole,Cfg_HeroDisplayRole_P.HeroId, HeroId)
    local TheBestId = 0
    local TheBestItemId = 0

    for _, v in ipairs(DataList) do
        local Id = v[Cfg_HeroDisplayRole_P.Id]
        local ItemId = v[Cfg_HeroDisplayRole_P.ItemId]
        if MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) > 0 then
            if TheBestId == 0 then
                TheBestId = Id
                TheBestItemId = ItemId
            else
                local TheBestItemIdCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, TheBestItemId)
                local TheItemIdCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
                if TheItemIdCfg[Cfg_ItemConfig_P.Quality] > TheBestItemIdCfg[Cfg_ItemConfig_P.Quality] then
                    TheBestId = Id
                    TheBestItemId = ItemId
                end
            end
        end
    end
    return TheBestId
end

function HeroDisplayBoardDetailLogic:GetTheBestEffectId()
    local DataList = G_ConfigHelper:GetDict(Cfg_HeroDisplayEffect)
    local TheBestId = 0
    local TheBestItemId = 0

    for _, v in ipairs(DataList) do
        local Id = v[Cfg_HeroDisplayEffect_P.Id]
        local ItemId = v[Cfg_HeroDisplayEffect_P.ItemId]
        if MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) > 0 then
            if TheBestId == 0 then
                TheBestId = Id
                TheBestItemId = ItemId
            else
                local TheBestItemIdCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, TheBestItemId)
                local TheItemIdCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
                if TheItemIdCfg[Cfg_ItemConfig_P.Quality] > TheBestItemIdCfg[Cfg_ItemConfig_P.Quality] then
                    TheBestId = Id
                    TheBestItemId = ItemId
                end
            end
        end
    end
    return TheBestId
end


--[[
    获取已拥有并且品质前三的StickerId
]]
function HeroDisplayBoardDetailLogic:GetTheTop3StickerId()
    local DataList = G_ConfigHelper:GetDict(Cfg_HeroDisplaySticker)

    local OwnList = {}
    for _, v in ipairs(DataList) do
        local Id = v[Cfg_HeroDisplaySticker_P.Id]
        local ItemId = v[Cfg_HeroDisplaySticker_P.ItemId]
        if MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) > 0 then
            local TheItemIdCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
           table.insert(OwnList, {Id = Id, Quality = TheItemIdCfg[Cfg_ItemConfig_P.Quality]})
        end
    end
    table.sort(OwnList, function(A, B)
        if A.Quality > B.Quality then
            return true
        end
        return A.Id > B.Id
    end
    )
    return OwnList[1] and OwnList[1].Id or 0, OwnList[2] and OwnList[2].Id or 0, OwnList[3] and OwnList[3].Id or 0
end


--[[
    获取已拥有并且品质最高的AchiveId，参数：英雄HeroId
]]
function HeroDisplayBoardDetailLogic:GetTheTop3AchieveId()
    local DataList = MvcEntry:GetModel(AchievementModel):GetDataList()

    local OwnList = {}
    for _, v in ipairs(DataList) do
        local Id = v.ID
        if v:IsUnlock() then
            local Lvl, _ = v:GetLevel()
            table.insert(OwnList, {Id = Id,  Level = Lvl })
        end
    end

    table.sort(OwnList, function(A, B)
        return A.Id > B.Id
    end)

    return OwnList[1] and OwnList[1].Id or 0, OwnList[2] and OwnList[2].Id or 0, OwnList[3] and OwnList[3].Id or 0
end


function HeroDisplayBoardDetailLogic:OnGUIButtonSelect()
    local TblSetList = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroDisplayBoardSet, Cfg_HeroDisplayBoardSet_P.HeroId, self.HeroId)
    local SelectParam = {}
    local MatchAnySet = false
    for _, Cfg in ipairs(TblSetList) do
        local FloorSetId = Cfg[Cfg_HeroDisplayBoardSet_P.FloorId]
        local RoleSetId = Cfg[Cfg_HeroDisplayBoardSet_P.RoleId]
        local EffectSetId = Cfg[Cfg_HeroDisplayBoardSet_P.EffectId]
        local StickerSetId = Cfg[Cfg_HeroDisplayBoardSet_P.StickerId]
    
        if self.ModelHero:HasDisplayBoardFloor(FloorSetId)
            and self.ModelHero:HasDisplayBoardRole(RoleSetId)
            and self.ModelHero:HasDisplayBoardEffect(EffectSetId)
            and self.ModelHero:HasDisplayBoardSticker(StickerSetId) then
            --当前编辑角色的完整套装
            SelectParam.FloorId = FloorSetId
            SelectParam.RoleId = RoleSetId
            SelectParam.EffectId = EffectSetId
            SelectParam.StickerId1 = StickerSetId
            MatchAnySet = true
            break
        end
    end

    if not MatchAnySet then
        SelectParam.FloorId = self:GetTheBestFloorId(self.HeroId)
        SelectParam.RoleId = self:GetTheBestRoleId(self.HeroId)
        SelectParam.EffectId = self:GetTheBestEffectId()
        SelectParam.StickerId1,SelectParam.StickerId2,SelectParam.StickerId3 = self:GetTheTop3StickerId()
        SelectParam.AchieveId1,SelectParam.AchieveId2,SelectParam.AchieveId3 = self:GetTheTop3AchieveId()
    end

    print_r(SelectParam)
    --背景
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerSelectFloorReq(self.HeroId, SelectParam.FloorId)

    --角色
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerSelectRoleReq(self.HeroId, SelectParam.RoleId)

    --特效
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerSelectEffectReq(self.HeroId, SelectParam.EffectId)

    --贴纸
    local Float2IntScale = HeroModel.DISPLAYBOARD_FLOAT2INTSCALE
    local StickerInfo = {
        StickerId = 0,
        XPos = 0,
        YPos = 0,
        Angle = 0,
        Scale = 1 * Float2IntScale
     }
    StickerInfo.StickerId = SelectParam.StickerId1
    StickerInfo.XPos = 5 * Float2IntScale
    StickerInfo.YPos = 236 * Float2IntScale
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerEquipStickerReq(self.HeroId, 1, StickerInfo)
    StickerInfo.StickerId = SelectParam.StickerId2
    StickerInfo.XPos = -320 * Float2IntScale
    StickerInfo.YPos = 239 * Float2IntScale
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerEquipStickerReq(self.HeroId, 2, StickerInfo)
    StickerInfo.StickerId = SelectParam.StickerId3
    StickerInfo.XPos = -327 * Float2IntScale
    StickerInfo.YPos = -475 * Float2IntScale
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerEquipStickerReq(self.HeroId, 3, StickerInfo)

    --成就
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerEquipAchieveReq(self.HeroId, 1, SelectParam.AchieveId1 or 0)
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerEquipAchieveReq(self.HeroId, 2, SelectParam.AchieveId2 or 0)
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerEquipAchieveReq(self.HeroId, 3, SelectParam.AchieveId3 or 0)
end


function HeroDisplayBoardDetailLogic:ON_HERO_DISPLAYBOARD_FLOOR_SELECT_Func()
    local Param = {
        DisplayId = self.HeroId,
    }
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_SHOW, Param)
end

function HeroDisplayBoardDetailLogic:ON_HERO_DISPLAYBOARD_ROLE_SELECT_Func()
    local Param = {
        DisplayId = self.HeroId,
    }
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_ROLE_SHOW, Param)
end

function HeroDisplayBoardDetailLogic:ON_HERO_DISPLAYBOARD_EFFECT_SELECT_Func()
    local Param = {
        DisplayId = self.HeroId,
    }
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_SHOW, Param)
end

function HeroDisplayBoardDetailLogic:ON_HERO_DISPLAYBOARD_STICKER_SELECT_Func()
    local Param = {
        DisplayId = self.HeroId,
    }
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_STICKER_SHOW, Param)
end

function HeroDisplayBoardDetailLogic:ON_HERO_DISPLAYBOARD_ACHIEVE_SELECT_Func()
    local Param = {
        DisplayId = self.HeroId,
    }
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_SHOW, Param)
end

function HeroDisplayBoardDetailLogic:Refresh3DDisplayBoard()
    local Param = {
        DisplayId = self.HeroId,
    }
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_SHOW, Param)
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_ROLE_SHOW, Param)
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_SHOW, Param)
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_STICKER_SHOW, Param)
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_SHOW, Param)
end

-- function HeroDisplayBoardDetailLogic:OnSpaceBarClick()
--     local VoItem = self.TabTypeId2Vo[self.CurTabId]
--     if not VoItem then
--         return
--     end
--     if VoItem.ViewItem ~= nil then
--         VoItem.ViewItem:OnSpaceBarClick()
--     end
-- end

return HeroDisplayBoardDetailLogic
