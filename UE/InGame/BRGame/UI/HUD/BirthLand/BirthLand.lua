require "UnLua"

local BirthLand = Class("Common.Framework.UserWidget")

function BirthLand:OnInit()
    print("BirthLand:OnInit")
    -- 注册消息监听
	self.MsgList = {
        --{ MsgName = GameDefine.MsgCpp.UISync_Update_RuntimeHeroId,                  Func = self.UpdateRuntimeHeroId,                  bCppMsg = true },
        --{ MsgName = GameDefine.MsgCpp.UISync_Update_PrePickHeroId,                  Func = self.UpdatePrePickHeroId,                  bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.PLAYER_TeammatePSList,     	Func = self.ReceiveUpdatePSList,	bCppMsg = true, WatchedObject = nil},
        { MsgName = GameDefine.MsgCpp.PLAYER_PSTeamPos,     	Func = self.ReceiveUpdateTeamPos,	bCppMsg = true, WatchedObject = nil},
    }
    MsgHelper:RegisterList(self, self.MsgList)
    UserWidget.OnInit(self)
    self.GUVViewModel_Birthland:K2_AddFieldValueChangedDelegateSimple("CurTimePeriod",{self,self.ReceiveCurTimePeriod})
    self.GUVViewModel_Birthland:K2_AddFieldValueChangedDelegateSimple("CountDownTime",{self,self.ReceiveCountDownTime})
    self.GUVViewModel_Birthland:K2_AddFieldValueChangedDelegateSimple("BaseVirtualCurrency",{self,self.ReceiveBaseVirtualCurrency})
    self.GUVViewModel_Birthland.PrePickHeroIdListEvent:Add(self,self.ReceivePrePickHeroIdList)
    self.GUVViewModel_Birthland.TeamMemberPrePickHeroEvent:Add(self,self.ReceiveTeamMemberPrePickHero)
    self.GUVViewModel_Birthland.TeamMemberRuntimeHeroEvent:Add(self,self.ReceiveTeamMemberRuntimeHero)
    self.GUVViewModel_Birthland.TeamMemberRuntimeSkinEvent:Add(self,self.ReceiveTeamMemberRuntimeSkin)
    self.PlayerIdToWidgetIndexTable = {}
    
    self:InitWidget()
    
    self.ShowSkillInfo = true
    self:OnToggleSkillInfo()
    self.GUIButton_Confirm.OnClicked:Add(self, self.OnConfirmClick)
    self.Button_Close.OnClicked:Add(self, self.CloseSelf)
    if BridgeHelper.IsMobilePlatform() then
        self.ImgIcon_SkillKey:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WidgetSwitcher_SkillStage:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ControlTipsIcon_1:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    self.ShowCurrencyInfo = false

    if self.ShowCurrencyInfo then
        self.GUICanvasPanel_Currency:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    self.WBP_Common_SocialBtn.GUIButton_Main.OnClicked:Add(self, self.OnOpenEditCurrency)

    self.HeroListArray:Add(self.HorBox_Assault)
    self.HeroListArray:Add(self.HorBox_Protect)
    self.HeroListArray:Add(self.HorBox_Support)
    self.HeroListArray:Add(self.HorBox_Information)

end

function BirthLand:OnDestroy()
    self.GUVViewModel_Birthland:K2_RemoveFieldValueChangedDelegateSimple("CurTimePeriod",{self,self.ReceiveCurTimePeriod})
    self.GUVViewModel_Birthland:K2_RemoveFieldValueChangedDelegateSimple("CountDownTime",{self,self.ReceiveCountDownTime})
    self.GUVViewModel_Birthland:K2_RemoveFieldValueChangedDelegateSimple("BaseVirtualCurrency",{self,self.ReceiveBaseVirtualCurrency})
    self.GUVViewModel_Birthland.PrePickHeroIdListEvent:Remove(self,self.ReceivePrePickHeroIdList)
    self.GUVViewModel_Birthland.TeamMemberPrePickHeroEvent:Remove(self,self.ReceiveTeamMemberPrePickHero)
    self.GUVViewModel_Birthland.TeamMemberRuntimeHeroEvent:Remove(self,self.ReceiveTeamMemberRuntimeHero)
    self.GUVViewModel_Birthland.TeamMemberRuntimeSkinEvent:Remove(self,self.ReceiveTeamMemberRuntimeSkin)

    self.GUIButton_Confirm.OnClicked:Remove(self, self.OnConfirmClick)
    self.Button_Close.OnClicked:Remove(self, self.CloseSelf)
    self.WBP_Common_SocialBtn.GUIButton_Main.OnClicked:Remove(self, self.OnOpenEditCurrency)

    UserWidget.OnDestroy(self)

