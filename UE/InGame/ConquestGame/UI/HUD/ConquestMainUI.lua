--
-- 征服模式信息UI
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2023.08.02
--

local ConquestMainUI = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function ConquestMainUI:OnInit()
	print("ConquestMainUI", string.format(">> %s:OnInit, ...", GetObjectName(self)))
   
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    self.BindNodes = {
    }
	self.MsgList = {
        { MsgName = GameDefine.MsgCpp.Statistic_RepDatasPS,	            Func = self.OnUpdateStatistic,             bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.GAMESTATE_GameFlowStateChange,	Func = self.OnGameFlowStateChange,         bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.GMP_Camp_ScoreChanged,	        Func = self.OnCampScoreChanged,            bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.OccupyingPercentChanged,	        Func = self.OnOccupyingPercentChanged,     bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.ZoneOwnerCampIdChanged,	        Func = self.OnZoneOwnerCampIdChanged,      bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.ZoneStateChanged,	                Func = self.OnZoneStateChangedTag,         bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.ZonePlayerChanged,	            Func = self.OnZonePlayerChangedTag,        bCppMsg = true,	WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.OccupyingCampIdChanged,	        Func = self.OnOccupyingCampIdChanged,      bCppMsg = true,	WatchedObject = nil },
        { MsgName = "ConquestMode.BeginTurnMode",	                    Func = self.OnBeginTurnMode,               bCppMsg = true,	WatchedObject = nil },
        { MsgName = "ConquestMode.EndTurnMode",	                        Func = self.OnEndTurnMode,                 bCppMsg = true,	WatchedObject = nil },

    }

    self.CampScore = {}
    self.RootPtr = UE.AGUVGameState.GetGUVObjectRootPtr(self)
    if  self.RootPtr  then
        self.LeftTime  =  self.RootPtr:GetStateTimeByName("Fighting")
    end
    local CountDownTimeFormat = TimeUtils.GetTimeStringColon(self.LeftTime)
    self.Text_Time:SetText(CountDownTimeFormat)
    self.PointsToSettle = 1
    local CampSubsystemConfig = UE.UCampExSubsystem.Get(self):GetCampConfig()
    if CampSubsystemConfig then
        self.PointsToSettle = CampSubsystemConfig.PointsToSettle
    end

    self.UpdateScoreTimer = Timer.InsertTimer(2, function() self:OnUpdateScore() end, true)

	UserWidget.OnInit(self)


end

function ConquestMainUI:OnUpdateScore()
    for CampId, NewScore in pairs(self.CampScore) do
        local percent = NewScore *1.0 / self.PointsToSettle
        --左侧显示己方，右侧显示敌方
        if CampId == self.LocalCampId then
            self.Text_ProgressNum1:SetText(NewScore)
            self.ProgressBar1:SetPercent(percent)
        else
            self.Text_ProgressNum2:SetText(NewScore)
            self.ProgressBar2:SetPercent(percent)
        end
    end
end

function ConquestMainUI:OnDestroy()
    --MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
    if self.CountDownTimer then
        Timer.RemoveTimer(self.CountDownTimer)
        self.CountDownTimer = nil
    end

    if self.UpdateScoreTimer then
        Timer.RemoveTimer(self.UpdateScoreTimer)
        self.UpdateScoreTimer = nil
    end
	UserWidget.OnDestroy(self)
end

function ConquestMainUI:OnShow(param)
    print("ConquestMainUI OnShow")
	self.WBP_ReuseList.OnUpdateItem:Add(self, self.OnUpdateUpStateContentItem)
    self:SetVisibility(UE.ESlateVisibility.Collapsed)

    --断线重连回来直接进入Fighting状态
    self.RootPtr = UE.AGUVGameState.GetGUVObjectRootPtr(self)
    if self.RootPtr then
        if "Fighting" ==  self.RootPtr:GetCurStateName() then
            self:StartCountDown()
        end
    end
end


-------------------------------------------- Function ------------------------------------
function ConquestMainUI:StartCountDown()
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local LocalCharacter = self.LocalPC.Character
    self.LocalCampId = LocalCharacter:GetCampId()
    print("ConquestMainUI", string.format(">> %s:StartCountDown, ...", GetObjectName(LocalCharacter)))

    local ZoneNum = UE.UConquestZoneSubsystem.Get(self):GetConquestZoneDataLength()
    --print("ConquestMainUI length: ",self.ConquestStateDataList:Length())
    self.WBP_ReuseList:Reload(ZoneNum)

    if self.CountDownTimer then
        Timer.RemoveTimer(self.CountDownTimer)
        self.CountDownTimer = nil
    end
    if self.RootPtr then
        self.LeftTime  = self.RootPtr:GetCurStateLeftTime()
    end

    local EndTime = GetTimestamp() + self.LeftTime
    local function _UpdateTime()
        local _timeStamp = GetTimestamp()
        local dif = EndTime - _timeStamp
        local timeStr = TimeUtils.GetTimeStringColon(dif)
        self.Text_Time:SetText(timeStr)
        return dif
    end

    self.CountDownTimer = Timer.InsertTimer(1, function()
        local dif = _UpdateTime()
        if dif <= 0 then
            --倒计时结束停止timer
            if self.CountDownTimer then
                Timer.RemoveTimer(self.CountDownTimer)
                self.CountDownTimer = nil
            end
        end
    end, true)
	
