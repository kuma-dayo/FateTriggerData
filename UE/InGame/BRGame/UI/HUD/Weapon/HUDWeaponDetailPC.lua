--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

--if GameLog then GameLog.AddToBlackList("HUDWeaponDetailPC") end

require "Common.Framework.UIHelper"

local ParentClassName = "InGame.BRGame.UI.HUD.Weapon.HUDWeaponDetailBase"
local HUDWeaponDetailBase = require(ParentClassName)
local HUDWeaponDetailPC = Class(ParentClassName)

-------------------------------------------- Init/Destroy ------------------------------------

function HUDWeaponDetailPC:OnInit()
    print("HUDWeaponDetailPC", ">> OnInit, ", GetObjectName(self))

    if self.TxtDMG then
        self.TxtDMG:SetText('')
    end
    
    self.AttachList = {
        "Weapon.AttachSlot.Barrel",
        "Weapon.AttachSlot.FrontGrip",
        "Weapon.AttachSlot.Optics",
        "Weapon.AttachSlot.Mag",
        "Weapon.AttachSlot.Stocks",
        "Weapon.AttachSlot.HopUp",
    }

    self.AttachWidgetTable = {}
    self.CurWeaponFinalAttchWidgetTable = {} --Tag:Widget
    self:InitAttachments()

    HUDWeaponDetailBase.OnInit(self)

end

function HUDWeaponDetailPC:OnDestroy()
    print("(Wzp)HUDWeaponDetailPC:OnDestroy  [ObjectName]=",GetObjectName(self))
    HUDWeaponDetailBase.OnDestroy(self)
end


function HUDWeaponDetailPC:InitData(InMainWidget, InSlotIndex, WeaponInfo)
    assert(InMainWidget and InSlotIndex, ">> InMainWidget is invalid!!!")


    -- 武器插槽Index
    self.SlotIndex  = InSlotIndex
    -- 父Widget的引用
    self.MainWidget = InMainWidget

    self.TabOn      = WeaponInfo.ImgTabOn

    self.BulletWarningNum = 0
end

function HUDWeaponDetailPC:InitAttachments()
    print("(Wzp)HUDWeaponDetailPC:InitAttachments  [ObjectName]=",GetObjectName(self))
    --拿到枪械所支持的配件列表
    --根据支持配件列表数量Length隐藏中多余配件蓝图
    --将支持的配件列表重新按照配好的优先级level 排序
    --排序后遍历，将数据赋值给配件蓝图
    --配件图标配表，根据配件tag查icon；还需要一个table 存当前配件的tag、widget、level信息，每当配件更新的时候从这个table中根据tag取widget更新
    local ChildNum = self.AttachSlots:GetChildrenCount()
    for i = 1, ChildNum do
        local AttachWidget = self.AttachSlots:GetChildAt(i-1)
        table.insert(self.AttachWidgetTable,{level = i, widget=AttachWidget})
    end

end


