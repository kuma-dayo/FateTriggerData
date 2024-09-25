---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 红点数据存储
--- Created At: 2023/10/10 20:14
--- Created By: 朝文
---

local super = ListModel
local class_name = "RedDotModel"
---@class RedDotModel : ListModel
RedDotModel = BaseClass(super, class_name)

RedDotModel.ON_REDDOT_ADDED   = "ON_REDDOT_ADDED"               --新增一个红点节点
RedDotModel.ON_REDDOT_REMOVED = "ON_REDDOT_REMOVED"             --移除一个红点节点
RedDotModel.ON_REDDOT_UPATED  = "ON_REDDOT_UPATED"              --红点节点的红点数量变动

RedDotModel.ON_REDDOT_TAG_ADDED   = "ON_REDDOT_TAG_ADDED"       --红点标签新增
RedDotModel.ON_REDDOT_TAG_REMOVED = "ON_REDDOT_TAG_REMOVED"     --红点标签移除
RedDotModel.ON_REDDOT_DIGIT_DATA_UPDATE = "ON_REDDOT_DIGIT_DATA_UPDATE"     --红点数字数据更新
RedDotModel.ON_REDDOT_UNLOCK_STATE_UPDATE = "ON_REDDOT_UNLOCK_STATE_UPDATE"     --红点解锁状态更新

--参考【RedDot.xlsx】中的【红点显示规则枚举】页签
RedDotModel.Enum_RedDotDisplayRule = {
    DoNotShow                = "DoNotShow",
    HasAnyChild              = "HasAnyChild",
    HasAnyChildNotContainTag = "HasAnyChildNotContainTag"
}

--参考【RedDot.xlsx】中的【红点展示类型枚举】页签
RedDotModel.Enum_RedDotDisplayType = {
    Normal  = "Normal",
    Number  = "Number",
    Text    = "Text",
}

--参考【RedDot.xlsx】中的【红点交互类型】页签
RedDotModel.Enum_RedDotInteractive = {
    NoAction                = "NoAction",
    ClearSelfAndChildren    = "ClearSelfAndChildren",
    AddTagForChildren       = "AddTagForChildren",
}

--参考【RedDot.xlsx】中的【红点层级】页签-红点触发操作类型
RedDotModel.Enum_RedDotTriggerType  = {
    --点击触发
    Click = 1,
    --悬停触发
    Hover = 2,
}

---用于区分物品系统里对应道具的红点前缀 key为红点前缀 value为对应的配置参数
RedDotModel.Const_ChangeItemRedDotConfigParam = {
    -- 皮肤item
    ["TabHeroSkinItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "HeroSkin", -- 等同于 Cfg_HeroSkin
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroSkin_P.ItemId
            -- 需要额外判断的参数列表  参数不符合则不属于此红点
            ExtraConfigParamList = {
                ["SuitID"] = 0,
            },
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "HeroSkin", -- 等同于 Cfg_HeroSkin
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroSkin_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "SkinId", -- 等同于 Cfg_HeroSkin_P.SkinId
        }
    },
    -- 仓库item
    ["DepotItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "ItemConfig", -- 等同于 Cfg_ItemConfig
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_ItemConfig_P.ItemId
            -- 需要额外判断的参数列表  
            ExtraConfigParamList = {
                -- 是否在背包中显示
                ["IsDepot"] = true, -- 等同于 Cfg_ItemConfig_P.IsDepot
            }
        }
    },
    -- 表情包item
    ["ChatEmojiItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "ChatEmojiCfg", -- 等同于 Cfg_ChatEmojiCfg
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_ChatEmojiCfg_P.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "ChatEmojiCfg", -- 等同于 Cfg_ChatEmojiCfg
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_ChatEmojiCfg_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "EmojiId", -- 等同于 Cfg_ChatEmojiCfg_P.EmojiId
        }
    },
    -- 先觉者绘框底板item
    ["HeroDisplayBoardFloorItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "HeroDisplayFloor", -- 等同于 Cfg_HeroDisplayFloor
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroDisplayFloor_P.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "HeroDisplayFloor", -- 等同于 Cfg_HeroDisplayFloor
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroDisplayFloor_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "ItemId", -- 等同于 Cfg_HeroDisplayFloor_P.ItemId
        }
    },
    -- 先觉者绘框角色item
    ["HeroDisplayBoardRoleItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "HeroDisplayRole", -- 等同于 Cfg_HeroDisplayRole
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroDisplayRole_P.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "HeroDisplayRole", -- 等同于 Cfg_HeroDisplayRole
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroDisplayRole_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "ItemId", -- 等同于 Cfg_HeroDisplayRole_P.ItemId
        }
    },
    -- 先觉者绘框特效item
    ["HeroDisplayBoardEffectItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "HeroDisplayEffect", -- 等同于 Cfg_HeroDisplayEffect
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroDisplayEffect.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "HeroDisplayEffect", -- 等同于 Cfg_HeroDisplayEffect
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroDisplayEffect_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "ItemId", -- 等同于 Cfg_HeroDisplayEffect.ItemId
        }
    },
    -- 先觉者绘框贴纸item
    ["HeroDisplayBoardStickerItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "HeroDisplaySticker", -- 等同于 Cfg_HeroDisplaySticker
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroDisplaySticker_P.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "HeroDisplaySticker", -- 等同于 Cfg_HeroDisplaySticker
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroDisplaySticker_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "ItemId", -- 等同于 Cfg_HeroDisplaySticker_P.ItemId
        }
    },
    -- 头像
    ["InformationPersonalHeadIconItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "HeroHeadConfig", -- 等同于 Cfg_HeroHeadConfig
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroHeadConfig_P.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "HeroHeadConfig", -- 等同于 Cfg_HeroHeadConfig
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_HeroHeadConfig_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "HeadId", -- 等同于 Cfg_HeroHeadConfig_P.HeadId
        }
    },
    -- 头像框
    ["InformationPersonalHeadIconFrameItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "HeadFrameCfg", -- 等同于 Cfg_HeadFrameCfg
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_HeadFrameCfg_P.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "HeadFrameCfg", -- 等同于 Cfg_HeadFrameCfg
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_HeadFrameCfg_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "Id", -- 等同于 Cfg_HeadFrameCfg_P.Id
        }
    },
    -- 头像挂件
    ["InformationPersonalHeadWidgetItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "HeadWidgetCfg", -- 等同于 Cfg_HeadWidgetCfg
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_HeadWidgetCfg_P.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "HeadWidgetCfg", -- 等同于 Cfg_HeadWidgetCfg
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_HeadWidgetCfg_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "Id", -- 等同于 Cfg_HeadWidgetCfg_P.Id
        }
    },
    -- 战备-武器-皮肤
    ["ArsenalWeaponSkinItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "WeaponSkinConfig", -- 等同于 Cfg_WeaponSkinConfig
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_WeaponSkinConfig_P.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "WeaponSkinConfig", -- 等同于 Cfg_WeaponSkinConfig
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_WeaponSkinConfig_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "SkinId", -- 等同于 Cfg_WeaponSkinConfig_P.SkinId
        }
    },
    -- 战备-载具-皮肤
    ["ArsenalVehicleSkinItem_"] = {
        -- 通过检测表判断物品是否属于此红点
        CheckConfigParam = {
            -- 配置表名称
            ConfigName = "VehicleSkinConfig", -- 等同于 Cfg_VehicleSkinConfig
            -- 取表的参数名  
            ConfigValue = "ItemId", -- 等同于 Cfg_VehicleSkinConfig_P.ItemId
        },
        -- 如果服务器下发的key没法直接作为红点后缀使用的话，需要传表进行转换
        ChangeSuffixKeyConfigParam = {
            -- 配置表名称
            ConfigName = "VehicleSkinConfig", -- 等同于 Cfg_VehicleSkinConfig
            -- 取表的参数名
            ConfigValue = "ItemId", -- 等同于 Cfg_VehicleSkinConfig_P.ItemId
            -- 需要获取的配置参数
            ConfigValueParam = "SkinId", -- 等同于 Cfg_VehicleSkinConfig_P.SkinId
        }
    },
}

---服务器的红点系统ID对应的叶子节点红点前缀（配置表对应）
RedDotModel.Const_SysRedDotKey = {
    [Pb_Enum_RED_DOT_SYS.RED_DOT_MAIL] = "MailTabItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_NOTICE] = "BroadcastTabItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_SHOP] = "ShopTabItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_GAME_PLAY_MODE] = "LevelDetails_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_CHAT_FRIEND] = "ChatFriendItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_CHAT_TEAM] = "ChatTeamItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_TEAM_INVIT] = "TeamUpInviteItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_TEAM_APPLY] = "TeamUpApplyItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_TEAM_ADD_FRIEND] = "TeamUpAddFriendItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_ACTIVITY] = "ActivityType_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_ACTIVITY_SUBITEM] = "ActivitySubItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_PLAYER_LEVEL] = "LevelGrowthRewardItem_",
    [Pb_Enum_RED_DOT_SYS.RED_DOT_BATTLE_PASS] = "SeasonBpRewardItem_",
}

function RedDotModel:__init()
    self:DataInit()
end

---初始化数据，用于第一次调用及登出的时候调用
function RedDotModel:DataInit()
    ---@type table<string, RedDotNode>
    self.RedDotMapKey2Node = {}
    ---@type RedDotNode[] 
    self.RedDotTree = {}

    self.ParentAndChildRelationshipMap = {}

    -- 自定义tag数据 
    self.CustomInfoMap = {}
    ---数字红点数据 key为红点框架的wholeKey value为table { 系统id SysId: 1, 数字红点展示数据 Value:99}
    self.DigitRedDotMap = {}

    -- 红点解锁状态列表 key 为红点前缀  value为解锁状态
    self.RedDotUnlockStateList = {}
    -- 红点解锁ID列表 key 为解锁ID  value为红点前缀列表
    self.RedDotUnlockIdList = {}
    -- 系统红点列表 key为服务器定义的红点系统类型 value为{{RedDotKey, RedDotSuffix}}
    self.SysRedDotList = {}
end

---@param data any
function RedDotModel:OnLogin(data)
    self:DataInit()
end

---玩家登出时调用
function RedDotModel:OnLogout(data)
    self:DataInit()
