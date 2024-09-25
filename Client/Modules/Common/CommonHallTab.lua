--[[
    通用的大厅CommonTab控件
]]

require "UnLua"

local class_name = "WCommonHallTab"
WCommonHallTab = WCommonHallTab or BaseClass(UIHandlerViewBase, class_name)

WCommonHallTab.DYNAMIC_EFFECT_ACTION_TYPE = {
    DEFAULT = 0,
    PLAY = 1,
    HERO = 2,
    WEAPON = 3,
    SHOP = 4,
    SEASON = 5
}

function WCommonHallTab:OnInit()
    local ConstPlayerState = require("Client.Modules.User.ConstPlayerState")
    local PLAYER_CLIENT_HALL_STATE = ConstPlayerState.Enum_PLAYER_CLIENT_HALL_STATE
    self.InputFocus = true
    self.TabList = {
        {Key=CommonConst.HL_PLAY, Class = require("Client.Modules.Hall.HallTabPlay"), WBPPath = "/Game/BluePrints/UMG/OutsideGame/Hall/WBP_HallTabPlay.WBP_HallTabPlay",  Node = self.View.BP_TabItem_Play, Name=G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHallTab_startthegame_Btn"), VirtualSceneId = 102, ClientHallState = PLAYER_CLIENT_HALL_STATE.Hall, IsShowSideBar = true, bHideTabOnShow = false },
        {Key=CommonConst.HL_HERO, Class = require("Client.Modules.Hero.HallTabHero"), WBPPath = "/Game/BluePrints/UMG/OutsideGame/Hero/WBP_HallTabHero.WBP_HallTabHero", Node = self.View.BP_TabItem_Hero, Name=G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHallTab_personwithforesight_Btn"), VirtualSceneId = 200, ClientHallState = PLAYER_CLIENT_HALL_STATE.HallHero , IsShowSideBar = true ,UnlockId = ViewConst.SystemUnlockHero, RedDotNode = self.View.WBP_RedDotFactory, RedDotKey = "TabHero", bHideTabOnShow = false},
        {Key=CommonConst.HL_ARSENAL,  Class = require("Client.Modules.Arsenal.HallTabArsenal"),WBPPath = "/Game/BluePrints/UMG/OutsideGame/Arsenal/WBP_HallTabArsenal.WBP_HallTabArsenal", Node = self.View.BP_TabItem_Weapon, Name=G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHallTab_warpreparedness_Btn"), VirtualSceneId = 300, ClientHallState = PLAYER_CLIENT_HALL_STATE.HallWeapon , IsShowSideBar = true ,UnlockId = ViewConst.SystemUnlockWeapon, RedDotNode = self.View.WBP_RedDotFactoryWeapon, RedDotKey = "TabArsenal", bHideTabOnShow = false},
        {Key=CommonConst.HL_SHOP,  Class = require("Client.Modules.Shop.HallTabShop"),WBPPath = "/Game/BluePrints/UMG/OutsideGame/Shop/Main/WBP_Shop_Main.WBP_Shop_Main", Node = self.View.BP_TabItem_Shop, Name=G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHallTab_shop_Btn"), VirtualSceneId = 700, ClientHallState = PLAYER_CLIENT_HALL_STATE.HallShop , IsShowSideBar = true,UnlockId = ViewConst.SystemUnlockShop, bHideTabOnShow = false},
        {Key=CommonConst.HL_SEASON, Class = require("Client.Modules.Season.HallTabSeason"),WBPPath = "/Game/BluePrints/UMG/OutsideGame/Season/WBP_Season_Main.WBP_Season_Main", Node = self.View.BP_TabItem_Season, Name=G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHallTab_season_Btn"), ClientHallState = PLAYER_CLIENT_HALL_STATE.HallSeason , IsShowSideBar = true ,UnlockId = ViewConst.SystemUnlockSeason, RedDotNode = self.View.WBP_RedDotFactorySeason, RedDotKey = "TabSeason", bHideTabOnShow = false},
    }

    self.MsgList = {
        {Model = CommonModel, MsgName = CommonModel.HALL_TAB_SWITCH,	Func = self.ON_HALL_TAB_SWITCH_Func },
        {Model = CommonModel, MsgName = CommonModel.HALL_TAB_SWITCH_AFTER_CLOSE_POPS,	Func = self.ON_HALL_TAB_SWITCH_AFTER_CLOSE_POPS_Func },
        {Model = HallModel, MsgName = HallModel.ON_HALL_SCENE_SWITCH_COMPLETED,	Func = self.ON_HALL_SCENE_SWITCH_COMPLETED_Func },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Q), Func = Bind(self,self.OnPrevTab)},
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.E), Func = Bind(self,self.OnNextTab) },
		{Model = MatchModel,  	MsgName = MatchModel.ON_MATCH_IDLE,         				    Func = self.ON_MATCH_IDLE_Func},
		{Model = MatchModel,  	MsgName = MatchModel.ON_DS_ERROR,         				    Func = self.ON_DS_ERROR_Func},
		{Model = MatchModel,  	MsgName = MatchModel.ON_MATCH_SUCCESS,         				Func = self.ON_GAMEMATCH_SUCCECS_Func},
		{Model = nil,  	MsgName = CommonEvent.ON_PRE_ENTER_BATTLE,         				Func = self.ON_PRE_ENTER_BATTLE_Func},
    }
    self.tabKey2Item = {}
    self.BindNodes = {}
    self.Index2Node = {}
    for i,v in ipairs(self.TabList) do
        self.tabKey2Item[v.Key] = v
        self.Index2Node[i] = v.Node

        local BindNodes = {
            {UDelegate = v.Node.GUIButton_TabBg.OnClicked,Func = Bind(self,self.OnTabItemClick,v.Key,false)},
            -- {UDelegate = v.Node.GUIButton_TabBg.OnHovered,Func = Bind(self,self.OnTabHovered,i)},
            -- {UDelegate = v.Node.GUIButton_TabBg.OnUnhovered,Func = Bind(self,self.OnTabUnhovered,i)}
        }
       
        self.BindNodes = ListMerge(self.BindNodes,BindNodes)

        --更新显示名称
        v.Node.LbName:SetText(StringUtil.Format(v.Name))

        --绑定红点
        if v.RedDotNode and v.RedDotKey then
            v.RedDotNode:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            ---@type CommonRedDot
            local RedDot = UIHandler.New(self, v.RedDotNode, CommonRedDot, {RedDotKey = v.RedDotKey, RedDotSuffix = ""}).ViewInstance
        end
    end

    self.TabViews = {}
    self.AnimationFinishCb = nil
    self.SwitchParam = nil
end

function WCommonHallTab:ON_PRE_ENTER_BATTLE_Func(Param)
    self:HideOldTab(self.curSelectTabKey)
end

-- --[[
--     收到Tab页切换通知 进行模拟点击
-- ]]
function WCommonHallTab:ON_HALL_TAB_SWITCH_Func(Param)
    local TabKey = Param.TabKey
    if not TabKey then
        return
    end
    self.IsForceSwitch = Param.IsForce or false
    self.SwitchParam = Param
    self:OnTabItemClick(TabKey,self.IsForceSwitch, Param.IsForceSelect)
end

-- 切换到指定页签，并且关闭上层所有Pops界面。
--[[ Param = {
        TabKey 指定切换的页签
        IsForce 是否强制切换（会忽略是否匹配成功的状态判断）
        IsForceSelect 是否强制选中（忽略当前选中的和已选中的是否同一页签的判断）
    }
]]
function WCommonHallTab:ON_HALL_TAB_SWITCH_AFTER_CLOSE_POPS_Func(Param)
    local TabKey = Param.TabKey
    if not TabKey then
        return
    end
    local SwitchSceneId = self.TabList[TabKey].VirtualSceneId

    self.SwitchParam = Param
    --[[
        这段逻辑主要是为了避免在关闭上层界面期间，打开关闭界面上一层界面所依赖的场景，以及避免在最终打开大厅界面的时候，先切换到上一个切页的场景，再切换到最终切页的场景
    ]]
    if SwitchSceneId and SwitchSceneId > 0 then
        -- SwitchSceneId 为最终展示的Tab页签的场景Id
        -- 记录入IsSwitchingToScene 等待ON_HALL_SCENE_SWITCH_COMPLETED_Func再触发Tab切换
        self.IsSwitchingToScene = {
            TabKey = TabKey,
            SwitchSceneId = SwitchSceneId
        }
        -- 当前已经打开的页签不同于最终要打开的页签，需要进一步处理
        if self.curSelectTabKey ~= TabKey then
            -- 先手动关闭当前Tab页，避免在切换后触发VirtualTriggerShow
            if self.TabViews[self.curSelectTabKey] then
                self.TabViews[self.curSelectTabKey]:ManualClose()
            end
            -- 修改大厅缓存的场景Id为最终场景Id
            MvcEntry:GetCtrl(ViewRegister):RegisterVirtualLevelView(ViewConst.Hall,SwitchSceneId)
        end
    else
        self:ON_HALL_TAB_SWITCH_Func(Param)
    end
    -- 调用关闭界面，并且在内部触发场景切换，切换到 SwitchSceneId
    MvcEntry:CloseView(ViewConst.AllPopViewsOnTargetId,ViewConst.Hall)
end

-- 场景切换完成事件回调 切换完成后才展示UI
function WCommonHallTab:ON_HALL_SCENE_SWITCH_COMPLETED_Func()
    if not self.IsSwitchingToScene then
        return
    end
    local CurSceneId = MvcEntry:GetModel(HallModel):GetSceneID()
    if CurSceneId == self.IsSwitchingToScene.SwitchSceneId then
        self.IsForceSwitch = true
        self:ShowNewTab(self.IsSwitchingToScene.TabKey)
        self.IsSwitchingToScene = nil
    end
end

function WCommonHallTab:OnPrevTab()
    self:OnTabItemClick(self:GetPreTabKey(self.curSelectTabKey))
end

function WCommonHallTab:OnNextTab()
    self:OnTabItemClick(self:GetNextTabKey(self.curSelectTabKey))
end

--[[
    检查可切换状态
]]
function WCommonHallTab:CheckTabCanSwitch(TabKey,IsInit)
    if self.tabKey2Item[TabKey] and self.tabKey2Item[TabKey].UnlockId then
        local UnlockId = self.tabKey2Item[TabKey].UnlockId
        if not MvcEntry:GetModel(NewSystemUnlockModel):IsSystemUnlock(UnlockId,true) then
            return false
        end
    end
    -- if self.IsPlayAnimation then
    --     return false
    -- end
    local CanSwitch = true
    -- IsInit 不执行此检测
    if not IsInit then
        if self.IsMatchSuccess then
            CanSwitch = false
        end
    end
    return CanSwitch
end

function WCommonHallTab:OnShow(Param)
    self.ParentContainer = Param.Container
    if not self.ParentContainer then
        CError("WCommonHallTab Need Parent Container!!! Please Check!")
        print_trackback()
        return
    end
    self.IsMatchSuccess = false
    self.IsPlayAnimation = false
    self.ClickCallBack = Param.ClickCallBack

    --self:PlayEffectByTabType(self.DYNAMIC_EFFECT_ACTION_TYPE.DEFAULT)
    -- self.OnShowTabHallTabView = Param.OnShowTabHallTabView
end

function WCommonHallTab:InitShow(TabInitParam)
    self.TabInitParam = TabInitParam
    self:OnTabItemClick(CommonConst.HL_PLAY,true)
end

function WCommonHallTab:OnHide()
    self.AnimationFinishCb = nil
    -- 注销页签动效事件监听
	MsgHelper:OpDelegateList(self.View, self.TabViewBindNodes, false)
    MvcEntry:GetCtrl(ViewRegister):RegisterVirtualLevelView(ViewConst.Hall,nil)

    self.SwitchParam = nil
end

function WCommonHallTab:GetIsShowSidebar()
    if self.tabKey2Item[self.curSelectTabKey] then
        return self.tabKey2Item[self.curSelectTabKey].IsShowSideBar or false
    end
    return false
end

function WCommonHallTab:GetCurSelectTabIndex()
    local TabIndex = 0
    for _,v in ipairs(self.TabList) do
        TabIndex = TabIndex + 1
        if v.Key == self.curSelectTabKey then
            break
        end
    end
    return TabIndex
end

function WCommonHallTab:GetPreTabKey(CurTabIndex)
    local TabIndex = CurTabIndex - 1
    if TabIndex <= 0 then 
        TabIndex = #self.TabList
    end
    return self.TabList[TabIndex].Key
end

function WCommonHallTab:GetNextTabKey(CurTabIndex)
    local TabIndex = CurTabIndex + 1
    if TabIndex > #self.TabList then 
        TabIndex = 1
    end
    return self.TabList[TabIndex].Key
end

--[[
    更新当前选中Tab显示
]]
function WCommonHallTab:UpdateCurSelect(OldTabViewKey)
    for i,v in ipairs(self.TabList) do
        if v.Key == self.curSelectTabKey then
	        -- 选中态目标不再触发hover效果及点击反馈
            v.Node.GUIButton_TabBg:SetIsEnabled(false)
            if v.Node.VXE_Btn_Selected then
                v.Node:VXE_Btn_Selected()
            end
        else
            if v.Key == OldTabViewKey and v.Node.VXE_Btn_UnSelected then
                v.Node:VXE_Btn_UnSelected()
            end
	        -- 选中态目标不再触发hover效果及点击反馈
            v.Node.GUIButton_TabBg:SetIsEnabled(true)
        end
    end
end

--[[
    TabItem点击
    TabKey
    点击执行流程 HideOldTab -> SwitchVirtualScene -> ShowNewTab
]]
function WCommonHallTab:OnTabItemClick(TabKey,IsInit,IsForceSelect)
    if self.IsHallStreamLevelLoading then
        return false
    end
    if not self:CheckTabCanSwitch(TabKey,IsInit) then
		return
	end
    if not IsForceSelect and self.curSelectTabKey == TabKey then
        return
    end
    local NewTabInfo = self.tabKey2Item[TabKey]
    if not NewTabInfo then
        return
    end
    if NewTabInfo.Class == nil then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHallTab_Functionisnotopen"))
        return
    end
    -- self:DoTabVxEffect(TabKey)

    -- 先隐藏旧Tab的UI，再切场景
    self:HideOldTab(self.curSelectTabKey, TabKey)

    if self.ClickCallBack then
        self.ClickCallBack(TabKey,IsInit)
    end

    --self:PlayEffectByTabType(TabKey)
end

-- Tab按钮的UI自定义动效 （此动效单独播放，不和实际切换逻辑耦合）
-- function WCommonHallTab:DoTabVxEffect(TabKey)
--     local OldTabInfo = self.tabKey2Item[self.curSelectTabKey]
--     if OldTabInfo then
--         -- UI动效自定义事件
--         OldTabInfo.Node:VX_Tab_Unchoose()
--     end
--     local NewTabInfo = self.tabKey2Item[TabKey]
--     -- UI动效自定义事件
--     NewTabInfo.Node:VX_Tab_Choose()
-- end

-- 先隐藏旧Tab的UI
function WCommonHallTab:HideOldTab(OldTabViewKey,NewTabViewKey)
    if self.TabViews[OldTabViewKey] and CommonUtil.IsValid(self.TabViews[OldTabViewKey].View) then
        -- 隐藏上一个Tab
        local OldTabView = self.TabViews[OldTabViewKey].View
        self.AnimationFinishCb = function()
            self.AnimationFinishCb = nil
            -- self.TabViews[OldTabViewKey]:OnHideAvator()
            -- self.TabViews[OldTabViewKey]:OnCustomHide()
            OldTabView:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.TabViews[OldTabViewKey]:ManualClose()
            if NewTabViewKey then
                self:SwitchVirtualScene(NewTabViewKey)
            end
        end
        OldTabView:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.AnimationFinishCb()
    else
        if NewTabViewKey then
            self:SwitchVirtualScene(NewTabViewKey)
        end
    end
end

-- 切换虚拟场景
function WCommonHallTab:SwitchVirtualScene(NewTabViewKey)
    local ExistSwitchSceneId = nil
    if  _G.HallSceneMgrInst then
        if self.TabList[NewTabViewKey].VirtualSceneId and self.TabList[NewTabViewKey].VirtualSceneId ~= 0 then
            ExistSwitchSceneId = self.TabList[NewTabViewKey].VirtualSceneId
        end
        -- local SwitchSceneId = self.TabList[NewTabViewKey].VirtualSceneId
        -- -- HallTabPlay不同状态下存在不同的vsid，这里需要取当前展示状态下的场景id
        -- if self.TabList[NewTabViewKey].IsUseCustomVirtualScene then
        --     SwitchSceneId = MvcEntry:GetModel(HallModel):GetCurVirtualSceneId()
        --     if not SwitchSceneId then
        --         CError("[WCommonHallTab]SwitchSceneId is nil")
        --         return
        --     end
        -- end

        -- -- 动态注册Hall下页签对应的虚拟场景Id
        -- MvcEntry:GetCtrl(ViewRegister):RegisterVirtualLevelView(ViewConst.Hall,SwitchSceneId)
        -- --[[
        --     依赖虚拟场景的UI展示，
        --     需要将Pop层的UI都置为不可见
        --     需要进行SwitchScene切换流关卡及摄相机
        -- ]]
        -- CLog("SwitchScene:" .. SwitchSceneId)
        -- self.IsHallStreamLevelLoading = true
        -- --添加InputShieldLayer屏蔽玩家操作，防止串用引发问题
        -- InputShieldLayer.Add(4,1,function ()
        --     --超时
        --     CWaring("SwitchScene Timeout Please Check!")
        --     self.IsHallStreamLevelLoading = false
	    --     InputShieldLayer.Close()
        --     self:ShowNewTab(NewTabViewKey)
        -- end)
        -- _G.HallSceneMgrInst:SwitchScene(SwitchSceneId,function ()
        --     --切换成功，才能执行打开逻辑
        --     self.IsHallStreamLevelLoading = false
	    --     InputShieldLayer.Close()
        --     self:ShowNewTab(NewTabViewKey)
        -- end)
    end
    if ExistSwitchSceneId then
        self:DoSwitchVirtualScene(ExistSwitchSceneId,function ()
            self:ShowNewTab(NewTabViewKey)
        end)
    else
        self:ShowNewTab(NewTabViewKey)
    end
end

-- 展示新Tab的UI
function WCommonHallTab:ShowNewTab(NewTabViewKey)
    local NewTabInfo = self.tabKey2Item[NewTabViewKey]
    if NewTabInfo then
        local Param = self.SwitchParam or {}
        if NewTabViewKey == CommonConst.HL_PLAY then
            Param.InData = self.TabInitParam[NewTabViewKey]
            self.TabInitParam[NewTabViewKey] = nil
        end

        ---是否屏蔽 自己
        local Visibility = NewTabInfo.bHideTabOnShow and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible
        self.View:SetVisibility(Visibility)

        local NewTabViewCls = self.TabViews[NewTabViewKey]
        local IsInit = false
        if not NewTabViewCls then
            local WidgetClass = UE.UClass.Load(NewTabInfo.WBPPath)
            local Widget = NewObject(WidgetClass, self.WidgetBase)
            UIRoot.AddChildToPanel(Widget,self.ParentContainer)
            NewTabViewCls = UIHandler.New(self, Widget, NewTabInfo.Class, Param).ViewInstance
            self.TabViews[NewTabViewKey] = NewTabViewCls

		    -- 注册页签动效事件监听
            -- local TabViewBindNodes = {
            --     { UDelegate = NewTabViewCls.View.OnCustomAniFinished_VxTabUiIn, Func = Bind(self, self.OnCustomAniFinished_VxTabUiIn, NewTabViewKey) }, 
            --     { UDelegate = NewTabViewCls.View.OnCustomAniFinished_VxTabUiOut, Func = Bind(self, self.OnCustomAniFinished_VxTabUiOut,NewTabViewKey) }, 	
            -- }
			-- MsgHelper:OpDelegateList(self.View, TabViewBindNodes, true)
            -- self.TabViewBindNodes = self.TabViewBindNodes or {}
            -- ListMerge(self.TabViewBindNodes,TabViewBindNodes)
            IsInit = true
        else
            NewTabViewCls:ManualOpen(Param)
        end

        local NewTabView = NewTabViewCls.View
        self.AnimationFinishCb =  function()
            self.AnimationFinishCb = nil
            self.IsPlayAnimation = false
        end
        if not IsInit and not self.IsForceSwitch and NewTabView.vx_tab_ui_in then
            -- UI动效自定义事件 显示走动效控制
            self.IsPlayAnimation = true
            NewTabView:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            NewTabView.vx_tab_ui_in:UnbindAllFromAnimationFinished(NewTabView)
            NewTabView.vx_tab_ui_in:BindToAnimationFinished(NewTabView,function ()
                self.AnimationFinishCb()
            end)
            NewTabView:PlayAnimation(NewTabView.vx_tab_ui_in)
        else
            NewTabView:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.AnimationFinishCb()
        end
        -- self.TabViews[NewTabViewKey]:OnShowAvator(nil,IsInit)
        -- self.TabViews[NewTabViewKey]:OnCustomShow()
         --这里不依赖ViewConst，所以需要单独处理一下7
        ---@type UserModel
        local UserModel = MvcEntry:GetModel(UserModel)
        UserModel:UpdatePlayerClientHallState(NewTabInfo.ClientHallState)
    end
   
    local OldTabViewKey = self.curSelectTabKey
    self.curSelectTabKey = NewTabViewKey
    MvcEntry:GetModel(HallModel):SetCurHallTabType(self.curSelectTabKey)
    -- 派发事件通知Tab切换完成
    MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_HALL_TAB_SWITCH_COMPLETED,self.curSelectTabKey)
    self:UpdateCurSelect(OldTabViewKey)
    self.IsForceSwitch = false
    self.SwitchParam = nil

    -- if self.OnShowTabHallTabView then
    --     local InParam = {bHideTabOnShow = NewTabInfo.bHideTabOnShow}
    --     self.OnShowTabHallTabView(InParam)
    -- end
