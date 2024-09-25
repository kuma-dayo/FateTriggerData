require "UnLua"

local brRules = {} -- 定义并返回一个 lua table 给 C++ GameMode，该 table 就是此模式的 Rule Set

brRules.GameAction = {} --由加载此规则的GameMode填充


-- 必需成员 States: 包含本模式所有状态的名字，没有空格
brRules.States = { 
    "WarmUp",
    "InProgress",
    "EndProgress"
}

brRules.WarmUpTime = 10.0 -- 秒

-- 从哪个状态开始
brRules.InitialState = "WarmUp"

-- 命名规则： table:状态名_事件名[_.*]
-- 每个这样的函数会在事件系统中生成一个id为 GameMode.Rule.状态名.事件名 的事件
-- 
function brRules:WarmUp_Tick(deltaTime)
    self.time_remain = self.time_remain - deltaTime
    --print("Warm Remain " .. self.time_remain .. " s")
end

function brRules:InProgress_Tick(deltaTime)
    --print(" " .. deltaTime .. " s")
end

function brRules:WarmUp_StateBegin()
    print("Warm up state begin, total time" .. self.WarmUpTime)
    self.GameAction:SetTimer("cBeginInProgress", self.WarmUpTime) -- 事件名, 时间，自定义事件建议以小写字母开头来区分
    self.time_remain = self.WarmUpTime
end

function brRules:WarmUp_cBeginInProgress(time)
    print("Begin In Progress LUA RULE triggered ::: " .. time)
    self.GameAction:ChangeState("InProgress")
end

function brRules:WarmUp_StateEnd()
    
end

function brRules:InProgress_StateBegin()
    self.GameAction:BeginPlayzone();
    self.GameAction:SpawnPlayerBR(self.GameAction:GetAllPlayers());
end

function brRules:InProgress_PlayerDead(PlayerState)
    print("Player Dead " .. PlayerState.PlayerId)
    if self.GameAction:GetNumAlivePlayers() <= 1 then
        self.GameAction:ChangeState("EndProgress")
    end
end

function brRules:EndProgress_StateBegin()
    self.GameAction:SetTimer("cFinishGame", 15)
end

function brRules:EndProgress_cFinishGame()
    self.GameAction:EndGame()
end

return brRules