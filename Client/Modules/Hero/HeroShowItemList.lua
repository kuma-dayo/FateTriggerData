local class_name = "HeroShowItemList"
local HeroShowItemList = BaseClass(nil, class_name)

--- 初始化
function HeroShowItemList:OnInit()
    self.BindNodes = {}
    self.MsgList = {}
    self.Widget2Item = {}
end

--- 隐藏
function HeroShowItemList:OnHide()
    self.Widget2Item = nil
end

--- 设置数据
function HeroShowItemList:OnShow(Param)
    local CfgHeros = Param.CfgHeros
    if not CfgHeros then
        return
    end
    self.View.GUITextBlock_Type:SetText(StringUtil.Format(Param.Name))
    if Param.TypeIcon then
        CommonUtil.SetBrushFromSoftObjectPath(self.View.Img_Icon,Param.TypeIcon)
    end
    local WidgetClass =
        UE4.UClass.Load(
        CommonUtil.FixBlueprintPathWithC(
            "/Game/BluePrints/UMG/OutsideGame/Hero/WBP_HeroListBtn.WBP_HeroListBtn"
        )
    )
    for i, v in ipairs(CfgHeros) do
        local Widget = NewObject(WidgetClass, self.View)
        self.View.HeroList:AddChild(Widget)

        local param = {
            HeroId = v[Cfg_HeroConfig_P.Id],
            IsLastOne = i == #CfgHeros,
        }
        UIHandler.New(self, Widget, require("Client.Modules.Hero.HeroShowItem"), param)
    end
end

return HeroShowItemList
