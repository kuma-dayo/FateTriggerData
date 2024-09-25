---
--- Ctrl 模块，主要用于处理协议和逻辑
--- Description: 物品获得面板协议处理,以及提供通用接口供外部打开物品获得面板
---
--- *【外部使用接口】
---     1.展示通用物品获得界面
---         local Param = {...}
---         MvcEntry:GetCtrl(ItemGetCtrl):ShowItemGet(Param)
---         @see ItemGetCtrl#ShowItemGet 上方的注释
---
--- Created At: 2023/03/27 17:15
--- Created By: 朝文
---

require("Client.Modules.ItemGet.ItemGetModel")

local class_name = "ItemGetCtrl"
---@class ItemGetCtrl : UserGameController
ItemGetCtrl = ItemGetCtrl or BaseClass(UserGameController, class_name)

function ItemGetCtrl:__init()
    CWaring("[cw] ItemGetCtrl init")
    self.Model = nil
    self.ShowItemGetCacheList = {}
end

function ItemGetCtrl:Initialize()
    self.Model = self:GetModel(ItemGetModel)
end

function ItemGetCtrl:OnLogout()
    self.ShowItemGetCacheList = {}
end

function ItemGetCtrl:AddMsgListenersUser()
    --添加协议回包监听事件
    self.ProtoList = {
        {MsgName = Pb_Message.DropPrizeItemSyn, Func = self.OnDropPrizeItemSyn},
    }
end

