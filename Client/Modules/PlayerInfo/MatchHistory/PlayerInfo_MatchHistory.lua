---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 个人空间，历史战绩页面
--- Created At: 2023/08/04 17:13
--- Created By: 朝文
---

local class_name = "PlayerInfo_MatchHistory"
---@class PlayerInfo_MatchHistory
local PlayerInfo_MatchHistory = BaseClass(nil, class_name)

function PlayerInfo_MatchHistory:OnInit()
    self._isFirstTimeGetData = true
    
    self.MsgList = {
        {Model = PlayerInfo_MatchHistoryModel, MsgName = PlayerInfo_MatchHistoryModel.ON_CHANGED,                   Func = self.ON_MATCH_HISTORY_CHANGED_func},
        {Model = PlayerInfo_MatchHistoryModel, MsgName = PlayerInfo_MatchHistoryModel.ON_GAME_DETAIL_RECORD_GOT,    Func = self.ON_GAME_DETAIL_RECORD_GOT_func},
    }
end

function PlayerInfo_MatchHistory:OnShow(TargetPlayerId)
    self.PlayerId = TargetPlayerId
    self._Widget2MatchHistoryItem = {}
    self.View.WBP_ReuseListEx.OnUpdateItem:Add(self.View, Bind(self, self.OnMatchHistoryItemUpdate))
    self.View.WBP_ReuseListEx.OnPreUpdateItem:Add(self.View, Bind(self, self.OnMatchHistoryItemPreUpdate))
    self.View.WBP_ReuseListEx.ScrollBoxList.OnUserScrolled:Add(self.View, Bind(self, self.OnMatchHistoryItemScrolled))

    ---@type PlayerInfo_MatchHistoryCtrl
    local PlayerInfo_MatchHistoryCtrl = MvcEntry:GetCtrl(PlayerInfo_MatchHistoryCtrl)
    ---@type PlayerInfo_MatchHistoryModel
    local PlayerInfo_MatchHistoryModel = MvcEntry:GetModel(PlayerInfo_MatchHistoryModel)
    if PlayerInfo_MatchHistoryModel:GetIsGotAllMatchHistory() then
        self:_UpdateHistoryList()
    else
        self:_UpdateHistoryList()
        ---@type SeasonModel
        local SeasonModel = MvcEntry:GetModel(SeasonModel)
        PlayerInfo_MatchHistoryCtrl:SendRecordsReq(PlayerInfo_MatchHistoryModel:GetLength(), SeasonModel:GetCurrentSeasonId(), self.PlayerId)
    end
end

function PlayerInfo_MatchHistory:OnHide()
    self.View.WBP_ReuseListEx.OnUpdateItem:Clear()
    self.View.WBP_ReuseListEx.ScrollBoxList.OnUserScrolled:Clear()

    if self.LoadTimer then
        Timer.RemoveTimer(self.LoadTimer)
        self.LoadTimer = nil
    end
end

function PlayerInfo_MatchHistory:SetData(Param)
end

--region WBP_ReuseListEx

function PlayerInfo_MatchHistory:_UpdateHistoryList()
    ---@type PlayerInfo_MatchHistoryModel
    local PlayerInfo_MatchHistoryModel = MvcEntry:GetModel(PlayerInfo_MatchHistoryModel)
    self.View.WBP_ReuseListEx:Reload(PlayerInfo_MatchHistoryModel:GetLength() + 1)       --额外增加一个item用来显示文字

    --第一次加载战绩，需要滚动到顶部
    if self._isFirstTimeGetData then
        if PlayerInfo_MatchHistoryModel:GetLength() == 0 then return end
        self:InsertTimer(Timer.NEXT_FRAME, function()
            self.View.WBP_ReuseListEx:ScrollToStart()
            self._isFirstTimeGetData = false
        end)
    end
end

---在更新之前，确认使用哪一种蓝图
function PlayerInfo_MatchHistory:OnMatchHistoryItemPreUpdate(_, Index)
    ---@type PlayerInfo_MatchHistoryModel
    local PlayerInfo_MatchHistoryModel = MvcEntry:GetModel(PlayerInfo_MatchHistoryModel)
    
    --默认文字
    if Index == PlayerInfo_MatchHistoryModel:GetLength() then
            self.View.WBP_ReuseListEx:ChangeItemClassForIndex(Index, "")        
    else
        local FixedIndex = Index + 1
        local Data = PlayerInfo_MatchHistoryModel:GetDataList()[FixedIndex]
        -- 自建房的levelId为0，取不出modeId，和后端商量改成直接从后端给modeId。 @chenyishui
        if Data and Data.GeneralData then
            local LevelId = Data.GeneralData.GameplayCfg.LevelId
            ---@type MatchModeSelectModel
            local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
            -- local ModeId = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId)
            local ModeId = Data.GeneralData.GameplayCfg.ModeId or MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId)
            local ModeType = MatchModeSelectModel:GetModeEntryCfg_ModeType(ModeId)
            self.View.WBP_ReuseListEx:ChangeItemClassForIndex(Index, ModeType)        
        else
            CError(" PlayerInfo_MatchHistory:OnMatchHistoryItemPreUpdate FixedIndex = " .. tostring(FixedIndex))
        end 
    end
end

