---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xike.123.
--- DateTime: 2023/4/21 19:34
---

local NetLogReportErrorTest = {}

function NetLogReportErrorTest.ErrorTest()
    print("NetLogReportErrorTest.ErrorTest.")
    local test = 1 + "string"
end

function NetLogReportErrorTest.TestSyncLoad()
    print("NetLogReportErrorTest.TestSyncLoad.")
    LoadObject("Blueprint'/Game/VehicleTemplate/Blueprints/SportsCar/SportsCar_Pawn.SportsCar_Pawn'")
end

return NetLogReportErrorTest