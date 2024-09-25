local class_name = "ReadyToLoadResourceMdt";
ReadyToLoadResourceMdt = ReadyToLoadResourceMdt or BaseClass(GameMediator, class_name);


function ReadyToLoadResourceMdt:__init()
end

function ReadyToLoadResourceMdt:OnShow(data)
end

function ReadyToLoadResourceMdt:OnHide()
end

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()

    self.MsgListGMP = {
        { InBindObject = _G.GameInstance,	MsgName = "ReadyToLoadResourceMdt.OnLoaded",Func = Bind(self,self.OnLoaded), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.GameInstance,	MsgName = "ReadyToLoadResourceMdt.Update",Func = Bind(self,self.OnUpdate), bCppMsg = true, WatchedObject = nil },
       
    }

end

function M:OnShow(Param)
    if _G.GameInstance then
        _G.GameInstance:ReadyToLoadResource()
    end

    self.UpdateBar:SetPercent(0.01)
end

function M:OnLoaded()
    self.UpdateBar:SetPercent(1)
    MvcEntry:CloseView(self.viewId)
end

function M:OnUpdate(data)
    self.UpdateBar:SetPercent(data)
end


return M