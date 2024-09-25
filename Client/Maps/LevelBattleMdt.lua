local class_name = "LevelBattleMdt";
---@class LevelBattleMdt : GameMediator
LevelBattleMdt = LevelBattleMdt or BaseClass(GameMediator, class_name);


function LevelBattleMdt:__init()
end

function LevelBattleMdt:OnShow(data)
	CLog("-----OnShow")
end

function LevelBattleMdt:OnHide()
	CLog("-----OnHide")
end