--[[
    问卷调查主界面
]]
require("Client.Modules.Questionnaire.md5")

local class_name = "QuestionnaireMdt"
QuestionnaireMdt = QuestionnaireMdt or BaseClass(GameMediator, class_name)

function QuestionnaireMdt:__init()
end

function QuestionnaireMdt:OnShow(data)
end

function QuestionnaireMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    -- self.InputFocus = true
    self.MsgList =
    {
        { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.GUIButton_Close_ClickFunc },
    }

    self.BindNodes = {
        { UDelegate = self.WBP_Btn_Close.GUIButton_Main.OnClicked,	Func = self.GUIButton_Close_ClickFunc },
        { UDelegate = self.WebBrowser.OnMouseEnterStateChanged,	Func = self.OnMouseEnterStateChanged},
        { UDelegate = self.WebBrowser.OnUrlChanged,	Func = self.OnUrlChanged},
        { UDelegate = self.WebBrowser.OnBeforePopup,	Func = self.OnBeforePopup},
    }

    ---@type QuestionnaireModel
    self.Model = MvcEntry:GetModel(QuestionnaireModel)

    UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.GUIButton_Close_ClickFunc),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })
    self.WBP_List.OnUpdateItem:Add(self, self.OnUpdateItem)
    self.Widget2Item = {}
    self.ShowList = {}
    self.CurSelAcId = 0
    self.Sid = ""
    self.Sid2CfgTabId = {}
end

function M:OnHide()
    self.CurSelAcId = 0
    self.Widget2Item = nil
    self.ShowList = nil
    self.Sid = ""
    self.Sid2CfgTabId = {}
end

function M:OnShow(ID)
    self.ShowList = self.Model:GetQuestionnaireCanShowCfgList(ID)
    if #self.ShowList == 0 then
        return
    end
    ---@type QuestionnaireInfoData
    for _,Data in ipairs(self.ShowList) do
        local Url = Data.WebUrl
        local StartPos,EndPos = string.find(Url, "?sid=")
        if StartPos and EndPos then
            local DefaulUrl = string.sub(Url, 1, StartPos - 1)
            local Sid = string.sub(Url, EndPos + 1)
            self.Sid2CfgTabId[Sid] = Data.ID
        end
    end
    self:UpdateUI(ID)
end

function M:UpdateUI(ID)
    self.CurSelAcId = ID ~= nil and ID or self.ShowList[1].ID
    self:RefreshTabList()
    self:UpdateWebBrowser(self.CurSelAcId)
end


function M:RefreshTabList()
    self.WBP_List:Reload(#self.ShowList)
end

function M:OnUpdateItem(Widget, Index)
	local FixIndex = Index + 1

    local Data = self.ShowList[FixIndex]
	local TargetItem = self:CreateItem(Widget)
	if TargetItem == nil then
		return
	end
    local param = {
        TabId = Data.ID,
        ClickFunc = Bind(self,self.OnTabItemClick, TargetItem, FixIndex),
        Index = FixIndex,
        ChooseTabId = self.CurSelAcId
    }
	TargetItem:SetData(param)
end

function M:CreateItem(Widget)
	local Item = self.Widget2Item[Widget]
	if not Item then
		Item = UIHandler.New(self, Widget, require("Client.Modules.Questionnaire.QuestionnaireTabItem"))
		self.Widget2Item[Widget] = Item
	end
	return Item.ViewInstance
end

function M:OnTabItemClick(Item, Index)
    ---@type QuestionnaireInfoData
    local CfgData = self.ShowList[Index] 
    self:UpdateWebBrowser(CfgData.ID)
end


function M:UpdateWebBrowser(Id)
    local cfg = self.Model:GetDataByID(Id)
    if cfg == nil then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_QuestionnaireMdt_Finish"))
        return
    end
    local Url = cfg.WebUrl
    if not Url then
        CWaring("QuestionnaireMdt Url is nil")
        return
    end
    local CallBackId = self.Model:GetCallBackIdByZoneIdList(cfg.ZoneIDs)
    local ZoneId = MvcEntry:GetModel(UserModel).ZoneID
    local StartPos,EndPos = string.find(Url, "?sid=")
    if not StartPos or not EndPos then
        CError("web url is wrong")
        return
    end
    local DefaulUrl = string.sub(Url, 1, StartPos - 1)
    self.Sid = string.sub(Url, EndPos + 1)
    local RedirectStr = StringUtil.FormatSimple("{0}?sid={1}&callback={2}&callback_params={3}", DefaulUrl, self.Sid, CallBackId, ZoneId)
    local Uid = tostring(MvcEntry:GetModel(UserModel):GetPlayerId())
    local AppSecretStr = cfg.SecretKey
    local timeStr = tostring(GetTimestamp())
    local source = "saros"
    local Param = {
        {Key = "appSecret", Value = AppSecretStr},
        {Key = "sid", Value = self.Sid},
        {Key = "uid", Value = Uid},
        {Key = "redirect", Value = RedirectStr},
        {Key = "timestamp", Value = timeStr},
        {Key = "source", Value = source},
    }
    table.sort(Param, function(TempA,TempB)
        return TempA.Key < TempB.Key
    end)

    local Str = ""
    for k, v in ipairs(Param) do
        if string.len(v.Value) > 0 then
            Str = StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_ThreeParam"), Str, v.Key, v.Value)
        end
    end
    local SignStr = md5.sumhexa(Str)
    local FixUrl = StringUtil.FormatSimple("{0}api/autologin?sid={1}&uid={2}&timestamp={3}&source={4}&redirect={5}&sign={6}&callback_params={7}", DefaulUrl, self.Sid, Uid, timeStr, source, string.urlencode(RedirectStr), SignStr, ZoneId)
    CLog("QuestionnaireMdt:UpdateWebBrowser：".. FixUrl)
    self.WebBrowser:LoadUrl(FixUrl)
end

function M:OnMouseEnterStateChanged(Enter)
    local LocalPC = CommonUtil.GetLocalPlayerC()
    if  LocalPC == nil then
        return
    end
    if Enter then
        LocalPC:SetUseSoftwareCursorWidgets(false)
    else
        LocalPC:SetUseSoftwareCursorWidgets(true)
    end
end

function M:OnUrlChanged(url)
    CLog("QuestionnaireMdt:OnUrlChanged：".. url)
    local StartPos,EndPos = string.find(url, "?sid=")
    if not StartPos or not EndPos then
        return
    end
    local Sid = string.sub(url, EndPos + 1, EndPos + 24)
    if Sid and Sid == self.Sid then
        local TabId = self.Sid2CfgTabId[Sid] or 0
        if TabId > 0 then
            self.Model:DispatchType(QuestionnaireModel.QUESTIONNAIRE_MAIN_PANEL_TAB_SELECT, TabId)
        end
    end
end

--网页内部链接跳转逻辑处理
function M:OnBeforePopup(Url, Frame)
    -- CWaring(StringUtil.Format("OnBeforePopup: Url:{0} Frame:{1}",Url, Frame))
    UE.UGFUnluaHelper.OpenExternalUrl(Url)
end

--点击关闭按钮事件
function M:GUIButton_Close_ClickFunc()
    local List = self.Model:GetQuestionnaireCanShowCfgList()
    if #List > 0 then
        local msgParam = {
            describe = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("146")),
            leftBtnInfo = {},
            rightBtnInfo = {
                callback = function()
                    MvcEntry:CloseView(self.viewId)
                end
            }
        }
        UIMessageBox.Show(msgParam)
    else
        MvcEntry:CloseView(self.viewId)
    end
end

return M