end

function BirthLand:OnShow(InContext, Blackboard)
    local TypeTxtList = {
        self.Text_Assault,
        self.Text_Protect,
        self.Text_Support,
        self.Text_Message,
    }
    local TypeIconList = {
        self.Img_Assault,
        self.Img_Protect,
        self.Img_Support,
        self.Img_Message,
    }
    if self.BirthlandAbilityPtr then
        for i = 1, self.HeroListArray:Length(), 1 do
            local BirthlandHeroTypeConfig = self.BirthlandAbilityPtr:GetTypeConfigByHeroType(i)
            if BirthlandHeroTypeConfig then
                if TypeTxtList[i] then
                    TypeTxtList[i]:SetText(BirthlandHeroTypeConfig.Name)
                end
                if TypeIconList then
                    CommonUtil.SetBrushFromSoftObjectPath(TypeIconList[i], UE.UKismetSystemLibrary.BreakSoftObjectPath(BirthlandHeroTypeConfig.TypeIconSoft))
                end
            end
        end
    end
    --self:UpdateAllTeammate()
end

function BirthLand:OnClose()
    print("BirthLand:OnClose()")
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager then
        UIManager:TryCloseDynamicWidget("UMG_Birthland_EditCurrency")
    end
end

function BirthLand:GetSkillDescPanel()
    if not self.CacheSkillDescPanel then
        self.CacheSkillDescPanel = self.SkillDescPanel:FindFirstChild()
    end
    return self.CacheSkillDescPanel
end


function BirthLand:InitWidget()
    local PlayerNum = 4
    print("nzyp " .. "PlayerNum",PlayerNum)
    for i = 1, PlayerNum do
        local PlayerListItem = UE.UWidgetBlueprintLibrary.Create(self, self.PlayerListItem)
        self.VerticalBox_PlayerList:AddChild(PlayerListItem)
        PlayerListItem:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function BirthLand:OnConfirmClick()
    if not self.GUIButton_Confirm:GetIsEnabled() then
        print("nzyp " .. "OnConfirmClick button is not enable")
        return
    end
    if self.PrePickHeroId then
        if self.PrePickHeroId ~= self.RuntimeHeroId then
            print("nzyp " .. "confirm",self.PrePickHeroId)
            self:OnClick_RuntimeHero(self.PrePickHeroId)
            if self.RuntimeHeroId and self.HeroItemArray then
                for index = 1, self.HeroItemArray:Length() do
                    local EachHeroItem = self.HeroItemArray:Get(index)
                    if EachHeroItem then
                        if self.RuntimeHeroId == EachHeroItem.HeroId then
                            EachHeroItem:SetPrePick(-1)
                        end
                    end
                end
            end
        end

    end
end

function BirthLand:OnPrePickHero(HeroId)
    if self.PrePickHeroId ~= HeroId then
        print("nzyp " .. "OnPrePickHero",self.PrePickHeroId, HeroId)
        self:OnClick_PrePickHero(HeroId)
    end
end


function BirthLand:ReceiveCurTimePeriod(vm, fieldID)
    print("nzyp " .. "ReceiveCurTimePeriod", vm.CurTimePeriod)
    if not self.BirthlandAbilityPtr then
        return
    end
    for index = self.BirthlandAbilityPtr.TimePeriodConfig:Length(), 1, -1 do
        if vm.CurTimePeriod <= self.BirthlandAbilityPtr.TimePeriodConfig:Get(index).ReserveTime then
            self.Text_Countdown:SetColorAndOpacity(self.BirthlandAbilityPtr.TimePeriodConfig:Get(index).FontColor)
            if index == self.BirthlandAbilityPtr.TimePeriodConfig:Length() then
                self.Button_Close:SetVisibility(UE.ESlateVisibility.Collapsed)
                self:CloseSelf()
            end
            break
        end
    end
