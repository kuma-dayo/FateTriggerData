
--- 视图控制器
local class_name = "AchievementGetNormalMdt";
AchievementGetNormalMdt = AchievementGetNormalMdt or BaseClass(GameMediator, class_name);

function AchievementGetNormalMdt:__init()
    self:ConfigViewId(ViewConst.AchievementGetNormal)
end

function AchievementGetNormalMdt:OnShow(data)
    
end

function AchievementGetNormalMdt:OnHide()
end

local class_name = "AchievementGetHighMdt";
AchievementGetHighMdt = AchievementGetHighMdt or BaseClass(GameMediator, class_name);

function AchievementGetHighMdt:__init()
    self:ConfigViewId(ViewConst.AchievementGetHigh)
end

function AchievementGetHighMdt:OnShow(data)
    
end

function AchievementGetHighMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    -- self.MsgList = 
    -- {
	-- 	{Model = AchievementModel, MsgName = ListModel.ON_UPDATED, Func = self.OnAchievementUpdate},
    -- }

    self.BindNodes = 
    {
		{ UDelegate = self.Button_BGClose.OnClicked,				    Func = self.OnCloseClickFunc },
	}

    ---@type AchievementModel
    self.Model = MvcEntry:GetModel(AchievementModel)
   
end

function M:OnHide()
    
end

function M:OnShow(Params)
    if not Params or not Params.Id then
        CWaring("AchievementGet:OnShow Params is nil")
        self:OnCloseClickFunc()
        return
    end
    ---@type AchievementData
    local Data = self.Model:GetData(Params.Id)
    if Data then
        Data = self.Model:GetItemShowInfo(Data, Data.Quality == 1 and Data.LV == 1)
    end
    if not Data then
        CWaring("AchievementGet:OnShow Data is nil")
        self:OnCloseClickFunc()
        return
    end
 
    self.GUITextBlock_Name:SetText(StringUtil.FormatText(Data:GetName()))
    -- self.GUITextBlock_Desc:SetText(StringUtil.FormatText(Data:GetDesc()))
    self.GUITextBlock_Condition:SetText(StringUtil.Format(Data:GetCondition(), Data:GetCondiNum()))
    self.GUITextBlock_Level:SetText("")

    local TipDesc = Data:GetDesc()
    self.DescTip:SetVisibility((not TipDesc or #TipDesc < 1) and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    if TipDesc then
        self.GUITextBlock_Desc:SetText(StringUtil.FormatText(Data:GetDesc()))
    end

    if Data.Quality < 5 then
        CommonUtil.SetBrushFromSoftObjectPath(self.Qulity_1, Data:GetShowGetPopItemImgByQualityLv(Data.Quality))
        CommonUtil.SetBrushFromSoftObjectPath(self.Qulity_2, Data:GetShowGetPopItemImgByQualityLv(Data.Quality))
        --self.Image_Qulity4:SetBrushFromSoftObjectPath(self.Model.ItemGetPopNormalBottomImage[Data.Quality])
        CommonUtil.SetBrushFromSoftObjectPath(self.Image_Qulity4, Data:GetRightDownImgByQualityLv(Data.Quality))
        CommonUtil.SetBrushFromSoftObjectPath(self.Image_Level, Data:GetItemTipQualityImgByQualityLv(Data.Quality))
    end

    CommonUtil.SetBrushFromSoftObjectPath(self.Img_Icon,Data:GetIcon())
    CommonUtil.SetQualityShowForQualityId(Data.Quality, {
        QualityColorImgs = {
            self.Img_Line,
            self.Img_Rainbow,
            self.Img_TipsLight,
            self.Img_TipsBg,
        },
        QualityColorTexts = {
            self.GUITextBlock_Level
        }
    })
end

function M:OnCloseClickFunc()
    MvcEntry:CloseView(self.viewId)
end

return M
