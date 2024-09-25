local  AchievementConst = require("Client.Modules.Achievement.AchievementConst")
--- 视图控制器
local class_name = "AchievementPersonItem";
local AchievementPersonItem = BaseClass(nil, class_name);

---@type AchievementData
AchievementPersonItem.Data = nil

function AchievementPersonItem:OnInit()
    self.MsgList = 
    {
		{Model = AchievementModel, MsgName = AchievementModel.ACHIEVE_PLAYER_DATA_UPDATE, Func = Bind(self, self.OnAchievementUpdate)},
    }

    self.BindNodes = 
    {
		
    }

    if self.View.BtnClickPopTip then
        table.insert(self.BindNodes, { UDelegate = self.View.BtnClickPopTip.OnClicked,				Func = Bind(self,self.OnClickTipPop) })
    end

    self.Model = MvcEntry:GetModel(AchievementModel)
    self.Data = nil
end

function AchievementPersonItem:OnShow(Param)
    self:UpdateUI(Param)
end

function AchievementPersonItem:OnHide()
    self.Data = nil
end

function AchievementPersonItem:UpdateUI(Param)
    self.Param = Param
    self.Data = self.Model:GetPlayerData(Param.AhicId,Param.PlayerId)
    self.View.GUIImageIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    if not self.Data then --此前有个报错，但目前无法复现出，先做个保护写下日志，下次复现继续排查
        print_r(self.Model.PlayerDataComplete, "AchievementPersonItem:UpdateUI===>self.Model:GetPlayerData is nil, need to check!!")
        print_r(Param, "AchievementPersonItem:UpdateUI===>Param informations!!")
        return
    end
    if self.View.GUITextBlock_Name then
        self.View.GUITextBlock_Name:SetVisibility(Param.NeedHideName and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.GUITextBlock_Name:SetText(StringUtil.FormatText(self.Data:GetName()))
    end
    if self.View.GUITextBlock_Count then
        self.View.GUITextBlock_Count:SetVisibility(self.Data.Count > 1 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        self.View.GUITextBlock_Count:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_7"),self.Data.Count))
    end
    if self.View.GUITextBlock_Level then
        self.View.GUITextBlock_Level:SetText("") --self.Data:GetCurQualityCap()
        --CommonUtil.SetTextColorFromQuality(self.View.GUITextBlock_Level,self.Data.Quality)
    end

    if Param.IsNeedReadSmallIcon then --IsNeedReadSmallIcon:是否走高清小图
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageIcon,self.Data:GetSmallIcon())
    else
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageIcon,self.Data:GetIcon())
    end
    self.View.GUIImageIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function AchievementPersonItem:OnCicked()
    local ViewOpenData = {
        Id = self.Data.ID,
    }
    MvcEntry:OpenView(ViewConst.AchievementTip, ViewOpenData)
end

function AchievementPersonItem:OnAchievementUpdate(PlayerId)
    if not self.Param then
        return
    end
    if self.Param.PlayerId ~= PlayerId then
        return
    end
    self:UpdateUI(self.Param)
end

function AchievementPersonItem:OnClickTipPop()
    if not self.Data then
        CError("AchievementPersonItem:OnClickTipPop===>self.Data is nil")
        return
    end
    local ViewOpenData = {
        Id = self.Data.ID,
        InNeedShowBtn = false
    }
    MvcEntry:OpenView(ViewConst.AchievementTip, ViewOpenData)
end

return AchievementPersonItem