function HUDWeaponDetailPC:ShowInitWeaponsUI(bChange)
    print("(Wzp)HUDWeaponDetailPC:ShowInitWeaponsUI  [ObjectName]=",GetObjectName(self),",[bChange]=",bChange)
    if bChange then
        self.TrsWeapon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.HV_DGM:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TrsBulletInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Panel_FireMode:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ImgIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Image_SpecialBg:SetVisibility(UE.ESlateVisibility.Collapsed)

        print("(Wzp)HUDWeaponDetailPC:ShowInitWeaponsUI  [#self.AttachList]=",#self.AttachList)
        for i = 1, #self.AttachList do
            local widget = self.AttachWidgetTable[i].widget
            local TagStr = self.AttachList[i]
            local Icon = self.AttachmentIconMap:Find(TagStr)
            widget:SetIcon(Icon)
            widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    else
        self.HV_DGM:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TrsBulletInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Panel_FireMode:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.ImgIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

end


function HUDWeaponDetailPC:MicrochipNotify(TheItemID)  --Override Funciton
    --发送芯片装备GMP
    print("(Wzp)HUDWeaponDetailPC:MicrochipNotify  [ObjectName]=",GetObjectName(self),",[TheItemID]=",TheItemID)
    MsgHelper:Send(self, GameDefine.Msg.WEAPON_WearMicroChip, {ItemID=TheItemID})

    --播放芯片效果的动画
    --self:PlayChipAnim(TheItemID)

    self.CurrentActiveChipId = TheItemID
    print("HUDWeaponDetailPC:MicrochipNotify PlayChipAnim")
end

function HUDWeaponDetailPC:UpdateInnerWeaponInfo(InWeaponSlotData)  --Override Funciton
    print("(Wzp)HUDWeaponDetailPC:ShowInitWeaponsUI  [ObjectName]=",GetObjectName(self))
    HUDWeaponDetailBase.UpdateInnerWeaponInfo(self, InWeaponSlotData)
    if self.CurrentWeaponBulletItemID then
        print("(Wzp)HUDWeaponDetailPC:ShowInitWeaponsUI  [self.CurrentWeaponBulletItemID]=",self.CurrentWeaponBulletItemID)
        self:UpdateWeaponBulletItemIcon(self.CurrentWeaponBulletItemID)
    end
end


function HUDWeaponDetailPC:ResetWidget()--Override Funciton
    print("(Wzp)HUDWeaponDetailPC:ResetWidget  [ObjectName]=",GetObjectName(self))
    self.WeaponSlotData.InventoryIdentity.ItemID = 0
    self.WeaponSlotData.InventoryIdentity.ItemInstanceID = 0
    self.GAWeaponInstance = nil
    self.WeaponSlotData.ItemType = ""
    self.WeaponSlotData.bActive = false

    self:UnBindGMP()
    self.TrsWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)

    if BridgeHelper.IsPCPlatform() then
        self.TabOn:GetDynamicMaterial():SetScalarParameterValue("AttachmentsNum", 6)
    end
    self:ResetAttachmentInfo()
end

function HUDWeaponDetailPC:IsExistValidWeaponInSlot()
    if (self.WeaponSlotData.InventoryIdentity.ItemID ~= 0) and (self.WeaponSlotData.InventoryIdentity.ItemInstanceID ~= 0) then
        return true
    else
        return false
    end
end




-- 更新当前武器的伤害值文字
-- return void
function HUDWeaponDetailPC:UpdateWeaponDamageNumber(CurrentDamageNumber)
    print("(Wzp)HUDWeaponDetailPC:UpdateWeaponDamageNumber  [ObjectName]=",GetObjectName(self),",[CurrentDamageNumber]=",CurrentDamageNumber)

    local TempNumber = 0
    if CurrentDamageNumber then
        TempNumber = CurrentDamageNumber
    end
    if self.TxtDMG then
        self.TxtDMG:SetText(string.format("%.1f", TempNumber))
    end
end




