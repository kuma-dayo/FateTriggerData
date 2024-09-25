--[[
    界面跳转管理
]]

local class_name = "ViewJumpCtrl"
---@class ViewJumpCtrl : UserGameController
ViewJumpCtrl = ViewJumpCtrl or BaseClass(UserGameController,class_name)

ViewJumpCtrl.JumpTypeDefine =
{
    DoNotJump = 0,    --不跳转界面
    JumpView = 1,     --默认跳转界面
    JumpActivity = 2, --默认跳转活动界面
    JumpWeb = 3,      --跳转Web
    DisabledBtn = 4,  --按钮置灰且无交互
    JumpApp = 5,      --跳转App
}

function ViewJumpCtrl:__init()
    CWaring("==ViewJumpCtrl init")
end

function ViewJumpCtrl:Initialize()
    self.CustomLogicId2Func = {
        [1001] = Bind(self,self.LogicId_1001),
        [1002] = Bind(self,self.LogicId_1002),
        [1003] = Bind(self,self.LogicId_1003),
        [1004] = Bind(self,self.LogicId_1004),
        [1005] = Bind(self,self.LogicId_1005),
        [1006] = Bind(self,self.LogicId_1006),
        [1007] = Bind(self,self.LogicId_1007),
    }
end

--[[
    玩家登入
]]
function ViewJumpCtrl:OnLogin(data)
    CWaring("ViewJumpCtrl OnLogin")
end


function ViewJumpCtrl:AddMsgListenersUser()
    
end

-- 跳转到JumpId对应的界面
function ViewJumpCtrl:JumpTo(JumpId)
    if not JumpId or JumpId == 0 then
        return
    end
    local JumpCfg = G_ConfigHelper:GetSingleItemById(Cfg_JumpViewCfg,JumpId)
    if not JumpCfg then
        CWaring("ViewJumpCtrl:JumpTo Can't GetJumpCfg For Id = "..JumpId)
        return
    end
    local JumpType = JumpCfg[Cfg_JumpViewCfg_P.JumpType]
    if JumpType == ViewJumpCtrl.JumpTypeDefine.JumpView then
        local ViewId = JumpCfg[Cfg_JumpViewCfg_P.ViewId]
        if ViewId and ViewId > 0 then
            local ViewParams = JumpCfg[Cfg_JumpViewCfg_P.ViewParams]
            if ViewParams then
                -- local Params = {
                --     JumpParam = ViewParams
                -- }
                -- TODO 每个界面按需组装自己的参数信息
                -- if ViewId == ViewConst.xx then
                    -- Params.xx = ViewParamsList[1]
                    -- Params.xx = ViewParamsList[2]
                -- end
                MvcEntry:OpenView(ViewId,{JumpParam = ViewParams})
            else
                MvcEntry:OpenView(ViewId)
            end
        elseif JumpCfg[Cfg_JumpViewCfg_P.LogicId] and JumpCfg[Cfg_JumpViewCfg_P.LogicId] > 0 then
            if self.CustomLogicId2Func[JumpCfg[Cfg_JumpViewCfg_P.LogicId]] then
                self.CustomLogicId2Func[JumpCfg[Cfg_JumpViewCfg_P.LogicId]](JumpCfg[Cfg_JumpViewCfg_P.ViewParams])
            else
                CWaring("ViewJumpCtrl:JumpTo Error,not found logic func with logic Id:"..JumpCfg[Cfg_JumpViewCfg_P.LogicId])
            end
        else
            CWaring("ViewJumpCtrl:JumpTo Cfg param Error:"..JumpId)
        end
    elseif JumpType == ViewJumpCtrl.JumpTypeDefine.JumpActivity then
        local ViewParams = JumpCfg[Cfg_JumpViewCfg_P.ViewParams]
        if ViewParams ~= nil and ViewParams:Length() > 0 then
            MvcEntry:GetCtrl(ActivityCtrl):OpenActivity(tonumber(ViewParams[1]))
        else
            CWaring("ViewJumpCtrl:JumpTo Activity ID Error:"..JumpId)
        end

    elseif JumpType == ViewJumpCtrl.JumpTypeDefine.JumpWeb then
        local ViewParams = JumpCfg[Cfg_JumpViewCfg_P.ViewParams]
        if ViewParams ~= nil and ViewParams:Length() > 0 then
            UE.UGFUnluaHelper.OpenExternalUrl(ViewParams[1])
        else
            CWaring("ViewJumpCtrl:JumpTo Activity ID Error:"..JumpId)
        end
        ---跳转web
    elseif JumpType == ViewJumpCtrl.JumpTypeDefine.JumpApp then
        ---跳转app
    end
