--[[
    角色展示板选择贴纸
]]


---@class StickerChooseLogic

local class_name = "StickerChooseLogic"
local StickerChooseLogic = BaseClass(nil, class_name)

local StickerChooseSlotItem = require("Client.Modules.Hero.HeroDetail.DisplayBoard.StickerChooseSlotItem")

function StickerChooseLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.Widget2Item = {}

    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,           Func = Bind(self, self.OnUpdateItem)},
	}

    self.MsgList = {
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_STICKER_SELECT,  Func = Bind(self, self.ON_HERO_DISPLAYBOARD_STICKER_SELECT_Func)},
        {Model = HeroModel, MsgName = HeroModel.ON_PLAYER_EQUIP_STICKER_RSP, Func = Bind(self,self.ON_PLAYER_EQUIP_STICKER_RSP_Func) },
        {Model = HeroModel, MsgName = HeroModel.ON_PLAYER_UNEQUIP_STICKER_RSP, Func = Bind(self,self.ON_PLAYER_EQUIP_STICKER_RSP_Func) },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_BUY, Func = Bind(self,self.ON_HERO_DISPLAYBOARD_BUY_Func) },
        -- {Model = DepotModel, MsgName = DepotModel.ON_DEPOT_DATA_INITED, Func = Bind(self, self.ON_DEPOT_DATA_INITED_Func) },
        {Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func =  Bind(self, self.ON_UPDATED_MAP_CUSTOM_Func) },
    }

    if CommonUtil.IsValid(self.View.GUIButtonBuy) then
        self.ButtonBuyIns = UIHandler.New(self, self.View.GUIButtonBuy, WCommonBtnTips,{
            OnItemClick = Bind(self, self.OnClicked_GUIButtonBuy),
            CommonTipsID = CommonConst.CT_SPACE,
            ActionMappingKey = ActionMappings.SpaceBar,
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_buy"),--购买
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            CheckButtonIsVisible = true,
        }).ViewInstance

        self.View.GUIButtonBuy:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    if CommonUtil.IsValid(self.View.GUIButtonFetch) then
        UIHandler.New(self, self.View.GUIButtonFetch, WCommonBtnTips,{
            OnItemClick = Bind(self, self.OnClicked_GUIButtonFetch),
            CommonTipsID = CommonConst.CT_SPACE,
            ActionMappingKey = ActionMappings.SpaceBar,
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Gotoget"),--前往获取
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            CheckButtonIsVisible = true,
        })

        self.View.GUIButtonFetch:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    if CommonUtil.IsValid(self.View.GUIButtonEquip) then
        UIHandler.New(self, self.View.GUIButtonEquip, WCommonBtnTips,{
            OnItemClick = Bind(self, self.OnClicked_GUIButtonEquip),
            CommonTipsID = CommonConst.CT_SPACE,
            ActionMappingKey = ActionMappings.SpaceBar,
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Equip_Btn"),--确认展示
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            CheckButtonIsVisible = true,
        })

        self.View.GUIButtonEquip:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    if CommonUtil.IsValid(self.View.GUIButtonNoAvailable) then
        UIHandler.New(self, self.View.GUIButtonNoAvailable, WCommonBtnTips,{
            OnItemClick = Bind(self, self.OnClicked_GUIButtonNoAvailable),
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Theactivityhasended"),--活动已结束
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            CheckButtonIsVisible = true,
        }).ViewInstance:SetBtnEnabled(false)

        self.View.GUIButtonNoAvailable:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end


    ----------------------------------------
    if CommonUtil.IsValid(self.View.GUIButtonUnEquip) then
        UIHandler.New(self, self.View.GUIButtonUnEquip, WCommonBtnTips,{
            OnItemClick = Bind(self, self.OnClicked_GUIButtonUnEquip),
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_unload"),--卸下
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            CheckButtonIsVisible = true,
        })

        self.View.GUIButtonUnEquip:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    if CommonUtil.IsValid(self.View.GUIButtonEdit) then
        -- UIHandler.New(self, self.View.GUIButtonEdit, WCommonBtnTips,{
        --     OnItemClick = Bind(self, self.OnClicked_GUIButtonEquip),
        --     CommonTipsID = CommonConst.CT_SPACE,
        --     ActionMappingKey = ActionMappings.SpaceBar,
        --     TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Equip"),--确认展示
        --     HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        --     CheckButtonIsVisible = true,
        -- })

        self.View.GUIButtonEdit:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    ----------------------------------------
end

function StickerChooseLogic:OnShow(Param)
    if not Param then
        return
    end
    self.HeroId = Param.HeroId
    self.TabId = Param.TabId
    self.RequestAvatarHiddenInGame = Param.OnRequestAvatarHiddenInGame
    self.OnChooseBoradItem = Param.OnChooseBoradItem
    
    ---@type HeroModel
    self.ModelHero = MvcEntry:GetModel(HeroModel)
    ---@type DepotModel
    self.ModelDepot = MvcEntry:GetModel(DepotModel)

    -- 默认不选中任何一个
    self:SetChooseBoradData(0, 0)

    ---@type boolean 是否正在编辑
    self.bEditing = false

    if CommonUtil.IsValid(self.View.WidgetSwitcher_Item) and CommonUtil.IsValid(self.View.Panel_Frame) then
        self.View.WidgetSwitcher_Item:SetActiveWidget(self.View.Panel_Frame)
    end

    --获取面板的初始数据
    self:GetDisplayBoardInitData()

    --右侧所有的贴纸
    self:UpdateStickerListShow()
    --更新左侧Slot
    self:UpdateSlotListShow()
    --更新3D面板的贴纸
    self:Update3DStickerListShow()

    --切换到3D角色面板
    self:SwitchToDisplayBoardTo3D(true)
    --关闭2D编辑页面
    self:SwitchStickerEditMdt(false)

    --更新按钮的状态
    self:UpdateButtonStateByChoose()

    --检测配置是否能被展示
    self:CheckIsShowFlag()
