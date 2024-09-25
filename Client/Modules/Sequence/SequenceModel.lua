--[[HallSequence数据模型]]
local super = GameEventDispatcher;
local class_name = "SequenceModel";
---@class SequenceModel : GameEventDispatcher
SequenceModel = BaseClass(super, class_name);

SequenceModel.BindTagEnum = {
    --[[
        摄相机Tag
    ]]
    CAMERA = "CameraTag",
    --[[
        角色动画
    ]]
    ACTOR_SKELETMESH_ANIM = "SkeletMeshAnimTag",
    --[[
        角色位移
    ]]
    ACTOR_TRANSFORM = "ActorTransformTag",
    --[[
        武器动画
    ]]
    WEAPON_SKELETMESH_ANIM = "WeaponMeshAnimTag",
    --[[
        角色Mesh组件（例如控制材质参数）
    ]]
    ACTOR_SKELETMESH_COMPONENT = "SkeletMeshComponentTag",
    --[[
        武器Mesh组件（例如控制材质参数）
    ]]
    WEAPON_SKELETMESH_COMPONENT = "WeaponMeshComponentTag",
    --[[
        需要在结束播放或停止播放进行销毁的对象
        此处属于补丁,LevelSequenceActor本身有生命周期管理, 目前为解决勾选了在[播完后暂停]选项之后不会对生成的对象进行销毁
        后续需要改动一下播放方式 TODO
    ]]
    DELETE_AFTER_END_TAG = "DeleteAfterEndTag",
    --[[
        需要下一个LS播放进行销毁的对象
    ]]
    DELETE_BEFORE_NEXT_TAG = "DeleteBeforeNextTag",
}

function SequenceModel:__init()
    self:DataInit()
end

function SequenceModel:DataInit()
    --[[
        SequenceActor列表
    ]]
    self.LSId2SequenceActor = {}
    self.LSTag2Id = {}
    --[[
        自增ID
    ]]
    self.IncrementLSId = 1
    --[[
        每个Tag对应的超时计时器Handler
    ]]
    self.TagTimerDelay = {}

    self.Tag2CustomCache = {}

    --[[
        当前控制摄相机的LSID
    ]]
    self.CameraControlLSId = 0

    --[[
        添加LSId2Tag2Bindings及ActorUID2BindingInfo逻辑

        保证Actor的每个Track同时只能由一个LS驱动 （否则容易引发问题）
    ]]
    --[[
        当前正在播放的LSTag对应的绑定信息
    ]]
    self.LSId2Tag2Bindings = {}
    --[[
        记录
        {
            [ActorUID] = {
                [BindTag] = LSID,
            }
        }
    ]]
    self.ActorUID2BindingInfo = {}

    self.ActorSequenceQueue = {}
end

function SequenceModel:AppendActorSequenceQueue(Actor, Tag, Param, CallBack)
    if not Actor then
        return
    end
    local Queue = self.ActorSequenceQueue[Actor] or {}
    local TData = {
        Tag = Tag,
        Param = Param,
        CallBack = CallBack
    }
    Queue[Tag] = TData
    self.ActorSequenceQueue[Actor] = Queue
end

function SequenceModel:GetActorSequenceQueue(Actor)
    if not Actor then
        return
    end
    return self.ActorSequenceQueue[Actor]
end

function SequenceModel:FinishActorSequenceQueue(Actor,Tag)
    if not Actor then
        return
    end
    if self.ActorSequenceQueue[Actor] then
        self.ActorSequenceQueue[Actor][Tag] = nil
    end
end

function SequenceModel:CleanActorSequenceQueue(Actor)
    if not Actor then
        return
    end
    self.ActorSequenceQueue[Actor] = nil
end

--[[
    获取创建LSActor时的自增ID
]]
function SequenceModel:GetAutoIncrementLSActorId()
	self.IncrementLSId = self.IncrementLSId + 1
	return self.IncrementLSId
end

function SequenceModel:CheckInTag(InTag)
    return InTag or "Normal"
