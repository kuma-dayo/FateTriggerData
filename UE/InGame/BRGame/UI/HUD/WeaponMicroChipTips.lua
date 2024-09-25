--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local WeaponMicroChipTips = Class("Common.Framework.UserWidget")

function WeaponMicroChipTips:OnInit()
    print("WeaponMicroChipTips", ">> OnInit, ", GetObjectName(self))

    self.MsgList = {
        { MsgName = GameDefine.Msg.WEAPON_WearMicroChip,Func = self.OnShowTips,bCppMsg = false}
    }

    UserWidget.OnInit(self)
        --先隐藏控件
    self.SB_TipsRoot:SetVisibility(UE.ESlateVisibility.Collapsed)

    local TempGameplayTag = UE.FGameplayTag()
    TempGameplayTag.TagName = GameDefine.NTag.TABLE_EnhanceAttribute
    self.EnhanceAttributeDT = UE.UTableManagerSubsystem.GetDataTableByTag(self, TempGameplayTag)

    self:ResetTimerParams()
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnTimer}, 1, true, 0, 0)
end

function WeaponMicroChipTips:OnTimer()
    if self.bIsStart then
        self.Timer = self.Timer + 1
        if self.Timer >= 3 then
            self:ResetTimerParams()
            self:VXE_HUD_WeaponMicroChipTips_Out()
        end
    end

end

function WeaponMicroChipTips:OnDestroy()
    print("WeaponMicroChipTips", ">> OnDestroy, ", GetObjectName(self))

    if 	self.TimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
        self.TimerHandle = nil
    end
    UserWidget.OnDestroy(self)
end


function WeaponMicroChipTips:ResetTimerParams()
    self.Timer = 0
    self.bIsStart = false
end

function  WeaponMicroChipTips:OnFinishAnim()
    UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
    self:VXE_HUD_WeaponMicroChipTips_Out()
end


--UITipsManager UpdateData Override
function WeaponMicroChipTips:OnShowTips(MsgBody)
    self:ForceLayoutPrepass()
    local ItemIDStr = MsgBody.ItemID
    if not ItemIDStr or ItemIDStr == "" then
        --播放收缩动画
        if self.bIsStart then
            self:ResetTimerParams()
            self:VXE_HUD_WeaponMicroChipTips_Out()
        end
        --如果ItemIDStr是nil或者""代表枪械无芯片，播放消失渐变动画
        return
    else
        --播放显示动画
        self.bIsStart = true
        self.Timer = 0
        self:VXE_HUD_WeaponMicroChipTips_In()
    end
    
    local ItemIDNum = tonumber(ItemIDStr)
    --获取品质等级
    local ItemLevel, bValidItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, ItemIDNum, "ItemLevel",
        GameDefine.NItemSubTable.Ingame, "WeaponMicroChipTips:OnShowTips")
    --获取品质色
    local LvBgColor = BattleUIHelper.GetMiscSystemValue(self, "WeaponAttchIconColor", ItemLevel)
    self.ImgTipsFrame:SetColorAndOpacity(LvBgColor)

    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, ItemIDNum)

    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, ItemIDStr)


    -- 显示物品名称
    local ItemNameStr = StructInfo_Item.ItemName
    if self.TextChipName then
        self.TextChipName:SetText(ItemNameStr)
    end
    -- 显示物品描述
    local ItemDescStr = self.DescMap:Find(ItemIDStr)
    if not ItemDescStr then
        print("WeaponMicroChipTips >> UpdateData > ItemDescStr is nil")
        return
    end
    --local ItemDescStr = StructInfo_Item.SimpleDescribe --使用配置表物品描述

    local ShowNameStr = StringUtil.Format('<span font="S1_Font" style="3_Regular" size="24">{0}</>', ItemNameStr)

    local KeywordColorHex = self.KeywordsColorArr:Find(ItemIDStr)
    local ShowDescStr = tostring(ItemDescStr)
    for index = 1, self.KeywordsArr:Num() do
        local Keyword = self.KeywordsArr:Get(index)
        local KeywordStr = tostring(Keyword)
        local bResult = string.find(ItemDescStr, KeywordStr)
        if bResult then
            local ReplaceStr = StringUtil.Format('<span font="S1_Font" style="3_Regular" size="20" color="{0}">{1}</>',
                KeywordColorHex, Keyword)
            ShowDescStr = string.gsub(ItemDescStr, tostring(Keyword), tostring(ReplaceStr))
        end
        print("WeaponMicroChipTips >> OnShowTips > Keyword = ", Keyword)
    end

    local ShowText = ShowNameStr .. "\n" .. ShowDescStr
    self.TextDesc:SetText(ShowText)


    local StructInfoEnhanceAttr = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.EnhanceAttributeDT, ItemIDStr)
    if StructInfoEnhanceAttr then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceIcon)
        if ImageSoftObjectPtr then
            if self.ImgChipIcon then
                self.ImgChipIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
            end
        end
    end
end




return WeaponMicroChipTips
