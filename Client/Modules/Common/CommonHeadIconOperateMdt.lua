--[[
    玩家头像操作界面
]]

local class_name = "CommonHeadIconOperateMdt";
CommonHeadIconOperateMdt = CommonHeadIconOperateMdt or BaseClass(GameMediator, class_name);

CommonHeadIconOperateMdt.OperateTypeEnum = {
    --添加好友
    AddFriend = 1,
    --删除好友
    DeleteFriend = 2,
    --邀请组队
    InviteTeam = 3,
    --踢出队伍
    KickoutTeam = 4,
    --转移队长
    TransferCaptain = 5,
    --退出队伍
    QuitTeam = 6,
    --个人中心
    Detail = 7,
    --私聊
    Chat = 8,
    --好友管理
    Manager = 9,
    -- 邀请进入（自建房）
    CustomRoom_Invite = 10,
    -- 移出房间（自建房）
    CustomRoom_Kickout = 11,
    -- 转移房主 （自建房）
    CustomRoom_TransMaster = 12,
}

--头像操作弹窗的对齐规则类型
CommonHeadIconOperateMdt.FocusTypeEnum = {
    LEFT = 1,
    RIGHT = 2,
    TOP = 3,
    --在Icon下面
    BOTTOM = 4,
}

function CommonHeadIconOperateMdt:__init()
end

function CommonHeadIconOperateMdt:OnShow(data)
end

function CommonHeadIconOperateMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


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