--更新配件信息
function HUDWeaponDetailPC:UpdateAttachmentInfo(bIsAttachChange, bIsSwitchWeapon)
    -- print("(Wzp)HUDWeaponDetailPC:UpdateAttachmentInfo  [ObjectName]=",GetObjectName(self),",[bIsAttachChange]=",bIsAttachChange,",[bIsSwitchWeapon]=",bIsSwitchWeapon)
    local ThebIsAttachChange = bIsAttachChange or false --配件是否改变
    local ThebIsSwitchWeapon = bIsSwitchWeapon or false --武器是否切换
    -- 根据插槽信息，开启/关闭相关插槽显示
    local CurrentWeaponInventoryIdentity = self.WeaponSlotData.InventoryIdentity
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

    local TempPawn = PlayerController:K2_GetPawn()
    local TempEquipmentComponent = UE.UEquipmentStatics.GetEquipmentComponent(TempPawn)
    if not TempEquipmentComponent then return end
    local GAWInstance = TempEquipmentComponent:GetEquipmentInstanceByInventoryIdentity(CurrentWeaponInventoryIdentity)
    if not GAWInstance then return end

    -- 获取这把武器拥有的配件插槽名称数组
    local WAttachmentSlotTagArray = UE.UGAWAttachmentFunctionLibrary.GetWeaponOwnedAttachSlotTags(GAWInstance)
    local AttachmentNum = WAttachmentSlotTagArray:Length()

    -- 步骤1：先将此武器的所有配件UI，重置+隐藏（现在根据策划的要求，没有配件时不隐藏配件UI）
    self:ResetAttachmentInfo()

    -- 步骤2：显示此武器可支持的配件插槽UI

    --重置隐藏配件
    for _, value in pairs(self.AttachWidgetTable) do
        value.widget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    local AttachSortInfo = {}
    local FinnalAttachLst = {}

    for i = 1, AttachmentNum do
        --拿到 可支持配件 的Tag
        local AttachmentTag = WAttachmentSlotTagArray:Get(i)
        local AttachTagStr = AttachmentTag.tagName

        --按从左往右顺序显示配件
        local Widget = self.AttachWidgetTable[i].widget
        Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        --查询当前Tag的优先级
        local Level = self.AttachmentLevelMap:Find(AttachTagStr)
        table.insert(AttachSortInfo, { level = Level, tag = AttachTagStr })
    end

    table.sort(AttachSortInfo, function(a, b)
        return a.level < b.level
    end)

    local WeaponTag = self.GAWeaponInstance and self.GAWeaponInstance:GetMainWeaponTag() or nil

    for i = 1, #AttachSortInfo do
        local widget    = self.AttachWidgetTable[i].widget
        local CurTag    = AttachSortInfo[i].tag

        widget:SetWeaponAttachmentIcon(WeaponTag,CurTag)
        FinnalAttachLst[CurTag] = widget
    end

    self.CurWeaponFinalAttchWidgetTable = FinnalAttachLst
    for i = 1, AttachmentNum do
        local AttachmentTag = WAttachmentSlotTagArray:Get(i)
        local GAWAttachmentEffectArray = UE.UGAWAttachmentFunctionLibrary.GetAllAttachmentEffectHandleInSlot(GAWInstance,
            AttachmentTag)
        local NewWidget = FinnalAttachLst[AttachmentTag.TagName]

        if not NewWidget then
            goto continue
        end


        local WAttachmentInSlot = GAWAttachmentEffectArray:Length()
        local TempGAWAttachmentEffect = nil
        if WAttachmentInSlot == 1 then
            TempGAWAttachmentEffect = GAWAttachmentEffectArray:Get(1)
            if TempGAWAttachmentEffect then
                local CurrentAttachmentObject = UE.UGAWAttachmentFunctionLibrary.GetAttachmentInstance(self.GAWeaponInstance, TempGAWAttachmentEffect.EffectHandle)
                if CurrentAttachmentObject then
                    NewWidget:UpdateAttachmentInfo(TempGAWAttachmentEffect.ItemID)
                end

            end
        end


        if AttachmentTag.TagName == "Weapon.AttachSlot.HopUp" and self.WeaponSlotData.bActive then
            local MicrochipID = TempGAWAttachmentEffect and tostring(TempGAWAttachmentEffect.ItemID) or nil
            if self.MicrochipID ~= MicrochipID and ThebIsAttachChange then
                self.MicrochipID = MicrochipID
                self:MicrochipNotify(MicrochipID)
            elseif ThebIsSwitchWeapon then
                self:MicrochipNotify(MicrochipID)
            end
        end

        ::continue::
    end

    if  self.TabOn then
        self.TabOn:GetDynamicMaterial():SetScalarParameterValue("AttachmentsNum", AttachmentNum)
    end
end


