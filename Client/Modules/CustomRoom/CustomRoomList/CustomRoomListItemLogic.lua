--[[
    房间列表Item逻辑
]]
local class_name = "CustomRoomListItemLogic"
local CustomRoomListItemLogic = BaseClass(nil, class_name)


function CustomRoomListItemLogic:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.Button_AreaClick.OnClicked,Func = Bind(self,self.OnClickedBtn) },
	}
    self.TheCustomRommModel = MvcEntry:GetModel(CustomRoomModel)
    self.TheMatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
end
function CustomRoomListItemLogic:OnShow(Param)
end

--[[
    local Param = {
        RoomId = RoomId
        ClickFunc
    }
]]
function CustomRoomListItemLogic:SetData(Param)
    if not Param then
        return
    end
    self.RoomId = Param.RoomId
    self.RoomInfo = Param.RoomInfo
    self.Param = Param

    self:UpdateShow()
end

function CustomRoomListItemLogic:OnHide()
end

function CustomRoomListItemLogic:UpdateShow()
    print_r(self.RoomInfo)
    local PlayerName = self.RoomInfo.CustomRoomName
    local StateText = StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"),self.RoomInfo.CurPlayerNum,self.RoomInfo.MaxPlayerNum)
    if self.RoomInfo.Status == Pb_Enum_CUSTOMROOM_STATUS.CUSTOMROOM_ST_GAME then
        StateText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListItemLogic_Inthegame"))
    end
    local CurDSPing = self.TheMatchSeverModel:GetDsPingByDsGroupId(self.RoomInfo.DsGroupId)
    local PingValue = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), CurDSPing, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListItemLogic_milliSecond"))
    local MapCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_SceneEntryCfg,self.RoomInfo.SceneId)
    local MapName = MapCfg and MapCfg[Cfg_ModeSelect_SceneEntryCfg_P.SceneName] or "None"
    local TeamMemberNumType = self.RoomInfo.TeamType
    local ViewTypeName = self.TheCustomRommModel:GetDesByViewType(self.RoomInfo.View)
    local CanWatch = self.RoomInfo.CanSpectate
    local IsLock = self.RoomInfo.IsLock
    local CanWatchText = StringUtil.Format(CanWatch and G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListItemLogic_open") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListItemLogic_close"))
    local PingUpperLimitValue = CommonUtil.GetParameterConfig(ParameterConfig.PingUpperLimit)
    if CurDSPing > PingUpperLimitValue then
        PingValue = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_ThreeParam"), ">", PingUpperLimitValue, G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListItemLogic_milliSecond"))
        CommonUtil.SetTextColorFromeHex(self.View.Text_Ping, "#FA090C")
    else
        CommonUtil.SetTextColorFromeHex(self.View.Text_Ping, "#F5EFDF")
    end
    self.View.Text_PlayerName:SetText(StringUtil.Format(StringUtil.StringTruncationByChar(PlayerName, "#")[1]))
    self.View.Text_State:SetText(StateText)
    self.View.Text_Ping:SetText(PingValue)
    self.View.Text_Map:SetText(StringUtil.Format(MapName))
    self.View.Image_Lock:SetVisibility(IsLock and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    for m=1,4 do
        local Child = self.View.BoxTeamMember:GetChildAt(m-1)
        if Child then
            Child:SetVisibility(m<=TeamMemberNumType and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
    end
    self.View.Text_ViewType:SetText(StringUtil.Format(ViewTypeName))
    self.View.Text_Watch:SetText(CanWatchText)
end
function CustomRoomListItemLogic:Select()
    local CurDSPing = self.TheMatchSeverModel:GetDsPingByDsGroupId(self.RoomInfo.DsGroupId)
    local PingUpperLimitValue = CommonUtil.GetParameterConfig(ParameterConfig.PingUpperLimit)
    if CurDSPing > PingUpperLimitValue then
        CommonUtil.SetTextColorFromeHex(self.View.Text_Ping, "#FA090C")
    else
        CommonUtil.SetTextColorFromeHex(self.View.Text_Ping, "#1B2024")
    end
    if self.View.VXE_Btn_Select then
        self.View:VXE_Btn_Select()
    end
end
function CustomRoomListItemLogic:UnSelect()
    local CurDSPing = self.TheMatchSeverModel:GetDsPingByDsGroupId(self.RoomInfo.DsGroupId)
    local PingUpperLimitValue = CommonUtil.GetParameterConfig(ParameterConfig.PingUpperLimit)
    if CurDSPing > PingUpperLimitValue then
        CommonUtil.SetTextColorFromeHex(self.View.Text_Ping, "#FA090C")
    else
        CommonUtil.SetTextColorFromeHex(self.View.Text_Ping, "#F5EFDF")
    end
    if self.View.VXE_Btn_UnSelect then
        self.View:VXE_Btn_UnSelect()
    end
end

function CustomRoomListItemLogic:OnClickedBtn()
    if self.Param.ClickFunc then
        self.Param.ClickFunc()
    end
end


return CustomRoomListItemLogic
