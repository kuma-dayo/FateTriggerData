--[[
    个人信息
]]
local AchievementPersonItem = require("Client.Modules.Achievement.AchievementPersonItem")
local class_name = "PlayerInfo_PersonInfo"
---@class PlayerInfo_PersonInfo
local PlayerInfo_PersonInfo = BaseClass(nil, class_name)

--个性签名输入框状态
PlayerInfo_PersonInfo.SignatureInputBoxState = {
    --待机状态
    IdleStatus = 0,
    --输入状态
    InputStatus = 1
}

function PlayerInfo_PersonInfo:OnInit()
    self.InputFocus = true
    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,		Func = Bind(self,self.OnUpdateHeroItem) },
		{ UDelegate = self.View.WBP_Friend_Btn_Change.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_ChangeShowHero) },
		{ UDelegate = self.View.WBP_Hot.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_AddHot) },
		{ UDelegate = self.View.WBP_Common_Btn.Btn_List.OnClicked,				Func = Bind(self,self.OnClick_OpenEditView) },
		{ UDelegate = self.View.Button_ID.OnClicked,				Func = Bind(self,self.OnClick_CopyPlayerId) },
		{ UDelegate = self.View.Button_Guest.OnClicked,				Func = Bind(self,self.OnClick_OpenGuestView) },
		{ UDelegate = self.View.WBP_TagEdit.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_TagEdit) },
        -- { UDelegate = self.View.WBP_SignatureEdit.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_SignatureEdit) },
        { UDelegate = self.View.Button_Signature.OnClicked,				Func = Bind(self,self.OnClick_SignatureEdit) },
        { UDelegate = self.View.WBP_Common_Btn_Complete.Btn_List.OnClicked,				Func = Bind(self,self.OnClick_SinatureComplete)},
        { UDelegate = self.View.WBP_Common_Btn_Cancel.Btn_List.OnClicked,				Func = Bind(self,self.OnClick_SinatureCancel)},
        { UDelegate = self.View.WBP_BtnLevel.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_Level)},
        { UDelegate = self.View.BtnOutSide_Signature.OnClicked,				Func = Bind(self,self.OnClick_SinatureCancel)},
    }
    self.MsgList = {
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_SHOW_HERO_CHANGED, Func = self.OnShowHeroChanged},
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_HOT_VALUE_CHANGED, Func = self.OnHotValueChanged},
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_SHOW_SOCIAL_TAG_CHANGED, Func = self.OnShowSocialTagChanged},
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PERSONAL_SIGNATURE_CHANGED, Func = self.OnPersonalSignatureChanged},
        -- {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_GIVE_LIKE_SUCCESS, Func = self.OnLikeChanged},
        {Model = UserModel, MsgName = UserModel.ON_PLAYER_LV_CHANGE, Func = self.OnPlayerLvOrExpChanged},
        {Model = UserModel, MsgName = UserModel.ON_PLAYER_EXP_CHANGE, Func = self.OnPlayerLvOrExpChanged},
        {Model = FriendModel, MsgName = FriendModel.ON_ADD_FRIEND, Func = self.OnFriendUpdate},
        {Model = FriendModel, MsgName = ListModel.ON_DELETED, Func = self.OnFriendUpdate},
        {Model = AchievementModel, MsgName = AchievementModel.ACHIEVE_STATE_CHANGE_ON_SLOT, Func = Bind(self, self.UpdateAchievement)},
        {Model = AchievementModel, MsgName = AchievementModel.ACHIEVE_DATA_UPDATE, Func = Bind(self, self.UpdateAchievement)},
        {Model = AchievementModel, MsgName = AchievementModel.ACHIEVE_PLAYER_DATA_UPDATE, Func = Bind(self, self.UpdateAchievement)},
    }
    ---@type PersonalInfoModel
    self.PersonalModel = MvcEntry:GetModel(PersonalInfoModel)
    
    -- 展示英雄按钮
    self.SetHeroShowBtn = UIHandler.New(self, self.View.WBP_Enter_Hero_Select, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnEnterChangeHero),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_show_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    }).ViewInstance

    UIHandler.New(self, self.View.WBP_CommonBtnTips, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnButtonClicked_Achievement),
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_assemble_Btn"),
        CommonTipsID = CommonConst.CT_X,
        ActionMappingKey = ActionMappings.X,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })

    -- 注册签名输入控件处理
    self.View.EditableText:SetText("")
    self.SignatureInputBox = UIHandler.New(self,self.View,CommonMultiLineTextBoxInput,{
        InputWigetName = "EditableText",
        SizeLimit = PersonalInfoModel.SignatureInputSizeLimit,
        FoucsViewId = ViewConst.PlayerInfo,
        OnTextChangedFunc = Bind(self,self.OnTextChangedFunc),
    }).ViewInstance

    -- 初始化按钮文本
    self.View.WBP_Common_Btn_Cancel.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.WBP_Common_Btn_Cancel.Text_Count:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1048")))

    self.View.WBP_Common_Btn_Complete.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.WBP_Common_Btn_Complete.Text_Count:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "Complete")))
    -- Avatar不同状态下的位置和角度（后续看是否替换成LS）
    self.AvatarTransform = {
        Default = {Location = UE.FVector(80300,-80,4), Rotation = UE.FRotator(0,10,0)},
        Open = { Location = UE.FVector(80230,-80,4), Rotation = UE.FRotator(0,-11,0)}
    }
    -- 主头像
    self.SingleHeadCls = nil
    -- 访客头像
    self.GuestHeadCls = {}
    -- 右侧英雄按钮
    self.RightHeroBtnCls = {}
    -- 左侧列表中英雄按钮 Key为Index 
    self.LeftHeroBtnCls = {}
    -- 左侧列表中复用英雄item Key为Widget
    self.LeftHeroBtnItemList = {}
    -- 展示的英雄列表数据
    self.HeroConfig = MvcEntry:GetModel(HeroModel):GetShowHeroCfgs()

    self.PlayerId = nil
    self.DetailData = nil

    -- 右侧英雄的配置
    self.ShowHeroConfig = {}
    -- 右侧当前选中的英雄Index
    self.SelectShowHeroIndex = 1
    -- 右侧当前选中的英雄Index
    self.SelectShowHeroId = nil

    -- 左侧当前选中的英雄Index
    self.LeftCurSelectHeroIndex = nil
    -- 左侧当前选中的英雄Id
    self.SelectToShowHeroId = nil
    -- 当前展示的Avatar英雄Id
    self.CurAvatarHeroId = nil

    --标签item列表
    self.SocialTagItemList = {}
    --个性签名输入框状态  用于更新UI
    self.SignatureInputState = self.SignatureInputBoxState.IdleStatus
