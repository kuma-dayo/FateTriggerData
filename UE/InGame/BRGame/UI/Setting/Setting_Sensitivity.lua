--
-- 设置界面 -- 灵敏度设置
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.11.11
--

local Setting_Sensitivity = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function Setting_Sensitivity:OnInit()

    -- self.MsgList = {
   
	-- }

	UserWidget.OnInit(self)
end

function Setting_Sensitivity:OnDestroy()

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------
-- function Setting_Sensitivity:BndEvt__BP_SubMenu_Sensitivity_BP_Group_K2Node_ComponentBoundEvent_0_OnItemValueChanged__DelegateSignature(Value,Tag)
--     --MsgHelper:SendCpp(self, UE.US1MiscLibrary.GetGameplayTagString(Tag), Value)
--     UE.UGenericSettingSubsystem.Get():SetSettingValue(Tag,Value)
-- end



return Setting_Sensitivity