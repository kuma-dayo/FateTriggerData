--[[
    通用玩家信息Hover提示界面
]]
local AchievementPersonItem = require("Client.Modules.Achievement.AchievementPersonItem")
local class_name = "CommonPlayerInfoHoverTipMdt";
CommonPlayerInfoHoverTipMdt = CommonPlayerInfoHoverTipMdt or BaseClass(GameMediator, class_name);

-- 玩家信息hover界面按钮类型
CommonPlayerInfoHoverTipMdt.OperateTypeEnum = {
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
    --举报
    Report = 13
}

function CommonPlayerInfoHoverTipMdt:__init()
end

function CommonPlayerInfoHoverTipMdt:OnShow(data)
end

function CommonPlayerInfoHoverTipMdt:OnHide()

end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.BtnOutSide.OnClicked,	Func = Bind(self,self.GUIButton_Close_ClickFunc)},
        { UDelegate = self.WBP_Hot.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_AddHot) },
	}
    self.MsgList = {
        { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID, Func = self.OnPlayerInfoChange},
        { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_COMMON_DIALOG_INFO_CHANGED_FOR_ID, Func = self.OnPlayerInfoChange},
        { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_COMMON_HEAD_CHANGE_OPERATE_BTN_STATE_EVENT, Func = self.OnCommonHeadChangeOperateBtnState},
        { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_HOT_VALUE_CHANGED, Func = self.OnHotValueChanged},
        { Model = UserModel, MsgName = UserModel.ON_COMMON_HEAD_HIDE, Func = self.CheckNeedClose},
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED,    Func = self.OnOtherViewShowed},
        
    }
    -- 这个界面无需输入事件，强制关闭WidgetFocus;避免当icon在滑动列表中，tips的显隐打乱了icon的Btn和列表直接的输入
    -- self.CloseWidgetFocus = true

    -- 玩家ID
    self.PlayerId = 0
    -- 玩家详细数据
    self.DetailData = nil
    -- 是否展示操作按钮
    self.IsShowOperateBtn = false
    -- 是否本人
    self.IsSelf = false
    --标签item列表
    self.SocialTagItemList = {}
    -- 操作按钮item
    self.OperateBtn = nil
    ---@type PersonalInfoModel
    self.PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)

    ---@type SeasonRankModel
    self.SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)

    self.BtnOutSide:SetVisibility(UE.ESlateVisibility.Collapsed)
end

--由mdt触发调用
--[[
    Param = {
        PlayerId: 玩家ID 必填
        PlayerName 玩家名字  组队邀请依赖参数
        SourceViewId 头像依赖的界面ID
        IsShowOperateBtn 是否显示操作按钮 选填  默认隐藏
        FilterOperateList 隐藏的按钮列表
        FocusWidget [Optional]: 附着的节点，传入则会将位置设置在该节点四周可放入位置
        FocusOffset [Optional]: 采样位置偏移 FVector2D
        IsNeedReqUpdateData 是否需要请求刷新数据
    }
]]
function M:OnShow(Params)
    if not Params or not Params.PlayerId then
        CError("CommonPlayerInfoHoverTipMdt Param Error")
        print_trackback()
        self:DoClose()
        return
    end
    self.Params = Params

    self.PlayerId = Params.PlayerId
    self.PlayerName = Params.PlayerName
    self.SourceViewId = Params.SourceViewId
    self.IsShowOperateBtn = Params.IsShowOperateBtn and true or false 
    self.FilterOperateList = Params.FilterOperateList or {}
    self.IsNeedReqUpdateData = Params.IsNeedReqUpdateData and true or false 
    
    self.DetailData = self.PersonalInfoModel:GetPlayerDetailInfo(self.PlayerId)
    self.IsSelf = self.PlayerId == MvcEntry:GetModel(UserModel):GetPlayerId()
    if not self.DetailData or self.IsNeedReqUpdateData then
        MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_GetPlayerCommonDialogDataReq({self.PlayerId})
    else
        self:UpdateUI()
    end
    self:UpdateAchievement()
    self:UpdateBtnShow()
    self:AdjustShowPos()
end

-- 更新成就信息
function M:UpdateAchievement()
    --打开自己的界面
    if self.IsSelf then
        self:UpdateAchievementShow()
    else
        self:UpdateAchievementShow()
        MvcEntry:GetCtrl(AchievementCtrl):GetAchievementInfoReq(self.PlayerId, Bind(self, self.UpdateAchievementShow), true)
    end
end

function M:OnRepeatShow(Params)
    self:OnShow(Params)
