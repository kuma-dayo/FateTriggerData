

local EnhanceTipsItem = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function EnhanceTipsItem:OnInit()
    
    
   self.TimerHandle =nil
    UserWidget.OnInit(self)
end

function EnhanceTipsItem:OnDestroy()
  
	UserWidget.OnDestroy(self)
end

function EnhanceTipsItem:BP_InitData(InEnhanceName,InEnhanceIconSoft,InEnhanceBgSoft,InEnhanceId,InIsCollapsedByTimer)
   print("wzp print EnhanceTipsItem:BP_InitData ")
   self.EnhanceId = InEnhanceId
    self.EnhanceName:SetText(InEnhanceName)
     -- 设置背景
     local EnhanceBgSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(InEnhanceBgSoft)
     if EnhanceBgSoftPtr then
        self.EnhanceBg:SetBrushFromSoftTexture(EnhanceBgSoftPtr, false)
     end
     
     -- 更新图片
     local EnhanceIconSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(InEnhanceIconSoft)
     if EnhanceIconSoftPtr then
        self.EnhanceIcon:SetBrushFromSoftTexture(EnhanceIconSoftPtr, false)
     end
     print("wzp print EnhanceTipsItem:BP_InitData InIsCollapsedByTimer=",InIsCollapsedByTimer)
     if InIsCollapsedByTimer == true then
         self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnRemoveEnhance }, self.DisappearTime,false, 0, 0)

     end
   --   local OutTime = self.DisappearTime - self.OutAnimTime
   --   self.OutAnimTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnRemoveAnim }, OutTime,false, 0, 0)

     self:VXE_HUD_EnhanceTips_In()
end

function EnhanceTipsItem:OnRemoveEnhance()
   --print("EnhanceTipsItem:OnRemoveEnhance",self.EnhanceId)
   MsgHelper:Send(self, "UIEvent.RemoveEnhanceId",self.EnhanceId)
   if self.TimerHandle then
       UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
       self.TimerHandle = nil
       
   end
end

-- function EnhanceTipsItem:OnRemoveAnim()
--    --print("EnhanceTipsItem:OnRemoveEnhance",self.EnhanceId)
--    self:VXE_HUD_EnhanceTips_Out()
--    if self.OutAnimTimerHandle then
--        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.OutAnimTimerHandle)
--        self.OutAnimTimerHandle = nil
       
--    end
-- end


return EnhanceTipsItem