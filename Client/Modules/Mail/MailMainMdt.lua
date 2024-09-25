--[[
    邮件主界面
]]

local class_name = "MailMainMdt";
MailMainMdt = MailMainMdt or BaseClass(GameMediator, class_name);

MailMainMdt.MenTabKeyEnum = {
    --系统
    System = 1,
    --礼物
    Gift = 2,
    --消息
    Message = 3,
}


function MailMainMdt:__init()
end

function MailMainMdt:OnShow(data)
end

function MailMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.MsgList = 
    {
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.GUIButton_Close_ClickFunc},
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.SpaceBar), Func = self.OnSpaceBarReceivedAward },
        {Model = MailModelSystem, MsgName = ListModel.ON_UPDATED, Func = self.OnMailListUpdate},
        {Model = MailModelSystem, MsgName = ListModel.ON_DELETED, Func = self.OnMailListDelete},
        {Model = MailModelGift, MsgName = ListModel.ON_UPDATED, Func = self.OnMailListUpdate},
        {Model = MailModelGift, MsgName = ListModel.ON_DELETED, Func = self.OnMailListDelete},
        {Model = MailModelMessage, MsgName = ListModel.ON_UPDATED, Func = self.OnMailListUpdate},
        {Model = MailModelMessage, MsgName = ListModel.ON_DELETED, Func = self.OnMailListDelete},
    }

    self.BindNodes = 
    {
		{ UDelegate = self.WBP_Btn_Close.GUIButton_Main.OnClicked,				    Func = self.GUIButton_Close_ClickFunc },
		{ UDelegate = self.BtnOutSide.OnClicked,				    Func = self.GUIButton_Close_ClickFunc },
        { UDelegate = self.OnAnimationFinished_vx_hall_mail_all_out,	Func = Bind(self,self.On_vx_hall_mail_list_close_Finished) },
	}

    self.MenTabKey2PageType = {
        [MailMainMdt.MenTabKeyEnum.System] = Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_SYS,
        [MailMainMdt.MenTabKeyEnum.Gift] = Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_GIFT,
        [MailMainMdt.MenTabKeyEnum.Message] = Pb_Enum_MAIL_PAGE_TYPE.MAIL_PAGE_MSG,
    }

    UIHandler.New(self,self.WBP_Btn_Delete, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.GUIButton_Delete_ClickFunc),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Mail', "Lua_MailMainMdt_Deleteread_Btn"),
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })
	UIHandler.New(self,self.WBP_Btn_Get, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.GUIButton_GetAll_ClickFunc),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Mail', "Lua_MailMainMdt_Clicktoclaim_Btn"),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })
end

function M:OnShow(Param)
    self.CurTabId = self:GetCurTabId()
    self.CurTabModel = self:GetCurTabMailModel()

    self.CurTabMailList = {}
    self.CurSelectMailId = 0 
    self.MailItemWidgetList = {}
    self.CurSelectMailItem = nil

    self:AddListeners()
    
    self:InitCommonUI()
    
    self:RefreshMailUI()

    self:RefreshAllMailList()
    self.Switcher_bg:SetActiveWidgetIndex(1)
    self:PlayMainDynamicEffectOnShow(true)
end

function M:OnHide()
    self:RemoveListeners()
end


function M:AddListeners()
    self.WBP_ReuseList_Mail.OnUpdateItem:Add(self,self.OnUpdateMailItem)
end

function M:RemoveListeners()
    self.WBP_ReuseList_Mail.OnUpdateItem:Clear()
end

