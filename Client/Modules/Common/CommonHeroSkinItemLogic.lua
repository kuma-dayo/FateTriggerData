--[[
    针对 WBP_CommonItemVertical 逻辑处理
]]
local class_name = "CommonHeroSkinItemLogic"
local CommonHeroSkinItemLogic = BaseClass(UIHandlerViewBase, class_name)


function CommonHeroSkinItemLogic:OnInit()
    self.BindNodes = {
    	{ UDelegate = self.View.MainBtn.OnClicked,	Func = Bind(self,self.MainBtn_OnClicked) },
	}
    self.IsSelect = false
    self.IsLock = false
end

function CommonHeroSkinItemLogic:OnShow()
    
end

function CommonHeroSkinItemLogic:OnHide()
    self.IsSelect = false
    self.IsLock = false
end

--[[
    Param = {
        HeroSkinId,
        BtnClickFunc,
    }
]]
function CommonHeroSkinItemLogic:SetData(Param)
    if not (Param and Param.HeroSkinId) then
        return
    end
    self.Param = Param
    if Param.IsSelect then
        self.IsSelect = Param.IsSelect
    end
    if Param.IsLock then
        self.IsLock = Param.IsLock
    end
    self:UpdateImg()
    self:UpdateState()
end

-- 更新展示
function CommonHeroSkinItemLogic:UpdateImg()
    if not self.Param then
        return
    end
    local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,self.Param.HeroSkinId)
    if not TblSkin then
        return
    end
    -- Icon展示
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImageIcon,TblSkin[Cfg_HeroSkin_P.HalfBodyBGPNGPath])
end

-- 更新锁定&选中状态
function CommonHeroSkinItemLogic:UpdateState()
    -- UX动效控制效果
    if self.IsLock then self.View:VXE_Btn_Bg_Lock() else self.View:VXE_Btn_Bg_Unlock() end
    if self.IsSelect then self.View:VXE_Btn_Select() else self.View:VXE_Btn_UnSelect() end
end

-- 同时设置选中和锁定状态
function CommonHeroSkinItemLogic:SetState(Param)
    self.IsSelect = Param.IsSelect
    self.IsLock = Param.IsLock
    self:UpdateState()
end

-- 是否选中
function CommonHeroSkinItemLogic:SetIsSelect(IsSelect)
    self.IsSelect = IsSelect
    self:UpdateState()
end

-- 是否锁定
function CommonHeroSkinItemLogic:SetIsLock(IsLock)
    self.IsLock = IsLock
    self:UpdateState()
end

function CommonHeroSkinItemLogic:MainBtn_OnClicked()
    if self.Param and self.Param.BtnClickFunc then
        self.Param.BtnClickFunc()
    end
end

return CommonHeroSkinItemLogic
