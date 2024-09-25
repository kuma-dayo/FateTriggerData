--
-- 战斗界面控件 - 队伍玩家信息
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.11
--
require ("InGame.BRGame.ItemSystem.RespawnSystemHelper")

local TeamPlayerInfo = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function TeamPlayerInfo:OnInit()
    print("TeamPlayerInfo:OnInit",  GetObjectName(self))
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	--self.LocalPS = self.LocalPC.PlayerState
	assert(self.LocalPC, ">> LocalPC is invalid!!!")
	self:InitPlayerStateInfo()
	self.IsShow = false
	self:CheckRules()
	
    UserWidget.OnInit(self)
end

function TeamPlayerInfo:OnDestroy()
    --print("TeamPlayerInfo", ">> OnDestroy, ...", GetObjectName(self))
    self.IsShow = false
	MsgHelper:UnregisterList(self, self.MsgList_Team or {})
	
	UserWidget.OnDestroy(self)
end
function TeamPlayerInfo:OnShow()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.IsInOB = false
	if self.LocalPC.OriginalPlayerState ~= self.LocalPC.PlayerState and self.LocalPC.OriginalPlayerState ~= nil then
		self.IsInOB = true
		self:ResetTeamItem()
		self:SetTeamPlayerDetail()
	end
	self.IsShow = true
	print("TeamPlayerInfo:OnShow IsShow",self.IsShow ,"IsInOB",self.IsInOB,GetObjectName(self))
	

end
function TeamPlayerInfo:OnClose()
	self.IsShow = false
	self:ResetTeamItem()
end
-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function TeamPlayerInfo:InitPlayerStateInfo()
    -- TODO:单排不显示
    if false then return end
	
	-- 注册本地玩家消息
    if (not self.MsgList_Team) then
        self.MsgList_Team = {
            { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,			Func = self.OnUpdateLocalPCPS,		bCppMsg = true, WatchedObject = self.LocalPC },
			{ MsgName = GameDefine.MsgCpp.PLAYER_PSTeamId,     			Func = self.OnUpdatePSTeamId,		bCppMsg = true, WatchedObject = nil },
			{ MsgName = GameDefine.MsgCpp.PLAYER_TeammatePSList,     	Func = self.OnUpdateTeammatePSList,	bCppMsg = true, WatchedObject = nil},
			{ MsgName = GameDefine.MsgCpp.PLAYER_PSTeamPos,          Func = self.OnChange_PSTeamPos, bCppMsg = true, WatchedObject =nil },
			--{ MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDying,			Func = self.OnBeginDying,			bCppMsg = true,	WatchedObject = nil},
			--{ MsgName = GameDefine.MsgCpp.PLAYER_OnEndDying,			Func = self.OnBeginDying,			bCppMsg = true,	WatchedObject = nil},
            { MsgName = GameDefine.MsgCpp.ObserveX_System_BecomeObserver,   Func = self.OnBecomeObserver, bCppMsg = true, WatchedObject =nil },
        }          
        MsgHelper:RegisterList(self, self.MsgList_Team)
    end
	
	local LocalGS = UE.UGameplayStatics.GetGameState(self)
	if LocalGS and  (not self.MsgList_GS)  then
		self.MsgList_GS = {
			{MsgName = GameDefine.MsgCpp.UISync_Update_RuleActiveTimeSec,     Func = self.OnRuleActiveParachuteRespawn,  bCppMsg = true,  WatchedObject = LocalGS},
			{MsgName = GameDefine.MsgCpp.UISync_Update_ParachuteRespawnRuleEnd,     Func = self.OnRuleFinishedParachuteRespawn,  bCppMsg = true,  WatchedObject = LocalGS}, 
		 }
		MsgHelper:RegisterList(self, self.MsgList_GS)
	end
	
	if (not self.MsgList_PS) then
    	self.MsgList_PS = {
   			
    		}
		MsgHelper:RegisterList(self, self.MsgList_PS)
		
	end
	-- 初始化队伍面板（生成和reset数据）
	
	self:ResetTeamItem()
	
	self:SetTeamPlayerDetail()

