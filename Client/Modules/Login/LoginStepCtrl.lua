require("Client.Modules.Login.LoginModel")

--[[
    登录步骤处理器
]]
local class_name = "LoginStepCtrl"
---@class LoginStepCtrl : UserGameController
---@field private model UserModel
LoginStepCtrl = LoginStepCtrl or BaseClass(UserGameController,class_name)


function LoginStepCtrl:__init()
end

function LoginStepCtrl:AddMsgListenersUser()
    self.MsgList = {
        { Model = ViewModel, MsgName = ViewModel.ON_SATE_DEACTIVE_CHANGED,    Func = self.ON_SATE_DEACTIVE_CHANGED_Func },
    }
end

function LoginStepCtrl:StepInit()
    if not self.SequentialOpenViewList then
        --[[
            顺序打开的列表界面
            会按顺序打开第一个界面，等界面关闭会按顺序打开后一个
            所有阶段执先完成，会跳转至 self:Jump2Login()
            {
                --界面ID
                ViewId = ViewConst.StartupPanel,
                --定制参数（可选）
                Param = nil
                --是否将此条配置关闭，不执行，默认false（可选）
                IsClose
            },
        ]]
        local TheUserModel = MvcEntry:GetModel(UserModel)
        local CommandLine = UE.UKismetSystemLibrary.GetCommandLine()
        local IsServerCloseNoticeActive = true
        local IsPolicyActive = true
        local IsAdultMark = true
        --UE.UGFUnluaHelper.IsEditor() or 
        if TheUserModel.IsLoginByCMD then
            IsServerCloseNoticeActive = false
            IsPolicyActive = false
            IsAdultMark = false
        end
        --是否跳过关服公告
        local bUseServerCloseNotive = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "bUseServerCloseNotive=")
        bUseServerCloseNotive = tonumber(bUseServerCloseNotive)
        if bUseServerCloseNotive and bUseServerCloseNotive <= 0 then
            IsServerCloseNoticeActive = false
        end
        --是否跳过设备性能检测
		local SkipDeviceMeetClose = false
		if TheUserModel.IsLoginByCMD or UE.UGFUnluaHelper.IsEditor() then
			SkipDeviceMeetClose = true
		else
			local bSkipDeviceMeets = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "bSkipDeviceMeets=")
			bSkipDeviceMeets = tonumber(bSkipDeviceMeets)
			if bSkipDeviceMeets and bSkipDeviceMeets > 0 then
				SkipDeviceMeetClose = true
			end
		end
        self.SequentialOpenViewList = {
            --[[
				检查设备是否符合性能准入门槛
				不符合，不让其进入游戏
			]]
	        {ViewId = 0,CustomWaitCustomLogic = function()
                local IsDeviceMeets = UE.UGFUnluaHelper.IsDeviceMeetsTheStandards()
				if not IsDeviceMeets then
					CWaring("CheckDeviceMeetsTheStandards IsDeviceMeets false")
					local msgParam = {
						describe = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Startup","DeviceMeetsTheStandardsTip"),
						rightBtnInfo = {                                        
							callback = function()
								CommonUtil.QuitGame()
							end
						},
						HideCloseBtn = true,
						HideCloseTip = true,
					}
					UIMessageBox.Show(msgParam)

                    MvcEntry:GetCtrl(EventTrackingCtrl):ReportViewIdWithOpen(0) --手动上报【不满足测试需求】弹窗
				else
					self:DoSequentialOpenView()
				end
            end,IsClose = SkipDeviceMeetClose},
            --登录前公告
            {ViewId = ViewConst.PreLoginNotice,Param = nil,IsClose = false,CheckOpenFunc = function()
                if self:GetSingleton(OnlineSubCtrl):IsOnlineEnabled() or #self:GetModel(PreLoginNoticeModel):GetNoticeList() == 0 then
                    return false
                end
                return true
            end},
            -- 区域.隐私.服务条款
            {ViewId = ViewConst.RegionPolicyPopup, Param = nil, IsClose = not(IsPolicyActive), CheckOpenFunc = function()
                local RegionPolicyID = SaveGame.GetItem(SystemMenuConst.RegionPolicyIdKey, nil, true) or 0
                if RegionPolicyID == 0 then
                    return true
                end
                return false
            end},
            -- 年龄确认
            {ViewId = 0, CustomWaitCustomLogic = function()
                local AdultMarkVal = SaveGame.GetItem(SystemMenuConst.AdultMarkKey, nil, true) or 0
                CLog("SystemMenuConst.AdultMarkKey, AdultMarkVal = " .. tostring(AdultMarkVal))
                if AdultMarkVal == 0 then
                    local msgParam = {
                        title = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","1746"),--请确认您是否已成年
						describe = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","1747"),--请确认您是否已成年
                        leftBtnInfo = {
                            name = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","1748"),--否，并未成年
                            callback = function()
								CommonUtil.QuitGame()
							end,
                        },
						rightBtnInfo = {
                            name = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","1749"),--是，我已成年    
                            callback = function()
                                SaveGame.SetItem(SystemMenuConst.AdultMarkKey, 1, nil, true) 
                                self:DoSequentialOpenView()
                            end                                    
						},
						HideCloseBtn = true,
						HideCloseTip = true,
					}
					UIMessageBox.Show(msgParam)
                else
                    self:DoSequentialOpenView()
                end
            end, IsClose = not(IsAdultMark)},
            {ViewId = 0,CustomWaitCustomLogic = function()
                self:GetSingleton(LoginCtrl):GetPreServerCloseInfo(function ()
                    self:DoSequentialOpenView()
                end)
            end,IsClose = not IsServerCloseNoticeActive},
            --关服提示界面
            {ViewId = ViewConst.ServerCloseNotice,Param = nil,IsClose = false,CheckOpenFunc = function()
                if self:GetSingleton(LoginCtrl):IsServerCloseByNotice() then
                    return true
                end
                return false
            end},
        }
    end
    self.SequentialId = 0
    self.IsWoking = true
