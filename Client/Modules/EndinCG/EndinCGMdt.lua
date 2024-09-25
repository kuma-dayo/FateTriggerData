require("Client.Modules.EndinCG.EndinCGDefine")


--- 端内CG
local class_name = "EndinCGMdt";
EndinCGMdt = EndinCGMdt or BaseClass(GameMediator, class_name);

function EndinCGMdt:__init()
end

function EndinCGMdt:OnShow(data)
    
end

function EndinCGMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    CWaring("EndinCGMdt:OnInit")
    
    self.CurMediaPlayer = self.TargetMediaPlayer
    self.CurMediaTextrue = self.TargetMediaTextrue
    self.CurMediaPlayer.PlayOnOpen = false
    self.CurMediaPlayer:SetLooping(false)
    self.CurVideoScreen = self.Video

    self.BindNodes = {
        -- { UDelegate = self.BP_RichText1.OnHyperlinkHovered,	Func = self.OnHoverKeyText },
        -- { UDelegate = self.BP_RichText2.OnHyperlinkUnhovered, Func = self.OnUnhoverKeyText },

        { UDelegate = self.CurMediaPlayer.OnMediaOpened, Func = Bind(self, self.OnMediaOpenedFunc) },  --在打开媒体源时调用的委托。
        { UDelegate = self.CurMediaPlayer.OnMediaOpenFailed, Func = Bind(self, self.OnMediaOpenFailedFunc) },  --当媒体源打开失败时调用的委托。
        { UDelegate = self.CurMediaPlayer.OnPlaybackResumed, Func = Bind(self, self.OnPlaybackResumedFunc) },  --恢复媒体播放时调用的委托。
        { UDelegate = self.CurMediaPlayer.OnMediaClosed, Func = Bind(self, self.OnMediaClosedFunc) },  --在媒体源关闭时调用的委托。
        { UDelegate = self.CurMediaPlayer.OnEndReached, Func = Bind(self, self.OnEndReachedFunc) },    --在播放到达媒体结束时调用的委托。
        { UDelegate = self.CurMediaPlayer.OnPlaybackSuspended, Func = Bind(self, self.OnPlaybackSuspendedFunc) },  --挂起媒体播放时调用的委托。
        { UDelegate = self.CurMediaPlayer.OnSeekCompleted, Func = Bind(self, self.OnSeekCompletedFunc) },  --当查找操作成功完成时调用的委托。
        { UDelegate = self.CurMediaPlayer.OnTracksChanged, Func = Bind(self, self.OnTracksChangedFunc) },  --当媒体音轨集合更改时调用的委托。
        { UDelegate = self.CurMediaPlayer.OnMetadataChanged, Func = Bind(self, self.OnMetadataChangedFunc) },  --当媒体元数据更改时调用的委托。
	}

    -- self.MsgList = 
    -- {
    -- }

    local BtnParam = {
        OnItemClick = Bind(self, self.OnButtonClicked_Back),
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_EndinCG_Jump_Btn"),--跳过
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    }
    UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips, BtnParam) ---ESC按钮
end

---@param Params CGPlayParam
function M:OnShow(Params)
    CWaring("EndinCGMdt:OnShow")
    self:RefreshEndinCG(Params)
end

---@param Params CGPlayParam
function M:OnRepeatShow(Params)
    CWaring("EndinCGMdt:OnRepeatShow")
	self:RefreshEndinCG(Params)
end

function M:OnHide()
    self:RemoveTickHandler()
    self:RemoveCloseCGHandler()
end

-- function M:OnDestroy()
--     self:RemoveTickHandler()
--     self:RemoveCloseCGHandler()
-- end

---@param EEndMode ECGEndMode
function M:CallFinishedCB_Inner(EEndMode)
    local Param = {EndMode = EEndMode}
    if self.OnCGFinished then
        self:OnCGFinished(Param)
    end
end

---设置视频UI是否可见
function M:SetVisibilityVideo(bShow)
    CWaring("EndinCGMdt:SetVisibilityVideo, bShow = "..tostring(bShow))

    if CommonUtil.IsValid(self.Image_BG) then
        self.Image_BG:SetVisibility(bShow and UE.ESlateVisibility.Hidden or UE.ESlateVisibility.SelfHitTestInvisible)
    end
    if CommonUtil.IsValid(self.CurVideoScreen) then
        -- self.CurVideoScreen:SetVisibility(bShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden)
        if bShow then
            self.CurVideoScreen:SetRenderOpacity(1)
        else
            self.CurVideoScreen:SetRenderOpacity(0)
        end
    end
