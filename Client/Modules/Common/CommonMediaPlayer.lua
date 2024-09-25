--[[
    通用的CommonMediaPlayer控件

    通用的UMGMediaPlayer播放器
    支持：
    切换视频
    播放/停止
    进度条功能（拖动，及自动跟随视频进度）

    local Param = {
        --MediaPlayer组件
        MediaPlayer = nil,
        --MediaSource路径
        MediaSourcePath = nil,
        --对应的通用蓝图组件
        WBP_Common_Video
        --是否自动播放 默认为真
        AutoPlay = nil,  
        --是否循环  默认为真
        IsLoop = nil,
        --是否关闭提示
        HideCloseTip,
    }
]]

local class_name = "CommonMediaPlayer"
CommonMediaPlayer = CommonMediaPlayer or BaseClass(nil, class_name)

function CommonMediaPlayer:OnInit()
end

function CommonMediaPlayer:OnShow(Param)
    self.Param = Param
    if self.Param.AutoPlay == nil then
        self.Param.AutoPlay = true
    end
    if self.Param.IsLoop == nil then
        self.Param.IsLoop = true
    end
    self.WBP_Common_Video = self.Param.WBP_Common_Video
    if not self.WBP_Common_Video then
        CError("CommonMediaPlayer Must Give WBP_Common_Video !!",true)
        return
    end
    self.WBP_Common_Video.CloseTipNode:SetVisibility(self.Param.HideCloseTip and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible )

    self.PlatformName = UE.UGameplayStatics.GetPlatformName()
    self.BindNodes = {
        --{UDelegate = self.WBP_Common_Video.SliderMedia.OnValueChanged,Func = Bind(self,self.OnValueChangedSlider)},
        {UDelegate = Param.MediaPlayer.OnMediaOpened,Func = Bind(self,self.OnMediaOpenedFunc)},
        {UDelegate = Param.MediaPlayer.OnSeekCompleted,Func = Bind(self,self.OnSeekCompletedFunc)},
        {UDelegate = Param.MediaPlayer.OnMediaOpenFailed,Func = Bind(self,self.OnMediaOpenFailedFunc)},
        {UDelegate = Param.MediaPlayer.OnPlaybackResumed,Func = Bind(self,self.OnPlaybackResumedFunc)},
        {UDelegate = Param.MediaPlayer.OnPlaybackSuspended,Func = Bind(self,self.OnPlaybackSuspendedFunc)},

        -- ButtonPlay和ButtonPause 按钮废弃, 只由ButtonVideo监听
        -- {UDelegate = Param.ButtonPlay.OnClicked,Func = Bind(self,self.OnButtonPlayClicked)},
        -- {UDelegate = Param.ButtonPause.OnClicked,Func = Bind(self,self.OnButtonPauseClicked)},
        {UDelegate = self.WBP_Common_Video.ButtonVideo.OnClicked,Func = Bind(self,self.OnButtonVideoClicked)},
        {UDelegate = self.WBP_Common_Video.ButtonVideo.OnHovered,Func = Bind(self,self.OnButtonVideoHovered)},
        {UDelegate = self.WBP_Common_Video.ButtonVideo.OnUnhovered,Func = Bind(self,self.OnButtonVideoUnhovered)},
        {UDelegate = self.WBP_Common_Video.ButtonVideo.OnPressed,Func = Bind(self,self.OnButtonVideoPressed)},
        {UDelegate = self.WBP_Common_Video.ButtonVideo.OnReleased,Func = Bind(self,self.OnButtonVideoReleased)},
        {UDelegate = self.WBP_Common_Video.SliderMedia.OnMouseCaptureBegin,Func = Bind(self,self.OnMouseCaptureBeginFunc)},
        {UDelegate = self.WBP_Common_Video.SliderMedia.OnMouseCaptureEnd,Func = Bind(self,self.OnMouseCaptureEndFunc)},
        {UDelegate = self.WBP_Common_Video.SliderMedia.OnControllerCaptureBegin,Func = Bind(self,self.OnControllerCaptureBeginFunc)},
        {UDelegate = self.WBP_Common_Video.SliderMedia.OnControllerCaptureEnd,Func = Bind(self,self.OnControllerCaptureEndFunc)},
    }
    self:ReRegister()

    self:SetMediaSound(Param.MediaPlayer)

    self:UpdateMediaSource(self.Param.MediaSourcePath,self.Param.AutoPlay)
