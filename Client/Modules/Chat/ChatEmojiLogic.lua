--[[
    聊天 - 选择表情面板
]]

local class_name = "ChatEmojiLogic"
ChatEmojiLogic = ChatEmojiLogic or BaseClass(nil, class_name)


function ChatEmojiLogic:OnInit()
    self.ChatEmojiModel = MvcEntry:GetModel(ChatEmojiModel)
    self.InputFocus = true
    self.BindNodes= {
		{ UDelegate = self.View.PreBtn.GUIButton.OnClicked,				    Func = Bind(self,self.OnTurnPage,-1) },
		{ UDelegate = self.View.NextBtn.GUIButton.OnClicked,				    Func = Bind(self,self.OnTurnPage,1) },
		{ UDelegate = self.View.WBP_ReuseList_Emoji_Group.OnUpdateItem,				    Func = Bind(self,self.OnUpdateSeriesItem) },
		{ UDelegate = self.View.WBP_ReuseList_Emoji.OnUpdateItem,				    Func = Bind(self,self.OnUpdateEmojiItem) },
	
    }

    self.MsgList = {
    }

    self.Index2SeriesWidget = {}
    self.SelectSeriesId = nil
    self.SelectSeriesIndex = nil
    -- 红点列表
    self.RedDotWidgetList = {}
end

function ChatEmojiLogic:OnShow()

end

function ChatEmojiLogic:OnHide()
    self.Index2SeriesWidget = {}
    self.SelectSeriesId = nil
    self.SelectSeriesIndex = nil
end

function ChatEmojiLogic:UpdateUI()
   self:UpdateSeriesList()
end

-- 更新系列列表
function ChatEmojiLogic:UpdateSeriesList()
    self.EmojiShowList = self.ChatEmojiModel:GetEmojiShowList()
    self.SeriesShowList = {}
    for SeriesId,_ in pairs(self.EmojiShowList) do
        self.SeriesShowList[#self.SeriesShowList + 1] = tonumber(SeriesId)
    end
    self.View.WBP_ReuseList_Emoji_Group:Reload(#self.SeriesShowList)
end

-- 更新系列Item
function ChatEmojiLogic:OnUpdateSeriesItem(_,Widget,I)
    local Index = I + 1
    self.Index2SeriesWidget[Index] = Widget
    local SeriesId = self.SeriesShowList[Index]
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ChatEmojiSeriesCfg, SeriesId)
    if Cfg then
        Widget.Btn_Group_Item.OnClicked:Clear()
        Widget.Btn_Group_Item.OnClicked:Add(self.View, Bind(self,self.OnSelectSeries,Index))
        CommonUtil.SetBrushFromSoftObjectPath(Widget.Img_Icon_Emoji, Cfg[Cfg_ChatEmojiSeriesCfg_P.IconPath])

        -- 绑定页签红点
        local RedDotKey = SeriesId == 1 and "ChatEmojiAllTab" or "ChatEmojiTab_"
        local RedDotSuffix = SeriesId == 1 and "" or tostring(SeriesId)
        self:RegisterRedDot(Widget, RedDotKey, RedDotSuffix)
        -- 默认选中第一个
        if not self.SelectSeriesIndex and Index == 1 then
            self:OnSelectSeries(Index)
        end
    end
end

-- 选中系列
function ChatEmojiLogic:OnSelectSeries(Index)
    if self.SelectSeriesIndex and self.Index2SeriesWidget[self.SelectSeriesIndex] then
        self.Index2SeriesWidget[self.SelectSeriesIndex]:RemoveActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.SELECT)
    end
    local SeriesId = self.SeriesShowList[Index]
    local Widget = self.Index2SeriesWidget[Index]
    if not Widget then
        CError(StringUtil.Format("OnSelectSeries Widget Error For Index = "..Index))
        return
    end
    Widget:AddActiveWidgetStyleFlags(CommonConst.BTN_STYLE_FLAGS.SELECT)
    self.SelectSeriesId = SeriesId
    self.SelectSeriesIndex = Index
    self:UpdateEmojiList()

    self:InteractRedDot(Widget)
end

-- 点击切换上/下一系列
function ChatEmojiLogic:OnTurnPage(Change)
    if not self.SelectSeriesIndex then
        CError("self.SelectSeriesIndex Error for turn page!!")
        return
    end
    local NewIndex = self.SelectSeriesIndex + Change
    if NewIndex > #self.SeriesShowList then
        NewIndex = #self.SeriesShowList
    elseif NewIndex < 1 then
        NewIndex = 1
    end
    if NewIndex ~= self.SelectSeriesIndex then
        self:OnSelectSeries(NewIndex)
    end
end

-- 刷新展示的表情列表
function ChatEmojiLogic:UpdateEmojiList()
    if not self.SelectSeriesId then
        CError("UpdateEmojiList SelectSeriesId Error !!")
        return
    end
    if not self.EmojiShowList[self.SelectSeriesId] or #self.EmojiShowList[self.SelectSeriesId] == 0 then
        CError("UpdateEmojiList Emoji List Error For SeriesId = "..tostring(self.SelectSeriesId))
        return
    end
    local EmojiList = self.EmojiShowList[self.SelectSeriesId]
    self.View.WBP_ReuseList_Emoji:Reload(#EmojiList)
end

-- 更新展示的表情item
function ChatEmojiLogic:OnUpdateEmojiItem(_,Widget,I)
    if not self.SelectSeriesId then
        CError("OnUpdateEmojiItem SelectSeriesId Error !!")
        return
    end
    local Index = I + 1
    local EmojiList = self.EmojiShowList[self.SelectSeriesId]
    if EmojiList and EmojiList[Index] then
        local EmojiId = EmojiList[Index]
        MvcEntry:GetCtrl(ChatCtrl):SetEmojiImg(EmojiId,Widget.Img_Icon_Emoji)
        self:RegisterRedDot(Widget, "ChatEmojiItem_", EmojiId)
        Widget.Btn_Group_Item.OnClicked:Clear()
        Widget.Btn_Group_Item.OnClicked:Add(self.View, Bind(self,self.OnSelectEmoji,EmojiId, Widget))

        Widget.Btn_Group_Item.OnHovered:Clear()
        Widget.Btn_Group_Item.OnHovered:Add(self.View, Bind(self,self.OnHoverEmoji,EmojiId, Widget))
    end
end

-- 选中表情
function ChatEmojiLogic:OnSelectEmoji(EmojiId, Widget)
    self.ChatEmojiModel:DispatchType(ChatEmojiModel.DO_SEND_EMOJI,EmojiId)
    self:InteractRedDot(Widget)
end

-- Hover表情
function ChatEmojiLogic:OnHoverEmoji(EmojiId, Widget)
    self:InteractRedDot(Widget, RedDotModel.Enum_RedDotTriggerType.Hover)
end

-- 绑定红点
function ChatEmojiLogic:RegisterRedDot(Widget, RedDotKey, RedDotSuffix)
    if Widget and Widget.WBP_RedDotFactory then
        if not self.RedDotWidgetList[Widget] then
            self.RedDotWidgetList[Widget] = UIHandler.New(self, Widget.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        else 
            self.RedDotWidgetList[Widget]:ChangeKey(RedDotKey, RedDotSuffix)
        end   
    end
end

-- 红点触发逻辑
function ChatEmojiLogic:InteractRedDot(Widget, TriggerType)
    TriggerType = TriggerType and TriggerType or RedDotModel.Enum_RedDotTriggerType.Click
    if self.RedDotWidgetList[Widget] then
        self.RedDotWidgetList[Widget]:Interact(TriggerType)
    end
end

return ChatEmojiLogic
