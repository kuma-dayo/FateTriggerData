require "UnLua"
local class_name = "SettingMainUI"
SettingMainUI = SettingMainUI or BaseClass(GameMediator, class_name);



function SettingMainUI:__init()
    print("SettingMainUI:__init")
    -- if UE.UGameplayStatics.GetPlatformName() == "Windows" then
    --     self:ConfigViewId(ViewConst.Setting)
    -- else 
    --     self:ConfigViewId(ViewConst.SettingMobile)
    -- end
    if  BridgeHelper.IsPCPlatform() then
        self:ConfigViewId(ViewConst.Setting)
    else
        self:ConfigViewId(ViewConst.SettingMobile)
    end
end

function SettingMainUI:OnShow(data)
    print("SettingMainUI:OnShow")
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    MsgHelper:Send(self.LocalPC, "SETTING_Show")
    --self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function SettingMainUI:OnHide()
end


---------------------------------
--local SettingMain = Class("Common.Framework.UserWidget")
--这里初始化的时候，框架没有初始化完毕，所以导致报错
local SettingMain = Class("Client.Mvc.UserWidgetBase")
function SettingMain:OnInit()
    print("SettingMain:OnInit")
    
    -- 注册消息监听
	self.MsgListGMP = {
		--{ MsgName = GameDefine.Msg.SETTING_Show,            Func = self.OnSettingShow,      bCppMsg = false },
		--{ MsgName = GameDefine.Msg.SETTING_Hide,            Func = self.OnSettingHide,      bCppMsg = false },
        { MsgName = "UIEvent.SettingIsShow",            Func = self.OnSettingIsShow,      bCppMsg = false },
		--{ MsgName = "SETTING_Hide",            Func = self.OnSettingHide,      bCppMsg = false },
        { MsgName = "UIEvent.ResetDefaultSetting", Func = self.ResetDefaultSetting,      bCppMsg = false},
        { MsgName = "UIEvent.ESCSetting", Func = self.ESCSetting,      bCppMsg = false},
        { MsgName = "UIEvent.ShowConflictTips", Func = self.ShowConflictTips,      bCppMsg = false},
        { MsgName = "UIEvent.SettingHide", Func = self.OnClicked_GUIButton_Close,      bCppMsg = false},
        { MsgName = "UIEvent.SetScrollWidgetIntoView", Func = self.SetScrollWidgetIntoView,      bCppMsg = false},
        { MsgName = "UIEvent.ChangeDetailContent", Func = self.ChangeDetailContent,      bCppMsg = false},
        { MsgName = "UIEvent.PosscessResetDefault", Func = self.PosscessResetDefault,      bCppMsg = true},
        { MsgName = "UIEvent.PosscessApply", Func = self.PosscessApply,      bCppMsg = true},
        { MsgName = "UIEvent.PosscessRefreshContent", Func = self.PosscessRefreshContent,      bCppMsg = true},
        { MsgName = "UIEvent.PosscessRefreshFixContent", Func = self.PosscessRefreshContent,      bCppMsg = true},
        { MsgName = "UIEvent.PosscessRefreshItemIsShow", Func = self.PosscessRefreshItemIsShow,      bCppMsg = true},
        { MsgName = "UIEvent.PosscessRefreshItemIsEdit", Func = self.PosscessRefreshItemIsEdit,      bCppMsg = true},
        { MsgName = "UIEvent.PosscessRefreshItemValue", Func = self.PosscessRefreshItemValue,      bCppMsg = true},
        
        
    }

    self.BindNodes = nil
    if BridgeHelper.IsPCPlatform() then
        self.BindNodes ={
            { UDelegate = self.Close.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_Close },
            { UDelegate = self.ResetDefault.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_ResetDefault},
            --{UDelegate = self.GUIButton_Center.OnClicked, Func = self.OnClicked_GUIButton_Center},
            { UDelegate = self.Apply.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_Apply},
            { UDelegate = self.Close.NotifyKey, Func = self.OnClicked_GUIButton_Close },
            {UDelegate = self.ResetDefault.NotifyKey, Func = self.OnClicked_GUIButton_ResetDefault},
            {UDelegate = self.Apply.NotifyKey, Func = self.OnClicked_GUIButton_Apply}
        }
    end
    self.BindNodes = self.BindNodes or {}
    table.insert(self.BindNodes, {UDelegate = self.GUIButton_Center.OnClicked, Func = self.OnClicked_GUIButton_Center})
    if self.GUIButton_Switcher then
        table.insert(self.BindNodes, {UDelegate = self.GUIButton_Switcher.OnClicked, Func = self.OnClicked_GUIButton_Switcher})
    end

    --隐私政策
    if CommonUtil.IsValid(self.GUIButton_Privacy) then
        table.insert(self.BindNodes, {UDelegate = self.GUIButton_Privacy.OnClicked, Func = self.OnClicked_GUIButton_Privacy}) 
    end
    --删除账号
    if CommonUtil.IsValid(self.GUIButton_Delete) then
        table.insert(self.BindNodes, {UDelegate = self.GUIButton_Delete.OnClicked, Func = self.OnClicked_GUIButton_Delete}) 
    end

    if  self:IsSettingMainOpenInHall() then
    self.MsgList = 
    {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnClicked_GUIButton_Close },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.R), Func = self.OnClicked_GUIButton_ResetDefault },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Enter), Func = self.OnClicked_GUIButton_Apply },
    }
    MsgHelper:RegisterList(self, self.MsgList)
    end
    -- MsgHelper:RegisterList(self, self.MsgLists)
    -- MsgHelper:OpDelegateList(self, self.BindNodes, true)
    
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    --初始化手柄图标
    self:InitGamepadData()
    local GenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(GameInstance);
    if GenericGamepadUMGSubsystem  then 
        local status = GenericGamepadUMGSubsystem:IsInGamepadInput()
        self:SetGamepadIconShow(status)
    end
    
   
    self:InitGamepadFocusWidget()
    
    if self:IsSettingMainOpenInHall() then
        self.bIsFocusable = false
    end

    if BridgeHelper.IsMobilePlatform() then
        self.BP_Button_ReturnLobby.Img_Icon:SetBrushFromTexture(self.BP_Button_ReturnLobby.Icon, false)
        self.BP_Button_Reset.Img_Icon:SetBrushFromTexture(self.BP_Button_Reset.Icon, false)
        self.BP_Button_ReturnLobby.Text_Name:SetText(self.BP_Button_ReturnLobby.TextContent)
        self.BP_Button_Reset.Text_Name:SetText(self.BP_Button_Reset.TextContent)
        table.insert(self.BindNodes, {UDelegate = self.BP_Button_ReturnLobby.Button_Reset.OnClicked, Func = self.OnReturnClick})
        table.insert(self.BindNodes, {UDelegate = self.BP_Button_Reset.Button_Reset.OnClicked, Func = self.OnClicked_GUIButton_ResetDefault}) 
        table.insert(self.BindNodes, {UDelegate = self.BP_Setting_Back.Button_Back.OnClicked, Func = self.OnClicked_GUIButton_Close}) 
        --已在大厅中隐藏按钮
        if self:IsSettingMainOpenInHall() then self.BP_Button_ReturnLobby:SetVisibility(UE.ESlateVisibility.Collapsed) end
    end

     UserWidgetBase.OnInit(self)
