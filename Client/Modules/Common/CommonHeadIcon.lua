--[[
    通用的CommonHeadIcon控件

    通用的头像Icon控件
]]
local HeadWidgetUtil = require("Client.Modules.PlayerInfo.HeadIconSetting.HeadWidgetUtil")
local class_name = "CommonHeadIcon"
---@class CommonHeadIcon
CommonHeadIcon = CommonHeadIcon or BaseClass(nil, class_name)

CommonHeadIcon.ClickTypeEnum = {
    --无
    None = 1,
    --弹窗操作界面
    Operate = 2,
}

function CommonHeadIcon:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.BtnClick.OnPressed,				Func = Bind(self,self.OnItemButtonOnPressed) },
        { UDelegate = self.View.BtnClick.OnHovered,				Func = Bind(self,self.OnItemButtonHovered) },
        { UDelegate = self.View.BtnClick.OnUnhovered,		    Func = Bind(self,self.OnItemButtonUnhovered) },
	}

    self.MsgList = {
        {Model = FriendModel, MsgName = ListModel.ON_UPDATED, Func = self.OnFriendUpdated},
        {Model = FriendModel, MsgName = FriendModel.ON_PLAYERSTATE_CHANGED, Func = self.UpdateFriendOnlineState},
        {Model = FriendModel, MsgName = ListModel.ON_DELETED, Func = self.OnCheckFriend},
        {Model = UserModel, MsgName = UserModel.ON_QUERY_PLAYER_STATE_RSP, Func = self.OnGetPlayerState},
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID, Func = self.OnGetPlayerDetailInfo},
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_COMMON_DIALOG_INFO_CHANGED_FOR_ID, Func = self.OnGetPlayerDetailInfo},
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_INFO_HOVER_TIPS_CLOSED_EVENT, Func = self.OnHoverTipsClosed},
        {Model = UserModel, MsgName = UserModel.ON_PLAYER_LV_CHANGE, Func = self.OnLevelUp},
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_DETAIL_INFO_CHANGED,    Func = self.OnOpenPersonalInfoView },
        -- {Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,  Func = self.OnOtherViewClosed },
    }

    ---@type HttpCtrl
    self.HttpCtrl = MvcEntry:GetCtrl(HttpCtrl)
    ---@type PersonalInfoCtrl
    self.PersonalInfoCtrl = MvcEntry:GetCtrl(PersonalInfoCtrl)
    ---@type HeadIconSettingModel
    self.HeadIconSettingModel = MvcEntry:GetModel(HeadIconSettingModel)
    ---@type PersonalInfoModel
    self.PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)
    ---@type ViewModel
    self.ViewModel = MvcEntry:GetModel(ViewModel)
    -- 当前材质名称 一致的情况 减少刷新
    self.CurMaterialName = ""
    -- 当前选中的状态
    self.CurSelectState = false
end
--[[
    Param格式指引
	{
        PlayerId          = 1,                                           --【必填】玩家唯一ID
        HeadIconId        = 1,                                           --【可选】头像ID，如果没有传则会通过PlayerId去获取
        HeadFrameId       = 1,                                           --【可选】头像框ID，如果没有传则会通过PlayerId去获取
        PortraitUrl       = "",                                          --【可选】自定义头像URL，如果没有传则会通过PlayerId去获取
        SelectPortraitUrl = false,                                       --【可选】是否装配自定义头像URL，如果没有传则会通过PlayerId去获取
        HeadWidgetList    = {},                                          --【可选】头像挂件列表，如果没有传则会通过PlayerId去获取
        --等级
        ShowLevel         = false,                                       --【可选】是否显示等级
        ShowUpAni         = false,                                       --【ShowLevel为true时有用，可选】是否展示升级特效（监听事件触发）
        --状态
        IsCaptain         = false,                                       --【可选】是否队长 （默认不是），会显示队长标识
        CloseOnlineCheck  = false,                                       --【可选】不检测在线状态 （即一直是在线样式），离线会有遮罩等效果
        CloseAutoCheckFriendShow = false,                                --【可选】关闭自动检测是否好友展示，如果开启了，则会检查传入的PlayerId是否是好友或自己的，如果是的话则显示陌生人图标
        PlayerState = {}                                                 --【可选】由外部传入的状态显示，传入了则不走请求
        --点击
		OnItemClick       = nil,                                         --【可选】点击回调
        ClickType         = CommonHeadIcon.ClickTypeEnum.Operate         --【可选】点击类型，默认为Operate，如无需要则选择 None
        PlayerName        = "1",                                         --【ClickType为Operate时有用，可选】玩家名字，当需要从离线玩家的下拉菜单进行邀请入队的时候，要传此参数。需要透传给服务器使用
        FocusType         = CommonHeadIconOperateMdt.FocusTypeEnum.RIGHT --【ClickType为Operate时有用，可选】弹出Tip位置采样规则 LEFT、RIGHT、TOP、BOTTOM
        FatherScale       = 1,                                           --【ClickType为Operate时有用，可选】父节点的缩放值 实在没找到获取的方式，只能先作为参数传进来
        ClickOpenPersonal = false,                                       --【可选】点击头像直接打开个人信息界面
        NotNeedReqPlayerInfo = false,                                    -- 是否不需要定时请求信息
        NeedSyncWidgets = {
            NameWidget = Table
        }                                                                -- 需要同步的外部控件
	}
--]]
function CommonHeadIcon:OnShow(Param)
    self:UpdateUI(Param,true)
