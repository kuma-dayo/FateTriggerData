--[[
    剧情背景加文本类型
]]

local class_name = "DialogActionBgAndTextMdt";
DialogActionBgAndTextMdt = DialogActionBgAndTextMdt or BaseClass(GameMediator, class_name);

function DialogActionBgAndTextMdt:__init()
end

function DialogActionBgAndTextMdt:OnShow(data)
end

function DialogActionBgAndTextMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()

    self.BindNodes = 
    {
		{ UDelegate = self.WBP_ReuseListEx_Content.OnUpdateItem,	Func = self.WBP_ReuseListEx_Content_OnUpdateItem },
		-- { UDelegate = self.WBP_ReuseListEx_Content.OnReloadFinish,	Func = self.WBP_ReuseListEx_Content_OnReloadFinish },
		{ UDelegate = self.GUIButton_ShowAllText.OnClicked,				    Func = self.OnClicked_GUIButton_ShowAllText },
		{ UDelegate = self.GUIButton_HideUI.OnClicked,				    Func = self.OnClicked_GUIButton_HideUI },
        
	}

	-- 退出按钮
    UIHandler.New(self,self.CommonBtnTips_Quit, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
        OnItemClick = Bind(self,self.OnEscClicked),
    })
    self.CommonBtnTips_Quit:SetVisibility(UE.ESlateVisibility.Collapsed)

    -- 自动播放按钮
    self.AutoPlayBtn = UIHandler.New(self,self.CommonBtnTips_AutoPlay, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_A,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.A,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "Lua_DialogActionPictureMdt_DoAutoPlay_Btn"),
        OnItemClick = Bind(self,self.OnDoAutoPlay),
    }).ViewInstance
    self.CommonBtnTips_AutoPlay:SetVisibility(UE.ESlateVisibility.Collapsed)

    -- 跳过按钮
    UIHandler.New(self,self.CommonBtnTips_Skip, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_S,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.S,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "1101_Btn"),
        OnItemClick = Bind(self,self.OnDoSkip),
    })
    self.CommonBtnTips_Skip:SetVisibility(UE.ESlateVisibility.Collapsed)

     -- 继续按钮
     UIHandler.New(self,self.CommonBtnTips_Continue, WCommonBtnTips, 
     {
         CommonTipsID = CommonConst.CT_SPACE,
         HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
         ActionMappingKey = ActionMappings.SpaceBar,
         TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "Lua_DialogActionTaskMdt_Continue_Btn"),
         OnItemClick = Bind(self,self.OnClicked_GUIButton_ShowAllText),
     })

    -- 隐藏UI按钮
    self.HideUIBtn = UIHandler.New(self,self.CommonBtnTips_HideUI, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_H,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.H,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", "Lua_DialogActionTaskMdt_HideUI_Btn"),
        OnItemClick = Bind(self,self.OnClicked_GUIButton_HideUI),
    }).ViewInstance
    self.AutoPlayTimer = nil
    -- print_r(self.WBP_ReuseListEx_Content.Slot:GetSize())
    self.WBP_ReuseListEx_Content:SetSizeToContent(30)
    self.IsShowContent = true
end