end
-------------------------------------事件驱动数据更新------------------------------------------
--- 初始化红点解锁列表
function RedDotModel:InitRedDotUnlockList()
    local RedDotCfgDict = self:RedDotHierarchyCfg_GetCfgDict()
    if RedDotCfgDict then
        -- 数据是登录服务器下发的 所以这里可以取到值
        local NewSystemUnlockModel = MvcEntry:GetModel(NewSystemUnlockModel)
        for _, RedDotCfg in pairs(RedDotCfgDict) do
            local UnlockId = RedDotCfg[Cfg_RedDotHierarchyCfg_P.RedDotUnlockId]
            local RedDotKey = RedDotCfg[Cfg_RedDotHierarchyCfg_P.Key]
            if UnlockId and UnlockId > 0 then
                local IsUnlock = NewSystemUnlockModel:IsSystemUnlock(UnlockId)
                self.RedDotUnlockStateList[RedDotKey] = IsUnlock

                self.RedDotUnlockIdList[UnlockId] = self.RedDotUnlockIdList[UnlockId] or {}

                local Length = self.RedDotUnlockIdList[UnlockId]
                self.RedDotUnlockIdList[UnlockId][Length + 1] = RedDotKey
            end
        end
    end
end

--- 更新红点解锁列表
function RedDotModel:UpdateRedDotUnlockList(UnlockId)
    local UnlockRedDotList = self.RedDotUnlockIdList[UnlockId]
    if UnlockRedDotList then
        for _, RedDotKey in ipairs(UnlockRedDotList) do
            self.RedDotUnlockStateList[RedDotKey] = true
            self:DispatchType(RedDotModel.ON_REDDOT_UNLOCK_STATE_UPDATE, RedDotKey)
        end
    end
end

-- 通过红点前缀判断解锁状态
function RedDotModel:CheckRedDotIsUnlock(RedDotKey)
    local IsUnlock = true
    -- true & nil 均为已解锁
    if self.RedDotUnlockStateList[RedDotKey] == false then
        IsUnlock = false
    end
    return IsUnlock
end
-------------------------------------服务器下发数据start---------------------------------------
---登录请求返回的服务器红点数据
function RedDotModel:SetRedDotData(Msg)
    self:UpdateRedDotSysData(Msg.RedDotSysMap)
    self:UpdateCustomRedDotData(Msg.CustomInfoMap, true)
    self:UpdateDigitRedDotData(Msg.DigitRedDotMap, false)
end

---增量同步红点数据   注：这一步RedDotSysMap有检测不一定等于服务器原始数据
function RedDotModel:UpdateRedDotData(RedDotSysMap, DigitRedDotMap)
    self:UpdateRedDotSysData(RedDotSysMap)
    self:UpdateDigitRedDotData(DigitRedDotMap, true)
end

---更新取消红点的数据
function RedDotModel:UpdateCancelRedDotData(Msg)
    ---该字段如果有值，则取消该系统的所有红点数据
    if Msg.SysId ~= Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD then
        local SysRedDotKey = ""
        local RedDotSuffix = ""
        local SysRedDotList = self:GetSysRedDotList(Msg.SysId)
        for _, RedDotData in ipairs(SysRedDotList) do
            self:RemoveRedDot(RedDotData.RedDotKey, RedDotData.RedDotSuffix, Msg.SysId)
        end
    else 
        if not Msg.CancelRedDotList then return end
        for Key, Value in pairs(Msg.CancelRedDotList) do
            local SysId = Value.SysId
            local KeyId = Value.KeyId
            self:UpdateRedDotState(SysId, KeyId, false)
        end
    end
end

---更新自定义Tag红点数据
function RedDotModel:UpdateSetRedDotTagData(Msg)
    self:UpdateCustomRedDotData(Msg.CustomInfoMap, Msg.SetFlag)
end

-------------------------------------服务器下发数据end-----------------------------------------
---更新系统红点状态(RedDotSysMap数据) 将服务器数据更新到红点框架
---@param RedDotSysMap table 系统红点状态数据
function RedDotModel:UpdateRedDotSysData(RedDotSysMap)
    if RedDotSysMap then
        for SysId, RedDotInfo in pairs(RedDotSysMap) do
            local RedDotMap = RedDotInfo["RedDotMap"]
            for KeyId, Value in pairs(RedDotMap) do
                local State = Value["State"]
                CLog("[hz] UpdateRedDotSysData SysId =" .. tostring(SysId) .. "KeyId=" .. tostring(KeyId) .. "State=" .. tostring(State))
                self:UpdateRedDotState(SysId, KeyId, State)
            end
        end
    end
end

---更新红点自定义Tag（CustomInfoMap数据） 将服务器数据更新到红点框架
---@param CustomInfoMap table 自定义红点状态数据
---@param IsTag boolean 是否打标记
function RedDotModel:UpdateCustomRedDotData(CustomInfoMap, IsTag)
    if CustomInfoMap then
        self.CustomInfoMap = CustomInfoMap or {}
        for CustomKey, Value in pairs(CustomInfoMap) do
            local RedDotKey, RedDotSuffix = self:SplitCustomKey(CustomKey)
            if RedDotKey and IsTag then
                local RedDotInteractiveTypeId = self:RedDotHierarchyCfg_GetRedDotInteractiveTypeId(RedDotKey)
                local TagKey = self:RedDotInteractiveTypeCfg_StringParam1(RedDotInteractiveTypeId)
                --如果参数配置的是self，则说明要使用自身的key作为tag，加到所有孩子上
                local WholeKey = self:ContactKey(RedDotKey, RedDotSuffix)
                if TagKey == "self" then TagKey = WholeKey end
                local RedDotTagList = Value["Tag"]
                for _, RedDotwholeKey in pairs(RedDotTagList) do
                    self:AddTagToLeaftNode(RedDotwholeKey, TagKey)
                end  
            end
        end
    end
end

---更新数字红点的红点数据(DigitRedDotMap数据) 数字红点需要展示的字样
---@param DigitRedDotMap table 自定义红点状态数据
---@param IsUpdate boolean 是否更新数据 如果是更新的情况需要派发事件更新
function RedDotModel:UpdateDigitRedDotData(DigitRedDotMap, IsUpdate)
    if DigitRedDotMap then
        for Key, DigitValue in pairs(DigitRedDotMap) do
            local SysId, KeyId = self:SplitCustomKey(Key)
            local PrefixKey, SuffixKey = self:ChangeSysIdToPrefixKey(SysId, KeyId)
            if PrefixKey then
                local WholeKey = self:ContactKey(PrefixKey, SuffixKey)
                self.DigitRedDotMap[WholeKey] = {
                    DigitValue = DigitValue
                }
                if IsUpdate then self:DispatchType(RedDotModel.ON_REDDOT_DIGIT_DATA_UPDATE, WholeKey) end
            end
        end
    end
end

---更新对应的红点状态
function RedDotModel:UpdateRedDotState(SysId, KeyId, State)
    local RedDotKey, RedDotSuffix = self:ChangeSysIdToPrefixKey(SysId, KeyId)
    if RedDotKey and RedDotKey ~= "" and RedDotSuffix then
        if State then
            self:AddRedDot(RedDotKey, RedDotSuffix, SysId, KeyId)
        else
            self:InteractCallBack(RedDotKey, RedDotSuffix)
        end
    end
end

---红点交互回调，根据配置触发特定的交互逻辑
---@param RedDotKey string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param RedDotSuffix string|number  红点尾缀，例如 TabHero_200010000 中的 200010000
function RedDotModel:InteractCallBack(RedDotKey, RedDotSuffix)
    CLog("[cw] RedDotModel:InteractCallBack(" .. string.format("%s, %s", RedDotKey, RedDotSuffix) .. ")")
    --0.无节点不处理
    local wholeKey = self:ContactKey(RedDotKey, RedDotSuffix)
    ---@type RedDotNode
    local RedDotNode = self:GetNodeWithKey(wholeKey)
    if not RedDotNode then return end

    local InteractiveTypeEnum = self:RedDotInteractiveTypeCfg_GetRedDotinteractiveTypeEnum_ByRedDotHierarchyCfgKey(RedDotKey)

    --1.不做任何处理
    CLog("[cw] wholeKey: " .. tostring(wholeKey) .. " InteractiveTypeEnum: " .. tostring(InteractiveTypeEnum))
    if self:IsEnumRedDotInteractive_NoAction(InteractiveTypeEnum) then
        --do nothing
        CLog("[cw] " .. tostring(wholeKey) .. " is interactived, but no change")

    --2.清除自身及孩子节点
    elseif self:IsEnumRedDotInteractive_ClearSelfAndChildren(InteractiveTypeEnum) then
        self:RemoveRedDot(RedDotKey, RedDotSuffix, RedDotNode.ServerSysId)
        CLog("[cw] " .. tostring(wholeKey) .. " and its children has been removed")
        self:_Debug_PrintRedDotTree()
    --奇奇怪怪的点，需要报错查一下
    else
        CError("[cw] Tring to interactive with a RedDot(" .. tostring(wholeKey) .. ") which interactive type is illegal")
        CError(debug.traceback())
        self:_Debug_PrintRedDotTree()
    end
end

---获取服务器下发的数字红点的数字
---@param RedDotKey string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param RedDotSuffix string|number  红点尾缀，例如 TabHero_200010000 中的 200010000
function RedDotModel:GetRedDotDigitValue(RedDotKey, RedDotSuffix)
    local DigitValue = 0
    local WholeKey = self:ContactKey(RedDotKey, RedDotSuffix)
    if self.DigitRedDotMap[WholeKey] and self.DigitRedDotMap[WholeKey]["DigitValue"] then
        DigitValue = self.DigitRedDotMap[WholeKey]["DigitValue"]
    end
    return DigitValue
end