function M:OnInit()
    self.BindNodes = {
        { UDelegate = self.GUIButton_OtherSide.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_OtherSide) },
    }

    self.MsgList = {
        {Model = UserModel, MsgName = UserModel.ON_COMMON_HEAD_HIDE, Func = self.CheckNeedClose},
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED,    Func = self.OnOtherViewShowed },
        { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_DETAIL_INFO_CHANGED,    Func = self.OnGetPlayerDetailInfo },
    }

    self.ActionMap = {
        [CommonHeadIconOperateMdt.OperateTypeEnum.AddFriend] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Addfriends"),Func = self.OnClick_AddFriend},
        [CommonHeadIconOperateMdt.OperateTypeEnum.DeleteFriend] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Removefriends"),Func = self.OnClick_DeleteFriend},
        [CommonHeadIconOperateMdt.OperateTypeEnum.InviteTeam] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Inviteateam"),Func = self.OnClick_InviteTeam},
        [CommonHeadIconOperateMdt.OperateTypeEnum.KickoutTeam] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Kickoutoftheteam"),Func = self.OnClick_KickoutTeam},
        [CommonHeadIconOperateMdt.OperateTypeEnum.TransferCaptain] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Transfercaptain"),Func = self.OnClick_TransferCaptain},
        [CommonHeadIconOperateMdt.OperateTypeEnum.QuitTeam] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Quittheteam"),Func = self.OnClick_QuitTeam},
        [CommonHeadIconOperateMdt.OperateTypeEnum.Detail] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Personalcenter"),Func = self.OnClick_Detail},
        [CommonHeadIconOperateMdt.OperateTypeEnum.Chat] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_chatindividually"),Func = self.OnClick_Chat},
        [CommonHeadIconOperateMdt.OperateTypeEnum.Manager] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Friendmanagement"),Func = self.OnClick_FriendManager},
        [CommonHeadIconOperateMdt.OperateTypeEnum.CustomRoom_Invite] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_invite"),Func = self.OnClick_CustomRoomInvite},
        [CommonHeadIconOperateMdt.OperateTypeEnum.CustomRoom_Kickout] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Moveoutoftheroom"),Func = self.OnClick_CustomRoomKickout},
        [CommonHeadIconOperateMdt.OperateTypeEnum.CustomRoom_TransMaster] = {OperateStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Transfertheowner"),Func = self.OnClick_CustomRoomTransMaster},
    }

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
        --需要采样的位置（决定自己的显示位置）
        FocusWidget
        --采样位置偏移
        FocusOffset
        --采样规则
        FocusType
        --绝对位置（与FocusWidget互斥，两者都有优先执行FocusWidget逻辑）
        AbsolutePosition
        --玩家名字 用于邀请入队时的参数
        PlayerName
        --头像依赖的ViewId
        SourceViewId
    }
]]
function M:OnShow(Param)
    self.Param = Param
    self.PlayerId = self.Param.PlayerId
    if not self.PlayerId then
        CError("CommonHeadIconOperateMdt Param PlayerId nil")
        return
    end
    -- self.FocusType = self.Param.FocusType or CommonHeadIconOperateMdt.FocusTypeEnum.BOTTOM
    self.FocusType = self.Param.FocusType or CommonHeadIconOperateMdt.FocusTypeEnum.RIGHT   -- 默认位置改为右侧
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
            CommonHeadIconOperateMdt.OperateTypeEnum.Detail
        }
        if self.TheTeamModel:IsSelfInTeam() then
            table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.QuitTeam)
        end
    else
         -- 其他人
        self.ActionBtnTypeList = 
        {
            [1] = CommonHeadIconOperateMdt.OperateTypeEnum.Detail,
        }

        --TODO 判断好友关系
        if self.IsFriend then
            table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.Chat)
            table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.Manager)
        else
            table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.AddFriend)
        end
        --TODO 判断自建房状态
        local IsSelfInCustomRoom = self.TheCustomRoomModel:IsPlayerInCurEnteredRoomInfo(self.TheUserModel:GetPlayerId())
        --自已已在自建房内，才会存在额外的自建房操作
        if IsSelfInCustomRoom then
            local IsInCustomRoom = self.TheCustomRoomModel:IsPlayerInCurEnteredRoomInfo(self.PlayerId)
            if not IsInCustomRoom then
                table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.CustomRoom_Invite)
            else
                local IsSelfCustomRoomMaster = self.TheCustomRoomModel:IsMaster(self.TheUserModel:GetPlayerId())
                if IsSelfCustomRoomMaster then
                    table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.CustomRoom_Kickout)
                    table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.CustomRoom_TransMaster)
                end
            end
        end
        --TODO 判断组队状态  （如果玩家在自建房内，下述逻辑不适用。 自建房不允许组件相关的操作）
        if not IsSelfInCustomRoom then
            local State = self.TheFriendModel:GetFriendState(self.PlayerId)
            if not IsInTeam then
                table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.InviteTeam)
            else
                -- 是否是队伍内的人
                local MyTeamId = self.TheTeamModel:GetTeamId()
                local IsInMyTeam = MyTeamId == PlayerTeamId
                if not IsInMyTeam then
                    -- 非队伍内，可以邀请组队
                    table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.InviteTeam)
                end
                -- 自己是该人队伍的队长，才能操作队伍选项
                self.IsCaptain = self.TheTeamModel:IsSelfTeamCaptain()
                if IsInMyTeam and self.IsCaptain then
                    table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.KickoutTeam)
                    --非匹配中才显示转移队长按钮
                    ---@type MatchModel
                    local MatchModel = MvcEntry:GetModel(MatchModel)
                    if not MatchModel:IsMatching() then
                        table.insert(self.ActionBtnTypeList,CommonHeadIconOperateMdt.OperateTypeEnum.TransferCaptain)
                    end
                end
            end
        end
    end
    if not self.ActionBtnTypeList then
        CError("CommonHeadIconOperateMdt ActionBtnTypeList nil",true)
        return
    end

    self.BtnList:ClearChildren()
    local IsAdd = false
    for _,BtnType in ipairs(self.ActionBtnTypeList) do
        -- 加一层过滤 有些特殊情况要堵住，例如个人中心界面的头像，不出现个人中心的按钮
        if not self.FilterList[BtnType] then
            local BtnTypeInfo = self.ActionMap[BtnType]
            if BtnTypeInfo then
                local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/Components/WBP_CommonBtn_Item.WBP_CommonBtn_Item")
                local Widget = NewObject(WidgetClass, self)
                self.BtnList:AddChild(Widget)

                -- Widget.Slot.Padding.Bottom = 10
                -- Widget.Slot:SetPadding(Widget.Slot.Padding)

                local BindNode = {UDelegate = Widget.BtnClick.OnClicked,Func = BtnTypeInfo.Func}
                table.insert(self.BindNodes,BindNode)

                Widget.LbName:SetText(StringUtil.Format(BtnTypeInfo.OperateStr))
                IsAdd = true
            end
        end
    end
    self.PanelRoot:SetRenderScale(UE.FVector2D(0.1,0.1))

    if not IsAdd then
        Timer.InsertTimer(-1,function ()
            if CommonUtil.IsValid(self.PanelRoot) then
                self:DoClose()
            end
        end)
        return
    end
    self:ReRegister()

    -- local BtnListSize = UE.USlateBlueprintLibrary.GetLocalSize(self.BtnList:GetCachedGeometry())
    -- print_r(BtnListSize)
    -- local ImgSize = self.ListBg.Slot:GetSize()
    -- ImgSize.y = BtnListSize.y + 10
    -- self.ListBg.Slot:SetSize(ImgSize)
    -- self.PanelRoot:SetVisibility(UE.ESlateVisibility.Hidden)
    
    Timer.InsertTimer(-1,function ()
        if CommonUtil.IsValid(self.PanelRoot) then
            self.PanelRoot:SetRenderScale(UE.FVector2D(1,1))
            local BtnListSize = UE.USlateBlueprintLibrary.GetLocalSize(self.BtnList:GetCachedGeometry())
            local ImgSize = self.ListBg.Slot:GetSize()
            ImgSize.y = BtnListSize.y
            self.ListBg.Slot:SetSize(ImgSize)

            if self.Param.FocusWidget then
                -- local rootWidget = self.WidgetTree and self.WidgetTree.RootWidget or nil--self.view:GetRootWidget()
                -- local ScreenPos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.Param.FocusWidget:GetCachedGeometry(), self.Param.FocusOffset or UE.FVector2D(0,0))
                -- print_r(ScreenPos)

                local PanelSize = self.PanelRoot:GetDesiredSize()
                local PixelPosition,ViewportPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,self.Param.FocusWidget:GetCachedGeometry(),UE.FVector2D(0,0))
                local FocusSize = UE.USlateBlueprintLibrary.GetLocalSize(self.Param.FocusWidget:GetCachedGeometry())
                local FocusScale = self.Param.FatherScale or 1
                FocusSize.x = FocusSize.x * FocusScale
                FocusSize.y = FocusSize.y * FocusScale
                local PanelRootPos = self:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,true)
                -- print_r(ViewportPosition)
                -- local CanvasPanelSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.PanelRoot)
                -- CanvasPanelSlot:SetPosition( PanelRootPos)
                self.PanelRoot.Slot:SetPosition( PanelRootPos)
            end
        end
    end)

    -- 记录头像依附的界面来源，用于添加好友传途径
    self:UpdateAddFriendModule()