function M:InitCommonUI()
    local ItemInfoList = {
        {Widget=self.WBP_Mail_TabItemSystem},
        {Widget=self.WBP_Mail_TabItemGift},
        {Widget=self.WBP_Mail_TabItemMessage},
    }
    local MailPageConfigs = G_ConfigHelper:GetDict(Cfg_MailPageConfig)
    for Index, Cfg in ipairs(MailPageConfigs) do
        local  Item = ItemInfoList[Index]
        if Item then
            Item.Id = Cfg[Cfg_MailPageConfig_P.PageId]
            Item.LabelStr = Cfg[Cfg_MailPageConfig_P.PageName]
            Item.TabIcon = Cfg[Cfg_MailPageConfig_P.TabIcon]
            Item.RedDotKey = "MailTab_"
            Item.RedDotSuffix = Cfg[Cfg_MailPageConfig_P.PageId]
        end
    end
    local MenuTabParam = {
        CurSelectId = MailMainMdt.MenTabKeyEnum.System,
        ClickCallBack = Bind(self,self.OnMenuBtnClick),
        ValidCheck = Bind(self,self.MenuValidCheck),
        HideInitTrigger = true,
		IsOpenKeyboardSwitch = true,
	}
    MenuTabParam.ItemInfoList = ItemInfoList
    UIHandler.New(self, self.HorizontalBox_Tab, CommonMenuTab, MenuTabParam)
    
    self.LeftUI:SetVisibility(UE.ESlateVisibility.Hidden)
end

function M:GetCurTabId()
    return MailMainMdt.MenTabKeyEnum.System
end

function M:GetCurTabMailModel()
    return MvcEntry:GetCtrl(MailCtrl):GetModelByPageType(self.MenTabKey2PageType[self.CurTabId])
end

function M:GetPageTypeByCurTab()
    return self.MenTabKey2PageType[self.CurTabId]
end


