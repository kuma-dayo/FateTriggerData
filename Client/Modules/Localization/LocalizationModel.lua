--[[
    本地化相关
    文本
    语音
]]
local super = GameEventDispatcher;
local class_name = "LocalizationModel";
---@class LocalizationModel : GameEventDispatcher
LocalizationModel = BaseClass(super, class_name);


-- LocalizationModel.ON_CURRENT_LANGUAGE_CHANGE_BEFORE = "ON_CURRENT_LANGUAGE_CHANGE_BEFORE"
LocalizationModel.ON_CURRENT_LANGUAGE_CHANGE = "ON_CURRENT_LANGUAGE_CHANGE"
LocalizationModel.ON_CURRENT_AUDIO_LANGUAGE_CHANGE = "ON_CURRENT_AUDIO_LANGUAGE_CHANGE"

--[[
    语言选择面板LocalSave Key
]]
LocalizationModel.LANSAVEKEY = {
	Txt = "CurTxtLanguage",
	Radio = "CurAudioCulture",
}

--[[
	本地化文本/资产支持的列表

	UE中的文化包含特定区域的国际化信息。文化名称由三个连字符隔开的部分组成（一个IETF语言标签：
	一个2字母ISO 639-1语言代码（如"zh"）
	一个可选的4字母ISO 15924脚本代码（如"Hans"）
	一个可选的2字母ISO 3166-1国家代码（如"CN"）。
]]
LocalizationModel.IllnLanguageSupportEnum = {
	zhHans = "zh-Hans",
	enUS = "en-US",
	jaJP = "ja-JP",
	zhHant = "zh-Hant",
}
--[[
	本地化语音支持的文化列表（wwise）
]]
LocalizationModel.IllnAudioCultureSupportEnum = {
	Chinese = "Chinese",
	English = "English(US)",
	Japanese = "Japanese",
}

LocalizationModel.BaseIllnLanguage2Index = {
	[LocalizationModel.IllnLanguageSupportEnum.zhHans] = 2,
	[LocalizationModel.IllnLanguageSupportEnum.enUS] = 0,
	[LocalizationModel.IllnLanguageSupportEnum.jaJP] = 1,
	[LocalizationModel.IllnLanguageSupportEnum.zhHant] = 3,
}
LocalizationModel.VoiceIllnLanguage2Index = {
	[LocalizationModel.IllnAudioCultureSupportEnum.Chinese] = 2,
	[LocalizationModel.IllnAudioCultureSupportEnum.English] = 0,
	[LocalizationModel.IllnAudioCultureSupportEnum.Japanese] = 1,
}


LocalizationModel.BaseTestIllnLanguage2Index = {
	[LocalizationModel.IllnLanguageSupportEnum.zhHans] = 1,
	[LocalizationModel.IllnLanguageSupportEnum.enUS] = 2,
	[LocalizationModel.IllnLanguageSupportEnum.zhHant] = 0,
}

LocalizationModel.VoiceTestIllnLanguage2Index = {
	[LocalizationModel.IllnAudioCultureSupportEnum.Chinese] = 0,
	[LocalizationModel.IllnAudioCultureSupportEnum.English] = 1,
}


function LocalizationModel:__init()
    self:DataInit()
end

