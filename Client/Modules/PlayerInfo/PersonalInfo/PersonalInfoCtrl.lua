--[[
    个人信息协议处理模块
]]

require("Client.Modules.PlayerInfo.PersonalInfo.PersonalInfoModel")
require("Client.Modules.PlayerInfo.HeadIconSetting.HeadIconSettingModel")
local class_name = "PersonalInfoCtrl"
---@class PersonalInfoCtrl : UserGameController
---@type PersonalInfoCtrl
PersonalInfoCtrl = PersonalInfoCtrl or BaseClass(UserGameController,class_name)


function PersonalInfoCtrl:__init()
    CWaring("==PersonalInfoCtrl init")
end

function PersonalInfoCtrl:Initialize()
    ---@type UserModel
    self.UserModel = MvcEntry:GetModel(UserModel)
    ---@type PersonalInfoModel
    self.PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)
    ---@type HeadIconSettingModel
    self.HeadIconSettingModel = MvcEntry:GetModel(HeadIconSettingModel)
    
    self.ReqCacheTimer = nil
    self.ReqCacheTime = 0.1  -- 请求缓存后发出，
    self.BaseInfoReqCache = {}
    self.BaseInfoReqCacheList = {}


    -- 社交信息同步时间
    self.SocialInfoAutoCheckTime = CommonUtil.GetParameterConfig(ParameterConfig.SocialInfoAutoCheckTime, 30)
    -- 查询的玩家信息列表
    self.QueryIdMap = {}
    self.QueryIdList = {}
	self.ViewQueryList = {}
end

--[[
    玩家登入
]]
function PersonalInfoCtrl:OnLogin(data)
    CWaring("PersonalInfoCtrl OnLogin")
    -- self.PersonalInfoModel:OnLogin()
    -- self.HeadIconSettingModel:OnLogin()
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendProto_PlayerLookUpDetailReq()
end

function PersonalInfoCtrl:OnLogout()
    -- self.PersonalInfoModel:OnLogout()
    -- self.HeadIconSettingModel:OnLogout()
    
    self:StopReqCacheTickTimer()
end

function PersonalInfoCtrl:AddMsgListenersUser()
    self.ProtoList = {
        -- 玩家信息相关
    	{MsgName = Pb_Message.PlayerLookUpDetailRsp,	Func = self.PlayerLookUpDetailRsp_Func },
        {MsgName = Pb_Message.GetPlayerDetailInfoRsp,	Func = self.GetPlayerDetailInfoRsp_Func },
        {MsgName = Pb_Message.HeroSelectShowRsp,	Func = self.HeroSelectShowRsp_Func },
        {MsgName = Pb_Message.PlayerLikeHeartRsp,	Func = self.PlayerLikeHeartRsp_Func },
        {MsgName = Pb_Message.PlayerLikeRsp,	Func = self.PlayerLikeRsp_Func },
        {MsgName = Pb_Message.PlayerUpdateTagRsp,	Func = self.PlayerUpdateTagRsp_Func },
        {MsgName = Pb_Message.PlayerUnlockTagNotify,   Func = self.PlayerUnlockTagNotify_Func},
        {MsgName = Pb_Message.SetPersonalRsp,    Func = self.SetPersonalRsp_Func},
        {MsgName = Pb_Message.GetPlayerCommonDialogDataRsp,    Func = self.GetPlayerCommonDialogDataRsp_Func},
        -- 个性化相关
        {MsgName = Pb_Message.PlayerBuyHeadRsp,	Func = self.PlayerBuyHeadRsp_Func },
        {MsgName = Pb_Message.PlayerSelectHeadRsp,	Func = self.PlayerSelectHeadRsp_Func },
        {MsgName = Pb_Message.PlayerBuyHeadFrameRsp,	Func = self.PlayerBuyHeadFrameRsp_Func },
        {MsgName = Pb_Message.PlayerBuyHeadWidgetRsp,	Func = self.PlayerBuyHeadWidgetRsp_Func },
        {MsgName = Pb_Message.PlayerSaveHeadFrameWidgetDataRsp,	Func = self.PlayerSaveHeadFrameWidgetDataRsp_Func },
        {MsgName = Pb_Message.UploadPortraitSync, Func = self.UploadPortraitSync }
    }
end


