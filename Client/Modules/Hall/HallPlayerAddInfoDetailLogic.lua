--[[
    玩家加成信息详情展示
]]
local class_name = "HallPlayerAddInfoDetailLogic"
local HallPlayerAddInfoDetailLogic = BaseClass(nil, class_name)


function HallPlayerAddInfoDetailLogic:OnInit()
end

function HallPlayerAddInfoDetailLogic:OnShow()
end

function HallPlayerAddInfoDetailLogic:OnHide()
end

function HallPlayerAddInfoDetailLogic:UpdateView()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local ExpAddInfo = UserModel:GetPlayerExpAddInfo()
    self:UpdateAddInfoItem(self.View.WBP_Props_Buff_Exp,ExpAddInfo,"Lua_HallPlayerAddInfoDetailLogic_ExpAddTips")
    local GoldAddInfo = UserModel:GetPlayerGoldAddInfo()
    self:UpdateAddInfoItem(self.View.WBP_Props_Buff_Gold,GoldAddInfo,"Lua_HallPlayerAddInfoDetailLogic_GoldAddTips")
end

function HallPlayerAddInfoDetailLogic:UpdateAddInfoItem(Item,AddInfo,TipsStrTemp)
    if not Item then
        return
    end
    if AddInfo then
        local TipsStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Match",TipsStrTemp)
        Item.GUIText_AddValue:SetText(StringUtil.Format(TipsStr,AddInfo.AddValue/10))
        Item.GUIText_LeftCount:SetText(AddInfo.LeftCount)
        Item:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        Item:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


return HallPlayerAddInfoDetailLogic
