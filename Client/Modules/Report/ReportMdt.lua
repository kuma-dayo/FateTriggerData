---
--- Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 举报界面
--- Created At: 2023/08/30 15:29
--- Created By: 朝文
---
local ReportConst = require("Client.Modules.Report.ReportConst")
local class_name = "ReportMdt"
---@class ReportMdt : GameMediator
ReportMdt = ReportMdt or BaseClass(GameMediator, class_name)
ReportMdt.Const = {
    MAX_REPORT_TEXT = 80
}

function ReportMdt:__init()
end

function ReportMdt:OnShow(data) end
function ReportMdt:OnHide() end

-------------------------------------------------------------------------------

---@class ReportObj : UserWidgetBase
local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    ---@type ReportTypeItem[]
    self._Widget2ReportTypeItem = {}
    ---@type ReportTargetItem
    self._Widget2ReportTargetItem = {}
    self._Widget2ReportDetailItem = {}
    
    self.BindNodes = {
        { UDelegate = self.WBP_ReuseList_Tab.OnUpdateItem,				Func = self.OnReportDetailItemUpdate},
        {UDelegate = self.WBP_ReuseList.OnUpdateItem,                   Func = self.OnUpdateItem},
        {UDelegate = self.WBP_CommonPopUp_Bg_L.Button_BGClose.OnClicked,				        Func = self.OnClicked_BGClose},
        --复制UID按钮
        { UDelegate = self.WBP_Btn.GUIButton_Main.OnClicked,            Func = Bind(self, self.OnClick_CopyUID)},
        
        --清空举报文字
        { UDelegate = self.WBP_Clear.GUIButton_Main.OnClicked,          Func = Bind(self, self.OnClick_Clear)},

        { UDelegate = self.GUIButton_Change.Btn_List.OnClicked,                  Func = Bind(self, self.OnClick_ChangeReportTarget)},
    }
    
    self.MsgList = {
        {Model = ReportModel, MsgName = ReportModel.ON_PLAYER_REPORTED, Func = self.ON_PLAYER_REPORTED_fuc},
    }
    
    --头像框
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    ---@type CommonHeadIcon
    self.HeadIcon = UIHandler.New(self, self.WBP_CommonHeadIcon, CommonHeadIcon, 
            {
                PlayerId   = UserModel:GetPlayerId(),
                ClickType  = CommonHeadIcon.ClickTypeEnum.None
            }).ViewInstance

    --取消按钮(提审特殊处理.如果在局内，不显示和不响应快捷键)
    local IsInBattle = MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle)
    local CancelActionMappingKey, CancelCommonTipsID
    if not IsInBattle then
        CancelActionMappingKey = ActionMappings.Escape
        CancelCommonTipsID = CommonConst.CT_ESC
    end
    UIHandler.New(self, self.WCommonBtn_Cancel, WCommonBtnTips,
            {
                OnItemClick = Bind(self, self.OnClicked_CancelBtn),
                TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Report', "Lua_ReportMdt_forgetit_Btn"),
                CommonTipsID = CancelCommonTipsID,
                ActionMappingKey = CancelActionMappingKey,
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            })

    --确定按钮(提审特殊处理.如果在局内，不显示和不响应快捷键)
    local ConfirmActionMappingKey, ConfirmCommonTipsID
    if not IsInBattle then
        ConfirmActionMappingKey = ActionMappings.SpaceBar
        ConfirmCommonTipsID = CommonConst.CT_SPACE
    end
    UIHandler.New(self, self.WCommonBtn_Confirm, WCommonBtnTips,
            {
                OnItemClick = Bind(self, self.OnClicked_ConfirmBtn),
                TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Report', "Lua_ReportMdt_report_Btn"),
                CommonTipsID = ConfirmCommonTipsID,
                ActionMappingKey = ConfirmActionMappingKey,
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            })

    --输入框
    self.InputBox = UIHandler.New(self, self, CommonTextBoxInput,
            {
                InputWigetName = "ContentInput",
                FoucsViewId = ViewConst.Chat,
                SizeLimit = ReportMdt.Const.MAX_REPORT_TEXT,
                OnTextChangedFunc = Bind(self, self.OnTextChangedFunc),
                OnTextCommittedEnterFunc = Bind(self, self.OnEnterFunc),
            }).ViewInstance
    
    --self.Img_PlayerListMask.OnMouseButtonDownEvent:Bind(self, self.OnMouseButtonDown_PlayerListMask)
    --self.WBP_ReuseListReportType.CanvasPanelList.Slot:SetAutoSize(true)
