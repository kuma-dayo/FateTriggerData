--
-- 战斗界面控件 - 通用提示Icon
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.06.21
--

local GenericIconTipsItem = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function GenericIconTipsItem:OnInit()
    self.TxtTips:SetText("")

	UserWidget.OnInit(self)
end

function GenericIconTipsItem:OnDestroy()

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------


--[[
    InParamerters = { bEnable = xx, IconAsset = xx, TextTips = xx, LinearColor = xx, }

function GenericIconTipsItem:InitData(InParamerters)
    --Dump(InParamerters, InParamerters, 9)
    
    if InParamerters.bEnable then
        self.TxtTips:SetText(InParamerters.TextTips)
        
	    --self.ImgTxtBg:SetColorAndOpacity(InParamerters.LinearColor)
	    --self.ImgIconBg:SetColorAndOpacity(InParamerters.LinearColor)

        if InParamerters.IconAsset and ("" ~= InParamerters.IconAsset) then
            self.ImgIcon:SetBrushFromSoftTexture(InParamerters.IconAsset, false)
        end
    end
    self:SetVisibility(InParamerters.bEnable and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
end]]--

function GenericIconTipsItem:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    local IconAssetSelector = UE.FGenericBlackboardKeySelector()  
    IconAssetSelector.SelectedKeyName = "IconAsset"
    local IconAssetValue ,OutIconAssetSelectorBool =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,IconAssetSelector)
    print("GenericIconTipsItem:OnTipsInitialize IconAssetValue",IconAssetValue,"OutIconAssetSelectorBool",OutIconAssetSelectorBool)
    if IconAssetValue == "" then
        print("GenericIconTipsItem:OnTipsInitialize IconAssetValue is nil")
        return 
    end
    local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(IconAssetValue)
    if not ImageSoftObjectPtr then return end
    if self.ImgIcon then self.ImgIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false) end
end



-------------------------------------------- Callable ------------------------------------


return GenericIconTipsItem


