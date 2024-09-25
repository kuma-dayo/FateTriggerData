require "UnLua"

local Setting = Class("Common.Framework.UserWidget")

function Setting:Initialize(Initializer)
end

function Setting:OnInit()
    -- 注册消息监听
	self.MsgList = {
		{ MsgName = GameDefine.Msg.SETTING_Show,            Func = self.OnSettingShow,      bCppMsg = false },
		{ MsgName = GameDefine.Msg.SETTING_Hide,            Func = self.OnSettingHide,      bCppMsg = false },
    }
    self.BindNodes ={
        { UDelegate = self.GUIButton_Close.OnClicked, Func = self.OnClicked_GUIButton_Close },
    }
    MsgHelper:RegisterList(self, self.MsgList)
    MsgHelper:OpDelegateList(self, self.BindNodes, true)

    UserWidget.OnInit(self)
end

function Setting:OnDestroy()
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

function Setting:OnSettingShow()
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:OnShow()
end

function Setting:OnSettingHide()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function Setting:OnClicked_GUIButton_Close()
    self:OnSettingHide()
end



return Setting