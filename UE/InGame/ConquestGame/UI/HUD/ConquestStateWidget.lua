--
-- 征服点状态UI
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2023.08.04
--

local ConquestStateWidget = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function ConquestStateWidget:OnInit()
	print("ConquestStateWidget", string.format(">> %s:OnInit, ...", GetObjectName(self)))
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.LocalCampId = -1
    self.BindNodes = {
    }
	self.MsgList = {
    }

	UserWidget.OnInit(self)

end

function ConquestStateWidget:OnDestroy()

	UserWidget.OnDestroy(self)
end

-- 
local ConquestStateShowMode = {
    Middle = 1,
    Up = 2,
    Float = 3,
}
function ConquestStateWidget:ChangeShowMode(ShowMode)
    self.ShowMode = ShowMode
    self.Text_State_Down:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Text_State_Up:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Image_Arrow:SetVisibility(UE.ESlateVisibility.Collapsed)

    if ShowMode == ConquestStateShowMode.Middle then
        self.Text_State_Down:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    elseif ShowMode == ConquestStateShowMode.Up then
    elseif ShowMode == ConquestStateShowMode.Float then
        self.Text_State_Up:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        --self.Image_Arrow:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Text_State_Down:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

end

function ConquestStateWidget:SelectTargetColor_RGW(ColorName,SameCamp,OwnerCamp)
    local Name  = SameCamp and "Green" or OwnerCamp and "Red" or "None"
    return self[ColorName .."_"..Name]
end

function ConquestStateWidget:SelectTargetColor_RG(ColorName,SameCamp)
    local Name  = SameCamp and "Green" or "Red"
    return self[ColorName .."_"..Name]
end

function ConquestStateWidget:SetDistance(InPlayerController, InZone)
    if InPlayerController.Pawn then
        local SelfPos = InPlayerController.Pawn:K2_GetActorLocation()
        local TargetPos = InZone:K2_GetActorLocation()
        local ToTargetDist = UE.UKismetMathLibrary.Vector_Distance(TargetPos, SelfPos)
        local ToTargetDistM = math.floor(ToTargetDist * 0.01)
        self.Text_State_Down:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ConquestStateWidget_meters"),ToTargetDistM))
        self.Text_State_Down:SetColorAndOpacity(self.DistanceTextColor)
    end
 
end

