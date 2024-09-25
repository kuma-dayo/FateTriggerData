require "UnLua"

local BirthLand_TeamMember = Class("Common.Framework.UserWidget")

function BirthLand_TeamMember:OnInit()
    self.MsgList = {
        -- { MsgName = UE.USDKTags.Get().RTCSDKOnUserPublishOrUnPublishStream,	Func = self.RTCSDKOnUserPublishOrUnPublishStream, 	bCppMsg = true },
        -- { MsgName = UE.USDKTags.Get().RTCSDKOnLocalPublishOrUnPublishStream,	Func = self.RTCSDKOnLocalPublishOrUnPublishStream, 	bCppMsg = true },
        -- -- { MsgName = UE.USDKTags.Get().RTCSDKOnRemoteAudioPropertiesReport,            Func = self.RTCSDKOnRemoteAudioPropertiesReport,      bCppMsg = true },
        -- { MsgName = UE.USDKTags.Get().RTCSDKOnLocalAudioPropertiesReport,            Func = self.RTCSDKOnLocalAudioPropertiesReport,      bCppMsg = true },
    }


    self.PlayerChatComponent = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.PlayerChatComponent.VoiceRoomMemberSpeakNotify:Add(self,self.OnVoicMemberSpeaking)
    self.PlayerChatComponent.VoiceLocalSpeakNotify:Add(self,self.OnVoiceLocalClientSpeaking)
    self.PlayerChatComponent.VoiceLocalIsOpenMicNotify:Add(self,self.OnVoiceLocalIsOpenMic)
    self.PlayerChatComponent.VoiceRemoteIsOpenMicNotify:Add(self,self.OnVoiceRemoteIsOpenMic)
    self.ImgIcon_Voice_Off:SetRenderOpacity(0.5)
    print("wzp print BirthLand_TeamMember >> OnInit")
    -- self.Btn_SwitchVoice.OnClicked:Add(self, self.GUIButton_OnClickedSwitchVoice)
    UserWidget.OnInit(self)
end



function BirthLand_TeamMember:OnDestroy()
    -- UnListenObjectMessage(UE.USDKTags.Get().RTCSDKOnUserPublishOrUnPublishStream, self, self.RTCSDKOnUserPublishOrUnPublishStream)
    -- if self.PlayerChatComponent then
    --     self.PlayerChatComponent.VoiceRoomMemberSpeakNotify:Remove(self, self.OnUpdateItemLocal)
    --     self.PlayerChatComponent.VoiceLocalSpeakNotify:Remove(self,self.OnVoiceLocalClientSpeaking)
    --     self.PlayerChatComponent.VoiceLocalIsOpenMicNotify:Remove(self,self.OnVoiceLocalIsOpenMic)
    --     self.PlayerChatComponent.VoiceRemoteIsOpenMicNotify:Remove(self,self.OnVoiceRemoteIsOpenMic)
    -- end

    UserWidget.OnDestroy(self)
end

