require("Client.Modules.Arsenal.ArsenalModel")
--[[
    武器协议处理模块
]]
local class_name = "ArsenalCtrl"
---@class ArsenalCtrl : UserGameController
---@field private model HeroModel
ArsenalCtrl = ArsenalCtrl or BaseClass(UserGameController,class_name)


function ArsenalCtrl:__init()
    CWaring("==ArsenalCtrl init")
    self.TheVehicleModel = self:GetModel(VehicleModel)
    self.TheWeaponModel =  self:GetModel(WeaponModel)
end

function ArsenalCtrl:Initialize()

end

function ArsenalCtrl:AddMsgListenersUser()
    self.ProtoList = {
		{MsgName = Pb_Message.SelectWeaponRsp,	Func = self.SelectWeaponRsp_Func },
        {MsgName = Pb_Message.BuyWeaponSkinRsp,	Func = self.BuyWeaponSkinRsp_Func },
        {MsgName = Pb_Message.SelectWeaponSkinRsp,	Func = self.SelectWeaponSkinRsp_Func },
        {MsgName = Pb_Message.BuyWeaponPartSkinRsp,	Func = self.BuyWeaponPartSkinRsp_Func },
        {MsgName = Pb_Message.SelectVehicleRsp,	Func = self.SelectVehicleRsp_Func },
        {MsgName = Pb_Message.BuyVehicleSkinRsp,	Func = self.BuyVehicleSkinRsp_Func },
        {MsgName = Pb_Message.SelectVehicleSkinRsp,	Func = self.SelectVehicleSkinRsp_Func },
        {MsgName = Pb_Message.BuyVehicleStickerRsp,	Func = self.BuyVehicleStickerRsp_Func },
        {MsgName = Pb_Message.UpdateVehicleStickerDataRsp,	Func = self.UpdateVehicleStickerDataRsp_Func },
        {MsgName = Pb_Message.RandomVehicleLicensePlateRsp,	Func = self.RandomVehicleLicensePlateRsp_Func },
        {MsgName = Pb_Message.VehicleSelectLicensePlateRsp,	Func = self.VehicleSelectLicensePlateRsp_Func },
        {MsgName = Pb_Message.VehicleDefaultLicenseSync,	Func = self.VehicleDefaultLicenseSync_Func },
        {MsgName = Pb_Message.UnequipStickerFromVehicleSkinRsp,	Func = self.UnequipStickerFromVehicleSkinRsp_Func },
	}
end

function ArsenalCtrl:OnLogin(data)
    CWaring("ArsenalCtrl OnLogin")
end


--[[
    // 选择使用的武器应答
    message SelectWeaponRsp
    {
        int64 WeaponId = 1;         // 选择的武器物品Id
    }
]]
function ArsenalCtrl:SelectWeaponRsp_Func(Msg)
    self.TheWeaponModel:SetSelectWeaponId(Msg.WeaponId)
end

--[[
    // 购买武器皮肤返回
    message BuyWeaponSkinRsp
    {
        int64 WeaponId = 1;         // 购买哪个武器的皮肤
        int64 WeaponSkinId = 2;     // 购买武器的哪个皮肤
    }
]]
function ArsenalCtrl:BuyWeaponSkinRsp_Func(Msg)
    self.TheWeaponModel:DispatchType(WeaponModel.ON_UNLOCK_WEAPON_SKIN)
end

--[[
    // 选择武器的皮肤返回: 装备皮肤
    message SelectWeaponSkinRsp
    {
        int64 WeaponId = 1;         // 武器的物品Id
        int64 WeaponSkinId = 2;     // 选择武器的哪个皮肤
    }
]]
function ArsenalCtrl:SelectWeaponSkinRsp_Func(Msg)
    self.TheWeaponModel:UpdateWeaponId2SkinId(Msg.WeaponId, Msg.WeaponSkinId)
end


--[[
    // 选择使用的载具应答
    message SelectVehicleRsp
    {
        int64 VehicleId = 1;        // 选择的载具Id
    }
]]
function ArsenalCtrl:SelectVehicleRsp_Func(Msg)
    self.TheVehicleModel:SetSelectVehicleId(Msg.VehicleId)
end

--[[
    // 购买载具皮肤返回
    message BuyVehicleSkinRsp
    {
        int64 VehicleId = 1;         // 购买哪个载具的皮肤
        int64 VehicleSkinId = 2;     // 购买载具的哪个皮肤  
    }
]]
function ArsenalCtrl:BuyVehicleSkinRsp_Func(Msg)
    self.TheVehicleModel:DispatchType(VehicleModel.ON_UNLOCK_VEHICLE_SKIN)
