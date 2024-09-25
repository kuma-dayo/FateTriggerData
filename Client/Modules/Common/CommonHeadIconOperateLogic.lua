--[[
    玩家头像操作界面逻辑
]]
local class_name = "CommonHeadIconOperateLogic"
local CommonHeadIconOperateLogic = BaseClass(nil, class_name)

--[[
    好友操作细则
    - 玩家自己的头像
        - 退出队伍
        - TODO 个人中心
    - 当玩家自己未在队伍中
        - 点击好友列表内好友：
            - 邀请组队
            - 移除好友
    - 当玩家在队伍中
        - 玩家自己为队长
            - 点击队伍内好友头像：
                - 踢出队伍
                - 删除好友
                - 转移队长
            - 点击队伍内非好友头像：
                - 踢出队伍
                - 添加好友
                - 转移队长
            - 点击好友列表内好友
                - 邀请组队
                - 删除好友

            - 点击好友列表内非好友
                - 邀请组队
                - 添加好友

        - 玩家自己不是队长
            - 点击队伍内好友头像
                - 删除好友
            - 点击队伍内非好友头像
                - 添加好友
            - 点击好友列表内好友头像
                - 邀请组队
                - 删除好友
            - 点击好友列表内非好友头像
                - 邀请组队
                - 添加好友
]]

--再等待接收请求玩家信息轮询消息后区分一下即将打开的界面(默认是打开个人中心)
CommonHeadIconOperateLogic.Enum_Action_Type = {
    Report = 1,  --举报
}

function CommonHeadIconOperateLogic:OnInit()
    self.BindNodes = 
    {

	}
    self.MsgList = {
        { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_DETAIL_INFO_CHANGED,    Func = self.OnGetPlayerDetailInfo },
    }

    self.ActionMap = {
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.AddFriend] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Addfriends"),Func = self.OnClick_AddFriend},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.DeleteFriend] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Removefriends"),Func = self.OnClick_DeleteFriend},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.InviteTeam] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Inviteateam"),Func = self.OnClick_InviteTeam},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.KickoutTeam] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Kickoutoftheteam"),Func = self.OnClick_KickoutTeam},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.TransferCaptain] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Transfercaptain"),Func = self.OnClick_TransferCaptain},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.QuitTeam] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Quittheteam"),Func = self.OnClick_QuitTeam},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Detail] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Personalcenter"),Func = self.OnClick_Detail},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Chat] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_chatindividually"),Func = self.OnClick_Chat},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Manager] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Friendmanagement"),Func = self.OnClick_FriendManager},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.CustomRoom_Invite] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_invite"),Func = self.OnClick_CustomRoomInvite},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.CustomRoom_Kickout] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Moveoutoftheroom"),Func = self.OnClick_CustomRoomKickout},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.CustomRoom_TransMaster] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Transfertheowner"),Func = self.OnClick_CustomRoomTransMaster},
        [CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Report] = {OperateStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Report', "11050"),Func = self.OnClick_Report},
    }
    -- 显示按钮列表
    self.ButtonItemList = {}

    self.TheUserModel = MvcEntry:GetModel(UserModel)
    self.TheFriendModel = MvcEntry:GetModel(FriendModel)
    self.TheTeamModel = MvcEntry:GetModel(TeamModel)
    self.TheCustomRoomModel = MvcEntry:GetModel(CustomRoomModel)
end