--[[
    玩家简要信息返回
    Lobby.proto
    DetailInfoList : repeated PlayerDetailInfo
    PlayerDetailInfo = 
    {
        int64 PlayerId = 1;
        int64 HeadId    = 2;        // 头像Id
        string PlayerName = 3;
    }
]]
function PersonalInfoCtrl:GetPlayerDetailInfoRsp_Func(Msg)
    local DetailInfoList = Msg.DetailInfoList
    for _,Vo in ipairs(DetailInfoList) do
        self.PersonalInfoModel:SetPlayerBaseInfo(Vo)
        self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID,Vo.PlayerId)
    end
    self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED)
end

-- 查看玩家信息回包
function PersonalInfoCtrl:PlayerLookUpDetailRsp_Func(Msg)
    self.PersonalInfoModel:OnGetPlayerDetailData(Msg.TargetPlayerId, Msg.DetailData)
end

-- 设置展示英雄回包
function PersonalInfoCtrl:HeroSelectShowRsp_Func(Msg)
    self.PersonalInfoModel:UpdateMyShowHero(Msg.Slot,Msg.HeroId)
end

-- 热度值返回
function PersonalInfoCtrl:PlayerLikeHeartRsp_Func(Msg)
    self.PersonalInfoModel:AddHotValue(Msg.TargetPlayerId)
end

-- 点赞返回
--[[
    Msg = 
    {
        int64 TargetPlayerId = 1;           // 目标对象
        int64 GameId = 2;                   // 对局游戏Id
    }
]]
function PersonalInfoCtrl:PlayerLikeRsp_Func(Msg)
    self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_GIVE_LIKE_SUCCESS,Msg)    
end

-- 更新个人标签返回
function PersonalInfoCtrl:PlayerUpdateTagRsp_Func(Msg)
    self.PersonalInfoModel:SetMySocialTagsList(Msg.TagIdList)
end

--更新标签解锁状态
function PersonalInfoCtrl:PlayerUnlockTagNotify_Func(Msg)
    self.PersonalInfoModel:SetMySocialTagsUnlockTagMap(Msg.UnlockTagMap, true)
end

-- 设置签名返回
function PersonalInfoCtrl:SetPersonalRsp_Func(Msg)
    if Msg then
        if Msg.ErrCode ~= ErrorCode.Success.ID then
            local MsgObject = {
                ErrCode = Msg.ErrCode,
                ErrCmd = "",
                ErrMsg = "",
            }
            MvcEntry:GetCtrl(ErrorCtrl):PopTipsAction(MsgObject, ErrorCtrl.TIP_TYPE.ERROR_CONFIG)
        end
        self.PersonalInfoModel:SetPersonalSignatureInfo(Msg.Personal)
    end
end

-- 获取批量玩家的交互弹窗数据返回
function PersonalInfoCtrl:GetPlayerCommonDialogDataRsp_Func(Msg)
    -- print_r(Msg, "[hz] GetPlayerCommonDialogDataRsp_Func ==== Msg")
    if Msg and Msg.CommonDialogInfoList then
        local CommonDialogInfoList = Msg.CommonDialogInfoList
        for _,Vo in ipairs(CommonDialogInfoList) do
            self.PersonalInfoModel:SetCommonDialogInfo(Vo)
            self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_PLAYER_COMMON_DIALOG_INFO_CHANGED_FOR_ID,Vo.PlayerId)
        end
    end
end

------------------------------------请求相关----------------------------

--[[
    请求玩家简要信息
]]
function PersonalInfoCtrl:SendGetPlayerBaseInfoReq(PlayerId)
    if self.BaseInfoReqCache[PlayerId] then
        -- 已经在请求缓存中了
        return
    end
    self.BaseInfoReqCache[PlayerId] = 1
    table.insert(self.BaseInfoReqCacheList,PlayerId)

    if #self.BaseInfoReqCacheList >= 20 then
        -- 超过5个则立刻发出请求
        self:StopReqCacheTickTimer()
        self:DoQueryPlayerInfo()
    elseif not self.ReqCacheTimer then
        -- 未超过五个则下一帧再请求，避免一帧发送多次
        self:StartReqCacheTickTimer()
    end
end

function PersonalInfoCtrl:SendGetPlayerListBaseInfoReq(PlayerList)
    if not PlayerList or #PlayerList <= 0 then
        return
    end

    for _,PlayerId in ipairs(PlayerList) do
        self:SendGetPlayerBaseInfoReq(PlayerId)
    end
end