end

--[[
  通过跳转ID列表可跳转界面对应的按钮名称,为支持以下举例：如果配了1）跳活动2）跳商城，1活动过期的情况下，就读2的跳转
  List为TArray类型
]]
function ViewJumpCtrl:GetBtnName(JumpIdList)
    -- SD_SpecialText 配置
    -- Lua_Special_OneParam {0} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam")
    -- Lua_Special_OneParam_Pro1_1 {0}% G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_1")
    -- Lua_Special_OneParam_Pro1_2 +{0}% G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_2")
    -- Lua_Special_OneParam_Pro1_3 -{0}% G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_3")
    -- Lua_Special_OneParam_Pro1_4 [{0}] G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_4")
    -- Lua_Special_OneParam_Pro1_5 ({0}) G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_5")
    -- Lua_Special_OneParam_Pro1_6 /{0} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_6")
    -- Lua_Special_OneParam_Pro1_7 X{0} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_7")
    -- Lua_Special_OneParam_Pro1_8 x{0} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_8")
    -- Lua_Special_OneParam_Pro1_9 +{0} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_9")
    -- Lua_Special_OneParam_Pro1_10 -{0} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_10")
    -- Lua_Special_OneParam_Pro1_11 {0}: G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_11")
    -- Lua_Special_OneParam_Pro1_12 x{0}+ G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_12")

    -- Lua_Special_TwoParam {0}{1} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam")
    -- Lua_Special_TwoParam_Pro2_1 {0}/{1} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1")
    -- Lua_Special_TwoParam_Pro2_2 {0}:{1} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_2")

    -- Lua_Special_ThreeParam {0}{1}{2} G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_ThreeParam")


    local JumpId = self:GetJumpIDByTArrayList(JumpIdList)
    -- print('=========================ViewJumpCtrl:GetBtnName',JumpId)
    local JumpCfg = G_ConfigHelper:GetSingleItemById(Cfg_JumpViewCfg,JumpId)
    local GetStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_ViewJumpCtrl_Get")
    if not JumpCfg then
        CWaring("ViewJumpCtrl:JumpTo Can't GetJumpCfg For Id = "..JumpId)
        local strTip = StringUtil.FormatText(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ViewJumpCtrl_IsNotOpen"))
        return strTip
    end
    local NameStr = JumpCfg[Cfg_JumpViewCfg_P.FuncName]
    local ViewParams = JumpCfg[Cfg_JumpViewCfg_P.ViewParams]
    local ActivityID = ViewParams ~= nil and ViewParams:Length() > 0 and ViewParams[1] or 0
    if #NameStr > 0 then
        return NameStr
    elseif JumpCfg[Cfg_JumpViewCfg_P.JumpType] == ViewJumpCtrl.JumpTypeDefine.JumpActivity then
        return StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), MvcEntry:GetModel(ActivityModel):GetActivityName(tonumber(ActivityID)), GetStr)
    elseif JumpCfg[Cfg_JumpViewCfg_P.JumpType] == ViewJumpCtrl.JumpTypeDefine.DoNotJump then 
        return StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_ViewJumpCtrl_LimitTimeGet"))--限时获取
    elseif JumpCfg[Cfg_JumpViewCfg_P.JumpType] == ViewJumpCtrl.JumpTypeDefine.JumpView then
        return StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_ViewJumpCtrl_GoToGet_Btn"))  --前往获取
    elseif JumpCfg[Cfg_JumpViewCfg_P.JumpType] == ViewJumpCtrl.JumpTypeDefine.DisabledBtn then
        --TODO
    elseif JumpCfg[Cfg_JumpViewCfg_P.JumpType] == ViewJumpCtrl.JumpTypeDefine.JumpWeb then
        --TODO
    elseif JumpCfg[Cfg_JumpViewCfg_P.JumpType] == ViewJumpCtrl.JumpTypeDefine.JumpApp then
        --TODO
    end

    return StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_ViewJumpCtrl_GoTo"), GetStr)
end

