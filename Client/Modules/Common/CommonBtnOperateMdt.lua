--[[
    通用按钮展开菜单界面
]]

local class_name = "CommonBtnOperateMdt";
CommonBtnOperateMdt = CommonBtnOperateMdt or BaseClass(GameMediator, class_name);


--头像操作弹窗的对齐规则类型
CommonBtnOperateMdt.FocusTypeEnum = {
    LEFT = 1,
    RIGHT = 2,
    TOP = 3,
    --在Icon下面
    BOTTOM = 4,
}


function CommonBtnOperateMdt:__init()
end

function CommonBtnOperateMdt:OnShow(data)
end

function CommonBtnOperateMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.BindNodes = {
        { UDelegate = self.GUIButton_OtherSide.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_OtherSide) },
    }

    self.MsgList = {
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED,    Func = self.OnOtherViewShowed },
    }

end

--[[
    
    Param = {
        -- 自行传入按钮文字和回调函数
        ActionBtnTypeList = {
            [1] = {OperateStr = "添加好友",Func = OnClick_AddFriend},
            [2] = {OperateStr = "移除好友",Func = OnClick_DeleteFriend},
        }
        --需要采样的位置（决定自己的显示位置）
        FocusWidget
        --采样位置偏移
        FocusOffset
        --采样规则
        FocusType
        --绝对位置（与FocusWidget互斥，两者都有优先执行FocusWidget逻辑）
        AbsolutePosition
    }
]]
function M:OnShow(Param)
    self.Param = Param
   
    self.FocusType = self.Param.FocusType or CommonBtnOperateMdt.FocusTypeEnum.RIGHT   -- 默认位置改为右侧
    self.ActionBtnTypeList = self.Param.ActionBtnTypeList or {}
    self.BtnList:ClearChildren()
    for _,BtnTypeInfo in ipairs(self.ActionBtnTypeList) do
        if BtnTypeInfo then
            local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/Components/WBP_CommonBtn_Item.WBP_CommonBtn_Item")
            local Widget = NewObject(WidgetClass, self)
            self.BtnList:AddChild(Widget)

            local ClickFunc = function()
                BtnTypeInfo.Func()
                self:DoClose()
            end
            local BindNode = {UDelegate = Widget.BtnClick.OnClicked,Func = ClickFunc}
            table.insert(self.BindNodes,BindNode)

            Widget.LbName:SetText(StringUtil.Format(BtnTypeInfo.OperateStr))
        end
    end
    self:ReRegister()
    self.PanelRoot:SetRenderScale(UE.FVector2D(0.1,0.1))
    
    Timer.InsertTimer(-1,function ()
        if CommonUtil.IsValid(self.PanelRoot) then
            self.PanelRoot:SetRenderScale(UE.FVector2D(1,1))
            local BtnListSize = UE.USlateBlueprintLibrary.GetLocalSize(self.BtnList:GetCachedGeometry())
            local ImgSize = self.ListBg.Slot:GetSize()
            ImgSize.y = BtnListSize.y
            self.ListBg.Slot:SetSize(ImgSize)

            if self.Param.FocusWidget then
                local PanelSize = self.PanelRoot:GetDesiredSize()
                local PixelPosition,ViewportPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,self.Param.FocusWidget:GetCachedGeometry(),UE.FVector2D(0,0))
                local FocusSize = UE.USlateBlueprintLibrary.GetLocalSize(self.Param.FocusWidget:GetCachedGeometry())
                local FocusScale = self.Param.FatherScale or 1
                FocusSize.x = FocusSize.x * FocusScale
                FocusSize.y = FocusSize.y * FocusScale
                local PanelRootPos = self:CalculatePanelRootPos(ViewportPosition,FocusSize,BtnListSize,PanelSize,true)
                self.PanelRoot.Slot:SetPosition( PanelRootPos)
            end
        end
    end)
end

