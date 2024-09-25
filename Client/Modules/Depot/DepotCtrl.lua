--[[
    玩家仓库道具数据模块
]]

require("Client.Modules.Depot.DepotConst")
require("Client.Modules.Depot.DepotModel");

local class_name = "DepotCtrl";
---@class DepotCtrl : UserGameController
---@field private super UserGameController
---@field private model DepotModel
DepotCtrl = DepotCtrl or BaseClass(UserGameController,class_name);


function DepotCtrl:__init()
    CWaring("==DepotCtrl init")
    self.Model = nil
end

function DepotCtrl:Initialize()
    self.Model = self:GetModel(DepotModel)
    ---物品列表是否同步完成
    self.ItemFinshSyncState = false
end

--[[
    玩家登出
]]
function DepotCtrl:OnLogout(data)
    CWaring("DepotCtrl OnLogout")
    ---物品列表是否同步完成
    self.ItemFinshSyncState = false
end

---【重写】用户重连，登录，用于重连情景需要清除数据的场景
---@param data any data有值表示为断线重连类型
function DepotCtrl:OnLogoutReconnect(data) 
    if data then
        ---物品列表是否同步完成
        self.ItemFinshSyncState = false
    end
end

function DepotCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.PlayerItemChangeSyn,	Func = self.On_PlayerItemChangeSyn },
        {MsgName = Pb_Message.PlayerUseItemRsp,	Func = self.On_PlayerUseItemRsp },
    }

    self.MsgList = {
		-- { Model = nil, MsgName = CommonEvent.ON_LOGIN_FINISHED, Func = self.ON_LOGIN_FINISHED_Func },
    }
end


--[[
    通知-帐号已经准备好， 普通登录和断线重连都会触发  后于ON_LOGIN_INFO_SYNCED_WITH_EVENT触发(已废弃)
]]
-- function DepotCtrl:ON_LOGIN_FINISHED_Func()
--     self.ItemFinshSyncState = true
--     self.Model:DispatchType(DepotModel.ON_DEPOT_DATA_INITED)
-- end

--[[
    登录全量or增量同步玩家物品数量增加或者减少
]]
function DepotCtrl:On_PlayerItemChangeSyn(Msg)
    if self.ItemFinshSyncState then
        ---属于增量
        local NewUnlockHeroIds = {} -- 检测新解锁的英雄
        for _,ItemInfo in ipairs(Msg.ItemList) do
            local CurData = self.Model:GetData(ItemInfo.ItemUniqId)
            local CurCount = CurData and CurData.ItemNum or 0
            local NewCount = CurCount
            if Msg.ChangeType == Pb_Enum_SYN_ITEM_CHANGE_TYPE.SYN_ITEM_CHANGE_ADD then
                -- 增加物品
                NewCount = CurCount + ItemInfo.ItemNum
                -- TODO 临时打印
                -- CWaring(StringUtil.Format("获得{0}共{1}个，共有{2}个",ItemInfo.ItemUniqId,ItemInfo.ItemNum,NewCount))
                if NewCount ~= 0 and CurCount == 0 and self:CheckIsHeroForId(ItemInfo.ItemId) then
                    NewUnlockHeroIds[#NewUnlockHeroIds + 1] = ItemInfo.ItemId
                end
            elseif Msg.ChangeType == Pb_Enum_SYN_ITEM_CHANGE_TYPE.SYN_ITEM_CHANGE_DEL then
                -- 减少物品
                NewCount = CurCount - ItemInfo.ItemNum
                if NewCount < 0 then
                    NewCount = 0
                end
                -- CWaring(StringUtil.Format("减少{0}共{1}个，剩余{2}个",ItemInfo.ItemUniqId,ItemInfo.ItemNum,NewCount))
            end    
            ItemInfo.ItemNum = NewCount
        end
        self.Model:UpdateDatas(Msg.ItemList)
        if #NewUnlockHeroIds > 0 then
            MvcEntry:GetModel(HeroModel):DispatchType(HeroModel.ON_NEW_HERO_UNLOCKED,NewUnlockHeroIds)
        end
    else
        ---属于登录全量更新
        self.Model:SetDataList(Msg.ItemList, true)
        -- 第一次同步完成，即设置全量同步结束，后续都走增量
        self.ItemFinshSyncState = true
        self.Model:DispatchType(DepotModel.ON_DEPOT_DATA_INITED)
    end
end

-- 检测是不是英雄类型
function DepotCtrl:CheckIsHeroForId(ItemId)
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not ItemCfg then
        return false
    end
    return ItemCfg[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER and ItemCfg[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Hero
end

--[[
    客户端请求使用物品
]]
function DepotCtrl:SendPlayerUseItemReq(ItemId,UseItemNum,ItemUniqId)
    local Msg = {
        ItemId = ItemId,
        UseItemNum = UseItemNum,
        ItemUniqId = ItemUniqId,
    }
    -- CWaring(StringUtil.Format("------使用{0}共{1}个",ItemUniqId,UseItemNum))
    self:SendProto(Pb_Message.PlayerUseItemReq,Msg,Pb_Message.PlayerUseItemRsp)
end

--[[
    服务器应答使用物品返回协议
]]
function DepotCtrl:On_PlayerUseItemRsp(Msg)
    local TipsStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotCtrl_Successfuluse")
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,Msg.ItemId)
    if ItemCfg then
        local UseType = ItemCfg[Cfg_ItemConfig_P.UseType]
        if UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_COMPOSE_ITEM then
            TipsStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotCtrl_ComposeSucess")
        end
    end
    UIAlert.Show(TipsStr)
end
