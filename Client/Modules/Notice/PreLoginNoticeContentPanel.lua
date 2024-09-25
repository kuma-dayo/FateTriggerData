--[[
    登录前公告界面内容
]]

local class_name = "PreLoginNoticeContentPanel"
PreLoginNoticeContentPanel = BaseClass(nil, class_name)

function PreLoginNoticeContentPanel:OnInit()
    --- @type PreLoginNoticeModel
    self.Model = MvcEntry:GetModel(PreLoginNoticeModel)

    self.BindNodes = {
        { UDelegate = self.View.WBP_List.OnUpdateItem, Func = Bind(self, self.OnUpdateItem) },
    }
end

function PreLoginNoticeContentPanel:OnShow()
end

function PreLoginNoticeContentPanel:OnHide()
    self.Model = nil
    self.ItemList = nil
end

function PreLoginNoticeContentPanel:UpdateUI(Param)
    if not (Param and Param.NoticeId) then
        CError("NoticeContentPanel Param Error", true)
        return
    end

    local Notice = self.Model:GetNoticeById(Param.NoticeId)
    if Notice == nil then
        CError("Notice of id [" .. Param.NoticeId .. "] doesn't exist",true)
        return
    end
    
    self.ItemList = Notice.ItemList

    self.View.WBP_List:ReloadToIndexByJumpStyle(#Notice.ItemList, 0, UE.EReuseListExJumpStyle.Begin)
    self.View.WBP_Notice_TitleItem.Text_Title:SetText(Notice.Title)
end

function PreLoginNoticeContentPanel:OnUpdateItem(_, Widget, I)
    local Index = I + 1
    local Item = self.ItemList[Index]
    if Item == nil then
        return
    end
    
    local luaSubHeading = StringUtil.ConvertFText2String(Item.SubHeading)    
    if string.match(luaSubHeading, "%s+") then
        -- 如果内容全是空白字符则隐藏，从而保持正常间距
        Widget.Text_Title:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        Widget.Text_Title:SetText(Item.SubHeading)
    end
    
    Widget.RichText_Des:SetText(StringUtil.Format(Item.Content))
end




return PreLoginNoticeContentPanel
