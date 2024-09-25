require "UnLua"
local class_name = "CustomLayoutApplyTips"
CustomLayoutApplyTips = CustomLayoutApplyTips or BaseClass(GameMediator, class_name);



function CustomLayoutApplyTips:__init()
    
    self:ConfigViewId(ViewConst.CustomLayoutApplyTips)
  
end



local CustomLayoutApplyTips =Class("Client.Mvc.UserWidgetBase")
function CustomLayoutApplyTips:OnInit()
 
    UserWidgetBase.OnInit(self)
    
end

function CustomLayoutApplyTips:OnShow()
    --自己倒计时把自己干掉  目前是2.0 大厅和局内要在两个地方配置
    self.DelayTimer = Timer.InsertTimer(self.DelayTime,function ()
        MvcEntry:CloseView(self.viewId)
        Timer.RemoveTimer(self.DelayTimer)
        self.DelayTimer = nil
     end)
end

return CustomLayoutApplyTips