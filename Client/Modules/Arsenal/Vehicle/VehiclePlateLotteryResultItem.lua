
--- 视图控制器
local class_name = "VehiclePlateLotteryResultItem";
local VehiclePlateLotteryResultItem = BaseClass(nil, class_name);

function VehiclePlateLotteryResultItem:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.VehiclePlateBtn.OnClicked,			    Func = Bind(self, self.OnVehiclePlateBtnCicked) },
		{ UDelegate = self.View.VehiclePlateBtn.OnHovered,				Func = Bind(self, self.OnVehiclePlateBtnHovered) },
		{ UDelegate = self.View.VehiclePlateBtn.OnUnhovered,			Func = Bind(self, self.OnVehiclePlateBtnUnhovered) },
	}
end

function VehiclePlateLotteryResultItem:OnShow(Param)
    self.Param = Param
    self.View:RemoveAllActiveWidgetStyleFlags()
end

function VehiclePlateLotteryResultItem:OnHide()
end

function VehiclePlateLotteryResultItem:SetData(LicensePlate)
    self.LicensePlate = LicensePlate
    self.View.TextBlock_LicensePlate:SetText(LicensePlate)
    self.View:RemoveAllActiveWidgetStyleFlags()
    self.View:AddActiveWidgetStyleFlags(1)
end

function VehiclePlateLotteryResultItem:OnVehiclePlateBtnCicked()
    if self.Param.OnItemClick then
        self.Param.OnItemClick(self, self.LicensePlate)
    end
end

function VehiclePlateLotteryResultItem:Select()
    self.View:AddActiveWidgetStyleFlags(3)
end

function VehiclePlateLotteryResultItem:UnSelect()
    self.View:RemoveActiveWidgetStyleFlags(3)
end

function VehiclePlateLotteryResultItem:OnVehiclePlateBtnHovered()
    self.View:AddActiveWidgetStyleFlags(2)
end

function VehiclePlateLotteryResultItem:OnVehiclePlateBtnUnhovered()
    self.View:RemoveActiveWidgetStyleFlags(2)
end

return VehiclePlateLotteryResultItem
