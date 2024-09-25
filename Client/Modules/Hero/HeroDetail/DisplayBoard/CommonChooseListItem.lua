--[[
    角色板：底板、角色、特效使用通用ITEM逻辑 :::::: 此脚本已经舍弃,使用 CommonItemIconVertical 代替
]]

local class_name = "CommonChooseListItem"
local CommonChooseListItem = BaseClass(UIHandlerViewBase, class_name)


function CommonChooseListItem:OnInit()
    ---@type HeroModel
    self.HeroModel = MvcEntry:GetModel(HeroModel)

    self.MsgList = {

	}

    self.BindNodes = {
        { UDelegate = self.View.MainBtn.OnClicked,	Func = Bind(self,self.MainBtn_OnClicked) },
        -- { UDelegate = self.View.GetBtn.OnClicked,		    Func = Bind(self,self.OnClicked_BtnClick) },
		-- { UDelegate = self.View.LockBtn.OnClicked,			Func = Bind(self,self.OnClicked_BtnClick) },
        -- { UDelegate = self.View.GetBtn.OnHovered,           Func = Bind(self,self.OnBtnHovered) },
		-- { UDelegate = self.View.LockBtn.OnHovered,		    Func = Bind(self,self.OnBtnHovered) },
        -- { UDelegate = self.View.GetBtn.OnUnhovered,         Func = Bind(self,self.OnBtnUnhovered) },
		-- { UDelegate = self.View.LockBtn.OnUnhovered,        Func = Bind(self,self.OnBtnUnhovered) },
	}
end

function CommonChooseListItem:MainBtn_OnClicked()
    if self.Param and self.Param.ClickFunc then
        local Param = {
            Index = self.Index
        }
        self.Param.ClickFunc(Param)
    end
end

function CommonChooseListItem:OnShow(Param)
    self:UpdateUI(Param)
end

function CommonChooseListItem:OnManualShow(Param)
    self:UpdateUI(Param)
end

function CommonChooseListItem:OnManualHide(Param)
end

function CommonChooseListItem:OnHide(Param)
end

---@param Param table:{HeroId:number,DisplayBoardId:number,DisplayBoardTabID:EHeroDisplayBoardTabID,Index:number,ClickFunc:func, RedDotKey:string, RedDotSuffix:string}
function CommonChooseListItem:UpdateUI(Param)
    if Param == nil then
        return
    end
    self.Param = Param
    self.HeroId = self.Param.HeroId
    self.DisplayBoardId = Param.DisplayBoardId
    self.DisplayBoardTabID = Param.DisplayBoardTabID
    self.Index = Param.Index
    self.ClickFunc = Param.ClickFunc
    self.RedDotKey = Param.RedDotKey
    self.RedDotSuffix = Param.RedDotSuffix

    if self.DisplayBoardId == nil or self.DisplayBoardId == 0 then
        return 
    end

    if self.DisplayBoardTabID == EHeroDisplayBoardTabID.Floor.TabId then
        self:UpdateFloorData_Inner()
    elseif self.DisplayBoardTabID == EHeroDisplayBoardTabID.Role.TabId then
        self:UpdateRoleData_Inner()
    elseif self.DisplayBoardTabID == EHeroDisplayBoardTabID.Effect.TabId then
        self:UpdateEffectData_Inner()
    end

    if UE.UGFUnluaHelper.IsEditor() then
        if CommonUtil.IsValid(self.View.GUITextBlock_165) then
            self.View.GUITextBlock_165:SetText(self.DisplayBoardId)
        end
    end
end

----------------------------------------------Floor >>

---更新Floor类型
function CommonChooseListItem:UpdateFloorData_Inner()
    local TblCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayFloor, self.DisplayBoardId)
    if TblCfg == nil then
        CWaring(string.format("CommonChooseListItem:UpdateFloorData_Inner, TblCfg == nil!!! FloorId = %s", self.DisplayBoardId))
        return
    end

    -- self.View.ImageIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local ItemId = TblCfg[Cfg_HeroDisplayFloor_P.ItemId]
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
    if ItemCfg == nil then
        CWaring(string.format("CommonChooseListItem:UpdateFloorData_Inner, ItemCfg == nil!!! FloorId =%s,ItemId = %s ", self.DisplayBoardId, ItemId))
        return
    end

    local ResPath = ItemCfg[Cfg_ItemConfig_P.ImagePath]
    if ResPath == "" then
        ResPath = ItemCfg[Cfg_ItemConfig_P.IconPath]
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImageIcon, ResPath)

    local Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
    self:UpdateQuality(Quality)

    local TagParam = self:GetCornerTagParam_Inner()
    self:SetCornerTagShow_Inner(TagParam)
