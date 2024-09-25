--[[
    设置系统协议处理模块
]]

require("Client.Modules.Setting.SettingModel")
local class_name = "SettingCtrl"
---@class SettingCtrl : UserGameController
SettingCtrl = SettingCtrl or BaseClass(UserGameController,class_name)


function SettingCtrl:__init()
    CWaring("==SettingCtrl init")
end

function SettingCtrl:Initialize()
     ---@type SettingModel
     self.SettingModel = MvcEntry:GetModel(SettingModel)
    
end

--[[
    玩家登入
]]
function SettingCtrl:OnLogin(data)
   
    --self.SettingModel:OnLogin()
    
    
end

function SettingCtrl:OnLogout()
    --self.SettingModel:OnLogout()
    
end



---监听消息，主要是监听后台发送的设置数据
function SettingCtrl:AddMsgListenersUser()
    print("SettingCtrl:AddMsgListenersUser")
    self.ProtoList = {
        --初始化接收一次全额的设置数据
    	{MsgName = Pb_Message.GetSettingsRsp,	Func = self.GetSettingsRsp_Func },
        --初始化接收手机端的自定义的数据
        {MsgName = Pb_Message.GetCustomLayoutRsp,	Func = self.GetCustomLayoutRsp_Func },
    }
    self.MsgListGMP = {
        {InBindObject = _G.MainSubSystem, MsgName = "UIEvent.SendSettingData", Func = Bind(self,self.SendSettingData), bCppMsg = true, WatchedObject = nil },
       
     }
end


---------------------------------请求相关--------------------------------------

function SettingCtrl:GetSettingsRsp_Func(Msg)
    print_r(Msg.Settings,"SettingCtrl:GetSettingsRsp_Func")
    self.LocalPC =  UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self.LocalPC)
   
    if SettingSubsystem ==nil then
       return
    end
    ---GenericSettingSubsystem其实就相当于model层
    for k,v in pairs(Msg.Settings) do
        --print("SettingCtrl:GetSettingsRsp_Func",k,v)
        local TmpSetting = UE.FSettingValue()
        TmpSetting.Value_Int = v.Value_Int
        TmpSetting.Value_Float = v.Value_Float
        --TmpSetting.Value_Bool = v.Value_Bool
        for _, ArrayV in pairs(v.Value_IntArray) do
            TmpSetting.Value_IntArray:Add(ArrayV)
        end
        --print("SettingCtrl:GetSettingsRsp_Func SetSettingDataFromServer",k,TmpSetting,SettingSubsystem)
        SettingSubsystem:SetSettingDataFromServer(k, TmpSetting)
    end
    
    SettingSubsystem:NotifyUpdateSettingDataFromServer()
   
    
end

-------------------------请求手机自定义布局的数据的回调----------------------------
function SettingCtrl:GetCustomLayoutRsp_Func(Msg)
    print_r(Msg.LayoutGroups,"SettingCtrl:GetCustomLayoutRsp_Func")
    self.LocalPC =  UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self.LocalPC)
   
    if SettingSubsystem ==nil then
        print("SettingCtrl:GetCustomLayoutRsp_Func",self.LocalPC,SettingSubsystem)
       return
    end
    for k,v in pairs(Msg.LayoutGroups) do 
        local TmpLayoutSaveData = UE.FSettingLayoutSaveData()
        TmpLayoutSaveData.LayoutName = v.LayoutGroupName
        for i,j in pairs(v.ChangedLayouts) do 
            local TmpLayoutItemSaveData = UE.FSettingLayoutItemSaveData()
            TmpLayoutItemSaveData.ItemLayoutTagName = i
            local TmpLayoutItemSaveDataToServer = UE.FSettingLayoutItemSaveDataToServer()
            TmpLayoutItemSaveDataToServer.PositionX = j.PositionX
            TmpLayoutItemSaveDataToServer.PositionY = j.PositionY
            TmpLayoutItemSaveDataToServer.Scale = j.Scale
            TmpLayoutItemSaveDataToServer.RenderOpacity = j.RenderOpacity
            TmpLayoutItemSaveDataToServer.IsBan = j.IsBan
            TmpLayoutItemSaveData.ItemSaveData = TmpLayoutItemSaveDataToServer
            TmpLayoutSaveData.LayoutSaveData:Add(TmpLayoutItemSaveData)
        end
        SettingSubsystem:SetMobileLayoutDataFromServer(k,TmpLayoutSaveData)

    end

end 

-------------------设置初始化的时候请求后台发送当前用户记录的数据-----------------------------
function SettingCtrl:SendSetting_Req(obj)
   
    --self.Context = obj
    self:SendProto(Pb_Message.GetSettingsReq,{},nil,true)

    --重新登录的时候要清理数据
    self.LocalPC =  UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self.LocalPC)
 ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = UserModel:GetPlayerId()
    SettingSubsystem:SetPlyaerId(PlayerId)
    print("SettingCtrl:SendSetting_Req",PlayerId)
end
   
--手机端的时候才需要请求
function SettingCtrl:SendCustomLayout_Req(obj)
    print("SettingCtrl:SendCustomLayout_Req")
    self:SendProto(Pb_Message.GetCustomLayoutReq,{},nil,true)
end


