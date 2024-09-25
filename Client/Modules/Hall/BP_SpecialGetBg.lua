require "UnLua"
-- 特殊获得弹窗 场景背景板
local BP_SpecialGetBg = Class()

function BP_SpecialGetBg:ReceiveBeginPlay()
    CLog("BP_SpecialGetBg: BeginPlay")
	self.Overridden.ReceiveBeginPlay(self)
    CommonUtil.DoMvcEntyAction(function ()
        MvcEntry:GetModel(ItemGetModel):AddListener(ItemGetModel.ON_SET_SPECIAL_GET_BG,self.SetSpecialMaterial,self)
    end)

end

function BP_SpecialGetBg:ReceiveEndPlay(EndPlayReason)
    self.Overridden.ReceiveEndPlay(self,EndPlayReason)	
    MvcEntry:GetModel(ItemGetModel):RemoveListener(ItemGetModel.ON_SET_SPECIAL_GET_BG,self.SetSpecialMaterial,self)
end

function BP_SpecialGetBg:SetSpecialMaterial(Quality)
    -- 暂时只有两个品质材质
    if Quality >= 4 then
        Quality = 4
    else
        Quality = 3
    end
    -- 设置对应的材质球
    local MaterialObj = self["SpecialMaterial_"..Quality]
    if MaterialObj then
        self.StaticMesh:SetMaterial(0,MaterialObj)
    end
end

function BP_SpecialGetBg:ReceiveDestroyed()
end

return BP_SpecialGetBg
