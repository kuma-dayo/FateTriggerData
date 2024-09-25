require("Client.Modules.DownloadPatch.DownloadPatchPanelModel")

local class_name = "DownloadPatchPanelMdt";
DownloadPatchPanelMdt = DownloadPatchPanelMdt or BaseClass(GameMediator, class_name);

function DownloadPatchPanelMdt:__init()
end

function DownloadPatchPanelMdt:OnShow(data)
    CLog("@huijin -----OnShow Patch 0")

end

function DownloadPatchPanelMdt:OnHide()
    CLog("-----OnHide")
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    CLog("huijin -----OnInit")
    self.PatchPipeline = UE.UGenericPatchSubsystem.GetGenericPatchSubsystem(GameInstance):GetPatchPipeline()
    self.PatchPipeline:InitPipeline()

    self.BindNodes = {
        { UDelegate = self.BtnSmall_Start.GUIButton_Main.OnClicked, Func = self.OnBtnSmallStopClicked },
        { UDelegate = self.BtnSmall_Stop.GUIButton_Main.OnClicked, Func = self.OnBtnSmallStartClicked },
    }
    self.MsgListGMP = {
        { InBindObject = _G.MainSubSystem,	MsgName = self.PatchPipeline:GetPreCheckGMPString(),	Func = Bind(self,self.OnPreDownload), 			bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = self.PatchPipeline:GetTaskStartGMP(5),	Func = Bind(self,self.OnStartDownloadFiles), 			bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = self.PatchPipeline:GetTaskStartGMP(7),	Func = Bind(self,self.OnStartMergeFiles), 		    bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = self.PatchPipeline:GetEndGMPString(),	Func = Bind(self,self.OnEndPipeline), 		    bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = self.PatchPipeline:GetNotEnoughGMPString(),	Func = Bind(self,self.NotEnoughSpace), 		    bCppMsg = true, WatchedObject = nil },
      --  { InBindObject = _G.MainSubSystem,	MsgName = self.PatchPipeline:GetCheckFailedString(),	Func = Bind(self,self.OnCheckFailed), 		    bCppMsg = true, WatchedObject = nil },
    }
    self.InStrTableKey = "/Game/Maps/Login/HotUpdate/DataTable/SD_HotUpdate.SD_HotUpdate"
end

function M:OnShow(data)
    MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.StartUpdate)
    if data~=nil and data.TargetVersion~= nil then
        for k, v in pairs(data) do
            CWaring(k .. "huijin: " .. tostring(v))
        end
        self.TargetVersion = data.TargetVersion
        self.PatchPipeline:SetSpecialVersion(self.TargetVersion)
    end
       
    self.UpdateBar:SetPercent(1)
    self.TEXT_ProcessPercent:SetText('100')
    self.TEXT_DownloadInformation:SetText('')
    --self.UpdateBar:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self.T_Friend_Invite_Bg_ProgressBar_Bottom:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Switcher_PauseStart:SetVisibility(UE.ESlateVisibility.Collapsed)
    --启动流水线
    self:DoStartPipeLine()
end


function M:OnHide()
    
end

--启动流水线
function M:DoStartPipeLine()
    if self.PatchPipeline == nil then
        return
    end
    self.PatchPipeline:StartPipeline()
end

--下载
function M:DoStartDownload()
    if self.PatchPipeline == nil then
        return
    end
    self.PatchPipeline:StartDownload()
end


--合并
function M:DoMerge()

end


--强制退出游戏
function M:DoExitGame()
    local LocalPC = CommonUtil.GetLocalPlayerC()
    UE.UKismetSystemLibrary.QuitGame(_G.GameInstance, LocalPC, 0, true)
end

--[[
    C++回调结果
]]