--[[
	Param->SetArrayField(TEXT("TextList"), TextJsonValueArray);
	Param->SetStringField(TEXT("TitleIndexStr"), TitleIndexStr);
	Param->SetStringField(TEXT("TitleText"), TitleText.ToString());
	Param->SetStringField(TEXT("BgImage"), BgImage.ToSoftObjectPath().ToString());
	Param->SetBoolField(TEXT("IsAutoPlay"), IsAutoPlay);
	Param->SetBoolField(TEXT("CanSkip"), CanSkip);
	Param->SetNumberField(TEXT("CanSkipIndex"), double(CanSkipIndex));
	Param->SetNumberField(TEXT("SkipToIndex"), double(SkipToIndex));
	Param->SetStringField(TEXT("SkipDes"), SkipDes.ToString());
	Param->SetNumberField(TEXT("AutoPlayIndex"), double(AutoPlayIndex));
	Param->SetBoolField(TEXT("CanQuit"), CanQuit);
	Param->SetNumberField(TEXT("Duration"), double(Duration));
    Param->SetNumberField(TEXT("ShowBtnIndex"), double(ShowBtnIndex));
]]
function M:OnShow(Param)
	self.Param = Param or {}
	if not self.Param.TextList or #self.Param.TextList == 0 then
        CError("DialogActionBgAndTextMdt Without TextList!! Please Check!!!")
        self:OnEscClicked()
		return
	end
	local TitleStr = self.Param.TitleIndexStr ~= "" and self.Param.TitleIndexStr or MvcEntry:GetCtrl(DialogSystemCtrl):GetPlayingStoryChapterName()
	self.Text_Chapter:SetText(TitleStr)
	local PartName = self.Param.TitleText ~= "" and self.Param.TitleText or MvcEntry:GetCtrl(DialogSystemCtrl):GetPlayingStoryPartName()
	self.Text_PartName:SetText(PartName)
    CommonUtil.SetBrushFromSoftObjectPath(self.Bg,self.Param.BgImage,true)
	self.ShowIndex = 1
	self:UpdateContent()
	self.IsAutoPlaying = false
    -- self:UpdateAutoPlayState()

    self.AutoPlayDelta = 0
	self.PlayTimer = self:InsertTimer(0, function (DeltaTime)
        self.AutoPlayDelta = self.AutoPlayDelta + DeltaTime
		self:CheckAutoPlay()
	end,true)
end

function M:OnHide()
	self:ClearAutoPlayTimer()
end

function M:UpdateContent()
    if self.ShowIndex == 1 then
        self.WBP_ReuseListEx_Content:Reload(self.ShowIndex)
    else
        self.WBP_ReuseListEx_Content:RefreshOne(self.ShowIndex-2)   -- 刷新上一个，把箭头去掉
        self.WBP_ReuseListEx_Content:AddOne(self.ShowIndex)
        -- self:UpdateListSize()
        self.WBP_ReuseListEx_Content:ScrollToEnd() 
    end
    -- 设置按钮状态
    self:UpdateBtnVisibile()
end