--region Debug 使用
-- lua.do local RedDotModel = MvcEntry:GetModel(RedDotModel); RedDotModel:_Debug_PrintRedDotTree();
local _indentCache = {}
function RedDotModel:_Debug_PrintRedDotTree()
    CLog("====== _Debug_PrintRedDotTree Start ======")
    local function _getIndent(indent) 
        if _indentCache[indent] then return _indentCache[indent] end

        local res = ""
        for i = 1, indent do
            res = res .. "    "
        end
        _indentCache[indent] = res
        return res
    end
    
    local function _innerPrint(indent, str, afterIndexStr)
        local pre = _getIndent(indent)
        if afterIndexStr then pre = pre .. tostring(afterIndexStr) end
        CLog(pre .. str)
    end
    
    ---@param node RedDotNode
    local function printTree(node, indent, afterIndexStr)
        --body
        _innerPrint(indent, tostring(afterIndexStr or "") .. tostring(node.Key) --[[.. "(" .. tostring(node) .. ")"--]] .." = {")
        
        --debug info
        _innerPrint(indent + 1, "RedDotCount: " .. tostring(node.RedDotCount))
    
        --parents
        if node.Parents and next(node.Parents) then
            local parentsStr, count = nil, 0
            for k, v in pairs(node.Parents) do
                if parentsStr then 
                    parentsStr = parentsStr .. ", " .. tostring(k) --[[ .. "(" .. tostring(tostring(v)) .. ")" --]] 
                else
                    parentsStr = tostring(k) --[[.. "[" .. tostring(tostring(v)) .. "]"--]]
                end
                count = count + 1
            end
            _innerPrint(indent + 1, "Parents(" .. tostring(count) .. ")" --[[ .. "(" .. tostring(node.Parents) .. ")" --]] .. " = [" .. tostring(parentsStr) .. "]")
        end
    
        --childs
        if node.Childs and next(node.Childs) then
            local index, count, childStr = 1, 0,nil
            for k, v in pairs(node.Childs) do 
                count = count + 1
                if childStr then
                    childStr = childStr .. ", " .. v.Key
                else
                    childStr = v.Key
                end
            end            
            _innerPrint(indent + 1, "Childs(" .. tostring(count) .. ")" --[[ .. "[" .. tostring(node.Childs) .. "]" --]] .."[" .. tostring(childStr) .. "] = {")
            for k, v in pairs(node.Childs) do
                printTree(v, indent + 2, "[" .. tostring(index) .. "] ")
                index = index + 1
            end
            _innerPrint(indent + 1, "}")
        end

        --tag
        local TagStr
        for tagKey, value in pairs(node.Tags) do
            if value then
                if not TagStr then
                    TagStr = tostring(tagKey)
                else
                    TagStr = TagStr .. ", " .. tostring(tagKey)
                end
            end
        end
        if TagStr then _innerPrint(indent + 1, "Tags = [" .. tostring(TagStr) .. "]") end
    
        _innerPrint(indent, "}")
    end

    for _, v in pairs(self.RedDotTree) do
        printTree(v, 0)        
    end
    CLog("====== _Debug_PrintRedDotTree End ======")
    --print_r(self.RedDotTree, "[cw] ====self.RedDotTree")
end
--endregion

--region 内部逻辑，不暴露
---内部生成一个红点节点
local function _CreateNode(key, suffix, serverSysId, serverKeyId, triggerTypeId)
    local RedDotNodeClass = require("Client.Modules.RedDot.RedDotNode")
    
    --这一部分使用了对象池
    ---[[
    local RedDotNode = PoolManager.CreateInstance(RedDotNodeClass, 1)[1]
    RedDotNode:InitData(key, suffix, serverSysId, serverKeyId, triggerTypeId)
    return RedDotNode
    --]]

    --这一部分没有使用对象池
    --[[
    ---@type RedDotNode
    local RedDotNode = RedDotNodeClass.New()
    RedDotNode:InitData(key, suffix)
    return RedDotNode
    --]]
end

local function _DeleteNode(RedDotNode)
    --这一部分使用了对象池
    ---[[
    PoolManager.Reclaim(RedDotNode)
    --]]
end 

---内部拼接完整key使用
local function _ContactKey(key, suffix)
    if not key then return "" end
    if not suffix then return key end
    return tostring(key) .. tostring(suffix)
end

---内部拼接自定义字符串 用于存储在服务器的CustomInfoMap
---@param key string 红点key 例如 TabHero_200010000 中的 TabHero_
---@param suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@return string 自定义字符串
local function _ContactCustomKey(key, suffix)
    if not key then return "" end
    if not suffix then return "" end
    local CustomKey = key .. ":" .. suffix
    return CustomKey
end

---拆分自定义字符串 获取对应的红点前缀跟后缀
---@param CustomKey string ---内部拼接自定义字符串
---@return string 红点key 红点尾缀
local function _SplitCustomKey(CustomKey)
    if not CustomKey then return "", "" end
    local CustomKeyArray = string.split(CustomKey, ":")
    local key = CustomKeyArray[1] or ""
    local suffix = CustomKeyArray[2] or ""
    return key, suffix
end

-- 通过物品ID判断红点归属
local function _CheckRedDotBelongByItemId(self, CheckConfigParam, ItemId)
    -- 是否属于此红点
    local IsBelong = false
    if CheckConfigParam then
        local CheckConfig = G_ConfigHelper:GetSingleItemByKey(CheckConfigParam.ConfigName, CheckConfigParam.ConfigValue, ItemId)
        if CheckConfig then
            IsBelong = true
            if CheckConfigParam.ExtraConfigParamList then
                -- 有额外参数需要判断
                for ConfigKey, ConfigValue in pairs(CheckConfigParam.ExtraConfigParamList) do
                    if CheckConfig[ConfigKey] and CheckConfig[ConfigKey] == ConfigValue then
                        -- not to do
                    else
                        IsBelong = false
                        break
                    end
                end
            end
        end
    end
    return IsBelong
end

-- 通过配置参数转换红点后缀
local function _ChangeRedDotSuffixKeyByConfigParam(self, ChangeSuffixKeyConfigParam, ItemId, KeyId)
    -- 红点后缀
    local SuffixKey = KeyId
    if ChangeSuffixKeyConfigParam then
        local SuffixConfig = G_ConfigHelper:GetSingleItemByKey(ChangeSuffixKeyConfigParam.ConfigName, ChangeSuffixKeyConfigParam.ConfigValue, ItemId)
        SuffixKey = SuffixConfig and tostring(SuffixConfig[ChangeSuffixKeyConfigParam.ConfigValueParam]) or ""
    end
    return SuffixKey
end

---将服务器提供的系统ID转换成对应的红点前缀跟后缀
---@param self RedDotModel
---@param SysId number 系统id
---@param KeyId number|string 对应系统的红点key
---@return string string 红点前缀、后缀
local function _ChangeSysIdToPrefixKey(self, SysId, KeyId)
    if not SysId then return "", "" end
    if not KeyId then return "", "" end
    local PrefixKey, SuffixKey = "", ""
    ---物品系统的需要做区分
    if SysId == Pb_Enum_RED_DOT_SYS.RED_DOT_ITEM then
        local DepotModel = MvcEntry:GetModel(DepotModel)
        local ItemVo = DepotModel:GetData(KeyId)
        if not ItemVo then CError("[hz] ItemVo is nil KeyId:" .. KeyId .. "is nil, please check") return "", "" end
        local ItemId = ItemVo.ItemId or 0
        for Key, Value in pairs(self.Const_ChangeItemRedDotConfigParam) do
            if Value then
                -- 需要检测的配置信息
                local CheckConfigParam = Value.CheckConfigParam
                -- 是否属于此红点
                local IsBelong = _CheckRedDotBelongByItemId(self, CheckConfigParam, ItemId)
                if IsBelong then
                    -- 红点前缀赋值
                    PrefixKey = Key
                    -- 如果需要转换红点后缀，需要传值
                    local ChangeSuffixKeyConfigParam = Value.ChangeSuffixKeyConfigParam
                    -- 红点后缀赋值
                    SuffixKey = _ChangeRedDotSuffixKeyByConfigParam(self, ChangeSuffixKeyConfigParam, ItemId, KeyId)
                    break
                end
            end
        end
    else
        -- 红点前缀赋值
        PrefixKey = self.Const_SysRedDotKey[SysId]
        -- 红点后缀赋值
        SuffixKey = KeyId
    end
    return PrefixKey, SuffixKey
end

---将红点框架中的红点前缀转换成对应的SysId
---@param self RedDotModel
---@param key string 红点key 例如 TabHero_200010000 中的 TabHero_
---@return number string 服务器定义的红点系统模块ID RedDot.RED_DOT_SYS
local function _ChangePrefixKeyToSysId(self, key, suffix)
    if not key or not suffix then return Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD end
    local SysId = Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD
    for Sys, PrefixKey in pairs(self.Const_SysRedDotKey) do
        if PrefixKey == key then
            SysId = Sys
            break;
        end
    end
    ---先检测其他类型 最后再检测RED_DOT_SYS.RED_DOT_ITEM类型的
    if SysId == Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD then
        for PrefixKey, Value in pairs(self.Const_ChangeItemRedDotConfigParam) do
            if PrefixKey == key then
                SysId = Pb_Enum_RED_DOT_SYS.RED_DOT_ITEM
                break;
            end
        end
    end
    return SysId
end   

---内部注册红点使用，local避免外部调用
---@param self RedDotModel
---@param Key string 红点key 例如 TabHero_200010000 中的 TabHero_
---@param Suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@param ServerSysId number 服务器定义的红点系统模块ID RedDot.RED_DOT_SYS
---@param ServerKeyId number 服务器定义的红点key
local function _InnerAddRedDot(self, Key, Suffix, ServerSysId, ServerKeyId)
    if not Key or Key == "" then return nil end

    Suffix = Suffix or ""

    --cache
    local WholeKey = _ContactKey(Key, Suffix)
    if self.RedDotMapKey2Node[WholeKey] then return self.RedDotMapKey2Node[WholeKey] end

    --根节点处理
    local ParentKeyAndSufList = self:RedDotHierarchyCfg_GetParentKeyAndSufList(Key, Suffix)
    local triggerTypeId = self:RedDotHierarchyCfg_GetRedDotTriggerTypeId(Key)
    --CLog("[cw] " .. tostring(key) .. tostring(suffix) .. "'s parent is " .. tostring(parentKey) .. tostring(parentSuffix))
    --如果父节点信息，说明这个是个根节点了
    if #ParentKeyAndSufList == 0 then
        if not self.RedDotTree[WholeKey] then
            local root = _CreateNode(WholeKey, "")
            self:DispatchType(RedDotModel.ON_REDDOT_ADDED, WholeKey)
            self.RedDotTree[WholeKey] = root
            self.RedDotMapKey2Node[WholeKey] = root
        end
        return self.RedDotTree[WholeKey]
    end

    --生成当前节点
    local RedDotNode = _CreateNode(Key, Suffix, ServerSysId, ServerKeyId, triggerTypeId)
    self:DispatchType(RedDotModel.ON_REDDOT_ADDED, WholeKey)
    self.RedDotMapKey2Node[WholeKey] = RedDotNode

    for _, ParentKeyAndSuf in ipairs(ParentKeyAndSufList) do
        local ParentKey = ParentKeyAndSuf.RedDotKey
        local ParentSuffix = ParentKeyAndSuf.RedDotSuffix
        --生成/获取父亲节点
        local ParentWholeKey = _ContactKey(ParentKey, ParentSuffix)
        local ParentNode = _InnerAddRedDot(self, ParentKey, ParentSuffix)
        
        --确认一下父子关系
        RedDotNode:UpdateRedDotParent(ParentWholeKey, ParentNode)
        ParentNode:UpdateRedDotChild(WholeKey, RedDotNode) 
    end
    
    return RedDotNode