end

function SequenceModel:GetLevelSequence(InLevelSequenceAssetPath)
    local SequenceAsset = UE.UGFUnluaHelper.ToSoftObjectPtr(InLevelSequenceAssetPath)
    local LevelSequence = SequenceAsset:Get()
    if not LevelSequence then
        LevelSequence = LoadObject(InLevelSequenceAssetPath)
    end
    return LevelSequence
end

--- 获取LS播放时长
---@param InLevelSequenceAssetPath string
function SequenceModel:GetLevelSequenceEndSeconds(InLevelSequenceAssetPath)
    local SequenceAsset = UE.UGFUnluaHelper.ToSoftObjectPtr(InLevelSequenceAssetPath)
    local LevelSequence = SequenceAsset:Get()
    if not LevelSequence then
        LevelSequence = LoadObject(InLevelSequenceAssetPath)
    end
    local StartTime = UE.UMovieSceneSequenceExtensions.GetPlaybackStartSeconds(LevelSequence)
    local EndTime = UE.UMovieSceneSequenceExtensions.GetPlaybackEndSeconds(LevelSequence)
    print("SequenceModel:GetLevelSequence:", StartTime, EndTime)
    return StartTime, EndTime
end

--[[
    获取当前可用的SequenceActor
    并赋予TagName方便查问题
    并设置好当前需要播放LS
]]
function SequenceModel:GetSequenceActorFromCache(InTag,InParams)
    InTag = self:CheckInTag(InTag)
    local TheSequenceActor = nil
    if InParams.UseCacheSequenceActorByTag then
        TheSequenceActor = self:GetCacheSequenceActorByTag(InTag)
    else
        for LSId,v in pairs(self.LSId2SequenceActor) do
            if not v.SequencePlayer:IsPlaying() then
                if InParams.CameraControl or LSId ~= self.CameraControlLSId then
                    TheSequenceActor = v
                    break
                end
            end
        end
    end
    if not TheSequenceActor then
        TheSequenceActor = self:CreateSequenceActor(InTag, InParams.UseCacheSequenceActorByTag)
        CWaring("SequenceModel:GetSequenceActorFromCache New Ins")
    else
        CWaring("SequenceModel:GetSequenceActorFromCache From Cache")
    end
    
    if not TheSequenceActor then
        CError("SequenceModel:GetSequenceActorFromCache TheSequenceActor is nil, InTag:"..InTag)
        return
    end

    self:StopSequenceByActor(TheSequenceActor)
    TheSequenceActor.TagName = InTag
    local LevelSequence =  self:GetLevelSequence(InParams.LevelSequenceAsset)
    TheSequenceActor:SetSequence(LevelSequence)

    if InParams.CameraControl then
        self.CameraControlLSId = TheSequenceActor.LSId
        CWaring("self.CameraControlLSId:" .. self.CameraControlLSId)
    end

    return TheSequenceActor
end
function SequenceModel:GetCacheSequenceActorByTag(InTag,InParams)
    InTag = self:CheckInTag(InTag)
    local LSId = self.LSTag2Id[InTag]
    return self:GetSequenceActorByLSId(LSId)
end

