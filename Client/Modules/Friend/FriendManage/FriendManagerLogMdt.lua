--[[
    好友管理 - 操作日志界面
]]

local class_name = "FriendManagerLogMdt";
FriendManagerLogMdt = FriendManagerLogMdt or BaseClass(GameMediator, class_name);

function FriendManagerLogMdt:__init()
end

function FriendManagerLogMdt:OnShow(data)
    
end

function FriendManagerLogMdt:OnHide()
end


-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.MsgList = 
    {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.GUIButton_Close_ClickFunc},
        {Model = FriendModel, MsgName = ListModel.ON_DELETED, Func =self.OnFriendDeleted},
        {Model = FriendModel, MsgName = FriendModel.ON_STAR_FLAG_CHANGED, Func =self.OnStarFlagChanged},
        {Model = FriendModel, MsgName = FriendModel.ON_INTIMACY_CHANGED, Func =self.OnIntimacyChanged},
        {Model = FriendOpLogModel, MsgName = FriendOpLogModel.ON_GET_FRIEND_OPLOG, Func =self.OnGetLog},
        {Model = DepotModel, MsgName = ListModel.ON_UPDATED, Func = self.OnDepotItemChanged},

    }

    self.BindNodes = 
    {
        { UDelegate = self.WBP_CommonBtn_Manager.GUIButton_Main.OnClicked,	Func = self.Btn_Manager_ClickFunc },
        { UDelegate = self.WBP_CommonBtn_Gift.GUIButton_Main.OnClicked,	Func = self.Btn_Gift_ClickFunc },
        { UDelegate = self.WBP_ReuseListEx_Log.OnUpdateItem,	Func = self.OnUpdateItem },

	}
    self.FriendModel = MvcEntry:GetModel(FriendModel)
    self.HeadIconCls = {}
    -- self.MaxListSize = self.WBP_ReuseListEx_Log.Slot:GetSize()
     -- 返回
     UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips,
     {
        OnItemClick = Bind(self, self.GUIButton_Close_ClickFunc),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerLogMdt_return"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
     })

     self.GiftItemId = DepotConst.ITEM_ID_FRIEND_INTIMACY
end

function M:OnHide()
    self.HeadIconCls = {}
end

function M:OnShow(PlayerId)
    if not PlayerId then
        CError("FriendManagerLogMdt need a PlayerId !!!",true)
        return
    end
    self:UpdateUI(PlayerId)
end

function M:OnRepeatShow(PlayerId)
    if not PlayerId then
        CError("FriendManagerLogMdt need a PlayerId !!!",true)
        return
    end
    self:UpdateUI(PlayerId)
end

function M:UpdateUI(PlayerId)
    self.PlayerId = PlayerId
    --[[
        message FriendBaseNode
        {
            string  PlayerName  = 1;    // 好友名称
            int64   PlayerId    = 2;    // 好友角色ID
            PlayerState PlayerState = 3; //好友状态
            int64   IntimacyValue= 4;   // 亲密度数值
            bool    StarFlag = 5;       // true 设置星标 false 未设置星标
        }
    ]]
    self.FriendData = self.FriendModel:GetData(self.PlayerId)
    if not self.FriendData then
        CError("FriendManagerLogMdt GetFriendData Error For id = "..self.PlayerId,true)
        return
    end
    self:UpdateIntimacy()
    self:UpdatePlayerInfo(self.WBP_PlayerItem_Self,true)
    self:UpdatePlayerInfo(self.WBP_PlayerItem_Friend)
    self:UpdatePlayTimeAndCount()
    -- 请求刷新一次日志信息
    -- self.WBP_ReuseListEx_Log:SetRenderOpacity(0)
    MvcEntry:GetCtrl(FriendCtrl):SendFriendGetOpLogReq(self.PlayerId)
end

-- 更新亲密度信息
function M:UpdateIntimacy()
    local IntimacyValue = self.FriendData.IntimacyValue or 0
    local IntimacyLevel,_,IntimacyImgPath = self.FriendModel:GetIntimacyImgIcon(IntimacyValue)
    self.Text_level:SetText(IntimacyLevel)
    self.IntimacyLevel = IntimacyLevel
    CommonUtil.SetBrushFromSoftObjectPath(self.Image_Lv,IntimacyImgPath)
    -- 鲜花道具数量
    self.Text_GiftNumber:SetText(MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.GiftItemId))
end

