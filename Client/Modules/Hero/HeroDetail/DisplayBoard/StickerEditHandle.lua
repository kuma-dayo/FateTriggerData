--[[
    用于 局外展示板系统-贴纸页签编辑功能 的逻辑类
]]

local class_name = "StickerEditHandle"
StickerEditHandle = StickerEditHandle or BaseClass(nil, class_name)


function StickerEditHandle:OnInit()
	self.BindNodes = {
        { UDelegate = self.View.Btn_Close.OnClicked,				Func = Bind(self,self.OnBtnCloseClick) },
        { UDelegate = self.View.Btn_Close.OnHovered,				Func = Bind(self, self.OnBtnCloseHover) },
		{ UDelegate = self.View.Btn_Close.OnUnhovered,				Func = Bind(self, self.OnBtnCloseUnhover) },

        { UDelegate = self.View.Btn_Alignment.OnClicked,			Func = Bind(self,self.OnBtnAlignmentClick) },
        { UDelegate = self.View.Btn_Alignment.OnHovered,				Func = Bind(self, self.OnBtnAlignmentHover) },
		{ UDelegate = self.View.Btn_Alignment.OnUnhovered,				Func = Bind(self, self.OnBtnAlignmentUnhover) },

        { UDelegate = self.View.Btn_Mirror.OnClicked,			Func = Bind(self,self.OnBtnMirrorClick) },
        { UDelegate = self.View.Btn_Mirror.OnHovered,				Func = Bind(self, self.OnBtnMirrorHover) },
		{ UDelegate = self.View.Btn_Mirror.OnUnhovered,				Func = Bind(self, self.OnBtnMirrorUnhover) },
    }

    self.MsgList = {
        { Model = CommonModel, MsgName = CommonModel.ON_WIDGET_TO_FOCUS,        Func = Bind(self, self.ON_WIDGET_TO_FOCUS_Fun) }, 
        { Model = InputModel, MsgName = InputModel.ON_COMMON_TOUCH_INPUT,		Func =  Bind(self,self.ON_COMMON_TOUCH_INPUT_Func) },
        { Model = InputModel, MsgName = InputModel.ON_TOUCH_LERP,		        Func =  Bind(self,self.ON_COMMON_TOUCH_INPUT_Func) }, 
    }

    self.VehicleSkinStickerEditUtil = require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerEditUtil")
end

function StickerEditHandle:OnShow(Param)
    Param = Param or {}
    -- CError(string.format("StickerEditHandle:OnShow,Param = %s",table.tostring(Param)))

    self.CallCloseFunc = Param.CallCloseFunc
    self.CallAlignmentFunc = Param.CallAlignmentFunc
    self.CallMirrorFunc = Param.CallMirrorFunc
    self.OnEditInfoTransformFunc = Param.OnEditInfoTransformFunc

    --TODO:显示水平翻转,关闭镜像翻转
    self.View.AlignmentLayer:SetVisibility(UE.ESlateVisibility.Visible)
    self.View.MirrorLayer:SetVisibility(UE.ESlateVisibility.Collapsed)

    self:EnterEdit(Param.EditParam)
end

function StickerEditHandle:OnHide(Param)
    -- CError("---------- StickerEditHandle:OnHide = ")
    if self.VehicleSkinStickerEditUtil ~= nil then
        -- CError("---------- StickerEditHandle:OnHide = 11111111111")
        self.VehicleSkinStickerEditUtil.FinishEditImage()
    end
    CommonUtil.SetCursorType(GameConfig.CursorType.Default)
    self.VehicleSkinStickerEditUtil = nil

    self:RemoveDelayFlushTimer()

    self.CallCloseFunc = nil
    self.CallAlignmentFunc = nil
    self.CallMirrorFunc = nil
    self.OnEditInfoTransformFunc = nil

    --清理
    self:OnEditEnd(true)
end

---@param Param StickerEditParam
function StickerEditHandle:OnManualShow(Param)
    -- CError(string.format("StickerEditHandle:OnManualShow,Param = %s",table.tostring(Param)))

    self:EnterEdit(Param.EditParam)
end

function StickerEditHandle:OnManualHide(Param)

end

function StickerEditHandle:UpdateUI(Param)
    -- CError(string.format("StickerEditHandle:UpdateUI,Param = %s",table.tostring(Param)))

    self.StickerId = Param.StickerId

    self:EnterEdit(Param.EditParam)
end


