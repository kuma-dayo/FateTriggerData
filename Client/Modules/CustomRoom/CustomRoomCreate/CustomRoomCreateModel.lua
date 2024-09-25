---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 自建房房间设置数据
--- Created At: 2023/06/15 17:25
--- Created By: 朝文
---

local super = ListModel
local class_name = "CustomRoomCreateModel"
---@class CustomRoomCreateModel : ListModel
CustomRoomCreateModel = BaseClass(super, class_name)
CustomRoomCreateModel.Const = {
    DefaultSelectPlayModeId = 10001,
    DefaultSelectPlayModeIdIndex = 1,   --TODO:这里需要动态获取
    
    DefaultSelectLevelId = 101101, 
    DefaultSelectLevelIdIndex = 1,      --TODO:这里需要动态获取
    
    DefaultSelectModeKey = "101_squad_tpp",
    DefaultSelectModeKeyIndex = 3,      --TODO:这里需要改为动态获取
    
    --这里后续要替换成模式选择的接口数据，目前是临时的
    PlayMode = {
        [1] = {
            PlayModeId = 10001,
            LevelIds = {
                [1] = {
                    LevelId = 101101,
                    ModeKeys = {
                        "101_solo_tpp",
                        "101_duo_tpp",
                        "101_squad_tpp",
                    }
                },
            }
            
        },
        --[2] = {
        --    PlayModeId = 10002,
        --}
        --[1] = {
        --    ModeKey = "101_solo_tpp",
        --    DisplayName = "普通试炼单排",
        --    Maps = {
        --        [1] = {
        --            SceneId = 101,
        --            DisplayName = "nordland",
        --        },
        --    }
        --},       
    }
}

function CustomRoomCreateModel:__init()
    self:DataInit()
end

---初始化数据，用于第一次调用及登出的时候调用
function CustomRoomCreateModel:DataInit()
    self.CurSelectPlayModeId = nil
    self._CurSelectPlayModeIndex = nil
    
    self.CUrSelectLevelId = nil
    self._CurSelectLevelIdIndex = nil
    
    self.CurSelectModeKey = nil
    self._CurSelectModeKeyIndex = nil
    --self._CurSelectModeCfg = nil

    --self.CurSelectSceneId = nil
    --self._CurSelectSceneIdIndex = nil
    --self._CurSelectSceneCfg = nil
end

---玩家登出时调用
function CustomRoomCreateModel:OnLogout(data)
    self:DataInit()
end

--------------------- Default ---------------------

function CustomRoomCreateModel:GetDefaultSelectPlayModeId()
    return CustomRoomCreateModel.Const.DefaultSelectPlayModeId, CustomRoomCreateModel.Const.DefaultSelectPlayModeIdIndex
end

function CustomRoomCreateModel:GetDefaultSelectLevelId()
    return CustomRoomCreateModel.Const.DefaultSelectLevelId, CustomRoomCreateModel.Const.DefaultSelectLevelIdIndex
end

function CustomRoomCreateModel:GetDefaultSelectModeKey()
    return CustomRoomCreateModel.Const.DefaultSelectModeKey, CustomRoomCreateModel.Const.DefaultSelectModeKeyIndex
end

--------------------- (select)PlayModeId ---------------------

function CustomRoomCreateModel:SetSelectPlayModeId(newPlayModeId, index)
    CLog("[cw] CustomRoomCreateModel:SetSelectPlayModeId(" .. string.format("%s, %s", tostring(newPlayModeId), tostring(index)) .. ")")
    self.CurSelectPlayModeId = newPlayModeId
    self._CurSelectPlayModeIndex = index
end

function CustomRoomCreateModel:GetSelectPlayModeId()
    return self.CurSelectPlayModeId, self._CurSelectPlayModeIndex
end

--------------------- (select)LevelId ---------------------

function CustomRoomCreateModel:SetSelectLevelId(newLevelId, index)
    CLog("[cw] CustomRoomCreateModel:SetSelectLevelId(" .. string.format("%s, %s", tostring(newLevelId), tostring(index)) .. ")")
    self.CUrSelectLevelId = newLevelId
    self._CurSelectLevelIdIndex = index
end

function CustomRoomCreateModel:GetSelectLevelId()
    return self.CUrSelectLevelId, self._CurSelectLevelIdIndex
end

--------------------- (select)ModeKey ---------------------

function CustomRoomCreateModel:SetSelectModeKey(newLevelId, index)
    self.CurSelectModeKey = newLevelId
    self._CurSelectModeKeyIndex = index
end

function CustomRoomCreateModel:GetSelectModeKey()
    return self.CurSelectModeKey, self._CurSelectModeKeyIndex
end

return CustomRoomCreateModel