end
function CommonHeadIcon:OnHide()
    -- 通知顶层下拉菜单操作界面关闭
    MvcEntry:GetModel(UserModel):DispatchType(UserModel.ON_COMMON_HEAD_HIDE,self.Param.PlayerId)
    self.IsForceMask = false
    self:ClearPopTimer()
end
-- 供外部调用，可能外部可见性隐藏了但实际并未释放，不会执行OnHide函数
function CommonHeadIcon:OnCustomHide()
    -- 通知顶层下拉菜单操作界面关闭
    MvcEntry:GetModel(UserModel):DispatchType(UserModel.ON_COMMON_HEAD_HIDE,self.Param.PlayerId)
    self:ClearPopTimer()
end

function CommonHeadIcon:UpdateUI(Param,IsInit)
    if not Param then
        CError("CommonHeadIcon:UpdateUI Param Error")
        print_trackback()
        return
    end
    if not self.PlayerId or self.PlayerId ~= Param.PlayerId then
        self:InitViewDefaultState()
    end
    self.Param = Param
    self.ClickType = self.Param.ClickType or CommonHeadIcon.ClickTypeEnum.Operate
    self.PlayerId = self.Param.PlayerId
    self.HeadFrameId = self.Param.HeadFrameId
    self.HeadIconId = self.Param.HeadIconId
    self.PortraitUrl = self.Param.PortraitUrl
    self.SelectPortraitUrl = self.Param.SelectPortraitUrl
    self.HeadWidgetList = self.Param.HeadWidgetList or {}
    self.IsCaptain = self.Param.IsCaptain or false
    self.ClickOpenPersonal = self.Param.ClickOpenPersonal or false
    self.NotNeedReqPlayerInfo = self.Param.NotNeedReqPlayerInfo or false
    self.CloseAutoCheckFriendShow = self.Param.CloseAutoCheckFriendShow or false
    self.IsForceMask = false
    self.IsSendUpdateHead = false
    self.CloseOnlineCheck = self.Param.CloseOnlineCheck or false
    self.PlayerName = self.Param.PlayerName or ""
    self.Level = MvcEntry:GetModel(UserModel):GetPlayerLvAndExp()
    self.CurSelectState = false
    self:UpdateOnlineState()
    self:ClearPopTimer()
    if not self.PlayerId then
        CError("CommonHeadIcon Param PlayerId nil")
        return
    end
    
    self.IsSelf = MvcEntry:GetModel(UserModel):IsSelf(self.PlayerId)
    if self.CloseAutoCheckFriendShow or self.IsSelf then
        self.View.Stranger:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self:OnCheckFriend()
    end

    self.View.Captain:SetVisibility(self.IsCaptain and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self:UpdateLevelShow()

    -- 更新头像及头像框
    if not self.HeadIconId or not self.PortraitUrl or self.SelectPortraitUrl == nil then
        local PlayerInfo = self.PersonalInfoModel:GetPlayerDetailInfo(self.PlayerId)
        if PlayerInfo then
            self.HeadIconId = PlayerInfo.HeadId
            self.PortraitUrl = PlayerInfo.PortraitUrl
            self.SelectPortraitUrl = PlayerInfo.SelectPortraitUrl
            self:UpdateHeadIcon()
            -- 如果数据是过期的，那就仅显示旧的头像，头像框和挂件等待轮询结果更新
            if not PlayerInfo.IsOutOfDate then
                self.HeadFrameId = PlayerInfo.HeadFrameId
                self.HeadWidgetList = PlayerInfo.HeadWidgetList or {}
                self:UpdateHeadFrame()
                self:UpdateHeadWidgets()
            end
        end
    else
        self:UpdateHeadIcon()
    end

    self.View.BtnClick:SetIsEnabled(self.ClickType ~= CommonHeadIcon.ClickTypeEnum.None)
    if IsInit and not self.NotNeedReqPlayerInfo and not self.IsSelf then
        -- 开启基础信息轮询
        MvcEntry:GetCtrl(PersonalInfoCtrl):QueryPlayerBaseInfoByView(self,self.PlayerId,true)
    end
end

function CommonHeadIcon:InitViewDefaultState()
    self.IsOnline = nil
    self.View.GUIImage_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.HeadIconFrame:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Stranger:SetVisibility(UE.ESlateVisibility.Collapsed)
end
function CommonHeadIcon:OnItemButtonOnPressed()
	-- CLog("ItemButton Clicked")
    if self.Param and self.Param.OnItemClick then
        self.Param.OnItemClick()
    end
    if self.PlayerId and self.ClickType == CommonHeadIcon.ClickTypeEnum.Operate then 
        -- 点击直接打开个人信息界面
        if self.ClickOpenPersonal then
            self:ClearPopTimer()
            if self.ViewModel:GetState(ViewConst.CommonPlayerInfoHoverTip) then
                MvcEntry:CloseView(ViewConst.CommonPlayerInfoHoverTip)
            end
            self:OpenPersonalInfo()
        else
            self.CurSelectState = true       
            if self.ViewModel:GetState(ViewConst.CommonPlayerInfoHoverTip) then   
                local Param = {
                    PlayerId = self.PlayerId,
                    BtnState = true, 
                }
                self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_COMMON_HEAD_CHANGE_OPERATE_BTN_STATE_EVENT, Param)
            else
                self:ClearPopTimer()
                self:OnOpenPlayerInfoHoverTipPop()
            end
        end
    end
    self.View.GUIImage_Select:SetVisibility(self.CurSelectState and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function CommonHeadIcon:OnItemButtonHovered()
    if self.PlayerId and self.ClickType == CommonHeadIcon.ClickTypeEnum.Operate then
        self:ClearPopTimer()
        local SendOffsetTime = 0.06 -- 0.2s后请求
        self.SendProtoTimer = Timer.InsertTimer(SendOffsetTime,function ()
            self.PersonalInfoCtrl:SendProto_GetPlayerCommonDialogDataReq({self.PlayerId})
        end)
        local OpenOffsetTime = 0.56--固定0.5S后才打开界面
        self.PopTimer = Timer.InsertTimer(OpenOffsetTime,function ()
            self:OnOpenPlayerInfoHoverTipPop()
        end)
    end
end

-- 打开通用弹窗
function CommonHeadIcon:OnOpenPlayerInfoHoverTipPop()
    if not CommonUtil.IsValid(self.View) then
        return
    end
    local Offset = UE.FVector2D(0,0)
    local IconSize = self.View:GetDesiredSize()
    local BgSize =  UE.USlateBlueprintLibrary.GetLocalSize(self.View.GUIImage_HeadBg:GetCachedGeometry())
    -- 水平和垂直方向都有空白区域
    Offset.x = (IconSize.x - BgSize.x)/2
    Offset.y = (IconSize.y - BgSize.y)/2
    
    local SourceViewId = nil
    local ParentHandler = self.Handler.ViewInstance
    while ParentHandler do
        local WidgetBase = ParentHandler.WidgetBase
        if WidgetBase and WidgetBase.IsA and WidgetBase:IsA(UE.UUserWidget) then
            SourceViewId = WidgetBase.viewId
            break
        end
        ParentHandler = ParentHandler.ViewInstance.ParentHandler
    end
    --[[
        PlayerId: 玩家ID 必填
        PlayerName 玩家名字  组队邀请依赖参数
        SourceViewId 头像依赖的界面ID
        IsShowOperateBtn 是否显示操作按钮 选填  默认隐藏
        IsHideBtnOutside [Optional]: 传入true,会隐藏点击空白关闭功能。避免影响上层界面交互 （通常通过Hover打开此界面时需要)
        FocusWidget [Optional]: 附着的节点，传入则会将位置设置在该节点四周可放入位置
        FocusOffset [Optional]: 采样位置偏移 FVector2D
    ]]
    -- 弹窗操作界面
    local Param =  {
        PlayerId = self.PlayerId,
        PlayerName = self.Param.PlayerName,
        SourceViewId = SourceViewId,
        IsShowOperateBtn = self.CurSelectState,
        FocusWidget = self.View,
        FilterOperateList = self.Param.FilterOperateList,
    }
    MvcEntry:OpenView(ViewConst.CommonPlayerInfoHoverTip,Param)
