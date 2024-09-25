--[[
    Loading蓝图对应的Lua代理
]]
local BP_Loading = Class("Client.Mvc.UserWidgetBase")

function BP_Loading:OnInit()
    CWaring("BP_Loading:OnInit")

    -- self.LbTips:SetText(MvcEntry:GetCtrl(LoadingCtrl):GetTipSelect())
    -- CommonUtil.SetBrushFromSoftObjectPath(self.GUIImageBg,MvcEntry:GetCtrl(LoadingCtrl):GetImgSelect())

    -- if CommonUtil.IsShipping() or not UE.UAsyncLoadingScreenLibrary.GetIsEnableLoadingDebugShow() then
    --     self.DebugPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- else
    --     --TODO 非Shipping模式展示CL相关DEBUG信息
    --     self.DebugPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    --     local TheUserModel = MvcEntry:GetModel(UserModel)
    --     self.LbClientCl:SetText(TheUserModel:GetClientP4Show())
    --     self.LbSeverCl:SetText(TheUserModel:GetGatewayP4Show())
    --     self.LbDsCl:SetText(TheUserModel:GetDSP4Show())
    --     self.LbGameId:SetText(TheUserModel:GetDSGameIdShow())
    --     self.LbKeyStep:SetText("--")

    --     --临时注释，在修复另一个偶现崩溃，这个先注释
    --     -- self.MsgList = 
    --     -- {
    --     --     {Model = CommonModel, MsgName = CommonModel.ON_CLIENT_HIT_KEY_STEP, Func = self.ON_CLIENT_HIT_KEY_STEP_Func },
    --     -- }
    -- end
end

function BP_Loading:OnShow(InData)
end

function BP_Loading:OnHide()
end

-- function BP_Loading:ON_CLIENT_HIT_KEY_STEP_Func(Msg)
--     if not Msg then
--         return
--     end
--     self.LbKeyStep:SetText("" .. Msg)
-- end

return BP_Loading
