--[[
   个人信息 - 个性化设置 - 系列Item - WBP_ImformationHeadItemWidget
]] 
local class_name = "HeadIconSettingSeriesItem"
local HeadIconSettingSeriesItem = BaseClass(nil, class_name)

function HeadIconSettingSeriesItem:OnInit()
    self.MsgList = {
        -- {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED,Func = Bind(self,self.OnGetPlayerBaseInfo) },
    }
    self.BindNodes = {
		-- { UDelegate = self.View.Button.OnClicked,				Func = Bind(self,self.OnClick_JumpToPlayerInfo) },
    }
    ---@type HeadIconSettingModel
    self.HeadIconSettingModel = MvcEntry:GetModel(HeadIconSettingModel)
    self.ColNum = 6
    self.Index2Item = {}
    self.UMGInfo = {
        UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/Item/WBP_ImformationHeadListItemWidget.WBP_ImformationHeadListItemWidget",
        LuaClass = require("Client.Modules.PlayerInfo.HeadIconSetting.HeadIconSettingItem"),
    }
end

--[[
    local Param = {
        SettingType = HeadIconSettingModel.SettingType
        SeriesCfg = Cfg_HeadIconSeriesCfg / Cfg_HeadFrameSeriesCfg / Cfg_HeadWidgetSeriesCfg
    }    
]]
function HeadIconSettingSeriesItem:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function HeadIconSettingSeriesItem:OnHide()
end

function HeadIconSettingSeriesItem:UpdateUI(Param)
    self.SettingType = Param.SettingType
    self.SeriesCfg = Param.SeriesCfg
    if not (self.SettingType and self.SeriesCfg) then
        return
    end
    local _,SeriesCfgKey = self.HeadIconSettingModel:GetSettintSeriesCfgNameAndKey(self.SettingType)
    if not SeriesCfgKey then
        CError("HeadIconSettingSeriesItem GetSettintSeriesCfgNameAndKey Error",true)
        return
    end
    self.View.Text_ListTitle:SetText(self.SeriesCfg[SeriesCfgKey.SeriesName] or "")
    local SeriesId = self.SeriesCfg[SeriesCfgKey.SeriesId]
    local SeriesDatas = self.HeadIconSettingModel:GetShowListForSeries(self.SettingType,SeriesId)

    --[[
        - 已经解锁的前置显示
        - 已解锁的内容以 ID 升序排列
    ]]
    table.sort(SeriesDatas,function (DataIdA, DataIdB)
        DataIdA = self.HeadIconSettingModel:TransUniqueId2Id(DataIdA)
        DataIdB = self.HeadIconSettingModel:TransUniqueId2Id(DataIdB)
        local IsUnlockA = self.HeadIconSettingModel:IsSettingUnlock(self.SettingType,DataIdA)
        local IsUnlockB = self.HeadIconSettingModel:IsSettingUnlock(self.SettingType,DataIdB)
        if IsUnlockA and not IsUnlockB then
            return true
        elseif not IsUnlockA and IsUnlockB then
            return false
        else
           return DataIdA < DataIdB
        end
    end)

    if not SeriesDatas or #SeriesDatas == 0 then
        CError("HeadIconSettingSeriesItem Get Show List Error For SeriesId = "..SeriesId,true)
        return
    end
    local Index = 1
    for _, DataId in ipairs(SeriesDatas) do
        local Item = self.Index2Item[Index]
        if not Item then
            local WidgetClassPath = self.UMGInfo.UMGPATH
            local WidgetClass = UE.UClass.Load(WidgetClassPath)
            if not WidgetClass then
                CError("HeadIconSettingSeriesItem Load WidgetClass Error",true)
                return
            end
            local Widget = NewObject(WidgetClass, self.View)
            local Col = Index % self.ColNum - 1
            if Col < 0 then
                Col = self.ColNum - 1
            end
            local Row =  math.floor(Index/self.ColNum)
            if Index%self.ColNum == 0 then
                Row = Row - 1
            end
            self.View.GridPanel:AddChildToGrid(Widget,Row,Col)
            
            local Nudge = self.View.GridNudge
            Widget.Slot:SetNudge(UE.FVector2D(Col*Nudge, Row*Nudge))
            local ViewItem = UIHandler.New(self,Widget,self.UMGInfo.LuaClass).ViewInstance
            Item = {}
            Item.View = Widget
            Item.ViewItem = ViewItem
            self.Index2Item[Index] = Item
        end
        local Param = {
            SettingType = self.SettingType,
            SeriesId = SeriesId,
            Id = DataId,
            -- IsFirstSeries = Param.IsFirstSeries,
            -- IsFirstData = Index == 1,
        }
        Item.ViewItem:UpdateUI(Param)
        Index = Index + 1
    end

    while self.Index2Item[Index] do
        self.Index2Item[Index].View:RemoveFromParent()
        self.Index2Item[Index] = nil
        Index = Index + 1
    end
end

return HeadIconSettingSeriesItem