end

function CommonHeadIcon:OnItemButtonUnhovered()
    self:ClearPopTimer()
    if self.PlayerId and self.ClickType == CommonHeadIcon.ClickTypeEnum.Operate then
        if not self.CurSelectState then
            MvcEntry:CloseView(ViewConst.CommonPlayerInfoHoverTip)
        end
    end
end

-- 清除弹窗倒计时器
function CommonHeadIcon:ClearPopTimer()
    if self then
        if self.SendProtoTimer then
            Timer.RemoveTimer(self.SendProtoTimer)
        end
        self.SendProtoTimer = nil 

        if self.PopTimer then
            Timer.RemoveTimer(self.PopTimer)
        end
        self.PopTimer = nil 
    end
end

-- 供外部调用 - 是否显示队长标识
function CommonHeadIcon:UpdateCaptainFlag(IsCaptain)
    self.IsCaptain = IsCaptain
    self.View.Captain:SetVisibility(self.IsCaptain and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-- 好友信息更新
function CommonHeadIcon:OnFriendUpdated()
    self:OnCheckFriend()
    self:UpdateFriendOnlineState()
end

-- 更新好友在线状态
function CommonHeadIcon:UpdateFriendOnlineState()
    if not self.IsFriend then
        return
    end
    local IsOnline = MvcEntry:GetModel(FriendModel):IsFriendOnline(self.PlayerId)
    if self.IsOnline ~= IsOnline then
        self:SetIsOnline(IsOnline)
    end
end

-- 得到状态查询结果
function CommonHeadIcon:OnGetPlayerState(Msg)
    local PlayerId = Msg.PlayerId
    local PlayerStateInfo = Msg.PlayerStateInfo
    if self.PlayerId == PlayerId then
        ---@type UserModel
        local UserModel = MvcEntry:GetModel(UserModel)
        local IsOnline = PlayerStateInfo.Status > Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE
        if self.IsOnline ~= IsOnline then
            self:SetIsOnline(IsOnline)
        end
    end
end

-- 检测是否显示陌生人
function CommonHeadIcon:OnCheckFriend()
    if self.CloseAutoCheckFriendShow or self.IsSelf then
        self:UpdateMask()
        return
    end
    self.IsFriend = MvcEntry:GetModel(FriendModel):IsFriend(self.PlayerId)
    self.IsStranger = not (self.IsFriend or self.IsSelf)
    self.View.Stranger:SetVisibility(self.IsStranger and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self:UpdateMask()
end

-- 更新是否离线
function CommonHeadIcon:UpdateOnlineState()
    -- self.IsOnline = true
    if self.IsSelf or self.CloseOnlineCheck then
        self:SetIsOnline(true)
        return
    end
    self.IsFriend = MvcEntry:GetModel(FriendModel):IsFriend(self.PlayerId)
    if self.IsFriend then
        self:OnFriendUpdated()
    elseif self.Param.PlayerState then
        local IsOnline = self.Param.PlayerState.Status > Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE
        if self.IsOnline ~= IsOnline then
            self:SetIsOnline(IsOnline)
        end
    else
        MvcEntry:GetModel(UserModel):GetPlayerState(self.PlayerId)
    end
end

-- 设置是否离线
function CommonHeadIcon:SetIsOnline(IsOnline)
    if self.IsSelf or self.CloseOnlineCheck then
        IsOnline = true
    end
    self.IsOnline = IsOnline
    self.View.GUIImage_HeadIcon:SetRenderOpacity(self.IsOnline and 1 or 0.6)
    -- 注：蓝图挂载了材质
    local MaterialName = self.IsOnline and "M_UI_CircleMask" or "M_UI_CircleMaskGray"
    if MaterialName ~= self.CurMaterialName then
        -- 此方法会有定时器刷新，增加当前材质名一致的时候不刷新 
        self.CurMaterialName = MaterialName
        local MaterialInstance = self.IsOnline and self.View.CircleMaskMaterialInstance or self.View.CircleMaskGaryMaterialInstance
        -- local MaterialInstPath = StringUtil.Format("/Game/Arts/UI/UIMaterial/MaterialInstance/{0}_Inst.{0}_Inst", MaterialName)
        -- CommonUtil.SetBrushFromSoftMaterialPath(self.View.GUIImage_HeadIcon,MaterialInstPath)
        self.View.GUIImage_HeadIcon:SetBrushFromMaterial(MaterialInstance)
        self:UpdateHeadIcon() 
    end
    -- self.View.TopThing:SetEffectMaterial(MaterialInst)
    self:UpdateMask() 
end

-- 更新遮罩显示状态
function CommonHeadIcon:UpdateMask()
    -- 离线 / 陌生人 需要展示遮罩
    local IsShowMask = not self.IsSelf and (self.IsForceMask or (not self.IsOnline) or self.IsStranger)
    self.View.GUIImage_Mask:SetVisibility(IsShowMask and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-- 外部调用，强制显示遮罩
function CommonHeadIcon:SetIsForceShowMask(IsShow)
    self.IsForceMask = IsShow
    if IsShow then
        self.View.GUIImage_Mask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
    else
        self:UpdateMask()
    end
end


-- 更新头像
function CommonHeadIcon:UpdateHeadIcon()
    -- 是否选择了自定义头像
    if self.SelectPortraitUrl and self.PortraitUrl and self.PortraitUrl ~= "" then
        self.View.GUIImage_HeadIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.IsSendUpdateHead = true
        self.HttpCtrl:SendImageUrlReq(self.PortraitUrl, function(Texture)
            if CommonUtil.IsValid(self.View) and Texture and self.IsSendUpdateHead then 
                self.View.GUIImage_HeadIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                local DynamicMaterial = self.View.GUIImage_HeadIcon:GetDynamicMaterial()
                if DynamicMaterial then
                    DynamicMaterial:SetTextureParameterValue("Target",Texture) 
                end
            end
        end)
    else
        if not self.HeadIconId or self.HeadIconId <= 0 then
            --先不用隐藏
            self.View.GUIImage_HeadIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
            return
        end
        local HeroHeadCfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadIcon,self.HeadIconId)
        if not HeroHeadCfg then
            return
        end
        self.View.GUIImage_HeadIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetMaterialTextureParamSoftObjectPath(self.View.GUIImage_HeadIcon, "Target", HeroHeadCfg[Cfg_HeroHeadConfig_P.IconPath])
    end
end

-- 更新头像框
function CommonHeadIcon:UpdateHeadFrame()
    if not self.HeadFrameId or self.HeadFrameId <= 0 then
        self.View.HeadIconFrame:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    local HeadFrameCfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadFrame,self.HeadFrameId)
    if not HeadFrameCfg then
        self.View.HeadIconFrame:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.View.HeadIconFrame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_HeadFrame,HeadFrameCfg[Cfg_HeadFrameCfg_P.IconPath])
