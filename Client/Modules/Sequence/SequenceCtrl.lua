
require("Client.Modules.Sequence.SequenceModel")
--[[
    LevelSequence播放处理模块

    ForExample:
    local InParams = {
        PlayRate = 0.1,--播放速率,负值等于反向播放
        IsPlayReverse = false, --是否反向播放
        IsDisableCameraCuts = false, --是否禁用摄像机裁剪
        NeedStopAllSequence = false, --是否需要先停止所有已播放的动画(主要是有些动画停留在最后一帧),也可播放动画前手动直接调用StopSequence停止前置某个动画
        StopAllSequenceCheckForceCallback  --是否需要检查强制回调并执行  默认为True(作为NeedStopAllSequence时的一个可选项)
        StopAllFilterTags = {},      --作为NeedStopAllSequence时的一个可选项，用于过滤，当在这个列表中时，不会执行Stop操作
        NeedStopAfterFinish = false, --是否需要在LS播完之后，立即触发Stop,触发RestoreState，避免被持续控制
        LevelSequenceAsset = "", --选择需要绑定的序列资源路径(动态加载ls需要)
        -- PauseEnd = true, -- 默认为真 是否播放完毕停留在最后一帧    【暂时不可用】
        -- RestoreState = true, -- 默认为真 播放前是否恢复播放器状态  【暂时不可用】
        TransformOrigin = nil    --是否根据此位置进行偏移
        SetBindings = {
            {
                ActorTag = "",
                Actor = ObjectActor, --AActor
                TargetTag = "SequenceTag",
            },
        },
        --[
            是否强制执行回调 默认为false
            当资源异常不存在的时候，会强制执行回调
            被主动Stop时，会强制执行回调
        ]
        ForceCallback,
        --超时时间  默认没有超时时间
        TimeOut，
    } or nil 

    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("HallMain_LS_3", function ()
		print("Wait For Into Game!!")
	end, InParams)
]]
local class_name = "SequenceCtrl"
local SuperClass = UserGameController
---@class SequenceCtrl : UserGameController
SequenceCtrl = SequenceCtrl or BaseClass(SuperClass, class_name)


function SequenceCtrl:__init()
    ---@type SequenceModel
    self.Model = self:GetModel(SequenceModel)
end

function SequenceCtrl:Initialize()
    self.TheLanguageModel = self:GetModel(LocalizationModel)
end

function SequenceCtrl:OnLogout()
    self:ClearAllCache()
end

function SequenceCtrl:AddMsgListenersUser()
	self.MsgList = {
		{Model = ViewModel, MsgName = ViewModel.ON_PRE_LOAD_MAP,	Func = self.ON_PRE_LOAD_MAP_Func },
        {Model = HallModel, MsgName = HallModel.ON_CAMERA_SWITCH_PRELOAD,	Func = self.ON_CAMERA_SWITCH_PRELOAD_Func },
        {Model = CommonModel, MsgName = CommonModel.ON_AVATAR_PREPARE_STATE_NOTIFY,	Func = self.OnAvatarPrepareStateNotify },
	}
end

function SequenceCtrl:OnAvatarPrepareStateNotify(InParams)
    CWaring("SequenceCtrl:OnAvatarPrepareStateNotify")
    if InParams then
        local List = self.Model:GetActorSequenceQueue(InParams.Actor)
        if not List then
            return
        end
        for _, v in pairs(List) do
            if InParams.State then
                self:PlaySequenceByTag(v.Tag, v.CallBack, v.Param, true)
            else
                self:StopSequenceByTag(v.Tag)
            end
        end
        -- self.Model:CleanActorSequenceQueue(InParams.Actor)
    end
end

--[[
    切换关卡，
    所有已经创建的SequenceActor 都会销毁
    相当定时器，也需要清除
]]
function SequenceCtrl:ON_PRE_LOAD_MAP_Func(MapName)
    CWaring("SequenceCtrl:ON_PRE_LOAD_MAP_Func Do Clean")
    self:ClearAllCache()
    self.Model:CleanSequencesCache()