-- 请求某个玩家的个人详细信息
-- 0查看自己，其他则是查看目标的PlayerId
function PersonalInfoCtrl:SendProto_PlayerLookUpDetailReq(TargetPlayerId)
    local Msg = {
        TargetPlayerId = TargetPlayerId,
    }
    self: SendProto(Pb_Message.PlayerLookUpDetailReq, Msg, Pb_Message.PlayerLookUpDetailRsp)
end

-- 请求设置展示英雄
function PersonalInfoCtrl:SendProto_HeroSelectShowReq(Msg)
    self:SendProto(Pb_Message.HeroSelectShowReq, Msg, Pb_Message.HeroSelectShowRsp)
end

-- 请求增加热度值
function PersonalInfoCtrl:SendProto_PlayerLikeHeartReq(TargetPlayerId)
    local PlayerId = self:GetModel(UserModel):GetPlayerId()
    if PlayerId == TargetPlayerId then
        return
    end
    print("SendProto_PlayerLikeHeartReq TargetPlayerId:"..TargetPlayerId)
    local Msg = {
        TargetPlayerId = TargetPlayerId,
    }
    self:SendProto(Pb_Message.PlayerLikeHeartReq, Msg, Pb_Message.PlayerLikeHeartRsp)
end

-- 请求给玩家点赞
--[[
    Msg =
    {
        int64 TargetPlayerId = 1;           // 目标对象
        string GameId = 2;                  // 对局游戏Id
    }
]]
function PersonalInfoCtrl:SendProto_PlayerLikeReq(Msg)
    print_r(Msg, "[cw] SendProto_PlayerLikeReq ====Msg")
    self:SendProto(Pb_Message.PlayerLikeReq, Msg, Pb_Message.PlayerLikeRsp)
end

--请求更新个人标签
---@param TagIdList number[] 标签ID列表 
function PersonalInfoCtrl:SendProto_PlayerUpdateTagReq(TagIdList)
    print_r(TagIdList, "[hz] SendProto_PlayerUpdateTagReq ====TagIdList")
    local Msg = {
        TagIdList = TagIdList,
    }
    self:SendProto(Pb_Message.PlayerUpdateTagReq, Msg, Pb_Message.PlayerUpdateTagRsp)
end

--请求更新个人标签
---@param TagIdList number[] 标签ID列表 
function PersonalInfoCtrl:SendProto_PlayerUpdateTagReq(TagIdList)
    print_r(TagIdList, "[hz] SendProto_PlayerUpdateTagReq ====TagIdList")
    local Msg = {
        TagIdList = TagIdList,
    }
    self:SendProto(Pb_Message.PlayerUpdateTagReq, Msg, Pb_Message.PlayerUpdateTagRsp)
end

--请求设置个人签名
---@param Personal string 个人签名
function PersonalInfoCtrl:SendProto_SetPersonalReq(Personal)
    CLog("[hz] SendProto_SetPersonalReq ====Personal " .. tostring(Personal))
    local Msg = {
        Personal = Personal,
    }
    self:SendProto(Pb_Message.SetPersonalReq, Msg, Pb_Message.SetPersonalRsp)
end

-- 获取批量玩家的交互弹窗数据
---@param PlayerIdList number[] 玩家PlayerId列表
function PersonalInfoCtrl:SendProto_GetPlayerCommonDialogDataReq(PlayerIdList)
    -- print_r(PlayerIdList, "[hz] SendProto_GetPlayerCommonDialogDataReq ==== PlayerIdList")
    local Msg = {
        PlayerIdList = PlayerIdList,
    }
    self:SendProto(Pb_Message.GetPlayerCommonDialogDataReq, Msg)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.GetPlayerCommonDialogDataReq, Msg, Pb_Message.GetPlayerCommonDialogDataRsp, false, false)
end

------------------------------------头像设置相关----------------------------

-- 解锁头像
function PersonalInfoCtrl:PlayerBuyHeadRsp_Func(Msg)
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_HEAD_ICON_UNLOCK,Msg.HeadId)
end

