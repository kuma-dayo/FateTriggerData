local ItemSlotEquipAreaMobile = Class("Common.Framework.UserWidget")

function ItemSlotEquipAreaMobile:OnInit()
    print("NewBagMobile@ItemSlotEquipAreaMobile Init")

    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    UserWidget.OnInit(self)
end

function ItemSlotEquipAreaMobile:OnShow(InContext, InGenericBlackboard)
    self.Overridden.OnShow(self, InContext, InGenericBlackboard)

    self:ShowWidget()
end

function ItemSlotEquipAreaMobile:OnDestroy()
    self:InitData()
    self:UnregUIEvent()
    
    UserWidget.OnDestroy(self)
end

--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  

function ItemSlotEquipAreaMobile:InitUI()
   self.EquipWidgetMap = {
        ["ArmorHead"] = self.BP_BagEquip_ArmorHead,
        ["Bag"] = self.BP_BagEquip_Bag,
        ["ArmorBody"] = self.BP_BagEquip_ArmorBody,
        ["Currency"] = self.BP_Currency,
   }

   -- 初始设置
   for ArmorType, ArmorWidget in pairs(self.EquipWidgetMap) do
        ArmorWidget:ResetWidget()
   end
end

function ItemSlotEquipAreaMobile:InitData()
    self.ViewModel_PlayerBag = UE.UGUIManager.GetUIManager(self):GetViewModelByName("ViewModel_PlayerBag")
    if not self.ViewModel_PlayerBag then
        print("BagM@ItemSlotEquipAreaMobile Init VM Failed!")
    end
end

function ItemSlotEquipAreaMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
       
    }
end

function ItemSlotEquipAreaMobile:InitUIEvent()
    if not self.ViewModel_PlayerBag then
        return
    end
    
    self.ViewModel_PlayerBag.UIEvent_Equip_Update:Add(self,self.OnUpdateArmorSlot)
    self.ViewModel_PlayerBag.UIEvent_Equip_Reset:Add(self,self.OnResetArmorSlot)

end

function ItemSlotEquipAreaMobile:UnregUIEvent()
    if not self.ViewModel_PlayerBag then
        return
    end
    self.ViewModel_PlayerBag.UIEvent_Equip_Update:Remove(self,self.OnUpdateArmorSlot)
    self.ViewModel_PlayerBag.UIEvent_Equip_Reset:Remove(self,self.OnResetArmorSlot)
end

function ItemSlotEquipAreaMobile:GetAllEquipWidget()
    return self.EquipWidgetMap
end

--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|
function ItemSlotEquipAreaMobile:ShowWidget()
    if not self.ViewModel_PlayerBag then
        return
    end

    local ExistArmorTypeNum = self.ViewModel_PlayerBag.EquipItemMap:Num()
    print("BagM@ItemSlotEquipAreaMobile ArmorTypeNum:", ExistArmorTypeNum)
    
    for ArmorType, ArmorWidget in pairs(self.EquipWidgetMap) do
        local ArmorData = self.ViewModel_PlayerBag.EquipItemMap:FindRef(ArmorType)
        if ArmorData ~= nil then
            ArmorWidget:SetArmorData(ArmorData)
            ArmorWidget:ShowWidget()
        else
            ArmorWidget:ResetWidget()
        end
    end
end



--   _   _ ___    ____ ___  _   _ _____ ____   ___  _      
--  | | | |_ _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |     
--  | | | || |  | |  | | | |  \| | | | | |_) | | | | |     
--  | |_| || |  | |__| |_| | |\  | | | |  _ <| |_| | |___  
--   \___/|___|  \____\___/|_| \_| |_| |_| \_\\___/|_____|


--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  
function ItemSlotEquipAreaMobile:OnUpdateArmorSlot(ArmorType)
    local NewData = self.ViewModel_PlayerBag.EquipItemMap:FindRef(ArmorType)
    local Widget = self.EquipWidgetMap[ArmorType]
    if NewData and Widget then
        Widget:SetArmorData(NewData)
        Widget:ShowWidget()
    end
end

function ItemSlotEquipAreaMobile:OnResetArmorSlot(ArmorType)
    local Widget = self.EquipWidgetMap[ArmorType]
    if Widget then
        Widget:ResetWidget()
    end
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 


return ItemSlotEquipAreaMobile