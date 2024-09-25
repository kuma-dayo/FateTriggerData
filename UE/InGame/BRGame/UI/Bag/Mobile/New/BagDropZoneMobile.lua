local BagDropZoneMobile = Class("Common.Framework.UserWidget")


local TAB_ENUM ={
    Bag = 1,
    Clothes = 2
}

local TAB_BG_STATE ={
    Normal = 1,
    Drop = 2
}

function BagDropZoneMobile:OnInit()
    print("BagM@DropZone Init")
    self:InitUi()

    self:BindUIEvent()
end

function BagDropZoneMobile:OnShow()

end


function BagDropZoneMobile:OnDestroy()

end

function BagDropZoneMobile:RegTabCallback(tabEnum, callback)
    self.TabCallback[tabEnum] = callback
end

--   _   _ ___   ___ _   _ ___ _____ 
--  | | | |_ _| |_ _| \ | |_ _|_   _|
--  | | | || |   | ||  \| || |  | |  
--  | |_| || |   | || |\  || |  | |  
--   \___/|___| |___|_| \_|___| |_|  
                                  
function BagDropZoneMobile:InitUi()    
    self.TabBgState = TAB_BG_STATE.Normal

    self.TabWidgetSwitcher ={
        [TAB_ENUM.Bag] = self.WidgetSwitcher_Bag,
        [TAB_ENUM.Clothes] = self.WidgetSwitcher_Clothes,
    }
    -- 当前不需要展示
    self.WidgetSwitcher_Clothes:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Button_Clothes:SetVisibility(UE.ESlateVisibility.Collapsed)

    self.TabCallback = {}

    self:SetVisibility(UE.ESlateVisibility.Visible)
end

--   _   _ ___   _   _    _    _   _ ____  _     _____ 
--  | | | |_ _| | | | |  / \  | \ | |  _ \| |   | ____|
--  | | | || |  | |_| | / _ \ |  \| | | | | |   |  _|  
--  | |_| || |  |  _  |/ ___ \| |\  | |_| | |___| |___ 
--   \___/|___| |_| |_/_/   \_\_| \_|____/|_____|_____|
                                                
function BagDropZoneMobile:SetTabIndex(TabEnum)
    print("NewBagMobile@SetTabIndex ", TabEnum)
    for tabEnum, switcher in pairs(self.TabWidgetSwitcher) do
        if tabEnum == TabEnum then
            switcher:SetActiveWidgetIndex(1)
        else
            switcher:SetActiveWidgetIndex(0)
        end
    end
end

function BagDropZoneMobile:SetDropState(IsDrop)
    if IsDrop then
        self.WidgetSwitcher_Drop:SetActiveWidgetIndex(1)
    else
        self.WidgetSwitcher_Drop:SetActiveWidgetIndex(0)
    end
end

--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  
                                              
function BagDropZoneMobile:BindUIEvent()
    self.Button_Close.OnClicked:Add(self,self.OnClicked_Close)

    self.Button_Bag.OnClicked:Add(self,self.OnClicked_Bag)
    self.Button_Clothes.OnClicked:Add(self,self.OnClicked_Clothes)
end

function BagDropZoneMobile:OnMouseButtonDown(MyGeometry, MouseEvent)
    -- 使得按钮响应
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function BagDropZoneMobile:OnMouseButtonUp(MyGeometry, MouseEvent)
   return UE.UWidgetBlueprintLibrary.Unhandled()
end

function BagDropZoneMobile:OnClicked_Close()
    print("NewBagMobile@OnClicked_Close")

    local UIManager = UE.UGUIManager.GetUIManager(self)
    UIManager:TryCloseDynamicWidget("UMG_Bag")
end

function BagDropZoneMobile:OnClicked_Bag()
    self:SetTabIndex(TAB_ENUM.Bag)

    if self.TabCallback[TAB_ENUM.Bag] then
        self.TabCallback[TAB_ENUM.Bag](TAB_ENUM.Bag)
    end

end

function BagDropZoneMobile:OnClicked_Clothes()
    self:SetTabIndex(TAB_ENUM.Clothes)
    if self.TabCallback[TAB_ENUM.Clothes] then
        self.TabCallback[TAB_ENUM.Clothes](TAB_ENUM.Clothes)
    end
end



function BagDropZoneMobile:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self:SetDropState(true)
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)

    print("BagM@BagDropZoneMobile:OnDragEnter")
end

function BagDropZoneMobile:OnDrop(MyGeometry, PointerEvent, Operation)
    print("BagM@BagDropZoneMobile:OnDrop")
    self:SetDropState(false)
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
end

function BagDropZoneMobile:OnDragLeave(PointerEvent, Operation)
    print("BagM@BagDropZoneMobile:OnDragLeave")
    self:SetDropState(false)
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end

return BagDropZoneMobile