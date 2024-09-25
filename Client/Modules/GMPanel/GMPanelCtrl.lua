require("Client.Modules.GMPanel.GMPanelModel")

--[[
    GM面板相关协议处理模块
]]
local class_name = "GMPanelCtrl"
---@class GMPanelCtrl : UserGameController
---@field private model GMPanelModel
local SuperClass = UserGameController
GMPanelCtrl = GMPanelCtrl or BaseClass(SuperClass, class_name)


function GMPanelCtrl:__init()
    self.Model = nil
end

function GMPanelCtrl:Initialize()
    self.Model = self:GetModel(GMPanelModel)
end

function GMPanelCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.GetGmListRsp,	Func = self.OnGetGmListRsp}, --请求GM配置列表回复
        {MsgName = Pb_Message.ExecuteOneGmCmdRsp,	Func = self.OnExecuteOneGmCmdRsp}, --请求GM执行结果返回
        {MsgName = Pb_Message.GMInstructionSync,	Func = self.OnGMInstructionSync}, --GM执行信息同步
    }
    self.MsgList = {
		{Model = GlobalInputModel, MsgName = EnhanceInputActionTriggered_Event(GlobalActionMappings.P),	Func = self.OnPClick },
    }
end


function GMPanelCtrl:OnLogin()
    self:ReqSendGetGmList()
end

function GMPanelCtrl:AddMsgListeners()
    GMPanelCtrl.super.AddMsgListeners(self)
end

function GMPanelCtrl:RemoveMsgListeners()
    GMPanelCtrl.super.RemoveMsgListeners(self)
end

--请求获取GM配置列表
function GMPanelCtrl:ReqSendGetGmList()
    self:SendProto(Pb_Message.GetGmListReq, {})
end

--请求GM配置列表回复
function GMPanelCtrl:OnGetGmListRsp(InGmListInfo)
    --MvcEntry:SendMessage(GameEntryProcessModel.ON_GAMESTART_MATHCANCEL, InData)
    --[[
        string ShowName = 1;    // 在客户端显示的Gm指令名称
        string FuncName = 2;    // 执行函数名称
        repeated string Examples = 3; // 参数举例说明，可能多个
    ]]
    -- for _, GmInfo in pairs(InGmListInfo) do
    --     print("GmInfoShowName--->", GmInfo.ShowName)
    -- end
    self.Model:SetGMListData(InGmListInfo)
end

--请求执行GM函数
function GMPanelCtrl:ReqCallFunc(InData,OriginText)
    -- for key, value in pairs(InData.Param) do
    --     print("GMPanelCtrl:ReqCallFunc>>>>>>>>>>>>>>>",value)
    -- end
    local CustomGM = self.Model:GetCustomGMByCmd(InData.FuncName)
    if CustomGM then
        CustomGM["ExcuteFunc"](OriginText)
    else
        self:SendProto(Pb_Message.ExecuteOneGmCmdReq, InData)
    end
end

function GMPanelCtrl:OnExecuteOneGmCmdRsp(InData)
    self:SendMessage(Pb_Message.ExecuteOneGmCmdRsp, InData)
end

--执行后台主动发起的GM命令
function GMPanelCtrl:OnGMInstructionSync(InData)
    --[[
            string CMD = 1;
            /*
                Type
                1:客户端脚本指令;
                2:客户端虚幻函数(GM)指令；
                3.DS GM指令；
                4.CMDjson格式
            */
                int32 Type = 2;
    ]]
    local Type = {
        ClientScript = 1,
        ClientUECMD = 2,
        ServerDSGM = 3,
        CMDjson = 4
    }
    -- print("GMPanelCtrl:OnGMInstructionSync>>>>>>>>>>>>>>>>>>>>>")
    -- print_r(InData)
    local CmdString = InData.CMD
    local CmdType = InData.Type
    if CmdType == Type.ClientUECMD or CmdType == Type.ServerDSGM then
        self:ExecuteCmd(CmdString)
    elseif CmdType == Type.ClientScript then    -- 脚本指令调用
        local LocalPC = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
        BridgeHelper.Exec(LocalPC, CmdString, " ")
    else

    end
end

function GMPanelCtrl:ExecuteCmd(Cmd)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, Cmd, PlayerController)
end

--局外P键触发GM界面
function GMPanelCtrl:OnPClick()
    --不在局内 & 不是正式环境
    if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) and not CommonUtil.IsShipping() then
        if MvcEntry:GetModel(ViewModel):GetState(ViewConst.GMPanel) then
            MvcEntry:CloseView(ViewConst.GMPanel)
        else
            MvcEntry:OpenView(ViewConst.GMPanel)
        end
    end
end








