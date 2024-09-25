require("UE.InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysConst")
local BuoysCommUI = Class("Common.Framework.UserWidget")

BuoysCommUI.SwicherMode = {ScreenCenter=0,Screen=1,ScreenEdge=2}
BuoysCommUI.BuoysWidgets = { "ScreenCenter", "Screen", "ScreenEdge" }

function BuoysCommUI:OnInit()

	self.BgWidgetArr = { ScreenCenter = nil, Screen = nil, ScreenEdge = nil }
	self.IconWidgetArr = { ScreenCenter = nil, Screen = nil, ScreenEdge = nil }


	self.NewSlateColor = UE.FSlateColor()

	for index = 1, #BuoysCommUI.BuoysWidgets do
		local WidgetStr = BuoysCommUI.BuoysWidgets[index]
		if self[WidgetStr] then
			local BgWidget = self[WidgetStr]:GetChildAt(0)
			local IconWidget = self[WidgetStr]:GetChildAt(1)
			self.BgWidgetArr[WidgetStr] = BgWidget
			self.IconWidgetArr[WidgetStr] = IconWidget
        end
    end

	-- 
	if self.MarkWidget2 then self.MarkWidget2.TxtDist:SetText('') end
	if self.TxtDist then self.TxtDist:SetText('') end
	if self.TxtName then self.TxtName:SetText('') end

	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

	self.TxtOpList = {}

	self:InitRangeAnimation()
	
	UserWidget.OnInit(self)
end

function BuoysCommUI:OnDestroy()
    print("BuoysCommUI >> OnDestroy, ", GetObjectName(self))
	
    UserWidget.OnDestroy(self)
end

-- 根据屏幕范围控制UI的显隐以及UI动效均挪到C++
function BuoysCommUI:InitRangeAnimation()
	--初始化更新范围标记播放的动画，添加显示范围，播放动画事件绑定InAnimation，OutAnimation委托
	--UE.FMarkWidgetAnimationParams()
end

-- 更新销毁Timer
function BuoysCommUI:UpdateLifeSpanTimer(bEnableTimer)
	print("BuoysCommItem", ">> UpdateLifeSpanTimer, ", bEnableTimer, self.DelayLifeSpan)

	if self.TimerDestroy then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerDestroy)
		self.TimerDestroy = nil
	end
	if bEnableTimer then
		self.TimerDestroy = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnTimer_OnDestroy}, self.DelayLifeSpan, false, 0, 0)
	end
end


function BuoysCommUI:OnTimer_OnDestroy()
	print("BuoysCommUI", ">> OnTimer_OnDestroy, DelayLifeSpan:", self.DelayLifeSpan,  GetObjectName(self))

	self:RemoveFromParent()
end


-- 距离显示文本可见性
function BuoysCommUI:IsVisible_TxtDist()
	if self.MarkWidget2 then return self.MarkWidget2.TxtDist and self.MarkWidget2.TxtDist:IsVisible() end
	if self.MarkWidget1 then return self.MarkWidget1.TxtDistSmall and self.MarkWidget1.TxtDistSmall:IsVisible() end
	return self.TxtDist and self.TxtDist:IsVisible()
end

-- 更新头标方向

function BuoysCommUI:UpdateBuoysDir(InRotYaw)							-- override
	
end



-- 更新距离逻辑
function BuoysCommUI:UpdateDistLogic(InDist, bForceUpdate)
	
end

-- 更新距离显示
-- function BuoysCommUI:UpdateTextDist(InDist, bForceUpdate)
-- 	local DistInt = math.tointeger(InDist)
--     local ShowText = BuoysConst.GetTextShowByDistInt(DistInt)

--     if self.MarkWidget2 then self.MarkWidget2.TxtDist:SetText(ShowText) end
--     if self.MarkWidget1 then self.MarkWidget1.TxtDistSmall:SetText(ShowText) end
--     if self.TxtDist then self.TxtDist:SetText(ShowText) end
--     if self.TxtDistSmall  then
--         self.TxtDistSmall:SetText(ShowText)
--     end
-- end

function BuoysCommUI:GetTargetActorLoc()
    -- if UE.UKismetSystemLibrary.IsValid(self.PlayerPawn) then
    --     return self.PlayerPawn::
    -- end

    return self.Tar3DMarkLoc
end

function BuoysCommUI:GetLocalPCPawnLoc()
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)

	--print("BuoysCommItem", ">> UpdateWidgetPos, ", GetObjectName(TargetActor), GetObjectName(LocalPCPawn), TargetActorLoc)
	if (not LocalPCPawn) then 
        return nil
    end

    return LocalPCPawn:K2_GetActorLocation()
end

-- TODO 转到c++
-- function BuoysCommUI:UpdateDistanceText(bForceUpdate)

-- 	self:UpdateDistLogic(self.ToTargetDistM, bForceUpdate)
--     -- 更新距离显示文本
--     if self:IsVisible_TxtDist() then
--         if self.RangeTxtDist and (self.ToTargetDistM >= self.RangeTxtDist.X and self.ToTargetDistM <= self.RangeTxtDist.Y) then
--             self:UpdateTextDist(self.ToTargetDistM, bForceUpdate)
--         elseif nil == self.RangeTxtDist then
--             self:UpdateTextDist(self.ToTargetDistM, bForceUpdate)
--         elseif self.MarkWidget2 and self.MarkWidget2.TxtDist then
--             self.MarkWidget2.TxtDist:SetVisibility(UE.ESlateVisibility.Collapsed)
-- 		elseif self.TxtDist then
-- 			self.TxtDist:SetVisibility(UE.ESlateVisibility.Collapsed)
--         end
--     end
-- end

-- TODO 转到c++
-- function BuoysCommUI:UpdateWidgetLine(bForceUpdate)
--     local TargetActorLoc = self:GetTargetActorLoc()
--     local LocalPCPawnLoc = self:GetLocalPCPawnLoc()
--     local ToTargetDist = UE.UKismetMathLibrary.Vector_Distance(TargetActorLoc, LocalPCPawnLoc)
-- 	local ToTargetDistM = math.floor(ToTargetDist * 0.01)
-- 	self:UpdateDistLogic(ToTargetDistM, bForceUpdate)
--     -- 更新距离显示文本
--     if self:IsVisible_TxtDist() then
--         if self.RangeTxtDist and (ToTargetDistM >= self.RangeTxtDist.X and ToTargetDistM <= self.RangeTxtDist.Y) then
--             self:UpdateTextDist(ToTargetDistM, bForceUpdate)
--         elseif nil == self.RangeTxtDist then
--             self:UpdateTextDist(ToTargetDistM, bForceUpdate)
--         elseif self.MarkWidget2.TxtDist then
--             self.MarkWidget2.TxtDist:SetVisibility(UE.ESlateVisibility.Collapsed)
-- 		elseif self.TxtDist then
-- 			self.TxtDist:SetVisibility(UE.ESlateVisibility.Collapsed)
--         end
--     end
-- end

--设置xtOpList
function BuoysCommUI:InitTxtOpList()

	for Key, Value in pairs(self.TxtOpList) do
		self.TxtOpList[Key] = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, Key)
	end

end

--检测TxtOpList
function BuoysCommUI:CheckTxtOpListKey(OutOpTxtKey)

	local bContain = false
	for k, _ in pairs(self.TxtOpList) do
		if (k == OutOpTxtKey) then
			bContain = true
			break
		end
	end

	if bContain  == false then
		table.insert(self.TxtOpList, OutOpTxtKey)
		self.TxtOpList[OutOpTxtKey] = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, OutOpTxtKey)
	end

end


return BuoysCommUI