end
function TeamPlayerInfo:OnBecomeObserver(InOBMessgae)
	print("TeamPlayerInfo:OnBecomeObserver",self.IsShow ,  GetObjectName(self))
	if self.IsShow == false then
		return 
	end
	
	self.IsInOB = true 
	self:ResetTeamItem()
	self:SetTeamPlayerDetail()
end
-- 清理本地玩家队伍
function TeamPlayerInfo:ResetTeamItem()
    self.TeamPlayerInfos = {}
    --self.Root:ClearChildren()

	-- local DefaultNum, ChildrenNum = 4, self.Root:GetChildrenCount()
	-- local NeedCreateNum = DefaultNum - ChildrenNum
	-- for i = 1, NeedCreateNum do
	-- 	local ChildWidget = UE.UGUIUserWidget.Create(self.LocalPC, self.DetailClass, self.LocalPC)
	-- 	self.Root:AddChild(ChildWidget)
	-- end
	local AllChildren = self.Root:GetAllChildren()
	for i = 1, AllChildren:Length() do
		local ChildWidget = AllChildren:GetRef(i)
		if ChildWidget then
			ChildWidget:ResetData()
			ChildWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
		end
	end
	--print("TeamPlayerInfo", ">> ResetTeamItem, ", DefaultNum, ChildrenNum, NeedCreateNum, self.Root:GetChildrenCount())
end

--创建队友detail数据
function TeamPlayerInfo:SetTeamPlayerDetail()
	
	-- 更新本地玩家队伍
    local TeamExSubsystem = UE.UTeamExSubsystem.Get(self)
	local TeamMembers = TeamExSubsystem:GetTeammatePSListByPS(self.LocalPC.PlayerState)
	local TeamMemberLength = TeamMembers:Length()
	--因为修改了时序问题，OnUpdateTeammatePSList会无脑多调一次，为了兼容OB逻辑，只能在初始化记录自己是不是在OB状态，然后走不同的逻辑
	if self.IsInOB == false then
		for i = 1, TeamMemberLength do
			local TmpPS = TeamMembers:GetRef(i)
			--print("TeamPlayerInfo:SetTeamPlayerDetail self.LocalPC.PlayerState",self.LocalPC.PlayerState,"PlayerName is ",self.LocalPC.PlayerState:GetPlayerName(),i,"TmpPS: ", TmpPS,"TmpPSPlayerName is ",TmpPS:GetPlayerName())  		
			--判断如果进来的是自己的信息就直接跳过，不生成
			if self.LocalPC.OriginalPlayerState ~= TmpPS  then
				
				self:UpdateTeamItem(TmpPS,i)
			end
			if 	TmpPS == nil then
				print("TeamPlayerInfo:SetTeamPlayerDetail TmpPS is nil index is ",i)
			end
		end
	else
		for i = 1, TeamMemberLength do
			local TmpPS = TeamMembers:GetRef(i)
			--print("TeamPlayerInfo:SetTeamPlayerDetail self.LocalPC.PlayerState",self.LocalPC.PlayerState,"PlayerName is ",self.LocalPC.PlayerState:GetPlayerName(),i,"TmpPS: ", TmpPS,"TmpPSPlayerName is ",TmpPS:GetPlayerName())  		
			--判断如果进来的是自己的信息就直接跳过，不生成
			if self.LocalPC.PlayerState ~= TmpPS  then	
				self:UpdateTeamItem(TmpPS,i)
			end
			if 	TmpPS == nil then
				print("TeamPlayerInfo:SetTeamPlayerDetail TmpPS is nil index is ",i)
			else
				print("TeamPlayerInfo:SetTeamPlayerDetail self.LocalPC.PlayerState ",self.LocalPC.PlayerState:GetPlayerName(),"TmpPS",TmpPS:GetPlayerName())
			end
		end
		
	end
	
	print("TeamPlayerInfo:SetTeamPlayerDetail TeamMemberLength",TeamMemberLength,self.IsShow )
end

