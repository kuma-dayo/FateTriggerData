--[[GMPanel数据模型]]
local super = GameEventDispatcher;
local class_name = "GMPanelModel";
---@class GMPanelModel : GameEventDispatcher
GMPanelModel = BaseClass(super, class_name);

GMPanelModel.GMConfig = require("GMConfig") --暂时兼容下GMConfig

function GMPanelModel:__init()
    --self:DataInit()

    self.GMList = {}
    self.GMListDirty = true
    self.RowNum = 5
    self.ColumnNum = 5
    self.CurrentTagIndex = 1
    self.CurrentDropdownCmdBtnTable = {}
end

function GMPanelModel:__dispose()
    
end

function GMPanelModel:OnGameInit()
    self:DataInit()
end

function GMPanelModel:DataInit()
    self:GMConfigDataInit()
end

--暂时兼容下GMConfig
function GMPanelModel:GMConfigDataInit()
    self.ETagType = self.GMConfig.ETagType
    self.NetProfile = self.GMConfig.NetProfile
    self.StatProfile = self.GMConfig.StatProfile
    self.CmdTagTable = self.GMConfig.CmdTagTable
    self.DropdownCmdList = self.GMConfig.DropdownCmdList

    self.CustomGMList = {
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_OutdierSocketReconnect",["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Offsitedisconnection"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_OutdierSocketReconnect),["Examples"] = {G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Afteristurnedonyouca")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_TestAchieve",["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Achievementtest"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_OpenTestAchieve),["Examples"] = {G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Loginafteropeningwil")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_RandomAddAchieve",["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_AddAchievements"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_RandomAddAchieve),["Examples"] = {G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Randomlyaddachieveme")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_OpenSettleRandomAchieve",["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Settlementsinglemach"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_OpenSettleRandomAchieve),["Examples"] = {G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Openthesettlementpan")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_CustomIpInput",["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_CustomizetheserverIP"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_CustomIpInput),["Examples"] = {G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Afteropeningyoucanen")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_OpenGuide",["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_OpenGuide"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_OpenGuide),["Examples"] = {G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_OpenGuideDesc")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_CompleteGuide",["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_CompleteGuide"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_CompleteGuide),["Examples"] = {G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_CompleteGuide")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_OpenModeSelectServerList",["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("CustomGMCMD_OpenModeSelectServerList"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_OpenModeSelectServerList),["Examples"] = {G_ConfigHelper:GetStrFromCommonStaticST("CustomGMCMD_OpenModeSelectServerList")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_TestLocalizationPluralForms",["Text"] = G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","CustomGMCMD_TestLocalizationPluralForms"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_TestLocalizationPluralForms),["Examples"] = {G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","CustomGMCMD_TestLocalizationPluralExample")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_ReadKeyValueFromDataTable",["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("CustomGMCMD_ReadKeyValueFromDataTable"),["ExcuteFunc"] = Bind(self,self.CustomGMCMD_ReadKeyValueFromDataTable),["Examples"] = {G_ConfigHelper:GetStrFromCommonStaticST("CustomGMCMD_ReadValueFromSTExample")}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_Loading",["Text"] = "模拟Loading",["ExcuteFunc"] = Bind(self,self.CustomGMCMD_Loading),["Examples"] = {"0#1001#101#1#0#0#10"," 阶段值#模式ID#地图ID#等级#对局次数#结算排名#超时时间"}},
        {["OutSider"] = true,["Cmd"] = "CustomGMCMD_ShowGVoiceUrl",["Text"] = "查看GVoiceUrl",["ExcuteFunc"] = Bind(self,self.CustomGMCMD_ShowGVoiceUrl),["Examples"] = {""}},
    }
    self.CustomGMKeyMap = nil
end

function GMPanelModel:SetGMListData(InGMListData)
    --[[
        string ShowName = 1;    // 在客户端显示的Gm指令名称
        string FuncName = 2;    // 执行函数名称
        repeated string Examples = 3; // 参数举例说明，可能多个
    ]]
    self.GMList = {}
    self.GMListDirty = true
    for _, GmInfo in pairs(InGMListData.GmListInfo) do
        --self.GMList[Index] = {["Text"] = GmInfo.ShowName, ["Cmd"] = GmInfo.FuncName}
        table.insert(self.GMList, {["Text"] = GmInfo.ShowName, ["Cmd"] = GmInfo.FuncName, ["Examples"] = GmInfo.Examples,["OutSider"] = true})
    end
