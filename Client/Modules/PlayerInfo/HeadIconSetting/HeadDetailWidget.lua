--[[
   个人信息 - 个性化设置 - 头像Item - WBP_HeadDetailWidget
]] 
local HeadWidgetUtil = require("Client.Modules.PlayerInfo.HeadIconSetting.HeadWidgetUtil")
local class_name = "HeadDetailWidget"
local HeadDetailWidget = BaseClass(nil, class_name)

function HeadDetailWidget:OnInit()
    ---@type HttpCtrl
    self.HttpCtrl = MvcEntry:GetCtrl(HttpCtrl)
    ---@type HeadIconSettingModel
    self.HeadIconSettingModel = MvcEntry:GetModel(HeadIconSettingModel)
    self.WidgetCls = {}
end

--[[
    local Param = {
        SettingType = HeadIconSettingModel.SettingType,
        Id,
        IsShowWeight = false -- (用于头像框) 是否显示总重量
        JustShowWidget = false -- (用于头像挂件) 是否仅展示，无需操控 / 未false时，需要显示当前头像框和头像框
        IsShowWholeHead = false -- 是否展示完整头像组件 头像&头像框&挂件
    }    
]]
function HeadDetailWidget:OnShow(Param)
    self:UpdateUI(Param)
end

function HeadDetailWidget:OnHide()
    self.WidgetCls = {}
end

function HeadDetailWidget:UpdateUI(Param)
    if not Param then
        return
    end
    self.Param = Param
    self.IsSendUpdateHead = false
    local TypeEnum = HeadIconSettingModel.SettingType
    local SettingType = Param.SettingType
    self.Cfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(self.Param.SettingType,self.Param.Id)
    if self.Param.JustShowWidget and not self.Cfg then
        CError(StringUtil.Format("HeadDetailWidget:GetHeadIconSettintCfg Error For Type ={0} Id = {1}",self.Param.SettingType,self.Param.Id),true)
        return
    end

    if SettingType == TypeEnum.HeadIcon then
        if self.Param.IsShowWholeHead then
            self.View.WidgetSwitcher_Head:SetActiveWidget(self.View.HeadIconWidgetShowWhole)
            self:UpdateWholeHeadIcon()
        else
            self.View.WidgetSwitcher_Head:SetActiveWidget(self.View.HeadIcon)
            self:UpdateHeadIcon(self.View.Image_Icon) 
        end
    elseif SettingType == TypeEnum.HeadFrame then
        if self.Param.IsShowWholeHead then
            self.View.WidgetSwitcher_Head:SetActiveWidget(self.View.HeadIconWidgetShowWhole)
            self:UpdateWholeHeadIcon()
        else
            self.View.WidgetSwitcher_Head:SetActiveWidget(self.View.HeadIconFrame)
            self:UpdateHeadFrameShowWeight()
            self:UpdateHeadIconFrame(self.View.Image_HeadFrame)
        end
    elseif SettingType == TypeEnum.HeadWidget then
        self.View.WidgetSwitcher_Head:SetActiveWidget(self.View.HeadIconWidget)
        self:UpdateHeadIconWidget()
    end
end

-- 重置为默认头像纹理
function HeadDetailWidget:ResetHeadDefaultIcon()
    if self.View.Image_Icon and self.View.HeadDefaultIcon then
        local Material = self.View.Image_Icon:GetDynamicMaterial()
        if Material then
            Material:SetTextureParameterValue("Target", self.View.HeadDefaultIcon)
        end
	end
end

-- 更新展示头像
function HeadDetailWidget:UpdateHeadIcon(HeadIconWidget, EmptyHeadIconWidget)
    if HeadIconWidget then
        -- 是否为自定义头像
        if self.HeadIconSettingModel:CheckIsCustomHead(self.Param.Id) then
            local CustomHeadUrl = self.HeadIconSettingModel:GetMySelfCustomHeadUrl(true)
            if CustomHeadUrl and CustomHeadUrl ~= "" then
                self.IsSendUpdateHead = true
                self.HttpCtrl:SendImageUrlReq(CustomHeadUrl, function(Texture)
                    if CommonUtil.IsValid(self.View) and Texture and self.IsSendUpdateHead then 
                        HeadIconWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                        HeadIconWidget:GetDynamicMaterial():SetTextureParameterValue("Target",Texture)
                    end
                end)
            else
                HeadIconWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
                if EmptyHeadIconWidget then
                    EmptyHeadIconWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                end
            end
        else
            HeadIconWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            if self.Cfg then
                CommonUtil.SetMaterialTextureParamSoftObjectPath(HeadIconWidget,"Target",self.Cfg[Cfg_HeroHeadConfig_P.IconPath])
            end
        end 
    end
end

-- 更新是否显示负重
function HeadDetailWidget:UpdateHeadFrameShowWeight()
    if self.Param.IsShowWeight then
        self.View.Panel_Weight:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        local MaxWeight = self.Cfg and self.Cfg[Cfg_HeadFrameCfg_P.MaxWeight] or 0
        self.View.Text_Weight:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_8"),MaxWeight)) 
    else
        self.View.Panel_Weight:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 更新展示头像框
