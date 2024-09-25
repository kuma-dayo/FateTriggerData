local DirectionBuoysOrdinary = Class("Common.Framework.UserWidget")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

function DirectionBuoysOrdinary:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    print("DirectionBuoysOrdinary >> OnInit, ", GetObjectName(self))
	UserWidget.OnInit(self)
end

function DirectionBuoysOrdinary:GetLocalPCPawnLoc()
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)

	if (not LocalPCPawn) then 
        return nil
    end

    return LocalPCPawn:K2_GetActorLocation()
end

function DirectionBuoysOrdinary:BPNativeFunc_OnCustomUpdate(InTaskData)

    self.CurRefPS = InTaskData.Owner
   
    self.CurTeamPos = BattleUIHelper.GetTeamPos(self.CurRefPS)
	if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor then
        self:UpdateWidgetColor(AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos))
	end
end

-- 更新控件颜色
function DirectionBuoysOrdinary:UpdateWidgetColor(InNewLinearColor)
    if self.Image_Bg then

        self.NewSlateColor = InNewLinearColor
        self.Image_Bg:SetColorAndOpacity(self.NewSlateColor)
    end
	--print("BuoysMarkSysPointItem", ">> UpdateWidgetColor, ...", GetObjectName(self))
end


return DirectionBuoysOrdinary