end

---@param Params CGPlayParam
function M:RefreshEndinCG(Params)
    CWaring("EndinCGMdt:RefreshEndinCG")

    MvcEntry:GetCtrl(EndinCGCtrl):SetMediaSound(self.CurMediaPlayer)

    self:SetVisibilityVideo(false)

    Params = Params or {}
    ---@type CGPlayParam
    self.Params = Params
    self.OnCGFinished = Params.OnCGFinished 
    self.bWaitExitBtn = false
    self.bIsCanSkip = false
    self.bPlaySounded = false
    self.PlaySoundEventName = SoundCfg.Music.MUSIC_CG
    self.StopSoundEventName = SoundCfg.Music.MUSIC_STOP_CG
    
    local ModuleId = Params.ModuleId or 0
    self.CGMoudleId = ModuleId
    local CGCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_CGSettingConfig, Cfg_CGSettingConfig_P.ModuleId, ModuleId)
    if CGCfg == nil then
        self:CloseEndinCG_Inner()
        self:CallFinishedCB_Inner(EndinCGDefine.ECGEndMode.ErrorExit)
        return
    end

    self.bIsCanSkip = CGCfg[Cfg_CGSettingConfig_P.IsCanSkip]

    local CGMoviePath = CGCfg[Cfg_CGSettingConfig_P.CGMovie]
    if string.len(CGMoviePath) <= 0 then
        self:CloseEndinCG_Inner()
        self:CallFinishedCB_Inner(EndinCGDefine.ECGEndMode.ErrorExit)
        return
    end

    self.DelayTime = CGCfg[Cfg_CGSettingConfig_P.DelaySkip]

    self.WidgetSwitcher_0:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.DelayTime > 0 then
        self.bWaitExitBtn = true
        self.WidgetSwitcher_0:SetActiveWidget(self.Panel_Count)
    end

    self:PlayMedia(CGMoviePath)
end

function M:PlayMedia(Path)
    -- self.CurMediaPlayer:Close()

    -- FileMediaSource'/Game/Movies/VehicleSkill/Vehicle01Fly.Vehicle01Fly'
    -- local Path = "FileMediaSource'/Game/Movies/VehicleSkill/Vehicle02Boost.Vehicle02Boost'"
    -- Path = "FileMediaSource'/Game/Movies/Hall/S1_MainHall_Screen_004_Match.S1_MainHall_Screen_004_Match'"
    -- if UE.UGFUnluaHelper.IsEditor() then
    --     Path = "FileMediaSource'/Game/Movies/VehicleSkill/Vehicle02Boost.Vehicle02Boost'"
    -- end
    CWaring(string.format("EndinCGMdt:PlayMedia, Path = %s", tostring(Path)))

    -------------------LoadObject:加载音效
    local PreLoadSoundRes = function()
        local UISoundCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_UISoundTable, Cfg_UISoundTable_P.SoundID, self.PlaySoundEventName)
        if UISoundCfg then
            local SoundEvent = UISoundCfg[Cfg_UISoundTable_P.SoundEvent]
            if SoundEvent then
                CWaring(string.format("EndinCGMdt:PlayMedia, 加载音效1, SoundEvent = [%s]", tostring(SoundEvent)))
                LoadObject(SoundEvent)    
            end
        end

        local UISoundCfg2 = G_ConfigHelper:GetSingleItemByKey(Cfg_UISoundTable, Cfg_UISoundTable_P.SoundID, self.StopSoundEventName)
        if UISoundCfg2 then
            local SoundEvent = UISoundCfg2[Cfg_UISoundTable_P.SoundEvent]
            if SoundEvent then
                CWaring(string.format("EndinCGMdt:PlayMedia, 加载音效2, SoundEvent = [%s]", tostring(SoundEvent)))
                LoadObject(SoundEvent)    
            end
        end
    end
    PreLoadSoundRes()
    -------------------LoadObject:加载音效

    -------------------LoadObject:加载视频
    local MediaSource = LoadObject(Path)
    -------------------LoadObject:加载视频
    if not(CommonUtil.IsValid(MediaSource)) then
        CError(string.format("EndinCGMdt:PlayMedia, MediaSource:IsValid == false !!! Path = %s", tostring(Path)), true)

        self:CloseEndinCG_Inner()
        self:CallFinishedCB_Inner(EndinCGDefine.ECGEndMode.ErrorExit)
        return
    end

    if not(MediaSource:Validate()) then
        --验证视频资源有效性
        CError(string.format("EndinCGMdt:PlayMedia, MediaSource:Verification failure !!! Path = %s", tostring(Path)), true)
        self:CloseEndinCG_Inner()
        self:CallFinishedCB_Inner(EndinCGDefine.ECGEndMode.ErrorExit)
        return
    end

    self.CurMediaTextrue.AutoClear = true
    self.CurMediaPlayer:OpenSource(MediaSource)
