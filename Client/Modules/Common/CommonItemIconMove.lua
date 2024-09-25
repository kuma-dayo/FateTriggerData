local class_name = "CommonItemIconMove"
local CommonItemIconMove = BaseClass(UIHandlerViewBase, class_name)

---@class CommonItemIconParam
---@field IconType CommonItemIcon.ICON_TYPE 图标所属类型，可根据不同类型做不同处理
---@field ItemId number 配置ID

function CommonItemIconMove:OnInit()
    self.MsgList = {}
    self.BindNodes = {}
    self:Init()
end

function CommonItemIconMove:OnShow(Param)
    self:UpdateUI(Param)
end

function CommonItemIconMove:OnManualShow(Param)
    self:UpdateUI(Param)
end

function CommonItemIconMove:OnManualHide(Param)
end

function CommonItemIconMove:OnHide(Param)
end

function CommonItemIconMove:OnDestroy(Data,IsNotVirtualTrigger)
end


function CommonItemIconMove:Init()
    self.IconParams = nil
    self.IconType = CommonItemIcon.ICON_TYPE.NONE
    self:Clear()
end

function CommonItemIconMove:Clear()
end

function CommonItemIconMove:UpdateUI(Param)
    self.IconParams = Param
    if not self.IconParams then
        self:PopError("CommonItemIcon:UpdateUI IconParams Error")
        return
    end

    if self.IconParams.ItemId <= 0 then
        print("CommonItemIcon:UpdateUI ItemId = 0; Use Default Show!")
        -- TODO 展示默认底图
        return
    end

    self.IconType = Param.IconType or CommonItemIcon.ICON_TYPE.NONE

    self:DoUpdate()
end

function CommonItemIconMove:DoUpdate()
    if not self.IconParams then
        return
    end
    local ICON_TYPE = CommonItemIcon.ICON_TYPE
    local IconPath, Quality
    if self.IconType == ICON_TYPE.PROP then
        -- 道具
        local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.IconParams.ItemId)
        if not ItemCfg then
            self:PopError("CommonItemIcon:DoUpdate GetItemConfig Error!")
            return
        end
        -- TODO 是否根据不同类型处理
        IconPath = ItemCfg[Cfg_ItemConfig_P.IconPath]
        Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
        self:SetShowCount(self.IconParams.ItemNum)
    elseif self.IconType == ICON_TYPE.ACHIEVEMENT then
        local Model = MvcEntry:GetModel(AchievementModel)
        ---@type AchievementData
        local Data = Model:GetData(self.IconParams.ItemId)
        if not Data then
            CError("CommonItemIcon:DoUpdate Data is nil id:"..self.IconParams.ItemId)
            return
        end
        
        -- self.View.GUITextBlock_Name:SetText(Data:GetName())
        -- self.View.GUITextBlock_Level:SetText(Data:GetCurQualityCap())
        IconPath = Data:GetIcon()
        Quality = Data.Quality
    end

    self:UpdateIcon(IconPath)
    self:UpdateQuality(Quality)
end

-- 更新Icon资源
function CommonItemIconMove:UpdateIcon(IconPath)
    self.View.GUIImageIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    local IconImg = LoadObject(IconPath)
    if IconImg then
        self.View.GUIImageIcon:SetBrushFromTexture(IconImg)
        self.View.GUIImageIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

-- 品质色
function CommonItemIconMove:UpdateQuality(Quality)
    self.View.GUIImage_QualityBg:SetVisibility(UE.ESlateVisibility.Collapsed)
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
    if QualityCfg then
        local QualityBgPath = QualityCfg[Cfg_ItemQualityColorCfg_P.QualityBg]
        self.View.GUIImage_QualityBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImage_QualityBg,QualityBgPath)
        -- CommonUtil.SetImageColorFromQuality(self.View.QualityBar,Quality)
        --CommonUtil.SetTextColorFromQuality(self.View.GUITextBlock_Level,Quality)
    end
end

return CommonItemIconMove