-- 使用头像
function PersonalInfoCtrl:PlayerSelectHeadRsp_Func(Msg)
    local IsCustomHead = self.HeadIconSettingModel:CheckIsCustomHead(Msg.HeadId)
    local MySelfPlayerId = self.UserModel:GetPlayerId()
    -- 特殊处理 如果头像传0的时候不赋值原本的HeadId
    if not IsCustomHead then
        self.UserModel.HeadId = Msg.HeadId
        self.PersonalInfoModel:SetPlayerHeadId(MySelfPlayerId,Msg.HeadId) 
    end
    self.PersonalInfoModel:SetPlayerCustomHeadSelectState(MySelfPlayerId, Msg.HeadId == HeadIconSettingModel.CustomHeadId)
    self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID,MySelfPlayerId)
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_USE_HEAD_ICON,Msg.HeadId)
end

-- 解锁头像框
function PersonalInfoCtrl:PlayerBuyHeadFrameRsp_Func(Msg)
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_HEAD_FRAME_UNLOCK,Msg.HeadFrameId)
end

-- 解锁头像挂件
function PersonalInfoCtrl:PlayerBuyHeadWidgetRsp_Func(Msg)
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_HEAD_WIDGET_UNLOCK,Msg.HeadWidgetId)
end

-- 请求保存头像框，头像挂件数据
function PersonalInfoCtrl:PlayerSaveHeadFrameWidgetDataRsp_Func(Msg)
    self.UserModel.HeadFrameId = Msg.HeadFrameId
    local MyPlayerId = self.UserModel:GetPlayerId()
    self.PersonalInfoModel:SetPlayerHeadFrameId(MyPlayerId,Msg.HeadFrameId)
    self.PersonalInfoModel:SetPlayerHeadWidgetList(MyPlayerId,Msg.HeadWidgetList)
    self.HeadIconSettingModel:ClearHeadWidgetTemp()
    self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID,MyPlayerId)
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_HEAD_FRAME_AND_WIDGET_CHANGED,Msg)
end

-- 上传自定义头像返回  客户端上传头像的时候，服务器会立即返回一次提示头像审核中, 审核完成后服务器会再返回一次提示审核结果
function PersonalInfoCtrl:UploadPortraitSync(Msg)
    if Msg then
        print_r(Msg, "[hz] UploadPortraitSync ==== Msg")
        local MyPlayerId = self.UserModel:GetPlayerId()
        if Msg.ErrCode == ErrorCode.Success.ID then
            self.UserModel.PortraitUrl = Msg.PortraitUrl
            self.UserModel.AuditPortraitUrl = Msg.AuditPortraitUrl
            self.PersonalInfoModel:SetPlayerCustomHeadUrl(MyPlayerId, Msg.PortraitUrl, Msg.AuditPortraitUrl)
            self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_CUSTOM_HEAD_INFO_CHANGED)
            self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID,MyPlayerId)

            if Msg.ActType == 1 then
                --表示来源来自于在线子系统更新自定义头像,需要马上装配自定义头像
                self:SendProto_PlayerSelectHeadReq(0)
            else
                local TipText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1053")
                UIAlert.Show(TipText)
            end
        else
            local MsgObject = {
                ErrCode = Msg.ErrCode,
                ErrCmd = "",
                ErrMsg = "",
            }
            MvcEntry:GetCtrl(ErrorCtrl):PopTipsAction(MsgObject, ErrorCtrl.TIP_TYPE.ERROR_CONFIG)

            -- 自定义头像 审核中&审核失败 更新一下数据
            if Msg.ErrCode == ErrorCode.PortraitAntiDoing.ID or Msg.ErrCode == ErrorCode.UploadPortraitFailed.ID then
                self.UserModel.AuditPortraitUrl = Msg.AuditPortraitUrl
                self.PersonalInfoModel:SetPlayerCustomHeadUrl(MyPlayerId, Msg.PortraitUrl, Msg.AuditPortraitUrl)
                self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_CUSTOM_HEAD_INFO_CHANGED)
            elseif Msg.ErrCode == ErrorCode.PortraitAntiDirtError.ID then
                self.PersonalInfoModel:SetPlayerCustomHeadUrl(MyPlayerId, self.UserModel.PortraitUrl, "")
                self.PersonalInfoModel:DispatchType(PersonalInfoModel.ON_CUSTOM_HEAD_INFO_CHANGED)
            end
        end
    end
end

------------------------------------请求头像设置相关----------------------------

-- 解锁头像
function PersonalInfoCtrl:SendProto_PlayerBuyHeadReq(HeadId)
    local Msg = {
        HeadId = HeadId
    }
    self:SendProto(Pb_Message.PlayerBuyHeadReq, Msg, Pb_Message.PlayerBuyHeadRsp)
end