end

function M:RemoveTickHandler()
    if self.TickHandler then
        self:RemoveTimer(self.TickHandler)
    end
    self.TickHandler = nil
end

function M:AddTickHandler()
    self:RemoveTickHandler()
    self.TickHandler = self:InsertTimer(Timer.NEXT_TICK, function(deltaTime)
        self:OnTickEvent(deltaTime)
    end, true)
end

function M:OnTickEvent(deltaTime)
    if not(self.CurMediaPlayer:IsPlaying()) then
        return
    end
    -- local CTime = self.CurMediaPlayer:GetTime()
    -- local Duration = self.CurMediaPlayer:GetDuration()
    -- local Seconds = UE.UKismetMathLibrary.GetTotalSeconds(CTime)
    -- local SecondsTotal = UE.UKismetMathLibrary.GetTotalSeconds(Duration)
    -- -- CWaring("Seconds:" .. Seconds)
    -- -- CWaring("SecondsTotal:" .. SecondsTotal)
    -- local Rate = Seconds / SecondsTotal
    -- Rate = math.min(Rate, 1)

    self.DelayTime = self.DelayTime - deltaTime
    if self.bWaitExitBtn then
        self:UpdateText_Count(self.DelayTime)

        if self.DelayTime <= 0 then
            self.bWaitExitBtn = false
            self.WidgetSwitcher_0:SetActiveWidget(self.Common_Bottom_Bar)
        end
    end
end

--- 跟新倒计时
function M:UpdateText_Count(InCount)
    InCount = math.ceil(InCount)
    local describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Loading', "1652"), InCount) -- <span style="4_Medium" size="18" color="#E98844FF">{0}s</>后可跳过
    -- if UE.UGFUnluaHelper.IsEditor() then
    --     -- local CTime = self.CurMediaPlayer:GetTime()
    --     local Duration = self.CurMediaPlayer:GetDuration()
    --     -- local Seconds = UE.UKismetMathLibrary.GetTotalSeconds(CTime)
    --     local SecondsTotal = UE.UKismetMathLibrary.GetTotalSeconds(Duration)
    --     describe = describe .. tostring(SecondsTotal)
    -- end
    self.Text_Count:SetText(describe)
end

-------------------------------------------------------------------------------MediaEvent >>

---在打开媒体源时调用的委托
function M:OnMediaOpenedFunc(_,OpenedUrl)
    CWaring(string.format("EndinCGMdt:OnMediaOpenedFunc, 在打开媒体源时调用的委托 OpenedUrl = %s", tostring(OpenedUrl)))

    local bIsLoop = self.Params.IsLoop or false
    local bAutoPlay = self.Params.AutoPlay
    if bAutoPlay == nil then
        bAutoPlay = true
    end
    bAutoPlay = true
    
    if bAutoPlay then
        self.CurMediaPlayer:Play()

        self.bPlaySounded = true
        CWaring(string.format("EndinCGMdt:OnMediaOpenedFunc, 播放音效, PlaySoundEventName = [%s]", tostring(self.PlaySoundEventName)))
        SoundMgr:PlaySound(self.PlaySoundEventName)

        --定时器强行关闭CG
        self:WaitForceCloseCG()
    end
end

---当媒体源打开失败时调用的委托
function M:OnMediaOpenFailedFunc(_,FailedUrl)
    CError(string.format("EndinCGMdt:OnMediaOpenFailedFunc, 当媒体源打开失败时调用的委托 ModuleId = [%s],FailedUrl=[%s]", tostring(self.Params.ModuleId), tostring(FailedUrl)), true)

    self:CloseEndinCG_Inner()
    self:CallFinishedCB_Inner(EndinCGDefine.ECGEndMode.ErrorExit)
end