end

--[[
    即将开始切换相机
    TODO 停止当前所有LS
]]
function SequenceCtrl:ON_CAMERA_SWITCH_PRELOAD_Func(Param)
    --TODO 停止当前所有的LS
    self:StopAllSequences()
end

--- 根据tag播放LevelSequence
function SequenceCtrl:PlaySequenceByTag(InTag, InFinishCallBack, InParams, InNotForceWait)
    InParams = InParams or {}

    InTag = self.Model:CheckInTag(InTag)
    if self:IsSequencePlaying(InTag) then
        CWaring("Sequence Already Playing:" .. InTag)
        self:StopSequenceByTag(InTag)
    end

 	local TActor = self:GetBindingActor(InParams.SetBindings)
    if not InNotForceWait and InParams.WaitUtilActorHasBeenPrepared then
       
        if TActor then
            -- body
            self.Model:AppendActorSequenceQueue(TActor,InTag, InParams, InFinishCallBack)
            return
        end
    end
    if TActor then
        TActor:SetActorScale3D(UE.FVector(1,1,1))
    end

    if InParams.PauseEnd == nil then
        InParams.PauseEnd = true
    end
    -- if InParams.RestoreState == nil then
    --     InParams.RestoreState = true
    -- end
    if InParams.ForceCallback then
        InParams.ForceFinishCallBackFunc = InFinishCallBack
    end
    if not InParams.LevelSequenceAsset then
        CError("SequenceCtrl:PlaySequenceByTag LevelSequenceAsset nil",true)
        if InParams.ForceCallback and InFinishCallBack then
            InFinishCallBack()
        end
        return
    end
    --尝试将路径转换到当前语言文化的路径
    InParams.LevelSequenceAsset = self.TheLanguageModel:ConvertPath2LocalizationPathByAudio(InParams.LevelSequenceAsset)
    --TODO 提前先判断资源是否存在
    local SequenceAssetObj = LoadObject(InParams.LevelSequenceAsset)
    if not SequenceAssetObj then
        CError("SequenceCtrl:PlaySequenceByTag LevelSequenceAsset not found:" .. InParams.LevelSequenceAsset,true)
        if InParams.ForceCallback and InFinishCallBack then
            InFinishCallBack()
        end
        return
    end
    local Tag2Bindings = {}
    if InParams.SetBindings and #InParams.SetBindings > 0 then
        --根据SetBindings进行Tag2Bindings赋值，此逻辑会额外修饰CameraControl变量，用来标记LS会接管相机
        self:SetTag2Bindings(Tag2Bindings,InParams,SequenceAssetObj)
    end
    if InParams.NeedStopAllSequence then
        if InParams.StopAllSequenceCheckForceCallback == nil then
            InParams.StopAllSequenceCheckForceCallback = true
        end
        if not InParams.CameraControl then
            CError("SequenceCtrl:NeedStopAllSequence  Need CameraControl",true)
            if InParams.ForceCallback and InFinishCallBack then
                InFinishCallBack()
            end
            return
        end
        self:StopAllSequences(InParams.StopAllFilterTags,InParams.StopAllSequenceCheckForceCallback)
    end
    local SequenceActor = self.Model:GetSequenceActorFromCache(InTag, InParams)
    if not SequenceActor then
        CWaring("SequenceCtrl:PlaySequenceByTag SequenceActor nil")
        if InFinishCallBack then
            InFinishCallBack()
        end
        return
    end
    --[[
        这么修改不行的
        需要添加C++方法，运行时修改SequencePlayer.PlaybackSettings
    ]]
    -- SequenceActor.PlaybackSettings.bRestoreState = InParams.RestoreState
    -- SequenceActor.PlaybackSettings.bPauseAtEnd = InParams.PauseEnd
    --//
    SequenceActor.bOverrideInstanceData = false
    if InParams.TransformOrigin then
        SequenceActor.bOverrideInstanceData = true
        SequenceActor.DefaultInstanceData.TransformOrigin = InParams.TransformOrigin
    end

    --根据Tag2Bindings进行Actors的绑定
    for BindingTag, BindActors in pairs(Tag2Bindings) do
        SequenceActor:SetBindingByTag(BindingTag, BindActors)
    end

    local SequencePlayer = SequenceActor:GetSequencePlayer()
    if not SequencePlayer then
        local ShowStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SequenceCtrl_ThecorrespondingActo"),InTag)
        CWaring(ShowStr)
        if InFinishCallBack then
            InFinishCallBack()
        end
        return nil
    end

    -- SequencePlayer.PlaybackSettings.bRestoreState = InParams.RestoreState
    CWaring(StringUtil.Format("SequenceCtrl:PlaySequenceByTag LS:{0} LSActorId:{1}  LSTag:{2}",InParams.LevelSequenceAsset,SequenceActor.LSId,InTag))
    self.Model:SetLSId2Tag2Bindings(SequenceActor.LSId,Tag2Bindings)
    self:PlaySequence(InTag,SequenceActor,InFinishCallBack, InParams, Tag2Bindings)
    return SequenceActor
