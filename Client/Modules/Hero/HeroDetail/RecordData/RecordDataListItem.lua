local class_name = "RecordDataListItem"
local RecordDataListItem = BaseClass(nil, class_name)


function RecordDataListItem:OnInit()
    self.MsgList = 
    {

	}
    self.BindNodes = 
    {
        { UDelegate = self.View.BtnItem.OnHovered,		    Func = Bind(self,self.OnHovered) },
        { UDelegate = self.View.BtnItem.OnUnhovered,		    Func = Bind(self,self.OnUnhovered) },
        { UDelegate = self.View.BtnItem.OnClicked,				    Func = Bind(self,self.OnDetailClicked) },
	}
end

function RecordDataListItem:OnShow(Param)

end

function RecordDataListItem:OnHide()
end

function RecordDataListItem:SetData(Index, Param)
    if not Param or not Param.Data then
        CWaring("RecordDataListItem:SetData Param is nil")
        return
    end
    self.Index = Index
    self.Param = Param
    self.View:UpdateShowStyle(Param.Data.PowerScoreInc >= 0, Index)
    self.View.GUITextBlock_RecordValue:SetText(math.abs(Param.Data.PowerScoreInc))
    self.TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_RoleRecord_Rank"), self.Param.Data.Rank)
end

function RecordDataListItem:OnHovered()
    if self.Param and self.Param.ItemCallBack then
        self.Param.ItemCallBack(self.View,true, self.TipStr, self.Index)
    end
end

function RecordDataListItem:OnUnhovered()
    if self.Param and self.Param.ItemCallBack then
        self.Param.ItemCallBack(self.View,false)
    end
end

function RecordDataListItem:OnDetailClicked()
    CWaring("RecordDataListItem:OnDetailClicked")
    MvcEntry:GetCtrl(PlayerInfo_MatchHistoryCtrl):OpenHistoryView(self.Param.Data.GameId,self.Param.SeasonId)
end

return RecordDataListItem