--[[
  通过跳转ID列表获取对应可跳转的ID,为支持以下举例：如果配了1）跳活动2）跳商城，1活动过期的情况下，就读2的跳转
  List为TArray类型
]]
function ViewJumpCtrl:GetJumpIDByTArrayList(List)
    if not List or List:Length() == 0 then
        return 0
    end
    for _,JumpId in pairs(List) do
        local JumpCfg = G_ConfigHelper:GetSingleItemById(Cfg_JumpViewCfg,JumpId)
        if JumpCfg ~= nil then
            -- 类型为限时活动时需要判断活动是否过期
            local ViewParams = JumpCfg[Cfg_JumpViewCfg_P.ViewParams]
            local ActivityID = ViewParams ~= nil and ViewParams:Length() > 0 and ViewParams[1] or 0
            if JumpCfg[Cfg_JumpViewCfg_P.JumpType] == ViewJumpCtrl.JumpTypeDefine.JumpActivity then
                if MvcEntry:GetModel(ActivityModel):IsActiivtyAvailable(tonumber(ActivityID)) then
                    return JumpId
                end
            else
                return JumpId
            end
        end
    end
    return 0
end

--[[
  通过跳转ID列表跳转到可跳转界面,为支持以下举例：如果配了1）跳活动2）跳商城，1活动过期的情况下，就读2的跳转
  List为TArray类型
]]
function ViewJumpCtrl:JumpToByTArrayList(List)
    local JumpId = self:GetJumpIDByTArrayList(List)
    self:JumpTo(JumpId)
end

-- 通过道具id获取道具表对应的jumpId数据
function ViewJumpCtrl:GetItemCfgJumpIdByID(id)
    if not id then
        return nil
    end
    local ItemCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_ItemConfig, Cfg_ItemConfig_P.ItemId, id)
    if ItemCfg == nil then
        return nil
    end
    return ItemCfg[Cfg_ItemConfig_P.JumpID]
end

--[[
  通过跳转ID列表获取对应可跳转的类型
  List为TArray类型
]]
function ViewJumpCtrl:GetJumpTypeByTArrayList(JumpIdList)
    local JumpId = self:GetJumpIDByTArrayList(JumpIdList)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_JumpViewCfg,JumpId)
    if not Cfg then
        return ViewJumpCtrl.JumpTypeDefine.DoNotJump
    end
    return Cfg[Cfg_JumpViewCfg_P.JumpType]
end

-----------------------------------自定义跳转逻辑实现----------------------------------
--[[
    跳转到充值界面的自定义跳转逻辑
]]
function ViewJumpCtrl:LogicId_1001(InParam)
    local SelectId = tonumber(InParam[2])
    if SelectId and SelectId > 0 then
        local TempParam = { bIsJumpCtrl = true }
        MvcEntry:GetCtrl(ShopCtrl):OpenShopDetailView(SelectId, TempParam)
    end
end

--- 
---@param InParam any
function ViewJumpCtrl:LogicId_1002(InParam)
    self:HallTabSwitch(CommonConst.HL_PLAY, InParam)
end

--- 英雄
---@param InParam any
function ViewJumpCtrl:LogicId_1003(InParam)
    self:HallTabSwitch(CommonConst.HL_HERO, {
        0,
        InParam[1]
    })
end

--- 
---@param InParam any
function ViewJumpCtrl:LogicId_1004(InParam)
    self:HallTabSwitch(CommonConst.HL_ARSENAL, InParam)
end

--- 赛季
---@param InParam any
function ViewJumpCtrl:LogicId_1005(InParam)
    self:HallTabSwitch(CommonConst.HL_SEASON, InParam)
end

--- 好感度
---@param InParam any
function ViewJumpCtrl:LogicId_1006(InParam)
    self:HallTabSwitch(CommonConst.HL_FAV, InParam)
end

function ViewJumpCtrl:LogicId_1007(InParam)
    self:HallTabSwitch(CommonConst.HL_SHOP, InParam)
end

function ViewJumpCtrl:HallTabSwitch(TabKey, InParam)
    local TabType = InParam and tonumber(InParam[1]) or 0
    local SelectId = InParam and tonumber(InParam[2]) or 0
    local Param = {
        TabKey = TabKey,
        TabType = TabType,
        IsForceSelect = true,
        SelectId = SelectId
    }
    MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.HALL_TAB_SWITCH_AFTER_CLOSE_POPS,Param)
end