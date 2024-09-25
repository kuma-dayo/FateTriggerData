require "UnLua"

local EnhanceAttributeBar = Class("Common.Framework.UserWidget")

function EnhanceAttributeBar:UpdateEnhanceInfo(InEnhanceId)
    local TempGameplayTag = UE.FGameplayTag()
    TempGameplayTag.TagName = GameDefine.NTag.TABLE_EnhanceAttribute
    local TempEnhanceAttributeDT = UE.UTableManagerSubsystem.GetDataTableByTag(self, TempGameplayTag)
    if TempEnhanceAttributeDT then
        local StructInfoEnhanceAttr = UE.UDataTableFunctionLibrary.GetRowDataStructure(TempEnhanceAttributeDT, tostring(InEnhanceId))
        if StructInfoEnhanceAttr then

            local EnhanceID = StructInfoEnhanceAttr.EnhanceID
            -- 设置背景
            -- local EnhanceBgSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceBgSoft)
            self:SetImageAttributeBg(EnhanceID)
            
            self:SetImageAttributeIcon(EnhanceID)
            -- 更新图片
            local EnhanceIconSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceIconSoft)
            self:SetImageAttributePettern(EnhanceIconSoftPtr)

            -- 更新名字
            local TranslatedItemName = StringUtil.Format(StructInfoEnhanceAttr.EnhanceName)
            self:SetTxtAttributeName(TranslatedItemName)
        end
    end
end

function EnhanceAttributeBar:SetImageAttributeBg(EnhanceID)
    if EnhanceID~=0 then
        local Tex2D = self.EnhanceBgTypeTexMap:Find(EnhanceID)
        if self.Image_Bg and Tex2D then
            self.Image_Bg:SetBrushFromSoftTexture(Tex2D, false)
        end
    end
end

function EnhanceAttributeBar:SetImageAttributeIcon(EnhanceID)
    if EnhanceID~=0 then
        local Tex2D = self.EnhanceIconTypeTexMap:Find(EnhanceID)
        if self.Image_Icon_Pettern and Tex2D then
            self.Image_Icon_Pettern:SetBrushFromSoftTexture(Tex2D, false)
        end
    end
end

function EnhanceAttributeBar:SetImageAttributePettern(EnhanceIconSoftPtr)
    if EnhanceIconSoftPtr then
        if self.Image_Icon_Pettern then
            self.Image_Icon_Pettern:SetBrushFromSoftTexture(EnhanceIconSoftPtr, false)
        end
    end
end

function EnhanceAttributeBar:SetTxtAttributeName(InText)
    if InText then
        if self.Txt_AttributeName then
            self.Txt_AttributeName:SetText(InText)
        end
    end
end

return EnhanceAttributeBar