end

function StickerChooseLogic:OnManualShow(param)
    self:OnShow(param)
end

function StickerChooseLogic:OnManualHide(param)
    -- self:OnHide()
    -- CError("XXXXXXXXXXXXd StickerChooseLogic:OnManualHide")
    self:SwitchStickerEditMdt(false)
end

function StickerChooseLogic:OnHide()
    -- CError("XXXXXXXXXXXXd StickerChooseLogic:OnHide")
    self:SwitchStickerEditMdt(false)
end

function StickerChooseLogic:OnShowAvator(Data,IsNotVirtualTrigger) 
    -- CError("---------------------- OnShowAvator,IsNotVirtualTrigger ="..tostring(IsNotVirtualTrigger))
    if IsNotVirtualTrigger then
        if self.RequestAvatarHiddenInGame then
            local param = {bHide = false,bReShowDisplayBoard = false}
            self.RequestAvatarHiddenInGame(param)
        end
    end
end

function StickerChooseLogic:OnHideAvator(Data,IsNotVirtualTrigger) 
    -- CError("---------------------- OnHideAvator,IsNotVirtualTrigger ="..tostring(IsNotVirtualTrigger))
end

---检测配置是否能被展示
function StickerChooseLogic:CheckIsShowFlag()
    local CheckFunc = function(BoardId)
        BoardId = BoardId or 0
        if BoardId <= 0  then
            return
        end

        local bCanShow = false
        for StickerId, DataCfg in pairs(self.StickerId2Data) do
            if StickerId == BoardId then
                bCanShow = true
                break
            end
        end

        if not bCanShow then
            if UE.UGFUnluaHelper.IsEditor() then
                UIAlert.Show(string.format("检测配置 BoardId=[%s] 不能展示给玩家!!!", tostring(BoardId)))
            end
           
            CError(string.format("StickerChooseLogic:CheckIsShowFlag, 检测配置 BoardId=[%s] 不能展示给玩家!!!",tostring(BoardId)))
        end
    end

    for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        local StickerId = self.ModelHero:GetSelectedDisplayBoardStickerId(self.HeroId, Slot)
        CheckFunc(StickerId)
    end
end

function StickerChooseLogic:SetChooseBoradData(StickerId, SlotId)
    self.ChooseStickerId = StickerId 
    self.ChooseSlotId = SlotId
    if self.OnChooseBoradItem then
        local Param = {TabId = self.TabId, BoradId = self.ChooseStickerId}
        self.OnChooseBoradItem(Param)
    end
end


-------------------------------------------------------------------------------Data >>
---重置贴纸数据:编辑状态的数据
function StickerChooseLogic:ResetEditSlot2StickerMap()
    ---@type table<number,LbStickerNode>
    self.EditSlot2StickerMap = {}
    for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        local StickerInfo = self.ModelHero:GetSelectedDisplayBoardSticker(self.HeroId, Slot)
        if StickerInfo then
            self.EditSlot2StickerMap[Slot] = DeepCopy(StickerInfo)
        else
            self.EditSlot2StickerMap[Slot] = nil
        end
    end
end

---获取面板的初始数据
function StickerChooseLogic:GetDisplayBoardInitData()
    self.EquippedFloorId = self.ModelHero:GetSelectedDisplayBoardFloorId(self.HeroId)
    self.EquippedRoleId = self.ModelHero:GetSelectedDisplayBoardRoleId(self.HeroId)
    self.EquippedEffectId = self.ModelHero:GetSelectedDisplayBoardEffectId(self.HeroId)

    self.EquippedSlotToAchieveId = {}
    for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        local AchieveId = self.ModelHero:GetSelectedDisplayBoardAchieveId(self.HeroId, Slot)
        self.EquippedSlotToAchieveId[Slot] = AchieveId
    end

    self:ResetEditSlot2StickerMap()
end

-------------------------------------------------------------------------------Data <<

-------------------------------------------------------------------------------Board_2D >>

-- 更新角色面板2D
function StickerChooseLogic:UpdateHeroDisplayBoard2D()
    local SlotToStickerInfo = {}
    for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        ---@type LbStickerNode
        -- local StickerInfo = self.EditSlot2StickerMap[Slot]
        local StickerInfo = self.ModelHero:GetSelectedDisplayBoardSticker(self.HeroId, Slot)
        SlotToStickerInfo[Slot] = StickerInfo
    end

    ---@type DisplayBoardNode
    local DisplayData = {
        HeroId = self.HeroId,
        FloorId = self.EquippedFloorId,
        RoleId = self.EquippedRoleId,
        EffectId = self.EquippedEffectId,
        SlotToAchieveId = self.EquippedSlotToAchieveId,
        SlotToStickerInfo = SlotToStickerInfo,
    }

    local Param = {
        HeroId = self.HeroId,
        DisplayData = DisplayData
    }

    if self.DisplayBoard2DHandler == nil or not(self.DisplayBoard2DHandler:IsValid()) then
        self.DisplayBoard2DHandler = UIHandler.New(self, self.View.WBP_HeroDisplayBoard2D, require("Client.Modules.Hero.HeroDetail.DisplayBoard.HeroDisplayBoard2D"), Param)
    else
        -- self.DisplayBoard2DHandler:ManualOpen(Param)
        self.DisplayBoard2DHandler.ViewInstance:UpdateUI(Param)
    end