--校验失败回调
function M:OnCheckFailed()
    local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "104")
    local describeMsg = TipStr 
    local ExitStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "Exit")
    local msgParam = {
        describe = describeMsg,
        rightBtnInfo = {
            name = ExitStr,
            callback = function()
                self:DoExitGame()
            end
        },
        HideCloseBtn = true,
        HideCloseTip = true,
    }
    UIMessageBox.Show(msgParam)
end

--预下载回调
function M:OnPreDownload(CheckCode)
    local DownloadPatchPanelModel = MvcEntry:GetModel(DownloadPatchPanelModel)
    local PreCheckEnumNormal = DownloadPatchPanelModel.PreCheckEnum["NORMAL_DOWNLOAD"]
    local PreCheckEnumNotEnough = DownloadPatchPanelModel.PreCheckEnum["NOT_ENOUGH_SPACE"]

    if CheckCode == PreCheckEnumNormal then
        local CurrentVersion = self.PatchPipeline:GetCurrentVersion()
        local TargetVersion = self.PatchPipeline:GetTargetVersion()
        local TotalBytes = self.PatchPipeline.TotalDownload
        local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "DownloadTo")
        local FormattedNumber = string.format("%.2f", TotalBytes/1024/1024)
        local TotalBytesStr = FormattedNumber .. " MB"
        local describeMsg = StringUtil.Format(TipStr, CurrentVersion,TargetVersion,TotalBytesStr)
        local ExitStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "Exit")
        local ContinueStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "ContinueDown")
        local msgParam = {
            describe = describeMsg,
            leftBtnInfo = {
                name = ExitStr,
                callback = function()
                    self:DoExitGame()
                end
            },
            rightBtnInfo = {
                name = ContinueStr,
                callback = function()
                    self:DoStartDownload()
                end
            },
            HideCloseBtn = true,
            HideCloseTip = true,
        }
        UIMessageBox.Show(msgParam)
        self:StateDownloadFiles()
    end

    if CheckCode == PreCheckEnumNotEnough then
        local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "103")
        local TotalBytes = self.PatchPipeline.TotalDownload
        local FreeSize = self.PatchPipeline:GetFreeSize()
        local describeMsg = StringUtil.Format(TipStr, FreeSize, TotalBytes)
        local ExitStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "Exit")
        local ContinueStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "ContinueDown")
        local msgParam = {
            describe = describeMsg,
            leftBtnInfo = {
                name = ContinueStr,
                callback = function()
                    self:DoStartDownload()
                end
            },
            rightBtnInfo = {
                name = ExitStr,
                callback = function()
                    self:DoExitGame()
                end
            },
            HideCloseBtn = true,
            HideCloseTip = true,
        }
        UIMessageBox.Show(msgParam)
    end
end

--下载回调
function M:OnStartDownloadFiles()
    CLog("StartDownloadFiles")
    -- 这部分CBT1版本暂时迁移到后面切换UI相关的地方
end

--合并回调
function M:OnStartMergeFiles()
    CLog("StartMergeFiles")
    self:StateMergeFiles()
end

function M:ErrorVersion()
    CWaring("ErrorVersion:" )
    local TargetVersion = self.PatchPipeline:GetTargetVersion()
    local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "105")
    local describeMsg = StringUtil.Format(TipStr,TargetVersion)
    local ExitStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "Exit")
    local msgParam = {
        describe = describeMsg,
        rightBtnInfo = {
            name = ExitStr,
            callback = function()
                self:DoExitGame()
            end
        },
        HideCloseBtn = true,
        HideCloseTip = true,
    }
    UIMessageBox.Show(msgParam)
end

--流程结束回调
function M:OnEndPipeline(Reason)
    CLog("EndPipeline lua" .. Reason)
    if Reason == 0 then
        self:MergeSuccess()
    elseif  Reason == 6 then
        self:ErrorVersion()
    elseif Reason == 1 then
        self:EnterLogin()
    elseif Reason == 4 then
        self:UpdateFailed()
    elseif Reason == 5 then
        if UE.UProjectBuildInformationLib:bIsInternalPackage() then
            self:EnterLogin()
        else
            self:UpdateFailed()
        end
    end