--[[
    Param结构指引
    {
        --玩家唯一ID
        PlayerId
        --玩家名字 用于邀请入队时的参数
        PlayerName
        --头像依赖的ViewId
        SourceViewId
        -- 隐藏的操作按钮列表
        FilterOperateList
    }
]]
function CommonHeadIconOperateLogic:OnShow(Param)
    self.Param = Param
    self.ActionType = 0
    self.PlayerId = self.Param.PlayerId
    if not self.PlayerId then
        CError("CommonPlayerInfoHoverTipMdt Param PlayerId nil")
        return
    end

    self.IsSelf = self.TheUserModel:IsSelf(self.PlayerId)
    self.IsFriend = self.TheFriendModel:IsFriend(self.PlayerId)
    self.FilterList = {}
    local FilterList = self.Param.FilterOperateList or {}
    for _,FilterType in ipairs(FilterList) do
        self.FilterList[FilterType] = 1
    end
    local PlayerTeamId = self.TheTeamModel:GetTeamId(self.PlayerId)

    -- 这个判断的是玩家自身队伍状态，非操作头像的队伍状态
    local IsInTeam = self.TheTeamModel:IsSelfInTeam()

    self.ActionBtnTypeList = nil
    if self.IsSelf then
        -- 玩家自己
        self.ActionBtnTypeList = 
        {
            CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Detail
        }
        if self.TheTeamModel:IsSelfInTeam() then
            table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.QuitTeam)
        end
    else
         -- 其他人
        self.ActionBtnTypeList = 
        {
            [1] = CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Detail,
        }

        if MvcEntry:GetModel(ViewModel):GetState(ViewConst.Chat) then
            --举报
            table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Report)
        end

        --TODO 判断好友关系
        if self.IsFriend then
            table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Chat)
            table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Manager)
        else
            table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.AddFriend)
        end
        --TODO 判断自建房状态
        local IsSelfInCustomRoom = self.TheCustomRoomModel:IsPlayerInCurEnteredRoomInfo(self.TheUserModel:GetPlayerId())
        --自已已在自建房内，才会存在额外的自建房操作
        if IsSelfInCustomRoom then
            local IsInCustomRoom = self.TheCustomRoomModel:IsPlayerInCurEnteredRoomInfo(self.PlayerId)
            if not IsInCustomRoom then
                table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.CustomRoom_Invite)
            else
                local IsSelfCustomRoomMaster = self.TheCustomRoomModel:IsMaster(self.TheUserModel:GetPlayerId())
                if IsSelfCustomRoomMaster then
                    table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.CustomRoom_Kickout)
                    table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.CustomRoom_TransMaster)
                end
            end
        end
        --TODO 判断组队状态  （如果玩家在自建房内，下述逻辑不适用。 自建房不允许组件相关的操作）
        if not IsSelfInCustomRoom then
            local State = self.TheFriendModel:GetFriendState(self.PlayerId)
            if not IsInTeam then
                table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.InviteTeam)
            else
                -- 是否是队伍内的人
                local MyTeamId = self.TheTeamModel:GetTeamId()
                local IsInMyTeam = MyTeamId == PlayerTeamId
                if not IsInMyTeam then
                    -- 非队伍内，可以邀请组队
                    table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.InviteTeam)
                end
                -- 自己是该人队伍的队长，才能操作队伍选项
                self.IsCaptain = self.TheTeamModel:IsSelfTeamCaptain()
                if IsInMyTeam and self.IsCaptain then
                    table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.KickoutTeam)
                    --非匹配中才显示转移队长按钮
                    ---@type MatchModel
                    local MatchModel = MvcEntry:GetModel(MatchModel)
                    if not MatchModel:IsMatching() then
                        table.insert(self.ActionBtnTypeList,CommonPlayerInfoHoverTipMdt.OperateTypeEnum.TransferCaptain)
                    end
                end
            end
        end
    end
    if not self.ActionBtnTypeList then
        CError("CommonPlayerInfoHoverTipMdt ActionBtnTypeList nil",true)
        return
    end

    if self.View.VerticalBox_BtnList then
        for _, Item in pairs(self.ButtonItemList) do
            if Item then
                Item:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
        for _,BtnType in ipairs(self.ActionBtnTypeList) do
            -- 加一层过滤 有些特殊情况要堵住，例如个人中心界面的头像，不出现个人中心的按钮
            if not self.FilterList[BtnType] then
                local BtnTypeInfo = self.ActionMap[BtnType]
                if BtnTypeInfo then
                    local Widget = self.ButtonItemList[BtnType]
                    if not CommonUtil.IsValid(Widget) then
                        local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/Components/WBP_CommonBtn_Item.WBP_CommonBtn_Item")
                        Widget = NewObject(WidgetClass, self.View)
                        self.View.VerticalBox_BtnList:AddChild(Widget)
                        self.ButtonItemList[BtnType] = Widget              
                        local BindNode = {UDelegate = Widget.BtnClick.OnClicked,Func = Bind(self,BtnTypeInfo.Func)}
                        table.insert(self.BindNodes,BindNode)
                        Widget.LbName:SetText(StringUtil.Format(BtnTypeInfo.OperateStr))
                    end
                    Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                end
            end
        end 
    end
    self:ReRegister()
    -- 记录头像依附的界面来源，用于添加好友传途径
    self:UpdateAddFriendModule()
end

function CommonHeadIconOperateLogic:UpdateAddFriendModule()
    self.AddFriendModuleId = GameModuleCfg.CommonHead.ID
    if self.Param and self.Param.SourceViewId then
        local ViewId = self.Param.SourceViewId
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ViewIdToModuleIdCfg,ViewId)
        if Cfg then
            self.AddFriendModuleId = Cfg[Cfg_ViewIdToModuleIdCfg_P.ModuleId]
        end
    end
    MvcEntry:GetModel(FriendModel):SetAddFriendModule(self.AddFriendModuleId)
    print(StringUtil.Format("============ UpdateAddFriendModule ViewId = {0}, ModuleId = {1} ",tostring(self.Param.SourceViewId),self.AddFriendModuleId))
end

function CommonHeadIconOperateLogic:OnHide()
    MvcEntry:GetModel(FriendModel):ClearAddFriendModule(self.AddFriendModuleId)
end

function CommonHeadIconOperateLogic:OnClick_GUIButton_OtherSide()
    self:DoClose()
end

function CommonHeadIconOperateLogic:DoClose()
    MvcEntry:CloseView(ViewConst.CommonPlayerInfoHoverTip)
end

--点击添加好友
function CommonHeadIconOperateLogic:OnClick_AddFriend()
    MvcEntry:GetCtrl(FriendCtrl):SendProto_AddFriendReq(self.Param.PlayerId)
    self:DoClose()
