--
-- 大地图
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.02.11
--

local LargemapPanel = Class("Common.Framework.UserWidget")
-------------------------------------------- Config/Enum ------------------------------------

function LargemapPanel:OnInit()
    print("LargemapPanel >> OnInit, ", GetObjectName(self))
    local MapName = UE.UGameplayStatics.GetCurrentLevelName(self, true)
    if self.TxtMapName then
        self.TxtMapName:SetText(UE.UKismetStringLibrary.ToUpper(MapName))
    end

    if self.TxtMapName1 then
        self.TxtMapName1:SetText(self.TxtMapName:GetText())
    end

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.RefPS = UE.UPlayerStatics.GetCPS(self.LocalPC)

    self.MinimapManager = UE.UMinimapManagerSystem.GetMinimapManagerSystem(self)

	if not self.WidgetSyle then
		self.WidgetSyle = 
		{
			["Normal"] = 1, -- 默认地图
			["ParachuteRespawn"] = 2, -- 跳伞复活
		}
	end
    self.MsgList = {}
    UserWidget.OnInit(self)
end

function LargemapPanel:OnDestroy()
	print("LargemapPanel >> OnDestroy, ", GetObjectName(self))
    UserWidget.OnDestroy(self)
end



-------------------------------------------- Override ------------------------------------
return LargemapPanel