end

function BirthLand:ReceiveCountDownTime(vm, fieldID)
    --print("nzyp " .. "ReceiveCountDownTime", vm.CountDownTime)
    
    if self.Text_Countdown then
        self.Text_Countdown:SetText(vm.CountDownTime)
    end
end


function BirthLand:ReceivePrePickHeroIdList(HeroIdList)
    print("nzyp " .. "ReceivePrePickHeroIdList", HeroIdList)
    self:UpdateHeroList()
    self:UpdateAllTeammate()
end

function BirthLand:ReceiveTeamMemberPrePickHero(pInTeamMemberPS, PrePickHeroId)
    print("nzyp " .. "PrePickHeroIdEvent", PrePickHeroId)

    if pInTeamMemberPS then
        if not self.BirthlandAbilityPtr then
            print("nzyp " .. "PrePickHeroIdEvent-- self.BirthlandAbilityPtr nil")
            return
        end
        local LocalPS = self.BirthlandAbilityPtr:GetOwningPlayerState()
        if not LocalPS then
            print("nzyp " .. "PrePickHeroIdEvent-- LocalPS nil")
            return
        end

        print("nzyp " .. "PrePickHeroIdEvent-- playerid and prepickheroid", pInTeamMemberPS.PlayerId, PrePickHeroId)
        local TeamIndex = UE.UTeamExSubsystem.Get(self):GetPlayerNumberInTeamByPS(pInTeamMemberPS)
        local PlayerWidget = self.VerticalBox_PlayerList:GetChildAt(TeamIndex-1)
        if PlayerWidget then
            print("nzyp " .. "PrePickHeroIdEvent-- TeamIndex", TeamIndex)
            PlayerWidget:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
            PlayerWidget:SetDataFromPS(pInTeamMemberPS,LocalPS,self.BirthlandAbilityPtr)
        end

        if LocalPS == pInTeamMemberPS then
            print("nzyp " .. "PrePickHeroIdEvent-- handle Local")
            if self.PrePickHeroId ~= PrePickHeroId and self.HeroItemArray then
                --清除上一个预选状态
                for index = 1, self.HeroItemArray:Length() do
                    local EachHeroItem = self.HeroItemArray:Get(index)
                    if EachHeroItem then
                        if self.PrePickHeroId and self.PrePickHeroId == EachHeroItem.HeroId  then
                            if not self.RuntimeHeroId or (self.RuntimeHeroId and self.RuntimeHeroId ~= EachHeroItem.HeroId) then
                                EachHeroItem:SetPrePick(-1)
                            end
                        end
                        if PrePickHeroId == EachHeroItem.HeroId then
                            EachHeroItem:SetPrePick(1)
                        end
                    end
                end

                self.PrePickHeroId = PrePickHeroId
                print("nzyp " .. "PrePickHeroIdEvent-- self.PrePickHeroId", self.PrePickHeroId)
                --if self.AvailableHeroIds and not self.AvailableHeroIds:Contains(self.PrePickHeroId) then
                --    local TipText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_BirthLand_Thisroleisunderdevel"))
                --    UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("Generic.FeedbackTips.Top",-1,UE.FGenericBlackboardContainer(),self,TipText)
                --end
            end
            self:UpdateHeroItemCanPick()
			
	    self:UpdateSelfInfoAndSkillInfo(self.PrePickHeroId)
        end
    end
end