end


function PlayerInfo_PersonInfo:OnShow(TargetPlayerId)
    MvcEntry:GetModel(FriendModel):SetAddFriendModule(GameModuleCfg.PersonInfo.ID)
    self:UpdateUI(TargetPlayerId)
end
function PlayerInfo_PersonInfo:OnRepeatShow(TargetPlayerId)
    -- 重置选中
    if self.RightHeroBtnCls then
        for _,Cls in pairs(self.RightHeroBtnCls) do
            Cls:UnSelect()
        end
    end
    self:UpdateUI(TargetPlayerId)
end

function PlayerInfo_PersonInfo:OnHide()
    self.SingleHeadCls = nil
    self.GuestHeadCls = {}
    self.RightHeroBtnCls = {}
    self:OnHideAvatorInner()
    self.PersonalModel:DispatchType(PersonalInfoModel.SET_ADD_FRIEND_BTN_ISSHOW,false)
    MvcEntry:GetModel(FriendModel):ClearAddFriendModule(GameModuleCfg.PersonInfo.ID)
end

function PlayerInfo_PersonInfo:UpdateUI(TargetPlayerId)
    self.PlayerId = TargetPlayerId
    self.DetailData = self.PersonalModel:GetPlayerDetailInfo(TargetPlayerId)
    if not self.DetailData then
        CError("PlayerInfo_PersonInfo GetPlayerDetailInfo Error!",true)
        return
    end
    self.IsSelf = TargetPlayerId == MvcEntry:GetModel(UserModel):GetPlayerId()
    local IsShowAddFriend = not (self.IsSelf or MvcEntry:GetModel(FriendModel):IsFriend(TargetPlayerId))
    self.PersonalModel:DispatchType(PersonalInfoModel.SET_ADD_FRIEND_BTN_ISSHOW,IsShowAddFriend)
    self:RegisterRedDot()
    self:SwitchHeroListOpenState(false)
    self:UpdateIsSelf()
    self:UpdateDetailLayer()
    self:UpdateShowHero()
    self:UpdateAchievement()
    self:UpdateRankInfo()
    self:UpdatetSocialTagShow()
    self:UpdateSignatureText()
    self:UpdateSignatureUI()    
end

-- 注册红点
function PlayerInfo_PersonInfo:RegisterRedDot()
    if self.IsSelf then
        self.View.WBP_RedDotFactoryPersonal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.WBP_RedDotFactoryLevel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if not self.PersonalRedDot then
            self.PersonalRedDot = UIHandler.New(self, self.View.WBP_RedDotFactoryPersonal, CommonRedDot, {RedDotKey = "InformationPersonal", RedDotSuffix = ""}).ViewInstance
        end
        if not self.LevelRedDot then
            self.LevelRedDot = UIHandler.New(self, self.View.WBP_RedDotFactoryLevel, CommonRedDot, {RedDotKey = "InformationLevel", RedDotSuffix = ""}).ViewInstance
        end
    else
        self.View.WBP_RedDotFactoryPersonal:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.WBP_RedDotFactoryLevel:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function PlayerInfo_PersonInfo:GetViewKey()
    return ViewConst.PlayerInfo * 100 + PlayerInfoModel.Enum_SubPageCfg.PersonalInfoPage.Id
end

