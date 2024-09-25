--
-- 小地图
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.02.11
--

local MinimapPanel = Class("Common.Framework.UserWidget")


-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Override ------------------------------------

-------------------------------------------- Init/Destroy ------------------------------------

--
function MinimapPanel:OnInit()
	--print("MinimapPanel", ">> OnInit, ", GetObjectName(self))
	
	-- 
	if BridgeHelper.IsMobilePlatform() then 
		self.BindNodes = {
			{ UDelegate = self.BtnLargemap.OnClicked,			Func = MinimapPanel.OnClicked_Largemap },
		}
	elseif self.BtnLargemap then
		self.BtnLargemap:RemoveFromParent()
		self.BtnLargemap = nil
	end

	--
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.MsgList = {
		{ MsgName = GameDefine.Msg.MINIMAP_CloseLargemap,		Func = self.OnCloseLargemap },
		{ MsgName = GameDefine.MsgCpp.PC_Input_ScaleMap,		Func = self.OnScaleMap, 	 bCppMsg = true, WatchedObject = self.LocalPC },
	}

	UserWidget.OnInit(self)
	

end

--
function MinimapPanel:OnDestroy()
	--print("MinimapPanel", ">> OnDestroy, ", GetObjectName(self))

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------

-------------------------------------------- Function ------------------------------------

-- 更新小地图大小
function MinimapPanel:UpdateMinimapSize()
	local ExtraSize = self.ExtraSize or 0
	if (not ExtraSize) or (ExtraSize <= 0) then
		Warning("MinimapPanel", ">> UpdateMinimapSize, ExtraSize isn't config!!!")
		return
	end

	local AddExtraSize = self.bIsMidState and ExtraSize or -ExtraSize
	UIHelper.SetWidgetSize(self.TrsTigger, AddExtraSize)
	UIHelper.SetWidgetSize(self.TrsMap, AddExtraSize)
	UIHelper.SetWidgetSize(self.TrsRetainer, AddExtraSize)
	
	local NewZoomLevel = self.bIsMidState and self.MidMapZoom or self.SmallMapZoom

	-- 保存
	--local SaveData = { bIsMidState = self.bIsMidState }
	--SaveGame:SaveFile(SaveGame.SaveName.Minimap, SaveData)

	-- 发个通知出去,我变了-.-
    MsgHelper:Send(self, GameDefine.Msg.MINIMAP_SizeChanged, AddExtraSize)
end

-- 触发大地图显示/隐藏
function MinimapPanel:ToggleShowLargemap()
	local UIManager = UE.UGUIManager.GetUIManager(self)
	local MinimapActor = MinimapHelper.GetMinimapActor(self)
    if (not UIManager) or (not MinimapActor) then
        Warning("MinimapPanel", ">> ToggleShowLargemap, UIManager/MinimapActor is invalid!", UIManager, MinimapActor)
        return
    end

	if UIManager:IsDynamicWidgetShowByHandle(self.HandleUILargemap) then
		--self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		UIManager:TryCloseDynamicWidgetByHandle(self.HandleUILargemap)
		self.LocalPC:ResetIgnoreLookInput()
		--MsgHelper:SendCpp(self.LocalPC, GameDefine.Msg.MINIMAP_StatusChanged,0) --0：小地图 1：大地图 2：中地图
	else		
		self.HandleUILargemap = UIManager:TryLoadDynamicWidget("UMG_Largemap")
		--MsgHelper:SendCpp(self.LocalPC, GameDefine.Msg.MINIMAP_StatusChanged,1) --0：小地图 1：大地图 2：中地图
		--self:SetVisibility(UE.ESlateVisibility.Collapsed)
	end 
end

-------------------------------------------- Callable ------------------------------------

function MinimapPanel:OnClicked_Largemap()
	print("MinimapPanel", ">> OnClicked_Largemap, ...")
	
	self:ToggleShowLargemap()
end

-- 缩放小地图
function MinimapPanel:OnScaleMap(InInputData)
	--print("MinimapPanel", ">> OnScaleMap, ...", InInputData)

	if self:IsVisible() then
		self.bIsMidState = (not self.bIsMidState)
		self:UpdateMinimapSize()
	end
end
function MinimapPanel:OnCloseLargemap(InContext)
	if InContext and (InContext:GetWorld() == self:GetWorld()) then
		self:ToggleShowLargemap()
	end
end

-- 触发大地图显示/隐藏
function MinimapPanel:OnSwitchFullMap(InKey)
	print("MinimapPanel", ">> OnSwitchFullMap, ...")
	self:ToggleShowLargemap()
end

return MinimapPanel