end

function M:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,Check)
    -- 水平方向两侧有空白区域
    local PanelOffset = UE.FVector2D(0,0)
    PanelOffset.x = (PanelSize.x - ImgSize.x)/2 
    PanelOffset.y = (PanelSize.y - ImgSize.y)/2 

    -- Icon侧边空白区域大小
    local FocusScale = self.Param.FatherScale or 1
    local FocusOffset = self.Param.FocusOffset or UE.FVector2D(0,0)
    FocusOffset.x = FocusOffset.x * FocusScale
    FocusOffset.y = FocusOffset.y * FocusScale
    local TmpXFix = ViewportPosition.x
    local TmpYFix = ViewportPosition.y
    local ViewportSize = CommonUtil.GetViewportSize(self)
    if self.FocusType == CommonHeadIconOperateMdt.FocusTypeEnum.BOTTOM then
        TmpXFix = TmpXFix - (PanelSize.x - FocusSize.x)/2
        TmpYFix = TmpYFix + FocusSize.y - FocusOffset.y
        if Check then
            if (TmpYFix + ImgSize.y/2) > ViewportSize.y then
                CWaring("CalculatePanelRootPos Check Fail:" .. self.FocusType .. "|Value:" .. TmpYFix)
                self.FocusType = CommonHeadIconOperateMdt.FocusTypeEnum.TOP
                return self:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,false)
            end
        end
    elseif self.FocusType == CommonHeadIconOperateMdt.FocusTypeEnum.TOP then
        TmpXFix = TmpXFix - (PanelSize.x - FocusSize.x)/2
        TmpYFix = TmpYFix - ImgSize.y + PanelOffset.y + FocusOffset.y
        if TmpYFix1 then
            if (TmpYFix - ImgSize.y) < 0 then
                CWaring("CalculatePanelRootPos Check Fail:" .. self.FocusType .. "|Value:" .. TmpYFix)
                self.FocusType = CommonHeadIconOperateMdt.FocusTypeEnum.BOTTOM
                return self:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,false)
            end
        end
    elseif self.FocusType == CommonHeadIconOperateMdt.FocusTypeEnum.RIGHT then
        TmpXFix = TmpXFix - PanelOffset.x - FocusOffset.x + FocusSize.x
        TmpYFix = TmpYFix + FocusOffset.y
        -- 左右侧增加上下对齐判断 -> 默认顶对齐,超出了就底对齐
        if (TmpYFix + ImgSize.y) > ViewportSize.y then
            TmpYFix = TmpYFix - ImgSize.y + FocusSize.y - FocusOffset.y
        end
        if Check then
            if (TmpXFix + ImgSize.x) > ViewportSize.x then
                CWaring("CalculatePanelRootPos Check Fail:" .. self.FocusType .. "|Value:" .. TmpXFix)
                self.FocusType = CommonHeadIconOperateMdt.FocusTypeEnum.LEFT
                return self:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,false)
            end
        end
    elseif self.FocusType == CommonHeadIconOperateMdt.FocusTypeEnum.LEFT then
        TmpXFix = TmpXFix - PanelOffset.x + FocusOffset.x - ImgSize.x
        TmpYFix = TmpYFix + FocusOffset.y
        -- 左右侧增加上下对齐判断 -> 默认顶对齐,超出了就底对齐
        if (TmpYFix + ImgSize.y) > ViewportSize.y then
            TmpYFix = TmpYFix - ImgSize.y + FocusSize.y - FocusOffset.y
        end
        if Check then
            if TmpXFix < 0 then
                CWaring("CalculatePanelRootPos Check Fail:" .. self.FocusType .. "|Value:" .. TmpXFix)
                self.FocusType = CommonHeadIconOperateMdt.FocusTypeEnum.RIGHT
                return self:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,false)
            end
            
        end
    end
    return UE.FVector2D(TmpXFix,TmpYFix)
