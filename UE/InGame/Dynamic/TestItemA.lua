require "UnLua"

local ItemA = Class()

function ItemA:Use()
    local ret = self.TestInt * 5
end

return ItemA