end

--[[
    Param 参考结构
    {
        --【通用】信息
		ReportScene                     = ReportConst.Enum_ReportScene.Chat,            --【必填】举报的场景(用来展示可以显示的举报类型页签)，参考 ReportConst.Enum_ReportScene.InGame|Settlemnet|PersonInfo|Chat
		ReportSceneId                   = GameId,                                       --【局内必填】 当局游戏ID
		ReportDetailScene               = "InGame_[GameId]_[LevelId]_[View]_[TeamType]",--【必填，局内案例】举报场景信息，表示发生举报的玩法。该参数由CP定义，或传入已有的玩法标记信息
										--"Hall_[xxx]"                                  --【必填，大厅案例】举报场景信息，表示发生举报的玩法。该参数由CP定义，或传入已有的玩法标记信息

		DefaultSelectReportPlayerIndex  = 1,                                            --【可选】默认选中的举报玩家索引，默认为1
		ReportPlayers = {                                                               --【必填】可供举报的玩家列表，至少有一名玩家
			[1] = {
				PlayerId = 1,                                                           --【必填】被举报的玩家ID
				PlayerName = "PlayerName"                                               --【必填】被举报的玩家名字
			}
		},

		--【文本信息】下列的信息只有在当ReportType为2（不良信息）时才有效
		ContentCombineType              = ReportConst.Enum_ReportContentCombineType.Text,  --【可选】举报的内容，参考 ReportConst.Enum_ReportContentCombineType
		ContentDetail = {
			TextContent = "xx可乐就是洁厕灵",
			ContentType = ReportConst.Enum_MsgType.WoldwideChannal,
			UrlContent  = "..."
		},

		--【局内】信息
		ReportLocation  = {1, 2, 3},                                                    --【必填】举报地点(Avatar/Avatar盒子 所处的位置) {x,y,z}        
	}
	
]]

function M:OnMouseButtonDown_PlayerListMask(InMyGeometry, InMouseEvent)
    --self.Img_PlayerListMask:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.GUICanvasPanelReportPlayers:SetVisibility(UE.ESlateVisibility.Collapsed)
	return UE.UWidgetBlueprintLibrary.Handled()

