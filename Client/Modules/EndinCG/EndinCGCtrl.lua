require("Client.Modules.EndinCG.EndinCGDefine")
require("Client.Modules.EndinCG.EndinCGModel")

--[[
    端内CG
]]
local class_name = "EndinCGCtrl"
---@class EndinCGCtrl : UserGameController
EndinCGCtrl = EndinCGCtrl or BaseClass(UserGameController, class_name)

--- UserGameController:OnLogin(data)            --用户登入，用于初始化数据,当玩家帐号信息同步完成，会触发
--- UserGameController:OnLogout(data)           --用户登出，用于清除旧用户的数据相关  data有值表示为断线重连
--- UserGameController:OnPreEnterBattle()          --用户从大厅进入战斗处理的逻辑（即将进入，还未进入）
--- UserGameController:OnPreBackToHall()           --用户从战斗返回大厅处理的逻辑（即将进入，还未进入）
--- UserGameController:AddMsgListenersUser()    --填写需要监听的事件


function EndinCGCtrl:__init()

end

function EndinCGCtrl:Initialize()
end

---用户登入，用于初始化数据,当玩家帐号信息同步完成，会触发
function EndinCGCtrl:OnLogin(data)
end

---用户登出，用于清除旧用户的数据相关  data有值表示为断线重连
function EndinCGCtrl:OnLogout(data)
end

---用户从大厅进入战斗处理的逻辑（即将进入，还未进入）
function EndinCGCtrl:OnPreEnterBattle()
end

---用户从战斗返回大厅处理的逻辑（即将进入，还未进入）
function EndinCGCtrl:OnPreBackToHall()
end

---填写需要监听的事件
function EndinCGCtrl:AddMsgListenersUser()
	-- self.MsgList = {}
end

-------------------------------------------------------------------------------PlayCG >>

---@class CGFinishedParam
---@field EndMode ECGEndMode CG结束方式 

---@class CGPlayParam CG播放参数
---@field ModuleId number ECGSettingConfig.EnterHall.ModuleId.模块ID
---@field OnCGFinished fun(Param:CGFinishedParam):void 播放完成回调

---@param Params CGPlayParam
function EndinCGCtrl:TryPlayCG(Params)
    Params = Params or {}

    CWaring(string.format("EndinCGCtrl:TryPlayCG, ModuleId = %s !!", tostring(Params.ModuleId)))

    local ModuleId = Params.ModuleId or 0
    local CGCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_CGSettingConfig, Cfg_CGSettingConfig_P.ModuleId, ModuleId)
    
    if CGCfg and string.len(CGCfg[Cfg_CGSettingConfig_P.CGMovie]) > 0 then
        local bNeedSkip = MvcEntry:GetModel(EndinCGModel):GetCGIsNeedSkip(ModuleId)
        if bNeedSkip then
            CWaring(string.format("EndinCGCtrl:TryPlayCG, bNeedSkip == true !!"))
            --跳过播放
            if Params.OnCGFinished then
                local EndParam = { EndMode = EndinCGDefine.ECGEndMode.Skipped }
                Params:OnCGFinished(EndParam)
            end
        else
            CWaring(string.format("EndinCGCtrl:TryPlayCG, MvcEntry:OpenView !!"))
            --打开CG播放页面
            MvcEntry:OpenView(ViewConst.EndinCG, Params)
        end
    else
        CError(string.format("EndinCGCtrl:TryPlayCG, CGCfg == nil or CGMovie =  !!"))
        if Params.OnCGFinished then
            local EndParam = { EndMode = EndinCGDefine.ECGEndMode.ErrorExit }
            Params:OnCGFinished(EndParam)
        end
    end
end

-- function EndinCGCtrl:TestShowCG()
--     local CGParam = 
--     {
--         ModuleId = ECGSettingConfig.EnterHall.ModuleId, 
--         OnCGFinished = function(_, Params)
--             CError("EndinCGMdt:TestShowCG SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS Params = "..table.tostring(Params))
--         end
--     }
--     MvcEntry:GetCtrl(EndinCGCtrl):TryPlayCG(CGParam)
-- end

-------------------------------------------------------------------------------PlayCG <<


function EndinCGCtrl:SetMediaSound(MediaPlayer)
    local MediaAudioActor = self:GetMediaSoundActor()
    if CommonUtil.IsValid(MediaAudioActor) then
        local Name = GetObjectName(MediaAudioActor:GetMediaPlayer())
        CWaring("EndinCGCtrl:SetMediaSound, ObjectName = "..tostring(Name))
        MediaAudioActor:SetMediaPlayer(MediaPlayer)
        Name = GetObjectName(MediaAudioActor:GetMediaPlayer())
        CWaring("EndinCGCtrl:SetMediaSound, ObjectName = "..tostring(Name))
    end
end

function EndinCGCtrl:GetMediaSoundActor()
    if not(CommonUtil.IsValid(self.MediaSoundActor)) then
        local CurWorld = _G.GameInstance:GetWorld()
        if CurWorld == nil then
            CWaring("EndinCGCtrl:GetMediaSoundActor, Not Found CurWorld")
            return 
        end
        local MediaSoundActorClass = UE.UClass.Load("/Game/BluePrints/Hall/MediaSound/BP_MediaSound.BP_MediaSound")
        if MediaSoundActorClass == nil then
            CError("EndinCGCtrl:GetMediaSoundActor, Not Found BP_MediaSound Class !!!", true)
            return
        end
    
        local SpawnLocation = UE.FVector(0, 0, 0)
        local SpawnRotation = UE.FRotator(0, 0, 0)
        local SpawnScale = UE.FVector(1, 1, 1)
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnLocation, SpawnRotation, SpawnScale)
        self.MediaSoundActor = CurWorld:SpawnActor(MediaSoundActorClass, SpawnTrans, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
        if not(CommonUtil.IsValid(self.MediaSoundActor)) then 
            CError("EndinCGCtrl:GetMediaSoundActor, Create MediaSoundActor Failed !!!", true)
            return
        end
    end

    return self.MediaSoundActor
end


