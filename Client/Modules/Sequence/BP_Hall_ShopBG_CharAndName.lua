local BP_Hall_ShopBG_CharAndName = Class()

function BP_Hall_ShopBG_CharAndName:ReceiveBeginPlay()
	CLog("BP_Hall_ShopBG_CharAndName: BeginPlay")
	self.Overridden.ReceiveBeginPlay(self)
    CommonUtil.DoMvcEntyAction(function ()
        MvcEntry:GetModel(ShopModel):AddListener(ShopModel.HANDLE_SHOPBG_SHOW,self.OnTriggerShowOrHide,self)
    end)
end


function BP_Hall_ShopBG_CharAndName:ReceiveEndPlay(EndPlayReason)
    self.Overridden.ReceiveEndPlay(self,EndPlayReason)	
    MvcEntry:GetModel(ShopModel):RemoveListener(ShopModel.HANDLE_SHOPBG_SHOW,self.OnTriggerShowOrHide,self)
end

function BP_Hall_ShopBG_CharAndName:OnTriggerShowOrHide(Param)
    if not Param then
        return
    end
    --TODO 调用蓝图方法
    if Param.Open then
        if Param.Text then
            self:HandleShowText(Param.Text)
        elseif Param.Path and Param.Path ~= "" then
            self:HandleShowBg(Param.Path)
        else
            self:TriggerHide()
        end
    else
        self:TriggerHide()
    end
end

return BP_Hall_ShopBG_CharAndName