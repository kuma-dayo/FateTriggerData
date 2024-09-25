--[[好友操作日志数据模型]]
local super = GameEventDispatcher;
local class_name = "DownloadPatchPanelModel";
---@class DownloadPatchPanelModel : GameEventDispatcher
---@field private super GameEventDispatcher
DownloadPatchPanelModel = BaseClass(super, class_name)

DownloadPatchPanelModel.DownloadPatchEnum = {
    START_DOWNLOAD = 5,
    START_MERGE = 7,
    End = 9,
}

DownloadPatchPanelModel.PreCheckEnum = {
    NORMAL_DOWNLOAD = 0,
    NOT_ENOUGH_SPACE = 1,
}


function DownloadPatchPanelModel:__init()
    self:_dataInit()
end

function DownloadPatchPanelModel:_dataInit()
    CLog("huijin2 ")
    self.LogList = {}
    self.PatchPipeline = UE.UGenericPatchSubsystem.GetGenericPatchSubsystem(GameInstance):GetPatchPipeline()
end

--[[
    玩家登出时调用
]]
function DownloadPatchPanelModel:OnLogout(data)
    DownloadPatchPanelModel.super.OnLogout(self)
    self:_dataInit()
end

function DownloadPatchPanelModel:GetCurrentState()
end

function DownloadPatchPanelModel:GetCurrentDownloadSpeed()
    return self.PatchPipeline and self.PatchPipeline.DownloadSpeed or 0
end

function DownloadPatchPanelModel:GetCurrentDownloadBytes()
    return self.PatchPipeline and  self.PatchPipeline.CurrentDownload or 0
end

function DownloadPatchPanelModel:GetTotalDownloadBytes()
    return self.PatchPipeline and  self.PatchPipeline.TotalDownload or 0
end

function DownloadPatchPanelModel:GetCurrentMergePaks()
    return self.PatchPipeline and  self.PatchPipeline.CurrentMergePak or 0
end

function DownloadPatchPanelModel:GetTotalMergePaks()
    return self.PatchPipeline and  self.PatchPipeline.TotalMergePak or 0
end

function DownloadPatchPanelModel:StartDownloadPipeline()

end

return DownloadPatchPanelModel;