end


--[[
    // 选择载具的皮肤返回
    message SelectVehicleSkinRsp
    {
        int64 VehicleId = 1;        // 载具的物品Id
        int64 VehicleSkinId = 2;    // 选择载具的哪个皮肤
    }
]]
function ArsenalCtrl:SelectVehicleSkinRsp_Func(Msg)
    self.TheVehicleModel:UpdateVehicleId2SkinId(Msg.VehicleId, Msg.VehicleSkinId)
end


--[[
    // 解锁成功的贴纸Id
    message BuyVehicleStickerRsp
    {
        repeated int64 StickerIdList = 1;   
    }
]]
function ArsenalCtrl:BuyVehicleStickerRsp_Func(Msg)
    self.TheVehicleModel:DispatchType(VehicleModel.ON_BUY_VEHICLE_SKIN_STICKER_LIST, {StickerInfoList = Msg.StickerInfoList, BuyFrom = Msg.BuyFrom})
end

--[[
    message StickerDataNode
    {
        int64 StickerId = 1;                // 载具贴纸Id
        string CustomData = 2;              // 自定义数据
    }

    message UpdateVehicleStickerDataRsp
    {
        int64 VehicleSkinId = 1;            // 载具皮肤Id
        repeated StickerDataNode StickerDataList = 2;   // 载具皮肤装备的贴纸数据
    }
]]
function ArsenalCtrl:UpdateVehicleStickerDataRsp_Func(Msg)
    local StickerList = {}
    for i=1, #Msg.StickerDataList do
        local StickerData = Msg.StickerDataList[i]
        local T = JSON:decode(StickerData.CustomData)
        table.insert(StickerList, 
        { 
            StickerId = StickerData.StickerId,
            Scale = T.Scale,
            Rotator = T.Rotator,
            Position = T.Position,
            RotateAngle = T.RotateAngle,
            ScaleLength = T.ScaleLength,
            Restore = T.Restore,
            Slot = T.Slot 
        })
    end
    self.TheVehicleModel:UpdateVehicleSkinId2StickerList(Msg.VehicleSkinId, StickerList)
    self.TheVehicleModel:DispatchType(VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER_LIST, 
    {
        VehicleSkinId = Msg.VehicleSkinId,
        UpdateReason = Msg.UpdateReason
    })
end

--[[
    // 从某些载具皮肤上卸载贴纸
    message UnequipStickerFromVehicleSkinRsp
    {
        int64 StickerId = 1;                // 卸载的贴纸Id
        repeated int64 SkinIdList = 2;      // 从哪些载具皮肤上卸载
    }
]]
function ArsenalCtrl:UnequipStickerFromVehicleSkinRsp_Func(Msg)

end


--[[
    // 载具摇号
    message RandomVehicleLicensePlateRsp
    {
        int64 VehicleId = 1;                            // 要摇号的载具Id
        repeated string LicensePlateList = 2;           // 摇号可选载具车牌号
    }
]]
function ArsenalCtrl:RandomVehicleLicensePlateRsp_Func(Msg)
    self.TheVehicleModel:UpdateVehicleId2PlateLotteryCount(Msg.VehicleId, Msg.LotteryCount)
    self.TheVehicleModel:DispatchType(VehicleModel.ON_LICENSEPLATE_LOTTERY_RESULT, Msg.LicensePlateList)
end

--[[
    //载具选择车牌号
    message VehicleSelectLicensePlateRsp
    {
        int64 VehicleId = 1;                            // 载具Id
        string LicensePlate = 2;                        // 载具车牌号
    }
]]
function ArsenalCtrl:VehicleSelectLicensePlateRsp_Func(Msg)
    self.TheVehicleModel:UpdateVehicleId2LicensePlate(Msg.VehicleId, Msg.LicensePlate)
    self.TheVehicleModel:DispatchType(VehicleModel.ON_LICENSEPLATE_SELECT, Msg.LicensePlate)
end


--[[
    // 获得载具物品时，主动推送载具生成的默认车牌号
    message VehicleDefaultLicenseSync
    {
        int64 VehicleId = 1;                            // 载具Id
        string LicensePlate = 2;                        // 载具车牌号
    }
]]
function ArsenalCtrl:VehicleDefaultLicenseSync_Func(Msg)
    self.TheVehicleModel:UpdateVehicleId2LicensePlate(Msg.VehicleId, Msg.LicensePlate)
end