end

-- 更新头像挂件
function CommonHeadIcon:UpdateHeadWidgets()
    if not self.HeadWidgetList or #self.HeadWidgetList == 0 then
        self.View.Panel_Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.View.Panel_Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local ShowWidgetList = {}
    for _,HeadWidgetNode in ipairs(self.HeadWidgetList) do
        local Cfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadWidget,HeadWidgetNode.HeadWidgetId)
        if Cfg then
            local ShowWidgetInfo = {
                HeadWidgetId = HeadWidgetNode.HeadWidgetId, 
                Angle = HeadWidgetNode.Angle,
                Cfg = Cfg,
            }
            table.insert(ShowWidgetList,ShowWidgetInfo)
        end
    end
    local HeadIconSize = self.View.Panel_Widget.Slot:GetSize().X
    HeadWidgetUtil.CreateHeadWidgets(self.View.Panel_Widget, self.View, ShowWidgetList, HeadIconSize/HeadWidgetUtil.DefaultSize) -- 挂件设置界面头像大小/通用头像大小98
end

function CommonHeadIcon:OnGetPlayerDetailInfo(PlayerId)
    if PlayerId ~= self.PlayerId then
        return
    end
    local PlayerInfo = self.PersonalInfoModel:GetPlayerDetailInfo(self.PlayerId)
    if not PlayerInfo then
        return
    end
    -- 名称
    self.PlayerName = PlayerInfo.PlayerName
    if self.Param and self.Param.NeedSyncWidgets and self.Param.NeedSyncWidgets.NameWidget then
        self.Param.NeedSyncWidgets.NameWidget:SetText(StringUtil.Format(self.PlayerName))
    end
    -- 头像
    local HeadIconId = PlayerInfo.HeadId
    local PortraitUrl = PlayerInfo.PortraitUrl
    local SelectPortraitUrl = PlayerInfo.SelectPortraitUrl
    -- 头像ID变化  自定义头像URL发生变化  自定义头像选中状态发生变化
    if (HeadIconId and self.HeadIconId ~= HeadIconId) or (PortraitUrl and PortraitUrl ~= "" and self.PortraitUrl ~= PortraitUrl) or (self.SelectPortraitUrl ~= SelectPortraitUrl)  then
        self.HeadIconId = HeadIconId
        self.PortraitUrl = PortraitUrl
        self.SelectPortraitUrl = SelectPortraitUrl
        self:UpdateHeadIcon()
    end

    -- 头像框
    local HeadFrameId = PlayerInfo.HeadFrameId
    if HeadFrameId and self.HeadFrameId ~= HeadFrameId then
        self.HeadFrameId = HeadFrameId
        self:UpdateHeadFrame()
    end

    -- 头像组件
    local HeadWidgetList = PlayerInfo.HeadWidgetList or {}
    local IsChange = false
    if #HeadWidgetList ~= #self.HeadWidgetList then
        IsChange = true
    else
        for Index,HeadWidgetNode in ipairs(HeadWidgetList) do
            if HeadWidgetNode.HeadWidgetId ~= self.HeadWidgetList[Index].HeadWidgetId
                or HeadWidgetNode.Angle ~= self.HeadWidgetList[Index].Angle then
                IsChange = true
                break
            end
        end        
    end
    if IsChange then
        self.HeadWidgetList = HeadWidgetList
        self:UpdateHeadWidgets()
    end
