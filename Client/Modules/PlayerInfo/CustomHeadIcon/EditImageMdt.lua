--[[
   个人信息 - 编辑头像图片界面
]] 
local class_name = "EditImageMdt";
EditImageMdt = EditImageMdt or BaseClass(GameMediator, class_name);

function EditImageMdt:__init()
end

function EditImageMdt:OnShow(data)
end

function EditImageMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    -- 取消
    UIHandler.New(self, self.WBP_CommonBtn_Left, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.GUIButton_Close_ClickFunc),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1048"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

    -- 确认上传按钮
    UIHandler.New(self, self.WBP_CommonBtn_Right, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.GUIButton_UploadHead_ClickFunc),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1049"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

	-- 图片限制移动的坐标  
	self.LimitMovePos = {
		-- 图片移动限制左侧坐标
		LimitLeftX = 0,
		-- 图片移动限制右侧坐标
		LimitRightX = 0,
		-- 图片移动限制上侧坐标
		LimitTopY = 0,
		-- 图片移动限制下侧坐标
		LimitDownY = 0
	}

	-- 图片尺寸相关信息  
	self.SourceSizeInfo = {
		-- 锚点跟左侧边缘的宽度差距
		LeftWidth = 0,
		-- 锚点跟右侧边缘的宽度差距
		RightWidth = 0,
		-- 锚点跟上侧边缘的高度差距
		TopHight = 0,
		-- 锚点跟下侧边缘的高度差距
		DownHight = 0,
	}
	-- 是否已经选择图片
	self.IsSelect = false
	-- 初始显示缩放值  输出图片大小256*256  选中框为690*690 所以原图需要放大2.7倍，截图范围才对应的上
	self.InitScale = 2.7
	-- 最小缩放值
	self.MinScale = 2.7 
	-- 最大缩放值
	self.MaxScale = 3.7
	-- 当前初始化缩放值
	self.CurScale = self.InitScale
	-- 选中的图片路径
	self.FilePath = ""

	---@type PersonalInfoCtrl
	self.PersonalInfoCtrl = MvcEntry:GetCtrl(PersonalInfoCtrl)
	---@type HeadIconSettingModel
	self.HeadIconSettingModel = MvcEntry:GetModel(HeadIconSettingModel)
end


--[[
	local Param = {
		-- 选中的图片路径
		FilePath
	}
]]
function M:OnShow(Param)
	if Param and Param.FilePath then
		self.FilePath = Param.FilePath
	else
		CError("[hz] EditImageMdt OnShow Param is nil ")
	end
	self:InitLimitMovePosition()
	self:InitSourceImageShow()
end

-- 初始化可移动的范围
function M:InitLimitMovePosition()
	local CurPos = self.GUIImage_Head.Slot:GetPosition()
	local CurSize = self.GUIImage_Head.Slot:GetSize()
    local CurAlignment = self.GUIImage_Head.Slot:GetAlignment()

	self.LimitMovePos.LimitLeftX = CurPos.X - CurAlignment.X * CurSize.X
	self.LimitMovePos.LimitRightX = CurPos.X + (1 - CurAlignment.X) * CurSize.X
	self.LimitMovePos.LimitTopY = CurPos.Y - CurAlignment.Y * CurSize.Y
	self.LimitMovePos.LimitDownY = CurPos.Y + (1 - CurAlignment.Y) * CurSize.Y

	-- 初始坐标点
	self.InitPos = self.GUIImage_Source.Slot:GetPosition()
	-- 当前图片移动的偏差值
	self.CurDeltaPos = UE.FVector2D(0, 0)	
end

-- 初始化源图展示
function M:InitSourceImageShow()
	if self.FilePath and self.FilePath ~= "" then
        local TheTexture = UE.UKismetRenderingLibrary.ImportFileAsTexture2D(self,self.FilePath)
        if TheTexture then
            self.GUIImage_Source:SetBrushFromTexture(TheTexture, true)
            self.GUIImage_Source:SetVisibility(UE.ESlateVisibility.Visible)
            self.IsSelect = true
			self.GUIImage_Source:SetRenderScale(UE.FVector2D(self.CurScale,self.CurScale))
			self.GUIImage_Source.Slot:SetPosition(UE.FVector2D(self.InitPos.X, self.InitPos.Y))
			self.CurPos = UE.FVector2D(self.InitPos.X, self.InitPos.Y)
			
			-- self.GUIImage_Target:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