end



----------------------------------------------Floor <<

----------------------------------------------Role >>

---更新Role类型
function CommonChooseListItem:UpdateRoleData_Inner()
    local TblCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayRole, self.DisplayBoardId)
    if TblCfg == nil then
        CWaring(string.format("CommonChooseListItem:UpdateRoleData_Inner, TblCfg == nil!!! RoleId = %s", self.DisplayBoardId))
        return
    end

    local ItemId = TblCfg[Cfg_HeroDisplayRole_P.ItemId]
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
    if ItemCfg == nil then
        CWaring(string.format("CommonChooseListItem:UpdateRoleData_Inner, ItemCfg == nil!!! RoleId =%s,ItemId = %s ",self.DisplayBoardId, ItemId))
        return
    end

    local ResPath = ItemCfg[Cfg_ItemConfig_P.ImagePath]
    if ResPath == "" then
        ResPath = ItemCfg[Cfg_ItemConfig_P.IconPath]
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImageIcon, ResPath)

    local Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
    self:UpdateQuality(Quality)

    local TagParam = self:GetCornerTagParam_Inner()
    self:SetCornerTagShow_Inner(TagParam)
end

----------------------------------------------Role <<

----------------------------------------------Effect >>

---更新Effect类型
function CommonChooseListItem:UpdateEffectData_Inner()
    local TblCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayEffect, self.DisplayBoardId)
    if TblCfg == nil then
        CWaring(string.format("CommonChooseListItem:UpdateEffectData_Inner, TblCfg == nil!!! Effect = %s",self.DisplayBoardId))
        return
    end

    local ItemId = TblCfg[Cfg_HeroDisplayEffect_P.ItemId]
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
    if ItemCfg == nil then
        CWaring(string.format("CommonChooseListItem:UpdateEffectData_Inner, ItemCfg == nil!!! Effect =%s,ItemId = %s ",self.DisplayBoardId, ItemId))
        return
    end

    local ResPath = ItemCfg[Cfg_ItemConfig_P.ImagePath]
    if ResPath == "" then
        ResPath = ItemCfg[Cfg_ItemConfig_P.IconPath]
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImageIcon, ResPath)

    local Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
    self:UpdateQuality(Quality)

    local TagParam = self:GetCornerTagParam_Inner()
    self:SetCornerTagShow_Inner(TagParam)
end

----------------------------------------------Effect <<

----------------------------------------------角标 >>

---@class CornerTagParam
---@field TagPos number
---@field TagId CornerTagCfg
---@field TagWordId number
---@field TagHeroId number
---@field TagHeroSkinId number
---@return CornerTagParam
function CommonChooseListItem:GetCornerTagParam_Inner()
    local TagParam = {
        TagPos = 2,
        TagId = 0,
        TagWordId = 0,
        TagHeroId = 0,
        TagHeroSkinId = 0
    }

    --已经装备
    local IsSelected = false
    if self.DisplayBoardTabID == EHeroDisplayBoardTabID.Floor.TabId then
        IsSelected = self.HeroModel:GetSelectedDisplayBoardFloorId(self.HeroId) == self.DisplayBoardId
    elseif self.DisplayBoardTabID == EHeroDisplayBoardTabID.Role.TabId then
        IsSelected = self.HeroModel:GetSelectedDisplayBoardRoleId(self.HeroId) == self.DisplayBoardId
    elseif self.DisplayBoardTabID == EHeroDisplayBoardTabID.Effect.TabId then
        IsSelected = self.HeroModel:GetSelectedDisplayBoardEffectId(self.HeroId) == self.DisplayBoardId
    end
    if IsSelected then
        TagParam.TagId = CornerTagCfg.Equipped.TagId
        return TagParam
    end

    --已经拥有
    local bHas = false
    if self.DisplayBoardTabID == EHeroDisplayBoardTabID.Floor.TabId then
        bHas = self.HeroModel:HasDisplayBoardFloor(self.DisplayBoardId)
    elseif self.DisplayBoardTabID == EHeroDisplayBoardTabID.Role.TabId then
        bHas = self.HeroModel:HasDisplayBoardRole(self.DisplayBoardId)
    elseif self.DisplayBoardTabID == EHeroDisplayBoardTabID.Effect.TabId then
        bHas = self.HeroModel:HasDisplayBoardEffect(self.DisplayBoardId)
    end
    if not(bHas) then
        TagParam.TagId = CornerTagCfg.Lock.TagId
        return TagParam
    end

    --被哪个英雄使用
    local UsedByHeroId = 0
    if self.DisplayBoardTabID == EHeroDisplayBoardTabID.Floor.TabId then
        UsedByHeroId = self.HeroModel:GetFloorUsedByHeroId(self.DisplayBoardId, self.HeroId)
    elseif self.DisplayBoardTabID == EHeroDisplayBoardTabID.Role.TabId then
        UsedByHeroId = 0
    elseif self.DisplayBoardTabID == EHeroDisplayBoardTabID.Effect.TabId then
        UsedByHeroId = self.HeroModel:GetEffectUsedByHeroId(self.DisplayBoardId, self.HeroId)
    end
    if UsedByHeroId > 0 then
        TagParam.TagId = CornerTagCfg.HeroBg.TagId
        TagParam.TagHeroId = UsedByHeroId
        TagParam.TagHeroSkinId = self.HeroModel:GetDefaultSkinIdByHeroId(UsedByHeroId)
        return TagParam
    end

    return TagParam
