---
--- 声音播放管理器
--- 1）播放背景音乐及音效请使用 SoundMgr:PlaySound(SoundEventName)
---		e.g: SoundMgr:PlaySound(SoundCfg.Music.MUSIC_PLAY)				背景音乐调用
---			 SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_START)		音效调用
--- 2）播放英雄角色语音请使用 SoundMgr:PlayHeroVoice(HeroSkinId, EventID)
---		e.g: SoundMgr:PlayHeroVoice(LeaderInfo.HeroSkinId, SoundCfg.Voice.MATCH_START)	英雄角色语音调用
---

require("Client.GameConfig")
require("Client.Sound.SoundModel")
require("Client.Sound.SoundCfg")
---@class SoundMgr
SoundMgr = SoundMgr or {}
-- SoundMgr.Music = require("Client.Sound.SoundCfg").Music
-- SoundMgr.SoundEffects = require("Client.Sound.SoundCfg").SoundEffects
-- SoundMgr.Voice = require("Client.Sound.SoundCfg").Voice

-- --用于目前Voice的CD，以事件名作为key。一个事件名可能对应多条音频资源，每个音频资源的长度不一样，所以同一个事件名里面的CD也会随着发生改变
-- ---@type table<事件名:string, 剩余CD:number>
-- local _PlayingCDList = {}

---封装一个接口来判断是否能够播放声音
---@return boolean 是否能够播放声音
function SoundMgr:_CanPlaySound()	
	if not GameConfig.IsTestMode() then
		return true
	end

	local _, CanPlaySound = UE.UGameHelper.FindIntConsoleVariable("CanPlaySound")
	if CanPlaySound == 0 then 
		return false 
	end

	return true
end

---播放2d声音（背景音乐或音效）
---@param SoundEventName string 声音事件名
---@see SoundCfg#Music 背景音枚举
---@see SoundCfg#SoundEffects 音效枚举
---@return number 正在播放的声音ID，如果返回 0 的话，说明没有成功播放声音
function SoundMgr:PlaySound(SoundEventName)
	--1.不能播放声音时不处理
	if not self:_CanPlaySound() then 
		return 0
	end
	
	--2.判空保护
	if SoundEventName == nil or SoundEventName == "" then
		CWaring("[SoundMgr] PlaySound: Tring to play a illegal SoundEvent(" .. tostring(SoundEventName) .. ")")
		return 0
	end
	
	--3.在 UISound.xlsx 表中，找到 SoundID 为 形参SoundEventName 的条目，没有就返回
	local UISoundCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_UISoundTable, Cfg_UISoundTable_P.SoundID, SoundEventName)
	if UISoundCfg == nil then
		CWaring("[SoundMgr] PlaySound: Can not find data of SoundEvent(" .. tostring(SoundEventName) .. ") in UISound.xlsx")
        return 0
    end
	
	--4.读表获取资源并播放
	local SoundEvent = UISoundCfg[Cfg_UISoundTable_P.SoundEvent]
	local SoftObjPath = UE.UKismetSystemLibrary.MakeSoftObjectPath(SoundEvent)
	--4.1.没有资源播放失败
	if SoftObjPath == nil then
		CWaring("[SoundMgr] PlaySound: Can not find asset base on SoundEventName(" .. tostring(SoundEventName) .. "), SoundAssertPath: " .. tostring(SoundEvent) )
		return 0		
	--4.2.走到这里说明播放没有问题了
	else
		local PlayingID = UE.UGTSoundStatics.PostAkEvent_Soft(_G.GameInstance:GetWorld(), SoftObjPath)
		-- CLog("[SoundMgr] PlaySound: Play SoundEventName(" .. tostring(SoundEventName) .. "); SoundAssertPath: " .. tostring(SoundEvent))		
		return PlayingID or 0
	end
end

--停止播放所有的语音
function SoundMgr:StopPlayAllVoice()
	print("SoundMgr:StopPlayAllVoice")
	local UISoundCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_UISoundTable, 
		Cfg_UISoundTable_P.SoundID, SoundCfg.Voice.HALL_STOP_ALL)

	if UISoundCfg == nil then
		CWaring("[SoundMgr] StopPlayAllVoice UISound.xlsx")
		return
    end

	local SoundEvent = UISoundCfg[Cfg_UISoundTable_P.SoundEvent]
	local SoftObjPath = UE.UKismetSystemLibrary.MakeSoftObjectPath(SoundEvent)
	if SoftObjPath == nil then
		CWaring("[SoundMgr] StopPlayAllVoice: Can not find asset")
		return
	end
	UE.UGTSoundStatics.PostAkEvent_Soft(_G.GameInstance:GetWorld(), SoftObjPath)
end

function SoundMgr:StopPlayAllEffect()
	print("SoundMgr:StopPlayAllEffect")
	local UISoundCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_UISoundTable, 
		Cfg_UISoundTable_P.SoundID, SoundCfg.Voice.HALL_STOP_EFFECT_ALL)

	if UISoundCfg == nil then
		CWaring("[SoundMgr] StopPlayAllVoice UISound.xlsx")
		return
    end

	local SoundEvent = UISoundCfg[Cfg_UISoundTable_P.SoundEvent]
	local SoftObjPath = UE.UKismetSystemLibrary.MakeSoftObjectPath(SoundEvent)
	if SoftObjPath == nil then
		CWaring("[SoundMgr] StopPlayAllVoice: Can not find asset")
		return
	end
	UE.UGTSoundStatics.PostAkEvent_Soft(_G.GameInstance:GetWorld(), SoftObjPath)
