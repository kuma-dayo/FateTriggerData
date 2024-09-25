--[[
   个人信息-编辑个性标签界面
]] 
local class_name = "PersonInfoTagEdit"
local PersonInfoTagEdit = BaseClass(nil, class_name)

function PersonInfoTagEdit:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true

    self.BindNodes = 
    {

	}
    self.MsgList = {
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_SHOW_SOCIAL_TAG_CHANGED, Func = self.OnShowSocialTagChanged},
        {Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_SOCIAL_TAG_UNLOCK_STATE_CHANGED, Func = self.OnSocialTagUnlockStateChanged},
    }

    ---@type PersonalInfoModel
    self.PersonalModel = MvcEntry:GetModel(PersonalInfoModel)
    --玩家ID
    self.PlayerId = 0
    --展示的标签列表
    self.ShowSocialTagInfoList = {}
    --展示的标签Item列表
    self.ShowSocialTagWidgetItem = {}
    --缓存每个页签对应的标签ID信息
    self.SocialTagIdList = {}
    --当前选中的页签ID
    self.SelectTabId = 1
    --标签item列表 用于复用
    self.SocialTagItemList = {}
    --刷新滑动列表的时候是否需要滑动到顶部
    self.NeedSrollToStart = true
end 

function PersonInfoTagEdit:OnShow(Param)
    if not Param or not Param.PlayerId then
        return
    end
    self.PlayerId = Param.PlayerId
    self:UpdateUI()
end

function PersonInfoTagEdit:OnHide()

end

function PersonInfoTagEdit:UpdateUI()
    self:UpdateShowTagList()
    self:UpdateTabShow()
    self:UpdateShowTagNum()
end

--展示的标签发生变化 需要更新UI
function PersonInfoTagEdit:OnShowSocialTagChanged()
    self:UpdateUI()
end

--标签的解锁状态发生变化
function PersonInfoTagEdit:OnSocialTagUnlockStateChanged()
    --排序更新
    local SocialTagsTypeCfgList = self.PersonalModel:GetSocialTagsTypeCfgList()
    local ItemInfoList = {}
    for _, SocialTagsTypeCfg in ipairs(SocialTagsTypeCfgList) do
        self.SocialTagIdList[SocialTagsTypeCfg.TagTypeId] = SocialTagsTypeCfg.TagIdList
    end
    self:UpdateTabShow()
end

--刷新展示标签列表
function PersonInfoTagEdit:UpdateShowTagList()
    self.ShowSocialTagInfoList = self.PersonalModel:GetShowSocialTagInfoList(self.PlayerId)
    local TotalShowSocialTagNum = self.PersonalModel:GetTotalShowSocialTagNum()
    for Index = 1, TotalShowSocialTagNum, 1 do
        local Widget = self.View["WBP_Imformation_EditTagBtn_" .. Index]
        if Widget then
            local ShowSocialTag = self.ShowSocialTagInfoList[Index]
            if ShowSocialTag then
                Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                local TargetItem = self:CreateItem(Widget)
                if TargetItem then
                    local Param = {
                        ---展示类型 @type PersonalInfoModel.Enum_SocialTagItemShowType
                        ShowType = PersonalInfoModel.Enum_SocialTagItemShowType.Only_DeleteOperation,
                        TagId = ShowSocialTag,
                        IsSelf = true,
                    }
                    TargetItem:OnShow(Param)
                end
            else
                Widget:SetVisibility(UE.ESlateVisibility.Collapsed)  
            end
        end
    end
end

function PersonInfoTagEdit:CreateItem(Widget)
    local Item = self.ShowSocialTagWidgetItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, PersonalInfoModel.SocialTagBtnItem.LuaClass)
        self.ShowSocialTagWidgetItem[Widget] = Item
    end
    return Item.ViewInstance
end

--更新标签页签
function PersonInfoTagEdit:UpdateTabShow()
    if not self.MenuTabListCls then
        self.SocialTagIdList = {}
        local SocialTagsTypeCfgList = self.PersonalModel:GetSocialTagsTypeCfgList()
        local ItemInfoList = {}
        local WidgetIndex = 1
        for _, SocialTagsTypeCfg in ipairs(SocialTagsTypeCfgList) do
            local ItemInfo = {
                id = SocialTagsTypeCfg.TagTypeId,
                LabelStr = StringUtil.Format(SocialTagsTypeCfg.TagTypeName)
            }
            self.SocialTagIdList[SocialTagsTypeCfg.TagTypeId] = SocialTagsTypeCfg.TagIdList
            WidgetIndex = WidgetIndex + 1

            ItemInfoList[#ItemInfoList + 1] = ItemInfo
        end
        local MenuTabParam = {
            TabItemType = CommonMenuTabUp.TabItemTypeEnum.TYPE3,
            ItemInfoList = ItemInfoList,
            ClickCallBack = Bind(self,self.OnMenuBtnClick),
            ValidCheck = Bind(self, self.OnTagTabValidCheck),
            IsOpenKeyboardSwitch = true,
        }
        -- 页签列表
        self.MenuTabListCls = UIHandler.New(self,self.View.WBP_Common_TabUp_03,CommonMenuTabUp, MenuTabParam).ViewInstance
    else
        --更新当前页签
        self:OnMenuBtnClick(self.SelectTabId)
    end
end

function PersonInfoTagEdit:OnTagTabValidCheck(TabId)
    return true
end

--点击页签回调
function PersonInfoTagEdit:OnMenuBtnClick(Id)
    self.SelectTabId = Id
    for _, SocialTagItem in pairs(self.SocialTagItemList) do
        if SocialTagItem and SocialTagItem.View then
            SocialTagItem.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    self.View.ScrollBox_Tag:ScrollToStart()
    local SocialTagInfoList = self.SocialTagIdList[self.SelectTabId]
    if SocialTagInfoList then
        for Index, TagInfo in ipairs(SocialTagInfoList) do
            local Item = self.SocialTagItemList[Index]
            local Param = {
                ---展示类型 @type PersonalInfoModel.Enum_SocialTagItemShowType
                ShowType = PersonalInfoModel.Enum_SocialTagItemShowType.All_Operation,
                TagId = TagInfo,
                IsSelf = true,
            }
            if not (Item and CommonUtil.IsValid(Item.View)) then
                local WidgetPanelClass = UE.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/WBP_Imformation_EditTagBtn_Canpel.WBP_Imformation_EditTagBtn_Canpel")
                local WidgetPanel = NewObject(WidgetPanelClass, self.WidgetBase)
                self.View.WrapBox_Tag:AddChild(WidgetPanel)
                Item = UIHandler.New(self,WidgetPanel.WBP_Imformation_EditTagBtn,require(PersonalInfoModel.SocialTagBtnItem.LuaClass),Param).ViewInstance
                self.SocialTagItemList[Index] = Item
            end
            Item.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            Item:OnShow(Param)
        end
    end
end

--更新展示的标签数量
function PersonInfoTagEdit:UpdateShowTagNum()
    local SocialTagInfoList = self.PersonalModel:GetShowSocialTagInfoList(self.PlayerId)
    local ShowTagNum = #SocialTagInfoList
    local TotalShowSocialTagNum = self.PersonalModel:GetTotalShowSocialTagNum()
    self.View.Text_Num:SetText(StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"), ShowTagNum, TotalShowSocialTagNum))
end

return PersonInfoTagEdit
