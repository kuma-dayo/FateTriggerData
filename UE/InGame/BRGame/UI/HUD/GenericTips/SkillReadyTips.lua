local SkillReadyTips = Class("Common.Framework.UserWidget")

function SkillReadyTips:OnInit()
    print("SkillReadyTips>>OnInit")
    UserWidget.OnInit(self)
end

function SkillReadyTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PC then return end
    if PC.PlayerState then
        local CurrentHeroId = UE.UPlayerExSubsystem.Get(self):GetPlayerRuntimeHeroId(PC.PlayerState:GetPlayerId())
        self:ReadDataTable(CurrentHeroId)
    end
end

function SkillReadyTips:ReadDataTable(InHeroId)
    local HeroSkillCfgList = UE.UDataTableFunctionLibrary.GetDataTableRowNames(self.HeroSkillCfg)
    for i = 1, HeroSkillCfgList:Length() do
        local DataTableRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.HeroSkillCfg, HeroSkillCfgList:Get(i))
        local HeroId = DataTableRow.HeroId
        local SkillTag = DataTableRow.SkillGameTag
        if InHeroId == HeroId and SkillTag.TagName == "Skill.SkillTag.Ultimate" then
            local SkillName = StringUtil.Format(DataTableRow.SkillName)
            local TipsText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SkillReadyTips_UltimateSkill"), SkillName)
            self.TxtTips:SetText(TipsText)
            local SkillIconPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(DataTableRow.SkillIconSoft)
            if SkillIconPtr then self.ImgIcon:SetBrushFromSoftTexture(SkillIconPtr, true) end
            goto continue
        end
    end
    ::continue::
end

function SkillReadyTips:OnDestroy()
    UserWidget.OnDestroy(self)
end


return SkillReadyTips