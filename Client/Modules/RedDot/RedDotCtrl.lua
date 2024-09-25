---
--- Ctrl 模块，主要用于处理协议
--- Description: 红点
--- Created At: 2023/10/11 14:38
--- Created By: 朝文
---

require("Client.Modules.RedDot.RedDotModel")

local class_name = "RedDotCtrl"
---@class RedDotCtrl : UserGameController
---@field private model RedDotModel
RedDotCtrl = RedDotCtrl or BaseClass(UserGameController, class_name)

function RedDotCtrl:__init()
    ---@type RedDotModel
    CWaring("[cw] RedDotCtrl init")
    self.Model = nil
    self:ResetData()
end

function RedDotCtrl:Initialize()
    ---@type RedDotModel
    self.Model = self:GetModel(RedDotModel)
end

--[[
    玩家登入的时候，进行请求数据
]]
function RedDotCtrl:OnLogin(data)
    CWaring("[cw] RedDotCtrl OnLogin")
    if data then
        self:ResetData()
    end
end

--[[
    玩家登出
]]
function RedDotCtrl:OnLogout(data)
    self:ResetData()
end

function RedDotCtrl:ResetData()
    --是否接收完服务器红点数据
    self.DataInited = false
    --依赖服务器数据的系统  需要依赖服务器数据返回再请求
    self.DependSystemList = {
        [Pb_Enum_RED_DOT_SYS.RED_DOT_MAIL] = false,
        -- [Pb_Enum_RED_DOT_SYS.RED_DOT_ITEM] = false,
    }
end

function RedDotCtrl:AddMsgListenersUser()
    --添加协议回包监听事件
    self.ProtoList = {
        {MsgName = Pb_Message.PlayerGetRedDotDataRsp, Func = self.On_PlayerGetRedDotDataRsp},
        {MsgName = Pb_Message.PlayerUpdateRedDotInfoSyn, Func = self.On_PlayerUpdateRedDotInfoSyn},
        {MsgName = Pb_Message.PlayerCancelRedDotInfoRsp, Func = self.On_PlayerCancelRedDotInfoRsp},
        {MsgName = Pb_Message.PlayerSetRedDotInfoTagRsp, Func = self.On_PlayerSetRedDotInfoTagRsp},
    }
    self.MsgList = {
		{Model = DepotModel,  	MsgName = DepotModel.ON_DEPOT_DATA_INITED,      Func = self.ON_DEPOT_DATA_INITED_FUNC},
        {Model = MailModelSystem, MsgName = MailModelSystem.ON_MAIL_DATA_INITED,    Func = self.ON_MAIL_DATA_INITED_FUNC},

        {Model = NewSystemUnlockModel, MsgName = NewSystemUnlockModel.ON_PLAYER_UNLOCK_INFO_INITED,    Func = self.ON_PLAYER_UNLOCK_INFO_INITED_FUNC},
        {Model = NewSystemUnlockModel, MsgName = NewSystemUnlockModel.ON_NEW_SYSTEM_UNLOCK,    Func = self.ON_NEW_SYSTEM_UNLOCK_FUNC},
    }
end

---获取某些系统的红点数据返回
function RedDotCtrl:On_PlayerGetRedDotDataRsp(Msg)
    if Msg == nil then
        return
    end
    self.DataInited = true
    -- print_r(Msg, "[hz] RedDotCtrl:On_PlayerGetRedDotDataRsp()------msg")
    self.Model:SetRedDotData(Msg)
end

function RedDotCtrl:On_PlayerUpdateRedDotInfoSyn(Msg)
    --没有接收到服务器数据前不需要处理更新的数据
    if Msg == nil or self.DataInited == false then
        return
    end
    print_r(Msg, "[hz] RedDotCtrl:PlayerUpdateRedDotInfoSyn()------msg")
    local RedDotSysMap = self:CheckAutoCancelRedDotInfo(Msg.RedDotSysMap)
    self.Model:UpdateRedDotData(RedDotSysMap, Msg.DigitRedDotMap)