end

function SettingMain:InitGamepadFocusWidget()
    self.CurrentFocusWidget = nil
end


function SettingMain:InitGamepadData()

    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local KeyIcon = SettingSubsystem.KeyIconMap:TryGetIconByKey(self,self.GamepadKeyLeft)
    if KeyIcon and KeyIcon:IsValid() then
        self.GamepadKeyLeftIcon:SetBrushFromTexture(KeyIcon,true)
    end
    KeyIcon = SettingSubsystem.KeyIconMap:TryGetIconByKey(self,self.GamepadKeyRight)
    if KeyIcon and KeyIcon:IsValid() then
        self.GamepadKeyRightIcon:SetBrushFromTexture(KeyIcon,true)
    end
    if BridgeHelper.IsPCPlatform() then
        self.Apply:InitGamepadData(self.GamepadApplyKey)
        self.ResetDefault:InitGamepadData(self.GamepadResetKey)
        self.Close:InitGamepadData(self.GamepadCloseKey)
    end

end

function SettingMain:OnChangeInputType(InStatus)
    self:SetGamepadIconShow(InStatus)
end
function SettingMain:SetGamepadIconShow(InStatus)
    
    if InStatus == true then
        self.GamepadKeyLeftIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.GamepadKeyRightIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.GamepadKeyLeftIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.GamepadKeyRightIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if BridgeHelper.IsPCPlatform() then
        self.Apply:SetGamepadIconShow(InStatus)
        self.ResetDefault:SetGamepadIconShow(InStatus)
        self.Close:SetGamepadIconShow(InStatus)
    end
end

