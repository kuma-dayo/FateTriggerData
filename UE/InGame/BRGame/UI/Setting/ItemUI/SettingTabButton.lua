require "UnLua"

local SettingTabButton = Class("Common.Framework.UserWidget")

function SettingTabButton:OnInit()
    self.BindNodes ={
        { UDelegate = self.GUIButton.OnClicked, Func = self.RefreshSubContent },
    }
    self.MsgListGMP = {
        { MsgName = "UIEvent.RefreshSubContent", Func = self.OnRefreshSubContent,      bCppMsg = false},
    }
   
    MsgHelper:OpDelegateList(self, self.BindNodes, true)
    MsgHelper:RegisterList(self, self.MsgListGMP)
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    UserWidget.OnInit(self)
end

function SettingTabButton:OnDestroy()
    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, false)
		self.BindNodes = nil
	end

	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end
	

    UserWidget.OnDestroy(self)
end

function SettingTabButton:InitData(InData)
    print("SettingTabButton:InitData",InData)
    self.TextBlock_Bookmark:SetText(InData.ShowText)
    self.LabelSelect:SetText(InData.ShowText)
    self.TabTag = InData.ButtonTabTag
    self.TabTablePath = InData.TabTablePath
    self.IsHideReset = InData.IsHideReset
end


function SettingTabButton:RefreshSubContent()
    print("SettingTabButton:RefreshSubContent",self.TabTag.TagName)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    -- if SettingSubsystem.CanShowConflictTipsTag:Contains(self.TabTag)  then
    --     SettingSubsystem:SetKeyMapConflict(self.TabTag.TagName,true)
    -- end
    --去系统询问当前能不能切
    --因为只有键位设置有这个弹出的需求，后续如果再有这类弹窗需要，请找许欣桐拓展成通用的地
    local IsConflict = SettingSubsystem:IsHasConflictKey()
    --local IsConflict = self:BP_IsHasConflict()
    --print("SettingTabButton:RefreshSubContent IsConflict",IsConflict)
    if IsConflict  == true  then
        MsgHelper:Send(self, "UIEvent.ShowConflictTips",self.TabTag.TagName)
        return 
    end
    
    self.NotifyActiveTab:Broadcast(self.TabTag,self.TabTablePath,self.Index,self.IsHideReset)
    self.WidgetSwitcher:SetActiveWidgetIndex(1)
    if self.ImgLine then self.ImgLine:SetVisibility(UE.ESlateVisibility.Collapsed) end
    self.IsActiviate = true
end

function SettingTabButton:ResetButtonState()
    print("SettingTabButton:ResetButtonState",self.TabTag.TagName)
    self.IsActiviate = false
    self.WidgetSwitcher:SetActiveWidgetIndex(0)
    
    if self.Index ==0 then
        if self.ImgLine then self.ImgLine:SetVisibility(UE.ESlateVisibility.Collapsed) end
    else
        if self.ImgLine then self.ImgLine:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
    end
    
end

-- 鼠标按键移入
function SettingTabButton:OnMouseEnter(InMyGeometry, InMouseEvent)
	print("SettingTabButton OnMouseEnter", GetObjectName(self), InMyGeometry, UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(InMouseEvent).KeyName)
    self:SetTabButtonLineHover(true)
    self.CheckHoverTab:Broadcast(self.Index,true)
end

-- 鼠标按键移出
function SettingTabButton:OnMouseLeave(InMouseEvent)
	print("SettingTabButton OnMouseLeave", GetObjectName(self), InMouseEvent)
   
    self.CheckHoverTab:Broadcast(self.Index,false)
    if self.Index == 0  or self.IsActiviate == true then
        self:SetTabButtonLineHover(true)
    end
end

function SettingTabButton:SetTabButtonLineHover(IsHover)
    print("SettingTabButton:SetTabButtonLineHover",IsHover,self.TabTag.TagName)
    if IsHover ==true then
        if self.ImgLine then self.ImgLine:SetVisibility(UE.ESlateVisibility.Collapsed) end
    else
        if self.ImgLine then self.ImgLine:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
    end
    
end

function SettingTabButton:OnRefreshSubContent(InTagName)
    if self.TabTag.TagName == InTagName then
        self:RefreshSubContent()
    end
end

return SettingTabButton