end

-- 个人信息更新
function M:OnPlayerInfoChange(PlayerId)
    if self.PlayerId == PlayerId then
        self.DetailData = self.PersonalInfoModel:GetPlayerDetailInfo(self.PlayerId) 
        self:UpdateUI()
        self:UpdateAchievementShow()
    end
end

--[[
    PlayerId 
    BtnState
]]
-- 更新操作按钮状态
function M:OnCommonHeadChangeOperateBtnState(Param)
    if self.PlayerId == Param.PlayerId then
        self:SetBtnShowState(Param.BtnState)
    end
end

-- 热度值变化
function M:OnHotValueChanged(Param)
    if Param.TargetPlayerId ~= self.PlayerId then
        return
    end
    self.Text_Hot:SetText(StringUtil.FormatNumberStr(Param.LikeHeartTotal))
    self.Text_Hot_Other:SetText(StringUtil.FormatNumberStr(Param.LikeHeartTotal))
    self:PlayHotAddAnimation()
end

-- 播放热度值增加效果
function M:PlayHotAddAnimation()
    -- self.View:StopAnimation(self.View.Vx_HotAdd)
    -- self.View:PlayAnimation(self.View.Vx_HotAdd)
end

-- 更新UI展示
function M:UpdateUI()
    self:UpdateHeadIcon()
    self:UpdatePlayerName()
    self:UpdateHotShow()
    self:UpdatetSocialTagShow()
    self:UpdateRankShow()
end

