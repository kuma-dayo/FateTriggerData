--[[
    通用商品信息描述控件
]]

local class_name = "CommonDescription"
CommonDescription = CommonDescription or BaseClass(nil, class_name)

---@class CommonDescriptionParam
---@field ItemID number 商品ID
---@field HideBtnSearch boolean 是否隐藏搜索按钮，默认为false
---@field ShowHighLevelTag boolean 是否显示高级标志，默认为false
---@field HideDescription boolean 是否隐藏描述，默认为false
---@field HideLine boolean 是否隐藏线条，默认为false
---@field ShowFreeTagTag boolean 是否显示免费标志，默认为false
function CommonDescription:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.BtnSearch.OnClicked,				Func = Bind(self,self.OnBtnSearchBtnClick) },
	}
end

function CommonDescription:OnShow(Param)
    self:UpdateUI(Param)
end

function CommonDescription:OnHide()  
end

function CommonDescription:UpdateUI(Param)
    self:SetViewVisible(false)
    if not Param or not Param.ItemID then
		CWaring("CommonDescription Param is nil, Please Check!",true)
        return
    end
    self.Param = Param
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.Param.ItemID)
    if not CfgItem then
        CWaring("ItemID Can't find in Cfg_ItemConfig, Please Check!",true)
        return
    end
    self:SetViewVisible(true)
    --道具名称
    self.View.LbGoodName:SetText(StringUtil.Format(CfgItem[Cfg_ItemConfig_P.Name]))
    --搜索按钮
    self.View.SearchBtton:SetVisibility(self.Param.HideBtnSearch and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.selfHitTestInvisible)

    --描述
    self.View.LbGoodDes:SetVisibility(self.Param.HideDescription and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.selfHitTestInvisible)
    --是否隐藏线条
    if CommonUtil.IsValid(self.View.GUIImage_1) then
        self.View.GUIImage_1:SetVisibility(self.Param.HideLine and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.selfHitTestInvisible)    
    end
    
    --道具品质
    local Widgets = {
        QualityIcon = self.View.WBP_CommonQualityLevel.GUIImageQuality,
    }
    CommonUtil.SetQualityShow(self.Param.ItemID,Widgets)
    --道具所属关系
    ---@type CommonDescriptionLabelParam
    local NameStr = CommonUtil.GetOwnershipNameByItemID(self.Param.ItemID)
    local Param1 = {
        ShowIndex = 0,
        ShowText = NameStr,
    }
    if not self.DescriptionLabelCls1 then
        self.DescriptionLabelCls1 = UIHandler.New(self,self.View.WBP_Common_DescriptionLabel_1, require("Client.Modules.Common.CommonDescriptionLabel"),Param1).ViewInstance
    else
        self.DescriptionLabelCls1:UpdateUI(Param1)
    end
    --道具类型
    local CfgTypeName = G_ConfigHelper:GetSingleItemByKeys(Cfg_ItemTypeNameConfig, {Cfg_ItemTypeNameConfig_P.Type, Cfg_ItemTypeNameConfig_P.SubType}, {CfgItem[Cfg_ItemConfig_P.Type], CfgItem[Cfg_ItemConfig_P.SubType]})
    local Str = CfgTypeName ~= nil and CfgTypeName[Cfg_ItemTypeNameConfig_P.ShowName] or nil
    ---@type CommonDescriptionLabelParam
    local Param2 = {
        ShowIndex = 0,
        ShowText = Str,
    }
    if not self.DescriptionLabelCls2 then
        self.DescriptionLabelCls2 = UIHandler.New(self,self.View.WBP_Common_DescriptionLabel_2, require("Client.Modules.Common.CommonDescriptionLabel"),Param2).ViewInstance
    else
        self.DescriptionLabelCls2:UpdateUI(Param2)
    end
    --高级、免费标志
    if self.Param.ShowHighLevelTag or self.Param.ShowFreeTagTag then
        ---@type CommonDescriptionLabelParam
        local Param3 = {
            ShowIndex = self.Param.ShowFreeTagTag and 2 or 1,
        }
        if not self.DescriptionLabelCls3 then
            self.DescriptionLabelCls3 = UIHandler.New(self,self.View.WBP_Common_DescriptionLabel_3, require("Client.Modules.Common.CommonDescriptionLabel"),Param3).ViewInstance
        else
            self.DescriptionLabelCls3:UpdateUI(Param3)
        end
    else
        self.View.WBP_Common_DescriptionLabel_3:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    --描述标签
    self:UpdateTagPanel()
    --道具描述
    self.View.LbGoodDes:SetText(StringUtil.Format(CfgItem[Cfg_ItemConfig_P.Des]))
end

function CommonDescription:SetViewVisible(bVisible)
    self.View:SetVisibility(bVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function CommonDescription:UpdateTagPanel()
    self.View.WBP_ShopRecommend_Type:SetVisibility(UE.ESlateVisibility.Collapsed)
    ---TODO
end

function CommonDescription:OnBtnSearchBtnClick()
    ---TODO
end

return CommonDescription