end
-------------------------------------------------------------------------------Board_2D <<
-------------------------------------------------------------------------------Board_2D_Edit >>

---打开2D编辑页面吗？
function StickerChooseLogic:SwitchStickerEditMdt(bOpen)
    if bOpen then
        local Param = {
            HeroId = self.HeroId,
            Slot = self.ChooseSlotId,
            StickerId = self.ChooseStickerId,
            OnRequestStartEdit = Bind(self, self.RequestStartEdit),
            RequestLimitBoxParam = Bind(self, self.GetLimitBoxParam),
            OnEditorStickerNtf = Bind(self, self.OnEditorStickerNtf),
            OnCloseStickerEdit = Bind(self, self.OnCloseStickerEditNtf),
            UIWidget = {
                LimitBox = self.View.LimitBox,
            }
        }
        
        MvcEntry:OpenView(ViewConst.HeroDisplayBoardStickerEdit, Param)
    
        if self.DisplayBoard2DHandler and (self.DisplayBoard2DHandler:IsValid()) then
            self.DisplayBoard2DHandler.ViewInstance:OpenStickerEdit()
        end
    else
        MvcEntry:CloseView(ViewConst.HeroDisplayBoardStickerEdit)

        if self.DisplayBoard2DHandler and (self.DisplayBoard2DHandler:IsValid()) then
            self.DisplayBoard2DHandler.ViewInstance:CloseStickerEdit()
        end
    end
end

---开始贴纸编辑并返回初始化参数
function StickerChooseLogic:RequestStartEdit()
    if self.DisplayBoard2DHandler and (self.DisplayBoard2DHandler:IsValid()) then
        local Param = {
            StickerId = self.ChooseStickerId,
            OnEditResultSyn = Bind(self, self.OnEditResultSyn)
        }

        local InitParam = self.DisplayBoard2DHandler.ViewInstance:StartStickerEdit(Param)
        return InitParam
    end
    return nil
end

function StickerChooseLogic:OnEditResultSyn(Param)
    -- local Param = {
    --     StickerId = self.EditorStickerId,
    --     Slot = self.EditSlot,
    --     Angle = Angle, 
    --     Scale = self.EditScale, 
    --     LocalPos = LocalPos
    -- }

    -- CError(string.format("同步贴纸编辑数据 Param = %s",table.tostring()))

    self.EditResultSynParam = Param
end

---获取编辑限制区域参数
function StickerChooseLogic:GetLimitBoxParam()
    -- self.view.LimitBox
    local Panel_FrameSize = UE.USlateBlueprintLibrary.GetLocalSize(self.View.Panel_Frame:GetCachedGeometry())
    local TopLeft = UE.USlateBlueprintLibrary.GetLocalTopLeft(self.View.LimitBox:GetCachedGeometry())
    local LimitBoxSize = UE.USlateBlueprintLibrary.GetLocalSize(self.View.LimitBox:GetCachedGeometry())
    local BottomRight = UE.FVector2D(0,0)
    BottomRight.X = Panel_FrameSize.X - (TopLeft.X + LimitBoxSize.X)
    BottomRight.Y = Panel_FrameSize.Y - (TopLeft.Y + LimitBoxSize.Y)
    return {TopLeft = TopLeft,BottomRight = BottomRight}
end

function StickerChooseLogic:OnEditorStickerNtf(Param)
    -- CError("编辑时的回调-通知！！")

    -- local Param = {
    --     RotateAngle = InputChgData.RotateAngle,
    --     ScaleLength = InputChgData.ScaleLength,
    --     AbsolutePos = InputChgData.AbsolutePos,
    -- }

    if self.DisplayBoard2DHandler or (self.DisplayBoard2DHandler:IsValid()) then
        local ViewInstance = self.DisplayBoard2DHandler.ViewInstance
        ViewInstance:UpdateStickerEdit(Param.RotateAngle, Param.ScaleLength, Param.AbsolutePos, Param.ScaleDir)
    end
end

---关闭贴纸编辑界面
function StickerChooseLogic:CloseStickerEdit()
    self.bEditing = false

    self:SetChooseBoradData(0, 0)
    self.EditResultSynParam = nil

    --关闭2D编辑页面
    self:SwitchStickerEditMdt(false)
    --切换到3D角色面板
    self:SwitchToDisplayBoardTo3D(true)

    --更新左侧Slot
    self:UpdateSlotListShow()
    --更新3D面板的贴纸
    self:Update3DStickerListShow()
    --更新按钮的状态
    self:UpdateButtonStateByChoose()

    --跟新右边List
    self.View.WBP_ReuseList:Refresh()
end

---通知贴纸编辑被关闭:从编辑器界面通知过来
function StickerChooseLogic:OnCloseStickerEditNtf()
    self:OnClicked_GUIButtonUnEquip()
  
    self:CloseStickerEdit()
end

-------------------------------------------------------------------------------Board_2D_Edit <<

-------------------------------------------------------------------------------Board_3D >>