function SettingMain:OnDestroy()
    --[[
     if self.BindNodes then
         MsgHelper:OpDelegateList(self, self.BindNodes, false)
 		self.BindNodes = nil
 	end

 	if self.MsgList then
 		MsgHelper:UnregisterList(self, self.MsgList)
 		self.MsgList = nil
 	end
	]]--
    
    UserWidgetBase.OnDestroy(self)
 end
 function SettingMain:OnClose()
    print("SettingMain:OnClose")
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    SettingSubsystem:ResetCachedLastApplyData()
    SettingSubsystem:ResetKeyMapConflict()
    self:ProcessSettingData()
 end


 --用于打开手机自定义布局时暂时隐藏布局，不能关闭
function SettingMain:OnSettingIsShow(data)
   if data.IsShow == true then
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
end


function SettingMain:OnSettingClose()
    print("SettingMain:OnSettingClose")
    self.IsShow = false
    UE.UGenericSettingSubsystem.Get(self):CallIsSettingShow(false)
   
    local UIManager = UE.UGUIManager.GetUIManager(self)
    UIManager:TryCloseDynamicWidget("UMG_Setting")
end
function SettingMain:ProcessSettingData()
    --发送当前修改的设置值到后台
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local InSettingDataTable = SettingSubsystem:GetModifySettingData()
    local DelSettingName = SettingSubsystem:GetDelTagNameArray()
    local BurySettings = SettingSubsystem:GetBurySettingData()
    MvcEntry:GetCtrl(SettingCtrl):SendSetting_Func(InSettingDataTable,DelSettingName)
    MvcEntry:GetCtrl(SettingCtrl):SendBurySettings_Func(BurySettings)
    --删除缓存的数据
    SettingSubsystem:ReSetModifyAndBurySettingData()
    
    ---如果当前是手机平台，要处理自定义布局数据
    if UE.UGFStatics.IsMobilePlatform()  then
        local InSaveMobileLayoutData = SettingSubsystem:GetCachedMobileLayoutSaveData()
        local InDelLayoutData = SettingSubsystem:GetDelMobileLayoutData()
        MvcEntry:GetCtrl(SettingCtrl):SendCustomLayout_Func(InSaveMobileLayoutData,InDelLayoutData)
        --删除缓存数据
        SettingSubsystem:ResetModifyMobileLayoutData()
        SettingSubsystem:ResetDelMobileLayoutData()

    end
end
--这是给ESC输入做的，因为按ESC会自动发一次消息，这样会乱
function SettingMain:OnClicked_GUIButton_Close()
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if SettingSubsystem and SettingSubsystem.CanShowConflictTipsTag:Contains(self.ActiveTabTag) then
        local IsConflict = SettingSubsystem:IsHasConflictKey()
        if IsConflict  == true  then  
            self:ShowConflictTips(nil)
            return
        end
    end
    self:ProcessSettingData()
    
    if self.MvcCtrl and self.viewId then
        
        --通过Mvc框架管理的
        MvcEntry:CloseView(self.viewId)
    else
        self:OnSettingClose()
    end
end



--恢复默认
function SettingMain:OnClicked_GUIButton_ResetDefault()
    
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local SettingTabData = SettingSubsystem:GetSettingTabDataByTag(self.ActiveTabTag)
    local IsSimilar = SettingSubsystem:IsSimilarToDefault(self.ActiveTabTag)
    print("SettingMain:OnClicked_GUIButton_ResetDefault",self.ActiveTabTag.TagName,IsSimilar)
    if IsSimilar == true then
        return 
    end
    if self.MvcCtrl and self.viewId then
        local Data ={
            TabText = SettingTabData.ResetTextTitle,
            DetailText = SettingTabData.ResetTextDetail,
            --IsSimilar =IsSimilar,
        }
        MvcEntry:OpenView(ViewConst.SettingSetPopUp,Data)
    else
        local GenericBlackboard = UE.FGenericBlackboardContainer()
        local  TabTextType= UE.FGenericBlackboardKeySelector()  
        TabTextType.SelectedKeyName = "TabText"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,TabTextType, tostring(SettingTabData.ResetTextTitle))
        TabTextType.SelectedKeyName = "DetailText"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,TabTextType, tostring(SettingTabData.ResetTextDetail))
        -- TabTextType.SelectedKeyName = "IsSimilar"
        -- UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsBool(GenericBlackboard,TabTextType,IsSimilar)
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        TipsManager:ShowTipsUIByTipsId("Setting.SettingSetPopUp",-1,GenericBlackboard,self)
    end  

    
