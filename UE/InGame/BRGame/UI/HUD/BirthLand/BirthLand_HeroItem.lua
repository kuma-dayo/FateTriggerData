require "UnLua"

local BirthLand_HeroItem = Class("Common.Framework.UserWidget")


function BirthLand_HeroItem:OnInit()

    UserWidget.OnInit(self)
    self.TeamPosTable = {}
    self.Btn_Item.OnClicked:Add(self, self.OnClickedEvent)
    self.Btn_Item.OnHovered:Add(self, self.OnHoveredEvent)
    self.Btn_Item.OnUnhovered:Add(self, self.OnUnhoveredEvent)

    self.Img_Bg_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Select_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.VerBox_Mark:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Bg_Line:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function BirthLand_HeroItem:OnClickedEvent()
    if self.Parent then
        if self.Parent.BirthlandAbilityPtr and self.Parent.BirthlandAbilityPtr.bShouldHeroDifferent and self.Picked then
            print("nzyp " .. "bShouldHeroDifferent",self.Parent.BirthlandAbilityPtr.bShouldHeroDifferent)
        end
        --self.Parent:UpdateSelfInfoAndSkillInfo(self.HeroId)
        self.Parent:OnPrePickHero(self.HeroId)
    end
end

function BirthLand_HeroItem:CanPick()
    if self.Parent and self.Parent.BirthlandAbilityPtr then
        if not self.Parent.BirthlandAbilityPtr.bShouldHeroDifferent then
            return true
        elseif not self.Picked then
            return true
        end
    end
    return false
end

function BirthLand_HeroItem:OnHoveredEvent()
    --self.Border_HeroName_Hover:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
end

function BirthLand_HeroItem:OnUnhoveredEvent()
    --self.Border_HeroName_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function BirthLand_HeroItem:SetDataByHeroConfig(HeroId, HeroIcon, HeroName, BirthLandWidget)
    self.Parent = BirthLandWidget
    self.HeroId = HeroId
    local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(HeroIcon)
    self.ImgIcon_Avatar:SetBrushFromSoftTexture(ImageSoftObjectPtr,true)
    --self.Text_HeroName:SetText(HeroName)
end

--队友没有预选效果，只有我有预选表现
function BirthLand_HeroItem:SetPrePick(TeamPos)
    if TeamPos <= 0 then
        self.Img_Bg_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.Img_Bg_Selected:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    end
end

function BirthLand_HeroItem:ClearPick(TeamPos)
    print("nzyp " .. "ClearPick-- TeamPos", TeamPos)
    for index = #self.TeamPosTable, 1, -1 do
        if self.TeamPosTable[index] == TeamPos then
            table.remove(self.TeamPosTable, index)
        end
    end
    self.VerBox_Mark:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Select_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Bg_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Bg_Line:SetVisibility(UE.ESlateVisibility.Collapsed)
    if #self.TeamPosTable <= 0 then
        print("nzyp " .. "ClearPick-- 11111111111111111")
        self.Picked = false
    else
        print("nzyp " .. "ClearPick-- 22222222222222222")
        local FirstTeamPos = self.TeamPosTable[1]
        self:SetPick(FirstTeamPos, self.LocalTeamPos and FirstTeamPos == self.LocalTeamPos)
        
        local HasLocal = false
        for index = 1, #self.TeamPosTable do
            if self.TeamPosTable[index] == self.LocalTeamPos then
                HasLocal = true
            end
        end
        if self.LocalTeamPos and HasLocal then
            self.Img_Select_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.Img_Select_Mask:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        end
    end
end

function BirthLand_HeroItem:SetPick(TeamPos, IsLocal)
    print("nzyp " .. "SetPick-- TeamPos", TeamPos, IsLocal)
    if TeamPos > 0 then
        local ImgColor = MinimapHelper.GetTeamMemberColor(TeamPos)
        self.WBP_Birthland_CornerMark_Item.Text_TeamPosition:SetText(TeamPos)
        self.WBP_Birthland_CornerMark_Item.ImgBg_Text:SetColorAndOpacity(ImgColor)

        local SlateColor = UE.FSlateColor()
        SlateColor.SpecifiedColor = ImgColor;
        self.Img_Bg_Line:SetBrushTintColor(SlateColor)

        self.VerBox_Mark:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.Img_Bg_Selected:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.Img_Bg_Line:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        if IsLocal then
            self.Img_Select_Mask:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.LocalTeamPos = TeamPos
        else
            self.Img_Select_Mask:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        end
        self.Picked = true
        self.TeamPosTable[#self.TeamPosTable+1] = TeamPos
    end
end

function BirthLand_HeroItem:SetIsLock(IsLock)
    print("nzyp " .. "SetIsLock ", IsLock)
    if IsLock then
        self.ImgIcon_Avatar:SetOpacity(self.Opacity_Avatar_Locked)
        self.ImgIcon_Locked:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.Btn_Item:SetIsEnabled(false)
    else
        self.ImgIcon_Avatar:SetOpacity(self.Opacity_Avatar_Unlocked)
        self.ImgIcon_Locked:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Btn_Item:SetIsEnabled(true)
    end
    
end
return BirthLand_HeroItem