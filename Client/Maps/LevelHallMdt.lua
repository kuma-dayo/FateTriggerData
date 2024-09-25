--[[
    大厅关卡蓝图
]]
local class_name = "LevelHallMdt";
LevelHallMdt = LevelHallMdt or BaseClass(GameMediator, class_name);

function LevelHallMdt:__init()
end

function LevelHallMdt:OnShow(data)
	CLog("LevelHallMdt:OnShow")
	self:SpawnHallSceneManager()
end

function LevelHallMdt:OnHide()
	CLog("-----OnHide")
end

function LevelHallMdt:SpawnHallSceneManager()
	local CurWorld = _G.GameInstance:GetWorld()
    if CurWorld == nil then
		CLog("Not Found CurWorld")
        return 
    end

	local HallSceneMgrClass = UE.UClass.Load("/Game/BluePrints/Hall/BP_HallSceneMgr.BP_HallSceneMgr")
    if HallSceneMgrClass == nil then
		CError("Not Found HallSceneMgrClass")
        return
    end

	local SpawnLocation = UE.FVector(0, 0, 0)
    local SpawnRotation = UE.FRotator(0, 0, 0)
    local SpawnScale = UE.FVector(1, 1, 1)
    local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnLocation, SpawnRotation, SpawnScale)
    local HallSceneManager = CurWorld:SpawnActor(HallSceneMgrClass, 
            SpawnTrans, 
            UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
	if HallSceneManager == nil then 
		CError("Create HallSceneManager Failed")
		return
	end
	--CLog("Create HallSceneManager OK")
end

-----------------------------------------------

local M = Class()

function M:OnShow(data)
end


return M