end

---取消红点返回
function RedDotCtrl:On_PlayerCancelRedDotInfoRsp(Msg)
    if Msg == nil then
        return
    end
    print_r(Msg, "[hz] RedDotCtrl:On_PlayerCancelRedDotInfoRsp()------msg")
    self.Model:UpdateCancelRedDotData(Msg)
end

---设置红点自定义Tag数据返回
function RedDotCtrl:On_PlayerSetRedDotInfoTagRsp(Msg)
    if Msg == nil then
        return
    end
    print_r(Msg, "[hz] RedDotCtrl:On_PlayerSetRedDotInfoTagRsp()------msg")
    self.Model:UpdateSetRedDotTagData(Msg)
end

--仓库数据接收完成返回
function RedDotCtrl:ON_DEPOT_DATA_INITED_FUNC()
    -- self.DependSystemList[Pb_Enum_RED_DOT_SYS.RED_DOT_ITEM] = true
    -- self:ReqPlayerGetRedDotData()
end

--邮件数据接收完成返回
function RedDotCtrl:ON_MAIL_DATA_INITED_FUNC()
    self.DependSystemList[Pb_Enum_RED_DOT_SYS.RED_DOT_MAIL] = true
    self:ReqPlayerGetRedDotData() 
end

-- 系统解锁信息初始化完成
function RedDotCtrl:ON_PLAYER_UNLOCK_INFO_INITED_FUNC()
    self.Model:InitRedDotUnlockList()
end

-- 通知系统解锁
function RedDotCtrl:ON_NEW_SYSTEM_UNLOCK_FUNC(UnlockId)
    self.Model:UpdateRedDotUnlockList(UnlockId)
end

---依赖的各系统数据接收完成时 开始请求红点数据
function RedDotCtrl:ReqPlayerGetRedDotData()
    --防止反复请求
    if self.DataInited then return end
    local AlReady = true
    for k, v in pairs(self.DependSystemList) do
        if v == false then
            AlReady = false
            break
        end
    end
    if AlReady then
        self:SendPlayerGetRedDotDataReq()
    end
end

---红点交互，根据配置触发特定的交互逻辑
---@param RedDotKey string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param RedDotSuffix string|number  红点尾缀，例如 TabHero_200010000 中的 200010000
---@param TriggerType number 红点触发操作类型
---@param IsCancelAllRedDot boolean 是否取消该系统的所有红点
function RedDotCtrl:Interact(RedDotKey, RedDotSuffix, TriggerType, IsCancelAllRedDot)
    CLog("[cw] RedDotCtrl:Interact(" .. string.format("%s, %s", RedDotKey, RedDotSuffix) .. ")")
    --0.无节点不处理
    local wholeKey = self.Model:ContactKey(RedDotKey, RedDotSuffix)
    TriggerType = TriggerType or RedDotModel.Enum_RedDotTriggerType.Click
    IsCancelAllRedDot = IsCancelAllRedDot and true or false
    ---@type RedDotNode
    local RedDotNode = self.Model:GetNodeWithKey(wholeKey)
    if not RedDotNode then return end
    --检测是否跟配置的触发类型一致   一致才响应
    if not RedDotNode:CheckIsSameTriggerType(TriggerType) then return end

    local InteractiveTypeEnum = self.Model:RedDotInteractiveTypeCfg_GetRedDotinteractiveTypeEnum_ByRedDotHierarchyCfgKey(RedDotKey)
    local ServerSysId = RedDotNode.ServerSysId
    local ServerKeyId = RedDotNode.ServerKeyId
    if self.Model:IsEnumRedDotInteractive_NoAction(InteractiveTypeEnum) then
        --not to do
    elseif self.Model:IsEnumRedDotInteractive_ClearSelfAndChildren(InteractiveTypeEnum) then
        local CancelSysId, CancelRedDotList = self.Model:GetAllCancelRedDotSysIdList(RedDotKey, RedDotSuffix, IsCancelAllRedDot)
        if CancelSysId ~= Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD  or #CancelRedDotList > 0 then
            CLog("[hz] RedDotCtrl:Interact CancelSysId=" .. tostring(CancelSysId))
            print_r(CancelRedDotList, "[hz] RedDotCtrl:Interact()------CancelRedDotList")
            self:SendPlayerCancelRedDotInfoReq(CancelSysId, CancelRedDotList)
        else
            ---其余直接走前端逻辑检测
            self.Model:InteractCallBack(RedDotKey, RedDotSuffix)
        end
    elseif self.Model:IsEnumRedDotInteractive_AddTagForChildren(InteractiveTypeEnum) then
        ---需要打标记的走服务器驱动
        local CustomKey = self.Model:ContactCustomKey(RedDotKey, RedDotSuffix)
        local ChildKeyList = self.Model:GetAllChildRedDotKeyList(RedDotKey, RedDotSuffix)
        local CustomInfoMap = {
            [CustomKey] = {
                ["Tag"] = ChildKeyList
            },
        }
        self:SendPlayerSetRedDotInfoTagReq(CustomInfoMap, true)
    else
        ---其余直接走前端逻辑检测
        self.Model:InteractCallBack(RedDotKey, RedDotSuffix)
    end
