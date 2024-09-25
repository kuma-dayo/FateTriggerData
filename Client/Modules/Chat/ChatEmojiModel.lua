--[[
    聊天表情数据模型
]]

local super = GameEventDispatcher;
local class_name = "ChatEmojiModel";

---@class ChatEmojiModel : GameEventDispatcher
---@field private super GameEventDispatcher
ChatEmojiModel = BaseClass(super, class_name)
ChatEmojiModel.ON_OPEN_EMOJI_PANEL = "ON_OPEN_EMOJI_PANEL" -- 打开选择表情面板
ChatEmojiModel.ON_CLOSE_EMOJI_PANEL = "ON_CLOSE_EMOJI_PANEL" -- 关闭选择表情面板
ChatEmojiModel.ON_NEW_CHAT_EMOJI_UNLOCK = "ON_NEW_CHAT_EMOJI_UNLOCK" -- 有新的表情解锁
ChatEmojiModel.DO_SEND_EMOJI = "DO_SEND_EMOJI" -- 发送聊天

function ChatEmojiModel:__init()
    self:_dataInit()
end

function ChatEmojiModel:_dataInit()
    self.LockList = {}
    self.EmojiShowList = {}
end

function ChatEmojiModel:OnLogin(data)
    -- self:_dataInit()
end

--[[
    玩家登出时调用
]]
function ChatEmojiModel:OnLogout(data)
    ChatEmojiModel.super.OnLogout(self)
    self:_dataInit()
end

-- 是否有可展示的表情
function ChatEmojiModel:HaveEmojiToShow()
    if self.IsDataChanged then
        self:UpdateShowList()
    end
    if not (self.EmojiShowList and self.EmojiShowList[1]) then
        return false
    end
    -- 1为所有表情
    return #self.EmojiShowList[1] > 0
end

-- 获取展示的表情列表
function ChatEmojiModel:GetEmojiShowList()
    if self.IsDataChanged then
        self:UpdateShowList()
    end
    return self.EmojiShowList
end

-- 更新展示的表情列表
function ChatEmojiModel:UpdateShowList()
    self.LockList = {}
    self.EmojiShowList = {}
    self.EmojiShowList[1] = {} -- 默认1为‘所有’分类
    self.DepotModel = MvcEntry:GetModel(DepotModel)
    local Cfgs = G_ConfigHelper:GetDict(Cfg_ChatEmojiCfg)
    for _, Cfg in ipairs(Cfgs) do
        local ItemId = Cfg[Cfg_ChatEmojiCfg_P.ItemId]
        local IsUnlock = self.DepotModel:HaveItem(ItemId)
        if IsUnlock then
            local EmojiId = Cfg[Cfg_ChatEmojiCfg_P.EmojiId]
            local SeriresId = Cfg[Cfg_ChatEmojiCfg_P.SeriesId]
            self.EmojiShowList[SeriresId] = self.EmojiShowList[SeriresId] or {}
            self.EmojiShowList[1][#self.EmojiShowList[1] + 1] = EmojiId
            self.EmojiShowList[SeriresId][#self.EmojiShowList[SeriresId] + 1] = EmojiId
        else
            self.LockList[ItemId] = 1 
        end
    end

    for _, EmojiList in pairs(self.EmojiShowList) do
        table.sort(EmojiList, function (EmojiIdA,EmojiIdB)
            return EmojiIdA < EmojiIdB
        end)
    end

    self.IsDataChanged = false
end

function ChatEmojiModel:CheckEmojiUnlock(ChangeMap)
    local AddMap = ChangeMap["AddMap"]
    for _, ItemVo in ipairs(AddMap) do
        local ItemId = ItemVo.ItemId
        if self.LockList[ItemId] then
            self.IsDataChanged = true
            break
        end
    end
    if not self.IsDataChanged then
        local UpdateMap = ChangeMap["UpdateMap"]
        for _, ItemVo in ipairs(UpdateMap) do
            local ItemId = ItemVo.ItemId
            if ItemVo.ItemNum > 0 then
                if self.LockList[ItemId] then
                    self.IsDataChanged = true
                    break
                end
            end
        end
    end
    if self.IsDataChanged then
        self:DispatchType(ChatEmojiModel.ON_NEW_CHAT_EMOJI_UNLOCK)
    end
end