--[[
    通用的CommonTips控件
    传值ItemId和具体的控件，进行自动取值展示
]]

local class_name = "CommonCurrencyTip"
CommonCurrencyTip = CommonCurrencyTip or BaseClass(nil, class_name)

---@class CommonCurrencyTipParam
---@field ItemId 道具图标
---@field ItemShowNum 道具数量（可选，有值：将会只显示对应数量  空值：会展示背包内的物品数量）
---@field CheckEnough 是否检查仓库物品足够 ItemShowNum非nil值时生效 （不足够时，数字会标红）
---@field IconWidget Icon控件
---@field LabelWidget 文本控件（显示数量）
CommonCurrencyTip.Param = nil

function CommonCurrencyTip:OnInit()
    self.MsgList = 
    {
		{Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = self.ON_UPDATED_MAP_CUSTOM_Func },
	}
end

function CommonCurrencyTip:OnShow(Param)
    self:UpdateItemInfo(Param)
end

function CommonCurrencyTip:OnHide()
end

function CommonCurrencyTip:OnManualShow(Param)
    self:UpdateItemInfo(self.Param)
end

--[[
    local Param = 
    {
        --道具图标
        ItemId = 0,
        --道具数量（可选，有值：将会只显示对应数量  空值：会展示背包内的物品数量）
        ItemShowNum = nil,
        --是否检查仓库物品足够 ItemShowNum非nil值时生效 （不足够时，数字会标红）
        CheckEnough = true,
        --Icon控件
        IconWidget = nil,
        --文本控件（显示数量）
        LabelWidget = nil,
    }
]]
--- UpdateItemInfo
---@param Param CommonCurrencyTipParam
function CommonCurrencyTip:UpdateItemInfo(Param)
	self.Param = self.Param or Param or {}
    if Param then
        self.Param.ItemId = Param.ItemId or self.Param.ItemId or 0
        self.Param.ItemShowNum = Param.ItemShowNum or self.Param.ItemShowNum or nil
        self.Param.IconWidget = Param.IconWidget or self.Param.IconWidget or nil
        self.Param.LabelWidget = Param.LabelWidget or self.Param.LabelWidget or nil
        if Param.CheckEnough ~= nil then
            self.Param.CheckEnough = Param.CheckEnough
        end
    end
    if not self.Param.ItemId or self.Param.ItemId <= 0 then
        return
    end
    self:UpdateItemShow()
end


function CommonCurrencyTip:UpdateItemId(ItemId,ItemShowNum)
    if not ItemId then
        return
    end
    self.Param.ItemId = ItemId
    self.Param.ItemShowNum = ItemShowNum or self.Param.ItemShowNum
    self:UpdateItemShow()
end

function CommonCurrencyTip:UpdateItemShow()
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.Param.ItemId)
    if not CfgItem then
        CError(string.format("UpdateItemShow:: Get Cfg_ItemConfig Failed!! ItemId=[%s]",self.Param.ItemId), true)
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.Param.IconWidget,CfgItem[Cfg_ItemConfig_P.IconPath])

    self:UpdateItemNum()
end

--[[
    更新道具数量
]]
function CommonCurrencyTip:UpdateItemNum()
    local ItemNum = 0
    if self.Param.ItemShowNum then
        ItemNum =self.Param.ItemShowNum
        CommonUtil.SetTextColorFromeHex(self.Param.LabelWidget,UIHelper.HexColor.White)
        if self.Param.CheckEnough then
            if not MvcEntry:GetModel(DepotModel):IsEnoughByItemId(self.Param.ItemId,self.Param.ItemShowNum) then
                CommonUtil.SetTextColorFromeHex(self.Param.LabelWidget,UIHelper.HexColor.Red)
            end
        --    if not MvcEntry:GetModel(DepotModel):IsEnoughMoneyByItemId(self.Param.ItemId,self.Param.ItemShowNum) then
        --         CommonUtil.SetTextColorFromeHex(self.Param.LabelWidget,UIHelper.HexColor.Red)
        --     end
        end
    else
        ItemNum = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.Param.ItemId)
        -- ItemNum = MvcEntry:GetModel(DepotModel):GetMoneyNumByItemID(self.Param.ItemId)
    end

    local MaxShowNum = CommonConst.MAX_SHOW_NUM_COIN
    self.Param.LabelWidget:SetText(ItemNum > MaxShowNum and MaxShowNum.."+" or ItemNum.."")

end

--[[
    道具发生变化回调
]]
function CommonCurrencyTip:ON_UPDATED_MAP_CUSTOM_Func(ChangeMap)
    if self.Param.ItemShowNum  then
        return
    end
    if ChangeMap[self.Param.ItemId] then
        self:UpdateItemNum()
    elseif self.Param.ItemId == DepotConst.ITEM_ID_DIAMOND and ChangeMap[DepotConst.ITEM_ID_DIAMOND_GIFT] then
        -- 系统赠送钻石需要特殊处理:此栏是钻石=900000002,而系统下发了免费钻石。这里必须更新钻石栏
        self:UpdateItemNum()
    end
end


return CommonCurrencyTip