function BirthLand_TeamMember:SetDataFromPS(PlayerState, LocalPS, BirthlandAbilityPtr)


    self.ChatComponent = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.bEVoiceChat = (self.ChatComponent.EVoiceChat == 0)
    -- self.RoomId = self.ChatComponent:GetRoomId()

    if not LocalPS or not BirthlandAbilityPtr then
        return
    end

    self.LocalPlayerId = LocalPS:GetPlayerId()
    
    if PlayerState then 
        self.CurrentTeammateOwnerPlayerId = PlayerState:GetPlayerId()
        local TeamIndex = UE.UTeamExSubsystem.Get(self):GetPlayerNumberInTeamByPS(PlayerState)
        local PlayerNum = UE.UTeamExSubsystem.Get(self):GetTeammatePSListByPS(PlayerState):Length()

        print("wzp print BirthLand_TeamMember >> SetDataFromPS self.CurrentTeammateOwnerPlayerId=",self.CurrentTeammateOwnerPlayerId)
        if TeamIndex == 1 then
            self.ImgPtn_First:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        end
        if TeamIndex == PlayerNum then
            self.ImgPtn_Last:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        end
        if TeamIndex < PlayerNum and PlayerNum ~= 1 then
            self.ImgPtn_Spacing:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        end

        if self.Text_TeamPosition then
            local ImgColor = self.Color_TeamPosition_Array:Get(TeamIndex)
            self.Text_TeamPosition:SetColorAndOpacity(ImgColor)
            self.Text_TeamPosition:SetText(TeamIndex)
        end
        if self.ImgBg_TeamPosition then
            local ImgColor = MinimapHelper.GetTeamMemberColor(TeamIndex)
            self.ImgBg_TeamPosition:SetColorAndOpacity(ImgColor)
        end
        
        local PlayerExInfo = UE.UPlayerExSubsystem.Get(self):GetPlayerExInfoByPlayerState(PlayerState)
        if PlayerExInfo then
            local PrePickHeroId = PlayerExInfo:GetPrePickHeroId()
            local RuntimeHeroId = PlayerExInfo:GetRuntimeHeroId()
            local RuntimeSkinId = PlayerExInfo:GetRuntimeSkinId()
            local ShowHeroId = RuntimeHeroId > 0 and RuntimeHeroId or PrePickHeroId

            local PawnConfig = UE.FGePawnConfig()
            local  bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(ShowHeroId,PawnConfig,self)
            if bIsValidData then
                self.Text_HeroName:SetText(RuntimeHeroId > 0 and PawnConfig.Name or StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_BirthLand_Choosing")))
                self.ImgIcon_Avatar:SetBrushFromSoftTexture(PawnConfig.SmallIcon, false)
            end
            
            -- if RuntimeSkinId > 0 then
            --     local HeroSkinInfo = BirthlandAbilityPtr:GetHeroSkinTableRowRef(RuntimeSkinId)
            --     if HeroSkinInfo and HeroSkinInfo.PNGPath then
            --         local HeadImage = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(HeroSkinInfo.PNGPathSoft)
            --         if HeadImage then
            --             self.ImgIcon_Avatar:SetBrushFromSoftTexture(HeadImage, false)
            --         end
            --     end
            -- else
            --     self.ImgIcon_Avatar:SetBrushFromSoftTexture(PawnConfig.SmallIcon, false)
            -- end

            self.ImgIcon_Avatar:SetOpacity(RuntimeHeroId > 0 and 1.0 or 0.5)
            self.Overlay_Choose:SetVisibility(RuntimeHeroId > 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible)
            self.WidgetSwitcher_BgStage:SetActiveWidgetIndex(RuntimeHeroId > 0 and 1 or 0)
            self.Text_PlayerName:SetText(PlayerState:GetPlayerName())
            self.Text_PlayerName:SetColorAndOpacity(PlayerState == LocalPS and self.Color_PlayerName_Self or self.Color_PlayerName_Other)
            self.Text_HeroName:SetColorAndOpacity(RuntimeHeroId > 0  and self.Color_HeroName_Chosen or self.Color_HeroName_Choose)
        end
    end
end



--本地开关麦 回调
function BirthLand_TeamMember:OnVoiceLocalIsOpenMic(bOpen)
    print("(Wzp)BirthLand_TeamMember:OnVoiceLocalIsOpenMic  [ObjectName]=",GetObjectName(self),",[bOpen]=",bOpen,",[self.LocalPlayerId]=",self.LocalPlayerId,",[self.CurrentTeammateOwnerPlayerId]=",self.CurrentTeammateOwnerPlayerId)
    if self.CurrentTeammateOwnerPlayerId == self.LocalPlayerId then
        self.WidgetSwitcher_Voice:SetActiveWidgetIndex(bOpen and 0 or 1)
    end
end


--远端开关麦 回调
function BirthLand_TeamMember:OnVoiceRemoteIsOpenMic(OpenID, IsOpen)
    print("(Wzp)BirthLand_TeamMember:OnVoiceRemoteIsOpenMic  [ObjectName]=",GetObjectName(self),",[OpenID]=",OpenID,",[self.LocalPlayerId]=",self.LocalPlayerId,",[IsOpen]=",IsOpen,",[self.CurrentTeammateOwnerPlayerId]=",self.CurrentTeammateOwnerPlayerId)
    print("(Wzp)BirthLand_TeamMember:OnVoiceRemoteIsOpenMic  [type(OpenID)]=",type(OpenID),",[type(self.Curre..PlayerId)]=",type(self.CurrentTeammateOwnerPlayerId))
    local CurrentTeammatePlayerIDStr = tostring(self.CurrentTeammateOwnerPlayerId)
    if OpenID ~= CurrentTeammatePlayerIDStr then
        return
    end
    self.WidgetSwitcher_Voice:SetActiveWidgetIndex(IsOpen and 0 or 1)
end


--本地说话 回调
function BirthLand_TeamMember:OnVoiceLocalClientSpeaking(bSpeaking)
    print("(Wzp)BirthLand_TeamMember:OnVoiceLocalClientSpeaking  [ObjectName]=",GetObjectName(self),",[bSpeaking]=",bSpeaking,",[self.LocalPlayerId]=",self.LocalPlayerId,",[bSpeaking]=",bSpeaking,",[self.CurrentTeammateOwnerPlayerId]=",self.CurrentTeammateOwnerPlayerId)
    
    local IsSelf = (self.CurrentTeammateOwnerPlayerId == self.LocalPlayerId)
    print("(Wzp_Error)BirthLand_TeamMember:OnVoiceLocalClientSpeaking  [IsSelf]=",IsSelf)
    if IsSelf then
        self.ImgIcon_Voice_Off:SetRenderOpacity(bSpeaking and 1 or 0.5)
    end
end

--远端说话 回调
function BirthLand_TeamMember:OnVoicMemberSpeaking(MemberID, bSpeaking)
    print("(Wzp)BirthLand_TeamMember:OnVoicMemberSpeaking  [ObjectName]=",GetObjectName(self),",[MemberID]=",MemberID,",[bSpeaking]=",bSpeaking)

    local RoomMemberInfo = self.PlayerChatComponent:GetVoiceRoomInfoByPlayerID(self.CurrentTeammateOwnerPlayerId)
    if not RoomMemberInfo then
        print("(Wzp_Error)BirthLand_TeamMember:OnVoicMemberSpeaking  [RoomMemberInfo]=nil")
        return
    end
    local QueryMemberID = RoomMemberInfo.MemberID
    print("(Wzp)BirthLand_TeamMember:OnVoicMemberSpeaking  [QueryMemberID]=",QueryMemberID)
    if QueryMemberID == MemberID then
        self.ImgIcon_Voice_Off:SetRenderOpacity(bSpeaking and 1 or 0.5)
    end
end


return BirthLand_TeamMember