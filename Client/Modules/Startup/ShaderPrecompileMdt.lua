--[[
    着色器预编译界面
]]

local class_name = "ShaderPrecompileMdt";
ShaderPrecompileMdt = ShaderPrecompileMdt or BaseClass(GameMediator, class_name);

function ShaderPrecompileMdt:__init()
end

function ShaderPrecompileMdt:OnShow(data)
end

function ShaderPrecompileMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    CWaring("ShaderPrecompileMdt:OnInit")

    self.LbTip:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","ShaderPrecompileTip"))
    self.LbValue:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.MsgList = {
		{ Model = CommonModel, MsgName = CommonModel.ON_SHADER_PRECOMPILE_UPDATE, Func = self.ON_SHADER_PRECOMPILE_UPDATE_Func },
        { Model = CommonModel, MsgName = CommonModel.ON_SHADER_PRECOMPILE_COMPLETE, Func = self.ON_SHADER_PRECOMPILE_COMPLETE_Func },
	}	
    self.AlreadyUpdateTip = false
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    self:InsertTimer(Timer.NEXT_FRAME,function ()
        if not UE.UGFUnluaHelper.IsShaderPrecompilationManual() then
            self:DoClose()
        else
            UE.UGFUnluaHelper.ShaderPrecompilationResumeBatching()
        end
    end)
end

function M:OnRepeatShow(Param)
end
function M:OnHide() 
end

--[[
    着色器编译进度更新
    local Param = {
        RemainTasks = 1,
        TotalTasks = 100,
    }
]]
function M:ON_SHADER_PRECOMPILE_UPDATE_Func(Param)
    if not self.AlreadyUpdateTip then
        self.AlreadyUpdateTip = true
        -- self.LbTip:SetText("正在进行着色器预编译：")
        self.LbTip:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","ShaderPrecompileProgress"))
        self.LbValue:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    local ProgressValue = (Param.TotalTasks - Param.RemainTasks)/Param.TotalTasks
    self.LbValue:SetText(StringUtil.FormatSimple("{0}%",math.floor(ProgressValue*100)))
end

--[[
    着色器编译完成通知
    local Param = {
        TotalTasks = 100,
    }
]]
function M:ON_SHADER_PRECOMPILE_COMPLETE_Func(Param)
    self.LbValue:SetText(StringUtil.FormatSimple("{0}%",100))

    self:InsertTimer(0.2,function ()
        self:DoClose()
    end)
end

function M:DoClose()
    MvcEntry:CloseView(self.viewId)
end


return M
