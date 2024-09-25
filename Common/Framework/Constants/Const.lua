local const = { }

-- 时间
const.MESC_ONE_SEC = 1000
const.SECONDS_ONE_MINUTE = 60
const.SECONDS_ONE_HOUR = 60 * 60
const.MSEC_ONE_HOUR = const.SECONDS_ONE_HOUR * const.MESC_ONE_SEC
const.MESC_ONE_MINUTE = const.SECONDS_ONE_MINUTE * const.MESC_ONE_SEC
const.HOUR_DAY_START_OFFSET = 0
const.HOUR_DAY_REFRESH_OFFSET = 4
const.SECONDS_ONE_DAY = 60 * 60 * 24
const.MSEC_ONE_DAY = 60 * 60 * 24 * const.MESC_ONE_SEC
const.SECONDS_ONE_WEEK = 7 * 24 * 60 * 60


--_G.const = const
return const