end

---角标设置
---@param TagParam CornerTagParam
function CommonChooseListItem:SetCornerTagShow_Inner(TagParam)
    TagParam = TagParam or {}
    if CommonUtil.IsValid(self.View.Root_SubScriptScale) then
        self.View.Root_SubScriptScale:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    local TagPos = TagParam.TagPos or 0
    local TagPanel = nil
    for PosIdx = 1, 3, 1 do
        local TempTagPanel = self.View["CornerTag_"..PosIdx]
        if CommonUtil.IsValid(TempTagPanel) then
            if PosIdx == TagPos then
                TempTagPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                TagPanel = TempTagPanel
            else
                TempTagPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
    end

    if TagPanel == nil then
        CError(string.format("CommonChooseListItem:SetCornerTagShow_Inner, Can't find TagPanel !!!,TagPos = %s",tostring(TagPos)))
        return
    end

    local TagId = TagParam.TagId
    if not TagId or TagId <= 0 then
        TagPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    if CommonUtil.IsValid(self.View.Img_Bg_Lock) then
        -- 遮罩设置
        self.View.Img_Bg_Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- if TagId == CornerTagCfg.Lock.TagId then
        --     self.View.Img_Bg_Lock:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        --     self.View.Img_Bg_Lock:SetColorAndOpacity(self.View.MaskColor_Lock)
        -- end
    end

    local TagCfg = G_ConfigHelper:GetSingleItemById(Cfg_CornerTagCfg, TagId)
    if not TagCfg then
        return
    end
    
    -- TagPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.View["CornerTagImg_"..TagPos] then
        self.View["CornerTagImg_"..TagPos]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.View["CornerTag_HeroHead_"..TagPos] then
        self.View["CornerTag_HeroHead_"..TagPos]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.View["CornerTagText_Img_"..TagPos] then
        self.View["CornerTagText_Img_"..TagPos]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.View["CornerTagText_Word_"..TagPos] then
        self.View["CornerTagText_Word_"..TagPos]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    local TagType = TagCfg[Cfg_CornerTagCfg_P.TagType]
    if TagType == CommonConst.CORNER_TYPE.IMG then
        CommonUtil.SetCornerTagImg(self.View["CornerTagImg_"..TagPos],TagId)
    elseif TagType == CommonConst.CORNER_TYPE.HERO_HEAD then
        CommonUtil.SetCornerTagHeroHead(self.View["CornerTagImg_"..TagPos],self.View["CornerTag_HeroHead_"..TagPos],TagParam.TagHeroId, TagParam.TagHeroSkinId)
    elseif TagType == CommonConst.CORNER_TYPE.WORD then
        CommonUtil.SetCornerTagWord(self.View["CornerTagText_Img_"..TagPos],self.View["CornerTagText_Word_"..TagPos],TagParam.TagWordId)
    end
end
----------------------------------------------角标 <<

----------------------------------------------品质 >>

-- 品质色
function CommonChooseListItem:UpdateQuality(Quality)

    CommonUtil.SetQualityBgVertical(self.View.GUIImageBtnBg, Quality)

    -- self.View.GUIImageBtnBg:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg, Quality)
    -- if QualityCfg then
    --     local QualityBgPath = QualityCfg[Cfg_ItemQualityColorCfg_P.QualityBg]
    --     self.View.GUIImageBtnBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageBtnBg, QualityBgPath)
    --     -- CommonUtil.SetImageColorFromQuality(self.View.QualityBar,Quality)
    --     --CommonUtil.SetTextColorFromQuality(self.View.GUITextBlock_Level,Quality)
    -- end
end

----------------------------------------------品质 <<

----------------------------------------------选中 >>
function CommonChooseListItem:SetIsSelect(bSelect)
    if bSelect then
        self.View:VXE_Btn_Select()
    else
        self.View:VXE_Btn_UnSelect()
    end
end
----------------------------------------------选中 >>



return CommonChooseListItem








