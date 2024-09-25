--- 视图控制器：社群关注主界面
local class_name = "ActivityCommunity"
local ActivityCommunity = BaseClass(ActivityViewBase, class_name)

function ActivityCommunity:OnInit(Param)
    ActivityCommunity.super.OnInit(self, Param)
    self.BindNodes = {
        {UDelegate = self.View.WBP_CommonBtn_Cir_Small_02.GUIButton_Main.OnClicked, Func = Bind(self, self.OpenHelpClick)},
        {UDelegate = self.View.WBP_Community_Btn.GUIButtonItem.OnClicked, Func = Bind(self, self.OnFirstBtnClick)},
        {UDelegate = self.View.WBP_Community_Btn_1.GUIButtonItem.OnClicked, Func = Bind(self, self.OnSeCondBtnClick)},
    }
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.Data = nil
    self.RewardWidgetList = {}
    local Index = 1
    local MaxLoop = 10

    repeat
        local Widget = self.View["WBP_Community_Item_" .. Index]
        if not Widget then
            break
        end
        Index = Index + 1
        Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        table.insert(self.RewardWidgetList, Widget)
    until Index > MaxLoop
end

function ActivityCommunity:OnShow(Param)
    if not Param or not Param.Id then
        CError("ActivityCommunity:OnShow Param is nil")
        return
    end
    CLog("ActivityCommunity:OnShow ActivityId:"..Param.Id)
    self.ActiveityID = Param.Id
    ---@type ActivityData
    self.Data = self.Model:GetData(Param.Id)
    if not self.Data then
        CError("ActivityCommunity:OnShow ActivityData is nil ActivityId:"..Param.Id)
        return
    end
    ---@type number[]
    self.SubList = self.Data:GetSubItemsByType(Pb_Enum_ACTIVITY_SUB_ITEM_TYPE.ACTIVITY_SUB_ITEM_TYPE_SHARE)
    if not self.SubList or #self.SubList == 0 then
        CError("ActivityCommunity:OnShow SubListis nil")
        return
    end
    --奖励仅显示第一个子项所配奖励
    local SubId = self.SubList[1]
    local SubData = self.Data:GetSubItemById(SubId)
    if not SubData then
        CError("ActivityCommunity:OnShow SubData nil")
        return
    end

    self.View.Text_Title:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self.Data:GetMainTitle()))
    self.View.GUITextDesc:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), self.Data:GetSubTitle()))
    CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImage_Bg,self.Data:GetBigImg())

    local Index = 1
    ---@type ActivityReward[]
    local State = SubData:GetState()
    for i, Reward in ipairs(SubData.Rewards) do
        local Widget = self.RewardWidgetList[i]
        if not Widget then
            break
        end
        Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local Param = {AcId = self.ActiveityID, SubIdList = self.SubList, RewardIndex = i}
        UIHandler.New(self, Widget, require("Client.Modules.Activity.ActivityContent.Community.ActivityCommunitySubItem"), Param)
    end
    self.View.WBP_CommonBtn_Cir_Small_02:SetVisibility(self.Data.HelpID == 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    self:UpdateBtn()
end

function ActivityCommunity:OnHide(Param)
    self.Data = nil
    self.TaskSubIDList = nil
end

function ActivityCommunity:OnManualShow(Param)
end

function ActivityCommunity:OnManualHide(Param)
end

function ActivityCommunity:UpdateBtn()
    local SubId = self.SubList[1]
    local SubData = self.Data:GetSubItemById(SubId)
    if not SubData then
        CError("ActivityCommunity:OnShow SubData nil")
        return
    end
    local IsGot = SubData:IsGot()
    local IsCanGet = SubData:IsCanGet() 
    local BtnStr = ""
    local IsEnabled = true
    local IsFinish = IsCanGet or IsGot
    if IsGot then
        BtnStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_HasGot")
        IsEnabled = false
    elseif IsCanGet then
        BtnStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_CanGet")
    end
    self.View.WBP_Community_Btn:SetBtnIsEnable(IsEnabled)

    self.View.WBP_Community_Btn.Img_Dec:SetVisibility(IsFinish and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.WBP_Community_Btn_1:SetVisibility(IsFinish and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.Panel_Gap:SetVisibility(IsFinish and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.Text1:SetVisibility(IsFinish and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.Text2:SetVisibility(IsFinish and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    if IsFinish then
        self.View.WBP_Community_Btn.Text_StoryTitle:SetText(StringUtil.FormatText(BtnStr))
    end
end


--帮助按钮点击事件
function ActivityCommunity:OpenHelpClick()
    self.Data:OpenHelpSys()
end

--第一个子项按钮点击事件
function ActivityCommunity:OnFirstBtnClick()
    if not self.SubList or #self.SubList == 0 then
        return
    end
    local SubId = self.SubList[1]
    local SubData = self.Data:GetSubItemById(SubId)
    if not SubData then
        return
    end
    local IsGot = SubData:IsGot()
    if IsGot then
        return
    end
    local IsCanJump = true
    --多个按钮其中一个按钮点击前往，即认为所有按钮都完成对应任务,点领取则领取两个按钮所带的奖励
    for i, Id in ipairs(self.SubList) do
        local vo = self.Data:GetSubItemById(Id)
        if vo then
            local IsCanGet = vo:IsCanGet()
            if IsCanGet then
                vo:DoAccept()
                IsCanJump = false
            else
                MvcEntry:GetCtrl(ActivityCtrl):SendProtoPlayerSetActivitySubItemPrizeStateReq(self.ActiveityID, vo.SubItemId)
            end
        end
    end
    if IsCanJump then
        SubData:JumpView() 
    end
end

--第二个子项按钮点击事件
function ActivityCommunity:OnSeCondBtnClick()
    if not self.SubList or #self.SubList < 2 then
        return
    end
    local SubId = self.SubList[2]
    local SubData = self.Data:GetSubItemById(SubId)
    if not SubData then
        return
    end
    local IsGot = SubData:IsGot()
    if IsGot then
        return
    end
    local IsCanJump = true
    --多个按钮其中一个按钮点击前往，即认为所有按钮都完成对应任务,点领取则领取两个按钮所带的奖励
    for i, Id in ipairs(self.SubList) do
        local vo = self.Data:GetSubItemById(Id)
        if vo then
            local IsCanGet = vo:IsCanGet()
            if IsCanGet then
                vo:DoAccept()
                IsCanJump = false
            else
                MvcEntry:GetCtrl(ActivityCtrl):SendProtoPlayerSetActivitySubItemPrizeStateReq(self.ActiveityID, vo.SubItemId)
            end
        end
    end
    if IsCanJump then
        SubData:JumpView() 
    end
end

function ActivityCommunity:OnStateChangedNotify()
    self:UpdateBtn()
end

return ActivityCommunity
