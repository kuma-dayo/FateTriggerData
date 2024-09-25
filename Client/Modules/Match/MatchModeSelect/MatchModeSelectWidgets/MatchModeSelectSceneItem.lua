---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 模式选择中，右上角场景item
--- Created At: 2023/07/19 10:27
--- Created By: 朝文
---

local class_name = "MatchModeSelectSceneItem"
---@class MatchModeSelectSceneItem
local MatchModeSelectSceneItem = BaseClass(nil, class_name)

function MatchModeSelectSceneItem:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.Button_ClickArea.OnClicked,	        Func = Bind(self, self.OnButtonClicked) },
        { UDelegate = self.View.Button_ClickArea.OnHovered,	        Func = Bind(self, self.OnButtonOnHovered) },
        { UDelegate = self.View.Button_ClickArea.OnUnhovered,       Func = Bind(self, self.OnButtonUnhovered) },        
    }
end

function MatchModeSelectSceneItem:OnShow(Param) end
function MatchModeSelectSceneItem:OnHide()
    if self.CountDownTimer then
        Timer.RemoveTimer(self.CountDownTimer)
        self.CountDownTimer = nil
    end
end

--[[
Param = {
    LevelId = 1,
    SceneId = 1,
    Desc = "",
    ClickCallback = function() end
}
--]]
function MatchModeSelectSceneItem:SetData(Param)
    self.Data = Param
end

function MatchModeSelectSceneItem:UpdateView()
    if self.CountDownTimer then
        Timer.RemoveTimer(self.CountDownTimer)
        self.CountDownTimer = nil
    end
    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    
    --背景图
    local imgPath = MatchModeSelectModel:GetSceneEntryCfg_ScenePreviewImgPath(self.Data.SceneId)    
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_MapIcon, imgPath)
    
    --地图名
    local name = MatchModeSelectModel:GetSceneEntryCfg_SceneName(self.Data.SceneId)
    self.View.Text_MapName:SetText(StringUtil.Format(name))
   
    --时间
    local startTime = MatchModeSelectModel:GetGameLevelEntryCfg_StartTime(self.Data.LevelId)
    local endTime = MatchModeSelectModel:GetGameLevelEntryCfg_EndTime(self.Data.LevelId)
    --没有配置则说明是永久开放的
    if startTime == 0 and endTime == 0 then
        self:SwitchState_Normal()
        self.View.HorizontalBox_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Text_MapDesc:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectSceneItem_Currentmap")))
        
    --这里就看一下这一张地图是否在时间内
    else
        local NowTimeStamp = GetTimestamp()
        --解锁了
        if startTime <= NowTimeStamp and NowTimeStamp < endTime then
            self:SwitchState_Normal()
            self.View.HorizontalBox_Time:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.Text_MapDesc:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectSceneItem_Currentmap")))

            local function _UpdateTIme()
                local _timeStamp = GetTimestamp()
                local dif = endTime - _timeStamp
                local timeStr = TimeUtils.GetTimeString_CountDownStyle(dif)
                self.View.Text_Time:SetText(timeStr)
                return dif
            end

            --显示倒计时相关控件，并初始化显示文字
            _UpdateTIme()
            self.CountDownTimer = Timer.InsertTimer(1, function()
                local dif = _UpdateTIme()
                if dif == 0 then
                    --这里应该触发一个刷新事件
                    
                end                
            end, true)
            
        --未解锁
        else
            self:SwitchState_Lock()
            self.View.Text_MapDesc:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectSceneItem_Unlockingsoon")))
            self.View.HorizontalBox_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function MatchModeSelectSceneItem:OnButtonClicked()
    --目前不支持点击
    
    --if self._isLock then return false end
    --
    --if self.Data and self.Data.ClickCallback then
    --    self.Data.ClickCallback()
    --end
end

function MatchModeSelectSceneItem:OnButtonOnHovered() end
function MatchModeSelectSceneItem:OnButtonUnhovered() end

function MatchModeSelectSceneItem:SwitchState_Select()  end
function MatchModeSelectSceneItem:SwitchState_Lock()    self.View.Locked:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) end
function MatchModeSelectSceneItem:SwitchState_Normal()  self.View.Locked:SetVisibility(UE.ESlateVisibility.Collapsed) end

return MatchModeSelectSceneItem
