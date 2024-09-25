--[[
    个人数据模型
]]

local super = GameEventDispatcher;
local class_name = "PersonalInfoModel";

---@class PersonalInfoModel : GameEventDispatcher
---@field private super GameEventDispatcher
---@type PersonalInfoModel
PersonalInfoModel = BaseClass(super, class_name)
PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED = "ON_PLAYER_BASE_INFO_CHANGED" -- 基础信息变化
PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID = "ON_PLAYER_BASE_INFO_CHANGED_FOR_ID" -- 基础信息变化 - 携带id
PersonalInfoModel.ON_PLAYER_DETAIL_INFO_CHANGED = "ON_PLAYER_DETAIL_INFO_CHANGED" -- 详细信息变化
PersonalInfoModel.ON_PLAYER_COMMON_DIALOG_INFO_CHANGED_FOR_ID = "ON_PLAYER_COMMON_DIALOG_INFO_CHANGED_FOR_ID" -- 交互弹窗数据信息变化 - 携带id
PersonalInfoModel.ON_SHOW_HERO_CHANGED = "ON_SHOW_HERO_CHANGED" -- 展示英雄变化
PersonalInfoModel.ON_HOT_VALUE_CHANGED = "ON_HOT_VALUE_CHANGED" -- 热度值变化
PersonalInfoModel.ON_GIVE_LIKE_SUCCESS = "ON_GIVE_LIKE_SUCCESS" -- 点赞成功
PersonalInfoModel.SET_ADD_FRIEND_BTN_ISSHOW = "SET_ADD_FRIEND_BTN_ISSHOW" -- (界面使用)是否显示添加好友按钮
PersonalInfoModel.ON_SHOW_SOCIAL_TAG_CHANGED = "ON_SHOW_SOCIAL_TAG_CHANGED" -- 展示的社交标签变化
PersonalInfoModel.ON_SOCIAL_TAG_UNLOCK_STATE_CHANGED = "ON_SOCIAL_TAG_UNLOCK_STATE_CHANGED" -- 社交标签解锁状态变化
PersonalInfoModel.ON_PERSONAL_SIGNATURE_CHANGED = "ON_PERSONAL_SIGNATURE_CHANGED" -- 自己的个性签名变化
PersonalInfoModel.ON_CUSTOM_HEAD_INFO_CHANGED = "ON_CUSTOM_HEAD_INFO_CHANGED" -- 自定义头像信息发生变化
PersonalInfoModel.ON_COMMON_HEAD_CHANGE_OPERATE_BTN_STATE_EVENT = "ON_COMMON_HEAD_CHANGE_OPERATE_BTN_STATE_EVENT" -- 通用头像触发改变操作按钮状态事件 - 携带玩家id 以及按钮状态
PersonalInfoModel.ON_PLAYER_INFO_HOVER_TIPS_CLOSED_EVENT = "ON_PLAYER_INFO_HOVER_TIPS_CLOSED_EVENT" -- 通用头像菜单关闭事件

--个人信息-社交标签item信息
PersonalInfoModel.SocialTagBtnItem = {
    UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/WBP_Imformation_EditTagBtn.WBP_Imformation_EditTagBtn",
    LuaClass = "Client.Modules.PlayerInfo.PersonalInfo.Item.PersonalInfoTagItem",
}

--个人信息-社交标签item 展示类型
PersonalInfoModel.Enum_SocialTagItemShowType = {
    --只能展示
    Only_Show = 1,
    --只能删除 (显示删除按钮)·
    Only_DeleteOperation = 2,
    --能执行所有操作 可选中 再次选中可删除  (不显示删除按钮)
    All_Operation = 3,
}   
--个性签名限制输入字符长度
PersonalInfoModel.SignatureInputSizeLimit = 50

function PersonalInfoModel:__init()
    self:_dataInit()
end