end

function SequenceCtrl:GetBindingActor(InBindingList)
    if not InBindingList then
        return
    end
    for _, BindingData in pairs(InBindingList) do
        if BindingData.TargetTag == SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM
        or BindingData.TargetTag == SequenceModel.BindTagEnum.ACTOR_SKELETMESH_COMPONENT then
            return BindingData.Actor
        end
    end
end

function SequenceCtrl:SetTag2Bindings(Tag2Bindings,InParams,SequenceAssetObj)
    local InBindingList = InParams.SetBindings

    --根据配置构造Actors结构
    for _, BindingData in pairs(InBindingList) do
        local BindActor = nil 
        local BindingTag = ""
        if not BindingData.ActorTag or string.len(BindingData.ActorTag) <= 0 then
            BindActor = BindingData.Actor
        else
            local Actors = UE.UGameplayStatics.GetAllActorsWithTag(GameInstance, BindingData.ActorTag)
            local Actor = nil
            if Actors:Length() > 0 then
                Actor = Actors:Get(1)
            end
            BindActor = Actor
        end
        if not BindActor then
            CError("SequenceCtrl:SetActorBindings>>>>>>>>>>>BindActor is nil, Please To Check it!!",true)
            return
        end
        BindingTag = BindingData.TargetTag
        if not BindingTag or string.len(BindingTag) <= 0 then
            CError("SequenceCtrl:SetActorBindings>>>>>>>>>>>BindingTag is nil, Please To Check it!!",true)
            return
        end
        if UE.UGFUnluaHelper.IsTagBindingExist(SequenceAssetObj,BindingTag) then
            if self.Model:IsActorCanBindingByBindingTag(BindActor,BindingTag,true) then
                if BindingTag == SequenceModel.BindTagEnum.CAMERA then
                    InParams.CameraControl = true
                end
                Tag2Bindings[BindingTag] = Tag2Bindings[BindingTag] or {}
                table.insert(Tag2Bindings[BindingTag], BindActor)
            end
        else
            CWaring("SequenceCtrl:SetTag2Bindings BindingTag not Found:" .. BindingTag)
        end
    end
end

function SequenceCtrl:AddActorBindings(SequenceActor,InBindingList)
    local Actor = nil
    for _, BindingData in pairs(InBindingList) do
        if #BindingData.ActorTag < 1 then
            Actor = BindingData.Actor
        else
            Actor = UE.UGameplayStatics.GetAllActorsWithTag(GameInstance, BindingData.ActorTag)
        end
        if not Actor then return end
        SequenceActor:AddBindingByTag(BindingData.TargetTag, Actor)
    end
