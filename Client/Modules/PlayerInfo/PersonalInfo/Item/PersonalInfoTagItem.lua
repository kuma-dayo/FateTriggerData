--[[
   个人信息 - 标签Item逻辑
]] 
local class_name = "PersonalInfoTagItem"
local PersonalInfoTagItem = BaseClass(nil, class_name)

function PersonalInfoTagItem:OnInit()
    self.MsgList = {
        -- { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID,Func = Bind(self,self.OnGetPlayerBaseInfo) },
        -- { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_DETAIL_INFO_CHANGED,    Func = self.OnGetPlayerDetailInfo },
    }
    self.BindNodes = {
		{ UDelegate = self.View.Button_DeleteTag.OnClicked,				Func = Bind(self,self.OnClick_DeleteTag) },
        { UDelegate = self.View.Button_Lock.OnClicked,				Func = Bind(self,self.OnClick_LockTag) },
		{ UDelegate = self.View.Button_Unlock.OnClicked,				Func = Bind(self,self.OnClick_UnlockTag) },
    }

    ---@type PersonalInfoCtrl
    self.PersonalCtrl = MvcEntry:GetCtrl(PersonalInfoCtrl)
    ---@type PersonalInfoModel
    self.PersonalModel = MvcEntry:GetModel(PersonalInfoModel)
end

--[[
    local Param = {
        --展示类型 @type PersonalInfoModel.Enum_SocialTagItemShowType
        ShowType
        --是否自己的标签  true的情况会检测标签解锁状态
        IsSelf     
        --标签ID
        TagId
    }
]]
function PersonalInfoTagItem:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function PersonalInfoTagItem:OnHide()
end

function PersonalInfoTagItem:UpdateUI(Param)
    ---展示类型 @type PersonalInfoModel.Enum_SocialTagItemShowType
    self.ShowType = Param.ShowType or PersonalInfoModel.Enum_SocialTagItemShowType.Only_Show
    --标签ID
    self.TagId = Param.TagId
    --是否自己的标签
    self.IsSelf = Param.IsSelf or false
    --标签配置信息
    self.TagCfgInfo = self.PersonalModel:GetSocialTagCfgInfoById(self.TagId)
    if not self.TagId or not self.TagCfgInfo then
        return
    end
    ---标签是否解锁
    self.IsUnLock = not self.IsSelf and true or self.PersonalModel:CheckSocialTagIsUnlock(self.TagId)
    ---标签是否被选中展示
    self.IsSelect = self.ShowType == PersonalInfoModel.Enum_SocialTagItemShowType.All_Operation and self.PersonalModel:CheckSocialTagIsSelectShow(self.TagId)


    self:UpdateCanOperationUI()
    self:UpdateWidgetSwitcher()
    self:UpdateTagName()
    self:UpdateTagBgColor()
    self:UpdateSelectState()
end

--更新可操作的UI显示状态
function PersonalInfoTagItem:UpdateCanOperationUI()
    if self.ShowType == PersonalInfoModel.Enum_SocialTagItemShowType.Only_Show then
        self.View.Button_DeleteTag:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Button_Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Button_Unlock:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif self.ShowType == PersonalInfoModel.Enum_SocialTagItemShowType.Only_DeleteOperation then
        self.View.Button_DeleteTag:SetVisibility(UE.ESlateVisibility.Visible)
        self.View.Button_Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Button_Unlock:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif self.ShowType == PersonalInfoModel.Enum_SocialTagItemShowType.All_Operation then
        self.View.Button_DeleteTag:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Button_Lock:SetVisibility(UE.ESlateVisibility.Visible)
        self.View.Button_Unlock:SetVisibility(UE.ESlateVisibility.Visible)
    end
end

--更新锁定&解除状态
function PersonalInfoTagItem:UpdateWidgetSwitcher()
    local Widget = self.IsUnLock and self.View.Panel_Unlock or self.View.Panel_Lock
    if Widget then
        self.View.WidgetSwitcher:SetActiveWidget(Widget)
    end
end

--更新标签的名字
function PersonalInfoTagItem:UpdateTagName()
    local Text_TagName = self.IsUnLock and self.View.Text_TagName or self.View.Text_TagName_Lock
    Text_TagName:SetText(StringUtil.FormatText(self.TagCfgInfo.TagName))
end

--更新标签的背景颜色
function PersonalInfoTagItem:UpdateTagBgColor()
    CommonUtil.SetImageColorFromHex(self.View.Image_TagBg, self.TagCfgInfo.BgHexColor)
end

--更新选中状态
function PersonalInfoTagItem:UpdateSelectState()
    local EventName = ""
    if self.IsUnLock then
        EventName = self.IsSelect and "VXE_Btn_Select" or "VXE_Btn_UnSelect"
    else
        EventName = self.IsSelect and "VXE_LockBtn_Select" or "VXE_LockBtn_UnSelect"
    end
    if self.View[EventName] then
        self.View[EventName](self.View)  
    end
end

--点击删除标签按钮
function PersonalInfoTagItem:OnClick_DeleteTag()
    if self.ShowType ~= PersonalInfoModel.Enum_SocialTagItemShowType.Only_DeleteOperation or not self.IsSelf then return end
    self:OnDeleteTag()
end

--点击锁定状态
function PersonalInfoTagItem:OnClick_LockTag()
    if self.ShowType ~= PersonalInfoModel.Enum_SocialTagItemShowType.All_Operation or not self.IsSelf then return end
    local TipText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1032")
    UIAlert.Show(TipText)
end

--点击解锁状态
function PersonalInfoTagItem:OnClick_UnlockTag()
    if self.ShowType ~= PersonalInfoModel.Enum_SocialTagItemShowType.All_Operation or not self.IsSelf then return end  
    if self.IsSelect then
        self:OnDeleteTag()
    else
        local ShowSocialTagInfoList = self.PersonalModel:GetDeepCopyShowSocialTagInfoList()
        local TotalShowSocialTagNum = self.PersonalModel:GetTotalShowSocialTagNum()
        if #ShowSocialTagInfoList < TotalShowSocialTagNum then
            ShowSocialTagInfoList[#ShowSocialTagInfoList + 1] = self.TagId
            self.PersonalCtrl:SendProto_PlayerUpdateTagReq(ShowSocialTagInfoList)
        else
            local TipText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1033")
            UIAlert.Show(TipText)
        end
    end
end

--删除标签
function PersonalInfoTagItem:OnDeleteTag()
    local ShowSocialTagInfoList = self.PersonalModel:GetDeepCopyShowSocialTagInfoList()
    local DelIndex = nil
    for Index, TagId in ipairs(ShowSocialTagInfoList) do
        if TagId == self.TagId then
            DelIndex = Index
            break
        end
    end
    if DelIndex then
        table.remove(ShowSocialTagInfoList,DelIndex)
        self.PersonalCtrl:SendProto_PlayerUpdateTagReq(ShowSocialTagInfoList)
    end
end

return PersonalInfoTagItem