end

-- 监听界面关闭事件
-- function CommonHeadIcon:OnOtherViewClosed(ViewId)
--     -- 操作菜单界面关闭，隐藏选中图片
--     if ViewId == ViewConst.CommonPlayerInfoHoverTip then
--         self.CurSelectState = false
--         self.View.GUIImage_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
--     end
-- end

function CommonHeadIcon:OnHoverTipsClosed()
    self.CurSelectState = false
    self.View.GUIImage_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function CommonHeadIcon:OnLevelUp(InData)
    if not self.Param.ShowLevel then
        return
    end

    self.Level = InData.Level
    self:UpdateLevelShow()

    if self.Param.ShowUpAni then
        self.View:PlayAnimation(self.View.vx_exp_level_up)
    end
end

function CommonHeadIcon:UpdateLevelShow()
    if self.Param.ShowLevel then
        self.View.Text_Level:SetText(StringUtil.Format(self.Level))
        self.View.LevelRoot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.View.LevelRoot:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 请求打开个人信息界面 
function CommonHeadIcon:OpenPersonalInfo()
    -- 增加个标识，由这个方法触发的请求才需要打开界面
    self.IsSendOpenPersonalInfo = true
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLookUpDetailReq(self.IsSelf and 0 or self.PlayerId)
end

--收到返回的信息，再打开个人中心界面
function CommonHeadIcon:OnOpenPersonalInfoView(TargetPlayerId)
    if not self.IsSendOpenPersonalInfo then return end
    self.IsSendOpenPersonalInfo = false
    if self.PlayerId == TargetPlayerId then
        local Param = {
            PlayerId = self.PlayerId,
            SelectTabId = 1,
            OnShowParam = TargetPlayerId
        }
        MvcEntry:OpenView(ViewConst.PlayerInfo, Param)
    end
end

return CommonHeadIcon