function LocalizationModel:DataInit()
	--[[
		语言选择面板
		{
			CurTxtLanguage = "zh-Hans",
			CurAudioCulture = "Chinese"
		}
	]]
	self.CurLanData = nil

	--[[
		本地化文本/资产支持的列表
		@param MatchFlag 表示匹配规则，例如如果本地文化是zh-Hans-CN，也将匹配到zh-Hans
		@param AudioCulture 表示对应的语音文化类型
		@param IsSupportMatch   当前是否支持匹配  为false情况下，不会进行初始化匹配
	]]
	self.IllnLanguageList = {
		[LocalizationModel.IllnLanguageSupportEnum.zhHans] = {
			MatchFlag = "zh-Hans",
			AudioCulture = LocalizationModel.IllnAudioCultureSupportEnum.Chinese,
			ShowIndex = 1,
			IsSupportMatch = true,
		},
		[LocalizationModel.IllnLanguageSupportEnum.enUS] = {
			MatchFlag = "en",
			AudioCulture = LocalizationModel.IllnAudioCultureSupportEnum.English,
			IsSupportMatch = true,
		},
		[LocalizationModel.IllnLanguageSupportEnum.jaJP] = {
			MatchFlag = "ja",
			AudioCulture = LocalizationModel.IllnAudioCultureSupportEnum.Japanese,
			IsSupportMatch = true,
		},
		[LocalizationModel.IllnLanguageSupportEnum.zhHant] = {
			MatchFlag = "zh-Hant",
			AudioCulture = LocalizationModel.IllnAudioCultureSupportEnum.Chinese,
			IsSupportMatch = false,
		},
	}
	self.IllnLanguageDefalutFix = LocalizationModel.IllnLanguageSupportEnum.enUS
	--[[
		本地化语音支持的文化列表（wwise）
	]]
	self.IllnAudioCultureList = {
		[LocalizationModel.IllnAudioCultureSupportEnum.Chinese] = {},
		[LocalizationModel.IllnAudioCultureSupportEnum.English] = {},
		[LocalizationModel.IllnAudioCultureSupportEnum.Japanese] = {},
	}

	--每个语音语言对应的文化类型，方便一些资产跟随语音去变化资产路径
	self.IllnAudioCulture2IllnLanguage = {}
	for k,v in pairs(self.IllnLanguageList) do
		if v.IsSupportMatch then
			self.IllnAudioCulture2IllnLanguage[v.AudioCulture] = k
		end
	end

	self.LanguageSupport2SeverLangType = {}
	for k,v in pairs(LocalizationModel.IllnLanguageSupportEnum) do
		self.LanguageSupport2SeverLangType[v] = k
	end

	self.SettingIndex2LanguageBase = {}
	for k,v in pairs(LocalizationModel.BaseIllnLanguage2Index) do
		self.SettingIndex2LanguageBase[v] = k
	end
	self.SettingIndex2LanguageBaseTest = {}
	for k,v in pairs(LocalizationModel.BaseTestIllnLanguage2Index) do
		self.SettingIndex2LanguageBaseTest[v] = k
	end

	self.SettingIndex2Voice = {}
	for k,v in pairs(LocalizationModel.VoiceIllnLanguage2Index) do
		self.SettingIndex2Voice[v] = k
	end
	self.SettingIndex2VoiceTest = {}
	for k,v in pairs(LocalizationModel.VoiceTestIllnLanguage2Index) do
		self.SettingIndex2VoiceTest[v] = k
	end

	---文本id对应的多语言
	self.TextId2MultiLanguage = nil


	--路径到本地化路径的映射表
	self.Path2LocalizationPathByCulture = {}
	self.Path2LocalizationPathByAudio = {}
end

--[[
	本地化文化发生改变时
]]
function LocalizationModel:ON_CULTURE_INIT_Func()
	self.Path2LocalizationPathByCulture = {}
end
function LocalizationModel:OnAudioLanguageChange()
	CWaring("LocalizationModel:OnAudioLanguageChange")
	self.Path2LocalizationPathByAudio = {}
	self.CurAudioLanguage2Culture = self.IllnAudioCulture2IllnLanguage[self:GetCurSelectAudioLanguage()]
	if not self.CurAudioLanguage2Culture then
		CWaring("LocalizationModel:OnAudioLanguageChange Fix CurAudioLanguage2Culture")
		self.CurAudioLanguage2Culture = LocalizationModel.IllnLanguageSupportEnum.enUS
	end
	--TODO 设置相关属于语音的组资源
	--SetCurrentAssetGroupCulture(const FName AssetGroup, const FString& Culture, const bool SaveToConfig = false);
	CWaring("self.CurAudioLanguage2Culture:" .. self.CurAudioLanguage2Culture)
	UE.UKismetInternationalizationLibrary.SetCurrentAssetGroupCulture("Audio",self.CurAudioLanguage2Culture,true)
end

function LocalizationModel:GetMultiLanguageByTextId(InTextId, InLanuage)
	if not self.TextId2MultiLanguage or not self.TextId2MultiLanguage[InTextId] or not self.TextId2MultiLanguage[InTextId][InLanuage] then
		return nil
	end
	return self.TextId2MultiLanguage[InTextId][InLanuage]
end

function LocalizationModel:SetMultiLanguageByTextId(InTextId, InLanuage, InText)
	self.TextId2MultiLanguage = self.TextId2MultiLanguage or {}
	self.TextId2MultiLanguage[InTextId] = self.TextId2MultiLanguage[InTextId] or {}
	self.TextId2MultiLanguage[InTextId][InLanuage] = InText
end

