require "UnLua"

M = Class()

function M:BeginPlayzone()
    --self.GameMode
    print("Call begin play zone in LUA RULE")
    NotifyObjectMessage(nil, "GameMode.BR.BeginPlayzone")
end

--function M:SpawnPlayerBR()
--    
--end

return M