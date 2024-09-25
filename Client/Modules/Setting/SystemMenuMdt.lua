--[[
    系统菜单界面
]] 
local class_name = "SystemMenuMdt";
SystemMenuMdt = SystemMenuMdt or BaseClass(GameMediator, class_name);

function SystemMenuMdt:__init()
    self:ConfigViewId(ViewConst.SystemMenu)
end

function SystemMenuMdt:OnShow(data)
end

function SystemMenuMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = {
		{ UDelegate = self.Button_Setting.OnClicked,			Func = self.OnCliked_BtnSetting},
		{ UDelegate = self.Button_QuitGame.OnClicked,			Func = self.OnCliked_BtnQuitGame},
        { UDelegate = self.Btn_BUG.Btn_List.OnClicked,			Func = self.OnCliked_BtnBugReport},
	}

    self.MsgList = {
        {Model = TeamModel, MsgName = TeamModel.ON_ADD_TEAM_MEMBER, Func = self.UpdateTeamVoice},
        {Model = TeamModel, MsgName = TeamModel.ON_DEL_TEAM_MEMBER, Func = self.UpdateTeamVoice},
        {Model = BanModel, MsgName = BanModel.ON_BAN_STATE_CHANGED, Func = self.CheckVoiceBaningTips}
    }

    self.VoiceSetting = {
        [1] = 
            {Type = SystemMenuConst.VoiceSettingType.VoiceIsOpen, Name = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_Voicechat"), ActionMappingKey = ActionMappings.L , BtnConfigs = {Left = {Title= G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_open")},Right = {Title = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_close")}}},
        [2] = 
            {Type = SystemMenuConst.VoiceSettingType.VoiceMode, Name = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_Chatmode"), ActionMappingKey = ActionMappings.K , BtnConfigs = {Left = {Title= G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_press")},Right = {Title = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_Freewheat")}}},
        [3] = 
            {Type = SystemMenuConst.VoiceSettingType.VoiceChannel, Name = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_Voicechannel"), ActionMappingKey = nil, BtnConfigs = {Left = {Title= G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_troops")},Right = {Title = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_nearby"),IsDisabled = true}}},
    }

    UIHandler.New(self, self.BtnBack, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnEscClick),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_SystemMenuMdt_return_Btn"),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })
    self.VoiceSettingCls = {}
    self.TeamVoiceCls = {}
end

function M:OnShow()
    self:UpdateVoiceSetting()
    self:UpdateTeamVoice()
    self:CheckVoiceBaningTips()
    self:CheckBugReport()
end

function M:OnHide()
    self.VoiceSettingCls = {}
    self.TeamVoiceCls = {}
end

-- 聊天设置
function M:UpdateVoiceSetting()
    self.VoiceSettingCls = {}
    for Index, SettingInfo in ipairs(self.VoiceSetting) do
        local Item = self["WBP_VoiceSettingItem_"..Index]
        if Item then
            local SettingCls = UIHandler.New(self,Item,require("Client.Modules.Setting.Item.SystemMenuVoiceSettingItem"),SettingInfo).ViewInstance
            self.VoiceSettingCls[SettingInfo.Type] = SettingCls
        end
    end
end

-- 小队语音管理
function M:UpdateTeamVoice()
    local ShowList = {}
    -- 还有蓝图 WBP_SystemMenu 中的屏蔽修改
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsSelfInTeam = TeamModel:IsSelfInTeam()
    if IsSelfInTeam then
        local TeamMembers = TeamModel:GetTeamMembers()
        local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
        for _,TeamMember in pairs(TeamMembers) do
            if TeamMember.PlayerId ~= MyPlayerId then
                ShowList[#ShowList + 1] = TeamMember
            end
        end
    end
    for Index = 1,3 do
        local Item = self["WBP_TeamVoiceSettingItem_"..Index]
        if Item then
            if ShowList[Index] then
                Item:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)     
                local SettingCls = self.TeamVoiceCls[Index]
                if not SettingCls then
                    SettingCls = UIHandler.New(self,Item,require("Client.Modules.Setting.Item.SystemMenuTeamVoiceItem")).ViewInstance
                    self.TeamVoiceCls[Index] = SettingCls
                end
                SettingCls:UpdateUI(ShowList[Index])
            else
                Item:SetVisibility(UE.ESlateVisibility.Collapsed)     
            end
        end
    end
end

-- 是否需要弹出禁言提示
function M:CheckVoiceBaningTips(Msg)
    if Msg and Msg.BanType and (Msg.BanType ~= Pb_Enum_BAN_TYPE.BAN_VOICE or not Msg.IsBan) then
        return
    end
    local BanModel = MvcEntry:GetModel(BanModel)
    local BanTips = BanModel:GetBanTipsForType(Pb_Enum_BAN_TYPE.BAN_VOICE)
    if BanTips then
        UIAlert.Show(BanTips)
    end
end

-- 是否需要弹出BUG上报按钮
function M:CheckBugReport()
    self.Btn_BUG:SetVisibility(CommonUtil.IsShipping() and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible) 
end


--点击设置
function M:OnCliked_BtnSetting()
   if  BridgeHelper.IsPCPlatform() then
        MvcEntry:OpenView(ViewConst.Setting)
    else
        MvcEntry:OpenView(ViewConst.SettingMobile)
   end
    -- if UE.UGameplayStatics.GetPlatformName() == "Windows" then
    --     print("OnCliked_BtnSetting",UE.UGameplayStatics.GetPlatformName() )
	-- 	MvcEntry:OpenView(ViewConst.Setting)
	-- else
	-- 	MvcEntry:OpenView(ViewConst.SettingMobile)
	-- end
   
end

--点击退出游戏
function M:OnCliked_BtnQuitGame()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if PlayerController then
        local TheSocketMgr = MvcEntry:GetModel(SocketMgr)
        TheSocketMgr:Close(nil,false)
        
        UE.UKismetSystemLibrary.QuitGame(self,PlayerController,0,false)
    end
end

function M:OnCliked_BtnBugReport()
    CWaring("SettingBugReportPopUp =====")
    MvcEntry:OpenView(ViewConst.SettingBugReportPopUp)
end


function M:OnEscClick()
    MvcEntry:CloseView(self.viewId)
end

return M