-- 使用头像
function PersonalInfoCtrl:SendProto_PlayerSelectHeadReq(HeadId)
    local Msg = {
        HeadId = HeadId
    }
    self:SendProto(Pb_Message.PlayerSelectHeadReq, Msg, Pb_Message.PlayerSelectHeadRsp)
end

-- 解锁头像框
function PersonalInfoCtrl:SendProto_PlayerBuyHeadFrameReq(HeadFrameId)
    local Msg = {
        HeadFrameId = HeadFrameId
    }
    self:SendProto(Pb_Message.PlayerBuyHeadFrameReq, Msg, Pb_Message.PlayerBuyHeadFrameRsp)
end

-- 解锁头像挂件
function PersonalInfoCtrl:SendProto_PlayerBuyHeadWidgetReq(HeadWidgetId)
    local Msg = {
        HeadWidgetId = HeadWidgetId
    }
    self:SendProto(Pb_Message.PlayerBuyHeadWidgetReq, Msg, Pb_Message.PlayerBuyHeadWidgetRsp)
end

-- 请求保存头像框，头像挂件数据
--[[
    msg = message PlayerSaveHeadFrameWidgetDataReq{
        int64 HeadFrameId = 1;              // 头像框Id
        repeated HeadWidgetNode HeadWidgetList = 2; // 头像挂件数据
    }
    HeadWidgetNode = {
        int32 Angle = 1;                    // 角度位置
        int64 HeadWidgetId = 2;             // 挂件Id
    }
]]
function PersonalInfoCtrl:SendProto_PlayerSaveHeadFrameWidgetDataReq(Msg)
    self:SendProto(Pb_Message.PlayerSaveHeadFrameWidgetDataReq, Msg, Pb_Message.PlayerSaveHeadFrameWidgetDataRsp)
end

-- 请求上传自定义头像数据
---@param Data any 二进制头像数据  
---@param Fmt string 头像格式: png/jepg...
function PersonalInfoCtrl:SendProto_UploadPortraitReq(Data, Fmt,ActType)
    local Msg = {
        Data = Data,
        Fmt = Fmt,
        ActType = ActType or 0,
    }
    self:SendProto(Pb_Message.UploadPortraitReq, Msg, Pb_Message.UploadPortraitSync)
end