end


---播放英雄声音
---@param HeroSkinId number 英雄皮肤ID
---@see SoundCfg#Voice 背景音枚举
---@param EventID string 声音事件名
---@return userdata|nil 事件在表里对应的数据，为 nil 时说明配置有问题，可以根据log进行排查
function SoundMgr:PlayHeroVoice(HeroSkinId, EventID)
	--1.判空保护
	if EventID == nil or EventID == "" then return end
	
	--2.CD中不处理
	-- if _PlayingCDList[EventID] ~= nil then 
	-- 	CLog("[SoundMgr] PlayHeroVoice: CD: Works EventID = " .. tostring(EventID)) 
	-- 	return 
	-- end
	---@type SoundModel
	local SoundModel = MvcEntry:GetModel(SoundModel)
	if SoundModel:IsSoundEventInCD(EventID) then 
		CLog("[SoundMgr] PlayHeroVoice: CD: Works HeroSkinId = " .. tostring(HeroSkinId) .. ", EventID = " .. tostring(EventID)) 
		return 
	end
	--3.根据皮肤id在 HeroConfig.xlsx 中找到对应的配置，判空保护处理
	local HeroSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin, Cfg_HeroSkin_P.SkinId, HeroSkinId)
	if HeroSkinCfg == nil then 
		CError("[SoundMgr] PlayHeroVoice: Can not find HeroSkinCfg data base on HeroSkinId(" .. tostring(HeroSkinId) .. ") in HeroSkin.xlsx") 
		return 
	end
	
	--4.检查 HeroConfig.xlsx 中是否有配置 语音配置 条目，且数据不为空
	local HeroVoiceCfgName = HeroSkinCfg[Cfg_HeroSkin_P.SkinVoice]
	if not HeroVoiceCfgName or HeroVoiceCfgName == "" then 
		CError("[SoundMgr] PlayHeroVoice: HeroVoiceCfgName is empty, plase check HeroSkin.xlsx - 皮肤ID(" .. tostring(HeroSkinId) .. ") - 语音配置") 
		return 
	end
	
	--5.筛选皮肤对应的音频表里，符合 EventID 字段与 形参EventID 一致的条目
	--没有找到的话就直接返回一个空条目
	local TargetItem = nil
	local SoundItems = G_ConfigHelper:GetMultiItemsByKey(HeroVoiceCfgName, "EventID", EventID)
	if not SoundItems or not next(SoundItems) then
		CWaring("[SoundMgr] PlayHeroVoice: Can not find SoundItems base on the EventID(" .. tostring(EventID) .. ") on the Cfg(" .. tostring(HeroVoiceCfgName) .. "), HeroSkinId(" .. tostring(HeroSkinId) .. ")")
		return TargetItem
	end
	
	--6.计算所有的音频权重，并随机一个音频出来
	local WeightMax = 0
	for _, v in pairs(SoundItems) do
		WeightMax = WeightMax + v["RandomWeight"]
	end

	local RandomValue =	math.random(0, WeightMax)
	local TempMax = 0
	for _, v in pairs(SoundItems) do
		TempMax = TempMax + v["RandomWeight"]
		if TempMax >= RandomValue then
			TargetItem = v
			break
		end
	end

	--7.找到对应条目的 Event资源 ，并处理播放
	local SoundEvent = TargetItem["SoundEvent"]
	local SoftObjPath = UE.UKismetSystemLibrary.MakeSoftObjectPath(SoundEvent)
	--7.1.找到对应的资源，播放
	if SoftObjPath then
		self:StopPlayAllVoice()
		--7.1.1.播放声音
		UE.UGTSoundStatics.PostAkEvent_Soft(_G.GameInstance:GetWorld(), SoftObjPath)
		--CLog("[SoundMgr] PlayHeroVoice: Play EventID(" .. tostring(EventID) .. "); SoundAssertPath: " .. tostring(SoundEvent) .. "; CD: " .. tostring(TargetItem["CD"]))
		
		--7.1.2.记录CD
		--CD 在 SoundMgr:TickVoiceCD 中做处理
		-- _PlayingCDList[EventID] = TargetItem["CD"]
		if TargetItem["CD"] > 0 then
			SoundModel:RefreshSoundEventCD(EventID, TargetItem["CD"])
		end
		
	--7.2.没有找到对应的资源，抛出警告
	else		
		CWaring("[SoundMgr] PlayHeroVoice: Can not find asset base on the EventID(" .. tostring(EventID) .. "), SoundEvent(" .. tostring(SoundEvent) .. "), HeroSkinId(" .. tostring(HeroSkinId) .. ")")
	end
	
	--8.返回对应音频的数据
	return TargetItem
end

-- ---声音CD TICK
-- ---更新记录的CD，如果CD结束就移除出CD列表，运行再次播放
-- function SoundMgr:TickVoiceCD(DelTime)
-- 	local RemoveList = {}
-- 	local UpdateList = {}
-- 	for k, v in pairs(_PlayingCDList) do 
-- 		v = v - DelTime
-- 		if v <= 0 then
-- 			table.insert(RemoveList, k)
-- 		else
-- 			UpdateList[k] = v
-- 		end
-- 	end

-- 	for k, v in pairs(UpdateList) do
-- 		_PlayingCDList[k] = v
-- 	end

-- 	for _, v in ipairs(RemoveList) do 
-- 		_PlayingCDList[v] = nil
-- 	end
-- end

-- ---TICK事件
-- function SoundMgr:Tick(DelTime)
-- 	self:TickVoiceCD(DelTime)
-- end

return SoundMgr