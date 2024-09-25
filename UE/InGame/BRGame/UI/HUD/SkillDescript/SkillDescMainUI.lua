-- 技能详情面板
--
-- @COMPANY	ByteDance
-- @AUTHOR	王泽平
-- @DATE	2023.10.17

local SkillDescMainUI = Class("Common.Framework.UserWidget")

-- region Define

--页面模式
local EPageMode={
    Map = 0,    --小地图页面
    SkillDesc = 1,  --技能详情页面
    AttributeDesc = 2 , --芯片详情页面
}

-- endregion

-------------------------------------------- Init/Destroy ------------------------------------

function SkillDescMainUI:OnInit()
    print("SkillDescMainUI >> OnInit")

    self.PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    -- region Event


    -- self.bIsFocusable = true
    -- self:SetFocus(true)


    -- endregion

    
    self:InitData()

    if not self.WidgetSyle then
		self.WidgetSyle = 
		{
			["Normal"] = 1, -- 默认
			["ParachuteRespawn"] = 2, -- 跳伞复活
		}
	end


	UserWidget.OnInit(self)
end


function SkillDescMainUI:OnShow(InContext, InGenericBlackboard)
    print("MainMenuUI:OnShow")
    -- self.bIsFocusable = true

    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.UI_SkillDesc_LeftOffset, Func = self.OnSkillDescPageLeftKey, bCppMsg = true,  WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.UI_SkillDesc_RightOffset, Func = self.OnSkillDescPageRightKey, bCppMsg = true,  WatchedObject = nil },
	}

    MsgHelper:RegisterList(self, self.MsgList)

    self.CurrentPageMode = EPageMode.Map   
    self.ModeNum = table.nums(EPageMode)
    self:SetPageMode(EPageMode.Map)

        
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
	BlackBoardKeySelector.SelectedKeyName = "LargeMapPanelType"
	local LargeTypeName, LargeType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InGenericBlackboard, BlackBoardKeySelector)
    
    print("LargemapPaneSkillDescMainUIl_PC:OnShow LargeTypeName:", LargeTypeName)

    if LargeType and "ParachuteRespawn" == LargeTypeName then
        self:AddActiveWidgetStyleFlagsByName(self.WidgetSyle[LargeTypeName])
    else
        self:AddActiveWidgetStyleFlagsByName(self.WidgetSyle["Normal"])
    end

    --self:Setfocus(true)
end

function SkillDescMainUI:OnClose()
    if self.MsgList then
        MsgHelper:UnregisterList(self, self.MsgList)
        self.MsgList = nil
    end
end


function SkillDescMainUI:InitData()
    print("SkillDescMainUI >> InitData")

    self.UIManager = UE.UGUIManager.GetUIManager(self)

        -- region Properties
        self.CurrentPageMode = EPageMode.Map     --当前页面模式,游戏运行第一次打开默认小地图
        self.ModeNum = table.nums(EPageMode)

        self.ButtonGroupLst ={
            {PageMode = EPageMode.Map ,BtnWidget= self.BP_BtnMap},
            {PageMode = EPageMode.SkillDesc ,BtnWidget= self.BP_BtnSkillDesc},
            {PageMode = EPageMode.AttributeDesc ,BtnWidget= self.BP_BtnMicrochipDesc},
        }
        
        -- endregion

        self.WidgetTable = {
            [EPageMode.Map] = "UMG_LargeMapPanel",
            [EPageMode.SkillDesc] = "UMG_SkillDescription",
            [EPageMode.AttributeDesc] = "UMG_EnhancedChipDescription",
        }

        self:OffsetPage(0)
end

function SkillDescMainUI:OnDestroy()
    print("SkillDescMainUI >> OnDestroy")
	UserWidget.OnDestroy(self)
end





-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------


function SkillDescMainUI:OnMapBtnClick()
    self.SetPageMode(EPageMode.Map)
end

function SkillDescMainUI:OnSkillDescBtnClick()
    self.SetPageMode(EPageMode.SkillDesc)