end


--[[
    退出帐号
]]
function SettingMain:OnClicked_GUIButton_Center()
    if not self:IsSettingMainOpenInHall()  then
        return
    end
    local Param = {
		LogoutActionType = MSDKConst.LogoutActionTypeEnum.Logout
	}
    MvcEntry:GetCtrl(CommonCtrl):GAME_LOGOUT(Param)
end

--[[
    切换帐号
]]
function SettingMain:OnClicked_GUIButton_Switcher()
    if not self:IsSettingMainOpenInHall()  then
        return
    end
    local Param = {
		LogoutActionType = MSDKConst.LogoutActionTypeEnum.SwitcherUser
	}
    MvcEntry:GetCtrl(CommonCtrl):GAME_LOGOUT(Param)
end

---隐私政策
function SettingMain:OnClicked_GUIButton_Privacy()
    local RegionPolicyID = MvcEntry:GetModel(SystemMenuModel):GetRegionPolicy()
    if RegionPolicyID == nil then
        return
    end
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_RegionPolicyConfig, RegionPolicyID)
    if Cfg == nil then
        return
    end

    local msgParam = {
        -- Url = "https://www.baidu.com/",
        Url = Cfg[Cfg_RegionPolicyConfig_P.PrivacyPolicyURL],
        TitleTxt = G_ConfigHelper:GetStrFromCommonStaticST("Lua_Statement_Privacy"),--隐私条款
    }
    UIWebBrowser.Show(msgParam)
end

---删除账号
function SettingMain:OnClicked_GUIButton_Delete()
    local describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_Account_Deletion_Tips")) --请联系contact@sarosgame.com删除账户
    local msgParam = {
        -- title = "ssdss2",
        describe = describe,
        -- leftBtnInfo = {},
        rightBtnInfo = {
            callback = function()
            end
        },
        -- HideCloseTip = true,
        -- HideCloseBtn = true,
    }
    UIMessageBox.Show(msgParam)
end

function SettingMain:ResetDefaultSetting()
    print("SettingMain:ResetDefault")
    --表现改完之后，需要将当前页面的数据存档都改回默认值
    if  self.IsShow == true then
        self:BPFunc_ResetSubContentData(self.ActiveTabSubContentPath,self.ActiveTabTag)
    end
    self:SetFocus(true)
    self:PosscessResetDefault()

end

--局内切回设置主界面需要主动设置focus
function SettingMain:ESCSetting()
    --print("SettingMain:ESCSetting")
    self:SetFocus(true)
    self:UpdateNavgation()
    self.bIsFocusable =true
end

