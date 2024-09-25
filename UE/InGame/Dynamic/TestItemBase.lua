require "UnLua"
require "InGame.Dynamic.DynamicLuaMgr"

local ItemBase = Class()

function ItemBase:Initialize(Initializer)

end

-- AActor BeginPlay Override
function ItemBase:ReceiveBeginPlay()
    self:BindDynamicLua()
end

-- AActor Destroy Override
function ItemBase:ReceiveDestroyed()
    self:UnBindDynamicLua()
    self:Destroy()
end

function ItemBase:DoFly()
    local DynamicLua = GetDynamicLuaInstance().GetDynamicLua(self.DynamicLua)
    if DynamicLua then
        DynamicLua.Use(self)
    end
end

function ItemBase:BindDynamicLua()
    local ObjectName = UE.UKismetSystemLibrary.GetObjectName(self)
    GetDynamicLuaInstance().LoadDynamicLua(ObjectName, self.DynamicLua)
end

function ItemBase:UnBindDynamicLua()
    local ObjectName = UE.UKismetSystemLibrary.GetObjectName(self)
    GetDynamicLuaInstance().UnLoadDynamicLua(ObjectName, self.DynamicLua)
end

return ItemBase