function PlayerInfo_MatchHistory:_GetOrCreateReuseMatchHistoryItem(Widget, LuaClass)    
    local Item = self._Widget2MatchHistoryItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require(LuaClass))
        self._Widget2MatchHistoryItem[Widget] = Item
    end

    return Item.ViewInstance
end

function PlayerInfo_MatchHistory:OnMatchHistoryItemUpdate(_, Widget, Index)    
    local FixedIndex = Index + 1

    ---@type PlayerInfo_MatchHistoryModel
    local PlayerInfo_MatchHistoryModel = MvcEntry:GetModel(PlayerInfo_MatchHistoryModel)
    if Index == PlayerInfo_MatchHistoryModel:GetLength() then
        if Widget then
            self.LastTextItem = Widget

            --这里判断一下，如果还没有加载所有数据，则显示下来加载数据
            if not PlayerInfo_MatchHistoryModel:GetIsGotAllMatchHistory() then
                Widget.Text:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_Dropdowntoloadmoreda")))
            --否则就显示无更多数据
            else
                Widget.Text:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_Alldatahasbeenloaded")))
            end 
        end
        return
    end
    
    local Data = PlayerInfo_MatchHistoryModel:GetDataList()[FixedIndex]
    if Data == nil then CLog("[cw] PlayerInfo_MatchHistory:OnMatchHistoryItemUpdate Data is nil")  return end
    if Data.GeneralData then
        local LevelId = Data.GeneralData.GameplayCfg.LevelId
        ---@type MatchModeSelectModel
        local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
        -- 自建房的levelId为0，取不出modeId，和后端商量改成直接从后端给modeId。 @chenyishui
        local ModeId = Data.GeneralData.GameplayCfg.ModeId or MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId)
        local ModeType = MatchModeSelectModel:GetModeEntryCfg_ModeType(ModeId)
        local TargetItem = self:_GetOrCreateReuseMatchHistoryItem(Widget, PlayerInfo_MatchHistoryModel.Enum_HistoryItemLuaPath[ModeType])   
        
        if TargetItem == nil then return end
        Data.FixedIndex = FixedIndex
        Data.CurPlayerId = self.PlayerId
        TargetItem:SetData(Data)
        TargetItem:UpdateView() 
    else
        CError(" PlayerInfo_MatchHistory:OnMatchHistoryItemUpdate FixedIndex = " .. tostring(FixedIndex))
    end
end

function PlayerInfo_MatchHistory:OnMatchHistoryItemScrolled()
    local Offset = self.View.WBP_ReuseListEx:GetScrollOffset()
    local MaxOffset = self.View.WBP_ReuseListEx:GetScrollOffsetOfEnd()
    if Offset ~= MaxOffset then return end

    if self.LoadTimer then return end
    ---@type PlayerInfo_MatchHistoryModel
    local PlayerInfo_MatchHistoryModel = MvcEntry:GetModel(PlayerInfo_MatchHistoryModel)
    self.LoadTimer = Timer.InsertTimer(PlayerInfo_MatchHistoryModel.Const.DefaultSendReqHistoryListDelay, function()
        if self.LoadTimer then
            Timer.RemoveTimer(self.LoadTimer)
            self.LoadTimer = nil
        end
    end)

    --判断是否已经拉取了所有的历史战绩历史，如果已经拉完了，则需要看一下是否有必要重拉
    ---@type SeasonModel
    local SeasonModel = MvcEntry:GetModel(SeasonModel)
    ---@type PlayerInfo_MatchHistoryCtrl
    local PlayerInfo_MatchHistoryCtrl = MvcEntry:GetCtrl(PlayerInfo_MatchHistoryCtrl)
    if PlayerInfo_MatchHistoryModel:GetIsGotAllMatchHistory() then
        --拉完了，但是满足再次拉取一次数据的条件
        if PlayerInfo_MatchHistoryModel:GetIsAvaliableForNextReq() then
            if self.LastTextItem then
                self.LastTextItem.Text:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_Dataloading"))) 
            end
            PlayerInfo_MatchHistoryCtrl:SendRecordsReq(0, SeasonModel:GetCurrentSeasonId(), self.PlayerId)
        --拉完了,且不满足下一次拉取间隔时间就不用再拉了
        else
            if self.LastTextItem then
                self.LastTextItem.Text:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_Alldatahasbeenloaded")))
            end
        end
        
        return
    end

    PlayerInfo_MatchHistoryCtrl:SendRecordsReq(PlayerInfo_MatchHistoryModel:GetLength(), SeasonModel:GetCurrentSeasonId(), self.PlayerId)

    if self.LastTextItem then
        self.LastTextItem.Text:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_Dataloading")))
    end
end

--endregion WBP_ReuseListEx

function PlayerInfo_MatchHistory:UpdateView(Param)
    CLog("[cw] PlayerInfo_MatchHistory:UpdateView()")
end

function PlayerInfo_MatchHistory:ON_MATCH_HISTORY_CHANGED_func()
    self:_UpdateHistoryList()
end

function PlayerInfo_MatchHistory:ON_GAME_DETAIL_RECORD_GOT_func(GameId)
    --打开历史记录详情界面
    MvcEntry:OpenView(ViewConst.MatchHistoryDetail,{GameId = GameId})
end

return PlayerInfo_MatchHistory