-- 更新头像相关
function M:UpdateHeadIcon()
    -- 头像
    local Param = {
        PlayerId = self.PlayerId,
        CloseOnlineCheck = true,
        CloseAutoCheckFriendShow = true,
        ClickType = CommonHeadIcon.ClickTypeEnum.None
    }
    if not self.SingleHeadCls then
        self.SingleHeadCls = UIHandler.New(self,self.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.SingleHeadCls:UpdateUI(Param)
    end
end

-- 更新玩家名称
function M:UpdatePlayerName()
    local PlayerName, PlayerDigitalId = StringUtil.SplitPlayerName(self.DetailData.PlayerName, true)
    self.Text_PlayerName:SetText(PlayerName)
    self.Text_PlayerNameId:SetText(PlayerDigitalId) 
end

-- 更新热度值展示
function M:UpdateHotShow()
    self.WidgetSwitcher_Hot:SetActiveWidget(self.IsSelf and self.Panel_SelfHot or self.Panel_OtherHot)
    if self.DetailData and self.DetailData.LikeHeartTotal then
        self.Text_Hot:SetText(StringUtil.FormatNumberStr(self.DetailData.LikeHeartTotal))
        self.Text_Hot_Other:SetText(StringUtil.FormatNumberStr(self.DetailData.LikeHeartTotal)) 
    end
end

--更新社交标签展示
function M:UpdatetSocialTagShow()
    local SocialTagInfoList = self.DetailData.TagIdList or {}
    for _, SocialTagItem in pairs(self.SocialTagItemList) do
        if SocialTagItem and SocialTagItem.View then
            SocialTagItem.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    for Index, TagInfo in ipairs(SocialTagInfoList) do
        local Item = self.SocialTagItemList[Index]
        local Param = {
            ShowType = PersonalInfoModel.Enum_SocialTagItemShowType.Only_Show,
            TagId = TagInfo,
            IsSelf = self.IsSelf
        }
        if not (Item and CommonUtil.IsValid(Item.View)) then
            local WidgetClass = UE.UClass.Load(PersonalInfoModel.SocialTagBtnItem.UMGPATH)
            local Widget = NewObject(WidgetClass, self.WidgetBase)
            self.WrapBox_Tag:AddChild(Widget)
            Item = UIHandler.New(self,Widget,require(PersonalInfoModel.SocialTagBtnItem.LuaClass),Param).ViewInstance
            self.SocialTagItemList[Index] = Item
        end
        Item.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        Item:OnShow(Param)
    end
end

-- 更新排位信息展示
function M:UpdateRankShow()
    local MaxDivisionInfo = self.PersonalInfoModel:GetMaxRankDivisionInfo(self.PlayerId)
    local IsHasRankInfo = MaxDivisionInfo ~= nil
    self.WidgetSwitcher_Rank:SetActiveWidget(IsHasRankInfo and self.Panel_Rank or self.Panel_RankEmpty)
    if MaxDivisionInfo then
        local DivisionIconPath = self.SeasonRankModel:GetDivisionIconPathByDivisionId(MaxDivisionInfo.MaxDivisionId)
        if DivisionIconPath and DivisionIconPath ~= "" then
            CommonUtil.SetBrushFromSoftObjectPath(self.Image_Rank, DivisionIconPath) 
        end
    end
end

-- 更新成就展示
function M:UpdateAchievementShow()
    self.AchieveItemList = self.AchieveItemList or {}
    local SlotMap = self.DetailData and self.DetailData.SlotMap or {}
    local IsOpenAchievement = MvcEntry:GetCtrl(AchievementCtrl).IsOpen
    local AchieveInfoList = {}
    for _, Value in pairs(SlotMap) do
        local AchvGroupId = Value.AchvGroupId
        local SlotPos = Value.SlotPos
        AchieveInfoList[SlotPos] = AchvGroupId
    end
    for i = 1, 3 do
        repeat
            local WidgetSwitcherAchievement = self["WidgetSwitcherAchievement_"..i]
            local Widget = self["WBP_Achievement_Person_Item_"..i]
            local Panel_AchievementEmpty = self["Panel_AchievementEmpty_"..i]
            local AhicId = AchieveInfoList[i]
            if not IsOpenAchievement or not AhicId or AhicId < 1 then
                WidgetSwitcherAchievement:SetActiveWidget(Panel_AchievementEmpty)
                break
            end

            --[[
                配置里的成就分为启用和未启用，仅用AhicId判断是否展示item不足够，还得判断有无对应成就数据,未启用的成就Model中不会装填数据
            ]]
            local Data = MvcEntry:GetModel(AchievementModel):GetData(AhicId)
            if not Data then
                WidgetSwitcherAchievement:SetActiveWidget(Panel_AchievementEmpty)
                break
            end

            WidgetSwitcherAchievement:SetActiveWidget(Widget)

            local Params = {
                AhicId = AhicId,
                PlayerId = self.PlayerId,
                IsNeedReadSmallIcon = true
            }
            if not self.AchieveItemList[i] then
                self.AchieveItemList[i] = UIHandler.New(self, Widget, AchievementPersonItem, Params).ViewInstance
            else
                self.AchieveItemList[i]:UpdateUI(Params)
            end
        until true
    end
end

-- 设置按钮的显示状态
function M:SetBtnShowState(IsShow)
    -- 是否展示操作按钮
    self.IsShowOperateBtn = IsShow
    self:UpdateBtnShow()
    self:AdjustShowPos()
end

-- 更新按钮的展示
function M:UpdateBtnShow()
    self.BtnOutSide:SetVisibility(self.IsShowOperateBtn and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    self.WBP_Common_PlayerFloatWindow_ListBtn:SetVisibility(self.IsShowOperateBtn and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden)
    -- 头像
    local Param = {
        -- 玩家唯一ID
        PlayerId = self.PlayerId,
        -- 玩家名字 用于邀请入队时的参数
        PlayerName = self.PlayerName,
        -- 头像依赖的ViewId
        SourceViewId = self.SourceViewId,
        -- 隐藏的操作按钮列表
        FilterOperateList = self.FilterOperateList,
    }
    if not self.OperateBtn then
        self.OperateBtn = UIHandler.New(self,self.WBP_Common_PlayerFloatWindow_ListBtn, require("Client.Modules.Common.CommonHeadIconOperateLogic"),Param).ViewInstance
    else
        self.OperateBtn:OnShow(Param)
    end
end

-- 计算浮窗出现的位置
function M:AdjustShowPos()
    self.VerticalBox:SetRenderScale(UE.FVector2D(0.001,0.001))
    self:ClearPopTimer()
    -- Icon按钮存在Hover放大效果，下一帧再进行位置计算，避免放大影响了Position计算  有点时序的问题，转局部坐标的时候有问题，故改为延迟0.1S
    self.PopTimer = Timer.InsertTimer(0.1,function ()
        if not CommonUtil.IsValid(self.VerticalBox) then
            return
        end
        self.VerticalBox:SetRenderScale(UE.FVector2D(1,1))
        self.VerticalBox:ForceLayoutPrepass()
        local ViewportSize = CommonUtil.GetViewportSize(self)
        local PanelSize = self.VerticalBox:GetDesiredSize()
        if not self.Params.FocusWidget then
            -- 没有要附着的点就居中显示
            self.VerticalBox.Slot:SetPosition(UE.FVector2D(ViewportSize.x/2-PanelSize.x/2,-ViewportSize.y/2+PanelSize.y/2))
        else
            local ShowPosition = self:CalculateFocusPos(PanelSize)
            self.VerticalBox.Slot:SetPosition(ShowPosition)
        end
    end)
end

function M:ClearPopTimer()
    if self.PopTimer then
        Timer.RemoveTimer(self.PopTimer)
    end
    self.PopTimer = nil
end
 
-- 计算在附着点的哪一侧位置显示
function M:CalculateFocusPos(PanelSize)
    -- FocusWidget大小
    local FocusWidgeSize = UE.USlateBlueprintLibrary.GetLocalSize(self.Params.FocusWidget:GetCachedGeometry())
    -- FocusWidget在屏幕上的位置
    local FocusWidgetScreenPos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.Params.FocusWidget:GetCachedGeometry(), self.Params.FocusOffset or UE.FVector2D(0,0))

    -- 转换成局部位置 (0,0)描点位置
    local FocusWidgetLocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self:GetCachedGeometry(), FocusWidgetScreenPos)
    -- 不显示按钮的情况 需要获取按钮的大小已计算真实容器的大小
    local ListBtnDesiredSize = self.IsShowOperateBtn == false and self.WBP_Common_PlayerFloatWindow_ListBtn:GetDesiredSize() or UE.FVector2D(0,0)
    -- 真实的容器大小，把vidden的按钮列表大小去除
    local RealPanelSize = UE.FVector2D(PanelSize.X, PanelSize.Y - ListBtnDesiredSize.Y)
    -- 偏移量参数
    local OffsetPos = UE.FVector2D(0,10)
    -- 最终显示坐标
    local PosX,PosY = 0,0
    -- 距离界面上边界距离
    local TopPadding = FocusWidgetLocalPos.Y - RealPanelSize.Y - OffsetPos.Y
    -- 距离界面左边界距离
    local LeftPadding = FocusWidgetLocalPos.X + FocusWidgeSize.X - OffsetPos.X
    -- 按钮列表vidden的时候，判断方向的时候把按钮大小加上
    local IsTopDirection = TopPadding - ListBtnDesiredSize.Y > 0 
    -- 是否在上方
    if IsTopDirection then
        -- 优先放顶部
        PosY = TopPadding
        if LeftPadding > RealPanelSize.X then
            -- 优先靠左展示，与Widget右对齐
            PosX = LeftPadding - RealPanelSize.X
        else
            -- 靠右展示，与Widget左对齐
            PosX = FocusWidgetLocalPos.X + OffsetPos.X
        end
    else
        -- 顶部放不下 放左/右侧 与Widget顶对齐
        PosY = FocusWidgetLocalPos.Y + FocusWidgeSize.Y + OffsetPos.Y
        if LeftPadding > RealPanelSize.X then
            -- 优先靠左展示，与Widget右对齐
            PosX = LeftPadding - RealPanelSize.X
        else
            -- 靠右展示，与Widget左对齐
            PosX = FocusWidgetLocalPos.X + OffsetPos.X
        end
    end
    return UE.FVector2D(PosX, PosY)
