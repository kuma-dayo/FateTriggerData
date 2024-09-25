local class_name = "CustomRoomTabWidgetLogic"
local CustomRoomTabWidgetLogic = BaseClass(nil, class_name)


function CustomRoomTabWidgetLogic:OnInit()
    self.BindNodes = {
		{UDelegate = self.View.GUIButton_ClickArea.OnClicked,Func = Bind(self,self.OnBtnClick)},
	}
end

function CustomRoomTabWidgetLogic:OnShow(Data)
    self:SetData(Data)
end
function CustomRoomTabWidgetLogic:OnHide()
    
end

--[[
     {
        OnItemClick = Bind(self,self.OnWatchTypeClick),
        ShowStr = "",
        InstanceId = 0,
    }
]]
function CustomRoomTabWidgetLogic:SetData(Data)
    if not Data then
        return
    end
    self.Data = Data

    self.View.Text_Mode:SetText(StringUtil.Format(self.Data.ShowStr or "None"))
end

function CustomRoomTabWidgetLogic:OnBtnClick()
    if self.Data and self.Data.OnItemClick then
        self.Data.OnItemClick(self.Data.InstanceId)
    end
end

function CustomRoomTabWidgetLogic:Select()
    self:UpdateWidgetState(1)
end
function CustomRoomTabWidgetLogic:UnSelect()
    self:UpdateWidgetState(0)
end
function CustomRoomTabWidgetLogic:UnAvailable()
    self:UpdateWidgetState(2)
end

function CustomRoomTabWidgetLogic:UpdateWidgetState(State)
    --0.normal 1.选择 2.锁住
    self.View:SetWidgetState(State)
end

function CustomRoomTabWidgetLogic:UpdateSelect(SelectInstanceId)
    if SelectInstanceId == self.Data.InstanceId then
        self:Select()
    else
        self:UnSelect()
    end
end
return CustomRoomTabWidgetLogic