function PersonalInfoModel:_dataInit()
    -- 玩家的详细信息
    --[[
        message PlayerDetailData 
    {
        ------------------ BaseInfo : 通过 GetPlayerDetailInfoReq 得到的只包含以下信息，变动通过 ON_PLAYER_BASE_INFO_CHANGED 派发
        int64   PlayerId        = 1;
        string  PlayerName      = 2;
        int64   HeadId          = 4;        // 选择的头像Id
        int64   HeadFrameId     = 5;        // 选择的头像框Id
        repeated HeadWidgetNode HeadWidgetList = 6; // 头像框挂件数据

        ------------------ DetailInfo : 通过 PlayerLookUpDetailReq 得到的包含所有信息，变动通过 ON_PLAYER_DETAIL_INFO_CHANGED 派发
        int32   Level           = 3;
        int64   LikeHeartTotal  = 7;        // 点赞热度值
        int64   LikeTotal       = 8;        // 点赞数量
        repeated RecentVisitorNode RecentVisitorList = 9;   // 访问列表
        repeated ShowHeroNode ShowHeroList = 10;    // 展示英雄列表
        WeaponPartNode WeaponPart = 11;          // 选择的武器装备的配件信息
        WeaponPartSkinNode WeaponPartSkin = 12;  // 选择武器皮肤装备的配件皮肤信息
        int64   Experience      = 14;       // 当前经验值
    }
    ]]
    self.PlayerDetailInfoList = {}

    -- 数据有效期（持续时间，单位:s)
    self.DataLimitTime = CommonUtil.GetParameterConfig(ParameterConfig.SocialInfoAutoCheckTime, 30)
    --社交标签配置列表
    self.SocialTagsCfgList = {}
    --社交标签类型配置列表
    self.SocialTagsTypeCfgList = {}
    --自己设为展示的社交标签列表 
    self.MySelfSocialTagIdList = {}
    --自己的解锁社交标签列表 Key是标签TagId,Value是该标签解锁的时间戳
    self.MySelfUnlockSocialTagIdList = {}
    --解锁状态是否改变 改变的情况需要重新排序  
    self.MySelfUnlockSocialTagStateChange = true
    --自己的个性签名
    self.MySelfPersonalSignature = ""
end

function PersonalInfoModel:OnLogin(data)
    self.PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    self:InitPersonInfoConfig()
end

--[[
    玩家登出时调用
]]
function PersonalInfoModel:OnLogout(data)
    PersonalInfoModel.super.OnLogout(self)
    self:_dataInit()
end

