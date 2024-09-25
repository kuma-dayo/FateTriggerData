require "UnLua"
local Watermark = Class("Common.Framework.UserWidget")

function Watermark:OnInit()
    print("Watermark:Initialize")

    self:UpdateQualityText()
    self.CliTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateUIDText}, 2.0, false, 0, 0)

    self.MsgList = {
        {MsgName = "Setting.Renderer.RenderingQuality", Func = self.UpdateQualityText, bCppMsg = true}
    }
    MsgHelper:RegisterList(self, self.MsgList)
    self:InitClientTime()
    UserWidget.OnInit(self)
end

function Watermark:OnDestroy()
    print("Watermark:OnDestroy")
    if self.GameStatusInfoViewModel then
        self.GameStatusInfoViewModel:K2_RemoveFieldValueChangedDelegateSimple("ClientTime",{self,self.UpdateClientTime})
        self.GameStatusInfoViewModel = nil
    end
end

function Watermark:UpdateUIDText()
    local GameState = UE.UGameplayStatics.GetGameState(self)
    local Uid = MvcEntry:GetModel(UserModel):GetPlayerId()
    local ClientCL,ClientStream = MvcEntry:GetModel(UserModel):GetP4ChangeList()
    local DSID = MvcEntry:GetModel(UserModel):GetDSGameIdShow()
    local DSVersion = tostring(GameState.DSChangelist)
    local AllWigets = self.WrapBoxScreen:GetAllChildren()
    for _, v in pairs(AllWigets) do
        v.Text_UID:SetText(tostring(Uid))
    end
    self.BP_Watermark1.GameID:SetText(StringUtil.Format("{0}-{1}-{2}", DSID,DSVersion,ClientCL))
    self.BP_Watermark1.Text_UID:SetText(tostring(Uid))
    -- self.BP_Watermark1.GameID:SetText(StringUtil.Format("GameID:{0}", DSID))
    -- self.BP_Watermark1.DSVersion:SetText(StringUtil.Format("DSVersion:{0}", DSVersion))
    -- self.BP_Watermark1.CLID:SetText(StringUtil.Format("CL:{0}", ClientCL))
end

function Watermark:UpdateQualityText()
    -- 尝试获取设置值
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if SettingSubsystem ~= nil then
        local RenderingQualityIndex = SettingSubsystem:GetSettingValue_int32ByTagName("Setting.Renderer.RenderingQuality")

        -- 检查获取的值是否有效
        if RenderingQualityIndex ~= nil then
            -- 定义渲染质量对应的文本
            local qualityText = {
                [0] = StringUtil.Format(G_ConfigHelper:GetStrFromIngameStaticST("SD_SettingInside", "low")),
                [1] = StringUtil.Format(G_ConfigHelper:GetStrFromIngameStaticST("SD_SettingInside", "med")),
                [2] = StringUtil.Format(G_ConfigHelper:GetStrFromIngameStaticST("SD_SettingInside", "high")),
                [3] = StringUtil.Format(G_ConfigHelper:GetStrFromIngameStaticST("SD_SettingInside", "superhigh")),
                [4] = StringUtil.Format(G_ConfigHelper:GetStrFromIngameStaticST("SD_SettingInside", "Film"))
            }

            -- 获取对应的文本，如果索引无效则使用默认值
            local qualityString = qualityText[RenderingQualityIndex] or StringUtil.Format(G_ConfigHelper:GetStrFromIngameStaticST("SD_SettingInside", "Unknown"))

            -- 更新文本显示
            self.BP_Watermark1.Text_RenderingQuality:SetText(qualityString)
        end
    end
end

function Watermark:InitClientTime()
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if not UIManager then return end
    self.GameStatusInfoViewModel = UIManager:GetViewModelByName("TagLayout.GamePlay.GameStatusInfo")
    if not self.GameStatusInfoViewModel then return end
    self.GameStatusInfoViewModel:K2_AddFieldValueChangedDelegateSimple("ClientTime",{self,self.UpdateClientTime})
end

function Watermark:UpdateClientTime(vm, fieldID)
    self.BP_Watermark1.ClientTime:SetText(vm.ClientTime)
end

return Watermark