end

--[[
	某些界面关闭时回调
]]
function LoginStepCtrl:ON_SATE_DEACTIVE_CHANGED_Func(ViewId)
    if not self.IsWoking then
        return
    end
	local ViewConfig = self.SequentialOpenViewList[self.SequentialId]
	if not ViewConfig then
		return
	end
	if ViewConfig.ViewId == ViewId then
		CWaring("M:ON_SATE_DEACTIVE_CHANGED_Func Close,Try Triiger Next")
		self:DoSequentialOpenView()
	end
end

function LoginStepCtrl:DoSequentialOpenView()
    if not self.IsWoking then
        CWaring("LoginStepCtrl:DoSequentialOpenView IsWoking false break")
        return
    end
	self.SequentialId = self.SequentialId + 1
	local ViewConfig = self.SequentialOpenViewList[self.SequentialId]

	if not ViewConfig then
        CWaring("LoginStepCtrl:DoSequentialOpenView End")
        self.IsWoking = false
		return
	end
	if ViewConfig.IsClose then
		CWaring("LoginStepCtrl:DoSequentialOpenView: Close Jump Next:" .. ViewConfig.ViewId)
		self:DoSequentialOpenView()
    elseif ViewConfig.CheckOpenFunc and not ViewConfig.CheckOpenFunc() then
        CWaring("LoginStepCtrl:DoSequentialOpenView: CheckOpenFunc false Jump Next:" .. ViewConfig.ViewId)
		self:DoSequentialOpenView()
    elseif ViewConfig.CustomWaitCustomLogic then
        CWaring("LoginStepCtrl:DoSequentialOpenView: CustomWaitCustomLogic")
        ViewConfig.CustomWaitCustomLogic()
    elseif ViewConfig.CustomLogic then
        CWaring("LoginStepCtrl:DoSequentialOpenView: CustomLogic")
        ViewConfig.CustomLogic()
        self:DoSequentialOpenView()
	else
        CWaring("LoginStepCtrl:DoSequentialOpenView: OpenView:" .. ViewConfig.ViewId)
		MvcEntry:OpenView(ViewConfig.ViewId,ViewConfig.Param)
	end
end


-------------------------------------------------------对外方法-----------------------------------------------------------

--[[
    开始执行欢迎界面显示流程
]]
function LoginStepCtrl:RunLoginStep()
    CWaring("LoginStepCtrl:RunLoginStep()")
    self:StepInit()
    self:DoSequentialOpenView()
end

function LoginStepCtrl:DynamicRegisterLoginStep(Step)
    CWaring("LoginStepCtrl:DynamicRegisterLoginStep()")
    self:StepInit()
    self.SequentialOpenViewList[#self.SequentialOpenViewList + 1] = Step
end