end

-- -- 外部调用 IsNotVirtualTrigger首次调用为true，首次调用由Tab自己控制逻辑。当外部切换界面的时候再走这个逻辑
-- function WCommonHallTab:OnShowAvator(Param,IsNotVirtualTrigger)
--     if IsNotVirtualTrigger then
--         return
--     end
--     if self.TabViews[self.curSelectTabKey] and CommonUtil.IsValid(self.TabViews[self.curSelectTabKey].View)
--     and not self.TabViews[self.curSelectTabKey].IsHide then
--         self.TabViews[self.curSelectTabKey]:OnShowAvator(Param,IsNotVirtualTrigger)
--     end
-- end

-- function WCommonHallTab:OnHideAvator(Param,IsNotVirtualTrigger)
--     if self.TabViews[self.curSelectTabKey] and CommonUtil.IsValid(self.TabViews[self.curSelectTabKey].View) then
--         self.TabViews[self.curSelectTabKey]:OnHideAvator(Param,IsNotVirtualTrigger)
--     end
-- end

-- function WCommonHallTab:OnTabHovered(Index)
--     local TabItem = self.Index2Node[Index]
--     local NextNode = self.Index2Node[Index+1]
--     -- local ColorAndOpacity = TabItem.GUITextBlock_1.ColorAndOpacity
--     -- ColorAndOpacity.A = 0.5
--     -- TabItem.GUITextBlock_1:SetColorAndOpacity(ColorAndOpacity)
--     TabItem.ImgLine:SetVisibility(UE.ESlateVisibility.Collapsed)
--     if NextNode then
--         NextNode.ImgLine:SetVisibility(UE.ESlateVisibility.Collapsed)
--     end
--     -- UI动效自定义事件
--     TabItem:VX_Tab_Hover()
-- end

