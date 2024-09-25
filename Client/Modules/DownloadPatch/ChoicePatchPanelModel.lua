--[[好友操作日志数据模型]]
local super = GameEventDispatcher;
local class_name = "ChoicePanelModel";
---@class  ChoicePanelModelModel : GameEventDispatcher
---@field private super GameEventDispatcher
ChoicePanelModel = BaseClass(super, class_name)

ChoicePanelModel.DownloadPatchEnum = {
    START_DOWNLOAD = 5,
    START_MERGE = 7,
    End = 9,
}

function ChoicePanelModel:__init()
    self:_dataInit()
end

function ChoicePanelModel:_dataInit()
    self.LogList = {}
    self.PatchPipeline = UE.UGenericPatchSubsystem.GetGenericPatchSubsystem(GameInstance):GetPatchPipeline()
end

--[[
    玩家登出时调用
]]
function ChoicePanelModel:OnLogout(data)
    ChoicePanelModel.super.OnLogout(self)
    self:_dataInit()
end


return ChoicePanelModel;
