---
--- 用于配置英雄界面中右边的列表中，使用WSAD或方向键找到的对应的索引位置
--- Created At: 2023/03/27 17:16
--- Created By: 朝文
---

--[[
    UMG 界面示意图
        11  6    1
        12  7    2
        13  8    3
        14  9    4
        15  10   5
--]]
local HeroDisplayListConfig = {  
    [1] = {
        Left = 6,
        Bottom = 2,
        Top = 0,
    },
    [2] = {
        Left = 7,
        Top = 1,
        Bottom = 3,
    },
    [3] = {
        Left = 8,
        Top = 2,
        Bottom = 4,
    },
    [4] = {
        Left = 9,
        Top = 3,        
        Bottom = 5,
    },
    [5] = {
        Left = 10,
        Top = 4,
        Bottom = 6,
    },
    [6] = {
        Left = 11,
        Right = 1,
        Top = 5,        
        Bottom = 7,
    },
    [7] = {
        Left = 12,
        Right = 2,
        Top = 6,
        Bottom = 8,
    },
    [8] = {        
        Left = 13,
        Right = 3,
        Top = 7,
        Bottom = 9,
    },
    [9] = {
        Left = 14,
        Right = 4,
        Top = 8,
        Bottom = 10,
    },
    [10] = {
        Left = 15,
        Right = 5,
        Top = 9,
        Bottom = 11,
    },
    [11] = {
        Right = 6,
        Top = 10,
        Bottom = 12,
    },
    [12] = {
        Right = 7,
        Top = 11,
        Bottom = 13,
    },
    [13] = {
        Right = 8,
        Top = 12,
        Bottom = 14,
    },
    [14] = {
        Right = 9,
        Top = 13,
        Bottom = 15,
    },
    [15] = {
        Right = 10,
        Top = 14,
    },
}

return HeroDisplayListConfig