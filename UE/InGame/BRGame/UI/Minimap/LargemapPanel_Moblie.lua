--
-- 大地图
--
-- @COMPANY	ByteDance
-- @AUTHOR	曾伟
-- @DATE	2022.10.20
--

local ParentClassName = "InGame.BRGame.UI.Minimap.LargemapPanel"
local LargemapPanel = require(ParentClassName)
local LargemapPanel_Moblie = Class(ParentClassName)


-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Override ------------------------------------

function LargemapPanel_Moblie:OnShow()
	--print("LargemapPanel_Moblie >> OnShow, ", GetObjectName(self))
end

-------------------------------------------- Init/Destroy ------------------------------------


function LargemapPanel_Moblie:OnInit()
	print("LargemapPanel_Moblie >> OnInit, ", GetObjectName(self))
	
	self.BindNodes = {
		{ UDelegate = self.BtnClose.OnClicked,				Func = self.OnClicked_Close },
		{ UDelegate = self.BtnZoomIn.OnClicked,				Func = self.OnClicked_ZoomIn },
		{ UDelegate = self.BtnZoomout.OnClicked,			Func = self.OnClicked_Zoomout },
		{ UDelegate = self.BtnBackToMe.OnClicked,			Func = self.OnClicked_BackToMe },
		{ UDelegate = self.BtnSinglePointMark.OnClicked,	Func = self.OnClicked_SinglePointMark },
		{ UDelegate = self.BtnDeleteMark.OnClicked,			Func = self.OnClicked_BtnDeleteMark },
		{ UDelegate = self.BtnSelfMark.OnClicked,			Func = self.OnClicked_BtnSelfMark },
		{ UDelegate = self.SliderMapZoom.OnValueChanged,				Func = self.OnValueChanged_ChangeMapZoomLevel },
	}
	
	self.MinimapManager = UE.UMinimapManagerSystem.GetMinimapManagerSystem(self)

	self.MaxZoomLevel =  self.BP_AdvanceLargemapPanelUI_Mobile and self.BP_AdvanceLargemapPanelUI_Mobile:GetMaxZoomLevel() or 5
	self.MinZoomLevel = self.BP_AdvanceLargemapPanelUI_Mobile and self.BP_AdvanceLargemapPanelUI_Mobile:GetMinZoomLevel() or 1
	self.CurrentZoomLevel = 1
	self.SliderMapZoom:SetMaxValue(self.MaxZoomLevel)
	self.SliderMapZoom:SetMinValue(self.MinZoomLevel)
	self.IsRouteMarkMod = false		-- 当前地图标记状态是否是路径标记模式

	if self.BP_AdvanceLargemapPanelUI_Mobile then
		self.BP_AdvanceLargemapPanelUI_Mobile:SetParentPanel(self)
	end
	
	LargemapPanel.OnInit(self)
end

--
function LargemapPanel_Moblie:OnDestroy()
	print("LargemapPanel_Moblie >> OnDestroy, ", GetObjectName(self))

	LargemapPanel.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------

-------------------------------------------- Function ------------------------------------


-------------------------------------------- Callable ------------------------------------

function LargemapPanel_Moblie:OnClicked_Close()
	print("LargemapPanel_Moblie >> OnClicked_Close, ...")
    MsgHelper:Send(self, GameDefine.Msg.MINIMAP_CloseLargemap, self)
end


function LargemapPanel_Moblie:OnClicked_ZoomIn()
	local ChangeZoomLevel = self.ChangedLevel or 1
	local NewZoomLevelTmp = math.clamp(self.CurrentZoomLevel + ChangeZoomLevel, self.MinZoomLevel, self.MaxZoomLevel)
	local NewPercent = (NewZoomLevelTmp - 1) / (self.MaxZoomLevel - 1)
	print("LargemapPanel_Moblie >> OnClicked_ZoomIn, NewZoomLevel:", NewZoomLevelTmp, "NewPercent:", NewPercent)
	self.ProgressBar_MapZoom:SetPercent(NewPercent)
	self.SliderMapZoom:SetValue(NewZoomLevelTmp)
	self.CurrentZoomLevel = NewZoomLevelTmp
	if self.BP_AdvanceLargemapPanelUI_Mobile then
		self.BP_AdvanceLargemapPanelUI_Mobile:ChangeMapZoomLevel({IsZoomIn = true, NewZoomLevel = self.CurrentZoomLevel})
	end
