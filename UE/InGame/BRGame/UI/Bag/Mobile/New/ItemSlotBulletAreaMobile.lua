local ItemSlotBulletAreaMobile = Class("Common.Framework.UserWidget")

function ItemSlotBulletAreaMobile:OnInit()
    print("NewBagMobile@ItemSlotBulletAreaMobile Init")

    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    UserWidget.OnInit(self)
end

function ItemSlotBulletAreaMobile:OnShow(InContext, InGenericBlackboard)
    self.Overridden.OnShow(self, InContext, InGenericBlackboard)

    self:ShowWidget()
end

function ItemSlotBulletAreaMobile:OnDestroy()
    self:InitData()
    self:UnregUIEvent()
    
    UserWidget.OnDestroy(self)
end

--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  

function ItemSlotBulletAreaMobile:InitUI()
   self.BulletWidgetMap = {
        [130200002] = self.BP_BagEquip_Bullet_1,
        [130200001] = self.BP_BagEquip_Bullet_2,
        [130200003] = self.BP_BagEquip_Bullet_3,
        [130200004] = self.BP_BagEquip_Bullet_4,
        [130200005] = self.BP_BagEquip_Bullet_5,
   }

   -- 初始设置
   for BulletID, BulletWidget in pairs(self.BulletWidgetMap) do
        BulletWidget:SetBulletID(BulletID)
   end
end

function ItemSlotBulletAreaMobile:InitData()
    self.ViewModel_PlayerBag = UE.UGUIManager.GetUIManager(self):GetViewModelByName("ViewModel_PlayerBag")
    if not self.ViewModel_PlayerBag then
        print("BagM@ItemSlotBulletAreaMobile Init VM Failed!")
    end
end

function ItemSlotBulletAreaMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
       
    }
end

function ItemSlotBulletAreaMobile:InitUIEvent()
    if not self.ViewModel_PlayerBag then
        return
    end
    self.ViewModel_PlayerBag.UIEvent_Bullet_Add:Add(self,self.OnBulletAdd)
    self.ViewModel_PlayerBag.UIEvent_Bullet_Destroy:Add(self,self.OnBulletDestroy)
    self.ViewModel_PlayerBag.UIEvent_Bullet_NumUpdate:Add(self,self.OnBulletNumUpdate)
    self.ViewModel_PlayerBag.UIEvent_Bullet_MaxNumUpdate:Add(self,self.OnBulletMaxNumUpdate)
end

function ItemSlotBulletAreaMobile:UnregUIEvent()
    if not self.ViewModel_PlayerBag then
        return
    end
    self.ViewModel_PlayerBag.UIEvent_Bullet_Add:Remove(self,self.OnBulletAdd)
    self.ViewModel_PlayerBag.UIEvent_Bullet_Destroy:Remove(self,self.OnBulletDestroy)
    self.ViewModel_PlayerBag.UIEvent_Bullet_NumUpdate:Remove(self,self.OnBulletNumUpdate)
    self.ViewModel_PlayerBag.UIEvent_Bullet_MaxNumUpdate:Remove(self,self.OnBulletMaxNumUpdate)
end

function ItemSlotBulletAreaMobile:GetAllBulletWidget()
    return self.BulletWidgetMap
end

--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|
function ItemSlotBulletAreaMobile:ShowWidget()
    if not self.ViewModel_PlayerBag then
        return
    end

    self:RefreshBulletTypeNum()
    for BulletID, BulletWidget in pairs(self.BulletWidgetMap) do
        local BulletData = self.ViewModel_PlayerBag.BulletItemMap:FindRef(BulletID)
        if BulletData ~= nil then
            BulletWidget:SetBulletData(BulletData)
            BulletWidget:ShowWidget()
        else
            BulletWidget:ResetWidget()
        end
    end
end

function ItemSlotBulletAreaMobile:RefreshBulletTypeNum()
    local ExistBulletTypeNum = self.ViewModel_PlayerBag.BulletItemMap:Num()
    print("BagM@ItemSlotBulletAreaMobile bulletTypeNum:", ExistBulletTypeNum)
    self.Text_BulletNum:SetText(tostring(ExistBulletTypeNum))
    self.Text_Bullet:SetText("/"..tostring(5))
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
function ItemSlotBulletAreaMobile:OnBulletAdd(BulletID)
    local NewData = self.ViewModel_PlayerBag.BulletItemMap:FindRef(BulletID)
    local Widget = self.BulletWidgetMap[BulletID]
    if NewData and Widget then
        Widget:SetBulletData(NewData)
        Widget:ShowWidget()
    end
    self:RefreshBulletTypeNum()
end

function ItemSlotBulletAreaMobile:OnBulletDestroy(BulletID)
    local Widget = self.BulletWidgetMap[BulletID]
    if Widget then
        Widget:ResetWidget()
    end
    self:RefreshBulletTypeNum()
end

function ItemSlotBulletAreaMobile:OnBulletNumUpdate(BulletID)
    local NewData = self.ViewModel_PlayerBag.BulletItemMap:FindRef(BulletID)
    local Widget = self.BulletWidgetMap[BulletID]
    if NewData and Widget then
        Widget:SetBulletData(NewData)
        Widget:RefreshBulletNum(NewData.ItemNum, NewData.ItemMaxNum)
    end
end

function ItemSlotBulletAreaMobile:OnBulletMaxNumUpdate(BulletID)
    local NewData = self.ViewModel_PlayerBag.BulletItemMap:FindRef(BulletID)
    local Widget = self.BulletWidgetMap[BulletID]
    if NewData and Widget then
        Widget:SetBulletData(NewData)
        Widget:RefreshBulletNum(NewData.ItemNum, NewData.ItemMaxNum)
    end
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 


return ItemSlotBulletAreaMobile