-- 添加队伍数据
function TeamPlayerInfo:UpdateTeamItem(InPlayerState, IndexInTeam)

	if not UE.UKismetSystemLibrary.IsValid(InPlayerState) then
		print("TeamPlayerInfo", "UpdateTeamItem PS=nil")
		return
	end

	local CurTeamPos = BattleUIHelper.GetTeamPos(InPlayerState)
	if IndexInTeam == nil then
		IndexInTeam = CurTeamPos
	end
	
	print("TeamPlayerInfo:", "UpdateTeamItem CurTeamPos(LogOnly)= ,IndexInTeam=", CurTeamPos, IndexInTeam)
	
	--if (not CurTeamPos) or (CurTeamPos <= 0) then
		--Warning("TeamPlayerInfo", ">> UpdateTeamItem, CurTeamPos invalid!", 
			--GetObjectName(InPlayerState), CurTeamPos)
		--return
	--end
	if IndexInTeam >4 then
		return
	end
	local InPlayerId = InPlayerState.PlayerId
	--先查找这个人的信息有没有之前被初始化过，如果有的话，先默认隐藏
	if (self.TeamPlayerInfos[InPlayerId]) and (self.TeamPlayerInfos[InPlayerId].TeamPos ~= IndexInTeam) and (self.TeamPlayerInfos[InPlayerId].PlayerId ==InPlayerId ) then
		local ChildWidget = self.Root:GetChildAt(self.TeamPlayerInfos[InPlayerId].TeamPos - 1)
		if ChildWidget then
			ChildWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
			print("TeamPlayerInfo:", "UpdateTeamItem Collapsed CurTeamPos(LogOnly)= ,IndexInTeam=", self.TeamPlayerInfos[InPlayerId].TeamPos, IndexInTeam,InPlayerState:GetPlayerName())
			self.TeamPlayerInfos[InPlayerId] =nil
			
		end
	end
	--如果这个人的数据没有被初始化过，需要重置他的信息并且初始化且设置可见性
	if (not self.TeamPlayerInfos[InPlayerId])  then
		local ChildWidget = self.Root:GetChildAt(IndexInTeam - 1)
		if ChildWidget then
			self:ClearTeamPlayerInfos(ChildWidget)
			ChildWidget:ResetData()
			ChildWidget:InitData(InPlayerState)
			ChildWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			
			self.TeamPlayerInfos[InPlayerId] = { Widget = ChildWidget, TeamPos = IndexInTeam, PlayerId =InPlayerId }
			print("TeamPlayerInfo:", ">> UpdateTeamItem, Update!", 
				GetObjectName(InPlayerState), GetObjectName(ChildWidget), IndexInTeam, InPlayerId,InPlayerState:GetPlayerName())
		end
	end
end


function TeamPlayerInfo:ClearTeamPlayerInfos(InChildWidget)
	for i,v in  pairs(self.TeamPlayerInfos) do 
		if v.Widget == InChildWidget then
			self.TeamPlayerInfos[i]=nil
			print("TeamPlayerInfo:ClearTeamPlayerInfos123 playerid is ",i,"TeamPos",v.TeamPos,"widget",GetObjectName(v.Widget))
		end
		--print("TeamPlayerInfo:ClearTeamPlayerInfos playerid is ",i,"TeamPos",v.TeamPos,"widget",GetObjectName(v.Widget))
	end
end

-------------------------------------------- Callable ------------------------------------

-- 
function TeamPlayerInfo:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
	--print("xiaoyaolua: TeamPlayerInfo", ">> OnUpdateLocalPCPS, ", GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InPCPS))
	
	if self.LocalPC == InLocalPC then
		if self.IsShow == true then
			if self.LocalPC.OriginalPlayerState ~= self.LocalPC.PlayerState and self.LocalPC.OriginalPlayerState ~= nil then
				self.IsInOB = true
			else
				self.IsInOB = false
			end
		end
		
		print("TeamPlayerInfo:OnUpdateLocalPCPS IsShow",self.IsShow ,"IsInOB",self.IsInOB,GetObjectName(self))
		self:InitPlayerStateInfo()
	end