-- 更新底部按钮显示状态
function M:UpdateBtnVisibile()
    local IsSkipVisible = self.IsShowContent and self.Param.CanSkip and self.ShowIndex >= self.Param.CanSkipIndex
    self.CommonBtnTips_Skip:SetVisibility(IsSkipVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    local IsAutoPlayVisible = self.IsShowContent and self.Param.IsAutoPlay and self.ShowIndex >= self.Param.AutoPlayIndex
    self.CommonBtnTips_AutoPlay:SetVisibility(IsAutoPlayVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.CommonBtnTips_Quit:SetVisibility((self.IsShowContent and self.Param.CanQuit and self.ShowIndex == #self.Param.TextList) and UE.ESlateVisibility.SelfHitTestInvisible or  UE.ESlateVisibility.Collapsed)
    self.CommonBtnTips_Continue:SetVisibility(self.IsShowContent and UE.ESlateVisibility.SelfHitTestInvisible or  UE.ESlateVisibility.Collapsed)
    self.CommonBtnTips_HideUI:SetVisibility((self.Param.ShowBtnIndex >= 0 and self.ShowIndex >= self.Param.ShowBtnIndex) and UE.ESlateVisibility.SelfHitTestInvisible or  UE.ESlateVisibility.Collapsed)
end

-- function M:WBP_ReuseListEx_Content_OnReloadFinish()
--     if self.ShowIndex == 1 and not self.FirstInitSize then
--         self:UpdateListSize()
--         self.FirstInitSize = true
--     end
--     -- print_r(self.WBP_ReuseListEx_Content.ContentSize)
-- end

-- function M:UpdateListSize()
--     local ViewportSize = CommonUtil.GetViewportSize(self)
--     local NewOffsets = self.WBP_ReuseListEx_Content.Slot:GetOffsets()
--     --print("self.WBP_ReuseListEx_Content.ContentSize.Y = "..self.WBP_ReuseListEx_Content.ContentSize.Y)
--     NewOffsets.Bottom = math.max(ViewportSize.Y - NewOffsets.Top - self.WBP_ReuseListEx_Content.ContentSize.Y,30)
--     self.WBP_ReuseListEx_Content.Slot:SetOffsets(NewOffsets)
-- end

function M:WBP_ReuseListEx_Content_OnUpdateItem(Widget,Index)
	local FixIndex = Index + 1
	local Text = self.Param.TextList[FixIndex]
	if not Text then
		return
	end
	if FixIndex == self.ShowIndex then
		Text = StringUtil.FormatSimple('{0}<widget src="W_TemaranNextIcon"></>',Text)
	end
	Widget.RichText_Content:SetText(Text)
    Widget.RichText_Content.OnHyperlinkHovered:Clear()
    Widget.RichText_Content.OnHyperlinkUnhovered:Clear()
    Widget.RichText_Content.OnHyperlinkHovered:Add(self, Bind(self,self.OnHoverKeyText))
    Widget.RichText_Content.OnHyperlinkUnhovered:Add(self, Bind(self,self.OnUnhoverKeyText))
end

function M:OnHoverKeyText(_,ActionKey)
    local Param = {
        KeyWord = ActionKey,
        FromViewId = self.viewId
    }
    MvcEntry:OpenView(ViewConst.CommonKeyWordTips,Param)
end

function M:OnUnhoverKeyText(_,ActionKey)
    MvcEntry:CloseView(ViewConst.CommonKeyWordTips)
end


function M:ToNextText()
	self.ShowIndex = self.ShowIndex + 1
	if self.ShowIndex > #self.Param.TextList then
        if self.IsAutoPlaying then
            self.IsAutoPlaying = false
            self:UpdateAutoPlayState()
        else
    		self:OnEscClicked()
        end
	else
		self:UpdateContent()
	end
end

function M:CheckAutoPlay()
	local Duration = self.Param.Duration or 1
	if not self.IsAutoPlaying or self.AutoPlayDelta < Duration then
		return
	end
	self:ToNextText()
	
    self.AutoPlayDelta = 0
end

function M:ClearAutoPlayTimer()
	if self.PlayTimer then
		self:RemoveTimer(self.PlayTimer)
		self.PlayTimer = nil
	end
end

function M:UpdateAutoPlayState()
    local TipsKey = self.IsAutoPlaying and "Lua_DialogActionPictureMdt_AutoPlaying" or "Lua_DialogActionPictureMdt_DoAutoPlay_Btn"
    self.AutoPlayBtn:SetTipsStr(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", TipsKey))
end

function M:OnDoAutoPlay()
    self.IsAutoPlaying = not self.IsAutoPlaying
    self.AutoPlayDelta = 0
    self:UpdateAutoPlayState()
end

function M:OnDoSkip()
    MvcEntry:GetCtrl(DialogSystemCtrl):DoSkipToEnd(self.Param.SkipDes,self.Param.SkipToIndex)
end

function M:OnClicked_GUIButton_ShowAllText()
    self.IsAutoPlaying = false
    self:UpdateAutoPlayState()
	self:ToNextText()
end

-- 点击隐藏内容
function M:OnClicked_GUIButton_HideUI()
    self.IsShowContent = not self.IsShowContent
    self.ContentPanel:SetVisibility(self.IsShowContent and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.GUIButton_HideUI:SetVisibility(self.IsShowContent and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
    local BtnKeys = self.IsShowContent and "Lua_DialogActionTaskMdt_HideUI_Btn" or "Lua_DialogActionTaskMdt_ShowUI"
    self.HideUIBtn:SetTipsStr(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", BtnKeys))
    self:UpdateBtnVisibile()
    if not self.IsShowContent then
        self.IsAutoPlaying = false
        self:UpdateAutoPlayState()
    end
end

function M:OnEscClicked()
    if self.Param.WithoutNext then
        -- MvcEntry:CloseView(self.viewId)
        MvcEntry:GetCtrl(DialogSystemCtrl):DoStopStory(self.viewId)
    else
        MvcEntry:GetCtrl(DialogSystemCtrl):FinishCurAction() 
    end
end

return M