function SettingMain:OnShow(data)
    --print("SettingMain:OnShow",data)
    self.IsShow = true
    self.bIsFocusable =true
    UE.UGenericSettingSubsystem.Get(self):CallIsSettingShow(true)
    self.TabButtonBox:ClearChildren()
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local WidgetType = SettingSubsystem:GetWidgetByType(UE.ESettingDataType.TabButton)
    local TabButtonData = SettingSubsystem:GetTabButtonData()
    local ChildWidget = nil
    for k, v in pairs(TabButtonData) do
        ChildWidget =  UE.UGUIUserWidget.Create(self.LocalPC, WidgetType, self.LocalPC)
       if ChildWidget then
            ChildWidget:InitData(v)
            self.TabButtonBox:AddChild(ChildWidget)
            --为每个Tab按钮绑个回调
            self.NewBindNodes ={
            { UDelegate = ChildWidget.NotifyActiveTab, Func = self.RefreshActiveTab },
            { UDelegate = ChildWidget.CheckHoverTab, Func = self.CheckHoverTab },
        }
        ChildWidget.Index =k-1
        MsgHelper:OpDelegateList(self, self.NewBindNodes, true)
       
       end
       
    end
    ChildWidget = self.TabButtonBox:GetChildAt(0)
    ChildWidget:RefreshSubContent()
    --CBT1屏蔽切换账号以及退出账号按钮
    --送审版本
    -- self.GUIButton_Center:SetVisibility(self:IsSettingMainOpenInHall() and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    -- if self.GUIButton_Switcher then
    --     self.GUIButton_Switcher:SetVisibility(self:IsSettingMainOpenInHall() and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    -- end

    --针对子系统，需要隐藏切换帐号及退出帐号按钮
    -- if MvcEntry:GetCtrl(OnlineSubCtrl):IsOnlineEnabled() then
    --     self.GUIButton_Center:SetVisibility(UE.ESlateVisibility.Collapsed)
    --     self.GUIButton_Switcher:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- end

    --隐私政策
    if CommonUtil.IsValid(self.GUIButton_Privacy) then
        self.GUIButton_Privacy:SetVisibility(self:IsSettingMainOpenInHall() and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    end
    --删除账号
    if CommonUtil.IsValid(self.GUIButton_Delete) then
        self.GUIButton_Delete:SetVisibility(self:IsSettingMainOpenInHall() and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    end
end


function SettingMain:RefreshActiveTab(InTag,InPath,InIndex,InIsHideReset)
    print("SettingMain:RefreshActiveTab",InTag.TagName,InPath,InIsHideReset)
    self.ActiveTabTag = InTag
    self.ActiveTabSubContentPath = InPath
    self.ActivateIndex = InIndex
    self.IsHideReset = InIsHideReset
    self.SubItemScrollBox:ClearChildren()
    
    --刷新SubContent的内容，一读取表里的数据，二生成对应的UI
    self:BPFunc_RefreshSubContentData(InPath,InTag)

    self:ResetTabButtonState(InTag,InIndex)
    local Widget = self.SubItemScrollBox:GetChildAt(1)
    if Widget and BridgeHelper.IsPCPlatform() then
        Widget:SetHoverStyle()
    end
    self:PosscessResetDefault()
    self:UpdateNavgation()
    self:FocusFirstWidget()
    --self:BindMessage()

    --[[
        补充设置界面Tab切换上报事件
    ]]
    local ViewParam = {
        ViewId = ViewConst.SystemMenu,
        TabId = InIndex,
    }
    MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
end

function SettingMain:FocusFirstWidget()
    --wzp
    --主要让手柄焦距到页签第一个Item选项栏
    --首先我需要遍历该页签所有的Item,并且从第一个开始检查，如果找到可用的Item将焦距设置这个Item，然后跳出循环
    --其次，这个函数应该只在切换页面的时机调用
    local ChildrenCount = self.SubItemScrollBox:GetChildrenCount()
    local Visible = nil
    local bIsEnable = nil
    for ChildIndex = 1, ChildrenCount do
        local CurrenEachWidget = self.SubItemScrollBox:GetChildAt(ChildIndex-1)
        local WidgetType = CurrenEachWidget.SettingDataType

        Visible = CurrenEachWidget:GetVisibility()
        bIsEnable = CurrenEachWidget.bIsEnabled
        if WidgetType ~= UE.ESettingDataType.Header and CurrenEachWidget.bIsEnabled and Visible ~= UE.ESlateVisibility.Collapsed then
            CurrenEachWidget:SetFocus()
            goto continue
        end
    end
    ::continue::
end


function SettingMain:UpdateNavgation()
    --更新手柄导航路径
    --1.切换页签需要更新导航 
    --2.当选项页面中任意一个Item设置可见性需要更新导航，避免焦距会导航到隐藏的Item上
    --3.当选项页面中任意一个Item设置是否启用需要更新导航，避免焦距导航到禁用状态的Item上
    local ChildrenCount = self.SubItemScrollBox:GetChildrenCount()

    self.NavgationWidgetArr = {}
    local Visible = nil
    local bIsEnable = nil
    for ChildIndex = 1, ChildrenCount do
        local CurrenEachWidget = self.SubItemScrollBox:GetChildAt(ChildIndex-1)
        local WidgetType = CurrenEachWidget.SettingDataType

        Visible = CurrenEachWidget:GetVisibility()
        bIsEnable = CurrenEachWidget.bIsEnabled
        if WidgetType ~= UE.ESettingDataType.Header and CurrenEachWidget.bIsEnabled and Visible ~= UE.ESlateVisibility.Collapsed then
            table.insert(self.NavgationWidgetArr,CurrenEachWidget)
            CurrenEachWidget.bIsFocusable = true
        else
            CurrenEachWidget.bIsFocusable = false
        end
    end
    self:SetAllChildWidgetNavigation()
end

function SettingMain:SetAllChildWidgetNavigation()
    
    local AllNavigationArr = UE.TArray(UE.FWidgetCustomNavigationData)

    for i = 1, #self.NavgationWidgetArr do
        local UpIndex = i - 1
        local DownIndex = i + 1
        local UpWidget = nil
        local DownWidget = nil

        local CurrentWidget = self.NavgationWidgetArr[i]
        if self.NavgationWidgetArr[UpIndex] then
            UpWidget = self.NavgationWidgetArr[UpIndex]
            CurrentWidget:SetNavigationRule(UE.EUINavigation.Up,UE.EUINavigationRule.Explicit,GetObjectName(UpWidget))
        end

        if self.NavgationWidgetArr[DownIndex] then
            DownWidget = self.NavgationWidgetArr[DownIndex]
            CurrentWidget:SetNavigationRule(UE.EUINavigation.Down,UE.EUINavigationRule.Explicit,GetObjectName(DownWidget))
        end

        CurrentWidget.bIsFocusable = true
        CurrentWidget.GamepadFocusChangeDelegate:Bind(self,self.OnGamepadFocusChange)
        CurrentWidget.GamepadFocusKeyDownDelegate:Bind(self,self.OnGamepadFocusItemKeyDown)
    end
end


function SettingMain:OnGamepadFocusableChange(bGamepadAttached)
    self.bGamepadAttached = bGamepadAttached
end


function SettingMain:ResetTabButtonState(InTag,InIndex)
    print("SettingMain:ResetTabButtonState",InTag.TagName,InIndex)
    local ChildWidget = nil
    for i=0, self.TabButtonBox:GetChildrenCount()-1 do
        ChildWidget = self.TabButtonBox:GetChildAt(i)
        if ChildWidget and ChildWidget.TabTag.TagName ~= InTag.TagName  then
            ChildWidget:ResetButtonState()
        end
    end
    if InIndex then
        ChildWidget = self.TabButtonBox:GetChildAt(InIndex+1)
        if ChildWidget then
            ChildWidget:SetTabButtonLineHover(true)
        end
    end
    
end


function SettingMain:CheckHoverTab(HoverIndex,IsHover)
    print("SettingMain:CheckHoverTab HoverIndex",HoverIndex,"IsHover",IsHover)
    
    if IsHover == false then
        self:ResetTabButtonState(self.ActiveTabTag,self.ActivateIndex)
    end
    local ChildWidget = self.TabButtonBox:GetChildAt(HoverIndex+1)
    if ChildWidget  then
        print("SettingMain:CheckHoverTab HoverIndex",HoverIndex,"Tag",ChildWidget.TabTag.TagName)
        if HoverIndex == self.ActivateIndex or ChildWidget.IsActiviate == true  then
            ChildWidget:SetTabButtonLineHover(true)
        else
            ChildWidget:SetTabButtonLineHover(IsHover)
        end     
    end
end


function SettingMain:ShowConflictTips(InTagName)
   
    
        local TabTxt = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SettingMain_Thereisaconflictbetw"))
        local DetailTxt = G_ConfigHelper:GetStrFromCommonStaticST("Lua_SettingMain_Incaseofconflictthef")
        if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
           
            local GenericBlackboard = UE.FGenericBlackboardContainer()
            local  TabTextType= UE.FGenericBlackboardKeySelector()  
            TabTextType.SelectedKeyName = "TabText"
            UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,TabTextType, tostring(TabTxt))
            TabTextType.SelectedKeyName = "DetailText"
            UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,TabTextType, tostring(DetailTxt))
            TabTextType.SelectedKeyName = "AskTagName"
            UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,TabTextType, tostring(InTagName))
            
            local TipsManager = UE.UTipsManager.GetTipsManager(self)
            TipsManager:ShowTipsUIByTipsId("Setting.SettingKeyMapConflict",-1,GenericBlackboard,self)
        else
            local Data ={
                TabText = TabTxt,
                DetailText = DetailTxt,
                AskTagName = InTagName
            }
            MvcEntry:OpenView(ViewConst.SettingKeyMapConflict,Data)
        end
end

function SettingMain:SetScrollWidgetIntoView(InWidget)
    print("SettingMain:SetScrollWidgetIntoView",InWidget)
    self.SubItemScrollBox:ScrollWidgetIntoView(InWidget)
end

function SettingMain:ChangeDetailContent(data)
    if BridgeHelper.IsMobilePlatform() then
        return 
    end
    print("SettingMain:ChangeDetailContent InTag",data.InTag.TagName,data.IsShowTableDetailWidget,data.InBlackboard)
    if self.SettingDetails then self.SettingDetails:OnInitialize(data.InTag,data.InBlackboard,data.IsShowTableDetailWidget,data.IsShowTitle) end
end


function SettingMain:PosscessResetDefault()
   
    if self.IsHideReset == true then
        if self.ResetDefault then self.ResetDefault:SetVisibility(UE.ESlateVisibility.Collapsed) end
        if self.BP_Button_Reset then self.BP_Button_Reset:SetVisibility(UE.ESlateVisibility.Collapsed) end
        return 
    else
        if self.ResetDefault then self.ResetDefault:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
        if self.BP_Button_Reset then self.BP_Button_Reset:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
    end
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
       local IsSimilar = SettingSubsystem:IsSimilarToDefault(self.ActiveTabTag)
       print("SettingMain:RefreshActiveTab IsSimilar",IsSimilar)
        if IsSimilar == true then  
            if self.ResetDefault then self.ResetDefault:SetVisibility(UE.ESlateVisibility.Collapsed) end
        else
            if self.ResetDefault then self.ResetDefault:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
        end
        if self.Apply then self.Apply:SetVisibility(UE.ESlateVisibility.Collapsed) end
end

function SettingMain:OnClicked_GUIButton_Apply()
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if SettingSubsystem:GetShouldCachedApplyData() == true then
        SettingSubsystem:ApplyCachedData()
        self.Apply:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if SettingSubsystem.ShowApplyPopUpTag:Contains(self.ActiveTabTag) then
        if self.MvcCtrl and self.viewId then
            local Data ={}
            Data.TagName = tostring(self.ActiveTabTag.TagName)
            
            MvcEntry:OpenView(ViewConst.SettingApplyPopUp,Data)
        else
            local TipsManager = UE.UTipsManager.GetTipsManager(self)
            local GenericBlackboard = UE.FGenericBlackboardContainer()
            local  TabType= UE.FGenericBlackboardKeySelector()  
            TabType.SelectedKeyName = "Tab"
            UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,TabType, tostring(self.ActiveTabTag.TagName))
            TipsManager:ShowTipsUIByTipsId("Setting.SettingApplyPopUp",-1,GenericBlackboard,self)
        end
    end
   