---@class ItemGetOnShowParam
--[[
    使用案例：
    local Param = {
        Title = "恭喜获得",                                               --【可选】如果需要自定义标题，请修改这个参数
        Tips = "点击空白处关闭",                                           --【可选】如果需要自定义提示，请修改这个参数
        PrizeItemList = {                                               --【*必填*】获得的物品列表
            [1] = {
                ItemId = 1,                                             --【*必填*】物品ID
                ItemNum = 1,                                            --【*必填*】物品数量
                DecomposeInfo = {                                       --【可选】如果这个物品包含分解信息，则在这里指明
                    ItemId = 1,                                         --【可选】分解之后的物品id
                    ItemNum = 1,                                        --【可选】分解之后的物品数量
                }
                ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,    --【可选】默认点击无效果
                HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,     --【可选】默认停留展示tip
                HoverScale = 1.15,                                      --【可选】Hover时放大倍率，默认为1.15
            },
            [2] = ...                                                   --格式同上
        },
        leftBtnInfo = {                                                 --【可选】左按钮信息，无数据则不显示
            name = "",                                                  --【可选】按钮名称，默认为【取消】
            callback = func,                                            --【可选】按钮回调
            iconID = 1,                                                 --【可选】展示的图标ID，参考【CommonConst.CT_BACK】
            actionMappingKey = nil,                                     --【可选】需要监听的按钮，参考【ActionMappings.Escape】
            style = nil,                                                --【可选】参考 WCommonBtnTips.HoverFontStyleType.Main
        }, 
        rightBtnInfo = {                                                --【可选】右铵钮信息，无数据则不显示
            name = "",                                                  --【可选】按钮名称，默认为【确认】
            callback = func,                                            --【可选】按钮回调
            iconID = 1,                                                 --【可选】展示的图标ID，参考【CommonConst.CT_SPACE】
            actionMappingKey = nil,                                     --【可选】需要监听的按钮，参考【ActionMappings.SpaceBar】
            style = nil,                                                --【可选】参考 WCommonBtnTips.HoverFontStyleType.Main
        }, 
    }
        
    MvcEntry:GetCtrl(ItemGetCtrl):ShowItemGet(Param)    
--]]
---展示通用物品获得界面，展示获得的物品
function ItemGetCtrl:ShowItemGet(Param)
    print_r(Param, "[cw] ItemGetCtrl:ShowItemGet Param")

    if not self:CheckCanShowItemGet(Param) then
        return
    end

    local List = {}
    if Param.PrizeItemList and next(Param.PrizeItemList) then
        for k, ItemInfo in pairs(Param.PrizeItemList) do
            local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemInfo.ItemId)
            if ItemCfg then
                if ItemCfg[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER and ItemCfg[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Pose then
                    --:特殊处理:角色姿势类型不需要展示
                else
                    table.insert(List,ItemInfo)
                end
            end
        end
    end

    local SpecialShowList = {}
    for _,ItemInfo in ipairs(List) do
        local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemInfo.ItemId)
        if ItemCfg and ItemCfg[Cfg_ItemConfig_P.IsSpecialPop] then
            SpecialShowList[#SpecialShowList + 1] = ItemInfo
        end
    end
    local function ShowCommonItemGet()
        if not self:CheckCanShowItemGet(Param) then
            return
        end
        -- if self:GetModel(ViewModel):GetState(ViewConst.ItemGet) then
        --     CWaring("ItemGetCtrl:ShowItemGet Already Exist ItemGetPanel,Try Close")
        --     self:CloseView(ViewConst.ItemGet)
        -- end
        ---@see MainCtrl#OpenView
        ---@see ItemGetMdt#OnShow
        Param.PrizeItemList = List
        self:OpenView(ViewConst.ItemGet, Param)
    end
    if #SpecialShowList > 0 then
        -- 打开特殊获取弹窗界面
        local tmpParam = {
            ShowList = SpecialShowList,
            PopUpEffectId = Param.PopUpEffectId,
            CloseCallback = #List > 1 and ShowCommonItemGet or nil,
        }
        self:OpenView(ViewConst.SpecialItemGet,tmpParam)
    else
        ShowCommonItemGet()
    end
end

--[[
    检测当前能否弹出:
    1. 当前已有奖励/特殊奖励弹窗在展示时，不弹出，缓存起来
]]
function ItemGetCtrl:CheckCanShowItemGet(ViewParam)
    local ViewModel = self:GetModel(ViewModel)
    if ViewModel:GetState(ViewConst.ItemGet) or ViewModel:GetState(ViewConst.SpecialItemGet) then
        CWaring("ItemGetCtrl:CheckCanShowItemGet Have ItemGet Displaying..")
        self.ShowItemGetCacheList = self.ShowItemGetCacheList or {}
        self.ShowItemGetCacheList[#self.ShowItemGetCacheList + 1] = ViewParam
        return false
    end
    return true
end

--[[
    检测是否有缓存奖励需要弹出
]]
function ItemGetCtrl:CheckHaveItemGetNeedToShow()
    if self.ShowItemGetCacheList and #self.ShowItemGetCacheList > 0 then
        CWaring("ItemGetCtrl:CheckCanShowItemGet Have ItemGet Need To Display..Num: "..#self.ShowItemGetCacheList)
        local FirstItem = table.remove(self.ShowItemGetCacheList,1)
        self:ShowItemGet(FirstItem)
    end
end

-----------------------------------------请求相关------------------------------

--[[
    回包数据类型备注
    data = {
        PrizeItemList = {
            [1] = {
                ItemId = 700000090,  --物品ID
                ItemNum = 1,         --物品数量         
            },
            [2] = {                  --格式同上
                ...
            },
        },
        --key对应着上方 PrizeItemList 的索引，如果物品存在分解，则下发对应的key中有分解信息。
        DecomposeItemList = {
            [2] = {                  --对应的 PrizeItemList 的索引
                ItemId = 700000090,  --分解之后的物品ID
                ItemNum = 1,         --分解之后的物品数量
            }
        }
    }
--]]
---接收协议回报 OnDropPrizeItemSyn
---@param data any 请说明数据类型及用途
function ItemGetCtrl:OnDropPrizeItemSyn(Msg)
    CLog("=======ItemGetCtrl:OnDropPrizeItemSyn=======")
    
    --把 DecomposeItemList 与 PrizeIetmList 组合一下
    local PrizeItemList = Msg.PrizeItemList
    for index, PrizeItemNode in pairs(Msg.DecomposeItemList or {}) do
        PrizeItemList[index].DecomposeInfo = PrizeItemNode
    end
    if #PrizeItemList == 0 then
        return
    end
    local Param = {
        PrizeItemList = PrizeItemList,
        PopUpEffectId = Msg.PopUpEffectId

    }
    self:ShowItemGet(Param)    

end