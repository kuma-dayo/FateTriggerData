---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 模式选择中，玩法模式列表物品
--- Created At: 2023/07/18 16:06
--- Created By: 朝文
---

local class_name = "MatchModeSelectPlayModeItem"
---@class MatchModeSelectPlayModeItem
local MatchModeSelectPlayModeItem = BaseClass(nil, class_name)
MatchModeSelectPlayModeItem.Const = {
    Default_SelectScale           = 1.15,
}

function MatchModeSelectPlayModeItem:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.Button_ClickArea.OnClicked,	        Func = Bind(self, self.OnButtonClicked_ClickArea) },
        { UDelegate = self.View.Button_ClickArea.OnHovered,	        Func = Bind(self, self.OnButtonOnHovered_ClickArea) },
        { UDelegate = self.View.Button_ClickArea.OnUnhovered,       Func = Bind(self, self.OnButtonUnhovered_ClickArea) },
    }

    

    self.MsgList = {
        {Model = MatchModeSelectModel,  MsgName = MatchModeSelectModel.ON_MATCH_MODE_MANUAL_SELECT,   Func = Bind(self, self.ON_MATCH_MODE_MANUAL_SELECT)},
    }
end

function MatchModeSelectPlayModeItem:OnShow(Param)
    -- self.View:SetRenderScale(UE.FVector2D(1,1))
    -- self.View.Hover_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
    
end

function MatchModeSelectPlayModeItem:OnHide()
    if self.CountDownTimer then
        Timer.RemoveTimer(self.CountDownTimer)
        self.CountDownTimer = nil
    end
end

--[[
Param = {
    PlayModeId      = 1,
    DescText        = "",
    ClickCallback   = function() end    
}
--]]
function MatchModeSelectPlayModeItem:SetData(Param)
    self.Data = Param
    -- 绑定红点
    self:RegisterRedDot()
end

function MatchModeSelectPlayModeItem:UpdateView()
    if self.CountDownTimer then
        Timer.RemoveTimer(self.CountDownTimer)
        self.CountDownTimer = nil
    end
    
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local CurSelectPlayModeId = MatchModel:GetPlayModeId()
    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local PlayModeId = self.Data.PlayModeId
    
    --名字
    local PlayModeName = MatchModeSelectModel:GetPlayModeCfg_PlayModeName(PlayModeId)
    self.View.Text_PlayModeName:SetText(StringUtil.Format(PlayModeName))

    --图片
    local previewImg = MatchModeSelectModel:GetPlayModeCfg_SmallPreviewImgPath(PlayModeId)
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Img_LevelPreview, previewImg)
    
    --描述
    local availableLevelId = MatchModeSelectModel:GetPlayModeCfg_Extra_CurAvailableGameLevelId(PlayModeId) or 0
    local availableSceneId = MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(availableLevelId) or 0
    local availableSceneName = MatchModeSelectModel:GetSceneEntryCfg_SceneName(availableSceneId) or ""
    self.View.Text_Name:SetText(StringUtil.Format(availableSceneName))

    --时间
    local isOpen = MatchModeSelectModel:GetPlayModeCfg_IsOpen(PlayModeId)
    local startTime = MatchModeSelectModel:GetPlayModeCfg_StartTime(PlayModeId) or -1
    local endTime = MatchModeSelectModel:GetPlayModeCfg_EndTime(PlayModeId) or -1
    --这里说明是永久开放的
    if startTime == 0 and endTime == 0 and isOpen then
        if CurSelectPlayModeId == PlayModeId then
            self:SwitchState_Choose()
        else
            self:SwitchState_Unlock()
        end
        
        --隐藏倒计时相关控件
        self.View.Canvas_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.ScaleBox_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Text_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        local curTimeStamp = GetTimestamp()
        self.View.Text_Time:SetText("")
        --入口开启了且再时间限制内
        if startTime <= curTimeStamp and curTimeStamp <= endTime and isOpen then
            if CurSelectPlayModeId == PlayModeId then
                self:SwitchState_Choose()
            else
                self:SwitchState_Unlock()
            end

            --显示倒计时相关控件
            self.View.Canvas_Time:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.ScaleBox_Time:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.Text_Time:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

            local function _UpdateTIme()
                local _timeStamp = GetTimestamp()
                local dif = endTime - _timeStamp
                local timeStr = TimeUtils.GetTimeString_CountDownStyle(dif)
                self.View.Text_Time:SetText(timeStr)
                return dif
            end

            --显示倒计时相关控件，并初始化显示文字
            _UpdateTIme()            
            self.CountDownTimer = Timer.InsertTimer(1, function()
                local dif = _UpdateTIme()
                if dif == 0 then
                    --这里应该触发一个刷新事件                    
                end
            end, true)
            
        --未开启
        else
            self:SwitchState_Lock()

            --隐藏倒计时相关控件
            self.View.Canvas_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.ScaleBox_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.View.Text_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
        end 
    end
