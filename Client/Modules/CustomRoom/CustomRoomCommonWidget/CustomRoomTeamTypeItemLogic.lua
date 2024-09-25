local class_name = "CustomRoomTeamTypeItemLogic"
local CustomRoomTeamTypeItemLogic = BaseClass(nil, class_name)


function CustomRoomTeamTypeItemLogic:OnInit()
    self.BindNodes = {
		{UDelegate = self.View.GUIButton_ClickArea.OnClicked,Func = Bind(self,self.OnBtnClick)},
	}
end

function CustomRoomTeamTypeItemLogic:OnShow(Data)
    self:SetData(Data)
end
function CustomRoomTeamTypeItemLogic:OnHide()
    
end

--[[
     {
        OnItemClick = Bind(self,self.OnWatchTypeClick),
        MemberCount = 0,
    }
]]
function CustomRoomTeamTypeItemLogic:SetData(Data)
    if not Data then
        return
    end
    self.Data = Data

    self.MemberCount = self.Data.MemberCount
    self.AvailableState = true

    for i=1,4 do
        if i <=self.MemberCount then
            self.View["NormalImage_" .. i]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.View["NormalImage_" .. i]:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function CustomRoomTeamTypeItemLogic:OnBtnClick()
    if not self.AvailableState then
        return
    end
    if self.Data and self.Data.OnItemClick then
        self.Data.OnItemClick(self.Data.MemberCount)
    end
end

function CustomRoomTeamTypeItemLogic:Select()
    self:UpdateWidgetState(1)
end
function CustomRoomTeamTypeItemLogic:UnSelect()
    self:UpdateWidgetState(0)
end
function CustomRoomTeamTypeItemLogic:UnAvailable()
    self.AvailableState = false
    self:UpdateWidgetState(2)
end
function CustomRoomTeamTypeItemLogic:DoAvailable()
    self.AvailableState = true
    self:UpdateWidgetState(0)
end

function CustomRoomTeamTypeItemLogic:UpdateWidgetState(State)
    --0.normal 1.选择 2.锁住
    self.View:SetWidgetState(State)
end

function CustomRoomTeamTypeItemLogic:UpdateSelect(SelectInstanceId)
    if not self.AvailableState then
        return
    end
    if SelectInstanceId == self.Data.MemberCount then
        self:Select()
    else
        self:UnSelect()
    end
end
return CustomRoomTeamTypeItemLogic
