local M = {}

local MAX_POOL_SIZE = 200
local pools = {}


function M.PreFetch(tag,count)
    if count <= 0 then
        return
    end
    if not tag then
        return
    end
    local pool = pools[tag]
    if not pool then
        pool = {}
        pools[tag] = pool
        pool.c = 0
        pool[0] = 0
    end
    if (pool[0] + count) > MAX_POOL_SIZE then
        error("[TablePool]PreFetch. count too large", 3)
        return
    end
    for i=1,count do
        local obj = {}

        local len = pool[0] + 1
        pool[len] = obj
        pool[0] = len
    end
end



function M.Fetch(tag)
    local pool = pools[tag]
    if not pool then
        pool = {}
        pools[tag] = pool
        pool.c = 0
        pool[0] = 0
    else
        local len = pool[0]
        if len > 0 then
            local obj = pool[len]
            pool[len] = nil
            pool[0] = len - 1
            return obj
        end
    end
    return {}
end


function M.Recycle(tag, obj, noclear)
    if not obj then
        error("[TablePool]Recycle. object empty", 2)
    end


    local pool = pools[tag]
    if not pool then
        pool = {}
        pools[tag] = pool
        pool.c = 0
        pool[0] = 0
    end

    do
        local cnt = pool.c + 1
        if cnt >= 20000 then
            print("[TablePool]Recycle. start a-new-round pool. <tag>=", tag)
            pool = {}
            pools[tag] = pool
            pool.c = 0
            pool[0] = 0
            return
        end
        pool.c = cnt
    end

    local len = pool[0] + 1
    if len > MAX_POOL_SIZE then
        -- discard it simply
        print("[TablePool]Recycle. full pool. <tag>=", tag)
        return
    end

    if not noclear then
        setmetatable(obj, nil)
        for k, _ in pairs(obj) do
            obj[k] = nil
        end
    end

    pool[len] = obj
    pool[0] = len
end

function M.RecycleTable(tag,obj)
    for k,v in pairs(obj) do
        if type(v) == 'table' then
            M.RecycleTable(tag,v)
        end
    end
    M.Recycle(tag,obj)
end


return M
