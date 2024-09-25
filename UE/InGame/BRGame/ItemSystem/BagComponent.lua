
require "UnLua"

require ("InGame.BRGame.GameDefine")
require ("InGame.BRGame.ItemSystem.ItemSystemHelper")

local BagComponent = Class()

-- 输出背包日志
function BagComponent:PrintToString()
    print(">>> BagData: ", self.BagData.CurrentWeight, self.BagData.MaxWeightNum)
    print(">>> Bag Item was replace api. can't output current item info.")
end


function BagComponent:BPCanDiscardItem(InInventoryIdentity, DiscardNum, UsefulReason)
    local CanDiscardItemResult = self.Overridden.BPCanDiscardItem(self, InInventoryIdentity, DiscardNum, UsefulReason)
    if not CanDiscardItemResult then return false end
    
    if UsefulReason ~= "CharacterDied" then
        return self:IsOperationEnabled()
    end

    return true
end

function BagComponent:OnRepBagElements(PreviousBagData)
    self.Overridden.OnRepBagElements(self, PreviousBagData)

    if self.BagData.CurrentUsedSlotNum > PreviousBagData.CurrentUsedSlotNum or self.BagData.MaxSlotNum ~= PreviousBagData.MaxSlotNum then
        UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("BagSlotTips",2,UE.FGenericBlackboardContainer(),nil)
    end
end

return BagComponent