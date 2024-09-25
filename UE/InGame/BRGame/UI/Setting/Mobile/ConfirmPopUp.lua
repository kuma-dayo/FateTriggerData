
require "UnLua"
local class_name = "ConfirmPopUp"
ConfirmPopUp = ConfirmPopUp or BaseClass(GameMediator, class_name);



function ConfirmPopUp:__init()
    print("LayoutSelectPopUp:__init")
    self:ConfigViewId(ViewConst.CustomLayoutConfirm)
  
end


local ConfirmPopUp =Class("Client.Mvc.UserWidgetBase")
function ConfirmPopUp:OnInit()
    self.BindNodes ={    
        { UDelegate = self.BP_Button_Weak_First.Button.OnReleased, Func = self.OnSaved},
        { UDelegate = self.BP_Button_Strong_First.Button.OnReleased, Func = self.OnUnSaved },
        { UDelegate = self.Button_Close.OnReleased, Func = self.OnCloseTips },
        }
    
    UserWidgetBase.OnInit(self)
end


function ConfirmPopUp:OnSaved()
    --向设置发送保存信号，关闭tips
    
    self:OnCloseTips()
    MsgHelper:Send(self, "UIEvent.NotifyCallSaveLayout")
    
    --self:CloseLayoutPanel()
end

function ConfirmPopUp:OnUnSaved()
    --清理缓存数据，关tips

    self:OnCloseTips()
    self:CloseLayoutPanel()
end

function ConfirmPopUp:OnCloseTips()
    self:CloseTips()
end

function ConfirmPopUp:CloseTips()
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        --在局内
        UE.UTipsManager.GetTipsManager(self):RemoveTipsUI("Setting.CustomLayoutConfirm")
    else
        MvcEntry:CloseView(self.viewId)
    end
end

function ConfirmPopUp:CloseLayoutPanel()
    local data ={
        IsShow = true
    }
    MsgHelper:Send(self, "UIEvent.SettingIsShow",data)
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        --在局内
        UE.UGUIManager.GetUIManager(self):TryCloseDynamicWidget("UMG_MobileCustomLayout")
    else
        MvcEntry:CloseView(ViewConst.CustomMainUI)
    end
   
    
end

return ConfirmPopUp