
--[[
背包界面-武器栏位-右下角的强化词条显示控件逻辑
功能逻辑：
1. 鼠标右键点击，销毁当前武器的词条
2. 鼠标Hover，显示有效的强化词条详细信息
3. UI刷新，显示强化词条的图标Icon
--]]

require "UnLua"

local EnhanceAttributeForWeapon = Class("Common.Framework.UserWidget")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

function EnhanceAttributeForWeapon:OnInit()
    self:SetCurrentWeaponInventoryIdentity(UE.FInventoryIdentity())
    local EnhancementSettings = UE.UEnhancementSettings.Get()
    if EnhancementSettings then
        self.DestroyHoldTime = EnhancementSettings.DestroyWeaponAttributeHoldTime
    end
    print("EnhanceAttributeForWeapon:OnInit !", GetObjectName(self))
    UserWidget.OnInit(self)
end

function EnhanceAttributeForWeapon:OnDestroy()
    self:ResetHold()
    UserWidget.OnDestroy(self)
end

function EnhanceAttributeForWeapon:OnClose()
    self:ResetHold()
    UserWidget.OnClose(self)
end

function EnhanceAttributeForWeapon:Tick(InMyGeometry, InDeltaTime)
    if self.IsHoldRightMouseButton and self.DestroyHoldTime then
        self.HoldingTime = self.HoldingTime + InDeltaTime
        if self.HoldingTime >= self.DestroyHoldTime then
            self:ResetHold()
            self:HoldToDestroyEnhanceAttribute()
        end
    end
end

function EnhanceAttributeForWeapon:OnMouseEnter(MyGeometry, MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        return
    end

    -- 显示强化词条细节信息
    if self.EnhanceId ~= "" then
        local TempInteractionKeyName = "Empty"
        self.Image_Bg_Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = nil,
            IsShowAtLeftSide = true,
            ItemID = self.ItemID,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = 1,
            IsShowDiscardNum = true,
            InteractionKeyName = TempInteractionKeyName,
            EnhanceId = self.EnhanceId,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })
    else
        self.Image_Bg_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


function EnhanceAttributeForWeapon:OnMouseLeave(MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        return
    end
    self.Image_Bg_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end


function EnhanceAttributeForWeapon:OnMouseButtonDown(MyGeometry, MouseEvent)

    -- if self.EnhanceId == "" then
    --     return UE.UWidgetBlueprintLibrary.Handled()
    -- end

    -- local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    -- if not MouseKey then
    --     return UE.UWidgetBlueprintLibrary.Handled()
    -- end

    -- if MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton and self.DestroyHoldTime then
    --     local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    --     if TempLocalPC then
    --         local TempBagComp = UE.UBagComponent.Get(TempLocalPC)
    --         if TempBagComp then
    --             local TempWeaponInventoryInstance = TempBagComp:GetInventoryInstance(self.WeaponInventoryIdentity)
    --             if TempWeaponInventoryInstance then
    --                 self:StartHold()
    --             end
    --         end
    --     end
    -- end
    print("EnhanceAttributeForWeapon:OnMouseButtonDown SendMsg Own ItemSlotWeaponAttachment !")

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
         return UE.UWidgetBlueprintLibrary.Handled()
    end

    if MouseKey.KeyName == GameDefine.NInputKey.MiddleMouseButton then
        -- 中键标记
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

        if PlayerController then
            local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
            if BattleChatComp then
                if self.EnhanceId ~= "" and self.EnhanceId ~= nil then
                    AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithEnhanveAttributeId(self, self.EnhanceId)
                    print("EnhanceAttributeForWeapon:OnMouseButtonDown SendMsg Own EnhanceAttributeForWeapon !")
                else
                    AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemType(self, self.DefaultType)
                    print("EnhanceAttributeForWeapon:OnMouseButtonDown SendMsg Need EnhanceAttributeForWeapon !")
                end
            end
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end


function EnhanceAttributeForWeapon:OnMouseButtonUp(MyGeometry, MouseEvent)
    -- local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)

    -- if MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton and self.IsHoldRightMouseButton then
    --     self:ResetHold()
    -- end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function EnhanceAttributeForWeapon:StartHold()
    self.IsHoldRightMouseButton = true
    self.HoldingTime = 0.0
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager then
        UIManager:SetCursorLongPressMaterialAndParameterName(self.TargetCursorMat,self.MatParameterName)
        UIManager:SetCursorStartLongPress(true,self.DestroyHoldTime,0.0)
    end
