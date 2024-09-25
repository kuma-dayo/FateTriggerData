---
--- Ctrl 模块，主要用于处理协议
--- Description: 匹配模式选择
--- Created At: 2023/05/12 11:39
--- Created By: 朝文
---

require("Client.Modules.Match.MatchModeSelect.MatchModeSelectModel")

local class_name = "MatchModeSelectCtrl"
---@class MatchModeSelectCtrl : UserGameController
MatchModeSelectCtrl = MatchModeSelectCtrl or BaseClass(UserGameController, class_name)

function MatchModeSelectCtrl:__init()
    CWaring("[cw] MatchModeSelectCtrl init")
    self.MatchModeSelectModel = nil
    self.MatchModel = nil
end

function MatchModeSelectCtrl:Initialize()
    ---@type MatchModeSelectModel
    self.MatchModeSelectModel = self:GetModel(MatchModeSelectModel)

    ---@type MatchModel
    self.MatchModel =self:GetModel(MatchModel)
end

function MatchModeSelectCtrl:AddMsgListenersUser()
    self.ProtoList = {
        { Model = TeamModel, MsgName = TeamModel.ON_SELF_QUIT_TEAM,	        Func = Bind(self, self.ON_SELF_QUIT_TEAM_func) },       --自己退出队伍（不包括单人队，真正意义上的退队）        
    }
    
    self.MsgList = {
        { Model = TeamModel, MsgName = TeamModel.ON_ADD_TEAM_MEMBER,	    Func = self.OnTeamMemberChanged },          --队员成员增加
        { Model = TeamModel, MsgName = TeamModel.ON_DEL_TEAM_MEMBER,	    Func = self.OnTeamMemberChanged },          --队员成员减少
    }
end

----------------------------------------- 事件相关 -----------------------------------------

function MatchModeSelectCtrl:ON_SELF_QUIT_TEAM_func()
    --TODO:离队后的模式选择逻辑这里处理
    --self:SendChangeModeReq()
end

---队伍中的玩家数量发生改变
function MatchModeSelectCtrl:OnTeamMemberChanged()
    --1.组队且非队长时，不需要处理
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if TeamModel:IsSelfTeamNotCaptain() then return end

    --2.单人/组队且为队长时，需要设置一下 MatchTeamMode
    local MyTeamPlayerCount = TeamModel:GetMyTeamMemberCount()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)    
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local PlayModeId = MatchModel:GetPlayModeId()
    local TeamType = MatchModel:GetTeamType()
    local MaxTeamMemberNum = TeamType or 0
    
    --当前模式人数上限小于当前队伍人数的话，需要更改模式，往大了阔 单 -> 双 -> 四人
    local MatchConst = require("Client.Modules.Match.MatchConst")
    if MaxTeamMemberNum < MyTeamPlayerCount then
        ---@type MatchCtrl
        local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)
        if MyTeamPlayerCount == 2 then
            --双人可以用
            if MatchModeSelectModel:GetPlayModeCfg_TeamType_Duo(PlayModeId) then                
                MatchCtrl:ChangeMatchModeInfo({
                    TeamType = MatchConst.Enum_TeamType.duo,
                })
                UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectCtrl_Themodehasbeenautoma")))                
                return
                
            --四人可以用
            elseif MatchModeSelectModel:GetPlayModeCfg_TeamType_Squad(PlayModeId) then
                MatchCtrl:ChangeMatchModeInfo({
                    TeamType = MatchConst.Enum_TeamType.squad,
                })
                UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectCtrl_Themodehasbeenautoma")))
                return
            end
            
            --走到这里说明都不能用，则弹出提示
            UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectCtrl_Thecurrentteammodeex")))
        else
            --四人可以用
            if MatchModeSelectModel:GetPlayModeCfg_TeamType_Squad(PlayModeId) then
                MatchCtrl:ChangeMatchModeInfo({
                    TeamType = MatchConst.Enum_TeamType.squad,
                })
                UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectCtrl_Themodehasbeenautoma")))
                return
            end
            
            --走到这里说明都不能用，则弹出提示
            UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModeSelectCtrl_Thecurrentteammodeex")))
        end
    end
end

-- GM打开模式选择界面中服务器列表展示
function MatchModeSelectCtrl:SetOpenModeSelectServerList()
    self.MatchModeSelectModel:SetIsShowModeSelectServerList(true)
end