end

-- 检测该节点是否打标记类型，是的话再删除红点的时候需要把服务器保存的tag信息删除
---@param self RedDotModel
---@param RedDotNode RedDotNode
local function _CheckIsTagRedDotNode(self, RedDotNode)
    if RedDotNode then
        local ContactCustomKey = _ContactCustomKey(RedDotNode.RedDotKey, RedDotNode.RedDotSuffix)
        if self.CustomInfoMap[ContactCustomKey] then
            ---@type RedDotCtrl
            local RedDotCtrl = MvcEntry:GetCtrl(RedDotCtrl)
            local CustomInfoMap = {
                [ContactCustomKey] = {
                    ["Tag"] = {}
                },
            }
            RedDotCtrl:SendPlayerSetRedDotInfoTagReq(CustomInfoMap, false)
        end
    end
end

---内部删除红点使用，local避免外部调用
---@param self RedDotModel
---@param RedDotNode RedDotNode
local function _InnerRemoveRedDotNode(self, RedDotNode)
    if not RedDotNode then CError("[cw] _InnerRemoveRedDotNode RedDotNode is nil, pelase check", true) return end
    local wholeKey = _ContactKey(RedDotNode.RedDotKey, RedDotNode.RedDotSuffix)
    
    --删除叶子节点
    if RedDotNode:IsLeaftNode() then
        --如果有父节点，断绝父子关系
        local bRoot = true
        for _, parentNode in pairs(RedDotNode.Parents) do
            parentNode:UpdateRedDotChild(wholeKey, nil)
            bRoot = false
        end

        --清除映射表
        self.RedDotMapKey2Node[wholeKey] = nil
        if bRoot then self.RedDotTree[RedDotNode.Key] = nil end
        _CheckIsTagRedDotNode(self,RedDotNode)
        _DeleteNode(RedDotNode)
        
        --抛出事件
        self:DispatchType(RedDotModel.ON_REDDOT_REMOVED, wholeKey)
        
    --删除中间节点
    else
        --先删除孩子
        for _, childNode in pairs(RedDotNode.Childs) do
            _InnerRemoveRedDotNode(self, childNode)
        end
        --再删除自己
        _InnerRemoveRedDotNode(self, RedDotNode)
    end
end

---内部删除红点使用，local避免外部调用
---@param self RedDotModel
---@param RedDotNode RedDotNode
---@param tag string 需要打上的标签
---@return boolean 是否成功添加tag
local function _InnerAddRedDotTag(self, RedDotNode, tag)
    if RedDotNode:IsLeaftNode() then
        if not RedDotNode:HasTag() then
            RedDotNode:AddTag(tag)
            self:DispatchType(RedDotModel.ON_REDDOT_TAG_ADDED, {
                RedDotKey = RedDotNode.RedDotKey,
                RedDotSuffix = RedDotNode.RedDotSuffix,
                Tag = tag
            })
            return true
        end
    else
        local allRes = false
        for _, child in pairs(RedDotNode.Childs) do
            local res = _InnerAddRedDotTag(self, child, tag)
            if res and not allRes then allRes = true end
        end
        return allRes
    end
end

---内部删除红点使用，local避免外部调用
---@param self RedDotModel
---@param RedDotNode RedDotNode
---@param tag string 需要删除的标签
local function _InnerRemoveRedDotTag(self, RedDotNode, tag)
    if RedDotNode:IsLeaftNode() then
        if RedDotNode:HasTag() then
            RedDotNode:RemoveTag(tag)
            self:DispatchType(RedDotModel.ON_REDDOT_TAG_REMOVED, {
                RedDotKey = RedDotNode.RedDotKey, 
                RedDotSuffix = RedDotNode.RedDotSuffix, 
                Tag = tag
            })
        end
    else
        for _, child in pairs(RedDotNode.Childs) do
            _InnerRemoveRedDotTag(self, child, tag)
        end
    end
end
--endregion

---更新叶子节点的红点数量变动，外部正常情况下不需要调用
---@param key string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@param change number 红点变动数量
function RedDotModel:_RefreshRedDotCount(key, suffix, change)
    local wholeKey = _ContactKey(key, suffix)
    local curNode = self.RedDotMapKey2Node[wholeKey]
    
    if not curNode then 
        CError("[cw] something wrong here")
        CError("[cw] key: " .. tostring(key))
        CError("[cw] suffix: " .. tostring(suffix))
        CError(debug.traceback())
        return 
    end
    
    curNode.RedDotCount = curNode.RedDotCount + change
    self:DispatchType(RedDotModel.ON_REDDOT_UPATED, wholeKey)
    
    local parents = curNode.Parents
    if curNode.RedDotCount == 0 then
        _InnerRemoveRedDotNode(self, curNode)
    end
    for _, parentNode in pairs(parents) do
        self:_RefreshRedDotCount(parentNode.RedDotKey, parentNode.RedDotSuffix, change)
    end
end

---@param key string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@return string 生成的完整的红点key，例如 TabHero_ 与 200010000 组合而成的 TabHero_200010000
function RedDotModel:ContactKey(key, suffix) return _ContactKey(key, suffix) end

---内部拼接自定义字符串 用于存储在服务器的CustomInfoMap
---@param key string 红点key 例如 TabHero_200010000 中的 TabHero_
---@param suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@return string 自定义字符串
function RedDotModel:ContactCustomKey(key, suffix) return _ContactCustomKey(key, suffix) end

---拆分自定义字符串 获取对应的红点前缀跟后缀
---@param CustomKey string ---内部拼接自定义字符串
---@return string 红点key 红点尾缀
function RedDotModel:SplitCustomKey(CustomKey) return _SplitCustomKey(CustomKey) end

---将服务器提供的系统ID转换成对应的红点前缀跟后缀
---@param SysId number 系统id
---@param KeyId number|string 对应系统的红点key
---@return string string 红点前缀、后缀
function RedDotModel:ChangeSysIdToPrefixKey(SysId, KeyId) return _ChangeSysIdToPrefixKey(self, SysId, KeyId) end

---将红点框架中的红点前缀转换成对应的服务器SysId
---@param key string 红点key 例如 TabHero_200010000 中的 TabHero_
---@param suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@return number 服务器定义的红点系统模块ID RedDot.RED_DOT_SYS
function RedDotModel:ChangePrefixKeyToSysId(key, suffix) return _ChangePrefixKeyToSysId(self, key, suffix) end

---@param ChildKey string 需要检查的子节点Key，例如 TabHero_200010000 中的 TabHero_
---@param ChildSuffix string|number 需要检查的子节点Key尾缀，例如 TabHero_200010000 中的 200010000
---@param ParentKey string 需要检查的父节点Key，例如 TabHero_200010000 中的 TabHero_
---@param ParentSuffix string|number 需要检查的父节点Key尾缀，例如 TabHero_200010000 中的 200010000
---@return boolean childKey_childSuffix 是否是 parentKey_parentSuffix 或其子节点
function RedDotModel:IsParentNode(ChildKey, ChildSuffix, ParentKey, ParentSuffix)
    if not ChildKey or not ParentKey then return false end
    
    ChildSuffix = ChildSuffix or ""
    ParentSuffix = ParentSuffix or ""

    local WholeChildKey = _ContactKey(ChildKey, ChildSuffix)
    local WholeParentKey = _ContactKey(ParentKey, ParentSuffix)

    self.ParentAndChildRelationshipMap[WholeChildKey] = self.ParentAndChildRelationshipMap[WholeChildKey] or {}
    if self.ParentAndChildRelationshipMap[WholeChildKey] and self.ParentAndChildRelationshipMap[WholeChildKey][WholeParentKey] ~= nil then
        return self.ParentAndChildRelationshipMap[WholeChildKey][WholeParentKey]
    end

    if ChildKey == ParentKey and ChildSuffix == ParentSuffix then
        self.ParentAndChildRelationshipMap[WholeChildKey][WholeParentKey] = true
        return true
    end
    
    local ParentKeyAndSufList = self:RedDotHierarchyCfg_GetParentKeyAndSufList(ChildKey, ChildSuffix)
    local IsBelong = false
    for _, ParentKeyAndSuf in ipairs(ParentKeyAndSufList) do
        local ChildsParentKey = ParentKeyAndSuf.RedDotKey
        local ChildsParentSuffix = ParentKeyAndSuf.RedDotSuffix
        local AloneWholeKey = _ContactKey(ChildsParentKey, ChildsParentSuffix)
        local AloneCheck = self:IsParentNode(ChildsParentKey, ChildsParentSuffix, ParentKey, ParentSuffix)
        if AloneCheck then
            IsBelong = true
            break
        end
    end
    self.ParentAndChildRelationshipMap[WholeChildKey][WholeParentKey] = IsBelong
    return IsBelong
end

---通过前后缀取得红点节点
---@param key string 红点key 例如 TabHero_200010000 中的 TabHero_
---@param suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@return RedDotNode| nil
function RedDotModel:GetNode(key, suffix)
    local wholeKey = _ContactKey(key, suffix)
    return self:GetNodeWithKey(wholeKey)
end

function RedDotModel:GetNodeWithKey(wholeKey)
    local node = self.RedDotMapKey2Node[wholeKey]
    return node
end

---通过前后缀移除一个红点
---@param key string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@param serverSysId number 服务器定义的红点系统模块ID RedDot.RED_DOT_SYS
function RedDotModel:RemoveRedDot(key, suffix, serverSysId)
    local wholeKey = _ContactKey(key, suffix)
    local node = self.RedDotMapKey2Node[wholeKey]    
    if not node then return end
        
    --非叶子节点，需要移除所有孩子
    --这一步做了之后，可以确保需要消除的node是叶子节点了
    local redDotNum = node.RedDotCount
    if not node:IsLeaftNode() then
        CLog("[cw] tring to remove a node(" .. tostring(wholeKey) .. ") witch is not a leaft node, be aware to the result")
        for _, childNode in pairs(node.Childs) do
            _InnerRemoveRedDotNode(self, childNode)
        end
    end
    
    --叶子节点直接移除，并且逐级减少上层节点的红点数量，为0后销毁
    self:_RefreshRedDotCount(key, suffix, redDotNum * -1)

    self:UpdateSysRedDotList(key, suffix, serverSysId, false)
