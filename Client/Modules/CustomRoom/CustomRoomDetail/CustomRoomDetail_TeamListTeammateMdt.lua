---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 自建房房间内，队伍列表中单个item中的单个队员item
--- Created At: 2023/06/13 15:17
--- Created By: 朝文
---

local class_name = "CustomRoomDetailTeamListTeammateMdt"
---@class CustomRoomDetailTeamListTeammateMdt
local CustomRoomDetailTeamListTeammateMdt = BaseClass(nil, class_name)

function CustomRoomDetailTeamListTeammateMdt:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.BtnSelectTeamPos.OnClicked,				Func = Bind(self,self.OnButtonClicked_SelectTeamPos) },
    }
end

function CustomRoomDetailTeamListTeammateMdt:OnShow(Param) end
function CustomRoomDetailTeamListTeammateMdt:OnHide() end

--[[
    Data = {
        "bAIPlayer" = false 
        "TeamId" = 1 
        "Name" = "百里奚2" 
        "HeroId" = 200010000 
        "PlayerId" = 251658244 
        "LobbyAddr" = "172.17.0.3" 
        "TeamPosition" = 1 
    }
--]]
function CustomRoomDetailTeamListTeammateMdt:SetData(Data)
    self.Data = Data
end

---更新名字及头像显示
function CustomRoomDetailTeamListTeammateMdt:UpdateView()
    --名字
    if self.Data and self.Data.Name then
        self.View.TxtPlayerName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.TxtPlayerName:SetText(self.Data.Name)
    else
        self.View.TxtPlayerName:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    --头像
    if self.Data and self.Data.HeroId then
        ---@type HeroModel
        local HeroModel = MvcEntry:GetModel(HeroModel)
        local DefaultSkinId = HeroModel:GetDefaultSkinIdByHeroId(self.Data.HeroId)
        local HeroSkinConfig = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin, Cfg_HeroSkin_P.SkinId, DefaultSkinId)
        if HeroSkinConfig then
            CommonUtil.SetBrushFromSoftObjectPath(self.View.HeroHeadPic, HeroSkinConfig.PNGPathAnomaly)
            self.View.HeroHeadPic:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    else
        self.View.HeroHeadPic:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---点击说明玩家需要切换到这个队伍
function CustomRoomDetailTeamListTeammateMdt:OnButtonClicked_SelectTeamPos()
    if not self.Data or not self.Data.TeamId then
        CError("[cw] Cannot change to a team which does not contain teamId")
        return
    end

    ---@type CustomRoomModel
    local CustomRoomModel = MvcEntry:GetModel(CustomRoomModel)
    if CustomRoomModel:IsInEnteringBattle() then UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomDetail_Enterthebattleplease"))) return end
    
    ---@type CustomRoomDetailModel
    local CustomRoomDetailModel = MvcEntry:GetModel(CustomRoomDetailModel)
    local TeamIndex = CustomRoomDetailModel:GetCustomRoomInfo_PlayerTeamIndex()

    if TeamIndex == self.Data.TeamId then
        CLog("[cw] player TeamId(" .. tostring(TeamIndex) .. ") is same with target TeamId(" .. tostring(self.Data.TeamId) .. "), do nothing")
        return
    end
    
    ---@type CustomRoomDetailCtrl
    local CustomRoomDetailCtrl = MvcEntry:GetCtrl(CustomRoomDetailCtrl)
    CustomRoomDetailCtrl:SendSelectTeamReq(self.Data.TeamId)
end

return CustomRoomDetailTeamListTeammateMdt