---切换到3D角色面板？
function StickerChooseLogic:SwitchToDisplayBoardTo3D(bShow3D)
    if self.RequestAvatarHiddenInGame then
        local param = {bHide = not(bShow3D),bReShowDisplayBoard = false}
        self.RequestAvatarHiddenInGame(param)
        -- if bShow3D then
        --     -- self.Handler.WidgetBaseOrHandler.ViewInstance:ShowDisplayBoardAvatar()
        --     self.ParentHandler.ViewInstance:ShowDisplayBoardAvatar()
        -- end
    end

    local bShowEditorUi = not(bShow3D)
    if bShowEditorUi then
        if CommonUtil.IsValid(self.View.Panel_Frame) then
            self.View.Panel_Frame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    else
        if CommonUtil.IsValid(self.View.Panel_Frame) then
            self.View.Panel_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

---更新3D面板的贴纸
function StickerChooseLogic:Update3DStickerListShow()
    local Update3DStickerShow = function(Slot)
        ---@type LbStickerNode
        local StickerInfo = self.ModelHero:GetSelectedDisplayBoardSticker(self.HeroId, Slot)
        local Param = {
            DisplayId = self.HeroId,
            Slot = Slot,
            StickerId = StickerInfo and StickerInfo.StickerId or 0,
            StickerInfo = StickerInfo
        }
        self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_STICKER_CHANGE, Param)
    end

    for Slot=1, HeroDefine.STICKER_SLOT_NUM do
        Update3DStickerShow(Slot)
    end
end
-------------------------------------------------------------------------------Board_3D <<

-------------------------------------------------------------------------------Slot >>

--- 获取有效的的Slot
--- @return number 返回4代表没有空的Slot
function StickerChooseLogic:GetValidChooseSlotId(InStickerId)
    local StickerId = 0
    local ValidSlotId = 0
    for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        StickerId = self.ModelHero:GetSelectedDisplayBoardStickerId(self.HeroId, Slot)
        if StickerId <= 0 and ValidSlotId <= 0  then
            ValidSlotId = Slot
        end
        if StickerId == InStickerId then
            ValidSlotId = Slot
            break
        end
    end
    if ValidSlotId <= 0  then
        ValidSlotId = HeroDefine.STICKER_SLOT_NUM + 1
    end
    return ValidSlotId
end

function StickerChooseLogic:GetSlotWidget(Slot)
    if Slot == 1 then
        return self.View.WBP_Widget1
    elseif Slot == 2 then
        return self.View.WBP_Widget2
    elseif Slot == 3 then
        return self.View.WBP_Widget3
    end
end

---更新左侧Slot
---@param bEditing boolean
function StickerChooseLogic:UpdateSlotListShow(bEditing)
    bEditing = bEditing or false

    self.Slot2WidgetIns = self.Slot2WidgetIns or {}
    for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        ---@type LbStickerNode
        local StickerInfo = self.ModelHero:GetSelectedDisplayBoardSticker(self.HeroId, Slot)

        local bPreview = false
        if bEditing and Slot == self.ChooseSlotId and StickerInfo == nil then
            bPreview = true
        end
        local StickerId = StickerInfo and StickerInfo.StickerId or 0
        if bEditing then
            StickerId = self.ChooseStickerId
        end
        local Param = {
            ChooseId = self.ChooseStickerId,
            InstigateType = StickerChooseSlotItem.InstigateType.Default,
            bPreview = bPreview,
            bEditing = bEditing,
            Slot = Slot,
            HeroId = self.HeroId,
            StickerId = StickerId,
            OnClickCallBack = Bind(self,self.OnClickedSlotArea),
        }
        if self.Slot2WidgetIns[Slot] == nil then
            local SlotWidget = self:GetSlotWidget(Slot)
            self.Slot2WidgetIns[Slot] = UIHandler.New(self, SlotWidget, StickerChooseSlotItem, Param).ViewInstance
        else
            self.Slot2WidgetIns[Slot]:UpdateUI(Param)
        end
    end
end

---点击贴纸Slot --> 进入贴纸编辑界面
function StickerChooseLogic:OnClickedSlotArea(Param)
    -- CError(string.format("---点击Slot ,Param = %s,ChooseStickerId = %s", table.tostring(Param), self.ChooseStickerId))

    -- local Param = {
    --     Slot = self.Slot,
    --     StickerId = self.StickerId,
    -- }
    -- local SlotId = self:GetValidChooseSlotId(Param.Slot)
    local SlotId = Param.Slot
    local ChooseStickerId = Param.StickerId
    self:SetChooseBoradData(ChooseStickerId, SlotId)

    --切换选中
    self:SetSelectedMark(self.ChooseStickerId)

    -- self:UpdateEditSlot2StickerMap(1)

    --屏蔽3D面板,显示2D面板
    self:SwitchToDisplayBoardTo3D(false)
    --更新角色面板2D
    self:UpdateHeroDisplayBoard2D()

    --更新左侧Slot
    self:UpdateSlotListShow()
    --更新3D面板的贴纸
    self:Update3DStickerListShow()
    --更新按钮的状态
    self:UpdateButtonStateByChoose()

    --打开2D编辑页面
    self:SwitchStickerEditMdt(true)
end

-------------------------------------------------------------------------------Slot <<