end
--点击删除好友
function CommonHeadIconOperateLogic:OnClick_DeleteFriend()
    MvcEntry:GetCtrl(FriendCtrl):SendProto_FriendDeleteReq(self.Param.PlayerId)
    self:DoClose()
end
--点击邀请组队
function CommonHeadIconOperateLogic:OnClick_InviteTeam()
    MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteReq(self.Param.PlayerId,self.Param.PlayerName,Pb_Enum_TEAM_SOURCE_TYPE.FRIEND_BAR)
    self:DoClose()
end
--点击T出队伍
function CommonHeadIconOperateLogic:OnClick_KickoutTeam()
    MvcEntry:GetCtrl(TeamCtrl):SendTeamKickReq(self.Param.PlayerId)
    self:DoClose()
end
--点击转移队伍
function CommonHeadIconOperateLogic:OnClick_TransferCaptain()
    MvcEntry:GetCtrl(TeamCtrl):SendTeamChangeLeaderReq(self.Param.PlayerId)
    self:DoClose()
end

--点击退出队伍（仅自己）
function CommonHeadIconOperateLogic:OnClick_QuitTeam()
    MvcEntry:GetCtrl(TeamCtrl):SendTeamQuitReq()
    self:DoClose()
end

--点击个人中心
function CommonHeadIconOperateLogic:OnClick_Detail()
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLookUpDetailReq(self.IsSelf and 0 or self.PlayerId)
end

--收到返回的信息，再打开个人中心界面
function CommonHeadIconOperateLogic:OnGetPlayerDetailInfo(TargetPlayerId)
    if self.ActionType == CommonHeadIconOperateLogic.Enum_Action_Type.Report then
        --打开举报
        self.ActionType = 0
        self:OnClick_Report()
        return
    end
    if self.Param.PlayerId == TargetPlayerId then
        local Param = {
            PlayerId = self.Param.PlayerId,
            SelectTabId = 1,
            OnShowParam = TargetPlayerId
        }
        MvcEntry:OpenView(ViewConst.PlayerInfo, Param)
    end
end

--点击私聊
function CommonHeadIconOperateLogic:OnClick_Chat()
    local Param = {
        TargetPlayerId = self.Param.PlayerId
    }
    MvcEntry:OpenView(ViewConst.Chat,Param)
end

--点击好友管理
function CommonHeadIconOperateLogic:OnClick_FriendManager()
    MvcEntry:OpenView(ViewConst.FriendManagerLog,self.Param.PlayerId)
end

--[[
    邀请至自建房
]]
function CommonHeadIconOperateLogic:OnClick_CustomRoomInvite()
    local PlayerId = self.Param.PlayerId
    --TODO 发送邀请至自建房协议
    MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_InviteReq(self.TheCustomRoomModel:GetCurEnteredRoomId(),PlayerId)
    self:DoClose()
end

--[[
    点击从房间T出
]]
function CommonHeadIconOperateLogic:OnClick_CustomRoomKickout()
    local PlayerId = self.Param.PlayerId
    if not self.TheCustomRoomModel:IsMaster(self.TheUserModel:GetPlayerId()) then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Nottheowner"))
    end

    --TODO 发送T人协议
    MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_KickPlayerReq(self.TheCustomRoomModel:GetCurEnteredRoomId(),PlayerId)
    self:DoClose()
end
--[[
    点击转移房主
]]
function CommonHeadIconOperateLogic:OnClick_CustomRoomTransMaster()
    local PlayerId = self.Param.PlayerId
    if not self.TheCustomRoomModel:IsMaster(self.TheUserModel:GetPlayerId()) then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Nottheowner"))
    end
    --TODO 发送转移协议
    MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_TransMasterReq(self.TheCustomRoomModel:GetCurEnteredRoomId(),PlayerId)
    self:DoClose()
end

--[[
    点击举报
]]
function CommonHeadIconOperateLogic:OnClick_Report()
    local PlayerInfo = MvcEntry:GetModel(PersonalInfoModel):GetPlayerDetailInfo(self.Param.PlayerId)
    if not PlayerInfo then 
        --等待轮询消息回来再尝试获取玩家信息
        self.ActionType = CommonHeadIconOperateLogic.Enum_Action_Type.Report
        return
    end
    local ReportConst = require("Client.Modules.Report.ReportConst")
    local Param = {
        ReportScene = ReportConst.Enum_ReportScene.Chat,
        ReportSceneId = ReportConst.Enum_HallReportSceneId.PersonalZone,
        ReportPlayers = {                                                           --【必填】可供举报的玩家列表，至少有一名玩家
            [1] = {
                PlayerId = self.Param.PlayerId,                                                       --【必填】被举报的玩家ID
                PlayerName = PlayerInfo.PlayerName                                           --【必填】被举报的玩家名字
            }
        },
    }
    MvcEntry:GetCtrl(ReportCtrl):HallReport(Param)
end

return CommonHeadIconOperateLogic