

require "UnLua"

local SettingDetail = Class("Common.Framework.UserWidget")

function SettingDetail:OnInit()
    print("SettingDetail:OnInit")
    self.PlatformName = UE.UGameplayStatics.GetPlatformName()
    self.BindNodes ={
        { UDelegate = self.Button_State.OnHovered, Func = self.OnStateHovered },
        { UDelegate = self.Button_State.OnUnhovered, Func = self.OnStateUnHovered },
        { UDelegate = self.Button_State.OnClicked, Func = self.OnPlayButtonClicked },
        {UDelegate = self.MediaPlayer.OnMediaOpened,Func =self.OnMediaOpenedFunc},
        {UDelegate = self.MediaPlayer.OnSeekCompleted,Func = self.OnSeekCompletedFunc},
        {UDelegate = self.MediaPlayer.OnMediaOpenFailed,Func = self.OnMediaOpenFailedFunc},
        {UDelegate = self.MediaPlayer.OnPlaybackResumed,Func = self.OnPlaybackResumedFunc},
        {UDelegate = self.MediaPlayer.OnPlaybackSuspended,Func = self.OnPlaybackSuspendedFunc},
        {UDelegate = self.SliderMedia_Normal.OnControllerCaptureBegin,Func = self.OnControllerCaptureBeginFunc},
        {UDelegate = self.SliderMedia_Normal.OnControllerCaptureEnd,Func = self.OnControllerCaptureEndFunc},
        {UDelegate = self.SliderMedia_Normal.OnMouseCaptureBegin,Func = self.OnMouseCaptureBeginFunc},
        {UDelegate = self.SliderMedia_Normal.OnMouseCaptureEnd,Func =self.OnMouseCaptureEndFunc}
    }
    -- if self.PlatformName == "Windows" then
    --     --FOR WINDOWS
    --     table.insert(self.BindNodes,{UDelegate = self.SliderMedia_Normal.OnMouseCaptureBegin,Func = self,self.OnMouseCaptureBeginFunc})
    --     table.insert(self.BindNodes,{UDelegate = self.SliderMedia_Normal.OnMouseCaptureEnd,Func = self,self.OnMouseCaptureEndFunc})
    -- else
    --     --FOR MOBILE
    --     table.insert(self.BindNodes,{UDelegate = self.SliderMedia_Normal.OnControllerCaptureBegin,Func = self,self.OnControllerCaptureBeginFunc})
    --     table.insert(self.BindNodes,{UDelegate = self.SliderMedia_Normal.SliderMedia.OnControllerCaptureEnd,Func = self,self.OnControllerCaptureEndFunc})
    -- end

    MsgHelper:OpDelegateList(self, self.BindNodes, true)
    self.DetailClass = nil
    self.ButtonClicked = false
    self.Rate = 0.066667
    UserWidget.OnInit(self)
end

function SettingDetail:OnDestroy()
    self.MediaPlayer:Close()
    UserWidget.OnDestroy(self)
end


function SettingDetail:OnShow(InContext)
    
end


function SettingDetail:OnClose(bDestroy)
    --print("SettingDetail:OnClose")
    self.MediaPlayer:Close()
end


function SettingDetail:OnInitialize(InTag,InGenericBlackboard,IsShow,IsShowTitle)
    print("SettingDetail:OnInitialize",InTag.TagName)
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.ParentTag = InTag
    local SettingSubSystem  = UE.UGenericSettingSubsystem.Get(self)
    local InSettingDetailData = SettingSubSystem:GetSettingDetailDataByItemTagName(InTag.TagName)
    if IsShowTitle == false then
        self.Text_Title:SetText("")
    else
        self.Text_Title:SetText(InSettingDetailData.DetailTitle)
    end
    self.RichText:SetText(InSettingDetailData.RichTextContent)
    --先默认开启显示图片或者视频
    self.PicOrMediaSwitcher:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if InSettingDetailData.IsPicture == true then
        self.PicOrMediaSwitcher:SetActiveWidgetIndex(1)
       self:InitPic(InSettingDetailData.PicTextureObj)
       
    else
        self.PicOrMediaSwitcher:SetActiveWidgetIndex(0)
        --self:InitVideo(InSettingDetailData.MediaUrl)
        self:InitVideo(tostring(InSettingDetailData.MediaSource))
        print("SettingDetail:OnInitialize MediaSource",tostring(InSettingDetailData.MediaSource))
       
    end
    self:RemoveTickHandler()
    local DetailSubWidgetClass = nil
    if InSettingDetailData.DetailWidgetPtr == nil then
        DetailSubWidgetClass = SettingSubSystem:GetDetailByItemTagName(InTag.TagName)
    else 
        DetailSubWidgetClass = InSettingDetailData.DetailWidgetPtr 
    end
     
    local DetailSubWidgetClassName = UE.UKismetSystemLibrary.GetClassDisplayName(DetailSubWidgetClass)
    --print("SettingDetail:OnInitialize DetailSubWidgetClass",InTag.TagName,DetailSubWidgetClassName,"selfDetailClass",self.DetailClass)
    if DetailSubWidgetClass and self.DetailClass~= DetailSubWidgetClassName then
        local DetailSubWidget = UE.UGUIUserWidget.Create(self.LocalPC, DetailSubWidgetClass, self.LocalPC)
        if DetailSubWidget then
            self.DetailItemPanel:AddChild(DetailSubWidget)
            self.DetailClass = DetailSubWidgetClassName
            --print("SettingDetail:OnInitialize DetailSubWidgetClass DetailSubWidget",InTag.TagName,DetailSubWidget)
            DetailSubWidget:OnInitialize(InTag,InGenericBlackboard,IsShow)    
        end
    elseif self.DetailClass == DetailSubWidgetClassName and self.DetailClass then
        local DetailSubWidget = self.DetailItemPanel:GetChildAt(0)
        DetailSubWidget:OnInitialize(InTag,InGenericBlackboard,IsShow)
    else
        self.DetailItemPanel:ClearChildren()
        self.DetailClass =nil
    end
    
    --self:InitVideo(nil)
