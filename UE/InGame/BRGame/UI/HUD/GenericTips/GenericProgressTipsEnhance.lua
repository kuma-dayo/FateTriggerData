

local ParentClassName = "InGame.BRGame.UI.HUD.GenericTips.GenericProgressTips"
local GenericProgressTips = require(ParentClassName)
local GenericProgressTipsEnhance = Class(ParentClassName)

function GenericProgressTipsEnhance:OnInit()
    --print("GenericProgressTipsEnhance:OnInit")
    GenericProgressTips.OnInit(self)
end


function GenericProgressTipsEnhance:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    GenericProgressTips.OnTipsInitialize(self,TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    --print("GenericProgressTipsEnhance:OnTipsInitialize")
    --开始解析黑板
    local BuffText = ""
    local BuffKey = UE.FGenericBlackboardKeySelector()
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPS)
    for k,v in pairs(HudDataCenter.HudNetDataCenterAsset.EnhanceSystemRules.NeedReadEnhanceNameArray) do 
        BuffKey.SelectedKeyName =v
        local OutText ,IsFind =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(TipGenricBlackboard,BuffKey)
        
        if IsFind == true then
            --找显示的内容
            local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(HudDataCenter.HudNetDataCenterAsset.EnhanceAttribute, v)
            if cfg then
                BuffText = BuffText .." "..cfg.EnhanceName
            end
                
        end
        print("GenericProgressTipsEnhance:OnTipsInitialize123",BuffText,v)
    end
    self.EnhancedName:SetText(BuffText)

    

end

return  GenericProgressTipsEnhance