-- 刷新来源图片尺寸相关信息
function M:UpdateSourceSizeInfo()
	local CurSize = UE.USlateBlueprintLibrary.GetLocalSize(self.GUIImage_Source:GetCachedGeometry())
	local CurAlignment = self.GUIImage_Source.Slot:GetAlignment()

	self.SourceSizeInfo.LeftWidth = CurSize.X * CurAlignment.X
	self.SourceSizeInfo.RightWidth = CurSize.X * (1 - CurAlignment.X)
	self.SourceSizeInfo.TopHight = CurSize.Y * CurAlignment.Y
	self.SourceSizeInfo.DownHight = CurSize.Y * (1 - CurAlignment.Y)
end

function M:OnHide()
    
end

-- 点击关闭
function M:GUIButton_Close_ClickFunc()
    MvcEntry:CloseView(ViewConst.EditImageMdt)
end

-- 上传头像点击
function M:GUIButton_UploadHead_ClickFunc()
	self:UpdateSourceSizeInfo()

	local IsCanUpload = self.HeadIconSettingModel:CheckIsCanUploadCustomHeadUrl()
	if IsCanUpload then
		local TargetOriTexture = UE.UGameHelper.GetTextureFromImage(self.GUIImage_Source)
		if TargetOriTexture then
			local CurSourcePos = self.GUIImage_Source.Slot:GetPosition()
			local CurSourceSize = UE.USlateBlueprintLibrary.GetLocalSize(self.GUIImage_Source:GetCachedGeometry())
			local CurHeadSize = self.GUIImage_Head.Slot:GetSize()
	
			-- 截取的X坐标（0，0锚点）  选中框的左边界 - 图片的左边界  获得截取的X坐标点  最后除于放大的倍数即可得到原图的坐标点
			local InterceptPosX = math.floor(math.max(((self.LimitMovePos.LimitLeftX - (CurSourcePos.X - self.SourceSizeInfo.LeftWidth * self.CurScale))/self.CurScale), 0))
			-- 截取的Y坐标（0，0锚点）  选中框的上边界 - 图片的上边界  获得截取的Y坐标点  最后除于放大的倍数即可得到原图的坐标点
			local InterceptPosY = math.floor(math.max(((self.LimitMovePos.LimitTopY - (CurSourcePos.Y - self.SourceSizeInfo.TopHight * self.CurScale))/self.CurScale), 0))
	
			-- 截取大小不能超过图片本身的大小
			local MaxWidth = CurSourceSize.X - InterceptPosX
			local MaxHeight = CurSourceSize.Y - InterceptPosY
	
			local InterceptWidth = math.floor((math.min(CurHeadSize.X / self.CurScale, MaxWidth)))
			local InterceptHeight = math.floor((math.min(CurHeadSize.Y / self.CurScale, MaxHeight)))

			local TargetTexture = UE.UGameHelper.CopyTextureRegion(TargetOriTexture, InterceptPosX, InterceptPosY, InterceptWidth, InterceptHeight)
			if TargetTexture then
				self.GUIImage_Source:SetVisibility(UE.ESlateVisibility.Collapsed)
				local PictureIntType = HttpModel.Const_PictureIntType.PNG
				UE.UGFUnluaHelper.EncodeTextureToString(TargetTexture, PictureIntType,1, function(ImageData)
                    if ImageData then
						local PictureStringType = MvcEntry:GetModel(HttpModel):GetPictureStringTypeByIntType(PictureIntType)
                        self.PersonalInfoCtrl:SendProto_UploadPortraitReq(ImageData, PictureStringType)
                        self:GUIButton_Close_ClickFunc()

                        -- self.GUIImage_Target:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                        -- self.GUIImage_Target:SetBrushFromTexture(TargetTexture, true)
                    else
                        CError("[hz] EditImage GUIButton_UploadHead_ClickFunc  ImageData is Nil  InterceptPosX = " .. tostring(InterceptPosX) .. " InterceptPosY = " .. tostring(InterceptPosY).. " InterceptWidth = " .. tostring(InterceptWidth) .. " InterceptHeight = " .. tostring(InterceptHeight))
                    end
                end)
			end
		end	
	else
		local TipsStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1051")
		UIAlert.Show(TipsStr)
	end