end

-------------------------------------------- Callable ------------------------------------

-- 状态列表元素更新
function ConquestMainUI:OnUpdateUpStateContentItem(Widget, I)
    print("ConquestMainUI:OnUpdateUpStateContentItem:",I)
    local ContentData = UE.UConquestZoneSubsystem.Get(self):GetConquestZoneData(I)
    if not ContentData then
        CWaring("ConquestMainUI:OnUpdateUpStateContentItem GetContentData Error; Index = "..tostring(I))
        return
    end
    Widget:ChangeShowMode(2)
    Widget:SetConquestData(ContentData)
end

function ConquestMainUI:OnGameFlowStateChange(PreStateName, CurStateName)
	print("ConquestMainUI", ">> OnGameFlowStateChange, ", CurStateName)
    if CurStateName == "Fighting" then
        self:StartCountDown()
    end
end

function ConquestMainUI:OnCampScoreChanged(CampId, NewScore)
	print("ConquestMainUI", ">> OnCampScoreChanged campid:", CampId, "  score:",NewScore)
    self.CampScore[CampId] = NewScore
end

function ConquestMainUI:InnerRefreshStateWidget(Zone)
    --更新中间的 状态
    local bFind = false
    for i = 1, Zone.ConquestZoneData.CharacterDataList:Length() do
        local CharacterData = Zone.ConquestZoneData.CharacterDataList:Get(i)
        if CharacterData.CurPawn == self.LocalPC.Character and UE.UConquestZoneSubsystem.IsInConquestZone(Zone,CharacterData) then --CharacterData.CurPawn == self.LocalPC.Character and CharacterData.bInZone then
            bFind = true
            self.BP_ConquestStateWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.BP_ConquestStateWidget:ChangeShowMode(1)
            self.BP_ConquestStateWidget:SetConquestData(Zone.ConquestZoneData)
            break;
        end
    end
    if not bFind then
        self.BP_ConquestStateWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    -- 更新上面的状态
    self.WBP_ReuseList:RefreshOne(Zone.ZoneIndex)
end

function ConquestMainUI:OnOccupyingPercentChanged(Zone, NewPercent)
	print("ConquestMainUI", ">> OnOccupyingPercentChanged Zone:", Zone:GetName(), "  percent:",NewPercent)
    self:InnerRefreshStateWidget(Zone)
end
function ConquestMainUI:OnZoneOwnerCampIdChanged(Zone, CampId)
	print("ConquestMainUI", ">> OnZoneOwnerCampIdChanged Zone:", Zone:GetName(), "  campid:",CampId)
    self:InnerRefreshStateWidget(Zone)
end

function ConquestMainUI:OnZoneStateChangedTag(Zone,NewState)
	print("ConquestMainUI", ">> OnZoneStateChangedTag Zone:", Zone:GetName(), "  State:",NewState)
    self:InnerRefreshStateWidget(Zone)

end
function ConquestMainUI:OnZonePlayerChangedTag(Zone)
	print("ConquestMainUI", ">> OnZonePlayerChangedTag Zone:", Zone:GetName())
    self:InnerRefreshStateWidget(Zone)

end

function ConquestMainUI:OnOccupyingCampIdChanged(Zone,CampId)
	print("ConquestMainUI", ">> OnZonePlayerChangedTag Zone:", Zone:GetName())
    self:InnerRefreshStateWidget(Zone)

end

function ConquestMainUI:OnBeginTurnMode(bSelfTurnMode)
	print("ConquestMainUI", ">> OnBeginTurnMode :", bSelfTurnMode)
    self.Panel_Fight2:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Panel_Fight1:SetVisibility(UE.ESlateVisibility.Collapsed)
    if bSelfTurnMode then
        self.Panel_Fight1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Panel_Fight2:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self:OnUpdateScore()
end

function ConquestMainUI:OnEndTurnMode()
	print("ConquestMainUI", ">> OnEndTurnMode ")
    self.Panel_Fight2:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Panel_Fight1:SetVisibility(UE.ESlateVisibility.Collapsed)
end


return ConquestMainUI