end

function M:InitDownloadFailed()
    CLog('InitDownloadFailed..')
    local TargetVersion = self.PatchPipeline:GetTargetVersion()
    local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "104")
    local describeMsg = StringUtil.Format(TipStr,TargetVersion)
    local ExitStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "Exit")
    local msgParam = {
        describe = describeMsg,
        rightBtnInfo = {
            name = ExitStr,
            callback = function()
                self:DoExitGame()
            end
        },
        HideCloseBtn = true,
        HideCloseTip = true,
    }
    UIMessageBox.Show(msgParam)
end

function M:MergeSuccess()
    CLog('MergeSuccess..')
    local TargetVersion = self.PatchPipeline:GetTargetVersion()
    local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "MergeSuc")
    local describeMsg = StringUtil.Format(TipStr,TargetVersion)
    local ExitStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "Exit")
    local msgParam = {
        describe = describeMsg,
        rightBtnInfo = {
            name = ExitStr,
            callback = function()
                self:DoExitGame()
            end
        },
        HideCloseBtn = true,
        HideCloseTip = true,
    }
    UIMessageBox.Show(msgParam)
end

function M:UpdateFailed()
    local ErrorCode = self.PatchPipeline:GetErrorCode()
    CLog("UpdateFailed: " .. ErrorCode)
    if ErrorCode ==  2 or ErrorCode == 3 or ErrorCode == 4 then
        local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "104")
        local describeMsg = TipStr
        local ExitStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "Exit")
        local msgParam = {
            describe = describeMsg,
            rightBtnInfo = {
                name = ExitStr,
                callback = function()
                    self:DoExitGame()
                end
            },
            HideCloseBtn = true,
            HideCloseTip = true,
        }
        UIMessageBox.Show(msgParam)
    end
end

function M:EnterLogin()
    MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.UpdateFinished)
    if  self.TimerHandleDownload then
        self:RemoveTimer(self.TimerHandleDownload)
        self.TimerHandleDownload = nil
    end
    if  self.TimerHandleMerge then
        self:RemoveTimer(self.TimerHandleMerge)
        self.TimerHandleMerge = nil
    end
    MvcEntry:CloseView(self.viewId)
end

--[[
    UI信息更新
]]

function M:CalPercentage(Current, Total)
    local Percentage = 0
    if (Total == 0) then
        Percentage = 0
    else
        Percentage = Current / Total
    end
    local Formatted = string.format('%.2f', Percentage)
    local Result = math.floor(tonumber(Formatted) * 100)
    return Result
end

function M:NotEnoughSpace(DiskSize,CurrentSize)
    self:PauseDownload()
    local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "103")
    local describeMsg = StringUtil.Format(TipStr, DiskSize,CurrentSize)
    local ExitStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "Exit")
    local ContinueStr =  G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "ContinueDown")
    local msgParam = {
        describe = describeMsg,
        leftBtnInfo = {
            name = ContinueStr,
            callback = function()
                self:DownloadStart()
            end
        },
        rightBtnInfo = {
            name = ExitStr,
            callback = function()
                self:DoExitGame()
            end
        },
        HideCloseBtn = true,
        HideCloseTip = true,
    }
    UIMessageBox.Show(msgParam)
end

