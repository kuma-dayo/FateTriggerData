--[[
    角色展示板编辑预览界面
]]

local class_name = "StickerEditMdt";
StickerEditMdt = StickerEditMdt or BaseClass(GameMediator, class_name);



function StickerEditMdt:__init()
end

function StickerEditMdt:OnShow(data)
end

function StickerEditMdt:OnHide()
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = false
    self.BindNodes = {
		
    }

    self.MsgList = {
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked },
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.SpaceBar), Func = self.OnSpaceBarClick },
        { Model = CommonModel, MsgName = CommonModel.ON_WIDGET_TO_FOCUS, Func = Bind(self, self.ON_WIDGET_TO_FOCUS_Fun) }, 
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED, Func = Bind(self, self.ON_AFTER_SATE_ACTIVE_CHANGED_Func) }, 
	}
end

function M:ON_WIDGET_TO_FOCUS_Fun(_, viewId)
    -- 2205
    -- CError("xxxxxxxxxxxxxxxxxx11111111 viewId = "..tostring(viewId))
end

function M:ON_AFTER_SATE_ACTIVE_CHANGED_Func(_, ViewId)
    -- 2205
    -- CError("xxxxxxxxxxxxxxxxxx22222222 viewId = "..tostring(viewId))
    -- if ViewId == self.viewId then
    --     return
    -- end
end

--[[
    Param = {
        HeroId
        SkinId
        SkinDataList
    }
]]
function M:OnShow(Param)
    if Param == nil then
        return
    end

    self.GUIImage_Mouse.Slot:SetOffsets(UE.FMargin(0, 0, 0, 0))
    self.GUIImage_Mouse:SetVisibility(UE.ESlateVisibility.Visible)
    -- if UE.UGFUnluaHelper.IsEditor() then
    --     self.GUIImage_Mouse:SetOpacity(0.3)
    -- else
    --     self.GUIImage_Mouse:SetOpacity(0.0)
    -- end


    self.bRepeatShow = false

    self:UpdateUI(Param)
end

function M:OnRepeatShow(Params)
    self.bRepeatShow = true

    self:UpdateUI(Params)
end

function M:OnHide()
    self.EditPanel:SetVisibility(UE.ESlateVisibility.Collapsed)

    self:ClearEnterEditTimer()
    self:ResetCustomData()
end

function M:UpdateUI(Param)
    
    --是否是同一个贴纸
    self.bIsTheSameSticker = self.StickerId == Param.StickerId

    self.StickerId = Param.StickerId
    self.OnRequestStartEdit = Param.OnRequestStartEdit
    self.RequestLimitBoxParam = Param.RequestLimitBoxParam
    self.OnEditorStickerNtf = Param.OnEditorStickerNtf
    self.OnCloseStickerEdit = Param.OnCloseStickerEdit

    -- self.LimitBox = Param.UIWidget.LimitBox
    -- self.WBP_VehicleSkinSticker_Edit = Param.UIWidget.WBP_VehicleSkinSticker_Edit
    -- self.EditPanel = Param.UIWidget.EditPanel
    -- self.GUIImage_222 = Param.UIWidget.GUIImage_222

    ---刷新贴纸编辑
    self:RefreshStickerEditHandler()
end

function M:ResetCustomData()
    self.bIsTheSameSticker = false
    self.StickerId = 0
    self.OnRequestStartEdit = nil
    self.RequestLimitBoxParam = nil
    self.OnEditorStickerNtf = nil
    self.bRepeatShow = false
end

function M:RequestStartEdit()
    if self.OnRequestStartEdit then
        return self.OnRequestStartEdit()
    end
    return nil
end

function M:RequestLimitBoxParam()
    if self.RequestLimitBoxParam then
        return self.RequestLimitBoxParam()
    end
    return nil
end