end

function M:OnHide()
    self:ClearPopTimer()
end

--关闭界面
function M:DoClose()
    self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_PLAYER_INFO_HOVER_TIPS_CLOSED_EVENT)
    MvcEntry:CloseView(self.viewId)
end

--点击关闭界面
function M:GUIButton_Close_ClickFunc()
    self:DoClose()
    return true
end

-- 点击增加热度值
function M:OnClick_AddHot()
    if self.IsSelf then
        -- 自己只播效果，数据不变
        -- 需求修改 点击自己不交互
        -- self:PlayHotAddAnimation()
    else
        MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLikeHeartReq(self.PlayerId)
    end
end

-- 所属的HeadIcon关闭，检测自身是否需要关闭
function M:CheckNeedClose(PlayerId)
    if self.PlayerId == PlayerId then
        self:DoClose()
    end
end

-- 监听其他pop层界面打开，则关闭自身
function M:OnOtherViewShowed(ViewId)
    if ViewId == self.viewId or not ViewConstConfig or not ViewConstConfig[ViewId]  then
        return
    end
    local Mdt =  MvcEntry:GetCtrl(ViewRegister):GetView(ViewId)
    if Mdt and Mdt.uiLayer and Mdt.uiLayer ==  UIRoot.UILayerType.Pop then
        -- 有其他pop层界面打开时候，关闭自身
        CLog("CommonPlayerInfoHoverTipMdt Closed for OpenView:"..ViewId)
        self:DoClose()
    end
end

--点击私聊
function M:OnClick_PrivateChat()

end

return M