--[[
	游戏开启时，初始当前本地化文及本地化语音

	由 LocalizationCtrl 触发
]]
function LocalizationModel:InitLanguageSetting()
	local OldLocalCurrentLanguage = UE.UKismetInternationalizationLibrary.GetCurrentLanguage()
	self:CheckCurLanInit()

	if OldLocalCurrentLanguage ~= self.CurLanData.CurTxtLanguage then
		CWaring("LocalizationModel:InitLanguageSetting OldLanguage:" .. OldLocalCurrentLanguage .. "|NewLanguage:" .. self.CurLanData.CurTxtLanguage)
	end

	self:SyncCurrentLanguage()
	self:SyncCurrentAudioCulture()
	self:OnAudioLanguageChange()
	if OldLocalCurrentLanguage == self.CurLanData.CurTxtLanguage then
		CWaring("LocalizationModel:InitLanguageSetting Language same So Triiger ON_CULTURE_INIT:" .. self.CurLanData.CurTxtLanguage)
		MvcEntry:SendMessage(CommonEvent.ON_CULTURE_INIT)
	else
		if not self:IsInternationalizationEnabled() then
			MvcEntry:SendMessage(CommonEvent.ON_CULTURE_INIT)
		end
	end
end


function LocalizationModel:IsInternationalizationEnabled()
	local WorldTypeFlag = UE.UGFUnluaHelper.GetWorldTypeFlag(GameInstance)
	if WorldTypeFlag == WorldTypeEnum.PIE then
		return false
	end
	return true
end


function LocalizationModel:SyncCurrentLanguage(CheckEnv)
    -- local WorldTypeFlag = UE.UGFUnluaHelper.GetWorldTypeFlag(GameInstance)
    -- CWaring("LocalizationModel WorldTypeFlag:" .. WorldTypeFlag)
	-- if WorldTypeFlag == WorldTypeEnum.PIE then
    --     if CheckEnv then
    --         UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_LocalizationModel_PleaseuseStandalonem") .. WorldTypeFlag)
    --     end
	-- 	return
	-- end
	if not self:IsInternationalizationEnabled() then
		if CheckEnv then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_LocalizationModel_PleaseuseStandalonem"))
        end
		return
	end
	UE.UKismetInternationalizationLibrary.SetCurrentLanguage(self.CurLanData.CurTxtLanguage,true)
end
function LocalizationModel:SyncCurrentAudioCulture()
	CWaring("self.CurLanData.CurAudioCulture:" .. self.CurLanData.CurAudioCulture)
	UE.UGTSoundStatics.SetAudioCulture(GameInstance,self.CurLanData.CurAudioCulture)
end


--[[
	获取当前的语言类型  根据匹配规则  转换到当前支持的语言类型
]]
function LocalizationModel:ConvertCurrentLanguage2SupportLanguage(HideFixAction)
	local SupportLanguage = nil
	local CurrentLanguage = UE.UKismetInternationalizationLibrary.GetCurrentLanguage()

	for Language,v in pairs(self.IllnLanguageList) do
		if v.IsSupportMatch then
			if CurrentLanguage == Language then
				SupportLanguage = CurrentLanguage
				break
			else
				local MatchFlag = v.MatchFlag
				if string.sub(CurrentLanguage,1,string.len(MatchFlag)) == MatchFlag then
					SupportLanguage = Language
					break
				end
			end
		end
	end

	if not SupportLanguage then
		CError("LocalizationModel:ConvertCurrentLanguage2SupportLanguage CurrentLanguage not Support:" .. CurrentLanguage,true)
		if not HideFixAction then
			SupportLanguage = self.IllnLanguageDefalutFix
		end
	else
		CWaring(StringUtil.FormatSimple("LocalizationModel:ConvertCurrentLanguage2SupportLanguage {0} to {1}",CurrentLanguage,SupportLanguage))
	end
	return SupportLanguage
end