end

function M:UpdateAddFriendModule()
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

function M:OnHide()
    MvcEntry:GetModel(FriendModel):ClearAddFriendModule(self.AddFriendModuleId)
end

function M:OnClick_GUIButton_OtherSide()
    self:DoClose()
end

function M:DoClose()
    MvcEntry:CloseView(self.viewId)
end

-- 所属的HeadIcon关闭，检测自身是否需要关闭
function M:CheckNeedClose(PlayerId)
    if self.Param.PlayerId == PlayerId then
        self:DoClose()
    end
end

--点击添加好友
function M:OnClick_AddFriend()
    MvcEntry:GetCtrl(FriendCtrl):SendProto_AddFriendReq(self.Param.PlayerId)
    self:DoClose()
end
--点击删除好友
function M:OnClick_DeleteFriend()
    MvcEntry:GetCtrl(FriendCtrl):SendProto_FriendDeleteReq(self.Param.PlayerId)
    self:DoClose()
end
--点击邀请组队
function M:OnClick_InviteTeam()
    MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteReq(self.Param.PlayerId,self.Param.PlayerName,Pb_Enum_TEAM_SOURCE_TYPE.FRIEND_BAR)
    self:DoClose()
end
--点击T出队伍
function M:OnClick_KickoutTeam()
    MvcEntry:GetCtrl(TeamCtrl):SendTeamKickReq(self.Param.PlayerId)
    self:DoClose()
end
--点击转移队伍
function M:OnClick_TransferCaptain()
    MvcEntry:GetCtrl(TeamCtrl):SendTeamChangeLeaderReq(self.Param.PlayerId)
    self:DoClose()
end

--点击退出队伍（仅自己）
function M:OnClick_QuitTeam()
    MvcEntry:GetCtrl(TeamCtrl):SendTeamQuitReq()
    self:DoClose()
end

-- 监听其他pop层界面打开，则关闭自身
function M:OnOtherViewShowed(ViewId)
    if ViewId == self.viewId then
        return
    end
    local Mdt =  MvcEntry:GetCtrl(ViewRegister):GetView(ViewId)
    if Mdt and Mdt.uiLayer and Mdt.uiLayer ==  UIRoot.UILayerType.Pop then
        -- 有其他pop层界面打开时候，关闭自身
        CLog("CommonHeadIconOperateMdt Closed for OpenView:"..ViewId)
        self:DoClose()
    end
end

--点击个人中心
function M:OnClick_Detail()
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLookUpDetailReq(self.IsSelf and 0 or self.PlayerId)
end

--收到返回的信息，再打开个人中心界面
function M:OnGetPlayerDetailInfo(TargetPlayerId)
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
function M:OnClick_Chat()
    local Param = {
        TargetPlayerId = self.Param.PlayerId
    }
    MvcEntry:OpenView(ViewConst.Chat,Param)
end

--点击好友管理
function M:OnClick_FriendManager()
    MvcEntry:OpenView(ViewConst.FriendManagerLog,self.Param.PlayerId)
end

--[[
    邀请至自建房
]]
function M:OnClick_CustomRoomInvite()
    local PlayerId = self.Param.PlayerId
    --TODO 发送邀请至自建房协议
    MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_InviteReq(self.TheCustomRoomModel:GetCurEnteredRoomId(),PlayerId)
    self:DoClose()
end

--[[
    点击从房间T出
]]
function M:OnClick_CustomRoomKickout()
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
function M:OnClick_CustomRoomTransMaster()
    local PlayerId = self.Param.PlayerId
    if not self.TheCustomRoomModel:IsMaster(self.TheUserModel:GetPlayerId()) then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHeadIconOperateMdt_Nottheowner"))
    end
    --TODO 发送转移协议
    MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_TransMasterReq(self.TheCustomRoomModel:GetCurEnteredRoomId(),PlayerId)
    self:DoClose()
end

return M