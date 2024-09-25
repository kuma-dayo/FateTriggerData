require("Core.BaseClass");
require("Core.Events.Event");
--[[全局公共事件]]
CommonEvent = BaseClass(Event, "CommonEvent");

CommonEvent.ON_GAME_INIT_BEFORE = "on_game_init_before";  --与ON_GAME_INIT同一帧，先于ON_GAME_INIT派发
CommonEvent.ON_GAME_INIT = "on_game_init"; 		--游戏GameIntance Start
CommonEvent.ON_CULTURE_INIT = "ON_CULTURE_INIT"; 		--游戏本地化初始化（初始化/文化发生改变时调用）


--动作-发送协议
CommonEvent.SEND_PROTO = "send_proto";
--动作-发送协议到DS服务器
CommonEvent.SEND_PROTO_DS = "SEND_PROTO_DS"; 	

--App即将切到后台
CommonEvent.ON_APP_WILL_ENTER_BACKGROUND = "ON_APP_WILL_ENTER_BACKGROUND"
--App已切回到前台
CommonEvent.ON_APP_HAS_ENTERED_FOREGROUND = "ON_APP_HAS_ENTERED_FOREGROUND"
--App即将停用
CommonEvent.ON_APP_WILL_DEACTIVATE = "ON_APP_WILL_DEACTIVATE"
--App已重新激活
CommonEvent.ON_APP_HAS_REACTIVATED = "ON_APP_HAS_REACTIVATED"
--修正默认相机的POV(坐标,FOV)
CommonEvent.ON_FIX_PLAYER_CAMERA_POV = "ON_FIX_PLAYER_CAMERA_POV"

--动作-触发连接游戏主Socket
CommonEvent.CONNECT_TO_MAIN_SOCKET = "CONNECT_TO_MAIN_SOCKET"
--通知-主Socket连接成功
CommonEvent.ON_MAIN_SOCKET_CONNECTED = "ON_MAIN_SOCKET_CONNECTED"
--通知-玩家登录失败
-- CommonEvent.ON_MAIN_LOGINED_FAIL = "ON_MAIN_LOGINED_FAIL"
--通知-玩家注册请求
-- CommonEvent.ON_MAIN_REQUIRE_REGISTER = "ON_MAIN_REQUIRE_REGISTER"
--通知-玩家随机昵称返回
-- CommonEvent.ON_RETURN_RANDOM_NAME = "ON_RETURN_RANDOM_NAME"
--通知-玩家注册成功
-- CommonEvent.ON_MAIN_REGISTERED = "ON_MAIN_REGISTERED"
--通知-玩家登录成功
-- CommonEvent.ON_MAIN_LOGINED = "ON_MAIN_LOGINED"
--通知-玩家登录失败
-- CommonEvent.ON_MAIN_LOGINED_FAIL = "ON_MAIN_LOGINED_FAIL"
--通知-玩家帐号所有信息同步完成   断线重连也会触发，参数data不为空
CommonEvent.ON_LOGIN_INFO_SYNCED = "ON_LOGIN_INFO_SYNCED"
-- --通知-帐号所有信息同步完成  后于ON_LOGIN_INFO_SYNCED触发   快速重连不会触发
-- CommonEvent.ON_LOGIN_INFO_SYNCED_READY = "ON_LOGIN_INFO_SYNCED_READY"
--通知-帐号所有信息同步完成且所有Model事件派发完成  后于ON_LOGIN_INFO_SYNCED_READY触发   快速重连不会触发
-- CommonEvent.ON_LOGIN_INFO_SYNCED_WITH_EVENT = "ON_LOGIN_INFO_SYNCED_WITH_EVENT"
--通知-帐号已经准备好， 普通登录和断线重连都会触发  后于ON_LOGIN_INFO_SYNCED_WITH_EVENT触发
CommonEvent.ON_LOGIN_FINISHED = "ON_LOGIN_FINISHED"
--通知-玩家登出
CommonEvent.ON_MAIN_LOGOUT = "ON_MAIN_LOGOUT"
--通知-玩家断线重连登出
CommonEvent.ON_RECONNECT_LOGOUT = "ON_RECONNECT_LOGOUT"
--重连状态  1表示真 0表示否
CommonEvent.RECONNECT_STATE = "RECONNECT_STATE"
--通知-玩家即将登出
CommonEvent.ON_PRE_LOGOUT = "ON_PRE_LOGOUT"

--通知-玩家即将进入战斗
CommonEvent.ON_PRE_ENTER_BATTLE = "ON_PRE_ENTER_BATTLE"
--通知-玩家即将返回大厅
CommonEvent.ON_PRE_BACK_TO_HALL = "ON_PRE_BACK_TO_HALL"
--通知-玩家已经进入战斗
CommonEvent.ON_AFTER_ENTER_BATTLE = "ON_AFTER_ENTER_BATTLE"
--通知-玩家已经进入大厅
CommonEvent.ON_AFTER_BACK_TO_HALL = "ON_AFTER_BACK_TO_HALL"


--通知-通用跨天通知
CommonEvent.ON_COMMON_DAYREFRESH = "ON_COMMON_DAYREFRESH"

CommonEvent.SHOW_VIEW_CHECK = "show_view_check"; --打开界面前检查是否允许
CommonEvent.HIDE_VIEW_CHECK = "hide_view_check"; --关闭界面前检查是否允许
CommonEvent.SHOW_VIEW = "show_view"; --打开界面
CommonEvent.HIDE_VIEW = "hide_view"; --关闭界面
CommonEvent.TOGGLE_VIEW = "toggle_view"; --根据打开状态反转界面打开状态


--UMG
-- CommonEvent.ON_CONSTRUCT = "CommonEvent.ON_CONSTRUCT"
CommonEvent.ON_DESTRUCT = "CommonEvent.ON_DESTRUCT"
-- CommonEvent.ON_SHOW = "CommonEvent.ON_SHOW"
-- CommonEvent.ON_HIDE = "CommonEvent.ON_HIDE"
CommonEvent.HAll_PANELTAB_CLICK = "CommonEvent.Hall_PanelTab_Click"

function CommonEvent:__init()	

end

return CommonEvent;