-----------------保存设置的时发送数据到后台---------------------------
function SettingCtrl:SendSetting_Func(InSettingDataTable,InDelSetting)
    print("SettingCtrl:SendSetting_Func",InSettingDataTable,InDelSetting)
    
    local ChangedSettings = {}
    for Key, Value in pairs(InSettingDataTable) do
        ChangedSettings[Key] = {
            Value_Int = Value.Value_Int,
            Value_Float = Value.Value_Float,
            -- = Value.Value_Bool,
            Value_IntArray = Value.Value_IntArray:ToTable()
        }
        -- for K, V in pairs(Value.Value_IntArray) do
        --     table.insert(ChangedSettings[Key].Value_IntArray, V)
        -- end
    end
    local DelSettings = InDelSetting:ToTable()
    -- for _, Value in pairs(InDelSetting) do
    --     table.insert(DelSettings, Value)
    -- end
    print_r(ChangedSettings, "SettingCtrl:SendSetting_Func InSettingDataTable")
    print_r(DelSettings, "SettingCtrl:SendSetting_Func InDelSetting")
    local Msg = 
    {
        ChangedSettings = ChangedSettings,
        DelSettings  = DelSettings
    }
    self:SendProto(Pb_Message.SaveSettingsReq,Msg,nil,true)
end

function SettingCtrl:SendCustomLayout_Func(InSaveLayoutData,InDelData)
    
    --每套布局数据
    local SaveCustomLayout = {}
    for k,v in pairs(InSaveLayoutData) do 
        local LayoutItemData ={}
        for i,j in pairs(v.LayoutSaveData) do 
            local LayoutBase = 
            {
                PositionX = j.ItemSaveData.PositionX,
                PositionY = j.ItemSaveData.PositionY,
                Scale = j.ItemSaveData.Scale,
                RenderOpacity = j.ItemSaveData.RenderOpacity,
                IsBan = j.ItemSaveData.IsBan,
             }
             LayoutItemData[j.ItemLayoutTagName] = LayoutBase
        end
        if v.LayoutSaveData:Num()>0 then
            local LayoutSaveData ={
                ChangedLayouts = LayoutItemData,
                LayoutGroupName = v.LayoutName
            }
            SaveCustomLayout[k] = LayoutSaveData
        end
       
    end
    local DelData = InDelData:ToTable()
    -- 

    -- for i = 0,3 do 
    --     local LayoutItemData ={}
    --     local Tmpdata = InSaveLayoutData:Find(i)
    --     for _,v in pairs(Tmpdata.LayoutSaveData) do 

    --         local LayoutBase =
    --          {
    --             PositionX = v.ItemSaveData.PositionX,
    --             PositionY = v.ItemSaveData.PositionY,
    --             Scale = v.ItemSaveData.Scale,
    --             RenderOpacity = v.ItemSaveData.RenderOpacity,
    --             IsBan = v.ItemSaveData.IsBan,
    --          }
             
    --          LayoutItemData[i.ItemLayoutTagName] = LayoutBase
    --     end
    --     --每套数据
    --     local Layotdata = {
    --         ChangedLayouts = LayoutItemData,
    --         --DeleteList = InDelData.i:ToTable()
    --     }
    --     SaveCustomLayout[i] = Layotdata
    -- end
     
    local Msg = 
    {
        SaveLayoutGroups = SaveCustomLayout,
        ResetGroupList = DelData
    }
    print_r(Msg,"SettingCtrl:SendCustomLayout_Func")
    self:SendProto(Pb_Message.SaveCustomLayoutReq,Msg,nil,true)
end

----------埋点相关----------------
function SettingCtrl:SendBurySettings_Func(InBurySettings)
    local time = GetTimestamp() 
    for k,v in pairs(InBurySettings) do
        local JsonValue = {
            ["setting_seq"] = time,
            ["setting_type"] = v.TabName,
            ["setting_item"] = k,
        }
        local settinglist = self:TransSettingtoList(v.OldValue)
        JsonValue["original_setting"] = settinglist
        settinglist = self:TransSettingtoList(v.NewValue)
        JsonValue["current_setting"] = settinglist
        local IsSave = 1
        if v.IsSave == false then
            IsSave = 0
        end
        JsonValue["is_save"]= IsSave
        print_r(JsonValue,"SettingCtrl:SendBurySettings_Func")
        UE.UBuryReportSubsystem.SendBuryByContext(GameInstance,nil,"preference_setting",CommonUtil.JsonSafeEncode(JsonValue))
    end
   
end

function SettingCtrl:TransSettingtoList(InSetting)
    local SettingTable ={}
    table.insert(SettingTable,InSetting.Value_Int)
    table.insert(SettingTable,InSetting.Value_Float)
    local value = 0
    for i=1,4 do
        value = InSetting.Value_IntArray:Find(i)
        if value == nil or  value<= 0 then
            value = -1
        end
        table.insert(SettingTable,value)
    end
    return SettingTable
end
------------处理外部进来的数据发后台的-------------

function SettingCtrl:SendSettingData() 
    self.LocalPC =  UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(GameInstance)
    local InServerData = SettingSubsystem:GetModifySettingData()
    local InDelData = SettingSubsystem:GetDelTagNameArray()
    local InBuryData = SettingSubsystem:GetBurySettingData()
    print("SettingCtrl:SendSettingData",InServerData,InDelData,InBuryData)
    self:SendSetting_Func(InServerData,InDelData)
    self:SendBurySettings_Func(InBuryData)

end
return SettingCtrl