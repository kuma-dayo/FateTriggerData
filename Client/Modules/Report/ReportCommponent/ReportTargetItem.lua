---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 举报对象item
--- Created At: 2023/09/01 11:44
--- Created By: 朝文
---

local class_name = "ReportTargetItem"
---@class ReportTargetItem
local ReportTargetItem = BaseClass(nil, class_name)

function ReportTargetItem:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.ButtonCombobox.OnClicked,    Func = Bind(self,self.OnButtonClicked_Combobox) },
        { UDelegate = self.View.WBP_Btn.GUIButton_Main.OnClicked,    Func = Bind(self,self.OnClick_CopyUID) },
    }

    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    ---@type CommonHeadIcon
    self.HeadIcon = UIHandler.New(self, self.View.WBP_CommonHeadIcon, CommonHeadIcon,
            {
                PlayerId   = UserModel:GetPlayerId(),
                ClickType  = CommonHeadIcon.ClickTypeEnum.None
            }).ViewInstance
end

function ReportTargetItem:OnShow(Param) end
function ReportTargetItem:OnHide()      end

--[[
    Param = {
        PlayerId = 1,
        PlayerName = "PlayerName" 
    }
--]]
function ReportTargetItem:SetData(Param)
    self.Data = Param
end

---@param ClickCallback fun(Data:table):void
function ReportTargetItem:SetClickCallback(ClickCallback)
    self.ClickCallback = ClickCallback
end

function ReportTargetItem:UpdateView()
    self.HeadIcon:UpdateUI({
        PlayerId   =  self.Data.PlayerId,
        ClickType  = CommonHeadIcon.ClickTypeEnum.None
    })
    self.View.Text_Name1:SetText(self.Data.PlayerName)
    -- self.View.Text_Name2:SetText(self.Data.PlayerName)
    -- self.View.Text_Name3:SetText(self.Data.PlayerName)
    
    self.View.Text_ID:SetText("ID: " .. self.Data.PlayerId)
end

function ReportTargetItem:Select()
    self.View.Text_ID:SetColorAndOpacity(self.View.Color_Select)
    self.View.Text_Name1:SetColorAndOpacity(self.View.Color_SelectName)
    -- self.View.Text_Name2:SetColorAndOpacity(self.View.Color_SelectName)
    -- self.View.Text_Name3:SetColorAndOpacity(self.View.Color_SelectName)
    --self.View.Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    -- self.View.GUIImage_Button_1:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.View.GUIImage_Button_2:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.View.GUIImage_Button_3:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.View.VXE_Btn_Select then
        self.View:VXE_Btn_Select()
    end
end

function ReportTargetItem:Unselect()
    self.View.Text_ID:SetColorAndOpacity(self.View.Color_Default)
    self.View.Text_Name1:SetColorAndOpacity(self.View.Color_DefultName)
    -- self.View.Text_Name2:SetColorAndOpacity(self.View.Color_DefultName)
    -- self.View.Text_Name3:SetColorAndOpacity(self.View.Color_DefultName)
    --self.View.Select:SetVisibility(UE.ESlateVisibility.Collapsed)

    -- self.View.GUIImage_Button_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.View.GUIImage_Button_2:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.View.GUIImage_Button_3:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.View.VXE_Btn_UnSelect then
        self.View:VXE_Btn_UnSelect()
    end
end

---点击复制当前展示的被举报玩家的id
function ReportTargetItem:OnClick_CopyUID()
    UE.UGFUnluaHelper.ClipboardCopy(StringUtil.ConvertFText2String(self.View.Text_ID:GetText()))
    UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Report', "Lua_ReportMdt_Copysucceeded"),3,self.View)
end

------------------------------------------------------- 按钮相关 ---------------------------------------------------------

function ReportTargetItem:OnButtonClicked_Combobox()
    if self.ClickCallback then
        self.ClickCallback(self.Data)
    end
end

return ReportTargetItem
