local GenericProgressTips = Class("Common.Framework.UserWidget")

function GenericProgressTips:OnInit()
    print("ResueProgressTips:OnInit")
    self.Totaltime = 0
    --只有开启客户端自动倒计时的时候才需要这个
    self.Rate = 0.005
    

    UserWidget.OnInit(self)
end


function GenericProgressTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    print("LogTipsManager GenericProgressTips:OnTipsInitialize")
    --使用C++的父类函数，主要是为了节约settext
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    --构建黑板的key,读取黑板里面是否要使用自动进度条，用正计时还是倒计时和进度条的type（向左走还是向右走）
    self.IsUseClientTimer = true
    self.IsUseAddNum = false
    self.IsUseAddProgress = true
    --是否用客户端的自动计时
    local IsUseClientTimerType = UE.FGenericBlackboardKeySelector()
    IsUseClientTimerType.SelectedKeyName ="IsUseClientTimer"
     --第一个返回值是黑板里的value，第二个是是否找得到这个key
    local OutIsUseClientTimerType ,TmpClientTimerlValue =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(TipGenricBlackboard,IsUseClientTimerType)
    print("LogTipsManager GenericProgressTips:OnTipsInitialize OutIsUseClientTimerType TmpClientTimerlValue",OutIsUseClientTimerType,TmpClientTimerlValue)
    --进度条向左还是向右
    local BoolProgressType = UE.FGenericBlackboardKeySelector()  
    BoolProgressType.SelectedKeyName = "IsUseAddProgress"
    local OutBoolProgressType ,TmpProgressTypeValue =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(TipGenricBlackboard,BoolProgressType)
    print("GenericProgressTips:OnTipsInitialize OutBoolProgressType TmpProgressTypeValue",OutBoolProgressType,TmpProgressTypeValue)
    --正计时还是倒计时
    local BoolNumType = UE.FGenericBlackboardKeySelector()  
    BoolNumType.SelectedKeyName = "IsUseAddNum"
    local OutBoolNumType ,TmpNumTypeValue =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(TipGenricBlackboard,BoolNumType)
    print("LogTipsManager GenericProgressTips:OnTipsInitialize OutBoolNumType TmpNumTypeValue",OutBoolNumType,TmpNumTypeValue)

    --判断最新的配置里面是否需要修改使用倒计时（默认是倒计时）
    if TmpNumTypeValue == true then
        self.IsUseAddNum = OutBoolNumType 
    end
    --判断是否使用自动进度条，先判断黑板有没有这个参数，没有的话用默认值（yes)
    if TmpClientTimerlValue == true then
        self.IsUseClientTimer = OutIsUseClientTimerType
    end
    --判断进度条向左走还是右走(默认向右，即yes)
    if TmpProgressTypeValue ==true then
        self.IsUseAddProgress = OutBoolProgressType
    end

    self.Totaltime = NewCountDownTime
    --用于计数当前走过了多少个Rate的时间
    self.CurrentTime = 0

    if self.IsUseClientTimer == true  then
        --self:SetClientTimer()
        if self.IsUseAddProgress == true then
            --self.GUIProgressBar:StartAddProgress(NewCountDownTime)
            --self.GUIProgressBar:SetPercent(0)
            self.ProgressBar_MI:GetDynamicMaterial():SetScalarParameterValue("Progress", 0)
        else 
            --self.GUIProgressBar:StartLessProgress(NewCountDownTime)
            --self.GUIProgressBar:SetPercent(1)
            self.ProgressBar_MI:GetDynamicMaterial():SetScalarParameterValue("Progress", 1)
        end
        if self.IsUseAddNum == true then
            self.TxtNum:SetText(0)
        else
            self.TxtNum:SetText(string.format("%.1f",self.Totaltime))
        end
    else
        self.TxtNum:SetText(NewCountDownTime)
    end
    if self.vx_genericprogresstips_in then self:VXE_HUD_GenericProgressTips_In() end
    --标记进度条是否完成
    self.bFinishProgress = false
end