end

function LargemapPanel_Moblie:OnClicked_Zoomout()
	local ChangeZoomLevel = self.ChangedLevel or 1
	local NewZoomLevelTmp = math.clamp(self.CurrentZoomLevel - ChangeZoomLevel, self.MinZoomLevel, self.MaxZoomLevel)
	local NewPercent = (NewZoomLevelTmp - 1) / (self.MaxZoomLevel - 1)
	print("LargemapPanel_Moblie >> OnClicked_Zoomout, NewZoomLevel:", NewZoomLevelTmp, "NewPercent:", NewPercent)
	self.ProgressBar_MapZoom:SetPercent(NewPercent)
	self.SliderMapZoom:SetValue(NewZoomLevelTmp)
	self.CurrentZoomLevel = NewZoomLevelTmp

	if self.BP_AdvanceLargemapPanelUI_Mobile then
		self.BP_AdvanceLargemapPanelUI_Mobile:ChangeMapZoomLevel({IsZoomIn = false, NewZoomLevel = self.CurrentZoomLevel})
	end
end

function LargemapPanel_Moblie:OnClicked_BackToMe()
	print("LargemapPanel_Moblie >> OnClicked_BackToMe")
	MsgHelper:Send(nil, GameDefine.Msg.LARGEMAP_MoveToMyself)
end

function LargemapPanel_Moblie:OnClicked_SinglePointMark()
	print("LargemapPanel_Moblie >> OnClicked_SinglePointMark	self.IsRouteMarkMod:", self.IsRouteMarkMod)
	if self.IsRouteMarkMod == true then
		self.IsRouteMarkMod = false
		self.TxtSinglePointMark:SetText(StringUtil.Format("单点标记"))
		MsgHelper:Send(nil, GameDefine.Msg.LARGEMAP_UpdateMapMarkMod_Moblie, {IsPlayerRouteMarkMod = false})
	else
		self.IsRouteMarkMod = true
		self.TxtSinglePointMark:SetText(StringUtil.Format("路径标记"))
		MsgHelper:Send(nil, GameDefine.Msg.LARGEMAP_UpdateMapMarkMod_Moblie, {IsPlayerRouteMarkMod = true})
	end
end

function LargemapPanel_Moblie:OnClicked_BtnDeleteMark()
	print("LargemapPanel_Moblie >> OnClicked_BtnDeleteMark")
	MsgHelper:Send(nil, GameDefine.Msg.LARGEMAP_DeleteMarkPoint_Moblie)
end

function LargemapPanel_Moblie:OnClicked_BtnSelfMark()
	print("LargemapPanel_Moblie >> OnClicked_BtnSelfMark")
	MsgHelper:Send(nil, GameDefine.Msg.LARGEMAP_MarkMyself)
end

function LargemapPanel_Moblie:OnValueChanged_ChangeMapZoomLevel(InZoomLevel)
	print("LargemapPanel_Moblie:OnValueChanged_ChangeMapZoomLevel-->InZoomLevel:", InZoomLevel)
	local NewPercent = (InZoomLevel - 1) / (self.MaxZoomLevel - 1)
	self.ProgressBar_MapZoom:SetPercent(NewPercent)
	self.CurrentZoomLevel = InZoomLevel
	if self.BP_AdvanceLargemapPanelUI_Mobile then
		self.BP_AdvanceLargemapPanelUI_Mobile:ChangeMapZoomLevel({IsZoomIn = nil, NewZoomLevel = InZoomLevel})
	end
end

function LargemapPanel_Moblie:OnChangeMapZoomLevel(InZoomLevel)
	self.CurrentZoomLevel = InZoomLevel
	local NewZoomLevelTmp = math.clamp(InZoomLevel, self.MinZoomLevel, self.MaxZoomLevel)
	local NewPercent = (NewZoomLevelTmp - 1) / (self.MaxZoomLevel - 1)
	print("LargemapPanel_Moblie >> OnClicked_Zoomout, NewZoomLevel:", NewZoomLevelTmp, "NewPercent:", NewPercent)
	self.ProgressBar_MapZoom:SetPercent(NewPercent)
	self.SliderMapZoom:SetValue(NewZoomLevelTmp)
end


return LargemapPanel_Moblie
