--[[
    个人信息 - 最近访客列表逻辑
]] 
local class_name = "PersonInfoGuestListLogic"
local PersonInfoGuestListLogic = BaseClass(nil, class_name)

function PersonInfoGuestListLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.MsgList = {

    }
    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,    Func = Bind(self, self.OnUpdateGuestItem)},

        { UDelegate = self.View.WBP_Btn_FirstPage.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageClick,-10) },
        { UDelegate = self.View.WBP_Btn_PrePage.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageClick,-1) },
        { UDelegate = self.View.WBP_Btn_NextPage.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageClick,1) },
        { UDelegate = self.View.WBP_Btn_LastPage.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageClick,10) },
    }

    self.RowsNum = 8 * 2
    self.Widget2Handler = {}
end

--[[
    local Param = {
        RecordType = self.SelectTabId,
    }
]]
function PersonInfoGuestListLogic:OnShow(GuestList)
    if not GuestList then
        return
    end
    self:UpdateUI(GuestList)
end

function PersonInfoGuestListLogic:OnHide()
end

function PersonInfoGuestListLogic:UpdateUI(GuestList)
    self.GuestList = GuestList
    self.SelectPageIndex = 1
    self:UpdateGuestList()
end

function PersonInfoGuestListLogic:UpdateGuestList()
    local ShowNums = #self.GuestList
    self.AllPageNum = math.floor(ShowNums /self.RowsNum) + 1;
    if ShowNums % self.RowsNum == 0 then
        self.AllPageNum = self.AllPageNum - 1;
    end
    self:UpdateCurPageShow()
end

function PersonInfoGuestListLogic:UpdateCurPageShow()
    self.ShowRecordList = {}
    for i=1,self.RowsNum do
        local Index = (self.SelectPageIndex - 1) * self.RowsNum + i;
        if self.GuestList[Index] then
            table.insert(self.ShowRecordList,self.GuestList[Index])
        end
    end
    self.View.WBP_ReuseList:Reload(#self.ShowRecordList)
    self.View.LbCurPageNum:SetText(tostring(self.SelectPageIndex))
    self.View.LbCurPageNumMax:SetText(tostring(self.AllPageNum))
end
function PersonInfoGuestListLogic:OnUpdateGuestItem(Handler,Widget, I)
    local Index = I + 1
    local ContentData = self.ShowRecordList[Index]
    if not ContentData then
        CWaring("PersonInfoGuestListLogic:OnUpdateGuestItem GetContentData Error; Index = "..tostring(Index))
        return
    end

    if not self.Widget2Handler[Widget] then
        self.Widget2Handler[Widget] = UIHandler.New(self,Widget,require("Client.Modules.PlayerInfo.PersonalInfo.Item.PersonalInfoGuestItem"))
    end

    local Param = {
        GuestInfo = ContentData
    }
    self.Widget2Handler[Widget].ViewInstance:UpdateUI(Param)
end

function PersonInfoGuestListLogic:OnPageClick(Value)
    local CustomSelectPage = nil
    if Value == -10 then
        CustomSelectPage = 1
    elseif Value == 10 then
        CustomSelectPage = self.AllPageNum
    elseif Value == -1 then
        CustomSelectPage = self.SelectPageIndex - 1
    elseif Value == 1 then
        CustomSelectPage = self.SelectPageIndex + 1
    end
    if not CustomSelectPage then
        return
    end
    if CustomSelectPage == self.SelectPageIndex then
        return
    end
    if CustomSelectPage <= 0 or CustomSelectPage > self.AllPageNum then
        return
    end
    self.SelectPageIndex = CustomSelectPage
    self:UpdateCurPageShow()
end

return PersonInfoGuestListLogic
