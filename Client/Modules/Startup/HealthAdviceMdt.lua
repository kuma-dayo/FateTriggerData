--[[
    健康游戏忠告
]]

local class_name = "HealthAdviceMdt";
HealthAdviceMdt = HealthAdviceMdt or BaseClass(GameMediator, class_name);

function HealthAdviceMdt:__init()
end

function HealthAdviceMdt:OnShow(data)
end

function HealthAdviceMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    local PopUpBgParam = {
        TitleText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","HealthAdviceTitle"),
        HideCloseTip = true,
    }
    UIHandler.New(self,self.WBP_CommonPopUp_Bg_L,CommonPopUpBgLogic,PopUpBgParam)
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    local ShowIime = 3
    if UE.UGFUnluaHelper.IsEditor() then
        ShowIime = 1   --编辑器环境，只展示X秒
    end
    self:InsertTimer(ShowIime,function ()
        self:DoClose()
    end)
end

function M:OnRepeatShow(Param)
    
end

function M:OnHide()
   
end


function M:OnFadeOutAnimationFinished()
    self:DoClose()
end

function M:DoClose()
    MvcEntry:CloseView(self.viewId) 
end

-- --[[
    -- 检查设备是否符合性能准入门槛
    -- 不符合，不让其进入游戏
-- ]]
-- function M:CheckDeviceMeetsTheStandards()
--     local IsEditor = UE.UGFUnluaHelper.IsEditor()
--     if IsEditor then
--         CWaring("CheckDeviceMeetsTheStandards IsEditor Break")
--         self:DoClose()
--         return
--     end
--     ---@type UserModel
-- 	local UserModel = MvcEntry:GetModel(UserModel)
--     if UserModel.IsLoginByCMD then
--         CWaring("CheckDeviceMeetsTheStandards IsLoginByCMD Break")
--         self:DoClose()
--         return
--     end
--     local CommandLine = UE.UKismetSystemLibrary.GetCommandLine()
--     local bSkipDeviceMeets = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "bSkipDeviceMeets=")
--     bSkipDeviceMeets = tonumber(bSkipDeviceMeets)
--     if bSkipDeviceMeets and bSkipDeviceMeets > 0 then
--         CWaring("CheckDeviceMeetsTheStandards bSkipDeviceMeets Break")
--         return
--     end

--     local IsDeviceMeets = UE.UGFUnluaHelper.IsDeviceMeetsTheStandards()
--     if not IsDeviceMeets then
--         CWaring("CheckDeviceMeetsTheStandards IsDeviceMeets false")
--         local msgParam = {
-- 			describe = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Startup","DeviceMeetsTheStandardsTip"),
-- 			rightBtnInfo = {                                        
-- 				callback = function()
-- 					CommonUtil.QuitGame()
-- 				end
-- 			},
--             HideCloseBtn = true,
--             HideCloseTip = true,
-- 		}
-- 		UIMessageBox.Show(msgParam)
--     else
--         self:DoClose()
--     end
-- end


return M