end

function EnhanceAttributeForWeapon:ResetHold()
    if self.IsHoldRightMouseButton then
        local UIManager = UE.UGUIManager.GetUIManager(self)
        if UIManager then
            UIManager:SetCursorStartLongPress(false,self.DestroyHoldTime,0.0)
        end
    end
    self.HoldingTime = 0.0
    self.IsHoldRightMouseButton = false
end

function EnhanceAttributeForWeapon:HoldToDestroyEnhanceAttribute()
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC then
        local TempBagComp = UE.UBagComponent.Get(TempLocalPC)
        if TempBagComp then
            local TempWeaponInventoryInstance = TempBagComp:GetInventoryInstance(self.WeaponInventoryIdentity)
            if TempWeaponInventoryInstance then
                TempWeaponInventoryInstance:RPCDestroyWeaponEnhance()
                MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
            end
        end
    end
end


function EnhanceAttributeForWeapon:UpdateEnhanceWeaponInnerInfo(InWeaponInventoryIdentity, InEnhanceId)
    -- 入参校验
    if not InWeaponInventoryIdentity then
        return
    end
    if not InEnhanceId then
        return
    end

    -- 更新当前强化词条的武器信息
    self:SetCurrentWeaponInventoryIdentity(InWeaponInventoryIdentity)

    if self.EnhanceId == "" and InEnhanceId == "" then
        return
    end

    if self.EnhanceId ~= InEnhanceId then
        -- 更新强化词条图片
        self.EnhanceId = InEnhanceId
        local TempGameplayTag = UE.FGameplayTag()
        TempGameplayTag.TagName = GameDefine.NTag.TABLE_EnhanceAttribute
        -- 查找表资源
        local TempEnhanceAttributeDT = UE.UTableManagerSubsystem.GetDataTableByTag(self, TempGameplayTag)
        if TempEnhanceAttributeDT then
            -- 查找表的某行
            local StructInfoEnhanceAttr = UE.UDataTableFunctionLibrary.GetRowDataStructure(TempEnhanceAttributeDT, tostring(InEnhanceId))
            if StructInfoEnhanceAttr then
                -- 查找强化词条图片
                local EnhanceIconSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceIconSoft)
                self:SetImageAttributeIcon(EnhanceIconSoftPtr)
            end
        end
    end
end

function EnhanceAttributeForWeapon:SetImageAttributeBg(InTexture)
    if InTexture then
        if self.Image_Bg then
            self.Image_Bg:SetBrushFromSoftTexture(InTexture, false)
        end
    else
        -- TODO：使用默认图片
    end
end

function EnhanceAttributeForWeapon:SetImageAttributeIcon(InTexture)
    if InTexture then
        if self.Image_Icon then
            self.Image_Icon:SetBrushFromSoftTexture(InTexture, false)
        end
    else
        -- TODO: 使用默认图片
    end
end


function EnhanceAttributeForWeapon:SetEnhanceEmptyState(IsEmpty)
    if IsEmpty then
        self.EnhanceId = ""
        self:SetCurrentWeaponInventoryIdentity(UE.FInventoryIdentity())
		self.Image_Icon:SetVisibility(UE.ESlateVisibility.Collapsed);
        self:SetImageAttributeIcon(nil)
		self.Image_Bg:SetColorAndOpacity(self.EnhanceEmpty);
        self:SetImageAttributeBg(nil)
    else
        self.Image_Icon:SetVisibility(UE.ESlateVisibility.Visible);
		self.Image_Bg:SetColorAndOpacity(self.EnhanceNotEmpty);
    end
end

return EnhanceAttributeForWeapon