end

--
function TeamPlayerInfo:OnUpdatePSTeamId(InPlayerState)
	print("TeamPlayerInfo123:OnUpdatePSTeamId")

	if InPlayerState and self.LocalPC.PlayerState then
		--print("xiaoyaolua: TeamPlayerInfo", ">> OnUpdatePSTeamId, ",InPlayerState,InPlayerState.Playerid)
		print("TeamPlayerInfo:OnUpdatePSTeamId", InPlayerState.Playerid)
		local bIsTeammate = UE.UTeamExSubsystem.Get(self):IsTeammateByPSandPS(self.LocalPC.PlayerState, InPlayerState)
		if not bIsTeammate then
			return
		end
	end
	
    if self:GetWorld() == InPlayerState:GetWorld()then
		self:UpdateTeamItem(InPlayerState)
	end
end

function TeamPlayerInfo:OnUpdateTeammatePSList(InPCPS)
	--print("xiaoyaolua: TeamPlayerInfo", ">> OnUpdateTeammatePSList")
	print("TeamPlayerInfo123:OnUpdateTeammatePSList")
    if self:GetWorld() == InPCPS:GetWorld()   then
		self:SetTeamPlayerDetail()
	else
		print("TeamPlayerInfo:OnUpdateTeammatePSList Failed selfWold",self:GetWorld(),"InPCPS:GetWorld:",InPCPS:GetWorld())
	end
end

function TeamPlayerInfo:OnChange_PSTeamPos(InPS, InPlayerSpec)
	if InPS == nil or InPlayerSpec ==nil then
		print("TeamPlayerInfo:OnChange_PSTeamPos",InPS,InPlayerSpec)
		return 
	end
	
	local InPlayerId = InPS.PlayerId
	print("TeamPlayerInfo:OnChange_PSTeamPos: InPlayerId",InPlayerId,"CurTeamPos",InPlayerSpec.PlayerSerialNumber)
	if (self.TeamPlayerInfos[InPlayerId]) then
		local ChildWidget = self.Root:GetChildAt(self.TeamPlayerInfos[InPlayerId].TeamPos - 1)
		if ChildWidget then
			ChildWidget:OnChange_PSTeamPos(InPS,InPlayerSpec)
		end 

	end
end


function TeamPlayerInfo:OnRuleActiveParachuteRespawn(InRuleActiveTimeSec,InRuleTag)
   print("TeamPlayerInfo:OnRuleActiveParachuteRespawn",InRuleActiveTimeSec, InRuleTag and InRuleTag.TagName or nil)
	if InRuleTag and InRuleTag.TagName == "GameplayAbility.GMS_GS.Respawn.Rule.Parachute" then
		self.ReBornWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.ReBornWidget:StartToreciprocal(InRuleActiveTimeSec)
	else
		self.ReBornWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
end

function TeamPlayerInfo:OnRuleFinishedParachuteRespawn()
	print("TeamPlayerInfo:OnRuleFinishedParachuteRespawn")
    self.ReBornWidget:ClearTimerHandle()
    self.ReBornWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    
end

function TeamPlayerInfo:CheckRules()
	print("TeamPlayerInfo:CheckRules")
	local PS = UE.UPlayerStatics.GetCPS(self.LocalPC)
	if not UE.UKismetSystemLibrary.IsValid(PS) then
		print("TeamPlayerInfo:CheckRules cannot get localps")
		return
	end
	if UE.URespawnSubsystem.Get(PS):IsParachuteRespawnValid() == true then
		print("TeamPlayerInfo:CheckRules IsParachuteRespawnValid is true")
	
		local RuleTag = UE.FGameplayTag()
		RuleTag.TagName = "GameplayAbility.GMS_GS.Respawn.Rule.Parachute"
   		local RuleActiveTime = RespawnSystemHelper.GetRuleActiveTimeSec(self,RuleTag)
		self:OnRuleActiveParachuteRespawn(RuleActiveTime,RuleTag)
	end
end

return TeamPlayerInfo