---适配限制区域与鼠标事件相应区域
function M:AdaptiveLimitBox()
    local LimitParam = self:RequestLimitBoxParam()
    if LimitParam then
        local Margin = UE.FMargin(0,0,0,0)
        -- {TopLeft = TopLeft,BottomRight = BottomRight}
        --TODO:贴纸拖动编辑区域
        Margin.Left = LimitParam.TopLeft.X
        Margin.Top = LimitParam.TopLeft.Y
        Margin.Right = LimitParam.BottomRight.X
        Margin.Bottom = LimitParam.BottomRight.Y
        self.LimitBox.Slot:SetOffsets(Margin)

        --TODO:鼠标事件相应区域
        local OffsetVal = 25
        Margin.Left = Margin.Left - OffsetVal
        -- Margin.Top = Margin.Top - OffsetVal
        Margin.Right = Margin.Right - OffsetVal
        -- Margin.Bottom = Margin.Bottom - OffsetVal
        self.GUIImage_Mouse.Slot:SetOffsets(Margin)
    else
        CError("M:AdaptiveLimitBox() LimitParam == nil")
    end
end

function M:RefreshStickerEditHandler()

    local EnterStickerEditFunc = function()
        self.EditPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- 适配限制区域与鼠标事件相应区域
        self:AdaptiveLimitBox()

        local EditParam = self:RequestStartEdit()
         -- CError(string.format("编辑参数11= %s", table.tostring(EditParam)))
        if self.StickerEditHandler == nil or not(self.StickerEditHandler:IsValid()) then
            local InitEditParam = {
                CallCloseFunc = Bind(self, self.OnStickerCloseClicked),
                CallAlignmentFunc = Bind(self, self.OnStickerAlignClicked),
                CallMirrorFunc = Bind(self, self.OnStickerMirrorClicked),
                OnEditInfoTransformFunc = Bind(self, self.OnEditInfoTransform),

                StickerId = self.StickerId, 
                EditParam = EditParam,
            }

            self.StickerEditHandler = UIHandler.New(self, self.WBP_VehicleSkinSticker_Edit, require("Client.Modules.Hero.HeroDetail.DisplayBoard.StickerEditHandle"), InitEditParam)
        else
            if self.StickerEditHandler and self.StickerEditHandler:IsValid() then
                local Param = {
                    StickerId = self.StickerId, 
                    EditParam = EditParam
                }
                self.StickerEditHandler.ViewInstance:UpdateUI(Param)
            end
        end
    end

    if self.bRepeatShow == false then
        self:ClearEnterEditTimer()

        self.WaitEnterEditTimer = self:InsertTimer(Timer.NEXT_FRAME, function()
            self:ClearEnterEditTimer()

            EnterStickerEditFunc()
        end, false)
    else
        if not(self.bIsTheSameSticker) then
            if self.WaitEnterEditTimer == nil then
                EnterStickerEditFunc()
            end
        end
    end
end

function M:ClearEnterEditTimer()
    if self.WaitEnterEditTimer then
        self:RemoveTimer(self.WaitEnterEditTimer)
    end
    self.WaitEnterEditTimer = nil
end

---------------------------------------------------回调>>

--[[
	编辑贴纸关闭：处理未装备贴纸的编辑刷新
	1、重置贴纸选中
	2、更新右边贴纸信息
	3、刷新贴纸列表：不选中
]]
function M:OnStickerCloseClicked()
    -- CError("SSSSSSSSSSSSSSSSSSSSSSS 编辑贴纸关闭：处理未装备贴纸的编辑刷新!!")

    if self.OnCloseStickerEdit then
        self.OnCloseStickerEdit()
    end
    
	-- self.CurSelectStickerId = 0
	-- self.CurSelectStickerSlot = 0
	-- self:UpdateEditStickerShow()
	-- self.ReuseList_Sticker:Refresh()
end

--水平翻转
function M:OnStickerAlignClicked(StickerId)
    -- CError("SSSSSSSSSSSSSSSSSSSSSSS 水平翻转!!")
end

