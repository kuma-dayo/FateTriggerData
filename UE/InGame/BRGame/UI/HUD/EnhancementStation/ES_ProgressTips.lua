--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ES_ProgressTips = Class("Common.Framework.UserWidget")

local function GetInt(BlackBoard, Key)
    local Value,Result =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsIntSimple(BlackBoard,Key)
    return Value
end

local function GetName(BlackBoard, Key)
    local Value,Result =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsNameSimple(BlackBoard,Key)
    return Value
end

local function GetString(BlackBoard, Key)
    local Value,Result =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsStringSimple(BlackBoard,Key)
    return Value
end

local function GetEnum(BlackBoard, Key)
    local Value,Result =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsEnumSimple(BlackBoard,Key)
    return Value
end

local function GetFloat(BlackBoard, Key)
    local Value,Result =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsFloatSimple(BlackBoard,Key)
    return Value
end

local function GetBool(BlackBoard, Key)
    local Value,Result =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBoolSimple(BlackBoard,Key)
    return Value
end

local function GetObject(BlackBoard, Key)
    local Value,Result =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsObjectSimple(BlackBoard,Key)
    return Value
end


function ES_ProgressTips:OnInit()

	UserWidget.OnInit(self)
end


function ES_ProgressTips:OnShow(InContext, InGenericBlackboard)

end

function ES_ProgressTips:UpdateData(Owner, Count, BlackBoard)
end


function ES_ProgressTips:OnDestroy()
    UserWidget.OnDestroy()
end


return ES_ProgressTips