-- function WCommonHallTab:OnTabUnhovered(Index)
    
--     local TabItem = self.Index2Node[Index]
--     local NextNode = self.Index2Node[Index+1]

--     -- local ColorAndOpacity = TabItem.GUITextBlock_1.ColorAndOpacity
--     -- ColorAndOpacity.A = 0.3
--     -- TabItem.GUITextBlock_1:SetColorAndOpacity(ColorAndOpacity)
--     if Index ~= 1 then
--         TabItem.ImgLine:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--     end
--     if NextNode then
--         NextNode.ImgLine:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--     end

--     -- UI动效自定义事件
--     TabItem:VX_Tab_Unhover()
-- end

function WCommonHallTab:ON_MATCH_IDLE_Func()
    if self.IsMatchSuccess then
        self.IsMatchSuccess = false
    end    
end

function WCommonHallTab:ON_DS_ERROR_Func()
    self.IsMatchSuccess = false
end

-- 监听匹配成功，匹配成功后不给进行切换
function WCommonHallTab:ON_GAMEMATCH_SUCCECS_Func()
    self.IsMatchSuccess = true
end


-- -- UI动效 播放完成回调
-- function WCommonHallTab:OnCustomAniFinished_VxTabUiIn(TabViewKey)
--     if self.AnimationFinishCb then
--         self.AnimationFinishCb()
--     end
-- end

