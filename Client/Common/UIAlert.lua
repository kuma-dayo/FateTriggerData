--[[
    公用提示信息组件
]]
UIAlert = UIAlert or {}
UIAlert.Const = {
    DefaultAutoHideTime = 3,
}

UIAlert.Instance = UIAlert.Instance or nil

---创建提示
---@param Msg string 需要展示的信息文字
---@param AutoHideTime number|nil 自动消失时间，不填默认为3秒
---@param InContext WorldContext 上下文，给局内获取TipsManager用的
function UIAlert.Show(Msg, AutoHideTime,InContext)
    Msg = StringUtil.Format(Msg)
    AutoHideTime = AutoHideTime or UIAlert.Const.DefaultAutoHideTime

    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        local MsgStr = tostring(Msg)
        --没有InContext则调用局外tips
        if InContext then
            local TipsManager =  UE.UTipsManager.GetTipsManager(InContext)
             --没有TipsManager则调用局外tips
            if TipsManager then
                --走局内Tips
                local GenericBlackboard = UE.FGenericBlackboardContainer()
                local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
                BlackboardKeySelector.SelectedKeyName = "TipsMsg"
                UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard, BlackboardKeySelector, MsgStr)
                TipsManager:ShowTipsUIByTipsId("ReportTips",AutoHideTime,GenericBlackboard,nil)
                return
            end
        end
    end

    if not UIAlert.Instance then
        local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(UIAlertUMGPath))
        UIAlert.Instance = NewObject(WidgetClass, GameInstance, nil, "Client.Common.UIAlert")
        UIRoot.AddChildToLayer(UIAlert.Instance,UIRoot.UILayerType.Tips)
    end
    
    UIAlert.Instance:Show(Msg,AutoHideTime)


end

local M = Class()

function M:Construct()
    --临时这么写，有界面打开或者关闭，将Tip进行隐藏
    MvcEntry:GetModel(ViewModel):AddListener(ViewModel.ON_SATE_ACTIVE_CHANGED,self.ON_SATE_CHANGED_Func,self)
    self.BindNodes = 
    {
        { UDelegate = self.OnAnimationFinished_vx_common_tips_out,	Func = self.On_vx_common_tips_out_Finished },
    }
end

function M:Destruct()
    if MvcEntry then
        MvcEntry:GetModel(ViewModel):RemoveListener(ViewModel.ON_SATE_ACTIVE_CHANGED,self.ON_SATE_CHANGED_Func,self)
    end
    UIAlert.Instance = nil
    self:CleanAutoHideTimer()
    self:Release()
end

function M:ON_SATE_CHANGED_Func()
    self:Hide()
end

function M:Show(msg, autoHideTime)
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:ScheduleAutoHide(autoHideTime)

    if self.RitchText_Tip then
        self.RitchText_Tip:SetText(StringUtil.Format(msg))
    end
    self:PlayDynamicEffectOnShow(true)
end

function M:Hide()
    self:CleanAutoHideTimer()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end

--[[
    提示信息 超时 关闭
]]
function M:ScheduleAutoHide(duration)
    self:CleanAutoHideTimer()
    self.AutoHideTimer = Timer.InsertTimer(duration,function()
        self.AutoHideTimer = nil
		self:OnAutoHide()
	end)   
end

function M:OnAutoHide()
    -- self:CleanAutoHideTimer()
    -- self:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:PlayDynamicEffectOnShow(false) --原先退出/隐藏逻辑走动效完成监听On_vx_common_tips_out_Finished
end

function M:CleanAutoHideTimer()
    if self.AutoHideTimer then
        Timer.RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
end

function M:On_vx_common_tips_out_Finished()
    self:CleanAutoHideTimer()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end


--[[
    播放显示退出动效
]]
function M:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_CommonTips_In then
            self:VXE_CommonTips_In()
        end
    else
        if self.VXE_CommonTips_Out then
            self:VXE_CommonTips_Out()
        end
    end
end


return M