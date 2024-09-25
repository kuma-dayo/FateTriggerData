---
--- Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 模式选择详细弹窗
--- Created At: 2023/07/21 11:00
--- Created By: 朝文
---

local class_name = "MatchModeSelect_PopMessageMdt"
---@class MatchModeSelect_PopMessageMdt : GameMediator
MatchModeSelect_PopMessageMdt = MatchModeSelect_PopMessageMdt or BaseClass(GameMediator, class_name)

function MatchModeSelect_PopMessageMdt:__init()
end

function MatchModeSelect_PopMessageMdt:OnShow(data) end
function MatchModeSelect_PopMessageMdt:OnHide() end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
        self.BindNodes = 
    {
		{ UDelegate = self.GUIButton_Close.OnClicked,				    Func = self.OnButtonClicked_Closed },
	}
    -- UIHandler.New(self, self.WCommonBtn_Confirm, WCommonBtnTips,
    --         {
    --             OnItemClick = Bind(self, self.OnButtonClicked_Closed),
    --             HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    --             CommonTipsID = CommonConst.CT_SPACE,
    --             TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectPopMessageMdt_confirm")),
    --             ActionMappingKey = ActionMappings.SpaceBar
    --         })
end

--[[
    Param 参考结构
    {
        PlayModeId = 玩法模式Id
    }
]]
function M:OnShow(Param)
    self.Data = Param

    self.WidgetSwitcher:SetActiveWidget(self.Panel_Image)

    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local PlayModeId = self.Data.PlayModeId

    local title = MatchModeSelectModel:GetPlayModeCfg_PlayModeName(PlayModeId)
    self.TxtTitle:SetText(StringUtil.Format(title))

    local desc = MatchModeSelectModel:GetPlayModeCfg_PopDetailDesc(PlayModeId)
    self.Text_Detail:SetText(StringUtil.Format(desc))

    local ImagePath = MatchModeSelectModel:GetPlayModeCfg_PopMessageImgPath(PlayModeId)
    CommonUtil.SetBrushFromSoftObjectPath(self.Img_Preview, ImagePath)
end

---反复打开界面，例如跳转回来时触发的逻辑
function M:OnRepeatShow(data)
end

function M:OnHide()
end

function M:OnButtonClicked_Closed()
    if self.Data and self.Data.CloseCallbackFunc then
        self.Data.CloseCallbackFunc()
    end
    
    MvcEntry:CloseView(ViewConst.MatchModeSelect_PopMessageMdt)
end

return M