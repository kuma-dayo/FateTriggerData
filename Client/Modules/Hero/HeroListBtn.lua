local class_name = "HeroListBtn"
---@class HeroListBtn
local HeroListBtn = BaseClass(nil, class_name)


function HeroListBtn:OnInit()
    UIHandler.New(self,self.View.GUIButton, CommonButtonExtend, 
    {
        ClickFunc = Bind(self,self.OnClicked_BtnClick),
        RightClickFunc = Bind(self,self.OnRightMouseClicked_BtnClick)
    })

    self.MsgList = {
		{Model = HeroModel, MsgName = HeroModel.ON_PLAYER_LIKE_HERO_CHANGE,	Func = Bind(self, self.UpdateBtnState) },
		{Model = HeroModel, MsgName = HeroModel.ON_HERO_LIKE_SKIN_CHANGE,	Func = Bind(self, self.UpdateSkin) },
	}
    self.Param = nil
end

function HeroListBtn:OnShow(Param)

end

function HeroListBtn:OnHide()
end

--[[
    {
        Data 
        ClickFunc
        RightClickFunc
        Index
        ExtraData = {
            isLocked = true   --是否已经解锁了
        }
        RedDotKey  红点前缀参数 有值就需要展示红点
    }
]]
function HeroListBtn:SetData(Param)
    --TODO 根据数据进行展示
    self.Param = Param
    self:UpdateSkin()
    self:UpdateBtnState()

    self:RegisterRedDot()
end

-- 注册红点
function HeroListBtn:RegisterRedDot()
    if self.Param and self.Param.RedDotKey then
        --绑定红点
        local RedDotKey = self.Param.RedDotKey
        local RedDotSuffix = self.Param.Data[Cfg_HeroConfig_P.Id]
        if not self.RedDot then
            CLog("[hz] WBP_RedDotFactory")
            self.View.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.RedDot = UIHandler.New(self, self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        else 
            self.RedDot:ChangeKey(RedDotKey, RedDotSuffix)
        end
    else
        self.View.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function HeroListBtn:UpdateSkin()
    local FavoriteSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(self.Param.Data[Cfg_HeroConfig_P.Id])
    local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,FavoriteSkinId)
    if not TblSkin then
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.HeroIcon,TblSkin[Cfg_HeroSkin_P.PNGPath])
end

---Data中的数据结构同HeroConfig结构一致，且一般不会有改变，所以就不去污染它了
---其他的额外数据存储再ExtraData字段中，更新这个字段请使用这个函数
---这个函数会触发一次 UpdateBtnState()
function HeroListBtn:UpdateExtraData(ExtraData)
    self.Param.ExtraData = ExtraData

    self:UpdateBtnState()
end

---按钮一共有以下形态 ①②③，为了方便管理，同一为一个函数来处理。
--- 一、未解锁 ① [参考 self.Param.ExtraData.isLocked，当这个字段为true时则为未解锁状态]
--- 二、已解锁
---     a.标记为喜欢 ② [是否标记为喜欢，需要判断当前数据中的英雄id是否等于HeroModel中存放的喜欢的英雄id]
---     b.未标记为喜欢 ③
function HeroListBtn:UpdateBtnState()
    self.IsLock = self.Param.ExtraData and self.Param.ExtraData.isLocked
    self.IsLikeNow = self.Param.Data[Cfg_HeroConfig_P.Id] == MvcEntry:GetModel(HeroModel):GetFavoriteId()
    --0.默认 1.喜欢 2.锁住
    self.View:SetWidgetState(self.IsLock and 2 or (self.IsLikeNow and 1 or 0), self.IsSelect)
    self.View.Img_SubLeft:SetVisibility(self.IsLikeNow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.Img_SubRight:SetVisibility(self.IsLock and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function HeroListBtn:GetIndex()
    return self.Param.Index
end

function HeroListBtn:Select()
    self.IsSelect = true
    self:UpdateBtnState()
end

function HeroListBtn:UnSelect()
    self.IsSelect = false
    self:UpdateBtnState()
end

function HeroListBtn:OnClicked_BtnClick()
    if self.Param and self.Param.ClickFunc then
        self.Param.ClickFunc()
    end
end

function HeroListBtn:OnRightMouseClicked_BtnClick()
    if self.Param and self.Param.RightClickFunc then
        self.Param.RightClickFunc()
    end
    --同时也切换选择
    if self.Param and self.Param.ClickFunc then
        self.Param.ClickFunc(true)
    end
end

return HeroListBtn