function LocalizationModel:CheckCurLanInit()
	if not self.CurLanData then
		self.CurLanData = {}
		self.CurLanData.CurTxtLanguage = SaveGame.GetItem(self.LANSAVEKEY.Txt, true)

		if not self.CurLanData.CurTxtLanguage or not self.IllnLanguageList[self.CurLanData.CurTxtLanguage] then
			--TODO 如果为空/为当前不支持的类型，则需要重新计算
			local CurTxtLanguage = self:ConvertCurrentLanguage2SupportLanguage()

			--针对TBT测试  强制将文化检测关掉，走默认文化
			-- local CurTxtLanguage = self.IllnLanguageDefalutFix
			-- SaveGame.SetItem(self.LANSAVEKEY.Txt,self.CurLanData.CurTxtLanguage, true)
			self:SetCurSelectLanTxtLanguage(CurTxtLanguage,false,true)
		end

		self.CurLanData.CurAudioCulture = SaveGame.GetItem(self.LANSAVEKEY.Radio, true)
		if not self.CurLanData.CurAudioCulture or not self.IllnAudioCultureList[self.CurLanData.CurAudioCulture] then
			--TODO 如果为空/为当前不支持的类型，则需要重新计算
			local CurTxtLanguageInfo = self.IllnLanguageList[self.CurLanData.CurTxtLanguage]
			local CurAudioCulture = CurTxtLanguageInfo.AudioCulture
			-- SaveGame.SetItem(self.LANSAVEKEY.Radio,self.CurLanData.CurAudioCulture, true)
			self:SetCurSelectLanRadioCulture(CurAudioCulture,false,true)
		end
		CWaring("LocalizationModel:CheckCurLanInit CurLanguage is:" .. self.CurLanData.CurTxtLanguage)
		CWaring("LocalizationModel:CheckCurLanInit CurAudioCulture is:" .. self.CurLanData.CurAudioCulture)
	end
end


function LocalizationModel:ConvertSettingIndex2LanguageBase(Index)
	return self.SettingIndex2LanguageBase[Index]
end
function LocalizationModel:ConvertSettingIndex2LanguageBaseTest(Index)
	return self.SettingIndex2LanguageBaseTest[Index]
end

function LocalizationModel:ConvertSettingIndex2Voice(Index)
	return self.SettingIndex2Voice[Index]
end
function LocalizationModel:ConvertSettingIndex2VoiceTest(Index)
	return self.SettingIndex2VoiceTest[Index]
end


--设置当前选中语言项索引
function LocalizationModel:SetCurSelectLanTxtLanguage(Language,DoAction,IsInit,ForceAppaySetting)
	if not IsInit then
		self:CheckCurLanInit()
	end
	if not Language then
		CWaring("LocalizationModel:SetCurSelectLanTxtLanguage Language nil")
		return
	end
	local Old = self.CurLanData.CurTxtLanguage
	if Old and Old == Language then
		CWaring("LocalizationModel:SetCurSelectLanTxtLanguage Language same break")
		return
	end
	self.CurLanData.CurTxtLanguage = Language
	-- CWaring("LocalizationModel2 OldLanguage2:" .. Old .. "|NewLanguage2:" .. self.CurLanData.CurTxtLanguage)
	SaveGame.SetItem(self.LANSAVEKEY.Txt, Language,true)

	if IsInit or ForceAppaySetting then
		local SettingSubsystem = UE.UGenericSettingSubsystem.Get(GameInstance)

		local NewSettingValue = UE.FSettingValue()
		NewSettingValue.Value_Int = LocalizationModel.BaseIllnLanguage2Index[Language]
		local TabTag  = UE.FGameplayTag()
		TabTag.TagName ="Setting.Language"
		-- CWaring("LocalizationModel NewSettingValue.Value_Int:" .. NewSettingValue.Value_Int)
		SettingSubsystem:ForceApplySetting("Setting.Language.Base",NewSettingValue,TabTag)

		if LocalizationModel.BaseTestIllnLanguage2Index[Language] then
			local NewSettingValue2 = UE.FSettingValue()
			NewSettingValue2.Value_Int = LocalizationModel.BaseTestIllnLanguage2Index[Language]
			-- CWaring("LocalizationModel NewSettingValue2.Value_Int:" .. NewSettingValue2.Value_Int)
			SettingSubsystem:ForceApplySetting("Setting.Language.Base.Test",NewSettingValue2,TabTag)
		end
	end

	if DoAction then
		self:SyncCurrentLanguage(true)
	end
	if Old ~= self.CurLanData.CurTxtLanguage then
		CWaring("LocalizationModel OldLanguage2:" .. (Old or "") .. "|NewLanguage2:" .. self.CurLanData.CurTxtLanguage)
		self:DispatchType(LocalizationModel.ON_CURRENT_LANGUAGE_CHANGE)
		return true
	end
	return false