-------------------------------------------------------------------------------List >>
--- 右侧所有的贴纸
function StickerChooseLogic:UpdateStickerListShow()
    self.ItemIns2Id = {}
    self.DataList = {}
    self.StickerId2Data = {}
    self.CurSelectItem = nil

    self:GetValidDisplayBoardData(self.HeroId)
    self:SortDisplayBoardData(self.DataList)
    self.DataListSize = #self.DataList
    self.View.WBP_ReuseList:Reload(#self.DataList)
end

function StickerChooseLogic:GetStickerIdData(StickerId)
    return self.StickerId2Data[StickerId]
end

---获取有效的贴纸数据
function StickerChooseLogic:GetValidDisplayBoardData(HeroId)
    local Dict = G_ConfigHelper:GetDict(Cfg_HeroDisplaySticker)
    for k, Cfg in pairs(Dict) do
        if(Cfg[Cfg_HeroDisplaySticker_P.HeroId] == 0 or Cfg[Cfg_HeroDisplaySticker_P.HeroId] == HeroId) and Cfg[Cfg_HeroDisplaySticker_P.ShowFlag] then
            table.insert(self.DataList, Cfg)

            local StickerId = Cfg[Cfg_HeroDisplaySticker_P.Id]
            self.StickerId2Data[StickerId] = Cfg
        end
    end
end

---排序
function StickerChooseLogic:SortDisplayBoardData(ListData)
    if ListData == nil or next(ListData) == nil then
        return
    end

    local SortFunc = function (ItemA,ItemB)
        local IdA = ItemA[Cfg_HeroDisplaySticker_P.Id]
        local IdB = ItemB[Cfg_HeroDisplaySticker_P.Id]
        --是否装备排序
        local IsEquipedA = self.ModelHero:HasDisplayBoardStickerIdSelected(self.HeroId, IdA) and 1 or 0
        local IsEquipedB = self.ModelHero:HasDisplayBoardStickerIdSelected(self.HeroId, IdB) and 1 or 0
        if IsEquipedA ~= IsEquipedB then
            return IsEquipedA > IsEquipedB
        end

        local ItemIdA = ItemA[Cfg_HeroDisplaySticker_P.ItemId]
        local ItemIdB = ItemB[Cfg_HeroDisplaySticker_P.ItemId]
        
        --是否拥有排序
        local HasSortA = self.ModelDepot:GetItemCountByItemId(ItemIdA) > 0 and 1 or 0
        local HasSortB = self.ModelDepot:GetItemCountByItemId(ItemIdB) > 0 and 1 or 0
        if HasSortA ~= HasSortB then
            return HasSortA > HasSortB
        end

        --排序权重:越大越靠前
        if ItemA[Cfg_HeroDisplaySticker_P.SortWeight] ~= ItemB[Cfg_HeroDisplaySticker_P.SortWeight] then
            return ItemA[Cfg_HeroDisplaySticker_P.SortWeight] > ItemB[Cfg_HeroDisplaySticker_P.SortWeight]
        end

        local ItemIdACfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemIdA)
        local ItemIdBCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemIdB)
        if ItemIdACfg and ItemIdBCfg then
            --品质权重:越大越靠前
            if ItemIdACfg[Cfg_ItemConfig_P.Quality] ~= ItemIdBCfg[Cfg_ItemConfig_P.Quality] then
                return ItemIdACfg[Cfg_ItemConfig_P.Quality] > ItemIdBCfg[Cfg_ItemConfig_P.Quality]
            end
        end
       
        return IdA > IdB
    end

    table.sort(ListData, SortFunc)
end

function StickerChooseLogic:CreateItem(Widget, IconParam)
	local Item = self.Widget2Item[Widget]
	if not Item then
		-- Item = UIHandler.New(self, Widget, require("Client.Modules.Hero.HeroDetail.DisplayBoard.StickerChooseListItem"))
        Item = UIHandler.New(self, Widget, CommonItemIcon, IconParam)
		self.Widget2Item[Widget] = Item
	end
	return Item.ViewInstance
end

function StickerChooseLogic:OnUpdateItem(Handler, Widget, Index)
	local FixIndex = Index + 1
	local ConfigData = self.DataList[FixIndex]
	if ConfigData == nil then
		return
	end

	local ItemIns = self:CreateItem(Widget)
	if ItemIns == nil then
		return
	end

    local StickerId = ConfigData[Cfg_HeroDisplaySticker_P.Id]
    local ItemId = ConfigData[Cfg_HeroDisplaySticker_P.ItemId]
    local RetVal = MvcEntry:GetCtrl(HeroCtrl):GetCornerTagParam(self.TabId, self.HeroId, StickerId)
    ---@type CornerTagParam
    local CornerTagInfo = RetVal.TagParam
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemId,
        ClickCallBackFunc = Bind(self, self.OnClickStickerItem, StickerId, ConfigData),
        -- ClickMethod = UE.EButtonClickMethod.DownAndUp,
        -- HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        ShowItemName = false,

        RightCornerTagId = CornerTagInfo.TagId,
        RightCornerTagHeroId = CornerTagInfo.TagHeroId,
        RightCornerTagHeroSkinId = CornerTagInfo.TagHeroSkinId,
        IsLock = CornerTagInfo.IsLock,
        IsGot = CornerTagInfo.IsGot,
        IsOutOfDate = CornerTagInfo.IsOutOfDate,
        RedDotKey = "HeroDisplayBoardStickerItem_",
        RedDotSuffix = StickerId,
        RedDotInteractType = CommonConst.RED_DOT_INTERACT_TYPE.CLICK,
    }

    ItemIns:UpdateUI(IconParam)

    self.ItemIns2Id[ItemIns] = StickerId
    
    if StickerId == self.ChooseStickerId then
        ItemIns:SetIsSelect(true)
    else
        ItemIns:SetIsSelect(false)
    end
end

function StickerChooseLogic:SetSelectedMark(InStickerId)
    for ItemIns, StickerId in pairs(self.ItemIns2Id) do
        if InStickerId == StickerId then
            ItemIns:SetIsSelect(true)
        else
            ItemIns:SetIsSelect(false)
        end
    end
end