---------------------------------------------------
-- 请求替换头像框
-- 替换前要对挂件列表检查容量是否满足新头像框总容量，超出的要卸下
function PersonalInfoCtrl:RequestChangeHeadFrame(HeadFrameId)
    local TotalWeight = self.HeadIconSettingModel:GetHeadFrameTotalWeight(HeadFrameId)
    -- local HeadWidgetList = self.HeadIconSettingModel:GetUsingHeadWidgetList()
    local HeadWidgetList = self.HeadIconSettingModel:GetSortedUsingHeadWidgetList()
    local TargetHeadWidget = {}
    local ToUseWeight = 0
    if HeadWidgetList and #HeadWidgetList > 0 then
        -- for _,HeadWidgetNode in ipairs(HeadWidgetList) do
            -- 从后往前遍历，优先放入后添加的挂件
        for Index = #HeadWidgetList , 1, -1 do
            local HeadWidgetNode = HeadWidgetList[Index]
            local Cfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadWidget,HeadWidgetNode.HeadWidgetId)
            if Cfg then
                local Weight = Cfg[Cfg_HeadWidgetCfg_P.Weight]
                if Weight + ToUseWeight <= TotalWeight then
                    local TargetHeadWidgetNode = {
                        Angle = HeadWidgetNode.Angle,
                        HeadWidgetId = self.HeadIconSettingModel:TransUniqueId2Id(HeadWidgetNode.HeadWidgetId)
                    }
                    -- TargetHeadWidget[#TargetHeadWidget + 1] = TargetHeadWidgetNode
                    table.insert(TargetHeadWidget,1,TargetHeadWidgetNode)
                    ToUseWeight = ToUseWeight + Weight
                else
                    break
                end
            end
        end
    end
    local Msg = {
        HeadFrameId = HeadFrameId,
        HeadWidgetList = TargetHeadWidget
    }
    self:SendProto_PlayerSaveHeadFrameWidgetDataReq(Msg)
end

function PersonalInfoCtrl:RequestChangeHeadWidget()
    local CurHeadFrameId = self.PersonalInfoModel:GetMyPlayerProperty("HeadFrameId")
    local HeadWidgetList = self.HeadIconSettingModel:GetUsingHeadWidgetList()
    local TargetHeadWidget = {}
    for _,HeadWidgetNode in ipairs(HeadWidgetList) do
        local TargetHeadWidgetNode = {
            Angle = HeadWidgetNode.Angle,
            HeadWidgetId = self.HeadIconSettingModel:TransUniqueId2Id(HeadWidgetNode.HeadWidgetId)
        }
        TargetHeadWidget[#TargetHeadWidget + 1] = TargetHeadWidgetNode
    end
    local Msg = {
        HeadFrameId = CurHeadFrameId,
        HeadWidgetList = TargetHeadWidget
    }
    self:SendProto_PlayerSaveHeadFrameWidgetDataReq(Msg)
end


function PersonalInfoCtrl:StartReqCacheTickTimer()
    self:StopReqCacheTickTimer()
    self.ReqCacheTimer = Timer.InsertTimer(self.ReqCacheTime,function ()
        self:DoQueryPlayerInfo()
        self.ReqCacheTimer = nil
    end)    
end

function PersonalInfoCtrl:StopReqCacheTickTimer()
    if self.ReqCacheTimer then
        Timer.RemoveTimer(self.ReqCacheTimer)
    end
    self.ReqCacheTimer = nil
end

----------------------- 基本信息轮询相关 ----------------------------------------

function PersonalInfoCtrl:QueryPlayersBaseInfoByView(WidgetBaseOrHandler,PlayerIdList,IsRequestNow)
    if not PlayerIdList or #PlayerIdList == 0 then
        return
    end
    for _, PlayerId in ipairs(PlayerIdList) do
        self:QueryPlayerBaseInfoByView(WidgetBaseOrHandler,PlayerId,IsRequestNow)
    end
end

function PersonalInfoCtrl:QueryPlayerBaseInfoByView(WidgetBaseOrHandler,PlayerId,IsRequestNow)
    if not WidgetBaseOrHandler then
		CError("PersonalInfoCtrl QueryPlayerBaseInfoByView WidgetBaseOrHandler nil,please check",true)
		return
	end

    if WidgetBaseOrHandler.IsClass and WidgetBaseOrHandler.Handler and WidgetBaseOrHandler.Handler.IsClass and WidgetBaseOrHandler.Handler:IsClass(UIHandler) then
		WidgetBaseOrHandler = WidgetBaseOrHandler.Handler
    end
    if not self.ViewQueryList[WidgetBaseOrHandler] then
        self.ViewQueryList[WidgetBaseOrHandler] = {}
        WidgetBaseOrHandler:RegisterDisposeUICallBack(Bind(self,self.RemoveViewQuery,WidgetBaseOrHandler),self)
        WidgetBaseOrHandler:RegisterDestructUICallBack(Bind(self,self.RemoveViewQuery,WidgetBaseOrHandler),self)
    end
    self.ViewQueryList[WidgetBaseOrHandler][PlayerId] = self.ViewQueryList[WidgetBaseOrHandler][PlayerId] or 0
    self.ViewQueryList[WidgetBaseOrHandler][PlayerId] = self.ViewQueryList[WidgetBaseOrHandler][PlayerId] + 1
    self:PushQueryPlayerId(PlayerId,IsRequestNow)
end

function PersonalInfoCtrl:RemoveQueryPlayerBaseInfoByView(WidgetBaseOrHandler,PlayerId)
    if not WidgetBaseOrHandler then
		CError("PersonalInfoCtrl RemoveQueryPlayerBaseInfoByView WidgetBaseOrHandler nil,please check",true)
		return
	end

    if WidgetBaseOrHandler.IsClass and WidgetBaseOrHandler.Handler and WidgetBaseOrHandler.Handler.IsClass and WidgetBaseOrHandler.Handler:IsClass(UIHandler) then
		WidgetBaseOrHandler = WidgetBaseOrHandler.Handler
    end
    if self.ViewQueryList[WidgetBaseOrHandler] and self.ViewQueryList[WidgetBaseOrHandler][PlayerId] then
        if self.ViewQueryList[WidgetBaseOrHandler][PlayerId] > 0 then
            self.ViewQueryList[WidgetBaseOrHandler][PlayerId] = self.ViewQueryList[WidgetBaseOrHandler][PlayerId] - 1
            self:DeleteQueryPlayerId(PlayerId)
        end
        if self.ViewQueryList[WidgetBaseOrHandler][PlayerId] == 0 then
            self.ViewQueryList[WidgetBaseOrHandler][PlayerId] = nil
            if not next(self.ViewQueryList[WidgetBaseOrHandler]) then
                self:RemoveViewQuery(WidgetBaseOrHandler)
            end
        end
    else
		CError("PersonalInfoCtrl RemoveQueryPlayerBaseInfoByView Can't Get Query Info",true)
    end
end

--[[
    加入需要查询的Id（记得移除）
]]
---@param IsRequestNow 是否在当前帧先发起一起请求
function PersonalInfoCtrl:PushQueryPlayerId(PlayerId,IsRequestNow)
    if not PlayerId then
        return
    end
    if IsRequestNow then
        self:SendGetPlayerBaseInfoReq(PlayerId)
    end
    self.QueryIdMap[PlayerId] = self.QueryIdMap[PlayerId] or 0
    if self.QueryIdMap[PlayerId] == 0 then
        self.QueryIdList[#self.QueryIdList + 1] = PlayerId
    end
    self.QueryIdMap[PlayerId] = self.QueryIdMap[PlayerId] + 1
    if not self.QueryTimer then
        self:StartQueryTimer()
    end
end

-- 移除查询的id
function PersonalInfoCtrl:DeleteQueryPlayerId(PlayerId)
    if not PlayerId then
        return
    end
    if not self.QueryIdMap[PlayerId] or self.QueryIdMap[PlayerId] == 0 then
        return
    end
    self.QueryIdMap[PlayerId] = self.QueryIdMap[PlayerId] - 1
    if self.QueryIdMap[PlayerId] == 0 then
        local Index = nil
        for I,InPlayerId in ipairs(self.QueryIdList) do
            if InPlayerId == PlayerId then
                Index = I
                break
            end
        end
        if Index then
            table.remove(self.QueryIdList,Index)
        end
    end
    if #self.QueryIdList == 0 then
        self:StopQueryTimer()
    end
end

--[[
    加入需要查询的Id列表（记得移除）
]]
function PersonalInfoCtrl:PushQueryPlayerIdList(PlayerIdList)
    if not PlayerIdList or #PlayerIdList == 0 then
        return
    end
    for _, PlayerId in ipairs(PlayerIdList) do
        self:PushQueryPlayerId(PlayerId)
    end
end

-- 移除查询的id列表
function PersonalInfoCtrl:DeleteQueryPlayerIdList(PlayerIdList)
    if not PlayerIdList or #PlayerIdList == 0 then
        return
    end
    for _, PlayerId in ipairs(PlayerIdList) do
        self:DeleteQueryPlayerId(PlayerId)
    end
end

--------------------- private -------------------------------------------------------------------------------

function PersonalInfoCtrl:DoQueryPlayerInfo()
    local Msg = {
        PlayerIdList = self.BaseInfoReqCacheList 
    }
    print_r(self.BaseInfoReqCacheList)
    self:SendProto(Pb_Message.GetPlayerDetailInfoReq,Msg)
    -- 清空请求缓存
    self.BaseInfoReqCache = {}
    self.BaseInfoReqCacheList = {}
end

function PersonalInfoCtrl:RemoveViewQuery(Handler)
    local CountMap = self.ViewQueryList[Handler]
    if not CountMap then
        CError("PersonalInfoCtrl RemoveViewQuery Handler Error!!",true)
        return
    end
    for PlayerId,Count in pairs(CountMap) do
        for I= 1,Count do
            self:DeleteQueryPlayerId(PlayerId)
        end
    end
    Handler:UnRegisterDisposeUICallBack(self)
    Handler:UnRegisterDestructUICallBack(self)
    self.ViewQueryList[Handler] = nil
end


function PersonalInfoCtrl:StartQueryTimer()
    self:StopQueryTimer()
    if not self.QueryIdList or #self.QueryIdList == 0 then
        return
    end
    self.QueryTimer = Timer.InsertTimer(self.SocialInfoAutoCheckTime,function ()
        if not self.QueryIdList or #self.QueryIdList == 0 then
            self:StopQueryTimer()
            return
        end
        self:SendGetPlayerListBaseInfoReq(self.QueryIdList)
    end,true)    
end

function PersonalInfoCtrl:StopQueryTimer()
    if self.QueryTimer then
        Timer.RemoveTimer(self.QueryTimer)
    end
    self.QueryTimer = nil
end