---@param EditParam StickerEditParam
function StickerEditHandle:EnterEdit(EditParam)
    -- CError(string.format("StickerEditHandle:EnterEdit,EditParam = %s", table.tostring(EditParam)))

    -- local ScreenPos = EditParam.AbsolutePos

    self:RemoveDelayFlushTimer()

    local Position = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.View.Content:GetCachedGeometry(), EditParam.AbsolutePos)
    local DirX = EditParam.Scale.X > 0 and 1 or -1
    local DirY = EditParam.Scale.Y > 0 and 1 or -1
    -- 进入编辑
    local InitEditParam = {
        -- Position = self:GetViewportPosition(EditParam.AbsolutePos),
        Position = Position,
        Scale = UE.FVector2D(DirX, DirY),
        -- RotateAngle = RoundFloat(UE.UKismetMathLibrary.RadiansToDegrees(self.StickerEditInfo.RotateAngle)),
        RotateAngle = EditParam.Angle,
        ScaleLength = math.abs(EditParam.Scale.X),
        InitSize = EditParam.InitSize,
    }
    -- CError("1111 ---------------- self.viewId ="..tostring(self.WidgetBase.viewId))
    self.VehicleSkinStickerEditUtil.SetScaleMax(HeroDefine.STICKER_SIZE_MAX)
    self.VehicleSkinStickerEditUtil.SetScaleMin(HeroDefine.STICKER_SIZE_MIN)
    self.VehicleSkinStickerEditUtil.EnterEditImage(self, InitEditParam)
    self:UpdateStickerEditPos()
end

function StickerEditHandle:RemoveDelayFlushTimer()
    if self.DelayFlushTimer then
        self:RemoveTimer(self.DelayFlushTimer)
    end
    self.DelayFlushTimer = nil
end

-- 更新底部按钮栏位置
-- 这里需要动态计算位置，蓝图锚点需左上方 alignmengt （1,0）
function StickerEditHandle:UpdateStickerEditPos()
    local Position = self.View.ImgPanel.Slot:GetPosition()
    local Size = self.View.ImgPanel.Slot:GetSize()
    local CurAlignment = self.View.ImgPanel.Slot:GetAlignment()
    local Angle = self.View.ImgPanel.RenderTransform.Angle
    if Angle < 0 then
        Angle = 360 + Angle
    end
    local Width = Size.X
    local CulAngle = Angle % 180
    if CulAngle > 90 then
        CulAngle = 180 - CulAngle
    end
    local Height = Size.X/2 * math.sin(UE.UKismetMathLibrary.DegreesToRadians(CulAngle)) + Size.Y / 2 * math.cos(UE.UKismetMathLibrary.DegreesToRadians(CulAngle)) + Size.Y / 2
    local StickerEditSize = self.View.Sticker_Edit.Slot:GetSize()
    self.View.Sticker_Edit.Slot:SetPosition(UE.FVector2D(Position.X +  Width - CurAlignment.X * Width + (StickerEditSize.X  - Width)* 0.5,Position.Y + Height  - CurAlignment.Y * Size.Y))
end

--[[
    根据2DUI编辑结果，来存储，并同步更新贴纸Component展示
]]
function StickerEditHandle:SetEditInfoTransform(InputChgData)
    -- CError(string.format(" 根据2DUI编辑结果,来存储,并同步更新贴纸Component展示 = %s", table.tostring(InputChgData)))
    if InputChgData == nil then
        return
    end
    
    local AbsolutePos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.View.Content:GetCachedGeometry(), UE.FVector2D(InputChgData.Position.X,InputChgData.Position.Y))
    InputChgData.AbsolutePos = AbsolutePos

    if self.OnEditInfoTransformFunc then
        self.OnEditInfoTransformFunc(InputChgData)
    end
end

function StickerEditHandle:OnEditEnd(bClean)
    -- if self:IsStickerEquip() then
    --     return
    -- end
    -- CommonUtil.SetCursorType(GameConfig.CursorType.Default)
    -- if not bClean then
    --     self:UpdateDecalComponentVisiblity(false)
    -- else
    --     local Param = {
    --         VehicleSkinId = self.VehicleSkinId,
    --         StickerInfo = self.StickerEditInfo,
    --     }
    --     MvcEntry:GetModel(ArsenalModel):DispatchType(ArsenalModel.ON_REMOVE_VEHICLE_SKIN_STICKER, Param)
    -- end
end

function StickerEditHandle:ON_COMMON_TOUCH_INPUT_Func()
    if self.StickerId == 0 then
        return
    end
    if self.Previewing then
        return
    end
    if  self.VehicleSkinStickerEditUtil then
        self.VehicleSkinStickerEditUtil.PostTransformChg()
    end
end

---------------------------- OnBtnEvent <<

function StickerEditHandle:OnBtnCloseClick()
    if self.CallCloseFunc ~= nil then
        self.CallCloseFunc()
    end
end

function StickerEditHandle:OnBtnCloseHover()
    self.View:PlayAnimation(self.View.vx_btn_close_hover)
end

function StickerEditHandle:OnBtnCloseUnhover()
    self.View:PlayAnimation(self.View.vx_btn_close_unhover)
end

