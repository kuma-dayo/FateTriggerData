--[[
    玩家统计数据模型
]]
local super = GameEventDispatcher;
local class_name = "PlayerStatModel";

PlayerStatModel = BaseClass(super, class_name);

function PlayerStatModel:__init()
    self:DataInit()
end

function PlayerStatModel:DataInit()
    self.StatType2MapValue = {}
end

--[[
    玩家登出时调用
]]
function PlayerStatModel:OnLogout(data)
    self:DataInit()
end

--[[
    message StatItem
    {
        map<string, int32>  Dict = 1;
    }

    // 同步所有统计数据
    message PlayerStatSyncData
    {
        map<int32, StatItem>   Data = 1;
    }
]]
function PlayerStatModel:PlayerStatSyncData_Func(Msg)
    for StatType,StatItem in pairs(Msg.Data) do
        self.StatType2MapValue[StatType] = self.StatType2MapValue[StatType] or {}

        for k,v in pairs(StatItem.Dict) do
            self.StatType2MapValue[StatType][k] = v
        end
    end
end

----------------------------------------------------供对外使用方法---------------------------------------
--[[
    获取指定StatType 及 指定FieldKeyList 下的值总和
    @param StatType 统计类型
    @param FieldKeyList  此类型下的分组Key列表，传空值表示取值此类型所有值总和
]]
function PlayerStatModel:GetValueWithStatTypeAndItemKey(StatType,FieldKeyList)
    if not self.StatType2MapValue[StatType] then
        return 0
    end
    local AllValue = 0
    local FieldKeyMap = nil
    if FieldKeyList and #FieldKeyList > 0 then
        FieldKeyMap = {}
        for k,v in ipairs(FieldKeyList) do
            FieldKeyMap[v] = 1
        end
    end
    for k,v in pairs(self.StatType2MapValue[StatType]) do
        if not FieldKeyMap or FieldKeyMap[k] then
            AllValue = AllValue + v
        end
    end
    return AllValue
end


return PlayerStatModel;