function M:UpdateDownloadProcess()
    local TotalBytes = MvcEntry:GetModel(DownloadPatchPanelModel):GetTotalDownloadBytes()
    local CurrentBytes = MvcEntry:GetModel(DownloadPatchPanelModel):GetCurrentDownloadBytes()
    local CurrentSpeed = MvcEntry:GetModel(DownloadPatchPanelModel):GetCurrentDownloadSpeed()
    local Percentage = self:CalPercentage(CurrentBytes, TotalBytes)
    local FinalText = Percentage
    local FormattedNumber = math.floor((CurrentSpeed + 512) / 1024)
    local FormattedCurrentBytes = string.format("%.2f", CurrentBytes / 1024/1024)
    local FormattedTotalBytes = string.format("%.2f", TotalBytes / 1024/1024)
    self.TEXT_DownloadInformation:SetText(StringUtil.Format(FormattedNumber).."KB/s ".."("..FormattedCurrentBytes.."MB/"..FormattedTotalBytes.."MB)")
    self.TEXT_ProcessPercent:SetText(StringUtil.Format(FinalText))
    self.UpdateBar:SetPercent(Percentage / 100)
    -- CLog("——————————————————————————————" .. FinalText)
    --self.TEXT_DownloadInformation:SetText(CurrentSpeed..'('..CurrentBytes..'/'..TotalBytes..')')
end

function M:UpdateMergeProcess()
    local TotalMerge = MvcEntry:GetModel(DownloadPatchPanelModel):GetTotalMergePaks()
    local CurrentMerge = MvcEntry:GetModel(DownloadPatchPanelModel):GetCurrentMergePaks()
    local Percentage = self:CalPercentage(TotalMerge, CurrentMerge)
    self.TEXT_DownloadInformation:SetText("")
    local FinalText = Percentage
    CLog("huijin:".."CurrentMerge"..CurrentMerge .."TotalMerge".. TotalMerge)
    self.TEXT_ProcessPercent:SetText(StringUtil.Format(FinalText))
    self.UpdateBar:SetPercent(CurrentMerge / TotalMerge)
    -- CLog("——————————————————————————————" .. FinalText)
    --self.TEXT_DownloadInformation:SetText('')
end

--下载
function M:StateDownloadFiles()
    self.UpdateBar:SetPercent(0)
    --self.UpdateBar:SetVisibility(UE.ESlateVisibility.Visible)
    --self.T_Friend_Invite_Bg_ProgressBar_Bottom:SetVisibility(UE.ESlateVisibility.Visible)
    --self.Switcher_PauseStart:SetVisibility(UE.ESlateVisibility.Visible)
    local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "IsDownloading")
    self.TEXT_ProcessInformation:SetText(StringUtil.Format(TipStr))
    -- timer 定时更新下载的速度，更新processbar和文字
    -- self.TimerHandleDownload = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, M.UpdateDownloadProcess }, 0.3, true, 0, 0)
    if self.TimerHandleDownload ~= nil then
        self:RemoveTimer(self.TimerHandleDownload)
    end
    self.TimerHandleDownload = self:InsertTimer(0.3, Bind(self,self.UpdateDownloadProcess), true)
end

--合并
function M:StateMergeFiles()
    --self.Switcher_PauseStart:SetVisibility(UE.ESlateVisibility.Collapsed)
    local TipStr = G_ConfigHelper:GetStrTableRow(self.InStrTableKey, "IsMergeing")
    self.TEXT_ProcessInformation:SetText(StringUtil.Format(TipStr))
    if self.TimerHandleMerge ~= nil then
        self:RemoveTimer(self.TimerHandleMerge)
    end
    self.TimerHandleMerge = self:InsertTimer(0.3, Bind(self,self.UpdateMergeProcess), true)
end

function M:DownloadStart()
    CLog(">>>> StartDownload: ")
    self.PatchPipeline:StartDownload()
end

function M:PauseDownload()
    CLog(">>>> PauseDownload: ")
    self.PatchPipeline:PauseDownload()
end

function M:OnBtnSmallStartClicked()
    if not self.DownloadStart then
        CLog("not self.DownloadStart: ")
        return
    end
    self:DownloadStart()
    self.Switcher_PauseStart:SetActiveWidget(self.BtnSmall_Start)
end

function M:OnBtnSmallStopClicked()
    if not self.PauseDownload then
        CLog("not self.PauseDownload: ")
    end
    self:PauseDownload()
    self.Switcher_PauseStart:SetActiveWidget(self.BtnSmall_Stop)
end

return M