end

---通过前后缀新增一个红点
---@param key string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@param serverSysId number 服务器定义的红点系统模块ID RedDot.RED_DOT_SYS
---@param serverKeyId number 服务器定义的红点key
function RedDotModel:AddRedDot(key, suffix, serverSysId, serverKeyId)
    local wholeKey = _ContactKey(key, suffix)
    if self.RedDotMapKey2Node[wholeKey] then
        CWaring("[cw] Tring to Regist a new RedDot(" .. tostring(wholeKey) .. "), which has same key with another RedDot in self.RedDotMapKey2Node, please check your logic", true)
        return
    end
    
    _InnerAddRedDot(self, key, suffix, serverSysId, serverKeyId)
    self:_RefreshRedDotCount(key, suffix, 1)

    self:UpdateSysRedDotList(key, suffix, serverSysId, true)
end

---获取到对应的红点节点，给这个节点底下的所有的叶子节点打上一个特定的标记
---@param wholeKey string 红点完整key，例如 TabHero_200010000
---@param tag string 需要打上的tag
---@return boolean 是否添加成功（如果有一个节点添加成功了，则视为有添加）
function RedDotModel:AddTagToLeaftNode(wholeKey, tag)
    local node = self.RedDotMapKey2Node[wholeKey]
    if not node then 
        CWaring("[cw] Tring to add a tag to a RedDot witch is not exist, your logic might be wrong, please check it.")
        return false
    end
    
    tag = tag or wholeKey
    local bAddRes = _InnerAddRedDotTag(self, node, tag)
    return bAddRes
end

---获取到对应的红点节点，给这个节点底下的所有的叶子节点打上一个特定的标记
---@param wholeKey string 红点完整key，例如 TabHero_200010000
---@param tag string 需要移除的tag
function RedDotModel:RemoveLeaftNodeTag(wholeKey, tag)
    local node = self.RedDotMapKey2Node[wholeKey]
    if not node then
        CWaring("[cw] Tring to remove a tag to a RedDot witch is not exist, your logic might be wrong, please check it.")
        return
    end

    tag = tag or wholeKey
    _InnerRemoveRedDotTag(self, node, tag)
end

---获取节点的红点数
---@param key string 红点key 例如 TabHero_200010000 中的 TabHero_
---@param suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
function RedDotModel:GetRedDotCount(key, suffix)
    local wholeKey = _ContactKey(key, suffix)
    local node = self.RedDotMapKey2Node[wholeKey]
    if not node then return 0 end
    
    return node.RedDotCount
end

---更新系统红点列表  
---@param Key string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param Suffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
---@param ServerSysId number 服务器定义的红点系统模块ID RedDot.RED_DOT_SYS
---@param IsAdd boolean 是否新增
function RedDotModel:UpdateSysRedDotList(Key, Suffix, ServerSysId, IsAdd)
    if ServerSysId and ServerSysId ~= Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD then
        self.SysRedDotList[ServerSysId] = self.SysRedDotList[ServerSysId] or {}
        if IsAdd then
            local Length = #self.SysRedDotList[ServerSysId]
            self.SysRedDotList[ServerSysId][Length + 1] = {
                RedDotKey = Key, 
                RedDotSuffix = Suffix,
            }
        else
            local DeleteIndex = nil
            for Index, RedDotData in ipairs(self.SysRedDotList[ServerSysId]) do
                if RedDotData.RedDotKey == Key and RedDotData.RedDotSuffix == Suffix then
                    DeleteIndex = Index
                    break
                end
            end
            if DeleteIndex then
                self.SysRedDotList[ServerSysId][DeleteIndex] = nil
            end
        end 
    end
end

---获取系统红点列表  
---@param ServerSysId number 服务器定义的红点系统模块ID RedDot.RED_DOT_SYS
---@return table 红点信息列表 
function RedDotModel:GetSysRedDotList(ServerSysId)
    local SysRedDotList = self.SysRedDotList[ServerSysId] or {}
    return SysRedDotList
end

---获取该红点的系统id列表
---@param RedDotKey string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param RedDotSuffix string|number  红点尾缀，例如 TabHero_200010000 中的 200010000
---@param IsCancelAllRedDot boolean 是否取消该系统的所有红点
function RedDotModel:GetAllCancelRedDotSysIdList(RedDotKey, RedDotSuffix, IsCancelAllRedDot)
    local CancelSysId = Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD
    local CancelRedDotList = {}
    local WholeKey = self:ContactKey(RedDotKey, RedDotSuffix)
    ---@type RedDotNode
    local RedDotNode = self:GetNodeWithKey(WholeKey)
    if RedDotNode then
        local ServerSysId = RedDotNode.ServerSysId
        local ServerKeyId = RedDotNode.ServerKeyId
        ---有系统id说明是服务器保存的叶子节点，直接走单个红点触发
        if ServerSysId ~= Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD then
            CancelSysId = IsCancelAllRedDot and ServerSysId or Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD
            CancelRedDotList[#CancelRedDotList + 1] = {
                SysId = ServerSysId,
                KeyId = ServerKeyId
            }
        else 
            ---根节点的情况 说明得获取所有子节点 然后触发红点消失逻辑
            local AllChildRedDotKeyInfoList = self:GetAllChildRedDotKeyInfoList(RedDotKey, RedDotSuffix)
            if AllChildRedDotKeyInfoList then
                ---去重列表 防止重复判断
                local DeduplicationKeyList = {}
                for _, ChildRedDotKeyInfo in ipairs(AllChildRedDotKeyInfoList) do
                    local WholeKey = ChildRedDotKeyInfo.RedDotKey .. "===" .. ChildRedDotKeyInfo.RedDotSuffix
                    if not DeduplicationKeyList[WholeKey] then
                        DeduplicationKeyList[WholeKey] = true
                        local WholeKey = self:ContactKey(ChildRedDotKeyInfo.RedDotKey, ChildRedDotKeyInfo.RedDotSuffix)
                        ---@type RedDotNode
                        local RedDotNode = self:GetNodeWithKey(WholeKey)
                        if RedDotNode and RedDotNode.ServerSysId ~= Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD then
                            CancelRedDotList[#CancelRedDotList + 1] = {
                                SysId = RedDotNode.ServerSysId,
                                KeyId = RedDotNode.ServerKeyId
                            }
                        end
                    end
                end
            end
        end
    end
    return CancelSysId, CancelRedDotList
end

---通过父节点的红点前后缀获取此节点的所有孩子节点前后缀信息  会递归添加所有子节点前后缀信息
---@param RedDotKey string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param RedDotSuffix string|number  红点尾缀，例如 TabHero_200010000 中的 200010000
---@return table --{{ RedDotKey = "", RedDotSuffix = ""}}
function RedDotModel:GetAllChildRedDotKeyInfoList(ParentRedDotKey, ParentRedDotSuffix)
    local AllChildRedDotKeyInfoList = {}
    local WholeKey = self:ContactKey(ParentRedDotKey, ParentRedDotSuffix)
    ---@type RedDotNode
    local RedDotNode = self:GetNodeWithKey(WholeKey)
    if RedDotNode and RedDotNode.Childs then
        for _, Child in pairs(RedDotNode.Childs) do
            AllChildRedDotKeyInfoList[#AllChildRedDotKeyInfoList + 1] = {
                RedDotKey = Child.RedDotKey,
                RedDotSuffix = Child.RedDotSuffix
            }
        end
        for _, ChildRedDotKeyInfo in ipairs(AllChildRedDotKeyInfoList) do
            local RedDotKeyInfoList = self:GetAllChildRedDotKeyInfoList(ChildRedDotKeyInfo.RedDotKey, ChildRedDotKeyInfo.RedDotSuffix)
            table.listmerge(AllChildRedDotKeyInfoList, RedDotKeyInfoList)
        end
    end
    return AllChildRedDotKeyInfoList
end