-----------------------------------------请求相关------------------------------
--[[
    选择武器：设为展示
]]
function ArsenalCtrl:SendProto_SelectWeaponReq(WeaponId)
    local Msg = {
        WeaponId = WeaponId,
    }
    self:SendProto(Pb_Message.SelectWeaponReq, Msg)
end

--[[
    购买武器皮肤
]]
function ArsenalCtrl:SendProto_BuyWeaponSkinReq(WeaponId, WeaponSkinId)
    local Msg = {
        WeaponId = WeaponId,
        WeaponSkinId = WeaponSkinId,
    }
    self:SendProto(Pb_Message.BuyWeaponSkinReq, Msg)
end

--[[
    选择武器皮肤: 装备皮肤
]]
function ArsenalCtrl:SendProto_SelectWeaponSkinReq(WeaponId, WeaponSkinId)
    local Msg = {
        WeaponId = WeaponId,
        WeaponSkinId = WeaponSkinId,
    }
    self:SendProto(Pb_Message.SelectWeaponSkinReq, Msg)
end


--[[
    武器配件：购买武器配件皮肤
]]
function ArsenalCtrl:SendProto_BuyWeaponPartSkinReq(WeaponSkinId, WeaponPartSkinId)
    local Msg = {
        WeaponSkinId = WeaponSkinId,
        WeaponPartSkinId = WeaponPartSkinId
    }
    self:SendProto(Pb_Message.BuyWeaponPartSkinReq, Msg)
end

--[[
    武器配件：购买武器配件皮肤返回
]]
function ArsenalCtrl:BuyWeaponPartSkinRsp_Func(Msg)
    self.TheVehicleModel:BuyWeaponPartSkin(Msg.WeaponSkinId, Msg.WeaponPartSkinId)
end


--[[
    选择载具：设为展示
]]
function ArsenalCtrl:SendProto_SelectVehicleReq(VehicleId)
    local Msg = {
        VehicleId = VehicleId,
    }
    self:SendProto(Pb_Message.SelectVehicleReq, Msg)
end

--[[
    购买载具皮肤
]]
function ArsenalCtrl:SendProto_BuyVehicleSkinReq(VehicleId, VehicleSkinId)
    local Msg = {
        VehicleId = VehicleId,
        VehicleSkinId = VehicleSkinId,
    }
    self:SendProto(Pb_Message.BuyVehicleSkinReq, Msg)
end


--[[
    选择载具的皮肤
]]
function ArsenalCtrl:SendProto_SelectVehicleSkinReq(VehicleId, VehicleSkinId)
    local Msg = {
        VehicleId = VehicleId,
        VehicleSkinId = VehicleSkinId,
    }
    self:SendProto(Pb_Message.SelectVehicleSkinReq, Msg)
end


--[[
    解锁载具贴纸
]]
function ArsenalCtrl:SendProto_BuyVehicleStickerReq(StickerInfoList, BuyFrom)
    local Msg = {
        StickerInfoList = StickerInfoList,
        BuyFrom = BuyFrom
    }
    self:SendProto(Pb_Message.BuyVehicleStickerReq, Msg)
end

--装配贴纸
function ArsenalCtrl:SendProto_AddVehicleSkinSticker(VehicleSkinId, AddStickerInfo, Reason)
    local StickerList = self.TheVehicleModel:GetVehicleSkinId2StickerList(VehicleSkinId) or {}
    table.insert(StickerList, {
        StickerId = AddStickerInfo.StickerId,
        Position = AddStickerInfo.Position,
        Scale = AddStickerInfo.Scale,
        Rotator = AddStickerInfo.Rotator,
        RotateAngle = AddStickerInfo.RotateAngle,
        ScaleLength = AddStickerInfo.ScaleLength,
        Restore = AddStickerInfo.Restore,
        Slot = self.TheVehicleModel:GetVehilceSkinEmptyStickerSlot(VehicleSkinId)
    })     
    self:SendProto_UpdateVehicleStickerDataReq(VehicleSkinId, StickerList, Reason)
end

--删除贴纸
function ArsenalCtrl:SendProto_RemoveVehicleSkinSticker(VehicleSkinId, StickerId, Slot, Reason)
    local StickerList = self.TheVehicleModel:GetVehicleSkinId2StickerList(VehicleSkinId) or {}
    for Index, V in ipairs(StickerList) do
        if V.StickerId == StickerId and V.Slot == Slot then
            CLog("Remove Slot = "..V.Slot)
            table.remove(StickerList, Index)
            break
        end
    end
    self:SendProto_UpdateVehicleStickerDataReq(VehicleSkinId, StickerList, Reason)
end