-- 处理只有查看自己才出现的元素
function PlayerInfo_PersonInfo:UpdateIsSelf()
    self.View.WBP_CommonBtnTips:SetVisibility((MvcEntry:GetCtrl(AchievementCtrl).IsOpen and self.IsSelf) and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    self.View.WBP_Common_Btn:SetVisibility(self.IsSelf and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    self.View.WBP_Friend_Btn_Change:SetVisibility(self.IsSelf and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    -- self.View.WBP_Hot.GUIButton_Main:SetIsEnabled(not self.IsSelf)
    self.View.WidgetSwitcher_Hot:SetActiveWidget(self.IsSelf and self.View.Panel_Hot or self.View.Panel_Hot_Other)
    
    --标签&签名相关
    self.View.WBP_TagEdit:SetVisibility(self.IsSelf and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    -- self.View.WBP_SignatureEdit:SetVisibility(self.IsSelf and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    self.View.Button_Signature:SetVisibility(self.IsSelf and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    self.View.WBP_BtnLevel:SetVisibility(self.IsSelf and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    
    self.View.WBP_Common_Btn_Cancel:SetVisibility(self.IsSelf and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.WBP_Common_Btn_Complete:SetVisibility(self.IsSelf and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.WidgetSwitcher:SetVisibility(self.IsSelf and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-- 更新详情模块
function PlayerInfo_PersonInfo:UpdateDetailLayer()
    -- 头像
    local Param = {
        PlayerId = self.DetailData.PlayerId,
        CloseOnlineCheck = true,
        CloseAutoCheckFriendShow = true,
        ClickType = CommonHeadIcon.ClickTypeEnum.None
    }
    if not self.SingleHeadCls then
        self.SingleHeadCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.SingleHeadCls:UpdateUI(Param)
    end
    -- 名字
    self.View.Text_PlayerName:SetText(self.DetailData.PlayerName)

    -- 等级&经验
    self:UpdateLvAndExp()
    
    
    -- ID - 三态文本，待加入动效后移除多余状态
    self.View.Text_PlayerID1:SetText(self.DetailData.PlayerId)
    self.View.Text_PlayerID2:SetText(self.DetailData.PlayerId)
    self.View.Text_PlayerID3:SetText(self.DetailData.PlayerId)
    -- 热度
    self.View.Text_AddHot:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Text_Hot:SetText(StringUtil.FormatNumberStr(self.DetailData.LikeHeartTotal))
    self.View.Text_Hot_Other:SetText(StringUtil.FormatNumberStr(self.DetailData.LikeHeartTotal))
    -- 点赞
    self.View.Text_LikeNum:SetText(StringUtil.FormatNumberStr(self.DetailData.LikeTotal))
    -- 访客
    self:UpdateGuestInfo()
end

-- 更新等级和经验
function PlayerInfo_PersonInfo:UpdateLvAndExp()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local MaxLevel = UserModel:GetPlayerMaxCfgLevel()
    local IsMaxLevel = self.DetailData.Level >= MaxLevel
    self.View.Switcher_Level:SetActiveWidget(IsMaxLevel and self.View.Panel_Finish or self.View.Panel_Lv)
    if not IsMaxLevel then
        self.View.Text_Level:SetText(self.DetailData.Level)
        local MaxExp = UserModel:GetPlayerMaxExpForLv(self.DetailData.Level)
        self.View.Text_Progress1:SetText(self.DetailData.Experience)
        self.View.Text_Progress2:SetText(MaxExp)
        self.View.ProgressBar_Level:SetPercent(self.DetailData.Experience/MaxExp)
    end
end

-- 更新访客信息
function PlayerInfo_PersonInfo:UpdateGuestInfo()
    local RecentVisitorList = self.DetailData.RecentVisitorList
    local TextStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_Visitrecently")
    if #RecentVisitorList == 0 then
        TextStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_Novisitorsforthetime")
        self.View.Guest_List:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.View.Guest_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local Index = 1
        -- for _,RecentVisitorNode in ipairs(RecentVisitorList) do
        for I = #RecentVisitorList,1,-1 do
            if Index > 3 then
                -- 这里最多显示3个
                break
            end
            local RecentVisitorNode = RecentVisitorList[I]
            local WBP_Head = self.View["WBP_Guest_Head_"..Index]
            WBP_Head:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            local Param = {
                PlayerId = RecentVisitorNode.PlayerId,
                CloseOnlineCheck = true,
                CloseAutoCheckFriendShow = true,
            }
            if not self.GuestHeadCls[Index] then
                self.GuestHeadCls[Index] = UIHandler.New(self,WBP_Head, CommonHeadIcon,Param).ViewInstance
            else
                self.GuestHeadCls[Index]:UpdateUI(Param)
            end
            Index = Index + 1
        end

        while self.View["WBP_Guest_Head_"..Index] do
            self.View["WBP_Guest_Head_"..Index]:SetVisibility(UE.ESlateVisibility.Collapsed)
            Index = Index + 1
        end
    end
    -- 三态文本，待加入动效后移除多余状态
    self.View.Text_Guest:SetText(StringUtil.Format(TextStr))
end

-- 更新展示英雄列表
function PlayerInfo_PersonInfo:UpdateShowHero()
    ---@type HeroModel
    local HeroModel = MvcEntry:GetModel(HeroModel)
    local ShowHeroList = self.DetailData.ShowHeroList
    self.ShowHeroConfig = {}
    for Index, ShowHeroNode in ipairs(ShowHeroList) do
        local Widget = self.View["WBP_HeadButtonWidget"..Index]
        if Widget then
            local ConfigData = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, ShowHeroNode.HeroId) 
            if ConfigData then
                self.ShowHeroConfig[Index] = ConfigData
                local Param  = {
                    Data = ConfigData,
                    HeroSkinId = ShowHeroNode.HeroSkinId,
                    ClickFunc = Bind(self, self.OnRightHeroItemClick, Index),
                }
                if not self.RightHeroBtnCls[Index] then
                    self.RightHeroBtnCls[Index] = UIHandler.New(self,Widget, require("Client.Modules.PlayerInfo.PersonalInfo.Item.HeroHeadBtn"),Param).ViewInstance
                end
                self.RightHeroBtnCls[Index]:SetData(Param)
            else
                CError("PlayerInfo_PersonInfo:UpdateShowHero GetHeroCfg Error For id = "..ShowHeroNode.HeroId,true)
            end
        end
    end
    -- 初始化点击
    self.SelectShowHeroIndex = 1
    self:OnRightHeroItemClick(self.SelectShowHeroIndex,true)
end

-- 点击右侧展示英雄
function PlayerInfo_PersonInfo:OnRightHeroItemClick(Index,IsInit)
    if not IsInit and self.SelectShowHeroIndex == Index then
        return
    end
    if not IsInit and self.SelectShowHeroIndex and self.RightHeroBtnCls[self.SelectShowHeroIndex] then
        self.RightHeroBtnCls[self.SelectShowHeroIndex]:UnSelect()
    end
    
    local ShowHeroNode = self.DetailData.ShowHeroList[Index]
    if not ShowHeroNode then
        return
    end
    self.SelectShowHeroIndex = Index
    self.RightHeroBtnCls[self.SelectShowHeroIndex]:Select()
    self.SelectShowHeroId = ShowHeroNode.HeroId

    if self.IsHeroListOpen then
        -- 更新展开的英雄列表的选中状态
        self:ResetToSelectCurShowHero()
    else
        --  更新Avatar 
        self:UpdateShowAvatar()
        -- 更新英雄名称
        if self.ShowHeroConfig[self.SelectShowHeroIndex] then
            self.View.Text_HeroName:SetText(StringUtil.Format(self.ShowHeroConfig[self.SelectShowHeroIndex][Cfg_HeroConfig_P.Name]))
        end
    end
end

-- 点击改变展示英雄按钮
function PlayerInfo_PersonInfo:OnClick_ChangeShowHero()
    self:SwitchHeroListOpenState(true)
    if not self.LeftHeroBtnCls or #self.LeftHeroBtnCls == 0 then
        self:InitHeroList()
    end
    self:ResetToSelectCurShowHero()
end

-- 初始化可选的英雄列表
function PlayerInfo_PersonInfo:InitHeroList()
    if not self.HeroConfig or #self.HeroConfig == 0 then
        return
    end
    self.View.WBP_ReuseList:Reload(#self.HeroConfig)
    -- local Index = 1
    -- for I = 1, #self.HeroConfig do
    --     local Widget = self.View["WBP_HeroListBtn_"..Index]
    --     if Widget then
    --         Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --         local ConfigData = self.HeroConfig[Index]
    --         local Param  = {
    --             Data = ConfigData,
    --             ClickFunc = Bind(self, self.OnLeftHeroItemClick, Index),
    --             Index = Index,
    --             ExtraData = {
    --                 isLocked = not HeroModel:CheckGotHeroById(ConfigData[Cfg_HeroConfig_P.Id])
    --             }
    --         }
    --         self.LeftHeroBtnCls[Index] = UIHandler.New(self,Widget, require("Client.Modules.Hero.HeroListBtn")).ViewInstance
    --         self.LeftHeroBtnCls[Index]:SetData(Param)
    --     else
    --         CError(" PlayerInfo_PersonInfo InitHeroList widget error for index = "..Index,true)
    --     end
    --     Index = Index + 1
    -- end
    -- while self.View["WBP_HeroListBtn_"..Index] do
    --     self.View["WBP_HeroListBtn_"..Index]:SetVisibility(UE.ESlateVisibility.Collapsed)
    --     self.LeftHeroBtnCls[Index] = nil
    --     Index = Index + 1
    -- end
end

function PlayerInfo_PersonInfo:OnUpdateHeroItem(Handler,Widget, Index)
	local FixIndex = Index + 1

	local TargetItem = self:CreateHeroItem(Widget)
	if TargetItem == nil then
		return
	end
    local ConfigData = self.HeroConfig[FixIndex]
    local Param  = {
        Data = ConfigData,
        ClickFunc = Bind(self, self.OnLeftHeroItemClick, FixIndex),
        Index = FixIndex,
        ExtraData = {
            isLocked = not HeroModel:CheckGotHeroById(ConfigData[Cfg_HeroConfig_P.Id])
        }
    }
    TargetItem:SetData(Param)
    self.LeftHeroBtnCls[FixIndex] = TargetItem
end

function PlayerInfo_PersonInfo:CreateHeroItem(Widget)
    local Item = self.LeftHeroBtnItemList[Widget]
    if not Item then
        Item = UIHandler.New(self,Widget, require("Client.Modules.Hero.HeroListBtn"))
        self.LeftHeroBtnItemList[Widget] = Item
    end
    return Item.ViewInstance
end

-- 点击左侧展示英雄
function PlayerInfo_PersonInfo:OnLeftHeroItemClick(Index, IsReset)
    if not IsReset and self.LeftCurSelectHeroIndex == Index then
        return
    end

    if self.LeftCurSelectHeroIndex and self.LeftHeroBtnCls[self.LeftCurSelectHeroIndex] then
        self.LeftHeroBtnCls[self.LeftCurSelectHeroIndex]:UnSelect()
    end
    self.LeftCurSelectHeroIndex = Index
    if self.LeftHeroBtnCls[Index] then
        self.LeftHeroBtnCls[Index]:Select()
    end
    local HeroCfg = self.HeroConfig[Index]
    if HeroCfg then
        local HeroId = HeroCfg[Cfg_HeroConfig_P.Id]
        self.SelectToShowHeroId = HeroId
        if HeroId == self.SelectShowHeroId then
            self.View.WidgetSwitcher_Select:SetActiveWidget(self.View.Text_Select)
        else
            self.View.WidgetSwitcher_Select:SetActiveWidget(self.View.Btn_Select)
            local IsGotHero = MvcEntry:GetModel(HeroModel):CheckGotHeroById(HeroId)
            self.SetHeroShowBtn:SetBtnEnabled(IsGotHero, IsGotHero and G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_show_Btn") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_Notunlockedyet_Btn"))
        end

        -- 更新Avatar
        self:UpdateShowAvatar()
        -- 更新英雄名字
        self.View.Text_HeroName:SetText(StringUtil.Format(HeroCfg[Cfg_HeroConfig_P.Name]))
    end
end

-- 左侧列表 选中 右侧当前选中的英雄
function PlayerInfo_PersonInfo:ResetToSelectCurShowHero()
    local SelectIndex = nil
    for Index = 1, #self.HeroConfig do
        local HeroId = self.HeroConfig[Index][Cfg_HeroConfig_P.Id]
        if HeroId == self.SelectShowHeroId then
            SelectIndex = Index
            break
        end
    end
    if not SelectIndex then
        CError("ResetToSelectCurShowHero no hero match for id = "..self.SelectShowHeroId,true)
        return
    end
    self:OnLeftHeroItemClick(SelectIndex, true)
end

function PlayerInfo_PersonInfo:UpdateAchievement()
    self.AchieveViewIns = self.AchieveViewIns or {}
    for i = 1, 3 do
        repeat
            local WidgetSwitcher_Achievement = self.View["WidgetSwitcher_Achievement_"..i] 
            local EmptyWidget = self.View["Panel_Achievement_Empty_"..i]
            local Widget = self.View["WBP_Achievement_Person_Item_"..i]
            local AhicId = MvcEntry:GetModel(AchievementModel):GetPlayerSlotAchieveId(i, self.PlayerId)
            if not MvcEntry:GetCtrl(AchievementCtrl).IsOpen or not AhicId or AhicId < 1 then
                WidgetSwitcher_Achievement:SetActiveWidget(EmptyWidget)
                break
            end
            WidgetSwitcher_Achievement:SetActiveWidget(Widget)

            local Params = {
                AhicId = AhicId,
                PlayerId = self.PlayerId,
                NeedHideName = true
            }
            if not self.AchieveViewIns[i] then
                self.AchieveViewIns[i] = UIHandler.New(self, Widget, AchievementPersonItem, Params).ViewInstance
            else
                self.AchieveViewIns[i]:UpdateUI(Params)
            end
        until true
    end
end

function PlayerInfo_PersonInfo:Update()
    
end


-- 确认展示英雄按钮
function PlayerInfo_PersonInfo:OnEnterChangeHero()
    if  not CommonUtil.GetWidgetIsVisibleReal(self.View.WBP_Enter_Hero_Select) then
        return
    end
    local ShowHeroNode = self.DetailData.ShowHeroList[self.SelectShowHeroIndex]
    if not ShowHeroNode then
        return
    end
    local Msg = {
        HeroId = self.SelectToShowHeroId,
        Slot = ShowHeroNode.Slot,
    }
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_HeroSelectShowReq(Msg)
end

-- 更新展示的英雄
function PlayerInfo_PersonInfo:OnShowHeroChanged(Slot)
    self:SwitchHeroListOpenState(false)
    self.DetailData = self.PersonalModel:GetPlayerDetailInfo(self.PlayerId)
    if not self.DetailData then
        CError("PlayerInfo_PersonInfo GetPlayerDetailInfo Error!",true)
        return
    end

    local ShowHeroNode = self.DetailData.ShowHeroList[Slot]
    self.SelectShowHeroId = ShowHeroNode.HeroId
    local ConfigData = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, ShowHeroNode.HeroId) 
    if ConfigData then
        self.ShowHeroConfig[Slot] = ConfigData
        if self.RightHeroBtnCls[Slot] then
            local Param  = {
                Data = ConfigData,
                HeroSkinId = ShowHeroNode.HeroSkinId,
            }
            self.RightHeroBtnCls[Slot]:UpdateData(Param)
        end
        -- 更新Avatar
        self:UpdateShowAvatar()
    end
end

-- 判断是关闭界面还是关闭选择列表
function PlayerInfo_PersonInfo:NeedToHandleClose()
    if self.IsHeroListOpen then
        if self.SelectShowHeroId ~= self.SelectToShowHeroId then
            self:ResetToSelectCurShowHero()
        end
        self:SwitchHeroListOpenState(false)
        return true
    end
    return false
end

-- 开关选择列表
function PlayerInfo_PersonInfo:SwitchHeroListOpenState(IsOpen)
    self.View.WidgetSwitcher_State:SetActiveWidget(IsOpen and self.View.Select or self.View.Detail)
    self.IsHeroListOpen = IsOpen
    self.View.Text_HeroName:SetVisibility(IsOpen and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.WBP_Friend_Btn_Change:SetVisibility(IsOpen and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    if self.CurShowAvatar then
        local TransformData = IsOpen and self.AvatarTransform.Open or self.AvatarTransform.Default
        local ToTransform = self.CurShowAvatar:GetTransform()
        self.CurShowAvatar:K2_SetActorLocationAndRotation(TransformData.Location,TransformData.Rotation, false, nil, false)
    end
end

-- 热度值变化
function PlayerInfo_PersonInfo:OnHotValueChanged(Param)
    if Param.TargetPlayerId ~= self.DetailData.PlayerId then
        return
    end
    self.View.Text_Hot:SetText(StringUtil.FormatNumberStr(Param.LikeHeartTotal))
    self.View.Text_Hot_Other:SetText(StringUtil.FormatNumberStr(Param.LikeHeartTotal))
    self:PlayHotAddAnimation()
end

--展示的标签发生变化 需要更新UI
function PlayerInfo_PersonInfo:OnShowSocialTagChanged()
    self:UpdatetSocialTagShow()
end

-- 个性签名发生变化 更新UI
function PlayerInfo_PersonInfo:OnPersonalSignatureChanged()
    if self.IsSelf then 
        self:UpdateSignatureText()
        self:UpdateSignatureUI()
    end
end

-- 点赞变化
-- function PlayerInfo_PersonInfo:OnLikeChanged(Param)
--     if Param.TargetPlayerId ~= self.DetailData.PlayerId then
--         return
--     end
-- end

-- 播放热度值增加效果
function PlayerInfo_PersonInfo:PlayHotAddAnimation()
    self.View:StopAnimation(self.View.Vx_HotAdd)
    self.View:PlayAnimation(self.View.Vx_HotAdd)
end

-- 点击打开个性化面板按钮
function PlayerInfo_PersonInfo:OnClick_OpenEditView()
    MvcEntry:OpenView(ViewConst.HeadIconSetting)
end

-- 点击复制id按钮
function PlayerInfo_PersonInfo:OnClick_CopyPlayerId()
    UE.UGFUnluaHelper.ClipboardCopy(StringUtil.ConvertFText2String(self.View.Text_PlayerID1:GetText()))
    UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfo_Copysucceeded"))
end

-- 点击增加热度值
function PlayerInfo_PersonInfo:OnClick_AddHot()
    if self.IsSelf then
        -- 自己只播效果，数据不变
        -- 需求修改 点击自己不交互
        -- self:PlayHotAddAnimation()
    else
        MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLikeHeartReq(self.DetailData.PlayerId)
    end
end

-- 点击访客按钮
function PlayerInfo_PersonInfo:OnClick_OpenGuestView()
    MvcEntry:OpenView(ViewConst.GuestList,self.PlayerId)
end

-- 点击标签编辑按钮
function PlayerInfo_PersonInfo:OnClick_TagEdit()
    if self.IsSelf then
        local Param = {
            PlayerId = self.PlayerId,
            SelectTabId = PersonInfoCommonPopMdt.TabTypeEnum.SocialTag
        }
        MvcEntry:OpenView(ViewConst.PersonInfoCommonPopMdt, Param)
    end
end

-- 点击个人签名编辑按钮
function PlayerInfo_PersonInfo:OnClick_SignatureEdit()
    if self.IsSelf then
        if MvcEntry:GetModel(NewSystemUnlockModel):IsSystemUnlock(ViewConst.SystemUnlockPersonalSinature,true) then
            self.SignatureInputState = self.SignatureInputBoxState.InputStatus
            self:UpdateSignatureUI()
            self.View.EditableText:SetKeyboardFocus()
            local SignatureText = self.PersonalModel:GetMySelfPersonalSignature()
            local ShowSignatureText = SignatureText or ""
            self.View.EditableText:SetText(ShowSignatureText)
            self:UpdateInputTextNumTip()
        end
    end
end

-- 点击签名编辑完成按钮
function PlayerInfo_PersonInfo:OnClick_SinatureComplete()
    if self.IsSelf then
        self.SignatureInputState = self.SignatureInputBoxState.IdleStatus
        self:UpdateSignatureUI()

        local InputText = self.View.EditableText:GetText()
        MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_SetPersonalReq(InputText)

        self:OnShowSinatureAuditState(InputText)
    end
end

-- 服务器没回包前显示审核状态
function PlayerInfo_PersonInfo:OnShowSinatureAuditState(InputText)
    local ActiveWidget = self.View.Panel_UnderReview
    self.View.WidgetSwitcher:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.WidgetSwitcher:SetActiveWidget(ActiveWidget)

    self.View.Text_Signature:SetText(StringUtil.Format(InputText))
end

-- 点击签名编辑取消按钮
function PlayerInfo_PersonInfo:OnClick_SinatureCancel()
    if self.IsSelf then
        self.SignatureInputState = self.SignatureInputBoxState.IdleStatus
        self:UpdateSignatureUI()
        -- self.View.EditableText:SetText("")
    end
end

-- 点击等级按钮
function PlayerInfo_PersonInfo:OnClick_Level()
    if self.IsSelf then
        MvcEntry:OpenView(ViewConst.PlayerLevelGrowthMdt)
    end
end

-------------- avatar相关 -----------------------
function PlayerInfo_PersonInfo:OnShowAvator(Param,IsNotVirtualTrigger)
    self:UpdateShowAvatar(true)
end

function PlayerInfo_PersonInfo:OnHideAvator(Param,IsNotVirtualTrigger)
    self:OnHideAvatorInner()
end

function PlayerInfo_PersonInfo:UpdateShowAvatar()
    local HeroId = self.IsHeroListOpen and self.SelectToShowHeroId or self.SelectShowHeroId
    if not HeroId or HeroId == self.CurAvatarHeroId then
        return
    end
    local TblHero = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroConfig, Cfg_HeroConfig_P.Id, HeroId)
    if not TblHero then
        return
    end
    local SkinId = nil
    if self.IsHeroListOpen then
        -- 选自己展示的英雄，皮肤取英雄系统选中穿戴的
        SkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(HeroId)
    else
       -- 查看别人的
       local ShowHeroNode = self.DetailData.ShowHeroList[self.SelectShowHeroIndex]
       if ShowHeroNode then
           SkinId = ShowHeroNode.HeroSkinId
       end
    end
    if not SkinId then
        CError("PlayerInfo_PersonInfo:UpdateShowAvatar GetSkinId Error For HeroId = "..HeroId,true)
        return
    end
    self:OnHideAvatorInner()
    self.CurAvatarHeroId = HeroId
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    local AvatarTransform = self.IsHeroListOpen and self.AvatarTransform.Open or self.AvatarTransform.Default
    local SpawnHeroParam = {
        ViewID = self:GetViewKey(),
        InstID = 0,
        HeroId = HeroId,
        SkinID = SkinId,
        Location = AvatarTransform.Location,
        Rotation = AvatarTransform.Rotation
    }
    self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    self:UpdateShowAvatarAction()
end

function PlayerInfo_PersonInfo:OnHideAvatorInner()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    HallAvatarMgr:HideAvatarByViewID(self:GetViewKey())
end

function PlayerInfo_PersonInfo:UpdateShowAvatarAction()
    self.CurShowAvatar:OpenOrCloseCameraAction(false)
    self.CurShowAvatar:OpenOrCloseAvatorRotate(false)
    self.CurShowAvatar:OpenOrCloseGestureAction(true)
end

function PlayerInfo_PersonInfo:OnPlayerLvOrExpChanged()
    if self.PlayerId == MvcEntry:GetModel(UserModel):GetPlayerId() then
        self.DetailData = self.PersonalModel:GetPlayerDetailInfo(self.PlayerId)
        if not self.DetailData then
            CError("PlayerInfo_PersonInfo GetPlayerDetailInfo Error!",true)
            return
        end
        self:UpdateLvAndExp()
    end
end

function PlayerInfo_PersonInfo:OnClickAddFriendBtn()
    if not self.IsSelf and self.PlayerId then
        MvcEntry:GetCtrl(FriendCtrl):SendProto_AddFriendReq(self.PlayerId)
    end
end

function PlayerInfo_PersonInfo:OnFriendUpdate()
    local IsShowAddFriend = self.IsSelf and not MvcEntry:GetModel(FriendModel):IsFriend(TargetPlayerId)
    self.PersonalModel:DispatchType(PersonalInfoModel.SET_ADD_FRIEND_BTN_ISSHOW,IsShowAddFriend)
end

function PlayerInfo_PersonInfo:OnButtonClicked_Achievement()
    MvcEntry:OpenView(ViewConst.AchievementAssemble)
end

function PlayerInfo_PersonInfo:OnTextChangedFunc(InputBox,InputTxt)
    if not CommonUtil.IsValid(self.View) then
        return
    end
    self:UpdateInputTextNumTip()
end

--更新排位信息展示
function PlayerInfo_PersonInfo:UpdateRankInfo()
    local MaxDivisionInfo = self.PersonalModel:GetMaxRankDivisionInfo(self.PlayerId)
    if MaxDivisionInfo then
        local MaxDivisionId = MaxDivisionInfo.MaxDivisionId
        self.View.WidgetSwitcher_Rank:SetActiveWidget(self.View.Panel_RankInfo)
        ---@type SeasonRankModel
        local SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)
        local DivisionIconPath = SeasonRankModel:GetDivisionIconPathByDivisionId(MaxDivisionId)
        if DivisionIconPath and DivisionIconPath ~= "" then
            CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Rank, DivisionIconPath) 
        end
        local DivisionName = SeasonRankModel:GetDivisionNameByDivisionId(MaxDivisionId)
        local RankModeName = SeasonRankModel:GetRankModeNameByPlayModeId(MaxDivisionInfo.PlayModeId)
        --段位名称
        self.View.Text_RankName:SetText(StringUtil.Format(DivisionName))
        --排位模式名称
        self.View.Text_RankMode:SetText(StringUtil.Format(RankModeName))
    else
        self.View.WidgetSwitcher_Rank:SetActiveWidget(self.View.Panel_RankEmpty)
    end

    local RankStatistics = self.DetailData.RankStatistics
    -- 排位统计数据
    if RankStatistics then
        ---@type PersonalStatisticsModel
        local PersonalStatisticsModel = MvcEntry:GetModel(PersonalStatisticsModel)
        local TopFiveRate = RankStatistics.RecordsNum > 0 and RankStatistics.Top5Num / RankStatistics.RecordsNum or 0
        local TopFiveRateStr = string.format("%.2f", TopFiveRate*100)
        self.View.Text_TopFive:SetText(StringUtil.Format("{0}%", TopFiveRateStr))
        self.View.Text_TopKill:SetText(StringUtil.FormatNumberWithComma(RankStatistics.TotKill))
        self.View.Text_SeasonRecordsNum:SetText(StringUtil.FormatNumberWithComma(RankStatistics.RecordsNum))
    end
end

--更新社交标签展示
function PlayerInfo_PersonInfo:UpdatetSocialTagShow()
    local SocialTagInfoList = self.DetailData.TagIdList or {}
    -- self.View.GUICanvasPanel_Tag:SetVisibility(IsHasTag and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    for _, SocialTagItem in pairs(self.SocialTagItemList) do
        if SocialTagItem and SocialTagItem.View then
            SocialTagItem.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    if SocialTagInfoList then
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
                self.View.WrapBox_Tag:AddChild(Widget)
                Item = UIHandler.New(self,Widget,require(PersonalInfoModel.SocialTagBtnItem.LuaClass),Param).ViewInstance
                self.SocialTagItemList[Index] = Item
            end
            Item.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            Item:OnShow(Param)
        end
    end
end

--更新服务器保存的个人签名
function PlayerInfo_PersonInfo:UpdateSignatureText()
    local ShowSignatureText = ""
    if self.IsSelf then
        local SignatureText = self.PersonalModel:GetMySelfPersonalSignature()
        ShowSignatureText = SignatureText or ""
    else
        ShowSignatureText = self.DetailData.Personal or ""
    end
    self.View.Text_Signature:SetText(StringUtil.Format(ShowSignatureText))
    -- self.View.EditableText:SetText(ShowSignatureText)
end

--更新个人签名UI的状态
function PlayerInfo_PersonInfo:UpdateSignatureUI()
    if self.IsSelf then 
        if self.SignatureInputState == self.SignatureInputBoxState.IdleStatus then
            self.View.Text_Signature:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.WBP_Common_Btn_Cancel:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.WBP_Common_Btn_Complete:SetVisibility(UE.ESlateVisibility.Collapsed)            -- self.View.WBP_SignatureEdit:SetVisibility(UE.ESlateVisibility.Visible)
            self.View.EditableText:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.WidgetSwitcher:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.BtnOutSide_Signature:SetVisibility(UE.ESlateVisibility.Collapsed)
        elseif self.SignatureInputState == self.SignatureInputBoxState.InputStatus then 
            self.View.Text_Signature:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.WBP_Common_Btn_Cancel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.WBP_Common_Btn_Complete:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.WidgetSwitcher:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

            self.View.WidgetSwitcher:SetActiveWidget(self.View.RichText_InputTextTip)
            -- self.View.WBP_SignatureEdit:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.EditableText:SetVisibility(UE.ESlateVisibility.Visible)
            self.View.BtnOutSide_Signature:SetVisibility(UE.ESlateVisibility.Visible)
        end 
    else
        self.View.EditableText:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.BtnOutSide_Signature:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

--更新可输入字符提示
function PlayerInfo_PersonInfo:UpdateInputTextNumTip()
    local InputText = self.View.EditableText:GetText()
    local TexNum = StringUtil.utf8StringLen(InputText)
    local SurplusTextNum = tonumber(PersonalInfoModel.SignatureInputSizeLimit) - TexNum
    SurplusTextNum = SurplusTextNum >= 0 and SurplusTextNum or 0
    local TipText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1030")
    local SurplusTextNumText = StringUtil.FormatSimple("<span color=\"#E47A30\">{0}</>",SurplusTextNum)
    self.View.RichText_InputTextTip:SetText(StringUtil.Format(TipText,SurplusTextNumText))
end

return PlayerInfo_PersonInfo