function BirthLand:ReceiveTeamMemberRuntimeHero(pInTeamMemberPS, RuntimeHeroId)
    print("nzyp " .. "RuntimeHeroIdEvent"..RuntimeHeroId)


    if not self.BirthlandAbilityPtr then
        print("nzyp " .. "RuntimeHeroIdEvent-- self.BirthlandAbilityPtr nil")
        return
    end
    local LocalPS = self.BirthlandAbilityPtr:GetOwningPlayerState()
    if not LocalPS then
        print("nzyp " .. "RuntimeHeroIdEvent-- LocalPS nil")
        return
    end

    if pInTeamMemberPS then
        print("nzyp " .. "RuntimeHeroIdEvent-- playerid and runtime heroid", pInTeamMemberPS.PlayerId, RuntimeHeroId)
        local TeamIndex = UE.UTeamExSubsystem.Get(self):GetPlayerNumberInTeamByPS(pInTeamMemberPS)
        --更新玩家头像
        local PlayerWidget = self.VerticalBox_PlayerList:GetChildAt(TeamIndex-1)
        if PlayerWidget then
            print("nzyp " .. "RuntimeHeroIdEvent-- TeamIndex", TeamIndex)
            PlayerWidget:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
            PlayerWidget:SetDataFromPS(pInTeamMemberPS,LocalPS,self.BirthlandAbilityPtr)
        end

        --清除上一个角色头像
        if self.PlayerIdToWidgetIndexTable then
            if self.PlayerIdToWidgetIndexTable[pInTeamMemberPS.PlayerId] then
                local LastWidgetId = self.PlayerIdToWidgetIndexTable[pInTeamMemberPS.PlayerId]
                local LastWidget = self.HeroItemArray:Get(LastWidgetId)
                if LastWidget then
                    print("nzyp " .. "RuntimeHeroIdEvent-- LastWidgetId",LastWidgetId, TeamIndex)
                    LastWidget:ClearPick(TeamIndex)
                end
            end
                    --选中当前角色头像
            for index = 1, self.HeroItemArray:Length() do
                local EachHeroItem = self.HeroItemArray:Get(index)
                print("nzyp " .. "RuntimeHeroIdEvent-- loop index",index)
                if EachHeroItem and RuntimeHeroId == EachHeroItem.HeroId then
                    EachHeroItem:SetPick(TeamIndex, LocalPS == pInTeamMemberPS)
                    self.PlayerIdToWidgetIndexTable[pInTeamMemberPS.PlayerId] = index
                    print("nzyp " .. "RuntimeHeroIdEvent-- CurrentWidgetId",index)
                    break
                end
            end
        end



        if pInTeamMemberPS == LocalPS then
            self.RuntimeHeroId = RuntimeHeroId
            print("nzyp " .. "RuntimeHeroIdEvent-- self.RuntimeHeroId",self.RuntimeHeroId)
            self:UpdateSelfInfoAndSkillInfo(self.RuntimeHeroId)
            self:CloseSelf()
        end
        self:UpdateHeroItemCanPick()
    end
end

function BirthLand:ReceiveTeamMemberRuntimeSkin(pInTeamMemberPS, RuntimeSkinId)
    print("nzyp " .. "RuntimeSkinEvent"..RuntimeSkinId)
end

function BirthLand:ReceiveUpdatePSList(inPS)
    print("nzyp " .. "ReceiveUpdatePSList")
    self:UpdateAllTeammate()
end
function BirthLand:ReceiveUpdateTeamPos(inPS, TeamExInfo)
    print("nzyp " .. "ReceiveUpdateTeamPos")
    self:UpdateAllTeammate()
end
-- 初始化技能信息
function BirthLand:UpdateAllTeammate()
    print("nzyp " .. "UpdateAllTeammate")
    if not self.BirthlandAbilityPtr then
        print("nzyp " .. "UpdateAllTeammate-- self.BirthlandAbilityPtr nil")
        return
    end
    local LocalPS = self.BirthlandAbilityPtr:GetOwningPlayerState()
    if not LocalPS then
        print("nzyp " .. "UpdateAllTeammate-- LocalPS nil")
        return
    end

    local TeamMembers = UE.UTeamExSubsystem.Get(self):GetTeammatePSListByPS(LocalPS)
    local AllTeammateWidgetArray = self.VerticalBox_PlayerList:GetAllChildren()
    print("nzyp " .. "UpdateAllTeammate--TeamMembers.length ",TeamMembers:Length(),AllTeammateWidgetArray:Length())
    if TeamMembers:Length() == 1 then
        self.ImgLine_TeamMember:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.ImgLine_TeamMember:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    end
    for index = 1, TeamMembers:Length() do
        local EachPS = TeamMembers:Get(index)
        if EachPS then
            local TeamIndex = UE.UTeamExSubsystem.Get(self):GetPlayerNumberInTeamByPS(EachPS)
            print("nzyp " .. "UpdateAllTeammate--loop TeamIndex ", TeamIndex)
            local EachWidget = AllTeammateWidgetArray:Get(TeamIndex)
            print("nzyp " .. "UpdateAllTeammate--loop index ", index)
            if EachWidget then
                print("nzyp " .. "UpdateAllTeammate--loop playerid ", EachPS:GetPlayerId())
                EachWidget:SetDataFromPS(EachPS, LocalPS, self.BirthlandAbilityPtr)
                EachWidget:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
            end

            --更新本页面的玩家信息
            if LocalPS == EachPS then
                print("nzyp " .. "UpdateAllTeammate-- self ")
                local PlayerExInfo = UE.UPlayerExSubsystem.Get(self):GetPlayerExInfoByPlayerState(LocalPS)
                if PlayerExInfo then
                    local PrePickHeroId = PlayerExInfo:GetPrePickHeroId()
                    local RuntimeHeroId = PlayerExInfo:GetRuntimeHeroId()
                    local ShowHeroId = RuntimeHeroId > 0 and RuntimeHeroId or PrePickHeroId
                    print("nzyp " .. "UpdateAllTeammate-- self showheroid", ShowHeroId)
                    self:UpdateSelfInfoAndSkillInfo(ShowHeroId)
                end
            end
        end
    end