---通过父节点的红点前后缀获取此节点的所有孩子节点完整红点key  会递归添加所有子节点
---@param RedDotKey string 红点key，例如 TabHero_200010000 中的 TabHero_
---@param RedDotSuffix string|number  红点尾缀，例如 TabHero_200010000 中的 200010000
---@return string[] 返回子节点的完整红点key列表
function RedDotModel:GetAllChildRedDotKeyList(ParentRedDotKey, ParentRedDotSuffix)
    local AllChildRedDotKeyList = {}
    local AllChildRedDotKeyInfoList = self:GetAllChildRedDotKeyInfoList(ParentRedDotKey, ParentRedDotSuffix)
    for _, RedDotKeyInfo in pairs(AllChildRedDotKeyInfoList) do
        local WholeKey = self:ContactKey(RedDotKeyInfo.RedDotKey, RedDotKeyInfo.RedDotSuffix)
        AllChildRedDotKeyList[#AllChildRedDotKeyList + 1] = WholeKey
    end
    return AllChildRedDotKeyList
end


--region 读表相关逻辑
--todo: 这一块读表太多了，可以考虑单独起一个文件来处理
---------------
--- 红点层级 ---
---------------
--region 红点层级
---获取【RedDot.xlsx】中的【红点层级】页签数据中 key 对应的条目
---@param key string 例如 TabHeroSinItem_
---@return userdata 表格【RedDot.xlsx】中的【红点层级】页签数据中 key 对应的条目数据
function RedDotModel:RedDotHierarchyCfg_GetCfg(key)
    local cfg = G_ConfigHelper:GetSingleItemById(Cfg_RedDotHierarchyCfg, key) 
    if not cfg then
        CError("[cw] cannot find " .. tostring(key) .. "'s RedDotHierarchyCfg")
        CError(debug.traceback()) 
    end
    return cfg
end

--region 红点层级
---获取【RedDot.xlsx】中的【红点层级】页签数据全表
---@param key string 例如 TabHeroSinItem_
---@return userdata 表格【RedDot.xlsx】中的【红点层级】页签数据中 key 对应的条目数据
function RedDotModel:RedDotHierarchyCfg_GetCfgDict()
    local cfg = G_ConfigHelper:GetDict(Cfg_RedDotHierarchyCfg) 
    if not cfg then
        CError("[cw] cannot find RedDotHierarchyCfg Dict")
        CError(debug.traceback()) 
    end
    return cfg
end

---获取到父节点的key与尾缀
---例如传入 TabHeroSinItem_,200010001 会获得 TabHeroSin_, 200010001
---@param ChildKey string 子节点key，例如 TabHeroSinItem_
---@param ChildSuffix string|number 子节点key尾缀
---@return table  {{ RedDotKey = 父节点key, RedDotSuffix = 父节点尾缀  }}父节点key, 父节点尾缀
function RedDotModel:RedDotHierarchyCfg_GetParentKeyAndSufList(ChildKey, ChildSuffix)
    local ParentKeyAndSufList = {}
    local ChildCfg = self:RedDotHierarchyCfg_GetCfg(ChildKey)
    if not ChildCfg then return ParentKeyAndSufList end

    local ParentKey = ChildCfg[Cfg_RedDotHierarchyCfg_P.ParentKey]
    if not ParentKey or ParentKey == "" then return ParentKeyAndSufList end

    --使用尾缀
    if ChildCfg[Cfg_RedDotHierarchyCfg_P.UseSuffix] then
        --父节点尾缀复用子节点尾缀
        if ChildCfg[Cfg_RedDotHierarchyCfg_P.ParentReuseSuffix] then
            ParentKeyAndSufList[#ParentKeyAndSufList + 1] = {
                RedDotKey = ParentKey,
                RedDotSuffix = ChildSuffix
            }
        --父节点尾缀不复用子节点尾缀，读表读取父节点尾缀
        else
            if ChildKey == RedDotModel.Const_SysRedDotKey[Pb_Enum_RED_DOT_SYS.RED_DOT_ACTIVITY_SUBITEM] then
                local ParentSuffix
                ---@type ActivitySubData
                local AcData = MvcEntry:GetModel(ActivitySubModel):GetData(tonumber(ChildSuffix))
                if AcData then
                    ParentSuffix = AcData.BelongAcId
                    -- CError(string.format("RedDotModel:RedDotHierarchyCfg_GetParentKeyAndSufList Succed !!! childKey=[%s],childSuffix=[%s],parentSuffix=[%s]",childKey,childSuffix,parentSuffix))
                else
                    CError(string.format("RedDotModel:RedDotHierarchyCfg_GetParentKeyAndSufList Faided !!! ChildKey=[%s], childSuffix=[%s]", ChildKey, ChildSuffix))
                    ParentSuffix = ChildSuffix
                end
                ParentKeyAndSufList[#ParentKeyAndSufList + 1] = {
                    RedDotKey = ParentKey,
                    RedDotSuffix = ParentSuffix
                }
            elseif ChildKey == "HeroDisplayBoardFloorItem_" or ChildKey == "HeroDisplayBoardRoleItem_" or ChildKey == "HeroDisplayBoardEffectItem_" or ChildKey == "HeroDisplayBoardStickerItem_" then
                --英雄绘板的需要单独处理
                local ConfigParam = RedDotModel.Const_ChangeItemRedDotConfigParam[ChildKey]
                if ConfigParam and ConfigParam.CheckConfigParam then
                    local ItemId = tonumber(ChildSuffix)
                    if ItemId  then
                        local CheckConfig = G_ConfigHelper:GetSingleItemByKey(ConfigParam.CheckConfigParam.ConfigName, ConfigParam.CheckConfigParam.ConfigValue, ItemId) 
                        if CheckConfig then
                            local HeroId = CheckConfig[Cfg_HeroDisplayRole_P.HeroId]
                            if HeroId and HeroId > 0 then
                                ParentKeyAndSufList[#ParentKeyAndSufList + 1] = {
                                    RedDotKey = ParentKey,
                                    RedDotSuffix = HeroId,
                                }
                            else
                                local ShowHeroCfgs = MvcEntry:GetModel(HeroModel):GetShowHeroCfgs()
                                if ShowHeroCfgs then
                                    for _, ShowHeroCfg in ipairs(ShowHeroCfgs) do
                                        ParentKeyAndSufList[#ParentKeyAndSufList + 1] = {
                                            RedDotKey = ParentKey,
                                            RedDotSuffix = ShowHeroCfg[Cfg_HeroConfig_P.Id]
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            else
                ParentKeyAndSufList = self:RedDotHierarchyCfg_GetParentKeyAndSufByConfig(ChildKey, ChildSuffix)
            end
        end
    --不使用尾缀
    else
        ParentKeyAndSufList[#ParentKeyAndSufList + 1] = {
            RedDotKey = ParentKey,
            RedDotSuffix = ""
        }
    end

    return ParentKeyAndSufList
end

---通过配置获取到父节点的key与尾缀
---例如传入 TabHeroSinItem_,200010001 会获得 TabHeroSin_, 200010001
---@param ChildKey string 子节点key，例如 TabHeroSinItem_
---@param ChildSuffix string|number 子节点key尾缀
---@return string, string 父节点key, 父节点尾缀
function RedDotModel:RedDotHierarchyCfg_GetParentKeyAndSufByConfig(ChildKey, ChildSuffix)
    local ParentKeyAndSufList = {}
    local ChildCfg = self:RedDotHierarchyCfg_GetCfg(ChildKey)
    if not ChildCfg then return ParentKeyAndSufList end

    local ParentKey = ChildCfg[Cfg_RedDotHierarchyCfg_P.ParentKey]
    local parentTableName = ChildCfg[Cfg_RedDotHierarchyCfg_P.ParentKeySearchTable]
    local parentTableField = ChildCfg[Cfg_RedDotHierarchyCfg_P.ParentKeySearchField]
    local parentTableFieldType = ChildCfg[Cfg_RedDotHierarchyCfg_P.ParentKeyType]
    if parentTableName and parentTableName ~= "" and parentTableField and parentTableField ~= "" and parentTableFieldType and parentTableFieldType ~= "" then
        local ParentSuffix
        local ParentSuffixCfgInfo 
        local ConfigParam = self:ChangeChildSuffixConfigParam(ChildKey, ChildSuffix)

        if parentTableFieldType == "string" then
            ParentSuffixCfgInfo = G_ConfigHelper:GetSingleItemById(parentTableName, tostring(ConfigParam), parentTableField)
        elseif parentTableFieldType == "number" then
            ParentSuffixCfgInfo = G_ConfigHelper:GetSingleItemById(parentTableName, tonumber(ConfigParam), parentTableField)
        end
        --取值有可能是table 
        if type(ParentSuffixCfgInfo) == "userdata" then
            for _, Value in pairs(ParentSuffixCfgInfo) do
                ParentKeyAndSufList[#ParentKeyAndSufList + 1] = {
                    RedDotKey = ParentKey,
                    RedDotSuffix = Value
                }
            end
        else 
            ParentKeyAndSufList[#ParentKeyAndSufList + 1] = {
                RedDotKey = ParentKey,
                RedDotSuffix = ParentSuffixCfgInfo
            }
        end
    end
    return ParentKeyAndSufList
end

-- 将红点后缀转换成配置参数 
function RedDotModel:ChangeChildSuffixConfigParam(ChildKey, ChildSuffix)
    local ConfigParam = ChildSuffix
    --- 特殊处理  有些红点key因为服务器是唯一ID 无法通过配置获取父节点的红点值  需要特殊转换一下
    if ChildKey == RedDotModel.Const_SysRedDotKey[Pb_Enum_RED_DOT_SYS.RED_DOT_MAIL] then
        local MailCtrl = MvcEntry:GetCtrl(MailCtrl)
        local MailInfo = MailCtrl:GetMailInfoByMailUniqId(ChildSuffix)
        ConfigParam = MailInfo and MailInfo.MailTemplateId or ChildSuffix 
    end
    return ConfigParam
end

---获取【RedDot.xlsx】中的【红点层级】页签数据中对应 key 的【红点显示规则】
---@param key string 例如 TabHeroSinItem_
---@return number 红点显示规则id
function RedDotModel:RedDotHierarchyCfg_GetRedDotDisplayRuleId(key)
    local RedDotHierarchyCfg = self:RedDotHierarchyCfg_GetCfg(key)
    if not RedDotHierarchyCfg then return end

    return RedDotHierarchyCfg[Cfg_RedDotHierarchyCfg_P.RedDotDisplayRuleId]
end

---获取【RedDot.xlsx】中的【红点层级】页签数据中对应 key 的【红点展示类型】
---@param key string 例如 TabHeroSinItem_
---@return number 红点展示类型id
function RedDotModel:RedDotHierarchyCfg_GetRedDotDisplayTypeId(key)
    local RedDotHierarchyCfg = self:RedDotHierarchyCfg_GetCfg(key)
    if not RedDotHierarchyCfg then return end

    return RedDotHierarchyCfg[Cfg_RedDotHierarchyCfg_P.RedDotDisplayTypeId]
end

---获取【RedDot.xlsx】中的【红点层级】页签数据中对应 key 的【红点交互类型】
---@param key string 节点key
---@return number 红点交互类型id
function RedDotModel:RedDotHierarchyCfg_GetRedDotInteractiveTypeId(key)
    local RedDotHierarchyCfg = self:RedDotHierarchyCfg_GetCfg(key)
    if not RedDotHierarchyCfg then return end

    local redDotType = RedDotHierarchyCfg[Cfg_RedDotHierarchyCfg_P.RedDotInteractiveTypeId]
    return redDotType
end

---获取【RedDot.xlsx】中的【红点层级】页签数据中对应 key 的【红点触发操作类型】
---@param key string 节点key
---@return number 红点触发操作类型id
function RedDotModel:RedDotHierarchyCfg_GetRedDotTriggerTypeId(key)
    local RedDotHierarchyCfg = self:RedDotHierarchyCfg_GetCfg(key)
    if not RedDotHierarchyCfg then return end

    local TriggerType = RedDotHierarchyCfg[Cfg_RedDotHierarchyCfg_P.RedDotTriggerTypeId] or RedDotModel.Enum_RedDotTriggerType.Click
    return TriggerType
end
--endregion 红点层级

------------------
--- 红点显示规则 ---
------------------
--region 红点显示规则
---获取【RedDot.xlsx】中的【红点显示规则】页签数据中 RedDotDisplayRuleId 对应的条目数据
---@param RedDotDisplayRuleId number 红点显示规则id
---@return userdata 表格【RedDot.xlsx】中的【红点显示规则】页签数据中 RedDotDisplayRuleId 对应的条目数据
function RedDotModel:RedDotDisplayRuleCfg_GetCfg(RedDotDisplayRuleId)
    local cfg = G_ConfigHelper:GetSingleItemById(Cfg_RedDotDisplayRuleCfg, RedDotDisplayRuleId)
    if not cfg then
        CError("[cw] cannot find " .. tostring(RedDotDisplayRuleId) .. "'s RedDotGenerateRuleCfg")
        CError(debug.traceback())
    end

    return cfg
end

---获取【RedDot.xlsx】中的【红点显示规则】页签数据中 RedDotDisplayRuleId 对应的【红点显示规则枚举】
---@param RedDotDisplayRuleId number 红点显示规则id
---@return string 红点显示规则枚举，参考 RedDotModel.Enum_RedDotDisplayRule
function RedDotModel:RedDotDisplayRuleCfg_GetRedDotDisplayRuleTypeEnum(RedDotDisplayRuleId)
    local RedDotDisplayRuleCfg = self:RedDotDisplayRuleCfg_GetCfg(RedDotDisplayRuleId)
    if not RedDotDisplayRuleCfg then return end

    local RedDotDisplayRuleTypeEnum = RedDotDisplayRuleCfg[Cfg_RedDotDisplayRuleCfg_P.RedDotDisplayRuleTypeEnum]
    return RedDotDisplayRuleTypeEnum
end

---@param key string 红点key，例如 TabHeroSinItem_
---@return string 红点显示规则枚举，参考 RedDotModel.Enum_RedDotDisplayRule
function RedDotModel:RedDotDisplayRuleCfg_GetRedDotDisplayRuleEnum_ByRedDotHierarchyCfgKey(key)
    local RedDotDisplayRuleId = self:RedDotHierarchyCfg_GetRedDotDisplayRuleId(key)
    if not RedDotDisplayRuleId then
        CError("[cw] RedDotGenerateRuleCfg_GetRedDotInteractiveEnum_ByRedDotHierarchyCfgKey cannot find " .. tostring(key) .. "'s RedDotDisplayRuleId")
        CError(debug.traceback())
        return 
    end

    local RedDotDisplayRuleTypeEnum = self:RedDotDisplayRuleCfg_GetRedDotDisplayRuleTypeEnum(RedDotDisplayRuleId)
    if not RedDotDisplayRuleTypeEnum then
        CError("[cw] RedDotGenerateRuleCfg_GetRedDotInteractiveEnum_ByRedDotHierarchyCfgKey cannot find " .. tostring(RedDotDisplayRuleTypeEnum) .. "'s cfg")
        CError(debug.traceback())
        return
    end
    
    return RedDotDisplayRuleTypeEnum
end

---@param RedDotDisplayRuleEnum string 参考 RedDotModel.Enum_RedDotDisplayRule
---@return boolean RedDotDisplayRuleEnum 是否为 【DoNotShow】
function RedDotModel:IsEnumRedDotDisplayRule_DoNotShow(RedDotDisplayRuleEnum)
    return RedDotDisplayRuleEnum == RedDotModel.Enum_RedDotDisplayRule.DoNotShow
end

---@param key string 例如 TabHeroSinItem_
---@return boolean key通过 【红点层级】与【红点显示规则】找到的红点显示类型枚举是否为 【DoNotShow】
function RedDotModel:IsEnumRedDotDisplayRule_DoNotShow_ByRedDotHierarchyCfgKey(key)
    local RedDotDisplayRuleEnum = self:RedDotDisplayRuleCfg_GetRedDotDisplayRuleEnum_ByRedDotHierarchyCfgKey(key)
    return self:IsEnumRedDotDisplayRule_DoNotShow(RedDotDisplayRuleEnum)
end

---@param RedDotDisplayRuleEnum string 参考 RedDotModel.Enum_RedDotDisplayRule
---@return boolean RedDotDisplayRuleEnum 是否为 【HasAnyChild】
function RedDotModel:IsEnumRedDotDisplayRule_HasAnyChild(RedDotDisplayRuleEnum)
    return RedDotDisplayRuleEnum == RedDotModel.Enum_RedDotDisplayRule.HasAnyChild
end

---@param key string 例如 TabHeroSinItem_
---@return boolean key通过 【红点层级】与【红点显示规则】找到的红点显示类型枚举是否为 【HasAnyChild】
function RedDotModel:IsEnumRedDotDisplayRule_IsHasAnyChild_ByRedDotHierarchyCfgKey(key)
    local RedDotDisplayRuleEnum = self:RedDotDisplayRuleCfg_GetRedDotDisplayRuleEnum_ByRedDotHierarchyCfgKey(key)
    return self:IsEnumRedDotDisplayRule_HasAnyChild(RedDotDisplayRuleEnum)
end

---@param RedDotDisplayRuleEnum string 参考 RedDotModel.Enum_RedDotDisplayRule
---@return boolean RedDotDisplayRuleEnum 是否为 【HasAnyChildNotContainTag】
function RedDotModel:IsEnumRedDotDisplayRule_HasAnyChildNotContainTag(RedDotDisplayRuleEnum)
    return RedDotDisplayRuleEnum == RedDotModel.Enum_RedDotDisplayRule.HasAnyChildNotContainTag
end

---@param key string 例如 TabHeroSinItem_
---@return boolean key通过 【红点层级】与【红点显示规则】找到的红点显示类型枚举是否为 【HasAnyChildNotContainTag】
function RedDotModel:IsEnumRedDotDisplayRule_IsHasAnyChildNotContainTag_ByRedDotHierarchyCfgKey(key)
    local RedDotDisplayRuleEnum = self:RedDotDisplayRuleCfg_GetRedDotDisplayRuleEnum_ByRedDotHierarchyCfgKey(key)
    return self:IsEnumRedDotDisplayRule_HasAnyChildNotContainTag(RedDotDisplayRuleEnum)
end

---@param RedDotDisplayRuleId number 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayRuleId
---@return string 参考【RedDot.xlsx】中的【红点显示规则】页签数据中 RedDotDisplayRuleId 对应的【String参数1】
function RedDotModel:RedDotDisplayRuleCfg_StringParam1(RedDotDisplayRuleId)
    local RedDotDisplayRuleCfg = self:RedDotDisplayRuleCfg_GetCfg(RedDotDisplayRuleId)
    if not RedDotDisplayRuleCfg then return end

    return RedDotDisplayRuleCfg[Cfg_RedDotDisplayRuleCfg_P.StringParam1]
end

--endregion 红点显示规则

------------------
--- 红点展示类型 ---
------------------
--region 红点展示类型
---获取【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId 对应的条目数据
---@param RedDotDisplayId number
function RedDotModel:RedDotDisplayTypeCfg_GetCfg(RedDotDisplayId)
    local cfg = G_ConfigHelper:GetSingleItemById(Cfg_RedDotDisplayTypeCfg, RedDotDisplayId)
    if not cfg then
        CError("[cw] cannot find " .. tostring(RedDotDisplayId) .. "'s RedDotDisplayTypeCfg")
        CError(debug.traceback())
    end

    return cfg
end

---获取【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId 对应的【红点展示类型枚举】
---@param RedDotDisplayId number 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId 对应的【红点展示类型枚举】
---@return string 红点展示类型枚举,参考 RedDotModel.Enum_RedDotDisplayType
function RedDotModel:RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum(RedDotDisplayId)
    local RedDotDisplayTypeCfg = self:RedDotDisplayTypeCfg_GetCfg(RedDotDisplayId)
    if not RedDotDisplayTypeCfg then return end

    local RedDotDisplayTypeEnum = RedDotDisplayTypeCfg[Cfg_RedDotDisplayTypeCfg_P.RedDotDisplayTypeEnum]
    return RedDotDisplayTypeEnum
end

---@param key string 例如 TabHeroSinItem_
---@return string 红点展示类型枚举,参考 RedDotModel.Enum_RedDotDisplayType
function RedDotModel:RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum_ByRedDotHierarchyCfgKey(key)
    local RedDotDisplayTypeId = self:RedDotHierarchyCfg_GetRedDotDisplayTypeId(key)
    if not RedDotDisplayTypeId then
        CError("[cw] RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum_ByRedDotHierarchyCfgKey cannot find " .. tostring(key) .. "'s RedDotDisplayTypeId")
        CError(debug.traceback())
        return
    end

    local RedDotDisplayRuleTypeEnum = self:RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum(RedDotDisplayTypeId)
    if not RedDotDisplayRuleTypeEnum then
        CError("[cw] RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum_ByRedDotHierarchyCfgKey cannot find " .. tostring(RedDotDisplayRuleTypeEnum) .. "'s cfg")
        CError(debug.traceback())
        return
    end

    return RedDotDisplayRuleTypeEnum
end

---@param RedDotDisplayTypeEnum string 参考 RedDotModel.Enum_RedDotDisplayType
---@return boolean key通过 【红点层级】与【红点展示类型】找到的红点显示类型枚举是否为 【Normal】
function RedDotModel:IsEnumRedDotDisplayType_Normal(RedDotDisplayTypeEnum)
    return RedDotDisplayTypeEnum == RedDotModel.Enum_RedDotDisplayType.Normal
end

---@param key string 例如 TabHeroSinItem_
---@return boolean key通过 【红点层级】与【红点展示类型】找到的红点显示类型枚举是否为 【Normal】
function RedDotModel:IsEnumRedDotDisplayType_Normal_ByRedDotHierarchyCfgKey(key)
    local RedDotDisplayTypeEnum = self:RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum_ByRedDotHierarchyCfgKey(key)
    return self:IsEnumRedDotDisplayType_Normal(RedDotDisplayTypeEnum)
end

---@param RedDotDisplayTypeEnum string 参考 RedDotModel.Enum_RedDotDisplayType
---@return boolean key通过 【红点层级】与【红点展示类型】找到的红点显示类型枚举是否为 【Number】
function RedDotModel:IsEnumRedDotDisplayType_Number(RedDotDisplayTypeEnum)
    return RedDotDisplayTypeEnum == RedDotModel.Enum_RedDotDisplayType.Number
end

---@param key string 例如 TabHeroSinItem_
---@return boolean key通过 【红点层级】与【红点展示类型】找到的红点显示类型枚举是否为 【Number】
function RedDotModel:IsEnumRedDotDisplayType_Number_ByRedDotHierarchyCfgKey(key)
    local RedDotDisplayTypeEnum = self:RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum_ByRedDotHierarchyCfgKey(key)
    return self:IsEnumRedDotDisplayType_Number(RedDotDisplayTypeEnum)
end

---@param RedDotDisplayTypeEnum string 参考 RedDotModel.Enum_RedDotDisplayType
---@return boolean key通过 【红点层级】与【红点展示类型】找到的红点显示类型枚举是否为 【Text】
function RedDotModel:IsEnumRedDotDisplayType_Text(RedDotDisplayTypeEnum)
    return RedDotDisplayTypeEnum == RedDotModel.Enum_RedDotDisplayType.Text
end

---@param key string 例如 TabHeroSinItem_
---@return boolean key通过 【红点层级】与【红点展示类型】找到的红点显示类型枚举是否为 【Text】
function RedDotModel:IsEnumRedDotDisplayType_Text_ByRedDotHierarchyCfgKey(key)
    local RedDotDisplayTypeEnum = self:RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum_ByRedDotHierarchyCfgKey(key)
    return self:IsEnumRedDotDisplayType_Text(RedDotDisplayTypeEnum)
end

---@param RedDotDisplayId number 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId
---@return string 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId 对应的【String参数1】
function RedDotModel:RedDotDisplayTypeCfg_StringParam1(RedDotDisplayId)
    local RedDotDisplayTypeCfg = self:RedDotDisplayTypeCfg_GetCfg(RedDotDisplayId)
    if not RedDotDisplayTypeCfg then return end
    
    return RedDotDisplayTypeCfg[Cfg_RedDotDisplayTypeCfg_P.StringParam1]
end

---@param RedDotDisplayId number 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId
---@return string 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId 对应的【String参数2】
function RedDotModel:RedDotDisplayTypeCfg_StringParam2(RedDotDisplayId)
    local RedDotDisplayTypeCfg = self:RedDotDisplayTypeCfg_GetCfg(RedDotDisplayId)
    if not RedDotDisplayTypeCfg then return end

    return RedDotDisplayTypeCfg[Cfg_RedDotDisplayTypeCfg_P.StringParam2]
end

---@param RedDotDisplayId number 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId
---@return string 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId 对应的【FText参数1】
function RedDotModel:RedDotDisplayTypeCfg_FTextParam1(RedDotDisplayId)
    local RedDotDisplayTypeCfg = self:RedDotDisplayTypeCfg_GetCfg(RedDotDisplayId)
    if not RedDotDisplayTypeCfg then return end

    return RedDotDisplayTypeCfg[Cfg_RedDotDisplayTypeCfg_P.FTextParam1]
end

---@param RedDotDisplayId number 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId
---@return string 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId 对应的【FText参数2】
function RedDotModel:RedDotDisplayTypeCfg_FTextParam2(RedDotDisplayId)
    local RedDotDisplayTypeCfg = self:RedDotDisplayTypeCfg_GetCfg(RedDotDisplayId)
    if not RedDotDisplayTypeCfg then return end

    return RedDotDisplayTypeCfg[Cfg_RedDotDisplayTypeCfg_P.FTextParam2]
end

---@param RedDotDisplayId number 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId
---@return string 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId 对应的【number参数1】
function RedDotModel:RedDotDisplayTypeCfg_NumParam1(RedDotDisplayId)
    local RedDotDisplayTypeCfg = self:RedDotDisplayTypeCfg_GetCfg(RedDotDisplayId)
    if not RedDotDisplayTypeCfg then return end

    return RedDotDisplayTypeCfg[Cfg_RedDotDisplayTypeCfg_P.NumParam1]
end

---@param RedDotDisplayId number 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId
---@return string 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotDisplayId 对应的【number参数2】
function RedDotModel:RedDotDisplayTypeCfg_NumParam2(RedDotDisplayId)
    local RedDotDisplayTypeCfg = self:RedDotDisplayTypeCfg_GetCfg(RedDotDisplayId)
    if not RedDotDisplayTypeCfg then return end

    return RedDotDisplayTypeCfg[Cfg_RedDotDisplayTypeCfg_P.NumParam2]
end

--endregion 红点展示类型

------------------
--- 红点交互类型 ---
------------------
--region 红点交互类型
---获取【RedDot.xlsx】中的【红点交互类型】页签数据中 RedDotInteractiveTypeId 对应的条目数据
function RedDotModel:RedDotInteractiveTypeCfg_GetCfg(RedDotInteractiveTypeId)
    local cfg = G_ConfigHelper:GetSingleItemById(Cfg_RedDotInteractiveTypeCfg, RedDotInteractiveTypeId)
    if not cfg then
        CError("[cw] cannot find " .. tostring(RedDotInteractiveTypeId) .. "'s RedDotInteractiveTypeCfg")
        CError(debug.traceback())
    end
    
    return cfg
end

---获取【RedDot.xlsx】中的【红点交互类型】页签数据中 RedDotInteractiveTypeId 对应【红点交互类型枚举】
---@param RedDotInteractiveTypeId number 参考【RedDot.xlsx】中的【红点交互类型】中的【红点交互类型id】
---@return string 参考 RedDotModel.Enum_RedDotInteractive
function RedDotModel:RedDotInteractiveTypeCfg_RedDotInteractiveTypeEnum(RedDotInteractiveTypeId)
    local RedDotInteractiveTypeCfg = self:RedDotInteractiveTypeCfg_GetCfg(RedDotInteractiveTypeId)
    if not RedDotInteractiveTypeCfg then return end

    return RedDotInteractiveTypeCfg[Cfg_RedDotInteractiveTypeCfg_P.RedDotInteractiveTypeEnum]
end

---@param key string 例如 TabHeroSinItem_
---@return string 参考 RedDotModel.Enum_RedDotInteractive
function RedDotModel:RedDotInteractiveTypeCfg_GetRedDotinteractiveTypeEnum_ByRedDotHierarchyCfgKey(key)
    local RedDotInteractiveTypeId = self:RedDotHierarchyCfg_GetRedDotInteractiveTypeId(key)
    if not RedDotInteractiveTypeId then
        CError("[cw] RedDotInteractiveTypeCfg_GetRedDotinteractiveTypeEnum_ByRedDotHierarchyCfgKey cannot find " .. tostring(key) .. "'s RedDotInteractiveTypeId")
        CError(debug.traceback())
        return
    end

    local RedDotInteractiveTypeEnum = self:RedDotInteractiveTypeCfg_RedDotInteractiveTypeEnum(RedDotInteractiveTypeId)
    if not RedDotInteractiveTypeEnum then
        CError("[cw] RedDotInteractiveTypeCfg_GetRedDotinteractiveTypeEnum_ByRedDotHierarchyCfgKey cannot find " .. tostring(RedDotInteractiveTypeEnum) .. "'s cfg")
        CError(debug.traceback())
        return
    end
    
    return RedDotInteractiveTypeEnum
end

---@param RedDotInteractiveTypeId number 参考【RedDot.xlsx】中的【红点交互类型】页签数据中 RedDotInteractiveTypeId
---@return string 参考【RedDot.xlsx】中的【红点展示类型】页签数据中 RedDotInteractiveTypeId 对应的【String参数1】
function RedDotModel:RedDotInteractiveTypeCfg_StringParam1(RedDotInteractiveTypeId)
    local RedDotInteractiveTypeCfg = self:RedDotInteractiveTypeCfg_GetCfg(RedDotInteractiveTypeId)
    if not RedDotInteractiveTypeCfg then return end

    return RedDotInteractiveTypeCfg[Cfg_RedDotInteractiveTypeCfg_P.StringParam1]    
end

---@param RedDotInteractiveTypeEnum string 参考 RedDotModel.Enum_RedDotInteractive
---@return boolean key通过 【红点层级】与【红点交互类型】找到的红点交互类型枚举是否为 【NoAction】
function RedDotModel:IsEnumRedDotInteractive_NoAction(RedDotInteractiveTypeEnum)
    return RedDotInteractiveTypeEnum == RedDotModel.Enum_RedDotInteractive.NoAction
end

---@param key string 例如 TabHeroSinItem_
---@return boolean key通过 【红点层级】与【红点交互类型】找到的红点交互类型枚举是否为 【NoAction】
function RedDotModel:IsEnumRedDotInteractive_NoAction_ByRedDotHierarchyCfgKey(key)
    local RedDotInteractiveTypeEnum = self:RedDotInteractiveTypeCfg_RedDotInteractiveTypeEnum(key)
    return self:IsEnumRedDotInteractive_NoAction(RedDotInteractiveTypeEnum)
end

---@param RedDotInteractiveTypeEnum string 参考 RedDotModel.Enum_RedDotInteractive
---@return boolean key通过 【红点层级】与【红点交互类型】找到的红点交互类型枚举是否为 【ClearSelfAndChildren】
function RedDotModel:IsEnumRedDotInteractive_ClearSelfAndChildren(RedDotInteractiveTypeEnum)
    return RedDotInteractiveTypeEnum == RedDotModel.Enum_RedDotInteractive.ClearSelfAndChildren
end

---@param key string 例如 TabHeroSinItem_
---@return boolean key通过 【红点层级】与【红点交互类型】找到的红点交互类型枚举是否为 【ClearSelfAndChildren】
function RedDotModel:IsEnumRedDotInteractive_ClearSelfAndChildren_ByRedDotHierarchyCfgKey(key)
    local RedDotInteractiveTypeEnum = self:RedDotInteractiveTypeCfg_RedDotInteractiveTypeEnum(key)
    return self:IsEnumRedDotInteractive_ClearSelfAndChildren(RedDotInteractiveTypeEnum)
end

---@param RedDotInteractiveTypeEnum string 参考 RedDotModel.Enum_RedDotInteractive
---@return boolean key通过 【红点层级】与【红点交互类型】找到的红点交互类型枚举是否为 【AddTagForChildren】
function RedDotModel:IsEnumRedDotInteractive_AddTagForChildren(RedDotInteractiveTypeEnum)
    return RedDotInteractiveTypeEnum == RedDotModel.Enum_RedDotInteractive.AddTagForChildren
end

---@param key string 例如 TabHeroSinItem_
---@return boolean key通过 【红点层级】与【红点交互类型】找到的红点交互类型枚举是否为 【AddTagForChildren】
function RedDotModel:IsEnumRedDotInteractive_AddTagForChildren_ByRedDotHierarchyCfgKey(key)
    local RedDotInteractiveTypeEnum = self:RedDotInteractiveTypeCfg_RedDotInteractiveTypeEnum(key)
    return self:IsEnumRedDotInteractive_AddTagForChildren(RedDotInteractiveTypeEnum)
end
--endregion 红点交互类型

--endregion 读表

return RedDotModel