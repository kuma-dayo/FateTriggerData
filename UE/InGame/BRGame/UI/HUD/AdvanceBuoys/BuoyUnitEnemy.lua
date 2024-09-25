
local BuoyUnitEnemy = Class("Common.Framework.UserWidget")

function BuoyUnitEnemy:OnInit()

	UserWidget.OnInit(self)
end

function BuoyUnitEnemy:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark(InTaskData)
	-- 设置玩家基础数据

	local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()

    BlackBoardKeySelector.SelectedKeyName = "HeroId"
    local HeroId, HeroIdType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt64(InTaskData.OtherData, BlackBoardKeySelector)

	local PawnConfig = nil
	local  bIsValidData = false
	PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(HeroId, PawnConfig, self)
	 if bIsValidData == true and PawnConfig then
		self.TxtName:SetText(PawnConfig.Name)
		print("BuoyUnitEnemy >> BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark HeroName:", PawnConfig.Name, GetObjectName(self))
	 end
end

function BuoyUnitEnemy:OnDestroy()
    print("BuoyUnitEnemy >> OnDestroy, ", GetObjectName(self))
	
    UserWidget.OnDestroy(self)
end

return BuoyUnitEnemy