--更新贴纸
function ArsenalCtrl:SendProto_UpdateVehicleSkinSticker(VehicleSkinId, StickeInfo, Reason)
    local StickerList = self.TheVehicleModel:GetVehicleSkinId2StickerList(VehicleSkinId) or {}
    for Index, V in ipairs(StickerList) do
        if StickerList[Index].Slot == StickeInfo.Slot then
            StickerList[Index].StickerId = StickeInfo.StickerId
            StickerList[Index].Position = StickeInfo.Position
            StickerList[Index].Rotator = StickeInfo.Rotator
            StickerList[Index].Scale = StickeInfo.Scale
            StickerList[Index].RotateAngle = StickeInfo.RotateAngle
            StickerList[Index].ScaleLength = StickeInfo.ScaleLength
            StickerList[Index].Restore = StickeInfo.Restore
            StickerList[Index].Slot = StickeInfo.Slot
            break
        end
    end
    self:SendProto_UpdateVehicleStickerDataReq(VehicleSkinId, StickerList, Reason)
end


--退出贴纸编辑：1）是否保存更新 2)重置贴纸槽位
-- StickerEditInfo 退出时编辑信息
function ArsenalCtrl:SendProto_ExitVehicleSkinSticker(VehicleSkinId, StickerEditInfo, Reason)
    local StickerList = self.TheVehicleModel:GetVehicleSkinId2StickerList(VehicleSkinId) or {}
    --1) 更新
    if StickerEditInfo then
        for Index, V in ipairs(StickerList) do
            if StickerList[Index].Slot == StickerEditInfo.Slot and StickerList[Index].StickerId == StickerEditInfo.StickerId then
                StickerList[Index].StickerId = StickerEditInfo.StickerId
                StickerList[Index].Position = StickerEditInfo.Position
                StickerList[Index].Rotator = StickerEditInfo.Rotator
                StickerList[Index].Scale = StickerEditInfo.Scale
                StickerList[Index].RotateAngle = StickerEditInfo.RotateAngle
                StickerList[Index].ScaleLength = StickerEditInfo.ScaleLength
                StickerList[Index].Restore = StickerEditInfo.Restore
                break
            end
        end
    end
   
    --稀有度高＞贴纸ID大
    table.sort(StickerList, function(Sticker1, Sticker2)
		local QualityA = self.TheVehicleModel:GetVehicleSkinStickerQuality(Sticker1.StickerId)
			local QualityB = self.TheVehicleModel:GetVehicleSkinStickerQuality(Sticker2.StickerId)
			if QualityA ~= QualityB then 
				return QualityA > QualityB
			end
		return Sticker1.StickerId > Sticker2.StickerId
	end)

    --重置槽位
    for Index, V in ipairs(StickerList) do
        StickerList[Index].Slot = Index
    end
    self:SendProto_UpdateVehicleStickerDataReq(VehicleSkinId, StickerList, Reason)
end




--[[
    更新某个载具皮肤的贴纸数据
]]
function ArsenalCtrl:SendProto_UpdateVehicleStickerDataReq(VehicleSkinId, StickerList, UpdateReason)
    local StickerDataList = {}
    for _, V in pairs(StickerList) do
        if V.StickerId ~= 0 then
            table.insert(StickerDataList, {
                StickerId = V.StickerId,
                CustomData = JSON:encode(V)
            })
        end
    end
    local Msg = {
        VehicleSkinId = VehicleSkinId,
        StickerDataList = StickerDataList,
        UpdateReason = UpdateReason
    }
    self:SendProto(Pb_Message.UpdateVehicleStickerDataReq, Msg)
end

--[[
    从某些载具皮肤上卸载贴纸
]]
function ArsenalCtrl:SendProto_UnequipStickerFromVehicleSkinReq(StickerId, VehicleSkinIdList)
    local Msg = {
        StickerId = StickerId,
        VehicleSkinIdList = VehicleSkinIdList
    }
    self:SendProto(Pb_Message.UnequipStickerFromVehicleSkinReq, Msg)
end


--[[
    载具摇号
]]
function ArsenalCtrl:SendProto_RandomVehicleLicensePlateReq(VehicleId)
    local Msg = {
        VehicleId = VehicleId,
    }
    self:SendProto(Pb_Message.RandomVehicleLicensePlateReq, Msg)
end

--[[
    载具选择车牌号
]]
function ArsenalCtrl:SendProto_VehicleSelectLicensePlateReq(VehicleId, LicensePlate)
    local Msg = {
        VehicleId = VehicleId,
        LicensePlate = LicensePlate
    }
    self:SendProto(Pb_Message.VehicleSelectLicensePlateReq, Msg)
end

