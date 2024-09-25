require "UnLua"

local GenericMissionUI = Class("Common.Framework.UserWidget")

function GenericMissionUI:Initialize(Initializer)
    print("GenericMissionUI:Initialize")
    self.MissionMap = {}
end

function GenericMissionUI:OnInit()
    print("GenericMissionUI:OnInit")
    -- 注册消息监听
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.GenericMission_Msg_ShowMission,                 Func = self.OnShowMission,         bCppMsg = true },

    }

    UserWidget.OnInit(self)
end

function GenericMissionUI:OnDestroy()
    UserWidget.OnDestroy(self)
end

function GenericMissionUI:OnShowMission(bShow)
    print("GenericMissionUI:OnShowMission")
    if bShow then
        self:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    local MissionSubSystem = UE.UMissionSubSystem.Get(GameInstance)
    if MissionSubSystem ~= nil then
        for _, GroupPtr in pairs(MissionSubSystem.MissionGroups) do
            if self.MissionMap[GroupPtr.MissionId] == nil then
                local ItemWidget = UE.UWidgetBlueprintLibrary.Create(self, self.ItemWidgetClass)
                self.VerticalBox_List:AddChild(ItemWidget)
                self.MissionMap[GroupPtr.MissionId] = ItemWidget
            end
            self.MissionMap[GroupPtr.MissionId]:BP_SetMissionInfo(GroupPtr)
        end
    end




end



return GenericMissionUI
