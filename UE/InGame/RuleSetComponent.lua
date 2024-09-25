require "UnLua"
require("Common.Framework.Functions")

--@Class RuleSetComponent:UObject
local RuleSetComponent = Class()

function RuleSetComponent:Initialize()
    self.ruleScript = {}
end

function RuleSetComponent:InitLuaRuleScript()
    self.Overridden.InitLuaRuleScript(self)
    local RuleModuleName = self.RuleModuleName
    local ActionModuleName = self.ActionModuleName
    
    self.GameAction = NewObject(self.ActionModuleClass, self, nil, ActionModuleName)
    self.ruleScript = require(RuleModuleName)
    
    self.ruleScript.GameAction = self.GameAction
    
    --self.GameAction = NewObject()
    
    local States = self.ruleScript.States
    if not States or type(States) ~= "table" then
        print("[Rule Script] No pre-defined states")
        States = {}
    end

    for name, value in pairs(self.ruleScript) do
        if type(value) == "function" then
            local split_name = string.split(name, "_")
            if #split_name < 2 then
                goto continue
            end
            local state_name = split_name[1]
            local event_name = split_name[2]
            local MessageName = "GameMode.Rule." .. state_name .. "." .. event_name
            
            -- put loaded function in to self table
            self[name] = function(_,...) -- first parameter '_' is an user object, use captured 'self' instead
                --print("LUA RULE function wrapper checked")
                value(self.ruleScript, ...) -- self.ruleScript is the real 'self' for member function value
            end
            
            ListenObjectMessage(self, MessageName, self, self[name])
            --print("[Lua Rule] listen message: " .. MessageName .. " to ", self[name])
        end
        ::continue::
    end
    
end

function RuleSetComponent:GetInitialState()
    return self.ruleScript.InitialState
end

return RuleSetComponent