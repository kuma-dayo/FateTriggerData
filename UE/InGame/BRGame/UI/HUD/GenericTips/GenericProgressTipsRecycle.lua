local GenericProgressTipsRecycle = Class("Common.Framework.UserWidget")

function GenericProgressTipsRecycle:OnInit()
    print("GenericProgressTipsRecycle:OnInit")
    self.Totaltime = 0
    self.Rate = 0.005
    UserWidget.OnInit(self)
end

function GenericProgressTipsRecycle:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    print("LogTipsManager GenericProgressTipsRecycle:OnTipsInitialize", NewCountDownTime)
    --使用C++的父类函数，主要是为了节约settext
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    -- 使用默认值 不读取黑板设置
    self.IsUseClientTimer = true
    self.IsUseAddNum = false
    self.IsUseAddProgress = true

    self.Totaltime = NewCountDownTime
    --用于计数当前走过了多少个Rate的时间
    self.CurrentTime = 0
    if self.IsUseClientTimer == true  then
        if self.IsUseAddProgress == true then
            self.Progress:SetPercent(0)
        else 
            self.Progress:SetPercent(1)
        end
        if self.IsUseAddNum == true then
            self.Text_Content:SetText(0)
        else
            self.Text_Content:SetText(string.format("%.1f",self.Totaltime))
        end
    else
        self.Text_Content:SetText(NewCountDownTime)
    end
    if self.vx_genericprogresstips_in then self:VXE_HUD_GenericTips_In() end
    
    self.bFinishProgress = false
end

function GenericProgressTipsRecycle:Tick(MyGeometry, InDeltaTime)
    if self.IsUseClientTimer == true  then
        self:UpdateClientProgressBarByDeltaTime(InDeltaTime)
    end
end

function GenericProgressTipsRecycle:UpdateClientProgressBarByDeltaTime(InDeltaTime)
    if self.CurrentTime >= self.Totaltime then
        return 
    end
    self.CurrentTime = self.CurrentTime + InDeltaTime
    if self.IsUseAddNum ==  true then
        self.Text_Content:SetText(string.format("%.1f",self.CurrentTime))
    else
        self.Text_Content:SetText(string.format("%.1f", math.abs((self.Totaltime-self.CurrentTime))))
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
        print("GenericProgressTipsRecycle:UpdateClientProgressBarByDeltaTime >> Play Out OutAniamtion >> LastTime", LastTime)
        self.bFinishProgress = true
        self:VXE_HUD_GenericTips_Out() 
    end

    self.Progress:SetPercent(NowPersent)
    print("GenericProgressTipsRecycle:UpdateClientProgressBarByDeltaTime", NowPersent)
end

function GenericProgressTipsRecycle:OnClose()
    print("GenericProgressTipsRecycle:OnClose")
    UserWidget.OnDestroy(self)
end

return GenericProgressTipsRecycle
