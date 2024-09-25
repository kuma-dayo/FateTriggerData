--[[
    用于 WBP_CommonPurchaseBtn 的逻辑类
    传值ItemId和具体的控件，进行自动取值展示
]]

local class_name = "CommonPurchaseBtn"
CommonPurchaseBtn = CommonPurchaseBtn or BaseClass(nil, class_name)

---@class CommonPurchaseBtnParam
---@field ItemId 道具图标
---@field ItemShowNum 道具数量（可选，有值：将会只显示对应数量  空值：会展示背包内的物品数量）
---@field CheckEnough 是否检查仓库物品足够 ItemShowNum非nil值时生效 （不足够时，数字会标红）
---@field IsSelect 是否选中态 默认为false 也可外部调用SetIsSelect改变

function CommonPurchaseBtn:OnInit()
    self.MsgList = 
    {
		{Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = Bind(self,self.ON_UPDATED_MAP_CUSTOM_Func) },
	}
	self.BindNodes = {
        { UDelegate = self.View.GUIButton_Normal.OnClicked,				Func = Bind(self,self.OnPurchaseBtnClick) },
		{ UDelegate = self.View.GUIButton_Normal.OnHovered,				Func = Bind(self,self.OnBtnHovered) },
		{ UDelegate = self.View.GUIButton_Normal.OnUnhovered,				Func = Bind(self,self.OnBtnUnhovered) },
        { UDelegate = self.View.GUIButton_Select.OnClicked,				Func = Bind(self,self.OnPurchaseBtnClick) },
		{ UDelegate = self.View.GUIButton_Select.OnHovered,				Func = Bind(self,self.OnBtnHovered) },
		{ UDelegate = self.View.GUIButton_Select.OnUnhovered,				Func = Bind(self,self.OnBtnUnhovered) },
    }
    self.LabelInitColor =  {
        ["Normal"] = {Hex = "F5EFDF", Opacity = 0.6},
        ["Select"] = {Hex = "1B2024"},
    }
    self.HoveredColor = "1B2024"
end

function CommonPurchaseBtn:OnShow(Param)
    self:UpdateItemInfo(Param)
end

function CommonPurchaseBtn:OnHide()
end

--[[
    local Param = 
    {
        --道具图标
        ItemId = 0,
        --道具数量（可选，有值：将会只显示对应数量  空值：会展示背包内的物品数量）
        ItemShowNum = nil,
        --点击回调
        CallFunc
        --Hover回调
        HoverFunc
        --Unhover回调
        UnhoverFunc
        --是否检查仓库物品足够 ItemShowNum非nil值时生效 （不足够时，数字会标红）
        CheckEnough = false,
        --是否选中态 默认为false 也可外部调用SetIsSelect改变
        IsSelect = false,
    }
]]
--- UpdateItemInfo
---@param Param CommonPurchaseBtnParam
function CommonPurchaseBtn:UpdateItemInfo(Param)
	self.Param = Param and Param or self.Param or {}
    if not self.Param.ItemId or self.Param.ItemId <= 0 then
        return
    end
    self:UpdateItemShow()
end


function CommonPurchaseBtn:UpdateItemId(ItemId,ItemShowNum)
    if not ItemId then
        return
    end
    self.Param.ItemId = ItemId
    self.Param.ItemShowNum = ItemShowNum or self.Param.ItemShowNum
    self:UpdateItemShow()
end

function CommonPurchaseBtn:UpdateItemShow()
    self.View.WidgetSwitcher_IsSelect:SetActiveWidget(self.Param.IsSelect and self.View.GUIButton_Select or self.View.GUIButton_Normal)
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.Param.ItemId)
    if not CfgItem then
        print_trackback()
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Icon_Normal,CfgItem[Cfg_ItemConfig_P.IconPath])
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Icon_Select,CfgItem[Cfg_ItemConfig_P.IconPath])
    self:UpdateItemNum()
end

--[[
    更新道具数量
]]
function CommonPurchaseBtn:UpdateItemNum()
    local ItemNum = 0
    if self.Param.ItemShowNum then
        ItemNum =self.Param.ItemShowNum
        CommonUtil.SetTextColorFromeHex(self.View.TextNum_Normal,self.LabelInitColor.Normal.Hex, self.LabelInitColor.Normal.Opacity)
        CommonUtil.SetTextColorFromeHex(self.View.TextNum_Select,self.LabelInitColor.Select.Hex)
        if self.Param.CheckEnough then
            if not MvcEntry:GetModel(DepotModel):IsEnoughByItemId(self.Param.ItemId,self.Param.ItemShowNum) then
                CommonUtil.SetTextColorFromeHex(self.View.TextNum_Normal,UIHelper.HexColor.Red)
                CommonUtil.SetTextColorFromeHex(self.View.TextNum_Select,UIHelper.HexColor.Red)
            end
        end
    else
        ItemNum = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.Param.ItemId)
    end

    local MaxShowNum = CommonConst.MAX_SHOW_NUM_COIN
    self.View.TextNum_Normal:SetText(ItemNum > MaxShowNum and MaxShowNum.."+" or ItemNum.."")
    self.View.TextNum_Select:SetText(ItemNum > MaxShowNum and MaxShowNum.."+" or ItemNum.."")
end

--[[
    道具发生变化回调
]]
function CommonPurchaseBtn:ON_UPDATED_MAP_CUSTOM_Func(_,ChangeMap)
    if not self.Param.CheckEnough  then
        return
    end
    if ChangeMap[self.Param.ItemId] then
        self:UpdateItemNum()
    end
end

--[[
    设置是否选中态
]]
function CommonPurchaseBtn:SetIsSelect(IsSelect)
    self.Param.IsSelect  = IsSelect
    self.View.WidgetSwitcher_IsSelect:SetActiveWidget(self.Param.IsSelect and self.View.GUIButton_Select or self.View.GUIButton_Normal)
end

function CommonPurchaseBtn:OnPurchaseBtnClick()
    if not self.Param.CallFunc then
        CWaring("CommonPurchaseBtn Clicked CallFunc nil!!")
        return
    end
    self.Param.CallFunc()
end

function CommonPurchaseBtn:OnBtnHovered()
    CommonUtil.SetTextColorFromeHex(self.View.TextNum_Normal, self.HoveredColor, 1)
    CommonUtil.SetBrushTintColorFromHex(self.View.Icon_Normal,self.HoveredColor)
    CommonUtil.SetBrushTintColorFromHex(self.View.Icon_Select,self.HoveredColor)
    if self.Param.HoverFunc then
        self.Param.HoverFunc()
    end
end

function CommonPurchaseBtn:OnBtnUnhovered()
    CommonUtil.SetTextColorFromeHex(self.View.TextNum_Normal,self.LabelInitColor.Normal.Hex, self.LabelInitColor.Normal.Opacity)
    CommonUtil.SetBrushTintColorFromHex(self.View.Icon_Normal,UIHelper.HexColor.White)
    CommonUtil.SetBrushTintColorFromHex(self.View.Icon_Select,UIHelper.HexColor.White)
    if self.Param.UnhoverFunc then
        self.Param.UnhoverFunc()
    end
end


return CommonPurchaseBtn