end

function BirthLand:UpdateSelfInfoAndSkillInfo(HeroId)
    print("nzyp " .. "UpdateSelfInfoAndSkillInfo", HeroId,self.BirthlandAbilityPtr)
    if HeroId > 0 and self.BirthlandAbilityPtr then
        print("nzyp " .. "UpdateSelfInfoAndSkillInfo-- set HeroInfo")
        local SkinId = self.BirthlandAbilityPtr:GetHeroSkinIdByHeroId(HeroId)
        local SkinName = ""
        if SkinId > 0 then
            local HeroSkinInfo = self.BirthlandAbilityPtr:GetHeroSkinTableRowRef(SkinId)
            local HeroConfig = self.BirthlandAbilityPtr:GetHeroConfigTableRowRef(HeroId)
            if HeroSkinInfo and HeroConfig and HeroConfig.SkinId ~= SkinId then
                SkinName = HeroSkinInfo.SkinName
            end
        end
        local HeroConfig = UE.FGePawnConfig()
        local bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(HeroId,HeroConfig,self)
        if bIsValidData then
            local FinalName = StringUtil.Format("{0} {1}", HeroConfig.Name, SkinName)
            self.Text_HeroName:SetText(FinalName)
            local HeroTypeName = self.BirthlandAbilityPtr:GetHeroTypeByHeroId(HeroId)
            self.Text_HeroCharacteristic:SetText(HeroTypeName)
            local BirthlandHeroConfig = self.BirthlandAbilityPtr:GetHeroConfigTableRowRef(HeroId)
            if BirthlandHeroConfig then
                local BirthlandTypeConfig = self.BirthlandAbilityPtr:GetTypeConfigByHeroType(BirthlandHeroConfig.TypeId)
                if BirthlandTypeConfig then
                    CommonUtil.SetBrushFromSoftObjectPath(self.Img_TypeIcon, UE.UKismetSystemLibrary.BreakSoftObjectPath(BirthlandTypeConfig.TypeIconSoft))
                end
            end
            print("nzyp " .. "UpdateSelfInfoAndSkillInfo-- HeroId, skinid, finalname",HeroId, SkinId ,FinalName)
            local SkillWidget = self:GetSkillDescPanel()
            if SkillWidget then
                SkillWidget:SetSkillListWidgetPadding(self.SkillPanelPadding)
                SkillWidget:ReadDataTable(HeroId)
                SkillWidget:SetHeroTextVisible(false)
            end
        end
    end



	local GameState = UE.UGameplayStatics.GetGameState(self)
    if GameState then
        print("nzyp " .. "UpdateSelfInfoAndSkillInfo-- set gamemode info and scene info")
        local GameId = GameState:GetGameModeId()
        local GameModeRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.GameModeDescTable, tostring(GameId))
        if GameModeRow then
            self.Text_GameMode:SetText(GameModeRow.ModeName)
        else
            self.Text_GameMode:SetText(GameId)
        end
        local SceneId = GameState:GetSceneId()
        local SceneRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.SceneTable, tostring(SceneId))
        print("nzyp " .. "UpdateSelfInfoAndSkillInfo-- gamemode and scene",GameId,SceneId)
        if SceneRow then
            self.Text_SiteName:SetText(SceneRow.SceneName)
        else
            self.Text_SiteName:SetText(SceneId)
        end
    end
