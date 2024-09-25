require("Client.Modules.Localization.LocalizationModel")

--[[
    本地化相关处理
]]
local class_name = "LocalizationCtrl"
---@class LocalizationCtrl : UserGameController
---@field private model UserModel
LocalizationCtrl = LocalizationCtrl or BaseClass(UserGameController,class_name)


function LocalizationCtrl:__init()
    self.Model = nil
    self.IsLocalizationInit = false
    self.JobManager = nil
end

function LocalizationCtrl:__dispose()
	self.JobManager:Dispose()
end

function LocalizationCtrl:Initialize()
    self.Model = self:GetModel(LocalizationModel)
    ---@type LocalizationTextJobManager
    self.JobManager = require("Client.Modules.Localization.LocalizationTextJobManager").New()
end


function LocalizationCtrl:AddMsgListenersUser()
    self.MsgList = {
        { Model = nil, MsgName = CommonEvent.ON_CULTURE_INIT,    Func = self.ON_CULTURE_INIT_Func ,Priority = 1},
        { Model = nil, MsgName = CommonEvent.ON_GAME_INIT_BEFORE,    Func = self.ON_GAME_INIT_BEFORE },
    }

    self.MsgListGMP = {
        { InBindObject = _G.MainSubSystem,	MsgName = "Setting.Language.Base",Func = Bind(self,self.OnBaseLanguageUpdate), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = "Setting.Language.Base.Test",Func = Bind(self,self.OnBaseTestLanguageUpdate), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = "Setting.Language.Voice",Func = Bind(self,self.OnVoiceLanguageUpdate), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = "Setting.Language.Voice.Test",Func = Bind(self,self.OnVoiceTestLanguageUpdate), bCppMsg = true, WatchedObject = nil },
    }

    self.ProtoList = {
        {MsgName = Pb_Message.GetTextIdMultiLanguageContentRsp,	Func = self.TextIdMultiLanguageContentRsp_Func },
	}
end

function LocalizationCtrl:TextIdMultiLanguageContentRsp_Func(Msg)
    print_r(Msg, "LocalizationCtrl:TextIdMultiLanguageContentRsp_Func")
    self.Model:SetMultiLanguageByTextId(Msg.TextId, Msg.LanguageType, Msg.Content)
    self.JobManager:SyncJob(Msg.TextId, Msg.Content)
end

function LocalizationCtrl:GetMultiLanguageContentByTextId(InTextId, InLanguageCallBack)
    print("LocalizationCtrl:GetMultiLanguageContentByTextId", InTextId)
    local LocalLanuage = self.Model:GetCurSelectLanguage()
    local Str = self.Model:GetMultiLanguageByTextId(InTextId, LocalLanuage)
    if Str then
        if InLanguageCallBack then
            InLanguageCallBack(Str)
        end
        return
    end

    if not self.JobManager:IsJobWorking(InTextId) then
        local Msg = {
            TextId = InTextId,
            LanguageType = LocalLanuage,
        }
        self:SendProto(Pb_Message.GetTextIdMultiLanguageContentReq,Msg,Pb_Message.GetTextIdMultiLanguageContentRsp)
    end
    self.JobManager:HandleJob(InTextId, InLanguageCallBack)
end

--[[
    本地化发生变化，需要清除本地相关文本cache
]]
function LocalizationCtrl:ON_CULTURE_INIT_Func()
    --TODO 需要清除本地化相关的cache
    G_ConfigHelper:OnCurrentLanguageChange();
    self.Model:ON_CULTURE_INIT_Func()
end

--[[
    在ON_GAME_INIT之前调用，触发多语言初始化
]]
function LocalizationCtrl:ON_GAME_INIT_BEFORE()
    self.Model:InitLanguageSetting()
    self.IsLocalizationInit = true
end

function LocalizationCtrl:OnBaseLanguageUpdate(_,SettingValue)
    if not self.IsLocalizationInit then
        CWaring("LocalizationCtrl:OnBaseLanguageUpdate IsLocalizationInit false,Break")
        return
    end
    local Index = SettingValue.Value_Int
    CWaring("LocalizationCtrl:OnBaseLanguageUpdate:" .. Index)
    local Language = self.Model:ConvertSettingIndex2LanguageBase(Index)
    local IsChange = self.Model:SetCurSelectLanTxtLanguage(Language,true)
    if IsChange then
        self:PopLocalizationChangeMessageBox()
    end
end
function LocalizationCtrl:OnBaseTestLanguageUpdate(_,SettingValue)
    if not self.IsLocalizationInit then
        CWaring("LocalizationCtrl:OnBaseLanguageUpdate IsLocalizationInit false,Break")
        return
    end
    local Index = SettingValue.Value_Int
    CWaring("LocalizationCtrl:OnBaseTestLanguageUpdate:" .. Index)
    local Language = self.Model:ConvertSettingIndex2LanguageBaseTest(Index)
    local IsChange = self.Model:SetCurSelectLanTxtLanguage(Language,true)
    if IsChange then
        self:PopLocalizationChangeMessageBox()
    end
end

function LocalizationCtrl:OnVoiceLanguageUpdate(_,SettingValue)
    if not self.IsLocalizationInit then
        CWaring("LocalizationCtrl:OnBaseLanguageUpdate IsLocalizationInit false,Break")
        return
    end
    local Index = SettingValue.Value_Int
    CWaring("LocalizationCtrl:OnVoiceLanguageUpdate:" .. Index)
    local Culture = self.Model:ConvertSettingIndex2Voice(Index)
    local IsChange = self.Model:SetCurSelectLanRadioCulture(Culture,true)
    if IsChange then
        self:PopLocalizationChangeMessageBox()
    end
end
function LocalizationCtrl:OnVoiceTestLanguageUpdate(_,SettingValue)
    if not self.IsLocalizationInit then
        CWaring("LocalizationCtrl:OnBaseLanguageUpdate IsLocalizationInit false,Break")
        return
    end
    local Index = SettingValue.Value_Int
    CWaring("LocalizationCtrl:OnVoiceTestLanguageUpdate:" .. Index)
    local Culture = self.Model:ConvertSettingIndex2VoiceTest(Index)
    local IsChange = self.Model:SetCurSelectLanRadioCulture(Culture,true)
    if IsChange then
        self:PopLocalizationChangeMessageBox()
    end
end

--[[
    弹窗提示，需要重启游戏，才能使本地化生效
]]
function LocalizationCtrl:PopLocalizationChangeMessageBox()
    -- if self:GetModel(ViewModel):GetState(ViewConst.MessageBox) then
    --     return
    -- end
    -- local msgParam = {
    --     describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_LocalizationSettingMdt_Localizedcontentcant")),
    --     leftBtnInfo = {
    --         name = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_LocalizationSettingMdt_Restartlater"),
    --         callback = function()
    --         end
    --     },
    --     rightBtnInfo = {
    --         name = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_LocalizationSettingMdt_Restartimmediately"),
    --         callback = function()
    --             --TODO 关闭游戏
    --             UE.UKismetSystemLibrary.QuitGame(GameInstance,CommonUtil.GetLocalPlayerC(),UE.EQuitPreference.Quit,true)
    --         end
    --     }
    -- }
    -- UIMessageBox.Show(msgParam)

    --TODO 现文本及语音及口型资产可即时生效，不再需要提示重启游戏
end

