local super = GameEventDispatcher;
local class_name = "SoundModel";
---@class SoundModel : GameEventDispatcher
SoundModel = BaseClass(super, class_name);


function SoundModel:OnLogout(Param)
    self:LogicDataInit()
end

function SoundModel:__init()
    self:LogicDataInit()
end


function SoundModel:LogicDataInit()
    self.SoundEvent2CD = {}
end


--[[
    刷新SoundEvent事件的CD时间缀
    CD 为秒
]]
function SoundModel:RefreshSoundEventCD(EventName,CD)
    self.SoundEvent2CD[EventName] = GetTimestampMilliseconds() + CD*1000;
end

--[[
    判断当前SoundEvent事件是否在CD中
]]
function SoundModel:IsSoundEventInCD(EventName)
    local CTime = GetTimestampMilliseconds();
    local CDTime = self.SoundEvent2CD[EventName] or 0
    return (CDTime > CTime)
end

return SoundModel