end

function GMPanelModel:GetGMListData()
    --测试
    if not self.GMList or #self.GMList < 1 then
        table.insert(self.GMList, {["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Initialize"), ["Cmd"] = "GSDKHelper Init", ["Examples"] = {"servercmd stat startfile"}})
        table.insert(self.GMList, {["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Login"), ["Cmd"] = "GSDKHelper Login", ["Examples"] = {"servercmd stat LoginIn"}})
        table.insert(self.GMList, {["Text"] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Logout"), ["Cmd"] = "GSDKHelper Logout", ["Examples"] = {"servercmd stat LoginOut"}})
    end
    if self.GMListDirty then
        self.GMListDirty = false

        self.GMList = ListMerge(self.GMList,self.CustomGMList)
    end
    return self.GMList
end

function GMPanelModel:MontageStr(InStrTable)
    local ResultStr = ""
    for _, Str in pairs(InStrTable) do
        ResultStr = ResultStr .. Str
    end
    return ResultStr
end

function GMPanelModel:GetGMListLenth()
    return #self.GMList
end

function GMPanelModel:GetCustomGMByCmd(Cmd)
    if not self.CustomGMKeyMap then
        self.CustomGMKeyMap = {}
        for k,v in pairs(self.CustomGMList) do
            self.CustomGMKeyMap[v["Cmd"]] = v
        end
    end
    return self.CustomGMKeyMap[Cmd] or nil
end

function GMPanelModel:CustomGMCMD_OutdierSocketReconnect()
    MvcEntry:GetCtrl(UserSocketLoginCtrl):SetIsOpenGMReconnect(true) 
    UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Setsuccessfully"))
end
function GMPanelModel:CustomGMCMD_OpenTestAchieve()
    MvcEntry:GetCtrl(AchievementCtrl).test = true
    UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_GMPanelModel_Setsuccessfully"))
end
function GMPanelModel:CustomGMCMD_RandomAddAchieve()
    MvcEntry:GetCtrl(AchievementCtrl).test = true
    MvcEntry:GetCtrl(AchievementCtrl):SettlementDataTest()
end
function GMPanelModel:CustomGMCMD_OpenSettleRandomAchieve()
    MvcEntry:GetCtrl(AchievementCtrl).test = true
    MvcEntry:GetCtrl(AchievementCtrl):SettlementDataTest(true)
    MvcEntry:GetCtrl(AchievementCtrl):TestSettlementView()
end

function GMPanelModel:CustomGMCMD_CustomIpInput()
    local CustomIpInputSwitch = MvcEntry:GetModel(LoginModel):GetCustomIpInputSwitch()
    MvcEntry:GetModel(LoginModel):SetCustomIpInputSwitch(not CustomIpInputSwitch)
end

function GMPanelModel:CustomGMCMD_OpenGuide()
    MvcEntry:GetCtrl(GuideCtrl):SetGMGuideOpenState(true)
end

function GMPanelModel:CustomGMCMD_CompleteGuide()
    MvcEntry:GetCtrl(GuideCtrl):SetGMCompleteGuide()
end

function GMPanelModel:CustomGMCMD_OpenModeSelectServerList()
    MvcEntry:GetCtrl(MatchModeSelectCtrl):SetOpenModeSelectServerList()
end

--[[
    读取Table的Value值
]]
function GMPanelModel:CustomGMCMD_ReadKeyValueFromDataTable(InInputText)
    local ResultInputStrArr = {}
    for SubStr in InInputText:gmatch("%S+") do
        table.insert(ResultInputStrArr, SubStr)
    end

    if #ResultInputStrArr < 2 then
        UIAlert.Show("缺少表参数!!")
        return
    end

    local TableName = ResultInputStrArr[2]

    if #ResultInputStrArr == 2 then
        --走读取StringTable
        local InStrTableKey = StringUtil.FormatSimple("/Game/DataTable/UIStatic/Text_OutsideGame/{0}.{0}", TableName)
        local STIsReg = UE.UKismetStringTableLibrary.IsRegisteredTableId(InStrTableKey)
        if not STIsReg then
            InStrTableKey = StringUtil.FormatSimple("/Game/DataTable/UIStatic/{0}.{0}", TableName)
            STIsReg = UE.UKismetStringTableLibrary.IsRegisteredTableId(InStrTableKey)
            if not STIsReg then
                InStrTableKey = StringUtil.FormatSimple("/Game/DataTable/UIStatic/Text_InsideGame/{0}.{0}", TableName)
                STIsReg = UE.UKismetStringTableLibrary.IsRegisteredTableId(InStrTableKey)
            end
        end

        if not STIsReg then
            UIAlert.Show(StringUtil.Format("未找到表{0}!!!", TableName))
            return
        end

        print(StringUtil.Format("=========Check Table {0} KeysValues Start========>", InInputText))
        local Keys = UE.UKismetStringTableLibrary.GetKeysFromStringTable(InStrTableKey)
        for _, Key in pairs(Keys) do
            local StrTableValue = UE.UKismetTextLibrary.TextFromStringTable(InStrTableKey, Key)
            print(StringUtil.Format("key:{0}, value:{1}", Key, StrTableValue))
        end

    else
        --走读取DataTable
        print(StringUtil.Format("=========Check Table {0} KeysValues========>", TableName))
        local CfgName = TableName
        local KeyName = ResultInputStrArr[3]
        local InCfgData = G_ConfigHelper.Helper:ReadConfig(CfgName, KeyName, false)
        for _, SubCfgData in pairs(InCfgData) do
            print(StringUtil.Format("value:{0}", SubCfgData[KeyName]))
        end
    end

    print(StringUtil.Format("=========Check Table {0} KeysValues End========>", InInputText))
end


-- 本地化单复数验证
function GMPanelModel:CustomGMCMD_TestLocalizationPluralForms(OriginText)
    if not OriginText or OriginText == "" then
        return
    end
    local TextList = string.split(OriginText,'#')
    if TextList and #TextList > 0 then
        local TempStr = TextList[1]
        table.remove(TextList,1)
        for I,Param in ipairs(TextList) do
            if tonumber(TextList[I]) then
                TextList[I] = tonumber(TextList[I])
            end
        end
        local ResultStr = StringUtil.Format(TempStr,table.unpack(TextList))
        UIAlert.Show(ResultStr)
    end
end

--[[
    模拟Loading展示GM
]]
function GMPanelModel:CustomGMCMD_Loading(OriginText)
    if not OriginText or OriginText == "" then
        return
    end
    local TextList = string.split(OriginText,'#')
    if TextList and #TextList > 0 then
        local TypeEnum = tonumber(TextList[1])
        local ModeId = tonumber(TextList[2])
        local SceneId = tonumber(TextList[3])
        local Level = tonumber(TextList[4])
        local BattleTime = tonumber(TextList[5])
        local SettlementRankIndex = tonumber(TextList[6])
        local Timeout = tonumber(TextList[7])

        local EnterFunc = function()
        end
        local LoadingShowParam = {
            TypeEnum = TypeEnum,
            ModeId = ModeId,
            SceneId = SceneId,
            Level = Level,
            BattleTime = BattleTime,
            SettlementRankIndex = SettlementRankIndex,
        }
        MvcEntry:GetCtrl(LoadingCtrl):ReqLoadingScreenShow(LoadingShowParam,EnterFunc)
        Timer.InsertTimer(Timeout,function ()
            UE.UAsyncLoadingScreenLibrary.StopLoadingScreen()
        end)
    end
end

--[[
    查看当前的GVoice使用的Url
]]
function GMPanelModel:CustomGMCMD_ShowGVoiceUrl()
    local Url = MvcEntry:GetModel(GVoiceModel):GetServerUrl()
    if Url then
        local Tips = "当前使用的Url为: "..Url
        if not CommonUtil.IsInBattle() then
            Tips = "自己Id: "..(MvcEntry:GetModel(TeamModel):GetSelfDsGroupId() or "nil").." 队长Id: "..(MvcEntry:GetModel(TeamModel):GetTeamCaptainDsGroupId() or "nil").." "..Tips
        end
        UIAlert.Show(Tips)
    else
       UIAlert.Show("未设置过Url") 
    end
end

return GMPanelModel