end

function CommonMediaPlayer:SetMediaSound(MediaPlayer)
    ---@type HallSceneMgr
    local HallSceneMgrInst = _G.HallSceneMgrInst
    if HallSceneMgrInst ~= nil then
        HallSceneMgrInst:SetMediaSound(MediaPlayer)
    end
end

function CommonMediaPlayer:OnHide()
    self:SetMediaSound(nil)
    self.Param.MediaPlayer:Close()
    self:StopSeekCheckTimer()
    self:RemoveTickHandler()
end

function CommonMediaPlayer:UpdateData(Param)
    self.Param = Param
    if self.Param.AutoPlay == nil then
        self.Param.AutoPlay = true
    end
    if self.Param.IsLoop == nil then
        self.Param.IsLoop = true
    end
    self:UpdateMediaSource(self.Param.MediaSourcePath,self.Param.AutoPlay)
end

function CommonMediaPlayer:AddTickHandler()
    self:RemoveTickHandler()
    self.TickHandler = Timer.InsertTimer(0,function (deltaTime)
        self:OnTickEvent(deltaTime)
    end,true)
end
function CommonMediaPlayer:RemoveTickHandler()
    if  self.TickHandler then
        Timer.RemoveTimer(self.TickHandler)
        self.TickHandler = nil
    end
    if  self.DelayTimer then
        Timer.RemoveTimer(self.DelayTimer)
        self.DelayTimer = nil
    end
end

function CommonMediaPlayer:UpdateMediaSource(Path,AutoPlay,IsLoop)
    --CError(string.format("CommonMediaPlayer:UpdateMediaSource,Path = [%s], AutoPlay=[%s], IsLoop=[%s]",tostring(Path),tostring(AutoPlay),tostring(IsLoop)))
    -- 切换视频需要重置下操作面板
    self.WBP_Common_Video.Panel_Stopping:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Common_Video.Panel_Loading:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Common_Video.Switcher_Slider:SetActiveWidget(self.WBP_Common_Video.SliderMedia)
    local MediaSource = LoadObject(Path)
    if AutoPlay ~= nil then
        self.Param.AutoPlay = AutoPlay
    end
    if IsLoop ~= nil then
        self.Param.IsLoop = IsLoop
    end
    self.Param.MediaPlayer:Close()
    self:RemoveTickHandler()
    self:StopSeekCheckTimer()
    self.CacheSeek = nil
    self.IsSeeking = false
    self.IsSeekingWhenPlay = false
    self.SliderCapture = false
    self.Param.MediaPlayer:Close()
    self.Param.MediaPlayer:OpenSource(MediaSource)
    self:SetSliderValue(0)
end

function CommonMediaPlayer:OnTickEvent(deltaTime)
    if not self.Param.MediaPlayer:IsPlaying() then
        return
    end
    if not self:IsUserActionAllowed() then
        return
    end
    local CTime = self.Param.MediaPlayer:GetTime()
    local Duration = self.Param.MediaPlayer:GetDuration()
    local Seconds = UE.UKismetMathLibrary.GetTotalSeconds(CTime)
    local SecondsTotal = UE.UKismetMathLibrary.GetTotalSeconds(Duration)
    -- CWaring("Seconds:" .. Seconds)
    -- CWaring("SecondsTotal:" .. SecondsTotal)
    local Rate = Seconds/SecondsTotal
    Rate = math.min(Rate,1)
    self:SetSliderValue(Rate)
end

function CommonMediaPlayer:SetSliderValue(Rate)
    self.IgnoreSliderValueChange = true
    self.WBP_Common_Video.SliderMedia:SetValue(Rate)
    self.IgnoreSliderValueChange = false
end


