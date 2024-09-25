---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 大逃杀历史战绩详细条目
--- Created At: 2023/08/14 17:27
--- Created By: 朝文
---

local class_name = "MatchHistoryDetail_SubPageItemBase"
---@class MatchHistoryDetail_SubPageItemBase
local MatchHistoryDetail_SubPageItemBase = BaseClass(nil, class_name)

function MatchHistoryDetail_SubPageItemBase:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.WBP_HistoryDetail_BrifeRecordItem_Base.GUIButton.OnClicked,     Func = Bind(self, self.OnButtonClicked) },
        { UDelegate = self.View.WBP_HistoryDetail_BrifeRecordItem_Base.GUIButton.OnHovered,     Func = Bind(self, self.OnButtonHovered) },    
        { UDelegate = self.View.WBP_HistoryDetail_BrifeRecordItem_Base.GUIButton.OnUnhovered,   Func = Bind(self, self.OnButtonUnhovered) },    
        { UDelegate = self.View.WBP_HistoryDetail_BrifeRecordItem_Base.GUIButton.OnPressed,     Func = Bind(self, self.OnButtonPressed) },    
        { UDelegate = self.View.WBP_HistoryDetail_BrifeRecordItem_Base.GUIButton.OnReleased,    Func = Bind(self, self.OnButtonReleased) }, 
    }
end

function MatchHistoryDetail_SubPageItemBase:OnShow(Param)
    local root = self.View.WBP_HistoryDetail_BrifeRecordItem_Base
    root.WidgetSwitcher_state:SetActiveWidgetIndex(0)
end

function MatchHistoryDetail_SubPageItemBase:OnHide() end

function MatchHistoryDetail_SubPageItemBase:SetData(Param)
    self.Data = Param
end

function MatchHistoryDetail_SubPageItemBase:UpdateView()
    --更新头像
    self:UpdateHeadIcon()
    --更新名字
    self:UpdatePlayerName()    

    --默认不选中，选中单独使用 Select 或 UnSelect 处理
    self.View.WBP_HistoryDetail_BrifeRecordItem_Base.BgMine:SetVisibility(UE.ESlateVisibility.Hidden)
    self:_UpdateTextColor(false)
    
    --TODO: 如果有其他需要更新的，再在后面加就行
end

--TODO: 重写，返回需要改变颜色的控件列表
---@return table
function MatchHistoryDetail_SubPageItemBase:GetAllNeedToChangeColorTextWidget()
    return {self.View.WBP_HistoryDetail_BrifeRecordItem_Base.PlayerName}
end

---更新头像
function MatchHistoryDetail_SubPageItemBase:UpdateHeadIcon()
    local Root = self.View.WBP_HistoryDetail_BrifeRecordItem_Base
    local Data = self.Data
    
    local HeroTypeId = Data.HeroTypeId
    local HeroSkinCfg = MvcEntry:GetModel(HeroModel):GetDefaultSkinCfgByHeroId(HeroTypeId)
    if HeroSkinCfg then
        --1.1.头像图标
        -- CommonUtil.SetBrushFromSoftObjectPath(Root.WBP_Head.GUIImage_Hero, HeroSkinCfg[Cfg_HeroSkin_P.PNGPathAnomaly])
        CommonUtil.SetMaterialTextureParamSoftObjectPath(Root.WBP_Head.GUIImage_Hero, "Target", HeroSkinCfg[Cfg_HeroSkin_P.PNGPathAnomaly])

        --1.2.位置信息
        Root.WBP_Head.Text_Num:SetText(Data.PosInTeam)

        --1.3.位置颜色
        local MiscSystem = UE.UMiscSystem.GetMiscSystem(GameInstance)
        local NewLinearColor = MiscSystem.TeamColors:FindRef(tostring(Data.PosInTeam))
        Root.WBP_Head.ImgBg:SetBrushTintColor(UIHelper.ToSlateColor_LC(NewLinearColor))
    else
        CError("[cw] cannot find icon base on the HeroTypeId(" .. tostring(HeroTypeId) .. ")")
    end
end

---更新玩家名字
function MatchHistoryDetail_SubPageItemBase:UpdatePlayerName()
    local Root = self.View.WBP_HistoryDetail_BrifeRecordItem_Base
    local Data = self.Data
    
    --2.设置名字   
    local PlayerName = Data.PlayerName or ""
    Root.PlayerName:SetText(PlayerName)
end

---封装一个调整颜色的函数，颜色都设置在蓝图里面了，需要调整的话去蓝图里面调整
---@param bIsSelect boolean 是否选中
function MatchHistoryDetail_SubPageItemBase:_UpdateTextColor(bIsSelect)
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = self.Data.PlayerId
    local IsSelf = PlayerId and tonumber(PlayerId) == UserModel:GetPlayerId()

    --1.选取对应颜色
    local TargetColor
    local Root = self.View.WBP_HistoryDetail_BrifeRecordItem_Base
    if bIsSelect then
        TargetColor = Root.SelectColor
    else
        TargetColor = IsSelf and Root.MyselfColor or Root.DefaultColor
    end

    if not TargetColor then
        CError("[cw] trying to set a illegal color to HallSettlementSubpageBattleItem")
        CError(debug.traceback())
        return
    end

    --2.设置颜色
    local List = self:GetAllNeedToChangeColorTextWidget()
    for _, TextWidget in pairs(List) do
        if TextWidget then TextWidget:SetColorAndOpacity(TargetColor) end
    end
end

function MatchHistoryDetail_SubPageItemBase:Select()
    self.View.WBP_HistoryDetail_BrifeRecordItem_Base.BgMine:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:_UpdateTextColor(true)
end

function MatchHistoryDetail_SubPageItemBase:UnSelect()
    self.View.WBP_HistoryDetail_BrifeRecordItem_Base.BgMine:SetVisibility(UE.ESlateVisibility.Hidden)
    self:_UpdateTextColor(false)
end

function MatchHistoryDetail_SubPageItemBase:OnButtonClicked()
    if self.Data and self.Data.clickCallback then
        print_r(self.Data, "[cw] self.Data")
        self.Data.clickCallback(self.Data)
    end
end

function MatchHistoryDetail_SubPageItemBase:OnButtonHovered()
    local root = self.View.WBP_HistoryDetail_BrifeRecordItem_Base
    root.WidgetSwitcher_state:SetActiveWidgetIndex(1)
end

function MatchHistoryDetail_SubPageItemBase:OnButtonUnhovered()
    local root = self.View.WBP_HistoryDetail_BrifeRecordItem_Base
    root.WidgetSwitcher_state:SetActiveWidgetIndex(0)
end

function MatchHistoryDetail_SubPageItemBase:OnButtonPressed()
    local root = self.View.WBP_HistoryDetail_BrifeRecordItem_Base
    root.WidgetSwitcher_state:SetActiveWidgetIndex(2)
end

function MatchHistoryDetail_SubPageItemBase:OnButtonReleased()
    local root = self.View.WBP_HistoryDetail_BrifeRecordItem_Base
    root.WidgetSwitcher_state:SetActiveWidgetIndex(0)
end

return MatchHistoryDetail_SubPageItemBase
