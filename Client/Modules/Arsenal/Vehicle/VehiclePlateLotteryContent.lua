--[[
    车牌摇号内容逻辑
]]

local class_name = "VehiclePlateLotteryContent"
VehiclePlateLotteryContent = BaseClass(UIHandlerViewBase, class_name)

function VehiclePlateLotteryContent:OnInit()
    self.TheVehicleModel = MvcEntry:GetModel(VehicleModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
    
    self.BindNodes = 
    {
        {UDelegate = self.View.WBP_ReuseList.OnUpdateItem, Func = Bind(self, self.OnUpdateItem)},
    }
    self.Widget2Item = {}
end

function VehiclePlateLotteryContent:OnShow(Param)
    self:UpdateUI(Param)
end

function VehiclePlateLotteryContent:OnHide()
end

function VehiclePlateLotteryContent:OnManualShow(Param)
    self:UpdateUI(Param)
end
function VehiclePlateLotteryContent:OnManualHide(Param)
end

function VehiclePlateLotteryContent:UpdateUI(Param)
    if Param == nil then
        return
    end
    local VehicleId = Param.VehicleId
   
    self:SetVehicleIdTip(VehicleId)
end

---车牌号
function VehiclePlateLotteryContent:SetVehicleIdTip(VehicleId)
    -- 您当前的车牌号：
    local VehicleIdTip = self.TheArsenalModel:GetArsenalText(10031)
    local VehicleNumText = self.TheVehicleModel:GetVehicleLicensePlate(VehicleId)
    self.View.TextBlock_RuleName:SetText(VehicleIdTip)
    self.View.TextBlock_RuleName_1:SetText(VehicleNumText)
    self.View.TextBlock_RuleName_2:SetText(VehicleIdTip)
    self.View.TextBlock_RuleName_3:SetText(VehicleNumText)
end

function VehiclePlateLotteryContent:SetReady()
    self.View.WidgetSwitcherStage:SetActiveWidgetIndex(0)
end


function VehiclePlateLotteryContent:SetDoing()
    self.View.WidgetSwitcherStage:SetActiveWidgetIndex(1)
end


function VehiclePlateLotteryContent:SetFinished(LicensePlateList)
    self.View.WidgetSwitcherStage:SetActiveWidgetIndex(2)
    self.LicensePlateList = LicensePlateList
    self.View.WBP_ReuseList:Reload(#self.LicensePlateList)
    self.CurLicensePlate = nil
end


function VehiclePlateLotteryContent:CreateItem(Widget, Data)
    local Item = self.Widget2Item[Widget]
    if not Item then
        local Param = {
			OnItemClick = Bind(self,self.OnItemClick)
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Arsenal.Vehicle.VehiclePlateLotteryResultItem"), Param)
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function VehiclePlateLotteryContent:OnItemClick(Item, LicensePlate)
    self.CurLicensePlate = LicensePlate
    if self.CurSelectItem then
		self.CurSelectItem:UnSelect()
	end
	self.CurSelectItem = Item
	if self.CurSelectItem then
		self.CurSelectItem:Select()
	end
end

function VehiclePlateLotteryContent:OnUpdateItem(_, Widget, Index)
    local FixIndex = Index + 1
    local Data = self.LicensePlateList[FixIndex]
    if Data == nil then
        return
    end
    local TargetItem = self:CreateItem(Widget, Data)
    if TargetItem == nil then
        return
    end
    TargetItem:SetData(Data)
end



return VehiclePlateLotteryContent