---恢复媒体播放时调用的委托。
function M:OnPlaybackResumedFunc()
    CWaring("EndinCGMdt:OnPlaybackResumedFunc, 恢复媒体播放时调用的委托")

    self:SetVisibilityVideo(true)

    if self.bWaitExitBtn then
        self.WidgetSwitcher_0:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WidgetSwitcher_0:SetActiveWidget(self.Panel_Count)
        
        self:UpdateText_Count(self.DelayTime)
    end

    --记录CG播放次数
    MvcEntry:GetModel(EndinCGModel):RecordCGPlayCount(self.CGMoudleId)

    self:AddTickHandler()
end

---在媒体源关闭时调用的委托
function M:OnMediaClosedFunc()
    CWaring("EndinCGMdt:OnMediaClosedFunc, 在媒体源关闭时调用的委托")
    -- self:RemoveTickHandler()
    -- self:RemoveCloseCGHandler()
end

---在播放到达媒体结束时调用的委托
function M:OnEndReachedFunc()
    CWaring("EndinCGMdt:OnEndReachedFunc, 在播放到达媒体结束时调用的委托")
    -- self:RemoveTickHandler()

    self:CloseEndinCG_Inner()
    self:CallFinishedCB_Inner(EndinCGDefine.ECGEndMode.EndOfPlay)
end

---挂起媒体播放时调用的委托。
function M:OnPlaybackSuspendedFunc()
    CWaring("EndinCGMdt:OnPlaybackSuspendedFunc, 挂起媒体播放时调用的委托。")
    -- self:UpdatePlayingShow()
end

---当查找操作成功完成时调用的委托。
function M:OnSeekCompletedFunc()
    CWaring("EndinCGMdt:OnSeekCompletedFunc, 当查找操作成功完成时调用的委托。")
end

---当媒体音轨集合更改时调用的委托
function M:OnTracksChangedFunc()
    CWaring("EndinCGMdt:OnTracksChangedFunc, 当媒体音轨集合更改时调用的委托")
end

---当媒体元数据更改时调用的委托
function M:OnMetadataChangedFunc()
    CWaring("EndinCGMdt:OnMetadataChangedFunc, 当媒体元数据更改时调用的委托")
end

-------------------------------------------------------------------------------MediaEvent <<


function M:CloseEndinCG_Inner()
    CWaring("EndinCGMdt:CloseEndinCG_Inner, 关闭CG")

    if self.bPlaySounded then
        -- SoundMgr:StopPlayAllEffect()
        self.bPlaySounded = false
        CWaring(string.format("EndinCGMdt:CloseEndinCG_Inner, 停止音效, StopSoundEventName = [%s]",tostring(self.StopSoundEventName)))
        SoundMgr:PlaySound(self.StopSoundEventName)
    end
    self.CurMediaPlayer:Close()

    self:RemoveTickHandler()
    self:RemoveCloseCGHandler()

    MvcEntry:GetCtrl(EndinCGCtrl):SetMediaSound(nil)
    MvcEntry:CloseView(ViewConst.EndinCG)
end

function M:OnButtonClicked_Back()
    CWaring("EndinCGMdt:OnButtonClicked_Back, 玩家关闭CG")
  
    self:CloseEndinCG_Inner()

    self:CallFinishedCB_Inner(EndinCGDefine.ECGEndMode.EscExit)
end

---强行关闭CG视频
function M:WaitForceCloseCG()
    -- local CTime = self.CurMediaPlayer:GetTime()
    local Duration = self.CurMediaPlayer:GetDuration()
    -- local Seconds = UE.UKismetMathLibrary.GetTotalSeconds(CTime)
    local SecondsTotal = UE.UKismetMathLibrary.GetTotalSeconds(Duration)
    -- describe = describe .. tostring(SecondsTotal)

    CWaring(string.format("EndinCGMdt:WaitForceCloseCG, Duration = [%s]", tostring(SecondsTotal)))

    self:RemoveCloseCGHandler()
    local DelayTime = SecondsTotal + 1
    -- DelayTime = 20
    self.WaitCloseCGHandler = self:InsertTimer(DelayTime, function()
        CWaring("EndinCGMdt:WaitForceCloseCG, ForceCloseCG !!!")
        self:CloseEndinCG_Inner()
        self:CallFinishedCB_Inner(EndinCGDefine.ECGEndMode.ErrorExit)
    end, false)
end

function M:RemoveCloseCGHandler()
    CWaring(string.format("EndinCGMdt:RemoveCloseCGHandler"))
    if self.WaitCloseCGHandler then
        self:RemoveTimer(self.WaitCloseCGHandler)
    end
    self.WaitCloseCGHandler = nil
end


return M