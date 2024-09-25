---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 自建房房间列表
--- Created At: 2023/05/29 18:28
--- Created By: 朝文
---

require("Client.Modules.CustomRoom.CustomRoomList.CustomRoomListModel")

local class_name = "CustomRoomListMdt"
---@class CustomRoomListMdt
local CustomRoomListMdt = BaseClass(nil, class_name)

function CustomRoomListMdt:OnInit()
    self._Widget2RoomItem = {}
    
    ---@type CustomRoomListModel
    self.CustomRoomListModel = MvcEntry:GetModel(CustomRoomListModel)
    
    ---@type CustomRoomModel
    self.CustomRoomModel = MvcEntry:GetModel(CustomRoomModel)

    self.MsgList = {
        { Model = CustomRoomListModel,    MsgName = CustomRoomListModel.ON_CHANGED,	Func = self.OnRoomListChange },
        { Model = CustomRoomListModel,    MsgName = CustomRoomListModel.ON_CHANGED,	Func = self.OnRoomListChange },
    }

    --底部按钮
    UIHandler.New(self, self.View.WBP_HallCustomerRoom_BottomBtns,
            require("Client.Modules.CustomRoom.CustomRoomCommonWidget.CustomRoomButtonsMdt"),
            {
                --左侧大按钮
                Button1Info = {                     --如果没有配置则隐藏按钮
                    Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListMdt_Createaroom"),
                    Callback = Bind(self, self.OnButtonClicked_CreateRoom),
                },
                --右侧大按钮
                Button2Info = {                     --如果没有配置则隐藏按钮
                    Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListMdt_Jointheroom"),
                    Callback = Bind(self, self.OnButtonClicked_EnterRoom),
                },
                --最左侧小按钮
                ButtonExtraInfo = {                 --如果没有配置则隐藏按钮
                    Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListMdt_Refreshlist"),
                    Callback = Bind(self, self.OnButtonClicked_RefreshRoomList),
                }
            })
end

function CustomRoomListMdt:OnShow(Param)
    self.View.WBP_ReuseList_RoomList.OnUpdateItem:Add(self.View, Bind(self, self.OnUpdateRoomListItem))
    
    --进入时拉取一次房间信息
    ---@type CustomRoomListCtrl
    local CustomRoomListCtrl = MvcEntry:GetCtrl(CustomRoomListCtrl)
    CustomRoomListCtrl:SendRoomInfoReq(0)
    
    --处理自动登录
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    if UserModel.IsLoginByCMD and UserModel.CMDLoginRoomID then
        ---@type CustomRoomCtrl
        local CustomRoomCtrl = MvcEntry:GetCtrl(CustomRoomCtrl)
        CustomRoomCtrl:SendEnterRoomReq(UserModel.CMDLoginRoomID)
    end 
end

function CustomRoomListMdt:OnHide()    
    self.View.WBP_ReuseList_RoomList.OnUpdateItem:Clear()

    --清空选中的信息，再次进入到此界面需要处于未选中的状态
    ---@type CustomRoomListModel
    local CustomRoomListModel = MvcEntry:GetModel(CustomRoomListModel)
    CustomRoomListModel:CleanCurSelRoomInfo()
end

---更新页面的函数
--- 1）刷新房间列表
function CustomRoomListMdt:UpdateView()
    --更新房间列表
    self.View.WBP_ReuseList_RoomList:Reload(self.CustomRoomListModel:GetLength())
end

------------------------------
--- WBP_ReuseList_RoomList ---
------------------------------
--region WBP_ReuseList_RoomList
function CustomRoomListMdt:_GetOrCreateRoomListItem(Widget)
    local Item = self._Widget2RoomItem[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.CustomRoom.CustomRoomList.CustomRoomList_ItemMdt"))
        self._Widget2RoomItem[Widget] = Item
    end
    
    return Item.ViewInstance
end

---更新 WBP_ReuseList_RoomList 的函数
---@param Widget userdata 控件
---@param Index number 在lua侧使用需要 +1
function CustomRoomListMdt:OnUpdateRoomListItem(Handler, Widget, Index)
    local FixedIndex = Index + 1
    
    local RoomInfo = self.CustomRoomListModel:GetDataList()
    RoomInfo = RoomInfo and RoomInfo[FixedIndex]
    if not RoomInfo then
        CLog("[cw] Cannot get RoomInfo by FixedIndex: " .. tostring(FixedIndex))
        return
    end
    
    ---@type CustomRoomListItemMdt
    local TargetItem = self:_GetOrCreateRoomListItem(Widget)
    if not TargetItem then return end

    TargetItem:SetData(RoomInfo)
    TargetItem:UpdateView()
end
--endregion WBP_ReuseList_RoomList

----------------------------------------------------- 按钮点击相关 -------------------------------------------------------

---创建房间
function CustomRoomListMdt:OnButtonClicked_CreateRoom()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    UserModel.IsLoginByCMD = false
        
    self.CustomRoomModel:DispatchType(self.CustomRoomModel.LOAD_ROOM_SETTINGS_PAGE)
end

---进入房间
function CustomRoomListMdt:OnButtonClicked_EnterRoom()
    local CurSelRoomId = self.CustomRoomListModel:GetCurSelRoomInfo_RoomId()
    if not CurSelRoomId then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_CustomRoomListMdt_Pleaseselectaroomfir"))    
        return 
    end
    
    -- 请求进入房间
    ---@type CustomRoomCtrl
    local CustomRoomCtrl = MvcEntry:GetCtrl(CustomRoomCtrl)
    CustomRoomCtrl:SendEnterRoomReq(CurSelRoomId)
end

---刷新房间
function CustomRoomListMdt:OnButtonClicked_RefreshRoomList()
    ---@type CustomRoomListCtrl
    local CustomRoomListCtrl = MvcEntry:GetCtrl(CustomRoomListCtrl)
    CustomRoomListCtrl:SendRoomInfoReq(0)
end

---点击右下角返回键
---关闭自建房面板（关闭整个自建房框架）
function CustomRoomListMdt:OnButtonClicked_Return()
    MvcEntry:CloseView(ViewConst.CustomRoomPanel)
end

------------------------------------------------------- 事件相关 --------------------------------------------------------

---当房间列表数据更新时，刷新一下页面
function CustomRoomListMdt:OnRoomListChange()
    self:UpdateView()
end

--------------------------------------------------------- end ----------------------------------------------------------

return CustomRoomListMdt
