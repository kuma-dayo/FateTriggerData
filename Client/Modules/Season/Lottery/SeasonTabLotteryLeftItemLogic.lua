--[[
   赛季抽奖左边列表Item
]] 
local class_name = "SeasonTabLotteryLeftItemLogic"
local SeasonTabLotteryLeftItemLogic = BaseClass(nil, class_name)

function SeasonTabLotteryLeftItemLogic:OnInit()

    self.BindNodes = {
		{ UDelegate = self.View.Btn_Normal.OnClicked,				Func = Bind(self,self.OnBtnClick) },
        { UDelegate = self.View.Btn_Selected.OnClicked,				Func = Bind(self,self.OnBtnClick) },
    }
    self.LeftWidget2SpecialHanler = {}
end

--[[
]]
function SeasonTabLotteryLeftItemLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function SeasonTabLotteryLeftItemLogic:OnHide()
end
--[[
    local Param = {
        ContentData = ContentData,
        OnClickCallBack = Bind(self,self.OnClickLeftContentItem,PrizePoolId),
    }
]]
function SeasonTabLotteryLeftItemLogic:UpdateUI(Param)
    if not Param then
        return
    end
    local ContentData = Param.ContentData
    local PrizePoolId = ContentData.PrizePoolId
    self.Param = Param

    local Widget = self.View
    local PrizePoolConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePoolConfig,PrizePoolId)
    for i=1,10 do
        local NameKey = "LbName" .. i
        if not Widget[NameKey] then
            break
        end
        Widget[NameKey]:SetText(PrizePoolConfig[Cfg_PrizePoolConfig_P.PoolName])
    end
    for i=1,10 do
        local NameKey = "ImageIcon" .. i
        if not Widget[NameKey] then
            break
        end
        CommonUtil.SetBrushFromSoftObjectPath(Widget[NameKey],PrizePoolConfig[Cfg_PrizePoolConfig_P.PoolIcon])
    end
    for i=1,10 do
        local NameKey = "ImageNum" .. i
        if not Widget[NameKey] then
            break
        end
        Widget[NameKey]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
   
    local NeedTimeShow = ContentData.BeginTime > 0 and true or false
    for i=1,10 do
        local NameKey = "WBP_CommonSpecialMark_" .. i
        if not Widget[NameKey] then
            break
        end
        local WBP_CommonSpecialMark = Widget[NameKey]
        if NeedTimeShow then
            WBP_CommonSpecialMark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            if not self.LeftWidget2SpecialHanler[WBP_CommonSpecialMark] then
                self.LeftWidget2SpecialHanler[WBP_CommonSpecialMark] = UIHandler.New(self,WBP_CommonSpecialMark,require("Client.Modules.Common.CommonSpecialMark")).ViewInstance
            end
            local CTime = GetTimestamp()
            local TimeStr = "--"
            if ContentData.EndTime > CTime then
                TimeStr = TimeUtils.GetTimeString_CountDownStyle(ContentData.EndTime - CTime)
            end
            local SpecialParam = {
                SpecialMarkText = TimeStr
            }
            self.LeftWidget2SpecialHanler[WBP_CommonSpecialMark]:UpdataShow(SpecialParam)
        else
            WBP_CommonSpecialMark:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    if NeedTimeShow then
        if not self.CounDownTimer then
            self.CounDownTimer = self:InsertTimerByEndTime(ContentData.EndTime,function (TimeStr,ResultParam)
                for k,SpecialHanler in pairs(self.LeftWidget2SpecialHanler) do
                    SpecialHanler:UpdateSpecialMarkText(TimeStr)
                end
            end)
        end
    end
end

function SeasonTabLotteryLeftItemLogic:Select()
    self.View.WidgetSwitcher:SetActiveWidget(true and self.View.Btn_Selected or self.View.Btn_Normal)
end
function SeasonTabLotteryLeftItemLogic:UnSelect()
    self.View.WidgetSwitcher:SetActiveWidget(false and self.View.Btn_Selected or self.View.Btn_Normal)
end

function SeasonTabLotteryLeftItemLogic:OnBtnClick()
    if self.Param and self.Param.OnClickCallBack then
        self.Param.OnClickCallBack()
    end
end


return SeasonTabLotteryLeftItemLogic
