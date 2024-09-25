local class_name = "HeroSkinSuitPartList"
local HeroSkinSuitPartList = BaseClass(nil, class_name)

function HeroSkinSuitPartList:OnInit()
    self.MsgList = {}
    self.BindNodes = {}
end

function HeroSkinSuitPartList:OnHide()
end

function HeroSkinSuitPartList:OnShow(inParam)
    self.PartType = inParam.PartType
    self.SuitId = inParam.SuitId
    self.CurSelectId = inParam.CurSelectId

    local CfgParts =
        G_ConfigHelper:GetMultiItemsByKeys(
        Cfg_HeroSkinPart,
        {Cfg_HeroSkinPart_P.PartType, Cfg_HeroSkinPart_P.SuitID},
        {self.PartType, self.SuitId}
    )
    if not CfgParts or #CfgParts < 1 then
        return
    end

    local WidgetClass =
        UE4.UClass.Load(
        CommonUtil.FixBlueprintPathWithC(
            "/Game/BluePrints/UMG/OutsideGame/Hero/WBP_HeroPartListBtn.WBP_HeroPartListBtn"
        )
    )
    for i, v in ipairs(CfgParts) do
        local Widget = NewObject(WidgetClass, self.View)
        self.View.WrapBox_PartList:AddChild(Widget)

        local param = {
            PartId = v[Cfg_HeroSkinPart_P.PartId],
            CurSelectId = self.CurSelectId
        }
        UIHandler.New(self, Widget, require("Client.Modules.Hero.Skin.HeroSkinSuitPartListItem"), param)
    end

    local CfgPartType =
        G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkinPartType, Cfg_HeroSkinPartType_P.PartType, self.PartType)
    if CfgPartType then
        self.View.GUITextBlock_PartName:SetText(StringUtil.FormatText(CfgPartType[Cfg_HeroSkinPartType_P.Name]))
    end
end

return HeroSkinSuitPartList
