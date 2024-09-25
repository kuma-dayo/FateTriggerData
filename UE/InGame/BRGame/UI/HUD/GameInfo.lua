-- GameId

local GameInfo = Class()
local GameReadUGSInIInfo = require("UE.InGame.BRGame.UI.HUD.GameReadUGSInIInfo")

function GameInfo:Construct()
    -- self.Super:Construct()
    -- local Time = os.date("Server-%Y-%m-%d %H:%M:%S")
    -- self.TimeText:SetText(Time)
    --local GameState = UE.UGameplayStatics.GetGameState(self)
    --self.GameIdText:SetText(GameState.GameId)
    
    self.CliTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.SetClientTime}, 1.0, false, 0, 0)
end

function GameInfo:SetClientTime()
    -- local Time = os.date("Client-%Y-%m-%d %H:%M:%S")
    -- self.ClientTimeText:SetText(Time)
    print("GameInfo:SetClientTime")
 
    local GameState = UE.UGameplayStatics.GetGameState(self)

    local CL = GameReadUGSInIInfo:GetCurChangeList()

    if CL == 0 then
        CL = tostring(GameState.LocalChangelist)
    end 
    
    if CommonUtil.IsShipping() then
        self.GameIdText:SetText("")
        self.LocalVersion:SetText("")
        self.DSVersion:SetText("")
        self.LocalCLText:SetText("")
        self.DSCLText:SetText("")
        self.LocalBuildArgs:SetText("")
        self.DSBuildArgs:SetText("")
    else
        self.GameIdText:SetText(GameState.GameId)
        self.LocalVersion:SetText("LocalVersion: " .. tostring(GameState.LocalVersion))
        self.DSVersion:SetText("DSVersion: " .. tostring(GameState.DSVersion))
        self.LocalCLText:SetText("LocalCL: " .. CL)
        self.DSCLText:SetText("DSCL: " .. tostring(GameState.DSChangelist))
        self.LocalBuildArgs:SetText("LocalBuildArgs: " .. tostring(GameState.LocalBuildArgs))
        self.DSBuildArgs:SetText("DSBuildArgs: " .. tostring(GameState.DSBuildArgs))
    end
end

function GameInfo:Destruct()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self,self.CliTimerHandle)
end

return GameInfo