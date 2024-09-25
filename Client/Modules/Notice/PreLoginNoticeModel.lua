--[[
    登录前公告 - 数据
]]

local super = GameEventDispatcher;
local class_name = "PreLoginNoticeModel";

---@class PreLoginNoticeModel : GameEventDispatcher
---@field private super GameEventDispatcher
PreLoginNoticeModel = BaseClass(super, class_name)


function PreLoginNoticeModel:__init()
    self:InitNoticeList()
end

function PreLoginNoticeModel:OnLogin(data)
end

--[[
    玩家登出时调用
]]
function PreLoginNoticeModel:OnLogout(data)
end

--[[
    左侧标题列表
]]
function PreLoginNoticeModel:GetNoticeList()
    return self.NoticeList or {}
end

function PreLoginNoticeModel:GetNoticeById(Id)
    return self.IdToNotice[Id]
end

-- 初始化登录前公告数据
function PreLoginNoticeModel:InitNoticeList()
    self.NoticeList = {}
    self.IdToNotice = {}

    local NoticeCfgs =  G_ConfigHelper:GetDict(Cfg_PreLoginNoticeConfig) 
    if not NoticeCfgs then
        CError("[PreLoginNoticeModel] InitNoticeList NoticeCfg is nil")
        return
    end

    local NowTimeStamp = GetTimestamp()

    for _, Cfg in pairs(NoticeCfgs) do
        local Id = Cfg[Cfg_PreLoginNoticeConfig_P.Id]
        local BeginTime = Cfg[Cfg_PreLoginNoticeConfig_P.BeginTimeTimestamp]
        local EndTime = Cfg[Cfg_PreLoginNoticeConfig_P.EndTimeTimestamp]

        if  (not BeginTime and not EndTime) or (BeginTime and EndTime and NowTimeStamp - BeginTime >= 0 and EndTime - NowTimeStamp > 0) then
            --- @class PreLoginNotice
            ---@field Id number
            ---@field ListName string 左侧标题
            ---@field Title string 右侧内容标题
            ---@field Prority number 优先级，数字越大就越靠前
            ---@field ItemList string 公告内容分段列表，格式为 { SubHeading='...', Content='...' }
            ---@field BeginTime number 公告开始展示时间戳
            ---@field EndTime number 公告结束展示时间戳
            local PreLoginNotice = {
                Id = Cfg[Cfg_PreLoginNoticeConfig_P.Id],
                ListName = Cfg[Cfg_PreLoginNoticeConfig_P.ListName],
                Title = Cfg[Cfg_PreLoginNoticeConfig_P.Title],
                Priority = Cfg[Cfg_PreLoginNoticeConfig_P.Priority],
                ItemList = self.NoticeContentItemsToContentList(Cfg),
                BeginTime = BeginTime,
                EndTime = EndTime,
            }

            table.insert(self.NoticeList, PreLoginNotice)
            self.IdToNotice[PreLoginNotice.Id] = PreLoginNotice
        end
    end

    -- 按照优先级排序
    table.sort(self.NoticeList, function (a,b)
        return a.Priority > b.Priority
    end)
end

-- 把表里配置中的 SubHeading1, Content1, SubHeading2, Content2 等字段改为列表
function PreLoginNoticeModel.NoticeContentItemsToContentList(NoticeCfg)
    local ItemList = {}
    local MaxSubHeadingNum = 9

    for i = 1, MaxSubHeadingNum do
        if #NoticeCfg[Cfg_PreLoginNoticeConfig_P["SubHeading" .. i]] ~= 0 then
            table.insert(ItemList, {
                SubHeading = NoticeCfg[Cfg_PreLoginNoticeConfig_P["SubHeading" .. i]],
                Content = NoticeCfg[Cfg_PreLoginNoticeConfig_P["Content" .. i]] or ""
            })
        end
    end

    return ItemList
end