function GenericProgressTips:UpdateData(Owner,NewCountDownTime,TipGenricBlackboard)
    
    local TxtNumSelector = UE.FGenericBlackboardKeySelector()
    TxtNumSelector.SelectedKeyName ="TxtNum"
    --第一个返回值是黑板里的value，第二个是是否找得到这个key
    local OutTxtNum ,IsFindTxtNum =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,TxtNumSelector)
    print("LogTipsManager GenericProgressTips:UpdateData OutTxtNum IsFindTxtNum",OutTxtNum,IsFindTxtNum)
    if IsFindTxtNum == true then
        self.TxtNum:SetText(OutTxtNum)
    else
        self.TxtNum:SetText(NewCountDownTime)
    end
    if NewCountDownTime<=0 then
        --self.GUIProgressBar:SetPercent(0)
        self.ProgressBar_MI:GetDynamicMaterial():SetScalarParameterValue("Progress", 0)
    end
    if self.IsUseClientTimer == false then
        local NowPersent = 0
        if self.IsUseAddProgress ==true then
             NowPersent = 1-(NewCountDownTime / self.Totaltime)
        else
             NowPersent = NewCountDownTime / self.Totaltime  
        end
        --self.GUIProgressBar:SetPercent(NowPersent)
        self.ProgressBar_MI:GetDynamicMaterial():SetScalarParameterValue("Progress", NowPersent)
    else 
        if NewCountDownTime>0 then
            print("LogTipsManager GenericProgressTips:UpdateData",NewCountDownTime)
            self.CurrentTime = self.Totaltime-NewCountDownTime
        end
    end
end

function GenericProgressTips:SetClientTimer()
   print("LogTipsManager GenericProgressTips:SetClientTimer")
   self.HoldTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateClientProgressBar}, self.Rate, true, 0, 0)
   
   
   
end

function GenericProgressTips:UpdateClientProgressBar()
    if self.CurrentTime > self.Totaltime then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.HoldTimer)
		self.HoldTimer = nil
    end

    self.CurrentTime = self.CurrentTime + self.Rate
    if self.IsUseAddNum ==  true then
        self.TxtNum:SetText(string.format("%.1f",self.CurrentTime))
    else
        self.TxtNum:SetText(string.format("%.1f", (self.Totaltime-self.CurrentTime)))
    end
    
    local NowPersent = 0 
    if self.IsUseAddProgress == true then
        NowPersent = self.CurrentTime / self.Totaltime        
    else
        NowPersent = 1-(self.CurrentTime / self.Totaltime)
    end
    --self.GUIProgressBar:SetPercent(NowPersent)
    print("GenericProgressTips:UpdateClientProgressBar",NowPersent,self)
    self.ProgressBar_MI:GetDynamicMaterial():SetScalarParameterValue("Progress", NowPersent)   
    
end

function GenericProgressTips:Tick(MyGeometry, InDeltaTime)
    if self.IsUseClientTimer == true  then
        self:UpdateClientProgressBarByDeltaTime(InDeltaTime)
    
        
    end
end

function GenericProgressTips:UpdateClientProgressBarByDeltaTime(InDeltaTime)
    if self.CurrentTime >= self.Totaltime then
        return 
    end
    self.CurrentTime = self.CurrentTime + InDeltaTime
    if self.IsUseAddNum ==  true then
        self.TxtNum:SetText(string.format("%.1f",self.CurrentTime))
    else
        self.TxtNum:SetText(string.format("%.1f", math.abs((self.Totaltime-self.CurrentTime))))
    end
    
    local NowPersent = 0 
    if self.IsUseAddProgress == true then
        NowPersent = self.CurrentTime / self.Totaltime        
    else
        NowPersent = 1-(self.CurrentTime / self.Totaltime)
    end

    local LastTime = self.Totaltime - self.CurrentTime
    --根据Min Tick Interval Time设置阈值
    if not self.bFinishProgress and LastTime <= 0.05 and self.vx_genericprogresstips_out then
        print("GenericProgressTips:UpdateClientProgressBarByDeltaTime >> Play Out OutAniamtion >> LastTime", LastTime)
        self.bFinishProgress = true
        self:VXE_HUD_GenericProgressTips_Out() 
    end

    --print("GenericProgressTips:UpdateClientProgressBarByDeltaTime",InDeltaTime,NowPersent,(1/InDeltaTime))
    --self.GUIProgressBar:SetPercent(NowPersent)
    self.ProgressBar_MI:GetDynamicMaterial():SetScalarParameterValue("Progress", NowPersent)
    print("GenericProgressTips:UpdateClientProgressBarByDeltaTime",NowPersent,self.ProgressBar_MI)
end
function GenericProgressTips:OnDestroy()
    print("GenericProgressTips:OnDestroy")
    UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.HoldTimer)
    self.HoldTimer = nil
    UserWidget.OnDestroy(self)
end



return GenericProgressTips