function StickerEditHandle:OnBtnAlignmentClick()
    if not self.CallAlignmentFunc then
        return
    end
    self.CallAlignmentFunc(self.StickerId)
  
    if self.VehicleSkinStickerEditUtil then
        self.VehicleSkinStickerEditUtil.DoHorizontalFlip()
    end
   
    self.View:PlayAnimation(self.View.vx_btn_aligment_click)
    -- self.View:PlayAnimation(self.View.vx_btn_aligment_unclick)
end

function StickerEditHandle:OnBtnAlignmentHover()
    self.View:PlayAnimation(self.View.vx_btn_aligment_hover)
end

function StickerEditHandle:OnBtnAlignmentUnhover()
    self.View:PlayAnimation(self.View.vx_btn_aligment_unhover)
end

function StickerEditHandle:OnBtnMirrorClick()
    if not self.CallMirrorFunc then
        return
    end
    self.CallMirrorFunc(self.StickerId)

    if self.VehicleSkinStickerEditUtil then
        self.VehicleSkinStickerEditUtil.DoMirrorFlip()
    end

    self.View:PlayAnimation(self.View.vx_btn_mirror_click)
    -- self.View:PlayAnimation(self.View.vx_btn_mirror_unclick)
end

function StickerEditHandle:OnBtnMirrorHover()
    self.View:PlayAnimation(self.View.vx_btn_mirror_hover)
end

function StickerEditHandle:OnBtnMirrorUnhover()
    self.View:PlayAnimation(self.View.vx_btn_mirror_unhover)
end

---------------------------- OnBtnEvent <<

---------------------------- OnMouseEvent >>

function StickerEditHandle:OnMouseMove(LimitBox, InMyGeometry, InMouseEvent)
    if self.StickerId == 0 then
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
	if self.VehicleSkinStickerEditUtil and self.VehicleSkinStickerEditUtil.OnMouseMove then
		local ReturnEvent = self.VehicleSkinStickerEditUtil.OnMouseMove(self.View, LimitBox, InMyGeometry, InMouseEvent)
        self:UpdateStickerEditPos()
        return ReturnEvent
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function StickerEditHandle:OnMouseButtonDown(InMyGeometry, InMouseEvent)
    if self.StickerId == 0 then
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
	if self.VehicleSkinStickerEditUtil and self.VehicleSkinStickerEditUtil.OnMouseButtonDown then
		return self.VehicleSkinStickerEditUtil.OnMouseButtonDown(self.View, InMyGeometry, InMouseEvent)
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function StickerEditHandle:OnMouseButtonUp(InMyGeometry, InMouseEvent)
    if self.StickerId == 0 then
        -- CError("StickerEditHandle:OnMouseButtonUp 00")
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
    if self.VehicleSkinStickerEditUtil and self.VehicleSkinStickerEditUtil.OnMouseButtonUp then
        -- CError("StickerEditHandle:OnMouseButtonUp 11")
		return self.VehicleSkinStickerEditUtil.OnMouseButtonUp(self.View, InMyGeometry, InMouseEvent)
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function StickerEditHandle:OnMouseLeaveScreen()
    if self.StickerId == 0 then
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
    if self.VehicleSkinStickerEditUtil and self.VehicleSkinStickerEditUtil.OnMouseLeaveScreen then
		return self.VehicleSkinStickerEditUtil.OnMouseLeaveScreen(self.View)
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

---------------------------- OnMouseEvent <<

---------------------------- CommitEdit >>

-- function StickerEditHandle:CommitEdit(AutoSave)
--     if AutoSave then
--         self:OnEditEnd()
--     end
--     if not self:CanCommit() then
--         return false
--     end
--     MvcEntry:GetCtrl(ArsenalCtrl):SendProto_UpdateVehicleSkinSticker(self.VehicleSkinId, self.StickerEditInfo, 
--         AutoSave and VehicleSkinStickerMdt.StickerUpdateType.AUTOSAVED or VehicleSkinStickerMdt.StickerUpdateType.EQUIP)
--     return true
-- end

----------------------------CommitEdit <<


--- 监听 UI 焦点切换
function StickerEditHandle:ON_WIDGET_TO_FOCUS_Fun(_, viewId)
    -- CError(string.format("监听 UI 焦点切换,Param =%s",tostring(viewId)))

    -- ViewConst.HeroDisplayBoardStickerEdit --2205
    --当商城界面重新获取焦点时,刷新UI数据
    local theViewId = self.WidgetBase and self.WidgetBase.viewId or ViewConst.HeroDisplayBoardStickerEdit
    if viewId ~= theViewId then
        -- CError("1111 viewId ~= ViewConst.HeroDisplayBoardStickerEdit")

        if self.VehicleSkinStickerEditUtil then
            self.VehicleSkinStickerEditUtil.SetCanEdit(false)
        end
        CommonUtil.SetCursorType(GameConfig.CursorType.Default)
    else
        if self.VehicleSkinStickerEditUtil then
            self.VehicleSkinStickerEditUtil.SetCanEdit(true)
        end
    end
end

return StickerEditHandle