function HUDWeaponDetailPC:UpdateAttachmentInfoByGMPData(InGAWAttachmentStateChangeGMPData)
    local AttachmentItemID = InGAWAttachmentStateChangeGMPData.AttachmentEffect.ItemID
    local TempPC = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    if not TempPC then 
        return 
    end

    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(TempPC, AttachmentItemID)
    if not IngameDT then
        return
    end

    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(AttachmentItemID))
    if not StructInfo_Item then
        return 
    end
    -- 根据类型判断
    if not StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Attachment then
        return
    end

    -- local CurrentAttachmentObject = UE.UGAWAttachmentFunctionLibrary.GetAttachmentInstance(self.GAWeaponInstance, InGAWAttachmentStateChangeGMPData.AttachmentEffect.EffectHandle)
    -- if not CurrentAttachmentObject then
    --     print("HUDWeaponDetailPC@UpdateAttachmentInfoByGMPData failed!")
    -- end
    local AttachmentTagName = StructInfo_Item.SlotName.TagName
    -- print("HUDWeaponDetailPC@UpdateAttachmentInfoByGMPData Tag", AttachmentTagName, InGAWAttachmentStateChangeGMPData.IsAttachAction)

    local TaegetWidget = self.CurWeaponFinalAttchWidgetTable[AttachmentTagName]
    if not TaegetWidget then
        return
    end

    if not InGAWAttachmentStateChangeGMPData.IsAttachAction then
        -- 卸下
        TaegetWidget:UpdateAttachmentInfo(nil)
    else
        -- 装上
        TaegetWidget:UpdateAttachmentInfo(InGAWAttachmentStateChangeGMPData.AttachmentEffect.ItemID)
    end

    if AttachmentTagName == "Weapon.AttachSlot.HopUp" and self.WeaponSlotData.bActive then
        local MicrochipID = InGAWAttachmentStateChangeGMPData.AttachmentEffect and tostring(InGAWAttachmentStateChangeGMPData.AttachmentEffect.ItemID) or nil
        if self.MicrochipID ~= MicrochipID and InGAWAttachmentStateChangeGMPData.IsAttachAction then
            self.MicrochipID = MicrochipID
            self:MicrochipNotify(MicrochipID)
        end
    end
end

function HUDWeaponDetailPC:ResetAttachmentInfo() -- override Function
    local testProfile = require("Common.Utils.InsightProfile")
    testProfile.Begin("HUDWeaponDetailPC:ResetAttachmentInfo")
    for i = 1, #self.AttachList do
        local widget = self.AttachWidgetTable[i].widget
        widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        widget:ResetAttachmentUI()
    end
    testProfile.End("HUDWeaponDetailPC:ResetAttachmentInfo")
end

