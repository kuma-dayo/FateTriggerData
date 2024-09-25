


local MobileDoorTip = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------
function MobileDoorTip:OnInit()
    print("MobileDoorTip:OnInit")
   -- self.MobileTipsButton.OnClicked:Add(self, self.OnClicked_SendMessage)
    self:InitUIEvent()
    self:InitData()

    UserWidget.OnInit(self)
end

function MobileDoorTip:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard, InContext)
    print("MobileDoorTip:OnTipsInitialize")
    if InContext ==nil then
        return
    end
    if UE.UKismetSystemLibrary.IsValid(InContext) then
        print("MobileDoorTip:OnTipsInitialize")
        self.InSkillGA = InContext

        local Door =InContext.GetDoorComponent and InContext:GetDoorComponent() or nil
        --因为在进门的的下一帧才能showtips,所以如果同一帧进门和出门的范围，在下一帧是会拿不到门的，所以统一做一次判空不作为，等remove
        if UE.UKismetSystemLibrary.IsValid(Door) then
            local DoorState = Door:GetCurInteractiveState()
            print("MobileDoorTip:OnTipsInitialize",GetObjectName(Door),DoorState)
            if DoorState == UE.EDoorInteractiveState.Closed then
                self.TextBlock_InteractiveName:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MobileDoorTip_openthedoor")))
            elseif DoorState == UE.EDoorInteractiveState.Opened_In or DoorState == UE.EDoorInteractiveState.Opened_Out then
                self.TextBlock_InteractiveName:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MobileDoorTip_closeadoor")))
            end

            if BridgeHelper.IsMobilePlatform() then
                -- 自动开门显示设置
                self.TextBlock_AutoName:SetText(InContext.CanAutoOpenDoor and "##自动" or "##手动")
            end
        end   
    end 
end


function MobileDoorTip:OnDestroy()
    UserWidget.OnDestroy(self)
end

function MobileDoorTip:InitUIEvent()
    -- 当前PC和移动端共用了一个lua文件
    if BridgeHelper.IsMobilePlatform() then
        self.Button_AutoOpen.OnClicked:Add(self, self.OnClick_AutoOpen)
    end
end

function MobileDoorTip:InitData()
    -- 当前界面上下文传入是skillGA
    self.InSkillGA = nil
end

-- UI EVENT
function MobileDoorTip:OnClick_AutoOpen()
    print("MobileDoorTip:OnClick_AutoOpen")
    if UE.UKismetSystemLibrary.IsValid(self.InSkillGA) then
        self.InSkillGA:SetCanAutoOpenDoor(not self.InSkillGA.CanAutoOpenDoor)
        self.TextBlock_AutoName:SetText(self.InSkillGA.CanAutoOpenDoor and "##自动" or "##手动")

        print("MobileDoorTip:OnClick_AutoOpen set value:", self.InSkillGA.CanAutoOpenDoor)
    end
end
-------------------------------------------- Function ------------------------------------



return MobileDoorTip