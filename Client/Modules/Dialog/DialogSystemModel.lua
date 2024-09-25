--[[
    剧情系统对接模块数据模型
]]

local super = GameEventDispatcher;
local class_name = "DialogSystemModel";

---@class DialogSystemModel : GameEventDispatcher
---@field private super GameEventDispatcher
DialogSystemModel = BaseClass(super, class_name)

DialogSystemModel.ON_PLAY_STORY = "ON_PLAY_STORY" -- 开始播放剧情
DialogSystemModel.ON_STOP_STORY = "ON_STOP_STORY" -- 剧情因设置中断，停止播放，并未完整结束
DialogSystemModel.ON_FINISH_STORY = "ON_FINISH_STORY" -- 剧情完成

local ActionToView = {
    -- 封面
    [UE.EDialogActionType.Title] = {View = ViewConst.DialogActionTitle},
    -- 对话
    [UE.EDialogActionType.Dialog] = {View = ViewConst.DialogActionDialog, EnableVirtualScene = true},
    -- 纯文本
    [UE.EDialogActionType.Text] = {View = ViewConst.DialogActionText},
    -- 背景图加文本
    [UE.EDialogActionType.BgAndText] = {View = ViewConst.DialogActionBgAndText, },
    -- 漫画
    [UE.EDialogActionType.Picture] = {View = ViewConst.DialogActionPicture, },
    -- 任务
    [UE.EDialogActionType.Task] = {View = ViewConst.DialogActionTask},
    -- 道具
    [UE.EDialogActionType.Item] = {View = ViewConst.DialogActionItem},
    -- 跳过
    -- [UE.EDialogActionType.SkipToEnd] = {View = ViewConst.DialogSkipTips, },
}

function DialogSystemModel:__init()
    self:_dataInit()
end

function DialogSystemModel:_dataInit()
    self:ResetData()
end

function DialogSystemModel:OnLogin(data)
    -- self:_dataInit()
end

--[[
    玩家登出时调用
]]
function DialogSystemModel:OnLogout(data)
    DialogSystemModel.super.OnLogout(self)
    self:_dataInit()
end

function DialogSystemModel:ResetData()
    if self.CurActionType and ActionToView[self.CurActionType] then
        MvcEntry:CloseView(ActionToView[self.CurActionType].View)
    end
    self.CurActionType = nil
    self:ClearCacheDialogList()
end

function DialogSystemModel:ClearCacheDialogList()
    self.CacheDialogList = {}
end

function DialogSystemModel:GetCacheDialogList()
    return self.CacheDialogList
end

function DialogSystemModel:DoAction(DoActionType,ParamJsonStr)
    local Param = json.decode(ParamJsonStr)
    -- 缓存对话数据，供log查看
    if DoActionType == UE.EDialogActionType.Dialog  then
        self.CacheDialogList[#self.CacheDialogList + 1] = Param
    else
        self.CacheDialogList = {}
    end
    if self.CurActionType and ActionToView[self.CurActionType] and DoActionType ~= self.CurActionType then
        MvcEntry:CloseView(ActionToView[self.CurActionType].View)
        self.CurActionType = nil
    end
    self.CurActionType = DoActionType
    if not ActionToView[DoActionType] then
        CWaring("DoAction Without ActionType = "..DoActionType)
        -- todo
        MvcEntry:GetCtrl(DialogSystemCtrl):FinishCurAction()
        return
    end
    local ViewId = ActionToView[DoActionType].View
    -- 根据配置的虚拟场景id，动态注册
    if ActionToView[DoActionType].EnableVirtualScene then
        local VirtualSceneId = Param.VirtualSceneId > 0 and Param.VirtualSceneId or VirtualViewConfig[ViewConst.FavorablityMainMdt].VirtualSceneId
        MvcEntry:GetCtrl(ViewRegister):RegisterVirtualLevelView(ViewId,VirtualSceneId)
    end
    MvcEntry:OpenView(ViewId,Param)
end

function DialogSystemModel:EndAction()
    
end