--动态在场景里生成SequencePlayer并赋值唯一ID
function SequenceModel:CreateSequenceActor(InTag, UseCacheSequenceActorByTag)
    local CurWorld = _G.GameInstance:GetWorld()
    if CurWorld == nil then
		CLog("Not Found CurWorld")
        return 
    end
	local LSActorClass = UE.UClass.Load("/Game/BluePrints/Hall/LS/BP_HallLSActor.BP_HallLSActor")
    if LSActorClass == nil then
		CError("Not Found LSActorClass")
        return
    end

	local SpawnLocation = UE.FVector(0, 0, 0)
    local SpawnRotation = UE.FRotator(0, 0, 0)
    local SpawnScale = UE.FVector(1, 1, 1)
    local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnLocation, SpawnRotation, SpawnScale)
    local LSActor = CurWorld:SpawnActor(LSActorClass, 
            SpawnTrans, 
            UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
	if LSActor == nil then 
		CError("Create LSActor Failed")
		return
	end
    local LSId = self:GetAutoIncrementLSActorId()
    LSActor.LSId = LSId
    self.LSId2SequenceActor[LSId] = LSActor
    self.LSTag2Id[InTag] = LSId
    return LSActor
end

--[[
    通过唯一ID获取对应的SequenceActor
]]
function SequenceModel:GetSequenceActorByLSId(LSId)
    if not LSId then
        return nil
    end
    return self.LSId2SequenceActor[LSId]
end

--[[
    通过TagName获取对应的SequenceActor
]]
function SequenceModel:GetSequenceActorByTag(InTag)
    InTag = self:CheckInTag(InTag)
    local TheSequenceActor = nil
    for _,v in pairs(self.LSId2SequenceActor) do
        if v.TagName == InTag then
            TheSequenceActor = v
            break
        end
    end
    return TheSequenceActor
end

function SequenceModel:GetSequencePlayerByTag(InTag)
    InTag = self:CheckInTag(InTag)
    local Actor =  self:GetSequenceActorByTag(InTag)
    if not Actor then
        return nil
    end
    local SequencePlayer = Actor:GetSequencePlayer()
    return SequencePlayer
end

function SequenceModel:StopAllSequences(StopAllFilterTags,CheckForceCallback)
    local StopAllFilterTagsMap = {}
    if StopAllFilterTags and #StopAllFilterTags > 0 then
        for k,v in ipairs(StopAllFilterTags) do
            StopAllFilterTagsMap[v] = 1
        end
    end
    for LSId,TheActor in pairs(self.LSId2SequenceActor) do
        local CanStop = true
        if string.len(TheActor.TagName) > 0 and StopAllFilterTagsMap[TheActor.TagName] then
            CanStop = false
            CWaring(StringUtil.Format("SequenceModel:StopAllSequences Filter:TagName {0} LSId {1}",TheActor.TagName,LSId))
        end
        if CanStop then
            self:StopSequenceByLSId(LSId,TheActor,CheckForceCallback)
        end
    end
end

function SequenceModel:StopSequenceByLSId(LSId,Actor,CheckForceCallback)
    if not Actor and LSId then
        Actor = self:GetSequenceActorByLSId(LSId)
    end
    if Actor and Actor:IsValid() then
        self:StopSequenceByActor(Actor,nil,CheckForceCallback)
    end
end

function SequenceModel:StopSequenceByTag(InTag,Actor,CheckForceCallback)
    if not Actor and InTag then
        Actor = self:GetSequenceActorByTag(InTag)
    end
    if Actor and Actor:IsValid() then
        CWaring("StopSequenceByTag:" .. InTag)
        self:StopSequenceByActor(Actor,InTag,CheckForceCallback)
    end
end

function SequenceModel:StopSequenceByActor(Actor,InTag,CheckForceCallback)
    -- if string.len(Actor.TagName) > 0 then
    --     CWaring(StringUtil.Format("SequenceModel:StopSequenceByActor TagName:{0} LSId:{1}",Actor.TagName,Actor.LSId))
    -- end
    if not CommonUtil.IsValid(Actor) then
        CError("SequenceModel:StopSequenceByActor Actor Is not Valid InTag:" .. (InTag and InTag or ""), true)
        return
    end
    CWaring("StopSequenceByLSId:" .. Actor.LSId)
    if InTag or string.len(Actor.TagName) > 0 then
        if not InTag then
            InTag = Actor.TagName
        end
        if CheckForceCallback then
            self:CheckForceCallBack(InTag)
        end
        self:CleanCacheByTag(InTag);
    end
    self:SetLSId2Tag2Bindings(Actor.LSId,nil)
    local SequencePlayer = Actor:GetSequencePlayer()
    if SequencePlayer and CommonUtil.IsValid(SequencePlayer) then
        SequencePlayer:Stop()
        UE.UGFUnluaHelper.ResetDirectorInstancesBySequencePlayer(SequencePlayer)
    end
    Actor:ResetBindings()
    Actor.TagName = ""
    if Actor.LSId == self.CameraControlLSId then
        self.CameraControlLSId = 0
    end
end

function SequenceModel:CheckForceCallBack(InTag)
    local CustomCache = self.Tag2CustomCache[InTag]
    if not CustomCache then
        return
    end
    if CustomCache.ForceCallback and CustomCache.ForceFinishCallBackFunc then
        CWaring("SequenceModel:CheckForceCallBack:" .. InTag)
        CustomCache.ForceFinishCallBackFunc()
    end
end

function SequenceModel:CleanSequencesCache()
    self:DataInit()
end

function SequenceModel:CleanCacheByTag(InTag)
    local TimerDelay = self.TagTimerDelay[InTag]
    if TimerDelay then
        TimerDelegate.RemoveTimer(TimerDelay)
    end
    self.TagTimerDelay[InTag] = nil
    self.Tag2CustomCache[InTag] = nil
end

function SequenceModel:ClearAllCache()
    for k,v in pairs(self.TagTimerDelay) do
        self:CleanCacheByTag(k)
    end
    self.Tag2CustomCache = {}
    self.ActorSequenceQueue = {}
end

function SequenceModel:AddCustomCacheByTag(InTag,InParams)
    self.Tag2CustomCache[InTag] = InParams
end

--[[
    增加计时器
]]
function SequenceModel:AddTimerDelay(InTag,TimeOut,CallBack)
    self:CleanCacheByTag(InTag)
    self.TagTimerDelay[InTag] = TimerDelegate.InsertTimer(TimeOut,CallBack)
end

function SequenceModel:CleanSequenceActorByLSId(LSId)
    local TheSequenceActor = self:GetSequenceActorByLSId(LSId)
    if TheSequenceActor then
        self:CleanCacheByTag(TheSequenceActor.TagName)
    end
    self.LSId2SequenceActor[LSId] = nil
end

function SequenceModel:GetCameraControlLSId()
    return self.CameraControlLSId
end

--[[
    缓存/清除 当前运行LS的的 绑定情况

    Tag2Bindings 有值为缓存行为    空值为清除行为
]]
function SequenceModel:SetLSId2Tag2Bindings(LSId,Tag2Bindings)
    if Tag2Bindings then
        if self.LSId2Tag2Bindings[LSId] then
            CError("SequenceModel:SetLSId2Tag2Bindings  LSTag2Tag2Bindings Already Exist,Please Stop First:" .. LSId,true)
            return
        end
        self.LSId2Tag2Bindings[LSId] = Tag2Bindings
        for BindingTag,BindActors in pairs(Tag2Bindings) do
            for k,BindActor in ipairs(BindActors) do
                local TheBindActorUniqueId = UE.UGFUnluaHelper.GetObjectUniqueID(BindActor)
                if TheBindActorUniqueId <= 0 then
                    CError("SequenceModel:SetLSId2Tag2Bindings TheBindActorUniqueId <= 0,Please Check",true)
                    return
                else
                    if not self:IsActorCanBindingByBindingTag(BindActor,BindingTag) then
                        return
                    end
                    self.ActorUID2BindingInfo[TheBindActorUniqueId] = self.ActorUID2BindingInfo[TheBindActorUniqueId] or {}
                    self.ActorUID2BindingInfo[TheBindActorUniqueId][BindingTag] = LSId
                    -- CWaring(StringUtil.Format("SequenceModel:SetLSId2Tag2Bindings Set BindingTag {0} LSId {1} UId {2}",BindingTag,LSId,TheBindActorUniqueId))
                end
            end
        end
    else
        if not self.LSId2Tag2Bindings[LSId] then
            -- CWaring("SequenceModel:SetLSId2Tag2Bindings self.LSId2Tag2Bindings not exist,So return:" .. LSId,true)
            return
        end
        local Tag2Bindings = self.LSId2Tag2Bindings[LSId]
        for BindingTag,BindActors in pairs(Tag2Bindings) do
            for k,BindActor in ipairs(BindActors) do
                if CommonUtil.IsValid(BindActor) then
                    local TheBindActorUniqueId = UE.UGFUnluaHelper.GetObjectUniqueID(BindActor)
                    -- CWaring(StringUtil.Format("SequenceModel:SetLSId2Tag2Bindings Clear BindingTag {0} LSId {1}",BindingTag,LSId))
                    self.ActorUID2BindingInfo[TheBindActorUniqueId][BindingTag] = nil
                end
            end
        end
        CWaring("SequenceModel:SetLSId2Tag2Bindings self.LSId2Tag2Bindings remove " .. LSId)
        self.LSId2Tag2Bindings[LSId] = nil
    end
end

--[[
    判断Actor对应的Track是否还存在绑定
    如果存在，就不能再被绑定

    AssumeControl  为true 表示会接管控制，会触发removeBinding
]]
function SequenceModel:IsActorCanBindingByBindingTag(BindActor,BindingTag,AssumeControl)
    local TheBindActorUniqueId = UE.UGFUnluaHelper.GetObjectUniqueID(BindActor)
    if TheBindActorUniqueId <= 0 then
        CError("SequenceModel:IsActorCanBindingByTag TheBindActorUniqueId <= 0,Please Check",true)
        return false
    end
    if self.ActorUID2BindingInfo[TheBindActorUniqueId] and self.ActorUID2BindingInfo[TheBindActorUniqueId][BindingTag] then
        if AssumeControl then
            local LSId = self.ActorUID2BindingInfo[TheBindActorUniqueId][BindingTag]
            CWaring(StringUtil.Format("SequenceModel:IsActorCanBindingByBindingTag AssumeControl Actor:{0} BindingTag:{1} LSId:{2}",TheBindActorUniqueId,BindingTag,LSId))
            self:RemoveBindingByLSId(LSId,BindingTag,BindActor)
            return true
        else
            CError(StringUtil.Format("SequenceModel:SetLSId2Tag2Bindings The Actor {0} with BindingTag {1} Already Binding By LSId {2},Please Stop First!",TheBindActorUniqueId,BindingTag,self.ActorUID2BindingInfo[TheBindActorUniqueId][BindingTag]),true)
            return false
        end
    end
    return true
end

function SequenceModel:RemoveBindingByLSId(LSId,InBindingTag,InBindingActor,Actor)
    if not Actor and LSId then
        Actor = self:GetSequenceActorByLSId(LSId)
    end
    if Actor and Actor:IsValid() then
        self:RemoveBindingByActor(Actor,InBindingTag,InBindingActor)
    end
end

function SequenceModel:RemoveBindingByActor(Actor,InBindingTag,InBindingActor)
    if not Actor then
        return
    end
    Actor:RemoveBindingByTag(InBindingTag, InBindingActor)

    local BindActorUniqueId = UE.UGFUnluaHelper.GetObjectUniqueID(InBindingActor)
    self.ActorUID2BindingInfo[BindActorUniqueId][InBindingTag] = nil
    local Tag2Bindings = self.LSId2Tag2Bindings[Actor.LSId]
    if Tag2Bindings and Tag2Bindings[InBindingTag] then
        local BindActors = Tag2Bindings[InBindingTag]
        local BindActorsNew = {}
        for k,BindActor in ipairs(BindActors) do
            if CommonUtil.IsValid(BindActor) then
                local TheBindActorUniqueId = UE.UGFUnluaHelper.GetObjectUniqueID(BindActor)
                if TheBindActorUniqueId ~= BindActorUniqueId then
                    table.insert(BindActorsNew,BindActor)
                end
            end
        end
        Tag2Bindings[InBindingTag] = BindActorsNew
    end
end


return SequenceModel