end

---------------------------检测红点自动触发消失---------------------------------
-- 当红点更新时候，检测某些特殊情况的红点是否直接触发消失
function RedDotCtrl:CheckAutoCancelRedDotInfo(RedDotSysMap)
    for SysId, RedDotInfo in pairs(RedDotSysMap) do
        local RedDotMap = RedDotInfo["RedDotMap"]
        for KeyId, Value in pairs(RedDotMap) do
            local State = Value["State"]
            if State then
                if SysId == Pb_Enum_RED_DOT_SYS.RED_DOT_CHAT_TEAM then
                    -- 在聊天组队页签时 直接消除红点
                    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.Chat) then
                        if MvcEntry:GetModel(ChatModel):GetCurChatType() == Pb_Enum_CHAT_TYPE.TEAM_CHAT then
                            Value["State"] = false
                            local SysId = Pb_Enum_RED_DOT_SYS.RED_DOT_CHAT_TEAM
                            local CancelRedDotList = {
                            }
                            self:SendPlayerCancelRedDotInfoReq(SysId, CancelRedDotList)
                        end
                    end
                    break;
                end
            end
        end
    end
    return RedDotSysMap
end
---------------------------检测红点自动触发消失---------------------------------

-----------------------------------------请求相关------------------------------
---获取某些系统的红点数据请求
function RedDotCtrl:SendPlayerGetRedDotDataReq()
    local Msg = {

    }
    self:SendProto(Pb_Message.PlayerGetRedDotDataReq, Msg)
end

---取消红点请求
---@param SysId number 红点系统枚举 该字段如果有值， 则取消该系统的所有红点数据，为0时，则以CancelRedDotList列表为准
---@param CancelRedDotList table 要取消的红点列表信息
function RedDotCtrl:SendPlayerCancelRedDotInfoReq(SysId, CancelRedDotList)
    local Msg = {
        SysId = SysId,
        CancelRedDotList = CancelRedDotList
    }
    CLog("[hz] SendPlayerCancelRedDotInfoReq")
    print_r(Msg)
    self:SendProto(Pb_Message.PlayerCancelRedDotInfoReq, Msg, Pb_Message.PlayerCancelRedDotInfoRsp)
end

---设置红点自定义Tag数据
---@param CustomInfoMap table 自定义Tag数据
---@param SetFlag boolean true 存储数据， false 取消数据
function RedDotCtrl:SendPlayerSetRedDotInfoTagReq(CustomInfoMap, SetFlag)
    local Msg = {
        CustomInfoMap = CustomInfoMap,
        SetFlag = SetFlag
    }
    self:SendProto(Pb_Message.PlayerSetRedDotInfoTagReq, Msg)
end

