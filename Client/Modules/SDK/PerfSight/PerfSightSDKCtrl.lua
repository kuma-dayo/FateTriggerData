require("Client.Modules.SDK.PerfSight.PerfSightSDKModel")

--[[
    PerfSightSDK 交互Ctrl
]]
local class_name = "PerfSightSDKCtrl"
PerfSightSDKCtrl = PerfSightSDKCtrl or BaseClass(UserGameController,class_name)

function PerfSightSDKCtrl:__init()
    self.Model = nil
end

function PerfSightSDKCtrl:Initialize()
    self.Model = self:GetModel(PerfSightSDKModel)
end

--[[
    判断返回SDK是否可用
]]
function PerfSightSDKCtrl:IsSDKEnable(DoTip)
    return UE.UPerfSightHelper.IsEnable()
end

function PerfSightSDKCtrl:AddMsgListenersUser()
    if not self:IsSDKEnable() then
        return
    end
    --SDK GMP事件监听
    local SDKTags = UE.USDKTags.Get()
    self.MsgListGMP = {

    } 

    self.MsgList = {
        {Model = ViewModel,MsgName = ViewModel.ON_PRE_LOAD_MAP,Func = self.ON_PRE_LOAD_MAP_Func}, 
        {Model = ViewModel,MsgName = ViewModel.ON_POST_LOAD_MAP,Func = self.ON_POST_LOAD_MAP_Func}, 
    }
end

function PerfSightSDKCtrl:OnLogin(data)
    CWaring("PerfSightSDKCtrl OnLogin")
    if not self:IsSDKEnable() then
        return
    end
    local TheUserModel = MvcEntry:GetModel(UserModel)
    UE.UPerfSightHelper.SetUserId(TheUserModel:GetPlayerId())

    if CommonUtil.IsPlatform_Windows() then
        UE.UPerfSightHelper.SetPCAppVersion(TheUserModel:GetAppVersion())
    else
        UE.UPerfSightHelper.SetVersionIden(TheUserModel:GetAppVersion())
    end
end

function PerfSightSDKCtrl:Init(IsOversea)
    if not self:IsSDKEnable() then
        return
    end
    local DebugMode = not CommonUtil.IsShipping()
    if not IsOversea then
        UE.UPerfSightHelper.Init("pc.perfsight.qq.com", "229716583", DebugMode)
    else
        UE.UPerfSightHelper.Init("pc.perfsight.wetest.net", "924600724", DebugMode)
    end
end

function PerfSightSDKCtrl:OnLogout(data)
    CWaring("PerfSightSDKCtrl OnLogout")
end


function PerfSightSDKCtrl:ON_PRE_LOAD_MAP_Func(MapName)
    if not self:IsSDKEnable() then
        return
    end
    UE.UPerfSightHelper.MarkLevelLoad(MapName or "")
end


function PerfSightSDKCtrl:ON_POST_LOAD_MAP_Func(MapName)
    if not self:IsSDKEnable() then
        return
    end
    UE.UPerfSightHelper.MarkLevelLoadCompleted()
end