end

function SettingMain:PosscessApply(IsSame)
   if IsSame == true then
        if self.Apply then self.Apply:SetVisibility(UE.ESlateVisibility.Collapsed) end
   else
        if self.Apply then self.Apply:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
   end
    
    
end

function SettingMain:OnKeyDown(MyGeometry,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    local IsApplayShow = false
    if self.Apply and self.Apply.Visibility ~= UE.ESlateVisibility.Collapsed then
        IsApplayShow = true
    end
    if self.Close and PressKey == self.Close.Key then
        self:OnClicked_GUIButton_Close()
    elseif self.ResetDefault and PressKey == self.ResetDefault.Key and self.IsHideReset == false then
        self:OnClicked_GUIButton_ResetDefault()
    elseif self.Apply and PressKey == self.Apply.Key and IsApplayShow == true then
        self:OnClicked_GUIButton_Apply()
    elseif PressKey == self.GamepadKeyLeft then
        self:HandleGamepadRefeshTab(-1)
    elseif PressKey == self.GamepadKeyRight then
        self:HandleGamepadRefeshTab(1)
    elseif PressKey == self.GamepadCloseKey then
        self:OnClicked_GUIButton_Close()
    elseif PressKey == self.GamepadResetKey and self.IsHideReset == false then
        self:OnClicked_GUIButton_ResetDefault()
    elseif PressKey == self.GamepadApplyKey and IsApplayShow == true then
        self:OnClicked_GUIButton_Apply()
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingMain:HandleGamepadRefeshTab(InIndex)
    --先检测新的索引是否合法，如果不合法直接return
    --如果合法则模拟点击Tab按钮，这样就不用再考虑视觉状态
    local NewIndex = self.ActivateIndex +InIndex
    --print("SettingMain:HandleGamepadRefeshTab",NewIndex,"self.ActivateIndex",self.ActivateIndex)
    if NewIndex < 0  then
        NewIndex =  self.TabButtonBox:GetChildrenCount()-1
    end
    if  NewIndex >= self.TabButtonBox:GetChildrenCount() then
        NewIndex = 0
    end
    local ChildTab = self.TabButtonBox:GetChildAt(NewIndex)
    if ChildTab then
        ChildTab:RefreshSubContent()
        --print("SettingMain:HandleGamepadRefeshTab ChildTab",ChildTab.TabTag.TagName)
    end
    
end


function SettingMain:PosscessRefreshContent(InTagName,InItemReturnValue)
    print("SettingMain:PosscessRefreshContent InTagName",InTagName,InItemReturnValue)
    
    local AllChildren = self.SubItemScrollBox:GetAllChildren()
    for k,v in pairs(AllChildren) do
      
        if v ~= nil and v.ParentTag.TagName == InTagName then      
            v:RefreshItemContent(InItemReturnValue)
        end
    end
end


function SettingMain:IsSettingMainOpenInHall()

    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        return false
     end
    -- if self.MvcCtrl ~= nil and self.viewId ~= nil  then
    --     return true
    -- end
    return true
end

function SettingMain:PosscessRefreshItemIsShow(InTagName,InInValue,InEffectIndex)
    print("SettingMain:PosscessRefreshItemIsShow InTagName",InTagName,InInValue.Value_Int,InEffectIndex)
    local AllChildren = self.SubItemScrollBox:GetAllChildren()
    for k,v in pairs(AllChildren) do
        
        if v.ParentTag.TagName == InTagName then
            if InInValue.Value_Int == InEffectIndex then
                v:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            else 
                v:SetVisibility(UE.ESlateVisibility.Collapsed)
              
            end
        end
    end
    --当Item显示隐藏的时候更新手柄导航信息，否则方向键会移动到隐藏的Item
    self:UpdateNavgation()
end

function SettingMain:PosscessRefreshItemIsEdit(InTagName,InInValue,InEffectIndex)
    print("SettingMain:PosscessRefreshItemIsEdit InTagName",InTagName,InInValue.Value_Int,InEffectIndex)
    local AllChildren = self.SubItemScrollBox:GetAllChildren()
    for k,v in pairs(AllChildren) do
        
        if v.ParentTag.TagName == InTagName then
            if InInValue.Value_Int == InEffectIndex then
                v:SetIsEnabled(true)
            else
                v:SetIsEnabled(false)

            end
        end
        --当启动禁用Item时候需要重新更新手柄导航信息，否则方向键会移动到置灰的Item
        self:UpdateNavgation()
    end
end

function SettingMain:PosscessRefreshItemValue(InTagName,InItemReturnValue)
    print("SettingMain:PosscessRefreshItemValue InTagName",InTagName,InItemReturnValue)
    local AllChildren = self.SubItemScrollBox:GetAllChildren()
    for k,v in pairs(AllChildren) do
        
        if v ~= nil and v.ParentTag.TagName == InTagName then
            print("SettingMain:PosscessRefreshContent ",v.ParentTag.TagName,InTagName)      
            v:RefreshItemContent(InItemReturnValue)
        end
        
    end
end

function SettingMain:OnReturnClick()
    if self.MvcCtrl and self.viewId then
        MvcEntry:OpenView(ViewConst.BackToLobbyConfirm)
    else
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        TipsManager:ShowTipsUIByTipsId("MainMenu.BackToLobbyConfirm")
    end
end

function SettingMain:OptionSwitch(bSwitch)
    local SettingDataType = self.CurrentFocusWidget.SettingDataType
    if SettingDataType == UE.ESettingDataType.RadioButton then
        local ActiveIndex = bSwitch and  1 or 0
        self.CurrentFocusWidget:RefreshActivateIndex(ActiveIndex)
    
    elseif SettingDataType == UE.ESettingDataType.Progress then
        if bSwitch then
            self.CurrentFocusWidget:AddSlider()
        else
            self.CurrentFocusWidget:SubSlider()
        end
    elseif  SettingDataType == UE.ESettingDataType.MultipleChoice then
        if bSwitch then
            self.CurrentFocusWidget:OnChangeIndex_Add()
        else
            self.CurrentFocusWidget:OnChangeIndex_Sub()
        end
    end

end

function SettingMain:GamepadSelectItem()
    local SettingDataType = self.CurrentFocusWidget.SettingDataType
    if SettingDataType ==  UE.ESettingDataType.ListItem then
        self.CurrentFocusWidget.SettingComboBox:OnClicked()
    end
end

function SettingMain:OnGamepadFocusChange(InFocuseWidget)
    if InFocuseWidget then
        self.CurrentFocusWidget = InFocuseWidget
        self.SubItemScrollBox:ScrollWidgetIntoView(InFocuseWidget)
    end
end

function SettingMain:OnGamepadFocusItemKeyDown(InGeometry,InKeyEvent)
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if not self.CurrentFocusWidget then return end

    if PressKey == self.GamepadSwitchLeft then
        self:OptionSwitch(false)
    elseif PressKey == self.GamepadSwitchRight then
        self:OptionSwitch(true)
    elseif PressKey == self.GamepadSelect then
        self:GamepadSelectItem()
    end
end

return SettingMain