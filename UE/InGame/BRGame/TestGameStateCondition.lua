require "UnLua"

local TestGameStateCondition = {}

function TestGameStateCondition:Pass(OwnerProxy)
    
    print("PassPassPassPass TestGameStateCondition:PassPassPass()")
    return false
end


return TestGameStateCondition