-- 更新开火模式UI
-- 可能的值
-- InFireModeTag - FGameplayTag
-- InFireModeNum - int32
function HUDWeaponDetailPC:UpdateFireMode(InFireModeTag, InFireModeTags)
    print("(Wzp)HUDWeaponDetailPC:UpdateAttachmentInfo  [ObjectName]=",GetObjectName(self),",[InFireModeTag]=",InFireModeTag.TagName)
    -- InFireModeTag 为现在选择的模式，类型为 FGameplayTag
    -- InFireModeTags 为现在总共有多少种模式，类型为 TArray<FGameplayTag>
    local IconType = self:ConvertFireModeTagToIconID(InFireModeTag)

    print("(Wzp)HUDWeaponDetailPC:UpdateAttachmentInfo  [IconType]=",IconType)

    if InFireModeTags == nil then
        return
    end

    local TempFireModeNum = InFireModeTags:Length()
    print("(Wzp)HUDWeaponDetailPC:UpdateAttachmentInfo  [TempFireModeNum]=",TempFireModeNum)
   -- local TempFireModeNum= 0

    if TempFireModeNum <= 0 or IconType == nil then
        -- 隐藏所有开火模式相关内容
        return
    end

    local FireModeLst = {}
    for _, value in pairs(InFireModeTags) do
        local TmpTagStr = self:ConvertFireModeTagToIconID(value)
        print("HUDWeaponDetailPC >> UpdateFireMode > InFireModeTags for TmpTagStr=",TmpTagStr)
        table.insert(FireModeLst, TmpTagStr)
    end



    -- 更新总的显示的圆点个数
    local WidgetModeNum = self.HV_SkillMode:GetChildrenCount() -- 1-3
    for index = 0, WidgetModeNum - 1 do
        local widget = self.HV_SkillMode:GetChildAt(index)
        widget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    local Tex2d;

    for _, value in pairs(FireModeLst) do
        local ModeStr = string.gsub(value, "Weapon.Attribute.FireMode.", "")
        local WidgetKey = ModeStr .. "Mode"
        local Widget = self[WidgetKey]
        Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        print("HUDWeaponDetailPC >> UpdateFireMode > FireModeLst for value=",value,",InFireModeTag.TagName=",InFireModeTag.TagName,",Equal=", value == InFireModeTag.TagName)
        print("HUDWeaponDetailPC >> UpdateFireMode > FireModeLst for Type(value)=",type(value) ,",Type(InFireModeTag.TagName)=",type(InFireModeTag.TagName))
        if value == InFireModeTag.TagName then
            -- Tex2d = self.FireModeDotStyleMap:Find(2)
            Widget:SetActiveWidgetIndex(1)
        else
            -- Tex2d = self.FireModeDotStyleMap:Find(1)
            Widget:SetActiveWidgetIndex(0)
        end
        print("HUDWeaponDetailPC >> UpdateFireMode > Tex2d=",Tex2d)
        -- Widget:SetBrushFromSoftTexture(Tex2d)
    end


    print("HUDWeaponDetailPC >> UpdateFireMode > bullettypeSwitcher")
    --在Switcher容器中根据子弹图标顺序就行切换，图标控件层级必须要跟 HUDWeaponDetailBase.FireModeIcons 表对齐，顺序一样
    for _, value in pairs(HUDWeaponDetailBase.FireModeIcons) do
        print("HUDWeaponDetailPC >> UpdateFireMode > bullettypeSwitcher for value=",value.Tag,",IconType=",IconType)
        if value.Tag == IconType then
            if self.bullettypeSwitcher then
                self.bullettypeSwitcher:SetActiveWidgetIndex(value.Level - 1)
            end
        end
    end
end



function HUDWeaponDetailPC:SetInfiniteAmmoWidget(NewState)
    print("(Wzp)HUDWeaponDetailPC:SetInfiniteAmmoWidget  [ObjectName]=",GetObjectName(self),",[NewState]=",NewState)
    if NewState then
        self.HV_MaxBullet:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.GUIImage_InfiniteAmmo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.HV_MaxBullet:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.GUIImage_InfiniteAmmo:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function HUDWeaponDetailPC:SetInfiniteAmmoColor(NewState)
    print("(Wzp)HUDWeaponDetailPC:SetInfiniteAmmoColor  [ObjectName]=",GetObjectName(self),",[NewState]=",NewState)
    if NewState then
        -- 可能需要把无限子弹的颜色改为对应的弹药类型颜色
        local TempColor
        if self.BulletIdColorMap then
            TempColor = self.BulletIdColorMap:Find(self.CurrentWeaponBulletItemID)
        end

        if TempColor then
            self.GUITextBlockTag:SetColorAndOpacity(TempColor)
            self.GUIImage_InfiniteAmmo:SetColorAndOpacity(TempColor);
        end
    end
end

-- 设置当前武器的当前弹夹子弹个数文字
-- return void
function HUDWeaponDetailPC:SetCurBulletNumTxt(InBulletNum)
    print("(Wzp)HUDWeaponDetailPC:SetCurBulletNumTxt  [ObjectName]=",GetObjectName(self),",[InBulletNum]=",InBulletNum)

    local cacheStr = ""

    if BridgeHelper.IsPCPlatform() then

        --普通文本子弹逻辑
        self:SetBulletColorNormalText(InBulletNum, self.CurrentBulletTextColor, self.CurrentBulletOutlineColor,
        self.BulletWarningNum, self.WarningTextColor, self.WarningOutlineColor,
            nil, self.HV_CurrentBullet)

        --富文本子弹逻辑
        -- local RetRichStr = self:SetBulletColorRichText(InBulletNum, 2, TempMinAmmoWarningNum, self.CurrenBulletNumColor,
        -- self.MinAmmoWarningColor, nil, 50, "4_Medium")

        -- self.RTxtCurBullet:SetText(InBulletNum and RetRichStr or "00")
    end
