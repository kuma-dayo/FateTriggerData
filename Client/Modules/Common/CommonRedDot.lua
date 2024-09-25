---
--- 红点工厂逻辑，根据传入的数据找到对应的红点样式并挂载
--- Description: 
--- Created At: 2023/10/12 17:08
--- Created By: 朝文
---

---这里只是一个空蓝图，具体挂载的红点得根据类型和蓝图后续动态生成挂载
--- UIHandler.New(self, self.WBP_RedDotFactory, CommonRedDot, {RedDotKey = "TabHeroSkinItem_", RedDotSuffix = "200030003"})

local class_name = "CommonRedDot"
---@class CommonRedDot
CommonRedDot = CommonRedDot or BaseClass(nil, class_name)

function CommonRedDot:OnInit()
    self.BindNodes = {
        --{ UDelegate = self.View.GUIButton_Tips.OnClicked,				Func = Bind(self,self.OnItemButtonClick) },
    }
end

--[[
    Param = {
        RedDotKey    = "TabHero_",
        RedDotSuffix = "10001000",
    }
--]]
function CommonRedDot:OnShow(Param)
    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Data = Param
    CLog("[cw] RedDotKey: " .. tostring(self.Data.RedDotKey) .. "RedDotSuffix: " .. tostring(self.Data.RedDotSuffix))
    self:_GenerateRedDotType()
end

function CommonRedDot:OnHide()
end

function CommonRedDot:_GenerateRedDotType()
    ---@type RedDotModel
    local RedDotModel = MvcEntry:GetModel(RedDotModel)
    local RedDotConfg = require("Client.Modules.RedDot.RedDotConfig")
    self.redDotDisplayTypeEnum = RedDotModel:RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum_ByRedDotHierarchyCfgKey(self.Data.RedDotKey) or RedDotConfg.Enum_Style.Normal
    CLog("[cw] self.redDotDisplayTypeEnum: " .. tostring(self.redDotDisplayTypeEnum))
    
    --初始化样式
    self.View.Content:ClearChildren()
    local UMGPath = RedDotConfg.UMG_Config[self.redDotDisplayTypeEnum].UMGPath
    local LuaPath = RedDotConfg.UMG_Config[self.redDotDisplayTypeEnum].LuaPath
    CLog("[cw] UMGPath: " .. tostring(UMGPath))
    CLog("[cw] LuaPath: " .. tostring(LuaPath))
    local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(UMGPath))
    local Widget = NewObject(WidgetClass, self.View)
    UIRoot.AddChildToPanel(Widget, self.View.Content)
    Widget.Slot:SetAutoSize(true)
    ---@generic RedDotUMGStyle : RedDotUMGBase
    ---@type RedDotUMGStyle
    self.InnderRedDot = UIHandler.New(self, Widget, LuaPath, self.Data).ViewInstance
end

--[[
    Param = {
        RedDotKey    = "TabHero_",
        RedDotSuffix = "10001000",
    }
--]]
---更换红点的前后缀，会触发更新
---@param RedDotKey string 红点key 例如 TabHero_200010000 中的 TabHero_
---@param RedDotSuffix string|number 红点尾缀，例如 TabHero_200010000 中的 200010000
function CommonRedDot:ChangeKey(RedDotKey, RedDotSuffix)
    CLog("[cw] CommonRedDot:ChangeKey(" .. string.format("%s, %s", RedDotKey, RedDotSuffix) .. ")")
    local oldRedDotKey, oldRedDotSuffix
    self.Data.RedDotKey = RedDotKey
    self.Data.RedDotSuffix = RedDotSuffix

    --如果相同的枚举样式类型，则直接刷新就好
    ---@type RedDotModel
    local RedDotModel = MvcEntry:GetModel(RedDotModel)
    local newDisplayEnumType = RedDotModel:RedDotDisplayTypeCfg_GetRedDotDisplayTypeEnum_ByRedDotHierarchyCfgKey(RedDotKey)
    if newDisplayEnumType == self.redDotDisplayTypeEnum then
        self.InnderRedDot:UpdateData(self.Data.RedDotKey, self.Data.RedDotSuffix)
        self.InnderRedDot:UpdateRedDot()
        CLog("[cw] " .. tostring(RedDotModel:ContactKey(RedDotKey, RedDotSuffix)) .. "has same display type(" .. tostring(newDisplayEnumType) .. ") with " .. tostring(RedDotModel:ContactKey(oldRedDotKey, oldRedDotSuffix)) .. ", so directly update reddot")
        return
    end
    
    --否则需要重新生成节点
    CLog("[cw] " .. tostring(RedDotModel:ContactKey(RedDotKey, RedDotSuffix)) .. "has different display type(" .. tostring(newDisplayEnumType) .. ") with " .. tostring(RedDotModel:ContactKey(oldRedDotKey, oldRedDotSuffix)) .. "'s type(" .. tostring(self.redDotDisplayTypeEnum) .. ") directly update reddot")
    self:_GenerateRedDotType()
end

---预留
function CommonRedDot:RefreshNode()
    if self.InnderRedDot and self.InnderRedDot.UpdateRedDot then
        self.InnderRedDot:UpdateRedDot()
    end
end

---触发红点交互
---@param TriggerType number 红点触发操作类型
function CommonRedDot:Interact(TriggerType)
    TriggerType = TriggerType or RedDotModel.Enum_RedDotTriggerType.Click
    if self.InnderRedDot then
        ---@type RedDotCtrl
        local RedDotCtrl = MvcEntry:GetCtrl(RedDotCtrl)
        RedDotCtrl:Interact(self.Data.RedDotKey, self.Data.RedDotSuffix, TriggerType)
    end
end

return CommonRedDot