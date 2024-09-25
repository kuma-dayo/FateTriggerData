--设置的数据 


local super = GameEventDispatcher;
local class_name = "SettingModel";

---@class SettingModel : GameEventDispatcher
---@field private super GameEventDispatcher
SettingModel = BaseClass(super, class_name)

function SettingModel:__init()
   -- print("SettingModel:__init")
    self:_dataInit()
end

function SettingModel:_dataInit()
   -- print("SettingModel:_dataInit")
    -- 默认设置
    
end

function SettingModel:OnLogin(data)
    --print("SettingModel:OnLogin")
    self:GetSettingData()
end

--[[
    玩家登出时调用
]]
function SettingModel:OnLogout(data)
    SettingModel.super.OnLogout(self)
   
end


function  SettingModel:GetSettingData()
    print("SettingModel:GetSettingData")
    MvcEntry:GetCtrl(SettingCtrl):SendSetting_Req(self)
    
    if UE.UGFStatics.IsMobilePlatform()  then
        MvcEntry:GetCtrl(SettingCtrl):SendCustomLayout_Req(self)
    end
end

-- 手动打开日志
function SettingModel:GMOpenReportLog()
    UE.UGFUnluaHelper.GMOpenReportLog()
end