-- local Params = {
--     Icon = self.View,
--     ItemId = self.IconParams.ItemId,
-- }
--- 点击了贴纸Item --> 进入贴纸编辑界面
function StickerChooseLogic:OnClickStickerItem(StickerId, ConfigData, Params)
    -- local StickerId = ConfigData[Cfg_HeroDisplaySticker_P.Id]
    -- CError(string.format("点击贴纸::StickerId = %s,ConfigData = %s, Params - %s",StickerId,table.tostring(ConfigData),table.tostring(Params)))

    local SlotId = self:GetValidChooseSlotId(StickerId)
    self:SetChooseBoradData(ConfigData[Cfg_HeroDisplaySticker_P.Id], SlotId)

    --切换选中
    self:SetSelectedMark(self.ChooseStickerId)

    -- self:UpdateEditSlot2StickerMap(1)

    --屏蔽3D面板,显示2D面板
    self:SwitchToDisplayBoardTo3D(false)
    --更新角色面板2D
    self:UpdateHeroDisplayBoard2D()

    --更新左侧Slot
    self:UpdateSlotListShow()
    --更新3D面板的贴纸
    self:Update3DStickerListShow()
    --更新按钮的状态
    self:UpdateButtonStateByChoose()

    --打开2D编辑页面
    self:SwitchStickerEditMdt(true)
end

-------------------------------------------------------------------------------List <<


-------------------------------------------------------------------------------Btn >>

-- function StickerChooseLogic:ActiveButtonStateByChoose(ActiveBtn)
--     if self.BtnWidgets == nil then
--         self.BtnWidgets = {self.View.GUIButtonAlreadyEqupped,self.View.GUIButtonNoAvailable,self.View.GUIButtonEquip,self.View.GUIButtonBuy,self.View.GUIButtonFetch}    
--     end
--     -- for k, BtnWidget in pairs(self.BtnWidgets) do
--     --     if BtnWidget == ActiveBtn then
--     --         BtnWidget:Setvisibility(UE.ESlateVisibility.Visible)
--     --     else
--     --         BtnWidget:Setvisibility(UE.ESlateVisibility.Collapsed)
--     --     end
--     -- end

--     for k, BtnWidget in pairs(self.BtnWidgets) do
--         if CommonUtil.GetWidgetIsVisibleReal(BtnWidget) then
--             CError(string.format("XXXXXXXXXXXXXX  K = %s ,true", k))
--         else
--             CError(string.format("XXXXXXXXXXXXXX  K = %s ,false", k))
--         end
--     end
-- end

---更新按钮的状态：
-- 1、选择不同的Slot
-- 2、选择不同的StickerId
-- 3、购买
function StickerChooseLogic:UpdateButtonStateByChoose()
    self.View.WidgetSwitcher:SetVisibility(self.ChooseStickerId == 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

    local bEqu = self.ModelHero:HasDisplayBoardStickerIdSelected(self.HeroId, self.ChooseStickerId)
    if bEqu then
        -- --已经装备,显示卸载与展示按钮
        -- self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonAlreadyEqupped)
        -- 展示/装备
        self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonEquip)
    else
        local StickerCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplaySticker, Cfg_HeroDisplaySticker_P.Id, self.ChooseStickerId)
        if StickerCfg ~= nil then
            local ItemId = StickerCfg[Cfg_HeroDisplaySticker_P.ItemId]--物品ID
            -- local IsLock = self.ModelDepot:GetItemCountByItemId(ItemId) <= 0
            local IsLock = not(self.ModelHero:HasDisplayBoardSticker(self.ChooseStickerId)) 
            if IsLock then
                local AvailableFlag = StickerCfg[Cfg_HeroDisplaySticker_P.AvailableFlag]--是否可获取
                local UnlockFlag = StickerCfg[Cfg_HeroDisplaySticker_P.UnlockFlag]--是否可解锁

                if AvailableFlag then
                    local JumpIDs = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(ItemId)--跳转IDs
                    if UnlockFlag then
                        if self.ButtonBuyIns then
                            local UnlockItemId = StickerCfg[Cfg_HeroDisplaySticker_P.UnlockItemId]--解锁用物品
                            local UnlockItemNum = StickerCfg[Cfg_HeroDisplaySticker_P.UnlockItemNum]--解锁用数量
                            self.ButtonBuyIns:ShowCurrency(UnlockItemId, UnlockItemNum, JumpIDs)
                        end
                        -- 购买
                        self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonBuy)
                    else
                        if JumpIDs and JumpIDs:Length() > 0 then
                            -- 有跳转配置则显示 跳转
                            self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonFetch)
                        else
                            -- 活动结束
                            self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonNoAvailable) 
                        end
                    end
                else
                    -- 活动结束
                    self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonNoAvailable)   
                end
            else
                -- 展示/装备
                self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonEquip)
            end
        end
    end
end

---Make贴纸装备的服务器数据
function StickerChooseLogic:MakeStickerParamToServer()
    if self.EditResultSynParam == nil then
        CError("StickerChooseLogic:MakeStickerParamToServer Failed!!!!,self.EditResultSynParam == nil")
        return nil
    end
    local Float2IntScale = HeroModel.DISPLAYBOARD_FLOAT2INTSCALE
    local StickerParam = {}
    StickerParam.StickerId = self.ChooseStickerId
    StickerParam.XPos = math.floor(self.EditResultSynParam.LocalPos.X * Float2IntScale) 
    StickerParam.YPos = math.floor(self.EditResultSynParam.LocalPos.Y * Float2IntScale)
    StickerParam.ScaleX = math.floor(self.EditResultSynParam.Scale.X * Float2IntScale)
    StickerParam.ScaleY = math.floor(self.EditResultSynParam.Scale.Y * Float2IntScale)
    StickerParam.Angle = math.floor(self.EditResultSynParam.Angle * Float2IntScale)
    return StickerParam