--镜像
function M:OnStickerMirrorClicked(StickerId)
    -- CError("SSSSSSSSSSSSSSSSSSSSSSS 镜像!!")
end

function M:OnEditInfoTransform(InputChgData)
    -- CError(string.format("OnEditInfoTransform 根据2DUI编辑结果,包含了水平翻转,镜像 = %s", table.tostring(InputChgData)))
    if InputChgData == nil then
        return
    end

    if self.OnEditorStickerNtf then
        local Param = {
            ScaleDir = InputChgData.Scale,
            RotateAngle = InputChgData.RotateAngle,
            ScaleLength = InputChgData.ScaleLength,
            AbsolutePos = InputChgData.AbsolutePos,
        }
        -- local Local =  UE.USlateBlueprintLibrary.AbsoluteToLocal(self.StickerPanel:GetCachedGeometry(), InputChgData.AbsolutePos)
        self.OnEditorStickerNtf(Param)
    end
end

---------------------------------------------------回调<<

------------------------------------------OnMouseEvent>>


function M:OnMouseButtonDown(InMyGeometry, InMouseEvent)
    -- CError("M:OnMouseButtonDown")
    self.bIsMouseButtonUp = false
    if self.StickerEditHandler and self.StickerEditHandler:IsValid() then
		return self.StickerEditHandler.ViewInstance:OnMouseButtonDown(InMyGeometry, InMouseEvent)
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function M:OnMouseButtonUp(InMyGeometry, InMouseEvent)

    -- CError("M:OnMouseButtonUp")
    self.bIsMouseButtonUp = true

    if self.StickerEditHandler and self.StickerEditHandler:IsValid() then
		return self.StickerEditHandler.ViewInstance:OnMouseButtonUp(InMyGeometry, InMouseEvent)
	end
   
    return UE.UWidgetBlueprintLibrary.Handled()
end

function M:OnMouseMove(InMyGeometry, InMouseEvent)
    -- CError("M:OnMouseMove")
	if self.StickerEditHandler and self.StickerEditHandler:IsValid() then
		return self.StickerEditHandler.ViewInstance:OnMouseMove(self.LimitBox, InMyGeometry, InMouseEvent)
	end
  
    return UE.UWidgetBlueprintLibrary.Handled()
end

function M:OnMouseLeave(InMouseEvent)
    -- CError("M:OnMouseLeave")
    if self.bIsMouseButtonUp == nil or self.bIsMouseButtonUp then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    -- 检测鼠标是否移动到屏幕外
    local curPos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent)
    -- local curPos = UE.UKismetInputLibrary.PointerEvent_GetLastScreenSpacePosition(InMouseEvent)
    local EditPanelGeometry = self.EditPanel:GetCachedGeometry()
    local LimitBoxGeometry = self.LimitBox:GetCachedGeometry()
    -- local TopLeft = UE.USlateBlueprintLibrary.GetLocalTopLeft(EditPanelGeometry)
    local bIsUnderLocation = UE.USlateBlueprintLibrary.IsUnderLocation(EditPanelGeometry, curPos)
    if bIsUnderLocation then
        bIsUnderLocation = UE.USlateBlueprintLibrary.IsUnderLocation(LimitBoxGeometry, curPos)
    end
    CWaring(string.format("M:OnMouseLeave curPos = %s,bIsUnderLocation = %s", table.tostring(curPos), tostring(bIsUnderLocation)))
    if not(bIsUnderLocation) then
        -- CError(string.format("M:OnMouseLeave curPos = %s,bIsUnderLocation = %s",table.tostring(curPos),tostring(bIsUnderLocation)))
        if self.StickerEditHandler and self.StickerEditHandler:IsValid() then
            return self.StickerEditHandler.ViewInstance:OnMouseLeaveScreen(nil, InMouseEvent)
        end
    end
  
    return UE.UWidgetBlueprintLibrary.Handled()
end

------------------------------------------OnMouseEvent<<

return M