end


function SequenceCtrl:IsEnablePostProcess(Tag2Bindings, IsEnablePostProcess)
    if not Tag2Bindings then
        return
    end

    local BindActors = Tag2Bindings[SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM] or Tag2Bindings[SequenceModel.BindTagEnum.ACTOR_SKELETMESH_COMPONENT]
    if not BindActors or #BindActors < 1 then
        return
    end

    local BindActor = BindActors[1]
    if not BindActor.SkeletalMesh then
        return
    end

    -- BindActor.SkeletalMesh:SetPostProcessSwitch(not IsEnablePostProcess)
end

function SequenceCtrl:PlaySequence(InTag,SequenceActor,InCallback, InParams, Tag2Bindings)
    local HallActor = nil
    if InParams.NeedAssign2Material then
        local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
        if HallAvatarMgr then
            HallActor = HallAvatarMgr:GetHallAvatar(MvcEntry:GetModel(UserModel).PlayerId, ViewConst.Hall, MvcEntry:GetModel(HeroModel):GetFavoriteId())
        end
        if HallActor then
            HallActor.NeedAssign2Material = true
        end
    end

    if InParams.IsEnablePostProcess then
        self:IsEnablePostProcess(Tag2Bindings, true)
    end

    local SequencePlayer = SequenceActor:GetSequencePlayer()
    local DelayCall = function (handler,IsTimerOut, IsForceStop)
        print("SequenceCtrl:PlaySequence DelayCall",InTag, IsTimerOut, IsForceStop)
        if HallActor then
            HallActor.NeedAssign2Material = false
        end
        SequencePlayer.OnStop:Clear()
        SequencePlayer.OnFinished:Clear()

        local TActor = self:GetBindingActor(InParams.SetBindings)
        self.Model:FinishActorSequenceQueue(TActor, InTag)

        if InParams.ForceStopAfterFinish then
            self.Model:StopSequenceByActor(SequenceActor)
        end

        SequenceActor.TagName = ""
        self:CleanCacheByTag(InTag)

        if InCallback then
            InCallback(IsForceStop)
        end

        if not IsTimerOut then
            if InParams.SaveCameraConfig then
                self:GetModel(HallModel):SaveNowCameraConfig()
            end
        else
            print_trackback()
            CWaring("SequenceCtrl:PlaySequence IsTimerOut:" .. InParams.LevelSequenceAsset)
        end
        if not IsForceStop and InParams.NeedStopAfterFinish then
            self.Model:StopSequenceByActor(SequenceActor)
        end

        if not InParams.ManualFocusMethodSetting and InParams.FocusMethodSetting then
            local Param = {
                FocusMethod = UE.ECameraFocusMethod.Disable,
				ManualFocusDistance = 10000
            }
            MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE,Param)
        end
        if InParams.IsEnablePostProcess then
            self:IsEnablePostProcess(Tag2Bindings, false)
        end

        local Actors = UE.UGFUnluaHelper.GetBindActorBySequencePlayer(SequencePlayer, SequenceModel.BindTagEnum.DELETE_AFTER_END_TAG)
        for _, Actor in pairs(Actors) do
            if CommonUtil.IsValid(Actor) then
                Actor:K2_DestroyActor()
            end
        end

        Actors = UE.UGFUnluaHelper.GetBindActorBySequencePlayer(SequencePlayer, SequenceModel.BindTagEnum.DELETE_BEFORE_NEXT_TAG)
        for _, TActor in pairs(Actors) do
            if CommonUtil.IsValid(TActor) then
                if IsForceStop then
                    TActor:K2_DestroyActor()
                else
                    if not TActor:ActorHasTag(SequenceModel.BindTagEnum.DELETE_BEFORE_NEXT_TAG) then
                        TActor.Tags:Add(SequenceModel.BindTagEnum.DELETE_BEFORE_NEXT_TAG)
                    end
                end
                print("K2_DestroyActor ADD DELETE_BEFORE_NEXT_TAG", InTag, TActor, IsForceStop)
            end
        end
        -- print("K2_DestroyActor DelayCall InTag", InTag, IsForceStop)
    end

    -- print("K2_DestroyActor Play InTag", InTag)

    local Actors = UE.UGameplayStatics.GetAllActorsWithTag(GameInstance, SequenceModel.BindTagEnum.DELETE_BEFORE_NEXT_TAG)
    for _, TActor in pairs(Actors) do
        if CommonUtil.IsValid(TActor) then
            print("K2_DestroyActor DELETE_BEFORE_NEXT_TAG", InTag, TActor)
            TActor:K2_DestroyActor()
        end
    end

    if InParams.FocusMethodSetting then
        local Param = {
            FocusMethod = InParams.FocusMethodSetting.FocusMethod,
            ManualFocusDistance = InParams.FocusMethodSetting.ManualFocusDistance or 10000
        }
        MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE,Param)
    end

    if InParams.TimeOut then
        self.Model:AddTimerDelay(InTag,InParams.TimeOut,Bind(self,DelayCall,true))
    end
    self.Model:AddCustomCacheByTag(InTag,InParams)
    SequencePlayer.OnFinished:Clear()
    SequencePlayer.OnFinished:Add(GameInstance, function ()
        DelayCall()
    end)

    SequencePlayer.OnStop:Clear()
    SequencePlayer.OnStop:Add(GameInstance, function ()
        DelayCall(nil, nil, true)
    end)

    --播放速率,负值等于反向播放
    SequencePlayer:SetPlayRate(InParams.PlayRate and InParams.PlayRate or 1)
    --是否禁用摄像机裁剪
    if InParams.IsDisableCameraCuts then
        SequencePlayer:SetDisableCameraCuts(InParams.IsDisableCameraCuts)
    else
        SequencePlayer:SetDisableCameraCuts(false)
    end

    if InParams.GoToEnd then
        SequencePlayer:GoToEnd()
    else
        if InParams.IsPlayReverse then
            --反向
            SequencePlayer:PlayReverse()
        else
            SequencePlayer:Play()
        end
    end
