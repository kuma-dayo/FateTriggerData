local ActivityDefine = {}

ActivityDefine.ActicityNoticeType = 9999
ActivityDefine.ActicityQuestionnaireType = 9998

---@class BannerShowState
ActivityDefine.BannerShowState = {
    None = 0,
    Normal = 1, --预展示状态
    Showing = 2,--展示状态
    Dismiss = 3,--不展示状态
}

---@class BannerShowType
ActivityDefine.BannerShowType = {
    None = 0,
    New = 1, --上新
    Daily = 2,--每日
}
---@class BannerDismissType
ActivityDefine.BannerDismissType = {
    None = 0,
    Open = 1,      --查阅（包含点该宣传图跳转，或其他方式进入系统后查阅过对应商品/活动）
    Permanent = 2, --常驻
}

---@class ActivityState
ActivityDefine.ActivityState = {
    None = 0,
    Open = 1,
    Close = 2,
}

---@class ActivitySubState
ActivityDefine.ActivitySubState = {
    Not = 0, -- 未获取
    Can = 1, -- 可获取
    Got = 2, -- 已获取
}

---活动来源类型,把公告也当做活动的数据类型
---@class ActivitySourceType
ActivityDefine.ActivitySourceType = {
    Normal = 0, --一般指活动
    Notice = 1, --公告
}

-- "0/空-默认，无沉底
-- 1-全部奖励进入已领取状态后沉底
-- 2-活动最后一天沉底
-- 3-最后一天所有奖励进入已领取状态后沉底"
---@class ActivitySinkType 沉底类型
ActivityDefine.ActivitySinkType = {
    None = 0,
    AllRewardGot = 1,
    FinalDay = 2,
    AllRewardGotAndFinalDay = 3,
}

---@class ActivityUMGBinds
---@field UMGPath string
---@field Script string
---@field ViewID number
ActivityDefine.ActivityUMGBinds = {
    [ActivityDefine.ActicityNoticeType] = {
        UMGPath = "/Game/BluePrints/UMG/OutsideGame/Activity/WBP_Activity_Bulletin.WBP_Activity_Bulletin",
        Script = "Client.Modules.Activity.ActivityContent.Notice.ActivityNotice",
        ViewID = 0
    },
    [ActivityDefine.ActicityQuestionnaireType] = {
        UMGPath = "/Game/BluePrints/UMG/OutsideGame/Activity/Questionnaire/WBP_Activity_Questionnaire.WBP_Activity_Questionnaire",
        Script = "Client.Modules.Activity.ActivityContent.Questionnaire.ActivityQuestionnaire",
        ViewID = 0
    },
    [Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_INVAILD] = {
        UMGPath = "",
        Script = "Client.Modules.Activity.ActivityContent.ActivityEmpty",
        ViewID = 0
    },
    [Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_THREE_LOGIN] = {
        UMGPath = "/Game/BluePrints/UMG/OutsideGame/Activity/ThreeDayEvent/WBP_ThreeDayEvent_Main.WBP_ThreeDayEvent_Main",
        Script = "Client.Modules.Activity.ActivityContent.ThreeDayLogin.ActivityThreeDayLogin",
        ViewID = 0
    },
    [Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_WEEK_LOGIN] = {
        UMGPath = "/Game/BluePrints/UMG/OutsideGame/Activity/WeeklyLogin/WBP_WeeklyLogin_Main.WBP_WeeklyLogin_Main",
        Script = "Client.Modules.Activity.ActivityContent.SevenLogin.ActivitySevenLogin",
        ViewID = 0
    },
    [Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_ATTATION] = {
        UMGPath = "/Game/BluePrints/UMG/OutsideGame/Activity/Community/WBP_Community_Main.WBP_Community_Main",
        Script = "Client.Modules.Activity.ActivityContent.Community.ActivityCommunity",
        ViewID = 0
    },
    [Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_SINGLE_TASK] = {
        UMGPath = "",
        Script = "",
        ViewID = 0
    },
    [Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_DAY_TASK] = {
        UMGPath = "/Game/BluePrints/UMG/OutsideGame/Activity/DailyTask/WBP_DailyTask_Main.WBP_DailyTask_Main",
        Script = "Client.Modules.Activity.ActivityContent.DailyTask.ActivityDailyTask",
        ViewID = 0
    },
    [Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_TASK] = {
        UMGPath = "",
        Script = "",
        ViewID = 0
    },
    [Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_EXCHANGE] = {
        UMGPath = "",
        Script = "",
        ViewID = 0
    },
    [Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_MULTI_JUMP] = {
        UMGPath = "/Game/BluePrints/UMG/OutsideGame/Activity/DoubleHeroEvent/WBP_DoubleHeroEvent_Main.WBP_DoubleHeroEvent_Main",
        Script = "Client.Modules.Activity.ActivityContent.DoubleHeroEvent.ActivityDoubleHeroEvent",
        ViewID = 0
    },
}

return ActivityDefine