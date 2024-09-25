--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require ("InGame.BRGame.GameDefine")
require ("InGame.BRGame.UI.HUD.BattleUIHelper")
require ("InGame.BRGame.ItemSystem.ItemSystemHelper")
require ("InGame.BRGame.UI.HUD.SelectItem.SelectItemHelper")

local HUDInGame = Class()


function HUDInGame:Initialize(Initializer)
end

function HUDInGame:ReceiveBeginPlay()
    -- 设置界面模式
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(self.LocalPC)
    self.LocalPC.bShowMouseCursor = false;-- pc 默认显示光标 进游戏需要手动隐藏光标

    -- 战斗主界面
    local UIManager = UE.UGUIManager.GetUIManager(self)
    UIManager:LoadPrimaryLayout()

    -- 启动基础/触摸组件/鼠标锁定
	--local tmpMainLayoutData = UE.UObject.Load(UIHelper.LayoutDTPath.TMPMainLayoutData)
    --UIManager:LoadLayoutData(tmpMainLayoutData)
    UIManager.bEnableLimitToCenter = true
    UIManager:SetTickable(true)
    UE.UGameplayStatics.SetViewportMouseCaptureMode(self,UE.EMouseCaptureMode.CapturePermanently)
    print("HUDInGame", ">> ReceiveBeginPlay, ", GetObjectName(self))
end

function HUDInGame:ReceiveEndPlay()
    print("HUDInGame", ">> ReceiveEndPlay, ", GetObjectName(self))

    local UIManager = UE.UGUIManager.GetUIManager(self)
    UIManager:SetTickable(false)
    UIManager.bEnableLimitToCenter = false
    --self:Release()
end

function HUDInGame:Destroyed()
    print("HUDInGame", ">> Destroyed, ", GetObjectName(self))
end

-------------------------------------------- Function ------------------------------------


--先注释了，将Ds刷新率..都搬到了视口上方显示了，写到了 GameStatusInfoTopWidget.lua里

-- function HUDInGame:ReceiveDrawHUD()
--     --print("HUDInGame>> ReceiveDrawHUD, ", GetObjectName(self))
--     local GameState = UE.UGameplayStatics.GetGameState(self)
--     if GameState and self.PlayerOwner and self.PlayerOwner.PlayerState then

--         -- local NetString = string.format("Ping=[%s] FPS=[%d] DsFPS=[%d] Up=[%.2fKB/s][%dpkt/s][%.2f%% loss] Down=[%.2fKB/s][%dpkt/s][%.2f%% loss] Queued=[%d]",  
--         -- math.floor(self.PlayerOwner.PlayerState:GetPingInMilliseconds()), GameState:GetFPS(), GameState:ClientGetDS_FPS(), self.PlayerOwner.PlayerState:GetOutBytesPerSecond(), self.PlayerOwner.PlayerState:GetOutPacketsPerSecond(), self.PlayerOwner.PlayerState:GetOutLossPercentage(),
--         --  self.PlayerOwner.PlayerState:GetInBytesPerSecond(), self.PlayerOwner.PlayerState:GetInPacketsPerSecond(), self.PlayerOwner.PlayerState:GetInLossPercentage(), self.PlayerOwner.PlayerState:GetQueuedBytesPerSecond())

--         local NetString = string.format("DsFPS=[%d] Queued=[%d]", GameState:ClientGetDS_FPS(), self.PlayerOwner.PlayerState:GetQueuedBytesPerSecond())
--         --print("HUDInGame>> ReceiveDrawHUD, NetString ", NetString)

--         --local PosX = self.Canvas.ClipX-1380
--         local PosX = self.Canvas.ClipX-330
--         local PosY = self.Canvas.ClipY
--         local TextScale = 2
--         local TextWidth,TextHight = self:GetTextSize(0, nil, nil, 0, TextScale)
--         PosX = PosX-TextWidth*TextScale
--         PosY = PosY-TextHight
--         --print("HUDInGame>> ReceiveDrawHUD, PosX ", PosX, " PosY ", PosY, " TextWidth ", TextWidth)
--         self:DrawText(NetString, UIHelper.LinearColor.Cyan, PosX/2, PosY/2, 0, TextScale, true)

--         local Year, Month, Day, Hour, Minute, Second, Millisecond = UE.UKismetMathLibrary.BreakDateTime(UE.UKismetMathLibrary.Now(), 0, 0, 0, 0, 0, 0, 0)
--         local TimeString = string.format("[%d.%d.%d-%d.%d.%d.%d]", Year, Month, Day, Hour, Minute, Second, Millisecond)
--         --print("HUDInGame>> ReceiveDrawHUD, TimeString ", TimeString)
--         self:DrawText(TimeString, UIHelper.LinearColor.Cyan, PosX/2 - 160, PosY/2, 0, TextScale, true)
--     end

-- end


-------------------------------------------- Callable ------------------------------------


return HUDInGame
