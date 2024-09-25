--[[
    剧情表现漫画界面
]]

local class_name = "DialogActionPictureMdt";
DialogActionPictureMdt = DialogActionPictureMdt or BaseClass(GameMediator, class_name);

function DialogActionPictureMdt:__init()
end

function DialogActionPictureMdt:OnShow(data)
end

function DialogActionPictureMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = 
    {
    }

    self.BindNodes = 
    {
		{ UDelegate = self.GUIButton_Close.OnClicked,				Func = Bind(self,self.OnEscClicked) },
		{ UDelegate = self.Btn_PrePage.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnTurnPage,true) },
		{ UDelegate = self.Btn_NextPage.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnTurnPage,false) },
        
	}
    -- 翻页示意按钮
    UIHandler.New(self,self.CommonBtnTips_TurnPage, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ZOOMINOUT,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", tostring(1121)),
        SureNoMappingKey = true
    })

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

    self.AutoPlayTimer = nil
end

--[[
    Param->SetArrayField(TEXT("ImageList"), ImagePathStringArray);
    Param->SetNumberField(TEXT("Duration"), double(Duration));
    Param->SetBoolField(TEXT("IsAutoPlay"), IsAutoPlay);
    Param->SetBoolField(TEXT("CanSkip"), CanSkip);
    Param->SetNumberField(TEXT("CanSkipIndex"), double(CanSkipIndex));
    Param->SetNumberField(TEXT("SkipToIndex"), double(SkipToIndex));
    Param->SetStringField(TEXT("SkipDes"), SkipDes.ToString());
    Param->SetNumberField(TEXT("TurnPageCD"), double(TurnPageCD));
    Param->SetNumberField(TEXT("AutoPlayIndex"), double(AutoPlayIndex));
    Param->SetBoolField(TEXT("CanQuit"), CanQuit);
]]
function M:OnShow(Param)
    self.Param  = Param or {}
    self.ImageList = Param.ImageList
    if not self.ImageList or #self.ImageList == 0 then
        CError("DialogActionPictureMdt Without ImageList!! Please Check!!!")
        self:OnEscClicked()
        return
    end
    self.GUITextBlock_TotalPage:SetText(StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_6"),#self.ImageList))
    self.CurImageIndex = 0
    self:TurnPage()

    self.AutoPlayDelta = 0
    self.TurnPageDelta = 0
    self.TickTimer = self:InsertTimer(0,function (DeltaTime)
        self.TurnPageDelta = self.TurnPageDelta + DeltaTime
        self.AutoPlayDelta = self.AutoPlayDelta + DeltaTime
        self:CheckAutoPlay()
    end,true)
end

function M:OnHide()
    if self.TickTimer then
        self:RemoveTimer(self.TickTimer)
        self.TickTimer = nil
    end
end

function M:TurnPage(IsFront)
    if (IsFront and self.CurImageIndex - 1 < 1) or (not IsFront and self.CurImageIndex + 1 > #self.ImageList) then
        self.IsAutoPlaying = false
        return
    end
    self.TurnPageDelta = 0
    self.CurImageIndex = IsFront and self.CurImageIndex - 1 or self.CurImageIndex + 1
    self.GUITextBlock_CurPage:SetText(self.CurImageIndex)
    local ImagePath = self.ImageList[self.CurImageIndex]
    CommonUtil.SetBrushFromSoftObjectPath(self.GUIImage_ShowPic,ImagePath,true)
    -- 设置按钮状态
    self.Btn_PrePage:SetVisibility(self.CurImageIndex > 1 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.Btn_NextPage:SetVisibility(self.CurImageIndex < #self.ImageList and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    local IsSkipVisible = self.Param.CanSkip and self.CurImageIndex >= self.Param.CanSkipIndex
    self.CommonBtnTips_Skip:SetVisibility(IsSkipVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    local IsAutoPlayVisible = self.Param.IsAutoPlay and self.CurImageIndex >= self.Param.AutoPlayIndex
    self.CommonBtnTips_AutoPlay:SetVisibility(IsAutoPlayVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.CommonBtnTips_Quit:SetVisibility((self.Param.CanQuit and self.CurImageIndex == #self.ImageList) and UE.ESlateVisibility.SelfHitTestInvisible or  UE.ESlateVisibility.Collapsed)
    self.GUIButton_Close:SetVisibility(self.CurImageIndex == #self.ImageList and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
end

function M:OnTurnPage(IsFront)
    self.IsAutoPlaying = false
    self:UpdateAutoPlayState()
    self:TurnPage(IsFront)
end

function M:OnMouseWheel(MyGeometry,MouseEvent)
    if self.TurnPageDelta < self.Param.TurnPageCD then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    self.IsAutoPlaying = false
    self:UpdateAutoPlayState()
    local WheelDelta = UE.UKismetInputLibrary.PointerEvent_GetWheelDelta(MouseEvent)
    self:TurnPage(WheelDelta > 0)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function M:OnDoSkip()
    MvcEntry:GetCtrl(DialogSystemCtrl):DoSkipToEnd(self.Param.SkipDes,self.Param.SkipToIndex)
end

function M:OnDoAutoPlay()
    self.IsAutoPlaying = not self.IsAutoPlaying
    self.AutoPlayDelta = 0
    self:UpdateAutoPlayState()
end

function M:UpdateAutoPlayState()
    local TipsKey = self.IsAutoPlaying and "Lua_DialogActionPictureMdt_AutoPlaying" or "Lua_DialogActionPictureMdt_DoAutoPlay_Btn"
    self.AutoPlayBtn:SetTipsStr(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Favorability_Outside", TipsKey))
end

function M:CheckAutoPlay()
    local Duration = self.Param.Duration or 1
    if not self.IsAutoPlaying or self.AutoPlayDelta < Duration then
        return
    end
    self:TurnPage()
    self.AutoPlayDelta = 0
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