end

function SettingDetail:GenerateDetailWidget()
    
end

function SettingDetail:InitVideo(InMediaUrl)
    print("SettingDetail:InitVideo",InMediaUrl)
    if InMediaUrl =="" then
        self.PicOrMediaSwitcher:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    local MediaSource = LoadObject(InMediaUrl)
    --self.MediaPlayer:Close()
    local isSuccess = self.MediaPlayer:OpenSource(MediaSource)
    --适合用于网络的？
    --local isSuccess = self.MediaPlayer:OpenUrl(InMediaUrl)
    if isSuccess == true then
        self.Button_StateSwitcher:SetActiveWidgetIndex(1)
        self.WidgetSwitcher_Progress:SetActiveWidgetIndex(0)
        self:SetSliderValue(0)
        self.SliderCapture = false
    else
        self.PicOrMediaSwitcher:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function SettingDetail:InitPic(InPicTextureObj)
    print("SettingDetail:InitPic",InPicTextureObj)
   if UE.UKismetSystemLibrary.IsValidSoftObjectReference(InPicTextureObj) then
        
        self.PicShow:SetBrushFromSoftTexture(InPicTextureObj)
    else
        self.PicOrMediaSwitcher:SetVisibility(UE.ESlateVisibility.Collapsed)
   end
end

------------视频滑条相关----------------------
function SettingDetail:SetSliderValue(InValue)
    self.SliderMedia_Normal:SetValue(InValue)
end

--[[
    是否允许玩家进行操作
]]
function SettingDetail:IsUserActionAllowed()
    
    if self.IsSeeking == true then
        return false
    end
    if self.SliderCapture == true then
        return false
    end
    if self.CacheSeekTimer then
        return false
    end
    return true
end


function SettingDetail:TickEvent()
    if not self.MediaPlayer:IsPlaying() then
        return
    end
    if not self:IsUserActionAllowed() then
        return
    end
    local CTime = self.MediaPlayer:GetTime()
    local Duration = self.MediaPlayer:GetDuration()
    local Seconds = UE.UKismetMathLibrary.GetTotalSeconds(CTime)
    local SecondsTotal = UE.UKismetMathLibrary.GetTotalSeconds(Duration)
    local Rate = Seconds/SecondsTotal
    Rate = math.min(Rate,1)
    self:SetSliderValue(Rate)
    print("SettingDetail:TickEvent Rate",Rate)

end

function SettingDetail:CacheSeekTimerCheck()
    if not self.CacheSeek then
        self:StopSeekCheckTimer()
        return
    end
    if self.IsSeeking then
        return
    end
    local CTime = self.MediaPlayer:GetTime()
    local Seconds = UE.UKismetMathLibrary.GetTotalSeconds(CTime)
    print("SettingDetail:CacheSeekTimerCheck NowVideoTime",Seconds,"TargetTime",self.CacheSeek.SecondsTotalTarget)
    if math.abs(Seconds - self.CacheSeek.SecondsTotalTarget) <= 0.5 then
        self:StopSeekCheckTimer()
        self.CacheSeek = nil
        self.Panel_Loading:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WidgetSwitcher_Progress:SetActiveWidgetIndex(0)
       
        if self.ButtonClicked == false then
            self.MediaPlayer:Play()
        end
        
    else
        print("SettingDetail:CacheSeekTimerCheckSeek Faild Try Again")
        self.IsSeeking = true
        self.MediaPlayer:Seek(self.CacheSeek.TargetValue)
    end
    
end