end

function BirthLand:OnToggleSkillInfo()
    self.ShowSkillInfo = not self.ShowSkillInfo
    self.Size_SkillDetails:SetVisibility(self.ShowSkillInfo and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.WidgetSwitcher_SkillStage:SetActiveWidgetIndex(self.ShowSkillInfo and 1 or 0)
end


function BirthLand:UpdateHeroItemCanPick()
    --判断该角色我是否能确认，这会影响到选定按钮的样式
    for index = 1, self.HeroItemArray:Length() do
        local EachHeroItem = self.HeroItemArray:Get(index)
        if EachHeroItem and self.PrePickHeroId == EachHeroItem.HeroId and EachHeroItem:CanPick() then
            self.GUIButton_Confirm:SetIsEnabled(true)
            self.ControlTipsTxt_1:SetText(self.Text_UnSelected)
            print("nzyp " .. "UpdateHeroItemCanPick-- SetIsEnabled true")
            return
        end
    end
    self.GUIButton_Confirm:SetIsEnabled(false)
    self.ControlTipsTxt_1:SetText(self.Text_Selected)
end


function BirthLand:UpdateHeroList()
    print("nzyp " .. "UpdateHeroList")
    if not self.BirthlandAbilityPtr then
        print("nzyp " .. "UpdateHeroList-- nil ability")
        return
    end

    if self.OwningPlayerId == -1 then
        print("nzyp " .. "self.OwningPlayerId == -1")
        return
    end

    local AvailableHeroIds = self.BirthlandAbilityPtr:GetAvailableHeroIds()
    local PrePickHeroIdList = self.BirthlandAbilityPtr:GetPrePickHeroIdList()
    print("nzyp " .. "UpdateHeroList-- AvailableHeroIds", AvailableHeroIds:Length(), "PrePickHeroIdList", PrePickHeroIdList:Length())
    if not AvailableHeroIds or AvailableHeroIds:Length() <= 0 or not PrePickHeroIdList or PrePickHeroIdList:Length() <= 0 then
        print("nzyp " .. "UpdateHeroList-- return")
        return
    end
    for index = 1, PrePickHeroIdList:Length() do
        print("nzyp " .. "UpdateHeroList-- loop index", index)
        local EachHeroId = PrePickHeroIdList:Get(index)
        local SkinId = self.BirthlandAbilityPtr:GetHeroSkinIdByHeroId(EachHeroId)
        local HeroConfig = self.BirthlandAbilityPtr:GetHeroConfigTableRowRef(EachHeroId)
        print("nzyp " .. "UpdateHeroList-- loop heroid SkinId ", EachHeroId, SkinId)
        if not SkinId then
            goto continue
        end
        local HeroSkinInfo = self.BirthlandAbilityPtr:GetHeroSkinTableRowRef(SkinId)
        if HeroSkinInfo and HeroConfig and HeroSkinInfo.PNGPathNormal then
            local HeroListItem = UE.UWidgetBlueprintLibrary.Create(self, self.HeroListItem)
            HeroListItem:SetDataByHeroConfig(EachHeroId, HeroSkinInfo.PNGPathNormal, HeroConfig.Name, self)
            print("nzyp " .. "UpdateHeroList-- loop HeroListArray:Length ", self.HeroListArray:Length(), HeroConfig.TypeId)
            if self.HeroListArray and self.HeroListArray:Length() >= HeroConfig.TypeId then
                self.HeroListArray:Get(HeroConfig.TypeId):AddChild(HeroListItem)
                self.HeroItemArray:Add(HeroListItem)
            end
            local TeamIndex = UE.UTeamExSubsystem.Get(self):GetPlayerNumberInTeamById(self.OwningPlayerId)
            if self.PrePickHeroId and self.PrePickHeroId == EachHeroId then
                print("nzyp " .. "UpdateHeroList-- loop setprepick ", TeamIndex)
                HeroListItem:SetPrePick(TeamIndex)
                if HeroListItem:CanPick() then
                    self.GUIButton_Confirm:SetIsEnabled(true)
                    self.ControlTipsTxt_1:SetText(self.Text_UnSelected)
                end
            end
            if self.RuntimeHeroId and self.RuntimeHeroId == EachHeroId then
                print("nzyp " .. "UpdateHeroList-- loop setpick ", TeamIndex)
                -- HeroListItem:SetPrePick(TeamIndex)
                -- self.PrePickHeroId = EachHeroId
                HeroListItem:SetPick(TeamIndex, true)
                self.PlayerIdToWidgetIndexTable[self.OwningPlayerId] = index-1
            end
            if not AvailableHeroIds:Contains(EachHeroId) then
                print("nzyp " .. "UpdateHeroList-- loop setlock ", TeamIndex)
                HeroListItem:SetIsLock(true)
            end
        end
        ::continue::
    end
end



function BirthLand:OnKeyDown(MyGeometry, InKeyEvent)
    local MouseKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if not MouseKey then 
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
    
    print("nzyp " .. "OnKeyDown", MouseKey.KeyName)
    if MouseKey.KeyName == "Tab" then
        self:OnToggleSkillInfo()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif MouseKey.KeyName == "SpaceBar" and self.PrePickHeroId then
        self:OnConfirmClick()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif MouseKey.KeyName == "Escape" or MouseKey.KeyName == "Gamepad_FaceButton_Right" then
        self:CloseSelf()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif PressKey == UE.FName("L") then
        self:OnSwitchVoice()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif PressKey == UE.FName("T") then
        self:ChooseParachuteCaptain()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif MouseKey.KeyName == "F1"then
        print("nzyp " .. "OnKeyDown Call", MouseKey.KeyName)
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function BirthLand:CloseSelf()
    print("nzyp " .. "close self")
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager and self.BirthlandAbilityPtr and self.RuntimeHeroId then
        UIManager:TryCloseDynamicWidgetByHandle(self.BirthlandAbilityPtr.WidgetHandle)
        print("nzyp " .. "close self11111111111111")
    end
end


function BirthLand:OnOpenEditCurrency()
    print("nzyp " .. "BirthLand:OnOpenEditCurrency")
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager and self.BirthlandAbilityPtr then
        local BlackboardContainer = UE.FGenericBlackboardContainer()
        local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
        BlackboardKeySelector.SelectedKeyName = "BirthlandAbilityPtr"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsObject(BlackboardContainer, BlackboardKeySelector, self.BirthlandAbilityPtr)
        UIManager:TryLoadDynamicWidget(self.BirthlandAbilityPtr.EditVirtualCurrencyHUD, BlackboardContainer, true)
    end
end


function BirthLand:ReceiveBaseVirtualCurrency(vm, fieldID)
    print("nzyp " .. "ReceiveBaseVirtualCurrency", vm.BaseVirtualCurrency)
    self.Text_Num:SetText(vm.BaseVirtualCurrency)
end


function BirthLand:OnSwitchVoice()
    print("wzp print BirthLand:OnSwitchVoice")
    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    local RtcGameRoomId = self.BattleChatComp:GetRtcGameRoomId()
    local RtcTeamRoomId = self.BattleChatComp:GetRtcTeamRoomId()
    local GetCurrentRoomId = self.BattleChatComp:GetCurrentRoomId()
    print("wzp print BirthLand:OnSwitchVoice RtcGameRoomId=",RtcGameRoomId,"RtcTeamRoomId=",RtcTeamRoomId,"GetCurrentRoomId=",GetCurrentRoomId)
    self.bVoice = not self.bVoice
    -- local EVoice =  self.bVoice and 1 or 2
    -- self.BattleChatComp:BP_SwitchPublishChannel(EVoice)
    -- self.BattleChatComp:SetTeamMicrophone(self.bVoice)
    local VoiceBtnTipStr = self.bVoice and StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_BirthLand_Turnoffvoice")) or StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_BirthLand_Turnonvoice"))
    self.ControlTipsTxt_2:SetText(VoiceBtnTipStr)
end

function BirthLand:ChooseParachuteCaptain()
    print("BirthLand:ChooseParachuteCaptain")
    
end

return BirthLand