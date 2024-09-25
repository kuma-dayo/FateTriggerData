--[[
    通用的 WBP_Common_ItemDescription 控件 WBP_Common_ItemDescription
]]
require "UnLua"

local class_name = "CommonItemDescription"
---@class CommonItemDescription
CommonItemDescription = CommonItemDescription or BaseClass(UIHandlerViewBase, class_name)

---@class ItemDesParam
---@field ItemId number 
---@field DescType CommonItemDescription.DESC_TYPE
---@field bNameNeedQuality boolean 名字需要品质区分吗

---@class CommonItemDescription.DESC_TYPE 描述类型
CommonItemDescription.DESC_TYPE = {
    PROP = 1, -- 道具
    ACHIEVEMENT = 2, --成就
}

function CommonItemDescription:OnInit()
    
end

---@param Param ItemDesParam
function CommonItemDescription:OnShow(Param)
	if not Param then
		return
	end
    self:UpdateUI(Param)
end

---@param Param ItemDesParam
function CommonItemDescription:OnManualShow(Param)
    if not Param then
		return
	end
    self:UpdateUI(Param)
end

function CommonItemDescription:OnHide()
end

function CommonItemDescription:OnManualHide()
end

---@param Param ItemDesParam
function CommonItemDescription:UpdateUI(Param)
    if not Param then
		return
	end
    self.bNameNeedQuality = Param.bNameNeedQuality or false 

    Param.DescType = Param.DescType or CommonItemDescription.DESC_TYPE.PROP

    if Param.DescType == CommonItemDescription.DESC_TYPE.PROP then
        self:SetPropInfo(Param.ItemId)
    elseif Param.DescType == CommonItemDescription.DESC_TYPE.ACHIEVEMENT then
        self:SetAchievementInfo(Param.ItemId)
    end
end

---------------------------------------------------Prop >>

function CommonItemDescription:SetPropInfo(ItemId)
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
    if ItemCfg then
        -- Name
        self.View.GUITextBlock_Name:SetText(ItemCfg[Cfg_ItemConfig_P.Name])

        -- Des
        -- self.View.Text_Description:SetText(ItemCfg[Cfg_ItemConfig_P.DetailDes])
        self.View.Text_Description:SetText(ItemCfg[Cfg_ItemConfig_P.Des])

        -- if UE.UGFUnluaHelper.IsEditor() then
        --     self.View.Text_Description:SetText(ItemId)
        -- end

        -- 品质色
        local Widgets = { QualityIcon = self.View.Image_Quality }
        if self.bNameNeedQuality then
            Widgets.QualityText = self.View.GUITextBlock_Name
        end
        CommonUtil.SetQualityShow(ItemId, Widgets)
    else
        self.View.GUITextBlock_Name:SetText("")
        self.View.Text_Description:SetText("")

        local SlateColor = UE.FSlateColor()
        SlateColor.SpecifiedColor = UIHelper.LinearColor.White
        self.View.GUITextBlock_Name:SetColorAndOpacity(SlateColor)
    end
end

---------------------------------------------------Prop <<

---------------------------------------------------Achievement >>

function CommonItemDescription:SetAchievementInfo(AchievementId)
    ---@type AchievementData
    local AchData = MvcEntry:GetModel(AchievementModel):GetData(AchievementId)

    if AchData then
        -- Name
        self.View.GUITextBlock_Name:SetText(AchData:GetName())
        -- Des
        self.View.Text_Description:SetText(AchData:GetDesc())

        -- if UE.UGFUnluaHelper.IsEditor() then
        --     self.View.Text_Description:SetText(StringUtil.Format("{0}|{1}|{2}", tostring(AchData.TaskId), tostring(AchData.ID), AchData:GetName()))
        -- end

        -- 品质色
        local QualityId = AchData:GetQuality()
        local Widgets = { QualityIcon = self.View.Image_Quality }
        if self.bNameNeedQuality then
            Widgets.QualityText = self.View.GUITextBlock_Name
        end
        CommonUtil.SetQualityShowForQualityId(QualityId, Widgets)
    else
        self.View.GUITextBlock_Name:SetText("")
        self.View.Text_Description:SetText("")

        local SlateColor = UE.FSlateColor()
        SlateColor.SpecifiedColor = UIHelper.LinearColor.White
        self.View.GUITextBlock_Name:SetColorAndOpacity(SlateColor)
    end
end


---------------------------------------------------Achievement <<


return CommonItemDescription