end

--region SelectLevel
function MatchModeSelectPlayModeItem:OnButtonClicked_ClickArea()
    if self.Data and self.Data.ClickCallback then
        self.Data.ClickCallback()
        -- 红点点击触发
        self:InteractRedDot()
    end
end
function MatchModeSelectPlayModeItem:ON_MATCH_MODE_MANUAL_SELECT(_, Id)
    if self.Data and self.Data.PlayModeId == Id then
        self:OnButtonClicked_ClickArea()
    end
end

function MatchModeSelectPlayModeItem:OnButtonOnHovered_ClickArea()
   if self._isSelect then return end

    --放大
    -- self.View:SetRenderScale(UE.FVector2D(MatchModeSelectPlayModeItem.Const.Default_SelectScale, MatchModeSelectPlayModeItem.Const.Default_SelectScale))

    --变色
    -- self.View.Hover_Frame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- if self._isLock then
    --     self.View.Hover_Frame:SetColorAndOpacity(self.View.HoverColor_Lock)
    -- else
    --     self.View.Hover_Frame:SetColorAndOpacity(self.View.HoverColor_Normol)
    -- end

    local EventName = self._isLock and "VXE_Btn_LockHover" or "VXE_Btn_Hover"
    if self.View[EventName] then
        self.View[EventName](self.View)  
    end
end

function MatchModeSelectPlayModeItem:OnButtonUnhovered_ClickArea()
    -- self.View:SetRenderScale(UE.FVector2D(1,1))
    -- self.View.Hover_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
    local EventName = self._isLock and "VXE_Btn_LockUnHover" or "VXE_Btn_UnHover"
    if self.View[EventName] then
        self.View[EventName](self.View)  
    end
end
--endregion SelectLevel

function MatchModeSelectPlayModeItem:SwitchState_Select()
    self._isSelect = true

    --选中背景光
    -- self.View.WidgetSwitcher_BGSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)   

    local EventName = self._isLock and "VXE_Btn_LockSelect" or "VXE_Btn_Select"
    if self.View[EventName] then
        self.View[EventName](self.View)  
    end
    -- if self._isLock then
        -- self.View.WidgetSwitcher_BGSelect:SetActiveWidgetIndex(1)
        -- self.View.WidgetSwitcher_LineState:SetActiveWidgetIndex(1)
    -- else
        -- self.View.WidgetSwitcher_BGSelect:SetActiveWidgetIndex(0)
        -- self.View.WidgetSwitcher_LineState:SetActiveWidgetIndex(0)
    -- end
    
    --选中之后触发unhover
    -- self.View:SetRenderScale(UE.FVector2D(1,1))
    -- self.View.Hover_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function MatchModeSelectPlayModeItem:SwitchState_Unselect()
    self._isSelect = false

    -- self.View.WidgetSwitcher_LineState:SetActiveWidgetIndex(1)
    
    local EventName = self._isLock and "VXE_Btn_LockNormal" or "VXE_Btn_Normal"
    if self.View[EventName] then
        self.View[EventName](self.View)  
    end
    
    --选中背景光
    -- self.View.WidgetSwitcher_BGSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function MatchModeSelectPlayModeItem:SwitchState_Unlock()
    self._isLock = false

    local EventName = "VXE_Btn_Normal"
    if self.View[EventName] then
        self.View[EventName](self.View)  
    end
    --右上角图标
    -- self.View.WidgetSwitcher_IconState:SetActiveWidgetIndex(0)
end

function MatchModeSelectPlayModeItem:SwitchState_Choose()
    self._isSelect = true

    local EventName = self._isLock and "VXE_Btn_LockSelect" or "VXE_Btn_Select"
    if self.View[EventName] then
        self.View[EventName](self.View)  
    end
    --右上角图标
    -- self.View.WidgetSwitcher_IconState:SetActiveWidgetIndex(2)
end

function MatchModeSelectPlayModeItem:SwitchState_Lock()
    self._isLock = true

    local EventName = "VXE_Btn_LockNormal"
    if self.View[EventName] then
        self.View[EventName](self.View)  
    end
    --右上角图标
    -- self.View.WidgetSwitcher_IconState:SetActiveWidgetIndex(1)
end

-- 绑定红点
function MatchModeSelectPlayModeItem:RegisterRedDot()
    if self.Data and self.Data.PlayModeId then
        self.View.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local RedDotKey = "Level_"
        local RedDotSuffix = self.Data.PlayModeId
        if not self.ItemRedDot then
            self.ItemRedDot = UIHandler.New(self, self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        else 
            self.ItemRedDot:ChangeKey(RedDotKey, RedDotSuffix)
        end  
    end
end

-- 红点触发逻辑
function MatchModeSelectPlayModeItem:InteractRedDot()
    if self.ItemRedDot then
        self.ItemRedDot:Interact()
    end
end

return MatchModeSelectPlayModeItem