end

function SkillDescMainUI:OnMicrochipBtnClick()
    self.SetPageMode(EPageMode.AttributeDesc)
end

function SkillDescMainUI:SetPageMode(InPageMode)
    self.CurrentPageMode = InPageMode
    local LoadUserWidgetKey =  self.WidgetTable[self.CurrentPageMode]
    local LoadWidgetWidgetHandle = self.UIManager:TryLoadDynamicWidget(LoadUserWidgetKey)

    for _, value in pairs(self.ButtonGroupLst) do
        if value.PageMode == self.CurrentPageMode then
            value.BtnWidget.WidgetSwitcher:SetActiveWidgetIndex(1)
        else
            value.BtnWidget.WidgetSwitcher:SetActiveWidgetIndex(0)
        end
    end

end

function SkillDescMainUI:LeftPage()
    self:OffsetPage(-1)
end

function SkillDescMainUI:RightPage()
    self:OffsetPage(1)
end

function SkillDescMainUI:OffsetPage(OffsetNum)
    print("SkillDescMainUI >> OffsetPage > OffsetNum=",OffsetNum,"self.CurrentPageMode=",self.CurrentPageMode)

    local TheCurrentPageMode = (self.CurrentPageMode + OffsetNum ) % self.ModeNum

    self:SetPageMode(TheCurrentPageMode)

    -- self.bIsFocusable = true

    self.SkillKeyTips:SetVisibility(self.CurrentPageMode == EPageMode.SkillDesc and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.AttributeKeyTips:SetVisibility(self.CurrentPageMode == EPageMode.AttributeDesc and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end






function SkillDescMainUI:OnSkillDescPageLeftKey()
    print("SkillDescMainUI >> OnSkillDescPageLeftKey")
    --self:SetPageMode(EPageMode.SkillDesc)
    self:LeftPage()
end


function SkillDescMainUI:OnSkillDescPageRightKey()
    print("SkillDescMainUI >> OnSkillDescPageRightKey")
    --self:SetPageMode(EPageMode.AttributeDesc)
    self:RightPage()
end

-- function SkillDescMainUI:OnKeyUp(MyGeometry,InKeyEvent)

--     print("SkillDescMainUI >> OnKeyUp")
--     local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
--     if PressKey == UE.FName("Q") then
--         return UE.UWidgetBlueprintLibrary.Handled()
--     elseif PressKey == UE.FName("E") then
--         return UE.UWidgetBlueprintLibrary.Handled()
--     end
--     return UE.UWidgetBlueprintLibrary.Unhandled()
-- end

-- function SkillDescMainUI:OnKeyDown(MyGeometry,InKeyEvent)

--     print("SkillDescMainUI >> OnKeyUp")
--     local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
--     if PressKey == UE.FName("Q") then
--         self:LeftPage()
--         return UE.UWidgetBlueprintLibrary.Handled()
--     elseif PressKey == UE.FName("E") then
--         self:RightPage()
--         return UE.UWidgetBlueprintLibrary.Handled()
--     end
--     return UE.UWidgetBlueprintLibrary.Unhandled()
-- end


function SkillDescMainUI:OnMouseButtonUp(InMyGeometry, InMouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SkillDescMainUI:OnMouseButtonDown(InMyGeometry, InMouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled()
end


function SkillDescMainUI:UpdateLargeMapPanelStyle()
    local IfRespawnParachute = false

    -- 显示跳伞复活倒计时UI，隐藏Tab切换页签
    if IfRespawnParachute then
		self:AddActiveWidgetStyleFlagsByName(self.WidgetSyle["ParachuteRespawn"])
	else
		self:AddActiveWidgetStyleFlagsByName(self.WidgetSyle["Normal"])
	end

end


function SkillDescMainUI:AddActiveWidgetStyleFlagsByName(SlyeName)
    self:RemoveAllActiveWidgetStyleFlags()
	self:AddActiveWidgetStyleFlags(SlyeName)
end

return SkillDescMainUI





