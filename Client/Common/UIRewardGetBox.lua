--[[
    公共奖励获得弹窗系统

]]
---@class UIRewardGetBox
UIRewardGetBox = UIRewardGetBox or {}

--[[
    公共方法
]]
---@public
---@param msgParam table 协议数据
function UIRewardGetBox.Show(msgParam)

    if msgParam.ShowType == nil then 
        return
    elseif msgParam.ShowType == pb_Reward_EShowType.None then
        -- pass

    elseif msgParam.ShowType == pb_Reward_EShowType.Common then
        -- 常规获取物品弹窗
        UIRewardGetBox.ShowCommonBox(msgParam)
    end

    -- TODO 不同类型的弹窗写这里

end

--[[
    常规获取物品弹窗
]]
---@private
---@param msgParam table
function UIRewardGetBox.ShowCommonBox(msgParam)
    -- 过滤一下数据
    if msgParam.Rewards == nil or #msgParam.Rewards == 0 then
        return
    end
    MvcEntry:OpenView(ViewConst.RewardGetBox, msgParam.Rewards)
end

--[[
    TODO 其他类型的物品弹窗
]]

return UIRewardGetBox