-- -- UI动效 播放完成回调
-- function WCommonHallTab:OnCustomAniFinished_VxTabUiOut(TabViewKey)
--     if self.AnimationFinishCb then
--         self.AnimationFinishCb()
--     end
-- end

function WCommonHallTab:PlayEffectByTabType(InType)
    if InType == self.DYNAMIC_EFFECT_ACTION_TYPE.DEFAULT then 
        if self.View.VXE_MainHall_Tab_In then
            self.View:VXE_MainHall_Tab_In()
        end
    elseif InType == self.DYNAMIC_EFFECT_ACTION_TYPE.HERO then
        if self.View.VXE_MainHall_Tab_In_Hero then
            self.View:VXE_MainHall_Tab_In_Hero()
        end
    elseif InType == self.DYNAMIC_EFFECT_ACTION_TYPE.SEASON then
        if self.View.VXE_MainHall_Tab_In_Season then
            self.View:VXE_MainHall_Tab_In_Season()
        end
    elseif InType == self.DYNAMIC_EFFECT_ACTION_TYPE.SHOP then
        if self.View.VXE_MainHall_Tab_In_Shop then
            self.View:VXE_MainHall_Tab_In_Shop()
        end
    elseif InType == self.DYNAMIC_EFFECT_ACTION_TYPE.WEAPON then
        if self.View.VXE_MainHall_Tab_In_Weapon then
            self.View:VXE_MainHall_Tab_In_Weapon()
        end
    elseif InType == self.DYNAMIC_EFFECT_ACTION_TYPE.PLAY then
        if self.View.VXE_MainHall_Tab_In_Play then
            self.View:VXE_MainHall_Tab_In_Play()
        end
    end
end



return WCommonHallTab