function SettingDetail:OnMediaOpenedFunc()
    print("SettingDetail:OnMediaOpenedFunc")
    -- self:RemoveTickHandler()
    -- self.TickHandler = Timer.InsertTimer(0,function (deltaTime)
    --     self:TickEvent(deltaTime)
    -- end,true)

    self.HoldTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TickEvent}, self.Rate, true, 0, 0)
end

function SettingDetail:RemoveTickHandler()
    if  self.HoldTimer then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.HoldTimer)
        self.HoldTimer = nil
    end
    if  self.DelayTimer then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.DelayTimer)
        self.DelayTimer = nil
    end
end

function SettingDetail:StopSeekCheckTimer()
    if self.CacheSeekTimer then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.CacheSeekTimer)
        self.CacheSeekTimer = nil
    end
end

function SettingDetail:OnSeekCompletedFunc()
    print("SettingDetail:OnSeekCompletedFunc")
    self.DelayTimer = Timer.InsertTimer(0.5,function ()
        self.IsSeeking = false
        Timer.RemoveTimer(self.DelayTimer)
        self.DelayTimer = nil
     end)
     
    
   
    --self:TickEvent()
    --self.WidgetSwitcher_Progress:SetActiveWidgetIndex(0)
end

function SettingDetail:OnMediaOpenFailedFunc()
    print("SettingDetail:OnMediaOpenFailed")
end



function SettingDetail:OnMouseCaptureBeginFunc()
    print("SettingDetail:OnMouseCaptureBeginFunc")
    self:OnCaptureBeginFunc()
end

function SettingDetail:OnMouseCaptureEndFunc()
    print("SettingDetail:OnMouseCaptureEndFunc")
    self:OnCaptureEndFunc()
end

function SettingDetail:OnControllerCaptureBeginFunc()
    print("SettingDetail:OnControllerCaptureBeginFunc")
    self:OnCaptureBeginFunc()
end

function SettingDetail:OnControllerCaptureEndFunc()
    print("SettingDetail:OnControllerCaptureEndFunc")
    self:OnCaptureEndFunc()
end

function SettingDetail:OnCaptureBeginFunc()
    self.SliderCapture = true
end

function SettingDetail:OnCaptureEndFunc()
    self.SliderCapture = false
    self.IsSeeking = true
    local Value = self.SliderMedia_Normal:GetValue()
    self.SliderMedia_Stop:SetValue(Value)
    self.Panel_Loading:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WidgetSwitcher_Progress:SetActiveWidgetIndex(1)
    print("SettingDetail:OnCaptureEndFunc Value ",Value)
    
    if self.MediaPlayer:IsPlaying() then
        self.MediaPlayer:Pause()
        
    end
    
    local Duration = self.MediaPlayer:GetDuration()
    local SecondsTotal = UE.UKismetMathLibrary.GetTotalSeconds(Duration)
    
    local TargetValue = UE.UKismetMathLibrary.Multiply_TimespanFloat(Duration,Value)
    local SecondsTotalTarget = UE.UKismetMathLibrary.GetTotalSeconds(TargetValue)
    
    
    local bIsSeek = self.MediaPlayer:Seek(TargetValue)
    print("OnValueChangedSlider:SecondsTotalTarget",SecondsTotalTarget,"SecondsTotal",SecondsTotal,"bIsSeek",bIsSeek)
   
    self.CacheSeek = {}
    self.CacheSeek.TargetValue = TargetValue
    self.CacheSeek.SecondsTotalTarget = SecondsTotalTarget
    self.CacheSeekTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.CacheSeekTimerCheck}, 0.3, true, 0, 0)
    
end

function SettingDetail:OnPlaybackResumedFunc()
    --print("SettingDetail:OnPlaybackResumedFunc")
    
end

function SettingDetail:OnPlaybackSuspendedFunc()
    --print("SettingDetail:OnPlaybackSuspendedFunc")
end

---------------------滑条结束分界线-----------------

function SettingDetail:OnStateHovered()
    --print("SettingDetail:OnStateHovered")
    self.State:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Panel_Stopping:SetVisibility(UE.ESlateVisibility.Collapsed)
    
end

function SettingDetail:OnStateUnHovered()
   --print("SettingDetail:OnStateUnHovered")
    self.State:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.ButtonClicked ==true then
        self.Panel_Stopping:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
   
end

function SettingDetail:OnPlayButtonClicked()
    if self.ButtonClicked == false then
        if self.MediaPlayer:IsReady() then
            self.MediaPlayer:Pause()
            self.Button_StateSwitcher:SetActiveWidgetIndex(0)
        end
        self.Panel_Stopping:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        if self.MediaPlayer:IsReady() then
            self.MediaPlayer:Play()
            self.Button_StateSwitcher:SetActiveWidgetIndex(1)
        end
        
    end
    self.ButtonClicked = not self.ButtonClicked
    
end


return SettingDetail