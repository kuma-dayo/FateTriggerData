--
-- 战斗界面 - Buff列表
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.28
--

local PlayerBuff = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function PlayerBuff:OnInit()
    print("PlayerBuff", ">> OnInit, ...", GetObjectName(self))

	local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
	self.ChildClass = UE.UKismetSystemLibrary.LoadClassAsset_Blocking(MiscSystem.PlayerBuffItemClass)
	self.MaxShowNum = self.MaxShowNum or 10
    
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

	--
	self:UpdateBuffList()
	self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PLAYER_SkillBuffChanged, 		Func = self.OnChanged_SkillBuff, 	bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.PLAYER_BuffTagChanged, 		Func = self.OnChanged_BuffTag, 		bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.PLAYER_BuffCurLevelChanged, 	Func = self.OnChanged_CurLevel, 	bCppMsg = true, WatchedObject = nil },
	}

	-- 屏蔽
	--self:SetVisibility(UE.ESlateVisibility.Collapsed)

	UserWidget.OnInit(self)
end

function PlayerBuff:OnDestroy()
    print("PlayerBuff", ">> OnDestroy, ...", GetObjectName(self))

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function PlayerBuff:UpdateBuffList(InActiveBuffArray)
	local CurChildNum = self.HBBuffList:GetChildrenCount()
	local ActiveBuffNum = InActiveBuffArray and InActiveBuffArray:Length() or 0
	local MaxNum = math.min(math.max(CurChildNum, ActiveBuffNum), self.MaxShowNum)
	for i = 1, MaxNum do
		local BuffObject = (i <= ActiveBuffNum) and InActiveBuffArray:GetRef(i) or nil
		local ChildWidget = (i <= CurChildNum) and self.HBBuffList:GetChildAt(i - 1) or nil
		--print("PlayerBuff", ">> UpdateBuffList, ", i, GetObjectName(BuffObject), GetObjectName(ChildWidget))
		
		if BuffObject and (not ChildWidget) then
			ChildWidget = UE.UGUIUserWidget.Create(self.LocalPC, self.ChildClass, self.LocalPC)
			self.HBBuffList:AddChild(ChildWidget)
		end

		if ChildWidget then
			ChildWidget:InitData(BuffObject)
		end
	end
end

-------------------------------------------- Callable ------------------------------------

-- 
function PlayerBuff:Tick(MyGeometry, InDeltaTime)
	-- TODO: 待对接最新技能
	do return end

	--InDeltaTime = UE.UGameplayStatics.GetWorldDeltaSeconds(self)
	local CurChildNum = self.HBBuffList:GetChildrenCount()
	for i = 1, CurChildNum do
		local ChildWidget = self.HBBuffList:GetChildAt(i - 1)
		if ChildWidget and ChildWidget:IsVisible() and ChildWidget.TickImpl then
			ChildWidget:TickImpl(MyGeometry, InDeltaTime)
		end
	end
end

-- 
function PlayerBuff:OnChanged_SkillBuff(InSkillComp)
	if InSkillComp:GetWorld() ~= self:GetWorld() then
		return
	end
	print("PlayerBuff", ">> OnChanged_SkillBuff, ", GetObjectName(self.LocalPC))
	
	self:UpdateBuffList(InSkillComp.ActiveBuff)
end

-- 
function PlayerBuff:OnChanged_BuffTag(InBuff, InOldValue)
	if InBuff:GetWorld() ~= self:GetWorld() then
		return
	end
	print("PlayerBuff", ">> OnChanged_BuffTag, ", GetObjectName(InBuff), InBuff:ToString())

end

-- 
function PlayerBuff:OnChanged_CurLevel(InBuff, InOldValue)
	if InBuff:GetWorld() ~= self:GetWorld() then
		return
	end
	print("PlayerBuff", ">> OnChanged_CurLevel, ", GetObjectName(InBuff), InBuff:ToString())
	
end

return PlayerBuff
