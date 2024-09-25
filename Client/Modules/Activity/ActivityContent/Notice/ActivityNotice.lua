--- 视图控制器
local class_name = "ActivityNotice"
local ActivityNotice = BaseClass(ActivityViewBase, class_name)

function ActivityNotice:OnInit(Param)
    self.MsgList = {}
    self.BindNodes = {
        {UDelegate = self.View.WBP_List.OnUpdateItem, Func = Bind(self, self.OnUpdateItem)},
        {UDelegate = self.View.WBP_List.OnReloadFinish, Func = Bind(self, self.OnReloadFinish)},
        {UDelegate = self.View.WBP_List.OnPreUpdateItem, Func = Bind(self, self.OnPreUpdateItem)},
    }
    ActivityNotice.super.OnInit(self, Param)
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.Data = nil
end

function ActivityNotice:OnShow(Param)
    if not Param or not Param.Id then
        CError("ActivityNotice:OnShow Param is nil")
        return
    end
    ---@type NoticeData
    self.Data = self.Model:GetData(Param.Id)
    if not self.Data then
        CError("ActivityNotice:OnShow NoticeData is nil NoticeDataId:"..Param.Id)
        return
    end

    local LanguageCallBack = function (Text)
        if not CommonUtil.IsValid(self.View) or not CommonUtil.IsValid(self.View.WBP_List) then
            return
        end
        -- body
        local MTitle, Contents = StringUtil.SplitTitleAndContentStrings(Text)
        self.MainTitleText = MTitle
        self.ShowTextList = Contents
        local Count = #self.ShowTextList
        if self.MainTitleText and string.len(self.MainTitleText) > 0 then
            Count = Count + 1
        end
        self.View.WBP_List:Reload(Count)
    end
    self.Data:GetContent(LanguageCallBack)
end

function ActivityNotice:OnHide(Param)
    self.Data = nil
end


function ActivityNotice:OnUpdateItem(_, Widget, Index)
    if Index == 0 and self.MainTitleText and string.len(self.MainTitleText) > 0 then
        Widget.Text_Title:SetText(StringUtil.Format(self.MainTitleText))
    else
        local FixIndex = Index + 1
        if self.MainTitleText and string.len(self.MainTitleText) > 0 then
            FixIndex = Index
        end
        local TextTable = self.ShowTextList[FixIndex]
        if TextTable then
            if TextTable.Title and string.len(TextTable.Title) > 0 then
                Widget.Text_Title:SetText(StringUtil.Format(TextTable.Title))
                Widget.Text_Title:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            else
                Widget.Text_Title:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
            Widget.RichText_Des:SetText(StringUtil.Format(TextTable.Content))
        end
    end
end

function ActivityNotice:OnReloadFinish()
end

function ActivityNotice:OnPreUpdateItem(_, Index)
    if Index == 0 and self.MainTitleText and string.len(self.MainTitleText) > 0 then
        self.View.WBP_List:ChangeItemClassForIndex(Index, "Title")
    else
        self.View.WBP_List:ChangeItemClassForIndex(Index, "")
    end
end

function ActivityNotice:OnStateChangedNotify()
    
end

return ActivityNotice