-- 更新玩家基本信息
function M:UpdatePlayerInfo(Widget,IsSelf)
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = IsSelf and UserModel:GetPlayerId() or self.FriendData.PlayerId
    local PlayerName = IsSelf and UserModel:GetPlayerName() or self.FriendData.PlayerName
    -- 头像
    local Param = {
        PlayerId = PlayerId,
        PlayerName = PlayerName,
        CloseOnlineCheck = true,
        FilterOperateList = {CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Manager},
    }
    local HeadIconName =  IsSelf and "Self" or "Friend"
    local HeadIconCls = self.HeadIconCls[HeadIconName]
    if not HeadIconCls then
        HeadIconCls = UIHandler.New(self,Widget.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
        self.HeadIconCls[HeadIconName] = HeadIconCls
    else
        HeadIconCls:UpdateUI(Param)
    end

    -- 名字
    if IsSelf then
        local PlayerNameStr,PlayerNameIdStr = StringUtil.SplitPlayerName(PlayerName,true)
        Widget.LabelPlayerName:SetText(PlayerNameStr)
        Widget.Text_PlayerNameId:SetText(PlayerNameIdStr)
    else
        -- 他人名字需要轮询更新
        local PlayerNameParam = {
            WidgetBaseOrHandler = self,
            TextBlockName = Widget.LabelPlayerName,
            TextBlockId = Widget.Text_PlayerNameId,
            PlayerId = PlayerId,
            DefaultStr = PlayerName,
        }
        MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
    end
    local TextColor = IsSelf and "F5EFAE" or "E9DCBC"
    -- local TheOpacity = IsSelf and 1 or 0.5
    CommonUtil.SetTextColorFromeHex(Widget.LabelPlayerName,TextColor,1)
    -- CommonUtil.SetTextColorFromeHex(Widget.Text_PlayerNameId,TextColor,TheOpacity)
    -- 星标
    local IsShowStar = not IsSelf and self.FriendData.StarFlag
    Widget.StarMark:SetVisibility(IsShowStar and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    -- 段位 TODO 暂无
    -- Widget.RankIcon
end

-- 更新共同游玩时长和次数
function M:UpdatePlayTimeAndCount()
    self.LabelInfoNum_Team:SetText(self.FriendData.PlayCount)
    self.LabelInfoNum_Time:SetText(math.floor(self.FriendData.PlayTime/3600))
end

-- 更新日志列表
function M:RefreshLogList()
    self.LogList = MvcEntry:GetModel(FriendOpLogModel):GetOpLogList(self.PlayerId)
    -- 顶部标题
    if not self.IsLogInit then
        local FirstLog = self.LogList[1]
        if not FirstLog then
            return
        end
        local TimeStr = TimeUtils.GetDateFromTimeStamp(FirstLog.OpTime)
        self.GUITextBlock_Date:SetText(StringUtil.Format(TimeStr))
        self.IsLogInit = true
    end
    self.WBP_ReuseListEx_Log:Reload(#self.LogList)
    self.WBP_ReuseListEx_Log:ScrollToEnd()
end

-- function M:AdjustListPos()
--     self.WBP_ReuseListEx_Log.CanvasPanelList:ForceLayoutPrepass()
--     local ActualHeight = self.WBP_ReuseListEx_Log.CanvasPanelList:GetDesiredSize().Y
--     local MaxHeight = self.MaxListSize.Y
--     local OffSet = UE.FVector2D(0,0)
--     if ActualHeight < MaxHeight then
--         OffSet.Y =  (MaxHeight - ActualHeight)/2
--     end
--     self.WBP_ReuseListEx_Log.Slot:SetPosition(OffSet)
--     self.WBP_ReuseListEx_Log:SetRenderOpacity(1)
-- end

function M:OnUpdateItem(Widget, I)
	local Index = I + 1
    local LogData = self.LogList[Index]
    if not LogData then
        CError("FriendManagerLogMdt OnUpdateItem GetData Error!! Index = "..Index,true)
        return
    end
    local TimeStr = TimeUtils.GetDateFromTimeStamp(LogData.OpTime)
    local LogStr = LogData.LogStr
    Widget.GUITextBlock_Date:SetText(StringUtil.Format(TimeStr))
    Widget.RichText_Content:SetText(StringUtil.Format(LogStr))
    local IsLast = Index == #self.LogList
    Widget.Image_Now:SetVisibility(IsLast and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    Widget.Image_Nor:SetVisibility(IsLast and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    Widget.Image_Line:SetVisibility(IsLast and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
end

-- 收到日志信息
function M:OnGetLog(TargetPlayerId)
    if TargetPlayerId ~= self.PlayerId then
        return
    end
    self:RefreshLogList()
end

-- 星标状态改变
function M:OnStarFlagChanged(PlayerId)
    if PlayerId ~= self.FriendData.PlayerId then
        return
    end
    self.FriendData = self.FriendModel:GetData(self.PlayerId)
    self.WBP_PlayerItem_Friend.StarMark:SetVisibility(self.FriendData.StarFlag and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-- 删除好友
function M:OnFriendDeleted(keyList)
    local IsContainThisFriend = false
    for _,PlayerId in ipairs(keyList) do
        if PlayerId == self.FriendData.PlayerId then
            IsContainThisFriend = true
            break
        end
    end
    if IsContainThisFriend then
        self:DoClose()
    end
end

-- 打开界面弹窗
function M:Btn_Manager_ClickFunc()
    local Param = {
        ActionBtnTypeList = {
            [1] = {OperateStr = self.FriendData.StarFlag and G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerLogMdt_Cancelthestarsign") or G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerLogMdt_Addstarmark"),Func = Bind(self,self.OnClick_SetStarFlag)},
            [2] = {OperateStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerLogMdt_Removefriends"),Func = Bind(self,self.OnClick_DeleteFriend)},
            --[3] = {OperateStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerLogMdt_report"),Func = Bind(self,self.OnClick_Report)},
            [3] = {OperateStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerLogMdt_blocksbonasocialnetw"),Func = Bind(self,self.OnClick_AddBlackList)},
        },
        FocusWidget = self.WBP_CommonBtn_Manager
    }
    MvcEntry:OpenView(ViewConst.CommonBtnOperate, Param)
end

-- 点击设置/取消星标
function M:OnClick_SetStarFlag()
    MvcEntry:GetCtrl(FriendCtrl):SendFriendSetStarReq(self.FriendData.PlayerId, not self.FriendData.StarFlag)
end

-- 删除好友
function M:OnClick_DeleteFriend()
    local msgParam = {
		describe = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerLogMdt_Areyousureyouwanttoh"),
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
                MvcEntry:GetCtrl(FriendCtrl):SendProto_FriendDeleteReq(self.FriendData.PlayerId)
            end
		}
	}
    UIMessageBox.Show(msgParam)
end

-- 举报
function M:OnClick_Report()
    UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerLogMdt_Functionisnotopen"))
end

-- 拉黑
function M:OnClick_AddBlackList()
    local msgParam = {
		describe = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerLogMdt_Afterblackingoutyouw"),
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
                MvcEntry:GetCtrl(FriendCtrl):SendFriendSetPlayerBlackReq(self.FriendData.PlayerId,true)
            end
		}
	}
    UIMessageBox.Show(msgParam)
end

-- 赠送鲜花
function M:Btn_Gift_ClickFunc()
    local DepotModel = MvcEntry:GetModel(DepotModel)
    local GiftItemCount = DepotModel:GetItemCountByItemId(self.GiftItemId)
    if GiftItemCount > 0 then
        local Param = {
            ItemId = self.GiftItemId,
            EnterBtnText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_DepotMainMdt_gift"),
            ExtraInfo = {
                TargetPlayerId = self.FriendData.PlayerId
            }
        }
        MvcEntry:OpenView(ViewConst.ItemUsePop,Param)
    else
        local ItemName = DepotModel:GetItemName(self.GiftItemId)
        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Friend","Lua_FriendManagerLogMdt_GiftItemNotEnough"),ItemName))
    end
end

-- 道具数量变化
function M:OnDepotItemChanged()
    self.Text_GiftNumber:SetText(MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.GiftItemId))
end

-- 亲密度变化
function M:OnIntimacyChanged()
    local IntimacyValue = self.FriendData.IntimacyValue or 0
    local IntimacyLevel = self.FriendModel:GetIntimacyImgIcon(IntimacyValue) 
    local IsLevelChanged = self.IntimacyLevel ~= IntimacyLevel
    self:UpdateIntimacy()
    if IsLevelChanged then
        -- 等级变化重新请求日志
        MvcEntry:GetCtrl(FriendCtrl):SendFriendGetOpLogReq(self.PlayerId)
    end
end

--关闭界面
function M:DoClose()
    MvcEntry:CloseView(self.viewId)
    return true
end

-- 点击关闭
function M:GUIButton_Close_ClickFunc()
    self:DoClose()
end

return M