end


-- 更新当前子弹个数的字体颜色
-- return void
function HUDWeaponDetailPC:UpdateCurrentBulletTextAndColor(CurrentBulletCount)
    print("(Wzp)HUDWeaponDetailPC:UpdateCurrentBulletTextAndColor  [ObjectName]=",GetObjectName(self),",[CurrentBulletCount]=",CurrentBulletCount)
    CurrentBulletCount = CurrentBulletCount or 0
    local FinalColor, TempMinAmmoWarningNum = UIHelper.LinearColor.LightGrey, 0

    
    if BridgeHelper.IsPCPlatform() then
        --普通文本子弹逻辑
        local BulletColor = self.MaxBulletTextColorMap:Find(self.CurrentWeaponBulletItemID) --self.WeaponBulletItemID
        local OutlineColor = self.MaxBulletOutlineColorMap:Find(self.CurrentWeaponBulletItemID)
        
        self:SetBulletColorNormalText(CurrentBulletCount, BulletColor, OutlineColor, TempMinAmmoWarningNum,
            self.WarningTextColor, self.WarningOutlineColor,
            self.GUITextBlockTag, self.HV_MaxBullet)

        --富文本子弹逻辑
        --local RetRichStr = self:SetBulletColorRichText(CurrentBulletCount,3,TempMinAmmoWarningNum,self.BulletColorStr,self.MinAmmoWarningColor,"/",28,"3_Regular")
        --self.RTxtMaxBullet:SetText(RetRichStr)
    end
end


function HUDWeaponDetailPC:SetBulletColorNormalText(CurBulletNum, BulletTextColor, OutlineTextColor, WarningNum,
                                                      WarningTextColor, WarningOutlineColor, FirstTextBlock,
                                                      ParentHorizontal)

    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("HUDWeaponDetailPC:SetBulletColorNormalText")
    if self.MainWidget and self.MainWidget.InvalidationBox then
        self.MainWidget.InvalidationBox:SetCanCache(false)
    end
    local TextColor = BulletTextColor
    local OutlineColor = OutlineTextColor
    local MaxBit = ParentHorizontal:GetChildrenCount()
    local formatStr = StringUtil.Format("%0{0}d", MaxBit)
    local TheCurBulletNum = CurBulletNum or 0
    local NumStr = string.format(formatStr, TheCurBulletNum)
    local TheNumber0Opacity = self.ZeroOpacity
    local TheWarningNum = WarningNum or 0

    local Char = '0'
    if TheCurBulletNum <= TheWarningNum then
        --少于等于警戒值
        TextColor = WarningTextColor
        OutlineColor = WarningOutlineColor
    end

    local bFind0 = true

    for i = 1, MaxBit do
        local TextBlock = ParentHorizontal:GetChildAt(i - 1) --拿到索引的TextBlock
        Char = string.sub(NumStr, i, i)              --拿到索引的字符
        TextBlock:SetText(Char)
        TextBlock:SetColorAndOpacity(TextColor)
        local FontInfo = TextBlock.Font
        FontInfo.OutlineSettings.OutlineColor = OutlineColor
        TextBlock:SetFont(FontInfo)

        if bFind0 then
            if NumStr:byte(i) ~= 48 then
                bFind0 = false
                TextBlock:SetRenderOpacity(1)
            else
                TextBlock:SetRenderOpacity(TheNumber0Opacity)
            end
        else
            TextBlock:SetRenderOpacity(1)
        end
    end

    if FirstTextBlock then
        local alpha = NumStr:byte(1) == 48 and TheNumber0Opacity or 1
        FirstTextBlock:SetRenderOpacity(alpha)
        FirstTextBlock:SetColorAndOpacity(TextColor)
        local FontInfo = FirstTextBlock.Font
        FontInfo.OutlineSettings.OutlineColor = OutlineColor
        FirstTextBlock:SetFont(FontInfo)
    end
    if self.MainWidget and self.MainWidget.InvalidationBox then
        self.MainWidget.InvalidationBox:SetCanCache(true)
    end
    TmpProfile.End("HUDWeaponDetailPC:SetBulletColorNormalText")
