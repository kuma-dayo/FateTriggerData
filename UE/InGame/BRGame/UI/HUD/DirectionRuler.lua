 --
-- 战斗HUD - 顶部方向标尺
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.16
--
require("InGame.BRGame.GameDefine")

local DirectionRuler = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function DirectionRuler:Initialize()
    self.MyInitializeId = math.random(0, 10000)
    print("DirectionRuler >> Initialize, ", self, self.MyInitializeId)
end

function DirectionRuler:OnInit()
    --
    self.ConvPosValue = 120
    self.ConstantRot = UE.FRotator(180, -90, 180) --180, 90, 180
    self.RulerMultiplier = self.ImgRuler.Slot:GetSize().X / 3600    --5400

    self.ControllerRot = UE.FRotator()
    self.ConvResultRot = UE.FRotator()
    self.CurRulerPos = self.TrsRuler.Slot:GetPosition()
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    -- 方向指示文本
    self.TxtDirList = {
        [0] = 1,
        [45] = 2,
        [90] = 3,
        [135] = 4,
        [180] = 5,
        [225] = 6,
        [270] = 7,
        [315] = 8
    }
    for Key, Value in pairs(self.TxtDirList) do
        local CfgKey = "Ruler_DirTxt" .. Value
        self.TxtDirList[Key] = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, CfgKey)
    end



    print("DirectionRuler >> OnInit, ", self, self.MyInitializeId, self.RulerMultiplier)

    UserWidget.OnInit(self)
end

function DirectionRuler:OnDestroy()
    print("DirectionRuler", ">> OnDestroy, ", self, self.MyInitializeId)

    UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------

function DirectionRuler:ToDirText(InDirValue)
    local Value =  self.TxtDirList[InDirValue] or InDirValue
    return StringUtil.ConvertString2FText(Value)
end

-------------------------------------------- Function ------------------------------------


-------------------------------------------- Callable ------------------------------------


return DirectionRuler