function ConquestStateWidget:SetConquestData(InConquestZoneData)
    --print("ConquestStateWidget:SetConquestData ZoneName ",InConquestZoneData.ZoneName)
    if self.LocalCampId == -1 then
        self.LocalCharacter = self.LocalPC.Character
        if self.LocalCharacter then
            self.LocalCampId = self.LocalCharacter:GetCampId()
        end
    end

    if  self.LocalCampId == -1 then
        return
    end


    local bSameCampOwnerToLocal = InConquestZoneData.OwnerCampId == self.LocalCampId
    local bSameCampOwnerToOccupying = InConquestZoneData.OwnerCampId == InConquestZoneData.OccupyingCampId 
    local bNoneOwnerCamp = InConquestZoneData.OwnerCampId == -1
    local bOwnerOccupying = InConquestZoneData.LastOccupyingCampId == -1 and InConquestZoneData.OccupyingCampId == self.LocalCampId or  InConquestZoneData.LastOccupyingCampId == self.LocalCampId
    local bHasOwnerCamp = InConquestZoneData.OwnerCampId > 0
    -- 征服点名称及颜色
    self.Text_PointName:SetText(InConquestZoneData.ZoneName)
    self.Text_PointName:SetColorAndOpacity(self:SelectTargetColor_RGW("TextColor",bSameCampOwnerToLocal,bHasOwnerCamp))
    -- 征服点玩家人数对比
    self.Panel_Progress:SetVisibility(UE.ESlateVisibility.Collapsed)
    if InConquestZoneData.CharacterDataList:Num() > 0 then
        local SelfCampPlayerNum = 0
        local OtherCampPlayerNum = 0
        for i = 1, InConquestZoneData.CharacterDataList:Length() do
            local CharacterData = InConquestZoneData.CharacterDataList:Get(i)
            if UE.UConquestZoneSubsystem.IsInConquestZone(InConquestZoneData.OwnerConquestZone,CharacterData)  then --CharacterData.CurPawn and CharacterData.bInZone
                if CharacterData.CurPawn:GetCampId() == self.LocalCampId then
                    SelfCampPlayerNum = SelfCampPlayerNum + 1
                else
                    OtherCampPlayerNum = OtherCampPlayerNum + 1
                end
            end
        end
    
        if SelfCampPlayerNum == 0 or OtherCampPlayerNum == 0 then
            self.Panel_Progress:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.Panel_Progress:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            local NumPercent = 1.0 * SelfCampPlayerNum / (SelfCampPlayerNum + OtherCampPlayerNum)
            self.ProgressBar_Num:SetPercent(NumPercent)
            self.Text_Num1:SetText(tostring(SelfCampPlayerNum))
            self.Text_Num2:SetText(tostring(OtherCampPlayerNum))
        end
    end

    --征服点进度条数值
    self.ProgressBar:SetPercent(InConquestZoneData.CampOccupyingPersent)
    local StateText = ""
    local StateTextColor = nil
    if InConquestZoneData.ConquestZoneState == UE.EConquestZoneStateType.State_None then
        -- 进度条背景
        self.Image_ProgressBg:SetColorAndOpacity(self.ProgressBgColor_None)
        -- 背景
        self.Image_Bg:SetColorAndOpacity(self.BgColor_None)
        -- 边条装饰
        self.Image_Outside:SetColorAndOpacity(self.OutsideColor_None)
        -- 进度条颜色
        self.ProgressBar:SetFillColorAndOpacity(self:SelectTargetColor_RG("ProgressColor_Unlight",bSameCampOwnerToLocal or bOwnerOccupying))
        -- 状态文字
        StateText = ""
        StateTextColor = self.TextColor_None
    elseif InConquestZoneData.ConquestZoneState == UE.EConquestZoneStateType.State_Occupation then
        -- 进度条背景
        self.Image_ProgressBg:SetColorAndOpacity(self:SelectTargetColor_RGW("ProgressBgColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 背景
        self.Image_Bg:SetColorAndOpacity(self:SelectTargetColor_RGW("BgColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 边条装饰
        self.Image_Outside:SetColorAndOpacity(self:SelectTargetColor_RGW("OutsideColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 进度条颜色
        self.ProgressBar:SetFillColorAndOpacity(self:SelectTargetColor_RG("ProgressColor_HighLight",bSameCampOwnerToLocal))
        -- 状态文字
        if bSameCampOwnerToLocal then
            StateText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ConquestStateWidget_Occupied"))
            StateTextColor = self.TextColor_Green
        else
            StateText =  StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ConquestStateWidget_Occupied"))
            StateTextColor = self.TextColor_Red
        end
    elseif InConquestZoneData.ConquestZoneState == UE.EConquestZoneStateType.State_Occupying then
        -- 进度条背景
        self.Image_ProgressBg:SetColorAndOpacity(self:SelectTargetColor_RGW("ProgressBgColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 背景
        self.Image_Bg:SetColorAndOpacity(self:SelectTargetColor_RGW("BgColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 边条装饰
        self.Image_Outside:SetColorAndOpacity(self:SelectTargetColor_RGW("OutsideColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 进度条颜色
        local color = bNoneOwnerCamp and bOwnerOccupying or bSameCampOwnerToLocal
        self.ProgressBar:SetFillColorAndOpacity(self:SelectTargetColor_RG("ProgressColor_HighLight",color)) --or bOwnerOccupying
        -- 状态文字
        if InConquestZoneData.OccupyingCampId == self.LocalCampId then
            StateText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ConquestStateWidget_Underoccupation"))
            StateTextColor = self.TextColor_Green
        else
            StateText =  StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ConquestStateWidget_Lost"))
            StateTextColor = self.TextColor_Red
        end
      
    elseif InConquestZoneData.ConquestZoneState == UE.EConquestZoneStateType.State_Dispute then
        -- 进度条背景
        self.Image_ProgressBg:SetColorAndOpacity(self:SelectTargetColor_RGW("ProgressBgColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 背景
        self.Image_Bg:SetColorAndOpacity(self:SelectTargetColor_RGW("BgColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 边条装饰
        self.Image_Outside:SetColorAndOpacity(self:SelectTargetColor_RGW("OutsideColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 进度条颜色
        self.ProgressBar:SetFillColorAndOpacity(self:SelectTargetColor_RG("ProgressColor_Unlight",bSameCampOwnerToLocal or bOwnerOccupying))
        -- 状态文字
        StateText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ConquestStateWidget_Contention"))
        StateTextColor = self:SelectTargetColor_RG("TextColor",bOwnerOccupying)
    elseif InConquestZoneData.ConquestZoneState == UE.EConquestZoneStateType.State_Suppression then
        -- 进度条背景
        self.Image_ProgressBg:SetColorAndOpacity(self:SelectTargetColor_RGW("ProgressBgColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 背景
        self.Image_Bg:SetColorAndOpacity(self:SelectTargetColor_RGW("BgColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 边条装饰
        self.Image_Outside:SetColorAndOpacity(self:SelectTargetColor_RGW("OutsideColor",bSameCampOwnerToLocal,bHasOwnerCamp))
        -- 进度条颜色
        self.ProgressBar:SetFillColorAndOpacity(self:SelectTargetColor_RG("ProgressColor_HighLight",bSameCampOwnerToLocal or bOwnerOccupying))
        -- 状态文字
        StateText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ConquestStateWidget_Underpressure"))
        StateTextColor = self:SelectTargetColor_RG("TextColor",bOwnerOccupying)
    end

    if self.ShowMode == ConquestStateShowMode.Middle then
        self.Text_State_Down:SetText(StateText)
        self.Text_State_Down:SetColorAndOpacity(StateTextColor)
    elseif self.ShowMode == ConquestStateShowMode.Float then
        self.Text_State_Up:SetText(StateText)
        self.Text_State_Up:SetColorAndOpacity(StateTextColor)
    end
end




return ConquestStateWidget
