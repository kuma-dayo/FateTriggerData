
require "UnLua"
local class_name = "CustomMainUI"
LayoutSelectPopUp = LayoutSelectPopUp or BaseClass(GameMediator, class_name);



function LayoutSelectPopUp:__init()
    print("LayoutSelectPopUp:__init")
    self:ConfigViewId(ViewConst.LayoutSelect)
  
end



local LayoutSelectPopUp =Class("Client.Mvc.UserWidgetBase")
function LayoutSelectPopUp:OnInit()
    self.BindNodes ={    
        { UDelegate = self.SelectWidget0.Button.OnClicked, Func = self.OnSelectWidget0},
        { UDelegate = self.SelectWidget1.Button.OnClicked, Func = self.OnSelectWidget1 },
        { UDelegate = self.SelectWidget2.Button.OnClicked, Func = self.OnSelectWidget2 },
        { UDelegate = self.SelectWidget3.Button.OnClicked, Func = self.OnSelectWidget3 },
        { UDelegate = self.Button_Close.OnClicked, Func = self.CloseLayoutSelect },
        
        }
    
    UserWidgetBase.OnInit(self)
end
function LayoutSelectPopUp:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:RevertItem()
    local Index,IsFindIndex =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsIntSimple(TipGenricBlackboard,"LayoutIndex")
    self.ActiveIndex = Index
    self.ItemBox:GetChildAt(self.ActiveIndex).WidgetSwitcher:SetActiveWidgetIndex(1)
    
end


function LayoutSelectPopUp:OnShow(data,GenricBlackboard)
   
    
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
     
    else
        self:RevertItem()
        self.ActiveIndex = data.LayoutIndex
        self.ItemBox:GetChildAt(self.ActiveIndex).WidgetSwitcher:SetActiveWidgetIndex(1)
    end
    
end

function LayoutSelectPopUp:ChangeActiveItem(InIndex)
    local widget = self.ItemBox:GetChildAt(self.ActiveIndex)
    widget.WidgetSwitcher:SetActiveWidgetIndex(0)
    self.ActiveIndex = InIndex
    widget = self.ItemBox:GetChildAt(self.ActiveIndex)
    widget.WidgetSwitcher:SetActiveWidgetIndex(1)
end

function LayoutSelectPopUp:OnSelectWidget0()
    self:ChangeActiveItem(0)
end

function LayoutSelectPopUp:OnSelectWidget1()
    self:ChangeActiveItem(1)
end
function LayoutSelectPopUp:OnSelectWidget2()
    self:ChangeActiveItem(2)
end
function LayoutSelectPopUp:OnSelectWidget3()
    self:ChangeActiveItem(3)
end

function LayoutSelectPopUp:RevertItem()
    local widget = nil
    for i= 0,self.ItemBox:GetChildrenCount()-1 do 
        widget = self.ItemBox:GetChildAt(i)
        widget.WidgetSwitcher:SetActiveWidgetIndex(0)
    end
end

function LayoutSelectPopUp:CloseLayoutSelect()
    --发送数据改变自定义的布局数据
    local data ={
        ActiveIndex =  self.ActiveIndex,
        NewText = self.ItemBox:GetChildAt(self.ActiveIndex).NewText,
    }
    MsgHelper:Send(self, "UIEvent.NotifyChangeLayout",data)
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        UE.UTipsManager.GetTipsManager(self):RemoveTipsUI("Setting.LayoutSelect")
    else
         MvcEntry:CloseView(self.viewId)
    end
end
return LayoutSelectPopUp