end

---装备按钮
function StickerChooseLogic:OnClicked_GUIButtonEquip()

    self.IsLock = not (self.ModelHero:CheckGotHeroById(self.HeroId))
    if self.IsLock then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Hero","Lua_HeroDisplayBoard_PleaseUnlockHero")) --请先解锁先觉者
        return
    end

    if self.EditResultSynParam == nil then
        return
    end

    if self.ChooseSlotId < HeroDefine.STICKER_SLOT_NUM + 1 then
        local StickerParam = self:MakeStickerParamToServer()
        self:SendProto_PlayerStickerReq(true, self.ChooseSlotId, StickerParam)
        
        -- --关闭编辑界面:这里不关闭编辑界面,等请求消息返回后再关闭编辑界面
        -- self:CloseStickerEdit()
    else
        local Param = {
            HeroId = self.HeroId,
            Slot = self.ChooseSlotId,
            StickerId = self.ChooseStickerId,
            EditResultSynParam = DeepCopy(self.EditResultSynParam),
            OnSelectSlotOption = Bind(self, self.OnSelectSlotOptionNtf),
        }
        -- 已经装满了,打开选择Slot界面
        MvcEntry:OpenView(ViewConst.HeroDisplayBoardStickerChooseSlot, Param)
    end
end

-- 已经装满了,打开选择Slot界面,返回
function StickerChooseLogic:OnSelectSlotOptionNtf(Param)
    local bEquip = Param.bEquip
    if bEquip then
        --玩家选择的展示按钮
        local Slot = Param.Slot
        local StickerParam = self:MakeStickerParamToServer()
        self:SendProto_PlayerStickerReq(true, Slot, StickerParam)

        -- MvcEntry:CloseView(ViewConst.HeroDisplayBoardStickerChooseSlot)
        -- self:CloseStickerEdit()
    else
        -- MvcEntry:CloseView(ViewConst.HeroDisplayBoardStickerChooseSlot)
    end
end

---卸载按钮
function StickerChooseLogic:OnClicked_GUIButtonUnEquip()
    -- 先检查是否有装备
    -- local StickerInfo = self.ModelHero:GetSelectedDisplayBoardSticker(self.HeroId, self.ChooseSlotId)
    local bEquiped = self.ModelHero:HasDisplayBoardStickerIdSelected(self.HeroId, self.ChooseStickerId)
    if bEquiped then
        self:SendProto_PlayerStickerReq(false, self.ChooseSlotId, self.ChooseSlotId)
    end
end

---去编辑按钮
function StickerChooseLogic:OnClicked_GUIButtonEdit()
    -- ---@type HeroModel
    
end

---活动已结束按钮
function StickerChooseLogic:OnClicked_GUIButtonNoAvailable()
    -- CError("---活动已结束按钮")
    -- local msgParam = {
    --     -- describe = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_isnotenoughtobuy"),
    --     describe = "活动已结束按钮"
    -- }
    -- UIMessageBox.Show(msgParam)
    UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Theactivityhasended"))--活动已结束
end

---前往获取按钮
function StickerChooseLogic:OnClicked_GUIButtonFetch()
    CWaring("StickerChooseLogic:OnClicked_GUIButtonFetch, 前往获取按钮")
    --前往跳转?
    local tblCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplaySticker, Cfg_HeroDisplaySticker_P.Id, self.ChooseStickerId)
    if tblCfg == nil then
        --TODO:跳转失败
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Theactivityhasended")) -- 活动已结束
        return
    end

    local JumpIDs = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(tblCfg[Cfg_HeroDisplaySticker_P.ItemId])
    if JumpIDs then
        MvcEntry:GetCtrl(ViewJumpCtrl):JumpToByTArrayList(JumpIDs)    
    end
    
    -- self.ButtonBuyIns:ShowCurrency(self.UnlockItemId, self.UnlockItemNum, JumpIDs)
end

---购买按钮
function StickerChooseLogic:OnClicked_GUIButtonBuy()
    -- CWaring("self.UnlockItemId:" .. self.UnlockItemId)

    local StickerCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplaySticker, Cfg_HeroDisplaySticker_P.Id, self.ChooseStickerId)
    if StickerCfg == nil then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Theactivityhasended")) -- 活动已结束
        return
    end

    local UnlockItemId = StickerCfg[Cfg_HeroDisplaySticker_P.UnlockItemId]
    local Cost = StickerCfg[Cfg_HeroDisplaySticker_P.UnlockItemNum]
    local Balance = self.ModelDepot:GetItemCountByItemId(UnlockItemId)
    local ItemName = self.ModelDepot:GetItemName(UnlockItemId)
	if Balance < Cost then
		local msgParam = {
			describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_isnotenoughtobuy"),ItemName),--{0}不够，无法购买
		}
		UIMessageBox.Show(msgParam)
		return
	end
	local msgParam = {
		-- describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Areyousureyouwanttob"), Cost,ItemName),--确定要花{0}{1}购买吗？
        describe = CommonUtil.GetBuyCostDescribeText(UnlockItemId, Cost), --确定要花 {0}{1} 购买吗？
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
				MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerBuyStickerReq(self.ChooseStickerId)
			end
		}
	}
	UIMessageBox.Show(msgParam)
end

