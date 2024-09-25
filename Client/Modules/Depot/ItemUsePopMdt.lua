--[[
    选择道具使用界面
]]

local class_name = "ItemUsePopMdt";
ItemUsePopMdt = ItemUsePopMdt or BaseClass(GameMediator, class_name);

function ItemUsePopMdt:__init()
end

function ItemUsePopMdt:OnShow(data)
    
end

function ItemUsePopMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.MsgList = 
    {
		{Model = FriendModel, MsgName = FriendModel.ON_USE_INTIMACY_ITEM_SUCCESS, Func = self.OnUseIntimacyItemSuccess},
    }

    self.Model = MvcEntry:GetModel(DepotModel)
end

--[[
    Param = {
        ItemId, -- 使用的道具id
        EnterBtnText,   -- 是否自定义确认键文字 默认为使用
        ExtraInfo   -- 其他信息
    }
]]
function M:OnShow(Param)
    if not (Param and Param.ItemId) then
        CError("ItemUsePopMdt Need ItemID")
        return
    end
    self.ItemId = Param.ItemId
    self.ExtraInfo = Param.ExtraInfo
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.ItemId)
    if not ItemCfg then
        return
    end

    -- 设置通用背景部分
    local TitleText = ItemCfg[Cfg_ItemConfig_P.UseItemTitle]
    if TitleText == "" then
        TitleText = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_ItemUsePopMdt_DefaultTitle")
    end
    local EnterBtnText = Param.EnterBtnText or G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_DepotMainMdt_use_Btn")
    local ContentWidgetCls = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC("/Game/BluePrints/UMG/Components/CommonPopUp/WBP_CommonPopUp_Content_EditableSlider.WBP_CommonPopUp_Content_EditableSlider"))
    local ContentWidget = NewObject(ContentWidgetCls, self)
    local PopUpBgParam = {
        TitleText = TitleText,
        ContentWidget = ContentWidget,
        BtnList = {
            [1] = {
                BtnParam = {
                    OnItemClick = Bind(self,self.OnCancelFunc),
                    TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_DepotMainMdt_cancel"),
                    CommonTipsID = CommonConst.CT_ESC,
                    ActionMappingKey = ActionMappings.Escape,
                    HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
                },
                IsWeak = true
            },
            [2] = {
                BtnParam = {
                    OnItemClick = Bind(self,self.OnEnterFunc),
                    TipStr = EnterBtnText,
                    CommonTipsID = CommonConst.CT_SPACE,
                    ActionMappingKey = ActionMappings.SpaceBar,
                    HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
                },
            }
        },
        CloseCb = Bind(self,self.DoCloseView)
    }
    self.CommonPopUpBgLogicCls = UIHandler.New(self,self.WBP_CommonPopUp_Bg,CommonPopUpBgLogic,PopUpBgParam).ViewInstance

    -- 设置内容部分
    local ItemList = {}
    ItemList[#ItemList + 1] = {ItemId = self.ItemId}
    
    local EditableSliderParam = {
        ItemList = ItemList,
        MaxNum = self.Model:GetItemCountByItemId(self.ItemId),
        GetDesStrFunc = Bind(self,self.SetDesStrOnSelectItemCountChanged),
        ValueChangeCallBack = Bind(self,self.OnSelectValueChanged)
    }
   
    self.CommonPopUpContentCls = UIHandler.New(self,self.ContentWidget,CommonPopUpEditableSliderLogic,EditableSliderParam).ViewInstance
    self.UseCount = 1
end

function M:OnHide()
   
end

function M:OnSelectValueChanged(Value)
    self.UseCount = Value
end

function M:SetDesStrOnSelectItemCountChanged(Num)
    if self.ItemId == DepotConst.ITEM_ID_FRIEND_INTIMACY then
        if self.ExtraInfo and self.ExtraInfo.TargetPlayerId then
            ---@type FriendModel
            local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_IntimacyItemConfig, self.ItemId)
            local AddIntimacyValue = Cfg and Cfg[Cfg_IntimacyItemConfig_P.IntimacyValue] or 0
            AddIntimacyValue = AddIntimacyValue * self.UseCount
            local TmpStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_ItemUsePopMdt_IntimacyDes")
            return StringUtil.Format(TmpStr, AddIntimacyValue)
        else
            CWaring("SetDesStrOnSelectItemCountChanged Without TargetId")
            return nil
        end
    else
        return nil
    end
end

function M:OnEnterFunc()
    if self.ItemId == DepotConst.ITEM_ID_FRIEND_INTIMACY then
        -- 赠送鲜花
        if self.ExtraInfo and self.ExtraInfo.TargetPlayerId then
            local Msg = {
                TargetPlayerId = self.ExtraInfo.TargetPlayerId,
                ItemId = self.ItemId,
                ItemNum = self.UseCount,
            }
            MvcEntry:GetCtrl(FriendCtrl):SendPlayerGiveFriendItemGiftReq(Msg)
        else
           CError("Use ITEM_ID_FRIEND_INTIMACY Without TargetId",true) 
        end
    else
        -- 使用道具 
        -- todo
    end
end

function M:OnCancelFunc()
    self:DoCloseView()
end

-- 赠送鲜花成功
function M:OnUseIntimacyItemSuccess(Msg)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_IntimacyItemConfig, Msg.ItemId)
    local AddIntimacyValue = Cfg and Cfg[Cfg_IntimacyItemConfig_P.IntimacyValue] or 0
    AddIntimacyValue = AddIntimacyValue * Msg.ItemNum
    local ItemName = MvcEntry:GetModel(DepotModel):GetItemName(Msg.ItemId)
    local TipsStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Depot","Lua_ItemUsePopMdt_IntimacyUseTips")
    UIAlert.Show(StringUtil.Format(TipsStr,ItemName,Msg.ItemNum,AddIntimacyValue))
    self:DoCloseView()
end

function M:DoCloseView()
    MvcEntry:CloseView(self.viewId)
end

return M