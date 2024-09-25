--[[
   赛季，抽奖记录  记录列表逻辑
]] 
local class_name = "SeasonLotteryRecordListLogic"
local SeasonLotteryRecordListLogic = BaseClass(nil, class_name)

function SeasonLotteryRecordListLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.MsgList = {
        {Model = SeasonLotteryModel, MsgName = SeasonLotteryModel.ON_RECORD_LIST_UPDATE,Func = Bind(self,self.ON_RECORD_LIST_UPDATE_Func) },
    }
    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,    Func = Bind(self, self.OnUpdateRecordList)},

        { UDelegate = self.View.WBP_Friend_Btn_Item_First.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageClick,-10) },
        { UDelegate = self.View.WBP_Friend_Btn_Item_Pre.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageClick,-1) },
        { UDelegate = self.View.WBP_Friend_Btn_Item_Next.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageClick,1) },
        { UDelegate = self.View.WBP_Friend_Btn_Item_Last.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnPageClick,10) },
    }

    self.RowsNum = 6

    self.Widget2Handler = {}

    self.RecordType2PbEnum = {
        [SeasonLotteryRecordMdt.TabTypeEnum.Forever] = Pb_Enum_LOTTERY_RECORD_TYPE.LOTTERY_RECORD_FOREVER,
        [SeasonLotteryRecordMdt.TabTypeEnum.Limit] = Pb_Enum_LOTTERY_RECORD_TYPE.LOTTERY_RECORD_TIME_LIMIT,
    }
end

--[[
    local Param = {
        RecordType = self.SelectTabId,
    }
]]
function SeasonLotteryRecordListLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function SeasonLotteryRecordListLogic:OnHide()
end

function SeasonLotteryRecordListLogic:UpdateUI(Param)
    self.RecordType = Param.RecordType
    self.SelectPageIndex = 1

    --TODO 请求抽奖记录
    MvcEntry:GetCtrl(SeasonCtrl):SendProto_PlayerGetLotteryRecordReq(self.RecordType2PbEnum[self.RecordType])
end


function SeasonLotteryRecordListLogic:ON_RECORD_LIST_UPDATE_Func()
    self:UpdateRecordListShow()
end

function SeasonLotteryRecordListLogic:UpdateRecordListShow()
    self.RecordList = MvcEntry:GetModel(SeasonLotteryModel):GetRecordListByRecordType(self.RecordType2PbEnum[self.RecordType])
    -- print_r(self.RecordList)

    local ShowNums = #self.RecordList
    self.AllPageNum = math.floor(ShowNums /self.RowsNum) + 1;
    if ShowNums % self.RowsNum == 0 then
        self.AllPageNum = self.AllPageNum - 1;
    end

    self:UpdateCurPagetShow()
end

function SeasonLotteryRecordListLogic:UpdateCurPagetShow()
    self.ShowRecordList = {}
    for i=1,self.RowsNum do
        local Index = (self.SelectPageIndex - 1) * self.RowsNum + i;
        if self.RecordList[Index] then
            table.insert(self.ShowRecordList,self.RecordList[Index])
        end
    end
    self.View.WBP_ReuseList:Reload(#self.ShowRecordList)

    self.View.LbCurPageNum:SetText(tostring(self.SelectPageIndex))
    self.View.LbCurPageNumMax:SetText(tostring(self.AllPageNum))
end
function SeasonLotteryRecordListLogic:OnUpdateRecordList(Handler,Widget, I)
    local Index = I + 1
    local ContentData = self.ShowRecordList[Index]
    if not ContentData then
        CWaring("SeasonLotteryRecordListLogic:OnUpdateRecordList GetContentData Error; Index = "..tostring(Index))
        return
    end

    if not self.Widget2Handler[Widget] then
        self.Widget2Handler[Widget] = UIHandler.New(self,Widget,require("Client.Modules.Season.Lottery.SeasonLotteryRecordItemLogic"))
    end

    local Param = {
        RecordInfo = ContentData
    }
    self.Widget2Handler[Widget].ViewInstance:UpdateUI(Param)
end

function SeasonLotteryRecordListLogic:OnPageClick(Value)
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
    self:UpdateCurPagetShow()
end

return SeasonLotteryRecordListLogic
