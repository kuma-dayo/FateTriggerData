---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 自建房房间条目信息
--- Created At: 2023/05/30 17:53
--- Created By: 朝文
---

require("Client.Modules.CustomRoom.CustomRoomList.CustomRoomListModel")

local class_name = "CustomRoomListItemMdt"
---@class CustomRoomListItemMdt
local CustomRoomListItemMdt = BaseClass(nil, class_name)
CustomRoomListItemMdt.Enum_TextColor = {
    NotAvailable    = UIHelper.ToSlateColor_LC(UE.FLinearColor(0.91, 0.86, 0.73, 0.3)), --房间不可用（已满、游戏中）
    SelectedStyle   = UIHelper.ToSlateColor_LC(UE.FLinearColor(0.01, 0.01, 0.02, 1)),   --选中
    NormalStyle     = UIHelper.ToSlateColor_LC(UE.FLinearColor(0.91, 0.86, 0.73, 1)),   --正常
}
CustomRoomListItemMdt.Enum_BgStyle = {
    Normal          = 0, --等待中
    Selected        = 1, --已选中
    NotAvailable    = 2  --游戏中
}
CustomRoomListItemMdt.Enum_RoomStateString = {
    [CustomRoomListModel.Enum_RoomState.Idle]         = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Waiting")), 
    [CustomRoomListModel.Enum_RoomState.Warmup]       = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Inthegame")), 
    [CustomRoomListModel.Enum_RoomState.InBattle]     = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Inthegame")), 
    [CustomRoomListModel.Enum_RoomState.Settlement]   = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Beinthesettlement")), 
    [CustomRoomListModel.Enum_RoomState.Recycle]      = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Recovering"))
}
CustomRoomListItemMdt.Enum_RoomModString = {
    [CustomRoomListModel.Enum_RoomMod.Single]         = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_singlerow")),
    [CustomRoomListModel.Enum_RoomMod.Double]         = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_doublerow")),
    [CustomRoomListModel.Enum_RoomMod.Clone]          = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Multi")),
    [CustomRoomListModel.Enum_RoomMod.Four]           = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Sipai")),
}

function CustomRoomListItemMdt:OnInit()
    self.Data = nil
    
    self.BindNodes = {
        { UDelegate = self.View.Button_Select.OnClicked,	Func = Bind(self, self.OnClicked_Select) },
        { UDelegate = self.View.Button_Select.OnHovered,	Func = Bind(self, self.OnnHovered_Select) },
        { UDelegate = self.View.Button_Select.OnUnhovered,	Func = Bind(self, self.OnUnhovered_Select) },
        { UDelegate = self.View.Button_Select.OnPressed,	Func = Bind(self, self.OnPressed_Select) },
        { UDelegate = self.View.Button_Select.OnReleased,	Func = Bind(self, self.OnReleased_Select) },
    }

    self.MsgList = {
        {Model = CustomRoomListModel, MsgName = CustomRoomListModel.ON_SELECT_ITEM,	Func = Bind(self, self.ON_SELECT_ITEM_func) },
    }
end

function CustomRoomListItemMdt:OnShow(Param) end
function CustomRoomListItemMdt:OnHide() end

--[[
    Param = { 
        RoomId = 1, 
        MasterInfo = { 
            PlayerId = 13237223429, 
            Name = "微凉", 
        },
        RepeatSelectHero = 0, 
        PlayerNum = 1, 
        TeamType = 1, 
        State = 1,                  CustomRoomListModel.Enum_RoomState
        CfgId = 101,
        GameplayId = 10101,
        LevelId = 1000,
        ModeKey = "101_solo_fpp",
    }
--]]
function CustomRoomListItemMdt:SetData(Param)
    self.Data = Param
end

---更新文字内容、文字颜色及背景颜色
--- 1）房间状态
--- 2）房间名字
--- 3）房间模式
--- 4）房间人数
--- 5）选中状态
function CustomRoomListItemMdt:UpdateView()
    if not self.Data then
        CError("[cw] CustomRoomListItemMdt: trying to UpdateView with illegal Data")
        return
    end
    
    -- 1.房间状态 e.g:等待中、游戏中、游戏中、结算中、回收中
    local roomState = CustomRoomListItemMdt.Enum_RoomStateString[self.Data.State]
    self.View.Text_RoomState:SetText(StringUtil.Format(roomState))
    
    -- 2.房间名字 e.g:百里奚的房间
    local roomName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_sroom"), self.Data.MasterInfo.Name) 
    self.View.Text_RoomName:SetText(roomName)
    
    -- 3.房间模式 e.g:单排、双排、复选、四排
    local roomMod = CustomRoomListItemMdt.Enum_RoomModString[self.Data.TeamType]
    self.View.Text_RoomMode:SetText(StringUtil.Format(roomMod))
    
    --4.玩家人数 e.g:1/64
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local MaxPlayerNum = MatchModeSelectModel:GetModeEntryCfg_MaxPlayer(self.Data.ModeKey)
    local roomPlayerNum = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"), self.Data.PlayerNum, MaxPlayerNum)
    self.View.Text_PlayerNum:SetText(roomPlayerNum)
    
    --5.选中状态
    self:AutoSelect()