function CommonMediaPlayer:UpdatePlayingShow()
    local IsPlaying = self.Param.MediaPlayer:IsPlaying()
    self.WBP_Common_Video.ImgPlay:SetVisibility(IsPlaying and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible)
    self.WBP_Common_Video.ImgPause:SetVisibility(IsPlaying and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--[[
    进度条的进度值产生变化回调
]]
function CommonMediaPlayer:OnValueChangedSlider(Handler,Value)
    if self.IgnoreSliderValueChange then
        CWaring("OnValueChangedSlider1:")
        return
    end
    if self.IsSeeking then
        return
    end
    self.IsSeeking = true
    local Duration = self.Param.MediaPlayer:GetDuration()
    local TargetValue = UE.UKismetMathLibrary.Multiply_TimespanFloat(Duration,Value)
    self.Param.MediaPlayer:Seek(TargetValue)
end

--[[
    是否允许玩家进行操作
]]
function CommonMediaPlayer:IsUserActionAllowed()
    if self.IsSeeking then
        return false
    end
    if self.SliderCapture then
        return false
    end
    if self.CacheSeekTimer then
        return false
    end
    return true
end


--[[
    播放视频
]]
function CommonMediaPlayer:OnButtonPlayClicked()
    if not self.Param.MediaPlayer:IsReady() then
        CWaring("OnButtonPlayClicked Fail")
        return
    end
    if not self:IsUserActionAllowed() then
        return
    end
    self.Param.MediaPlayer:Play()
end

--[[
    停止播放
]]
function CommonMediaPlayer:OnButtonPauseClicked()
    if not self.Param.MediaPlayer:IsReady() then
        CWaring("OnButtonPauseClicked Fail")
        return
    end
    if not self:IsUserActionAllowed() then
        return
    end
    self.Param.MediaPlayer:Pause()
end

--[[
    视频区域点击
--]]
function CommonMediaPlayer:OnButtonVideoClicked()
    if not self.Param.MediaPlayer:IsReady() then
        CWaring("OnButtonPauseClicked Fail")
        return
    end
    if not self:IsUserActionAllowed() then
        return
    end
    local IsPlaying = self.Param.MediaPlayer:IsPlaying()
    if IsPlaying then
        self.Param.MediaPlayer:Pause()
    else
        self.Param.MediaPlayer:Play()
    end
end

--[[
    视频区域Hover，出现操作菜单 PanelOperate
]]
function CommonMediaPlayer:OnButtonVideoHovered()
    self.WBP_Common_Video.PanelOperate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WBP_Common_Video.Panel_Stopping:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:UpdatePlayingShow()
end

function CommonMediaPlayer:OnButtonVideoUnhovered()
    self.WBP_Common_Video.PanelOperate:SetVisibility(UE.ESlateVisibility.Collapsed)
    local IsPlaying = self.Param.MediaPlayer:IsPlaying()
    if not IsPlaying then
        self.WBP_Common_Video.Panel_Stopping:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    end
    self:UpdatePlayingShow()
end

function CommonMediaPlayer:OnButtonVideoPressed()
    -- self.WBP_Common_Video.PanelOperate:SetRenderOpacity(0.6)
end
function CommonMediaPlayer:OnButtonVideoReleased()
    -- self.WBP_Common_Video.PanelOperate:SetRenderOpacity(1)
end

function CommonMediaPlayer:OnMediaOpenedFunc()
    CWaring("OnMediaOpenedFunc")
    self.Param.MediaPlayer:SetLooping(self.Param.IsLoop)
    if self.Param.AutoPlay then
        self.Param.MediaPlayer:Play()
    end
    self:AddTickHandler()
end
function CommonMediaPlayer:OnMediaOpenFailedFunc()
    -- CWaring("OnMediaOpenFailedFunc")
end
function CommonMediaPlayer:OnSeekCompletedFunc()
     CWaring("OnSeekCompletedFunc")
     -- 加个延迟再修改标记，避免解码速度慢导致取出的时间一直不满足，导致不停Seek @chenyishui
    self.DelayTimer = Timer.InsertTimer(0.5,function ()
        self.IsSeeking = false
        Timer.RemoveTimer(self.DelayTimer)
        self.DelayTimer = nil
     end)
    -- self.IsSeeking = false
    --self.Param.MediaPlayer:Pause()
end

function CommonMediaPlayer:OnMouseCaptureBeginFunc()
    -- CWaring("OnMouseCaptureBeginFunc")
    self:OnCaptureBeginFunc()
end
function CommonMediaPlayer:OnMouseCaptureEndFunc()
    -- CWaring("OnMouseCaptureEndFunc")
    self:OnCaptureEndFunc()
end
function CommonMediaPlayer:OnControllerCaptureBeginFunc()
    -- CWaring("OnControllerCaptureBeginFunc")
    self:OnCaptureBeginFunc()
end
function CommonMediaPlayer:OnControllerCaptureEndFunc()
    -- CWaring("OnControllerCaptureEndFunc")
    self:OnCaptureEndFunc()
end

function CommonMediaPlayer:OnCaptureBeginFunc()
    self.SliderCapture = true
    --self.Param.MediaPlayer:Pause()
end

function CommonMediaPlayer:OnCaptureEndFunc()
    self.SliderCapture = false

    local Value = self.WBP_Common_Video.SliderMedia:GetValue()
    CWaring("OnValueChangedSlider:" .. Value)
    if Value > 0.95 then
        -- 视频末端有部分有进度条但无实际视频内容，拖到该位置会导致seek失败，直接从头播放 @chenyishui
        Value = 0
    end
    self.IsSeeking = true
    self.IsSeekingWhenPlay = false
    self.WBP_Common_Video.Panel_Loading:SetVisibility(UE.ESlateVisibility.Visible)
    -- 需求 Panel_Loading 出现时，隐藏Panel_Stopping
    self.WBP_Common_Video.Panel_Stopping:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Common_Video.Switcher_Slider:SetActiveWidget(self.WBP_Common_Video.SliderMedia_Stop)
    self.WBP_Common_Video.SliderMedia_Stop:SetValue(Value)
    -- NetLoading.Add(nil, nil, nil, 0)
    if self.Param.MediaPlayer:IsPlaying() then
        self.Param.MediaPlayer:Pause()
        self.IsSeekingWhenPlay = true
    end
    
    local Duration = self.Param.MediaPlayer:GetDuration()
    local SecondsTotal = UE.UKismetMathLibrary.GetTotalSeconds(Duration)
    local TargetValue = UE.UKismetMathLibrary.Multiply_TimespanFloat(Duration,Value)
    local SecondsTotalTarget = UE.UKismetMathLibrary.GetTotalSeconds(TargetValue)
    CWaring(StringUtil.Format("OnValueChangedSlider:{0}/{1}",SecondsTotalTarget,SecondsTotal))
    self.Param.MediaPlayer:Seek(TargetValue)
    
    self.CacheSeek = {}
    self.CacheSeek.TargetValue = TargetValue
    self.CacheSeek.SecondsTotalTarget = SecondsTotalTarget
    
    self:AddSeekCheckTimer()
end

function CommonMediaPlayer:AddSeekCheckTimer()  
    self:StopSeekCheckTimer()
    self.CacheSeekTimer = Timer.InsertTimer(0.2,function()
        self:CacheSeekTimerCheck()
    end,true)
end
function CommonMediaPlayer:StopSeekCheckTimer()
    if self.CacheSeekTimer then
        Timer.RemoveTimer(self.CacheSeekTimer)
        self.CacheSeekTimer = nil
    end
end
function CommonMediaPlayer:CacheSeekTimerCheck()
    if not self.CacheSeek then
        self:StopSeekCheckTimer()
        return
    end
    if self.IsSeeking then
        return
    end
    if self.Param.MediaPlayer:IsBuffering() then
        return
    end
    local CTime = self.Param.MediaPlayer:GetTime()
    local Seconds = UE.UKismetMathLibrary.GetTotalSeconds(CTime)
    --[[
        ElectraPlayer 播放器依赖IsBuffering即可，不需要额外判断时间

        已知wmfmedia IsBuffering不可靠
        其它解码器待观察
    ]]
    if math.abs(Seconds - self.CacheSeek.SecondsTotalTarget) <= 0.5 or self.Param.MediaPlayer:GetPlayerName() == "ElectraPlayer" then
        self:StopSeekCheckTimer()
        self.CacheSeek = nil
        self.WBP_Common_Video.Panel_Loading:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_Common_Video.Switcher_Slider:SetActiveWidget(self.WBP_Common_Video.SliderMedia)
        -- NetLoading.Close()
        if self.IsSeekingWhenPlay then
            self.IsSeekingWhenPlay = false
            self.Param.MediaPlayer:Play()
        else
            -- 恢复 Panel_Stopping 的显示状态
            self.WBP_Common_Video.Panel_Stopping:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        end
    else
        CWaring("Seek Faild Try Again")
        self.IsSeeking = true
        self.Param.MediaPlayer:Seek(self.CacheSeek.TargetValue)
    end
end

function CommonMediaPlayer:OnPlaybackResumedFunc()
    CWaring("OnPlaybackResumedFunc")
    self:UpdatePlayingShow()
end

function CommonMediaPlayer:OnPlaybackSuspendedFunc()
    CWaring("OnPlaybackSuspendedFunc")
    self:UpdatePlayingShow()
end

return CommonMediaPlayer