function M:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,Check)
    -- 水平方向两侧有空白区域
    local PanelOffset = UE.FVector2D(0,0)
    PanelOffset.x = (PanelSize.x - ImgSize.x)/2 
    PanelOffset.y = (PanelSize.y - ImgSize.y)/2 

    -- Icon侧边空白区域大小
    local FocusScale = self.Param.FatherScale or 1
    local FocusOffset = self.Param.FocusOffset or UE.FVector2D(0,0)
    FocusOffset.x = FocusOffset.x * FocusScale
    FocusOffset.y = FocusOffset.y * FocusScale
    local TmpXFix = ViewportPosition.x
    local TmpYFix = ViewportPosition.y
    local ViewportSize = CommonUtil.GetViewportSize(self)
    if self.FocusType == CommonBtnOperateMdt.FocusTypeEnum.BOTTOM then
        TmpXFix = TmpXFix - (PanelSize.x - FocusSize.x)/2
        TmpYFix = TmpYFix + FocusSize.y - FocusOffset.y
        if Check then
            if (TmpYFix + ImgSize.y/2) > ViewportSize.y then
                CWaring("CalculatePanelRootPos Check Fail:" .. self.FocusType .. "|Value:" .. TmpYFix)
                self.FocusType = CommonBtnOperateMdt.FocusTypeEnum.TOP
                return self:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,false)
            end
        end
    elseif self.FocusType == CommonBtnOperateMdt.FocusTypeEnum.TOP then
        TmpXFix = TmpXFix - (PanelSize.x - FocusSize.x)/2
        TmpYFix = TmpYFix - ImgSize.y + PanelOffset.y + FocusOffset.y
        if TmpYFix1 then
            if (TmpYFix - ImgSize.y) < 0 then
                CWaring("CalculatePanelRootPos Check Fail:" .. self.FocusType .. "|Value:" .. TmpYFix)
                self.FocusType = CommonBtnOperateMdt.FocusTypeEnum.BOTTOM
                return self:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,false)
            end
        end
    elseif self.FocusType == CommonBtnOperateMdt.FocusTypeEnum.RIGHT then
        TmpXFix = TmpXFix - PanelOffset.x - FocusOffset.x + FocusSize.x
        TmpYFix = TmpYFix + FocusOffset.y
        -- 左右侧增加上下对齐判断 -> 默认顶对齐,超出了就底对齐
        if (TmpYFix + ImgSize.y) > ViewportSize.y then
            TmpYFix = TmpYFix - ImgSize.y + FocusSize.y - FocusOffset.y
        end
        if Check then
            if (TmpXFix + ImgSize.x) > ViewportSize.x then
                CWaring("CalculatePanelRootPos Check Fail:" .. self.FocusType .. "|Value:" .. TmpXFix)
                self.FocusType = CommonBtnOperateMdt.FocusTypeEnum.LEFT
                return self:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,false)
            end
        end
    elseif self.FocusType == CommonBtnOperateMdt.FocusTypeEnum.LEFT then
        TmpXFix = TmpXFix - PanelOffset.x + FocusOffset.x - ImgSize.x
        TmpYFix = TmpYFix + FocusOffset.y
        -- 左右侧增加上下对齐判断 -> 默认顶对齐,超出了就底对齐
        if (TmpYFix + ImgSize.y) > ViewportSize.y then
            TmpYFix = TmpYFix - ImgSize.y + FocusSize.y - FocusOffset.y
        end
        if Check then
            if TmpXFix < 0 then
                CWaring("CalculatePanelRootPos Check Fail:" .. self.FocusType .. "|Value:" .. TmpXFix)
                self.FocusType = CommonBtnOperateMdt.FocusTypeEnum.RIGHT
                return self:CalculatePanelRootPos(ViewportPosition,FocusSize,ImgSize,PanelSize,false)
            end
            
        end
    end
    return UE.FVector2D(TmpXFix,TmpYFix)
end

function M:OnHide()
end

function M:OnClick_GUIButton_OtherSide()
    self:DoClose()
end

function M:DoClose()
    MvcEntry:CloseView(self.viewId)
end


-- 监听其他pop层界面打开，则关闭自身
function M:OnOtherViewShowed(ViewId)
    if ViewId == self.viewId then
        return
    end
    local Mdt =  MvcEntry:GetCtrl(ViewRegister):GetView(ViewId)
    if Mdt and Mdt.uiLayer and Mdt.uiLayer ==  UIRoot.UILayerType.Pop then
        -- 有其他pop层界面打开时候，关闭自身
        CLog("CommonBtnOperateMdt Closed for OpenView:"..ViewId)
        self:DoClose()
    end
end

return M