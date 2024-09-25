--- 视图控制器
local class_name = "ActivityThreeDayLogin"
local ActivityThreeDayLogin = BaseClass(ActivityViewBase, class_name)

ActivityThreeDayLogin.SubItemTypeDefine = {
    Login = 1
}

function ActivityThreeDayLogin:OnInit(Param)
    ActivityThreeDayLogin.super.OnInit(self, Param)
    self.BindNodes = {
        {UDelegate = self.View.WBP_CommonBtn_Cir_Small_02.GUIButton_Main.OnClicked, Func = Bind(self, self.OpenHelpClick)},
    }
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.Data = nil
end

function ActivityThreeDayLogin:OnShow(Param)
    if not Param or not Param.Id then
        CError("ActivityThreeDayLogin:OnShow Param is nil")
        return
    end
    CLog("ActivityThreeDayLogin:OnShow ActivityId:"..Param.Id)
    ---@type ActivityData
    self.Data = self.Model:GetData(Param.Id)
    if not self.Data then
        CError("ActivityThreeDayLogin:OnShow ActivityData is nil ActivityId:"..Param.Id)
        return
    end

    self.View.PanelHelp:SetVisibility(self.Data.HelpID < 1 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

    self.View.Text_Title:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self.Data:GetMainTitle()))
    self.View.GUITextDesc:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self.Data:GetSubTitle()))
    CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImage_Bg,self.Data:GetBigImg())

    local Index = 1
    ---@type number[]
    local SubList = self.Data:GetSubItemsByType(ActivityThreeDayLogin.SubItemTypeDefine.Login)
    if not SubList then
        CError("ActivityThreeDayLogin:OnShow SubListis nil")
        return
    end
    for _, SubId in ipairs(SubList) do
        local WeeklyLoginItem = self.View["WBP_ItemDay".. Index]
        if CommonUtil.IsValid(WeeklyLoginItem) then
            UIHandler.New(self,WeeklyLoginItem,require("Client.Modules.Activity.ActivityContent.ThreeDayLogin.ActivityThreeDayLoginSubItem"),{Index = Index,AcId = Param.Id, SubId = SubId})
        end
        Index = Index + 1
    end
    self:HandleCountDownTimer()
end

function ActivityThreeDayLogin:HandleCountDownTimer()
    self:ClearTimer()
    -- self.LeftTime = self.Data:GetLeftTime()
    self.CountDownTimer = Timer.InsertTimer(60,function ()
        self.View.Text_Time:SetText(self.Data:GetLeftTimeStr())
    end, true, "", true)
    -- <span size="32">0</><span size="24">天</><span size="32">00</><span size="24">小时</>
end

function ActivityThreeDayLogin:ClearTimer()
    Timer.RemoveTimer(self.CountDownTimer)
    self.CountDownTimer = nil
end

function ActivityThreeDayLogin:OnHide(Param)
    self.Data = nil
    self:ClearTimer()
end

function ActivityThreeDayLogin:OnManualShow(Param)
    self:HandleCountDownTimer()
end

function ActivityThreeDayLogin:OnManualHide(Param)
    self:ClearTimer()
end

function ActivityThreeDayLogin:OpenHelpClick()
    self.Data:OpenHelpSys()
end

return ActivityThreeDayLogin