function M:RefreshMailUI()
    local TabModel = self:GetCurTabMailModel()
    if TabModel == nil then
        return
    end
    local Count = TabModel:GetMailCount()
    self.MailNumRoot:SetVisibility(Count == 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

    local Str = StringUtil.Format('<span color="#F5EFAE">{0}</>', Count)
    self.GUITextBlockNumber:SetText(StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"), Str, TabModel:GetMailMaxLimit()))
    -- self.GUITextBlockNumberMax:SetText(TabModel:GetMailMaxLimit())

    if TabModel:GetLength() > 0 then
        self.WidgetSwitcherMail:SetActiveWidgetIndex(0)
    else
        self.WidgetSwitcherMail:SetActiveWidgetIndex(1)
    end

    local ReadWithOutAttachMailList = TabModel:GetReadWithOutAttachMailList()
    self.WBP_Btn_Delete:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WBP_Btn_Get:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local AttachMailList = TabModel:GetAttachedMailList()
    if #AttachMailList > 0 then
        if #ReadWithOutAttachMailList == 0 then
            self.WBP_Btn_Delete:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        if #ReadWithOutAttachMailList == 0 then
            self.WBP_Btn_Delete:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.WBP_Btn_Get:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.WBP_Btn_Get:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

end


function M:RefreshAllMailList()
    if self.CurTabModel == nil then
        return
    end
    self.Id2DataIndex = {}
    self.MailDataList = self.CurTabModel:GetDataList()
    self.CurTabModel:SortItemTable(self.MailDataList)
    if #self.MailDataList > 0 then
        self.WidgetSwitcherMail:SetActiveWidgetIndex(0)
        self.WBP_ReuseList_Mail:Reload(#self.MailDataList)
    else
        self.WidgetSwitcherMail:SetActiveWidgetIndex(1)
    end
end

function M:RefreshMailList(UpdateMailList)
    local TheList = UpdateMailList or {}
    for k,v in ipairs(TheList) do
        local MailUniqId = v["MailUniqId"]
        local TheIndex = self.Id2DataIndex[MailUniqId]
        for index,data in ipairs(self.MailDataList) do
            if MailUniqId == data.MailUniqId then
                self.MailDataList[index] = v
                break
            end
        end
        self.WBP_ReuseList_Mail:RefreshOne(TheIndex)
        if self.CurSelectMailId == v.MailUniqId then
            self:UpdateMailDetail(v)
        end
    end
end

function M:CreateMailItem(Widget)
	local Item = self.MailItemWidgetList[Widget]
	if not Item then
		local Param = {
			OnItemClick = Bind(self,self.OnMailItemClick)
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Mail.MailItem"), Param)
		self.MailItemWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end

function M:OnMailItemClick(Item, MailData, DataIndex)
	if Item == nil or MailData == nil then 
		return
	end
    self.CurSelectMailId = MailData.MailUniqId
	self:OnSelectMailItem(Item, MailData)
end

function M:OnSelectMailItem(Item, MailData)
	if self.CurSelectMailItem then
		self.CurSelectMailItem:UnSelect()
	end
    if Item then
        self.CurSelectMailItem = Item
        if self.CurSelectMailItem then
            self.CurSelectMailItem:Select()
        end
    end
    self:UpdateMailDetail(MailData, true)
end

function M:OnUpdateMailItem(Widget, Index)
	local i = Index + 1
	local MailData = self.MailDataList[i]
	if MailData == nil then
		return
	end

	local ListItem = self:CreateMailItem(Widget)
	if ListItem == nil then
		return
	end

    if MailData.MailUniqId == self.CurSelectMailId then
		self:OnSelectMailItem(ListItem, MailData)
	else
		ListItem:UnSelect()
	end
    self.Id2DataIndex[MailData.MailUniqId] = Index
	ListItem:SetItemData(MailData, i)
end

function M:UpdateMailDetail(MailData, isSwitch)
    if MailData == nil then
        return
    end
    self.Switcher_bg:SetActiveWidgetIndex(0)
    local IsQuestionnaireMail = self.CurTabModel:IsQuestionnaireMail(MailData)
    if not IsQuestionnaireMail then
        self.DetailUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WBP_Mail_Questionnaire:SetVisibility(UE.ESlateVisibility.Collapsed)
        --仅切换邮件时需要传入PageType字段
        local PageType = isSwitch and self:GetPageTypeByCurTab() or nil
        local Param = {MailData = MailData, PageType = PageType}
        if self.MailDetailViewInst == nil then
            self.MailDetailViewInst = UIHandler.New(self, self, require("Client.Modules.Mail.MailDetailLogic"), Param).ViewInstance
        else 
            self.MailDetailViewInst:UpdateMailDetail(Param)
        end
        if self.MailDetailViewInst ~= nil then
            self.MailDetailViewInst:UpdateMailDetailVisibility(self.CurSelectMailId == MailData.MailUniqId)
        end
    else
		self.LeftUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.DetailUI:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_Mail_Questionnaire:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if self.MailQuestionnaireViewInst == nil then
            self.MailQuestionnaireViewInst = UIHandler.New(self, self, require("Client.Modules.Mail.MailQuestionnaireLogic"), MailData).ViewInstance
        else 
            self.MailQuestionnaireViewInst:UpdateMailDetail(MailData)
        end
        if self.MailQuestionnaireViewInst ~= nil then
            self.MailQuestionnaireViewInst:UpdateMailDetailVisibility(self.CurSelectMailId == MailData.MailUniqId)
        end
    end
    self:PlayLeftContentDynamicEffectOnShow(true)
end

--邮件标签
function M:OnMenuBtnClick(Id, ItemInfo, IsInit)
    self.CurTabId = Id
    self.CurTabModel = self:GetCurTabMailModel()
    --self.LeftUI:SetVisibility(UE.ESlateVisibility.Hidden)
    self:RefreshMailUI()
    self:RefreshAllMailList()
end

function M:MenuValidCheck(Id)
    -- if Id == MailMainMdt.MenTabKeyEnum.System then
    --     return true
    -- end
    -- UIAlert.Show("功能未开放")
    return true
end


function M:OnMailListUpdate(ChangeMap)
    local AddList = ChangeMap["AddMap"] or {}
    local UpdateList = ChangeMap["UpdateMap"] or {}
    if #AddList > 0 then
        self:RefreshAllMailList()
    else
        self:RefreshMailList(UpdateList)
    end

    self:RefreshMailUI()
end

function M:OnMailListDelete(KeyList)
    if KeyList and #KeyList> 0 then
        for _, MailId in ipairs(KeyList) do
           if MailId == self.CurSelectMailId then
                self.CurSelectMailId = 0
                if self.MailDetailViewInst ~= nil then
                    self.MailDetailViewInst:UpdateMailDetailVisibility(false)
                end
                if self.MailQuestionnaireViewInst ~= nil then
                    self.MailQuestionnaireViewInst:UpdateMailDetailVisibility(false)
                end
                self.Switcher_bg:SetActiveWidgetIndex(1)
                break
           end
        end
    end

    self:RefreshMailUI()
    self:RefreshAllMailList()
end

--关闭界面
function M:DoClose()
    --MvcEntry:CloseView(self.viewId)
    self:PlayMainDynamicEffectOnShow(false)
    self:PlayLeftContentDynamicEffectOnShow(false)
    return true
end

--空格响应
-- function M:OnSpaceBarReceivedAward()
--     -- if self.MailDetailViewInst ~= nil and 
--     --     self.MailDetailViewInst:IsVisible() then
--     --         self.MailDetailViewInst:OnGUIButtonGetClicked()
--     -- else
--     self:GUIButton_GetAll_ClickFunc()     
--     -- end
-- end


-- 点击关闭
function M:GUIButton_Close_ClickFunc()
    self:DoClose()
    return true
end

function M:GUIButton_Delete_ClickFunc()
    local TabModel = self:GetCurTabMailModel()
    if TabModel == nil then
        CLog("Delete: CurModel Failed")
        return
    end

    local ReadWithOutAttachMailList = TabModel:GetReadWithOutAttachMailList()
    if #ReadWithOutAttachMailList == 0 then 
        CLog("Delete: ReadWithOutAttachMailList Failed")
        return
    end

    local msgParam = {
		describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Mail', "Lua_MailMainMdt_Areyousureyouwanttod")),
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
                local PageType = self:GetPageTypeByCurTab()
                local ReadWithOutAttachMailList = TabModel:GetReadWithOutAttachMailList()
                if #ReadWithOutAttachMailList > 0 then 
                    MvcEntry:GetCtrl(MailCtrl):SendProto_PlayerDeleteMailReq(PageType, ReadWithOutAttachMailList)
                end
			end
		}
	}
	UIMessageBox.Show(msgParam)
end


function M:GUIButton_GetAll_ClickFunc()
    local TabModel = self:GetCurTabMailModel()
    if TabModel == nil then
        CLog("GetAll: CurModel Failed")
        return
    end
    local PageType = self:GetPageTypeByCurTab()
    local AttachMailList = TabModel:GetAttachedMailList()
    if #AttachMailList > 0 then 
        MvcEntry:GetCtrl(MailCtrl):SendProto_PlayerGetAppendReq(PageType, 
        AttachMailList)
    else 
        CLog("GetAll: AttachMailList Failed")
    end
end

--[[
    播放列表显示退出动效
]]
function M:PlayMainDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Hall_Mail_Open then
            self:VXE_Hall_Mail_Open()
        end
    else
        if self.VXE_Hall_Mail_Close then
            self:VXE_Hall_Mail_Close()
        end
    end
end

--[[
    播放内容显示退出动效
]]
function M:PlayLeftContentDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Hall_Mail_Read_In then
            self:VXE_Hall_Mail_Read_In()
        end
    else
        -- if self.VXE_Hall_Mail_Content_Out then
        --     self:VXE_Hall_Mail_Content_Out()
        -- end
    end
end

function M:On_vx_hall_mail_list_close_Finished()
    MvcEntry:CloseView(self.viewId)
end

return M