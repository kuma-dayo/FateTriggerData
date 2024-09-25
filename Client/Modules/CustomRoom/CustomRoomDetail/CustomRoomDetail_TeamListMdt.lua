---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 自建房房间详情内的单个队伍列表控件
--- Created At: 2023/06/13 14:50
--- Created By: 朝文
---

local class_name = "CustomRoomDetailTeamListMdt"
---@class CustomRoomDetailTeamListMdt
local CustomRoomDetailTeamListMdt = BaseClass(nil, class_name)

function CustomRoomDetailTeamListMdt:OnInit()
    self.Data = {}
    self.TeamIndex = nil
    self.MaxTeamPlayerNum = nil
end

function CustomRoomDetailTeamListMdt:OnShow()
    self._Widget2TeammateItem = {}
    self.View.WBP_ReuseList_Teammate.OnUpdateItem:Add(self.View, Bind(self, self.OnTeammateItemUpdate))

    --设置ScrollBox不会响应滑轮
    self.View.WBP_ReuseList_Teammate.ScrollBoxList:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.WBP_ReuseList_Teammate.ScrollBoxList.ConsumeMouseWheel = UE.EConsumeMouseWheel.Never
end

function CustomRoomDetailTeamListMdt:OnHide()
    self.View.WBP_ReuseList_Teammate.OnUpdateItem:Clear()
end

---获取或创建一个使用lua绑定的控件
---@return CustomRoomDetailTeamListTeammateMdt
function CustomRoomDetailTeamListMdt:_GetOrCreateReuseTeammateItem(Widget)
    local Item = self._Widget2TeammateItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.CustomRoom.CustomRoomDetail.CustomRoomDetail_TeamListTeammateMdt"))
        self._Widget2TeammateItem[Widget] = Item
    end
    
    return Item.ViewInstance
end

---更新 WBP_ReuseList_Teammate 的函数
---@param Widget userdata 控件
---@param Index number 在lua侧使用需要 +1
function CustomRoomDetailTeamListMdt:OnTeammateItemUpdate(_, Widget, Index)
    local FixedIndex = Index + 1
    local Data = self.Data[FixedIndex]
        
	local TargetItem = self:_GetOrCreateReuseTeammateItem(Widget)
    if not TargetItem then return end

    TargetItem:SetData(Data)
    TargetItem:UpdateView()
end

--[[
    Data = {
        [1] = { 
            "bAIPlayer" = false 
            "TeamId" = 1 
            "Name" = "百里奚2" 
            "HeroId" = 200010000 
            "PlayerId" = 251658244 
            "LobbyAddr" = "172.17.0.3" 
            "TeamPosition" = 1 
        }，
        [2] = {...}
    }
--]]
function CustomRoomDetailTeamListMdt:SetData(Data)
    self.Data = Data
end

---设置队伍编号
function CustomRoomDetailTeamListMdt:SetTeamIndex(newTeamIndex)
    self.TeamIndex = newTeamIndex
end

---设置队伍最大允许的队员数量
function CustomRoomDetailTeamListMdt:SetMaxTeamPlayerNum(newMaxTeamPlayerNum)
    self.MaxTeamPlayerNum = newMaxTeamPlayerNum
end

---更新标题及内部的成员显示
function CustomRoomDetailTeamListMdt:UpdateView()
    self.View.WBP_ReuseList_Teammate:Reload(self.MaxTeamPlayerNum)

    self.View.Text_TeamID:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetail_Team"), self.TeamIndex))
end

return CustomRoomDetailTeamListMdt