-------------------------------------------------------------------------------Btn <<

function StickerChooseLogic:UpdateBoard3DSlot2StickerId(Slot)
    self.EditSlot2StickerId = {}

    for Slot=1, HeroDefine.STICKER_SLOT_NUM do
        local ViewStickerId = self.ChooseSlotId == Slot and self.ChooseStickerId or 0
        local StickerId = self.ModelHero:GetSelectedDisplayBoardStickerId(self.HeroId, Slot)
        if ViewStickerId ~= 0 and ViewStickerId ~= StickerId then
            self:SetBoard3DSlot2StickerId(Slot, ViewStickerId)
        else 
            if StickerId ~= 0 then
                self:SetBoard3DSlot2StickerId(Slot, StickerId)
            else
                self:SetBoard3DSlot2StickerId(Slot, 0)
            end
        end
    end

    if self.ChooseStickerId ~= 0 then
        for Slot=1, HeroDefine.STICKER_SLOT_NUM do
            if Slot ~= self.ChooseSlotId then
                local StickerId = self.ModelHero:GetSelectedDisplayBoardStickerId(self.HeroId, Slot)    
                self:SetBoard3DSlot2StickerId(Slot, self.ChooseStickerId ~= StickerId and StickerId or 0)
            end
        end
    end
end

function StickerChooseLogic:OnSlotButtonHaveClicked(Slot)
    if self.ChooseSlotId == Slot then
        return
    end
    local StickerId = self.ModelHero:GetSelectedDisplayBoardStickerId(self.HeroId, Slot)
    self:SetChooseBoradData(StickerId, Slot)

    self:UpdateSlotListShow()
    --更新3D面板的贴纸
    self:Update3DStickerListShow()
    --更新按钮的状态
    self:UpdateButtonStateByChoose()
    self.View.WBP_ReuseList:Refresh()
end


function StickerChooseLogic:OnSlotButtonNotHaveClicked(Slot)
    if self.ChooseSlotId == Slot then
        return
    end
    local StickerId = self.ModelHero:GetSelectedDisplayBoardStickerId(self.HeroId, Slot)
    self:SetChooseBoradData(StickerId, Slot)

    self:UpdateSlotListShow()
    --更新3D面板的贴纸
    self:Update3DStickerListShow()
    --更新按钮的状态
    self:UpdateButtonStateByChoose()
    self.View.WBP_ReuseList:Refresh()
end


-------------------------------------------------------------------------------Server>>

function StickerChooseLogic:ON_HERO_DISPLAYBOARD_STICKER_SELECT_Func(Param)
    -- if Param == nil or Param.HeroId ~= self.HeroId then
    --     return
    -- end

    -- if Param.bEquip then
    --     --关闭贴纸编辑界面
    --     self:CloseStickerEdit()
    -- end

    -- self.bEditing = false

    -- self:SetChooseBoradData(0, 0)

    -- --关闭2D编辑页面
    -- self:SwitchStickerEditMdt(false)
    -- --切换到3D角色面板
    -- self:SwitchToDisplayBoardTo3D(true)

    -- --更新左侧Slot
    -- self:UpdateSlotListShow()
    -- --更新3D面板的贴纸
    -- self:Update3DStickerListShow()
    -- --更新按钮的状态
    -- self:UpdateButtonStateByChoose()

    -- --跟新右边List
    -- self.View.WBP_ReuseList:Refresh()
end

function StickerChooseLogic:ON_PLAYER_EQUIP_STICKER_RSP_Func()
    --关闭贴纸编辑界面
    self:CloseStickerEdit()

    self.bEditing = false

    self:SetChooseBoradData(0, 0)

    -- --关闭2D编辑页面
    -- self:SwitchStickerEditMdt(false)
    -- --切换到3D角色面板
    -- self:SwitchToDisplayBoardTo3D(true)

    --更新左侧Slot
    self:UpdateSlotListShow()
    --更新3D面板的贴纸
    self:Update3DStickerListShow()
    --更新按钮的状态
    self:UpdateButtonStateByChoose()

    --跟新右边List
    self.View.WBP_ReuseList:Refresh()
end

function StickerChooseLogic:ON_HERO_DISPLAYBOARD_BUY_Func(_,StickerId)

    if self.ChooseStickerId == StickerId then
        self:OnClicked_GUIButtonEquip()
    else
        --更新按钮的状态
        self:UpdateButtonStateByChoose()
        self.View.WBP_ReuseList:Refresh()
    end
end

-- function StickerChooseLogic:ON_DEPOT_DATA_INITED_Func()
--     --更新按钮的状态
--     self:UpdateButtonStateByChoose()
--     self.View.WBP_ReuseList:Refresh()
-- end

function StickerChooseLogic:ON_UPDATED_MAP_CUSTOM_Func(_,ChangeMap)
    --更新按钮的状态
    self:UpdateButtonStateByChoose()
    self.View.WBP_ReuseList:Refresh()
end

---请求装备/卸载贴纸
---@param bEquip boolean
---@param InSlot number
---@param StickerParam table
function StickerChooseLogic:SendProto_PlayerStickerReq(bEquip, InSlot, StickerParam)
    if bEquip then
        if StickerParam == nil then
            CError("StickerChooseLogic:SendProto_PlayerStickerReq Failed!!!!,StickerParam == nil", true)
            return    
        end
        MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerEquipStickerReq(self.HeroId, InSlot, StickerParam)
    else
        MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerUnEquipStickerReq(self.HeroId, InSlot)
    end
end

-------------------------------------------------------------------------------Server<<



return StickerChooseLogic