end
---不要直接调用，请通过 ReportCtrl 里的接口打开
function M:OnShow(Param,Blackboard)       
    print("ReportMdt >> OnShow")
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then

        local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(LocalPC)
        LocalPC.bShowMouseCursor = true
        self:SetFocus(true)



        local ReportPlayerSelector = UE.FGenericBlackboardKeySelector()
        ReportPlayerSelector.SelectedKeyName ="PreInputMode"
        local PreInputMode ,bPreInputMode =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(Blackboard,ReportPlayerSelector)
        self.PreInputMode = PreInputMode
        ReportPlayerSelector.SelectedKeyName ="ReportPlayerId"
        local ReportPlayerId ,bFindReportPlayerId =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(Blackboard,ReportPlayerSelector)
        ReportPlayerSelector.SelectedKeyName ="ReportPlayerName"
        local ReportPlayerName ,bFindReportPlayerName =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(Blackboard,ReportPlayerSelector)
        ReportPlayerSelector.SelectedKeyName ="GameId"
        local GameId ,bFindGameId =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(Blackboard,ReportPlayerSelector)
        ReportPlayerSelector.SelectedKeyName ="ReportLocation"
        local ReportLocation ,bFindReportLocation =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsVector(Blackboard,ReportPlayerSelector)
        ReportPlayerSelector.SelectedKeyName ="ReportTeamId"
        local ReportTeamId ,bFindReportTeamId =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(Blackboard,ReportPlayerSelector)
        ReportPlayerSelector.SelectedKeyName ="PlayerState"
        local PlayerState ,bFindPlayerState =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsObject(Blackboard,ReportPlayerSelector)
        ReportPlayerSelector.SelectedKeyName ="ReportPlayerState"
        local ReportPlayerState ,bFindReportPlayerState =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsObject(Blackboard,ReportPlayerSelector)
        local ReportPlayerId_Int = tonumber(ReportPlayerId)

        self.ReportPlayers={}
        self.ReportPlayers={ --添加被举报者信息
            [1] = {
                PlayerId =ReportPlayerId_Int,  --被举报的玩家ID
                PlayerName = ReportPlayerName  --被举报的玩家名字
            }
        }
        local TeamExSubsystem = UE.UTeamExSubsystem.Get(self)

        local TeamMembers =TeamExSubsystem:GetTeammatePSListByPS(ReportPlayerState) --队伍成员数组

        local SelfPlayerId = PlayerState:GetPlayerId() --举报者的PlayerId
        local ReportPlayerId2 = ReportPlayerState:GetPlayerId()  --被举报者的PlayerId

        local TeamMemberLength = TeamMembers:Length()
        for i = 1, TeamMemberLength do
            local TmpPS = TeamMembers:GetRef(i)
            if TmpPS  then 
                local TmpPlayerId = TmpPS:GetPlayerId() --当前遍历的PlayerId
                if (TmpPlayerId ~=  SelfPlayerId) and (TmpPlayerId ~= ReportPlayerId2) then --如果这个玩家举报者 或者被举报者则跳过
                    table.insert(self.ReportPlayers,{
                        PlayerId = TmpPS:GetPlayerId(),              --【必填】被举报的玩家ID
                        PlayerName = TmpPS:GetPlayerName()  --【必填】被举报的玩家名字
                    })
                end
            end
        end

        self.GameState = UE.UGameplayStatics.GetGameState(self)
        local gameTeamMode = UE.UTeamExSubsystem.Get(self):GetTeamPlayerNumber()
        local TheGameId =  self.GameState.GameId

        local DefaultSelectReportPlayerIndex  = 1

        self.ReportLocation     = {0,0,0} 
        self.ReportScene  =  ReportConst.Enum_ReportScene.InGame               --举报场景
        self.ReportDetailScene ={
            GameId      = TheGameId,                                                   --【必填】当前游戏的GameId
            LevelId     = 1,                                                --【必填】当前游戏的LevelId
            View        = 3,                                                      --【必填】当前游戏的视角(fpp, tpp)
            TeamType    = 4,                                                     --【必填】当前游戏的队伍模式(solo, due, squad)
        }

        self.ReportSceneId = 1
        self.CurSelReportPlayerIndex = DefaultSelectReportPlayerIndex
        self.ContentCombineType = ReportConst.Enum_ReportContentCombineType.Text
        self.ContentDetail  = {
			TextContent = "",
			ContentType = ReportConst.Enum_MsgType.WoldwideChannal,
			UrlContent  = "..."
		}


    else
            --0.缓存数据
        self.ReportScene        = Param.ReportScene                 --举报场景
        self.ReportDetailScene  = Param.ReportDetailScene           --举报场景信息
        self.ReportSceneId      = Param.ReportSceneId or ""         --【局内】GameId
        self.ReportLocation     = Param.ReportLocation              --【局内】举报地点
        self.ReportPlayers      = Param.ReportPlayers               --被举报的玩家列表
        self.CurSelReportPlayerIndex = Param.DefaultSelectReportPlayerIndex or 1    --选中的玩家索引
        self.ContentCombineType = Param.ContentCombineType          --文本类型
        self.ContentDetail      = Param.ContentDetail               --文本类型细节

        --CLog("[cw] self.ReportScene: " .. tostring(self.ReportScene))
        --CLog("[cw] self.ReportDetailScene: " .. tostring(self.ReportDetailScene))
        --CLog("[cw] self.ReportSceneId: " .. tostring(self.ReportSceneId))
        --print_r(self.ReportLocation, "[cw] ====self.ReportLocation")
        --print_r(self.ReportPlayers, "[cw] ====self.ReportPlayers")
        --CLog("[cw] self.CurSelReportPlayerIndex: " .. tostring(self.CurSelReportPlayerIndex))
        --CLog("[cw] self.ContentCombineType: " .. tostring(self.ContentCombineType))
        --print_r(self.ContentDetail, "[cw] ====self.ContentDetail")
    end

    self.WBP_CommonPopUp_Bg_L.TextBlock_Title:SetText(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Report"))
    self.WBP_Common_TabUp_03.LeftSwitchTabIconLeft:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Common_TabUp_03.RightSwitchTabIconRight:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:InitView()
end

---初始化界面，仅在OnShow时候调用
function M:InitView()
    --1.默认隐藏举报对象列表，如果举报列表超过1人，则显示切换按钮
    --self:InitReportPlayers()
    self.GUIButton_Change:SetVisibility(#self.ReportPlayers > 1 and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)

    --2.左侧举报人信息
    self.CurSelPlayerInfo = self.ReportPlayers[1]
    self:UpdateLeftPlayerInfo()

    --3.右侧举报类型标签，默认选中第一条举报类型数据
    ---@type ReportModel
    local ReportModel = MvcEntry:GetModel(ReportModel)
    self.ReportCfg = ReportModel:GetReportCfg(self.ReportScene)
    self.CurSelReportType = self.ReportCfg and self.ReportCfg[1] and self.ReportCfg[1].ReportType
    self:InitReportTypes()

    --4.右侧举报详细条目
    self.CurAvailableReportIds = ReportModel:GetReportCfg(self.ReportScene, self.CurSelReportType)
    self:UpdateReportDetailItems()
    self:UpdateClearBtn(false)
    self.GUICanvasPanelReportPlayers:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_ReuseList:Reload(#self.ReportPlayers)
end

---反复打开界面，例如跳转回来时触发的逻辑
function M:OnRepeatShow(data) end
function M:OnHide()
    self.WBP_Common_TabUp_03.TabItemList:ClearChildren()
    --self.HorizontalBoxReportType:ClearChildren()
    self._Widget2ReportTypeItem = nil
    
    --self.HorizontalBoxReportPlayers:ClearChildren()
    self._Widget2ReportTargetItem = nil
end

---局内关闭触发
function M:OnClose()
    self.ReportDetails = {}
    self.ContentInput:SetText("")

    self.WBP_Common_TabUp_03.TabItemList:ClearChildren()

    --self.HorizontalBoxReportPlayers:ClearChildren()
    self._Widget2ReportTargetItem = {}
    
    --self.HorizontalBoxReportType:ClearChildren()
    self._Widget2ReportTypeItem = {}

   -- self.HorizontalBoxReportPlayers:ClearChildren()
    --self._Widget2ReportTargetItem = {}
end

function M:OnClicked_BGClose()
    self:CloseUI()
end

----------------------------------------- 左侧（被举报玩家头像、名字、UID、可举报玩家列表） -------------------------------------

function M:InitReportPlayers()
    self.GUICanvasPanelReportPlayers:SetVisibility(UE.ESlateVisibility.Collapsed)
    
    local WidgetClass = UE4.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Report/WBP_ReportSelectItemWidget_New.WBP_ReportSelectItemWidget_New")
    for i, ReportPlayer in ipairs(self.ReportPlayers) do
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget, self.HorizontalBoxReportPlayers)
        ---@type ReportTargetItem
        local widget = UIHandler.New(self, Widget, require("Client.Modules.Report.ReportCommponent.ReportTargetItem")).ViewInstance
        self._Widget2ReportTargetItem[i] = widget
        
        widget:SetData(ReportPlayer)
        widget:SetClickCallback(function(Data) self:OnReportTargetItemClicked(i, Data) end)
        widget:UpdateView()

        if self.CurSelReportPlayerIndex == i then
            widget:Select()
        else
            widget:Unselect()
        end
    end
end

---@param Index number 所选的举报对象的索引
---@param Data table 所选的举报对象内的数据信息
function M:OnReportTargetItemClicked(Index, Data)
    CLog("[cw] M:OnReportTargetItemClicked(" .. string.format("%s, %s", Index, Data) .. ")")
    
    self.GUICanvasPanelReportPlayers:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self.Img_PlayerListMask:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:OnReportPlayerChanged(Index)
end
--endregion

---更新左侧玩家信息（头像框、名字、ID）
function M:UpdateLeftPlayerInfo()
    if not self.HeadIcon then return end

    local Data = self.ReportPlayers[self.CurSelReportPlayerIndex]
    if not Data then return end

    self.Text_Name:SetText(Data.PlayerName)
    self.Text_ID:SetText(Data.PlayerId)
    self.HeadIcon:UpdateUI(
            {
                PlayerId = Data.PlayerId,
                CloseOnlineCheck = true,
                CloseAutoCheckFriendShow = true,
                ClickType = CommonHeadIcon.ClickTypeEnum.None
            }
    )
end

---点击复制当前展示的被举报玩家的id
function M:OnClick_CopyUID()
    UE.UGFUnluaHelper.ClipboardCopy(StringUtil.ConvertFText2String(self.Text_ID:GetText()))
    UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Report', "Lua_ReportMdt_Copysucceeded"),3,self)
end

---点击打开可举报玩家列表
function M:OnClick_ChangeReportTarget()
    CLog("[cw] M:OnClick_ChangeReportTarget()")
    self.GUICanvasPanelReportPlayers:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --self.Img_PlayerListMask:SetVisibility(UE.ESlateVisibility.Visible)
end

--------------------------------------------- 右侧（举报类型、举报详细条目、举报文字） -----------------------------------------

--region 举报类型列表

---更新举报类型显示
function M:InitReportTypes()
    for i, reportcfg in ipairs(self.ReportCfg) do
        local WidgetClass = UE4.UClass.Load("/Game/BluePrints/UMG/Components/WBP_CommonTab_NormalItem.WBP_CommonTab_NormalItem")
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget, self.WBP_Common_TabUp_03.TabItemList)
        local widget = UIHandler.New(self, Widget, require("Client.Modules.Report.ReportCommponent.ReportTypeItem")).ViewInstance
        self._Widget2ReportTypeItem[i] = widget

        widget:SetData(reportcfg)
        widget:SetClickCallback(function(ReportType, ReportIds) self:OnReportTypeItemClicked(ReportType, ReportIds) end)
        widget:UpdateView()

        if reportcfg.ReportType == self.CurSelReportType then
            widget:Select()
        else
            widget:Unselect()
        end
        
        local marge = UE.FMargin()
        if i == 1 then
            marge.Right = self.ReportTypeItemPadding
        elseif i == #self.ReportCfg then
            marge.Left = self.ReportTypeItemPadding
        else
            marge.Left = self.ReportTypeItemPadding
            marge.Right = self.ReportTypeItemPadding
        end
        widget.View.Slot:SetPadding(marge)
    end
end

---当举报类型标签被点击的时候
---@param Data
function M:OnReportTypeItemClicked(Data)    
    self:OnReportTypeChange(Data.ReportType)
end
--endregion

--region 举报细节选项
---更新举报子类型显示
function M:UpdateReportDetailItems()
    self.WBP_ReuseList_Tab:Reload(#self.CurAvailableReportIds)
end

---获取或创建一个使用lua绑定的控件
---@return ReportDetailItem
function M:_GetOrCreateReuseReportDetailItem(Widget)
    local Item = self._Widget2ReportDetailItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.Report.ReportCommponent.ReportDetailItem"))
        self._Widget2ReportDetailItem[Widget] = Item
    end
    
    return Item.ViewInstance
end

---更新 WBP_ReuseList_Tab 的函数
---@param Widget userdata 控件
---@param Index number 在lua侧使用需要 +1
function M:OnReportDetailItemUpdate(Widget, Index)
    local FixedIndex = Index + 1
    
    --[[
        ReportId = 1007
    --]]
    local ReportId = self.CurAvailableReportIds[FixedIndex]
    if not ReportId then
        CLog("[cw][ReportMdt] Cannot get Info by FixedIndex: " .. tostring(FixedIndex))
        return
    end
    
	local TargetItem = self:_GetOrCreateReuseReportDetailItem(Widget)
    if not TargetItem then return end

    TargetItem:SetData(ReportId)
    TargetItem:SetClickCallback(function(ReportType, ReportIds) self:OnReportDetailItemClicked(ReportType, ReportIds) end)
    TargetItem:UpdateView()

    TargetItem:Unselect()
end

---当点击举报详细条目
---@param ReportId number 举报条目的ID
function M:OnReportDetailItemClicked(ReportId)
    if self.ReportDetails and self.ReportDetails[ReportId] then
        self:OnReportDetailChange(ReportId, false)    
    else
        self:OnReportDetailChange(ReportId, true)
    end
end
--endregion

function M:UpdateClearBtn(display)
    if display then
        self.ClearPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.ClearPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

--region 输入文字相关
---更新输入文字字数显示
function M:UpdateInputCount()
    local Len = StringUtil.utf8StringLen(self.ReportText)
    self.Text_InputCount:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"), Len, ReportMdt.Const.MAX_REPORT_TEXT))
end

---当输入文字变动时
---@param Str string 新的文字
function M:OnTextChangedFunc(_, Str)
    local len = StringUtil.utf8StringLen(Str)
    if len > ReportMdt.Const.MAX_REPORT_TEXT then
        Str = StringUtil.CutByLength(Str, ReportMdt.Const.MAX_REPORT_TEXT)
        self.ContentInput:SetText(Str)
    end
    self.ReportText = StringUtil.ConvertFText2String(Str)
    self:UpdateInputCount()
    self:UpdateClearBtn(len > 0)
end

---当文字输入完毕
function M:OnEnterFunc()
    CLog("[cw] M:OnEnterFunc()")
    local len = StringUtil.utf8StringLen(self.ReportText)
    self:UpdateClearBtn(len > 0)
end

---点击按钮清空输入的文字
function M:OnClick_Clear()
    self.ReportText = ""
    self.ContentInput:SetText("")
    self:UpdateInputCount()
end
--endregion

------------------------------------------------ 底部（取消按钮、确认按钮） -------------------------------------------------

---点击取消按钮关闭界面
function M:OnClicked_CancelBtn()
    self:CloseUI()
end

---点击取消按钮关闭界面
function M:CloseUI()



    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then

        local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        if self.PreInputMode == 1 then
            UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(LocalPC)
            LocalPC.bShowMouseCursor = true
        elseif self.PreInputMode == 2 then
            UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(LocalPC)
            LocalPC.bShowMouseCursor = true
        elseif self.PreInputMode == 3 then
            UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(LocalPC)
            LocalPC.bShowMouseCursor = false
        end

        local UIManager = UE.UGUIManager.GetUIManager(self)
        -- UIManager:CloseByHandle(self.Handle, false)
        local bClose = UIManager:TryCloseDynamicWidget("UMG_Report")
        -- print("ReportMdt >> CloseUI > bClose=",bClose)
    else
        MvcEntry:CloseView(ViewConst.Report)
    end
end


---举报前检查
function M:_ReportCheck()
    if not self.ReportDetails or not next(self.ReportDetails) then
        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Report', "Lua_ReportMdt_Pleaseselecttherepor")),3,self)
        return false
    end
    
    return true
end

---发送举报
function M:OnClicked_ConfirmBtn()
    print("ReportMdt >>  OnClicked_ConfirmBtn")
    if not self:_ReportCheck() then 
        return
     end
    
    ---@type ReportModel
    local ReportModel = MvcEntry:GetModel(ReportModel)
    local ReportLableList = {}
    for ReportId, bSelect  in pairs(self.ReportDetails) do
        if bSelect then
            table.insert(ReportLableList, ReportModel:GetReportLableByReportID(ReportId))
        end
    end

    local _reportcontent = {}
    for k, v in pairs(self.ReportDetails) do
        table.insert(_reportcontent, {
            type = v,
            content = self.ContentDetail.TextContent or "",
        })
    end

    local SceneDes = ReportModel:GetReportSceneDescByScenesId(self.ReportScene)
    local SubScene = ReportModel:GetReportTypeName(self.CurSelReportType)

    --整理ReportDetail
    --https://bytedance.feishu.cn/docx/Y7SWdWOYKoBDIcxamKdcd3h1nEe
    local _ReportDetail = {
        scene                = self.ReportDetailScene,
        scene_id             = self.ReportSceneId,
        location             = self.ReportLocation,
        report_content       = _reportcontent,
        msg_type             = self.ContentDetail.ContentType,
        content_combine_type = self.ContentCombineType,
        content_url          = self.ContentDetail.UrlContent
    }
    
    ---@type ReportCtrl
    local ReportCtrl = MvcEntry:GetCtrl(ReportCtrl)
    ReportCtrl:SendPlayerReportInfoReq({
        RePlayerId          = self.ReportPlayers[self.CurSelReportPlayerIndex].PlayerId,
        RePlayerName        = self.ReportPlayers[self.CurSelReportPlayerIndex].PlayerName,
        ReportType          = self.CurSelReportType,
        ReportLabelList     = ReportLableList,
        ReportText          = self.ReportText,
        Scene               = self.ReportScene,
        SubScene            = SubScene,
        ReportDetail        = _ReportDetail
    })

    -- UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Report', "Lua_ReportMdt_Thankyouforyourrepor")),3,self)
    -- self:CloseUI()
end

-------------------------------------------------------- 变动 -----------------------------------------------------------

---当被举报的玩家索引发生改变
---@param newReportPlayerIndex number 新的举报玩家信息索引
function M:OnReportPlayerChanged(newReportPlayerIndex)
    if self.CurSelReportPlayerIndex == newReportPlayerIndex then return end
    
    self.CurSelReportPlayerIndex = newReportPlayerIndex

    for index, widget in pairs(self._Widget2ReportTargetItem) do
        if index == self.CurSelReportPlayerIndex then
            widget:Select()
        else
            widget:Unselect()
        end
    end
    
    self:UpdateLeftPlayerInfo()
end

---当举报类型变动时
---@param newReportType number 新的举报类型
function M:OnReportTypeChange(newReportType)
    if self.CurSelReportType == newReportType then return end

    self.CurSelReportType = newReportType
    self.ReportDetails = {}
    ---@type ReportModel
    local ReportModel = MvcEntry:GetModel(ReportModel)
    self.CurAvailableReportIds = ReportModel:GetReportCfg(self.ReportScene, self.CurSelReportType)
    
    for _, ReportTypeItem in pairs(self._Widget2ReportTypeItem) do
        if ReportTypeItem.Data.ReportType == self.CurSelReportType then
            ReportTypeItem:Select()
        else
            ReportTypeItem:Unselect()
        end
    end

    self:UpdateReportDetailItems()
end

---当举报详细条目变动时
---@param ReportId number 变动的举报条目ID
---@param bCheck boolean 需要勾选还是不勾选
function M:OnReportDetailChange(ReportId, bCheck)
    self.ReportDetails = self.ReportDetails or {}
    if bCheck then
        self.ReportDetails[ReportId] = true
    else
        self.ReportDetails[ReportId] = nil
    end

    for _, ReportDetailItem in pairs(self._Widget2ReportDetailItem) do
        ---@type ReportDetailItem
        local Instance = ReportDetailItem.ViewInstance
        if self.ReportDetails[Instance.Data] then
            Instance:Select()
        else
            Instance:Unselect()
        end
    end
end

----------------------------------------------------- 事件相关 -----------------------------------------------------------

---举报成功后
function M:ON_PLAYER_REPORTED_fuc(ReportedPlayerId)
    print("ReportMdt >>  ON_PLAYER_REPORTED_fuc > ReportedPlayerId=",ReportedPlayerId)
    UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Report', "Lua_ReportMdt_Thankyouforyourrepor")),3,self)
    self:CloseUI()
end


function M:OnKeyDown(MyGeometry,InKeyEvent)
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        if PressKey == UE.FName("Escape") then
            self:CloseUI()
            return UE.UWidgetBlueprintLibrary.Handled()
        end
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end



function M:CreateItem(Widget)
    self.ItemWidgetList = self.ItemWidgetList or {}
	local Item = self.ItemWidgetList[Widget]
	if not Item then
		Item = UIHandler.New(self, Widget, require("Client.Modules.Report.ReportCommponent.ReportTargetItem")) --ReportTargetItem
		self.ItemWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end

function M:OnUpdateItem(Widget, Index)
    local FixIndex = Index + 1
    local ItemData = self.ReportPlayers[FixIndex]
    if ItemData == nil then
        return
    end

    local TargetItem = self:CreateItem(Widget)
    if TargetItem == nil then
        return
    end
    TargetItem:SetData(ItemData)
    TargetItem:SetClickCallback(function(Data) self:OnReportTargetItemClicked(FixIndex, Data) end)
    TargetItem:UpdateView()

    self._Widget2ReportTargetItem[FixIndex] = TargetItem
end

return M