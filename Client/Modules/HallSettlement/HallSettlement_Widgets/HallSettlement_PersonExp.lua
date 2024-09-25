---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 局外结算经验面板
--- Created At: 2023/08/23 10:21
--- Created By: 朝文
---

local class_name = "HallSettlement_PersonExp"
---@class HallSettlement_PersonExp
local HallSettlement_PersonExp = BaseClass(nil, class_name)

function HallSettlement_PersonExp:OnInit()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    --更新玩家头像
    local Param = {
        PlayerId = UserModel:GetPlayerId(),
        CloseAutoCheckFriendShow = true,
        ClickType = CommonHeadIcon.ClickTypeEnum.None
    }
    self.HeadIcon = UIHandler.New(self, self.View.WBP_CommonHeadIcon, CommonHeadIcon, Param).ViewInstance
end

function HallSettlement_PersonExp:OnShow(Param)
    self.View.Text_Add:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function HallSettlement_PersonExp:OnHide()  
    self:ClearAnimationBind()
    self:ClearPersonExpTimer()
end

-- 清除绑定动画回调
function HallSettlement_PersonExp:ClearAnimationBind()
    if self.HeadIcon and CommonUtil.IsValid(self.HeadIcon.View.vx_exp_level_up) then
        self.HeadIcon.View.vx_exp_level_up:UnbindAllFromAnimationFinished(self.HeadIcon.View) 
    end  
    if CommonUtil.IsValid(self.View) and CommonUtil.IsValid(self.View.vx_exp_num_add_in) then
        self.View.vx_exp_num_add_in:UnbindAllFromAnimationFinished(self.View) 
    end
end


function HallSettlement_PersonExp:SetData(Param)    end

--[[
    Param = {
        Level = 1,
        Exp = 1,
    }
--]]
---初始化显示经验
function HallSettlement_PersonExp:InitExpDispaly(Param)
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    self.InitData = {
        CurrentLevel = Param.Level,
        CurrentExp = Param.Exp,
        NextLevel = Param.Level + 1,
        NextLevelNeedExp = UserModel:GetPlayerMaxExpForLv(Param.Level),
    }
    
    self.View.Text_Progress1:SetText(self.InitData.CurrentExp)
    self.View.Text_Progress2:SetText(self.InitData.NextLevelNeedExp)

    self.View.Text_Level:SetText(StringUtil.FormatSimple("Lv.{0}", Param.Level))
    
    local Percent = self.InitData.CurrentExp/self.InitData.NextLevelNeedExp
    self.View.GUIProgressBar:SetPercent(Percent)

    --这里不依赖头像里面的lua逻辑，自己处理
    self.HeadIcon.View.Text_Level:SetText(Param.Level)
    self.HeadIcon.View.Text_Level:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.HeadIcon.View.Text_Level_1:SetText(Param.Level)
    self.HeadIcon.View.Text_Level_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.HeadIcon.View.LevelRoot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function HallSettlement_PersonExp:AddExp(Exp)
    self:OnPlayAddExpAnimation(Exp)
    self:OnPlayExpProgressAnimation(Exp)
end

-- 播放增加经验动画
function HallSettlement_PersonExp:OnPlayAddExpAnimation(Exp)
    self.View.Text_Add:SetText("+" .. tostring(Exp))
    self.View.Text_Add:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    if CommonUtil.IsValid(self.View.vx_exp_num_add_in) then
        self.View.vx_exp_num_add_in:UnbindAllFromAnimationFinished(self.View)
        self.View.vx_exp_num_add_in:BindToAnimationFinished(self.View, function()
            self.View:PlayAnimation(self.View.vx_exp_num_add_out, 0, 1, 0, 1, false)
        end)
        self.View:PlayAnimation(self.View.vx_exp_num_add_in, 0, 1, 0, 1, false) 
    end
end

-- 播放经验进度条动画
function HallSettlement_PersonExp:OnPlayExpProgressAnimation(Exp)
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    -- 升级播放动画需要花费的时间
    local LevelUpTime = self.HeadIcon.View.vx_exp_level_up:GetEndTime()
    -- 度过的时间
    local PastTime = 0
    -- 执行时间
    local ExecutionTime = 0
    local leftExp = Exp
    self:ClearPersonExpTimer()
    self.PersonExpTimer = self:InsertTimer(Timer.NEXT_FRAME,
            function(DeltaTime)
                PastTime = PastTime + DeltaTime
                if PastTime >= ExecutionTime then
                    if leftExp > 0 then
                        self.InitData.CurrentExp = self.InitData.CurrentExp + 1
                        self.View.Text_Progress1:SetText(self.InitData.CurrentExp)
                        local Percent = self.InitData.CurrentExp/self.InitData.NextLevelNeedExp
                        self.View.GUIProgressBar:SetPercent(Percent)
                        --这里升级了
                        if self.InitData.CurrentExp == self.InitData.NextLevelNeedExp then
                            self.InitData.CurrentLevel = self.InitData.NextLevel
                            self.InitData.NextLevel = self.InitData.NextLevel + 1
                            self.InitData.CurrentExp = 0
                            self.InitData.NextLevelNeedExp = UserModel:GetPlayerMaxExpForLv(self.InitData.CurrentLevel)
            
                            self.HeadIcon.View.Text_Level:SetText(self.InitData.CurrentLevel)
                            self.HeadIcon.View.Text_Level_1:SetText(self.InitData.CurrentLevel)
                            self:OnPlayLevelUpAnimation()    
                            ExecutionTime = PastTime + LevelUpTime              
                        --这里没有升级
                        else
                            ExecutionTime = PastTime + DeltaTime
                        end
                        leftExp = leftExp - 1 
                    else
                        self:ClearPersonExpTimer()
                    end
                end
            end,
            true, TimerTypeEnum.Timer, "HallSettlement_PersonExpTimer")
end

-- 播放升级动画
function HallSettlement_PersonExp:OnPlayLevelUpAnimation()
    if self.HeadIcon and CommonUtil.IsValid(self.HeadIcon.View.vx_exp_level_up) then
        self.HeadIcon.View.vx_exp_level_up:UnbindAllFromAnimationFinished(self.HeadIcon.View)
        self.HeadIcon.View.vx_exp_level_up:BindToAnimationFinished(self.HeadIcon.View, function()
            self:OnLevelUpAnimationCompleteCallBack()
        end)
        self.HeadIcon.View:PlayAnimation(self.HeadIcon.View.vx_exp_level_up, 0, 1, 0, 1, false)
    end
end

-- 升级动画播放完成回调
function HallSettlement_PersonExp:OnLevelUpAnimationCompleteCallBack()
    ---------------------------- 提审专用：等级2时提示所有系统已解锁 --------------------------
    if self.InitData.CurrentLevel == 2 then
        UIMessageBox.Show({describe = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HallSettlement_Allsystemshavebeenun"))})
    end
    --------------------------------------- 提审专用 -------------------------------------
    self.View.Text_Progress1:SetText(self.InitData.CurrentExp)
    self.View.Text_Progress2:SetText(self.InitData.NextLevelNeedExp)
    local Percent = self.InitData.CurrentExp/self.InitData.NextLevelNeedExp
    self.View.GUIProgressBar:SetPercent(Percent)
    self.View.Text_Level:SetText(StringUtil.FormatSimple("Lv.{0}", self.InitData.CurrentLevel))
end

--移除经验定时器
function HallSettlement_PersonExp:ClearPersonExpTimer()
    if self.PersonExpTimer then
        Timer.RemoveTimer(self.PersonExpTimer)
    end
    self.PersonExpTimer = nil
end


return HallSettlement_PersonExp