end



---comment 根据子弹数量返回富文本,通常颜色为基本颜色,如果前面一直有0,那么0会是半透明基本颜色，直到后面第一个不是0的数开始显示基本颜色;
---如果子弹数小于警告值,那么颜色会变成警告色;
---@param BulletNum number 子弹数量
---@param MaxBulletCharCount number 子弹显示最大位数 如"99" 3="099" 2="99" 1="9"
---@param WarningNum number  警告值：[子弹数量]小于[警告值] 富文本将会变成[警告色]
---@param StandColorHex string 基本颜色：当子弹数大于警告子弹数时显示的颜色
---@param WarningColorHex string 警告色
---@param FirstAttchStr string 第一个附加的字符串
---@param StandFontSize number 字体大小
---@param FontStype string 字体风格
---@return string 富文本字符串
function HUDWeaponDetailPC:SetBulletColorRichText(BulletNum, MaxBulletCharCount, WarningNum, StandColorHex,
                                                    WarningColorHex, FirstAttchStr, StandFontSize, FontStype)

    local formatStr = StringUtil.Format("%0{0}d", MaxBulletCharCount)
    local NumStr = string.format(formatStr, BulletNum)
    local RetRichStr = ""
    if BulletNum <= WarningNum then
        --少于等于警戒值
        --套用富文本模板插入颜色和文字
        RetRichStr = FirstAttchStr and
            StringUtil.Format('<span font="S1_Font" style="3_Regular" color="{0}" size="34">{1}</>', WarningColorHex,
                FirstAttchStr) or ""

        for i = 1, MaxBulletCharCount do
            local Char = string.sub(NumStr, i, i)
            RetRichStr = RetRichStr ..
                StringUtil.Format('<span font="{0}" color="{1}" size="{2}">{3}</>', FontStype, WarningColorHex,
                    StandFontSize,
                    Char)
        end
    else
        --大于警戒值
        --透明度列表
        local AlphaStrArr = {}
        for i = 1, MaxBulletCharCount do
            --默认全部设置成不透明 Hex=??????FF
            AlphaStrArr[i] = "FF"
        end

        for i = 1, MaxBulletCharCount do
            if NumStr:byte(i) ~= 48 then
                --判断字符的Ascll码是否为"0"，找到第一个不为0的数字，打断循环
                break
            end
            --设置透明度为60%
            AlphaStrArr[i] = "99"
        end

        --RetRichStr = StringUtil.Format('<span font="S1_Font" style="3_Regular" color="{0}" size="34">/</>', StandColorHex .. AlphaStrArr[1])

        --套用富文本模板插入颜色和文字
        RetRichStr = FirstAttchStr and
            StringUtil.Format('<span font="S1_Font" style="3_Regular" color="{0}" size="34">{1}</>',
                StandColorHex .. AlphaStrArr[1], FirstAttchStr) or ""

        for i = 1, MaxBulletCharCount do
            local ColorStr = StandColorHex .. AlphaStrArr[i]
            local Char = string.sub(NumStr, i, i)
            RetRichStr = RetRichStr ..
                StringUtil.Format('<span font="{0}" color="{1}" size="{2}">{3}</>', FontStype, ColorStr, StandFontSize,
                    Char)
        end
    end

    return RetRichStr
end



return HUDWeaponDetailPC
