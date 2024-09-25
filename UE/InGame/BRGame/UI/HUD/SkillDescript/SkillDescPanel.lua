-- 技能详情面板
--
-- @COMPANY	ByteDance
-- @AUTHOR	王泽平
-- @DATE	2023.10.17

local SkillDescPanel = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function SkillDescPanel:OnInit()
    print("SkillDescPanel >> OnInit")

    self.PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    -- region Event

    if self.SkillListWidget then
        self.SkillListWidget.OnUpdateItem:Add(self, self.OnUpdateSkillDescWidget)
    end


    -- endregion
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.UI_SkillDesc_SkillDetail_Down, Func = self.OnSkillDescKeyDown, bCppMsg = true, WatchedObject = nil },
        -- { MsgName = GameDefine.MsgCpp.UI_SkillDesc_SkillDetail_Up,   Func = self.OnSkillDescKeyUp,   bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,           Func = self.OnUpdatePlayerPawn, bCppMsg = true, WatchedObject = self.PC },
    }

    self:InitData()
    UserWidget.OnInit(self)
end

function SkillDescPanel:InitData()
    print("SkillDescPanel >> InitData")
    self.HeroSkillLst = {}
    self.SkillTagCfgCache = {}
    self.IsTextWidgetUseSimpleDesc = true
    self.bSelectHero = false
    -- endregion
    if self.PC and self.PC.PlayerState then
        local CurrentHeroId = UE.UPlayerExSubsystem.Get(self):GetPlayerRuntimeHeroId(self.PC.PlayerState:GetPlayerId())
        self:ReadDataTable(CurrentHeroId)
    end
end

function SkillDescPanel:OnShow()
    self:InitData()
end


function SkillDescPanel:OnDestroy()
    print("SkillDescPanel >> OnDestroy")
    UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------


-- region 读表
-- 改一点方便复用
function SkillDescPanel:ReadDataTable(InHeroId)
    print("[Wzp]SkillDescPanel:ReadDataTable InHeroId=",InHeroId)
    local CurrentHeroId = InHeroId

    self.HeroSkillLst = {}

    --region 读取英雄信息
    local HeroTypeCfgList = UE.UDataTableFunctionLibrary.GetDataTableRowNames(self.HeroCfg)
    for i = 1, HeroTypeCfgList:Length() do
        local DataTableRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.HeroCfg, HeroTypeCfgList:Get(i))
        local HeroId = DataTableRow.Id
        if CurrentHeroId == HeroId then
            if self.Text_Hero then
                self.Text_Hero:SetText(DataTableRow.Name) --设置英雄类型文本
            end
            break
        end
    end
    --endregion

    --region 读取英雄技能

    local HeroSkillCfgList = UE.UDataTableFunctionLibrary.GetDataTableRowNames(self.HeroSkillCfg)
    for i = 1, HeroSkillCfgList:Length() do
        local DataTableRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.HeroSkillCfg, HeroSkillCfgList:Get(i))

        local HeroId = DataTableRow.HeroId
        if CurrentHeroId == HeroId then
            local SkillTag = DataTableRow.SkillGameTag

            if SkillTag.TagName == "Skill.SkillTag.Passive" then
                self.HeroSkillLst[0] = DataTableRow
                --self.PassiveCfg = DataTableRow
            elseif SkillTag.TagName == "Skill.SkillTag.Tactical" then
                self.HeroSkillLst[1] = DataTableRow
                -- self.TacticalCfg = DataTableRow
            elseif SkillTag.TagName == "Skill.SkillTag.Ultimate" then
                self.HeroSkillLst[2] = DataTableRow
                -- self.UltimateCfg = DataTableRow
            end
        end

        if #self.HeroSkillLst >= 3 then
            break
        end
    end
    --endregion
    print("[Wzp]SkillDescPanel >> ReadDataTable > self.HeroSkillLst")
    GameLog.Dump(self.HeroSkillLst,self.HeroSkillLst)

    --region 读取技能标签
    local SkillTagCfgList = UE.UDataTableFunctionLibrary.GetDataTableRowNames(self.HeroSkillTagCfg)
    for i = 1, SkillTagCfgList:Length() do
        local DataTableRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.HeroSkillTagCfg,
            SkillTagCfgList:Get(i))
        self.SkillTagCfgCache[DataTableRow.SkillTag] = DataTableRow
    end
    --endregion

    print("[Wzp]SkillDescPanel >> ReadDataTable > self.SkillTagCfgCache")
    GameLog.Dump(self.SkillTagCfgCache,self.SkillTagCfgCache)

    local SkillNum = 3
    if  self.SkillListWidget then
        self.SkillListWidget:Reload(SkillNum)
    end


    -- self.SkillListWidget:Clear()
    -- for index = 1, SkillNum do
    --     self.SkillListWidget:AddOne(SkillNum)
    -- end
end

--endregion