end

---根据数据处理选中相关的状态
function CustomRoomListItemMdt:AutoSelect()
    ---@type CustomRoomListModel
    local CustomRoomListModel = MvcEntry:GetModel(CustomRoomListModel)
    local CurSelRoomId = CustomRoomListModel:GetCurSelRoomInfo_RoomId()
    if CurSelRoomId == self.Data.RoomId then
        self:Select()
    else
        self:UnSelect()
    end
end

---封装一个函数统一处理文字颜色
---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self CustomRoomListItemMdt
---@param targetColor userdata FSlateColor 目标颜色
local function _ChangeTextColor(self, targetColor)
    self.View.Text_RoomState:SetColorAndOpacity(targetColor)
    self.View.Text_RoomName:SetColorAndOpacity(targetColor)
    self.View.Text_RoomMode:SetColorAndOpacity(targetColor)
    self.View.Text_PlayerNum:SetColorAndOpacity(targetColor)
end

---选中
function CustomRoomListItemMdt:Select()
    local TextColor, BgIndex

    ---@type CustomRoomListModel
    local CustomRoomListModel = MvcEntry:GetModel(CustomRoomListModel)
    local IsFull = CustomRoomListModel:IsRoomPlayerFull(self.Data.RoomId)
    local IsStateInIdle = CustomRoomListModel:IsRoomState_Idle(self.Data.RoomId)
    
    --不可用
    if IsFull or not IsStateInIdle then
        TextColor = CustomRoomListItemMdt.Enum_TextColor.NotAvailable
        BgIndex = CustomRoomListItemMdt.Enum_BgStyle.NotAvailable
    --可用选中
    else
        TextColor = CustomRoomListItemMdt.Enum_TextColor.SelectedStyle
        BgIndex = CustomRoomListItemMdt.Enum_BgStyle.Selected
    end

    _ChangeTextColor(self, TextColor)
    self.View.BgSwitch:SetActiveWidgetIndex(BgIndex)
end

---未选中
function CustomRoomListItemMdt:UnSelect()
    local TextColor, BgIndex

    ---@type CustomRoomListModel
    local CustomRoomListModel = MvcEntry:GetModel(CustomRoomListModel)
    local IsFull = CustomRoomListModel:IsRoomPlayerFull(self.Data.RoomId)
    local IsStateInIdle = CustomRoomListModel:IsRoomState_Idle(self.Data.RoomId)
    
    --不可用
    if IsFull or not IsStateInIdle then
        TextColor = CustomRoomListItemMdt.Enum_TextColor.NotAvailable
        BgIndex = CustomRoomListItemMdt.Enum_BgStyle.NotAvailable
    --可用未选中
    else
        TextColor = CustomRoomListItemMdt.Enum_TextColor.NormalStyle
        BgIndex = CustomRoomListItemMdt.Enum_BgStyle.Normal
    end

    _ChangeTextColor(self, TextColor)
    self.View.BgSwitch:SetActiveWidgetIndex(BgIndex)
end

-------------------------------------------------------- 按钮相关 -------------------------------------------------------- 

function CustomRoomListItemMdt:OnClicked_Select()
    if not self.Data then CError("[cw] room data is nil, cannot click") return end

    ---@type CustomRoomListModel
    local CustomRoomListModel = MvcEntry:GetModel(CustomRoomListModel)
    local IsStateInIdleOrWarmup = CustomRoomListModel:IsRoomState_Idle(self.Data.RoomId) or CustomRoomListModel:IsRoomState_Warmup(self.Data.RoomId)    
    if not IsStateInIdleOrWarmup then UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Thebattlehasbegun")) return end
    
    local IsFull = CustomRoomListModel:IsRoomPlayerFull(self.Data.RoomId)
    if IsFull then UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomList_Roomsizelimit")) return end
    
    CustomRoomListModel:SetCurSelRoomInfo(self.Data)    
end

function CustomRoomListItemMdt:OnnHovered_Select()  end
function CustomRoomListItemMdt:OnUnhovered_Select() end
function CustomRoomListItemMdt:OnPressed_Select()   end
function CustomRoomListItemMdt:OnReleased_Select()  end

------------------------------------------------------ 按钮相关 end ------------------------------------------------------

---当选中的房间数据变动时，自动变换选中状态
function CustomRoomListItemMdt:ON_SELECT_ITEM_func()
    self:AutoSelect()
end

return CustomRoomListItemMdt