end
--设置当前选中语音项索引
function LocalizationModel:SetCurSelectLanRadioCulture(Culture,DoAction,IsInit,ForceAppaySetting)
	if not IsInit then
		self:CheckCurLanInit()
	end
	if not Culture then
		CWaring("LocalizationModel:SetCurSelectLanRadioCulture Culture nil")
		return
	end
	local Old = self.CurLanData.CurAudioCulture
	if Old and Old == Culture then
		CWaring("LocalizationModel:SetCurSelectLanRadioCulture Culture same break")
		return
	end
	self.CurLanData.CurAudioCulture = Culture
	SaveGame.SetItem(self.LANSAVEKEY.Radio, Culture,true)

	
	if IsInit or ForceAppaySetting then
		local SettingSubsystem = UE.UGenericSettingSubsystem.Get(GameInstance)
		
		local NewSettingValue = UE.FSettingValue()
		NewSettingValue.Value_Int = LocalizationModel.VoiceIllnLanguage2Index[Culture]
		local TabTag  = UE.FGameplayTag()
		TabTag.TagName ="Setting.Language"
		SettingSubsystem:ForceApplySetting("Setting.Language.Voice",NewSettingValue,TabTag)

		if LocalizationModel.VoiceTestIllnLanguage2Index[Culture] then
			local NewSettingValue2 = UE.FSettingValue()
			NewSettingValue2.Value_Int = LocalizationModel.VoiceTestIllnLanguage2Index[Culture]
			SettingSubsystem:ForceApplySetting("Setting.Language.Voice.Test",NewSettingValue2,TabTag)
		end
	end


	if DoAction then
		self:SyncCurrentAudioCulture()
	end
	if Old ~= self.CurLanData.CurAudioCulture then
		CWaring("LocalizationModel OldRadioCulture2:" .. (Old or "") .. "|NewRadioCulture2:" .. self.CurLanData.CurAudioCulture)
		self:DispatchType(LocalizationModel.ON_CURRENT_AUDIO_LANGUAGE_CHANGE)
		self:OnAudioLanguageChange()
		return true
	end
	return false
end
function LocalizationModel:GetCurSelectLanData()
	self:CheckCurLanInit()
	return self.CurLanData
end

--[[
	获取当前本地化生效语言类型
]]
function LocalizationModel:GetCurSelectLanguage()
	self:CheckCurLanInit()
	if self.CurLanData then
		return self.CurLanData.CurTxtLanguage
	end
end

--[[
	获取当前语音生效语言类型
]]
function LocalizationModel:GetCurSelectAudioLanguage()
	self:CheckCurLanInit()
	if self.CurLanData then
		return self.CurLanData.CurAudioCulture
	end
end

--[[
	获取创角时，服务器需要的语言类型参数
]]
function LocalizationModel:GetCurSelectLanguageServer()
	local CurTxtLanguage = self:GetCurSelectLanguage()
	if CurTxtLanguage and self.LanguageSupport2SeverLangType[CurTxtLanguage] then
		return self.LanguageSupport2SeverLangType[CurTxtLanguage]
	end
	return ""
end

--[[
	转换路径到对应本地化路径下，根据当前选中 语音语言类型
]]
function LocalizationModel:ConvertPath2LocalizationPathByAudio(Path)
	if not self.Path2LocalizationPathByAudio[Path] then
		local FixPath = string.gsub(Path,"/Game/",StringUtil.FormatSimple("{0}{1}/","/Game/L10N/",self.CurAudioLanguage2Culture))
		if UE.UGFUnluaHelper.IsPackageExist(FixPath) then
			CWaring("LocalizationModel:ConvertPath2LocalizationPathByAudio Path Suc:" .. FixPath)
			self.Path2LocalizationPathByAudio[Path] = FixPath
		else
			CWaring("LocalizationModel:ConvertPath2LocalizationPathByAudio Path Not Exist:" .. FixPath)
			self.Path2LocalizationPathByAudio[Path] = Path
		end
	end
	return self.Path2LocalizationPathByAudio[Path]
end

--[[
	转换路径到对应本地化路径下，根据当前选中 文本语言类型
]]
function LocalizationModel:ConvertPath2LocalizationPathByCulture(Path)
	if not self.Path2LocalizationPathByCulture[Path] then
		local CurLanguageCulture = self:GetCurSelectLanguage()
		local FixPath = string.gsub(Path,"/Game/",StringUtil.FormatSimple("{0}{1}/","/Game/L10N/",CurLanguageCulture))
		if UE.UGFUnluaHelper.IsPackageExist(FixPath) then
			CWaring("LocalizationModel:ConvertPath2LocalizationPathByCulture Path Suc:" .. FixPath)
			self.Path2LocalizationPathByCulture[Path] = FixPath
		else
			CWaring("LocalizationModel:ConvertPath2LocalizationPathByCulture Path Not Exist:" .. FixPath)
			self.Path2LocalizationPathByCulture[Path] = Path
		end
	end
	return self.Path2LocalizationPathByCulture[Path]
end


return LocalizationModel