function HeadDetailWidget:UpdateHeadIconFrame(HeadIconFrameWidget)
    if self.Cfg then
        CommonUtil.SetBrushFromSoftObjectPath(HeadIconFrameWidget,self.Cfg[Cfg_HeadFrameCfg_P.IconPath])
    end
end

-- 更新展示头像挂件
function HeadDetailWidget:UpdateHeadIconWidget()
    local TotalWeight = self.HeadIconSettingModel:GetCurMaxWeight()
    if not self.Param.JustShowWidget then
        self.View.Container_Weight:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- 显示当前佩戴的头像和头像框
        self.View.WidgetSwitcher_WidgetBg:SetActiveWidget(self.View.IconBg)
        self.View.Panel_Widget.Slot:SetSize(UE.FVector2D(HeadWidgetUtil.DefaultSize,HeadWidgetUtil.DefaultSize))
        -- 更新自己身上的装备的头像信息
        self:UpdateEquipHeadIconInfo(self.View.Image_BgIcon)
        -- 更新已装备的头像框信息
        self:UpdateEquipHeadIconFrameInfo(self.View.Image_BgIconFrame)

        -- 计算佩戴的挂件
        local ShowWidgetList = {}
        local UsedWeight = 0
        local IsSelectUsing = self.Cfg and self.HeadIconSettingModel:IsHeadWidgetUsing(self.Param.Id)
        if self.Cfg and not IsSelectUsing then
            -- 有选中，且选中的未装备，才需要作为将占用重量进行计算
            UsedWeight = self.Cfg[Cfg_HeadWidgetCfg_P.Weight]
        end
        local HeadWidgetList = {}
        if UsedWeight > 0 then
            -- 有选中的，需要检测重量的，使用排序的列表
            HeadWidgetList = self.HeadIconSettingModel:GetSortedUsingHeadWidgetList()
        else
            -- 无选中的，使用原生列表
            HeadWidgetList = self.HeadIconSettingModel:GetUsingHeadWidgetList()
        end
            
        -- local HeadWidgetList = self.HeadIconSettingModel:GetUsingHeadWidgetList()
        -- local HeadWidgetList = self.HeadIconSettingModel:GetSortedUsingHeadWidgetList()
        if HeadWidgetList and #HeadWidgetList > 0 then
            -- for _,HeadWidgetNode in ipairs(HeadWidgetList) do
            -- 从后往前遍历，优先放入后添加的挂件
            for Index = #HeadWidgetList , 1, -1 do
                local HeadWidgetNode = HeadWidgetList[Index]
                local Cfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadWidget,HeadWidgetNode.HeadWidgetId)
                if Cfg then
                    local ShowWidgetInfo = {
                        HeadWidgetId = HeadWidgetNode.HeadWidgetId, 
                        Angle = HeadWidgetNode.Angle,
                        Cfg = Cfg,
                        WidgetContainer = self.View.Panel_Widget
                    }
                    if UsedWeight > 0 then
                        -- 如果有选中的，需要检测容量，超重要先卸下
                        local Weight = Cfg[Cfg_HeadWidgetCfg_P.Weight]
                        if Weight + UsedWeight <= TotalWeight then
                            table.insert(ShowWidgetList,1,ShowWidgetInfo)
                            UsedWeight = UsedWeight + Weight
                        else
                            break
                        end
                    else
                        -- 无选中则直接展示当前已佩戴的
                        table.insert(ShowWidgetList,1,ShowWidgetInfo)
                    end
                end
            end
        end
        if self.Cfg and not IsSelectUsing then
            -- 最后添加选中的（如果有）
            local ShowWidgetInfo = {
                HeadWidgetId = self.Param.Id, 
                Angle = 0,
                Cfg = self.Cfg,
                WidgetContainer = self.View.Panel_Widget
            }
            table.insert(ShowWidgetList,ShowWidgetInfo)
        end
    
        HeadWidgetUtil.CreateHeadWidgets(self.View.Panel_Widget, self.View, ShowWidgetList)
        -- 非仅展示的，需要一个操作逻辑
        local WidgetCount = self.View.Panel_Widget:GetChildrenCount()
        local Index = 1
        for I = 1,WidgetCount do
            local Widget = self.View.Panel_Widget:GetChildAt(Index-1)
            local WidgetCls = self.WidgetCls[Index]
            if not WidgetCls then
                WidgetCls = UIHandler.New(self,Widget,require("Client.Modules.PlayerInfo.HeadIconSetting.HeadWidgetOperate")).ViewInstance
                self.WidgetCls[Index] = WidgetCls
            end
            WidgetCls:UpdateUI(ShowWidgetList[Index])
            Index = Index + 1
        end
        while self.WidgetCls[Index] do
            self.WidgetCls[Index] = nil
            Index = Index + 1
        end
    elseif self.Cfg then
        -- 仅展示挂件本身以及所需容量
        local ShowWidgetList = {
            [1] = {
                Angle = 0,
                Cfg = self.Cfg,
            }
        }
        self.View.WidgetSwitcher_WidgetBg:SetActiveWidget(self.View.EmptyBg)
        self.View.Panel_Widget.Slot:SetSize(UE.FVector2D(HeadWidgetUtil.EmptyBgSize,HeadWidgetUtil.EmptyBgSize))
        HeadWidgetUtil.CreateHeadWidgets(self.View.Panel_Widget, self.View, ShowWidgetList,HeadWidgetUtil.EmptyBgSize/HeadWidgetUtil.DefaultSize)
        self.View.Container_Weight:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        CommonUtil.AddChildToContainer(self.View.Container_Weight,self.View,"/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/Item/WBP_ImformationCircleWidget3.WBP_ImformationCircleWidget3",self.Cfg[Cfg_HeadWidgetCfg_P.Weight],self.View.WidgetHeightPadding)
    end