end

function M:On_GUIImage_Source_MouseButtonDown(Geometry, MouseEvent)
    if not self.IsSelect then
        return
    end
	self.IsClick = true
	self:UpdateSourceSizeInfo()
	-- 点击位置
    local BeginScreenSpacePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
	local _,BeginViewPortPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(self,BeginScreenSpacePos)
	-- 视口相对位置
	self.BeginViewPortPos = BeginViewPortPos
	self.CurPos = self.GUIImage_Source.Slot:GetPosition()
    return UE.UWidgetBlueprintLibrary.Handled()
end

-- Move事件必须基于背景层。如果基于当前图片，会存在滑动过快导致滑出了图片区域，而位置更新跟不上停住的问题
function M:OnMouseMove(Geometry, MouseEvent)
	-- print("============ On_GUIImage_Source_MouseMove")
	if not self.IsClick then
		return UE.UWidgetBlueprintLibrary.Handled()
	end
	local CurScreenSpacePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
	local _,CurViewPortPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(self,CurScreenSpacePos)
	local DeltaPosX,DeltaPosY = CurViewPortPos.X - self.BeginViewPortPos.X,CurViewPortPos.Y - self.BeginViewPortPos.Y

	-- 头像框不超过图片边缘
	local TargetX = self.CurPos.X + DeltaPosX
	local TargetY = self.CurPos.y + DeltaPosY
	-- 是否可以水平方向移动
	local IsCanMoveHorizontal = TargetX - self.SourceSizeInfo.LeftWidth * self.CurScale <= self.LimitMovePos.LimitLeftX and TargetX + self.SourceSizeInfo.RightWidth * self.CurScale >= self.LimitMovePos.LimitRightX
	-- 是否可以竖直方向移动
	local IsCanMoveVertical = TargetY - self.SourceSizeInfo.TopHight * self.CurScale <= self.LimitMovePos.LimitTopY and TargetY + self.SourceSizeInfo.DownHight * self.CurScale >= self.LimitMovePos.LimitDownY
	if IsCanMoveHorizontal or IsCanMoveVertical then
		self.CurDeltaPos.X = IsCanMoveHorizontal and DeltaPosX or self.CurDeltaPos.X
		self.CurDeltaPos.Y = IsCanMoveVertical and DeltaPosY or self.CurDeltaPos.Y
		-- CLog("[hz]    EditImageMdt:OnMouseMove = true    DeltaPosX = " .. tostring(DeltaPosX) .. " DeltaPosY = " .. tostring(DeltaPosY))
		self:OnMoveImage(self.CurDeltaPos.X,self.CurDeltaPos.Y)
	end
	return UE.UWidgetBlueprintLibrary.Handled()
end

function M:On_GUIImage_Source_MouseButtonUp(Geometry, MouseEvent)
	print("============ On_GUIImage_Source_MouseButtonUp")
	self.IsClick = false
	self.CurDragPos = nil
    return UE.UWidgetBlueprintLibrary.Handled()
end

function M:On_GUIImage_Source_MouseWheel(Geometry, MouseEvent)
	local WheelDelta = UE.UKismetInputLibrary.PointerEvent_GetWheelDelta(MouseEvent)
	self:OnScaleImage(WheelDelta)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function M:OnScaleImage(Delta)
	local CurrentScale = self.GUIImage_Source.RenderTransform.Scale.X
	if Delta > 0 then
		CurrentScale = CurrentScale + 0.1
	elseif Delta < 0 then
		CurrentScale = CurrentScale - 0.1
	end
	if CurrentScale < self.MinScale then
		CurrentScale = self.MinScale
	elseif CurrentScale > self.MaxScale then
		CurrentScale = self.MaxScale
	end

	self.CurScale = CurrentScale
	self.GUIImage_Source:SetRenderScale(UE.FVector2D(CurrentScale,CurrentScale))
end

function M:OnMoveImage(DeltaPosX,DeltaPosY)
	if self.CurPos then
		self.GUIImage_Source.Slot:SetPosition(UE.FVector2D(self.CurPos.X + DeltaPosX,self.CurPos.Y + DeltaPosY))
	end
end

return M