-------- 对外接口 -----------
--[[
    初始化个人信息配置信息
]]
function PersonalInfoModel:InitPersonInfoConfig()
    --初始化社交标签配置列表
    self.SocialTagsCfgList = {}
    --key为标签类型 value为标签ID table
    local TotalTabIdList = {}
    local SocialTagCfgs =  G_ConfigHelper:GetDict(Cfg_SocialTagCfg)
    for _,Cfg in pairs(SocialTagCfgs) do
        local TagId = Cfg[Cfg_SocialTagCfg_P.TagId]
        local TagTypeId = Cfg[Cfg_SocialTagCfg_P.TagTypeId]
        ---@class SocialTagCfgInfo
        ---@field TagId number 标签ID
        ---@field TagTypeId number 标签类型ID
        ---@field TagName string 标签名称
        ---@field BgHexColor string 标签背景颜色
        local SocialTagCfgInfo = {
            TagId = TagId,
            TagTypeId = TagTypeId,
            TagName = Cfg[Cfg_SocialTagCfg_P.TagName],
            BgHexColor = Cfg[Cfg_SocialTagCfg_P.BgHexColor],
        }
        self.SocialTagsCfgList[TagId] = SocialTagCfgInfo
        --通过标签类型分类
        TotalTabIdList[TagTypeId] = TotalTabIdList[TagTypeId] or {}
        local CurListLength = #TotalTabIdList[TagTypeId]
        TotalTabIdList[TagTypeId][CurListLength +1] = TagId
    end
    --初始化社交标签类型配置列表
    self.SocialTagsTypeCfgList = {}
    local SocialTagTypeCfgs =  G_ConfigHelper:GetDict(Cfg_SocialTagTypeCfg)
    for _,Cfg in ipairs(SocialTagTypeCfgs) do
        local TagTypeId = Cfg[Cfg_SocialTagTypeCfg_P.TagTypeId]
        local TabIdList = TotalTabIdList[TagTypeId] or {}
        ---@class SocialTagTypeCfgInfo
        ---@field TagTypeId number 标签类型ID
        ---@field TagTypeName string 标签类型名称
        ---@field TagIdList table 标签IDtable
        local SocialTagTypeCfgInfo = {
            TagTypeId = TagTypeId,
            TagTypeName = Cfg[Cfg_SocialTagTypeCfg_P.TagTypeName],
            TagIdList = TabIdList
        }
        self.SocialTagsTypeCfgList[#self.SocialTagsTypeCfgList + 1] = SocialTagTypeCfgInfo
    end
end

-- 获取自己的玩家信息
-- 自己的信息有变动会同步更新，无需处理有效时间
function PersonalInfoModel:GetMyPlayerProperty(PropertyName)
    if not (self.PlayerId and self.PlayerDetailInfoList and self.PlayerDetailInfoList[self.PlayerId]) then
        return nil
    end
    local DetailInfo = self.PlayerDetailInfoList[self.PlayerId]
    return DetailInfo[PropertyName]
end

-- 获取玩家的详细信息
-- 所有获取子属性接口，均先从此接口获取信息，这里会处理信息有效时间，超过有效期则返回nil并发起请求，通过监听 ON_PLAYER_BASE_INFO_CHANGED 获取更新后的信息
function PersonalInfoModel:GetPlayerDetailInfo(PlayerId)
    -- CError("===============GetPlayerDetailInfo"..PlayerId)
    if self.PlayerDetailInfoList and self.PlayerDetailInfoList[PlayerId] then
        local LastUpdateTime = self.PlayerDetailInfoList[PlayerId].UpdateTime or 0
        self.PlayerDetailInfoList[PlayerId].IsOutOfDate = GetTimestamp() - LastUpdateTime >= self.DataLimitTime
        if self.PlayerDetailInfoList[PlayerId].IsOutOfDate then
            MvcEntry:GetCtrl(PersonalInfoCtrl):SendGetPlayerBaseInfoReq(PlayerId)
        end
        return self.PlayerDetailInfoList[PlayerId]
    else
        MvcEntry:GetCtrl(PersonalInfoCtrl):SendGetPlayerBaseInfoReq(PlayerId)
        return nil
    end
end

-- 获取缓存的玩家信息，仅查询，不请求更新
function PersonalInfoModel:GetCachePlayerDetailInfo(PlayerId)
    if  self.PlayerDetailInfoList and self.PlayerDetailInfoList[PlayerId]  then
        return self.PlayerDetailInfoList[PlayerId]
    end
    return nil
end

-- 获取玩家的头像id
function PersonalInfoModel:GetPlayerHeadId(PlayerId)
    local PlayerInfo = self:GetPlayerDetailInfo(PlayerId)
    if PlayerInfo then
        return PlayerInfo.HeadId
    end
    return nil
end

-- 获取玩家的自定义头像URL
function PersonalInfoModel:GetPlayerCustomHeadUrl(PlayerId)
    local PlayerInfo = self:GetPlayerDetailInfo(PlayerId)
    if PlayerInfo then
        return PlayerInfo.PortraitUrl
    end
    return nil
end

-- 获取我自己审核中的自定义头像URL
function PersonalInfoModel:GetMySelfAuditCustomHeadUrl(PlayerId)
    local CustomHeadUrl = self:GetMyPlayerProperty("AuditPortraitUrl") or ""
end
----------------------------------------
-- 更新玩家头像Id
function PersonalInfoModel:SetPlayerHeadId(PlayerId,HeadId)
    self.PlayerDetailInfoList[PlayerId] = self.PlayerDetailInfoList[PlayerId] or {}
    self.PlayerDetailInfoList[PlayerId].HeadId = HeadId
    self.PlayerDetailInfoList[PlayerId].UpdateTime = GetTimestamp()
end

-- 更新玩家自定义头像装备状态
function PersonalInfoModel:SetPlayerCustomHeadSelectState(PlayerId, SelectPortraitUrl)
    self.PlayerDetailInfoList[PlayerId] = self.PlayerDetailInfoList[PlayerId] or {}
    self.PlayerDetailInfoList[PlayerId].SelectPortraitUrl = SelectPortraitUrl and true or false
    self.PlayerDetailInfoList[PlayerId].UpdateTime = GetTimestamp()
end

-- 更新玩家自定义头像URL信息  所有PortraitUrl通过此接口赋值 
function PersonalInfoModel:SetPlayerCustomHeadUrl(PlayerId, PortraitUrl, AuditPortraitUrl)
    self.PlayerDetailInfoList[PlayerId] = self.PlayerDetailInfoList[PlayerId] or {}
    local OldPortraitUrl = self.PlayerDetailInfoList[PlayerId].PortraitUrl
    self.PlayerDetailInfoList[PlayerId].PortraitUrl = PortraitUrl or nil
    if AuditPortraitUrl ~= nil then
        self.PlayerDetailInfoList[PlayerId].AuditPortraitUrl = AuditPortraitUrl
    end
    self.PlayerDetailInfoList[PlayerId].UpdateTime = GetTimestamp()

    -- 说明旧头像链接失效了 不需要再使用
    if OldPortraitUrl and OldPortraitUrl ~= "" and OldPortraitUrl ~= PortraitUrl then
        ---@type HttpModel
        local HttpModel = MvcEntry:GetModel(HttpModel)
        HttpModel:DispatchType(HttpModel.ON_REMOVE_TEXTURE_CACHE_EVENT, OldPortraitUrl)
    end
end

-- 更新玩家自定义头像信息
function PersonalInfoModel:SetPlayerCustomHeadInfo(PlayerId, PortraitUrl, AuditPortraitUrl, SelectPortraitUrl)
    self.PlayerDetailInfoList[PlayerId] = self.PlayerDetailInfoList[PlayerId] or {}

    self:SetPlayerCustomHeadUrl(PlayerId, PortraitUrl, AuditPortraitUrl)
    self:SetPlayerCustomHeadSelectState(PlayerId, SelectPortraitUrl)
    self.PlayerDetailInfoList[PlayerId].UpdateTime = GetTimestamp()
end

-- 更新玩家头像框Id
function PersonalInfoModel:SetPlayerHeadFrameId(PlayerId,HeadFrameId)
    self.PlayerDetailInfoList[PlayerId] = self.PlayerDetailInfoList[PlayerId] or {}
    self.PlayerDetailInfoList[PlayerId].HeadFrameId = HeadFrameId
    self.PlayerDetailInfoList[PlayerId].UpdateTime = GetTimestamp()
end

-- 更新玩家头像挂件
function PersonalInfoModel:SetPlayerHeadWidgetList(PlayerId,HeadWidgetList)
    HeadWidgetList = HeadWidgetList or {}
    self.PlayerDetailInfoList[PlayerId] = self.PlayerDetailInfoList[PlayerId] or {}
    self.PlayerDetailInfoList[PlayerId].HeadWidgetList = HeadWidgetList
    self.PlayerDetailInfoList[PlayerId].UpdateTime = GetTimestamp()
end

-- 更新玩家等级和经验
function PersonalInfoModel:SetPlayerLvAndExp(PlayerId, InLevel, InExperience)
    self.PlayerDetailInfoList[PlayerId] = self.PlayerDetailInfoList[PlayerId] or {}
    self.PlayerDetailInfoList[PlayerId].Level = InLevel
    self.PlayerDetailInfoList[PlayerId].Experience = InExperience
    self.PlayerDetailInfoList[PlayerId].UpdateTime = GetTimestamp()
end

-- 更新多个玩家头像Id
function PersonalInfoModel:SetPlayerHeadIdForList(PlayerList, NotNeedDispatch)
    for _,Vo in ipairs(PlayerList) do
        self.PlayerDetailInfoList[Vo.PlayerId] = self.PlayerDetailInfoList[Vo.PlayerId] or {}
        self.PlayerDetailInfoList[Vo.PlayerId].HeadId = Vo.HeadId
        self.PlayerDetailInfoList[Vo.PlayerId].UpdateTime = GetTimestamp()
        if not NotNeedDispatch then
            self:DispatchType(PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID,Vo.PlayerId)
        end
    end
    if not NotNeedDispatch then
        self:DispatchType(PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED)
    end
end

-- 更新玩家个性标签数据
function PersonalInfoModel:SetPlayerTagIdList(PlayerId, TagIdList)
    self.PlayerDetailInfoList[PlayerId] = self.PlayerDetailInfoList[PlayerId] or {}
    self.PlayerDetailInfoList[PlayerId].TagIdList = TagIdList
    self.PlayerDetailInfoList[PlayerId].UpdateTime = GetTimestamp()
end

-- 更新玩家个性签名数据
function PersonalInfoModel:SetPlayerPersonal(PlayerId, Personal)
    self.PlayerDetailInfoList[PlayerId] = self.PlayerDetailInfoList[PlayerId] or {}
    self.PlayerDetailInfoList[PlayerId].Personal = Personal
    self.PlayerDetailInfoList[PlayerId].UpdateTime = GetTimestamp()
end

-- 收到服务器返回的个基本信息
function PersonalInfoModel:SetPlayerBaseInfo(Vo, NotNeedDispatch)
    if not Vo then
        return
    end
    self.PlayerDetailInfoList[Vo.PlayerId] = self.PlayerDetailInfoList[Vo.PlayerId] or {}
    self.PlayerDetailInfoList[Vo.PlayerId].HeadId = Vo.HeadId
    self.PlayerDetailInfoList[Vo.PlayerId].PlayerName = Vo.PlayerName
    self.PlayerDetailInfoList[Vo.PlayerId].HeadFrameId = Vo.HeadFrameId
    self.PlayerDetailInfoList[Vo.PlayerId].HeadWidgetList = Vo.HeadWidgetList
    self:SetPlayerCustomHeadUrl(Vo.PlayerId, Vo.PortraitUrl)
    self:SetPlayerCustomHeadSelectState(Vo.PlayerId, Vo.SelectPortraitUrl)
    self.PlayerDetailInfoList[Vo.PlayerId].MaxDivisionInfoList = Vo.MaxDivisionInfoList
    self.PlayerDetailInfoList[Vo.PlayerId].UpdateTime = GetTimestamp()
end

-- 收到服务器下发的MiscData信息
function PersonalInfoModel:SetMyMiscData(MiscData)
    self:SetMySocialTagsList(MiscData.TagIdList)
    self:SetMySocialTagsUnlockTagMap(MiscData.UnlockTagMap)
    self:SetPersonalSignatureInfo(MiscData.Personal)
end

-- 收到服务器下发的自己的社交标签相关信息
---@param TagIdList number[] 当前展示的标签列表
---@param IsAddUpdate boolean 是否增量更新
function PersonalInfoModel:SetMySocialTagsList(TagIdList, IsAddUpdate)
    if TagIdList then
        if IsAddUpdate then
            for _, TagId in pairs(TagIdList) do
                self.MySelfSocialTagIdList[#self.MySelfSocialTagIdList + 1] = TagId
            end
        else
            self.MySelfSocialTagIdList = TagIdList
        end
        local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
        self:SetPlayerTagIdList(MyPlayerId, self.MySelfSocialTagIdList)
        self:DispatchType(PersonalInfoModel.ON_SHOW_SOCIAL_TAG_CHANGED)
    end
end

-- 收到服务器下发的自己的社交标签相关信息
---@param UnlockTagMap table 解锁社交标签列表 Key是标签TagId,Value
---@param IsAddUpdate boolean 是否增量更新
function PersonalInfoModel:SetMySocialTagsUnlockTagMap(UnlockTagMap, IsAddUpdate)
    if UnlockTagMap then
        if IsAddUpdate then
            for TagId, UnlockTime in pairs(UnlockTagMap) do
                self.MySelfUnlockSocialTagIdList[TagId] = UnlockTime 
            end
        else
            self.MySelfUnlockSocialTagIdList = UnlockTagMap
        end
        self.MySelfUnlockSocialTagStateChange = true
        self:DispatchType(PersonalInfoModel.ON_SOCIAL_TAG_UNLOCK_STATE_CHANGED)
    end
end

-- 设置个人签名返回
function PersonalInfoModel:SetPersonalSignatureInfo(Personal)
    self.MySelfPersonalSignature = Personal
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    self:SetPlayerPersonal(MyPlayerId, self.MySelfPersonalSignature)
    self:DispatchType(PersonalInfoModel.ON_PERSONAL_SIGNATURE_CHANGED)
end

-- 收到服务器返回的个人详细信息
function PersonalInfoModel:OnGetPlayerDetailData(TargetPlayerId, DetailData)
    if TargetPlayerId == 0 then
        -- 自己的信息
        TargetPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    end
    self.PlayerDetailInfoList[TargetPlayerId] = DetailData
    self.PlayerDetailInfoList[TargetPlayerId].UpdateTime = GetTimestamp()
    -- 重新处理一下展示英雄的数据,以Slot为Key
    local ShowHeroList = DetailData.ShowHeroList
    self.PlayerDetailInfoList[TargetPlayerId].ShowHeroList = {}
    for _,ShowHeroNode in ipairs(ShowHeroList) do
        self.PlayerDetailInfoList[TargetPlayerId].ShowHeroList[ShowHeroNode.Slot] = ShowHeroNode
    end
    self:DispatchType(PersonalInfoModel.ON_PLAYER_DETAIL_INFO_CHANGED,TargetPlayerId)
end

-- 更新我的展示英雄
function PersonalInfoModel:UpdateMyShowHero(Slot, HeroId)
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    if self.PlayerDetailInfoList and self.PlayerDetailInfoList[MyPlayerId] then
        local ShowHeroList = self.PlayerDetailInfoList[MyPlayerId].ShowHeroList
        if ShowHeroList and ShowHeroList[Slot] then
            ShowHeroList[Slot].HeroId = HeroId
            ShowHeroList[Slot].HeroSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(HeroId)
            self:DispatchType(PersonalInfoModel.ON_SHOW_HERO_CHANGED,Slot)
        else
            CError("UpdateMyShowHero Can't Found Data For Slot = "..Slot,true)    
        end
    else
        CError("UpdateMyShowHero Can't Found My Data",true)    
    end
end

-- 更新热度值
function PersonalInfoModel:AddHotValue(TargetPlayerId)
    if self.PlayerDetailInfoList[TargetPlayerId] then
        self.PlayerDetailInfoList[TargetPlayerId].LikeHeartTotal = self.PlayerDetailInfoList[TargetPlayerId].LikeHeartTotal or 0
        self.PlayerDetailInfoList[TargetPlayerId].LikeHeartTotal = self.PlayerDetailInfoList[TargetPlayerId].LikeHeartTotal + 1
        local Param = {
            TargetPlayerId = TargetPlayerId,
            LikeHeartTotal = self.PlayerDetailInfoList[TargetPlayerId].LikeHeartTotal
        }
        self:DispatchType(PersonalInfoModel.ON_HOT_VALUE_CHANGED,Param)
    end
end

-- 收到服务器返回的交互弹窗数据
function PersonalInfoModel:SetCommonDialogInfo(Vo)
    if not Vo then
        return
    end
    self.PlayerDetailInfoList[Vo.PlayerId] = self.PlayerDetailInfoList[Vo.PlayerId] or {}
    self.PlayerDetailInfoList[Vo.PlayerId].HeadId = Vo.HeadId
    self.PlayerDetailInfoList[Vo.PlayerId].PlayerName = Vo.PlayerName
    self.PlayerDetailInfoList[Vo.PlayerId].HeadFrameId = Vo.HeadFrameId
    self.PlayerDetailInfoList[Vo.PlayerId].HeadWidgetList = Vo.HeadWidgetList or {}
    self:SetPlayerCustomHeadUrl(Vo.PlayerId, Vo.PortraitUrl)
    self:SetPlayerCustomHeadSelectState(Vo.PlayerId, Vo.SelectPortraitUrl)
    self.PlayerDetailInfoList[Vo.PlayerId].LikeHeartTotal = Vo.LikeHeartTotal
    self.PlayerDetailInfoList[Vo.PlayerId].Personal = Vo.Personal
    self.PlayerDetailInfoList[Vo.PlayerId].SlotMap = Vo.SlotMap or {}
    self.PlayerDetailInfoList[Vo.PlayerId].TagIdList = Vo.TagIdList or {}
    self.PlayerDetailInfoList[Vo.PlayerId].MaxDivisionInfoList = Vo.MaxDivisionInfoList or {}
    self.PlayerDetailInfoList[Vo.PlayerId].UpdateTime = GetTimestamp()
end

function PersonalInfoModel:GetSlotAchievement(Slot)
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    if self.PlayerDetailInfoList and self.PlayerDetailInfoList[MyPlayerId] then
        local AchiMap = self.PlayerDetailInfoList[MyPlayerId].SlotMap
        if AchiMap then
           return AchiMap[Slot]
        end
    end
end

--获取社交标签类型配置列表
---@return SocialTagTypeCfgInfo[]
function PersonalInfoModel:GetSocialTagsTypeCfgList()
    if self.MySelfUnlockSocialTagStateChange then
        self.MySelfUnlockSocialTagStateChange = false
        for _, SocialTagsTypeCfg in ipairs(self.SocialTagsTypeCfgList) do
            table.sort(SocialTagsTypeCfg.TagIdList,function(A,B)
                local AIsUnlock = self:CheckSocialTagIsUnlock(A)
                local BIsUnlock = self:CheckSocialTagIsUnlock(B)
                if AIsUnlock ~= BIsUnlock then
                    return AIsUnlock
                else
                    return A < B    
                end
            end)
        end
    end
    return self.SocialTagsTypeCfgList
end

--通过社交标签ID获取对应的配置信息
---@param TagId number 标签ID
---@return SocialTagCfgInfo 
function PersonalInfoModel:GetSocialTagCfgInfoById(TagId)
    return self.SocialTagsCfgList[TagId]
end

--获取自己展示的社交标签信息列表
function PersonalInfoModel:GetShowSocialTagInfoList()
    return self.MySelfSocialTagIdList
end

--获取深拷贝展示的社交标签信息列表
function PersonalInfoModel:GetDeepCopyShowSocialTagInfoList()
    local MySelfSocialTagIdList = DeepCopy(self.MySelfSocialTagIdList)
    return MySelfSocialTagIdList
end

--获取可展示的社交标签数量
function PersonalInfoModel:GetTotalShowSocialTagNum()
    local TotalShowTagNum = CommonUtil.GetParameterConfig(ParameterConfig.PlayerMiscTagCountMax)
    return TotalShowTagNum
end

--检测社交标签是否解锁
---@param TagId number 社交标签ID
function PersonalInfoModel:CheckSocialTagIsUnlock(TagId)
    local IsUnlock = false
    local CurTime = GetTimestamp()
    local UnlockTime = self.MySelfUnlockSocialTagIdList[TagId]
    if UnlockTime and CurTime >= UnlockTime then
        IsUnlock = true
    end
    return IsUnlock
end

--检测社交标签是否被选中展示
---@param TagId number 社交标签ID
function PersonalInfoModel:CheckSocialTagIsSelectShow(TagId)
    local IsSelectShow = false
    local ShowSocialTagInfoList = self:GetShowSocialTagInfoList()
    for _, ShowTagId in ipairs(ShowSocialTagInfoList) do
        if ShowTagId == TagId then
            IsSelectShow = true
            break;
        end
    end
    return IsSelectShow
end

-- 获取自己的个性签名
function PersonalInfoModel:GetMySelfPersonalSignature()
    return self.MySelfPersonalSignature
end

-- 获取当前赛季排位里最高的段位信息  依赖个人信息里的数据 没有数据会返回空
function PersonalInfoModel:GetMaxRankDivisionInfo(TargetPlayerId)
    local MaxDivisionInfo = nil
    local PlayerInfo = self:GetPlayerDetailInfo(TargetPlayerId)
    if PlayerInfo and PlayerInfo.MaxDivisionInfoList then
        ---@type SeasonRankModel
        local SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)
        for _, MaxDivisionInfoValue in ipairs(PlayerInfo.MaxDivisionInfoList) do
            local IsRankMode = SeasonRankModel:CheckIsRankModeByPlayModeId(MaxDivisionInfoValue.PlayModeId)
            if IsRankMode then
                -- 判空 防止空表的情况下报错
                if MaxDivisionInfoValue.MaxDivisionId and MaxDivisionInfoValue.MaxDivisionId > 0 then
                    MaxDivisionInfo = MaxDivisionInfoValue 
                end
                break
            end
        end
    end
    return MaxDivisionInfo
end