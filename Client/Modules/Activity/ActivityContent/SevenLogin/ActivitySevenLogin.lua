--- 视图控制器
local class_name = "ActivitySevenLogin"
local ActivitySevenLogin = BaseClass(ActivityViewBase, class_name)

ActivitySevenLogin.SubItemTypeDefine = {
    Login = 1
}

function ActivitySevenLogin:OnInit(Param)
    ActivitySevenLogin.super.OnInit(self, Param)
    self.BindNodes = {
        {UDelegate = self.View.Btn_instructions.OnClicked, Func = Bind(self, self.OpenHelpClick)},
    }
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.Data = nil
end

function ActivitySevenLogin:OnShow(Param)
    if not Param or not Param.Id then
        CError("ActivitySevenLogin:OnShow Param is nil")
        return
    end
    CLog("ActivitySevenLogin:OnShow ActivityId:"..Param.Id)
    ---@type ActivityData
    self.Data = self.Model:GetData(Param.Id)
    if not self.Data then
        CError("ActivitySevenLogin:OnShow ActivityData is nil ActivityId:"..Param.Id)
        return
    end

    self.View.Text_MainTittle:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self.Data:GetMainTitle()))
    self.View.Text_Des:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self.Data:GetSubTitle()))
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_bg,self.Data:GetBigImg())

    local Index = 1
    ---@type number[]
    local SubList = self.Data:GetSubItemsByType(ActivitySevenLogin.SubItemTypeDefine.Login)
    if not SubList then
        CError("ActivitySevenLogin:OnShow SubListis nil")
        return
    end
    for _, SubId in ipairs(SubList) do
        local WeeklyLoginItem = self.View["WBP_WeeklyLogin_Item_".. Index]
        if CommonUtil.IsValid(WeeklyLoginItem) then
            UIHandler.New(self,WeeklyLoginItem,require("Client.Modules.Activity.ActivityContent.SevenLogin.ActivitySevenLoginSubItem"),{Index = Index,AcId = Param.Id, SubId = SubId})
        end
        Index = Index + 1
    end
    self:HandleCountDownTimer()
end

function ActivitySevenLogin:HandleCountDownTimer()
    self:ClearTimer()
    -- self.LeftTime = self.Data:GetLeftTime()
    self.CountDownTimer = Timer.InsertTimer(60,function ()
        self.View.Text_LeftTime:SetText(self.Data:GetLeftTimeStr())
    end, true, "", true)
    -- <span size="32">0</><span size="24">天</><span size="32">00</><span size="24">小时</>
end

function ActivitySevenLogin:ClearTimer()
    Timer.RemoveTimer(self.CountDownTimer)
    self.CountDownTimer = nil
end

function ActivitySevenLogin:OnHide(Param)
    self.Data = nil
    self:ClearTimer()
end

function ActivitySevenLogin:OnManualShow(Param)
    self:HandleCountDownTimer()
end

function ActivitySevenLogin:OnManualHide(Param)
    self:ClearTimer()
end

function ActivitySevenLogin:OpenHelpClick()
    self.Data:OpenHelpSys()
end

function ActivitySevenLogin:OnStateChangedNotify()
    
end
return ActivitySevenLogin