end

-- 更新已装备的头像信息
function HeadDetailWidget:UpdateEquipHeadIconInfo(HeadIconWidget)
    ---@type PersonalInfoModel
    local PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)
    local UsingId = self.HeadIconSettingModel:GetUsingId(HeadIconSettingModel.SettingType.HeadIcon)
    if UsingId then
        HeadIconWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if UsingId == HeadIconSettingModel.CustomHeadId then
            local CustomHeadUrl = self.HeadIconSettingModel:GetMySelfCustomHeadUrl(true)
            self.HttpCtrl:SendImageUrlReq(CustomHeadUrl, function(Texture)
                if CommonUtil.IsValid(self.View) and Texture then 
                    HeadIconWidget:GetDynamicMaterial():SetTextureParameterValue("Target",Texture)
                end
            end)
        else
            local HeadCfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadIcon,UsingId)
            if HeadCfg then
                CommonUtil.SetMaterialTextureParamSoftObjectPath(HeadIconWidget,"Target",HeadCfg[Cfg_HeroHeadConfig_P.IconPath])
            end
        end
    end
end

-- 更新已装备的头像框信息
function HeadDetailWidget:UpdateEquipHeadIconFrameInfo(HeadIconFrameWidget)
    ---@type PersonalInfoModel
    local PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)
    local CurHeadFrameId = PersonalInfoModel:GetMyPlayerProperty("HeadFrameId")
    if CurHeadFrameId then
        local HeadFrameCfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadFrame,CurHeadFrameId)
        if HeadFrameCfg then
            CommonUtil.SetBrushFromSoftObjectPath(HeadIconFrameWidget,HeadFrameCfg[Cfg_HeadFrameCfg_P.IconPath])
        end
    end
end

-- 更新已装备的挂件信息
function HeadDetailWidget:UpdateEquipHeadIconWidgetInfo(WidgetPanel)
    -- 计算佩戴的挂件
    local ShowWidgetList = {}
    local HeadWidgetList = self.HeadIconSettingModel:GetUsingHeadWidgetList()
    if HeadWidgetList and #HeadWidgetList > 0 then
        -- 从后往前遍历，优先放入后添加的挂件
        for Index = #HeadWidgetList , 1, -1 do
            local HeadWidgetNode = HeadWidgetList[Index]
            local Cfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadWidget,HeadWidgetNode.HeadWidgetId)
            if Cfg then
                local ShowWidgetInfo = {
                    HeadWidgetId = HeadWidgetNode.HeadWidgetId, 
                    Angle = HeadWidgetNode.Angle,
                    Cfg = Cfg,
                    WidgetContainer = WidgetPanel
                }
                -- 无选中则直接展示当前已佩戴的
                table.insert(ShowWidgetList,1,ShowWidgetInfo)
            end
        end
    end
    HeadWidgetUtil.CreateHeadWidgets(WidgetPanel, self.View, ShowWidgetList)
end

-- 展示完整头像组件 头像&头像框&挂件
function HeadDetailWidget:UpdateWholeHeadIcon()
    self.View.Image_EmptyHeadIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    ---@type PersonalInfoModel
    local PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)
    if self.Param.SettingType == HeadIconSettingModel.SettingType.HeadIcon then
        self:UpdateHeadIcon(self.View.Image_BgIconShowWhole, self.View.Image_EmptyHeadIcon)
        self:UpdateEquipHeadIconFrameInfo(self.View.Image_BgIconFrameShowWhole)
        self:UpdateEquipHeadIconWidgetInfo(self.View.Panel_WidgetShowWhole)
    elseif self.Param.SettingType == HeadIconSettingModel.SettingType.HeadFrame then
        self:UpdateEquipHeadIconInfo(self.View.Image_BgIconShowWhole)
        self:UpdateHeadIconFrame(self.View.Image_BgIconFrameShowWhole)
        self:UpdateEquipHeadIconWidgetInfo(self.View.Panel_WidgetShowWhole)
    end
end

return HeadDetailWidget
