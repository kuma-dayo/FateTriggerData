---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 自建房右侧英雄列表物品
--- Created At: 2023/06/25 16:27
--- Created By: 朝文
---
--- 外部可调用接口
--- 1）CustomRoomDetailHeroListItemMdt:SetData(Param)
---     设置数据
--- 2）CustomRoomDetailHeroListItemMdt:UpdateView()
---     更新界面展示，包括头像及 已选中/未选中/队友选中 三种状态 
---     判断 已选中/未选中/队友选中 的逻辑，数据来源 CustomRoomDetailModel
---
---     当状态为 队友选中 时，如果当前自建房的模式不是复选模式，则点击无响应

local class_name = "CustomRoomDetailHeroListItemMdt"
---@class CustomRoomDetailHeroListItemMdt
local CustomRoomDetailHeroListItemMdt = BaseClass(nil, class_name)
local Enum_State = {
    UnSelect = 1,
    Select_BySelf = 2,
    Select_ByTeammate = 3,
}

function CustomRoomDetailHeroListItemMdt:OnInit()
    self.Data = nil
    self._State = Enum_State.UnSelect
    
    self.BindNodes =
    {
        { UDelegate =  self.View.BtnChooseHero.OnClicked,		Func = Bind(self, self.OnButtonClicked_ChooseHero) },
    }
end

function CustomRoomDetailHeroListItemMdt:OnShow(Param)
    self:UnSelect()
end

function CustomRoomDetailHeroListItemMdt:OnHide()
end

--[[
    Param = 200010000
--]]
function CustomRoomDetailHeroListItemMdt:SetData(Param)
    self.Data = Param
end

function CustomRoomDetailHeroListItemMdt:UpdateView()
    --更新头像
    ---@type HeroModel
    local HeroModel = MvcEntry:GetModel(HeroModel)
    local DefaultHeroSkin = HeroModel:GetDefaultSkinIdByHeroId(self.Data)
    if not DefaultHeroSkin then
        CError("[cw] Cannot get default skin of hero " .. tostring(self.Data) .. "")
        return    
    end
    
    local DefaultHeroSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin, Cfg_HeroSkin_P.SkinId, DefaultHeroSkin)  
    if not DefaultHeroSkinCfg then
        CError("[cw] Cannot find SkinCfg base on DefaultHeroSkin(" .. tostring(DefaultHeroSkinCfg) .. "of hero" .. tostring(self.Data) ..")")
    else
        CommonUtil.SetBrushFromSoftObjectPath(self.View.HeroHeadPic, DefaultHeroSkinCfg.HalfBodyBGPNGPath)
    end

    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local UserId = UserModel:GetPlayerId()

    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local SelecterInfo = CustomRoomDetailModel:GetHeroSelectByTeammate(self.Data)
    if not SelecterInfo then
        self:UnSelect()
    else
        if SelecterInfo.PlayerId == UserId then
            self:Select_BySelf()
        else
            self:Select_ByTeammate()
        end
    end
end

function CustomRoomDetailHeroListItemMdt:Select_BySelf()
    self._State = Enum_State.Select_BySelf

    self.View.HeroHeadPic:SetRenderOpacity(1)
    self.View.SelectLuckPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.IconSwitch:SetActiveWidgetIndex(0)
end

function CustomRoomDetailHeroListItemMdt:Select_ByTeammate()
    self._State = Enum_State.Select_ByTeammate

    self.View.HeroHeadPic:SetRenderOpacity(0.5)
    self.View.SelectLuckPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.IconSwitch:SetActiveWidgetIndex(2)
end

function CustomRoomDetailHeroListItemMdt:UnSelect()
    self._State = Enum_State.UnSelect
    
    self.View.HeroHeadPic:SetRenderOpacity(1)
    self.View.SelectLuckPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.IconSwitch:SetActiveWidgetIndex(1)
end

function CustomRoomDetailHeroListItemMdt:OnButtonClicked_ChooseHero()
    CLog("[cw][CustomRoomDetailHeroListItemMdt] OnButtonClicked_ChooseHero(" .. string.format("%s", self.Data) .. ")")
    if not self.Data then return end

    ---@type CustomRoomModel
    local CustomRoomModel = MvcEntry:GetModel(CustomRoomModel)

    ---@type CustomRoomDetailCtrl
    local CustomRoomDetailCtrl = MvcEntry:GetCtrl(CustomRoomDetailCtrl)
    
    --被自己选中
    if self._State == Enum_State.Select_BySelf then
        --do nothing
        
    --被队友选中
    elseif self._State == Enum_State.Select_ByTeammate then
        ---@type CustomRoomDetailModel
        local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
        local ModeKey = CustomRoomDetailModel:GetRoomInfo_ModeKey()
        ---@type MatchModeSelectModel
        local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
        local IsRepeatChoose = false
        --MatchModeSelectModel:GetModeEntryCfg_IsRepeatChoose(ModeKey)
        --多选模式
        if IsRepeatChoose then
            if CustomRoomModel:IsInEnteringBattle() then UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetail_Enterthebattleplease"))) return end
            
            CustomRoomDetailCtrl:SendSelectHeroReq(self.Data)
        --单选模式
        else
            local Param = { describe = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetail_ThecurrentProphethas")) }
            UIMessageBox.Show(Param)
        end
        
    --未被选中
    elseif self._State == Enum_State.UnSelect then
        if CustomRoomModel:IsInEnteringBattle() then UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetail_Enterthebattleplease"))) return end

        CustomRoomDetailCtrl:SendSelectHeroReq(self.Data)
    end 
end

return CustomRoomDetailHeroListItemMdt