function SkillDescPanel:OnUpdateSkillDescWidget(Widget, Index)
    print("SkillDescPanel >> OnUpdateSkillDescWidget > Index=", Index)
    local CurrentWidgetData = self.HeroSkillLst[Index]
    if not CurrentWidgetData then
        if self.Text_Hero then
            self.Text_Hero:SetText(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SkillDescPanel_Thereseemstobenoconf"))
        end
        Widget.Text_Des:SetText(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SkillDescPanel_Thereseemstobenoconf"))
        return
    end
   
    print("[Wzp]SkillDescPanel >> OnUpdateSkillDescWidget > SkillName=",SkillName)
    local SkillName =  StringUtil.Format(CurrentWidgetData.SkillName)
    local SkillDesSimple = StringUtil.Format(CurrentWidgetData.SkillDesSimple)
    local SkillDesDetail = StringUtil.Format(CurrentWidgetData.SkillDesDetail)
    local SkillCd = CurrentWidgetData.SkillCd
    local SkillType = StringUtil.Format(CurrentWidgetData.SkillType)
    local SkillIconSoft = CurrentWidgetData.SkillIconSoft
    local SkillGameTag = CurrentWidgetData.SkillGameTag
    local SkillTag = CurrentWidgetData.SkillTag

    if SkillGameTag.TagName == "Skill.SkillTag.Passive" then
        --被动技能不显示按键提示
        Widget.BP_InputKeyHintImage:SetVisibility(UE.ESlateVisibility.Collapsed)
        Widget.BP_SkillDesWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif SkillGameTag.TagName == "Skill.SkillTag.Tactical" then
        Widget.BP_InputKeyHintImage.InputAction = self.IA_Tactical
        Widget.BP_InputKeyHintImage:RefreshKeyIcon(self.IA_Tactical)
    elseif SkillGameTag.TagName == "Skill.SkillTag.Ultimate" then
        Widget.BP_InputKeyHintImage.InputAction = self.IA_Ultimate
        Widget.BP_InputKeyHintImage:RefreshKeyIcon(self.IA_Ultimate)
    end

    Widget.BP_SkillDesWidget:SetCDTime(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SkillDescPanel_scooling"), SkillCd))
    local SkillIconPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(SkillIconSoft)
    if SkillIconPtr then
        Widget.WBP_CommonSkillIcon.SkillIcon:SetBrushFromSoftTexture(SkillIconPtr, true)
    end

    local HeroSkillTagCfgData = self.SkillTagCfgCache[SkillTag]
    local TransSkillTag = StringUtil.Format(HeroSkillTagCfgData.SkillTagName)
    Widget.WBP_CommonSkillIcon.SkillTag:SetText(TransSkillTag)
    Widget.Text_SkillName:SetText(SkillName)
    if self.IsTextWidgetUseSimpleDesc then
        Widget.Text_Des:SetText(SkillDesSimple)
    else
        Widget.Text_Des:SetText(SkillDesDetail)
    end
    Widget.Text_Name:SetText(SkillType)
end

function SkillDescPanel:OnSkillDescKeyDown()
    self:SwitchSkillDesc()
end

function SkillDescPanel:SwitchSkillDesc()
    if self.bSelectHero == true then
        return
    end
    if not self.SkillListWidget then return end
    self.IsTextWidgetUseSimpleDesc = not self.IsTextWidgetUseSimpleDesc
    self.SkillListWidget:Refresh()
end

function SkillDescPanel:OnSkillDescKeyUp()
    print("SkillDescPanel >> OnSkillDescKeyUp")
    if not self.SkillListWidget then return end
    self.IsTextWidgetUseSimpleDesc = true
    self.SkillListWidget:Refresh()
end

function SkillDescPanel:OnUpdatePlayerPawn(InLocalPC, InPCPwn)
    print("SkillDescPanel >> OnUpdatePlayerPawn")
    if self.PC == InLocalPC and self.PC.PlayerState then
        local CurrentHeroId = UE.UPlayerExSubsystem.Get(self):GetPlayerRuntimeHeroId(self.PC.PlayerState:GetPlayerId())
        if CurrentHeroId <= 0 then
            return
        end
        print("SkillDescPanel >> OnUpdatePlayerPawn ReadDataTable()")
        self:ReadDataTable(CurrentHeroId)
    end
end

function SkillDescPanel:SetHeroTextVisible(IsVisible)
    if self.Overlay_HeroName then
        self.Overlay_HeroName:SetVisibility(IsVisible and UE.ESlateVisibility.HitTestInvisible or
        UE.ESlateVisibility.Collapsed)
    end

end

function SkillDescPanel:SetSkillListWidgetPadding(inItemPadding)
    self.bSelectHero = true
    if  self.SkillListWidget then
        self.SkillListWidget:SetItemPadding(math.tointeger(inItemPadding))
    end
end

return SkillDescPanel