end


function SequenceCtrl:SetPlayRate(InTag, PlayRate)
    local SequenceActor = self.Model:GetSequenceActorByTag(InTag)
    if not SequenceActor then
        return
    end
    local SequencePlayer = SequenceActor:GetSequencePlayer()
    SequencePlayer:SetPlayRate(PlayRate)
end


--停止所有Sequences
function SequenceCtrl:StopAllSequences(StopAllFilterTags,CheckForceCallback)
    CWaring("SequenceCtrl:StopAllSequences")
    self.Model:StopAllSequences(StopAllFilterTags,CheckForceCallback)
    if not (StopAllFilterTags and #StopAllFilterTags > 0) then
        self:RestoreMaterialParameterCollection()
    end
end

--停止指定Sequences
function SequenceCtrl:StopSequenceByTag(InTag)
    self.Model:StopSequenceByTag(InTag,nil)
end

function SequenceCtrl:CleanSequenceActorByLSId(LSId)
    CWaring("SequenceCtrl:CleanSequenceActorByLSId:" .. LSId)
    self.Model:CleanSequenceActorByLSId(LSId)
end

function SequenceCtrl:ClearAllCache()
    self.Model:ClearAllCache()
end

function SequenceCtrl:CleanCacheByTag(InTag)
    self.Model:CleanCacheByTag(InTag)
end

function SequenceCtrl:ResetBindings(InTag)
    local SequenceActor = self.Model:GetSequenceActorByTag(InTag)
    if not SequenceActor then
        return
    end
    -- CWaring("SequenceCtrl:ResetBindings():" .. InTag)
    SequenceActor:ResetBindings()
end

function SequenceCtrl:RemoveBindingByTag(InTag,InBindingTag, InBindingActor)
    local SequenceActor = self.Model:GetSequenceActorByTag(InTag)
    if not SequenceActor then
        return
    end
    SequenceActor:RemoveBindingByTag(InBindingTag, InBindingActor)
end

--指定Sequence是否在播放中
function SequenceCtrl:IsSequencePlaying(InTag)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return false end
    return SequencePlayer:IsPlaying()
end

--指定Sequence能否播放
function SequenceCtrl:SequenceCanPlay(InTag)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return end
    return SequencePlayer:CanPlay()
end

--设置指定Sequence暂停播放
function SequenceCtrl:SequencePlayPause(InTag, InOnPauseCallBack)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return end
    SequencePlayer:Pause()
    if InOnPauseCallBack then
        SequencePlayer.OnPaused:Clear()
        SequencePlayer.OnPaused:Add(GameInstance, function ()
            InOnPauseCallBack()
        end)
    end
end

--反向播放(现时正向播放则会变为反向,反之也成立)
function SequenceCtrl:SequenceChangePlaybackDirection(InTag)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return end
    SequencePlayer:ChangePlaybackDirection()
end

--获取Sequence播放的持续时间帧
function SequenceCtrl:GetSequenceDurationFrames(InTag)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return end
    return SequencePlayer:GetFrameDuration()
end

--设置Sequence所做的任何更改恢复到其原始状态
function SequenceCtrl:SetSequenceRestoreState(InTag)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return end
    SequencePlayer:RestoreState()
end

function SequenceCtrl:GetCurrentTime(InTag)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return 0 end
    return UE.UGFUnluaHelper.ConvertFrameTime2Seconds(SequencePlayer:GetCurrentTime())
end

function SequenceCtrl:GetStartTime(InTag)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return 0 end
    return UE.UGFUnluaHelper.ConvertFrameTime2Seconds(SequencePlayer:GetStartTime())
end

function SequenceCtrl:GetEndTime(InTag)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return 0 end
    return UE.UGFUnluaHelper.ConvertFrameTime2Seconds(SequencePlayer:GetEndTime())
end

function SequenceCtrl:GetDuration(InTag)
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return 0 end
    return UE.UGFUnluaHelper.ConvertFrameTime2Seconds(SequencePlayer:GetDuration())
end

function SequenceCtrl:GetLeftTime(InTag)
    return self:GetDuration(InTag) - self:GetCurrentTime(InTag)
end

--设置Sequence从当前位置播放到请求的位置并暂停（如果请求的位置在当前位置之前，播放将被反转。如果在此播放期间调用Stop()或Pause()，将取消播放到请求的位置)
function SequenceCtrl:SetSequencePlayTo(InTag, InPlaybackParams)
    --[[
        local InPlaybackParams = {
            bHasJumped = false,
            Frame = 0.1,--frameTime
            MarkedFrame = "", --string
            PositionType = UE.EMovieScenePositionType.Frame,
            Time = 0.1,--time
            UpdateMethod = UE.EUpdatePositionMethod.Play
        }
    ]]
    local SequencePlayer = self.Model:GetSequencePlayerByTag(InTag)
    if not SequencePlayer then return end
    SequencePlayer:PlayTo(InPlaybackParams)
end

--[[
    手动恢复材质参数合集参数
    规避5.1 LS无法无法Restore材质参数合集的BUG
]]
function SequenceCtrl:RestoreMaterialParameterCollection()
    local MPBase = LoadObject("MaterialParameterCollection'/Game/Arts/Effect/Materials/MP/MP_EFF_Base.MP_EFF_Base'")
    if not MPBase then
        return
    end
    local lineColorInput = UE.FLinearColor(1,1,1)
    UE.UKismetMaterialLibrary.SetVectorParameterValue(GameInstance, MPBase, "A_Albedo Tint Color", lineColorInput)
end